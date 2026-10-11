"""Unit tests for the probe, not Android playback or adult identity evidence."""
import ast
from pathlib import Path
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
                   and node.name in ("_observed_parent_label", "parents")]
        self.reader = Mock(side_effect=frames)
        self.tap = Mock()
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


if __name__ == "__main__":
    unittest.main()
