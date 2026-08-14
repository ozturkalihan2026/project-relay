from __future__ import annotations

from dataclasses import dataclass
from typing import Mapping


@dataclass(frozen=True, slots=True)
class InterventionPolicy:
    windows: tuple[int, ...] = (60, 90, 120)
    max_swaps: int = 2
    max_swaps_per_window: int = 1

    def validate(self) -> None:
        if not self.windows or any(window <= 0 for window in self.windows):
            raise ValueError("Müdahale pencereleri pozitif olmalıdır.")
        if tuple(sorted(set(self.windows))) != self.windows:
            raise ValueError("Müdahale pencereleri sıralı ve benzersiz olmalıdır.")
        if self.max_swaps <= 0 or self.max_swaps_per_window <= 0:
            raise ValueError("Müdahale hakları pozitif olmalıdır.")


@dataclass(frozen=True, slots=True)
class ModuleVitality:
    module_id: str
    hp: float
    max_hp: float

    def to_dict(self) -> dict[str, float | str]:
        return {
            "module_id": self.module_id,
            "hp": round(self.hp, 3),
            "max_hp": round(self.max_hp, 3),
        }


@dataclass(frozen=True, slots=True)
class ModuleSwapResult:
    tick: int
    outgoing: ModuleVitality
    incoming: ModuleVitality
    swaps_used: int
    swaps_remaining: int

    def to_dict(self) -> dict[str, object]:
        return {
            "tick": self.tick,
            "outgoing": self.outgoing.to_dict(),
            "incoming": self.incoming.to_dict(),
            "swaps_used": self.swaps_used,
            "swaps_remaining": self.swaps_remaining,
        }


class InterventionError(ValueError):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code


class ModuleHealthRack:
    """Tracks active and benched module HP across tactical swap windows.

    Active modules begin with their supplied current HP. Reserve modules have no
    current HP until their first deployment, so they enter at full HP. Once a
    module has been active, every later bench/re-entry cycle preserves its most
    recent HP.
    """

    def __init__(
        self,
        *,
        active: Mapping[str, tuple[float, float]],
        reserves: Mapping[str, float],
        policy: InterventionPolicy | None = None,
    ) -> None:
        self.policy = policy or InterventionPolicy()
        self.policy.validate()
        if not active:
            raise ValueError("Müdahale rafı en az bir aktif modül gerektirir.")
        overlap = set(active).intersection(reserves)
        if overlap:
            raise ValueError(f"Modül hem aktif hem rafta olamaz: {sorted(overlap)}")
        self._active_ids = set(active)
        self._max_hp = {
            **{module_id: values[1] for module_id, values in active.items()},
            **dict(reserves),
        }
        self._stored_hp: dict[str, float | None] = {
            **{
                module_id: self._clamp_hp(current_hp, max_hp)
                for module_id, (current_hp, max_hp) in active.items()
            },
            **{module_id: None for module_id in reserves},
        }
        self._used_windows: set[int] = set()
        self._swaps_used = 0

    @property
    def swaps_used(self) -> int:
        return self._swaps_used

    @property
    def swaps_remaining(self) -> int:
        return max(0, self.policy.max_swaps - self._swaps_used)

    @property
    def active_ids(self) -> frozenset[str]:
        return frozenset(self._active_ids)

    @property
    def used_windows(self) -> frozenset[int]:
        return frozenset(self._used_windows)

    def update_active_hp(self, module_id: str, hp: float) -> ModuleVitality:
        if module_id not in self._active_ids:
            raise InterventionError(
                "module_not_active",
                "Yalnız aktif bir modülün canı güncellenebilir.",
            )
        max_hp = self._max_hp[module_id]
        current = self._clamp_hp(hp, max_hp)
        self._stored_hp[module_id] = current
        return ModuleVitality(module_id, current, max_hp)

    def vitality(self, module_id: str) -> ModuleVitality | None:
        if module_id not in self._max_hp:
            raise InterventionError("module_not_found", "Modül müdahale rafında yok.")
        hp = self._stored_hp[module_id]
        if hp is None:
            return None
        return ModuleVitality(module_id, hp, self._max_hp[module_id])

    def swap(
        self,
        *,
        tick: int,
        outgoing_id: str,
        incoming_id: str,
    ) -> ModuleSwapResult:
        if tick not in self.policy.windows:
            raise InterventionError(
                "window_closed",
                "Modül değişimi yalnız 60, 90 ve 120. adımlarda yapılabilir.",
            )
        if tick in self._used_windows:
            raise InterventionError(
                "window_already_used",
                "Bu müdahale penceresinde bir değişim zaten yapıldı.",
            )
        if self._swaps_used >= self.policy.max_swaps:
            raise InterventionError(
                "swap_limit_reached",
                "Savaşın iki modül değişim hakkı kullanıldı.",
            )
        if outgoing_id not in self._active_ids:
            raise InterventionError(
                "outgoing_not_active",
                "Çıkarılacak modül aktif devrede bulunmuyor.",
            )
        if incoming_id in self._active_ids:
            raise InterventionError(
                "incoming_already_active",
                "Girecek modül zaten aktif devrede.",
            )
        if incoming_id not in self._max_hp:
            raise InterventionError(
                "incoming_not_available",
                "Girecek modül müdahale rafında bulunmuyor.",
            )

        outgoing_hp = self._stored_hp[outgoing_id]
        if outgoing_hp is None:
            raise InterventionError(
                "outgoing_hp_missing",
                "Aktif modülün güncel canı bulunamadı.",
            )
        incoming_hp = self._stored_hp[incoming_id]
        if incoming_hp is None:
            incoming_hp = self._max_hp[incoming_id]
            self._stored_hp[incoming_id] = incoming_hp

        self._active_ids.remove(outgoing_id)
        self._active_ids.add(incoming_id)
        self._used_windows.add(tick)
        self._swaps_used += 1
        return ModuleSwapResult(
            tick=tick,
            outgoing=ModuleVitality(
                outgoing_id,
                outgoing_hp,
                self._max_hp[outgoing_id],
            ),
            incoming=ModuleVitality(
                incoming_id,
                incoming_hp,
                self._max_hp[incoming_id],
            ),
            swaps_used=self._swaps_used,
            swaps_remaining=self.swaps_remaining,
        )

    @staticmethod
    def _clamp_hp(hp: float, max_hp: float) -> float:
        if max_hp <= 0:
            raise ValueError("Azami modül canı pozitif olmalıdır.")
        return min(max_hp, max(0.0, hp))
