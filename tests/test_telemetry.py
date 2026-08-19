from __future__ import annotations

import unittest

from fastapi.testclient import TestClient
from sqlalchemy import func, select

from relay_api.app import create_app
from relay_api.config import Settings
from relay_api.database import Database
from relay_api.db_models import ProductEventRecord


class TelemetryApiTests(unittest.TestCase):
    def setUp(self) -> None:
        self.database = Database("sqlite+pysqlite:///:memory:")
        self.database.create_schema_for_tests()
        settings = Settings(
            database_url="sqlite+pysqlite:///:memory:",
            jwt_secret="telemetry-test-secret-with-at-least-32-characters",
        )
        self.client = TestClient(create_app(settings=settings, database=self.database))
        guest = self.client.post("/api/v1/auth/guest").json()
        self.headers = {
            "Authorization": f"Bearer {guest['tokens']['access_token']}"
        }

    def tearDown(self) -> None:
        self.client.close()
        self.database.dispose()

    def _payload(self, event_name: str = "mode_selected") -> dict:
        return {
            "events": [
                {
                    "event_id": "evt:test:0001",
                    "event_name": event_name,
                    "context": {"mode": "online", "module_count": 3},
                    "client_version": "0.8.23",
                    "occurred_at": "2026-08-13T12:00:00Z",
                }
            ]
        }

    def test_allowed_event_is_idempotently_persisted(self) -> None:
        first = self.client.post(
            "/api/v1/telemetry/events",
            headers=self.headers,
            json=self._payload(),
        )
        duplicate = self.client.post(
            "/api/v1/telemetry/events",
            headers=self.headers,
            json=self._payload(),
        )

        self.assertEqual(first.status_code, 202, first.text)
        self.assertEqual(first.json(), {"accepted": 1, "duplicates": 0})
        self.assertEqual(duplicate.status_code, 202, duplicate.text)
        self.assertEqual(duplicate.json(), {"accepted": 0, "duplicates": 1})
        with self.database.session() as session:
            count = session.scalar(select(func.count(ProductEventRecord.id)))
        self.assertEqual(count, 1)

    def test_unknown_event_and_anonymous_request_are_rejected(self) -> None:
        anonymous = self.client.post(
            "/api/v1/telemetry/events",
            json=self._payload(),
        )
        unknown = self.client.post(
            "/api/v1/telemetry/events",
            headers=self.headers,
            json=self._payload("free_form_secret_dump"),
        )

        self.assertEqual(anonymous.status_code, 401)
        self.assertEqual(unknown.status_code, 422, unknown.text)
        self.assertEqual(unknown.json()["code"], "telemetry_event_not_allowed")


if __name__ == "__main__":
    unittest.main()
