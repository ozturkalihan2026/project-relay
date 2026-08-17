"""Cevrimiçi canlı savaş oturumları.

Asenkron PvP yerine, oyuncular savaş boyunca modül değiştirebilir.
Motor tarafı aynı LiveBattleSession kullanılır; fark rakip seçimi ve
veri tabanı tablosudur.
"""

from __future__ import annotations

import hashlib
import uuid
from collections import Counter
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import desc, select

from relay_engine import (
    BattleModifiers,
    BattleEvent,
    BoardLayout,
    Direction,
    InterventionError,
    InterventionWindowState,
    LiveBattleSession,
    ModuleKind,
    ModulePlacement,
    ReplayStateFrame,
    ReserveModule,
    Side,
)

from .collection import CollectionService
from .database import Database
from .db_models import OnlineBattleSessionRecord
from .online import OnlinePlayService
from .service import MatchService
from .store import MatchNotFoundError, OpponentSnapshot, StoredMatch
from .weekly_protocol import weekly_protocol


@dataclass(frozen=True, slots=True)
class OnlineBattleSessionSnapshot:
    session_id: str
    player_id: str
    status: str
    tick: int
    complete: bool
    player_board: BoardLayout
    opponent_board: BoardLayout
    frame: ReplayStateFrame
    intervention: InterventionWindowState
    reserves: tuple[ReserveModule, ...]
    events: tuple[BattleEvent, ...]
    opponent_name: str
    opponent_description: str
    match: StoredMatch | None


class OnlineLiveBattleError(Exception):
    def __init__(
        self,
        code: str,
        message: str,
        *,
        status_code: int = 409,
    ) -> None:
        super().__init__(message)
        self.code = code
        self.message = message
        self.status_code = status_code


class OnlineLiveBattleService:
    def __init__(
        self,
        database: Database,
        match_service: MatchService,
        online_service: OnlinePlayService,
        collection_service: CollectionService | None = None,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
    ) -> None:
        self.database = database
        self.match_service = match_service
        self.online_service = online_service
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)
        self.collection_service = collection_service or CollectionService(
            database,
            clock=self.clock,
        )

    def start_session(self, player_id: str) -> OnlineBattleSessionSnapshot:
        now = self.clock()
        with self.database.session() as session:
            active = session.scalar(
                select(OnlineBattleSessionRecord).where(
                    OnlineBattleSessionRecord.player_id == player_id,
                    OnlineBattleSessionRecord.status.in_(
                        ("active", "resolving")
                    ),
                )
                .order_by(desc(OnlineBattleSessionRecord.created_at))
                .limit(1)
            )
            if active is not None:
                record_id = active.id
                record_status = active.status
            else:
                player_board = self.online_service.get_board(player_id)
                if player_board is None:
                    raise OnlineLiveBattleError(
                        "board_required",
                        "Canlı savaş için önce geçerli kartınızı kaydedin.",
                        status_code=409,
                    )
                opponent = self.online_service._select_opponent(
                    player_id,
                    module_count=len(player_board.board.modules),
                )
                if opponent is None:
                    from .bots import get_bot

                    bot = get_bot("balanced")
                    opponent_board = bot.board_for_count(
                        len(player_board.board.modules)
                    )
                    snapshot_opponent = OpponentSnapshot(
                        kind="bot",
                        opponent_id=bot.bot_id,
                        display_name=bot.display_name,
                        description=(
                            "Uygun yeni oyuncu düzeni bulunamadığı için "
                            "sunucu yedek rakibi kullanıldı."
                        ),
                    )
                    opponent_player_id = None
                else:
                    board_record, player = opponent
                    opponent_board = OnlinePlayService._board_from_record(
                        board_record,
                    )
                    snapshot_opponent = OpponentSnapshot(
                        kind="player",
                        opponent_id=player.id,
                        display_name=player.display_name,
                        description="Kayıtlı gerçek oyuncu devresi.",
                    )
                    opponent_player_id = player.id

                protocol = weekly_protocol(self.clock())
                reserves = self._online_reserves(
                    player_id,
                    player_board.board,
                )
                record = OnlineBattleSessionRecord(
                    id=self.id_source(),
                    player_id=player_id,
                    opponent_player_id=opponent_player_id,
                    opponent_kind=snapshot_opponent.kind,
                    opponent_id=snapshot_opponent.opponent_id,
                    opponent_name=snapshot_opponent.display_name,
                    opponent_description=snapshot_opponent.description,
                    status="active",
                    seed=self.match_service.seed_source(),
                    player_board=player_board.board.to_dict(),
                    opponent_board=opponent_board.to_dict(),
                    player_modifiers=protocol.definition.modifiers.to_dict(),
                    opponent_modifiers=BattleModifiers().to_dict(),
                    player_reserves=[item.to_dict() for item in reserves],
                    commands=[],
                    current_tick=0,
                    weekly_protocol_key=protocol.key,
                    final_match_id=None,
                    created_at=now,
                    updated_at=now,
                    completed_at=None,
                )
                session.add(record)
                session.flush()
                record_id = record.id
                record_status = record.status

        if record_status in {"completed", "resolving"}:
            return self._finalize_session(player_id, record_id)
        return self._build_snapshot(player_id, record_id)

    def current_session(
        self,
        player_id: str,
    ) -> OnlineBattleSessionSnapshot:
        with self.database.session() as session:
            record = self._latest_record(session, player_id, lock=False)
        if record.status in {"completed", "resolving"}:
            return self._finalize_session(player_id, record.id)
        battle = self._rebuild_session(record)
        if battle.complete:
            return self._finalize_session(player_id, record.id)
        return self._snapshot_from_battle(player_id, record, battle)

    def advance_session(
        self,
        player_id: str,
        *,
        ticks: int = 1,
    ) -> OnlineBattleSessionSnapshot:
        if not 1 <= ticks <= 12:
            raise OnlineLiveBattleError(
                "advance_ticks_invalid",
                "Canlı savaş tek istekte 1 ile 12 adım ilerletilebilir.",
                status_code=422,
            )
        now = self.clock()
        with self.database.session() as session:
            record = self._latest_record(session, player_id, lock=True)
            if record.status == "completed":
                complete = True
            elif record.status != "active":
                raise OnlineLiveBattleError(
                    "battle_session_not_active",
                    "Canlı savaş oturumu etkin değil.",
                )
            else:
                battle = self._rebuild_session(record)
                battle.advance_to(battle.tick + ticks)
                record.current_tick = battle.tick
                record.updated_at = now
                complete = battle.complete
                if complete:
                    record.status = "resolving"
                session.flush()

        if complete:
            return self._finalize_session(player_id, record.id)
        return self._build_snapshot(player_id, record.id)

    def swap_module(
        self,
        player_id: str,
        *,
        outgoing_id: str,
        incoming_id: str,
        orientation: Direction | None = None,
    ) -> OnlineBattleSessionSnapshot:
        now = self.clock()
        with self.database.session() as session:
            record = self._latest_record(session, player_id, lock=True)
            if record.status != "active":
                raise OnlineLiveBattleError(
                    "battle_session_not_active",
                    "Tamamlanmış savaşta modül değiştirilemez.",
                )
            battle = self._rebuild_session(record)
            try:
                battle.queue_swap(
                    side=Side.LEFT,
                    outgoing_id=outgoing_id,
                    incoming_id=incoming_id,
                    orientation=orientation,
                )
            except InterventionError as error:
                raise OnlineLiveBattleError(
                    error.code, str(error)
                ) from error
            commands = list(record.commands or [])
            commands.append(
                {
                    "tick": battle.tick,
                    "outgoing_id": outgoing_id,
                    "incoming_id": incoming_id,
                    "orientation": (
                        orientation.value if orientation is not None else None
                    ),
                }
            )
            record.commands = commands
            record.updated_at = now
            session.flush()
        return self._build_snapshot(player_id, record.id)

    def _online_reserves(
        self,
        player_id: str,
        board: BoardLayout,
    ) -> tuple[ReserveModule, ...]:
        kit = self.collection_service.snapshot(player_id).kits["online"]
        used = Counter(module.kind for module in board.modules)
        reserves: list[ReserveModule] = []
        for slot, kind in enumerate(kit.module_kinds, start=1):
            if used[kind] > 0:
                used[kind] -= 1
                continue
            reserves.append(
                ReserveModule(
                    module_id=f"online-reserve-{slot}-{kind.value}",
                    kind=kind,
                    level=1,
                )
            )
        return tuple(reserves)

    def _latest_record(
        self,
        session,
        player_id: str,
        *,
        lock: bool,
    ) -> OnlineBattleSessionRecord:
        query = (
            select(OnlineBattleSessionRecord)
            .where(OnlineBattleSessionRecord.player_id == player_id)
            .order_by(desc(OnlineBattleSessionRecord.created_at))
            .limit(1)
        )
        if lock:
            query = query.with_for_update()
        record = session.scalar(query)
        if record is None:
            raise OnlineLiveBattleError(
                "battle_session_not_found",
                "Canlı savaş bulunamadı.",
                status_code=404,
            )
        return record

    def _rebuild_session(
        self,
        record: OnlineBattleSessionRecord,
    ) -> LiveBattleSession:
        battle = self.match_service.engine.start_live_session(
            self._board_from_payload(record.player_board),
            self._board_from_payload(record.opponent_board),
            seed=record.seed,
            left_modifiers=self._modifiers_from_payload(
                record.player_modifiers
            ),
            right_modifiers=self._modifiers_from_payload(
                record.opponent_modifiers
            ),
            left_reserves=tuple(
                ReserveModule(
                    module_id=str(item["module_id"]),
                    kind=ModuleKind(str(item["kind"])),
                    level=int(item.get("level", 1)),
                )
                for item in list(record.player_reserves or [])
            ),
            overload=False,
            max_ticks=self.match_service.engine.config.live_max_ticks,
        )
        for command in list(record.commands or []):
            command_tick = int(command["tick"])
            if command_tick > record.current_tick:
                raise OnlineLiveBattleError(
                    "battle_session_corrupt",
                    "Canlı savaş komutu kayıtlı adımdan ileride.",
                    status_code=500,
                )
            battle.advance_to(command_tick)
            orientation_value = command.get("orientation")
            try:
                battle.queue_swap(
                    side=Side.LEFT,
                    outgoing_id=str(command["outgoing_id"]),
                    incoming_id=str(command["incoming_id"]),
                    orientation=(
                        Direction(str(orientation_value))
                        if orientation_value is not None
                        else None
                    ),
                )
            except (InterventionError, ValueError) as error:
                raise OnlineLiveBattleError(
                    "battle_session_corrupt",
                    f"Canlı savaş komutu yeniden kurulamadı: {error}",
                    status_code=500,
                ) from error
        battle.advance_to(record.current_tick)
        return battle

    def _snapshot_from_battle(
        self,
        player_id: str,
        record: OnlineBattleSessionRecord,
        battle: LiveBattleSession,
        match: StoredMatch | None = None,
    ) -> OnlineBattleSessionSnapshot:
        intervention = battle.intervention_state(Side.LEFT)
        module_catalog = {
            item.module_id: ReserveModule(
                module_id=item.module_id,
                kind=item.kind,
                level=item.level,
            )
            for item in self._board_from_payload(record.player_board).modules
        }
        module_catalog.update(
            {
                str(item["module_id"]): ReserveModule(
                    module_id=str(item["module_id"]),
                    kind=ModuleKind(str(item["kind"])),
                    level=int(item.get("level", 1)),
                )
                for item in list(record.player_reserves or [])
            }
        )
        reserves = tuple(
            module_catalog[module_id]
            for module_id in intervention.reserve_module_ids
            if module_id in module_catalog
        )
        return OnlineBattleSessionSnapshot(
            session_id=record.id,
            player_id=record.player_id,
            status=record.status,
            tick=battle.tick,
            complete=battle.complete,
            player_board=battle.layout(Side.LEFT),
            opponent_board=battle.layout(Side.RIGHT),
            frame=battle.snapshot().frame,
            intervention=intervention,
            reserves=reserves,
            events=battle.events,
            opponent_name=record.opponent_name,
            opponent_description=record.opponent_description,
            match=match,
        )

    def _build_snapshot(
        self,
        player_id: str,
        record_id: str,
    ) -> OnlineBattleSessionSnapshot:
        with self.database.session() as session:
            record = session.get(OnlineBattleSessionRecord, record_id)
            if record is None or record.player_id != player_id:
                raise OnlineLiveBattleError(
                    "battle_session_not_found",
                    "Canlı savaş bulunamadı.",
                    status_code=404,
                )
        battle = self._rebuild_session(record)
        return self._snapshot_from_battle(player_id, record, battle)

    def _finalize_session(
        self,
        player_id: str,
        record_id: str,
    ) -> OnlineBattleSessionSnapshot:
        with self.database.session() as session:
            record = session.get(OnlineBattleSessionRecord, record_id)
            if record is None or record.player_id != player_id:
                raise OnlineLiveBattleError(
                    "battle_session_not_found",
                    "Canlı savaş bulunamadı.",
                    status_code=404,
                )
        battle = self._rebuild_session(record)
        if not battle.complete:
            raise OnlineLiveBattleError(
                "battle_in_progress",
                "Savaş sonucu oturum tamamlanmadan üretilemez.",
            )

        match_id = hashlib.sha256(
            f"online-live:{record.id}".encode("utf-8")
        ).hexdigest()[:32]
        try:
            match = self.match_service.get_match(match_id)
        except MatchNotFoundError:
            match = StoredMatch(
                match_id=match_id,
                created_at=self._as_utc(record.created_at),
                source="online_live",
                requester_player_id=player_id,
                opponent_player_id=record.opponent_player_id,
                opponent=OpponentSnapshot(
                    kind=record.opponent_kind,
                    opponent_id=record.opponent_id,
                    display_name=record.opponent_name,
                    description=record.opponent_description,
                ),
                player_board=self._board_from_payload(record.player_board),
                opponent_board=self._board_from_payload(record.opponent_board),
                result=battle.result().to_dict(include_events=True),
                player_modifiers=dict(record.player_modifiers or {}),
                opponent_modifiers=dict(record.opponent_modifiers or {}),
                weekly_protocol_key=record.weekly_protocol_key,
            )
            self.match_service.store.save(match)

        now = self.clock()
        with self.database.session() as session:
            record = session.scalar(
                select(OnlineBattleSessionRecord)
                .where(
                    OnlineBattleSessionRecord.id == record_id,
                    OnlineBattleSessionRecord.player_id == player_id,
                )
                .with_for_update()
            )
            if record is None:
                raise OnlineLiveBattleError(
                    "battle_session_not_found",
                    "Canlı savaş bulunamadı.",
                    status_code=404,
                )
            if record.final_match_id is None:
                record.final_match_id = match.match_id
            record.status = "completed"
            record.current_tick = battle.tick
            record.updated_at = now
            record.completed_at = record.completed_at or now
            session.flush()

        return self._snapshot_from_battle(
            player_id, record, battle, match
        )

    @staticmethod
    def _board_from_payload(payload: dict[str, object]) -> BoardLayout:
        return BoardLayout(
            name=str(payload["name"]),
            modules=tuple(
                ModulePlacement(
                    module_id=str(item["module_id"]),
                    kind=ModuleKind(str(item["kind"])),
                    row=int(item["row"]),
                    column=int(item["column"]),
                    orientation=Direction(
                        str(item.get("orientation", Direction.EAST.value))
                    ),
                    level=int(item.get("level", 1)),
                )
                for item in list(payload["modules"])
            ),
        )

    @staticmethod
    def _modifiers_from_payload(
        payload: dict[str, object],
    ) -> BattleModifiers:
        return BattleModifiers(
            generator_output_multiplier=float(
                payload.get("generator_output_multiplier", 1.0)
            ),
            initial_shield=float(payload.get("initial_shield", 0.0)),
            module_hp_bonus=float(payload.get("module_hp_bonus", 0.0)),
            initial_energy_reserve=float(
                payload.get("initial_energy_reserve", 0.0)
            ),
            reserve_capacity_bonus=float(
                payload.get("reserve_capacity_bonus", 0.0)
            ),
            efficient_module_ids=tuple(
                str(item)
                for item in list(payload.get("efficient_module_ids", []))
            ),
            focused_amplifier_ids=tuple(
                str(item)
                for item in list(
                    payload.get("focused_amplifier_ids", [])
                )
            ),
        )

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)
