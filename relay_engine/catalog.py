from __future__ import annotations

from dataclasses import dataclass

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
BACK_PORT = frozenset({Direction.WEST})
RELAY_PORTS = frozenset({Direction.WEST, Direction.EAST})
GENERATOR_PORTS = frozenset(
    {
        Direction.NORTH,
        Direction.EAST,
        Direction.SOUTH,
    }
)


MODULE_SPECS: dict[ModuleKind, ModuleSpec] = {
    ModuleKind.GENERATOR: ModuleSpec(
        kind=ModuleKind.GENERATOR,
        display_name="Jeneratör",
        description=(
            "Çekirdek kapısında içe dönük çalışır; bir portuyla pasif "
            "çekirdeği, iki portuyla halkanın iki yönünü besler."
        ),
        max_hp=52,
        ports=GENERATOR_PORTS,
        energy_output=8,
        threat=60,
    ),
    ModuleKind.BATTERY: ModuleSpec(
        kind=ModuleKind.BATTERY,
        display_name="Batarya",
        description=(
            "Enerjiyi depolar ve dört yöne aktarır; dallanan devrelerde "
            "rezerv ve kavşak görevi görür."
        ),
        max_hp=38,
        ports=ALL_PORTS,
        battery_capacity=20,
        threat=40,
    ),
    ModuleKind.LASER: ModuleSpec(
        kind=ModuleKind.LASER,
        display_name="Lazer",
        description=(
            "Az enerjiyle sık ateş eder; arka portu enerji hattına dönük "
            "olmalıdır."
        ),
        max_hp=27,
        ports=BACK_PORT,
        energy_cost=4,
        cooldown_ticks=2,
        heat_per_action=14,
        damage=8,
        threat=100,
    ),
    ModuleKind.PULSE_CANNON: ModuleSpec(
        kind=ModuleKind.PULSE_CANNON,
        display_name="Darbe Topu",
        description=(
            "Yüksek anlık hasar verir fakat çok enerji ve ısı üretir; "
            "batarya ve soğutmayla güçlenir."
        ),
        max_hp=33,
        ports=BACK_PORT,
        energy_cost=8,
        cooldown_ticks=4,
        heat_per_action=30,
        damage=16,
        threat=110,
    ),
    ModuleKind.SHIELD: ModuleSpec(
        kind=ModuleKind.SHIELD,
        display_name="Kalkan",
        description=(
            "Gelen hasarı karşılayan ortak kalkan havuzunu doldurur ve "
            "silahlardan önce hedef çekerek onları korur; tek portlu olduğu "
            "için hattın ucuna yerleşir."
        ),
        max_hp=35,
        ports=BACK_PORT,
        energy_cost=5,
        cooldown_ticks=3,
        heat_per_action=11,
        shield=14,
        threat=120,
    ),
    ModuleKind.COOLER: ModuleSpec(
        kind=ModuleKind.COOLER,
        display_name="Soğutucu",
        description=(
            "Bağlı devredeki ısıyı düşürür ve saldırı modüllerinin daha "
            "uzun süre çalışmasını sağlar."
        ),
        max_hp=31,
        ports=BACK_PORT,
        energy_cost=3,
        cooldown_ticks=2,
        heat_per_action=5,
        cooling=12,
        threat=75,
    ),
    ModuleKind.AMPLIFIER: ModuleSpec(
        kind=ModuleKind.AMPLIFIER,
        display_name="Güçlendirici",
        description=(
            "Enerjiyi düz hat üzerinde aktarır ve önündeki modülün etkisini "
            "artırır; yönü stratejinin parçasıdır."
        ),
        max_hp=25,
        ports=RELAY_PORTS,
        threat=90,
    ),
    ModuleKind.REPAIR: ModuleSpec(
        kind=ModuleKind.REPAIR,
        display_name="Onarım",
        description=(
            "Hasar görmüş enerjili modülü onarır; uzun savaşlarda savunma "
            "düzeninin dayanıklılığını artırır."
        ),
        max_hp=30,
        ports=BACK_PORT,
        energy_cost=5,
        cooldown_ticks=4,
        heat_per_action=14,
        repair=11,
        threat=80,
    ),
}


def get_spec(kind: ModuleKind) -> ModuleSpec:
    return MODULE_SPECS[kind]


def world_ports(kind: ModuleKind, orientation: Direction) -> frozenset[Direction]:
    spec = get_spec(kind)
    if spec.ports == ALL_PORTS:
        return ALL_PORTS
    return frozenset(orientation.rotate_from_east(port) for port in spec.ports)
