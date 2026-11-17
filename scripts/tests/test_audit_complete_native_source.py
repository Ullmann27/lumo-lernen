"""Regression tests for the full-content source gate; no fake APK."""
from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / "audit_complete_native_source.py"
spec = importlib.util.spec_from_file_location("native_asset_audit", MODULE)
assert spec is not None and spec.loader is not None
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class NativeSourceGateTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for item in audit.REQUIRED_CODE:
            path = self.root / item
            path.parent.mkdir(parents=True, exist_ok=True)
            if item.endswith("kart_island.gd"):
                content = 'const HOME = preload("res://scripts/games/kart_neon_hub.gd")\n'
            elif item.endswith("kart_jungle_environment.gd"):
                content = 'const V2 = preload("res://assets/kart/jungle_emerald_3600/detail_v2/dressing/jungle_dressing_v2.gd")\n'
            else:
                content = "extends Node3D\n"
            path.write_text(content)
        manifest = self.root / audit.R02_PREFIX / "manifest.json"
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(json.dumps({"vehicles": list(range(1, 11))}))
        for item in audit.R02_GLB_PATHS:
            path = self.root / item
            data = b"glTF" + (2).to_bytes(4, "little") + (20).to_bytes(4, "little") + b"12345678"
            path.write_bytes(data)

    def inspect(self):
        with patch.object(audit, "sha_at", return_value=audit.ARCHIVED_NATIVE_SHA):
            return audit.audit(self.root)

    def test_complete_fixture_is_source_ready_only_not_an_apk(self):
        r = self.inspect()
        self.assertTrue(r["source_ready_for_runtime_tests"])
        self.assertEqual(r["optimized_r02_models_verified"], 30)
        self.assertFalse(r["apk_created"])
        self.assertFalse(r["physical_fold7_tested"])

    def test_missing_one_optimized_model_blocks_full_content(self):
        (self.root / audit.R02_GLB_PATHS[-1]).unlink()
        r = self.inspect()
        self.assertFalse(r["source_ready_for_runtime_tests"])
        self.assertEqual(r["optimized_r02_models_verified"], 29)

    def test_renamed_neon_entry_blocks_full_content(self):
        path = self.root / "scripts/games/kart_island.gd"
        path.write_text("extends Node3D\n")
        r = self.inspect()
        self.assertFalse(r["source_ready_for_runtime_tests"])
        self.assertFalse(r["runtime_route_source_signals"]["kart_scene_loads_neon_hub"])

    def test_wrong_source_sha_blocks_full_content(self):
        with patch.object(audit, "sha_at", return_value="a" * 40):
            r = audit.audit(self.root)
        self.assertFalse(r["source_ready_for_runtime_tests"])
        self.assertFalse(r["native_source_identity_matched"])


if __name__ == "__main__":
    unittest.main()
