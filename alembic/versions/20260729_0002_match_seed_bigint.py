"""Store deterministic match seeds as signed 64-bit integers.

Revision ID: 20260729_0002
Revises: 20260729_0001
Create Date: 2026-07-29
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260729_0002"
down_revision: str | None = "20260729_0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    with op.batch_alter_table("matches") as batch_op:
        batch_op.alter_column(
            "seed",
            existing_type=sa.Integer(),
            type_=sa.BigInteger(),
            existing_nullable=False,
        )


def downgrade() -> None:
    with op.batch_alter_table("matches") as batch_op:
        batch_op.alter_column(
            "seed",
            existing_type=sa.BigInteger(),
            type_=sa.Integer(),
            existing_nullable=False,
        )
