from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from relay_engine import BoardLayout, Direction, ModuleKind, ModulePlacement


class ApiModel(BaseModel):
    model_config = ConfigDict(extra="forbid")


class ModulePlacementPayload(ApiModel):
    module_id: str = Field(min_length=1, max_length=64)
    kind: ModuleKind
    row: int = Field(ge=0, lt=4)
    column: int = Field(ge=0, lt=4)
    orientation: Direction = Direction.EAST
    level: int = Field(default=1, ge=1, le=3)

    @field_validator("module_id")
    @classmethod
    def module_id_must_not_be_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Modül kimliği boş olamaz.")
        return value

    def to_domain(self) -> ModulePlacement:
        return ModulePlacement(
            module_id=self.module_id,
            kind=self.kind,
            row=self.row,
            column=self.column,
            orientation=self.orientation,
            level=self.level,
        )


class BoardPayload(ApiModel):
    name: str = Field(default="Oyuncu Devresi", min_length=1, max_length=80)
    modules: list[ModulePlacementPayload] = Field(min_length=1, max_length=16)

    @field_validator("name")
    @classmethod
    def name_must_not_be_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Kart adı boş olamaz.")
        return value

    def to_domain(self) -> BoardLayout:
        return BoardLayout(
            name=self.name,
            modules=tuple(module.to_domain() for module in self.modules),
        )


class HealthResponse(ApiModel):
    status: str
    service: str
    version: str
    rules_version: str
    storage: str
    database: str


class BoardValidationResponse(ApiModel):
    valid: bool
    board_size: int
    module_count: int
    powered_module_ids: list[str]
    unpowered_module_ids: list[str]


class ModuleSpecResponse(ApiModel):
    kind: ModuleKind
    display_name: str
    description: str
    max_hp: float
    ports: list[Direction]
    energy_output: float
    battery_capacity: float
    energy_cost: float
    cooldown_ticks: int
    heat_per_action: float
    damage: float
    shield: float
    cooling: float
    repair: float
    threat: int


class ModuleCatalogResponse(ApiModel):
    rules_version: str
    modules: list[ModuleSpecResponse]


class BotResponse(ApiModel):
    bot_id: str
    display_name: str
    difficulty: str
    description: str
    available_module_counts: list[int]


class BotListResponse(ApiModel):
    bots: list[BotResponse]


class CreateBotMatchRequest(ApiModel):
    board: BoardPayload
    bot_id: str = Field(default="starter_laser", min_length=1, max_length=40)


class PlayerResponse(ApiModel):
    player_id: str
    display_name: str
    created_at: str


class TokenPairResponse(ApiModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    access_expires_in: int
    refresh_expires_in: int


class GuestSessionResponse(ApiModel):
    player: PlayerResponse
    tokens: TokenPairResponse


class RefreshSessionRequest(ApiModel):
    refresh_token: str = Field(min_length=32, max_length=4096)


class SavedBoardResponse(ApiModel):
    board_id: str
    fingerprint: str
    updated_at: str
    board: BoardPayload
    powered_module_ids: list[str]
    unpowered_module_ids: list[str]


class CurrentPlayerResponse(ApiModel):
    player: PlayerResponse
    board: SavedBoardResponse | None


class ModuleSummaryResponse(ApiModel):
    module_id: str
    kind: ModuleKind
    hp: float
    max_hp: float
    heat: float
    powered: bool
    overheated: bool


class BoardSummaryResponse(ApiModel):
    name: str
    core_hp: float
    core_max_hp: float
    shield: float
    energy_spent: float
    total_damage: float
    surviving_modules: int
    modules: list[ModuleSummaryResponse]


class DecisionMetricResponse(ApiModel):
    key: str
    left_value: float
    right_value: float
    preferred: str


class BattleDecisionResponse(ApiModel):
    criterion: str
    metrics: list[DecisionMetricResponse]


class BattleSummaryResponse(ApiModel):
    winner: str | None
    reason: str
    ticks: int
    seed: int
    left: BoardSummaryResponse
    right: BoardSummaryResponse
    decision: BattleDecisionResponse
    replay_checksum: str


class ReplayMetadataResponse(ApiModel):
    checksum: str
    event_count: int
    path: str


class MatchOpponentResponse(ApiModel):
    kind: str
    opponent_id: str
    display_name: str
    description: str


class RatingChangeResponse(ApiModel):
    outcome: str
    rating_before: int
    rating_after: int
    rating_delta: int
    week_key: str


class SeasonPointChangeResponse(ApiModel):
    season_key: str
    outcome: str
    points_gained: int
    total_points: int


class MatchResponse(ApiModel):
    match_id: str
    created_at: str
    source: str
    opponent: MatchOpponentResponse
    player_board: BoardPayload
    opponent_board: BoardPayload
    result: BattleSummaryResponse
    replay: ReplayMetadataResponse
    rating_change: RatingChangeResponse | None = None
    progression_reward: RewardGrantResponse | None = None
    season_change: SeasonPointChangeResponse | None = None


class BattleEventResponse(ApiModel):
    tick: int
    side: str
    type: str
    actor_id: str
    amount: float
    target_id: str | None = None
    detail: str | None = None


class ReplayModuleStateResponse(ApiModel):
    module_id: str
    hp: float
    max_hp: float
    heat: float
    cooldown: int
    powered: bool
    overheated: bool


class ReplayBoardStateResponse(ApiModel):
    core_hp: float
    shield: float
    energy_reserve: float
    energy_output: float
    energy_spent: float
    modules: list[ReplayModuleStateResponse]


class ReplayStateFrameResponse(ApiModel):
    tick: int
    left: ReplayBoardStateResponse
    right: ReplayBoardStateResponse


class ReplayResponse(ApiModel):
    match_id: str
    rules_version: str
    seed: int
    checksum: str
    events: list[BattleEventResponse]
    state_frames: list[ReplayStateFrameResponse]


class VerifyReplayRequest(ApiModel):
    match_id: str = Field(min_length=1, max_length=64)
    checksum: str = Field(min_length=64, max_length=64, pattern=r"^[0-9a-f]{64}$")


class VerifyReplayResponse(ApiModel):
    match_id: str
    valid: bool
    supplied_checksum: str
    actual_checksum: str


class RatingProfileResponse(ApiModel):
    player_id: str
    rating: int
    peak_rating: int
    rated_matches: int
    wins: int
    draws: int
    losses: int
    win_rate: float


class LeagueEntryResponse(ApiModel):
    week_key: str
    starts_at: str
    ends_at: str
    points: int
    wins: int
    draws: int
    losses: int
    position: int
    participant_count: int


class LeagueStandingResponse(ApiModel):
    position: int
    player_id: str
    display_name: str
    points: int
    wins: int
    draws: int
    losses: int
    rating: int
    is_current_player: bool


class MatchHistoryItemResponse(ApiModel):
    match_id: str
    created_at: str
    opponent_kind: str
    opponent_name: str
    outcome: str
    rated: bool
    rating_delta: int
    rating_after: int | None
    reason: str
    replay_path: str


class MatchmakingMetricsResponse(ApiModel):
    searches: int
    human_opponents: int
    bot_fallbacks: int
    human_opponent_rate: float


class CareerResponse(ApiModel):
    profile: RatingProfileResponse
    league: LeagueEntryResponse
    leaderboard: list[LeagueStandingResponse]
    recent_matches: list[MatchHistoryItemResponse]
    matchmaking: MatchmakingMetricsResponse


class MatchHistoryResponse(ApiModel):
    items: list[MatchHistoryItemResponse]
    total: int
    limit: int
    offset: int


class CurrentLeagueResponse(ApiModel):
    league: LeagueEntryResponse
    leaderboard: list[LeagueStandingResponse]


class ProgressionProfileResponse(ApiModel):
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


class DailyMissionResponse(ApiModel):
    mission_id: str
    title: str
    description: str
    progress: int
    target: int
    completed: bool
    claimed: bool
    reward_xp: int
    reward_credits: int


class AchievementResponse(ApiModel):
    achievement_id: str
    title: str
    description: str
    progress: int
    target: int
    unlocked: bool
    claimed: bool
    reward_xp: int
    reward_credits: int


class BoosterMasteryResponse(ApiModel):
    booster_id: str
    display_name: str
    description: str
    unlock_level: int
    unlocked: bool
    tier: int
    effect_value: int
    effect_label: str
    next_tier_level: int | None


class RewardGrantResponse(ApiModel):
    source_type: str
    source_id: str
    reason: str
    xp: int
    credits: int
    level_before: int
    level_after: int
    level_up: bool
    total_xp_after: int
    credits_after: int
    granted_at: str


class ProgressionResponse(ApiModel):
    day_key: str
    profile: ProgressionProfileResponse
    daily_missions: list[DailyMissionResponse]
    achievements: list[AchievementResponse]
    boosters: list[BoosterMasteryResponse]


class ClaimRewardResponse(ApiModel):
    reward: RewardGrantResponse


class ErrorResponse(ApiModel):
    code: str
    message: str
    details: list[dict[str, Any]] | None = None


class CareerBoosterChoiceResponse(ApiModel):
    booster_id: str
    display_name: str
    description: str
    tier: int
    effect_value: int
    effect_label: str
    credit_cost: int


class CareerOpponentPreviewResponse(ApiModel):
    stage_number: int
    total_stages: int
    title: str
    briefing: str
    is_boss: bool
    opponent_id: str
    display_name: str
    description: str
    board: BoardPayload


class CareerRunResponse(ApiModel):
    run_id: str | None
    status: str
    stage_index: int
    total_stages: int
    wins: int
    selected_boosters: list[CareerBoosterChoiceResponse]
    offered_boosters: list[CareerBoosterChoiceResponse]
    opponent: CareerOpponentPreviewResponse | None
    last_match_id: str | None
    reward: RewardGrantResponse | None
    board_required: bool
    can_battle: bool
    can_choose_booster: bool
    started_at: str | None
    ended_at: str | None


class CareerBoosterSelectionRequest(ApiModel):
    booster_id: str = Field(min_length=1, max_length=40)


class CareerBattleResponse(ApiModel):
    match: MatchResponse
    run: CareerRunResponse


class ControlledKitResponse(ApiModel):
    name: str
    module_kinds: list[ModuleKind]
    updated_at: str


class CosmeticItemResponse(ApiModel):
    cosmetic_id: str
    category: str
    display_name: str
    description: str
    credit_cost: int
    accent_hex: str
    owned: bool
    equipped: bool


class CollectionResponse(ApiModel):
    player_id: str
    credits: int
    cosmetics: list[CosmeticItemResponse]
    kit: ControlledKitResponse
    kits: dict[str, ControlledKitResponse]
    equipped_module_skin_id: str
    equipped_board_theme_id: str
    equipped_profile_frame_id: str


class SaveControlledKitRequest(ApiModel):
    mode: Literal["online", "training", "career"] = "online"
    name: str = Field(min_length=1, max_length=40)
    module_kinds: list[ModuleKind] = Field(min_length=8, max_length=8)


class EquipCosmeticRequest(ApiModel):
    cosmetic_id: str = Field(min_length=1, max_length=48)


class SeasonWindowResponse(ApiModel):
    season_key: str
    title: str
    starts_at: str
    ends_at: str


class SeasonEntryResponse(ApiModel):
    points: int
    matches: int
    wins: int
    draws: int
    losses: int
    position: int
    participant_count: int
    claimed_tiers: list[int]


class SeasonTierResponse(ApiModel):
    tier: int
    title: str
    required_points: int
    reward_xp: int
    reward_credits: int
    unlocked: bool
    claimed: bool


class SeasonStandingResponse(ApiModel):
    position: int
    player_id: str
    display_name: str
    points: int
    wins: int
    matches: int
    is_current_player: bool


class SeasonResponse(ApiModel):
    season: SeasonWindowResponse
    entry: SeasonEntryResponse
    tiers: list[SeasonTierResponse]
    leaderboard: list[SeasonStandingResponse]


class AlphaSafetyResponse(ApiModel):
    match_requests: int
    match_limit: int
    match_window_seconds: int
    feedback_requests: int
    feedback_limit: int
    feedback_window_seconds: int
    blocked_until: str | None
    server_authoritative_results: bool
    idempotent_rewards: bool
    board_validation: bool


class AlphaFeedbackRequest(ApiModel):
    category: Literal["denge", "hata", "arayuz", "diger"]
    message: str = Field(min_length=3, max_length=1200)
    client_version: str = Field(default="0.8.4", min_length=1, max_length=24)


class AlphaFeedbackResponse(ApiModel):
    feedback_id: str
    category: str
    created_at: str


class SocialPlayerResponse(ApiModel):
    player_id: str
    display_name: str
    status_message: str
    favorite_module: str
    relationship: str


class FriendRequestResponse(ApiModel):
    request_id: str
    player: SocialPlayerResponse
    created_at: str


class SocialProfileResponse(ApiModel):
    player_id: str
    display_name: str
    status_message: str
    favorite_module: str
    friend_count: int


class ClanMemberResponse(ApiModel):
    player_id: str
    display_name: str
    role: str
    joined_at: str
    is_current_player: bool


class ClanResponse(ApiModel):
    clan_id: str
    name: str
    tag: str
    description: str
    leader_player_id: str
    is_open: bool
    member_count: int
    members: list[ClanMemberResponse]


class SocialSnapshotResponse(ApiModel):
    profile: SocialProfileResponse
    incoming_requests: list[FriendRequestResponse]
    outgoing_requests: list[FriendRequestResponse]
    friends: list[SocialPlayerResponse]
    clan: ClanResponse | None


class SocialSearchResponse(ApiModel):
    players: list[SocialPlayerResponse]


class ClanListResponse(ApiModel):
    clans: list[ClanResponse]


class UpdateSocialProfileRequest(ApiModel):
    status_message: str = Field(min_length=1, max_length=160)
    favorite_module: ModuleKind


class CreateClanRequest(ApiModel):
    name: str = Field(min_length=3, max_length=48)
    tag: str = Field(min_length=2, max_length=8)
    description: str = Field(min_length=3, max_length=240)
