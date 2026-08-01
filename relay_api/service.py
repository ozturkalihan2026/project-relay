from __future__ import annotations

import secrets
import uuid
from collections.abc import Callable
from datetime import UTC, datetime

from relay_engine import (
    BattleModifiers,
    BoardLayout,
    CircuitBattleEngine,
    compute_replay_checksum,
)

from .bots import BOTS, BotDefinition, get_bot
from .store import (
    InMemoryMatchStore,
    MatchStore,
    OpponentSnapshot,
    StoredMatch,
)


RULES_VERSION = "0.8"
API_VERSION = "0.8.0"


class MatchService:
    def __init__(
        self,
        *,
        engine: CircuitBattleEngine | None = None,
        store: MatchStore | None = None,
        seed_source: Callable[[], int] | None = None,
        id_source: Callable[[], str] | None = None,
        clock: Callable[[], datetime] | None = None,
    ) -> None:
        self.engine = engine or CircuitBattleEngine()
        self.store = store or InMemoryMatchStore()
        self.seed_source = seed_source or (lambda: secrets.randbits(63))
        self.id_source = id_source or (lambda: uuid.uuid4().hex)
        self.clock = clock or (lambda: datetime.now(UTC))

    def validate_board(self, board: BoardLayout) -> tuple[list[str], list[str]]:
        board.validate(self.engine.config.board_size)
        powered = self.engine.powered_module_ids(board)
        all_ids = {module.module_id for module in board.modules}
        return sorted(powered), sorted(all_ids - powered)

    def list_bots(self) -> list[BotDefinition]:
        return list(BOTS.values())

    def create_bot_match(self, board: BoardLayout, bot_id: str) -> StoredMatch:
        board.validate(self.engine.config.board_size)
        bot = get_bot(bot_id)
        opponent_board = bot.board_for_count(len(board.modules))
        return self.create_match(
            player_board=board,
            opponent_board=opponent_board,
            opponent=OpponentSnapshot(
                kind="bot",
                opponent_id=bot.bot_id,
                display_name=bot.display_name,
                description=bot.description,
            ),
            source="bot",
        )

    def create_match(
        self,
        *,
        player_board: BoardLayout,
        opponent_board: BoardLayout,
        opponent: OpponentSnapshot,
        source: str,
        requester_player_id: str | None = None,
        opponent_player_id: str | None = None,
        player_modifiers: BattleModifiers | None = None,
        opponent_modifiers: BattleModifiers | None = None,
    ) -> StoredMatch:
        player_board.validate(self.engine.config.board_size)
        opponent_board.validate(self.engine.config.board_size)
        if len(player_board.modules) != len(opponent_board.modules):
            raise ValueError(
                "Sunucu eşleştirmesi oyuncu ve rakip için eşit modül "
                "sayısı gerektirir."
            )
        seed = self.seed_source()
        result = self.engine.simulate(
            player_board,
            opponent_board,
            seed=seed,
            left_modifiers=player_modifiers,
            right_modifiers=opponent_modifiers,
        )
        match = StoredMatch(
            match_id=self.id_source(),
            created_at=self.clock(),
            source=source,
            requester_player_id=requester_player_id,
            opponent_player_id=opponent_player_id,
            opponent=opponent,
            player_board=player_board,
            opponent_board=opponent_board,
            result=result.to_dict(include_events=True),
        )
        self.store.save(match)
        return match

    def get_match(self, match_id: str) -> StoredMatch:
        return self.store.get(match_id)

    def verify_replay(self, match_id: str, checksum: str) -> tuple[bool, str]:
        match = self.store.get(match_id)
        actual = compute_replay_checksum(match.result["events"])
        return secrets.compare_digest(actual, checksum), actual
