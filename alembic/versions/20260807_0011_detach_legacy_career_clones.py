"""detach legacy career boards cloned from async PvP

Revision ID: 20260807_0011
Revises: 20260806_0010
Create Date: 2026-08-07
"""

from collections.abc import Sequence

from alembic import op

revision: str = "20260807_0011"
down_revision: str | None = "20260806_0010"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    # v0.6.1-v0.8.13 kariyer devresi yoksa çevrimiçi devreyi bir kez kopyalıyordu.
    # Yalnız hâlâ çevrimiçi devreyle birebir aynı fingerprint taşıyan eski
    # kopyaları temizleyerek iki modun başlangıç durumunu kesin biçimde ayırırız.
    op.execute(
        """
        DELETE FROM career_boards AS cb
        USING boards AS b
        WHERE cb.player_id = b.player_id
          AND cb.fingerprint = b.fingerprint
        """
    )


def downgrade() -> None:
    # Silinen otomatik kopyaları güvenilir biçimde yeniden üretmek mümkün değil.
    pass
