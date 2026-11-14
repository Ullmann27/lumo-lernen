"""Actual 61c Android HUD pixels must fit the focused OCR ribbon.

The three original PNGs are byte-exact failed-job captures, not recreated
screens. Their source identities and original unsuccessful OCR accompany them.
Only the occluded-raster and overlay cases below are deliberate countercases;
no emulator, touch, saved session or driving success is claimed by this suite.
"""
import hashlib
import inspect
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

sys.dont_write_bytecode = True
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import focused_race_hud_text, focused_race_hud_visible
from test_modernization_tour_identity import TOUR_MODULE as tour


FIXTURES = Path(__file__).parent / 'fixtures/kart-hud-61c'


class CurrentFocusedRaceHudTests(unittest.TestCase):
    def assert_actual_hud(self, name):
        original = json.loads((FIXTURES / (name + '-focused-hud.json')).read_text())
        self.assertFalse(original['three_hud_indicators'])
        self.assertTrue(original['not_paused_or_finished'])
        actual = focused_race_hud_text(FIXTURES / (name + '.png'))
        print(f'Actual raster {name}: {actual!r}', flush=True)
        self.assertTrue(focused_race_hud_visible(actual), actual)

    def test_first_update_original_recovers_all_three_hud_features(self):
        self.assert_actual_hud('update-0')

    def test_last_update_original_recovers_all_three_hud_features(self):
        self.assert_actual_hud('update-17')

    def test_api37_first_attempt_original_recovers_all_three_hud_features(self):
        self.assert_actual_hud('api37-host-20')

    def test_original_fixtures_keep_their_recorded_bytes_and_dimensions(self):
        manifest = json.loads((FIXTURES / 'provenance.json').read_text())
        self.assertEqual(manifest['run_id'], 43551424080)
        self.assertEqual(manifest['qa_source'], '61c94cfb78bda8dfbe191331eca0fd0382deb151')
        self.assertEqual(manifest['apk_source'], '7b16f2f5ab16f3d913ee170aefd9807c87216260')
        for case in manifest['cases']:
            for row in case['files']:
                with self.subTest(fixture=row['fixture']):
                    source = FIXTURES / row['fixture']
                    data = source.read_bytes()
                    self.assertEqual(len(data), row['bytes'])
                    self.assertEqual(hashlib.sha256(data).hexdigest(), row['sha256'])
                    if source.suffix == '.png':
                        with Image.open(source) as image:
                            image.load()
                            self.assertEqual(image.size, (2400, 1080))

    def test_incomplete_current_hud_letters_do_not_become_a_visual_pass(self):
        # Deliberate negative derivative, never an original or evidence frame:
        # remove the letter pixels below the old cut, leaving the top half.
        with tempfile.TemporaryDirectory() as work:
            path = Path(work) / 'synthetic-half-drawn.png'
            with Image.open(FIXTURES / 'update-0.png') as source:
                damaged = source.convert('RGB')
            ImageDraw.Draw(damaged).rectangle((600, 162, 1799, 215), fill='#26303B')
            damaged.save(path)
            actual = focused_race_hud_text(path)
            self.assertFalse(focused_race_hud_visible(actual), actual)

    def test_existing_pause_and_result_guards_reject_a_readable_real_hud(self):
        # Read real HUD pixels once. Only the separate full-frame overlay
        # observation and clock below are synthetic: no device is touched.
        actual = focused_race_hud_text(FIXTURES / 'update-0.png')
        self.assertTrue(focused_race_hud_visible(actual), actual)
        for caption in ('Weiterfahren', 'Kleine Pause', 'geschafft', 'Noch ein Rennen'):
            frame = {'text': caption, 'lines': [{'text': caption}]}
            with self.subTest(caption=caption), tempfile.TemporaryDirectory() as work:
                out = Path(work)
                with patch.object(tour, '_shot', return_value=b'no-new-device-capture'), \
                        patch.object(tour, 'read_frame', return_value=frame), \
                        patch.object(tour, 'focused_race_hud_text', return_value=actual), \
                        patch.object(tour.time, 'monotonic', side_effect=[0, 0, 91]), \
                        patch.object(tour.time, 'sleep'), \
                        patch.object(tour.evidence, 'rendered_race_frame') as pixels, \
                        patch.object(tour.base, 'adb') as adb:
                    with self.assertRaisesRegex(RuntimeError, 'No current race HUD'):
                        tour.wait_race_hud(out)
                report = json.loads((out / '21_race_hud_0-focused-hud.json').read_text())
                self.assertTrue(report['three_hud_indicators'])
                self.assertFalse(report['not_paused_or_finished'])
                self.assertFalse((out / '21_race_hud.png').exists())
                pixels.assert_not_called()
                adb.assert_not_called()

    def test_observation_budget_and_three_feature_guard_remain_strict(self):
        self.assertEqual(inspect.signature(tour.wait_race_hud).parameters['timeout'].default, 90)
        for partial in ('RUNDE 1/2 PLATZ 6/6', 'RUNDE 1/2 0 km/h',
                        'PLATZ 6/6 0 km/h', 'RUNDE 3/2 PLATZ 6/6 0 km/h',
                        'RUNDE 1/2 PLATZ 7/6 0 km/h'):
            with self.subTest(partial=partial):
                self.assertFalse(focused_race_hud_visible(partial))


if __name__ == '__main__':
    unittest.main()
