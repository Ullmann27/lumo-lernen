"""Current Cards layout images must supplement the existing scene evidence.

These are synthetic archive-contract tests, not Android or visual acceptance.
"""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_studio_delivery as delivery
import test_studio_delivery as studio_contracts


PROBE = 'studio-evidence/captures/cards_safe_area_regression'


class StudioCardsCaptureBindingTests(unittest.TestCase):
    def setUp(self):
        self.fixture = studio_contracts.StudioDeliveryTests('runTest')
        self.fixture.setUp()
        self.addCleanup(self.fixture.doCleanups)

    def test_current_safe_area_capture_is_actual_cards_production_scene(self):
        for filename in ('android35_portrait-playing.png',
                         'android35_portrait-paused.png',
                         'landscape_cutout_fixture-playing.png'):
            with self.subTest(filename=filename):
                self.assertEqual(delivery.capture_module(PROBE + '/' + filename), 'cards')

    def test_existing_cards_images_cannot_replace_current_safe_area_review(self):
        args = self.fixture.review_fixture()
        args[1]['images'] = [entry for entry in args[1]['images']
                             if str(Path(entry['artifact_entry']).parent) != PROBE]
        self.assertEqual({entry['module'] for entry in args[1]['images']},
                         delivery.REVIEW_MODULES)
        self.assertTrue(any(entry['module'] == 'cards' for entry in args[1]['images']))
        with self.assertRaisesRegex(ValueError, 'current Cards safe-area capture'):
            delivery.verify_visual_review(*args)
        destination = self.fixture.base / 'missing-cards-safe-area'
        with self.assertRaisesRegex(ValueError, 'current Cards safe-area capture'):
            self.fixture.record(args, destination)
        self.assertFalse((destination / delivery.REVIEW_RECEIPT).exists())


if __name__ == '__main__':
    unittest.main()
