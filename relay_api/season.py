from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Literal

from sqlalchemy import desc, select

from .database import Database
from .db_models import (
    MatchRecord,
    PlayerRecord,
    SeasonEntryRecord,
    SeasonMatchRecord,
)
from .progression import ProgressionService, RewardGrant
from .store import StoredMatch

Outcome = Literal["win", "draw", "loss"]
SEASON_WIN_POINTS = 5
SEASON_DRAW_POINTS = 3
SEASON_LOSS_POINTS = 1
MAX_SEASON_LEADERBOARD = 100


@dataclass(frozen=True, slots=True)
class SeasonWindow:
    key: str
    title: str
    starts_at: datetime
    ends_at: datetime


@dataclass(frozen=True, slots=True)
class SeasonTierDefinition:
    tier: int
    required_points: int
    reward_xp: int
    reward_credits: int
    title: str


SEASON_TIERS: tuple[SeasonTierDefinition, ...] = (
    SeasonTierDefinition(1, 8, 20, 8, "İlk Devre"),
    SeasonTierDefinition(2, 18, 28, 10, "Kıvılcım"),
    SeasonTierDefinition(3, 30, 36, 14, "Kararlı Akım"),
    SeasonTierDefinition(4, 45, 48, 18, "Bağlantı Ustası"),
    SeasonTierDefinition(5, 62, 60, 24, "Yüksek Gerilim"),
    SeasonTierDefinition(6, 82, 75, 30, "Çekirdek Muhafızı"),
    SeasonTierDefinition(7, 105, 90, 38, "Sinyal Avcısı"),
    SeasonTierDefinition(8, 132, 110, 46, "Devre Komutanı"),
    SeasonTierDefinition(9, 162, 135, 58, "Alfa Şampiyonu"),
    SeasonTierDefinition(10, 200, 175, 75, "Sezon Çekirdeği"),
    SeasonTierDefinition(11, 235, 190, 82, "Güç Hattı"),
    SeasonTierDefinition(12, 272, 210, 90, "Senkron Darbe"),
    SeasonTierDefinition(13, 312, 235, 100, "Enerji Muhafızı"),
    SeasonTierDefinition(14, 355, 260, 112, "Taktik Ustası"),
    SeasonTierDefinition(15, 402, 290, 125, "İleri Devre"),
    SeasonTierDefinition(16, 452, 325, 140, "Rekabet Çekirdeği"),
    SeasonTierDefinition(17, 506, 365, 158, "Yüksek Sinyal"),
    SeasonTierDefinition(18, 565, 410, 178, "Elit Frekans"),
    SeasonTierDefinition(19, 630, 470, 205, "Sezon Öncüsü"),
    SeasonTierDefinition(20, 700, 560, 250, "Sezon Şampiyonu"),
)


class SeasonError(Exception):
    def __init__(self, code: str, message: str, *, status_code: int = 409) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class SeasonEntry:
    season_key: str
    points: int
    matches: int
    wins: int
    draws: int
    losses: int
    position: int
    participant_count: int
    claimed_tiers: tuple[int, ...]


@dataclass(frozen=True, slots=True)
class SeasonTier:
    tier: int
    title: str
    required_points: int
    reward_xp: int
    reward_credits: int
    unlocked: bool
    claimed: bool


@dataclass(frozen=True, slots=True)
class SeasonStanding:
    position: int
    player_id: str
    display_name: str
    points: int
    wins: int
    matches: int
    is_current_player: bool


@dataclass(frozen=True, slots=True)
class SeasonSnapshot:
    window: SeasonWindow
    entry: SeasonEntry
    tiers: tuple[SeasonTier, ...]
    leaderboard: tuple[SeasonStanding, ...]


@dataclass(frozen=True, slots=True)
class SeasonPointChange:
    season_key: str
    outcome: Outcome
    points_gained: int
    total_points: int


def season_window(moment: datetime) -> SeasonWindow:
    value = _as_utc(moment)
    starts_at = value.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    if starts_at.month == 12:
        ends_at = starts_at.replace(year=starts_at.year + 1, month=1)
    else:
        ends_at = starts_at.replace(month=starts_at.month + 1)
    return SeasonWindow(
        key=f"{starts_at.year}-{starts_at.month:02d}",
        title=f"SEZON {starts_at.year}.{starts_at.month:02d}",
        starts_at=starts_at,
        ends_at=ends_at,
    )


class SeasonService:
    def __init__(
        self,
        database: Database,
        progression: ProgressionService,
        *,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self.database = database
        self.progression = progression
        self.clock = clock or (lambda: datetime.now(UTC))

    def record_match(self, match: StoredMatch) -> SeasonPointChange | None:
        if (
            match.source != "async"
            or match.requester_player_id is None
            or match.opponent_player_id is None
            or match.opponent.kind != "player"
        ):
            return None
        with self.database.session() as session:
            persisted = session.get(MatchRecord, match.match_id)
            if persisted is None:
                raise LookupError("Sezon puanı verilecek maç bulunamadı.")
            if session.get(SeasonMatchRecord, match.match_id) is not None:
                return None
            window = season_window(match.created_at)
            requester_outcome, opponent_outcome = _outcomes(match)
            requester_points = _points(requester_outcome)
            opponent_points = _points(opponent_outcome)
            now = self.clock()
            requester = self._entry(
                session, window.key, match.requester_player_id, now
            )
            opponent = self._entry(
                session, window.key, match.opponent_player_id, now
            )
            self._record(requester, requester_outcome, requester_points, now)
            self._record(opponent, opponent_outcome, opponent_points, now)
            session.add(
                SeasonMatchRecord(
                    match_id=match.match_id,
                    season_key=window.key,
                    requester_player_id=match.requester_player_id,
                    opponent_player_id=match.opponent_player_id,
                    requester_points=requester_points,
                    opponent_points=opponent_points,
                    recorded_at=now,
                )
            )
            session.flush()
            return SeasonPointChange(
                season_key=window.key,
                outcome=requester_outcome,
                points_gained=requester_points,
                total_points=requester.points,
            )

    def snapshot(self, player_id: str, *, limit: int = 20) -> SeasonSnapshot:
        limit = max(1, min(limit, MAX_SEASON_LEADERBOARD))
        now = self.clock()
        window = season_window(now)
        with self.database.session() as session:
            if session.get(PlayerRecord, player_id) is None:
                raise LookupError("Oyuncu bulunamadı.")
            record = session.get(SeasonEntryRecord, (window.key, player_id))
            rows = list(
                session.execute(
                    select(SeasonEntryRecord, PlayerRecord)
                    .join(PlayerRecord, PlayerRecord.id == SeasonEntryRecord.player_id)
                    .where(SeasonEntryRecord.season_key == window.key)
                    .order_by(
                        desc(SeasonEntryRecord.points),
                        desc(SeasonEntryRecord.wins),
                        SeasonEntryRecord.updated_at,
                        SeasonEntryRecord.player_id,
                    )
                )
            )
            position = 0
            standings: list[SeasonStanding] = []
            for index, (entry, player) in enumerate(rows, start=1):
                if entry.player_id == player_id:
                    position = index
                if index <= limit:
                    standings.append(
                        SeasonStanding(
                            position=index,
                            player_id=entry.player_id,
                            display_name=player.display_name,
                            points=entry.points,
                            wins=entry.wins,
                            matches=entry.matches,
                            is_current_player=entry.player_id == player_id,
                        )
                    )
            points = record.points if record is not None else 0
            claimed = tuple(sorted(record.claimed_tiers or [])) if record else ()
            entry = SeasonEntry(
                season_key=window.key,
                points=points,
                matches=record.matches if record else 0,
                wins=record.wins if record else 0,
                draws=record.draws if record else 0,
                losses=record.losses if record else 0,
                position=position,
                participant_count=len(rows),
                claimed_tiers=claimed,
            )
            return SeasonSnapshot(
                window=window,
                entry=entry,
                tiers=tuple(
                    SeasonTier(
                        tier=item.tier,
                        title=item.title,
                        required_points=item.required_points,
                        reward_xp=item.reward_xp,
                        reward_credits=item.reward_credits,
                        unlocked=points >= item.required_points,
                        claimed=item.tier in claimed,
                    )
                    for item in SEASON_TIERS
                ),
                leaderboard=tuple(standings),
            )

    def claim_tier(self, player_id: str, tier: int) -> RewardGrant:
        definition = next((item for item in SEASON_TIERS if item.tier == tier), None)
        if definition is None:
            raise SeasonError("season_tier_not_found", "Sezon kademesi bulunamadı.", status_code=404)
        window = season_window(self.clock())
        with self.database.session() as session:
            record = session.scalar(
                select(SeasonEntryRecord)
                .where(
                    SeasonEntryRecord.season_key == window.key,
                    SeasonEntryRecord.player_id == player_id,
                )
                .with_for_update()
            )
            if record is None or record.points < definition.required_points:
                raise SeasonError("season_tier_locked", "Bu sezon kademesi henüz açılmadı.")
            claimed = set(record.claimed_tiers or [])
            already_claimed = tier in claimed
        reward = self.progression.grant_external_reward(
            player_id,
            source_type="season_tier",
            source_id=f"{window.key}:{tier}",
            reason=f"{window.title}: {definition.title}",
            xp=definition.reward_xp,
            credits=definition.reward_credits,
        )
        if not already_claimed:
            with self.database.session() as session:
                record = session.scalar(
                    select(SeasonEntryRecord)
                    .where(
                        SeasonEntryRecord.season_key == window.key,
                        SeasonEntryRecord.player_id == player_id,
                    )
                    .with_for_update()
                )
                if record is None:
                    raise SeasonError("season_entry_missing", "Sezon kaydı bulunamadı.")
                claimed = set(record.claimed_tiers or [])
                claimed.add(tier)
                record.claimed_tiers = sorted(claimed)
                record.updated_at = self.clock()
        return reward

    @staticmethod
    def _entry(session, season_key: str, player_id: str, now: datetime) -> SeasonEntryRecord:
        record = session.scalar(
            select(SeasonEntryRecord)
            .where(
                SeasonEntryRecord.season_key == season_key,
                SeasonEntryRecord.player_id == player_id,
            )
            .with_for_update()
        )
        if record is None:
            record = SeasonEntryRecord(
                season_key=season_key,
                player_id=player_id,
                points=0,
                matches=0,
                wins=0,
                draws=0,
                losses=0,
                claimed_tiers=[],
                created_at=now,
                updated_at=now,
            )
            session.add(record)
            session.flush()
        return record

    @staticmethod
    def _record(record: SeasonEntryRecord, outcome: Outcome, points: int, now: datetime) -> None:
        record.points += points
        record.matches += 1
        if outcome == "win":
            record.wins += 1
        elif outcome == "draw":
            record.draws += 1
        else:
            record.losses += 1
        record.updated_at = now


def _outcomes(match: StoredMatch) -> tuple[Outcome, Outcome]:
    winner = match.result.get("winner")
    if winner is None:
        return "draw", "draw"
    if winner == "left":
        return "win", "loss"
    if winner == "right":
        return "loss", "win"
    raise ValueError(f"Bilinmeyen savaş kazananı: {winner}")


def _points(outcome: Outcome) -> int:
    return {
        "win": SEASON_WIN_POINTS,
        "draw": SEASON_DRAW_POINTS,
        "loss": SEASON_LOSS_POINTS,
    }[outcome]


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
