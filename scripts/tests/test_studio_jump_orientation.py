"""Offline portrait plumbing regressions; original frames, no Android or motion acceptance."""
import ast
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import tempfile
import time
from types import SimpleNamespace
import unicodedata
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).parent / 'fixtures/studio_creative_android'


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


studio = load(ROOT / '.github/probes/studio_creative_android_probe.py', 'studio_jump_orientation')
readiness = load(ROOT / 'tools/android_qa/native_surface_readiness.py', 'studio_jump_readiness')


class FirstCheckpointReached(RuntimeError):
    pass


class JumpOrientationContracts(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.out = Path(self.temporary.name)
        self.frames = json.loads((FIXTURES / 'jump-portrait-ocr.json').read_text())['frames']
        for frame in self.frames:
            self.assertEqual(hashlib.sha256((FIXTURES / frame['file']).read_bytes()).hexdigest(),
                             frame['sha256'])
        self.observations, self.commands = [], []

    def helper(self):
        def capture(*_args, **_kwargs):
            if len(self.observations) >= len(self.frames):
                raise RuntimeError('No additional original replay frame')
            frame = self.frames[len(self.observations)]
            self.observations.append(frame)
            return {'file': str((FIXTURES / frame['file']).resolve())}

        def image_lines(_out, _tag, _wanted, *, source_path, **_kwargs):
            digest = hashlib.sha256(source_path.read_bytes()).hexdigest()
            return next(frame['matches'] for frame in self.frames if frame['sha256'] == digest)

        def adb(*args, **kwargs):
            self.commands.append((args, kwargs))
            return ''

        source = ROOT / '.github/probes/creative_android_probe.py'
        names = {'digest', 'normalized', 'native_tap', 'native_text', 'leave'}
        definitions = [node for node in ast.parse(source.read_text()).body
                       if isinstance(node, ast.FunctionDef) and node.name in names]
        namespace = {'Path': Path, 'hashlib': hashlib, 'json': json, 're': re,
                     'unicodedata': unicodedata, 'PACKAGE': studio.PACKAGE,
                     'time': SimpleNamespace(monotonic=time.monotonic, sleep=lambda _delay: None),
                     'base': SimpleNamespace(adb=adb, foreground=lambda: 'FlutterActivity'),
                     'capture': capture, 'image_lines': image_lines,
                     'inspect_surface': readiness.inspect_surface,
                     'target_observation': readiness.target_observation}
        exec(compile(ast.Module(body=definitions, type_ignores=[]), str(source), 'exec'), namespace)
        return SimpleNamespace(**namespace)

    def tour(self, helper):
        tour = studio.Tour.__new__(studio.Tour)
        tour.out, tour.counter, tour.probe = self.out, 0, helper
        return tour

    def test_actual_jump_entry_requires_both_full_portrait_targets_before_first_checkpoint(self):
        helper = self.helper()
        tour = self.tour(helper)
        tour.enter = lambda *_args: None
        tour.jump_save = lambda: (_ for _ in ()).throw(FirstCheckpointReached())
        with self.assertRaises(FirstCheckpointReached):
            tour.jump()
        journal = json.loads(next(self.out.glob('*-surface-readiness.json')).read_text())
        self.assertEqual(journal['orientation_policy'], 'responsive')
        self.assertEqual(journal['timeout_seconds'], 120)
        self.assertEqual(len(journal['frames']), 2)
        self.assertFalse(journal['frames'][0]['target']['stable_observed_target'])
        self.assertTrue(journal['frames'][1]['target']['stable_observed_target'])
        self.assertEqual(len(self.commands), 1)
        self.assertEqual(self.commands[0][0],
                         ('shell', 'input', 'swipe', '999', '74', '999', '74', '120'))

    def test_observe_forwards_portrait_policy_and_preserves_landscape_default(self):
        helper = self.helper()
        tour = self.tour(helper)
        calls = []

        def shot(_tag):
            frame = self.frames[min(len(calls), 1)]
            calls.append(frame)
            return FIXTURES / frame['file'], {'file': frame['file']}

        tour.shot = shot
        with patch.object(studio.time, 'sleep'):
            target = tour.observe('Pause', exact=True, orientation='responsive')
            self.assertEqual(len(calls), 2)
            self.assertTrue(target['stable']['stable_observed_target'])
            calls.clear()
            with self.assertRaisesRegex(RuntimeError, 'never stabilized'):
                tour.observe('Pause', exact=True)
        self.assertEqual(len(calls), 3)
        self.assertEqual(self.commands, [])

    def test_responsive_still_rejects_partial_frames_and_invalid_current_bounds(self):
        source = FIXTURES / self.frames[0]['file']
        full = readiness.inspect_surface(source, orientation='responsive')
        self.assertTrue(full['acceptable_for_target_sampling'])
        with Image.open(source) as original:
            partial = original.convert('RGB')
        ImageDraw.Draw(partial).rectangle((0, 0, partial.width // 4, partial.height), fill=(0, 0, 0))
        path = self.out / 'synthetic-incomplete-counterexample.png'
        partial.save(path)
        rejected = readiness.inspect_surface(path, orientation='responsive')
        self.assertFalse(rejected['acceptable_for_target_sampling'])
        self.assertIn('blank edge band', rejected['reasons'][0])
        rect = self.frames[0]['matches'][0]['bounds']
        first = readiness.target_observation(full, rect)
        self.assertFalse(readiness.target_observation(rejected, rect, first)['stable_observed_target'])
        self.assertFalse(readiness.target_observation(full, [-1, 0, 1034, 83], first)['target_geometry_valid'])
        with self.assertRaises(ValueError):
            readiness.inspect_surface(source, orientation='ignore')

    def test_leave_forwards_only_requested_policy_and_retains_process_and_foreground_gates(self):
        helper = self.helper()
        calls, returned = [], []
        namespace = helper.leave.__globals__
        namespace['native_text'] = lambda *args, **kwargs: calls.append((args, kwargs))
        namespace['capture'] = lambda *_args: returned.append(True)
        helper.leave(self.out, 'default', already_menu=True)
        self.assertEqual(calls[-1][1]['orientation'], 'landscape')
        tour = self.tour(helper)
        tour.profile = 'synthetic-test-profile'
        tour.live = SimpleNamespace(live_nodes=lambda *_args: [
            {'package': studio.PACKAGE, 'text': 'Spielen'}])
        helper.flutter_return_capture = lambda *_args: None
        helper.prefs = lambda *_args: {'flutter.lumo_active_profile': tour.profile}
        tour.leave('Zur Spieleauswahl · Abenteuer behalten', already_pause=True,
                   orientation='responsive')
        self.assertEqual(calls[-1][1], {'tap': True, 'exact': True, 'orientation': 'responsive'})
        self.assertEqual(len(returned), 2)
        helper.base.adb = lambda *_args, **_kwargs: 'still-running'
        with self.assertRaisesRegex(RuntimeError, 'process did not stop'):
            helper.leave(self.out, 'process', already_menu=True, orientation='responsive')
        helper.base.adb = lambda *_args, **_kwargs: ''
        helper.base.foreground = lambda: 'LumoGameActivity'
        with self.assertRaisesRegex(RuntimeError, 'still foreground'):
            helper.leave(self.out, 'foreground', already_menu=True, orientation='responsive')
        self.assertEqual(len(returned), 2)


if __name__ == '__main__':
    unittest.main()
