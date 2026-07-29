from __future__ import annotations

from collections.abc import Iterator
from contextlib import contextmanager

from sqlalchemy import Engine, create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker
from sqlalchemy.pool import StaticPool


class Base(DeclarativeBase):
    pass


class Database:
    def __init__(self, url: str) -> None:
        self.url = url
        parsed = make_url(url)
        engine_options: dict[str, object] = {"pool_pre_ping": True}
        if parsed.get_backend_name() == "sqlite":
            engine_options["connect_args"] = {"check_same_thread": False}
            if parsed.database in {None, "", ":memory:"}:
                engine_options["poolclass"] = StaticPool
        self.engine: Engine = create_engine(url, **engine_options)
        self.session_factory = sessionmaker(
            bind=self.engine,
            class_=Session,
            expire_on_commit=False,
        )

    @property
    def storage_name(self) -> str:
        return make_url(self.url).get_backend_name()

    @contextmanager
    def session(self) -> Iterator[Session]:
        database_session = self.session_factory()
        try:
            yield database_session
            database_session.commit()
        except Exception:
            database_session.rollback()
            raise
        finally:
            database_session.close()

    def ping(self) -> bool:
        try:
            with self.engine.connect() as connection:
                connection.execute(text("SELECT 1"))
            return True
        except Exception:
            return False

    def create_schema_for_tests(self) -> None:
        from . import db_models  # noqa: F401

        Base.metadata.create_all(self.engine)

    def dispose(self) -> None:
        self.engine.dispose()
