from __future__ import annotations

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from .database import Database
from .db_models import AlphaFeedbackRecord, PlayerRecord, PlayerSafetyRecord

MATCH_WINDOW = timedelta(minutes=1)
MATCH_REQUEST_LIMIT = 20
FEEDBACK_WINDOW = timedelta(hours=1)
FEEDBACK_REQUEST_LIMIT = 3


class AlphaSafetyError(Exception):
    def __init__(self, code: str, message: str, *, status_code: int = 429) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class AlphaSafetySnapshot:
    match_requests: int
    match_limit: int
    match_window_seconds: int
    feedback_requests: int
    feedback_limit: int
    feedback_window_seconds: int
    blocked_until: datetime | None
    server_authoritative_results: bool = True
    idempotent_rewards: bool = True
    board_validation: bool = True


@dataclass(frozen=True, slots=True)
class FeedbackReceipt:
    feedback_id: str
    category: str
    created_at: datetime


class AlphaSafetyService:
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

    def guard_async_match(self, player_id: str) -> None:
        now = self.clock()
        with self.database.session() as session:
            record = self._record(session, player_id, now)
            blocked_until = _as_utc(record.blocked_until) if record.blocked_until is not None else None
            if blocked_until is not None and blocked_until > now:
                raise AlphaSafetyError(
                    "alpha_temporarily_blocked",
                    "Çok hızlı istek algılandı. Kısa süre sonra yeniden dene.",
                )
            if now - _as_utc(record.match_window_started_at) >= MATCH_WINDOW:
                record.match_window_started_at = now
                record.match_requests = 0
                record.blocked_until = None
            if record.match_requests >= MATCH_REQUEST_LIMIT:
                record.blocked_until = record.match_window_started_at + MATCH_WINDOW
                record.updated_at = now
                raise AlphaSafetyError(
                    "match_rate_limited",
                    "Bir dakika içindeki savaş isteği sınırına ulaşıldı.",
                )
            record.match_requests += 1
            record.updated_at = now

    def submit_feedback(
        self,
        player_id: str,
        *,
        category: str,
        message: str,
        client_version: str,
    ) -> FeedbackReceipt:
        now = self.clock()
        clean_message = message.strip()
        if not clean_message:
            raise AlphaSafetyError(
                "feedback_empty",
                "Geri bildirim metni boş olamaz.",
                status_code=422,
            )
        with self.database.session() as session:
            record = self._record(session, player_id, now)
            if now - _as_utc(record.feedback_window_started_at) >= FEEDBACK_WINDOW:
                record.feedback_window_started_at = now
                record.feedback_requests = 0
            if record.feedback_requests >= FEEDBACK_REQUEST_LIMIT:
                raise AlphaSafetyError(
                    "feedback_rate_limited",
                    "Bir saat içindeki geri bildirim sınırına ulaşıldı.",
                )
            feedback_id = self.id_source()
            session.add(
                AlphaFeedbackRecord(
                    id=feedback_id,
                    player_id=player_id,
                    category=category,
                    message=clean_message,
                    client_version=client_version,
                    created_at=now,
                )
            )
            record.feedback_requests += 1
            record.updated_at = now
            return FeedbackReceipt(feedback_id, category, now)

    def snapshot(self, player_id: str) -> AlphaSafetySnapshot:
        now = self.clock()
        with self.database.session() as session:
            record = self._record(session, player_id, now)
            match_requests = record.match_requests
            feedback_requests = record.feedback_requests
            if now - _as_utc(record.match_window_started_at) >= MATCH_WINDOW:
                match_requests = 0
            if now - _as_utc(record.feedback_window_started_at) >= FEEDBACK_WINDOW:
                feedback_requests = 0
            return AlphaSafetySnapshot(
                match_requests=match_requests,
                match_limit=MATCH_REQUEST_LIMIT,
                match_window_seconds=int(MATCH_WINDOW.total_seconds()),
                feedback_requests=feedback_requests,
                feedback_limit=FEEDBACK_REQUEST_LIMIT,
                feedback_window_seconds=int(FEEDBACK_WINDOW.total_seconds()),
                blocked_until=record.blocked_until,
            )

    @staticmethod
    def _record(session, player_id: str, now: datetime) -> PlayerSafetyRecord:
        if session.get(PlayerRecord, player_id) is None:
            raise LookupError("Oyuncu bulunamadı.")
        record = session.scalar(
            select(PlayerSafetyRecord)
            .where(PlayerSafetyRecord.player_id == player_id)
            .with_for_update()
        )
        if record is None:
            record = PlayerSafetyRecord(
                player_id=player_id,
                match_window_started_at=now,
                match_requests=0,
                feedback_window_started_at=now,
                feedback_requests=0,
                blocked_until=None,
                updated_at=now,
            )
            session.add(record)
            session.flush()
        return record


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
