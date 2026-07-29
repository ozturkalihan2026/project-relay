from __future__ import annotations

import unittest
from itertools import combinations

from relay_api.bots import BOTS
from relay_engine import (
    BoardLayout,
    CircuitBattleEngine,
    Direction,
    ModuleKind,
    ModulePlacement,
    Side,
)
from relay_engine.catalog import get_spec


BALANCE_SEEDS = tuple(range(1, 22))


def _matchup_score(
    engine: CircuitBattleEngine,
    first: BoardLayout,
    second: BoardLayout,
) -> tuple[int, int, int]:
    first_wins = 0
    second_wins = 0
    draws = 0
    for seed in BALANCE_SEEDS:
        for left, right, first_side in (
            (first, second, Side.LEFT),
            (second, first, Side.RIGHT),
        ):
            result = engine.simulate(left, right, seed=seed)
            if result.winner is None:
                draws += 1
            elif result.winner is first_side:
                first_wins += 1
            else:
                second_wins += 1
    return first_wins, second_wins, draws


def _pulse_spam_board() -> BoardLayout:
    return BoardLayout(
        name="Darbe Topu Yığını",
        modules=(
            ModulePlacement(
                "SPAM-GEN",
                ModuleKind.GENERATOR,
                0,
                1,
                Direction.SOUTH,
            ),
            ModulePlacement(
                "SPAM-BAT",
                ModuleKind.BATTERY,
                1,
                3,
            ),
            ModulePlacement(
                "SPAM-PULSE-A",
                ModuleKind.PULSE_CANNON,
                0,
                2,
            ),
            ModulePlacement(
                "SPAM-PULSE-B",
                ModuleKind.PULSE_CANNON,
                0,
                3,
                Direction.NORTH,
            ),
            ModulePlacement(
                "SPAM-PULSE-C",
                ModuleKind.PULSE_CANNON,
                2,
                3,
                Direction.SOUTH,
            ),
            ModulePlacement(
                "SPAM-PULSE-D",
                ModuleKind.PULSE_CANNON,
                3,
                2,
                Direction.SOUTH,
            ),
        ),
    )


class BattleBalanceTests(unittest.TestCase):
    def setUp(self) -> None:
        self.engine = CircuitBattleEngine()

    def test_all_server_opponents_are_valid_and_fully_powered(self) -> None:
        self.assertEqual(len(BOTS), 9)
        for bot in BOTS.values():
            with self.subTest(bot=bot.bot_id):
                self.assertEqual(
                    bot.available_module_counts,
                    (1, 2, 3, 4, 5, 6),
                )
                for module_count in bot.available_module_counts:
                    board = bot.board_for_count(module_count)
                    board.validate()
                    self.assertEqual(len(board.modules), module_count)
                    self.assertEqual(
                        self.engine.powered_module_ids(board),
                        frozenset(
                            module.module_id for module in board.modules
                        ),
                    )

    def test_all_count_matched_variants_survive_multi_battle_regression(
        self,
    ) -> None:
        reference = BOTS["balanced"]
        for bot in BOTS.values():
            for module_count in range(1, 7):
                left = reference.board_for_count(module_count)
                right = bot.board_for_count(module_count)
                for seed in range(1, 8):
                    with self.subTest(
                        bot=bot.bot_id,
                        module_count=module_count,
                        seed=seed,
                    ):
                        result = self.engine.simulate(left, right, seed=seed)
                        self.assertEqual(
                            len(result.left.modules),
                            len(result.right.modules),
                        )

    def test_no_server_strategy_is_unbeaten_across_seeded_matchups(self) -> None:
        scores: dict[tuple[str, str], tuple[int, int, int]] = {}
        for pair in combinations(BOTS, 2):
            first_id, second_id = sorted(pair)
            scores[(first_id, second_id)] = _matchup_score(
                self.engine,
                BOTS[first_id].board,
                BOTS[second_id].board,
            )

        for candidate_id in BOTS:
            counters: list[str] = []
            for opponent_id in BOTS:
                if candidate_id == opponent_id:
                    continue
                first_id, second_id = sorted((candidate_id, opponent_id))
                first_wins, second_wins, _ = scores[(first_id, second_id)]
                if candidate_id == first_id:
                    candidate_wins, opponent_wins = first_wins, second_wins
                else:
                    candidate_wins, opponent_wins = second_wins, first_wins
                if opponent_wins > candidate_wins:
                    counters.append(opponent_id)
            with self.subTest(candidate=candidate_id):
                self.assertTrue(
                    counters,
                    f"{candidate_id} için kazanan bir karşı düzen bulunamadı.",
                )

    def test_attack_defense_counter_cycle_remains_intact(self) -> None:
        counter_pairs = (
            ("laser_swarm", "pulse_volley"),
            ("pulse_volley", "shield_wall"),
            ("shield_wall", "repair_guard"),
            ("repair_guard", "laser_swarm"),
            ("balanced", "laser_swarm"),
        )
        for target_id, counter_id in counter_pairs:
            with self.subTest(target=target_id, counter=counter_id):
                target_wins, counter_wins, _ = _matchup_score(
                    self.engine,
                    BOTS[target_id].board,
                    BOTS[counter_id].board,
                )
                self.assertGreater(counter_wins, target_wins)

    def test_pulse_spam_has_a_reliable_fortress_counter(self) -> None:
        pulse_spam = _pulse_spam_board()
        pulse_wins, shield_wins, draws = _matchup_score(
            self.engine,
            pulse_spam,
            BOTS["fortress"].board,
        )

        self.assertEqual(draws, 0)
        self.assertGreater(shield_wins, pulse_wins)
        self.assertGreaterEqual(shield_wins, 38)

    def test_pulse_cannon_balance_values_stay_below_old_dominant_curve(
        self,
    ) -> None:
        pulse = get_spec(ModuleKind.PULSE_CANNON)
        shield = get_spec(ModuleKind.SHIELD)
        generator = get_spec(ModuleKind.GENERATOR)

        self.assertEqual(pulse.energy_cost, 8)
        self.assertEqual(pulse.damage, 16)
        self.assertEqual(pulse.heat_per_action, 30)
        self.assertEqual(generator.energy_output, 8)
        self.assertEqual(shield.shield, 14)
        self.assertGreater(shield.threat, pulse.threat)


if __name__ == "__main__":
    unittest.main()
