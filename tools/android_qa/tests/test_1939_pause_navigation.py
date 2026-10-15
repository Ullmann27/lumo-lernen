"""Offline replay of actual failed-run OCR; not an Android runtime claim."""
import ast
import importlib.util
import json
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
spec = importlib.util.spec_from_file_location('kart_probe', ROOT / '.github/probes/kart_complete_android_probe.py')
kart = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kart)


class PauseNavigationTest(unittest.TestCase):
    def test_actual_clipped_gas_menu_scrolls_only_after_two_stable_frames(self):
        self.replay(remove_footer=False)

    def test_ambiguous_or_missing_footer_cannot_authorize_scroll(self):
        self.replay(remove_footer=True)

    def replay(self, remove_footer):
        fixture = json.loads((Path(__file__).parent / 'fixtures/1939_pause_ocr.json').read_text())
        rows = fixture['rows']
        if remove_footer:
            rows = [r for r in rows if r['text'] != 'Zum Lernen']
        self.assertFalse(any('GAS-Taste' in r['text'] for r in rows))
        captures, swipes, touches = [], [], []
        def capture(out, tag, **_):
            captures.append(tag)
            return {'file': tag + '.png'}
        def swipe(*args, **_):
            swipes.append((len(captures), args))
        def lines(*_, **__):
            # Synthetic target appearance after the actual observed scroll.
            return rows if not swipes else [{'text': 'Gas: GAS-Taste halten', 'bounds': [500, 400, 700, 420]}]
        creative = SimpleNamespace(
            normalized=lambda v: re.sub('[^a-z0-9]', '', v.lower()),
            capture=capture,
            inspect_surface=lambda p: {'acceptable_for_target_sampling': True, 'pixels': [1200, 896], 'source_sha256': 'bound-frame'},
            digest=lambda p: 'bound-frame', image_lines=lines,
            native_tap=lambda *args, **kwargs: touches.append((args, kwargs)),
            native_text=Mock(side_effect=AssertionError('Gas must retain the strict native touch gate')))
        node = next(n for n in ast.walk(ast.parse((ROOT / '.github/probes/lumo_1939_pause_navigation.py').read_text())) if isinstance(n, ast.FunctionDef) and n.name == 'tap_pause_setting')
        scope = dict(Path=Path, json=json, creative=creative, base=SimpleNamespace(adb=swipe),
                     time=SimpleNamespace(monotonic=lambda: 0, sleep=lambda _: None),
                     scroll_observation=kart.scroll_observation, stable_scroll_observation=kart.stable_scroll_observation)
        exec(compile(ast.Module(body=[node], type_ignores=[]), 'actual_1939_navigation', 'exec'), scope)
        with tempfile.TemporaryDirectory() as tmp:
            if remove_footer:
                with self.assertRaisesRegex(RuntimeError, 'pause footer'):
                    scope['tap_pause_setting'](Path(tmp), 'Gas: GAS-Taste halten', 'gas', scroll='down')
                self.assertEqual(swipes, [])
                self.assertEqual(touches, [])
            else:
                scope['tap_pause_setting'](Path(tmp), 'Gas: GAS-Taste halten', 'gas', scroll='down')
                self.assertEqual(len(swipes), 1)
                self.assertEqual(swipes[0][0], 3)
                args = swipes[0][1]
                self.assertEqual(args[:3], ('shell', 'input', 'swipe'))
                x, y0, x1, y1 = map(int, args[3:7])
                self.assertEqual(x, x1)
                self.assertTrue(191 <= y1 < y0 <= 575)
                self.assertEqual(args[7], '900')
                self.assertEqual(len(touches), 1)
                self.assertTrue(touches[0][1]['exact'])
                self.assertIsNotNone(touches[0][1]['missing_caption'])

if __name__ == '__main__':
    unittest.main()
