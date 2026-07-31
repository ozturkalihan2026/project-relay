"""Add progression, rewards, daily missions and achievements.

Revision ID: 20260731_0004
Revises: 20260731_0003
Create Date: 2026-07-31
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260731_0004"
down_revision: str | None = "20260731_0003"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "player_progression",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("total_xp", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("credits", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("matches_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("wins", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("draws", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("losses", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("player_id"),
    )

    op.create_table(
        "reward_grants",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("source_type", sa.String(length=24), nullable=False),
        sa.Column("source_id", sa.String(length=64), nullable=False),
        sa.Column("reason", sa.String(length=120), nullable=False),
        sa.Column("xp", sa.Integer(), nullable=False),
        sa.Column("credits", sa.Integer(), nullable=False),
        sa.Column("level_before", sa.Integer(), nullable=False),
        sa.Column("level_after", sa.Integer(), nullable=False),
        sa.Column("total_xp_after", sa.Integer(), nullable=False),
        sa.Column("credits_after", sa.Integer(), nullable=False),
        sa.Column("granted_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "player_id",
            "source_type",
            "source_id",
            name="uq_reward_grants_source",
        ),
    )
    op.create_index(
        "ix_reward_grants_player_time",
        "reward_grants",
        ["player_id", "granted_at"],
    )

    op.create_table(
        "daily_missions",
        sa.Column("day_key", sa.String(length=10), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("mission_id", sa.String(length=40), nullable=False),
        sa.Column("progress", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("target", sa.Integer(), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("claimed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint(
            "day_key",
            "player_id",
            "mission_id",
            name="pk_daily_missions",
        ),
    )
    op.create_index(
        "ix_daily_missions_player_day",
        "daily_missions",
        ["player_id", "day_key"],
    )

    op.create_table(
        "player_achievements",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("achievement_id", sa.String(length=40), nullable=False),
        sa.Column("progress", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("target", sa.Integer(), nullable=False),
        sa.Column("unlocked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("claimed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint(
            "player_id",
            "achievement_id",
            name="pk_player_achievements",
        ),
    )


def downgrade() -> None:
    op.drop_table("player_achievements")
    op.drop_index("ix_daily_missions_player_day", table_name="daily_missions")
    op.drop_table("daily_missions")
    op.drop_index("ix_reward_grants_player_time", table_name="reward_grants")
    op.drop_table("reward_grants")
    op.drop_table("player_progression")
