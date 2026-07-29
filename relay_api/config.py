from __future__ import annotations

import os
from dataclasses import dataclass


DEFAULT_DATABASE_URL = (
    "postgresql+psycopg://relay:relay@127.0.0.1:5432/project_relay"
)
DEFAULT_JWT_SECRET = (
    "project-relay-local-development-secret-change-before-deployment"
)


@dataclass(frozen=True, slots=True)
class Settings:
    database_url: str = DEFAULT_DATABASE_URL
    jwt_secret: str = DEFAULT_JWT_SECRET
    jwt_issuer: str = "project-relay"
    access_token_seconds: int = 15 * 60
    refresh_token_seconds: int = 30 * 24 * 60 * 60
    recent_opponent_limit: int = 3

    def __post_init__(self) -> None:
        if len(self.jwt_secret) < 32:
            raise ValueError(
                "RELAY_JWT_SECRET en az 32 karakter olmalıdır."
            )
        if self.access_token_seconds <= 0:
            raise ValueError(
                "RELAY_ACCESS_TOKEN_SECONDS pozitif olmalıdır."
            )
        if self.refresh_token_seconds <= 0:
            raise ValueError(
                "RELAY_REFRESH_TOKEN_SECONDS pozitif olmalıdır."
            )
        if self.recent_opponent_limit < 0:
            raise ValueError(
                "RELAY_RECENT_OPPONENT_LIMIT negatif olamaz."
            )

    @classmethod
    def from_environment(cls) -> "Settings":
        return cls(
            database_url=os.getenv(
                "RELAY_DATABASE_URL",
                DEFAULT_DATABASE_URL,
            ),
            jwt_secret=os.getenv("RELAY_JWT_SECRET", DEFAULT_JWT_SECRET),
            jwt_issuer=os.getenv("RELAY_JWT_ISSUER", "project-relay"),
            access_token_seconds=int(
                os.getenv("RELAY_ACCESS_TOKEN_SECONDS", str(15 * 60))
            ),
            refresh_token_seconds=int(
                os.getenv(
                    "RELAY_REFRESH_TOKEN_SECONDS",
                    str(30 * 24 * 60 * 60),
                )
            ),
            recent_opponent_limit=int(
                os.getenv("RELAY_RECENT_OPPONENT_LIMIT", "3")
            ),
        )
