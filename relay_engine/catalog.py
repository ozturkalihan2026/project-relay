from __future__ import annotations

import json
from dataclasses import dataclass
from importlib.resources import files
from typing import Any

from .enums import Direction, ModuleKind


@dataclass(frozen=True, slots=True)
class ModuleSpec:
    kind: ModuleKind
    display_name: str
    description: str
    max_hp: float
    ports: frozenset[Direction]
    energy_output: float = 0.0
    battery_capacity: float = 0.0
    energy_cost: float = 0.0
    cooldown_ticks: int = 0
    heat_per_action: float = 0.0
    damage: float = 0.0
    shield: float = 0.0
    cooling: float = 0.0
    repair: float = 0.0
    threat: int = 0


ALL_PORTS = frozenset(Direction)
_NUMERIC_FIELDS = (
    "energy_output",
    "battery_capacity",
    "energy_cost",
    "heat_per_action",
    "damage",
    "shield",
    "cooling",
    "repair",
)


def load_module_specs(payload: dict[str, Any]) -> dict[ModuleKind, ModuleSpec]:
    if payload.get("schema_version") != 1:
        raise RuntimeError("Desteklenmeyen modül içerik şeması.")
    raw_modules = payload.get("modules")
    if not isinstance(raw_modules, list):
        raise RuntimeError("Modül içeriğinde 'modules' listesi bulunmalıdır.")

    result: dict[ModuleKind, ModuleSpec] = {}
    for raw in raw_modules:
        if not isinstance(raw, dict):
            raise RuntimeError("Her modül girdisi bir nesne olmalıdır.")
        try:
            kind = ModuleKind(str(raw["kind"]))
            ports = frozenset(Direction(str(value)) for value in raw["ports"])
            display_name = str(raw["display_name"]).strip()
            description = str(raw["description"]).strip()
            max_hp = _non_negative_number(raw["max_hp"], "max_hp")
        except (KeyError, TypeError, ValueError) as exc:
            raise RuntimeError(f"Geçersiz modül içeriği: {raw!r}") from exc
        if kind in result:
            raise RuntimeError(f"Yinelenen modül türü: {kind.value}")
        if not display_name or not description or max_hp <= 0 or not ports:
            raise RuntimeError(f"Eksik modül tanımı: {kind.value}")
        values = {
            field: _non_negative_number(raw.get(field, 0), field)
            for field in _NUMERIC_FIELDS
        }
        cooldown_ticks = _non_negative_int(
            raw.get("cooldown_ticks", 0),
            "cooldown_ticks",
        )
        threat = _non_negative_int(raw.get("threat", 0), "threat")
        result[kind] = ModuleSpec(
            kind=kind,
            display_name=display_name,
            description=description,
            max_hp=max_hp,
            ports=ports,
            cooldown_ticks=cooldown_ticks,
            threat=threat,
            **values,
        )

    missing = set(ModuleKind) - set(result)
    extra_count = len(result) - len(ModuleKind)
    if missing or extra_count:
        labels = ", ".join(sorted(kind.value for kind in missing))
        raise RuntimeError(f"Modül kataloğu eksik veya geçersiz: {labels}")
    return result


def _load_bundled_module_specs() -> dict[ModuleKind, ModuleSpec]:
    resource = files("relay_content").joinpath("modules.json")
    payload = json.loads(resource.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise RuntimeError("Modül içerik kökü bir nesne olmalıdır.")
    return load_module_specs(payload)


def _non_negative_number(value: Any, field: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise RuntimeError(f"{field} sayısal olmalıdır.")
    number = float(value)
    if number < 0:
        raise RuntimeError(f"{field} negatif olamaz.")
    return number


def _non_negative_int(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise RuntimeError(f"{field} negatif olmayan tam sayı olmalıdır.")
    return value


MODULE_SPECS = _load_bundled_module_specs()


def get_spec(kind: ModuleKind) -> ModuleSpec:
    return MODULE_SPECS[kind]


def world_ports(kind: ModuleKind, orientation: Direction) -> frozenset[Direction]:
    spec = get_spec(kind)
    if spec.ports == ALL_PORTS:
        return ALL_PORTS
    return frozenset(orientation.rotate_from_east(port) for port in spec.ports)
