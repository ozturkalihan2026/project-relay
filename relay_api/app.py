from __future__ import annotations

from typing import Any

from fastapi import (
    Depends,
    FastAPI,
    Request,
    status,
)
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.exc import SQLAlchemyError

from relay_engine.catalog import MODULE_SPECS

from .auth import AuthError, AuthService, GuestSession, PlayerView
from .bots import BotDefinition, BotNotFoundError
from .config import Settings
from .database import Database
from .online import OnlinePlayError, OnlinePlayService, SavedBoard
from .schemas import (
    BoardPayload,
    BoardValidationResponse,
    BotListResponse,
    BotResponse,
    CreateBotMatchRequest,
    CurrentPlayerResponse,
    ErrorResponse,
    GuestSessionResponse,
    HealthResponse,
    MatchResponse,
    ModuleCatalogResponse,
    ModuleSpecResponse,
    RefreshSessionRequest,
    ReplayResponse,
    SavedBoardResponse,
    VerifyReplayRequest,
    VerifyReplayResponse,
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


def _match_payload(match: StoredMatch) -> dict[str, Any]:
    result = {
        key: value
        for key, value in match.result.items()
        if key not in {"events", "state_frames"}
    }
    events = match.result.get("events", [])
    return {
        "match_id": match.match_id,
        "created_at": match.created_at.isoformat(),
        "source": match.source,
        "opponent": {
            "kind": match.opponent.kind,
            "opponent_id": match.opponent.opponent_id,
            "display_name": match.opponent.display_name,
            "description": match.opponent.description,
        },
        "player_board": match.player_board.to_dict(),
        "opponent_board": match.opponent_board.to_dict(),
        "result": result,
        "replay": {
            "checksum": match.result["replay_checksum"],
            "event_count": len(events),
            "path": f"/api/v1/matches/{match.match_id}/replay",
        },
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
    bearer = HTTPBearer(auto_error=False)

    application = FastAPI(
        title="Project Relay API",
        version=API_VERSION,
        description=(
            "Project Relay v0.4.7 kalıcı misafir oturumu, sunucu kartı ve "
            "asenkron oyuncu eşleştirmesi API'si. Bütün savaş sonuçları "
            "deterministik motor tarafından sunucuda hesaplanır."
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
    ) -> StoredMatch:
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
            return match
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
        return match

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
        saved = resolved_online.save_board(
            player.player_id,
            board.to_domain(),
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
        },
        tags=["matches"],
    )
    def create_async_match(
        player: PlayerView = Depends(current_player),
    ) -> dict[str, Any]:
        return _match_payload(
            resolved_online.create_async_match(player.player_id)
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
        return _match_payload(authorized_match(match_id, credentials))

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
        match = authorized_match(match_id, credentials)
        return {
            "match_id": match.match_id,
            "rules_version": RULES_VERSION,
            "seed": match.result["seed"],
            "checksum": match.result["replay_checksum"],
            "events": match.result.get("events", []),
            "state_frames": match.result.get("state_frames", []),
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
        authorized_match(request.match_id, credentials)
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
