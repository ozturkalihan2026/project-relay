from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from threading import RLock
from typing import Any, Protocol

from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement

from .database import Database
from .db_models import MatchRecord


@dataclass(frozen=True, slots=True)
class OpponentSnapshot:
    kind: str
    opponent_id: str
    display_name: str
    description: str


@dataclass(frozen=True, slots=True)
class StoredMatch:
    match_id: str
    created_at: datetime
    source: str
    requester_player_id: str | None
    opponent_player_id: str | None
    opponent: OpponentSnapshot
    player_board: BoardLayout
    opponent_board: BoardLayout
    result: dict[str, Any]


class MatchNotFoundError(LookupError):
    def __init__(self, match_id: str) -> None:
        super().__init__(f"Maç bulunamadı: {match_id}")
        self.match_id = match_id


class MatchStore(Protocol):
    storage_name: str

    def save(self, match: StoredMatch) -> None: ...

    def get(self, match_id: str) -> StoredMatch: ...


class InMemoryMatchStore:
    storage_name = "memory"

    def __init__(self) -> None:
        self._matches: dict[str, StoredMatch] = {}
        self._lock = RLock()

    def save(self, match: StoredMatch) -> None:
        with self._lock:
            self._matches[match.match_id] = match

    def get(self, match_id: str) -> StoredMatch:
        with self._lock:
            try:
                return self._matches[match_id]
            except KeyError as exc:
                raise MatchNotFoundError(match_id) from exc


class DatabaseMatchStore:
    def __init__(self, database: Database) -> None:
        self.database = database
        self.storage_name = database.storage_name

    def save(self, match: StoredMatch) -> None:
        result = dict(match.result)
        events = list(result.pop("events", []))
        state_frames = list(result.pop("state_frames", []))
        with self.database.session() as session:
            session.add(
                MatchRecord(
                    id=match.match_id,
                    created_at=match.created_at,
                    source=match.source,
                    requester_player_id=match.requester_player_id,
                    opponent_player_id=match.opponent_player_id,
                    opponent_kind=match.opponent.kind,
                    opponent_id=match.opponent.opponent_id,
                    opponent_name=match.opponent.display_name,
                    opponent_description=match.opponent.description,
                    player_board=match.player_board.to_dict(),
                    opponent_board=match.opponent_board.to_dict(),
                    result=result,
                    replay={
                        "events": events,
                        "state_frames": state_frames,
                    },
                    replay_checksum=str(match.result["replay_checksum"]),
                    event_count=len(events),
                    seed=int(match.result["seed"]),
                    rules_version="0.7",
                )
            )

    def get(self, match_id: str) -> StoredMatch:
        with self.database.session() as session:
            record = session.get(MatchRecord, match_id)
            if record is None:
                raise MatchNotFoundError(match_id)
            result = dict(record.result)
            result["events"] = list(record.replay.get("events", []))
            result["state_frames"] = list(
                record.replay.get("state_frames", [])
            )
            return StoredMatch(
                match_id=record.id,
                created_at=self._as_utc(record.created_at),
                source=record.source,
                requester_player_id=record.requester_player_id,
                opponent_player_id=record.opponent_player_id,
                opponent=OpponentSnapshot(
                    kind=record.opponent_kind,
                    opponent_id=record.opponent_id,
                    display_name=record.opponent_name,
                    description=record.opponent_description,
                ),
                player_board=_board_from_dict(record.player_board),
                opponent_board=_board_from_dict(record.opponent_board),
                result=result,
            )

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)


def _board_from_dict(payload: dict[str, Any]) -> BoardLayout:
    return BoardLayout(
        name=str(payload["name"]),
        modules=tuple(
            ModulePlacement(
                module_id=str(module["module_id"]),
                kind=ModuleKind(str(module["kind"])),
                row=int(module["row"]),
                column=int(module["column"]),
                orientation=Direction(
                    str(module.get("orientation", Direction.EAST.value))
                ),
                level=int(module.get("level", 1)),
            )
            for module in payload["modules"]
        ),
    )
