from __future__ import annotations

from datetime import datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    JSON,
    PrimaryKeyConstraint,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class PlayerRecord(Base):
    __tablename__ = "players"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    display_name: Mapped[str] = mapped_column(
        String(32),
        nullable=False,
        unique=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )


class RefreshSessionRecord(Base):
    __tablename__ = "refresh_sessions"

    jti: Mapped[str] = mapped_column(String(32), primary_key=True)
    family_id: Mapped[str] = mapped_column(String(32), nullable=False)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    token_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    rotated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    __table_args__ = (
        Index("ix_refresh_sessions_player_id", "player_id"),
        Index("ix_refresh_sessions_family_id", "family_id"),
    )


class BoardRecord(Base):
    __tablename__ = "boards"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    modules: Mapped[list[dict[str, Any]]] = mapped_column(
        JSON,
        nullable=False,
    )
    fingerprint: Mapped[str] = mapped_column(String(64), nullable=False)
    module_count: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    eligible: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=True,
    )

    __table_args__ = (
        UniqueConstraint("player_id", name="uq_boards_player_id"),
        Index(
            "ix_boards_matchmaking",
            "module_count",
            "eligible",
            "updated_at",
        ),
    )


class MatchRecord(Base):
    __tablename__ = "matches"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    source: Mapped[str] = mapped_column(String(16), nullable=False)
    requester_player_id: Mapped[str | None] = mapped_column(
        ForeignKey("players.id", ondelete="SET NULL"),
        nullable=True,
    )
    opponent_player_id: Mapped[str | None] = mapped_column(
        ForeignKey("players.id", ondelete="SET NULL"),
        nullable=True,
    )
    opponent_kind: Mapped[str] = mapped_column(String(16), nullable=False)
    opponent_id: Mapped[str] = mapped_column(String(40), nullable=False)
    opponent_name: Mapped[str] = mapped_column(String(80), nullable=False)
    opponent_description: Mapped[str] = mapped_column(
        String(240),
        nullable=False,
    )
    player_board: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    opponent_board: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
    )
    result: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    replay: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    replay_checksum: Mapped[str] = mapped_column(String(64), nullable=False)
    event_count: Mapped[int] = mapped_column(Integer, nullable=False)
    seed: Mapped[int] = mapped_column(BigInteger, nullable=False)
    rules_version: Mapped[str] = mapped_column(String(16), nullable=False)

    __table_args__ = (
        Index(
            "ix_matches_requester_created",
            "requester_player_id",
            "created_at",
        ),
        Index(
            "ix_matches_opponent_created",
            "opponent_player_id",
            "created_at",
        ),
    )


class PlayerRatingRecord(Base):
    __tablename__ = "player_ratings"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        primary_key=True,
    )
    rating: Mapped[int] = mapped_column(Integer, nullable=False, default=1000)
    peak_rating: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=1000,
    )
    rated_matches: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )
    wins: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    draws: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    losses: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )


class LeagueEntryRecord(Base):
    __tablename__ = "league_entries"

    week_key: Mapped[str] = mapped_column(String(8), nullable=False)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    rating_at_start: Mapped[int] = mapped_column(Integer, nullable=False)
    rating_current: Mapped[int] = mapped_column(Integer, nullable=False)
    points: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    wins: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    draws: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    losses: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        PrimaryKeyConstraint(
            "week_key",
            "player_id",
            name="pk_league_entries",
        ),
        Index(
            "ix_league_entries_leaderboard",
            "week_key",
            "points",
            "wins",
            "rating_current",
        ),
    )


class MatchRatingRecord(Base):
    __tablename__ = "match_rating_changes"

    match_id: Mapped[str] = mapped_column(
        ForeignKey("matches.id", ondelete="CASCADE"),
        primary_key=True,
    )
    week_key: Mapped[str] = mapped_column(String(8), nullable=False)
    requester_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    opponent_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    outcome: Mapped[str] = mapped_column(String(8), nullable=False)
    requester_rating_before: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    requester_rating_after: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    requester_delta: Mapped[int] = mapped_column(Integer, nullable=False)
    opponent_rating_before: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    opponent_rating_after: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    opponent_delta: Mapped[int] = mapped_column(Integer, nullable=False)
    applied_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        Index(
            "ix_match_rating_requester_week",
            "requester_player_id",
            "week_key",
        ),
        Index(
            "ix_match_rating_opponent_week",
            "opponent_player_id",
            "week_key",
        ),
    )

class PlayerProgressionRecord(Base):
    __tablename__ = "player_progression"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        primary_key=True,
    )
    total_xp: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    credits: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    matches_completed: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )
    wins: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    draws: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    losses: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )


class RewardGrantRecord(Base):
    __tablename__ = "reward_grants"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    source_type: Mapped[str] = mapped_column(String(24), nullable=False)
    source_id: Mapped[str] = mapped_column(String(64), nullable=False)
    reason: Mapped[str] = mapped_column(String(120), nullable=False)
    xp: Mapped[int] = mapped_column(Integer, nullable=False)
    credits: Mapped[int] = mapped_column(Integer, nullable=False)
    level_before: Mapped[int] = mapped_column(Integer, nullable=False)
    level_after: Mapped[int] = mapped_column(Integer, nullable=False)
    total_xp_after: Mapped[int] = mapped_column(Integer, nullable=False)
    credits_after: Mapped[int] = mapped_column(Integer, nullable=False)
    granted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        UniqueConstraint(
            "player_id",
            "source_type",
            "source_id",
            name="uq_reward_grants_source",
        ),
        Index("ix_reward_grants_player_time", "player_id", "granted_at"),
    )


class DailyMissionRecord(Base):
    __tablename__ = "daily_missions"

    day_key: Mapped[str] = mapped_column(String(10), nullable=False)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    mission_id: Mapped[str] = mapped_column(String(40), nullable=False)
    progress: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    target: Mapped[int] = mapped_column(Integer, nullable=False)
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    claimed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        PrimaryKeyConstraint(
            "day_key",
            "player_id",
            "mission_id",
            name="pk_daily_missions",
        ),
        Index("ix_daily_missions_player_day", "player_id", "day_key"),
    )


class PlayerAchievementRecord(Base):
    __tablename__ = "player_achievements"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    achievement_id: Mapped[str] = mapped_column(String(40), nullable=False)
    progress: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    target: Mapped[int] = mapped_column(Integer, nullable=False)
    unlocked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    claimed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        PrimaryKeyConstraint(
            "player_id",
            "achievement_id",
            name="pk_player_achievements",
        ),
    )



class CareerRunRecord(Base):
    __tablename__ = "career_runs"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(String(24), nullable=False)
    stage_index: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    wins: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    selected_boosters: Mapped[list[str]] = mapped_column(
        JSON,
        nullable=False,
        default=list,
    )
    offered_boosters: Mapped[list[str]] = mapped_column(
        JSON,
        nullable=False,
        default=list,
    )
    last_match_id: Mapped[str | None] = mapped_column(
        ForeignKey("matches.id", ondelete="SET NULL"),
        nullable=True,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    ended_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    __table_args__ = (
        Index("ix_career_runs_player_time", "player_id", "started_at"),
        Index("ix_career_runs_player_status", "player_id", "status"),
    )
