from __future__ import annotations

from enum import Enum


class Direction(str, Enum):
    NORTH = "north"
    EAST = "east"
    SOUTH = "south"
    WEST = "west"

    @property
    def delta(self) -> tuple[int, int]:
        return {
            Direction.NORTH: (-1, 0),
            Direction.EAST: (0, 1),
            Direction.SOUTH: (1, 0),
            Direction.WEST: (0, -1),
        }[self]

    @property
    def opposite(self) -> Direction:
        return {
            Direction.NORTH: Direction.SOUTH,
            Direction.EAST: Direction.WEST,
            Direction.SOUTH: Direction.NORTH,
            Direction.WEST: Direction.EAST,
        }[self]

    def rotate_from_east(self, relative: Direction) -> Direction:
        """Rotate a port defined for an east-facing module."""
        directions = [
            Direction.NORTH,
            Direction.EAST,
            Direction.SOUTH,
            Direction.WEST,
        ]
        steps = (directions.index(self) - directions.index(Direction.EAST)) % 4
        return directions[(directions.index(relative) + steps) % 4]


class ModuleKind(str, Enum):
    GENERATOR = "generator"
    BATTERY = "battery"
    LASER = "laser"
    PULSE_CANNON = "pulse_cannon"
    SHIELD = "shield"
    COOLER = "cooler"
    AMPLIFIER = "amplifier"
    REPAIR = "repair"


class Side(str, Enum):
    LEFT = "left"
    RIGHT = "right"

    @property
    def opposite(self) -> Side:
        return Side.RIGHT if self is Side.LEFT else Side.LEFT


class EventType(str, Enum):
    MODULE_SWAP = "module_swap"
    OVERLOAD = "overload"
    ENERGY_STARVED = "energy_starved"
    OVERHEAT = "overheat"
    RECOVERED = "recovered"
    ATTACK = "attack"
    SHIELD = "shield"
    SHIELD_ABSORB = "shield_absorb"
    COOL = "cool"
    REPAIR = "repair"
    DESTROYED = "destroyed"
    CORE_DAMAGE = "core_damage"
