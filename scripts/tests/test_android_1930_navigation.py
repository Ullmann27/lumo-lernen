"""Actual saved hierarchy regressions, not a substitute for Android acceptance."""
import ast
from pathlib import Path
import re
import types
import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / ".github/probes/lumo_education_android_probe.py"
FIXTURE = ROOT / "scripts/tests/fixtures/android_1930_header_navigation.xml"
SCROLL_FIXTURE = ROOT / "scripts/tests/fixtures/android_1930_scroll_feedback.xml"
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"


def control(label, *, clickable=True, enabled=True, package=PACKAGE,
            bounds="[47,230][121,298]"):
    return {
        "package": package, "text": "", "content-desc": label,
        "clickable": str(clickable).lower(), "enabled": str(enabled).lower(),
        "bounds": bounds, "scrollable": "false",
    }


class CourseNavigationTest(unittest.TestCase):
    def setUp(self):
        helpers = [node for node in ast.parse(SOURCE.read_text()).body
                   if isinstance(node, ast.FunctionDef)
                   and node.name in ("_enabled_control_bounds", "_answer_accepted", "tap")]
        self.reader = Mock()
        self.adb = Mock()
        self.capture = Mock()
        existing = types.SimpleNamespace(
            PACKAGE=PACKAGE,
            live=types.SimpleNamespace(live_nodes=self.reader),
            base=types.SimpleNamespace(adb=self.adb),
            recover_launcher_dialog=Mock(return_value=False),
            capture=self.capture,
        )
        scope = {"existing": existing, "re": re, "Path": Path,
                 "time": types.SimpleNamespace(sleep=Mock())}
        exec(compile(ast.Module(body=helpers, type_ignores=[]), str(SOURCE), "exec"), scope)
        self.select = scope["_enabled_control_bounds"]
        self.accepted = scope["_answer_accepted"]
        self.tap = scope["tap"]

    def test_saved_real_android_hierarchy_selects_navigation_not_logo(self):
        nodes = [node.attrib for node in ET.parse(FIXTURE).iter("node")]
        self.assertEqual(self.select(nodes, "Lernen"), [47, 230, 121, 298])
        static = [n for n in nodes
                  if n.get("content-desc") == "Lernen" and n.get("clickable") == "false"]
        self.assertTrue(any(n["bounds"] == "[31,109][113,135]" for n in static))

    def test_second_wrong_tap_uses_actual_selected_answer_and_feedback(self):
        fixture = ROOT / 'scripts/tests/fixtures/android_1931_minus_wrong.xml'
        nodes = [node.attrib for node in ET.parse(fixture).iter('node')]
        function = next(node for node in ast.parse(SOURCE.read_text()).body
                        if isinstance(node, ast.FunctionDef) and node.name == 'subtraction_course')
        calls = [node for node in ast.walk(function) if isinstance(node, ast.Call)]
        def argument(tag, index):
            return next(node.args[index].value for node in calls
                        if any(isinstance(arg, ast.Constant) and arg.value == tag
                               for arg in node.args))
        self.assertIsNotNone(self.select(nodes, argument('minus-second-real-wrong-answer', 1)))
        self.assertEqual(argument('minus-second-wrong-feedback', 1),
                         'Wir können es mit kleineren Schritten probieren')

    def test_smaller_static_label_never_becomes_a_touch_target(self):
        nodes = [
            control("Lernen", clickable=False, bounds="[31,109][113,135]"),
            control("Lernen"),
        ]
        self.assertEqual(self.select(nodes, "Lernen"), [47, 230, 121, 298])

    def test_disabled_foreign_partial_and_zero_size_targets_are_rejected(self):
        nodes = [
            control("Lernen", enabled=False),
            control("Lernen", package="com.google.android.apps.nexuslauncher"),
            control("Lernen und Spielen"),
            control("Lernen", bounds="[20,30][20,30]"),
            control("Lernen", clickable=False),
        ]
        self.assertIsNone(self.select(nodes, "Lernen"))

    def test_current_merged_accessible_caption_remains_supported(self):
        self.assertEqual(self.select([control("Lernen. Mathe, Deutsch und mehr\nLernen")],
                                     "Lernen"), [47, 230, 121, 298])

    def test_actual_saved_navigation_presses_only_observed_enabled_bounds(self):
        self.reader.return_value = [node.attrib for node in ET.parse(FIXTURE).iter("node")]
        self.tap(Path("/unit-fixture"), "Lernen", "school-overview")
        self.adb.assert_called_once_with("shell", "input", "swipe",
                                        "84", "264", "84", "264", "120")
        self.capture.assert_not_called()

    def test_gliding_label_waits_for_a_current_real_tap_action(self):
        self.reader.side_effect = [[control("Lernen", clickable=False)], [control("Lernen")]]
        self.tap(Path("/unit-fixture"), "Lernen", "settling")
        self.adb.assert_called_once_with("shell", "input", "swipe",
                                        "84", "264", "84", "264", "120")

    def test_static_label_only_fails_without_injecting_a_touch(self):
        self.reader.return_value = [control("Lernen", clickable=False)]
        with self.assertRaisesRegex(RuntimeError, "No enabled live Flutter course control"):
            self.tap(Path("/unit-fixture"), "Lernen", "static-only")
        self.adb.assert_not_called()
        self.capture.assert_called_once()

    def test_actual_offscreen_feedback_is_not_a_pass_from_weiterkommen(self):
        nodes = [node.attrib for node in ET.parse(SCROLL_FIXTURE).iter("node")]
        values = [n.get("content-desc", "") or n.get("text", "") for n in nodes]
        self.assertIn("Lernen. Spielen. Weiterkommen.", values)
        self.assertIn("1, richtig", values)
        self.assertFalse(self.accepted(nodes, "1"))

    def test_correct_answer_feedback_and_continue_must_share_current_frame(self):
        right = control("1, richtig", clickable=False, enabled=False)
        feedback = control("Das passt! Weiter geht es in deinem Tempo.", clickable=False)
        proceed = control("Weiter")
        self.assertTrue(self.accepted([right, feedback, proceed], "1"))
        for partial in ([right, feedback], [right, proceed], [feedback, proceed]):
            self.assertFalse(self.accepted(partial, "1"))

    def test_wrong_answer_or_disabled_continue_cannot_pass(self):
        feedback = control("Du hast selbst gerechnet. Gut gemacht!", clickable=False)
        proceed = control("Weiter")
        self.assertFalse(self.accepted([
            control("2, richtig", clickable=False), feedback, proceed], "1"))
        self.assertFalse(self.accepted([
            control("1, richtig", clickable=False), feedback,
            control("Weiter", enabled=False)], "1"))
        self.assertFalse(self.accepted([
            control("1, richtig", clickable=False),
            control("Fast! Probiere es noch einmal.", clickable=False), proceed], "1"))


if __name__ == "__main__":
    unittest.main()
