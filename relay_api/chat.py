from __future__ import annotations

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import and_, or_, select

from .database import Database
from .db_models import (
    ChatGroupMemberRecord,
    ChatGroupRecord,
    ChatMessageRecord,
    ClanMemberRecord,
    FriendRequestRecord,
    PlayerRecord,
)


class ChatError(Exception):
    def __init__(self, code: str, message: str, *, status_code: int = 409) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class ChatChannel:
    channel_type: str
    channel_key: str
    title: str
    subtitle: str
    unread_hint: int = 0


@dataclass(frozen=True, slots=True)
class ChatMessage:
    message_id: str
    channel_type: str
    channel_key: str
    sender_player_id: str
    sender_display_name: str
    message: str
    created_at: datetime


class ChatService:
    def __init__(
        self,
        database: Database,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
    ) -> None:
        self.database = database
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)

    def channels(self, player_id: str) -> tuple[ChatChannel, ...]:
        with self.database.session() as session:
            self._require_player(session, player_id)
            channels: list[ChatChannel] = [
                ChatChannel('server', 'global', 'TÜM SUNUCU', 'Herkese açık sunucu sohbeti')
            ]
            membership = session.scalar(
                select(ClanMemberRecord).where(ClanMemberRecord.player_id == player_id)
            )
            if membership is not None:
                channels.append(
                    ChatChannel('clan', membership.clan_id, 'KLAN', 'Klan üyeleri sohbeti')
                )
            accepted = list(
                session.scalars(
                    select(FriendRequestRecord).where(
                        FriendRequestRecord.status == 'accepted',
                        or_(
                            FriendRequestRecord.sender_player_id == player_id,
                            FriendRequestRecord.receiver_player_id == player_id,
                        ),
                    )
                )
            )
            for request in accepted:
                friend_id = (
                    request.receiver_player_id
                    if request.sender_player_id == player_id
                    else request.sender_player_id
                )
                friend = session.get(PlayerRecord, friend_id)
                if friend is None:
                    continue
                channels.append(
                    ChatChannel(
                        'direct',
                        self.direct_key(player_id, friend_id),
                        friend.display_name,
                        'Özel sohbet',
                    )
                )
            memberships = list(
                session.scalars(
                    select(ChatGroupMemberRecord).where(
                        ChatGroupMemberRecord.player_id == player_id
                    )
                )
            )
            for member in memberships:
                group = session.get(ChatGroupRecord, member.group_id)
                if group is not None:
                    channels.append(
                        ChatChannel('group', group.id, group.name, 'Grup sohbeti')
                    )
            return tuple(channels)

    def messages(
        self,
        player_id: str,
        *,
        channel_type: str,
        channel_key: str,
        limit: int = 80,
    ) -> tuple[ChatMessage, ...]:
        with self.database.session() as session:
            self._authorize_channel(session, player_id, channel_type, channel_key)
            rows = list(
                session.scalars(
                    select(ChatMessageRecord)
                    .where(
                        ChatMessageRecord.channel_type == channel_type,
                        ChatMessageRecord.channel_key == channel_key,
                    )
                    .order_by(ChatMessageRecord.created_at.desc())
                    .limit(min(max(limit, 1), 120))
                )
            )
            rows.reverse()
            result: list[ChatMessage] = []
            for row in rows:
                sender = session.get(PlayerRecord, row.sender_player_id)
                result.append(
                    ChatMessage(
                        message_id=row.id,
                        channel_type=row.channel_type,
                        channel_key=row.channel_key,
                        sender_player_id=row.sender_player_id,
                        sender_display_name=sender.display_name if sender else 'Oyuncu',
                        message=row.message,
                        created_at=row.created_at,
                    )
                )
            return tuple(result)

    def send_message(
        self,
        player_id: str,
        *,
        channel_type: str,
        channel_key: str,
        message: str,
    ) -> ChatMessage:
        clean = message.strip()
        if not 1 <= len(clean) <= 500:
            raise ChatError('invalid_message', 'Mesaj 1-500 karakter olmalıdır.')
        with self.database.session() as session:
            self._authorize_channel(session, player_id, channel_type, channel_key)
            sender = self._require_player(session, player_id)
            record = ChatMessageRecord(
                id=self.id_source(),
                channel_type=channel_type,
                channel_key=channel_key,
                sender_player_id=player_id,
                message=clean,
                created_at=self.clock(),
            )
            session.add(record)
            session.flush()
            return ChatMessage(
                message_id=record.id,
                channel_type=channel_type,
                channel_key=channel_key,
                sender_player_id=player_id,
                sender_display_name=sender.display_name,
                message=record.message,
                created_at=record.created_at,
            )

    def create_group(
        self,
        player_id: str,
        *,
        name: str,
        member_player_ids: list[str],
    ) -> ChatChannel:
        clean = name.strip()
        if not 2 <= len(clean) <= 40:
            raise ChatError('invalid_group_name', 'Grup adı 2-40 karakter olmalıdır.')
        unique_members = list(dict.fromkeys([player_id, *member_player_ids]))
        if len(unique_members) < 2 or len(unique_members) > 12:
            raise ChatError('invalid_group_size', 'Grup 2-12 oyuncudan oluşmalıdır.')
        now = self.clock()
        with self.database.session() as session:
            self._require_player(session, player_id)
            for member_id in unique_members:
                self._require_player(session, member_id)
                if member_id != player_id and not self._are_friends(session, player_id, member_id):
                    raise ChatError('group_member_not_friend', 'Gruba yalnız arkadaşlarını ekleyebilirsin.')
            group = ChatGroupRecord(
                id=self.id_source(),
                name=clean,
                owner_player_id=player_id,
                created_at=now,
            )
            session.add(group)
            session.flush()
            for member_id in unique_members:
                session.add(
                    ChatGroupMemberRecord(
                        group_id=group.id,
                        player_id=member_id,
                        joined_at=now,
                    )
                )
            return ChatChannel('group', group.id, group.name, 'Grup sohbeti')

    @staticmethod
    def direct_key(left: str, right: str) -> str:
        return ':'.join(sorted((left, right)))

    def _authorize_channel(self, session, player_id: str, channel_type: str, channel_key: str) -> None:
        self._require_player(session, player_id)
        if channel_type == 'server' and channel_key == 'global':
            return
        if channel_type == 'clan':
            membership = session.scalar(
                select(ClanMemberRecord).where(
                    ClanMemberRecord.player_id == player_id,
                    ClanMemberRecord.clan_id == channel_key,
                )
            )
            if membership is not None:
                return
        elif channel_type == 'group':
            membership = session.get(ChatGroupMemberRecord, (channel_key, player_id))
            if membership is not None:
                return
        elif channel_type == 'direct':
            parts = channel_key.split(':')
            if len(parts) == 2 and player_id in parts:
                other = parts[0] if parts[1] == player_id else parts[1]
                if self._are_friends(session, player_id, other):
                    return
        raise ChatError('chat_access_denied', 'Bu sohbet kanalına erişimin yok.', status_code=403)

    @staticmethod
    def _are_friends(session, left: str, right: str) -> bool:
        return session.scalar(
            select(FriendRequestRecord.id).where(
                FriendRequestRecord.status == 'accepted',
                or_(
                    and_(
                        FriendRequestRecord.sender_player_id == left,
                        FriendRequestRecord.receiver_player_id == right,
                    ),
                    and_(
                        FriendRequestRecord.sender_player_id == right,
                        FriendRequestRecord.receiver_player_id == left,
                    ),
                ),
            )
        ) is not None

    @staticmethod
    def _require_player(session, player_id: str) -> PlayerRecord:
        player = session.get(PlayerRecord, player_id)
        if player is None:
            raise ChatError('player_not_found', 'Oyuncu bulunamadı.', status_code=404)
        return player
