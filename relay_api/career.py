from __future__ import annotations

import hashlib
import json
import uuid
from collections import Counter
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import desc, select

from relay_engine import BattleModifiers, BoardLayout

from .bots import get_bot
from .database import Database
from .db_models import (
    CareerBoardRecord,
    CareerRunRecord,
    PlayerProgressionRecord,
    PlayerRecord,
)
from .online import OnlinePlayService, SavedBoard
from .progression import (
    BoosterMastery,
    ProgressionService,
    RewardGrant,
)
from .service import MatchService
from .store import OpponentSnapshot, StoredMatch

TOTAL_STAGES = 5
_ACTIVE_STATUSES = {"active", "awaiting_booster"}
_TERMINAL_STATUSES = {"completed", "failed", "abandoned"}


@dataclass(frozen=True, slots=True)
class CareerStageDefinition:
    stage_number: int
    bot_id: str
    title: str
    briefing: str
    is_boss: bool = False


CAREER_STAGES: tuple[CareerStageDefinition, ...] = (
    CareerStageDefinition(
        1,
        "starter_laser",
        "İlk Temas",
        "Lazer hattını okuyup temel karşı devreyi kur.",
    ),
    CareerStageDefinition(
        2,
        "battery_pulse",
        "Rezerv Darbesi",
        "Batarya destekli ağır saldırıya karşı enerji ve savunmayı dengele.",
    ),
    CareerStageDefinition(
        3,
        "shield_wall",
        "Kalkan Duvarı",
        "Yüksek emilimli savunmayı sürdürülebilir hasarla aş.",
    ),
    CareerStageDefinition(
        4,
        "repair_guard",
        "Onarım Muhafızı",
        "Uzayan savaşta onarım zincirini bozacak hedef düzenini kur.",
    ),
    CareerStageDefinition(
        5,
        "amplified_pulse",
        "Bölüm Sonu: Aşırı Akım",
        "Güçlendirilmiş Darbe Topu çekirdeğini analiz edip son devreni hazırla.",
        is_boss=True,
    ),
)

# Güçlendirici mağazası yalnız dördüncü zaferden sonra, boss öncesinde açılır.
_BOSS_BOOSTER_OFFERS: tuple[str, str, str] = (
    "overcharge",
    "reinforced_shield",
    "reserve_cell",
)
_SKIP_BOOSTER_ID = "none"


def _booster_credit_cost(tier: int) -> int:
    return 75 + max(0, tier - 1) * 25


class CareerRunError(Exception):
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


@dataclass(frozen=True, slots=True)
class CareerBoosterChoice:
    booster_id: str
    display_name: str
    description: str
    tier: int
    effect_value: int
    effect_label: str
    credit_cost: int


@dataclass(frozen=True, slots=True)
class CareerOpponentPreview:
    stage_number: int
    total_stages: int
    title: str
    briefing: str
    is_boss: bool
    opponent_id: str
    display_name: str
    description: str
    board: BoardLayout


@dataclass(frozen=True, slots=True)
class CareerRunSnapshot:
    run_id: str | None
    status: str
    stage_index: int
    total_stages: int
    wins: int
    selected_boosters: tuple[CareerBoosterChoice, ...]
    offered_boosters: tuple[CareerBoosterChoice, ...]
    opponent: CareerOpponentPreview | None
    last_match_id: str | None
    reward: RewardGrant | None
    board_required: bool
    started_at: datetime | None
    ended_at: datetime | None

    @property
    def can_battle(self) -> bool:
        return (
            self.status == "active"
            and not self.board_required
            and self.opponent is not None
        )

    @property
    def can_choose_booster(self) -> bool:
        return self.status == "awaiting_booster" and bool(
            self.offered_boosters
        )


@dataclass(frozen=True, slots=True)
class CareerBattleResult:
    match: StoredMatch
    run: CareerRunSnapshot


class CareerRunService:
    def __init__(
        self,
        database: Database,
        match_service: MatchService,
        online_service: OnlinePlayService,
        progression_service: ProgressionService,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
    ) -> None:
        self.database = database
        self.match_service = match_service
        self.online_service = online_service
        self.progression_service = progression_service
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)

    def save_board(self, player_id: str, board: BoardLayout) -> SavedBoard:
        """Save the independent career circuit without touching async PvP."""
        board.validate(self.match_service.engine.config.board_size)
        now = self.clock()
        payload = board.to_dict()
        fingerprint = hashlib.sha256(
            json.dumps(
                payload,
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            ).encode("utf-8")
        ).hexdigest()
        with self.database.session() as session:
            if session.get(PlayerRecord, player_id) is None:
                raise CareerRunError(
                    "player_not_found",
                    "Oyuncu bulunamadı.",
                    status_code=404,
                )
            record = session.scalar(
                select(CareerBoardRecord).where(
                    CareerBoardRecord.player_id == player_id
                )
            )
            if record is None:
                record = CareerBoardRecord(
                    id=self.id_source(),
                    player_id=player_id,
                    name=board.name,
                    modules=payload["modules"],
                    fingerprint=fingerprint,
                    module_count=len(board.modules),
                    created_at=now,
                    updated_at=now,
                )
                session.add(record)
            else:
                record.name = board.name
                record.modules = payload["modules"]
                record.fingerprint = fingerprint
                record.module_count = len(board.modules)
                record.updated_at = now
            session.flush()
            return self._saved_career_board(record)

    def get_board(
        self,
        player_id: str,
        *,
        clone_online_if_missing: bool = True,
    ) -> SavedBoard | None:
        with self.database.session() as session:
            record = session.scalar(
                select(CareerBoardRecord).where(
                    CareerBoardRecord.player_id == player_id
                )
            )
            if record is not None:
                return self._saved_career_board(record)
        if not clone_online_if_missing:
            return None
        online_board = self.online_service.get_board(player_id)
        if online_board is None:
            return None
        # Existing v0.6.1 players start with a one-time copy. Later edits are
        # fully independent, so career changes never overwrite async PvP.
        return self.save_board(
            player_id,
            BoardLayout(
                name="Kariyer Devresi",
                modules=online_board.board.modules,
            ),
        )

    def current(self, player_id: str) -> CareerRunSnapshot:
        with self.database.session() as session:
            if session.get(PlayerRecord, player_id) is None:
                raise CareerRunError(
                    "player_not_found",
                    "Oyuncu bulunamadı.",
                    status_code=404,
                )
            record = session.scalar(
                select(CareerRunRecord)
                .where(CareerRunRecord.player_id == player_id)
                .order_by(desc(CareerRunRecord.started_at))
                .limit(1)
            )
        if record is None:
            return self._idle_snapshot(player_id)
        return self._snapshot(player_id, record)

    def start(self, player_id: str) -> CareerRunSnapshot:
        board = self.get_board(player_id)
        if board is None:
            raise CareerRunError(
                "board_required",
                "Kariyer koşusu için önce geçerli devrenizi kaydedin.",
            )
        now = self.clock()
        with self.database.session() as session:
            player = session.scalar(
                select(PlayerRecord)
                .where(PlayerRecord.id == player_id)
                .with_for_update()
            )
            if player is None:
                raise CareerRunError(
                    "player_not_found",
                    "Oyuncu bulunamadı.",
                    status_code=404,
                )
            # The player row serializes concurrent start requests so one
            # account cannot create two active runs.
            active = session.scalar(
                select(CareerRunRecord)
                .where(
                    CareerRunRecord.player_id == player_id,
                    CareerRunRecord.status.in_(_ACTIVE_STATUSES),
                )
                .order_by(desc(CareerRunRecord.started_at))
                .limit(1)
            )
            if active is not None:
                return self._snapshot(player_id, active)
            record = CareerRunRecord(
                id=self.id_source(),
                player_id=player_id,
                status="active",
                stage_index=0,
                wins=0,
                selected_boosters=[],
                offered_boosters=[],
                last_match_id=None,
                started_at=now,
                updated_at=now,
                ended_at=None,
            )
            session.add(record)
            session.flush()
        return self._snapshot(player_id, record)

    def select_booster(
        self,
        player_id: str,
        booster_id: str,
    ) -> CareerRunSnapshot:
        now = self.clock()
        profile = self.progression_service.snapshot(player_id).profile
        masteries = {
            item.booster_id: item
            for item in self.progression_service.booster_masteries(profile.level)
        }
        if booster_id != _SKIP_BOOSTER_ID and booster_id not in masteries:
            raise CareerRunError(
                "booster_not_found",
                "Seçilen güçlendirici bulunamadı.",
                status_code=404,
            )
        with self.database.session() as session:
            record = self._active_record(session, player_id, lock=True)
            if record.status != "awaiting_booster":
                raise CareerRunError(
                    "booster_not_expected",
                    "Güçlendirici mağazası yalnız boss savaşından önce açılır.",
                )
            offered = list(record.offered_boosters or [])
            if booster_id != _SKIP_BOOSTER_ID and booster_id not in offered:
                raise CareerRunError(
                    "booster_not_offered",
                    "Seçilen güçlendirici boss öncesi seçenekler arasında yok.",
                )
            if booster_id != _SKIP_BOOSTER_ID:
                mastery = masteries[booster_id]
                cost = _booster_credit_cost(mastery.tier)
                progression = session.scalar(
                    select(PlayerProgressionRecord)
                    .where(PlayerProgressionRecord.player_id == player_id)
                    .with_for_update()
                )
                if progression is None or progression.credits < cost:
                    raise CareerRunError(
                        "insufficient_credits",
                        f"Bu güçlendirici için {cost} Devre Kredisi gerekiyor.",
                    )
                progression.credits -= cost
                progression.updated_at = now
                selected = list(record.selected_boosters or [])
                selected.append(booster_id)
                record.selected_boosters = selected
            record.offered_boosters = []
            record.status = "active"
            record.updated_at = now
            session.flush()
        return self._snapshot(player_id, record)

    def battle(self, player_id: str) -> CareerBattleResult:
        board = self.get_board(player_id)
        if board is None:
            raise CareerRunError(
                "board_required",
                "Savaştan önce geçerli devrenizi kaydedin.",
            )
        with self.database.session() as session:
            record = self._active_record(session, player_id, lock=True)
            if record.status != "active":
                raise CareerRunError(
                    "booster_selection_required",
                    "Boss savaşından önce güçlendirici seçin veya güçlendiricisiz ilerleyin.",
                )
            stage_index = record.stage_index
            selected_boosters = list(record.selected_boosters or [])
            run_id = record.id
        if not 0 <= stage_index < TOTAL_STAGES:
            raise CareerRunError(
                "career_stage_invalid",
                "Kariyer koşusu aşaması geçersiz.",
            )

        stage = CAREER_STAGES[stage_index]
        bot = get_bot(stage.bot_id)
        opponent_board = bot.board_for_count(len(board.board.modules))
        modifiers = self._modifiers(player_id, selected_boosters)
        match = self.match_service.create_match(
            player_board=board.board,
            opponent_board=opponent_board,
            opponent=OpponentSnapshot(
                kind="career_bot",
                opponent_id=bot.bot_id,
                display_name=bot.display_name,
                description=f"Kariyer {stage.stage_number}/5 • {stage.title}",
            ),
            source="career",
            requester_player_id=player_id,
            opponent_player_id=None,
            player_modifiers=modifiers,
        )

        won = match.result.get("winner") == "left"
        now = self.clock()
        terminal_completed = False
        terminal_failed = False
        with self.database.session() as session:
            record = session.scalar(
                select(CareerRunRecord)
                .where(
                    CareerRunRecord.id == run_id,
                    CareerRunRecord.player_id == player_id,
                )
                .with_for_update()
            )
            if record is None:
                raise CareerRunError(
                    "career_run_not_found",
                    "Aktif kariyer koşusu bulunamadı.",
                    status_code=404,
                )
            if record.status != "active" or record.stage_index != stage_index:
                raise CareerRunError(
                    "career_state_changed",
                    "Kariyer koşusu başka bir işlemle değişti; ekranı yenileyin.",
                )
            record.last_match_id = match.match_id
            if won:
                record.wins += 1
                record.stage_index += 1
                if record.stage_index >= TOTAL_STAGES:
                    record.status = "completed"
                    record.offered_boosters = []
                    record.ended_at = now
                    terminal_completed = True
                elif record.stage_index == TOTAL_STAGES - 1:
                    record.status = "awaiting_booster"
                    record.offered_boosters = list(_BOSS_BOOSTER_OFFERS)
                else:
                    record.status = "active"
                    record.offered_boosters = []
            else:
                record.status = "failed"
                record.offered_boosters = []
                record.ended_at = now
                terminal_failed = True
            record.updated_at = now
            session.flush()

        if terminal_completed or terminal_failed:
            self.progression_service.grant_career_run(
                player_id,
                run_id,
                wins=record.wins,
                completed=terminal_completed,
            )
        return CareerBattleResult(
            match=match,
            run=self._snapshot(player_id, record),
        )

    def abandon(self, player_id: str) -> CareerRunSnapshot:
        now = self.clock()
        with self.database.session() as session:
            record = self._active_record(session, player_id, lock=True)
            record.status = "abandoned"
            record.offered_boosters = []
            record.ended_at = now
            record.updated_at = now
            session.flush()
        return self._snapshot(player_id, record)

    def _active_record(self, session, player_id: str, *, lock: bool):
        query = (
            select(CareerRunRecord)
            .where(
                CareerRunRecord.player_id == player_id,
                CareerRunRecord.status.in_(_ACTIVE_STATUSES),
            )
            .order_by(desc(CareerRunRecord.started_at))
            .limit(1)
        )
        if lock:
            query = query.with_for_update()
        record = session.scalar(query)
        if record is None:
            raise CareerRunError(
                "career_run_not_found",
                "Aktif kariyer koşusu bulunamadı.",
                status_code=404,
            )
        return record

    def _idle_snapshot(self, player_id: str) -> CareerRunSnapshot:
        return CareerRunSnapshot(
            run_id=None,
            status="idle",
            stage_index=0,
            total_stages=TOTAL_STAGES,
            wins=0,
            selected_boosters=(),
            offered_boosters=(),
            opponent=None,
            last_match_id=None,
            reward=None,
            board_required=self.get_board(player_id) is None,
            started_at=None,
            ended_at=None,
        )

    def _snapshot(
        self,
        player_id: str,
        record: CareerRunRecord,
    ) -> CareerRunSnapshot:
        profile = self.progression_service.snapshot(player_id).profile
        masteries = {
            item.booster_id: item
            for item in self.progression_service.booster_masteries(profile.level)
        }
        selected = tuple(
            self._choice(masteries[booster_id])
            for booster_id in list(record.selected_boosters or [])
            if booster_id in masteries
        )
        offered = tuple(
            self._choice(masteries[booster_id])
            for booster_id in list(record.offered_boosters or [])
            if booster_id in masteries
        )
        saved_board = self.get_board(player_id)
        opponent = None
        if (
            record.status == "active"
            and 0 <= record.stage_index < TOTAL_STAGES
            and saved_board is not None
        ):
            stage = CAREER_STAGES[record.stage_index]
            bot = get_bot(stage.bot_id)
            opponent = CareerOpponentPreview(
                stage_number=stage.stage_number,
                total_stages=TOTAL_STAGES,
                title=stage.title,
                briefing=stage.briefing,
                is_boss=stage.is_boss,
                opponent_id=bot.bot_id,
                display_name=bot.display_name,
                description=bot.description,
                board=bot.board_for_count(len(saved_board.board.modules)),
            )
        reward = None
        if record.status in {"completed", "failed"}:
            reward = self.progression_service.career_reward(
                player_id, record.id
            )
            if reward is None:
                # A process can stop after the terminal run commit but before
                # its reward transaction. Reading the run repairs that narrow
                # window through the idempotent reward key.
                reward = self.progression_service.grant_career_run(
                    player_id,
                    record.id,
                    wins=record.wins,
                    completed=record.status == "completed",
                )
        return CareerRunSnapshot(
            run_id=record.id,
            status=record.status,
            stage_index=record.stage_index,
            total_stages=TOTAL_STAGES,
            wins=record.wins,
            selected_boosters=selected,
            offered_boosters=offered,
            opponent=opponent,
            last_match_id=record.last_match_id,
            reward=reward,
            board_required=saved_board is None,
            started_at=self._as_utc(record.started_at),
            ended_at=(
                self._as_utc(record.ended_at)
                if record.ended_at is not None
                else None
            ),
        )

    def _modifiers(
        self,
        player_id: str,
        selected_boosters: list[str],
    ) -> BattleModifiers:
        profile = self.progression_service.snapshot(player_id).profile
        masteries = {
            item.booster_id: item
            for item in self.progression_service.booster_masteries(profile.level)
        }
        counts = Counter(selected_boosters)
        overcharge = counts["overcharge"] * masteries["overcharge"].effect_value
        shield = (
            counts["reinforced_shield"]
            * masteries["reinforced_shield"].effect_value
        )
        repair = (
            counts["emergency_repair"]
            * masteries["emergency_repair"].effect_value
        )
        reserve = (
            counts["reserve_cell"] * masteries["reserve_cell"].effect_value
        )
        return BattleModifiers(
            generator_output_multiplier=1.0 + (overcharge / 100.0),
            initial_shield=float(shield),
            module_hp_bonus=float(repair),
            initial_energy_reserve=float(reserve),
            reserve_capacity_bonus=float(reserve),
        )

    @staticmethod
    def _choice(mastery: BoosterMastery) -> CareerBoosterChoice:
        return CareerBoosterChoice(
            booster_id=mastery.booster_id,
            display_name=mastery.display_name,
            description=mastery.description,
            tier=mastery.tier,
            effect_value=mastery.effect_value,
            effect_label=mastery.effect_label,
            credit_cost=_booster_credit_cost(mastery.tier),
        )

    @staticmethod
    def _saved_career_board(record: CareerBoardRecord) -> SavedBoard:
        return SavedBoard(
            board_id=record.id,
            player_id=record.player_id,
            board=OnlinePlayService._board_from_record(record),
            fingerprint=record.fingerprint,
            updated_at=CareerRunService._as_utc(record.updated_at),
        )

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)
