"""The Android tour must refuse any APK other than the exact verified build."""
import hashlib
import importlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

sys.dont_write_bytecode = True
# Import Pillow before load_tour(): patch.dict restores sys.modules on exit and
# would otherwise drop the PIL plugin modules the tour's Image relies on.
Image.preinit()
ROOT = Path(__file__).resolve().parents[3]
TOUR = ROOT / '.github/probes/modernization_android_tour.py'


def load_tour():
    for path in (ROOT / 'tools/android_qa', ROOT / 'scripts/probes', ROOT / '.github/probes'):
        sys.path.insert(0, str(path))
    adapter = SimpleNamespace(live_nodes=lambda *_: [], live_tap_label=lambda *_: None)
    with patch.dict(sys.modules, {'pr207_android_ui_probe': adapter}):
        spec = importlib.util.spec_from_file_location('modernization_tour_under_test', TOUR)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
    return module


TOUR_MODULE = load_tour()


class TourApkIdentityTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        folder = Path(self.temp.name)
        self.apk = folder / 'Lumo-Lernen-Neu.apk'
        self.apk.write_bytes(b'actual apk bytes')
        digest = hashlib.sha256(self.apk.read_bytes()).hexdigest()
        version = re.search(r'^version:\s*([0-9.]+)\+(\d+)', (ROOT / 'pubspec.yaml').read_text(), re.M)
        pin = json.loads((ROOT / 'config/godot-source.json').read_text())['revision']
        self.provenance = {
            'sha256': digest, 'flutter_source_commit': 'a' * 40, 'tracked_source_clean': True,
            'godot': {'revision': pin, 'pck_sha256': 'b' * 64},
            'signingCertificateSha256': TOUR_MODULE.probe.CERT,
            'versionName': version[1], 'versionCode': int(version[2]), 'abis': ['arm64-v8a', 'x86_64'],
        }
        self.provenance_path = folder / 'BUILD-PROVENANCE-x86_64.json'
        self.sums = folder / 'SHA256SUMS.txt'
        self.sums.write_text(f'{"c" * 64}  dist/Lumo-Lernen-Neu.apk\n'
                             f'{digest}  dist/x86_64/Lumo-Lernen-Neu.apk\n')
        self.cwd = os.getcwd()
        os.chdir(ROOT)
        self.addCleanup(os.chdir, self.cwd)

    def verify(self, **changes):
        provenance = dict(self.provenance, **changes)
        self.provenance_path.write_text(json.dumps(provenance))
        # A PR has a synthetic merge GITHUB_SHA, but the workflow checks out
        # the immutable pull_request.head.sha. Verify against that Git HEAD.
        with patch.dict(os.environ, {'GITHUB_SHA': 'd' * 40}):
            with patch.object(TOUR_MODULE.base, 'command',
                              return_value='a' * 40) as checkout:
                result = TOUR_MODULE.verify_apk_identity(
                    self.apk, self.provenance_path, self.sums)
                checkout.assert_called_once_with('git', 'rev-parse', 'HEAD')
                return result

    def test_the_exact_verified_build_is_accepted(self):
        report = self.verify()
        self.assertTrue(all(report['checks'].values()))
        self.assertEqual(report['flutter_source_commit'], 'a' * 40)

    def test_any_other_build_identity_is_refused(self):
        for changes, reason in (
                ({'signingCertificateSha256': 'd' * 64}, 'signing_certificate'),
                ({'godot': {'revision': 'e' * 40}}, 'godot_revision_is_pinned'),
                ({'flutter_source_commit': 'f' * 40}, 'flutter_source_is_this_commit'),
                ({'tracked_source_clean': False}, 'tracked_source_clean'),
                ({'versionCode': 1}, 'version_matches_pubspec'),
                ({'sha256': '0' * 64}, 'sha256_matches_provenance'),
                ({'abis': ['arm64-v8a']}, 'x86_64_native_code')):
            with self.subTest(reason=reason):
                with self.assertRaisesRegex(RuntimeError, reason):
                    self.verify(**changes)

    def test_build_job_checksum_must_match_the_tested_file(self):
        self.sums.write_text(f'{"0" * 64}  dist/x86_64/Lumo-Lernen-Neu.apk\n')
        with self.assertRaisesRegex(RuntimeError, 'sha256_matches_build_sums'):
            self.verify()


class TourLabelTests(unittest.TestCase):
    def test_only_this_apps_visible_captions_are_compared(self):
        package = TOUR_MODULE.PACKAGE
        nodes = [{'package': package, 'text': 'Mathematik', 'content-desc': ''},
                 {'package': package, 'text': '', 'content-desc': 'Deutsch\nLesen'},
                 {'package': 'com.android.systemui', 'text': '12:00', 'content-desc': ''}]
        self.assertEqual(TOUR_MODULE.labels(nodes), ['Mathematik', 'Deutsch', 'Lesen'])



class TourRealKartTouchTests(unittest.TestCase):
    """Regression from the actual Build 1995 Android UI hierarchy."""

    def test_clipped_one_pixel_kart_button_scrolls_before_press(self):
        package = TOUR_MODULE.PACKAGE

        def rect(value, y0, y1, *, clickable=False, scrollable=False):
            return {
                'package': package, 'text': '', 'content-desc': value,
                'bounds': f'[68,{y0}][1012,{y1}]',
                'enabled': 'true',
                'clickable': 'true' if clickable else 'false',
                'scrollable': 'true' if scrollable else 'false',
            }

        # GitHub run 39622472973: the launcher claimed a clickable button,
        # but exposed only y=1992..1993; the recorded tap never opened Godot.
        clipped = rect('Losfahren', 1992, 1993, clickable=True)
        usable = rect('Losfahren', 1250, 1380, clickable=True)
        scroll = rect('', 100, 1940, scrollable=True)
        with tempfile.TemporaryDirectory() as temp, \
                patch.object(TOUR_MODULE.probe.live, 'live_nodes',
                             side_effect=[[clipped, scroll], [usable, scroll]]), \
                patch.object(TOUR_MODULE.probe, 'recover_launcher_dialog',
                             return_value=False), \
                patch.object(TOUR_MODULE.base, 'adb') as adb, \
                patch.object(TOUR_MODULE.probe.time, 'sleep'):
            label = TOUR_MODULE.try_tap(Path(temp), ['Losfahren'], 'open-kart')
        self.assertEqual(label, 'Losfahren')
        motions = [call.args for call in adb.call_args_list]
        self.assertEqual(len(motions), 2)
        self.assertEqual(motions[0][0:3], ('shell', 'input', 'swipe'))
        self.assertGreater(int(motions[0][4]), int(motions[0][6]),
                           'Kart must scroll toward the bottom before tapping')
        self.assertEqual(motions[1], ('shell', 'input', 'swipe',
                                      '540', '1315', '540', '1315', '120'))

    def test_too_small_or_invalid_touch_threshold_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            for height in (-1, 0, 201):
                with self.subTest(height=height):
                    with self.assertRaises(ValueError):
                        TOUR_MODULE.probe.flutter_tap(
                            Path(temp), 'Losfahren', 'guard',
                            min_visible_height_px=height)


@unittest.skipUnless(shutil.which('tesseract'), 'tesseract OCR is required')
class TourKartLandingStartTests(unittest.TestCase):
    """The NextGen landing (Godot 700baf49) puts its golden START bottom-left.

    Unified run 39720099333 never found it: the gold-pill fallback only
    scanned the bottom-right corner of the classic garage's Weiter button.
    """

    FIXTURES = ROOT / 'tools/android_qa/tests/fixtures'

    def test_real_landing_start_is_found_bottom_left(self):
        for name, (width, height) in (('landing-1280x720.jpg', (1280, 720)),
                                      ('landing-2400x1080.jpg', (2400, 1080))):
            with self.subTest(name=name):
                png = (self.FIXTURES / 'kart-landing-700baf49' / name).read_bytes()
                point = TOUR_MODULE._read_garage_footer(png, 'START')
                self.assertIsNotNone(point)
                # The left action, not "Zurück zur Spielewelt" on the right.
                self.assertLess(point[0], width * .5)
                self.assertGreater(point[1], height * .85)
                self.assertIsNone(TOUR_MODULE._read_garage_footer(png, 'Weiter'))

    def test_real_android_garage_keeps_weiter_and_has_no_start(self):
        png = (self.FIXTURES / 'kart-garage-api35/garage-step1-640x320.png').read_bytes()
        weiter = TOUR_MODULE._read_garage_footer(png, 'Weiter')
        self.assertIsNotNone(weiter)
        self.assertGreater(weiter[0], 640 * .6)
        self.assertIsNone(TOUR_MODULE._read_garage_footer(png, 'START'))


class TourRaceModeTests(unittest.TestCase):
    def test_premium_start_binds_the_tour_to_the_real_grand_prix_mode(self):
        with tempfile.TemporaryDirectory() as temp, \
                patch.object(TOUR_MODULE, 'godot_alive', return_value=True), \
                patch.object(TOUR_MODULE, '_screencap', return_value=b'frame'), \
                patch.object(TOUR_MODULE, '_read_garage_footer', return_value=(20, 30)), \
                patch.object(TOUR_MODULE.time, 'sleep'), \
                patch.object(TOUR_MODULE.base, 'adb', return_value=
                             '[Kart] race_world_ready: sonnenhafen mode=cup'), \
                patch.object(TOUR_MODULE.evidence, 'garage_replaced', return_value={}), \
                patch.object(TOUR_MODULE.evidence, 'rendered_race_frame', return_value={}):
            report = TOUR_MODULE._start_actual_embedded_race(Path(temp))
        self.assertEqual(report['expected_mode'], 'cup')
        self.assertEqual(report['expected_track'], 'sonnenhafen')

    def test_running_clock_uses_the_launch_expectation(self):
        state = {'mode': 'cup', 'track_id': 'sonnenhafen', 'finished': False,
                 'completed_race': False, 'countdown': 0, 'elapsed': 2,
                 'distance': 0, 'result_id': 'actual-race'}
        session = SimpleNamespace(expected_mode='cup', expected_track='sonnenhafen',
                                  read=lambda _: state)
        with patch.object(TOUR_MODULE, 'godot_alive', return_value=True), \
                patch.object(TOUR_MODULE.time, 'sleep'), \
                patch.object(TOUR_MODULE.time, 'monotonic', side_effect=[0, 0, 2]):
            self.assertEqual(TOUR_MODULE.wait_race_running(session, timeout=1), state)


if __name__ == '__main__':
    unittest.main()
