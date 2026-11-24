"""Replay the failed 2067 Android image; no device or workshop-completion claim."""
import hashlib
import io
import json
from pathlib import Path
import shutil
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

from test_modernization_tour_identity import TOUR_MODULE as tour


FIXTURES = Path(__file__).with_name('fixtures') / 'kart-showroom-2067'


class RequiredWorkshopObservation(Exception):
    """Stop the structural replay at the unchanged post-touch requirement."""


@unittest.skipUnless(shutil.which('tesseract'), 'tesseract OCR is required')
class KartShowroomCaptionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        proof = json.loads((FIXTURES / 'provenance.json').read_text())
        if (proof['run_id'] != 45064686303 or proof['job_id'] != 137346316152
                or proof['source_commit'] != '376217b4e39b726657a8fe96e9868f816f681edf'):
            raise AssertionError('Actual failing screenshot lost its source binding')
        row = proof['files'][0]
        cls.frame = (FIXTURES / row['file']).read_bytes()
        if len(cls.frame) != row['bytes'] or hashlib.sha256(cls.frame).hexdigest() != row['sha256']:
            raise AssertionError('CI log-preview bytes changed')
        with Image.open(io.BytesIO(cls.frame)) as image:
            image.verify()

    def setUp(self):
        import tempfile
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.out = Path(self.folder.name)

    def read(self, caption='Teile wechseln'):
        return tour._read_showroom_action(self.frame, caption, self.out, 'parts')

    def test_actual_ci_button_above_footer_is_read_from_its_visible_component(self):
        point = self.read()
        self.assertIsNotNone(point)
        # Bounds of the visible original control in this 960x432 CI preview,
        # used only as a fixture assertion, never as production touch input.
        self.assertTrue(160 <= point[0] <= 298 and 160 <= point[1] <= 214)
        report = json.loads((self.out / 'parts-component-caption.json').read_text())
        self.assertEqual(report['status'], 'OBSERVED')
        self.assertEqual(report['source_sha256'], hashlib.sha256(self.frame).hexdigest())
        self.assertEqual(len(report['matches']), 1)
        self.assertTrue(any('Teile wechseln' in row['observed_caption']
                            for row in report['components']))

    def test_real_frame_never_accepts_an_absent_action(self):
        self.assertIsNone(self.read('Teile verkaufen'))
        report = json.loads((self.out / 'parts-component-caption.json').read_text())
        self.assertEqual(report['status'], 'NOT_FOUND')

    def test_blank_frame_never_substitutes_a_coordinate(self):
        buffer = io.BytesIO()
        Image.new('RGB', (960, 432), '#081320').save(buffer, 'PNG')
        with patch.object(tour.subprocess, 'run') as ocr:
            self.assertIsNone(tour._read_showroom_action(
                buffer.getvalue(), 'Teile wechseln', self.out, 'blank'))
        ocr.assert_not_called()

    def test_whole_caption_rejects_an_instruction_containing_the_action(self):
        with patch.object(tour.probe, 'gold_caption_boxes', return_value=[[152, 148, 304, 220]]), \
                patch.object(tour.subprocess, 'run', return_value=SimpleNamespace(
                    stdout=b'Bitte Teile wechseln')):
            self.assertIsNone(self.read())

    def test_colour_without_text_cannot_pass(self):
        with patch.object(tour.probe, 'gold_caption_boxes', return_value=[[152, 148, 304, 220]]), \
                patch.object(tour.subprocess, 'run', return_value=SimpleNamespace(stdout=b'')):
            self.assertIsNone(self.read())

    def test_two_distinct_caption_components_fail_closed(self):
        with patch.object(tour.probe, 'gold_caption_boxes',
                          return_value=[[152, 148, 304, 220], [500, 148, 652, 220]]), \
                patch.object(tour.subprocess, 'run',
                             return_value=SimpleNamespace(stdout=b'Teile wechseln')):
            with self.assertRaisesRegex(RuntimeError, 'Ambiguous distinct showroom action'):
                self.read()
        report = json.loads((self.out / 'parts-component-caption.json').read_text())
        self.assertEqual(report['status'], 'FAIL')

    def test_showroom_flow_uses_the_observed_button_and_still_requires_workshop(self):
        def footer(_png, caption, **kwargs):
            if caption == 'Teile wechseln':
                return None  # The proven full-frame/footer reader miss.
            if caption == 'Teilewerkstatt':
                raise RequiredWorkshopObservation()
            return (50, 50)  # Earlier navigation is a structural test stub.

        with patch.object(tour, '_screencap', return_value=self.frame), \
                patch.object(tour, '_read_garage_footer', side_effect=footer), \
                patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'sleep'):
            with self.assertRaises(RequiredWorkshopObservation):
                tour._showroom_after_race(self.out)
        self.assertEqual(adb.call_count, 3)
        args = adb.call_args.args
        self.assertEqual(args[:3], ('shell', 'input', 'tap'))
        self.assertTrue(160 <= int(args[3]) <= 298 and 160 <= int(args[4]) <= 214)
        self.assertEqual((self.out / '22_rueckkehr_garage.png').read_bytes(), self.frame)


if __name__ == '__main__':
    unittest.main()
