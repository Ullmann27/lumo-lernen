"""Regression for a newer source being packaged with an older workflow version."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "build_version", Path(__file__).resolve().parents[1] / "build_version.py"
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class BuildVersionTests(unittest.TestCase):
    def test_pubspec_is_the_default_version_source(self):
        self.assertEqual(module.resolve_version("name: app\nversion: 0.10.10+1602\n", {}),
                         ("0.10.10", 1602))

    def test_stale_visual_workflow_cannot_create_a_downgrade(self):
        with self.assertRaisesRegex(ValueError, "older than declared"):
            module.resolve_version("version: 0.10.10+1602\n", {"LUMO_BUILD_NUMBER": "1504"})

    def test_newer_explicit_build_remains_supported(self):
        self.assertEqual(module.resolve_version("version: 0.10.10+1602\n",
                                               {"LUMO_BUILD_NUMBER": "1603"}),
                         ("0.10.10", 1603))

    def test_malformed_version_is_rejected_before_building(self):
        with self.assertRaises(ValueError):
            module.resolve_version("version: 0.10.10\n", {})
