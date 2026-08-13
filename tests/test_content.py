from __future__ import annotations

import copy
import json
import unittest
from importlib.resources import files
from pathlib import Path

from relay_api.content import CAREER_SECTORS, load_career_sectors
from relay_engine import ModuleKind
from relay_engine.catalog import MODULE_SPECS, load_module_specs


class DataDrivenContentTests(unittest.TestCase):
    def test_docker_image_bundles_content_before_install_and_migrates_first(self) -> None:
        dockerfile = (
            Path(__file__).resolve().parents[1] / "Dockerfile"
        ).read_text(encoding="utf-8")

        content_copy = "COPY relay_content ./relay_content"
        package_install = "RUN python -m pip install --no-cache-dir ."
        startup = "alembic upgrade head && exec uvicorn"
        self.assertIn(content_copy, dockerfile)
        self.assertLess(dockerfile.index(content_copy), dockerfile.index(package_install))
        self.assertIn(startup, dockerfile)

    def test_bundled_module_catalog_covers_every_engine_kind(self) -> None:
        self.assertEqual(set(MODULE_SPECS), set(ModuleKind))
        self.assertEqual(MODULE_SPECS[ModuleKind.GENERATOR].energy_output, 8)
        self.assertEqual(MODULE_SPECS[ModuleKind.PULSE_CANNON].damage, 16)

    def test_bundled_sector_has_five_ordered_stages_and_final_boss(self) -> None:
        sector = CAREER_SECTORS[0]

        self.assertEqual(sector.sector_id, "signal_threshold")
        self.assertEqual(
            [stage.stage_number for stage in sector.stages],
            [1, 2, 3, 4, 5],
        )
        self.assertTrue(sector.stages[-1].is_boss)
        self.assertTrue(sector.stages[0].guidance_text)

    def test_invalid_content_fails_fast_before_server_start(self) -> None:
        module_payload = json.loads(
            files("relay_content").joinpath("modules.json").read_text("utf-8")
        )
        module_payload["modules"] = module_payload["modules"][:-1]
        with self.assertRaises(RuntimeError):
            load_module_specs(module_payload)

        sector_payload = json.loads(
            files("relay_content").joinpath("sectors.json").read_text("utf-8")
        )
        invalid_sector = copy.deepcopy(sector_payload)
        invalid_sector["sectors"][0]["stages"][-1]["is_boss"] = False
        with self.assertRaises(RuntimeError):
            load_career_sectors(invalid_sector)


if __name__ == "__main__":
    unittest.main()
