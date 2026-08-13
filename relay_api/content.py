from __future__ import annotations

import json
from dataclasses import dataclass
from importlib.resources import files
from typing import Any


@dataclass(frozen=True, slots=True)
class CareerStageDefinition:
    stage_number: int
    bot_id: str
    title: str
    briefing: str
    guidance_title: str
    guidance_text: str
    icon: str
    is_boss: bool = False


@dataclass(frozen=True, slots=True)
class CareerSectorDefinition:
    sector_id: str
    number: int
    title: str
    stages: tuple[CareerStageDefinition, ...]


def load_career_sectors(
    payload: dict[str, Any],
) -> tuple[CareerSectorDefinition, ...]:
    if payload.get("schema_version") != 1:
        raise RuntimeError("Desteklenmeyen kariyer içerik şeması.")
    raw_sectors = payload.get("sectors")
    if not isinstance(raw_sectors, list) or not raw_sectors:
        raise RuntimeError("Kariyer içeriğinde en az bir sektör bulunmalıdır.")

    sectors: list[CareerSectorDefinition] = []
    seen_ids: set[str] = set()
    seen_numbers: set[int] = set()
    for raw_sector in raw_sectors:
        if not isinstance(raw_sector, dict):
            raise RuntimeError("Her sektör girdisi bir nesne olmalıdır.")
        sector_id = _text(raw_sector, "sector_id")
        title = _text(raw_sector, "title")
        number = _positive_int(raw_sector.get("number"), "number")
        if sector_id in seen_ids or number in seen_numbers:
            raise RuntimeError("Sektör kimliği ve numarası benzersiz olmalıdır.")
        seen_ids.add(sector_id)
        seen_numbers.add(number)
        raw_stages = raw_sector.get("stages")
        if not isinstance(raw_stages, list) or not raw_stages:
            raise RuntimeError(f"{sector_id} sektörü aşama içermelidir.")
        stages = tuple(
            _stage(raw_stage, expected=index + 1)
            for index, raw_stage in enumerate(raw_stages)
        )
        bosses = [stage for stage in stages if stage.is_boss]
        if len(bosses) != 1 or not stages[-1].is_boss:
            raise RuntimeError(
                f"{sector_id} sektörü son aşamada tam bir boss içermelidir."
            )
        sectors.append(
            CareerSectorDefinition(
                sector_id=sector_id,
                number=number,
                title=title,
                stages=stages,
            )
        )
    return tuple(sorted(sectors, key=lambda sector: sector.number))


def _stage(raw: Any, *, expected: int) -> CareerStageDefinition:
    if not isinstance(raw, dict):
        raise RuntimeError("Her kariyer aşaması bir nesne olmalıdır.")
    stage_number = _positive_int(raw.get("stage_number"), "stage_number")
    if stage_number != expected:
        raise RuntimeError("Kariyer aşamaları 1'den başlayan kesintisiz sırada olmalıdır.")
    return CareerStageDefinition(
        stage_number=stage_number,
        bot_id=_text(raw, "bot_id"),
        title=_text(raw, "title"),
        briefing=_text(raw, "briefing"),
        guidance_title=_text(raw, "guidance_title"),
        guidance_text=_text(raw, "guidance_text"),
        icon=_text(raw, "icon"),
        is_boss=bool(raw.get("is_boss", False)),
    )


def _text(payload: dict[str, Any], field: str) -> str:
    value = payload.get(field)
    if not isinstance(value, str) or not value.strip():
        raise RuntimeError(f"{field} boş olmayan metin olmalıdır.")
    return value.strip()


def _positive_int(value: Any, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise RuntimeError(f"{field} pozitif tam sayı olmalıdır.")
    return value


def _load_bundled_sectors() -> tuple[CareerSectorDefinition, ...]:
    resource = files("relay_content").joinpath("sectors.json")
    payload = json.loads(resource.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise RuntimeError("Kariyer içerik kökü bir nesne olmalıdır.")
    return load_career_sectors(payload)


CAREER_SECTORS = _load_bundled_sectors()
DEFAULT_CAREER_SECTOR = CAREER_SECTORS[0]
