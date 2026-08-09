from __future__ import annotations

import os
import unittest
os.environ.setdefault('RELAY_DATABASE_URL', 'sqlite+pysqlite:///:memory:')
os.environ.setdefault('RELAY_JWT_SECRET', 'test-secret-with-at-least-thirty-two-characters')
from fastapi.testclient import TestClient

from relay_api.app import create_app
from relay_api.config import Settings
from relay_api.database import Database


class ChatApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.database = Database('sqlite+pysqlite:///:memory:')
        self.database.create_schema_for_tests()
        settings = Settings(
            database_url='sqlite+pysqlite:///:memory:',
            jwt_secret='test-secret-with-at-least-thirty-two-characters',
        )
        self.client = TestClient(create_app(settings=settings, database=self.database))
        self.first = self.client.post('/api/v1/auth/guest').json()
        self.second = self.client.post('/api/v1/auth/guest').json()
        self.h1 = {'Authorization': f"Bearer {self.first['tokens']['access_token']}"}
        self.h2 = {'Authorization': f"Bearer {self.second['tokens']['access_token']}"}

    def tearDown(self) -> None:
        self.database.dispose()

    def test_server_and_direct_chat_flow(self) -> None:
        server = self.client.get('/api/v1/chat/channels', headers=self.h1)
        self.assertEqual(server.status_code, 200, server.text)
        self.assertEqual(server.json()['channels'][0]['channel_type'], 'server')
        sent = self.client.post(
            '/api/v1/chat/messages',
            headers=self.h1,
            json={'channel_type': 'server', 'channel_key': 'global', 'message': 'Merhaba devre!'},
        )
        self.assertEqual(sent.status_code, 200, sent.text)

        second_id = self.second['player']['player_id']
        req = self.client.post(f'/api/v1/me/friends/requests/{second_id}', headers=self.h1)
        self.assertEqual(req.status_code, 200, req.text)
        incoming = self.client.get('/api/v1/me/social', headers=self.h2).json()['incoming_requests'][0]
        accepted = self.client.post(
            f"/api/v1/me/friends/requests/{incoming['request_id']}/accept",
            headers=self.h2,
        )
        self.assertEqual(accepted.status_code, 200, accepted.text)
        direct = next(
            item for item in self.client.get('/api/v1/chat/channels', headers=self.h1).json()['channels']
            if item['channel_type'] == 'direct'
        )
        private = self.client.post(
            '/api/v1/chat/messages',
            headers=self.h1,
            json={'channel_type': 'direct', 'channel_key': direct['channel_key'], 'message': 'Özel sinyal'},
        )
        self.assertEqual(private.status_code, 200, private.text)
        read = self.client.get(
            '/api/v1/chat/messages',
            headers=self.h2,
            params={'channel_type': 'direct', 'channel_key': direct['channel_key']},
        )
        self.assertEqual(read.status_code, 200, read.text)
        self.assertEqual(read.json()['messages'][-1]['message'], 'Özel sinyal')


if __name__ == '__main__':
    unittest.main()
