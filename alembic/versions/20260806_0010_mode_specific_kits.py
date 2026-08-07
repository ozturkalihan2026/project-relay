"""add mode-specific controlled kits

Revision ID: 20260806_0010
Revises: 20260801_0009
Create Date: 2026-08-06
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "20260806_0010"
down_revision: str | None = "20260801_0009"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "player_loadouts",
        sa.Column("mode_kits", sa.JSON(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("player_loadouts", "mode_kits")
