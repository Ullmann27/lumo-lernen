"""Unit tests for the probe, not Android playback or adult identity evidence."""
import ast
import json
import math
from pathlib import Path
import re
import tempfile
import types
import unittest
from unittest.mock import Mock


SOURCE = Path(__file__).resolve().parents[2] / ".github/probes/lumo_speech_android_probe.py"
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"


def control(label, *, clickable=True, package=PACKAGE, enabled=True):
    return {
        "package": package,
        "text": "",
        "content-desc": label,
        "clickable": str(clickable).lower(),
        "enabled": str(enabled).lower(),
        "bounds": "[12,120][220,200]",
    }


class ParentNavigationTest(unittest.TestCase):
    def run_probe(self, frames):
        tree = ast.parse(SOURCE.read_text())
        # Execute the actual helpers without importing an emulator or reader.
        helpers = [node for node in tree.body if isinstance(node, ast.FunctionDef)
                   and node.name in ("_observed_parent_label",
                                     "_merged_profile_edit_visible", "parents")]
        self.reader = Mock(side_effect=frames)
        self.tap = Mock()
        self.ocr_tap = Mock()
        self.adb = Mock()
        self.capture = Mock()
        existing = types.SimpleNamespace(
            PACKAGE=PACKAGE,
            live=types.SimpleNamespace(live_nodes=self.reader),
            base=types.SimpleNamespace(adb=self.adb),
            flutter_tap=self.tap,
            capture=self.capture,
        )
        scope = {"existing": existing, "time": types.SimpleNamespace(sleep=Mock())}
        scope["_tap_merged_profile_edit"] = self.ocr_tap
        exec(compile(ast.Module(body=helpers, type_ignores=[]), str(SOURCE), "exec"), scope)
        return scope["parents"](Path("/unit-fixture"))

    def test_real_mobile_route_uses_profile_then_profile_edit(self):
        self.run_probe([
            [control("Start\nStart"), control("Profil\nProfil")],
            [control("Profil\nbearbeiten"), control("Profil\nProfil")],
            [control("Elternbereich", clickable=False)],
        ])
        self.assertEqual([call.args[1] for call in self.tap.call_args_list],
                         ["Profil", "Profil\nbearbeiten"])
        self.adb.assert_not_called()

    def test_edit_label_may_be_one_line(self):
        self.run_probe([
            [control("Profil bearbeiten")],
            [control("Elternbereich", clickable=False)],
        ])
        self.assertEqual(self.tap.call_args.args[1], "Profil bearbeiten")
        self.adb.assert_not_called()

    def test_existing_desktop_parent_control_remains_supported(self):
        self.run_probe([
            [control("Eltern")],
            [control("Elternbereich", clickable=False)],
        ])
        self.assertEqual(self.tap.call_args.args[1], "Eltern")

    def test_already_open_parent_page_needs_no_tap(self):
        self.run_probe([[control("Elternbereich", clickable=False)]])
        self.tap.assert_not_called()
        self.adb.assert_not_called()

    def test_parent_named_button_is_not_a_verified_parent_page(self):
        self.run_probe([
            [control("Elternbereich")],
            [control("Elternbereich", clickable=False)],
        ])
        self.tap.assert_called_once()

    def test_foreign_disabled_or_partial_labels_do_not_create_navigation(self):
        bad = [
            control("Profil", package="com.google.android.apps.nexuslauncher"),
            control("Profil bearbeiten", enabled=False),
            control("Profil einer anderen Person"),
        ]
        with self.assertRaisesRegex(RuntimeError, "parent navigation"):
            self.run_probe([bad] * 10)
        self.tap.assert_not_called()
        self.adb.assert_not_called()

    def test_pending_navigation_is_not_tapped_again(self):
        home = [control("Profil\nProfil")]
        self.run_probe([
            home, home,
            [control("Profil\nbearbeiten")],
            [control("Elternbereich", clickable=False)],
        ])
        self.assertEqual(self.tap.call_count, 2)
        self.adb.assert_not_called()

    def test_actual_android_merged_profile_card_uses_observed_caption_ocr(self):
        merged = control(
            "Level 1\n0\nEntdecker:in\nKlasse 1\n0 / 400 XP\n"
            "Profil\nbearbeiten\nLernprofi: 0 von 10\nSpieler:in: 0 von 1"
        )
        merged["bounds"] = "[0,831][1080,1678]"
        self.run_probe([
            [control("Profil\nProfil")],
            [merged, control("Profil\nProfil")],
            [control("Elternbereich", clickable=False)],
        ])
        self.assertEqual([call.args[1] for call in self.tap.call_args_list],
                         ["Profil"])
        self.ocr_tap.assert_called_once()
        self.assertEqual(self.ocr_tap.call_args.args[1], "parents-merged-edit-1")
        self.adb.assert_not_called()

    def test_merged_edit_ocr_requires_adjacent_actual_words(self):
        bad = [control("Level 1\nProfil\nanderes\nbearbeiten")]
        with self.assertRaisesRegex(RuntimeError, "parent navigation"):
            self.run_probe([bad] * 10)
        self.ocr_tap.assert_not_called()
        self.adb.assert_not_called()

    def test_foreign_or_hidden_merged_edit_never_uses_ocr(self):
        hidden = control("Level 1\nProfil\nbearbeiten")
        hidden["visible-to-user"] = "false"
        bad = [
            hidden,
            control("Level 1\nProfil\nbearbeiten",
                    package="com.google.android.apps.nexuslauncher"),
        ]
        with self.assertRaisesRegex(RuntimeError, "parent navigation"):
            self.run_probe([bad] * 10)
        self.ocr_tap.assert_not_called()
        self.tap.assert_not_called()
        self.adb.assert_not_called()


class MergedProfileTouchTest(unittest.TestCase):
    def run_touch(self, bounds):
        tree = ast.parse(SOURCE.read_text())
        helpers = [node for node in tree.body if isinstance(node, ast.FunctionDef)
                   and node.name in ("_merged_profile_edit_visible",
                                     "_tap_merged_profile_edit")]
        geometry_source = SOURCE.parents[2] / "tools/android_qa/native_surface_readiness.py"
        geometry = ast.parse(geometry_source.read_text())
        geometry_scope = {"math": math}
        exec(compile(ast.Module(body=[node for node in geometry.body
                                    if isinstance(node, ast.FunctionDef)
                                    and node.name == "target_observation"],
                                type_ignores=[]), str(geometry_source), "exec"),
             geometry_scope)
        card = control("Level 1\nProfil\nbearbeiten\nLernprofi: 0 von 10")
        card["bounds"] = "[0,831][1080,1678]"
        self.adb = Mock()
        self.reader = Mock(return_value=[card])
        self.ocr = Mock(return_value=[{"text": "bearbeiten", "bounds": bounds}])
        existing = types.SimpleNamespace(
            PACKAGE=PACKAGE,
            base=types.SimpleNamespace(foreground=Mock(return_value=PACKAGE),
                                       adb=self.adb),
            live=types.SimpleNamespace(live_nodes=self.reader),
            capture=Mock(return_value={"file": "actual-frame.png",
                                       "width": 1080, "height": 2400}),
            digest=Mock(return_value="mock-capture-digest"),
            normalized=lambda text: re.sub("[^a-z]", "", text.lower()),
            image_lines=self.ocr,
            target_observation=geometry_scope["target_observation"],
        )
        clock = types.SimpleNamespace(monotonic=__import__("time").monotonic,
                                      sleep=Mock())
        scope = {"existing": existing, "time": clock, "re": re, "json": json}
        exec(compile(ast.Module(body=helpers, type_ignores=[]), str(SOURCE), "exec"), scope)
        with tempfile.TemporaryDirectory() as tmp:
            try:
                return scope["_tap_merged_profile_edit"](Path(tmp), "unit-caption")
            finally:
                self.journal = json.loads(
                    (Path(tmp) / "unit-caption-observed-touch.json").read_text())

    def test_two_current_caption_reads_are_required_before_portrait_touch(self):
        # These are the OCR word bounds in the actual failed Android capture,
        # not a fabricated future runtime result. The device is mocked here.
        self.run_touch([707, 1191, 909, 1219])
        self.assertEqual(self.ocr.call_count, 2)
        self.assertEqual(self.reader.call_count, 2)
        self.assertIs(self.ocr.call_args.kwargs["exact"], True)
        self.adb.assert_called_once_with(
            "shell", "input", "swipe", "808", "1205", "808", "1205", "120")
        self.assertEqual(self.journal["status"], "TOUCH_SENT")
        self.assertFalse(self.journal["frames"][0]["target"]["stable_observed_target"])
        self.assertTrue(self.journal["frames"][1]["target"]["stable_observed_target"])

    def test_caption_outside_actual_card_never_creates_a_touch(self):
        with self.assertRaisesRegex(TimeoutError, "observed twice"):
            self.run_touch([1, 1, 40, 20])
        self.adb.assert_not_called()
        self.assertEqual(self.ocr.call_count, 6)
        self.assertEqual(self.journal["status"], "FAIL")


if __name__ == "__main__":
    unittest.main()
