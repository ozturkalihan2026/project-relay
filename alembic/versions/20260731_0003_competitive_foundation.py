"""Add player rating, weekly league and idempotent match rating tables.

Revision ID: 20260731_0003
Revises: 20260729_0002
Create Date: 2026-07-31
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260731_0003"
down_revision: str | None = "20260729_0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "player_ratings",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column(
            "rating",
            sa.Integer(),
            nullable=False,
            server_default="1000",
        ),
        sa.Column(
            "peak_rating",
            sa.Integer(),
            nullable=False,
            server_default="1000",
        ),
        sa.Column(
            "rated_matches",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "wins",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "draws",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "losses",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("player_id"),
    )

    op.create_table(
        "league_entries",
        sa.Column("week_key", sa.String(length=8), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("rating_at_start", sa.Integer(), nullable=False),
        sa.Column("rating_current", sa.Integer(), nullable=False),
        sa.Column(
            "points",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "wins",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "draws",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column(
            "losses",
            sa.Integer(),
            nullable=False,
            server_default="0",
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint(
            "week_key",
            "player_id",
            name="pk_league_entries",
        ),
    )
    op.create_index(
        "ix_league_entries_leaderboard",
        "league_entries",
        ["week_key", "points", "wins", "rating_current"],
    )

    op.create_table(
        "match_rating_changes",
        sa.Column("match_id", sa.String(length=32), nullable=False),
        sa.Column("week_key", sa.String(length=8), nullable=False),
        sa.Column(
            "requester_player_id",
            sa.String(length=32),
            nullable=False,
        ),
        sa.Column(
            "opponent_player_id",
            sa.String(length=32),
            nullable=False,
        ),
        sa.Column("outcome", sa.String(length=8), nullable=False),
        sa.Column("requester_rating_before", sa.Integer(), nullable=False),
        sa.Column("requester_rating_after", sa.Integer(), nullable=False),
        sa.Column("requester_delta", sa.Integer(), nullable=False),
        sa.Column("opponent_rating_before", sa.Integer(), nullable=False),
        sa.Column("opponent_rating_after", sa.Integer(), nullable=False),
        sa.Column("opponent_delta", sa.Integer(), nullable=False),
        sa.Column("applied_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["match_id"],
            ["matches.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["requester_player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["opponent_player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("match_id"),
    )
    op.create_index(
        "ix_match_rating_requester_week",
        "match_rating_changes",
        ["requester_player_id", "week_key"],
    )
    op.create_index(
        "ix_match_rating_opponent_week",
        "match_rating_changes",
        ["opponent_player_id", "week_key"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_match_rating_opponent_week",
        table_name="match_rating_changes",
    )
    op.drop_index(
        "ix_match_rating_requester_week",
        table_name="match_rating_changes",
    )
    op.drop_table("match_rating_changes")
    op.drop_index(
        "ix_league_entries_leaderboard",
        table_name="league_entries",
    )
    op.drop_table("league_entries")
    op.drop_table("player_ratings")
