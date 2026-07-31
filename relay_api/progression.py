from __future__ import annotations

import uuid
from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, date, datetime
from typing import Literal

from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import Database
from .db_models import (
    DailyMissionRecord,
    MatchRecord,
    PlayerAchievementRecord,
    PlayerProgressionRecord,
    PlayerRatingRecord,
    PlayerRecord,
    RewardGrantRecord,
)
from .store import StoredMatch

Outcome = Literal["win", "draw", "loss"]

MATCH_REWARDS: dict[Outcome, tuple[int, int]] = {
    "win": (50, 30),
    "draw": (35, 20),
    "loss": (25, 12),
}


@dataclass(frozen=True, slots=True)
class DailyMissionDefinition:
    mission_id: str
    title: str
    description: str
    metric: str
    target: int
    reward_xp: int
    reward_credits: int


DAILY_MISSIONS: tuple[DailyMissionDefinition, ...] = (
    DailyMissionDefinition(
        mission_id="first_signal",
        title="İlk Sinyal",
        description="Bir asenkron devre savaşını tamamla.",
        metric="matches_completed",
        target=1,
        reward_xp=30,
        reward_credits=25,
    ),
    DailyMissionDefinition(
        mission_id="steady_current",
        title="Kararlı Akım",
        description="Üç asenkron devre savaşını tamamla.",
        metric="matches_completed",
        target=3,
        reward_xp=70,
        reward_credits=60,
    ),
    DailyMissionDefinition(
        mission_id="victory_pulse",
        title="Zafer Darbesi",
        description="Bir asenkron devre savaşı kazan.",
        metric="wins",
        target=1,
        reward_xp=50,
        reward_credits=40,
    ),
)


@dataclass(frozen=True, slots=True)
class AchievementDefinition:
    achievement_id: str
    title: str
    description: str
    metric: str
    target: int
    reward_xp: int
    reward_credits: int


ACHIEVEMENTS: tuple[AchievementDefinition, ...] = (
    AchievementDefinition(
        achievement_id="first_battle",
        title="Devreye Giriş",
        description="İlk asenkron savaşını tamamla.",
        metric="matches_completed",
        target=1,
        reward_xp=100,
        reward_credits=50,
    ),
    AchievementDefinition(
        achievement_id="first_victory",
        title="İlk Kıvılcım",
        description="İlk asenkron zaferini kazan.",
        metric="wins",
        target=1,
        reward_xp=100,
        reward_credits=75,
    ),
    AchievementDefinition(
        achievement_id="circuit_veteran",
        title="Devre Ustası",
        description="On asenkron savaşı tamamla.",
        metric="matches_completed",
        target=10,
        reward_xp=250,
        reward_credits=150,
    ),
    AchievementDefinition(
        achievement_id="level_five",
        title="Yükselen Gerilim",
        description="Oyuncu seviyesini 5'e çıkar.",
        metric="level",
        target=5,
        reward_xp=250,
        reward_credits=200,
    ),
    AchievementDefinition(
        achievement_id="rating_1100",
        title="Rekabet Frekansı",
        description="Derece puanını 1100'e çıkar.",
        metric="rating",
        target=1100,
        reward_xp=300,
        reward_credits=250,
    ),
)


@dataclass(frozen=True, slots=True)
class BoosterDefinition:
    booster_id: str
    display_name: str
    description: str
    unlock_level: int
    effect_values: tuple[int, int, int, int, int]
    effect_template: str


BOOSTERS: tuple[BoosterDefinition, ...] = (
    BoosterDefinition(
        booster_id="overcharge",
        display_name="Aşırı Şarj",
        description=(
            "Yalnız kariyer koşusunda jeneratör üretimini geçici artırır."
        ),
        unlock_level=1,
        effect_values=(5, 8, 11, 14, 17),
        effect_template="Jeneratör üretimi +%{value}",
    ),
    BoosterDefinition(
        booster_id="reinforced_shield",
        display_name="Güçlendirilmiş Kalkan",
        description=(
            "Yalnız kariyer koşusunda ilk kalkan darbesine geçici emilim ekler."
        ),
        unlock_level=1,
        effect_values=(5, 8, 11, 14, 17),
        effect_template="İlk darbede +{value} emilim",
    ),
    BoosterDefinition(
        booster_id="emergency_repair",
        display_name="Acil Onarım",
        description=(
            "Yalnız kariyer koşusunda savaş modüllerine geçici dayanıklılık verir."
        ),
        unlock_level=1,
        effect_values=(8, 12, 16, 20, 24),
        effect_template="Savaş modülü Canı +{value}",
    ),
    BoosterDefinition(
        booster_id="reserve_cell",
        display_name="Yedek Hücre",
        description=(
            "Yalnız kariyer koşusunda savaşa geçici rezerv enerjiyle başlatır."
        ),
        unlock_level=1,
        effect_values=(5, 8, 11, 14, 17),
        effect_template="Başlangıç rezervi +{value}",
    ),
)


class ProgressionError(Exception):
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
class ProgressionProfile:
    player_id: str
    total_xp: int
    level: int
    xp_into_level: int
    xp_for_next_level: int
    credits: int
    matches_completed: int
    wins: int
    draws: int
    losses: int


@dataclass(frozen=True, slots=True)
class DailyMission:
    mission_id: str
    title: str
    description: str
    progress: int
    target: int
    completed: bool
    claimed: bool
    reward_xp: int
    reward_credits: int


@dataclass(frozen=True, slots=True)
class Achievement:
    achievement_id: str
    title: str
    description: str
    progress: int
    target: int
    unlocked: bool
    claimed: bool
    reward_xp: int
    reward_credits: int


@dataclass(frozen=True, slots=True)
class BoosterMastery:
    booster_id: str
    display_name: str
    description: str
    unlock_level: int
    unlocked: bool
    tier: int
    effect_value: int
    effect_label: str
    next_tier_level: int | None


@dataclass(frozen=True, slots=True)
class RewardGrant:
    source_type: str
    source_id: str
    reason: str
    xp: int
    credits: int
    level_before: int
    level_after: int
    total_xp_after: int
    credits_after: int
    granted_at: datetime

    @property
    def level_up(self) -> bool:
        return self.level_after > self.level_before


@dataclass(frozen=True, slots=True)
class ProgressionSnapshot:
    day_key: str
    profile: ProgressionProfile
    daily_missions: tuple[DailyMission, ...]
    achievements: tuple[Achievement, ...]
    boosters: tuple[BoosterMastery, ...]


def xp_required_for_level(level: int) -> int:
    if level < 1:
        raise ValueError("Seviye 1 veya daha büyük olmalıdır.")
    return 100 + ((level - 1) * 25)


def level_progress(total_xp: int) -> tuple[int, int, int]:
    if total_xp < 0:
        raise ValueError("Toplam deneyim negatif olamaz.")
    level = 1
    remaining = total_xp
    required = xp_required_for_level(level)
    while remaining >= required:
        remaining -= required
        level += 1
        required = xp_required_for_level(level)
    return level, remaining, required


def booster_tier_for_level(level: int) -> int:
    return min(5, max(1, 1 + (max(level, 1) // 10)))


class ProgressionService:
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

    def apply_match(self, match: StoredMatch) -> RewardGrant | None:
        if match.source != "async" or match.requester_player_id is None:
            return None
        player_id = match.requester_player_id
        with self.database.session() as session:
            persisted = session.scalar(
                select(MatchRecord)
                .where(MatchRecord.id == match.match_id)
                .with_for_update()
            )
            if persisted is None:
                raise LookupError("Ödüllendirilecek maç veritabanında yok.")
            existing = session.scalar(
                select(RewardGrantRecord).where(
                    RewardGrantRecord.player_id == player_id,
                    RewardGrantRecord.source_type == "match",
                    RewardGrantRecord.source_id == match.match_id,
                )
            )
            if existing is not None:
                return self._grant(existing)
            if session.get(PlayerRecord, player_id) is None:
                raise LookupError("Ödüllendirilecek oyuncu bulunamadı.")

            now = self.clock()
            record = self._progression_record(session, player_id, now)
            outcome = self._requester_outcome(match)
            xp, credits = MATCH_REWARDS[outcome]
            grant = self._apply_reward(
                session,
                record,
                source_type="match",
                source_id=match.match_id,
                reason=f"Asenkron savaş: {outcome}",
                xp=xp,
                credits=credits,
                now=now,
            )
            record.matches_completed += 1
            if outcome == "win":
                record.wins += 1
            elif outcome == "draw":
                record.draws += 1
            else:
                record.losses += 1
            record.updated_at = now
            self._advance_daily_missions(
                session,
                record.player_id,
                now.date(),
                outcome,
                now,
            )
            self._sync_achievements(session, record, now)
            session.flush()
            return grant

    def match_reward(
        self,
        match_id: str,
        player_id: str,
    ) -> RewardGrant | None:
        with self.database.session() as session:
            record = session.scalar(
                select(RewardGrantRecord).where(
                    RewardGrantRecord.player_id == player_id,
                    RewardGrantRecord.source_type == "match",
                    RewardGrantRecord.source_id == match_id,
                )
            )
            return self._grant(record) if record is not None else None

    def snapshot(self, player_id: str) -> ProgressionSnapshot:
        now = self.clock()
        with self.database.session() as session:
            if session.get(PlayerRecord, player_id) is None:
                raise LookupError("Oyuncu bulunamadı.")
            record = self._progression_record(session, player_id, now)
            missions = self._ensure_daily_missions(
                session,
                player_id,
                now.date(),
                now,
            )
            achievements = self._sync_achievements(session, record, now)
            session.flush()
            profile = self._profile(record)
            return ProgressionSnapshot(
                day_key=now.date().isoformat(),
                profile=profile,
                daily_missions=tuple(
                    self._daily_mission(mission) for mission in missions
                ),
                achievements=tuple(
                    self._achievement(achievement)
                    for achievement in achievements
                ),
                boosters=self._boosters(profile.level),
            )

    def claim_daily_mission(
        self,
        player_id: str,
        mission_id: str,
    ) -> RewardGrant:
        definition = self._daily_definition(mission_id)
        now = self.clock()
        day_key = now.date().isoformat()
        with self.database.session() as session:
            record = self._progression_record(session, player_id, now)
            self._ensure_daily_missions(session, player_id, now.date(), now)
            mission = session.get(
                DailyMissionRecord,
                (day_key, player_id, mission_id),
            )
            if mission is None:
                raise ProgressionError(
                    "mission_not_found",
                    "Günlük görev bulunamadı.",
                    status_code=404,
                )
            existing = self._existing_grant(
                session,
                player_id,
                "daily_mission",
                f"{day_key}:{mission_id}",
            )
            if existing is not None:
                return self._grant(existing)
            if mission.progress < mission.target:
                raise ProgressionError(
                    "mission_incomplete",
                    "Bu günlük görev henüz tamamlanmadı.",
                )
            grant = self._apply_reward(
                session,
                record,
                source_type="daily_mission",
                source_id=f"{day_key}:{mission_id}",
                reason=f"Günlük görev: {definition.title}",
                xp=definition.reward_xp,
                credits=definition.reward_credits,
                now=now,
            )
            mission.claimed_at = now
            self._sync_achievements(session, record, now)
            session.flush()
            return grant

    def claim_achievement(
        self,
        player_id: str,
        achievement_id: str,
    ) -> RewardGrant:
        definition = self._achievement_definition(achievement_id)
        now = self.clock()
        with self.database.session() as session:
            record = self._progression_record(session, player_id, now)
            self._sync_achievements(session, record, now)
            achievement = session.get(
                PlayerAchievementRecord,
                (player_id, achievement_id),
            )
            if achievement is None:
                raise ProgressionError(
                    "achievement_not_found",
                    "Başarım bulunamadı.",
                    status_code=404,
                )
            existing = self._existing_grant(
                session,
                player_id,
                "achievement",
                achievement_id,
            )
            if existing is not None:
                return self._grant(existing)
            if achievement.unlocked_at is None:
                raise ProgressionError(
                    "achievement_locked",
                    "Bu başarım henüz açılmadı.",
                )
            grant = self._apply_reward(
                session,
                record,
                source_type="achievement",
                source_id=achievement_id,
                reason=f"Başarım: {definition.title}",
                xp=definition.reward_xp,
                credits=definition.reward_credits,
                now=now,
            )
            achievement.claimed_at = now
            self._sync_achievements(session, record, now)
            session.flush()
            return grant

    def grant_career_run(
        self,
        player_id: str,
        run_id: str,
        *,
        wins: int,
        completed: bool,
    ) -> RewardGrant:
        """Grant one terminal reward for a server-authoritative career run."""
        now = self.clock()
        with self.database.session() as session:
            existing = self._existing_grant(
                session, player_id, "career_run", run_id
            )
            if existing is not None:
                return self._grant(existing)
            if session.get(PlayerRecord, player_id) is None:
                raise LookupError("Ödüllendirilecek oyuncu bulunamadı.")
            record = self._progression_record(session, player_id, now)
            xp = max(0, wins) * 30 + (150 if completed else 0)
            credits = max(0, wins) * 18 + (100 if completed else 0)
            result_label = "tamamlandı" if completed else "sona erdi"
            grant = self._apply_reward(
                session,
                record,
                source_type="career_run",
                source_id=run_id,
                reason=f"Kariyer koşusu {result_label}: {wins}/5 zafer",
                xp=xp,
                credits=credits,
                now=now,
            )
            self._sync_achievements(session, record, now)
            session.flush()
            return grant

    def career_reward(
        self, player_id: str, run_id: str
    ) -> RewardGrant | None:
        with self.database.session() as session:
            existing = self._existing_grant(
                session, player_id, "career_run", run_id
            )
            return self._grant(existing) if existing is not None else None

    @staticmethod
    def booster_masteries(level: int) -> tuple[BoosterMastery, ...]:
        return ProgressionService._boosters(level)

    def _apply_reward(
        self,
        session: Session,
        record: PlayerProgressionRecord,
        *,
        source_type: str,
        source_id: str,
        reason: str,
        xp: int,
        credits: int,
        now: datetime,
    ) -> RewardGrant:
        level_before, _, _ = level_progress(record.total_xp)
        record.total_xp += xp
        record.credits += credits
        record.updated_at = now
        level_after, _, _ = level_progress(record.total_xp)
        grant = RewardGrantRecord(
            id=self.id_source(),
            player_id=record.player_id,
            source_type=source_type,
            source_id=source_id,
            reason=reason,
            xp=xp,
            credits=credits,
            level_before=level_before,
            level_after=level_after,
            total_xp_after=record.total_xp,
            credits_after=record.credits,
            granted_at=now,
        )
        session.add(grant)
        session.flush()
        return self._grant(grant)

    def _progression_record(
        self,
        session: Session,
        player_id: str,
        now: datetime,
    ) -> PlayerProgressionRecord:
        record = session.scalar(
            select(PlayerProgressionRecord)
            .where(PlayerProgressionRecord.player_id == player_id)
            .with_for_update()
        )
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

    def _ensure_daily_missions(
        self,
        session: Session,
        player_id: str,
        day: date,
        now: datetime,
    ) -> list[DailyMissionRecord]:
        day_key = day.isoformat()
        rows = {
            row.mission_id: row
            for row in session.scalars(
                select(DailyMissionRecord).where(
                    DailyMissionRecord.day_key == day_key,
                    DailyMissionRecord.player_id == player_id,
                )
            )
        }
        result: list[DailyMissionRecord] = []
        for definition in DAILY_MISSIONS:
            row = rows.get(definition.mission_id)
            if row is None:
                row = DailyMissionRecord(
                    day_key=day_key,
                    player_id=player_id,
                    mission_id=definition.mission_id,
                    progress=0,
                    target=definition.target,
                    completed_at=None,
                    claimed_at=None,
                    created_at=now,
                    updated_at=now,
                )
                session.add(row)
            result.append(row)
        session.flush()
        return result

    def _advance_daily_missions(
        self,
        session: Session,
        player_id: str,
        day: date,
        outcome: Outcome,
        now: datetime,
    ) -> None:
        rows = self._ensure_daily_missions(
            session,
            player_id,
            day,
            now,
        )
        for row in rows:
            definition = self._daily_definition(row.mission_id)
            increment = 0
            if definition.metric == "matches_completed":
                increment = 1
            elif definition.metric == "wins" and outcome == "win":
                increment = 1
            row.progress = min(row.target, row.progress + increment)
            if row.progress >= row.target and row.completed_at is None:
                row.completed_at = now
            row.updated_at = now

    def _sync_achievements(
        self,
        session: Session,
        record: PlayerProgressionRecord,
        now: datetime,
    ) -> list[PlayerAchievementRecord]:
        rating = session.get(PlayerRatingRecord, record.player_id)
        level, _, _ = level_progress(record.total_xp)
        values = {
            "matches_completed": record.matches_completed,
            "wins": record.wins,
            "level": level,
            "rating": rating.rating if rating is not None else 1000,
        }
        rows = {
            row.achievement_id: row
            for row in session.scalars(
                select(PlayerAchievementRecord).where(
                    PlayerAchievementRecord.player_id == record.player_id
                )
            )
        }
        result: list[PlayerAchievementRecord] = []
        for definition in ACHIEVEMENTS:
            progress = min(
                definition.target,
                int(values.get(definition.metric, 0)),
            )
            row = rows.get(definition.achievement_id)
            if row is None:
                row = PlayerAchievementRecord(
                    player_id=record.player_id,
                    achievement_id=definition.achievement_id,
                    progress=progress,
                    target=definition.target,
                    unlocked_at=(now if progress >= definition.target else None),
                    claimed_at=None,
                    created_at=now,
                    updated_at=now,
                )
                session.add(row)
            else:
                row.progress = progress
                row.target = definition.target
                if progress >= definition.target and row.unlocked_at is None:
                    row.unlocked_at = now
                row.updated_at = now
            result.append(row)
        session.flush()
        return result

    def _profile(self, record: PlayerProgressionRecord) -> ProgressionProfile:
        level, xp_into_level, xp_for_next = level_progress(record.total_xp)
        return ProgressionProfile(
            player_id=record.player_id,
            total_xp=record.total_xp,
            level=level,
            xp_into_level=xp_into_level,
            xp_for_next_level=xp_for_next,
            credits=record.credits,
            matches_completed=record.matches_completed,
            wins=record.wins,
            draws=record.draws,
            losses=record.losses,
        )

    @staticmethod
    def _requester_outcome(match: StoredMatch) -> Outcome:
        winner = match.result.get("winner")
        if winner is None:
            return "draw"
        if winner == "left":
            return "win"
        if winner == "right":
            return "loss"
        raise ValueError(f"Bilinmeyen savaş kazananı: {winner}")

    @staticmethod
    def _grant(record: RewardGrantRecord) -> RewardGrant:
        return RewardGrant(
            source_type=record.source_type,
            source_id=record.source_id,
            reason=record.reason,
            xp=record.xp,
            credits=record.credits,
            level_before=record.level_before,
            level_after=record.level_after,
            total_xp_after=record.total_xp_after,
            credits_after=record.credits_after,
            granted_at=_as_utc(record.granted_at),
        )

    def _daily_mission(self, record: DailyMissionRecord) -> DailyMission:
        definition = self._daily_definition(record.mission_id)
        return DailyMission(
            mission_id=record.mission_id,
            title=definition.title,
            description=definition.description,
            progress=record.progress,
            target=record.target,
            completed=record.completed_at is not None,
            claimed=record.claimed_at is not None,
            reward_xp=definition.reward_xp,
            reward_credits=definition.reward_credits,
        )

    def _achievement(self, record: PlayerAchievementRecord) -> Achievement:
        definition = self._achievement_definition(record.achievement_id)
        return Achievement(
            achievement_id=record.achievement_id,
            title=definition.title,
            description=definition.description,
            progress=record.progress,
            target=record.target,
            unlocked=record.unlocked_at is not None,
            claimed=record.claimed_at is not None,
            reward_xp=definition.reward_xp,
            reward_credits=definition.reward_credits,
        )

    @staticmethod
    def _boosters(level: int) -> tuple[BoosterMastery, ...]:
        tier = booster_tier_for_level(level)
        next_tier_level = tier * 10 if tier < 5 else None
        values: list[BoosterMastery] = []
        for definition in BOOSTERS:
            unlocked = level >= definition.unlock_level
            value = definition.effect_values[tier - 1] if unlocked else 0
            values.append(
                BoosterMastery(
                    booster_id=definition.booster_id,
                    display_name=definition.display_name,
                    description=definition.description,
                    unlock_level=definition.unlock_level,
                    unlocked=unlocked,
                    tier=tier if unlocked else 0,
                    effect_value=value,
                    effect_label=(
                        definition.effect_template.format(value=value)
                        if unlocked
                        else f"Seviye {definition.unlock_level}'de açılır"
                    ),
                    next_tier_level=next_tier_level if unlocked else None,
                )
            )
        return tuple(values)

    @staticmethod
    def _existing_grant(
        session: Session,
        player_id: str,
        source_type: str,
        source_id: str,
    ) -> RewardGrantRecord | None:
        return session.scalar(
            select(RewardGrantRecord).where(
                RewardGrantRecord.player_id == player_id,
                RewardGrantRecord.source_type == source_type,
                RewardGrantRecord.source_id == source_id,
            )
        )

    @staticmethod
    def _daily_definition(mission_id: str) -> DailyMissionDefinition:
        try:
            return next(
                mission for mission in DAILY_MISSIONS
                if mission.mission_id == mission_id
            )
        except StopIteration as exc:
            raise ProgressionError(
                "mission_not_found",
                "Günlük görev bulunamadı.",
                status_code=404,
            ) from exc

    @staticmethod
    def _achievement_definition(
        achievement_id: str,
    ) -> AchievementDefinition:
        try:
            return next(
                achievement for achievement in ACHIEVEMENTS
                if achievement.achievement_id == achievement_id
            )
        except StopIteration as exc:
            raise ProgressionError(
                "achievement_not_found",
                "Başarım bulunamadı.",
                status_code=404,
            ) from exc


def _as_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
