from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path

from relay_api.database import Database
from relay_api.db_models import PlayerProgressionRecord, PlayerRecord, SeasonEntryRecord
from relay_api.progression import ProgressionService
from relay_api.season import SeasonError, SeasonService, season_window
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


def _match(match_id: str, now: datetime, winner: str | None = "left") -> StoredMatch:
    return StoredMatch(
        match_id=match_id,
        created_at=now,
        source="async",
        requester_player_id="player-a",
        opponent_player_id="player-b",
        opponent=OpponentSnapshot(
            kind="player",
            opponent_id="player-b",
            display_name="BakirAkım",
            description="Test",
        ),
        player_board=_board("A", "A"),
        opponent_board=_board("B", "B"),
        result={
            "winner": winner,
            "reason": "test",
            "ticks": 1,
            "seed": 1,
            "left": {},
            "right": {},
            "decision": {"criterion": "test", "metrics": []},
            "replay_checksum": "0" * 64,
            "events": [],
            "state_frames": [],
        },
    )


class SeasonServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "season.db"
        self.database = Database(f"sqlite+pysqlite:///{path}")
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 8, 1, 8, 0, tzinfo=UTC)
        with self.database.session() as session:
            session.add_all(
                [
                    PlayerRecord(
                        id="player-a",
                        display_name="MaviRole",
                        created_at=self.now,
                        last_seen_at=self.now,
                    ),
                    PlayerRecord(
                        id="player-b",
                        display_name="BakirAkım",
                        created_at=self.now,
                        last_seen_at=self.now,
                    ),
                ]
            )
        self.store = DatabaseMatchStore(self.database)
        self.progression = ProgressionService(
            self.database,
            clock=lambda: self.now,
            id_source=lambda: "reward-id",
        )
        self.service = SeasonService(
            self.database,
            self.progression,
            clock=lambda: self.now,
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def test_calendar_month_is_one_season(self) -> None:
        window = season_window(self.now)
        self.assertEqual(window.key, "2026-08")
        self.assertEqual(window.starts_at.day, 1)
        self.assertEqual(window.ends_at.month, 9)

    def test_real_player_match_is_recorded_once_for_both_players(self) -> None:
        match = _match("season-win", self.now)
        self.store.save(match)
        change = self.service.record_match(match)
        duplicate = self.service.record_match(match)

        self.assertIsNotNone(change)
        self.assertEqual(change.points_gained, 5)
        self.assertEqual(change.total_points, 5)
        self.assertIsNone(duplicate)
        requester = self.service.snapshot("player-a")
        opponent = self.service.snapshot("player-b")
        self.assertEqual(requester.entry.points, 5)
        self.assertEqual(requester.entry.wins, 1)
        self.assertEqual(opponent.entry.points, 1)
        self.assertEqual(opponent.entry.losses, 1)

    def test_bot_fallback_does_not_grant_season_points(self) -> None:
        match = _match("season-bot", self.now)
        match = StoredMatch(
            match_id=match.match_id,
            created_at=match.created_at,
            source=match.source,
            requester_player_id=match.requester_player_id,
            opponent_player_id=None,
            opponent=OpponentSnapshot(
                kind="bot",
                opponent_id="starter_laser",
                display_name="Başlangıç Lazeri",
                description="Bot",
            ),
            player_board=match.player_board,
            opponent_board=match.opponent_board,
            result=match.result,
        )
        self.store.save(match)
        self.service.record_match(match)

        snapshot = self.service.snapshot("player-a")
        self.assertEqual(snapshot.entry.points, 0)
        self.assertEqual(snapshot.entry.matches, 0)

    def test_locked_tier_rejects_then_claim_is_idempotent(self) -> None:
        with self.assertRaises(SeasonError):
            self.service.claim_tier("player-a", 1)
        with self.database.session() as session:
            session.add(
                SeasonEntryRecord(
                    season_key="2026-08",
                    player_id="player-a",
                    points=12,
                    matches=3,
                    wins=2,
                    draws=0,
                    losses=1,
                    claimed_tiers=[],
                    created_at=self.now,
                    updated_at=self.now,
                )
            )
        first = self.service.claim_tier("player-a", 1)
        second = self.service.claim_tier("player-a", 1)
        self.assertEqual(first.total_xp_after, second.total_xp_after)
        with self.database.session() as session:
            progression = session.get(PlayerProgressionRecord, "player-a")
            self.assertEqual(progression.total_xp, 20)
            self.assertEqual(progression.credits, 8)
        self.assertTrue(self.service.snapshot("player-a").tiers[0].claimed)


if __name__ == "__main__":
    unittest.main()
