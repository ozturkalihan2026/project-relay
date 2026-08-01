from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path

from relay_api.database import Database
from relay_api.db_models import ClanRecord, FriendRequestRecord, PlayerRecord
from relay_api.social import SocialError, SocialService


class SocialServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "social.db"
        self.database = Database(f"sqlite+pysqlite:///{path}")
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 8, 1, 20, 0, tzinfo=UTC)
        with self.database.session() as session:
            session.add_all(
                [
                    PlayerRecord(
                        id="player-a",
                        display_name="MaviRole-1001",
                        created_at=self.now,
                        last_seen_at=self.now,
                    ),
                    PlayerRecord(
                        id="player-b",
                        display_name="NeonBobin-1002",
                        created_at=self.now,
                        last_seen_at=self.now,
                    ),
                    PlayerRecord(
                        id="player-c",
                        display_name="KeskinDiyot-1003",
                        created_at=self.now,
                        last_seen_at=self.now,
                    ),
                ]
            )
        ids = iter(["request-1", "clan-1", "request-2", "clan-2"])
        self.service = SocialService(
            self.database,
            clock=lambda: self.now,
            id_source=lambda: next(ids),
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def test_profile_defaults_update_and_player_search(self) -> None:
        snapshot = self.service.snapshot("player-a")
        self.assertEqual(snapshot.profile.favorite_module, "generator")
        self.assertEqual(snapshot.profile.friend_count, 0)

        updated = self.service.update_profile(
            "player-a",
            status_message="Kalkan ağı kuruyor.",
            favorite_module="shield",
        )
        self.assertEqual(updated.profile.status_message, "Kalkan ağı kuruyor.")
        self.assertEqual(updated.profile.favorite_module, "shield")

        results = self.service.search_players("player-a", "Neon")
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0].player_id, "player-b")
        self.assertEqual(results[0].relationship, "none")

    def test_friend_request_acceptance_and_removal(self) -> None:
        sender = self.service.send_friend_request("player-a", "player-b")
        self.assertEqual(len(sender.outgoing_requests), 1)
        receiver = self.service.snapshot("player-b")
        self.assertEqual(len(receiver.incoming_requests), 1)

        accepted = self.service.respond_friend_request(
            "player-b",
            receiver.incoming_requests[0].request_id,
            accept=True,
        )
        self.assertEqual(accepted.profile.friend_count, 1)
        self.assertEqual(accepted.friends[0].player_id, "player-a")
        self.assertEqual(self.service.snapshot("player-a").profile.friend_count, 1)

        removed = self.service.remove_friend("player-a", "player-b")
        self.assertEqual(removed.profile.friend_count, 0)
        with self.database.session() as session:
            self.assertIsNone(session.get(FriendRequestRecord, "request-1"))

    def test_duplicate_or_self_friend_request_is_rejected(self) -> None:
        with self.assertRaises(SocialError) as self_error:
            self.service.send_friend_request("player-a", "player-a")
        self.assertEqual(self_error.exception.code, "self_friend_request")

        self.service.send_friend_request("player-a", "player-b")
        with self.assertRaises(SocialError) as duplicate:
            self.service.send_friend_request("player-b", "player-a")
        self.assertEqual(duplicate.exception.code, "request_exists")

    def test_clan_create_join_leave_rules(self) -> None:
        leader = self.service.create_clan(
            "player-a",
            name="Neon Muhafızlar",
            tag="NEON",
            description="Karşı devre ve savunma odaklı açık klan.",
        )
        self.assertIsNotNone(leader.clan)
        self.assertEqual(leader.clan.member_count, 1)
        self.assertEqual(leader.clan.members[0].role, "leader")

        directory = self.service.list_clans("player-b")
        self.assertEqual(len(directory), 1)
        joined = self.service.join_clan("player-b", directory[0].clan_id)
        self.assertEqual(joined.clan.member_count, 2)

        with self.assertRaises(SocialError) as leader_leave:
            self.service.leave_clan("player-a")
        self.assertEqual(leader_leave.exception.code, "leader_cannot_leave")

        self.assertIsNone(self.service.leave_clan("player-b").clan)
        self.assertIsNone(self.service.leave_clan("player-a").clan)
        with self.database.session() as session:
            self.assertIsNone(session.get(ClanRecord, "request-1"))


if __name__ == "__main__":
    unittest.main()
