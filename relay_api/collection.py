from __future__ import annotations

import uuid
from collections import Counter
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Literal

from sqlalchemy import select
from sqlalchemy.orm import Session

from relay_engine import BoardLayout, ModuleKind

from .database import Database
from .db_models import (
    BoardRecord,
    PlayerCosmeticRecord,
    PlayerLoadoutRecord,
    PlayerProgressionRecord,
    PlayerRecord,
)

CosmeticCategory = Literal["module_skin", "board_theme", "profile_frame"]


class CollectionError(Exception):
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
class CosmeticDefinition:
    cosmetic_id: str
    category: CosmeticCategory
    display_name: str
    description: str
    credit_cost: int
    accent_hex: str
    starter: bool = False


@dataclass(frozen=True, slots=True)
class CosmeticView:
    cosmetic_id: str
    category: CosmeticCategory
    display_name: str
    description: str
    credit_cost: int
    accent_hex: str
    owned: bool
    equipped: bool


@dataclass(frozen=True, slots=True)
class ControlledKit:
    name: str
    module_kinds: tuple[ModuleKind, ...]
    updated_at: datetime

    @property
    def counts(self) -> dict[ModuleKind, int]:
        return dict(Counter(self.module_kinds))


@dataclass(frozen=True, slots=True)
class CollectionSnapshot:
    player_id: str
    credits: int
    cosmetics: tuple[CosmeticView, ...]
    kit: ControlledKit
    equipped_module_skin_id: str
    equipped_board_theme_id: str
    equipped_profile_frame_id: str


COSMETICS: tuple[CosmeticDefinition, ...] = (
    CosmeticDefinition(
        cosmetic_id="module_neon_cyan",
        category="module_skin",
        display_name="Neon Siyan",
        description="Modül simgelerinde Project Relay'in başlangıç neon vurgusu.",
        credit_cost=0,
        accent_hex="#38E8FF",
        starter=True,
    ),
    CosmeticDefinition(
        cosmetic_id="module_coral_pulse",
        category="module_skin",
        display_name="Mercan Darbesi",
        description="Saldırı ve bağlantı vurgularına sıcak mercan tonu uygular.",
        credit_cost=350,
        accent_hex="#FF6B6B",
    ),
    CosmeticDefinition(
        cosmetic_id="module_mint_flux",
        category="module_skin",
        display_name="Nane Akışı",
        description="Modül çerçevelerinde sakin ve yüksek kontrastlı nane vurgusu.",
        credit_cost=500,
        accent_hex="#63F5C7",
    ),
    CosmeticDefinition(
        cosmetic_id="board_midnight_grid",
        category="board_theme",
        display_name="Gece Izgarası",
        description="Koyu laboratuvar zemini ve standart devre ızgarası.",
        credit_cost=0,
        accent_hex="#102B35",
        starter=True,
    ),
    CosmeticDefinition(
        cosmetic_id="board_ion_storm",
        category="board_theme",
        display_name="İyon Fırtınası",
        description="Devre kartına mor-mavi iyon alanı görünümü kazandırır.",
        credit_cost=650,
        accent_hex="#8B7CFF",
    ),
    CosmeticDefinition(
        cosmetic_id="board_mint_matrix",
        category="board_theme",
        display_name="Nane Matrisi",
        description="Kablo ve hücre zemininde nane renkli matris vurgusu.",
        credit_cost=800,
        accent_hex="#39DDA5",
    ),
    CosmeticDefinition(
        cosmetic_id="frame_circuit_basic",
        category="profile_frame",
        display_name="Devre Çerçevesi",
        description="Oyuncu adını ince bir devre iziyle çevreleyen başlangıç çerçevesi.",
        credit_cost=0,
        accent_hex="#2B5969",
        starter=True,
    ),
    CosmeticDefinition(
        cosmetic_id="frame_ranked_gold",
        category="profile_frame",
        display_name="Dereceli Altın",
        description="Profil alanında altın lig vurgulu premium kozmetik çerçeve.",
        credit_cost=950,
        accent_hex="#FFD166",
    ),
    CosmeticDefinition(
        cosmetic_id="frame_boss_core",
        category="profile_frame",
        display_name="Boss Çekirdeği",
        description="Kariyer boss devrelerinden esinlenen kırmızı çekirdek çerçevesi.",
        credit_cost=1200,
        accent_hex="#FF4D6D",
    ),
)

COSMETIC_BY_ID = {item.cosmetic_id: item for item in COSMETICS}
STARTER_EQUIPPED: dict[CosmeticCategory, str] = {
    "module_skin": "module_neon_cyan",
    "board_theme": "board_midnight_grid",
    "profile_frame": "frame_circuit_basic",
}
DEFAULT_KIT: tuple[ModuleKind, ...] = tuple(ModuleKind)
KIT_SIZE = 8
MAX_DUPLICATE_PER_KIND = 3


class CollectionService:
    def __init__(
        self,
        database: Database,
        *,
        clock: Callable[[], datetime] | None = None,
        id_source: Callable[[], str] | None = None,
    ) -> None:
        self.database = database
        self.clock = clock or (lambda: datetime.now(UTC))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)

    def snapshot(self, player_id: str) -> CollectionSnapshot:
        now = self.clock()
        with self.database.session() as session:
            self._require_player(session, player_id)
            progression = self._progression_record(session, player_id, now)
            loadout = self._loadout_record(session, player_id, now)
            self._ensure_starter_ownership(session, player_id, now)
            session.flush()
            return self._snapshot(session, progression, loadout)

    def purchase(self, player_id: str, cosmetic_id: str) -> CollectionSnapshot:
        definition = self._definition(cosmetic_id)
        now = self.clock()
        with self.database.session() as session:
            self._require_player(session, player_id)
            progression = self._progression_record(session, player_id, now)
            loadout = self._loadout_record(session, player_id, now)
            self._ensure_starter_ownership(session, player_id, now)
            owned = session.get(PlayerCosmeticRecord, (player_id, cosmetic_id))
            if owned is not None:
                raise CollectionError(
                    "cosmetic_already_owned",
                    "Bu kozmetik zaten koleksiyonunuzda.",
                )
            if progression.credits < definition.credit_cost:
                raise CollectionError(
                    "insufficient_credits",
                    "Bu kozmetik için yeterli Devre Krediniz yok.",
                )
            progression.credits -= definition.credit_cost
            progression.updated_at = now
            session.add(
                PlayerCosmeticRecord(
                    player_id=player_id,
                    cosmetic_id=cosmetic_id,
                    acquired_at=now,
                )
            )
            self._set_equipped(loadout, definition.category, cosmetic_id)
            loadout.updated_at = now
            session.flush()
            return self._snapshot(session, progression, loadout)

    def equip(self, player_id: str, cosmetic_id: str) -> CollectionSnapshot:
        definition = self._definition(cosmetic_id)
        now = self.clock()
        with self.database.session() as session:
            self._require_player(session, player_id)
            progression = self._progression_record(session, player_id, now)
            loadout = self._loadout_record(session, player_id, now)
            self._ensure_starter_ownership(session, player_id, now)
            if session.get(PlayerCosmeticRecord, (player_id, cosmetic_id)) is None:
                raise CollectionError(
                    "cosmetic_not_owned",
                    "Bu kozmetiği kuşanmak için önce satın almalısınız.",
                )
            self._set_equipped(loadout, definition.category, cosmetic_id)
            loadout.updated_at = now
            session.flush()
            return self._snapshot(session, progression, loadout)

    def save_kit(
        self,
        player_id: str,
        *,
        name: str,
        module_kinds: list[ModuleKind],
    ) -> CollectionSnapshot:
        normalized_name = name.strip()
        if not normalized_name:
            raise CollectionError("kit_name_required", "Kit adı boş olamaz.")
        self._validate_kit(module_kinds)
        now = self.clock()
        with self.database.session() as session:
            self._require_player(session, player_id)
            progression = self._progression_record(session, player_id, now)
            loadout = self._loadout_record(session, player_id, now)
            self._ensure_starter_ownership(session, player_id, now)
            loadout.kit_name = normalized_name[:40]
            loadout.module_kinds = [kind.value for kind in module_kinds]
            loadout.updated_at = now
            session.flush()
            return self._snapshot(session, progression, loadout)

    def validate_board(self, player_id: str, board: BoardLayout) -> None:
        """Reject server-saved boards that use modules outside the active kit."""
        now = self.clock()
        with self.database.session() as session:
            self._require_player(session, player_id)
            loadout = self._loadout_record(session, player_id, now)
            allowed = Counter(ModuleKind(value) for value in loadout.module_kinds)
            used = Counter(module.kind for module in board.modules)
            violations = [
                f"{kind.value}: {count}/{allowed.get(kind, 0)}"
                for kind, count in used.items()
                if count > allowed.get(kind, 0)
            ]
            if violations:
                raise CollectionError(
                    "board_exceeds_active_kit",
                    "Devre aktif sekizli kit sınırını aşıyor: "
                    + ", ".join(violations),
                )

    @staticmethod
    def _validate_kit(module_kinds: list[ModuleKind]) -> None:
        if len(module_kinds) != KIT_SIZE:
            raise CollectionError(
                "kit_size_invalid",
                f"Kontrollü kit tam olarak {KIT_SIZE} modül yuvası içermelidir.",
            )
        counts = Counter(module_kinds)
        if counts[ModuleKind.GENERATOR] != 1:
            raise CollectionError(
                "kit_generator_invalid",
                "Sekizli kit tam olarak bir jeneratör içermelidir.",
            )
        too_many = [
            kind.value
            for kind, count in counts.items()
            if kind is not ModuleKind.GENERATOR and count > MAX_DUPLICATE_PER_KIND
        ]
        if too_many:
            raise CollectionError(
                "kit_duplicate_limit",
                "Bir modül türü kitte en fazla üç kez bulunabilir: "
                + ", ".join(too_many),
            )

    def _snapshot(
        self,
        session: Session,
        progression: PlayerProgressionRecord,
        loadout: PlayerLoadoutRecord,
    ) -> CollectionSnapshot:
        owned_ids = set(
            session.scalars(
                select(PlayerCosmeticRecord.cosmetic_id).where(
                    PlayerCosmeticRecord.player_id == progression.player_id
                )
            )
        )
        equipped = {
            loadout.module_skin_id,
            loadout.board_theme_id,
            loadout.profile_frame_id,
        }
        cosmetics = tuple(
            CosmeticView(
                cosmetic_id=item.cosmetic_id,
                category=item.category,
                display_name=item.display_name,
                description=item.description,
                credit_cost=item.credit_cost,
                accent_hex=item.accent_hex,
                owned=item.cosmetic_id in owned_ids,
                equipped=item.cosmetic_id in equipped,
            )
            for item in COSMETICS
        )
        return CollectionSnapshot(
            player_id=progression.player_id,
            credits=progression.credits,
            cosmetics=cosmetics,
            kit=ControlledKit(
                name=loadout.kit_name,
                module_kinds=tuple(
                    ModuleKind(value) for value in loadout.module_kinds
                ),
                updated_at=self._as_utc(loadout.updated_at),
            ),
            equipped_module_skin_id=loadout.module_skin_id,
            equipped_board_theme_id=loadout.board_theme_id,
            equipped_profile_frame_id=loadout.profile_frame_id,
        )

    def _loadout_record(
        self,
        session: Session,
        player_id: str,
        now: datetime,
    ) -> PlayerLoadoutRecord:
        record = session.get(PlayerLoadoutRecord, player_id)
        if record is not None:
            return record
        record = PlayerLoadoutRecord(
            player_id=player_id,
            kit_name="Başlangıç Sekizlisi",
            module_kinds=[kind.value for kind in self._legacy_compatible_kit(session, player_id)],
            module_skin_id=STARTER_EQUIPPED["module_skin"],
            board_theme_id=STARTER_EQUIPPED["board_theme"],
            profile_frame_id=STARTER_EQUIPPED["profile_frame"],
            created_at=now,
            updated_at=now,
        )
        session.add(record)
        session.flush()
        return record

    @staticmethod
    def _legacy_compatible_kit(
        session: Session,
        player_id: str,
    ) -> tuple[ModuleKind, ...]:
        board = session.scalar(
            select(BoardRecord).where(BoardRecord.player_id == player_id)
        )
        selected: list[ModuleKind] = []
        if board is not None:
            for module in board.modules:
                kind = ModuleKind(str(module["kind"]))
                if kind is ModuleKind.GENERATOR and kind in selected:
                    continue
                if selected.count(kind) < MAX_DUPLICATE_PER_KIND:
                    selected.append(kind)
        if ModuleKind.GENERATOR not in selected:
            selected.insert(0, ModuleKind.GENERATOR)
        for kind in DEFAULT_KIT:
            if len(selected) >= KIT_SIZE:
                break
            if kind is ModuleKind.GENERATOR and kind in selected:
                continue
            if kind not in selected:
                selected.append(kind)
        while len(selected) < KIT_SIZE:
            for kind in DEFAULT_KIT:
                if kind is ModuleKind.GENERATOR:
                    continue
                if selected.count(kind) < MAX_DUPLICATE_PER_KIND:
                    selected.append(kind)
                    break
        return tuple(selected[:KIT_SIZE])

    @staticmethod
    def _progression_record(
        session: Session,
        player_id: str,
        now: datetime,
    ) -> PlayerProgressionRecord:
        record = session.get(PlayerProgressionRecord, player_id)
        if record is None:
            record = PlayerProgressionRecord(
                player_id=player_id,
                total_xp=0,
                credits=0,
                matches_completed=0,
                wins=0,
                draws=0,
                losses=0,
                created_at=now,
                updated_at=now,
            )
            session.add(record)
            session.flush()
        return record

    @staticmethod
    def _ensure_starter_ownership(
        session: Session,
        player_id: str,
        now: datetime,
    ) -> None:
        for definition in COSMETICS:
            if not definition.starter:
                continue
            if session.get(
                PlayerCosmeticRecord,
                (player_id, definition.cosmetic_id),
            ) is None:
                session.add(
                    PlayerCosmeticRecord(
                        player_id=player_id,
                        cosmetic_id=definition.cosmetic_id,
                        acquired_at=now,
                    )
                )

    @staticmethod
    def _set_equipped(
        loadout: PlayerLoadoutRecord,
        category: CosmeticCategory,
        cosmetic_id: str,
    ) -> None:
        if category == "module_skin":
            loadout.module_skin_id = cosmetic_id
        elif category == "board_theme":
            loadout.board_theme_id = cosmetic_id
        elif category == "profile_frame":
            loadout.profile_frame_id = cosmetic_id
        else:  # pragma: no cover - Literal guards this path
            raise ValueError(f"Bilinmeyen kozmetik kategorisi: {category}")

    @staticmethod
    def _require_player(session: Session, player_id: str) -> None:
        if session.get(PlayerRecord, player_id) is None:
            raise CollectionError(
                "player_not_found",
                "Oyuncu bulunamadı.",
                status_code=404,
            )

    @staticmethod
    def _definition(cosmetic_id: str) -> CosmeticDefinition:
        try:
            return COSMETIC_BY_ID[cosmetic_id]
        except KeyError as exc:
            raise CollectionError(
                "cosmetic_not_found",
                "Kozmetik bulunamadı.",
                status_code=404,
            ) from exc

    @staticmethod
    def _as_utc(value: datetime) -> datetime:
        if value.tzinfo is None:
            return value.replace(tzinfo=UTC)
        return value.astimezone(UTC)
