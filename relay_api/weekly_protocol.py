from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from relay_engine import BattleModifiers


@dataclass(frozen=True, slots=True)
class WeeklyProtocolDefinition:
    protocol_id: str
    title: str
    description: str
    effect_label: str
    modifiers: BattleModifiers


@dataclass(frozen=True, slots=True)
class WeeklyProtocol:
    key: str
    definition: WeeklyProtocolDefinition
    starts_at: datetime
    ends_at: datetime


PROTOCOLS: tuple[WeeklyProtocolDefinition, ...] = (
    WeeklyProtocolDefinition(
        protocol_id="reserve_pulse",
        title="Rezerv Darbesi",
        description=(
            "Her iki devre de savaşa ek enerji rezerviyle başlar; yüksek "
            "maliyetli saldırılar daha erken devreye girebilir."
        ),
        effect_label="İki taraf için başlangıç rezervi +6",
        modifiers=BattleModifiers(
            initial_energy_reserve=6.0,
            reserve_capacity_bonus=6.0,
        ),
    ),
    WeeklyProtocolDefinition(
        protocol_id="steady_current",
        title="Kararlı Akım",
        description=(
            "Jeneratör çıkışı iki taraf için eşit oranda yükselir; enerji "
            "dağıtım sırası daha belirleyici olur."
        ),
        effect_label="İki taraf için jeneratör üretimi +%8",
        modifiers=BattleModifiers(generator_output_multiplier=1.08),
    ),
    WeeklyProtocolDefinition(
        protocol_id="shield_boot",
        title="Kalkan Önyüklemesi",
        description=(
            "Devre çekirdekleri kısa bir koruma katmanıyla başlar; ilk saldırı "
            "dalgasının zamanlaması değişir."
        ),
        effect_label="İki taraf için başlangıç kalkanı +8",
        modifiers=BattleModifiers(initial_shield=8.0),
    ),
    WeeklyProtocolDefinition(
        protocol_id="reinforced_grid",
        title="Güçlendirilmiş Izgara",
        description=(
            "Tüm modüller iki tarafta da daha dayanıklıdır; hedef önceliği ve "
            "onarım değeri öne çıkar."
        ),
        effect_label="İki taraf için modül canı +4",
        modifiers=BattleModifiers(module_hp_bonus=4.0),
    ),
)


def weekly_protocol(moment: datetime) -> WeeklyProtocol:
    normalized = _as_utc(moment)
    starts_at = (normalized - timedelta(days=normalized.weekday())).replace(
        hour=0,
        minute=0,
        second=0,
        microsecond=0,
    )
    ends_at = starts_at + timedelta(days=7)
    iso_year, iso_week, _ = normalized.isocalendar()
    definition = PROTOCOLS[(iso_week - 1) % len(PROTOCOLS)]
    return WeeklyProtocol(
        key=f"{iso_year}-W{iso_week:02d}:{definition.protocol_id}",
        definition=definition,
        starts_at=starts_at,
        ends_at=ends_at,
    )


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
