from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime, timedelta
from pathlib import Path

from relay_api.alpha import AlphaSafetyError, AlphaSafetyService
from relay_api.database import Database
from relay_api.db_models import AlphaFeedbackRecord, PlayerRecord


class AlphaSafetyServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        path = Path(self.temp.name) / "alpha.db"
        self.database = Database(f"sqlite+pysqlite:///{path}")
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 8, 1, 8, 0, tzinfo=UTC)
        with self.database.session() as session:
            session.add(
                PlayerRecord(
                    id="player-a",
                    display_name="MaviRole",
                    created_at=self.now,
                    last_seen_at=self.now,
                )
            )
        self.service = AlphaSafetyService(
            self.database,
            clock=lambda: self.now,
            id_source=lambda: f"feedback-{self.now.minute}",
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def test_match_rate_limit_resets_after_window(self) -> None:
        for _ in range(20):
            self.service.guard_async_match("player-a")
        with self.assertRaises(AlphaSafetyError):
            self.service.guard_async_match("player-a")
        self.now += timedelta(minutes=1, seconds=1)
        self.service.guard_async_match("player-a")
        self.assertEqual(self.service.snapshot("player-a").match_requests, 1)

    def test_feedback_is_persisted_and_limited(self) -> None:
        for index in range(3):
            self.now += timedelta(minutes=1)
            receipt = self.service.submit_feedback(
                "player-a",
                category="denge",
                message=f"Geri bildirim {index}",
                client_version="0.7.0",
            )
            self.assertEqual(receipt.category, "denge")
        with self.assertRaises(AlphaSafetyError):
            self.service.submit_feedback(
                "player-a",
                category="hata",
                message="Dördüncü geri bildirim",
                client_version="0.7.0",
            )
        with self.database.session() as session:
            self.assertEqual(session.query(AlphaFeedbackRecord).count(), 3)


if __name__ == "__main__":
    unittest.main()
