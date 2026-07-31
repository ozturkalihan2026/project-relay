from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path

from relay_api.competitive import (
    CompetitiveService,
    calculate_elo_delta,
    league_window,
)
from relay_api.database import Database
from relay_api.db_models import PlayerRecord
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


class CompetitiveServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "competitive.db"
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
        self.store = DatabaseMatchStore(self.database)
        self.service = CompetitiveService(
            self.database,
            clock=lambda: self.now,
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def _match(
        self,
        match_id: str,
        winner: str | None,
        *,
        opponent_kind: str = "player",
        opponent_player_id: str | None = "player-b",
    ) -> StoredMatch:
        match = StoredMatch(
            match_id=match_id,
            created_at=self.now,
            source="async",
            requester_player_id="player-a",
            opponent_player_id=opponent_player_id,
            opponent=OpponentSnapshot(
                kind=opponent_kind,
                opponent_id=opponent_player_id or "balanced",
                display_name="BakirAkım-1002",
                description="Test rakibi",
            ),
            player_board=_board("A", "A"),
            opponent_board=_board("B", "B"),
            result=_result(winner),
        )
        self.store.save(match)
        return match

    def test_elo_delta_is_symmetric_and_rewards_underdog_more(self) -> None:
        favorite_win = calculate_elo_delta(1200, 1000, won=True)
        underdog_win = calculate_elo_delta(1000, 1200, won=True)
        favorite_loss = calculate_elo_delta(1200, 1000, won=False)

        self.assertGreater(underdog_win, favorite_win)
        self.assertEqual(favorite_loss, -underdog_win)

    def test_exact_draw_changes_no_rating_but_counts_for_league(self) -> None:
        change = self.service.apply_match(self._match("draw-match", None))
        self.assertIsNotNone(change)
        assert change is not None
        self.assertEqual(change.requester_delta, 0)
        self.assertEqual(change.opponent_delta, 0)

        first = self.service.career("player-a")
        second = self.service.career("player-b")
        self.assertEqual(first.profile.rating, 1000)
        self.assertEqual(second.profile.rating, 1000)
        self.assertEqual(first.profile.draws, 1)
        self.assertEqual(first.league.points, 1)
        self.assertEqual(second.league.points, 1)

    def test_decisive_match_is_conserved_and_idempotent(self) -> None:
        match = self._match("win-match", "left")
        first_change = self.service.apply_match(match)
        second_change = self.service.apply_match(match)
        self.assertEqual(first_change, second_change)
        assert first_change is not None
        self.assertEqual(
            first_change.requester_delta + first_change.opponent_delta,
            0,
        )
        self.assertGreater(first_change.requester_delta, 0)

        requester = self.service.career("player-a")
        opponent = self.service.career("player-b")
        self.assertEqual(requester.profile.rated_matches, 1)
        self.assertEqual(opponent.profile.rated_matches, 1)
        self.assertEqual(requester.profile.wins, 1)
        self.assertEqual(opponent.profile.losses, 1)
        self.assertEqual(requester.league.points, 3)
        self.assertEqual(opponent.league.points, 0)

    def test_bot_fallback_never_affects_rating(self) -> None:
        change = self.service.apply_match(
            self._match(
                "bot-match",
                "left",
                opponent_kind="bot",
                opponent_player_id=None,
            )
        )
        self.assertIsNone(change)
        career = self.service.career("player-a")
        self.assertEqual(career.profile.rated_matches, 0)
        self.assertEqual(career.profile.rating, 1000)
        self.assertEqual(career.league.position, 0)
        self.assertEqual(career.league.participant_count, 0)

    def test_viewing_career_does_not_join_weekly_league(self) -> None:
        first = self.service.career("player-a")
        second = self.service.career("player-b")

        self.assertEqual(first.league.position, 0)
        self.assertEqual(second.league.position, 0)
        self.assertEqual(first.league.participant_count, 0)
        self.assertEqual(second.league.participant_count, 0)
        self.assertEqual(first.leaderboard, ())

    def test_history_and_matchmaking_metrics_keep_replay_paths(self) -> None:
        self.service.apply_match(self._match("history-match", "right"))
        page = self.service.match_history("player-a")
        career = self.service.career("player-a")

        self.assertEqual(page.total, 1)
        self.assertEqual(page.items[0].outcome, "loss")
        self.assertTrue(page.items[0].rated)
        self.assertEqual(
            page.items[0].replay_path,
            "/api/v1/matches/history-match/replay",
        )
        self.assertEqual(career.matchmaking.searches, 1)
        self.assertEqual(career.matchmaking.human_opponents, 1)
        self.assertEqual(career.matchmaking.bot_fallbacks, 0)
        self.assertEqual(career.league.week_key, league_window(self.now).key)


if __name__ == "__main__":
    unittest.main()
