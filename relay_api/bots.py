from __future__ import annotations

from dataclasses import dataclass

from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement


@dataclass(frozen=True, slots=True)
class BotDefinition:
    bot_id: str
    display_name: str
    difficulty: str
    description: str
    variants: tuple[BoardLayout, ...]

    @property
    def board(self) -> BoardLayout:
        """Return the complete six-module layout used by balance tests."""
        return self.variants[-1]

    @property
    def available_module_counts(self) -> tuple[int, ...]:
        return tuple(len(board.modules) for board in self.variants)

    def board_for_count(self, module_count: int) -> BoardLayout:
        for board in self.variants:
            if len(board.modules) == module_count:
                return board
        raise ValueError(
            f"{self.display_name} için {module_count} modüllük rakip düzeni "
            "bulunmuyor."
        )


def _module(
    module_id: str,
    kind: ModuleKind,
    row: int,
    column: int,
    orientation: Direction = Direction.EAST,
) -> ModulePlacement:
    return ModulePlacement(module_id, kind, row, column, orientation)


def _variants(
    name: str,
    modules: tuple[ModulePlacement, ...],
) -> tuple[BoardLayout, ...]:
    if len(modules) != 6:
        raise ValueError(f"{name} rakip şablonu tam altı modül içermelidir.")
    return tuple(
        BoardLayout(
            name=f"{name} • {module_count}M",
            modules=modules[:module_count],
        )
        for module_count in range(1, 7)
    )


BOTS: dict[str, BotDefinition] = {
    "starter_laser": BotDefinition(
        bot_id="starter_laser",
        display_name="Kıvılcım",
        difficulty="easy",
        description=(
            "Modül sayınıza göre ölçeklenen sade lazer ve destek devresi."
        ),
        variants=_variants(
            "Kıvılcım",
            (
                _module(
                    "BOT-SL-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-SL-LASER", ModuleKind.LASER, 0, 2),
                _module("BOT-SL-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-SL-SHIELD",
                    ModuleKind.SHIELD,
                    0,
                    3,
                    Direction.NORTH,
                ),
                _module(
                    "BOT-SL-COOL",
                    ModuleKind.COOLER,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-SL-REPAIR",
                    ModuleKind.REPAIR,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "battery_pulse": BotDefinition(
        bot_id="battery_pulse",
        display_name="Voltaj",
        difficulty="medium",
        description=(
            "Modül sayınıza göre Darbe Topu, batarya ve destek ekler."
        ),
        variants=_variants(
            "Voltaj",
            (
                _module(
                    "BOT-BP-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-BP-PULSE", ModuleKind.PULSE_CANNON, 0, 2),
                _module("BOT-BP-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-BP-COOL",
                    ModuleKind.COOLER,
                    0,
                    3,
                    Direction.NORTH,
                ),
                _module(
                    "BOT-BP-SHIELD",
                    ModuleKind.SHIELD,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-BP-REPAIR",
                    ModuleKind.REPAIR,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "balanced": BotDefinition(
        bot_id="balanced",
        display_name="Denge",
        difficulty="hard",
        description=(
            "Modül sayınıza göre saldırı, savunma ve soğutmayı dengeler."
        ),
        variants=_variants(
            "Denge",
            (
                _module(
                    "BOT-BA-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-BA-LASER", ModuleKind.LASER, 0, 2),
                _module("BOT-BA-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-BA-PULSE",
                    ModuleKind.PULSE_CANNON,
                    0,
                    3,
                    Direction.NORTH,
                ),
                _module(
                    "BOT-BA-SHIELD",
                    ModuleKind.SHIELD,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-BA-COOL",
                    ModuleKind.COOLER,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "laser_swarm": BotDefinition(
        bot_id="laser_swarm",
        display_name="Prizma",
        difficulty="hard",
        description=(
            "Modül sayınıza göre büyüyen lazer baskısı kalkan ağırlıklı "
            "devreleri sınar."
        ),
        variants=_variants(
            "Prizma",
            (
                _module(
                    "BOT-LS-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-LS-LASER-A", ModuleKind.LASER, 0, 2),
                _module("BOT-LS-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-LS-LASER-B",
                    ModuleKind.LASER,
                    0,
                    3,
                    Direction.NORTH,
                ),
                _module(
                    "BOT-LS-LASER-C",
                    ModuleKind.LASER,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-LS-SHIELD",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "pulse_volley": BotDefinition(
        bot_id="pulse_volley",
        display_name="Yankı",
        difficulty="hard",
        description=(
            "Modül sayınıza göre büyüyen Darbe Topu yaylımı lazer "
            "sürülerini sınar."
        ),
        variants=_variants(
            "Yankı",
            (
                _module(
                    "BOT-PV-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-PV-PULSE-A", ModuleKind.PULSE_CANNON, 0, 2),
                _module("BOT-PV-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-PV-PULSE-B",
                    ModuleKind.PULSE_CANNON,
                    0,
                    3,
                    Direction.NORTH,
                ),
                _module(
                    "BOT-PV-PULSE-C",
                    ModuleKind.PULSE_CANNON,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-PV-SHIELD",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "shield_wall": BotDefinition(
        bot_id="shield_wall",
        display_name="Hisar",
        difficulty="hard",
        description=(
            "İki Kalkan ve iki Darbe Topuyla yüksek ön hasara karşılık "
            "verir."
        ),
        variants=_variants(
            "Hisar",
            (
                _module(
                    "BOT-SW-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-SW-PULSE", ModuleKind.PULSE_CANNON, 0, 2),
                _module("BOT-SW-BAT", ModuleKind.BATTERY, 0, 0),
                _module(
                    "BOT-SW-SHIELD-A",
                    ModuleKind.SHIELD,
                    1,
                    3,
                ),
                _module(
                    "BOT-SW-SHIELD-B",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-SW-PULSE-B",
                    ModuleKind.PULSE_CANNON,
                    2,
                    0,
                    Direction.WEST,
                ),
            ),
        ),
    ),
    "fortress": BotDefinition(
        bot_id="fortress",
        display_name="Siper",
        difficulty="expert",
        description=(
            "Üç Kalkanlı savunma hattı, dört Darbe Toplu yığınları sınar."
        ),
        variants=_variants(
            "Siper",
            (
                _module(
                    "BOT-FT-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-FT-PULSE", ModuleKind.PULSE_CANNON, 0, 2),
                _module("BOT-FT-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-FT-SHIELD-A",
                    ModuleKind.SHIELD,
                    0,
                    0,
                    Direction.WEST,
                ),
                _module(
                    "BOT-FT-SHIELD-B",
                    ModuleKind.SHIELD,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-FT-SHIELD-C",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "repair_guard": BotDefinition(
        bot_id="repair_guard",
        display_name="Anka",
        difficulty="medium",
        description=(
            "Modül sayınıza göre lazerini onarım, kalkan ve soğutmayla "
            "destekler."
        ),
        variants=_variants(
            "Anka",
            (
                _module(
                    "BOT-RG-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module("BOT-RG-LASER", ModuleKind.LASER, 0, 2),
                _module("BOT-RG-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-RG-REPAIR",
                    ModuleKind.REPAIR,
                    0,
                    3,
                    Direction.NORTH,
                ),
                _module(
                    "BOT-RG-SHIELD",
                    ModuleKind.SHIELD,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-RG-COOL",
                    ModuleKind.COOLER,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
    "amplified_pulse": BotDefinition(
        bot_id="amplified_pulse",
        display_name="Aşırı Akım",
        difficulty="expert",
        description=(
            "Modül sayınıza göre güçlendirilmiş Darbe Topu ve savunma "
            "desteği kurar."
        ),
        variants=_variants(
            "Aşırı Akım",
            (
                _module(
                    "BOT-AP-GEN",
                    ModuleKind.GENERATOR,
                    0,
                    1,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-AP-LASER",
                    ModuleKind.LASER,
                    0,
                    2,
                ),
                _module("BOT-AP-BAT", ModuleKind.BATTERY, 1, 3),
                _module(
                    "BOT-AP-AMP",
                    ModuleKind.AMPLIFIER,
                    2,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-AP-PULSE",
                    ModuleKind.PULSE_CANNON,
                    3,
                    3,
                    Direction.SOUTH,
                ),
                _module(
                    "BOT-AP-SHIELD",
                    ModuleKind.SHIELD,
                    3,
                    2,
                    Direction.SOUTH,
                ),
            ),
        ),
    ),
}


def get_bot(bot_id: str) -> BotDefinition:
    try:
        return BOTS[bot_id]
    except KeyError as exc:
        raise BotNotFoundError(bot_id) from exc


class BotNotFoundError(LookupError):
    def __init__(self, bot_id: str) -> None:
        super().__init__(f"Bot bulunamadı: {bot_id}")
        self.bot_id = bot_id
