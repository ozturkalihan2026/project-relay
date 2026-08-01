from __future__ import annotations

import unittest

from fastapi.testclient import TestClient

from relay_api.app import create_app
from relay_api.config import Settings
from relay_api.database import Database


class SocialApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.database = Database("sqlite+pysqlite:///:memory:")
        self.database.create_schema_for_tests()
        settings = Settings(
            database_url="sqlite+pysqlite:///:memory:",
            jwt_secret="test-secret-with-at-least-thirty-two-characters",
        )
        self.client = TestClient(create_app(settings=settings, database=self.database))
        self.first = self.client.post("/api/v1/auth/guest").json()
        self.second = self.client.post("/api/v1/auth/guest").json()
        self.first_headers = {
            "Authorization": f"Bearer {self.first['tokens']['access_token']}"
        }
        self.second_headers = {
            "Authorization": f"Bearer {self.second['tokens']['access_token']}"
        }

    def tearDown(self) -> None:
        self.database.dispose()

    def test_friend_and_clan_flow(self) -> None:
        updated = self.client.put(
            "/api/v1/me/social/profile",
            headers=self.first_headers,
            json={
                "status_message": "Kalkan ağı kuruyor.",
                "favorite_module": "shield",
            },
        )
        self.assertEqual(updated.status_code, 200, updated.text)
        self.assertEqual(updated.json()["profile"]["favorite_module"], "shield")

        second_name = self.second["player"]["display_name"]
        search = self.client.get(
            "/api/v1/social/players",
            headers=self.first_headers,
            params={"query": second_name[:4]},
        )
        self.assertEqual(search.status_code, 200, search.text)
        target = search.json()["players"][0]
        self.assertEqual(target["player_id"], self.second["player"]["player_id"])

        sent = self.client.post(
            f"/api/v1/me/friends/requests/{target['player_id']}",
            headers=self.first_headers,
        )
        self.assertEqual(sent.status_code, 200, sent.text)
        incoming = self.client.get(
            "/api/v1/me/social", headers=self.second_headers
        ).json()["incoming_requests"]
        self.assertEqual(len(incoming), 1)

        accepted = self.client.post(
            f"/api/v1/me/friends/requests/{incoming[0]['request_id']}/accept",
            headers=self.second_headers,
        )
        self.assertEqual(accepted.status_code, 200, accepted.text)
        self.assertEqual(accepted.json()["profile"]["friend_count"], 1)

        clan = self.client.post(
            "/api/v1/clans",
            headers=self.first_headers,
            json={
                "name": "Neon Muhafızlar",
                "tag": "NEON",
                "description": "Savunma ve karşı devre odaklı açık klan.",
            },
        )
        self.assertEqual(clan.status_code, 201, clan.text)
        clan_id = clan.json()["clan"]["clan_id"]

        joined = self.client.post(
            f"/api/v1/clans/{clan_id}/join",
            headers=self.second_headers,
        )
        self.assertEqual(joined.status_code, 200, joined.text)
        self.assertEqual(joined.json()["clan"]["member_count"], 2)

        leader_leave = self.client.post(
            "/api/v1/me/clan/leave",
            headers=self.first_headers,
        )
        self.assertEqual(leader_leave.status_code, 409, leader_leave.text)
        self.assertEqual(leader_leave.json()["code"], "leader_cannot_leave")


if __name__ == "__main__":
    unittest.main()
