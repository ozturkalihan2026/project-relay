from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path

from relay_api.chat import ChatError, ChatService
from relay_api.database import Database
from relay_api.db_models import ClanMemberRecord, ClanRecord, FriendRequestRecord, PlayerRecord


class ChatServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.database = Database(f"sqlite+pysqlite:///{Path(self.temp.name) / 'chat.db'}")
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 8, 8, 0, 0, tzinfo=UTC)
        with self.database.session() as session:
            session.add_all([
                PlayerRecord(id='a', display_name='MaviRole-A', created_at=self.now, last_seen_at=self.now),
                PlayerRecord(id='b', display_name='MaviRole-B', created_at=self.now, last_seen_at=self.now),
                PlayerRecord(id='c', display_name='MaviRole-C', created_at=self.now, last_seen_at=self.now),
                FriendRequestRecord(id='f1', sender_player_id='a', receiver_player_id='b', status='accepted', created_at=self.now, updated_at=self.now),
                ClanRecord(id='clan-1', name='Devre', tag='DVR', description='Test', leader_player_id='a', is_open=True, created_at=self.now, updated_at=self.now),
                ClanMemberRecord(clan_id='clan-1', player_id='a', role='leader', joined_at=self.now),
                ClanMemberRecord(clan_id='clan-1', player_id='b', role='member', joined_at=self.now),
            ])
        ids=iter(['m1','g1','m2','m3'])
        self.service=ChatService(self.database, clock=lambda: self.now, id_source=lambda: next(ids))

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def test_server_clan_direct_and_group_channels(self) -> None:
        channels=self.service.channels('a')
        kinds={item.channel_type for item in channels}
        self.assertTrue({'server','clan','direct'}.issubset(kinds))
        direct=next(item for item in channels if item.channel_type=='direct')
        sent=self.service.send_message('a', channel_type='direct', channel_key=direct.channel_key, message='Selam')
        self.assertEqual(sent.message, 'Selam')
        self.assertEqual(len(self.service.messages('b', channel_type='direct', channel_key=direct.channel_key)), 1)
        group=self.service.create_group('a', name='Taktik', member_player_ids=['b'])
        self.assertEqual(group.channel_type, 'group')
        self.assertTrue(any(item.channel_key==group.channel_key for item in self.service.channels('b')))

    def test_direct_chat_requires_friendship(self) -> None:
        key=self.service.direct_key('a','c')
        with self.assertRaises(ChatError) as denied:
            self.service.send_message('a', channel_type='direct', channel_key=key, message='Merhaba')
        self.assertEqual(denied.exception.code, 'chat_access_denied')


if __name__ == '__main__':
    unittest.main()
