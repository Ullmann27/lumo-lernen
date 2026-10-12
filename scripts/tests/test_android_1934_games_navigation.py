import importlib.util
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('gamescontrols',ROOT/'.github/probes/lumo_games_android_controls.py')
controls=importlib.util.module_from_spec(spec)
spec.loader.exec_module(controls)
PACKAGE='dev.ullmann.lumo.lumo_lernen.coachpreview'


class ActualNavigationTest(unittest.TestCase):
    def setUp(self):
        path=ROOT/'scripts/tests/fixtures/android_1934_short_landscape_navigation.xml'
        self.nodes=[n.attrib for n in ET.parse(path).iter('node')]

    def test_actual_short_landscape_uses_sidebar_not_larger_right_column(self):
        self.assertEqual(controls.navigation_scroll_bounds(self.nodes,PACKAGE),[11,136,169,230])

    def test_clipped_six_pixel_navigation_is_not_tappable(self):
        self.assertIsNone(controls.enabled_button_bounds(self.nodes,PACKAGE,'Lernen'))
        self.assertEqual(controls.enabled_button_bounds(self.nodes,PACKAGE,'Start'),[47,139,133,218])

    def test_logo_caption_and_other_package_do_not_create_navigation_control(self):
        self.assertIsNone(controls.enabled_button_bounds(self.nodes,PACKAGE,'Spielen'))
        self.assertIsNone(controls.navigation_scroll_bounds(self.nodes,'another.package'))

# Exercise only the QA helper with the exact observed emulator system-dialog
# wording/bounds. These tests do not manufacture Android acceptance evidence.
import ast
import json
import re
from tempfile import TemporaryDirectory
from types import SimpleNamespace
from unittest.mock import Mock


class EmulatorSystemDialogTest(unittest.TestCase):
    def setUp(self):
        path = ROOT / '.github/probes/creative_android_probe.py'
        module = ast.parse(path.read_text())
        function = next(n for n in module.body
                        if isinstance(n, ast.FunctionDef)
                        and n.name == 'recover_launcher_dialog')
        self.adb = Mock()
        namespace = {
            'Path': Path, 'json': json, 're': re,
            'base': SimpleNamespace(adb=self.adb),
            'time': SimpleNamespace(sleep=lambda _seconds: None),
            'capture': lambda _out, name: {'file': name + '.png'},
        }
        exec(compile(ast.Module(body=[function], type_ignores=[]),
                     str(path), 'exec'), namespace)
        self.recover = namespace['recover_launcher_dialog']

    @staticmethod
    def system_nodes():
        return [
            {'package': 'android', 'text': "System UI isn't responding"},
            {'package': 'android', 'text': 'Close app', 'enabled': 'true',
             'clickable': 'true', 'bounds': '[71,1171][1009,1303]'},
            {'package': 'android', 'text': 'Wait', 'enabled': 'true',
             'clickable': 'true', 'bounds': '[71,1303][1009,1435]'},
        ]

    def test_real_system_ui_anr_uses_observed_wait_and_keeps_json_valid(self):
        with TemporaryDirectory() as directory:
            out = Path(directory)
            self.assertTrue(self.recover(out, self.system_nodes(), 'welcome'))
            self.adb.assert_called_once_with(
                'shell', 'input', 'tap', '540', '1369')
            records = json.loads((out / 'launcher-recovery.json').read_text())
            self.assertEqual(records[0]['dialog'], "System UI isn't responding")
            self.assertEqual(records[0]['action'], 'Wait')
            self.assertEqual(records[0]['observed_bounds'], [71, 1303, 1009, 1435])

    def test_only_two_system_recoveries_before_hard_failure(self):
        with TemporaryDirectory() as directory:
            out = Path(directory)
            self.assertTrue(self.recover(out, self.system_nodes(), 'welcome'))
            self.assertTrue(self.recover(out, self.system_nodes(), 'welcome'))
            with self.assertRaisesRegex(RuntimeError, 'repeatedly stopped'):
                self.recover(out, self.system_nodes(), 'welcome')
            self.assertEqual(self.adb.call_count, 2)

    def test_app_anr_or_foreign_dialog_must_not_be_dismissed(self):
        with TemporaryDirectory() as directory:
            out = Path(directory)
            app = [{'package': 'android',
                    'text': "Lumo Lernen isn't responding"}]
            foreign = [{'package': PACKAGE,
                        'text': "System UI isn't responding"}]
            self.assertFalse(self.recover(out, app, 'app-anr'))
            self.assertFalse(self.recover(out, foreign, 'foreign'))
            self.adb.assert_not_called()

    def test_disabled_wait_does_not_authorize_system_tap(self):
        with TemporaryDirectory() as directory:
            nodes = self.system_nodes()
            nodes[-1]['enabled'] = 'false'
            with self.assertRaisesRegex(RuntimeError, 'enabled Wait'):
                self.recover(Path(directory), nodes, 'disabled')
            self.adb.assert_not_called()
