"""add persistent live career battle sessions

Revision ID: 20260814_0016
Revises: 20260813_0015
Create Date: 2026-08-14
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260814_0016"
down_revision: str | None = "20260813_0015"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "career_battle_sessions",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("run_id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("stage_index", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("seed", sa.BigInteger(), nullable=False),
        sa.Column("player_board", sa.JSON(), nullable=False),
        sa.Column("opponent_board", sa.JSON(), nullable=False),
        sa.Column("player_modifiers", sa.JSON(), nullable=False),
        sa.Column("opponent_modifiers", sa.JSON(), nullable=False),
        sa.Column("player_reserves", sa.JSON(), nullable=False),
        sa.Column("commands", sa.JSON(), nullable=False),
        sa.Column("current_tick", sa.Integer(), nullable=False),
        sa.Column("final_match_id", sa.String(length=32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["run_id"],
            ["career_runs.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["final_match_id"],
            ["matches.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "run_id",
            "stage_index",
            name="uq_career_battle_sessions_run_stage",
        ),
    )
    op.create_index(
        "ix_career_battle_sessions_player_status",
        "career_battle_sessions",
        ["player_id", "status"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_career_battle_sessions_player_status",
        table_name="career_battle_sessions",
    )
    op.drop_table("career_battle_sessions")
