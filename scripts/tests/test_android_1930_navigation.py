"""Actual saved hierarchy regressions, not a substitute for Android acceptance."""
import ast
import json
from pathlib import Path
import re
import types
import tempfile
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
                   and node.name in ("_enabled_control_bounds", "_answer_accepted", "tap", "wait_proactive_help_offer", "tap_named_course")]
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
        self.events = []
        self.wait_text = Mock(side_effect=lambda *args, **kwargs: self.events.append('scan'))
        scope = {"existing": existing, "re": re, "Path": Path, "json": json,
                 "time": types.SimpleNamespace(sleep=lambda seconds: self.events.append(('quiet', seconds))),
                 "wait_text": self.wait_text}
        exec(compile(ast.Module(body=helpers, type_ignores=[]), str(SOURCE), "exec"), scope)
        self.select = scope["_enabled_control_bounds"]
        self.accepted = scope["_answer_accepted"]
        self.tap = scope["tap"]
        self.help_offer = scope.get('wait_proactive_help_offer')
        self.scope = scope

    def test_school_course_uses_actual_named_plus_button_not_clipped_syllables_button(self):
        fixture = ROOT / 'scripts/tests/fixtures/android_1933_course_hub.xml'
        self.reader.return_value = [n.attrib for n in ET.parse(fixture).iter('node')]
        self.assertEqual(self.select(self.reader.return_value, 'Mit Lumo anfangen'),
                         [35, 825, 1165, 872])
        function = next(n for n in ast.parse(SOURCE.read_text()).body
                        if isinstance(n, ast.FunctionDef) and n.name == 'school_course')
        class ObservedStart(Exception):
            pass
        def wait(_out, marker, _tag):
            if marker == 'Heute lernen wir einen Rechentrick':
                raise ObservedStart()
            return ''
        self.scope.update(tap=Mock(), wait_text=wait)
        exec(compile(ast.Module(body=[function], type_ignores=[]), str(SOURCE), 'exec'), self.scope)
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaises(ObservedStart):
                self.scope['school_course'](Path(folder))
        self.adb.assert_called_once_with('shell', 'input', 'swipe',
                                        '600', '405', '600', '405', '120')

    def test_help_probe_waits_quietly_before_any_scrolling_scan(self):
        self.assertIsNotNone(self.help_offer)
        self.help_offer(Path('/tmp/unit-fixture'))
        self.assertGreaterEqual(self.events[0][1], 15)
        self.assertEqual(self.events[0][0], 'quiet')
        self.assertEqual(self.events[1], 'scan')
        self.assertEqual(self.wait_text.call_args.args[1], 'Zeig mir wie')

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

    def test_non_math_feedback_is_exact_and_keeps_same_frame_requirement(self):
        feedback = 'Das hast du selbst herausgefunden. Gut gemacht!'
        right = control('Blüte, richtig', clickable=False, enabled=False)
        message = control(feedback, clickable=False)
        proceed = control('Weiter')
        self.assertFalse(self.accepted([right, message, proceed], 'Blüte'))
        self.assertTrue(self.accepted([right, message, proceed], 'Blüte',
                                     correct_feedback=(feedback,)))
        for partial in ([right, message], [right, proceed], [message, proceed]):
            self.assertFalse(self.accepted(partial, 'Blüte',
                                          correct_feedback=(feedback,)))
        self.assertFalse(self.accepted([
            right, control('Du hast selbst gerechnet. Gut gemacht!', clickable=False),
            proceed], 'Blüte', correct_feedback=(feedback,)))


if __name__ == "__main__":
    unittest.main()
