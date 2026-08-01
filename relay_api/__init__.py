"""Project Relay HTTP API package.

The FastAPI application is loaded lazily so Alembic and lightweight domain
imports do not initialize the database engine as a side effect.
"""
from __future__ import annotations

from typing import Any

__all__ = ["app", "create_app"]


def __getattr__(name: str) -> Any:
    if name in {"app", "create_app"}:
        from .app import app, create_app

        return app if name == "app" else create_app
    raise AttributeError(name)
