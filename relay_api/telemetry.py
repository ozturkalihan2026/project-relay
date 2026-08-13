from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from .database import Database
from .db_models import ProductEventRecord


ALLOWED_PRODUCT_EVENTS = frozenset(
    {
        "mode_selected",
        "board_validated",
        "async_match_started",
        "career_run_started",
        "career_upgrade_selected",
        "sandbox_opened",
        "settings_changed",
    }
)


@dataclass(frozen=True, slots=True)
class ProductEventInput:
    event_id: str
    event_name: str
    context: dict[str, Any]
    client_version: str
    occurred_at: datetime


@dataclass(frozen=True, slots=True)
class TelemetryReceipt:
    accepted: int
    duplicates: int


class TelemetryError(Exception):
    def __init__(self, code: str, message: str, *, status_code: int = 422) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


class TelemetryService:
    def __init__(
        self,
        database: Database,
        *,
        clock=None,
    ) -> None:
        self.database = database
        self.clock = clock or (lambda: datetime.now(UTC))

    def record(
        self,
        player_id: str,
        events: list[ProductEventInput],
    ) -> TelemetryReceipt:
        accepted = 0
        duplicates = 0
        received_at = self.clock()
        seen_ids: set[str] = set()
        with self.database.session() as session:
            for event in events:
                if event.event_name not in ALLOWED_PRODUCT_EVENTS:
                    raise TelemetryError(
                        "telemetry_event_not_allowed",
                        "Bu telemetri olayı izin verilen ürün sözlüğünde yok.",
                    )
                context = _safe_context(event.context)
                if (
                    event.event_id in seen_ids
                    or session.get(ProductEventRecord, event.event_id) is not None
                ):
                    duplicates += 1
                    continue
                seen_ids.add(event.event_id)
                session.add(
                    ProductEventRecord(
                        id=event.event_id,
                        player_id=player_id,
                        event_name=event.event_name,
                        context=context,
                        client_version=event.client_version,
                        occurred_at=_as_utc(event.occurred_at),
                        received_at=received_at,
                    )
                )
                accepted += 1
        return TelemetryReceipt(accepted=accepted, duplicates=duplicates)


def _safe_context(context: dict[str, Any]) -> dict[str, Any]:
    if len(context) > 20:
        raise TelemetryError(
            "telemetry_context_too_large",
            "Telemetri bağlamı en fazla 20 alan içerebilir.",
        )
    safe: dict[str, Any] = {}
    for key, value in context.items():
        if not key or len(key) > 48:
            raise TelemetryError(
                "telemetry_context_key_invalid",
                "Telemetri bağlam anahtarı geçersiz.",
            )
        if isinstance(value, str):
            safe[key] = value[:120]
        elif value is None or isinstance(value, (bool, int, float)):
            safe[key] = value
        else:
            raise TelemetryError(
                "telemetry_context_value_invalid",
                "Telemetri bağlamı yalnızca basit değerler içerebilir.",
            )
    return safe


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
