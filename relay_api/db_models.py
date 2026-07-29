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
