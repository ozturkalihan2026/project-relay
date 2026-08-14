from __future__ import annotations

import unittest

from relay_engine import (
    BattleConfig,
    BoardLayout,
    CircuitBattleEngine,
    Direction,
    EventType,
    InterventionError,
    ModuleKind,
    ModulePlacement,
    ReserveModule,
    Side,
)


def placement(
    module_id: str,
    kind: ModuleKind,
    row: int,
    column: int,
    orientation: Direction = Direction.EAST,
) -> ModulePlacement:
    return ModulePlacement(module_id, kind, row, column, orientation)


def passive_board(prefix: str, *, with_laser: bool) -> BoardLayout:
    modules = [
        placement(
            f"{prefix}-GEN",
            ModuleKind.GENERATOR,
            0,
            1,
            Direction.SOUTH,
        )
    ]
    if with_laser:
        modules.append(placement(f"{prefix}-LASER", ModuleKind.LASER, 0, 2))
    return BoardLayout(name=prefix, modules=tuple(modules))


class LiveBattleSessionTests(unittest.TestCase):
    def test_incremental_session_matches_uninterrupted_simulation(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=40))
        left = passive_board("LEFT", with_laser=True)
        right = passive_board("RIGHT", with_laser=True)

        baseline = engine.simulate(left, right, seed=818)
        session = engine.start_live_session(
            left,
            right,
            seed=818,
            max_ticks=40,
        )
        while not session.complete:
            session.advance()

        self.assertEqual(session.result().to_dict(), baseline.to_dict())

    def test_swap_consumes_rolling_window_and_applies_on_next_tick(self) -> None:
        engine = CircuitBattleEngine(
            BattleConfig(core_hp=10_000, live_max_ticks=130)
        )
        session = engine.start_live_session(
            passive_board("LEFT", with_laser=True),
            passive_board("RIGHT", with_laser=False),
            seed=91,
            left_reserves=(
                ReserveModule("LEFT-SHIELD", ModuleKind.SHIELD),
            ),
        )

        session.advance_to(60)
        opened = session.intervention_state(Side.LEFT)
        self.assertTrue(opened.active)
        self.assertEqual(opened.window_tick, 60)

        swap = session.queue_swap(
            side=Side.LEFT,
            outgoing_id="LEFT-LASER",
            incoming_id="LEFT-SHIELD",
        )
        self.assertEqual(swap.window_tick, 60)
        self.assertFalse(session.intervention_state(Side.LEFT).active)
        self.assertTrue(session.intervention_state(Side.LEFT).pending)
        self.assertEqual(session.tick, 60)

        snapshot = session.advance()
        self.assertEqual(snapshot.tick, 61)
        self.assertFalse(snapshot.left_intervention.pending)
        self.assertIn(
            "LEFT-SHIELD",
            {item.module_id for item in snapshot.left_layout.modules},
        )
        swap_events = [
            event
            for event in session.events
            if event.event_type is EventType.MODULE_SWAP
        ]
        self.assertEqual(len(swap_events), 1)
        self.assertEqual(swap_events[0].tick, 61)
        self.assertEqual(swap_events[0].actor_id, "LEFT-SHIELD")
        self.assertEqual(swap_events[0].target_id, "LEFT-LASER")

        session.advance_to(89)
        self.assertFalse(session.intervention_state(Side.LEFT).active)
        session.advance()
        self.assertTrue(session.intervention_state(Side.LEFT).active)
        self.assertEqual(
            session.intervention_state(Side.LEFT).window_tick,
            90,
        )

    def test_request_before_first_window_is_rejected_without_stopping_battle(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(core_hp=10_000))
        session = engine.start_live_session(
            passive_board("LEFT", with_laser=True),
            passive_board("RIGHT", with_laser=False),
            left_reserves=(ReserveModule("LEFT-SHIELD", ModuleKind.SHIELD),),
        )

        session.advance_to(59)
        with self.assertRaises(InterventionError) as rejected:
            session.queue_swap(
                side=Side.LEFT,
                outgoing_id="LEFT-LASER",
                incoming_id="LEFT-SHIELD",
            )
        self.assertEqual(rejected.exception.code, "window_closed")
        self.assertEqual(session.advance().tick, 60)
        self.assertTrue(session.intervention_state(Side.LEFT).active)

        next_snapshot = session.advance()
        self.assertEqual(next_snapshot.tick, 61)
        self.assertTrue(next_snapshot.left_intervention.active)
        self.assertFalse(next_snapshot.left_intervention.pending)

    def test_unused_windows_roll_forward_to_tick_120(self) -> None:
        engine = CircuitBattleEngine(
            BattleConfig(core_hp=10_000, live_max_ticks=130)
        )
        session = engine.start_live_session(
            passive_board("LEFT", with_laser=True),
            passive_board("RIGHT", with_laser=False),
            left_reserves=(ReserveModule("LEFT-SHIELD", ModuleKind.SHIELD),),
        )

        session.advance_to(120)
        state = session.intervention_state(Side.LEFT)
        self.assertTrue(state.active)
        self.assertEqual(state.window_tick, 120)
        self.assertEqual(state.swaps_remaining, 2)

    def test_second_swap_can_return_benched_module_with_preserved_hp(self) -> None:
        engine = CircuitBattleEngine(
            BattleConfig(core_hp=10_000, live_max_ticks=130)
        )
        session = engine.start_live_session(
            passive_board("LEFT", with_laser=True),
            passive_board("RIGHT", with_laser=False),
            left_reserves=(ReserveModule("LEFT-SHIELD", ModuleKind.SHIELD),),
        )

        session.advance_to(75)
        first = session.queue_swap(
            side=Side.LEFT,
            outgoing_id="LEFT-LASER",
            incoming_id="LEFT-SHIELD",
        )
        laser_hp = first.outgoing.hp
        session.advance()
        session.advance_to(90)
        second = session.queue_swap(
            side=Side.LEFT,
            outgoing_id="LEFT-SHIELD",
            incoming_id="LEFT-LASER",
        )

        self.assertEqual(second.incoming.hp, laser_hp)
        self.assertEqual(second.swaps_remaining, 0)
        session.advance()
        frame_ids = {
            module.module_id for module in session.snapshot().frame.left.modules
        }
        self.assertIn("LEFT-LASER", frame_ids)
        self.assertNotIn("LEFT-SHIELD", frame_ids)


if __name__ == "__main__":
    unittest.main()
