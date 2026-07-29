from __future__ import annotations

import unittest
from datetime import UTC, datetime, timedelta

from relay_api.auth import AuthError, JwtCodec


class JwtCodecTests(unittest.TestCase):
    def setUp(self) -> None:
        self.now = datetime(2026, 7, 29, 12, 0, tzinfo=UTC)
        self.codec = JwtCodec(
            secret="jwt-codec-test-secret-with-at-least-32-characters",
            issuer="project-relay-test",
            clock=lambda: self.now,
        )

    def test_signed_access_token_round_trip(self) -> None:
        token, expires_at = self.codec.encode(
            subject="player-1",
            token_type="access",
            jti="access-1",
            lifetime_seconds=900,
        )

        claims = self.codec.decode(token, expected_type="access")

        self.assertEqual(claims.subject, "player-1")
        self.assertEqual(claims.jti, "access-1")
        self.assertEqual(expires_at, self.now + timedelta(seconds=900))

    def test_tampered_signature_is_rejected(self) -> None:
        token, _ = self.codec.encode(
            subject="player-1",
            token_type="access",
            jti="access-1",
            lifetime_seconds=900,
        )
        header, payload, signature = token.split(".")
        changed = f"{'A' if signature[0] != 'A' else 'B'}{signature[1:]}"
        tampered = f"{header}.{payload}.{changed}"

        with self.assertRaises(AuthError) as raised:
            self.codec.decode(tampered, expected_type="access")

        self.assertEqual(raised.exception.code, "invalid_token")

    def test_expired_and_wrong_type_tokens_are_rejected(self) -> None:
        token, _ = self.codec.encode(
            subject="player-1",
            token_type="refresh",
            jti="refresh-1",
            lifetime_seconds=60,
        )

        with self.assertRaises(AuthError) as wrong_type:
            self.codec.decode(token, expected_type="access")
        self.assertEqual(wrong_type.exception.code, "wrong_token_type")

        self.now += timedelta(seconds=61)
        with self.assertRaises(AuthError) as expired:
            self.codec.decode(token, expected_type="refresh")
        self.assertEqual(expired.exception.code, "token_expired")


if __name__ == "__main__":
    unittest.main()
