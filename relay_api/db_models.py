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


class CareerBoardRecord(Base):
    __tablename__ = "career_boards"

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

    __table_args__ = (
        UniqueConstraint("player_id", name="uq_career_boards_player_id"),
        Index("ix_career_boards_player_time", "player_id", "updated_at"),
    )


class MatchRecord(Base):
    __tablename__ = "matches"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    source: Mapped[str] = mapped_column(String(16), nullable=False)
    weekly_protocol_key: Mapped[str | None] = mapped_column(
        String(48),
        nullable=True,
    )
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
    player_modifiers: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
        default=dict,
    )
    opponent_modifiers: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
        default=dict,
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
    selected_module_upgrades: Mapped[list[dict[str, Any]]] = mapped_column(
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


class CareerBattleSessionRecord(Base):
    __tablename__ = "career_battle_sessions"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    run_id: Mapped[str] = mapped_column(
        ForeignKey("career_runs.id", ondelete="CASCADE"),
        nullable=False,
    )
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    stage_index: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(16), nullable=False)
    seed: Mapped[int] = mapped_column(BigInteger, nullable=False)
    player_board: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    opponent_board: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    player_modifiers: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
    )
    opponent_modifiers: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
    )
    player_reserves: Mapped[list[dict[str, Any]]] = mapped_column(
        JSON,
        nullable=False,
        default=list,
    )
    commands: Mapped[list[dict[str, Any]]] = mapped_column(
        JSON,
        nullable=False,
        default=list,
    )
    current_tick: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    final_match_id: Mapped[str | None] = mapped_column(
        ForeignKey("matches.id", ondelete="SET NULL"),
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
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )

    __table_args__ = (
        UniqueConstraint(
            "run_id",
            "stage_index",
            name="uq_career_battle_sessions_run_stage",
        ),
        Index(
            "ix_career_battle_sessions_player_status",
            "player_id",
            "status",
        ),
    )


class PlayerCosmeticRecord(Base):
    __tablename__ = "player_cosmetics"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    cosmetic_id: Mapped[str] = mapped_column(String(48), nullable=False)
    acquired_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        PrimaryKeyConstraint(
            "player_id",
            "cosmetic_id",
            name="pk_player_cosmetics",
        ),
        Index("ix_player_cosmetics_player", "player_id"),
    )


class PlayerLoadoutRecord(Base):
    __tablename__ = "player_loadouts"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        primary_key=True,
    )
    kit_name: Mapped[str] = mapped_column(String(40), nullable=False)
    module_kinds: Mapped[list[str]] = mapped_column(JSON, nullable=False)
    mode_kits: Mapped[dict[str, object] | None] = mapped_column(
        JSON,
        nullable=True,
    )
    module_skin_id: Mapped[str] = mapped_column(String(48), nullable=False)
    board_theme_id: Mapped[str] = mapped_column(String(48), nullable=False)
    profile_frame_id: Mapped[str] = mapped_column(String(48), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )


class SeasonEntryRecord(Base):
    __tablename__ = "season_entries"

    season_key: Mapped[str] = mapped_column(String(16), nullable=False)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    points: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    matches: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    wins: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    draws: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    losses: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    claimed_tiers: Mapped[list[int]] = mapped_column(
        JSON,
        nullable=False,
        default=list,
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
            "season_key",
            "player_id",
            name="pk_season_entries",
        ),
        Index(
            "ix_season_entries_leaderboard",
            "season_key",
            "points",
            "wins",
            "updated_at",
        ),
    )


class SeasonMatchRecord(Base):
    __tablename__ = "season_match_points"

    match_id: Mapped[str] = mapped_column(
        ForeignKey("matches.id", ondelete="CASCADE"),
        primary_key=True,
    )
    season_key: Mapped[str] = mapped_column(String(16), nullable=False)
    requester_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    opponent_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    requester_points: Mapped[int] = mapped_column(Integer, nullable=False)
    opponent_points: Mapped[int] = mapped_column(Integer, nullable=False)
    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        Index(
            "ix_season_match_player",
            "season_key",
            "requester_player_id",
        ),
    )


class AlphaFeedbackRecord(Base):
    __tablename__ = "alpha_feedback"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    category: Mapped[str] = mapped_column(String(24), nullable=False)
    message: Mapped[str] = mapped_column(String(1200), nullable=False)
    client_version: Mapped[str] = mapped_column(String(24), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        Index("ix_alpha_feedback_player_time", "player_id", "created_at"),
    )


class ProductEventRecord(Base):
    __tablename__ = "product_events"

    id: Mapped[str] = mapped_column(String(40), primary_key=True)
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        nullable=False,
    )
    event_name: Mapped[str] = mapped_column(String(48), nullable=False)
    context: Mapped[dict[str, Any]] = mapped_column(
        JSON,
        nullable=False,
        default=dict,
    )
    client_version: Mapped[str] = mapped_column(String(24), nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    received_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    __table_args__ = (
        Index("ix_product_events_name_time", "event_name", "received_at"),
        Index("ix_product_events_player_time", "player_id", "received_at"),
    )


class PlayerSafetyRecord(Base):
    __tablename__ = "player_safety"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        primary_key=True,
    )
    match_window_started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    match_requests: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    feedback_window_started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    feedback_requests: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        default=0,
    )
    blocked_until: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )


class PlayerSocialProfileRecord(Base):
    __tablename__ = "player_social_profiles"

    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"),
        primary_key=True,
    )
    status_message: Mapped[str] = mapped_column(
        String(160), nullable=False, default="Devresini geliştiriyor."
    )
    favorite_module: Mapped[str] = mapped_column(
        String(32), nullable=False, default="generator"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )


class FriendRequestRecord(Base):
    __tablename__ = "friend_requests"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    sender_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"), nullable=False
    )
    receiver_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(16), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    __table_args__ = (
        UniqueConstraint(
            "sender_player_id",
            "receiver_player_id",
            name="uq_friend_requests_direction",
        ),
        Index("ix_friend_requests_receiver_status", "receiver_player_id", "status"),
        Index("ix_friend_requests_sender_status", "sender_player_id", "status"),
    )


class ClanRecord(Base):
    __tablename__ = "clans"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    name: Mapped[str] = mapped_column(String(48), nullable=False, unique=True)
    tag: Mapped[str] = mapped_column(String(8), nullable=False, unique=True)
    description: Mapped[str] = mapped_column(String(240), nullable=False)
    leader_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="RESTRICT"), nullable=False
    )
    is_open: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    __table_args__ = (
        Index("ix_clans_open_updated", "is_open", "updated_at"),
    )


class ClanMemberRecord(Base):
    __tablename__ = "clan_members"

    clan_id: Mapped[str] = mapped_column(
        ForeignKey("clans.id", ondelete="CASCADE"), nullable=False
    )
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"), nullable=False, unique=True
    )
    role: Mapped[str] = mapped_column(String(16), nullable=False)
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False
    )

    __table_args__ = (
        PrimaryKeyConstraint("clan_id", "player_id", name="pk_clan_members"),
        Index("ix_clan_members_clan_role", "clan_id", "role", "joined_at"),
    )


class ChatGroupRecord(Base):
    __tablename__ = "chat_groups"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    name: Mapped[str] = mapped_column(String(40), nullable=False)
    owner_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class ChatGroupMemberRecord(Base):
    __tablename__ = "chat_group_members"

    group_id: Mapped[str] = mapped_column(
        ForeignKey("chat_groups.id", ondelete="CASCADE"), nullable=False
    )
    player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"), nullable=False
    )
    joined_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        PrimaryKeyConstraint("group_id", "player_id", name="pk_chat_group_members"),
        Index("ix_chat_group_members_player", "player_id", "joined_at"),
    )


class ChatMessageRecord(Base):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(String(32), primary_key=True)
    channel_type: Mapped[str] = mapped_column(String(16), nullable=False)
    channel_key: Mapped[str] = mapped_column(String(96), nullable=False)
    sender_player_id: Mapped[str] = mapped_column(
        ForeignKey("players.id", ondelete="CASCADE"), nullable=False
    )
    message: Mapped[str] = mapped_column(String(500), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    __table_args__ = (
        Index("ix_chat_messages_channel_time", "channel_type", "channel_key", "created_at"),
    )
