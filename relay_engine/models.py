from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from .catalog import get_spec
from .enums import Direction, EventType, ModuleKind, Side
from .topology import BOARD_SIZE, CORE_CELLS, CORE_GATE_DIRECTIONS


MAX_BOARD_MODULES = 6


@dataclass(frozen=True, slots=True)
class ModulePlacement:
    module_id: str
    kind: ModuleKind
    row: int
    column: int
    orientation: Direction = Direction.EAST
    level: int = 1

    @property
    def position(self) -> tuple[int, int]:
        return self.row, self.column

    def to_dict(self) -> dict[str, Any]:
        return {
            "module_id": self.module_id,
            "kind": self.kind.value,
            "row": self.row,
            "column": self.column,
            "orientation": self.orientation.value,
            "level": self.level,
        }


@dataclass(frozen=True, slots=True)
class BoardLayout:
    modules: tuple[ModulePlacement, ...]
    name: str = "Devre"

    def validate(self, board_size: int = BOARD_SIZE) -> None:
        if board_size != BOARD_SIZE:
            raise ValueError("Merkezî çekirdek topolojisi 4×4 kart gerektirir.")
        if not self.modules:
            raise ValueError("Kartta en az bir modül bulunmalıdır.")
        if len(self.modules) > MAX_BOARD_MODULES:
            raise ValueError(
                f"Bir savaş kartında en fazla {MAX_BOARD_MODULES} modül "
                "kullanılabilir."
            )

        ids: set[str] = set()
        positions: set[tuple[int, int]] = set()
        generator_count = 0

        for module in self.modules:
            if not module.module_id.strip():
                raise ValueError("Modül kimliği boş olamaz.")
            if module.module_id in ids:
                raise ValueError(f"Tekrarlanan modül kimliği: {module.module_id}")
            if module.position in positions:
                raise ValueError(f"Aynı hücrede birden fazla modül var: {module.position}")
            if not 0 <= module.row < board_size or not 0 <= module.column < board_size:
                raise ValueError(
                    f"Modül kart sınırları dışında: {module.module_id} {module.position}"
                )
            if module.position in CORE_CELLS:
                raise ValueError(
                    "Ortadaki 2×2 alan pasif çekirdeğe ayrılmıştır; "
                    f"modül yerleştirilemez: {module.position}"
                )
            if not 1 <= module.level <= 3:
                raise ValueError("Prototipte modül seviyesi 1 ile 3 arasında olmalıdır.")

            ids.add(module.module_id)
            positions.add(module.position)
            generator_count += int(module.kind is ModuleKind.GENERATOR)

        if generator_count != 1:
            raise ValueError("Her kartta tam olarak bir jeneratör bulunmalıdır.")

        generator = next(
            module
            for module in self.modules
            if module.kind is ModuleKind.GENERATOR
        )
        required_direction = CORE_GATE_DIRECTIONS.get(generator.position)
        if required_direction is None:
            raise ValueError(
                "Jeneratör yalnızca çekirdeğin dört kapı hücresinden birine "
                "yerleştirilebilir."
            )
        if generator.orientation is not required_direction:
            raise ValueError(
                "Jeneratörün ön yönü çekirdeğe bakmalıdır: "
                f"{generator.position} için {required_direction.value}."
            )

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "modules": [module.to_dict() for module in self.modules],
        }


@dataclass(frozen=True, slots=True)
class BattleModifiers:
    """Run-local combat modifiers. Never persisted as competitive power."""

    generator_output_multiplier: float = 1.0
    initial_shield: float = 0.0
    module_hp_bonus: float = 0.0
    initial_energy_reserve: float = 0.0
    reserve_capacity_bonus: float = 0.0


@dataclass(frozen=True, slots=True)
class BattleConfig:
    board_size: int = BOARD_SIZE
    core_hp: float = 120
    max_ticks: int = 90
    passive_heat_loss: float = 2
    overheat_threshold: float = 100
    recovery_threshold: float = 55
    max_board_shield: float = 60
    amplifier_effect_multiplier: float = 1.35
    amplifier_heat_multiplier: float = 1.25
    max_effect_multiplier: float = 1.75
    max_heat_multiplier: float = 1.60


@dataclass(frozen=True, slots=True)
class BattleEvent:
    tick: int
    side: Side
    event_type: EventType
    actor_id: str
    target_id: str | None = None
    amount: float = 0.0
    detail: str | None = None

    def to_dict(self) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "tick": self.tick,
            "side": self.side.value,
            "type": self.event_type.value,
            "actor_id": self.actor_id,
            "amount": round(self.amount, 3),
        }
        if self.target_id is not None:
            payload["target_id"] = self.target_id
        if self.detail is not None:
            payload["detail"] = self.detail
        return payload


@dataclass(frozen=True, slots=True)
class ModuleSummary:
    module_id: str
    kind: ModuleKind
    hp: float
    max_hp: float
    heat: float
    powered: bool
    overheated: bool

    def to_dict(self) -> dict[str, Any]:
        return {
            "module_id": self.module_id,
            "kind": self.kind.value,
            "hp": round(self.hp, 3),
            "max_hp": round(self.max_hp, 3),
            "heat": round(self.heat, 3),
            "powered": self.powered,
            "overheated": self.overheated,
        }


@dataclass(frozen=True, slots=True)
class BoardSummary:
    name: str
    core_hp: float
    core_max_hp: float
    shield: float
    energy_spent: float
    total_damage: float
    modules: tuple[ModuleSummary, ...]

    @property
    def surviving_modules(self) -> int:
        return sum(module.hp > 0 for module in self.modules)

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "core_hp": round(self.core_hp, 3),
            "core_max_hp": round(self.core_max_hp, 3),
            "shield": round(self.shield, 3),
            "energy_spent": round(self.energy_spent, 3),
            "total_damage": round(self.total_damage, 3),
            "surviving_modules": self.surviving_modules,
            "modules": [module.to_dict() for module in self.modules],
        }


@dataclass(frozen=True, slots=True)
class DecisionMetric:
    key: str
    left_value: float
    right_value: float
    preferred: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "left_value": round(self.left_value, 6),
            "right_value": round(self.right_value, 6),
            "preferred": self.preferred,
        }


@dataclass(frozen=True, slots=True)
class BattleDecision:
    criterion: str
    metrics: tuple[DecisionMetric, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "criterion": self.criterion,
            "metrics": [metric.to_dict() for metric in self.metrics],
        }


@dataclass(frozen=True, slots=True)
class ReplayModuleState:
    module_id: str
    hp: float
    max_hp: float
    heat: float
    cooldown: int
    powered: bool
    overheated: bool

    def to_dict(self) -> dict[str, Any]:
        return {
            "module_id": self.module_id,
            "hp": round(self.hp, 3),
            "max_hp": round(self.max_hp, 3),
            "heat": round(self.heat, 3),
            "cooldown": self.cooldown,
            "powered": self.powered,
            "overheated": self.overheated,
        }


@dataclass(frozen=True, slots=True)
class ReplayBoardState:
    core_hp: float
    shield: float
    energy_reserve: float
    energy_output: float
    energy_spent: float
    modules: tuple[ReplayModuleState, ...]

    def to_dict(self) -> dict[str, Any]:
        return {
            "core_hp": round(self.core_hp, 3),
            "shield": round(self.shield, 3),
            "energy_reserve": round(self.energy_reserve, 3),
            "energy_output": round(self.energy_output, 3),
            "energy_spent": round(self.energy_spent, 3),
            "modules": [module.to_dict() for module in self.modules],
        }


@dataclass(frozen=True, slots=True)
class ReplayStateFrame:
    tick: int
    left: ReplayBoardState
    right: ReplayBoardState

    def to_dict(self) -> dict[str, Any]:
        return {
            "tick": self.tick,
            "left": self.left.to_dict(),
            "right": self.right.to_dict(),
        }


@dataclass(frozen=True, slots=True)
class BattleResult:
    winner: Side | None
    reason: str
    ticks: int
    seed: int
    left: BoardSummary
    right: BoardSummary
    decision: BattleDecision
    events: tuple[BattleEvent, ...] = field(repr=False)
    state_frames: tuple[ReplayStateFrame, ...] = field(
        default=(),
        repr=False,
    )
    replay_checksum: str = ""

    def to_dict(self, include_events: bool = True) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "winner": self.winner.value if self.winner else None,
            "reason": self.reason,
            "ticks": self.ticks,
            "seed": self.seed,
            "left": self.left.to_dict(),
            "right": self.right.to_dict(),
            "decision": self.decision.to_dict(),
            "replay_checksum": self.replay_checksum,
        }
        if include_events:
            payload["events"] = [event.to_dict() for event in self.events]
            payload["state_frames"] = [
                frame.to_dict() for frame in self.state_frames
            ]
        return payload


def scaled_value(value: float, level: int) -> float:
    """Run-local level scaling. Account progression never calls this."""
    return value * (1 + 0.18 * (level - 1))


def module_max_hp(module: ModulePlacement) -> float:
    return scaled_value(get_spec(module.kind).max_hp, module.level)
