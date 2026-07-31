from __future__ import annotations

import tempfile
import unittest
from datetime import UTC, datetime
from pathlib import Path

from relay_api.collection import CollectionError, CollectionService
from relay_api.database import Database
from relay_api.db_models import PlayerProgressionRecord, PlayerRecord
from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement


class CollectionServiceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        url = f"sqlite+pysqlite:///{Path(self.temp.name) / 'collection.db'}"
        self.database = Database(url)
        self.database.create_schema_for_tests()
        self.now = datetime(2026, 7, 31, 18, 0, tzinfo=UTC)
        with self.database.session() as session:
            session.add(
                PlayerRecord(
                    id="player-a",
                    display_name="BakirAkım-6200",
                    created_at=self.now,
                    last_seen_at=self.now,
                )
            )
        self.service = CollectionService(
            self.database,
            clock=lambda: self.now,
        )

    def tearDown(self) -> None:
        self.database.dispose()
        self.temp.cleanup()

    def test_initial_snapshot_owns_starters_and_has_eight_slot_kit(self) -> None:
        snapshot = self.service.snapshot("player-a")

        self.assertEqual(snapshot.credits, 0)
        self.assertEqual(len(snapshot.kit.module_kinds), 8)
        self.assertEqual(
            snapshot.kit.module_kinds.count(ModuleKind.GENERATOR),
            1,
        )
        starters = [item for item in snapshot.cosmetics if item.credit_cost == 0]
        self.assertEqual(len(starters), 3)
        self.assertTrue(all(item.owned and item.equipped for item in starters))

    def test_purchase_deducts_credits_and_equips_cosmetic(self) -> None:
        with self.database.session() as session:
            session.add(
                PlayerProgressionRecord(
                    player_id="player-a",
                    total_xp=0,
                    credits=500,
                    matches_completed=0,
                    wins=0,
                    draws=0,
                    losses=0,
                    created_at=self.now,
                    updated_at=self.now,
                )
            )

        snapshot = self.service.purchase("player-a", "module_coral_pulse")

        self.assertEqual(snapshot.credits, 280)
        item = next(
            item
            for item in snapshot.cosmetics
            if item.cosmetic_id == "module_coral_pulse"
        )
        self.assertTrue(item.owned)
        self.assertTrue(item.equipped)

    def test_purchase_rejects_insufficient_credits(self) -> None:
        with self.assertRaises(CollectionError) as context:
            self.service.purchase("player-a", "frame_ranked_gold")
        self.assertEqual(context.exception.code, "insufficient_credits")

    def test_kit_requires_eight_slots_and_exactly_one_generator(self) -> None:
        with self.assertRaises(CollectionError) as context:
            self.service.save_kit(
                "player-a",
                name="Eksik Kit",
                module_kinds=[ModuleKind.GENERATOR, ModuleKind.LASER],
            )
        self.assertEqual(context.exception.code, "kit_size_invalid")

        with self.assertRaises(CollectionError) as context:
            self.service.save_kit(
                "player-a",
                name="Çift Jeneratör",
                module_kinds=[
                    ModuleKind.GENERATOR,
                    ModuleKind.GENERATOR,
                    ModuleKind.LASER,
                    ModuleKind.LASER,
                    ModuleKind.SHIELD,
                    ModuleKind.COOLER,
                    ModuleKind.AMPLIFIER,
                    ModuleKind.REPAIR,
                ],
            )
        self.assertEqual(context.exception.code, "kit_generator_invalid")

    def test_saved_board_must_fit_active_kit_counts(self) -> None:
        self.service.save_kit(
            "player-a",
            name="Savunma Kiti",
            module_kinds=[
                ModuleKind.GENERATOR,
                ModuleKind.BATTERY,
                ModuleKind.LASER,
                ModuleKind.SHIELD,
                ModuleKind.SHIELD,
                ModuleKind.COOLER,
                ModuleKind.AMPLIFIER,
                ModuleKind.REPAIR,
            ],
        )
        board = BoardLayout(
            name="Aşırı Lazer",
            modules=(
                ModulePlacement(
                    module_id="GEN",
                    kind=ModuleKind.GENERATOR,
                    row=0,
                    column=1,
                    orientation=Direction.SOUTH,
                ),
                ModulePlacement(
                    module_id="LASER-1",
                    kind=ModuleKind.LASER,
                    row=0,
                    column=2,
                    orientation=Direction.EAST,
                ),
                ModulePlacement(
                    module_id="LASER-2",
                    kind=ModuleKind.LASER,
                    row=0,
                    column=3,
                    orientation=Direction.EAST,
                ),
            ),
        )
        with self.assertRaises(CollectionError) as context:
            self.service.validate_board("player-a", board)
        self.assertEqual(context.exception.code, "board_exceeds_active_kit")


if __name__ == "__main__":
    unittest.main()
