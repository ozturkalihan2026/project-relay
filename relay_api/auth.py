from __future__ import annotations

import base64
import hashlib
import hmac
import json
import secrets
import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

from sqlalchemy import select

from .config import Settings
from .database import Database
from .db_models import PlayerRecord, RefreshSessionRecord


class AuthError(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        *,
        status_code: int = 401,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class TokenClaims:
    subject: str
    token_type: str
    jti: str
    issued_at: datetime
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class TokenBundle:
    access_token: str
    refresh_token: str
    access_expires_in: int
    refresh_expires_in: int


@dataclass(frozen=True, slots=True)
class PlayerView:
    player_id: str
    display_name: str
    created_at: datetime


@dataclass(frozen=True, slots=True)
class GuestSession:
    player: PlayerView
    tokens: TokenBundle


def _encode_segment(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _decode_segment(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    try:
        return base64.urlsafe_b64decode(value + padding)
    except Exception as exc:
        raise AuthError("invalid_token", "Oturum anahtarı geçersiz.") from exc


class JwtCodec:
    def __init__(
        self,
        *,
        secret: str,
        issuer: str,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        if len(secret) < 32:
            raise ValueError("JWT gizli anahtarı en az 32 karakter olmalıdır.")
        self._secret = secret.encode("utf-8")
        self._issuer = issuer
        self._clock = clock or (lambda: datetime.now(UTC))

    def encode(
        self,
        *,
        subject: str,
        token_type: str,
        jti: str,
        lifetime_seconds: int,
    ) -> tuple[str, datetime]:
        now = self._clock()
        expires_at = now + timedelta(seconds=lifetime_seconds)
        header = {"alg": "HS256", "typ": "JWT"}
        payload = {
            "iss": self._issuer,
            "sub": subject,
            "typ": token_type,
            "jti": jti,
            "iat": int(now.timestamp()),
            "exp": int(expires_at.timestamp()),
        }
        encoded_header = _encode_segment(
            json.dumps(
                header,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        )
        encoded_payload = _encode_segment(
            json.dumps(
                payload,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        )
        signing_input = f"{encoded_header}.{encoded_payload}".encode("ascii")
        signature = hmac.new(
            self._secret,
            signing_input,
            hashlib.sha256,
        ).digest()
        return (
            f"{encoded_header}.{encoded_payload}.{_encode_segment(signature)}",
            expires_at,
        )

    def decode(self, token: str, *, expected_type: str) -> TokenClaims:
        parts = token.split(".")
        if len(parts) != 3:
            raise AuthError("invalid_token", "Oturum anahtarı geçersiz.")
        encoded_header, encoded_payload, encoded_signature = parts
        signing_input = f"{encoded_header}.{encoded_payload}".encode("ascii")
        expected_signature = hmac.new(
            self._secret,
            signing_input,
            hashlib.sha256,
        ).digest()
        supplied_signature = _decode_segment(encoded_signature)
        if not hmac.compare_digest(expected_signature, supplied_signature):
            raise AuthError("invalid_token", "Oturum imzası geçersiz.")
        try:
            header = json.loads(_decode_segment(encoded_header))
            payload = json.loads(_decode_segment(encoded_payload))
        except (TypeError, ValueError, json.JSONDecodeError) as exc:
            raise AuthError(
                "invalid_token",
                "Oturum anahtarı okunamadı.",
            ) from exc
        if not isinstance(header, dict) or not isinstance(payload, dict):
            raise AuthError(
                "invalid_token",
                "Oturum anahtarı geçersiz.",
            )
        if header.get("alg") != "HS256" or payload.get("iss") != self._issuer:
            raise AuthError("invalid_token", "Oturum anahtarı geçersiz.")
        if payload.get("typ") != expected_type:
            raise AuthError(
                "wrong_token_type",
                "Bu işlem için yanlış oturum anahtarı kullanıldı.",
            )
        try:
            issued_at = datetime.fromtimestamp(int(payload["iat"]), UTC)
            expires_at = datetime.fromtimestamp(int(payload["exp"]), UTC)
            subject = str(payload["sub"])
            jti = str(payload["jti"])
        except (KeyError, TypeError, ValueError, OverflowError) as exc:
            raise AuthError(
                "invalid_token",
                "Oturum alanları eksik veya geçersiz.",
            ) from exc
        if expires_at <= self._clock():
            raise AuthError("token_expired", "Oturum süresi doldu.")
        return TokenClaims(
            subject=subject,
            token_type=expected_type,
            jti=jti,
            issued_at=issued_at,
            expires_at=expires_at,
        )


_ADJECTIVES = (
    "Mavi",
    "Parlak",
    "Sessiz",
    "Hizli",
    "Keskin",
    "Dengeli",
    "Gumus",
    "Neon",
)
_COMPONENTS = (
    "Role",
    "Diyot",
    "Bobin",
    "Devre",
    "Kivilcim",
    "Piksel",
    "Rotor",
    "Sinyal",
)


class AuthService:
    def __init__(
        self,
        database: Database,
        settings: Settings,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
        number_source: Callable[[], int] | None = None,
    ) -> None:
        self.database = database
        self.settings = settings
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)
        self.number_source = number_source or (
            lambda: secrets.randbelow(9000) + 1000
        )
        self.codec = JwtCodec(
            secret=settings.jwt_secret,
            issuer=settings.jwt_issuer,
            clock=self.clock,
        )

    def create_guest(self) -> GuestSession:
        now = self.clock()
        with self.database.session() as session:
            player: PlayerRecord | None = None
            for attempt in range(32):
                adjective = _ADJECTIVES[attempt % len(_ADJECTIVES)]
                component = _COMPONENTS[
                    (attempt // len(_ADJECTIVES)) % len(_COMPONENTS)
                ]
                name = f"{adjective}{component}-{self.number_source():04d}"
                exists = session.scalar(
                    select(PlayerRecord.id).where(
                        PlayerRecord.display_name == name
                    )
                )
                if exists is None:
                    player = PlayerRecord(
                        id=self.id_source(),
                        display_name=name,
                        created_at=now,
                        last_seen_at=now,
                    )
                    session.add(player)
                    session.flush()
                    break
            if player is None:
                raise AuthError(
                    "guest_name_unavailable",
                    "Güvenli misafir adı oluşturulamadı.",
                    status_code=503,
                )
            tokens = self._issue_tokens(session, player.id, now=now)
            return GuestSession(
                player=self._player_view(player),
                tokens=tokens,
            )

    def refresh(self, refresh_token: str) -> GuestSession:
        claims = self.codec.decode(
            refresh_token,
            expected_type="refresh",
        )
        now = self.clock()
        with self.database.session() as session:
            refresh_session = session.get(RefreshSessionRecord, claims.jti)
            if refresh_session is None:
                raise AuthError(
                    "refresh_session_not_found",
                    "Yenileme oturumu bulunamadı.",
                )
            expected_hash = hashlib.sha256(
                refresh_token.encode("utf-8")
            ).hexdigest()
            if not hmac.compare_digest(
                expected_hash,
                refresh_session.token_hash,
            ):
                raise AuthError(
                    "invalid_refresh_token",
                    "Yenileme anahtarı geçersiz.",
                )
            if (
                refresh_session.rotated_at is not None
                or refresh_session.revoked_at is not None
            ):
                raise AuthError(
                    "refresh_token_reused",
                    "Bu yenileme anahtarı daha önce kullanıldı.",
                )
            if self._as_utc(refresh_session.expires_at) <= now:
                raise AuthError(
                    "token_expired",
                    "Yenileme oturumunun süresi doldu.",
                )
            player = session.get(PlayerRecord, claims.subject)
            if player is None or refresh_session.player_id != player.id:
                raise AuthError("player_not_found", "Oyuncu bulunamadı.")
            refresh_session.rotated_at = now
            player.last_seen_at = now
            tokens = self._issue_tokens(
                session,
                player.id,
                now=now,
                family_id=refresh_session.family_id,
            )
            return GuestSession(
                player=self._player_view(player),
                tokens=tokens,
            )

    def authenticate_access(self, access_token: str) -> PlayerView:
        claims = self.codec.decode(access_token, expected_type="access")
        with self.database.session() as session:
            player = session.get(PlayerRecord, claims.subject)
            if player is None:
                raise AuthError("player_not_found", "Oyuncu bulunamadı.")
            player.last_seen_at = self.clock()
            return self._player_view(player)

    def _issue_tokens(
        self,
        session: Any,
        player_id: str,
        *,
        now: datetime,
        family_id: str | None = None,
    ) -> TokenBundle:
        access_jti = self.id_source()
        refresh_jti = self.id_source()
        access_token, _ = self.codec.encode(
            subject=player_id,
            token_type="access",
            jti=access_jti,
            lifetime_seconds=self.settings.access_token_seconds,
        )
        refresh_token, refresh_expires_at = self.codec.encode(
            subject=player_id,
            token_type="refresh",
            jti=refresh_jti,
            lifetime_seconds=self.settings.refresh_token_seconds,
        )
        session.add(
            RefreshSessionRecord(
                jti=refresh_jti,
                family_id=family_id or self.id_source(),
                player_id=player_id,
                token_hash=hashlib.sha256(
                    refresh_token.encode("utf-8")
                ).hexdigest(),
                created_at=now,
                expires_at=refresh_expires_at,
                rotated_at=None,
                revoked_at=None,
            )
        )
        return TokenBundle(
            access_token=access_token,
            refresh_token=refresh_token,
            access_expires_in=self.settings.access_token_seconds,
            refresh_expires_in=self.settings.refresh_token_seconds,
        )

    @staticmethod
    def _player_view(player: PlayerRecord) -> PlayerView:
        return PlayerView(
            player_id=player.id,
            display_name=player.display_name,
            created_at=AuthService._as_utc(player.created_at),
        )

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)
