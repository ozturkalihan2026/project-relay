from __future__ import annotations

import hashlib
import json
from collections.abc import Iterable, Mapping
from typing import Any

from .models import BattleEvent


def compute_replay_checksum(
    events: Iterable[BattleEvent | Mapping[str, Any]],
) -> str:
    """Return the canonical SHA-256 identity of a replay event stream."""
    payload = [
        event.to_dict() if isinstance(event, BattleEvent) else dict(event)
        for event in events
    ]
    encoded = json.dumps(
        payload,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()
