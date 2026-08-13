"""persist the weekly protocol used by async matches

Revision ID: 20260813_0014
Revises: 20260813_0013
Create Date: 2026-08-13
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260813_0014"
down_revision: str | None = "20260813_0013"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "matches",
        sa.Column("weekly_protocol_key", sa.String(length=48), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("matches", "weekly_protocol_key")
