"""Replay unchanged a31 Android PNGs through real surface checks and OCR.

The two originals are from failed workflow 43381440720, job 131762099939.
Capture replay and intercepted input are offline probe regressions, not a new
Android run. Provenance and original SHA-256 values are next to the fixtures.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from native_surface_readiness import inspect_surface, target_observation

FIXTURES = Path(__file__).with_name('fixtures')
ORIGINALS = (
    ('android_2018_learning_portrait_a31_00.png',
     '6e81c02b44eb4361deec4aba145886544981ee751eb70cb40369b7b25c5fa000'),
    ('android_2018_learning_portrait_a31_36.png',
     'bf1d6854a60de936d46f34024684570cf7fc1e800aa13a32c267c2f3158be5d2'),
)


class NextgenResponsiveSurfaceTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.out = Path(folder.name)

    def load_probe(self):
        for directory in (ROOT / '.github/probes', ROOT / 'scripts/probes'):
            sys.path.insert(0, str(directory))
        path = ROOT / '.github/probes/creative_android_probe.py'
        spec = importlib.util.spec_from_file_location('responsive_surface_probe', path)
        probe = importlib.util.module_from_spec(spec)
        base = importlib.import_module('pr207_android_smoke')
        adapter = SimpleNamespace(live_nodes=lambda *_: [], live_tap_label=lambda *_: None)
        with patch.dict(sys.modules, {'pr207_android_ui_probe': adapter}), \
                patch.object(base, 'ui_nodes'), patch.object(base, 'tap_label'):
            spec.loader.exec_module(probe)
        return probe

    def test_actual_complete_portrait_frames_require_explicit_responsive_policy(self):
        provenance = json.loads((FIXTURES / 'android_2018_learning_portrait_a31.json').read_text())
        self.assertEqual(provenance['apk_identity']['flutter_source_commit'],
                         'a31c0070a9c1e9dfbea08f123d7ed77e5f0a8ad9')
        for name, digest in ORIGINALS:
            with self.subTest(name=name):
                source = FIXTURES / name
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), digest)
                default = inspect_surface(source)
                self.assertFalse(default['acceptable_for_target_sampling'])
                self.assertEqual(default['reasons'], ['native landscape surface has not arrived'])
                responsive = inspect_surface(source, orientation='responsive')
                self.assertEqual(responsive['source_sha256'], digest)
                self.assertEqual(responsive['pixels'], [1080, 2400])
                self.assertEqual(responsive['blank_edge_columns'], {'left': 0, 'right': 0})
                self.assertTrue(responsive['acceptable_for_target_sampling'])

    def test_unknown_orientation_never_relaxes_the_default(self):
        for orientation in ('portrait', 'responisve', '', None, True):
            with self.subTest(orientation=orientation), self.assertRaises(ValueError):
                inspect_surface(FIXTURES / ORIGINALS[0][0], orientation=orientation)

    def test_responsive_still_rejects_blank_and_partial_portrait_viewports(self):
        for edge in ('left', 'right', 'all'):
            with self.subTest(edge=edge):
                # Deliberately synthetic negative inputs; originals stay unchanged.
                frame = Image.new('RGB', (108, 240), (20, 40, 60))
                bounds = {'left': (0, 0, 30, 240), 'right': (78, 0, 108, 240),
                          'all': (0, 0, 108, 240)}[edge]
                frame.paste('black', bounds)
                source = self.out / (edge + '.png')
                frame.save(source)
                observed = inspect_surface(source, orientation='responsive')
                self.assertFalse(observed['acceptable_for_target_sampling'])
                self.assertEqual(len(observed['reasons']), 1)
                self.assertIn('blank edge band', observed['reasons'][0])
                target = target_observation(observed, [35, 60, 65, 80])
                self.assertFalse(target['target_geometry_valid'])
                self.assertFalse(target['stable_observed_target'])

    def test_responsive_resize_and_invalid_bounds_still_require_new_valid_pair(self):
        frame = inspect_surface(FIXTURES / ORIGINALS[0][0], orientation='responsive')
        # Geometry-only checks; these rectangles are not used as touch evidence.
        bounds = [100, 2000, 500, 2100]
        first = target_observation(frame, bounds)
        self.assertFalse(first['stable_observed_target'])
        second = target_observation(frame, bounds, first)
        self.assertTrue(second['stable_observed_target'])
        resized = dict(frame, pixels=[1080, 2520])
        after_resize = target_observation(resized, bounds, second)
        self.assertFalse(after_resize['stable_observed_target'])
        self.assertTrue(target_observation(resized, bounds, after_resize)['stable_observed_target'])
        for bad in ([100, 2390, 500, 2410], [-1, 20, 30, 40],
                    [100, 20, 100, 40], [float('nan'), 20, 30, 40]):
            with self.subTest(bounds=bad):
                result = target_observation(frame, bad, second)
                self.assertFalse(result['target_geometry_valid'])
                self.assertFalse(result['stable_observed_target'])

    def test_default_native_touch_rejects_the_original_portrait_without_ocr(self):
        probe = self.load_probe()
        now = [0.0]

        def capture(out, tag, timeout):
            self.assertGreater(timeout, 0)
            path = out / (tag + '.png')
            path.write_bytes((FIXTURES / ORIGINALS[0][0]).read_bytes())
            return {'file': path.name}

        with patch.object(probe, 'capture', capture), \
                patch.object(probe, 'image_lines') as reader, \
                patch.object(probe.base, 'adb') as touch, \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe.time, 'sleep', side_effect=lambda seconds: now.__setitem__(0, now[0] + seconds)):
            with self.assertRaises(TimeoutError):
                probe.native_tap(self.out, 'Ein Objekt zeigen', 'default', timeout=3, exact=True)
        reader.assert_not_called()
        touch.assert_not_called()
        report = json.loads((self.out / 'default-surface-readiness.json').read_text())
        self.assertEqual(report['orientation_policy'], 'landscape')
        self.assertEqual(report['elapsed_seconds'], 3)

    def test_two_original_portrait_frames_use_real_ocr_before_intercepted_touch(self):
        self.assertIsNotNone(shutil.which('tesseract'),
                             'Required captured-frame regression needs the actual Tesseract executable')
        probe = self.load_probe()
        originals = iter(ORIGINALS)

        def capture(out, tag, timeout):
            self.assertGreater(timeout, 0)
            name, digest = next(originals)
            raw = (FIXTURES / name).read_bytes()
            self.assertEqual(hashlib.sha256(raw).hexdigest(), digest)
            path = out / (tag + '.png')
            path.write_bytes(raw)
            return {'file': path.name}

        with patch.object(probe, 'capture', capture), \
                patch.object(probe, 'image_lines', wraps=probe.image_lines) as reader, \
                patch.object(probe.base, 'adb') as touch, \
                patch.object(probe.time, 'sleep'):
            # Only capture/input are doubled: source pixels, all surface guards,
            # exact phrase recognition and Tesseract itself execute unchanged.
            probe.native_text(self.out, 'Ein Objekt zeigen', 'responsive', tap=True,
                              exact=True, orientation='responsive')
        self.assertEqual(reader.call_count, 2)
        touch.assert_called_once()
        report = json.loads((self.out / 'responsive-surface-readiness.json').read_text())
        self.assertEqual(report['status'], 'TOUCH_SENT')
        self.assertEqual(report['orientation_policy'], 'responsive')
        self.assertEqual([frame['source_sha256'] for frame in report['frames']],
                         [digest for _, digest in ORIGINALS])
        self.assertFalse(report['frames'][0]['target']['stable_observed_target'])
        self.assertTrue(report['frames'][1]['target']['stable_observed_target'])
        x0, y0, x1, y1 = report['final_observed_bounds']
        x, y = report['touch']
        self.assertTrue(0 <= x0 < x < x1 <= 1080 and 0 <= y0 < y < y1 <= 2400)
        self.assertEqual(touch.call_args.args,
                         ('shell', 'input', 'swipe', str(x), str(y), str(x), str(y), '120'))


if __name__ == '__main__':
    unittest.main()
