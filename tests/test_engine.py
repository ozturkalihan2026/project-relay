from __future__ import annotations

import unittest

from relay_engine import (
    BattleConfig,
    BoardLayout,
    CircuitBattleEngine,
    Direction,
    EventType,
    ModuleKind,
    ModulePlacement,
)
from relay_engine.catalog import world_ports


def placement(
    module_id: str,
    kind: ModuleKind,
    row: int,
    column: int,
    orientation: Direction = Direction.EAST,
) -> ModulePlacement:
    return ModulePlacement(module_id, kind, row, column, orientation)


def generator(module_id: str) -> ModulePlacement:
    return placement(
        module_id,
        ModuleKind.GENERATOR,
        0,
        1,
        Direction.SOUTH,
    )


def simple_laser_board(prefix: str = "A") -> BoardLayout:
    return BoardLayout(
        name=prefix,
        modules=(
            generator(f"{prefix}-GEN"),
            placement(f"{prefix}-LASER", ModuleKind.LASER, 0, 2),
        ),
    )


def generator_only(prefix: str = "B") -> BoardLayout:
    return BoardLayout(name=prefix, modules=(generator(f"{prefix}-GEN"),))


class CircuitBattleEngineTests(unittest.TestCase):
    def test_same_input_and_seed_produce_identical_replay(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=30))
        first = engine.simulate(
            simple_laser_board("A"), simple_laser_board("B"), seed=77
        )
        second = engine.simulate(
            simple_laser_board("A"), simple_laser_board("B"), seed=77
        )

        self.assertEqual(first.to_dict(), second.to_dict())
        self.assertEqual(first.replay_checksum, second.replay_checksum)

    def test_connected_module_is_powered_and_attacks(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=5))
        board = simple_laser_board()

        self.assertEqual(
            engine.powered_module_ids(board), frozenset({"A-GEN", "A-LASER"})
        )

        result = engine.simulate(board, generator_only(), seed=1)
        self.assertGreater(result.left.total_damage, 0)
        self.assertTrue(
            any(event.event_type is EventType.ATTACK for event in result.events)
        )

    def test_generator_is_protected_while_other_modules_survive(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=90))
        defender = BoardLayout(
            name="Savunmacı",
            modules=(
                generator("D-GEN"),
                placement("D-BAT-1", ModuleKind.BATTERY, 0, 2),
                placement("D-BAT-2", ModuleKind.BATTERY, 1, 3),
            ),
        )

        result = engine.simulate(simple_laser_board("A"), defender, seed=14)
        destroyed_regular_modules: set[str] = set()
        regular_ids = {"D-BAT-1", "D-BAT-2"}
        generator_attack_seen = False

        for event in result.events:
            if (
                event.event_type is EventType.DESTROYED
                and event.target_id in regular_ids
            ):
                destroyed_regular_modules.add(event.target_id)
            if (
                event.event_type is EventType.ATTACK
                and event.target_id == "D-GEN"
            ):
                self.assertEqual(destroyed_regular_modules, regular_ids)
                generator_attack_seen = True

        self.assertTrue(generator_attack_seen)

    def test_core_is_protected_until_generator_is_destroyed(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=60))
        result = engine.simulate(
            simple_laser_board("A"),
            generator_only("D"),
            seed=2,
        )

        generator_destroyed_index = next(
            index
            for index, event in enumerate(result.events)
            if event.event_type is EventType.DESTROYED
            and event.target_id == "D-GEN"
        )
        core_damage_indices = [
            index
            for index, event in enumerate(result.events)
            if event.event_type is EventType.CORE_DAMAGE
        ]

        self.assertTrue(core_damage_indices)
        self.assertTrue(
            all(index > generator_destroyed_index for index in core_damage_indices)
        )

    def test_fallback_target_preserves_module_generator_core_order(self) -> None:
        engine = CircuitBattleEngine()
        state = engine._create_state(
            BoardLayout(
                modules=(
                    generator("GEN"),
                    placement("BAT", ModuleKind.BATTERY, 0, 2),
                    placement("LASER", ModuleKind.LASER, 0, 3),
                )
            )
        )

        state.modules[(0, 3)].hp = 0
        self.assertEqual(
            engine._fallback_target(state).placement.module_id,
            "BAT",
        )

        state.modules[(0, 2)].hp = 0
        self.assertEqual(
            engine._fallback_target(state).placement.module_id,
            "GEN",
        )

        state.modules[(0, 1)].hp = 0
        self.assertIsNone(engine._fallback_target(state))

    def test_server_decision_identifies_first_timeout_tiebreak_difference(
        self,
    ) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=1))
        result = engine.simulate(
            simple_laser_board("A"),
            BoardLayout(
                modules=(
                    generator("D-GEN"),
                    placement("D-SHIELD", ModuleKind.SHIELD, 0, 2),
                )
            ),
            seed=6,
        )

        self.assertEqual(result.reason, "timeout_tiebreak")
        self.assertEqual(result.decision.criterion, "total_damage")
        self.assertEqual(
            [metric.key for metric in result.decision.metrics],
            [
                "core_hp_ratio",
                "surviving_modules",
                "module_hp_ratio",
                "total_damage",
                "damage_efficiency",
                "total_heat",
            ],
        )
        total_damage = next(
            metric
            for metric in result.decision.metrics
            if metric.key == "total_damage"
        )
        self.assertGreater(total_damage.left_value, total_damage.right_value)

    def test_core_distributes_power_to_the_other_three_gates(self) -> None:
        engine = CircuitBattleEngine()
        board = BoardLayout(
            modules=(
                generator("GEN"),
                placement("RIGHT", ModuleKind.LASER, 1, 3),
                placement(
                    "BOTTOM",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
                placement(
                    "LEFT",
                    ModuleKind.COOLER,
                    2,
                    0,
                    Direction.WEST,
                ),
            )
        )

        self.assertEqual(
            engine.powered_module_ids(board),
            frozenset({"GEN", "RIGHT", "BOTTOM", "LEFT"}),
        )

    def test_all_four_generator_gates_are_rotationally_symmetric(self) -> None:
        engine = CircuitBattleEngine()
        cases = (
            ((0, 1), Direction.SOUTH, (1, 3), Direction.EAST),
            ((1, 3), Direction.WEST, (3, 2), Direction.SOUTH),
            ((3, 2), Direction.NORTH, (2, 0), Direction.WEST),
            ((2, 0), Direction.EAST, (0, 1), Direction.NORTH),
        )
        for (
            generator_position,
            generator_direction,
            target_position,
            target_direction,
        ) in cases:
            with self.subTest(generator=generator_position):
                board = BoardLayout(
                    modules=(
                        placement(
                            "GEN",
                            ModuleKind.GENERATOR,
                            generator_position[0],
                            generator_position[1],
                            generator_direction,
                        ),
                        placement(
                            "TARGET",
                            ModuleKind.LASER,
                            target_position[0],
                            target_position[1],
                            target_direction,
                        ),
                    )
                )
                self.assertEqual(
                    engine.powered_module_ids(board),
                    frozenset({"GEN", "TARGET"}),
                )

    def test_core_touching_non_gate_cell_gets_no_free_connection(self) -> None:
        engine = CircuitBattleEngine()
        board = BoardLayout(
            modules=(
                generator("GEN"),
                placement(
                    "NON-GATE",
                    ModuleKind.LASER,
                    1,
                    0,
                    Direction.SOUTH,
                ),
            )
        )

        self.assertEqual(engine.powered_module_ids(board), frozenset({"GEN"}))

    def test_generator_and_core_power_five_parallel_endpoints_without_battery(
        self,
    ) -> None:
        engine = CircuitBattleEngine()
        board = BoardLayout(
            modules=(
                generator("GEN"),
                placement(
                    "RING-LEFT",
                    ModuleKind.LASER,
                    0,
                    0,
                    Direction.WEST,
                ),
                placement("RING-RIGHT", ModuleKind.LASER, 0, 2),
                placement("CORE-RIGHT", ModuleKind.SHIELD, 1, 3),
                placement(
                    "CORE-BOTTOM",
                    ModuleKind.COOLER,
                    3,
                    2,
                    Direction.SOUTH,
                ),
                placement(
                    "CORE-LEFT",
                    ModuleKind.REPAIR,
                    2,
                    0,
                    Direction.WEST,
                ),
            )
        )

        self.assertEqual(
            engine.powered_module_ids(board),
            frozenset(module.module_id for module in board.modules),
        )

    def test_replay_state_frames_expose_live_module_and_board_status(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=6))
        result = engine.simulate(
            simple_laser_board("A"),
            simple_laser_board("B"),
            seed=12,
        )

        self.assertEqual(len(result.state_frames), result.ticks + 1)
        initial = result.state_frames[0]
        final = result.state_frames[-1]
        self.assertEqual(initial.tick, 0)
        self.assertEqual(initial.left.core_hp, 120)
        self.assertEqual(initial.left.energy_reserve, 0)
        self.assertEqual(initial.left.energy_output, 8)
        self.assertTrue(all(module.powered for module in initial.left.modules))
        self.assertEqual(final.tick, result.ticks)
        self.assertEqual(final.left.core_hp, result.left.core_hp)
        self.assertEqual(
            [module.hp for module in final.left.modules],
            [module.hp for module in result.left.modules],
        )
        self.assertGreater(final.left.energy_spent, 0)
        self.assertGreater(max(module.heat for module in final.left.modules), 0)

    def test_wrong_orientation_leaves_laser_unpowered(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=8))
        board = BoardLayout(
            modules=(
                generator("GEN"),
                placement("LASER", ModuleKind.LASER, 0, 2, Direction.WEST),
            )
        )

        self.assertEqual(engine.powered_module_ids(board), frozenset({"GEN"}))
        result = engine.simulate(board, generator_only(), seed=1)
        self.assertEqual(result.left.total_damage, 0)
        self.assertFalse(
            any(
                event.actor_id == "LASER" and event.event_type is EventType.ATTACK
                for event in result.events
            )
        )

    def test_single_port_modules_connect_in_all_four_orientations(self) -> None:
        engine = CircuitBattleEngine()
        cases = {
            Direction.EAST: (
                (0, 1, Direction.SOUTH),
                (0, 2),
            ),
            Direction.WEST: (
                (0, 1, Direction.SOUTH),
                (0, 0),
            ),
            Direction.SOUTH: (
                (2, 0, Direction.EAST),
                (3, 0),
            ),
            Direction.NORTH: (
                (2, 0, Direction.EAST),
                (1, 0),
            ),
        }
        endpoint_kinds = (
            ModuleKind.LASER,
            ModuleKind.PULSE_CANNON,
            ModuleKind.SHIELD,
            ModuleKind.COOLER,
            ModuleKind.REPAIR,
        )

        for kind in endpoint_kinds:
            for orientation, (generator_data, endpoint) in cases.items():
                with self.subTest(kind=kind.value, orientation=orientation.value):
                    generator_row, generator_column, generator_orientation = (
                        generator_data
                    )
                    board = BoardLayout(
                        modules=(
                            placement(
                                "GEN",
                                ModuleKind.GENERATOR,
                                generator_row,
                                generator_column,
                                generator_orientation,
                            ),
                            placement(
                                "END",
                                kind,
                                endpoint[0],
                                endpoint[1],
                                orientation,
                            ),
                        )
                    )

                    self.assertEqual(
                        engine.powered_module_ids(board),
                        frozenset({"GEN", "END"}),
                    )

    def test_relay_modules_carry_energy_in_all_four_orientations(self) -> None:
        engine = CircuitBattleEngine()
        horizontal = (
            (0, 1, Direction.SOUTH),
            (0, 2),
            (0, 3, Direction.EAST),
        )
        vertical = (
            (2, 0, Direction.EAST),
            (1, 0),
            (0, 0, Direction.NORTH),
        )

        for relay_kind in (ModuleKind.BATTERY, ModuleKind.AMPLIFIER):
            for orientation in Direction:
                with self.subTest(
                    kind=relay_kind.value,
                    orientation=orientation.value,
                ):
                    generator_data, relay_position, endpoint_data = (
                        horizontal
                        if orientation in (Direction.EAST, Direction.WEST)
                        else vertical
                    )
                    board = BoardLayout(
                        modules=(
                            placement(
                                "GEN",
                                ModuleKind.GENERATOR,
                                generator_data[0],
                                generator_data[1],
                                generator_data[2],
                            ),
                            placement(
                                "RELAY",
                                relay_kind,
                                relay_position[0],
                                relay_position[1],
                                orientation,
                            ),
                            placement(
                                "LASER",
                                ModuleKind.LASER,
                                endpoint_data[0],
                                endpoint_data[1],
                                endpoint_data[2],
                            ),
                        )
                    )

                    self.assertEqual(
                        engine.powered_module_ids(board),
                        frozenset({"GEN", "RELAY", "LASER"}),
                    )

    def test_port_rotation_matrix_matches_module_front_direction(self) -> None:
        expected_back_ports = {
            Direction.EAST: frozenset({Direction.WEST}),
            Direction.SOUTH: frozenset({Direction.NORTH}),
            Direction.WEST: frozenset({Direction.EAST}),
            Direction.NORTH: frozenset({Direction.SOUTH}),
        }
        expected_relay_ports = {
            Direction.EAST: frozenset({Direction.WEST, Direction.EAST}),
            Direction.SOUTH: frozenset({Direction.NORTH, Direction.SOUTH}),
            Direction.WEST: frozenset({Direction.EAST, Direction.WEST}),
            Direction.NORTH: frozenset({Direction.SOUTH, Direction.NORTH}),
        }
        expected_generator_ports = {
            Direction.EAST: frozenset(
                {Direction.NORTH, Direction.EAST, Direction.SOUTH}
            ),
            Direction.SOUTH: frozenset(
                {Direction.EAST, Direction.SOUTH, Direction.WEST}
            ),
            Direction.WEST: frozenset(
                {Direction.SOUTH, Direction.WEST, Direction.NORTH}
            ),
            Direction.NORTH: frozenset(
                {Direction.WEST, Direction.NORTH, Direction.EAST}
            ),
        }

        for orientation, ports in expected_back_ports.items():
            with self.subTest(kind="laser", orientation=orientation.value):
                self.assertEqual(world_ports(ModuleKind.LASER, orientation), ports)
        for orientation in Direction:
            with self.subTest(kind="battery", orientation=orientation.value):
                self.assertEqual(
                    world_ports(ModuleKind.BATTERY, orientation),
                    frozenset(Direction),
                )
        for orientation, ports in expected_relay_ports.items():
            with self.subTest(kind="amplifier", orientation=orientation.value):
                self.assertEqual(
                    world_ports(ModuleKind.AMPLIFIER, orientation),
                    ports,
                )
        for orientation, ports in expected_generator_ports.items():
            with self.subTest(kind="generator", orientation=orientation.value):
                self.assertEqual(
                    world_ports(ModuleKind.GENERATOR, orientation),
                    ports,
                )

    def test_six_module_board_can_branch_and_be_completely_powered(self) -> None:
        engine = CircuitBattleEngine()
        modules = (
            generator("MAX-GEN"),
            placement("MAX-LASER", ModuleKind.LASER, 0, 2),
            placement("MAX-BAT", ModuleKind.BATTERY, 1, 3),
            placement(
                "MAX-PULSE",
                ModuleKind.PULSE_CANNON,
                0,
                3,
                Direction.NORTH,
            ),
            placement(
                "MAX-SHIELD",
                ModuleKind.SHIELD,
                2,
                3,
                Direction.SOUTH,
            ),
            placement(
                "MAX-COOL",
                ModuleKind.COOLER,
                3,
                2,
                Direction.SOUTH,
            ),
        )
        board = BoardLayout(name="Altı Modüllük Kart", modules=modules)
        expected_ids = frozenset(module.module_id for module in modules)

        self.assertEqual(engine.powered_module_ids(board), expected_ids)

    def test_mirrored_boards_end_in_exact_draw(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=40))
        left_layout = BoardLayout(
            name="Sol",
            modules=(
                generator("L-GEN"),
                placement("L-LASER", ModuleKind.LASER, 0, 2),
                placement(
                    "L-SHIELD",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        )
        right_layout = BoardLayout(
            name="Sağ",
            modules=(
                generator("R-GEN"),
                placement("R-LASER", ModuleKind.LASER, 0, 2),
                placement(
                    "R-SHIELD",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        )

        result = engine.simulate(left_layout, right_layout, seed=928)
        self.assertIsNone(result.winner)
        self.assertIn(result.reason, {"exact_draw", "mutual_core_destruction"})
        self.assertEqual(result.left.core_hp, result.right.core_hp)
        self.assertEqual(result.left.total_damage, result.right.total_damage)
        self.assertEqual(
            [(module.hp, module.heat) for module in result.left.modules],
            [(module.hp, module.heat) for module in result.right.modules],
        )

    def test_amplifier_increases_laser_damage_and_heat(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=12))
        amplified = BoardLayout(
            modules=(
                generator("A-GEN"),
                placement("A-AMP", ModuleKind.AMPLIFIER, 0, 2),
                placement("A-LASER", ModuleKind.LASER, 0, 3),
            )
        )
        relayed = BoardLayout(
            modules=(
                generator("B-GEN"),
                placement("B-BAT", ModuleKind.BATTERY, 0, 2),
                placement("B-LASER", ModuleKind.LASER, 0, 3),
            )
        )

        amplified_result = engine.simulate(amplified, generator_only("X"), seed=4)
        relayed_result = engine.simulate(relayed, generator_only("X"), seed=4)
        amplified_laser = next(
            module
            for module in amplified_result.left.modules
            if module.kind is ModuleKind.LASER
        )
        relayed_laser = next(
            module
            for module in relayed_result.left.modules
            if module.kind is ModuleKind.LASER
        )

        self.assertGreater(
            amplified_result.left.total_damage,
            relayed_result.left.total_damage,
        )
        self.assertGreater(amplified_laser.heat, relayed_laser.heat)

    def test_cooler_reduces_heat(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=24))
        cooled = BoardLayout(
            modules=(
                generator("C-GEN"),
                placement("C-LASER", ModuleKind.LASER, 0, 2),
                placement(
                    "C-COOL",
                    ModuleKind.COOLER,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            )
        )
        uncooled = simple_laser_board("U")

        cooled_result = engine.simulate(cooled, generator_only("X"), seed=2)
        uncooled_result = engine.simulate(uncooled, generator_only("X"), seed=2)
        cooled_laser = next(
            module
            for module in cooled_result.left.modules
            if module.kind is ModuleKind.LASER
        )
        uncooled_laser = next(
            module
            for module in uncooled_result.left.modules
            if module.kind is ModuleKind.LASER
        )

        self.assertLess(cooled_laser.heat, uncooled_laser.heat)
        self.assertTrue(
            any(event.event_type is EventType.COOL for event in cooled_result.events)
        )

    def test_generator_runs_pulse_cannon_and_battery_stores_idle_energy(
        self,
    ) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=8))
        battery_board = BoardLayout(
            modules=(
                generator("B-GEN"),
                placement("B-BAT", ModuleKind.BATTERY, 0, 2),
                placement("B-PULSE", ModuleKind.PULSE_CANNON, 0, 3),
            )
        )
        no_battery_board = BoardLayout(
            modules=(
                generator("N-GEN"),
                placement("N-AMP", ModuleKind.AMPLIFIER, 0, 2),
                placement("N-PULSE", ModuleKind.PULSE_CANNON, 0, 3),
            )
        )

        with_battery = engine.simulate(battery_board, generator_only("X"), seed=3)
        without_battery = engine.simulate(
            no_battery_board,
            generator_only("X"),
            seed=3,
        )

        self.assertGreater(with_battery.left.total_damage, 0)
        self.assertGreater(without_battery.left.total_damage, 0)
        self.assertGreater(
            max(frame.left.energy_reserve for frame in with_battery.state_frames),
            0,
        )
        self.assertEqual(
            max(frame.left.energy_reserve for frame in without_battery.state_frames),
            0,
        )

    def test_support_modules_skip_actions_with_no_useful_effect(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=12))
        cooler_board = BoardLayout(
            modules=(
                generator("C-GEN"),
                placement("C-COOL", ModuleKind.COOLER, 0, 2),
            )
        )
        repair_board = BoardLayout(
            modules=(
                generator("R-GEN"),
                placement("R-REPAIR", ModuleKind.REPAIR, 0, 2),
            )
        )

        cooler_result = engine.simulate(
            cooler_board,
            generator_only("C-ENEMY"),
            seed=4,
        )
        repair_result = engine.simulate(
            repair_board,
            generator_only("R-ENEMY"),
            seed=4,
        )

        self.assertFalse(
            any(
                event.side.value == "left"
                and event.event_type is EventType.COOL
                for event in cooler_result.events
            )
        )
        self.assertFalse(
            any(
                event.side.value == "left"
                and event.event_type is EventType.REPAIR
                for event in repair_result.events
            )
        )
        self.assertEqual(cooler_result.left.energy_spent, 0)
        self.assertEqual(repair_result.left.energy_spent, 0)

    def test_energy_priority_rotates_and_coalesces_starvation_warnings(
        self,
    ) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=6))
        board = BoardLayout(
            modules=(
                generator("GEN"),
                placement("SHIELD-A", ModuleKind.SHIELD, 0, 2),
                placement("SHIELD-B", ModuleKind.SHIELD, 1, 3),
                placement(
                    "SHIELD-C",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            )
        )

        result = engine.simulate(board, generator_only("ENEMY"), seed=7)
        shield_events = [
            event
            for event in result.events
            if event.side.value == "left"
            and event.event_type is EventType.SHIELD
        ]
        starvation_events = [
            event
            for event in result.events
            if event.side.value == "left"
            and event.event_type is EventType.ENERGY_STARVED
        ]

        self.assertEqual(
            {event.actor_id for event in shield_events},
            {"SHIELD-A", "SHIELD-B", "SHIELD-C"},
        )
        self.assertEqual(
            sum(
                event.actor_id == "SHIELD-C"
                for event in starvation_events
            ),
            1,
        )
        self.assertTrue(
            all(event.detail == "streak_started" for event in starvation_events)
        )

    def test_shield_never_spends_energy_when_pool_is_full(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=30))
        board = BoardLayout(
            modules=(
                generator("GEN"),
                placement("SHIELD", ModuleKind.SHIELD, 0, 2),
            )
        )

        result = engine.simulate(board, generator_only("ENEMY"), seed=2)
        shield_events = [
            event
            for event in result.events
            if event.side.value == "left"
            and event.event_type is EventType.SHIELD
        ]

        self.assertTrue(shield_events)
        self.assertTrue(all(event.amount > 0 for event in shield_events))
        self.assertEqual(result.left.energy_spent, len(shield_events) * 5)

    def test_repair_restores_damaged_module(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=12))
        repair_board = BoardLayout(
            modules=(
                generator("R-GEN"),
                placement("R-REPAIR", ModuleKind.REPAIR, 0, 2),
            )
        )

        result = engine.simulate(repair_board, simple_laser_board("ENEMY"), seed=10)

        repair_events = [
            event
            for event in result.events
            if event.side.value == "left" and event.event_type is EventType.REPAIR
        ]
        self.assertTrue(repair_events)
        self.assertGreater(sum(event.amount for event in repair_events), 0)

    def test_shield_absorbs_incoming_damage(self) -> None:
        engine = CircuitBattleEngine(BattleConfig(max_ticks=8))
        shield_board = BoardLayout(
            modules=(
                generator("S-GEN"),
                placement("S-SHIELD", ModuleKind.SHIELD, 0, 2),
            )
        )

        result = engine.simulate(shield_board, simple_laser_board("ENEMY"), seed=5)

        self.assertTrue(
            any(
                event.event_type is EventType.SHIELD_ABSORB
                for event in result.events
            )
        )

    def test_invalid_boards_are_rejected(self) -> None:
        cases = [
            (
                (
                    generator("GEN"),
                    placement("LASER", ModuleKind.LASER, 0, 1),
                ),
                "Aynı hücre",
            ),
            (
                (
                    placement(
                        "GEN",
                        ModuleKind.GENERATOR,
                        4,
                        0,
                        Direction.SOUTH,
                    ),
                ),
                "sınırları dışında",
            ),
            (
                (
                    generator("GEN"),
                    placement("GEN", ModuleKind.LASER, 0, 2),
                ),
                "Tekrarlanan",
            ),
            (
                (placement("LASER", ModuleKind.LASER, 0, 2),),
                "tam olarak bir jeneratör",
            ),
            (
                (
                    generator("GEN"),
                    placement("LASER", ModuleKind.LASER, 1, 1),
                ),
                "pasif çekirdeğe",
            ),
            (
                (
                    placement(
                        "GEN",
                        ModuleKind.GENERATOR,
                        0,
                        0,
                        Direction.SOUTH,
                    ),
                ),
                "dört kapı",
            ),
            (
                (
                    placement(
                        "GEN",
                        ModuleKind.GENERATOR,
                        0,
                        1,
                        Direction.EAST,
                    ),
                ),
                "ön yönü çekirdeğe",
            ),
        ]
        for modules, message in cases:
            with self.subTest(message=message):
                with self.assertRaisesRegex(ValueError, message):
                    BoardLayout(modules=modules).validate()


if __name__ == "__main__":
    unittest.main()
