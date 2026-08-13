from __future__ import annotations

import hashlib
import json
import uuid
from collections import Counter
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime

from sqlalchemy import desc, select

from relay_engine import (
    BattleModifiers,
    BoardLayout,
    ModuleKind,
    ModulePlacement,
)
from relay_engine.catalog import get_spec
from relay_engine.models import scaled_value

from .bots import get_bot
from .content import (
    DEFAULT_CAREER_SECTOR,
    CareerSectorDefinition,
    CareerStageDefinition,
)
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

CAREER_STAGES: tuple[CareerStageDefinition, ...] = (
    DEFAULT_CAREER_SECTOR.stages
)
TOTAL_STAGES = len(CAREER_STAGES)
_ACTIVE_STATUSES = {"active", "awaiting_upgrade", "awaiting_booster"}
_TERMINAL_STATUSES = {"completed", "failed", "abandoned"}

# Güçlendirici mağazası yalnız dördüncü zaferden sonra, boss öncesinde açılır.
_BOSS_BOOSTER_OFFERS: tuple[str, str, str] = (
    "overcharge",
    "reinforced_shield",
    "reserve_cell",
)
_SKIP_BOOSTER_ID = "none"
_LEGACY_UPGRADE_PREFIX = "module_upgrade|"
_UPGRADE_RULESET_VERSION = "1"
_UPGRADE_BRANCHES: dict[ModuleKind, tuple[str, str]] = {
    ModuleKind.GENERATOR: ("overclock", "regulated"),
    ModuleKind.BATTERY: ("overclock", "primed"),
    ModuleKind.AMPLIFIER: ("overclock", "focused"),
    ModuleKind.LASER: ("overclock", "efficient"),
    ModuleKind.PULSE_CANNON: ("overclock", "efficient"),
    ModuleKind.SHIELD: ("overclock", "efficient"),
    ModuleKind.COOLER: ("overclock", "efficient"),
    ModuleKind.REPAIR: ("overclock", "efficient"),
}


def _parse_legacy_upgrade(value: str) -> tuple[str, str] | None:
    if not value.startswith(_LEGACY_UPGRADE_PREFIX):
        return None
    parts = value.split("|", 2)
    if len(parts) != 3 or parts[2] not in {"overclock", "efficient"}:
        return None
    return parts[1], parts[2]


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
class CareerModuleUpgrade:
    module_id: str
    kind: str
    branch: str
    display_name: str
    description: str
    effect_label: str
    before_value: str
    after_value: str


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
    selected_upgrades: tuple[CareerModuleUpgrade, ...] = ()
    offered_upgrades: tuple[CareerModuleUpgrade, ...] = ()
    sector: CareerSectorDefinition = DEFAULT_CAREER_SECTOR

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

    @property
    def can_choose_upgrade(self) -> bool:
        return self.status == "awaiting_upgrade" and bool(self.offered_upgrades)


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
            active_run = session.scalar(
                select(CareerRunRecord)
                .where(
                    CareerRunRecord.player_id == player_id,
                    CareerRunRecord.status.in_(_ACTIVE_STATUSES),
                )
                .order_by(desc(CareerRunRecord.started_at))
                .limit(1)
                .with_for_update()
            )
            if active_run is not None and record is not None:
                previous_kinds = {
                    str(item["module_id"]): str(item["kind"])
                    for item in list(record.modules or [])
                }
                next_modules = {item.module_id: item for item in board.modules}
                for upgrade in self._upgrade_records(
                    active_run,
                    previous_kinds,
                ):
                    upgraded = next_modules.get(str(upgrade["module_id"]))
                    if (
                        upgraded is None
                        or upgraded.kind.value != str(upgrade["kind"])
                    ):
                        raise CareerRunError(
                            "upgraded_module_locked",
                            "Koşu sırasında yükseltilmiş modül kaldırılamaz veya başka bir modülle değiştirilemez.",
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
        clone_online_if_missing: bool = False,
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
                selected_module_upgrades=[],
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

    def select_module_upgrade(
        self,
        player_id: str,
        module_id: str,
        branch: str,
    ) -> CareerRunSnapshot:
        board = self.get_board(player_id)
        if board is None:
            raise CareerRunError("board_required", "Önce kariyer devrenizi kaydedin.")
        module = next(
            (item for item in board.board.modules if item.module_id == module_id),
            None,
        )
        if module is None:
            raise CareerRunError("upgrade_module_not_found", "Yükseltilecek modül devrede bulunamadı.", status_code=404)
        if branch not in self._branches_for(module):
            raise CareerRunError(
                "upgrade_branch_invalid",
                "Bu yükseltme dalı seçilen modülde etkili değil.",
            )
        now = self.clock()
        with self.database.session() as session:
            record = self._active_record(session, player_id, lock=True)
            if record.status != "awaiting_upgrade":
                raise CareerRunError("upgrade_not_expected", "Bu aşamada modül yükseltmesi seçilemez.")
            module_kinds = {
                item.module_id: item.kind.value for item in board.board.modules
            }
            existing = [
                str(item["module_id"])
                for item in self._upgrade_records(record, module_kinds)
            ]
            if module_id in existing:
                raise CareerRunError("module_already_upgraded", "Bu modül koşuda zaten yükseltildi.")
            selected = list(record.selected_module_upgrades or [])
            selected.append(
                {
                    "module_id": module.module_id,
                    "kind": module.kind.value,
                    "branch": branch,
                    "tier": 1,
                    "acquired_stage": record.stage_index,
                    "ruleset_version": _UPGRADE_RULESET_VERSION,
                }
            )
            record.selected_module_upgrades = selected
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
            module_kinds = {
                item.module_id: item.kind.value for item in board.board.modules
            }
            selected_upgrades = self._upgrade_records(record, module_kinds)
            run_id = record.id
        if not 0 <= stage_index < TOTAL_STAGES:
            raise CareerRunError(
                "career_stage_invalid",
                "Kariyer koşusu aşaması geçersiz.",
            )

        stage = CAREER_STAGES[stage_index]
        bot = get_bot(stage.bot_id)
        opponent_board = bot.board_for_count(len(board.board.modules))
        modifiers = self._modifiers(
            player_id,
            selected_boosters,
            selected_upgrades,
        )
        battle_board = self._apply_module_upgrades(
            board.board,
            selected_upgrades,
        )
        match = self.match_service.create_match(
            player_board=battle_board,
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
                    record.status = "awaiting_upgrade"
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
            selected_upgrades=self._selected_upgrades(record, saved_board),
            offered_upgrades=(
                self._upgrade_offers(record, saved_board)
                if record.status == "awaiting_upgrade"
                else ()
            ),
        )

    def _modifiers(
        self,
        player_id: str,
        selected_boosters: list[str],
        selected_upgrades: list[dict[str, object]],
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
        regulated_count = sum(
            1 for item in selected_upgrades if item["branch"] == "regulated"
        )
        primed_count = sum(
            1 for item in selected_upgrades if item["branch"] == "primed"
        )
        return BattleModifiers(
            generator_output_multiplier=(1.0 + (overcharge / 100.0))
            * (1.0 + (0.15 * regulated_count)),
            initial_shield=float(shield),
            module_hp_bonus=float(repair),
            initial_energy_reserve=float(reserve + (8 * primed_count)),
            reserve_capacity_bonus=float(reserve + (8 * primed_count)),
            efficient_module_ids=tuple(
                str(item["module_id"])
                for item in selected_upgrades
                if item["branch"] == "efficient"
            ),
            focused_amplifier_ids=tuple(
                str(item["module_id"])
                for item in selected_upgrades
                if item["branch"] == "focused"
            ),
        )

    @staticmethod
    def _apply_module_upgrades(
        board: BoardLayout,
        selected: list[dict[str, object]],
    ) -> BoardLayout:
        overclocked = {
            str(item["module_id"])
            for item in selected
            if item["branch"] == "overclock"
        }
        return BoardLayout(
            name=board.name,
            modules=tuple(
                ModulePlacement(
                    module_id=item.module_id,
                    kind=item.kind,
                    row=item.row,
                    column=item.column,
                    orientation=item.orientation,
                    level=min(3, item.level + 1) if item.module_id in overclocked else item.level,
                )
                for item in board.modules
            ),
        )

    @staticmethod
    def _upgrade_choice(module, branch: str) -> CareerModuleUpgrade:
        spec = get_spec(module.kind)
        title = {
            "overclock": "Aşırı Sürüş",
            "efficient": "Kararlı Devre",
            "regulated": "Regüle Akım",
            "primed": "Ön Şarj",
            "focused": "Odak Matrisi",
        }[branch]
        if branch == "overclock":
            label, base_value = CareerRunService._primary_upgrade_value(module)
            before = scaled_value(base_value, module.level)
            after = scaled_value(base_value, min(3, module.level + 1))
            description = (
                f"Seviye {module.level} → {min(3, module.level + 1)}; "
                "etki ve dayanıklılık artar, aktif modüllerde yük de büyür."
            )
        elif branch == "efficient":
            label = "Enerji / eylem ısısı"
            before = (
                f"{CareerRunService._number(spec.energy_cost)} / "
                f"{CareerRunService._number(spec.heat_per_action)}"
            )
            after = (
                f"{CareerRunService._number(spec.energy_cost * 0.82)} / "
                f"{CareerRunService._number(spec.heat_per_action * 0.78)}"
            )
            description = "Enerji maliyeti %18, eylem ısısı %22 azalır."
        elif branch == "regulated":
            label = "Jeneratör çıkışı"
            before = scaled_value(spec.energy_output, module.level)
            after = before * 1.15
            description = (
                "Enerji çıkışı %15 artar; ek eylem ısısı oluşturmaz."
            )
        elif branch == "primed":
            label = "Batarya kapasitesi"
            before = scaled_value(spec.battery_capacity, module.level)
            after = before + 8
            description = (
                "Savaşa +8 enerjiyle başlar ve rezerv kapasitesini +8 artırır."
            )
        else:
            label = "Güçlendirme / ısı"
            before = "+35% / +25%"
            after = "+50% / +32%"
            description = (
                "Hedef modülün etkisini daha güçlü artırır; ek ısı yükü de yükselir."
            )
        return CareerModuleUpgrade(
            module_id=module.module_id,
            kind=module.kind.value,
            branch=branch,
            display_name=title,
            description=description,
            effect_label=label,
            before_value=(
                before
                if isinstance(before, str)
                else CareerRunService._number(before)
            ),
            after_value=(
                after
                if isinstance(after, str)
                else CareerRunService._number(after)
            ),
        )

    def _selected_upgrades(self, record, saved_board) -> tuple[CareerModuleUpgrade, ...]:
        if saved_board is None:
            return ()
        modules = {item.module_id: item for item in saved_board.board.modules}
        kinds = {module_id: item.kind.value for module_id, item in modules.items()}
        return tuple(
            self._upgrade_choice(modules[str(item["module_id"])], str(item["branch"]))
            for item in self._upgrade_records(record, kinds)
            if str(item["module_id"]) in modules
        )

    def _upgrade_offers(self, record, saved_board) -> tuple[CareerModuleUpgrade, ...]:
        if saved_board is None:
            return ()
        selected_ids = {item.module_id for item in self._selected_upgrades(record, saved_board)}
        return tuple(
            self._upgrade_choice(module, branch)
            for module in saved_board.board.modules
            if module.module_id not in selected_ids
            for branch in self._branches_for(module)
        )

    @staticmethod
    def _branches_for(module: ModulePlacement) -> tuple[str, ...]:
        return tuple(
            branch
            for branch in _UPGRADE_BRANCHES[module.kind]
            if branch != "overclock" or module.level < 3
        )

    @staticmethod
    def _upgrade_records(
        record,
        module_kinds: dict[str, str],
    ) -> list[dict[str, object]]:
        result: list[dict[str, object]] = []
        seen: set[str] = set()
        for raw in list(getattr(record, "selected_module_upgrades", None) or []):
            if not isinstance(raw, dict):
                continue
            module_id = str(raw.get("module_id", ""))
            kind = str(raw.get("kind", module_kinds.get(module_id, "")))
            branch = str(raw.get("branch", ""))
            if (
                not module_id
                or not kind
                or branch not in {"overclock", "efficient", "regulated", "primed", "focused"}
                or module_id in seen
            ):
                continue
            result.append(
                {
                    "module_id": module_id,
                    "kind": kind,
                    "branch": branch,
                    "tier": int(raw.get("tier", 1)),
                    "acquired_stage": int(raw.get("acquired_stage", 0)),
                    "ruleset_version": str(
                        raw.get("ruleset_version", _UPGRADE_RULESET_VERSION)
                    ),
                }
            )
            seen.add(module_id)

        # Eski alfa kayıtları okunmaya devam eder; yeni seçimler artık ayrı
        # selected_module_upgrades alanına yazılır.
        for value in list(record.selected_boosters or []):
            parsed = _parse_legacy_upgrade(value)
            if parsed is None or parsed[0] in seen:
                continue
            kind = module_kinds.get(parsed[0])
            if kind is None:
                continue
            result.append(
                {
                    "module_id": parsed[0],
                    "kind": kind,
                    "branch": parsed[1],
                    "tier": 1,
                    "acquired_stage": 0,
                    "ruleset_version": "legacy",
                }
            )
            seen.add(parsed[0])
        return result

    @staticmethod
    def _primary_upgrade_value(module: ModulePlacement) -> tuple[str, float]:
        spec = get_spec(module.kind)
        if spec.damage > 0:
            return "Hasar", spec.damage
        if spec.shield > 0:
            return "Kalkan", spec.shield
        if spec.cooling > 0:
            return "Soğutma", spec.cooling
        if spec.repair > 0:
            return "Onarım", spec.repair
        if spec.energy_output > 0:
            return "Enerji çıkışı", spec.energy_output
        if spec.battery_capacity > 0:
            return "Batarya kapasitesi", spec.battery_capacity
        return "Dayanıklılık", spec.max_hp

    @staticmethod
    def _number(value: float) -> str:
        rounded = round(value, 1)
        return str(int(rounded)) if rounded.is_integer() else f"{rounded:.1f}"

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
