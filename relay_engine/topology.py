from __future__ import annotations

from .enums import Direction


BOARD_SIZE = 4
CORE_CELLS = frozenset(
    {
        (1, 1),
        (1, 2),
        (2, 1),
        (2, 2),
    }
)

# The four gates form one rotationally symmetric set around the 2x2 core.
# Each value points from the gate cell into the core.
CORE_GATE_DIRECTIONS: dict[tuple[int, int], Direction] = {
    (0, 1): Direction.SOUTH,
    (1, 3): Direction.WEST,
    (3, 2): Direction.NORTH,
    (2, 0): Direction.EAST,
}
CORE_GATE_CELLS = frozenset(CORE_GATE_DIRECTIONS)
PLACEABLE_CELLS = frozenset(
    (row, column)
    for row in range(BOARD_SIZE)
    for column in range(BOARD_SIZE)
    if (row, column) not in CORE_CELLS
)


def core_direction(position: tuple[int, int]) -> Direction | None:
    return CORE_GATE_DIRECTIONS.get(position)


def is_core_cell(position: tuple[int, int]) -> bool:
    return position in CORE_CELLS


def is_core_gate(position: tuple[int, int]) -> bool:
    return position in CORE_GATE_CELLS
