"""Pure and filesystem-level tests for Cloud checkpoint safety boundaries."""
from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import tempfile
import unittest

MODULE_FILE = Path(__file__).resolve().parents[1] / "lumo_autosave.py"
spec = importlib.util.spec_from_file_location("lumo_autosave", MODULE_FILE)
assert spec and spec.loader
autosave = importlib.util.module_from_spec(spec)
spec.loader.exec_module(autosave)


class CheckpointSafetyTest(unittest.TestCase):
    def test_only_known_design_and_code_paths_are_allowed(self):
        for path in (
            "lib/features/home/lumo_home_hero.dart",
            "lib/theme/lumo_materials.dart",
            "lib/widgets/lumo_scene_atmosphere.dart",
            "assets/lumo_design/fox/pose.webp",
            "assets/kart/landing/hero.glb",
            "docs/design/STATUS.md",
            "test/lumo_render_test.dart",
            "tools/lumo_autosave.py",
            "AGENTS.md",
            "pubspec.yaml",
        ):
            with self.subTest(path=path):
                self.assertTrue(autosave.safe_path(path))
        for path in (
            "../external.dart",
            "/tmp/private.dart",
            "build/app/outputs/flutter.apk",
            ".dart_tool/cache/file.dart",
            "tools/debug.jks",
            "tools/lumo-debug.keystore",
            "android/local.properties",
            ".env",
            "config/service_account.json",
            "server/.env.prod",
            "data/medical.csv",
            "private/credential.json",
            "README.exe",
        ):
            with self.subTest(path=path):
                self.assertFalse(autosave.safe_path(path))

    def test_known_secret_patterns_are_not_uploaded(self):
        original = Path.cwd()
        with tempfile.TemporaryDirectory() as directory:
            try:
                os.chdir(directory)
                p = Path("lib/lumo.dart")
                p.parent.mkdir()
                p.write_text("final x = 'ok';")
                self.assertTrue(autosave.safe_content(str(p)))
                p.write_text("final key = 'sk-proj-" + "x" * 35 + "';")
                self.assertFalse(autosave.safe_content(str(p)))
                p.write_text("GROQ_API_KEY='gsk_" + "s" * 34 + "'")
                self.assertFalse(autosave.safe_content(str(p)))
                p.write_text("-----BEGIN PRIVATE KEY-----\nredacted\n")
                self.assertFalse(autosave.safe_content(str(p)))
            finally:
                os.chdir(original)

    def test_symlinks_and_oversized_assets_are_rejected(self):
        original = Path.cwd()
        with tempfile.TemporaryDirectory() as directory:
            try:
                os.chdir(directory)
                assets = Path("assets/lumo_design")
                assets.mkdir(parents=True)
                target = Path("private-file.txt")
                target.write_text("confidential")
                link = assets / "external.svg"
                link.symlink_to(target.resolve())
                self.assertFalse(autosave.safe_content(str(link)))
                large = assets / "enormous.png"
                with large.open("wb") as writer:
                    writer.truncate(autosave.MAX_FILE_BYTES + 1)
                self.assertFalse(autosave.safe_content(str(large)))
            finally:
                os.chdir(original)


if __name__ == "__main__":
    unittest.main()
