"""Add server-authoritative career run persistence.

Revision ID: 20260731_0005
Revises: 20260731_0004
"""

from __future__ import annotations

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260731_0005"
down_revision: str | None = "20260731_0004"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "career_runs",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=24), nullable=False),
        sa.Column("stage_index", sa.Integer(), nullable=False),
        sa.Column("wins", sa.Integer(), nullable=False),
        sa.Column("selected_boosters", sa.JSON(), nullable=False),
        sa.Column("offered_boosters", sa.JSON(), nullable=False),
        sa.Column("last_match_id", sa.String(length=32), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["last_match_id"], ["matches.id"], ondelete="SET NULL"
        ),
        sa.ForeignKeyConstraint(
            ["player_id"], ["players.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_career_runs_player_time",
        "career_runs",
        ["player_id", "started_at"],
        unique=False,
    )
    op.create_index(
        "ix_career_runs_player_status",
        "career_runs",
        ["player_id", "status"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index("ix_career_runs_player_status", table_name="career_runs")
    op.drop_index("ix_career_runs_player_time", table_name="career_runs")
    op.drop_table("career_runs")
