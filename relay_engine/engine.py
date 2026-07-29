from __future__ import annotations

import hashlib
from dataclasses import dataclass

from .catalog import get_spec, world_ports
from .enums import Direction, EventType, ModuleKind, Side
from .models import (
    BattleConfig,
    BattleDecision,
    BattleEvent,
    BattleResult,
    BoardLayout,
    BoardSummary,
    DecisionMetric,
    ModulePlacement,
    ModuleSummary,
    ReplayBoardState,
    ReplayModuleState,
    ReplayStateFrame,
    module_max_hp,
    scaled_value,
)
from .replay import compute_replay_checksum
from .topology import CORE_GATE_DIRECTIONS


@dataclass(slots=True)
class _ModuleState:
    placement: ModulePlacement
    hp: float
    max_hp: float
    heat: float = 0.0
    cooldown: int = 0
    overheated: bool = False
    energy_wait_ticks: int = 0
    energy_starved_reported: bool = False

    @property
    def alive(self) -> bool:
        return self.hp > 0


@dataclass(slots=True)
class _BoardState:
    layout: BoardLayout
    modules: dict[tuple[int, int], _ModuleState]
    core_hp: float
    shield: float = 0.0
    energy_reserve: float = 0.0
    energy_spent: float = 0.0
    total_damage: float = 0.0


@dataclass(frozen=True, slots=True)
class _Intent:
    tick: int
    side: Side
    actor_position: tuple[int, int]
    kind: ModuleKind
    amount: float
    target_position: tuple[int, int] | None = None
    target_core: bool = False


class CircuitBattleEngine:
    """Server-authoritative deterministic circuit combat simulation."""

    def __init__(self, config: BattleConfig | None = None) -> None:
        self.config = config or BattleConfig()

    def simulate(
        self,
        left_layout: BoardLayout,
        right_layout: BoardLayout,
        *,
        seed: int = 1,
    ) -> BattleResult:
        left_layout.validate(self.config.board_size)
        right_layout.validate(self.config.board_size)

        states = {
            Side.LEFT: self._create_state(left_layout),
            Side.RIGHT: self._create_state(right_layout),
        }
        events: list[BattleEvent] = []
        state_frames = [self._snapshot_frame(0, states)]
        winner: Side | None = None
        reason = "draw"
        final_tick = 0

        for tick in range(1, self.config.max_ticks + 1):
            final_tick = tick
            left_intents = self._plan_tick(
                tick, Side.LEFT, states[Side.LEFT], states[Side.RIGHT], seed, events
            )
            right_intents = self._plan_tick(
                tick, Side.RIGHT, states[Side.RIGHT], states[Side.LEFT], seed, events
            )

            intents = left_intents + right_intents
            self._apply_support_intents(intents, states, events)
            self._apply_attack_intents(intents, states, events)
            state_frames.append(self._snapshot_frame(tick, states))

            left_dead = states[Side.LEFT].core_hp <= 0
            right_dead = states[Side.RIGHT].core_hp <= 0
            if left_dead or right_dead:
                if left_dead and right_dead:
                    winner = None
                    reason = "mutual_core_destruction"
                elif right_dead:
                    winner = Side.LEFT
                    reason = "core_destroyed"
                else:
                    winner = Side.RIGHT
                    reason = "core_destroyed"
                break
        else:
            winner, reason = self._resolve_timeout(states)

        left_summary = self._summarize(states[Side.LEFT])
        right_summary = self._summarize(states[Side.RIGHT])
        decision = self._build_decision(states, reason)
        checksum = compute_replay_checksum(events)
        return BattleResult(
            winner=winner,
            reason=reason,
            ticks=final_tick,
            seed=seed,
            left=left_summary,
            right=right_summary,
            decision=decision,
            events=tuple(events),
            state_frames=tuple(state_frames),
            replay_checksum=checksum,
        )

    def powered_module_ids(self, layout: BoardLayout) -> frozenset[str]:
        """Public helper used by a future editor to preview live connections."""
        layout.validate(self.config.board_size)
        state = self._create_state(layout)
        powered = self._powered_positions(state)
        return frozenset(state.modules[position].placement.module_id for position in powered)

    def _create_state(self, layout: BoardLayout) -> _BoardState:
        modules: dict[tuple[int, int], _ModuleState] = {}
        for placement in layout.modules:
            max_hp = module_max_hp(placement)
            modules[placement.position] = _ModuleState(
                placement=placement,
                hp=max_hp,
                max_hp=max_hp,
            )
        return _BoardState(
            layout=layout,
            modules=modules,
            core_hp=self.config.core_hp,
        )

    def _plan_tick(
        self,
        tick: int,
        side: Side,
        own: _BoardState,
        enemy: _BoardState,
        seed: int,
        events: list[BattleEvent],
    ) -> list[_Intent]:
        for module in own.modules.values():
            if not module.alive:
                continue
            module.heat = max(0.0, module.heat - self.config.passive_heat_loss)
            module.cooldown = max(0, module.cooldown - 1)
            if module.overheated and module.heat <= self.config.recovery_threshold:
                module.overheated = False
                events.append(
                    BattleEvent(
                        tick=tick,
                        side=side,
                        event_type=EventType.RECOVERED,
                        actor_id=module.placement.module_id,
                    )
                )

        powered = self._powered_positions(own)
        for position, module in own.modules.items():
            if not module.alive or position not in powered:
                module.energy_wait_ticks = 0
                module.energy_starved_reported = False
        battery_capacity = sum(
            scaled_value(
                get_spec(own.modules[position].placement.kind).battery_capacity,
                own.modules[position].placement.level,
            )
            for position in powered
            if own.modules[position].alive
        )
        own.energy_reserve = min(own.energy_reserve, battery_capacity)
        available_energy = sum(
            scaled_value(
                get_spec(own.modules[position].placement.kind).energy_output,
                own.modules[position].placement.level,
            )
            for position in powered
            if own.modules[position].alive
        )

        intents: list[_Intent] = []
        action_positions = sorted(
            powered,
            key=lambda position: (
                -own.modules[position].energy_wait_ticks,
                position[0],
                position[1],
                own.modules[position].placement.module_id,
            ),
        )
        projected_shield = own.shield
        projected_heat = {
            position: module.heat
            for position, module in own.modules.items()
            if position in powered and module.alive
        }
        projected_hp = {
            position: module.hp
            for position, module in own.modules.items()
            if position in powered and module.alive
        }
        for position in action_positions:
            module = own.modules[position]
            spec = get_spec(module.placement.kind)
            if (
                not module.alive
                or module.overheated
                or module.cooldown > 0
                or spec.energy_cost <= 0
            ):
                continue

            effect_multiplier, heat_multiplier = self._amplifier_multipliers(
                position, own, powered
            )
            amount = self._effect_amount(module.placement, effect_multiplier)
            target_position: tuple[int, int] | None = None
            target_core = False
            if spec.damage > 0:
                target_position = self._choose_target(
                    enemy, seed, tick, module.placement
                )
                target_core = target_position is None
            elif spec.shield > 0:
                if projected_shield >= self.config.max_board_shield - 1e-9:
                    module.energy_wait_ticks = 0
                    module.energy_starved_reported = False
                    continue
            elif spec.cooling > 0:
                if not any(heat > 1e-9 for heat in projected_heat.values()):
                    module.energy_wait_ticks = 0
                    module.energy_starved_reported = False
                    continue
            elif spec.repair > 0:
                target_position = self._choose_projected_repair_target(
                    own,
                    powered,
                    projected_hp,
                )
                if target_position is None:
                    module.energy_wait_ticks = 0
                    module.energy_starved_reported = False
                    continue

            energy_cost = scaled_value(spec.energy_cost, module.placement.level)
            total_energy = available_energy + own.energy_reserve
            if total_energy + 1e-9 < energy_cost:
                module.energy_wait_ticks += 1
                if not module.energy_starved_reported:
                    events.append(
                        BattleEvent(
                            tick=tick,
                            side=side,
                            event_type=EventType.ENERGY_STARVED,
                            actor_id=module.placement.module_id,
                            amount=energy_cost - total_energy,
                            detail="streak_started",
                        )
                    )
                    module.energy_starved_reported = True
                continue

            from_current = min(available_energy, energy_cost)
            available_energy -= from_current
            own.energy_reserve -= energy_cost - from_current
            own.energy_spent += energy_cost
            module.energy_wait_ticks = 0
            module.energy_starved_reported = False

            module.cooldown = spec.cooldown_ticks
            added_heat = (
                scaled_value(spec.heat_per_action, module.placement.level)
                * heat_multiplier
            )
            module.heat += added_heat
            projected_heat[position] = projected_heat.get(position, 0.0) + added_heat

            if spec.shield > 0:
                projected_shield = min(
                    self.config.max_board_shield,
                    projected_shield + amount,
                )
            elif spec.cooling > 0:
                for cooled_position, heat in projected_heat.items():
                    projected_heat[cooled_position] = max(0.0, heat - amount)
            elif spec.repair > 0 and target_position is not None:
                target = own.modules[target_position]
                projected_hp[target_position] = min(
                    target.max_hp,
                    projected_hp[target_position] + amount,
                )

            intents.append(
                _Intent(
                    tick=tick,
                    side=side,
                    actor_position=position,
                    kind=module.placement.kind,
                    amount=amount,
                    target_position=target_position,
                    target_core=target_core,
                )
            )

            if module.heat >= self.config.overheat_threshold:
                module.overheated = True
                events.append(
                    BattleEvent(
                        tick=tick,
                        side=side,
                        event_type=EventType.OVERHEAT,
                        actor_id=module.placement.module_id,
                        amount=module.heat,
                    )
                )

        own.energy_reserve = min(battery_capacity, own.energy_reserve + available_energy)
        return intents

    def _effect_amount(
        self, placement: ModulePlacement, effect_multiplier: float
    ) -> float:
        spec = get_spec(placement.kind)
        base = spec.damage or spec.shield or spec.cooling or spec.repair
        return scaled_value(base, placement.level) * effect_multiplier

    def _apply_support_intents(
        self,
        intents: list[_Intent],
        states: dict[Side, _BoardState],
        events: list[BattleEvent],
    ) -> None:
        for intent in intents:
            if intent.kind in (ModuleKind.LASER, ModuleKind.PULSE_CANNON):
                continue
            own = states[intent.side]
            actor = own.modules[intent.actor_position]
            actor_id = actor.placement.module_id

            if intent.kind is ModuleKind.SHIELD:
                before = own.shield
                own.shield = min(
                    self.config.max_board_shield, own.shield + intent.amount
                )
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.SHIELD,
                        actor_id=actor_id,
                        target_id="board",
                        amount=own.shield - before,
                    )
                )
            elif intent.kind is ModuleKind.COOLER:
                powered = self._powered_positions(own)
                removed_heat = 0.0
                for position in powered:
                    module = own.modules[position]
                    if module.alive:
                        before = module.heat
                        module.heat = max(0.0, module.heat - intent.amount)
                        removed_heat += before - module.heat
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.COOL,
                        actor_id=actor_id,
                        target_id="powered_circuit",
                        amount=removed_heat,
                    )
                )
            elif intent.kind is ModuleKind.REPAIR and intent.target_position is not None:
                target = own.modules.get(intent.target_position)
                if target is None or not target.alive:
                    continue
                before = target.hp
                target.hp = min(target.max_hp, target.hp + intent.amount)
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.REPAIR,
                        actor_id=actor_id,
                        target_id=target.placement.module_id,
                        amount=target.hp - before,
                    )
                )

    def _apply_attack_intents(
        self,
        intents: list[_Intent],
        states: dict[Side, _BoardState],
        events: list[BattleEvent],
    ) -> None:
        attacks = [
            intent
            for intent in intents
            if intent.kind in (ModuleKind.LASER, ModuleKind.PULSE_CANNON)
        ]
        for intent in attacks:
            attacker = states[intent.side]
            defender = states[intent.side.opposite]
            actor_id = attacker.modules[intent.actor_position].placement.module_id
            remaining = intent.amount

            if defender.shield > 0:
                absorbed = min(defender.shield, remaining)
                defender.shield -= absorbed
                remaining -= absorbed
                attacker.total_damage += absorbed
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.SHIELD_ABSORB,
                        actor_id=actor_id,
                        target_id="enemy_board",
                        amount=absorbed,
                    )
                )

            if remaining <= 0:
                continue

            if intent.target_core:
                actual = min(defender.core_hp, remaining)
                defender.core_hp = max(0.0, defender.core_hp - remaining)
                attacker.total_damage += actual
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.CORE_DAMAGE,
                        actor_id=actor_id,
                        target_id="enemy_core",
                        amount=actual,
                    )
                )
                continue

            target = (
                defender.modules.get(intent.target_position)
                if intent.target_position is not None
                else None
            )
            if target is None or not target.alive:
                target = self._fallback_target(defender)
            if target is None:
                actual = min(defender.core_hp, remaining)
                defender.core_hp = max(0.0, defender.core_hp - remaining)
                attacker.total_damage += actual
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.CORE_DAMAGE,
                        actor_id=actor_id,
                        target_id="enemy_core",
                        amount=actual,
                    )
                )
                continue

            actual = min(target.hp, remaining)
            target.hp = max(0.0, target.hp - remaining)
            attacker.total_damage += actual
            events.append(
                BattleEvent(
                    tick=intent.tick,
                    side=intent.side,
                    event_type=EventType.ATTACK,
                    actor_id=actor_id,
                    target_id=target.placement.module_id,
                    amount=actual,
                )
            )
            if target.hp <= 0:
                events.append(
                    BattleEvent(
                        tick=intent.tick,
                        side=intent.side,
                        event_type=EventType.DESTROYED,
                        actor_id=actor_id,
                        target_id=target.placement.module_id,
                    )
                )

    def _powered_positions(self, board: _BoardState) -> set[tuple[int, int]]:
        generators = [
            position
            for position, module in board.modules.items()
            if module.alive and module.placement.kind is ModuleKind.GENERATOR
        ]
        if not generators:
            return set()

        powered = set(generators)
        frontier = list(generators)
        while frontier:
            position = frontier.pop()
            for neighbor in self._power_neighbors(position, board):
                if neighbor not in powered and board.modules[neighbor].alive:
                    powered.add(neighbor)
                    frontier.append(neighbor)
        return powered

    def _power_neighbors(
        self, position: tuple[int, int], board: _BoardState
    ) -> list[tuple[int, int]]:
        neighbors = self._connected_neighbors(position, board)
        if not self._module_has_core_port(position, board):
            return neighbors

        for gate_position in CORE_GATE_DIRECTIONS:
            if (
                gate_position != position
                and gate_position not in neighbors
                and self._module_has_core_port(gate_position, board)
            ):
                neighbors.append(gate_position)
        return neighbors

    def _module_has_core_port(
        self, position: tuple[int, int], board: _BoardState
    ) -> bool:
        core_direction = CORE_GATE_DIRECTIONS.get(position)
        module = board.modules.get(position)
        if core_direction is None or module is None or not module.alive:
            return False
        return core_direction in world_ports(
            module.placement.kind,
            module.placement.orientation,
        )

    def _connected_neighbors(
        self, position: tuple[int, int], board: _BoardState
    ) -> list[tuple[int, int]]:
        module = board.modules[position]
        ports = world_ports(module.placement.kind, module.placement.orientation)
        neighbors: list[tuple[int, int]] = []
        for direction in Direction:
            if direction not in ports:
                continue
            row_delta, column_delta = direction.delta
            neighbor_position = (
                position[0] + row_delta,
                position[1] + column_delta,
            )
            neighbor = board.modules.get(neighbor_position)
            if neighbor is None or not neighbor.alive:
                continue
            neighbor_ports = world_ports(
                neighbor.placement.kind, neighbor.placement.orientation
            )
            if direction.opposite in neighbor_ports:
                neighbors.append(neighbor_position)
        return neighbors

    def _amplifier_multipliers(
        self,
        target_position: tuple[int, int],
        board: _BoardState,
        powered: set[tuple[int, int]],
    ) -> tuple[float, float]:
        amplifier_count = 0
        for position in powered:
            amplifier = board.modules[position]
            if (
                not amplifier.alive
                or amplifier.placement.kind is not ModuleKind.AMPLIFIER
            ):
                continue
            row_delta, column_delta = amplifier.placement.orientation.delta
            front = (position[0] + row_delta, position[1] + column_delta)
            if front == target_position and target_position in self._connected_neighbors(
                position, board
            ):
                amplifier_count += 1

        effect = min(
            self.config.max_effect_multiplier,
            self.config.amplifier_effect_multiplier**amplifier_count,
        )
        heat = min(
            self.config.max_heat_multiplier,
            self.config.amplifier_heat_multiplier**amplifier_count,
        )
        return effect, heat

    def _choose_target(
        self,
        enemy: _BoardState,
        seed: int,
        tick: int,
        actor: ModulePlacement,
    ) -> tuple[int, int] | None:
        eligible = self._eligible_attack_targets(enemy)
        if not eligible:
            return None

        highest_threat = max(
            get_spec(module.placement.kind).threat for _, module in eligible
        )
        candidates = sorted(
            position
            for position, module in eligible
            if get_spec(module.placement.kind).threat == highest_threat
        )
        key = (
            f"{seed}:{tick}:{actor.row}:{actor.column}:{actor.kind.value}"
        ).encode("utf-8")
        index = int.from_bytes(hashlib.sha256(key).digest()[:8], "big") % len(candidates)
        return candidates[index]

    def _eligible_attack_targets(
        self,
        board: _BoardState,
    ) -> list[tuple[tuple[int, int], _ModuleState]]:
        """Return only the targets in the defender's current combat phase."""
        regular_modules = [
            (position, module)
            for position, module in board.modules.items()
            if module.alive and module.placement.kind is not ModuleKind.GENERATOR
        ]
        if regular_modules:
            return regular_modules

        generators = [
            (position, module)
            for position, module in board.modules.items()
            if module.alive and module.placement.kind is ModuleKind.GENERATOR
        ]
        return generators

    def _choose_repair_target(
        self,
        board: _BoardState,
        powered: set[tuple[int, int]],
    ) -> tuple[int, int] | None:
        damaged = [
            (module.hp / module.max_hp, position)
            for position in powered
            if (module := board.modules[position]).alive and module.hp < module.max_hp
        ]
        return min(damaged, default=(0.0, None))[1]

    def _choose_projected_repair_target(
        self,
        board: _BoardState,
        powered: set[tuple[int, int]],
        projected_hp: dict[tuple[int, int], float],
    ) -> tuple[int, int] | None:
        damaged = [
            (projected_hp[position] / module.max_hp, position)
            for position in powered
            if (module := board.modules[position]).alive
            and projected_hp[position] < module.max_hp - 1e-9
        ]
        return min(damaged, default=(0.0, None))[1]

    def _fallback_target(self, board: _BoardState) -> _ModuleState | None:
        eligible = self._eligible_attack_targets(board)
        if not eligible:
            return None
        return max(
            (module for _, module in eligible),
            key=lambda module: (
                get_spec(module.placement.kind).threat,
                -module.placement.row,
                -module.placement.column,
            ),
        )

    def _resolve_timeout(
        self, states: dict[Side, _BoardState]
    ) -> tuple[Side | None, str]:
        left_score = self._tiebreak_score(states[Side.LEFT])
        right_score = self._tiebreak_score(states[Side.RIGHT])
        if left_score > right_score:
            return Side.LEFT, "timeout_tiebreak"
        if right_score > left_score:
            return Side.RIGHT, "timeout_tiebreak"
        return None, "exact_draw"

    def _tiebreak_score(self, board: _BoardState) -> tuple[float, ...]:
        metrics = self._tiebreak_metrics(board)
        return (
            metrics["core_hp_ratio"],
            metrics["surviving_modules"],
            metrics["module_hp_ratio"],
            metrics["total_damage"],
            metrics["damage_efficiency"],
            -metrics["total_heat"],
        )

    def _tiebreak_metrics(self, board: _BoardState) -> dict[str, float]:
        alive = [module for module in board.modules.values() if module.alive]
        all_max_hp = sum(module.max_hp for module in board.modules.values())
        module_hp = sum(module.hp for module in board.modules.values())
        efficiency = board.total_damage / max(1.0, board.energy_spent)
        total_heat = sum(module.heat for module in alive)
        return {
            "core_hp_ratio": round(board.core_hp / self.config.core_hp, 6),
            "surviving_modules": float(len(alive)),
            "module_hp_ratio": round(module_hp / all_max_hp, 6),
            "total_damage": round(board.total_damage, 6),
            "damage_efficiency": round(efficiency, 6),
            "total_heat": round(total_heat, 6),
        }

    def _build_decision(
        self,
        states: dict[Side, _BoardState],
        reason: str,
    ) -> BattleDecision:
        left_metrics = self._tiebreak_metrics(states[Side.LEFT])
        right_metrics = self._tiebreak_metrics(states[Side.RIGHT])
        preferences = {
            "core_hp_ratio": "higher",
            "surviving_modules": "higher",
            "module_hp_ratio": "higher",
            "total_damage": "higher",
            "damage_efficiency": "higher",
            "total_heat": "lower",
        }
        metrics = tuple(
            DecisionMetric(
                key=key,
                left_value=left_metrics[key],
                right_value=right_metrics[key],
                preferred=preference,
            )
            for key, preference in preferences.items()
        )

        if reason in {"core_destroyed", "mutual_core_destruction"}:
            return BattleDecision(criterion=reason, metrics=metrics)

        for metric in metrics:
            if metric.left_value != metric.right_value:
                return BattleDecision(criterion=metric.key, metrics=metrics)
        return BattleDecision(criterion="exact_draw", metrics=metrics)

    def _summarize(self, board: _BoardState) -> BoardSummary:
        powered = self._powered_positions(board)
        modules = tuple(
            ModuleSummary(
                module_id=module.placement.module_id,
                kind=module.placement.kind,
                hp=module.hp,
                max_hp=module.max_hp,
                heat=module.heat,
                powered=position in powered,
                overheated=module.overheated,
            )
            for position, module in sorted(board.modules.items())
        )
        return BoardSummary(
            name=board.layout.name,
            core_hp=board.core_hp,
            core_max_hp=self.config.core_hp,
            shield=board.shield,
            energy_spent=board.energy_spent,
            total_damage=board.total_damage,
            modules=modules,
        )

    def _snapshot_frame(
        self,
        tick: int,
        states: dict[Side, _BoardState],
    ) -> ReplayStateFrame:
        return ReplayStateFrame(
            tick=tick,
            left=self._snapshot_board(states[Side.LEFT]),
            right=self._snapshot_board(states[Side.RIGHT]),
        )

    def _snapshot_board(self, board: _BoardState) -> ReplayBoardState:
        powered = self._powered_positions(board)
        energy_output = sum(
            scaled_value(
                get_spec(board.modules[position].placement.kind).energy_output,
                board.modules[position].placement.level,
            )
            for position in powered
            if board.modules[position].alive
        )
        modules = tuple(
            ReplayModuleState(
                module_id=module.placement.module_id,
                hp=module.hp,
                max_hp=module.max_hp,
                heat=module.heat,
                cooldown=module.cooldown,
                powered=position in powered,
                overheated=module.overheated,
            )
            for position, module in sorted(board.modules.items())
        )
        return ReplayBoardState(
            core_hp=board.core_hp,
            shield=board.shield,
            energy_reserve=board.energy_reserve,
            energy_output=energy_output,
            energy_spent=board.energy_spent,
            modules=modules,
        )
