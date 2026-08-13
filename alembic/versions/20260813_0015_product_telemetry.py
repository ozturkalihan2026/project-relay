"""add privacy-controlled product telemetry events

Revision ID: 20260813_0015
Revises: 20260813_0014
Create Date: 2026-08-13
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260813_0015"
down_revision: str | None = "20260813_0014"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "product_events",
        sa.Column("id", sa.String(length=40), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("event_name", sa.String(length=48), nullable=False),
        sa.Column("context", sa.JSON(), nullable=False),
        sa.Column("client_version", sa.String(length=24), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("received_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["player_id"],
            ["players.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_product_events_name_time",
        "product_events",
        ["event_name", "received_at"],
        unique=False,
    )
    op.create_index(
        "ix_product_events_player_time",
        "product_events",
        ["player_id", "received_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_product_events_player_time",
        table_name="product_events",
    )
    op.drop_index(
        "ix_product_events_name_time",
        table_name="product_events",
    )
    op.drop_table("product_events")
