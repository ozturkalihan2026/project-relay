"""separate career module upgrades and persist match modifiers

Revision ID: 20260813_0013
Revises: 20260808_0012
Create Date: 2026-08-13
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa


revision: str = "20260813_0013"
down_revision: str | None = "20260808_0012"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    empty_json = sa.text("'{}'")
    empty_list = sa.text("'[]'")
    op.add_column(
        "career_runs",
        sa.Column(
            "selected_module_upgrades",
            sa.JSON(),
            nullable=False,
            server_default=empty_list,
        ),
    )
    op.add_column(
        "matches",
        sa.Column(
            "player_modifiers",
            sa.JSON(),
            nullable=False,
            server_default=empty_json,
        ),
    )
    op.add_column(
        "matches",
        sa.Column(
            "opponent_modifiers",
            sa.JSON(),
            nullable=False,
            server_default=empty_json,
        ),
    )


def downgrade() -> None:
    op.drop_column("matches", "opponent_modifiers")
    op.drop_column("matches", "player_modifiers")
    op.drop_column("career_runs", "selected_module_upgrades")
