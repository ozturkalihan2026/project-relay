from __future__ import annotations

import io
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from alembic import command
from alembic.config import Config
from sqlalchemy import BigInteger, create_engine, inspect


class MigrationTests(unittest.TestCase):
    def test_initial_migration_compiles_for_postgresql(self) -> None:
        output = io.StringIO()
        config = Config("alembic.ini", output_buffer=output)
        with patch.dict(
            os.environ,
            {
                "RELAY_DATABASE_URL": (
                    "postgresql+psycopg://relay:relay@db:5432/project_relay"
                )
            },
        ):
            command.upgrade(config, "head", sql=True)

        sql = output.getvalue()
        self.assertIn("CREATE TABLE players", sql)
        self.assertIn("CREATE TABLE refresh_sessions", sql)
        self.assertIn("CREATE TABLE boards", sql)
        self.assertIn("CREATE TABLE matches", sql)
        self.assertIn("JSON", sql)
        self.assertIn("ALTER COLUMN seed TYPE BIGINT", sql)

    def test_initial_migration_creates_and_downgrades_online_schema(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as directory:
            database_path = Path(directory) / "migration-test.db"
            database_url = f"sqlite+pysqlite:///{database_path}"
            config = Config("alembic.ini")
            with patch.dict(
                os.environ,
                {"RELAY_DATABASE_URL": database_url},
            ):
                command.upgrade(config, "head")
                command.check(config)

            engine = create_engine(database_url)
            seed_column = next(
                column
                for column in inspect(engine).get_columns("matches")
                if column["name"] == "seed"
            )
            self.assertIsInstance(seed_column["type"], BigInteger)
            self.assertEqual(
                set(inspect(engine).get_table_names()),
                {
                    "alembic_version",
                    "boards",
                    "matches",
                    "players",
                    "refresh_sessions",
                },
            )
            engine.dispose()

            with patch.dict(
                os.environ,
                {"RELAY_DATABASE_URL": database_url},
            ):
                command.downgrade(config, "base")

            engine = create_engine(database_url)
            self.assertEqual(
                set(inspect(engine).get_table_names()),
                {"alembic_version"},
            )
            engine.dispose()


if __name__ == "__main__":
    unittest.main()
