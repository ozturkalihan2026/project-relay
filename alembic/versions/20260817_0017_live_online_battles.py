"""add persistent live online battle sessions

Revision ID: 20260817_0017
Revises: 20260814_0016
Create Date: 2026-08-17
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260817_0017"
down_revision: str | None = "20260814_0016"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "online_battle_sessions",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("opponent_player_id", sa.String(length=32), nullable=True),
        sa.Column("opponent_kind", sa.String(length=16), nullable=False),
        sa.Column("opponent_id", sa.String(length=40), nullable=False),
        sa.Column("opponent_name", sa.String(length=80), nullable=False),
        sa.Column("opponent_description", sa.String(length=240), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("seed", sa.BigInteger(), nullable=False),
        sa.Column("player_board", sa.JSON(), nullable=False),
        sa.Column("opponent_board", sa.JSON(), nullable=False),
        sa.Column("player_modifiers", sa.JSON(), nullable=False),
        sa.Column("opponent_modifiers", sa.JSON(), nullable=False),
        sa.Column("player_reserves", sa.JSON(), nullable=False),
        sa.Column("commands", sa.JSON(), nullable=False),
        sa.Column("current_tick", sa.Integer(), nullable=False),
        sa.Column("weekly_protocol_key", sa.String(length=48), nullable=True),
        sa.Column("final_match_id", sa.String(length=32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["opponent_player_id"],
            ["players.id"],
            ondelete="SET NULL",
        ),
        sa.ForeignKeyConstraint(
            ["final_match_id"],
            ["matches.id"],
            ondelete="SET NULL",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_online_battle_sessions_player_status",
        "online_battle_sessions",
        ["player_id", "status"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_online_battle_sessions_player_status",
        table_name="online_battle_sessions",
    )
    op.drop_table("online_battle_sessions")
