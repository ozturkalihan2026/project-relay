from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime, timedelta
from pathlib import Path

from fastapi.testclient import TestClient

from relay_api.app import create_app
from relay_api.config import Settings
from relay_api.database import Database
from relay_api.online import OnlinePlayService
from relay_api.service import MatchService
from relay_api.store import DatabaseMatchStore
from relay_engine import compute_replay_checksum

def player_board() -> dict:
    return {
        "name": "Test Devresi",
        "modules": [
            {
                "module_id": "P-GEN",
                "kind": "generator",
                "row": 0,
                "column": 1,
                "orientation": "south",
                "level": 1,
            },
            {
                "module_id": "P-LASER",
                "kind": "laser",
                "row": 0,
                "column": 2,
                "orientation": "east",
                "level": 1,
            },
            {
                "module_id": "P-COOL-OFFLINE",
                "kind": "cooler",
                "row": 3,
                "column": 0,
                "orientation": "east",
                "level": 1,
            },
        ],
    }


class _AdvancingClock:
    def __init__(self) -> None:
        self.current = datetime(2026, 7, 29, 12, 0, tzinfo=UTC)

    def __call__(self) -> datetime:
        value = self.current
        self.current += timedelta(seconds=1)
        return value


class OnlineApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        database_path = (
            Path(self.temporary_directory.name) / "project-relay-test.db"
        )
        self.database_url = f"sqlite+pysqlite:///{database_path}"
        self.settings = Settings(
            database_url=self.database_url,
            jwt_secret="online-test-secret-with-at-least-32-characters",
            recent_opponent_limit=3,
        )
        self.database = Database(self.database_url)
        self.database.create_schema_for_tests()
        self.clock = _AdvancingClock()
        self.match_number = 0

        def next_match_id() -> str:
            self.match_number += 1
            return f"async-match-{self.match_number:04d}"

        self.match_service = MatchService(
            store=DatabaseMatchStore(self.database),
            seed_source=lambda: 4040 + self.match_number,
            id_source=next_match_id,
            clock=self.clock,
        )
        self.online_service = OnlinePlayService(
            self.database,
            self.match_service,
            self.settings,
            clock=self.clock,
        )
        self.app = create_app(
            self.match_service,
            settings=self.settings,
            database=self.database,
            online_service=self.online_service,
        )
        self.client = TestClient(self.app)

    def tearDown(self) -> None:
        self.client.close()
        self.database.dispose()
        self.temporary_directory.cleanup()

    def _guest(self) -> dict:
        response = self.client.post("/api/v1/auth/guest")
        self.assertEqual(response.status_code, 201, response.text)
        return response.json()

    @staticmethod
    def _authorization(guest: dict) -> dict[str, str]:
        return {
            "Authorization": (
                f"Bearer {guest['tokens']['access_token']}"
            )
        }

    def _save_board(self, guest: dict, board: dict | None = None) -> dict:
        response = self.client.put(
            "/api/v1/me/board",
            headers=self._authorization(guest),
            json=board or player_board(),
        )
        self.assertEqual(response.status_code, 200, response.text)
        return response.json()

    def test_guest_account_has_safe_name_and_authenticated_profile(self) -> None:
        guest = self._guest()

        self.assertRegex(
            guest["player"]["display_name"],
            r"^[A-Za-z]+[A-Za-z]+-\d{4}$",
        )
        self.assertEqual(guest["tokens"]["token_type"], "bearer")
        profile = self.client.get(
            "/api/v1/me",
            headers=self._authorization(guest),
        )

        self.assertEqual(profile.status_code, 200, profile.text)
        self.assertEqual(
            profile.json()["player"]["player_id"],
            guest["player"]["player_id"],
        )
        self.assertIsNone(profile.json()["board"])

    def test_refresh_token_rotates_and_cannot_be_reused(self) -> None:
        guest = self._guest()
        old_refresh = guest["tokens"]["refresh_token"]

        rotated = self.client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": old_refresh},
        )
        reused = self.client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": old_refresh},
        )

        self.assertEqual(rotated.status_code, 200, rotated.text)
        self.assertNotEqual(
            rotated.json()["tokens"]["refresh_token"],
            old_refresh,
        )
        self.assertEqual(reused.status_code, 401, reused.text)
        self.assertEqual(
            reused.json()["code"],
            "refresh_token_reused",
        )

    def test_protected_routes_reject_missing_access_token(self) -> None:
        profile = self.client.get("/api/v1/me")
        save = self.client.put(
            "/api/v1/me/board",
            json=player_board(),
        )
        match = self.client.post("/api/v1/matches/async")
        career = self.client.get("/api/v1/me/career")
        history = self.client.get("/api/v1/me/matches")
        league = self.client.get("/api/v1/league/current")
        progression = self.client.get("/api/v1/me/progression")
        statistics = self.client.get("/api/v1/me/statistics")

        self.assertEqual(profile.status_code, 401)
        self.assertEqual(save.status_code, 401)
        self.assertEqual(match.status_code, 401)
        self.assertEqual(career.status_code, 401)
        self.assertEqual(history.status_code, 401)
        self.assertEqual(league.status_code, 401)
        self.assertEqual(progression.status_code, 401)
        self.assertEqual(statistics.status_code, 401)
        self.assertEqual(
            match.json()["code"],
            "authorization_required",
        )

    def test_current_board_is_upserted_and_returned_from_profile(self) -> None:
        guest = self._guest()
        first = self._save_board(guest)
        changed = player_board()
        changed["name"] = "Güncel Devre"
        second = self._save_board(guest, changed)
        profile = self.client.get(
            "/api/v1/me",
            headers=self._authorization(guest),
        )

        self.assertEqual(first["board_id"], second["board_id"])
        self.assertNotEqual(first["fingerprint"], second["fingerprint"])
        self.assertEqual(
            profile.json()["board"]["board"]["name"],
            "Güncel Devre",
        )
        self.assertEqual(
            profile.json()["board"]["powered_module_ids"],
            ["P-GEN", "P-LASER"],
        )

    def test_async_match_requires_a_saved_board(self) -> None:
        guest = self._guest()

        response = self.client.post(
            "/api/v1/matches/async",
            headers=self._authorization(guest),
        )

        self.assertEqual(response.status_code, 409, response.text)
        self.assertEqual(response.json()["code"], "board_required")

    def test_async_match_uses_other_player_with_equal_module_count(self) -> None:
        first = self._guest()
        second = self._guest()
        self._save_board(first)
        second_board = player_board()
        second_board["name"] = "İkinci Oyuncu Devresi"
        self._save_board(second, second_board)

        response = self.client.post(
            "/api/v1/matches/async",
            headers=self._authorization(first),
        )

        self.assertEqual(response.status_code, 201, response.text)
        payload = response.json()
        self.assertEqual(payload["source"], "async")
        self.assertEqual(payload["opponent"]["kind"], "player")
        self.assertEqual(
            payload["opponent"]["opponent_id"],
            second["player"]["player_id"],
        )
        self.assertNotEqual(
            payload["opponent"]["opponent_id"],
            first["player"]["player_id"],
        )
        self.assertEqual(
            len(payload["player_board"]["modules"]),
            len(payload["opponent_board"]["modules"]),
        )
        self.assertIsNotNone(payload["rating_change"])
        self.assertIsNotNone(payload["progression_reward"])
        self.assertIsNotNone(payload["season_change"])
        self.assertIn(payload["season_change"]["points_gained"], {1, 3, 5})
        self.assertEqual(
            payload["season_change"]["total_points"],
            payload["season_change"]["points_gained"],
        )
        self.assertGreater(payload["progression_reward"]["xp"], 0)
        self.assertGreater(payload["progression_reward"]["credits"], 0)
        self.assertIn(
            payload["rating_change"]["outcome"],
            {"win", "draw", "loss"},
        )
        career = self.client.get(
            "/api/v1/me/career",
            headers=self._authorization(first),
        )
        history = self.client.get(
            "/api/v1/me/matches",
            headers=self._authorization(first),
        )
        league = self.client.get(
            "/api/v1/league/current",
            headers=self._authorization(first),
        )
        progression = self.client.get(
            "/api/v1/me/progression",
            headers=self._authorization(first),
        )
        statistics = self.client.get(
            "/api/v1/me/statistics",
            headers=self._authorization(first),
        )
        season = self.client.get(
            "/api/v1/me/season",
            headers=self._authorization(first),
        )
        self.assertEqual(career.status_code, 200, career.text)
        self.assertEqual(history.status_code, 200, history.text)
        self.assertEqual(league.status_code, 200, league.text)
        self.assertEqual(progression.status_code, 200, progression.text)
        self.assertEqual(statistics.status_code, 200, statistics.text)
        self.assertEqual(season.status_code, 200, season.text)
        self.assertEqual(career.json()["profile"]["rated_matches"], 1)
        self.assertEqual(history.json()["total"], 1)
        self.assertTrue(history.json()["items"][0]["rated"])
        self.assertGreaterEqual(league.json()["league"]["position"], 1)
        self.assertEqual(progression.json()["profile"]["matches_completed"], 1)
        self.assertEqual(len(progression.json()["daily_missions"]), 3)
        self.assertEqual(statistics.json()["profile"]["rated_matches"], 1)
        self.assertEqual(
            season.json()["entry"]["points"],
            payload["season_change"]["points_gained"],
        )

    def test_progression_reward_daily_claim_and_achievement_are_idempotent(
        self,
    ) -> None:
        first = self._guest()
        second = self._guest()
        self._save_board(first)
        self._save_board(second)
        headers = self._authorization(first)

        created = self.client.post(
            "/api/v1/matches/async",
            headers=headers,
        )
        self.assertEqual(created.status_code, 201, created.text)
        reward = created.json()["progression_reward"]
        self.assertGreater(reward["xp"], 0)
        self.assertGreater(reward["credits"], 0)

        snapshot = self.client.get(
            "/api/v1/me/progression",
            headers=headers,
        )
        self.assertEqual(snapshot.status_code, 200, snapshot.text)
        first_signal = next(
            mission
            for mission in snapshot.json()["daily_missions"]
            if mission["mission_id"] == "first_signal"
        )
        self.assertTrue(first_signal["completed"])
        self.assertFalse(first_signal["claimed"])

        claimed = self.client.post(
            "/api/v1/me/daily-missions/first_signal/claim",
            headers=headers,
        )
        claimed_again = self.client.post(
            "/api/v1/me/daily-missions/first_signal/claim",
            headers=headers,
        )
        self.assertEqual(claimed.status_code, 200, claimed.text)
        self.assertEqual(claimed.json(), claimed_again.json())

        achievement = self.client.post(
            "/api/v1/me/achievements/first_battle/claim",
            headers=headers,
        )
        locked = self.client.post(
            "/api/v1/me/achievements/circuit_veteran/claim",
            headers=headers,
        )
        self.assertEqual(achievement.status_code, 200, achievement.text)
        self.assertEqual(locked.status_code, 409, locked.text)
        self.assertEqual(locked.json()["code"], "achievement_locked")

    def test_recent_opponent_is_not_repeated_and_bot_is_safe_fallback(
        self,
    ) -> None:
        first = self._guest()
        second = self._guest()
        self._save_board(first)
        self._save_board(second)
        headers = self._authorization(first)

        first_match = self.client.post(
            "/api/v1/matches/async",
            headers=headers,
        )
        second_match = self.client.post(
            "/api/v1/matches/async",
            headers=headers,
        )

        self.assertEqual(
            first_match.json()["opponent"]["kind"],
            "player",
        )
        self.assertEqual(
            second_match.json()["opponent"]["kind"],
            "bot",
        )
        self.assertIn(
            "yeni oyuncu",
            second_match.json()["opponent"]["description"],
        )
        self.assertIsNotNone(first_match.json()["rating_change"])
        self.assertIsNone(second_match.json()["rating_change"])
        self.assertIsNone(second_match.json()["season_change"])
        self.assertIsNotNone(second_match.json()["progression_reward"])
        career = self.client.get(
            "/api/v1/me/career",
            headers=headers,
        ).json()
        self.assertEqual(career["profile"]["rated_matches"], 1)
        self.assertEqual(career["matchmaking"]["searches"], 2)
        self.assertEqual(career["matchmaking"]["human_opponents"], 1)
        self.assertEqual(career["matchmaking"]["bot_fallbacks"], 1)

    def test_postgresql_sized_seed_is_persisted_for_async_match(self) -> None:
        guest = self._guest()
        self._save_board(guest)
        large_seed = (1 << 62) + 2026
        match_service = MatchService(
            store=DatabaseMatchStore(self.database),
            seed_source=lambda: large_seed,
            id_source=lambda: "large-seed-match",
            clock=self.clock,
        )
        online_service = OnlinePlayService(
            self.database,
            match_service,
            self.settings,
            clock=self.clock,
        )
        app = create_app(
            match_service,
            settings=self.settings,
            database=self.database,
            online_service=online_service,
        )

        with TestClient(app) as client:
            response = client.post(
                "/api/v1/matches/async",
                headers=self._authorization(guest),
            )
            persisted = client.get(
                "/api/v1/matches/large-seed-match",
                headers=self._authorization(guest),
            )

        self.assertEqual(response.status_code, 201, response.text)
        self.assertEqual(response.json()["result"]["seed"], large_seed)
        self.assertEqual(persisted.status_code, 200, persisted.text)
        self.assertEqual(persisted.json()["result"]["seed"], large_seed)

    def test_persisted_match_and_replay_survive_app_recreation(self) -> None:
        first = self._guest()
        second = self._guest()
        self._save_board(first)
        self._save_board(second)
        headers = self._authorization(first)
        created = self.client.post(
            "/api/v1/matches/async",
            headers=headers,
        ).json()

        replacement_database = Database(self.database_url)
        replacement_app = create_app(
            settings=self.settings,
            database=replacement_database,
        )
        with TestClient(replacement_app) as replacement_client:
            match = replacement_client.get(
                f"/api/v1/matches/{created['match_id']}",
                headers=headers,
            )
            replay = replacement_client.get(
                f"/api/v1/matches/{created['match_id']}/replay",
                headers=headers,
            )
        replacement_database.dispose()

        self.assertEqual(match.status_code, 200, match.text)
        self.assertEqual(replay.status_code, 200, replay.text)
        self.assertEqual(
            replay.json()["checksum"],
            created["replay"]["checksum"],
        )
        self.assertEqual(
            replay.json()["checksum"],
            compute_replay_checksum(replay.json()["events"]),
        )

    def test_private_async_replay_allows_participants_only(self) -> None:
        first = self._guest()
        second = self._guest()
        stranger = self._guest()
        self._save_board(first)
        second_board = player_board()
        second_board["name"] = "İkinci Oyuncu Devresi"
        self._save_board(second, second_board)
        created = self.client.post(
            "/api/v1/matches/async",
            headers=self._authorization(first),
        ).json()
        path = f"/api/v1/matches/{created['match_id']}/replay"

        anonymous = self.client.get(path)
        participant = self.client.get(
            path,
            headers=self._authorization(second),
        )
        participant_match = self.client.get(
            f"/api/v1/matches/{created['match_id']}",
            headers=self._authorization(second),
        )
        denied = self.client.get(
            path,
            headers=self._authorization(stranger),
        )

        self.assertEqual(anonymous.status_code, 401)
        self.assertEqual(participant.status_code, 200, participant.text)
        self.assertEqual(
            participant_match.json()["player_board"]["name"],
            "İkinci Oyuncu Devresi",
        )
        self.assertEqual(
            participant_match.json()["opponent"]["opponent_id"],
            first["player"]["player_id"],
        )
        self.assertEqual(
            participant_match.json()["replay"]["checksum"],
            participant.json()["checksum"],
        )
        self.assertEqual(
            participant.json()["checksum"],
            compute_replay_checksum(participant.json()["events"]),
        )
        self.assertEqual(denied.status_code, 403)
        self.assertEqual(denied.json()["code"], "match_access_denied")
