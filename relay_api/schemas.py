from __future__ import annotations

from typing import Any

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


class MatchResponse(ApiModel):
    match_id: str
    created_at: str
    source: str
    opponent: MatchOpponentResponse
    player_board: BoardPayload
    opponent_board: BoardPayload
    result: BattleSummaryResponse
    replay: ReplayMetadataResponse


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


class ErrorResponse(ApiModel):
    code: str
    message: str
    details: list[dict[str, Any]] | None = None
