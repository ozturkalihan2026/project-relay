"""Create persistent guest, board, session, match and replay tables.

Revision ID: 20260729_0001
Revises:
Create Date: 2026-07-29
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260729_0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "players",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("display_name", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("last_seen_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("display_name"),
    )
    op.create_table(
        "refresh_sessions",
        sa.Column("jti", sa.String(length=32), nullable=False),
        sa.Column("family_id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("rotated_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("jti"),
    )
    op.create_index(
        "ix_refresh_sessions_player_id",
        "refresh_sessions",
        ["player_id"],
    )
    op.create_index(
        "ix_refresh_sessions_family_id",
        "refresh_sessions",
        ["family_id"],
    )
    op.create_table(
        "boards",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("name", sa.String(length=80), nullable=False),
        sa.Column("modules", sa.JSON(), nullable=False),
        sa.Column("fingerprint", sa.String(length=64), nullable=False),
        sa.Column("module_count", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "eligible",
            sa.Boolean(),
            nullable=False,
            server_default=sa.true(),
        ),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("player_id", name="uq_boards_player_id"),
    )
    op.create_index(
        "ix_boards_matchmaking",
        "boards",
        ["module_count", "eligible", "updated_at"],
    )
    op.create_table(
        "matches",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("source", sa.String(length=16), nullable=False),
        sa.Column("requester_player_id", sa.String(length=32), nullable=True),
        sa.Column("opponent_player_id", sa.String(length=32), nullable=True),
        sa.Column("opponent_kind", sa.String(length=16), nullable=False),
        sa.Column("opponent_id", sa.String(length=40), nullable=False),
        sa.Column("opponent_name", sa.String(length=80), nullable=False),
        sa.Column(
            "opponent_description",
            sa.String(length=240),
            nullable=False,
        ),
        sa.Column("player_board", sa.JSON(), nullable=False),
        sa.Column("opponent_board", sa.JSON(), nullable=False),
        sa.Column("result", sa.JSON(), nullable=False),
        sa.Column("replay", sa.JSON(), nullable=False),
        sa.Column("replay_checksum", sa.String(length=64), nullable=False),
        sa.Column("event_count", sa.Integer(), nullable=False),
        sa.Column("seed", sa.Integer(), nullable=False),
        sa.Column("rules_version", sa.String(length=16), nullable=False),
        sa.ForeignKeyConstraint(
            ["opponent_player_id"],
            ["players.id"],
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["requester_player_id"],
            ["players.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_matches_requester_created",
        "matches",
        ["requester_player_id", "created_at"],
    )
    op.create_index(
        "ix_matches_opponent_created",
        "matches",
        ["opponent_player_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_matches_opponent_created", table_name="matches")
    op.drop_index("ix_matches_requester_created", table_name="matches")
    op.drop_table("matches")
    op.drop_index("ix_boards_matchmaking", table_name="boards")
    op.drop_table("boards")
    op.drop_index(
        "ix_refresh_sessions_family_id",
        table_name="refresh_sessions",
    )
    op.drop_index(
        "ix_refresh_sessions_player_id",
        table_name="refresh_sessions",
    )
    op.drop_table("refresh_sessions")
    op.drop_table("players")
