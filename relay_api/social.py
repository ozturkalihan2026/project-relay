from __future__ import annotations

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import and_, func, or_, select
from sqlalchemy.exc import IntegrityError

from .database import Database
from .db_models import (
    ClanMemberRecord,
    ClanRecord,
    FriendRequestRecord,
    PlayerRecord,
    PlayerSocialProfileRecord,
)

DEFAULT_STATUS = "Devresini geliştiriyor."
DEFAULT_FAVORITE_MODULE = "generator"
MAX_CLAN_MEMBERS = 20


class SocialError(Exception):
    def __init__(self, code: str, message: str, *, status_code: int = 409) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class SocialPlayer:
    player_id: str
    display_name: str
    status_message: str
    favorite_module: str
    relationship: str


@dataclass(frozen=True, slots=True)
class FriendRequestView:
    request_id: str
    player: SocialPlayer
    created_at: datetime


@dataclass(frozen=True, slots=True)
class ClanMemberView:
    player_id: str
    display_name: str
    role: str
    joined_at: datetime
    is_current_player: bool


@dataclass(frozen=True, slots=True)
class ClanView:
    clan_id: str
    name: str
    tag: str
    description: str
    leader_player_id: str
    is_open: bool
    member_count: int
    members: tuple[ClanMemberView, ...]


@dataclass(frozen=True, slots=True)
class SocialProfileView:
    player_id: str
    display_name: str
    status_message: str
    favorite_module: str
    friend_count: int


@dataclass(frozen=True, slots=True)
class SocialSnapshot:
    profile: SocialProfileView
    incoming_requests: tuple[FriendRequestView, ...]
    outgoing_requests: tuple[FriendRequestView, ...]
    friends: tuple[SocialPlayer, ...]
    clan: ClanView | None


class SocialService:
    def __init__(
        self,
        database: Database,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
    ) -> None:
        self.database = database
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)

    def snapshot(self, player_id: str) -> SocialSnapshot:
        with self.database.session() as session:
            player = session.get(PlayerRecord, player_id)
            if player is None:
                raise SocialError("player_not_found", "Oyuncu bulunamadı.", status_code=404)
            profile = self._profile(session, player_id)
            accepted = list(
                session.scalars(
                    select(FriendRequestRecord).where(
                        and_(
                            FriendRequestRecord.status == "accepted",
                            or_(
                                FriendRequestRecord.sender_player_id == player_id,
                                FriendRequestRecord.receiver_player_id == player_id,
                            ),
                        )
                    )
                )
            )
            friend_ids = [
                item.receiver_player_id
                if item.sender_player_id == player_id
                else item.sender_player_id
                for item in accepted
            ]
            friends = tuple(
                self._player_view(session, friend_id, relationship="friend")
                for friend_id in sorted(
                    friend_ids,
                    key=lambda value: session.get(PlayerRecord, value).display_name.lower(),
                )
            )
            incoming_records = list(
                session.scalars(
                    select(FriendRequestRecord)
                    .where(
                        FriendRequestRecord.receiver_player_id == player_id,
                        FriendRequestRecord.status == "pending",
                    )
                    .order_by(FriendRequestRecord.created_at.desc())
                )
            )
            outgoing_records = list(
                session.scalars(
                    select(FriendRequestRecord)
                    .where(
                        FriendRequestRecord.sender_player_id == player_id,
                        FriendRequestRecord.status == "pending",
                    )
                    .order_by(FriendRequestRecord.created_at.desc())
                )
            )
            membership = session.scalar(
                select(ClanMemberRecord).where(ClanMemberRecord.player_id == player_id)
            )
            clan = (
                self._clan_view(session, membership.clan_id, player_id)
                if membership is not None
                else None
            )
            return SocialSnapshot(
                profile=SocialProfileView(
                    player_id=player.id,
                    display_name=player.display_name,
                    status_message=profile.status_message,
                    favorite_module=profile.favorite_module,
                    friend_count=len(friends),
                ),
                incoming_requests=tuple(
                    FriendRequestView(
                        request_id=item.id,
                        player=self._player_view(
                            session, item.sender_player_id, relationship="incoming"
                        ),
                        created_at=item.created_at,
                    )
                    for item in incoming_records
                ),
                outgoing_requests=tuple(
                    FriendRequestView(
                        request_id=item.id,
                        player=self._player_view(
                            session, item.receiver_player_id, relationship="outgoing"
                        ),
                        created_at=item.created_at,
                    )
                    for item in outgoing_records
                ),
                friends=friends,
                clan=clan,
            )

    def update_profile(
        self,
        player_id: str,
        *,
        status_message: str,
        favorite_module: str,
    ) -> SocialSnapshot:
        status_value = status_message.strip()
        module_value = favorite_module.strip().lower()
        if not 1 <= len(status_value) <= 160:
            raise SocialError("invalid_status", "Durum mesajı 1-160 karakter olmalıdır.")
        allowed_modules = {
            "generator",
            "battery",
            "laser",
            "pulse_cannon",
            "shield",
            "cooler",
            "amplifier",
            "repair",
        }
        if module_value not in allowed_modules:
            raise SocialError("invalid_favorite_module", "Favori modül geçersiz.")
        with self.database.session() as session:
            profile = self._profile(session, player_id)
            profile.status_message = status_value
            profile.favorite_module = module_value
            profile.updated_at = self.clock()
        return self.snapshot(player_id)

    def search_players(self, player_id: str, query: str, *, limit: int = 20) -> tuple[SocialPlayer, ...]:
        value = query.strip()
        if len(value) < 2:
            raise SocialError("search_too_short", "Arama için en az 2 karakter yazın.")
        with self.database.session() as session:
            rows = list(
                session.scalars(
                    select(PlayerRecord)
                    .where(
                        PlayerRecord.id != player_id,
                        PlayerRecord.display_name.ilike(f"%{value}%"),
                    )
                    .order_by(PlayerRecord.display_name.asc())
                    .limit(min(max(limit, 1), 30))
                )
            )
            return tuple(
                self._player_view(
                    session,
                    row.id,
                    relationship=self._relationship(session, player_id, row.id),
                )
                for row in rows
            )

    def send_friend_request(self, player_id: str, target_player_id: str) -> SocialSnapshot:
        if player_id == target_player_id:
            raise SocialError("self_friend_request", "Kendinize arkadaşlık isteği gönderemezsiniz.")
        now = self.clock()
        with self.database.session() as session:
            if session.get(PlayerRecord, target_player_id) is None:
                raise SocialError("player_not_found", "Oyuncu bulunamadı.", status_code=404)
            existing = session.scalar(
                select(FriendRequestRecord).where(
                    or_(
                        and_(
                            FriendRequestRecord.sender_player_id == player_id,
                            FriendRequestRecord.receiver_player_id == target_player_id,
                        ),
                        and_(
                            FriendRequestRecord.sender_player_id == target_player_id,
                            FriendRequestRecord.receiver_player_id == player_id,
                        ),
                    )
                )
            )
            if existing is not None:
                if existing.status == "accepted":
                    raise SocialError("already_friends", "Bu oyuncu zaten arkadaşınız.")
                if existing.status == "pending":
                    raise SocialError("request_exists", "Bu oyuncuyla bekleyen bir istek var.")
                existing.sender_player_id = player_id
                existing.receiver_player_id = target_player_id
                existing.status = "pending"
                existing.updated_at = now
            else:
                session.add(
                    FriendRequestRecord(
                        id=self.id_source(),
                        sender_player_id=player_id,
                        receiver_player_id=target_player_id,
                        status="pending",
                        created_at=now,
                        updated_at=now,
                    )
                )
        return self.snapshot(player_id)

    def respond_friend_request(self, player_id: str, request_id: str, *, accept: bool) -> SocialSnapshot:
        with self.database.session() as session:
            request = session.get(FriendRequestRecord, request_id)
            if request is None or request.receiver_player_id != player_id:
                raise SocialError("friend_request_not_found", "Arkadaşlık isteği bulunamadı.", status_code=404)
            if request.status != "pending":
                raise SocialError("friend_request_closed", "Bu istek daha önce sonuçlandırılmış.")
            request.status = "accepted" if accept else "declined"
            request.updated_at = self.clock()
        return self.snapshot(player_id)

    def remove_friend(self, player_id: str, friend_player_id: str) -> SocialSnapshot:
        with self.database.session() as session:
            request = session.scalar(
                select(FriendRequestRecord).where(
                    FriendRequestRecord.status == "accepted",
                    or_(
                        and_(
                            FriendRequestRecord.sender_player_id == player_id,
                            FriendRequestRecord.receiver_player_id == friend_player_id,
                        ),
                        and_(
                            FriendRequestRecord.sender_player_id == friend_player_id,
                            FriendRequestRecord.receiver_player_id == player_id,
                        ),
                    ),
                )
            )
            if request is None:
                raise SocialError("friend_not_found", "Arkadaşlık kaydı bulunamadı.", status_code=404)
            session.delete(request)
        return self.snapshot(player_id)

    def list_clans(self, player_id: str, *, limit: int = 30) -> tuple[ClanView, ...]:
        with self.database.session() as session:
            clan_ids = list(
                session.scalars(
                    select(ClanRecord.id)
                    .where(ClanRecord.is_open.is_(True))
                    .order_by(ClanRecord.updated_at.desc())
                    .limit(min(max(limit, 1), 50))
                )
            )
            return tuple(self._clan_view(session, clan_id, player_id) for clan_id in clan_ids)

    def create_clan(
        self,
        player_id: str,
        *,
        name: str,
        tag: str,
        description: str,
    ) -> SocialSnapshot:
        name_value = name.strip()
        tag_value = tag.strip().upper()
        description_value = description.strip()
        if not 3 <= len(name_value) <= 48:
            raise SocialError("invalid_clan_name", "Klan adı 3-48 karakter olmalıdır.")
        if not 2 <= len(tag_value) <= 8 or not tag_value.replace("_", "").isalnum():
            raise SocialError("invalid_clan_tag", "Klan etiketi 2-8 harf veya rakam olmalıdır.")
        if not 3 <= len(description_value) <= 240:
            raise SocialError("invalid_clan_description", "Klan açıklaması 3-240 karakter olmalıdır.")
        now = self.clock()
        try:
            with self.database.session() as session:
                if session.scalar(
                    select(ClanMemberRecord).where(ClanMemberRecord.player_id == player_id)
                ) is not None:
                    raise SocialError("already_in_clan", "Önce mevcut klanınızdan ayrılmalısınız.")
                clan = ClanRecord(
                    id=self.id_source(),
                    name=name_value,
                    tag=tag_value,
                    description=description_value,
                    leader_player_id=player_id,
                    is_open=True,
                    created_at=now,
                    updated_at=now,
                )
                session.add(clan)
                session.flush()
                session.add(
                    ClanMemberRecord(
                        clan_id=clan.id,
                        player_id=player_id,
                        role="leader",
                        joined_at=now,
                    )
                )
        except IntegrityError as exc:
            raise SocialError("clan_name_taken", "Klan adı veya etiketi kullanımda.") from exc
        return self.snapshot(player_id)

    def join_clan(self, player_id: str, clan_id: str) -> SocialSnapshot:
        now = self.clock()
        with self.database.session() as session:
            if session.scalar(
                select(ClanMemberRecord).where(ClanMemberRecord.player_id == player_id)
            ) is not None:
                raise SocialError("already_in_clan", "Zaten bir klana üyesiniz.")
            clan = session.get(ClanRecord, clan_id)
            if clan is None:
                raise SocialError("clan_not_found", "Klan bulunamadı.", status_code=404)
            if not clan.is_open:
                raise SocialError("clan_closed", "Bu klan yeni üye kabul etmiyor.")
            member_count = session.scalar(
                select(func.count()).select_from(ClanMemberRecord).where(
                    ClanMemberRecord.clan_id == clan_id
                )
            ) or 0
            if member_count >= MAX_CLAN_MEMBERS:
                raise SocialError("clan_full", "Klan üye sınırına ulaştı.")
            session.add(
                ClanMemberRecord(
                    clan_id=clan_id,
                    player_id=player_id,
                    role="member",
                    joined_at=now,
                )
            )
            clan.updated_at = now
        return self.snapshot(player_id)

    def leave_clan(self, player_id: str) -> SocialSnapshot:
        with self.database.session() as session:
            membership = session.scalar(
                select(ClanMemberRecord).where(ClanMemberRecord.player_id == player_id)
            )
            if membership is None:
                raise SocialError("not_in_clan", "Bir klana üye değilsiniz.", status_code=404)
            clan = session.get(ClanRecord, membership.clan_id)
            if clan is None:
                session.delete(membership)
            elif membership.role == "leader":
                member_count = session.scalar(
                    select(func.count()).select_from(ClanMemberRecord).where(
                        ClanMemberRecord.clan_id == clan.id
                    )
                ) or 0
                if member_count > 1:
                    raise SocialError(
                        "leader_cannot_leave",
                        "Lider, klanı başka üyeler varken terk edemez.",
                    )
                session.delete(membership)
                session.flush()
                session.delete(clan)
            else:
                session.delete(membership)
                clan.updated_at = self.clock()
        return self.snapshot(player_id)

    def _profile(self, session, player_id: str) -> PlayerSocialProfileRecord:
        if session.get(PlayerRecord, player_id) is None:
            raise SocialError("player_not_found", "Oyuncu bulunamadı.", status_code=404)
        record = session.get(PlayerSocialProfileRecord, player_id)
        if record is None:
            record = PlayerSocialProfileRecord(
                player_id=player_id,
                status_message=DEFAULT_STATUS,
                favorite_module=DEFAULT_FAVORITE_MODULE,
                updated_at=self.clock(),
            )
            session.add(record)
            session.flush()
        return record

    def _player_view(self, session, player_id: str, *, relationship: str) -> SocialPlayer:
        player = session.get(PlayerRecord, player_id)
        if player is None:
            raise SocialError("player_not_found", "Oyuncu bulunamadı.", status_code=404)
        profile = self._profile(session, player_id)
        return SocialPlayer(
            player_id=player.id,
            display_name=player.display_name,
            status_message=profile.status_message,
            favorite_module=profile.favorite_module,
            relationship=relationship,
        )

    @staticmethod
    def _relationship(session, player_id: str, other_id: str) -> str:
        request = session.scalar(
            select(FriendRequestRecord).where(
                or_(
                    and_(
                        FriendRequestRecord.sender_player_id == player_id,
                        FriendRequestRecord.receiver_player_id == other_id,
                    ),
                    and_(
                        FriendRequestRecord.sender_player_id == other_id,
                        FriendRequestRecord.receiver_player_id == player_id,
                    ),
                )
            )
        )
        if request is None or request.status == "declined":
            return "none"
        if request.status == "accepted":
            return "friend"
        return "outgoing" if request.sender_player_id == player_id else "incoming"

    def _clan_view(self, session, clan_id: str, viewer_player_id: str) -> ClanView:
        clan = session.get(ClanRecord, clan_id)
        if clan is None:
            raise SocialError("clan_not_found", "Klan bulunamadı.", status_code=404)
        memberships = list(
            session.scalars(
                select(ClanMemberRecord)
                .where(ClanMemberRecord.clan_id == clan_id)
                .order_by(ClanMemberRecord.role.desc(), ClanMemberRecord.joined_at.asc())
            )
        )
        members = tuple(
            ClanMemberView(
                player_id=item.player_id,
                display_name=session.get(PlayerRecord, item.player_id).display_name,
                role=item.role,
                joined_at=item.joined_at,
                is_current_player=item.player_id == viewer_player_id,
            )
            for item in memberships
        )
        return ClanView(
            clan_id=clan.id,
            name=clan.name,
            tag=clan.tag,
            description=clan.description,
            leader_player_id=clan.leader_player_id,
            is_open=clan.is_open,
            member_count=len(members),
            members=members,
        )
