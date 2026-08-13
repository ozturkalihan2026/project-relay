from __future__ import annotations

import unittest
from datetime import UTC, datetime

from relay_api.weekly_protocol import PROTOCOLS, weekly_protocol


class WeeklyProtocolTests(unittest.TestCase):
    def test_protocol_uses_iso_week_boundaries(self) -> None:
        protocol = weekly_protocol(datetime(2026, 8, 13, 18, 30, tzinfo=UTC))

        self.assertTrue(protocol.key.startswith("2026-W33:"))
        self.assertEqual(protocol.starts_at.weekday(), 0)
        self.assertEqual(protocol.starts_at.hour, 0)
        self.assertEqual(protocol.ends_at.weekday(), 0)
        self.assertEqual((protocol.ends_at - protocol.starts_at).days, 7)

    def test_rotation_is_deterministic_and_symmetric_safe(self) -> None:
        first = weekly_protocol(datetime(2026, 1, 5, tzinfo=UTC))
        repeated = weekly_protocol(datetime(2026, 1, 11, 23, 59, tzinfo=UTC))
        next_week = weekly_protocol(datetime(2026, 1, 12, tzinfo=UTC))

        self.assertEqual(first, repeated)
        self.assertNotEqual(first.definition.protocol_id, next_week.definition.protocol_id)
        self.assertGreaterEqual(len(PROTOCOLS), 4)
        self.assertNotEqual(first.definition.modifiers.to_dict(), {})


if __name__ == "__main__":
    unittest.main()
