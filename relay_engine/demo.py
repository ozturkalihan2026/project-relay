from __future__ import annotations

import argparse
import json
from pathlib import Path

from .engine import CircuitBattleEngine
from .enums import Direction, ModuleKind
from .models import BoardLayout, ModulePlacement


def demo_boards() -> tuple[BoardLayout, BoardLayout]:
    left = BoardLayout(
        name="Mavi Devre",
        modules=(
            ModulePlacement(
                "L-GEN", ModuleKind.GENERATOR, 0, 1, Direction.SOUTH
            ),
            ModulePlacement("L-LASER", ModuleKind.LASER, 0, 2),
            ModulePlacement("L-BAT", ModuleKind.BATTERY, 1, 3),
            ModulePlacement("L-PULSE", ModuleKind.PULSE_CANNON, 0, 3, Direction.NORTH),
            ModulePlacement("L-SHIELD", ModuleKind.SHIELD, 2, 3, Direction.SOUTH),
            ModulePlacement("L-COOL", ModuleKind.COOLER, 3, 2, Direction.SOUTH),
        ),
    )
    right = BoardLayout(
        name="Kırmızı Devre",
        modules=(
            ModulePlacement(
                "R-GEN", ModuleKind.GENERATOR, 2, 0, Direction.EAST
            ),
            ModulePlacement("R-PULSE", ModuleKind.PULSE_CANNON, 3, 0, Direction.SOUTH),
            ModulePlacement("R-BAT", ModuleKind.BATTERY, 3, 2),
            ModulePlacement("R-LASER", ModuleKind.LASER, 3, 1, Direction.WEST),
            ModulePlacement("R-SHIELD", ModuleKind.SHIELD, 3, 3),
            ModulePlacement("R-REPAIR", ModuleKind.REPAIR, 1, 3),
        ),
    )
    return left, right


def main() -> None:
    parser = argparse.ArgumentParser(description="Project Relay savaş demosu")
    parser.add_argument("--seed", type=int, default=2026)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    engine = CircuitBattleEngine()
    left, right = demo_boards()
    result = engine.simulate(left, right, seed=args.seed)
    payload = result.to_dict(include_events=True)

    winner = result.winner.value if result.winner else "beraberlik"
    print(f"Sonuç: {winner} | neden: {result.reason} | adım: {result.ticks}")
    print(f"Tekrar özeti: {result.replay_checksum}")
    print(f"Olay sayısı: {len(result.events)}")
    print("\nİlk 12 olay:")
    print(
        json.dumps(
            [event.to_dict() for event in result.events[:12]],
            ensure_ascii=False,
            indent=2,
        )
    )

    if args.output:
        args.output.write_text(
            json.dumps(payload, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        print(f"\nTam tekrar kaydı yazıldı: {args.output}")


if __name__ == "__main__":
    main()
