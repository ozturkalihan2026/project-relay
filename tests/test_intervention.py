from __future__ import annotations

import unittest

from relay_engine import InterventionError, InterventionPolicy, ModuleHealthRack


class ModuleHealthRackTests(unittest.TestCase):
    def test_first_entry_is_full_and_reentry_preserves_last_active_hp(self) -> None:
        rack = ModuleHealthRack(
            active={"generator": (120, 120), "laser": (34, 80)},
            reserves={"shield": 95},
        )

        first = rack.swap(
            tick=60,
            outgoing_id="laser",
            incoming_id="shield",
        )
        self.assertEqual(first.outgoing.hp, 34)
        self.assertEqual(first.incoming.hp, 95)
        self.assertEqual(first.swaps_remaining, 998)

        rack.update_active_hp("shield", 41)
        second = rack.swap(
            tick=90,
            outgoing_id="shield",
            incoming_id="laser",
        )
        self.assertEqual(second.outgoing.hp, 41)
        self.assertEqual(second.incoming.hp, 34)
        self.assertEqual(second.swaps_remaining, 997)
        self.assertEqual(rack.vitality("shield").hp, 41)

    def test_unused_right_carries_but_each_window_allows_only_one_swap(self) -> None:
        rack = ModuleHealthRack(
            active={"generator": (120, 120), "laser": (80, 80)},
            reserves={"shield": 95, "repair": 70},
        )

        rack.swap(tick=90, outgoing_id="laser", incoming_id="shield")
        with self.assertRaises(InterventionError) as duplicate:
            rack.swap(tick=90, outgoing_id="shield", incoming_id="repair")
        self.assertEqual(duplicate.exception.code, "window_already_used")

        second = rack.swap(
            tick=120,
            outgoing_id="shield",
            incoming_id="repair",
        )
        self.assertEqual(second.swaps_used, 2)

    def test_window_stays_open_while_battle_advances_then_locks_after_swap(self) -> None:
        rack = ModuleHealthRack(
            active={"generator": (120, 120), "laser": (80, 80)},
            reserves={"shield": 95},
        )

        self.assertIsNone(rack.active_window(59))
        self.assertEqual(rack.active_window(60), 60)
        self.assertEqual(rack.active_window(89), 60)

        swap = rack.swap(tick=75, outgoing_id="laser", incoming_id="shield")
        self.assertEqual(swap.tick, 75)
        self.assertEqual(swap.window_tick, 60)
        self.assertIsNone(rack.active_window(76))
        self.assertEqual(rack.active_window(90), 90)

    def test_closed_window_and_third_swap_are_rejected(self) -> None:
        rack = ModuleHealthRack(
            active={"generator": (120, 120), "laser": (80, 80)},
            reserves={"shield": 95, "repair": 70},
            policy=InterventionPolicy(max_swaps=2, max_swaps_per_window=1),
        )
        with self.assertRaises(InterventionError) as closed:
            rack.swap(tick=59, outgoing_id="laser", incoming_id="shield")
        self.assertEqual(closed.exception.code, "window_closed")

        rack.swap(tick=60, outgoing_id="laser", incoming_id="shield")
        rack.swap(tick=90, outgoing_id="shield", incoming_id="repair")
        with self.assertRaises(InterventionError) as exhausted:
            rack.swap(tick=120, outgoing_id="repair", incoming_id="laser")
        self.assertEqual(exhausted.exception.code, "swap_limit_reached")


if __name__ == "__main__":
    unittest.main()
