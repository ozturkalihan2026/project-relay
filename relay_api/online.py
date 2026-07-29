from __future__ import annotations

import hashlib
import json
import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import desc, select

from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement

from .bots import get_bot
from .config import Settings
from .database import Database
from .db_models import BoardRecord, MatchRecord, PlayerRecord
from .service import MatchService
from .store import OpponentSnapshot, StoredMatch


class OnlinePlayError(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        *,
        status_code: int,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


@dataclass(frozen=True, slots=True)
class SavedBoard:
    board_id: str
    player_id: str
    board: BoardLayout
    fingerprint: str
    updated_at: datetime


class OnlinePlayService:
    def __init__(
        self,
        database: Database,
        match_service: MatchService,
        settings: Settings,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
    ) -> None:
        self.database = database
        self.match_service = match_service
        self.settings = settings
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)

    def save_board(self, player_id: str, board: BoardLayout) -> SavedBoard:
        board.validate(self.match_service.engine.config.board_size)
        now = self.clock()
        board_payload = board.to_dict()
        fingerprint = hashlib.sha256(
            json.dumps(
                board_payload,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        with self.database.session() as session:
            if session.get(PlayerRecord, player_id) is None:
                raise OnlinePlayError(
                    "player_not_found",
                    "Oyuncu bulunamadı.",
                    status_code=404,
                )
            record = session.scalar(
                select(BoardRecord).where(
                    BoardRecord.player_id == player_id
                )
            )
            if record is None:
                record = BoardRecord(
                    id=self.id_source(),
                    player_id=player_id,
                    name=board.name,
                    modules=board_payload["modules"],
                    fingerprint=fingerprint,
                    module_count=len(board.modules),
                    created_at=now,
                    updated_at=now,
                    eligible=True,
                )
                session.add(record)
            else:
                record.name = board.name
                record.modules = board_payload["modules"]
                record.fingerprint = fingerprint
                record.module_count = len(board.modules)
                record.updated_at = now
                record.eligible = True
            session.flush()
            return self._saved_board(record)

    def get_board(self, player_id: str) -> SavedBoard | None:
        with self.database.session() as session:
            record = session.scalar(
                select(BoardRecord).where(
                    BoardRecord.player_id == player_id
                )
            )
            return self._saved_board(record) if record is not None else None

    def create_async_match(self, player_id: str) -> StoredMatch:
        player_board = self.get_board(player_id)
        if player_board is None:
            raise OnlinePlayError(
                "board_required",
                "Asenkron savaş için önce geçerli kartınızı kaydedin.",
                status_code=409,
            )
        opponent = self._select_opponent(
            player_id,
            module_count=len(player_board.board.modules),
        )
        if opponent is None:
            bot = get_bot("balanced")
            opponent_board = bot.board_for_count(
                len(player_board.board.modules)
            )
            snapshot = OpponentSnapshot(
                kind="bot",
                opponent_id=bot.bot_id,
                display_name=bot.display_name,
                description=(
                    "Uygun yeni oyuncu düzeni bulunamadığı için sunucu "
                    "yedek rakibi kullanıldı."
                ),
            )
            opponent_player_id = None
        else:
            record, player = opponent
            opponent_board = self._board_from_record(record)
            snapshot = OpponentSnapshot(
                kind="player",
                opponent_id=player.id,
                display_name=player.display_name,
                description="Kayıtlı gerçek oyuncu devresi.",
            )
            opponent_player_id = player.id
        return self.match_service.create_match(
            player_board=player_board.board,
            opponent_board=opponent_board,
            opponent=snapshot,
            source="async",
            requester_player_id=player_id,
            opponent_player_id=opponent_player_id,
        )

    def _select_opponent(
        self,
        player_id: str,
        *,
        module_count: int,
    ) -> tuple[BoardRecord, PlayerRecord] | None:
        with self.database.session() as session:
            recent_ids = list(
                session.scalars(
                    select(MatchRecord.opponent_player_id)
                    .where(
                        MatchRecord.requester_player_id == player_id,
                        MatchRecord.opponent_player_id.is_not(None),
                    )
                    .order_by(desc(MatchRecord.created_at))
                    .limit(self.settings.recent_opponent_limit)
                )
            )
            query = (
                select(BoardRecord, PlayerRecord)
                .join(
                    PlayerRecord,
                    PlayerRecord.id == BoardRecord.player_id,
                )
                .where(
                    BoardRecord.player_id != player_id,
                    BoardRecord.module_count == module_count,
                    BoardRecord.eligible.is_(True),
                )
                .order_by(BoardRecord.updated_at, BoardRecord.player_id)
            )
            if recent_ids:
                query = query.where(
                    BoardRecord.player_id.not_in(recent_ids)
                )
            return session.execute(query.limit(1)).first()

    @staticmethod
    def _saved_board(record: BoardRecord) -> SavedBoard:
        return SavedBoard(
            board_id=record.id,
            player_id=record.player_id,
            board=OnlinePlayService._board_from_record(record),
            fingerprint=record.fingerprint,
            updated_at=OnlinePlayService._as_utc(record.updated_at),
        )

    @staticmethod
    def _board_from_record(record: BoardRecord) -> BoardLayout:
        return BoardLayout(
            name=record.name,
            modules=tuple(
                ModulePlacement(
                    module_id=str(module["module_id"]),
                    kind=ModuleKind(str(module["kind"])),
                    row=int(module["row"]),
                    column=int(module["column"]),
                    orientation=Direction(
                        str(
                            module.get(
                                "orientation",
                                Direction.EAST.value,
                            )
                        )
                    ),
                    level=int(module.get("level", 1)),
                )
                for module in record.modules
            ),
        )

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)
