"""chat foundation

Revision ID: 20260808_0012
Revises: 20260807_0011
Create Date: 2026-08-08
"""
from collections.abc import Sequence
from alembic import op
import sqlalchemy as sa

revision: str = '20260808_0012'
down_revision: str | None = '20260807_0011'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        'chat_groups',
        sa.Column('id', sa.String(length=32), nullable=False),
        sa.Column('name', sa.String(length=40), nullable=False),
        sa.Column('owner_player_id', sa.String(length=32), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['owner_player_id'], ['players.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_table(
        'chat_group_members',
        sa.Column('group_id', sa.String(length=32), nullable=False),
        sa.Column('player_id', sa.String(length=32), nullable=False),
        sa.Column('joined_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['group_id'], ['chat_groups.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['player_id'], ['players.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('group_id', 'player_id', name='pk_chat_group_members'),
    )
    op.create_index('ix_chat_group_members_player', 'chat_group_members', ['player_id', 'joined_at'])
    op.create_table(
        'chat_messages',
        sa.Column('id', sa.String(length=32), nullable=False),
        sa.Column('channel_type', sa.String(length=16), nullable=False),
        sa.Column('channel_key', sa.String(length=96), nullable=False),
        sa.Column('sender_player_id', sa.String(length=32), nullable=False),
        sa.Column('message', sa.String(length=500), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['sender_player_id'], ['players.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index('ix_chat_messages_channel_time', 'chat_messages', ['channel_type', 'channel_key', 'created_at'])


def downgrade() -> None:
    op.drop_index('ix_chat_messages_channel_time', table_name='chat_messages')
    op.drop_table('chat_messages')
    op.drop_index('ix_chat_group_members_player', table_name='chat_group_members')
    op.drop_table('chat_group_members')
    op.drop_table('chat_groups')
