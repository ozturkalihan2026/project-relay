"""Generate Project Relay's deterministic local combat sound set."""

from __future__ import annotations

import math
import random
import struct
import wave
from collections.abc import Callable
from pathlib import Path


SAMPLE_RATE = 44_100
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "sounds"
Signal = Callable[[float], float]


def _sweep(
    start_hz: float,
    end_hz: float,
    duration: float,
    *,
    phase: float = 0,
) -> Signal:
    slope = (end_hz - start_hz) / duration

    def signal(time: float) -> float:
        angle = (
            2
            * math.pi
            * (start_hz * time + 0.5 * slope * time * time)
            + phase
        )
        return math.sin(angle)

    return signal


def _tone(frequency: float, *, phase: float = 0) -> Signal:
    return lambda time: math.sin(2 * math.pi * frequency * time + phase)


def _envelope(
    duration: float,
    *,
    attack: float = 0.01,
    release: float = 0.2,
    curve: float = 1.5,
) -> Signal:
    def signal(time: float) -> float:
        if time < 0 or time >= duration:
            return 0
        attack_gain = min(1.0, time / max(attack, 1e-6))
        release_start = max(attack, duration - release)
        if time <= release_start:
            release_gain = 1.0
        else:
            release_gain = max(
                0.0,
                (duration - time) / max(release, 1e-6),
            )
        return attack_gain * release_gain**curve

    return signal


def _delayed(signal: Signal, delay: float, gain: float = 1) -> Signal:
    return lambda time: gain * signal(time - delay) if time >= delay else 0


def _noise(seed: int, *, smoothing: float = 0) -> Signal:
    randomizer = random.Random(seed)
    values = [
        randomizer.uniform(-1, 1)
        for _ in range(int(SAMPLE_RATE * 1.2) + 1)
    ]
    if smoothing > 0:
        previous = 0.0
        for index, value in enumerate(values):
            previous = previous * smoothing + value * (1 - smoothing)
            values[index] = previous

    def signal(time: float) -> float:
        index = int(time * SAMPLE_RATE)
        return values[index] if 0 <= index < len(values) else 0

    return signal


def _layer(signal: Signal, envelope: Signal, gain: float) -> Signal:
    return lambda time: signal(time) * envelope(time) * gain


def _mix(*signals: Signal) -> Signal:
    return lambda time: sum(signal(time) for signal in signals)


def _write(name: str, duration: float, signal: Signal) -> None:
    samples = [
        signal(index / SAMPLE_RATE)
        for index in range(int(duration * SAMPLE_RATE))
    ]
    peak = max(max(abs(sample) for sample in samples), 1e-9)
    scale = 0.88 / peak
    pcm = b"".join(
        struct.pack(
            "<h",
            int(max(-1.0, min(1.0, sample * scale)) * 32_767),
        )
        for sample in samples
    )
    with wave.open(str(OUTPUT / name), "wb") as target:
        target.setnchannels(1)
        target.setsampwidth(2)
        target.setframerate(SAMPLE_RATE)
        target.writeframes(pcm)


def _laser() -> tuple[float, Signal]:
    duration = 0.42
    body = _mix(
        _layer(
            _sweep(2_350, 230, 0.34),
            _envelope(0.34, attack=0.002, release=0.22),
            1.0,
        ),
        _layer(
            _sweep(1_250, 115, 0.38, phase=0.4),
            _envelope(0.38, attack=0.003, release=0.27),
            0.5,
        ),
    )
    return duration, _mix(body, _delayed(body, 0.055, 0.25))


def _pulse_cannon() -> tuple[float, Signal]:
    duration = 0.58
    return duration, _mix(
        _layer(
            _sweep(190, 42, duration),
            _envelope(duration, attack=0.001, release=0.5),
            1.1,
        ),
        _layer(
            _tone(58),
            _envelope(duration, attack=0.001, release=0.52),
            0.6,
        ),
        _layer(
            _noise(73, smoothing=0.48),
            _envelope(0.13, attack=0.001, release=0.12),
            0.8,
        ),
    )


def _shield_charge() -> tuple[float, Signal]:
    duration = 0.62
    shimmer = _mix(
        _sweep(210, 890, 0.5),
        _layer(_sweep(540, 1_520, 0.52, phase=0.7), lambda _: 1, 0.35),
    )
    return duration, _mix(
        _layer(
            shimmer,
            _envelope(0.55, attack=0.03, release=0.16),
            0.8,
        ),
        _layer(
            _tone(1_760),
            _envelope(0.62, attack=0.30, release=0.25),
            0.22,
        ),
    )


def _shield_impact() -> tuple[float, Signal]:
    duration = 0.52
    return duration, _mix(
        _layer(
            _noise(411, smoothing=0.3),
            _envelope(0.085, attack=0.001, release=0.08),
            0.9,
        ),
        _layer(
            _sweep(620, 170, 0.30),
            _envelope(0.34, attack=0.001, release=0.30),
            0.85,
        ),
        _layer(
            _tone(1_080),
            _envelope(0.52, attack=0.003, release=0.48),
            0.34,
        ),
        _layer(
            _tone(1_620, phase=0.8),
            _envelope(0.46, attack=0.003, release=0.43),
            0.18,
        ),
    )


def _cool() -> tuple[float, Signal]:
    duration = 0.78
    return duration, _mix(
        _layer(
            _noise(2026, smoothing=0.72),
            _envelope(duration, attack=0.04, release=0.55),
            1.0,
        ),
        _layer(
            _sweep(1_100, 320, duration),
            _envelope(duration, attack=0.02, release=0.6),
            0.22,
        ),
    )


def _repair() -> tuple[float, Signal]:
    duration = 0.72
    notes: list[Signal] = []
    for index, frequency in enumerate((520, 660, 880, 1_040)):
        delay = 0.12 * index
        note = _layer(
            _tone(frequency),
            _envelope(0.20, attack=0.005, release=0.16),
            0.55,
        )
        notes.append(_delayed(note, delay))
    return duration, _mix(*notes)


def _recovered() -> tuple[float, Signal]:
    duration = 0.82
    return duration, _mix(
        _layer(
            _sweep(280, 760, 0.55),
            _envelope(0.62, attack=0.02, release=0.28),
            0.55,
        ),
        _delayed(
            _layer(
                _tone(1_040),
                _envelope(0.42, attack=0.01, release=0.38),
                0.45,
            ),
            0.30,
        ),
        _delayed(
            _layer(
                _tone(1_320),
                _envelope(0.32, attack=0.01, release=0.28),
                0.28,
            ),
            0.42,
        ),
    )


def _overheat() -> tuple[float, Signal]:
    duration = 0.88

    def alarm(time: float) -> float:
        frequency = 760 if int(time / 0.14) % 2 == 0 else 540
        gate = 1.0 if time % 0.14 < 0.095 else 0.0
        return math.sin(2 * math.pi * frequency * time) * gate

    return duration, _mix(
        _layer(
            alarm,
            _envelope(duration, attack=0.01, release=0.22),
            0.7,
        ),
        _layer(
            _noise(911, smoothing=0.62),
            _envelope(duration, attack=0.18, release=0.45),
            0.55,
        ),
    )


def _energy_starved() -> tuple[float, Signal]:
    duration = 0.58

    def chopped(time: float) -> float:
        gate = 1.0 if int(time / 0.055) % 2 == 0 else 0.18
        return _sweep(330, 72, duration)(time) * gate

    return duration, _layer(
        chopped,
        _envelope(duration, attack=0.004, release=0.30),
        1.0,
    )


def _core_damage() -> tuple[float, Signal]:
    duration = 0.64
    return duration, _mix(
        _layer(
            _sweep(120, 34, duration),
            _envelope(duration, attack=0.001, release=0.58),
            1.0,
        ),
        _layer(
            _noise(120, smoothing=0.58),
            _envelope(0.24, attack=0.001, release=0.22),
            0.82,
        ),
        _delayed(
            _layer(
                _tone(72),
                _envelope(0.40, attack=0.001, release=0.38),
                0.50,
            ),
            0.075,
        ),
    )


def _destroyed() -> tuple[float, Signal]:
    duration = 0.96
    debris = _mix(
        *(
        _delayed(
            _layer(
                _noise(31 + index, smoothing=0.15),
                _envelope(0.045, attack=0.001, release=0.04),
                0.35,
            ),
            0.12 + index * 0.085,
        )
        for index in range(6)
        )
    )
    return duration, _mix(
        _layer(
            _noise(404, smoothing=0.68),
            _envelope(duration, attack=0.001, release=0.82),
            1.0,
        ),
        _layer(
            _sweep(105, 26, duration),
            _envelope(duration, attack=0.001, release=0.90),
            0.9,
        ),
        debris,
    )


def _attack() -> tuple[float, Signal]:
    duration = 0.30
    return duration, _mix(
        _layer(
            _sweep(980, 210, duration),
            _envelope(duration, attack=0.002, release=0.24),
            0.8,
        ),
        _layer(
            _noise(88, smoothing=0.3),
            _envelope(0.06, attack=0.001, release=0.055),
            0.4,
        ),
    )


def _level_up() -> tuple[float, Signal]:
    duration = 1.16
    fanfare = _mix(
        _layer(
            _tone(523.25),
            _envelope(0.34, attack=0.008, release=0.24),
            0.52,
        ),
        _delayed(
            _layer(
                _tone(659.25),
                _envelope(0.34, attack=0.008, release=0.24),
                0.52,
            ),
            0.20,
        ),
        _delayed(
            _layer(
                _mix(
                    _tone(783.99),
                    _layer(_tone(1_046.50), lambda _: 1, 0.45),
                ),
                _envelope(0.62, attack=0.01, release=0.50),
                0.58,
            ),
            0.40,
        ),
    )
    applause = _layer(
        _noise(2_026, smoothing=0.18),
        _envelope(duration, attack=0.04, release=0.72, curve=1.2),
        0.16,
    )
    sparkle = _layer(
        _sweep(1_100, 3_200, duration, phase=0.25),
        _envelope(duration, attack=0.02, release=0.82),
        0.12,
    )
    return duration, _mix(fanfare, applause, sparkle)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    sounds = {
        "laser.wav": _laser(),
        "pulse_cannon.wav": _pulse_cannon(),
        "attack.wav": _attack(),
        "core_damage.wav": _core_damage(),
        "shield_charge.wav": _shield_charge(),
        "shield.wav": _shield_charge(),
        "shield_absorb.wav": _shield_impact(),
        "cool.wav": _cool(),
        "repair.wav": _repair(),
        "recovered.wav": _recovered(),
        "overheat.wav": _overheat(),
        "energy_starved.wav": _energy_starved(),
        "destroyed.wav": _destroyed(),
        "level_up.wav": _level_up(),
    }
    for name, (duration, signal) in sounds.items():
        _write(name, duration, signal)


if __name__ == "__main__":
    main()
