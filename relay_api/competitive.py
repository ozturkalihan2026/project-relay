from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from collections.abc import Callable
from typing import Literal

from sqlalchemy import desc, func, or_, select
from sqlalchemy.orm import Session

from .database import Database
from .db_models import (
    LeagueEntryRecord,
    MatchRatingRecord,
    MatchRecord,
    PlayerRatingRecord,
    PlayerRecord,
)
from .store import StoredMatch

DEFAULT_RATING = 1000
ELO_K_FACTOR = 32
LEAGUE_WIN_POINTS = 3
LEAGUE_DRAW_POINTS = 1
MAX_HISTORY_LIMIT = 50
MAX_LEADERBOARD_LIMIT = 100

Outcome = Literal["win", "draw", "loss"]


@dataclass(frozen=True, slots=True)
class LeagueWindow:
    key: str
    starts_at: datetime
    ends_at: datetime


@dataclass(frozen=True, slots=True)
class MatchRatingChange:
    match_id: str
    week_key: str
    requester_player_id: str
    opponent_player_id: str
    outcome: str
    requester_rating_before: int
    requester_rating_after: int
    requester_delta: int
    opponent_rating_before: int
    opponent_rating_after: int
    opponent_delta: int
    applied_at: datetime

    def perspective(self, player_id: str) -> dict[str, int | str]:
        if player_id == self.requester_player_id:
            return {
                "outcome": self.outcome,
                "rating_before": self.requester_rating_before,
                "rating_after": self.requester_rating_after,
                "rating_delta": self.requester_delta,
            }
        if player_id == self.opponent_player_id:
            outcome = {
                "win": "loss",
                "loss": "win",
                "draw": "draw",
            }[self.outcome]
            return {
                "outcome": outcome,
                "rating_before": self.opponent_rating_before,
                "rating_after": self.opponent_rating_after,
                "rating_delta": self.opponent_delta,
            }
        raise ValueError("Oyuncu bu dereceli maçın katılımcısı değildir.")


@dataclass(frozen=True, slots=True)
class RatingProfile:
    player_id: str
    rating: int
    peak_rating: int
    rated_matches: int
    wins: int
    draws: int
    losses: int

    @property
    def win_rate(self) -> float:
        if self.rated_matches == 0:
            return 0.0
        return self.wins / self.rated_matches


@dataclass(frozen=True, slots=True)
class LeagueEntry:
    week_key: str
    starts_at: datetime
    ends_at: datetime
    points: int
    wins: int
    draws: int
    losses: int
    position: int
    participant_count: int


@dataclass(frozen=True, slots=True)
class LeagueStanding:
    position: int
    player_id: str
    display_name: str
    points: int
    wins: int
    draws: int
    losses: int
    rating: int
    is_current_player: bool


@dataclass(frozen=True, slots=True)
class MatchHistoryItem:
    match_id: str
    created_at: datetime
    opponent_kind: str
    opponent_name: str
    outcome: Outcome
    rated: bool
    rating_delta: int
    rating_after: int | None
    reason: str
    replay_path: str


@dataclass(frozen=True, slots=True)
class MatchmakingMetrics:
    searches: int
    human_opponents: int
    bot_fallbacks: int

    @property
    def human_opponent_rate(self) -> float:
        if self.searches == 0:
            return 0.0
        return self.human_opponents / self.searches


@dataclass(frozen=True, slots=True)
class CareerSnapshot:
    profile: RatingProfile
    league: LeagueEntry
    leaderboard: tuple[LeagueStanding, ...]
    recent_matches: tuple[MatchHistoryItem, ...]
    matchmaking: MatchmakingMetrics


@dataclass(frozen=True, slots=True)
class MatchHistoryPage:
    items: tuple[MatchHistoryItem, ...]
    total: int
    limit: int
    offset: int


def league_window(moment: datetime) -> LeagueWindow:
    value = _as_utc(moment)
    starts_at = (value - timedelta(days=value.weekday())).replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )
    iso = starts_at.isocalendar()
    return LeagueWindow(
        key=f"{iso.year}-W{iso.week:02d}",
        starts_at=starts_at,
        ends_at=starts_at + timedelta(days=7),
    )


def calculate_elo_delta(
    player_rating: int,
    opponent_rating: int,
    *,
    won: bool,
    k_factor: int = ELO_K_FACTOR,
) -> int:
    """Return a conserved ELO-style delta for a decisive result.

    Exact battle draws are intentionally handled outside this function and
    never change either player's rating, matching the product fairness rule.
    """

    expected = 1 / (1 + 10 ** ((opponent_rating - player_rating) / 400))
    score = 1.0 if won else 0.0
    raw = k_factor * (score - expected)
    rounded = _round_half_away_from_zero(raw)
    if won:
        return max(1, rounded)
    return min(-1, rounded)


class CompetitiveService:
    def __init__(
        self,
        database: Database,
        *,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self.database = database
        self.clock = clock or (lambda: datetime.now(UTC))

    def apply_match(self, match: StoredMatch) -> MatchRatingChange | None:
        if (
            match.source != "async"
            or match.requester_player_id is None
            or match.opponent_player_id is None
            or match.opponent.kind != "player"
        ):
            return None

        with self.database.session() as session:
            persisted_match = session.scalar(
                select(MatchRecord)
                .where(MatchRecord.id == match.match_id)
                .with_for_update()
            )
            if persisted_match is None:
                raise LookupError("Derecelendirilecek maç veritabanında yok.")
            existing = session.get(MatchRatingRecord, match.match_id)
            if existing is not None:
                return self._rating_change(existing)

            player_ids = sorted(
                [match.requester_player_id, match.opponent_player_id]
            )
            locked_players = list(
                session.scalars(
                    select(PlayerRecord)
                    .where(PlayerRecord.id.in_(player_ids))
                    .order_by(PlayerRecord.id)
                    .with_for_update()
                )
            )
            if len(locked_players) != 2:
                raise LookupError("Dereceli maç katılımcısı bulunamadı.")

            requester = self._rating_record(
                session,
                match.requester_player_id,
                match.created_at,
            )
            opponent = self._rating_record(
                session,
                match.opponent_player_id,
                match.created_at,
            )
            requester_before = requester.rating
            opponent_before = opponent.rating
            winner = match.result.get("winner")
            if winner is None:
                outcome: Outcome = "draw"
                requester_delta = 0
            elif winner == "left":
                outcome = "win"
                requester_delta = calculate_elo_delta(
                    requester_before,
                    opponent_before,
                    won=True,
                )
            elif winner == "right":
                outcome = "loss"
                requester_delta = calculate_elo_delta(
                    requester_before,
                    opponent_before,
                    won=False,
                )
            else:
                raise ValueError(f"Bilinmeyen savaş kazananı: {winner}")
            opponent_delta = -requester_delta

            requester.rating += requester_delta
            opponent.rating += opponent_delta
            requester.peak_rating = max(
                requester.peak_rating,
                requester.rating,
            )
            opponent.peak_rating = max(opponent.peak_rating, opponent.rating)
            self._record_result(requester, outcome)
            self._record_result(
                opponent,
                {"win": "loss", "loss": "win", "draw": "draw"}[outcome],
            )
            applied_at = self.clock()
            requester.updated_at = applied_at
            opponent.updated_at = applied_at

            window = league_window(match.created_at)
            requester_league = self._league_record(
                session,
                window,
                requester,
                requester_before,
                match.created_at,
            )
            opponent_league = self._league_record(
                session,
                window,
                opponent,
                opponent_before,
                match.created_at,
            )
            self._record_league_result(
                requester_league,
                outcome,
                requester.rating,
                applied_at,
            )
            self._record_league_result(
                opponent_league,
                {"win": "loss", "loss": "win", "draw": "draw"}[outcome],
                opponent.rating,
                applied_at,
            )

            record = MatchRatingRecord(
                match_id=match.match_id,
                week_key=window.key,
                requester_player_id=match.requester_player_id,
                opponent_player_id=match.opponent_player_id,
                outcome=outcome,
                requester_rating_before=requester_before,
                requester_rating_after=requester.rating,
                requester_delta=requester_delta,
                opponent_rating_before=opponent_before,
                opponent_rating_after=opponent.rating,
                opponent_delta=opponent_delta,
                applied_at=applied_at,
            )
            session.add(record)
            session.flush()
            return self._rating_change(record)

    def get_match_rating(self, match_id: str) -> MatchRatingChange | None:
        with self.database.session() as session:
            record = session.get(MatchRatingRecord, match_id)
            return self._rating_change(record) if record is not None else None

    def career(
        self,
        player_id: str,
        *,
        history_limit: int = 10,
        leaderboard_limit: int = 20,
    ) -> CareerSnapshot:
        history_limit = max(1, min(history_limit, MAX_HISTORY_LIMIT))
        leaderboard_limit = max(
            1,
            min(leaderboard_limit, MAX_LEADERBOARD_LIMIT),
        )
        now = self.clock()
        window = league_window(now)
        with self.database.session() as session:
            player = session.get(PlayerRecord, player_id)
            if player is None:
                raise LookupError("Oyuncu bulunamadı.")
            rating = self._rating_record(session, player_id, now)
            entry = session.scalar(
                select(LeagueEntryRecord).where(
                    LeagueEntryRecord.week_key == window.key,
                    LeagueEntryRecord.player_id == player_id,
                )
            )
            standings, position, participant_count = self._leaderboard(
                session,
                window,
                player_id,
                leaderboard_limit,
            )
            recent = self._history_items(
                session,
                player_id,
                limit=history_limit,
                offset=0,
            )
            metrics = self._matchmaking_metrics(
                session,
                player_id,
                window,
            )
            return CareerSnapshot(
                profile=self._profile(rating),
                league=LeagueEntry(
                    week_key=window.key,
                    starts_at=window.starts_at,
                    ends_at=window.ends_at,
                    points=entry.points if entry is not None else 0,
                    wins=entry.wins if entry is not None else 0,
                    draws=entry.draws if entry is not None else 0,
                    losses=entry.losses if entry is not None else 0,
                    position=position if entry is not None else 0,
                    participant_count=participant_count,
                ),
                leaderboard=tuple(standings),
                recent_matches=tuple(recent),
                matchmaking=metrics,
            )

    def match_history(
        self,
        player_id: str,
        *,
        limit: int = 20,
        offset: int = 0,
    ) -> MatchHistoryPage:
        limit = max(1, min(limit, MAX_HISTORY_LIMIT))
        offset = max(0, offset)
        with self.database.session() as session:
            if session.get(PlayerRecord, player_id) is None:
                raise LookupError("Oyuncu bulunamadı.")
            participant_filter = or_(
                MatchRecord.requester_player_id == player_id,
                MatchRecord.opponent_player_id == player_id,
            )
            total = session.scalar(
                select(func.count(MatchRecord.id)).where(participant_filter)
            ) or 0
            items = self._history_items(
                session,
                player_id,
                limit=limit,
                offset=offset,
            )
            return MatchHistoryPage(
                items=tuple(items),
                total=int(total),
                limit=limit,
                offset=offset,
            )

    def current_league(
        self,
        player_id: str,
        *,
        limit: int = 50,
    ) -> tuple[LeagueEntry, tuple[LeagueStanding, ...]]:
        snapshot = self.career(
            player_id,
            history_limit=1,
            leaderboard_limit=limit,
        )
        return snapshot.league, snapshot.leaderboard

    def _rating_record(
        self,
        session: Session,
        player_id: str,
        now: datetime,
    ) -> PlayerRatingRecord:
        record = session.scalar(
            select(PlayerRatingRecord)
            .where(PlayerRatingRecord.player_id == player_id)
            .with_for_update()
        )
        if record is None:
            record = PlayerRatingRecord(
                player_id=player_id,
                rating=DEFAULT_RATING,
                peak_rating=DEFAULT_RATING,
                rated_matches=0,
                wins=0,
                draws=0,
                losses=0,
                created_at=now,
                updated_at=now,
            )
            session.add(record)
            session.flush()
        return record

    @staticmethod
    def _record_result(record: PlayerRatingRecord, outcome: Outcome) -> None:
        record.rated_matches += 1
        if outcome == "win":
            record.wins += 1
        elif outcome == "draw":
            record.draws += 1
        else:
            record.losses += 1

    def _league_record(
        self,
        session: Session,
        window: LeagueWindow,
        rating: PlayerRatingRecord,
        rating_before: int,
        now: datetime,
    ) -> LeagueEntryRecord:
        record = session.scalar(
            select(LeagueEntryRecord)
            .where(
                LeagueEntryRecord.week_key == window.key,
                LeagueEntryRecord.player_id == rating.player_id,
            )
            .with_for_update()
        )
        if record is None:
            record = LeagueEntryRecord(
                week_key=window.key,
                player_id=rating.player_id,
                rating_at_start=rating_before,
                rating_current=rating.rating,
                points=0,
                wins=0,
                draws=0,
                losses=0,
                created_at=now,
                updated_at=now,
            )
            session.add(record)
            session.flush()
        return record

    @staticmethod
    def _record_league_result(
        record: LeagueEntryRecord,
        outcome: Outcome,
        current_rating: int,
        now: datetime,
    ) -> None:
        if outcome == "win":
            record.wins += 1
            record.points += LEAGUE_WIN_POINTS
        elif outcome == "draw":
            record.draws += 1
            record.points += LEAGUE_DRAW_POINTS
        else:
            record.losses += 1
        record.rating_current = current_rating
        record.updated_at = now

    def _leaderboard(
        self,
        session: Session,
        window: LeagueWindow,
        current_player_id: str,
        limit: int,
    ) -> tuple[list[LeagueStanding], int, int]:
        rows = list(
            session.execute(
                select(LeagueEntryRecord, PlayerRecord)
                .join(
                    PlayerRecord,
                    PlayerRecord.id == LeagueEntryRecord.player_id,
                )
                .where(LeagueEntryRecord.week_key == window.key)
                .order_by(
                    desc(LeagueEntryRecord.points),
                    desc(LeagueEntryRecord.wins),
                    desc(LeagueEntryRecord.rating_current),
                    LeagueEntryRecord.updated_at,
                    LeagueEntryRecord.player_id,
                )
            )
        )
        participant_count = len(rows)
        position = 0
        standings: list[LeagueStanding] = []
        for index, (entry, player) in enumerate(rows, start=1):
            if entry.player_id == current_player_id:
                position = index
            if index <= limit:
                standings.append(
                    LeagueStanding(
                        position=index,
                        player_id=entry.player_id,
                        display_name=player.display_name,
                        points=entry.points,
                        wins=entry.wins,
                        draws=entry.draws,
                        losses=entry.losses,
                        rating=entry.rating_current,
                        is_current_player=(
                            entry.player_id == current_player_id
                        ),
                    )
                )
        return standings, position, participant_count

    def _history_items(
        self,
        session: Session,
        player_id: str,
        *,
        limit: int,
        offset: int,
    ) -> list[MatchHistoryItem]:
        records = list(
            session.scalars(
                select(MatchRecord)
                .where(
                    or_(
                        MatchRecord.requester_player_id == player_id,
                        MatchRecord.opponent_player_id == player_id,
                    )
                )
                .order_by(desc(MatchRecord.created_at), desc(MatchRecord.id))
                .offset(offset)
                .limit(limit)
            )
        )
        rating_changes = {
            record.match_id: record
            for record in session.scalars(
                select(MatchRatingRecord).where(
                    MatchRatingRecord.match_id.in_(
                        [record.id for record in records]
                    )
                )
            )
        } if records else {}
        requester_ids = {
            record.requester_player_id
            for record in records
            if record.requester_player_id is not None
        }
        requester_names = {
            record.id: record.display_name
            for record in session.scalars(
                select(PlayerRecord).where(PlayerRecord.id.in_(requester_ids))
            )
        } if requester_ids else {}

        items: list[MatchHistoryItem] = []
        for record in records:
            is_requester = record.requester_player_id == player_id
            winner = record.result.get("winner")
            if winner is None:
                outcome: Outcome = "draw"
            elif (winner == "left") == is_requester:
                outcome = "win"
            else:
                outcome = "loss"

            if is_requester:
                opponent_kind = record.opponent_kind
                opponent_name = record.opponent_name
            else:
                opponent_kind = "player"
                opponent_name = requester_names.get(
                    record.requester_player_id or "",
                    "Bilinmeyen Oyuncu",
                )

            rating_record = rating_changes.get(record.id)
            rating_delta = 0
            rating_after: int | None = None
            if rating_record is not None:
                change = self._rating_change(rating_record).perspective(player_id)
                rating_delta = int(change["rating_delta"])
                rating_after = int(change["rating_after"])

            items.append(
                MatchHistoryItem(
                    match_id=record.id,
                    created_at=_as_utc(record.created_at),
                    opponent_kind=opponent_kind,
                    opponent_name=opponent_name,
                    outcome=outcome,
                    rated=rating_record is not None,
                    rating_delta=rating_delta,
                    rating_after=rating_after,
                    reason=str(record.result.get("reason", "")),
                    replay_path=f"/api/v1/matches/{record.id}/replay",
                )
            )
        return items

    def _matchmaking_metrics(
        self,
        session: Session,
        player_id: str,
        window: LeagueWindow,
    ) -> MatchmakingMetrics:
        rows = list(
            session.scalars(
                select(MatchRecord).where(
                    MatchRecord.requester_player_id == player_id,
                    MatchRecord.source == "async",
                    MatchRecord.created_at >= window.starts_at,
                    MatchRecord.created_at < window.ends_at,
                )
            )
        )
        human = sum(record.opponent_kind == "player" for record in rows)
        bot = sum(record.opponent_kind == "bot" for record in rows)
        return MatchmakingMetrics(
            searches=len(rows),
            human_opponents=human,
            bot_fallbacks=bot,
        )

    @staticmethod
    def _profile(record: PlayerRatingRecord) -> RatingProfile:
        return RatingProfile(
            player_id=record.player_id,
            rating=record.rating,
            peak_rating=record.peak_rating,
            rated_matches=record.rated_matches,
            wins=record.wins,
            draws=record.draws,
            losses=record.losses,
        )

    @staticmethod
    def _rating_change(record: MatchRatingRecord) -> MatchRatingChange:
        return MatchRatingChange(
            match_id=record.match_id,
            week_key=record.week_key,
            requester_player_id=record.requester_player_id,
            opponent_player_id=record.opponent_player_id,
            outcome=record.outcome,
            requester_rating_before=record.requester_rating_before,
            requester_rating_after=record.requester_rating_after,
            requester_delta=record.requester_delta,
            opponent_rating_before=record.opponent_rating_before,
            opponent_rating_after=record.opponent_rating_after,
            opponent_delta=record.opponent_delta,
            applied_at=_as_utc(record.applied_at),
        )


def _round_half_away_from_zero(value: float) -> int:
    if value >= 0:
        return math.floor(value + 0.5)
    return math.ceil(value - 0.5)


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
