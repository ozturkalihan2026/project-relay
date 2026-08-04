from __future__ import annotations

import unittest
from datetime import UTC, datetime

from fastapi.testclient import TestClient

from relay_api.app import create_app
from relay_api.config import Settings
from relay_api.database import Database
from relay_api.service import MatchService
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

def max_powered_board() -> dict:
    return {
        "name": "Altı Modüllük Kart",
        "modules": [
            {
                "module_id": "MAX-GEN",
                "kind": "generator",
                "row": 0,
                "column": 1,
                "orientation": "south",
                "level": 1,
            },
            {
                "module_id": "MAX-BAT",
                "kind": "battery",
                "row": 1,
                "column": 3,
                "orientation": "east",
                "level": 1,
            },
            {
                "module_id": "MAX-LASER",
                "kind": "laser",
                "row": 0,
                "column": 2,
                "orientation": "east",
                "level": 1,
            },
            {
                "module_id": "MAX-PULSE",
                "kind": "pulse_cannon",
                "row": 0,
                "column": 3,
                "orientation": "north",
                "level": 1,
            },
            {
                "module_id": "MAX-SHIELD",
                "kind": "shield",
                "row": 2,
                "column": 3,
                "orientation": "south",
                "level": 1,
            },
            {
                "module_id": "MAX-COOL",
                "kind": "cooler",
                "row": 3,
                "column": 2,
                "orientation": "south",
                "level": 1,
            },
        ],
    }


class RelayApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.database = Database("sqlite+pysqlite:///:memory:")
        self.database.create_schema_for_tests()
        settings = Settings(
            database_url="sqlite+pysqlite:///:memory:",
            jwt_secret="test-secret-with-at-least-thirty-two-characters",
        )
        service = MatchService(
            seed_source=lambda: 2026,
            id_source=lambda: "match-test-001",
            clock=lambda: datetime(2026, 7, 27, 12, 0, tzinfo=UTC),
        )
        self.client = TestClient(
            create_app(
                service,
                settings=settings,
                database=self.database,
            )
        )

    def _create_match(self) -> dict:
        response = self.client.post(
            "/api/v1/matches/bot",
            json={"board": player_board(), "bot_id": "starter_laser"},
        )
        self.assertEqual(response.status_code, 201, response.text)
        return response.json()

    def test_health_reports_version_and_database_storage(self) -> None:
        response = self.client.get("/healthz")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["version"], "0.8.3")
        self.assertEqual(response.json()["rules_version"], "0.8")
        self.assertEqual(response.json()["storage"], "sqlite")
        self.assertEqual(response.json()["database"], "ok")

    def test_career_run_api_exposes_authoritative_full_preview(self) -> None:
        guest_response = self.client.post("/api/v1/auth/guest")
        self.assertEqual(guest_response.status_code, 201, guest_response.text)
        guest = guest_response.json()
        headers = {
            "Authorization": f"Bearer {guest['tokens']['access_token']}"
        }

        idle = self.client.get("/api/v1/me/career-run", headers=headers)
        self.assertEqual(idle.status_code, 200, idle.text)
        self.assertEqual(idle.json()["status"], "idle")
        self.assertTrue(idle.json()["board_required"])

        saved = self.client.put(
            "/api/v1/me/career-board",
            headers=headers,
            json=player_board(),
        )
        self.assertEqual(saved.status_code, 200, saved.text)
        self.assertEqual(saved.json()["board"]["name"], player_board()["name"])

        profile = self.client.get("/api/v1/me", headers=headers)
        self.assertEqual(profile.status_code, 200, profile.text)
        self.assertIsNone(profile.json()["board"])
        career_board = self.client.get(
            "/api/v1/me/career-board", headers=headers
        )
        self.assertEqual(career_board.status_code, 200, career_board.text)

        started = self.client.post(
            "/api/v1/me/career-run/start", headers=headers
        )
        self.assertEqual(started.status_code, 200, started.text)
        payload = started.json()
        self.assertEqual(payload["status"], "active")
        self.assertEqual(payload["total_stages"], 5)
        self.assertEqual(payload["opponent"]["stage_number"], 1)
        self.assertEqual(
            len(payload["opponent"]["board"]["modules"]),
            len(player_board()["modules"]),
        )
        self.assertTrue(payload["can_battle"])

        refreshed = self.client.get("/api/v1/me/career-run", headers=headers)
        self.assertEqual(refreshed.status_code, 200, refreshed.text)
        self.assertEqual(
            refreshed.json()["opponent"]["board"],
            payload["opponent"]["board"],
        )


    def test_collection_api_exposes_starters_and_saves_controlled_kit(self) -> None:
        guest_response = self.client.post("/api/v1/auth/guest")
        self.assertEqual(guest_response.status_code, 201, guest_response.text)
        guest = guest_response.json()
        headers = {
            "Authorization": f"Bearer {guest['tokens']['access_token']}"
        }

        collection = self.client.get(
            "/api/v1/me/collection",
            headers=headers,
        )
        self.assertEqual(collection.status_code, 200, collection.text)
        payload = collection.json()
        self.assertEqual(len(payload["kit"]["module_kinds"]), 8)
        self.assertEqual(
            payload["kit"]["module_kinds"].count("generator"),
            1,
        )
        self.assertEqual(
            len([item for item in payload["cosmetics"] if item["owned"]]),
            3,
        )

        saved = self.client.put(
            "/api/v1/me/kit",
            headers=headers,
            json={
                "name": "Savunma Sekizlisi",
                "module_kinds": [
                    "generator",
                    "battery",
                    "laser",
                    "shield",
                    "shield",
                    "cooler",
                    "amplifier",
                    "repair",
                ],
            },
        )
        self.assertEqual(saved.status_code, 200, saved.text)
        self.assertEqual(saved.json()["kit"]["name"], "Savunma Sekizlisi")

        rejected = self.client.put(
            "/api/v1/me/board",
            headers=headers,
            json={
                "name": "Kit Dışı Devre",
                "modules": [
                    {
                        "module_id": "G",
                        "kind": "generator",
                        "row": 0,
                        "column": 1,
                        "orientation": "south",
                        "level": 1,
                    },
                    {
                        "module_id": "L1",
                        "kind": "laser",
                        "row": 0,
                        "column": 2,
                        "orientation": "east",
                        "level": 1,
                    },
                    {
                        "module_id": "L2",
                        "kind": "laser",
                        "row": 0,
                        "column": 3,
                        "orientation": "east",
                        "level": 1,
                    },
                ],
            },
        )
        self.assertEqual(rejected.status_code, 409, rejected.text)
        self.assertEqual(
            rejected.json()["code"],
            "board_exceeds_active_kit",
        )

    def test_match_result_explains_server_decision_metrics(self) -> None:
        payload = self._create_match()
        decision = payload["result"]["decision"]

        self.assertIn(
            decision["criterion"],
            {
                "core_destroyed",
                "mutual_core_destruction",
                "core_hp_ratio",
                "surviving_modules",
                "module_hp_ratio",
                "total_damage",
                "damage_efficiency",
                "total_heat",
                "exact_draw",
            },
        )
        self.assertEqual(
            [metric["key"] for metric in decision["metrics"]],
            [
                "core_hp_ratio",
                "surviving_modules",
                "module_hp_ratio",
                "total_damage",
                "damage_efficiency",
                "total_heat",
            ],
        )
        self.assertTrue(
            all(metric["preferred"] in {"higher", "lower"}
                for metric in decision["metrics"])
        )

    def test_catalog_exposes_all_eight_modules(self) -> None:
        response = self.client.get("/api/v1/modules")

        self.assertEqual(response.status_code, 200)
        modules = response.json()["modules"]
        self.assertEqual(len(modules), 8)
        self.assertTrue(all(module["description"] for module in modules))
        self.assertIn(
            "dört yöne aktarır",
            next(
                module["description"]
                for module in modules
                if module["kind"] == "battery"
            ),
        )
        generator = next(
            module for module in modules if module["kind"] == "generator"
        )
        battery = next(
            module for module in modules if module["kind"] == "battery"
        )
        amplifier = next(
            module for module in modules if module["kind"] == "amplifier"
        )
        self.assertEqual(len(generator["ports"]), 3)
        self.assertEqual(len(battery["ports"]), 4)
        self.assertEqual(len(amplifier["ports"]), 4)
        self.assertIn("çekirdeği", generator["description"])
        self.assertIn("yönsüz enerji kavşağı", battery["description"])
        self.assertIn("oku hangi komşu modülün", amplifier["description"])
        self.assertEqual(
            {module["kind"] for module in modules},
            {
                "generator",
                "battery",
                "laser",
                "pulse_cannon",
                "shield",
                "cooler",
                "amplifier",
                "repair",
            },
        )

    def test_bot_catalog_has_nine_server_boards(self) -> None:
        response = self.client.get("/api/v1/bots")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            {bot["bot_id"] for bot in response.json()["bots"]},
            {
                "starter_laser",
                "battery_pulse",
                "balanced",
                "laser_swarm",
                "pulse_volley",
                "shield_wall",
                "fortress",
                "repair_guard",
                "amplified_pulse",
            },
        )
        self.assertTrue(
            all(
                bot["available_module_counts"] == [1, 2, 3, 4, 5, 6]
                for bot in response.json()["bots"]
            )
        )

    def test_board_validation_reports_powered_and_unpowered_modules(self) -> None:
        response = self.client.post(
            "/api/v1/boards/validate",
            json=player_board(),
        )

        self.assertEqual(response.status_code, 200, response.text)
        payload = response.json()
        self.assertTrue(payload["valid"])
        self.assertEqual(payload["module_count"], 3)
        self.assertEqual(payload["powered_module_ids"], ["P-GEN", "P-LASER"])
        self.assertEqual(payload["unpowered_module_ids"], ["P-COOL-OFFLINE"])

    def test_board_validation_accepts_all_four_connection_directions(self) -> None:
        cases = {
            "east": ((0, 1, "south"), (0, 2)),
            "west": ((0, 1, "south"), (0, 0)),
            "south": ((2, 0, "east"), (3, 0)),
            "north": ((2, 0, "east"), (1, 0)),
        }
        for orientation, (generator_data, endpoint) in cases.items():
            with self.subTest(orientation=orientation):
                generator_row, generator_column, generator_orientation = (
                    generator_data
                )
                row, column = endpoint
                board = {
                    "name": f"{orientation} bağlantısı",
                    "modules": [
                        {
                            "module_id": "P-GEN",
                            "kind": "generator",
                            "row": generator_row,
                            "column": generator_column,
                            "orientation": generator_orientation,
                            "level": 1,
                        },
                        {
                            "module_id": "P-SHIELD",
                            "kind": "shield",
                            "row": row,
                            "column": column,
                            "orientation": orientation,
                            "level": 1,
                        },
                    ],
                }

                response = self.client.post(
                    "/api/v1/boards/validate",
                    json=board,
                )

                self.assertEqual(response.status_code, 200, response.text)
                self.assertEqual(
                    response.json()["powered_module_ids"],
                    ["P-GEN", "P-SHIELD"],
                )
        self.assertEqual(
            response.json()["unpowered_module_ids"],
            [],
        )

    def test_board_validation_powers_all_six_allowed_modules(
        self,
    ) -> None:
        board = max_powered_board()

        response = self.client.post("/api/v1/boards/validate", json=board)

        self.assertEqual(response.status_code, 200, response.text)
        payload = response.json()
        self.assertEqual(payload["module_count"], 6)
        self.assertEqual(payload["unpowered_module_ids"], [])
        self.assertEqual(
            set(payload["powered_module_ids"]),
            {module["module_id"] for module in board["modules"]},
        )

    def test_board_validation_rejects_more_than_six_modules(self) -> None:
        board = max_powered_board()
        board["modules"].append(
            {
                "module_id": "MAX-EXTRA",
                "kind": "battery",
                "row": 3,
                "column": 3,
                "orientation": "east",
                "level": 1,
            }
        )

        response = self.client.post("/api/v1/boards/validate", json=board)

        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "board_validation_failed")
        self.assertIn("en fazla 6 modül", response.json()["message"])

    def test_domain_invalid_board_uses_stable_error_contract(self) -> None:
        board = player_board()
        board["modules"][1]["row"] = 0
        board["modules"][1]["column"] = 1

        response = self.client.post("/api/v1/boards/validate", json=board)

        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "board_validation_failed")
        self.assertIn("Aynı hücre", response.json()["message"])

    def test_board_validation_rejects_core_cells(self) -> None:
        board = player_board()
        board["modules"][2]["row"] = 2
        board["modules"][2]["column"] = 2

        response = self.client.post("/api/v1/boards/validate", json=board)

        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "board_validation_failed")
        self.assertIn("pasif çekirdeğe", response.json()["message"])

    def test_board_validation_rejects_generator_away_from_a_core_gate(
        self,
    ) -> None:
        board = player_board()
        board["modules"][0]["row"] = 0
        board["modules"][0]["column"] = 0

        response = self.client.post("/api/v1/boards/validate", json=board)

        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "board_validation_failed")
        self.assertIn("dört kapı", response.json()["message"])

    def test_request_validation_rejects_unknown_fields(self) -> None:
        board = player_board()
        board["unexpected"] = True

        response = self.client.post("/api/v1/boards/validate", json=board)

        self.assertEqual(response.status_code, 422)
        self.assertEqual(response.json()["code"], "request_validation_failed")

    def test_bot_match_returns_summary_without_embedding_events(self) -> None:
        payload = self._create_match()

        self.assertEqual(payload["match_id"], "match-test-001")
        self.assertEqual(payload["result"]["seed"], 2026)
        self.assertEqual(
            payload["opponent"]["opponent_id"],
            "starter_laser",
        )
        self.assertEqual(payload["opponent"]["kind"], "bot")
        self.assertEqual(payload["source"], "bot")
        self.assertEqual(payload["player_board"], player_board())
        self.assertEqual(
            payload["opponent_board"]["name"],
            "Kıvılcım • 3M",
        )
        self.assertEqual(len(payload["opponent_board"]["modules"]), 3)
        self.assertEqual(
            len(payload["player_board"]["modules"]),
            len(payload["opponent_board"]["modules"]),
        )
        self.assertNotIn("events", payload["result"])
        self.assertNotIn("state_frames", payload["result"])
        self.assertGreater(payload["replay"]["event_count"], 0)
        self.assertEqual(
            payload["replay"]["checksum"],
            payload["result"]["replay_checksum"],
        )

    def test_server_matches_equal_module_counts_from_one_to_six(self) -> None:
        full_board = max_powered_board()
        for module_count in range(1, 7):
            with self.subTest(module_count=module_count):
                board = {
                    "name": f"{module_count} Modüllük Oyuncu",
                    "modules": full_board["modules"][:module_count],
                }
                response = self.client.post(
                    "/api/v1/matches/bot",
                    json={"board": board, "bot_id": "starter_laser"},
                )

                self.assertEqual(response.status_code, 201, response.text)
                payload = response.json()
                self.assertEqual(
                    len(payload["player_board"]["modules"]),
                    module_count,
                )
                self.assertEqual(
                    len(payload["opponent_board"]["modules"]),
                    module_count,
                )

    def test_match_and_replay_can_be_read_separately(self) -> None:
        created = self._create_match()

        match_response = self.client.get("/api/v1/matches/match-test-001")
        replay_response = self.client.get(
            "/api/v1/matches/match-test-001/replay"
        )

        self.assertEqual(match_response.status_code, 200)
        self.assertEqual(replay_response.status_code, 200)
        replay = replay_response.json()
        self.assertEqual(replay["checksum"], created["replay"]["checksum"])
        self.assertEqual(
            replay["checksum"],
            compute_replay_checksum(replay["events"]),
        )
        self.assertEqual(
            len(replay["state_frames"]),
            created["result"]["ticks"] + 1,
        )
        self.assertEqual(replay["state_frames"][0]["tick"], 0)
        self.assertEqual(
            replay["state_frames"][-1]["left"]["core_hp"],
            created["result"]["left"]["core_hp"],
        )
        first_module = replay["state_frames"][0]["left"]["modules"][0]
        self.assertEqual(
            {
                "module_id",
                "hp",
                "max_hp",
                "heat",
                "cooldown",
                "powered",
                "overheated",
            },
            set(first_module),
        )

    def test_replay_verification_accepts_correct_and_rejects_wrong_checksum(
        self,
    ) -> None:
        created = self._create_match()

        correct = self.client.post(
            "/api/v1/replays/verify",
            json={
                "match_id": created["match_id"],
                "checksum": created["replay"]["checksum"],
            },
        )
        wrong = self.client.post(
            "/api/v1/replays/verify",
            json={
                "match_id": created["match_id"],
                "checksum": "0" * 64,
            },
        )

        self.assertEqual(correct.status_code, 200)
        self.assertTrue(correct.json()["valid"])
        self.assertEqual(wrong.status_code, 200)
        self.assertFalse(wrong.json()["valid"])
        self.assertEqual(
            wrong.json()["actual_checksum"],
            created["replay"]["checksum"],
        )

    def test_missing_bot_and_match_return_404(self) -> None:
        missing_bot = self.client.post(
            "/api/v1/matches/bot",
            json={"board": player_board(), "bot_id": "unknown"},
        )
        missing_match = self.client.get("/api/v1/matches/not-found")

        self.assertEqual(missing_bot.status_code, 404)
        self.assertEqual(missing_bot.json()["code"], "bot_not_found")
        self.assertEqual(missing_match.status_code, 404)
        self.assertEqual(missing_match.json()["code"], "match_not_found")

    def test_season_and_closed_alpha_endpoints_are_authenticated(self) -> None:
        guest_response = self.client.post("/api/v1/auth/guest")
        self.assertEqual(guest_response.status_code, 201, guest_response.text)
        token = guest_response.json()["tokens"]["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        season = self.client.get("/api/v1/me/season", headers=headers)
        safety = self.client.get("/api/v1/me/alpha-safety", headers=headers)
        feedback = self.client.post(
            "/api/v1/alpha/feedback",
            headers=headers,
            json={
                "category": "arayuz",
                "message": "Sezon ekranı test geri bildirimi.",
                "client_version": "0.8.3",
            },
        )

        self.assertEqual(season.status_code, 200, season.text)
        self.assertEqual(season.json()["entry"]["points"], 0)
        self.assertEqual(len(season.json()["tiers"]), 4)
        self.assertEqual(safety.status_code, 200, safety.text)
        self.assertTrue(safety.json()["server_authoritative_results"])
        self.assertTrue(safety.json()["idempotent_rewards"])
        self.assertEqual(feedback.status_code, 201, feedback.text)
        self.assertEqual(feedback.json()["category"], "arayuz")

    def test_local_flutter_web_origin_passes_cors_preflight(self) -> None:
        response = self.client.options(
            "/api/v1/modules",
            headers={
                "Origin": "http://localhost:54321",
                "Access-Control-Request-Method": "GET",
            },
        )

        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(
            response.headers["access-control-allow-origin"],
            "http://localhost:54321",
        )
        self.assertIn("GET", response.headers["access-control-allow-methods"])


if __name__ == "__main__":
    unittest.main()
