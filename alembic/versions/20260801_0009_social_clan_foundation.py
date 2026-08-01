"""Add social profile, friendships and clan foundation.

Revision ID: 20260801_0009
Revises: 20260801_0008
Create Date: 2026-08-01
"""
from __future__ import annotations

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa

revision: str = "20260801_0009"
down_revision: str | None = "20260801_0008"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "player_social_profiles",
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column(
            "status_message",
            sa.String(length=160),
            nullable=False,
            server_default="Devresini geliştiriyor.",
        ),
        sa.Column(
            "favorite_module",
            sa.String(length=32),
            nullable=False,
            server_default="generator",
        ),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("player_id"),
    )
    op.create_table(
        "friend_requests",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("sender_player_id", sa.String(length=32), nullable=False),
        sa.Column("receiver_player_id", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["sender_player_id"], ["players.id"], ondelete="CASCADE"
        ),
        sa.ForeignKeyConstraint(
            ["receiver_player_id"], ["players.id"], ondelete="CASCADE"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "sender_player_id",
            "receiver_player_id",
            name="uq_friend_requests_direction",
        ),
    )
    op.create_index(
        "ix_friend_requests_receiver_status",
        "friend_requests",
        ["receiver_player_id", "status"],
    )
    op.create_index(
        "ix_friend_requests_sender_status",
        "friend_requests",
        ["sender_player_id", "status"],
    )
    op.create_table(
        "clans",
        sa.Column("id", sa.String(length=32), nullable=False),
        sa.Column("name", sa.String(length=48), nullable=False),
        sa.Column("tag", sa.String(length=8), nullable=False),
        sa.Column("description", sa.String(length=240), nullable=False),
        sa.Column("leader_player_id", sa.String(length=32), nullable=False),
        sa.Column("is_open", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["leader_player_id"], ["players.id"], ondelete="RESTRICT"
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("name"),
        sa.UniqueConstraint("tag"),
    )
    op.create_index("ix_clans_open_updated", "clans", ["is_open", "updated_at"])
    op.create_table(
        "clan_members",
        sa.Column("clan_id", sa.String(length=32), nullable=False),
        sa.Column("player_id", sa.String(length=32), nullable=False),
        sa.Column("role", sa.String(length=16), nullable=False),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["clan_id"], ["clans.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["player_id"], ["players.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("clan_id", "player_id", name="pk_clan_members"),
        sa.UniqueConstraint("player_id"),
    )
    op.create_index(
        "ix_clan_members_clan_role",
        "clan_members",
        ["clan_id", "role", "joined_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_clan_members_clan_role", table_name="clan_members")
    op.drop_table("clan_members")
    op.drop_index("ix_clans_open_updated", table_name="clans")
    op.drop_table("clans")
    op.drop_index("ix_friend_requests_sender_status", table_name="friend_requests")
    op.drop_index("ix_friend_requests_receiver_status", table_name="friend_requests")
    op.drop_table("friend_requests")
    op.drop_table("player_social_profiles")
