from __future__ import annotations

import itertools
import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path

from relay_api.career import CareerRunError, CareerRunService
from relay_api.config import Settings
from relay_api.database import Database
from relay_api.db_models import (
    CareerRunRecord,
    PlayerProgressionRecord,
    PlayerRecord,
)
from relay_api.online import OnlinePlayService
from relay_api.progression import ProgressionService
from relay_api.service import MatchService
from relay_api.store import DatabaseMatchStore, OpponentSnapshot, StoredMatch
from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement


def _board() -> BoardLayout:
    return BoardLayout(
        name="Kariyer Test Devresi",
        modules=(
            ModulePlacement(
                module_id="P-GEN",
                kind=ModuleKind.GENERATOR,
                row=0,
                column=1,
                orientation=Direction.SOUTH,
            ),
            ModulePlacement(
                module_id="P-LASER",
                kind=ModuleKind.LASER,
                row=0,
                column=2,
                orientation=Direction.EAST,
            ),
            ModulePlacement(
                module_id="P-COOL",
                kind=ModuleKind.COOLER,
                row=0,
                column=3,
                orientation=Direction.EAST,
            ),
        ),
    )


class ScriptedMatchService(MatchService):
    def __init__(self, database: Database, winners: list[str | None]) -> None:
        ids = (f"career-match-{i}" for i in itertools.count(1))
        super().__init__(
            store=DatabaseMatchStore(database),
            id_source=lambda: next(ids),
            seed_source=lambda: 61,
            clock=lambda: datetime(2026, 7, 31, 12, 0, tzinfo=UTC),
        )
        self.winners = iter(winners)
        self.last_player_modifiers = None

    def create_match(
        self,
        *,
        player_board,
        opponent_board,
        opponent: OpponentSnapshot,
        source: str,
        requester_player_id=None,
        opponent_player_id=None,
        player_modifiers=None,
        opponent_modifiers=None,
    ) -> StoredMatch:
        self.last_player_modifiers = player_modifiers
        winner = next(self.winners)
        match = StoredMatch(
            match_id=self.id_source(),
            created_at=self.clock(),
            source=source,
            requester_player_id=requester_player_id,
            opponent_player_id=opponent_player_id,
            opponent=opponent,
            player_board=player_board,
            opponent_board=opponent_board,
            result={
                "winner": winner,
                "reason": "scripted",
                "ticks": 1,
                "seed": 61,
                "left": {},
                "right": {},
                "decision": {"criterion": "scripted", "metrics": []},
                "replay_checksum": "0" * 64,
                "events": [],
                "state_frames": [],
            },
        )
        self.store.save(match)
        return match


class CareerRunServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "career.db"
        self.database = Database(f"sqlite+pysqlite:///{path}")
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 7, 31, 12, 0, tzinfo=UTC)
        with self.database.session() as session:
            session.add(
                PlayerRecord(
                    id="player-a",
                    display_name="MaviRole-1001",
                    created_at=self.now,
                    last_seen_at=self.now,
                )
            )
        self.settings = Settings(
            database_url=f"sqlite+pysqlite:///{path}",
            jwt_secret="test-secret-with-at-least-thirty-two-characters",
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def _service(self, winners: list[str | None]):
        matches = ScriptedMatchService(self.database, winners)
        online = OnlinePlayService(
            self.database,
            matches,
            self.settings,
            clock=lambda: self.now,
            id_source=lambda: "board-a",
        )
        progression = ProgressionService(
            self.database,
            clock=lambda: self.now,
            id_source=(lambda counter=itertools.count(1): f"grant-{next(counter)}"),
        )
        run_ids = (f"run-{index}" for index in itertools.count(1))
        career = CareerRunService(
            self.database,
            matches,
            online,
            progression,
            clock=lambda: self.now,
            id_source=lambda: next(run_ids),
        )
        return career, online, progression, matches

    def test_start_requires_saved_board(self) -> None:
        career, _, _, _ = self._service(["left"])
        with self.assertRaises(CareerRunError) as context:
            career.start("player-a")
        self.assertEqual(context.exception.code, "board_required")

    def test_start_is_idempotent_while_run_is_active(self) -> None:
        career, _, _, _ = self._service(["left"])
        career.save_board("player-a", _board())

        first = career.start("player-a")
        second = career.start("player-a")

        self.assertEqual(first.run_id, second.run_id)
        self.assertEqual(second.status, "active")

    def test_start_exposes_exact_full_opponent_board_preview(self) -> None:
        career, _, _, _ = self._service(["left"])
        career.save_board("player-a", _board())
        run = career.start("player-a")

        self.assertEqual(run.status, "active")
        self.assertEqual(run.opponent.stage_number, 1)
        self.assertEqual(run.opponent.total_stages, 5)
        self.assertEqual(len(run.opponent.board.modules), 3)
        result = career.battle("player-a")
        self.assertEqual(
            result.match.opponent_board.to_dict(),
            run.opponent.board.to_dict(),
        )
        self.assertEqual(result.run.status, "active")
        self.assertEqual(result.run.stage_index, 1)
        self.assertEqual(result.run.offered_boosters, ())

    def test_five_wins_complete_run_and_reward_once(self) -> None:
        career, _, progression, matches = self._service(["left"] * 5)
        career.save_board("player-a", _board())
        progression.snapshot("player-a")
        with self.database.session() as session:
            record = session.get(PlayerProgressionRecord, "player-a")
            assert record is not None
            record.credits = 200

        run = career.start("player-a")
        for stage in range(4):
            result = career.battle("player-a")
            run = result.run
            if stage < 3:
                self.assertEqual(run.status, "active")
                self.assertEqual(run.offered_boosters, ())
            else:
                self.assertEqual(run.status, "awaiting_booster")
                self.assertEqual(len(run.offered_boosters), 3)

        overcharge = next(
            item for item in run.offered_boosters
            if item.booster_id == "overcharge"
        )
        self.assertEqual(overcharge.credit_cost, 75)
        run = career.select_booster("player-a", "overcharge")
        self.assertEqual(run.status, "active")
        self.assertEqual(run.opponent.stage_number, 5)
        self.assertEqual(
            progression.snapshot("player-a").profile.credits,
            125,
        )

        run = career.battle("player-a").run
        self.assertEqual(run.status, "completed")
        self.assertEqual(run.wins, 5)
        self.assertEqual(run.reward.xp, 300)
        self.assertEqual(run.reward.credits, 190)
        self.assertEqual(
            progression.career_reward("player-a", run.run_id),
            run.reward,
        )
        self.assertGreater(
            matches.last_player_modifiers.generator_output_multiplier,
            1.0,
        )
        self.assertEqual(
            progression.snapshot("player-a").profile.credits,
            315,
        )
        restarted = career.start("player-a")
        self.assertEqual(restarted.status, "active")
        self.assertEqual(restarted.selected_boosters, ())

    def test_booster_can_be_skipped_before_boss(self) -> None:
        career, _, _, _ = self._service(["left"] * 4)
        career.save_board("player-a", _board())
        career.start("player-a")
        run = None
        for _ in range(4):
            run = career.battle("player-a").run
        assert run is not None
        self.assertEqual(run.status, "awaiting_booster")

        advanced = career.select_booster("player-a", "none")

        self.assertEqual(advanced.status, "active")
        self.assertEqual(advanced.opponent.stage_number, 5)
        self.assertEqual(advanced.selected_boosters, ())

    def test_career_board_is_independent_from_async_pvp_board(self) -> None:
        career, online, _, _ = self._service([])
        online.save_board("player-a", _board())
        career_board = BoardLayout(
            name="Ayrı Kariyer Devresi",
            modules=tuple(
                module if module.module_id != "P-COOL" else ModulePlacement(
                    module_id=module.module_id,
                    kind=module.kind,
                    row=3,
                    column=2,
                    orientation=Direction.NORTH,
                )
                for module in _board().modules
            ),
        )
        career.save_board("player-a", career_board)

        saved_online = online.get_board("player-a")
        saved_career = career.get_board(
            "player-a", clone_online_if_missing=False
        )

        self.assertIsNotNone(saved_online)
        self.assertIsNotNone(saved_career)
        self.assertEqual(saved_online.board.to_dict(), _board().to_dict())
        self.assertEqual(saved_career.board.to_dict(), career_board.to_dict())
        self.assertNotEqual(saved_online.fingerprint, saved_career.fingerprint)

    def test_terminal_read_repairs_missing_idempotent_reward(self) -> None:
        career, _, progression, _ = self._service([])
        career.save_board("player-a", _board())
        with self.database.session() as session:
            session.add(
                CareerRunRecord(
                    id="run-repair",
                    player_id="player-a",
                    status="failed",
                    stage_index=2,
                    wins=2,
                    selected_boosters=["overcharge"],
                    offered_boosters=[],
                    last_match_id=None,
                    started_at=self.now,
                    updated_at=self.now,
                    ended_at=self.now,
                )
            )

        repaired = career.current("player-a")

        self.assertEqual(repaired.status, "failed")
        self.assertEqual(repaired.reward.xp, 60)
        self.assertEqual(repaired.reward.credits, 36)
        self.assertEqual(
            progression.career_reward("player-a", "run-repair"),
            repaired.reward,
        )

    def test_non_win_fails_and_clears_active_effects_for_new_run(self) -> None:
        career, _, _, _ = self._service([None])
        career.save_board("player-a", _board())
        career.start("player-a")
        result = career.battle("player-a")
        self.assertEqual(result.run.status, "failed")
        self.assertEqual(result.run.wins, 0)
        self.assertEqual(result.run.reward.xp, 0)
        self.assertEqual(result.run.reward.credits, 0)


if __name__ == "__main__":
    unittest.main()
