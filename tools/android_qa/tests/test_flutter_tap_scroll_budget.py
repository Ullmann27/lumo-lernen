"""Bounded live-search contracts for the actual Flutter tap helper.

The API35 e3d run exhausted its last scroll immediately before the real voice
control appeared. These are synthetic transport fixtures, not Android proof.
The actual helper is loaded from source; no navigation algorithm is copied.
"""
import ast
from pathlib import Path
import re
import tempfile
from types import SimpleNamespace
import unittest


ROOT = Path(__file__).resolve().parents[3]
LABEL = 'Neue Sätze offline vorlesen'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'


class FlutterTapScrollBudgetTests(unittest.TestCase):
    def run_search(self, *, budget=2, target_after=None, enabled=True,
                   target_height=126, clickable=True):
        source = ROOT / '.github/probes/creative_android_probe.py'
        function = next(node for node in ast.parse(source.read_text()).body
                        if isinstance(node, ast.FunctionDef)
                        and node.name == 'flutter_tap')
        gestures, presses, observations, screenshots = [], [], [], []
        scroll = {'package': PACKAGE, 'scrollable': 'true',
                  'bounds': '[0,346][1080,1859]'}
        target = {'package': PACKAGE, 'text': '',
                  'content-desc': LABEL + '\nLokale Modellfreigabe',
                  'bounds': f'[100,900][980,{900 + target_height}]',
                  'enabled': 'true' if enabled else 'false',
                  'clickable': 'true' if clickable else 'false'}

        def live_nodes(_out, tag):
            observations.append((tag, len(gestures)))
            visible = target_after is not None and len(gestures) >= target_after
            return [scroll, target] if visible else [scroll]

        def adb(*args):
            self.assertEqual(args[:3], ('shell', 'input', 'swipe'))
            if args[-1] == '400':
                gestures.append(args)
            else:
                self.assertEqual(args[-1], '120')
                presses.append(args)

        scope = {'Path': Path, 're': re, 'PACKAGE': PACKAGE,
                 'live': SimpleNamespace(live_nodes=live_nodes),
                 'base': SimpleNamespace(adb=adb),
                 'time': SimpleNamespace(sleep=lambda _seconds: None),
                 'recover_launcher_dialog': lambda *_args: False,
                 'capture': lambda _out, tag: screenshots.append(tag)}
        exec(compile(ast.Module(body=[function], type_ignores=[]),
                     str(source), 'exec'), scope)
        error = None
        with tempfile.TemporaryDirectory() as directory:
            try:
                scope['flutter_tap'](Path(directory), LABEL, 'voice-control',
                                     scroll_attempts=budget,
                                     min_visible_height_px=48)
            except RuntimeError as caught:
                error = caught
        return SimpleNamespace(error=error, gestures=gestures, presses=presses,
                               observations=observations, screenshots=screenshots)

    def test_target_after_last_allowed_scroll_is_observed_and_pressed(self):
        for budget in (1, 2, 16):
            with self.subTest(budget=budget):
                result = self.run_search(budget=budget, target_after=2 * budget)
                self.assertIsNone(result.error)
                self.assertEqual(len(result.gestures), 2 * budget)
                self.assertEqual(result.observations[-1][1], 2 * budget)
                self.assertEqual(result.presses, [
                    ('shell', 'input', 'swipe', '540', '963', '540', '963', '120')])
                self.assertEqual(result.screenshots, [])

    def test_missing_target_still_fails_after_final_observation_without_extra_swipe(self):
        result = self.run_search(budget=2)
        self.assertRegex(str(result.error), 'No enabled live Flutter control: ' + LABEL)
        self.assertEqual(len(result.gestures), 4)
        self.assertEqual(len(result.observations), 6)
        self.assertEqual(result.observations[-1][1], 4)
        self.assertEqual(result.presses, [])
        self.assertEqual(result.screenshots, ['voice-control-missing'])

    def test_disabled_final_target_is_not_pressed(self):
        result = self.run_search(target_after=4, enabled=False)
        self.assertIsInstance(result.error, RuntimeError)
        self.assertEqual(len(result.gestures), 4)
        self.assertEqual(result.observations[-1][1], 4)
        self.assertEqual(result.presses, [])

    def test_clipped_final_target_keeps_existing_touch_height_guard(self):
        result = self.run_search(target_after=4, target_height=1)
        self.assertIsInstance(result.error, RuntimeError)
        self.assertEqual(len(result.gestures), 4)
        self.assertEqual(result.observations[-1][1], 4)
        self.assertEqual(result.presses, [])

    def test_unsettled_final_target_is_not_mistaken_for_a_successful_press(self):
        result = self.run_search(target_after=4, clickable=False)
        self.assertIsInstance(result.error, RuntimeError)
        self.assertEqual(len(result.gestures), 4)
        self.assertEqual(result.observations[-1][1], 4)
        self.assertEqual(result.presses, [])

    def test_already_visible_target_does_not_add_scroll_or_observation(self):
        result = self.run_search(target_after=0)
        self.assertIsNone(result.error)
        self.assertEqual(len(result.observations), 1)
        self.assertEqual(result.gestures, [])
        self.assertEqual(len(result.presses), 1)


if __name__ == '__main__':
    unittest.main()
