"""Add season, closed alpha feedback and persistent safety guards.

Revision ID: 20260801_0008
Revises: 20260731_0007
Create Date: 2026-08-01
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "20260801_0008"
down_revision: str | None = "20260731_0007"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "season_entries",
        sa.Column("season_key", sa.String(length=16), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("points", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("matches", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("wins", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("draws", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("losses", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("claimed_tiers", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("season_key", "player_id", name="pk_season_entries"),
    )
    op.create_index(
        "ix_season_entries_leaderboard",
        "season_entries",
        ["season_key", "points", "wins", "updated_at"],
    )
    op.create_table(
        "season_match_points",
        sa.Column("match_id", sa.String(length=32), nullable=False),
        sa.Column("season_key", sa.String(length=16), nullable=False),
        sa.Column("requester_player_id", sa.String(length=32), nullable=False),
        sa.Column("opponent_player_id", sa.String(length=32), nullable=False),
        sa.Column("requester_points", sa.Integer(), nullable=False),
        sa.Column("opponent_points", sa.Integer(), nullable=False),
        sa.Column("recorded_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["match_id"], ["matches.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["requester_player_id"], ["players.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["opponent_player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("match_id"),
    )
    op.create_index(
        "ix_season_match_player",
        "season_match_points",
        ["season_key", "requester_player_id"],
    )
    op.create_table(
        "alpha_feedback",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("category", sa.String(length=24), nullable=False),
        sa.Column("message", sa.String(length=1200), nullable=False),
        sa.Column("client_version", sa.String(length=24), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_alpha_feedback_player_time",
        "alpha_feedback",
        ["player_id", "created_at"],
    )
    op.create_table(
        "player_safety",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("match_window_started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("match_requests", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("feedback_window_started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("feedback_requests", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("blocked_until", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("player_id"),
    )


def downgrade() -> None:
    op.drop_table("player_safety")
    op.drop_index("ix_alpha_feedback_player_time", table_name="alpha_feedback")
    op.drop_table("alpha_feedback")
    op.drop_index("ix_season_match_player", table_name="season_match_points")
    op.drop_table("season_match_points")
    op.drop_index("ix_season_entries_leaderboard", table_name="season_entries")
    op.drop_table("season_entries")
