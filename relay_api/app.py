from __future__ import annotations

from typing import Any

from fastapi import (
    Depends,
    FastAPI,
    Query,
    Request,
    status,
)
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.exc import SQLAlchemyError

from relay_engine import compute_replay_checksum
from relay_engine.catalog import MODULE_SPECS

from .auth import AuthError, AuthService, GuestSession, PlayerView
from .alpha import AlphaSafetyError, AlphaSafetyService, AlphaSafetySnapshot
from .bots import BotDefinition, BotNotFoundError
from .collection import (
    CollectionError,
    CollectionService,
    CollectionSnapshot,
)
from .competitive import (
    CareerSnapshot,
    CompetitiveService,
    LeagueEntry,
    LeagueStanding,
    MatchHistoryItem,
    MatchHistoryPage,
    MatchRatingChange,
)
from .career import (
    CareerRunError,
    CareerRunService,
    CareerRunSnapshot,
)
from .config import Settings
from .database import Database
from .db_models import PlayerRecord
from .online import OnlinePlayError, OnlinePlayService, SavedBoard
from .progression import (
    ProgressionError,
    ProgressionService,
    ProgressionSnapshot,
    RewardGrant,
)
from .schemas import (
    BoardPayload,
    BoardValidationResponse,
    BotListResponse,
    BotResponse,
    AlphaFeedbackRequest,
    AlphaFeedbackResponse,
    AlphaSafetyResponse,
    CareerBattleResponse,
    CareerBoosterSelectionRequest,
    CareerResponse,
    CareerRunResponse,
    CollectionResponse,
    EquipCosmeticRequest,
    ClaimRewardResponse,
    CreateBotMatchRequest,
    CurrentLeagueResponse,
    CurrentPlayerResponse,
    ErrorResponse,
    GuestSessionResponse,
    HealthResponse,
    MatchHistoryResponse,
    MatchResponse,
    ProgressionResponse,
    ModuleCatalogResponse,
    ModuleSpecResponse,
    RefreshSessionRequest,
    ReplayResponse,
    SavedBoardResponse,
    SaveControlledKitRequest,
    SeasonResponse,
    ClanListResponse,
    CreateClanRequest,
    SocialSearchResponse,
    SocialSnapshotResponse,
    UpdateSocialProfileRequest,
    VerifyReplayRequest,
    VerifyReplayResponse,
)
from .season import (
    SeasonError,
    SeasonPointChange,
    SeasonService,
    SeasonSnapshot,
)
from .social import (
    ClanView,
    SocialError,
    SocialPlayer,
    SocialService,
    SocialSnapshot,
)
from .service import API_VERSION, RULES_VERSION, MatchService
from .store import (
    DatabaseMatchStore,
    MatchNotFoundError,
    StoredMatch,
)


def _bot_payload(bot: BotDefinition) -> dict[str, Any]:
    return {
        "bot_id": bot.bot_id,
        "display_name": bot.display_name,
        "difficulty": bot.difficulty,
        "description": bot.description,
        "available_module_counts": list(bot.available_module_counts),
    }


def _swap_side(value: str | None) -> str | None:
    if value == "left":
        return "right"
    if value == "right":
        return "left"
    return value


def _perspective_result(
    match: StoredMatch,
    *,
    reverse: bool,
) -> dict[str, Any]:
    result = {
        key: value
        for key, value in match.result.items()
        if key not in {"events", "state_frames"}
    }
    if not reverse:
        return result
    result["winner"] = _swap_side(result.get("winner"))
    result["left"], result["right"] = result["right"], result["left"]
    decision = dict(result.get("decision", {}))
    decision["metrics"] = [
        {
            **metric,
            "left_value": metric.get("right_value"),
            "right_value": metric.get("left_value"),
        }
        for metric in decision.get("metrics", [])
    ]
    result["decision"] = decision
    return result


def _perspective_events(
    match: StoredMatch,
    *,
    reverse: bool,
) -> list[dict[str, Any]]:
    events = [dict(event) for event in match.result.get("events", [])]
    if not reverse:
        return events
    for event in events:
        event["side"] = _swap_side(str(event.get("side")))
    return events


def _perspective_frames(
    match: StoredMatch,
    *,
    reverse: bool,
) -> list[dict[str, Any]]:
    frames = [dict(frame) for frame in match.result.get("state_frames", [])]
    if not reverse:
        return frames
    return [
        {
            **frame,
            "left": frame["right"],
            "right": frame["left"],
        }
        for frame in frames
    ]


def _match_payload(
    match: StoredMatch,
    *,
    rating_change: MatchRatingChange | None = None,
    progression_reward: RewardGrant | None = None,
    season_change: SeasonPointChange | None = None,
    viewer_player_id: str | None = None,
    opponent_override: dict[str, str] | None = None,
) -> dict[str, Any]:
    reverse = (
        viewer_player_id is not None
        and viewer_player_id == match.opponent_player_id
    )
    result = _perspective_result(match, reverse=reverse)
    events = _perspective_events(match, reverse=reverse)
    checksum = (
        compute_replay_checksum(events)
        if reverse
        else str(match.result["replay_checksum"])
    )
    rating_payload = None
    if rating_change is not None and viewer_player_id is not None:
        rating_payload = {
            **rating_change.perspective(viewer_player_id),
            "week_key": rating_change.week_key,
        }
    opponent = opponent_override or {
        "kind": match.opponent.kind,
        "opponent_id": match.opponent.opponent_id,
        "display_name": match.opponent.display_name,
        "description": match.opponent.description,
    }
    return {
        "match_id": match.match_id,
        "created_at": match.created_at.isoformat(),
        "source": match.source,
        "opponent": opponent,
        "player_board": (
            match.opponent_board.to_dict()
            if reverse
            else match.player_board.to_dict()
        ),
        "opponent_board": (
            match.player_board.to_dict()
            if reverse
            else match.opponent_board.to_dict()
        ),
        "result": result,
        "replay": {
            "checksum": checksum,
            "event_count": len(events),
            "path": f"/api/v1/matches/{match.match_id}/replay",
        },
        "rating_change": rating_payload,
        "progression_reward": (
            _reward_payload(progression_reward)
            if progression_reward is not None
            else None
        ),
        "season_change": (
            {
                "season_key": season_change.season_key,
                "outcome": season_change.outcome,
                "points_gained": season_change.points_gained,
                "total_points": season_change.total_points,
            }
            if season_change is not None
            else None
        ),
    }


def _reward_payload(reward: RewardGrant) -> dict[str, Any]:
    return {
        "source_type": reward.source_type,
        "source_id": reward.source_id,
        "reason": reward.reason,
        "xp": reward.xp,
        "credits": reward.credits,
        "level_before": reward.level_before,
        "level_after": reward.level_after,
        "level_up": reward.level_up,
        "total_xp_after": reward.total_xp_after,
        "credits_after": reward.credits_after,
        "granted_at": reward.granted_at.isoformat(),
    }


def _progression_payload(snapshot: ProgressionSnapshot) -> dict[str, Any]:
    profile = snapshot.profile
    return {
        "day_key": snapshot.day_key,
        "profile": {
            "player_id": profile.player_id,
            "total_xp": profile.total_xp,
            "level": profile.level,
            "xp_into_level": profile.xp_into_level,
            "xp_for_next_level": profile.xp_for_next_level,
            "credits": profile.credits,
            "matches_completed": profile.matches_completed,
            "wins": profile.wins,
            "draws": profile.draws,
            "losses": profile.losses,
        },
        "daily_missions": [
            {
                "mission_id": item.mission_id,
                "title": item.title,
                "description": item.description,
                "progress": item.progress,
                "target": item.target,
                "completed": item.completed,
                "claimed": item.claimed,
                "reward_xp": item.reward_xp,
                "reward_credits": item.reward_credits,
            }
            for item in snapshot.daily_missions
        ],
        "achievements": [
            {
                "achievement_id": item.achievement_id,
                "title": item.title,
                "description": item.description,
                "progress": item.progress,
                "target": item.target,
                "unlocked": item.unlocked,
                "claimed": item.claimed,
                "reward_xp": item.reward_xp,
                "reward_credits": item.reward_credits,
            }
            for item in snapshot.achievements
        ],
        "boosters": [
            {
                "booster_id": item.booster_id,
                "display_name": item.display_name,
                "description": item.description,
                "unlock_level": item.unlock_level,
                "unlocked": item.unlocked,
                "tier": item.tier,
                "effect_value": item.effect_value,
                "effect_label": item.effect_label,
                "next_tier_level": item.next_tier_level,
            }
            for item in snapshot.boosters
        ],
    }


def _league_payload(entry: LeagueEntry) -> dict[str, Any]:
    return {
        "week_key": entry.week_key,
        "starts_at": entry.starts_at.isoformat(),
        "ends_at": entry.ends_at.isoformat(),
        "points": entry.points,
        "wins": entry.wins,
        "draws": entry.draws,
        "losses": entry.losses,
        "position": entry.position,
        "participant_count": entry.participant_count,
    }


def _standing_payload(standing: LeagueStanding) -> dict[str, Any]:
    return {
        "position": standing.position,
        "player_id": standing.player_id,
        "display_name": standing.display_name,
        "points": standing.points,
        "wins": standing.wins,
        "draws": standing.draws,
        "losses": standing.losses,
        "rating": standing.rating,
        "is_current_player": standing.is_current_player,
    }


def _history_item_payload(item: MatchHistoryItem) -> dict[str, Any]:
    return {
        "match_id": item.match_id,
        "created_at": item.created_at.isoformat(),
        "opponent_kind": item.opponent_kind,
        "opponent_name": item.opponent_name,
        "outcome": item.outcome,
        "rated": item.rated,
        "rating_delta": item.rating_delta,
        "rating_after": item.rating_after,
        "reason": item.reason,
        "replay_path": item.replay_path,
    }


def _career_payload(snapshot: CareerSnapshot) -> dict[str, Any]:
    profile = snapshot.profile
    metrics = snapshot.matchmaking
    return {
        "profile": {
            "player_id": profile.player_id,
            "rating": profile.rating,
            "peak_rating": profile.peak_rating,
            "rated_matches": profile.rated_matches,
            "wins": profile.wins,
            "draws": profile.draws,
            "losses": profile.losses,
            "win_rate": profile.win_rate,
        },
        "league": _league_payload(snapshot.league),
        "leaderboard": [
            _standing_payload(standing) for standing in snapshot.leaderboard
        ],
        "recent_matches": [
            _history_item_payload(item) for item in snapshot.recent_matches
        ],
        "matchmaking": {
            "searches": metrics.searches,
            "human_opponents": metrics.human_opponents,
            "bot_fallbacks": metrics.bot_fallbacks,
            "human_opponent_rate": metrics.human_opponent_rate,
        },
    }


def _career_run_payload(snapshot: CareerRunSnapshot) -> dict[str, Any]:
    def booster_payload(item):
        return {
            "booster_id": item.booster_id,
            "display_name": item.display_name,
            "description": item.description,
            "tier": item.tier,
            "effect_value": item.effect_value,
            "effect_label": item.effect_label,
            "credit_cost": item.credit_cost,
        }

    opponent = None
    if snapshot.opponent is not None:
        item = snapshot.opponent
        opponent = {
            "stage_number": item.stage_number,
            "total_stages": item.total_stages,
            "title": item.title,
            "briefing": item.briefing,
            "is_boss": item.is_boss,
            "opponent_id": item.opponent_id,
            "display_name": item.display_name,
            "description": item.description,
            "board": item.board.to_dict(),
        }
    return {
        "run_id": snapshot.run_id,
        "status": snapshot.status,
        "stage_index": snapshot.stage_index,
        "total_stages": snapshot.total_stages,
        "wins": snapshot.wins,
        "selected_boosters": [
            booster_payload(item) for item in snapshot.selected_boosters
        ],
        "offered_boosters": [
            booster_payload(item) for item in snapshot.offered_boosters
        ],
        "opponent": opponent,
        "last_match_id": snapshot.last_match_id,
        "reward": (
            _reward_payload(snapshot.reward)
            if snapshot.reward is not None
            else None
        ),
        "board_required": snapshot.board_required,
        "can_battle": snapshot.can_battle,
        "can_choose_booster": snapshot.can_choose_booster,
        "started_at": (
            snapshot.started_at.isoformat()
            if snapshot.started_at is not None
            else None
        ),
        "ended_at": (
            snapshot.ended_at.isoformat()
            if snapshot.ended_at is not None
            else None
        ),
    }



def _season_payload(snapshot: SeasonSnapshot) -> dict[str, Any]:
    return {
        "season": {
            "season_key": snapshot.window.key,
            "title": snapshot.window.title,
            "starts_at": snapshot.window.starts_at.isoformat(),
            "ends_at": snapshot.window.ends_at.isoformat(),
        },
        "entry": {
            "points": snapshot.entry.points,
            "matches": snapshot.entry.matches,
            "wins": snapshot.entry.wins,
            "draws": snapshot.entry.draws,
            "losses": snapshot.entry.losses,
            "position": snapshot.entry.position,
            "participant_count": snapshot.entry.participant_count,
            "claimed_tiers": list(snapshot.entry.claimed_tiers),
        },
        "tiers": [
            {
                "tier": item.tier,
                "title": item.title,
                "required_points": item.required_points,
                "reward_xp": item.reward_xp,
                "reward_credits": item.reward_credits,
                "unlocked": item.unlocked,
                "claimed": item.claimed,
            }
            for item in snapshot.tiers
        ],
        "leaderboard": [
            {
                "position": item.position,
                "player_id": item.player_id,
                "display_name": item.display_name,
                "points": item.points,
                "wins": item.wins,
                "matches": item.matches,
                "is_current_player": item.is_current_player,
            }
            for item in snapshot.leaderboard
        ],
    }


def _alpha_safety_payload(snapshot: AlphaSafetySnapshot) -> dict[str, Any]:
    return {
        "match_requests": snapshot.match_requests,
        "match_limit": snapshot.match_limit,
        "match_window_seconds": snapshot.match_window_seconds,
        "feedback_requests": snapshot.feedback_requests,
        "feedback_limit": snapshot.feedback_limit,
        "feedback_window_seconds": snapshot.feedback_window_seconds,
        "blocked_until": (
            snapshot.blocked_until.isoformat()
            if snapshot.blocked_until is not None
            else None
        ),
        "server_authoritative_results": snapshot.server_authoritative_results,
        "idempotent_rewards": snapshot.idempotent_rewards,
        "board_validation": snapshot.board_validation,
    }


def _collection_payload(snapshot: CollectionSnapshot) -> dict[str, Any]:
    return {
        "player_id": snapshot.player_id,
        "credits": snapshot.credits,
        "cosmetics": [
            {
                "cosmetic_id": item.cosmetic_id,
                "category": item.category,
                "display_name": item.display_name,
                "description": item.description,
                "credit_cost": item.credit_cost,
                "accent_hex": item.accent_hex,
                "owned": item.owned,
                "equipped": item.equipped,
            }
            for item in snapshot.cosmetics
        ],
        "kit": {
            "name": snapshot.kit.name,
            "module_kinds": [kind.value for kind in snapshot.kit.module_kinds],
            "updated_at": snapshot.kit.updated_at.isoformat(),
        },
        "equipped_module_skin_id": snapshot.equipped_module_skin_id,
        "equipped_board_theme_id": snapshot.equipped_board_theme_id,
        "equipped_profile_frame_id": snapshot.equipped_profile_frame_id,
    }

def _social_player_payload(player: SocialPlayer) -> dict[str, Any]:
    return {
        "player_id": player.player_id,
        "display_name": player.display_name,
        "status_message": player.status_message,
        "favorite_module": player.favorite_module,
        "relationship": player.relationship,
    }


def _clan_payload(clan: ClanView) -> dict[str, Any]:
    return {
        "clan_id": clan.clan_id,
        "name": clan.name,
        "tag": clan.tag,
        "description": clan.description,
        "leader_player_id": clan.leader_player_id,
        "is_open": clan.is_open,
        "member_count": clan.member_count,
        "members": [
            {
                "player_id": item.player_id,
                "display_name": item.display_name,
                "role": item.role,
                "joined_at": item.joined_at.isoformat(),
                "is_current_player": item.is_current_player,
            }
            for item in clan.members
        ],
    }


def _social_payload(snapshot: SocialSnapshot) -> dict[str, Any]:
    return {
        "profile": {
            "player_id": snapshot.profile.player_id,
            "display_name": snapshot.profile.display_name,
            "status_message": snapshot.profile.status_message,
            "favorite_module": snapshot.profile.favorite_module,
            "friend_count": snapshot.profile.friend_count,
        },
        "incoming_requests": [
            {
                "request_id": item.request_id,
                "player": _social_player_payload(item.player),
                "created_at": item.created_at.isoformat(),
            }
            for item in snapshot.incoming_requests
        ],
        "outgoing_requests": [
            {
                "request_id": item.request_id,
                "player": _social_player_payload(item.player),
                "created_at": item.created_at.isoformat(),
            }
            for item in snapshot.outgoing_requests
        ],
        "friends": [_social_player_payload(item) for item in snapshot.friends],
        "clan": _clan_payload(snapshot.clan) if snapshot.clan is not None else None,
    }


def _history_payload(page: MatchHistoryPage) -> dict[str, Any]:
    return {
        "items": [_history_item_payload(item) for item in page.items],
        "total": page.total,
        "limit": page.limit,
        "offset": page.offset,
    }


def _session_payload(guest_session: GuestSession) -> dict[str, Any]:
    return {
        "player": _player_payload(guest_session.player),
        "tokens": {
            "access_token": guest_session.tokens.access_token,
            "refresh_token": guest_session.tokens.refresh_token,
            "token_type": "bearer",
            "access_expires_in": guest_session.tokens.access_expires_in,
            "refresh_expires_in": guest_session.tokens.refresh_expires_in,
        },
    }


def _player_payload(player: PlayerView) -> dict[str, Any]:
    return {
        "player_id": player.player_id,
        "display_name": player.display_name,
        "created_at": player.created_at.isoformat(),
    }


def _saved_board_payload(
    saved_board: SavedBoard,
    match_service: MatchService,
) -> dict[str, Any]:
    powered, unpowered = match_service.validate_board(saved_board.board)
    return {
        "board_id": saved_board.board_id,
        "fingerprint": saved_board.fingerprint,
        "updated_at": saved_board.updated_at.isoformat(),
        "board": saved_board.board.to_dict(),
        "powered_module_ids": powered,
        "unpowered_module_ids": unpowered,
    }


def create_app(
    service: MatchService | None = None,
    *,
    settings: Settings | None = None,
    database: Database | None = None,
    auth_service: AuthService | None = None,
    online_service: OnlinePlayService | None = None,
    competitive_service: CompetitiveService | None = None,
    progression_service: ProgressionService | None = None,
    career_service: CareerRunService | None = None,
    collection_service: CollectionService | None = None,
    season_service: SeasonService | None = None,
    alpha_safety_service: AlphaSafetyService | None = None,
    social_service: SocialService | None = None,
) -> FastAPI:
    resolved_settings = settings or Settings.from_environment()
    resolved_database = database or Database(
        resolved_settings.database_url
    )
    match_service = service or MatchService(
        store=DatabaseMatchStore(resolved_database)
    )
    resolved_auth = auth_service or AuthService(
        resolved_database,
        resolved_settings,
    )
    resolved_online = online_service or OnlinePlayService(
        resolved_database,
        match_service,
        resolved_settings,
    )
    resolved_competitive = competitive_service or CompetitiveService(
        resolved_database,
        clock=match_service.clock,
    )
    resolved_progression = progression_service or ProgressionService(
        resolved_database,
        clock=match_service.clock,
    )
    resolved_career = career_service or CareerRunService(
        resolved_database,
        match_service,
        resolved_online,
        resolved_progression,
    )
    resolved_collection = collection_service or CollectionService(
        resolved_database
    )
    resolved_season = season_service or SeasonService(
        resolved_database,
        resolved_progression,
        clock=match_service.clock,
    )
    resolved_alpha = alpha_safety_service or AlphaSafetyService(
        resolved_database
    )
    resolved_social = social_service or SocialService(resolved_database)
    bearer = HTTPBearer(auto_error=False)

    application = FastAPI(
        title="Project Relay API",
        version=API_VERSION,
        description=(
            "Project Relay v0.8.4 profil, klan ve doğrudan kariyer hazırlığı düzeni; sosyal yapı ve klan temeli API'si. "
            "Arkadaşlık istekleri, oyuncu profilleri, açık klan keşfi ve "
            "sunucu yetkili üyelik kuralları birlikte doğrulanır."
        ),
    )
    application.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type"],
    )
    application.state.match_service = match_service
    application.state.database = resolved_database
    application.state.auth_service = resolved_auth
    application.state.online_service = resolved_online
    application.state.competitive_service = resolved_competitive
    application.state.progression_service = resolved_progression
    application.state.career_service = resolved_career
    application.state.collection_service = resolved_collection
    application.state.season_service = resolved_season
    application.state.alpha_safety_service = resolved_alpha
    application.state.social_service = resolved_social

    def current_player(
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    ) -> PlayerView:
        if credentials is None:
            raise AuthError(
                "authorization_required",
                "Bu işlem için misafir oturumu gereklidir.",
            )
        return resolved_auth.authenticate_access(credentials.credentials)

    def authorized_match(
        match_id: str,
        credentials: HTTPAuthorizationCredentials | None,
    ) -> tuple[StoredMatch, str | None]:
        match = match_service.get_match(match_id)
        allowed_players = {
            value
            for value in (
                match.requester_player_id,
                match.opponent_player_id,
            )
            if value is not None
        }
        if not allowed_players:
            return match, None
        if credentials is None:
            raise AuthError(
                "authorization_required",
                "Bu maçı görüntülemek için oturum gereklidir.",
            )
        player = resolved_auth.authenticate_access(credentials.credentials)
        if player.player_id not in allowed_players:
            raise AuthError(
                "match_access_denied",
                "Bu maç başka bir oyuncuya aittir.",
                status_code=403,
            )
        return match, player.player_id

    def opponent_for_viewer(
        match: StoredMatch,
        viewer_player_id: str | None,
    ) -> dict[str, str] | None:
        if (
            viewer_player_id is None
            or viewer_player_id != match.opponent_player_id
            or match.requester_player_id is None
        ):
            return None
        with resolved_database.session() as session:
            requester = session.get(PlayerRecord, match.requester_player_id)
            display_name = (
                requester.display_name
                if requester is not None
                else "Bilinmeyen Oyuncu"
            )
        return {
            "kind": "player",
            "opponent_id": match.requester_player_id,
            "display_name": display_name,
            "description": "Kayıtlı gerçek oyuncu devresi.",
        }

    @application.exception_handler(RequestValidationError)
    async def request_validation_handler(
        _request: Request,
        exc: RequestValidationError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content={
                "code": "request_validation_failed",
                "message": "İstek alanları geçersiz.",
                "details": jsonable_encoder(exc.errors()),
            },
        )

    @application.exception_handler(ValueError)
    async def domain_validation_handler(
        _request: Request,
        exc: ValueError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            content={
                "code": "board_validation_failed",
                "message": str(exc),
                "details": None,
            },
        )

    @application.exception_handler(AuthError)
    async def auth_error_handler(
        _request: Request,
        exc: AuthError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(OnlinePlayError)
    async def online_error_handler(
        _request: Request,
        exc: OnlinePlayError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(ProgressionError)
    async def progression_error_handler(
        _request: Request,
        exc: ProgressionError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={"code": exc.code, "message": exc.message},
        )

    @application.exception_handler(CollectionError)
    async def collection_error_handler(
        _request: Request,
        exc: CollectionError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(CareerRunError)
    async def career_error_handler(
        _request: Request,
        exc: CareerRunError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(SeasonError)
    async def season_error_handler(
        _request: Request,
        exc: SeasonError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(AlphaSafetyError)
    async def alpha_safety_error_handler(
        _request: Request,
        exc: AlphaSafetyError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(SocialError)
    async def social_error_handler(
        _request: Request,
        exc: SocialError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "code": exc.code,
                "message": exc.message,
                "details": None,
            },
        )

    @application.exception_handler(BotNotFoundError)
    async def bot_not_found_handler(
        _request: Request,
        exc: BotNotFoundError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={
                "code": "bot_not_found",
                "message": str(exc),
                "details": None,
            },
        )

    @application.exception_handler(MatchNotFoundError)
    async def match_not_found_handler(
        _request: Request,
        exc: MatchNotFoundError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={
                "code": "match_not_found",
                "message": str(exc),
                "details": None,
            },
        )

    @application.exception_handler(SQLAlchemyError)
    async def database_error_handler(
        _request: Request,
        _exc: SQLAlchemyError,
    ) -> JSONResponse:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "code": "database_unavailable",
                "message": "Kalıcı oyun veritabanına ulaşılamadı.",
                "details": None,
            },
        )

    @application.get(
        "/healthz",
        response_model=HealthResponse,
        tags=["system"],
    )
    def health() -> JSONResponse | dict[str, str]:
        database_ok = resolved_database.ping()
        payload = {
            "status": "ok" if database_ok else "degraded",
            "service": "project-relay-api",
            "version": API_VERSION,
            "rules_version": RULES_VERSION,
            "storage": resolved_database.storage_name,
            "database": "ok" if database_ok else "unavailable",
        }
        if not database_ok:
            return JSONResponse(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                content=payload,
            )
        return payload

    @application.post(
        "/api/v1/auth/guest",
        response_model=GuestSessionResponse,
        status_code=status.HTTP_201_CREATED,
        responses={503: {"model": ErrorResponse}},
        tags=["auth"],
    )
    def create_guest_session() -> dict[str, Any]:
        return _session_payload(resolved_auth.create_guest())

    @application.post(
        "/api/v1/auth/refresh",
        response_model=GuestSessionResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["auth"],
    )
    def refresh_guest_session(
        request: RefreshSessionRequest,
    ) -> dict[str, Any]:
        return _session_payload(
            resolved_auth.refresh(request.refresh_token)
        )

    @application.get(
        "/api/v1/me",
        response_model=CurrentPlayerResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["players"],
    )
    def get_current_player(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        board = resolved_online.get_board(player.player_id)
        return {
            "player": _player_payload(player),
            "board": (
                _saved_board_payload(board, match_service)
                if board is not None
                else None
            ),
        }

    @application.get(
        "/api/v1/me/career",
        response_model=CareerResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["competitive"],
    )
    def get_career(
        history_limit: int = Query(default=10, ge=1, le=50),
        leaderboard_limit: int = Query(default=20, ge=1, le=100),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _career_payload(
            resolved_competitive.career(
                player.player_id,
                history_limit=history_limit,
                leaderboard_limit=leaderboard_limit,
            )
        )

    @application.get(
        "/api/v1/me/statistics",
        response_model=CareerResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["competitive"],
    )
    def get_statistics(
        history_limit: int = Query(default=10, ge=1, le=50),
        leaderboard_limit: int = Query(default=20, ge=1, le=100),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _career_payload(
            resolved_competitive.career(
                player.player_id,
                history_limit=history_limit,
                leaderboard_limit=leaderboard_limit,
            )
        )

    @application.get(
        "/api/v1/me/progression",
        response_model=ProgressionResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["progression"],
    )
    def get_progression(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _progression_payload(
            resolved_progression.snapshot(player.player_id)
        )

    @application.post(
        "/api/v1/me/daily-missions/{mission_id}/claim",
        response_model=ClaimRewardResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["progression"],
    )
    def claim_daily_mission(
        mission_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return {
            "reward": _reward_payload(
                resolved_progression.claim_daily_mission(
                    player.player_id, mission_id
                )
            )
        }

    @application.post(
        "/api/v1/me/achievements/{achievement_id}/claim",
        response_model=ClaimRewardResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["progression"],
    )
    def claim_achievement(
        achievement_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return {
            "reward": _reward_payload(
                resolved_progression.claim_achievement(
                    player.player_id, achievement_id
                )
            )
        }

    @application.get(
        "/api/v1/me/career-run",
        response_model=CareerRunResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["career"],
    )
    def get_career_run(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _career_run_payload(resolved_career.current(player.player_id))

    @application.post(
        "/api/v1/me/career-run/start",
        response_model=CareerRunResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["career"],
    )
    def start_career_run(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _career_run_payload(resolved_career.start(player.player_id))

    @application.post(
        "/api/v1/me/career-run/booster",
        response_model=CareerRunResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["career"],
    )
    def choose_career_booster(
        request: CareerBoosterSelectionRequest,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _career_run_payload(
            resolved_career.select_booster(
                player.player_id, request.booster_id
            )
        )

    @application.post(
        "/api/v1/me/career-run/battle",
        response_model=CareerBattleResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["career"],
    )
    def battle_career_run(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        outcome = resolved_career.battle(player.player_id)
        return {
            "match": _match_payload(
                outcome.match, viewer_player_id=player.player_id
            ),
            "run": _career_run_payload(outcome.run),
        }

    @application.post(
        "/api/v1/me/career-run/abandon",
        response_model=CareerRunResponse,
        responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
        tags=["career"],
    )
    def abandon_career_run(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _career_run_payload(resolved_career.abandon(player.player_id))

    @application.get(
        "/api/v1/me/social",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["social"],
    )
    def get_social_snapshot(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(resolved_social.snapshot(player.player_id))

    @application.put(
        "/api/v1/me/social/profile",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["social"],
    )
    def update_social_profile(
        request: UpdateSocialProfileRequest,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(
            resolved_social.update_profile(
                player.player_id,
                status_message=request.status_message,
                favorite_module=request.favorite_module.value,
            )
        )

    @application.get(
        "/api/v1/social/players",
        response_model=SocialSearchResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["social"],
    )
    def search_social_players(
        query: str = Query(min_length=2, max_length=32),
        limit: int = Query(default=20, ge=1, le=30),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return {
            "players": [
                _social_player_payload(item)
                for item in resolved_social.search_players(
                    player.player_id, query, limit=limit
                )
            ]
        }

    @application.post(
        "/api/v1/me/friends/requests/{target_player_id}",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["social"],
    )
    def send_friend_request(
        target_player_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(
            resolved_social.send_friend_request(player.player_id, target_player_id)
        )

    @application.post(
        "/api/v1/me/friends/requests/{request_id}/accept",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
        tags=["social"],
    )
    def accept_friend_request(
        request_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(
            resolved_social.respond_friend_request(
                player.player_id, request_id, accept=True
            )
        )

    @application.post(
        "/api/v1/me/friends/requests/{request_id}/decline",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
        tags=["social"],
    )
    def decline_friend_request(
        request_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(
            resolved_social.respond_friend_request(
                player.player_id, request_id, accept=False
            )
        )

    @application.post(
        "/api/v1/me/friends/{friend_player_id}/remove",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}},
        tags=["social"],
    )
    def remove_friend(
        friend_player_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(
            resolved_social.remove_friend(player.player_id, friend_player_id)
        )

    @application.get(
        "/api/v1/clans",
        response_model=ClanListResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["clans"],
    )
    def list_clans(
        limit: int = Query(default=30, ge=1, le=50),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return {
            "clans": [
                _clan_payload(item)
                for item in resolved_social.list_clans(player.player_id, limit=limit)
            ]
        }

    @application.post(
        "/api/v1/clans",
        response_model=SocialSnapshotResponse,
        status_code=status.HTTP_201_CREATED,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["clans"],
    )
    def create_clan(
        request: CreateClanRequest,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(
            resolved_social.create_clan(
                player.player_id,
                name=request.name,
                tag=request.tag,
                description=request.description,
            )
        )

    @application.post(
        "/api/v1/clans/{clan_id}/join",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["clans"],
    )
    def join_clan(
        clan_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(resolved_social.join_clan(player.player_id, clan_id))

    @application.post(
        "/api/v1/me/clan/leave",
        response_model=SocialSnapshotResponse,
        responses={401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}},
        tags=["clans"],
    )
    def leave_clan(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _social_payload(resolved_social.leave_clan(player.player_id))

    @application.get(
        "/api/v1/me/matches",
        response_model=MatchHistoryResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["competitive"],
    )
    def get_match_history(
        limit: int = Query(default=20, ge=1, le=50),
        offset: int = Query(default=0, ge=0),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _history_payload(
            resolved_competitive.match_history(
                player.player_id,
                limit=limit,
                offset=offset,
            )
        )

    @application.get(
        "/api/v1/league/current",
        response_model=CurrentLeagueResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["competitive"],
    )
    def get_current_league(
        limit: int = Query(default=50, ge=1, le=100),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        league, leaderboard = resolved_competitive.current_league(
            player.player_id,
            limit=limit,
        )
        return {
            "league": _league_payload(league),
            "leaderboard": [
                _standing_payload(standing) for standing in leaderboard
            ],
        }

    @application.get(
        "/api/v1/me/season",
        response_model=SeasonResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["season"],
    )
    def get_current_season(
        limit: int = Query(default=20, ge=1, le=100),
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _season_payload(
            resolved_season.snapshot(player.player_id, limit=limit)
        )

    @application.post(
        "/api/v1/me/season/tiers/{tier}/claim",
        response_model=ClaimRewardResponse,
        responses={
            401: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
            409: {"model": ErrorResponse},
        },
        tags=["season"],
    )
    def claim_season_tier(
        tier: int,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return {
            "reward": _reward_payload(
                resolved_season.claim_tier(player.player_id, tier)
            )
        }

    @application.get(
        "/api/v1/me/alpha-safety",
        response_model=AlphaSafetyResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["alpha"],
    )
    def get_alpha_safety(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _alpha_safety_payload(
            resolved_alpha.snapshot(player.player_id)
        )

    @application.post(
        "/api/v1/alpha/feedback",
        response_model=AlphaFeedbackResponse,
        status_code=status.HTTP_201_CREATED,
        responses={
            401: {"model": ErrorResponse},
            422: {"model": ErrorResponse},
            429: {"model": ErrorResponse},
        },
        tags=["alpha"],
    )
    def submit_alpha_feedback(
        request: AlphaFeedbackRequest,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        receipt = resolved_alpha.submit_feedback(
            player.player_id,
            category=request.category,
            message=request.message,
            client_version=request.client_version,
        )
        return {
            "feedback_id": receipt.feedback_id,
            "category": receipt.category,
            "created_at": receipt.created_at.isoformat(),
        }

    @application.get(
        "/api/v1/me/collection",
        response_model=CollectionResponse,
        responses={401: {"model": ErrorResponse}},
        tags=["collection"],
    )
    def get_collection(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _collection_payload(
            resolved_collection.snapshot(player.player_id)
        )

    @application.post(
        "/api/v1/me/collection/cosmetics/{cosmetic_id}/purchase",
        response_model=CollectionResponse,
        responses={
            401: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
            409: {"model": ErrorResponse},
        },
        tags=["collection"],
    )
    def purchase_cosmetic(
        cosmetic_id: str,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _collection_payload(
            resolved_collection.purchase(player.player_id, cosmetic_id)
        )

    @application.put(
        "/api/v1/me/collection/equipped",
        response_model=CollectionResponse,
        responses={
            401: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
            409: {"model": ErrorResponse},
        },
        tags=["collection"],
    )
    def equip_cosmetic(
        request: EquipCosmeticRequest,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _collection_payload(
            resolved_collection.equip(
                player.player_id,
                request.cosmetic_id,
            )
        )

    @application.put(
        "/api/v1/me/kit",
        response_model=CollectionResponse,
        responses={
            401: {"model": ErrorResponse},
            409: {"model": ErrorResponse},
            422: {"model": ErrorResponse},
        },
        tags=["collection"],
    )
    def save_controlled_kit(
        request: SaveControlledKitRequest,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _collection_payload(
            resolved_collection.save_kit(
                player.player_id,
                name=request.name,
                module_kinds=request.module_kinds,
            )
        )

    @application.get(
        "/api/v1/me/career-board",
        response_model=SavedBoardResponse,
        responses={
            401: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
        },
        tags=["career"],
    )
    def get_career_board(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        saved = resolved_career.get_board(player.player_id)
        if saved is None:
            raise CareerRunError(
                "career_board_not_found",
                "Henüz kayıtlı bir kariyer devresi yok.",
                status_code=404,
            )
        return _saved_board_payload(saved, match_service)

    @application.put(
        "/api/v1/me/career-board",
        response_model=SavedBoardResponse,
        responses={
            401: {"model": ErrorResponse},
            409: {"model": ErrorResponse},
            422: {"model": ErrorResponse},
        },
        tags=["career"],
    )
    def save_career_board(
        board: BoardPayload,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        domain_board = board.to_domain()
        resolved_collection.validate_board(player.player_id, domain_board)
        saved = resolved_career.save_board(
            player.player_id,
            domain_board,
        )
        return _saved_board_payload(saved, match_service)

    @application.put(
        "/api/v1/me/board",
        response_model=SavedBoardResponse,
        responses={
            401: {"model": ErrorResponse},
            422: {"model": ErrorResponse},
        },
        tags=["boards"],
    )
    def save_current_board(
        board: BoardPayload,
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        domain_board = board.to_domain()
        resolved_collection.validate_board(player.player_id, domain_board)
        saved = resolved_online.save_board(
            player.player_id,
            domain_board,
        )
        return _saved_board_payload(saved, match_service)

    @application.get(
        "/api/v1/modules",
        response_model=ModuleCatalogResponse,
        tags=["catalog"],
    )
    def module_catalog() -> dict[str, Any]:
        modules = []
        for kind, spec in MODULE_SPECS.items():
            modules.append(
                ModuleSpecResponse(
                    kind=kind,
                    display_name=spec.display_name,
                    description=spec.description,
                    max_hp=spec.max_hp,
                    ports=sorted(spec.ports, key=lambda item: item.value),
                    energy_output=spec.energy_output,
                    battery_capacity=spec.battery_capacity,
                    energy_cost=spec.energy_cost,
                    cooldown_ticks=spec.cooldown_ticks,
                    heat_per_action=spec.heat_per_action,
                    damage=spec.damage,
                    shield=spec.shield,
                    cooling=spec.cooling,
                    repair=spec.repair,
                    threat=spec.threat,
                )
            )
        return {"rules_version": RULES_VERSION, "modules": modules}

    @application.get(
        "/api/v1/bots",
        response_model=BotListResponse,
        tags=["catalog"],
    )
    def bots() -> dict[str, Any]:
        return {"bots": [_bot_payload(bot) for bot in match_service.list_bots()]}

    @application.post(
        "/api/v1/boards/validate",
        response_model=BoardValidationResponse,
        responses={422: {"model": ErrorResponse}},
        tags=["boards"],
    )
    def validate_board(board: BoardPayload) -> dict[str, Any]:
        domain_board = board.to_domain()
        powered, unpowered = match_service.validate_board(domain_board)
        return {
            "valid": True,
            "board_size": match_service.engine.config.board_size,
            "module_count": len(domain_board.modules),
            "powered_module_ids": powered,
            "unpowered_module_ids": unpowered,
        }

    @application.post(
        "/api/v1/matches/bot",
        response_model=MatchResponse,
        status_code=status.HTTP_201_CREATED,
        responses={
            404: {"model": ErrorResponse},
            422: {"model": ErrorResponse},
        },
        tags=["matches"],
    )
    def create_bot_match(request: CreateBotMatchRequest) -> dict[str, Any]:
        match = match_service.create_bot_match(
            request.board.to_domain(),
            request.bot_id,
        )
        return _match_payload(match)

    @application.post(
        "/api/v1/matches/async",
        response_model=MatchResponse,
        status_code=status.HTTP_201_CREATED,
        responses={
            401: {"model": ErrorResponse},
            409: {"model": ErrorResponse},
            429: {"model": ErrorResponse},
        },
        tags=["matches"],
    )
    def create_async_match(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        resolved_alpha.guard_async_match(player.player_id)
        match = resolved_online.create_async_match(player.player_id)
        rating_change = resolved_competitive.apply_match(match)
        season_change = resolved_season.record_match(match)
        progression_reward = resolved_progression.apply_match(match)
        return _match_payload(
            match,
            rating_change=rating_change,
            progression_reward=progression_reward,
            season_change=season_change,
            viewer_player_id=player.player_id,
        )

    @application.get(
        "/api/v1/matches/{match_id}",
        response_model=MatchResponse,
        responses={
            401: {"model": ErrorResponse},
            403: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
        },
        tags=["matches"],
    )
    def get_match(
        match_id: str,
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    ) -> dict[str, Any]:
        match, viewer_player_id = authorized_match(match_id, credentials)
        return _match_payload(
            match,
            rating_change=resolved_competitive.get_match_rating(match_id),
            progression_reward=(
                resolved_progression.match_reward(match_id, viewer_player_id)
                if viewer_player_id is not None
                else None
            ),
            viewer_player_id=viewer_player_id,
            opponent_override=opponent_for_viewer(
                match,
                viewer_player_id,
            ),
        )

    @application.get(
        "/api/v1/matches/{match_id}/replay",
        response_model=ReplayResponse,
        response_model_exclude_none=True,
        responses={
            401: {"model": ErrorResponse},
            403: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
        },
        tags=["replays"],
    )
    def get_replay(
        match_id: str,
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    ) -> dict[str, Any]:
        match, viewer_player_id = authorized_match(match_id, credentials)
        reverse = (
            viewer_player_id is not None
            and viewer_player_id == match.opponent_player_id
        )
        events = _perspective_events(match, reverse=reverse)
        return {
            "match_id": match.match_id,
            "rules_version": RULES_VERSION,
            "seed": match.result["seed"],
            "checksum": (
                compute_replay_checksum(events)
                if reverse
                else match.result["replay_checksum"]
            ),
            "events": events,
            "state_frames": _perspective_frames(match, reverse=reverse),
        }

    @application.post(
        "/api/v1/replays/verify",
        response_model=VerifyReplayResponse,
        responses={
            401: {"model": ErrorResponse},
            403: {"model": ErrorResponse},
            404: {"model": ErrorResponse},
            422: {"model": ErrorResponse},
        },
        tags=["replays"],
    )
    def verify_replay(
        request: VerifyReplayRequest,
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer),
    ) -> dict[str, Any]:
        match, viewer_player_id = authorized_match(
            request.match_id,
            credentials,
        )
        if (
            viewer_player_id is not None
            and viewer_player_id == match.opponent_player_id
        ):
            actual = compute_replay_checksum(
                _perspective_events(match, reverse=True)
            )
            valid = actual == request.checksum
        else:
            valid, actual = match_service.verify_replay(
                request.match_id,
                request.checksum,
            )
        return {
            "match_id": request.match_id,
            "valid": valid,
            "supplied_checksum": request.checksum,
            "actual_checksum": actual,
        }

    return application


app = create_app()
