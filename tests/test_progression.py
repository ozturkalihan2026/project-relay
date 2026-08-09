from __future__ import annotations

import itertools
import tempfile
import unittest
from datetime import UTC, datetime, timedelta
from pathlib import Path

from relay_api.database import Database
from relay_api.db_models import PlayerProgressionRecord, PlayerRecord
from relay_api.progression import (
    ProgressionError,
    ProgressionService,
    level_progress,
    xp_required_for_level,
)
from relay_api.store import DatabaseMatchStore, OpponentSnapshot, StoredMatch
from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement


def _board(name: str, prefix: str) -> BoardLayout:
    return BoardLayout(
        name=name,
        modules=(
            ModulePlacement(
                module_id=f"{prefix}-GEN",
                kind=ModuleKind.GENERATOR,
                row=0,
                column=1,
                orientation=Direction.SOUTH,
            ),
        ),
    )


def _result(winner: str | None) -> dict:
    return {
        "winner": winner,
        "reason": "test_result",
        "ticks": 1,
        "seed": 7,
        "left": {},
        "right": {},
        "decision": {"criterion": "test", "metrics": []},
        "replay_checksum": "0" * 64,
        "events": [],
        "state_frames": [],
    }


class ProgressionServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "progression.db"
        self.database = Database(f"sqlite+pysqlite:///{path}")
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 7, 31, 9, 0, tzinfo=UTC)
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
                        display_name="BakirAkım-1002",
                        created_at=self.now,
                        last_seen_at=self.now,
                    ),
                ]
            )
        ids = (f"grant-{index}" for index in itertools.count(1))
        self.store = DatabaseMatchStore(self.database)
        self.service = ProgressionService(
            self.database,
            clock=lambda: self.now,
            id_source=lambda: next(ids),
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def _match(
        self,
        match_id: str,
        winner: str | None,
        *,
        source: str = "async",
        requester_player_id: str | None = "player-a",
    ) -> StoredMatch:
        match = StoredMatch(
            match_id=match_id,
            created_at=self.now,
            source=source,
            requester_player_id=requester_player_id,
            opponent_player_id="player-b" if source == "async" else None,
            opponent=OpponentSnapshot(
                kind="player" if source == "async" else "bot",
                opponent_id="player-b" if source == "async" else "balanced",
                display_name="BakirAkım-1002",
                description="Test rakibi",
            ),
            player_board=_board("A", "A"),
            opponent_board=_board("B", "B"),
            result=_result(winner),
        )
        self.store.save(match)
        return match

    def test_level_curve_increases_required_xp(self) -> None:
        self.assertEqual(xp_required_for_level(1), 100)
        self.assertEqual(xp_required_for_level(2), 125)
        self.assertEqual(xp_required_for_level(6), 237)
        self.assertEqual(xp_required_for_level(10), 425)
        self.assertEqual(level_progress(99), (1, 99, 100))
        self.assertEqual(level_progress(100), (2, 0, 125))
        self.assertEqual(level_progress(225), (3, 0, 150))

    def test_long_term_curve_slows_late_levels_without_changing_first_five(self) -> None:
        self.assertEqual(
            sum(xp_required_for_level(level) for level in range(1, 5)),
            550,
        )
        self.assertEqual(
            sum(xp_required_for_level(level) for level in range(1, 10)),
            1_960,
        )
        self.assertEqual(
            sum(xp_required_for_level(level) for level in range(1, 20)),
            9_255,
        )
        self.assertEqual(
            sum(xp_required_for_level(level) for level in range(1, 40)),
            55_745,
        )
        self.assertEqual(
            sum(xp_required_for_level(level) for level in range(1, 50)),
            102_940,
        )

    def test_initial_snapshot_exposes_goals_and_temporary_boosters(self) -> None:
        snapshot = self.service.snapshot("player-a")

        self.assertEqual(snapshot.profile.level, 1)
        self.assertEqual(snapshot.profile.credits, 0)
        self.assertEqual(len(snapshot.daily_missions), 10)
        self.assertEqual(len(snapshot.achievements), 28)
        self.assertEqual(len(snapshot.boosters), 4)
        self.assertTrue(snapshot.boosters[0].unlocked)
        self.assertIn("geçici", snapshot.boosters[0].description)
        self.assertTrue(snapshot.boosters[1].unlocked)

    def test_async_win_rewards_once_and_advances_daily_goals(self) -> None:
        match = self._match("win-match", "left")
        first = self.service.apply_match(match)
        second = self.service.apply_match(match)

        self.assertEqual(first, second)
        assert first is not None
        self.assertEqual(first.xp, 32)
        self.assertEqual(first.credits, 14)
        snapshot = self.service.snapshot("player-a")
        self.assertEqual(snapshot.profile.total_xp, 32)
        self.assertEqual(snapshot.profile.credits, 14)
        self.assertEqual(snapshot.profile.matches_completed, 1)
        self.assertEqual(snapshot.profile.wins, 1)
        missions = {item.mission_id: item for item in snapshot.daily_missions}
        self.assertEqual(missions["first_signal"].progress, 1)
        self.assertEqual(missions["steady_current"].progress, 1)
        self.assertEqual(missions["victory_pulse"].progress, 1)
        achievements = {
            item.achievement_id: item for item in snapshot.achievements
        }
        self.assertTrue(achievements["first_battle"].unlocked)
        self.assertTrue(achievements["first_victory"].unlocked)

    def test_daily_claim_is_idempotent_and_can_level_up(self) -> None:
        self.service.apply_match(self._match("daily-match", "left"))
        first = self.service.claim_daily_mission(
            "player-a",
            "first_signal",
        )
        second = self.service.claim_daily_mission(
            "player-a",
            "first_signal",
        )

        self.assertEqual(first, second)
        self.assertEqual(first.xp, 15)
        snapshot = self.service.snapshot("player-a")
        self.assertEqual(snapshot.profile.total_xp, 47)
        self.assertEqual(snapshot.profile.credits, 22)
        mission = next(
            item
            for item in snapshot.daily_missions
            if item.mission_id == "first_signal"
        )
        self.assertTrue(mission.claimed)

    def test_locked_achievement_cannot_be_claimed(self) -> None:
        with self.assertRaises(ProgressionError) as context:
            self.service.claim_achievement("player-a", "circuit_veteran")
        self.assertEqual(context.exception.code, "achievement_locked")

    def test_bot_training_does_not_award_progression(self) -> None:
        match = self._match(
            "bot-match",
            "left",
            source="bot",
            requester_player_id=None,
        )
        self.assertIsNone(self.service.apply_match(match))
        self.assertEqual(
            self.service.snapshot("player-a").profile.total_xp,
            0,
        )

    def test_daily_progress_resets_without_lifetime_leak(self) -> None:
        self.service.apply_match(self._match("day-one", "left"))
        self.now += timedelta(days=1)
        snapshot = self.service.snapshot("player-a")
        self.assertTrue(all(item.progress == 0 for item in snapshot.daily_missions))

    def test_level_ten_upgrades_only_temporary_booster_tiers(self) -> None:
        total = sum(xp_required_for_level(level) for level in range(1, 10))
        with self.database.session() as session:
            session.add(
                PlayerProgressionRecord(
                    player_id="player-a",
                    total_xp=total,
                    credits=0,
                    matches_completed=0,
                    wins=0,
                    draws=0,
                    losses=0,
                    created_at=self.now,
                    updated_at=self.now,
                )
            )

        snapshot = self.service.snapshot("player-a")
        self.assertEqual(snapshot.profile.level, 10)
        self.assertTrue(all(item.unlocked for item in snapshot.boosters))
        self.assertTrue(all(item.tier == 2 for item in snapshot.boosters))
        self.assertEqual(snapshot.boosters[0].effect_value, 8)


if __name__ == "__main__":
    unittest.main()
