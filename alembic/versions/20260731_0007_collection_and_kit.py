"""add cosmetic collection and controlled eight-slot kit

Revision ID: 20260731_0007
Revises: 20260731_0006
Create Date: 2026-07-31
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260731_0007"
down_revision: str | None = "20260731_0006"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "player_cosmetics",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("cosmetic_id", sa.String(length=48), nullable=False),
        sa.Column("acquired_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint(
            "player_id", "cosmetic_id", name="pk_player_cosmetics"
        ),
    )
    op.create_index(
        "ix_player_cosmetics_player",
        "player_cosmetics",
        ["player_id"],
        unique=False,
    )
    op.create_table(
        "player_loadouts",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("kit_name", sa.String(length=40), nullable=False),
        sa.Column("module_kinds", sa.JSON(), nullable=False),
        sa.Column("module_skin_id", sa.String(length=48), nullable=False),
        sa.Column("board_theme_id", sa.String(length=48), nullable=False),
        sa.Column("profile_frame_id", sa.String(length=48), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("player_id"),
    )


def downgrade() -> None:
    op.drop_table("player_loadouts")
    op.drop_index("ix_player_cosmetics_player", table_name="player_cosmetics")
    op.drop_table("player_cosmetics")
