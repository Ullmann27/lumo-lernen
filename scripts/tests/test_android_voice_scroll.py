"""Bounded real-control reader regressions, not emulator/audio approval."""
import ast
from pathlib import Path
import re
import types
import unittest
from unittest.mock import Mock


SOURCE = Path(__file__).resolve().parents[2] / ".github/probes/creative_android_probe.py"
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
LABEL = "App und lokale Stimme prüfen"


class LongParentScrollTest(unittest.TestCase):
    def run_reader(self, **options):
        tree = ast.parse(SOURCE.read_text())
        helper = next(node for node in tree.body
                      if isinstance(node, ast.FunctionDef) and node.name == "flutter_tap")
        self.position = 0
        self.scrolled = 0
        self.control_touches = 0

        def nodes(*_):
            frame = [{"package": PACKAGE, "scrollable": "true",
                      "bounds": "[20,100][1180,650]", "enabled": "true"}]
            if self.position >= 17:
                frame.append({"package": PACKAGE, "clickable": "true",
                              "enabled": "true", "content-desc": LABEL,
                              "bounds": "[200,300][780,400]"})
            return frame

        def adb(*args):
            if args[:3] != ("shell", "input", "swipe"):
                raise AssertionError("Only observed live finger gestures expected")
            if args[-1] == "120":
                self.control_touches += 1
            else:
                self.scrolled += 1
                self.position = max(
                    0, min(30, self.position + (1 if int(args[4]) > int(args[6]) else -1)))

        self.nodes = Mock(side_effect=nodes)
        self.capture = Mock()
        scope = {
            "Path": Path, "PACKAGE": PACKAGE, "re": re,
            "live": types.SimpleNamespace(live_nodes=self.nodes),
            "base": types.SimpleNamespace(adb=adb),
            "time": types.SimpleNamespace(sleep=Mock()),
            "recover_launcher_dialog": Mock(return_value=False),
            "capture": self.capture,
        }
        exec(compile(ast.Module(body=[helper], type_ignores=[]), str(SOURCE), "exec"),
             scope)
        return scope["flutter_tap"](Path("/unit-fixture"), LABEL, "unit-scroll", **options)

    def test_long_parent_diagnosis_is_reached_with_explicit_bounded_forward_search(self):
        self.run_reader(scroll_attempts=48, direction_order=(1, -1))
        self.assertEqual(self.scrolled, 17)
        self.assertEqual(self.control_touches, 1)
        self.capture.assert_not_called()

    def test_existing_default_search_is_not_silently_unbounded(self):
        with self.assertRaisesRegex(RuntimeError, "No enabled live Flutter control"):
            self.run_reader()
        self.assertEqual(self.nodes.call_count, 24)
        self.assertEqual(self.position, 12)
        self.assertEqual(self.control_touches, 0)
        self.capture.assert_called_once()

    def test_unbounded_search_budget_is_rejected_before_reading_or_touching(self):
        with self.assertRaises(ValueError):
            self.run_reader(scroll_attempts=999)
        self.assertEqual(self.nodes.call_count, 0)
        self.assertEqual(self.control_touches, 0)

    def test_unknown_scroll_direction_is_rejected(self):
        with self.assertRaises(ValueError):
            self.run_reader(direction_order=(0, 1))
        self.assertEqual(self.nodes.call_count, 0)


class PreservedKartEntryTest(unittest.TestCase):
    def test_voice_probe_uses_the_observed_kart_launch_control(self):
        """The real 38135805251 hierarchy exports Losfahren, not the default."""
        probe = SOURCE.with_name("lumo_free_voice_android_probe.py")
        tree = ast.parse(probe.read_text())
        call = next(node for node in ast.walk(tree)
                    if isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Attribute)
                    and node.func.attr == "enter"
                    and len(node.args) > 3
                    and isinstance(node.args[3], ast.Constant)
                    and node.args[3].value == "preserved-kart")
        helper = next(node for node in ast.parse(SOURCE.read_text()).body
                      if isinstance(node, ast.FunctionDef) and node.name == "enter")
        tap = Mock()
        header = Mock()
        scope = {
            "Path": Path, "PACKAGE": PACKAGE, "flutter_tap": tap,
            "base": types.SimpleNamespace(
                foreground=Mock(return_value=PACKAGE + "/LumoGameActivity"),
                adb=Mock(return_value="1234")),
            "time": types.SimpleNamespace(sleep=Mock()), "native_text": header,
        }
        exec(compile(ast.Module(body=[helper], type_ignores=[]), str(SOURCE), "exec"),
             scope)
        out = Path("/unit-fixture")
        eval(compile(ast.Expression(body=call), str(probe), "eval"), {
            "existing": types.SimpleNamespace(enter=scope["enter"]), "out": out})
        tap.assert_called_once_with(out, "Losfahren", "preserved-kart-launch")
        header.assert_called_once_with(out, "Einzelrennen", "preserved-kart-header")

    def test_voice_probe_returns_with_the_observed_exact_menu_caption(self):
        """The real 38136812518 menu exports Zum Lernen, not Zur Spielewelt."""
        probe = SOURCE.with_name("lumo_free_voice_android_probe.py")
        tree = ast.parse(probe.read_text())
        call = next(node for node in ast.walk(tree)
                    if isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Attribute)
                    and node.func.attr == "leave"
                    and len(node.args) > 1
                    and isinstance(node.args[1], ast.Constant)
                    and node.args[1].value == "preserved-kart")
        helper = next(node for node in ast.parse(SOURCE.read_text()).body
                      if isinstance(node, ast.FunctionDef) and node.name == "leave")
        touch = Mock()
        scope = {
            "Path": Path, "PACKAGE": PACKAGE, "native_text": touch,
            "base": types.SimpleNamespace(
                foreground=Mock(return_value=PACKAGE + "/MainActivity"),
                adb=Mock(return_value="")),
            "time": types.SimpleNamespace(sleep=Mock()), "capture": Mock(),
        }
        exec(compile(ast.Module(body=[helper], type_ignores=[]), str(SOURCE), "exec"),
             scope)
        out = Path("/unit-fixture")
        eval(compile(ast.Expression(body=call), str(probe), "eval"), {
            "existing": types.SimpleNamespace(leave=scope["leave"]), "out": out})
        touch.assert_called_once_with(
            out, "Zum Lernen", "preserved-kart-pause", tap=True, exact=True)

    def test_other_games_keep_the_existing_return_caption(self):
        helper = next(node for node in ast.parse(SOURCE.read_text()).body
                      if isinstance(node, ast.FunctionDef) and node.name == "leave")
        touch = Mock()
        scope = {
            "Path": Path, "PACKAGE": PACKAGE, "native_text": touch,
            "base": types.SimpleNamespace(
                foreground=Mock(return_value=PACKAGE + "/MainActivity"),
                adb=Mock(return_value="")),
            "time": types.SimpleNamespace(sleep=Mock()), "capture": Mock(),
        }
        exec(compile(ast.Module(body=[helper], type_ignores=[]), str(SOURCE), "exec"),
             scope)
        out = Path("/unit-fixture")
        scope["leave"](out, "another-game", already_menu=True)
        touch.assert_called_once_with(
            out, "Zur Spielewelt", "another-game-pause", tap=True)


if __name__ == "__main__":
    unittest.main()
