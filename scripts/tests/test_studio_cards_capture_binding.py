"""Bind current Cards and shared mobile-layout images to their actual scenes.

These are synthetic archive-contract tests, not Android or visual acceptance.
"""
import hashlib
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_studio_delivery as delivery
import test_studio_delivery as studio_contracts


PROBE = 'studio-evidence/captures/cards_safe_area_regression'
MOBILE_PROBE = 'studio-evidence/captures/mobile_safe_area_regression'
MOBILE_MODULES = ('jump', 'build', 'puzzle', 'treasure')


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

    def test_each_shared_mobile_capture_maps_to_its_actual_production_scene(self):
        for module in MOBILE_MODULES:
            entry = MOBILE_PROBE + '/' + module + '-landscape-cutout.png'
            with self.subTest(module=module):
                self.assertEqual(delivery.capture_module(entry), module)
                self.assertEqual(delivery.reviewed_relative_path('a' * 64, module, entry),
                    str(delivery.REVIEW_DIRECTORY / ('a' * 64 + '-' + module + '-' +
                                                     module + '-landscape-cutout.png')))

    def test_shared_mobile_probe_does_not_guess_unknown_names_or_wrong_modules(self):
        for filename in ('actual.png', 'cards-landscape-cutout.png', 'build-landscape.png',
                         'build-landscape-cutout-copy.png', 'Jump-landscape-cutout.png',
                         'jump-landscape-cutout.png/other.png'):
            with self.subTest(filename=filename), self.assertRaises(ValueError):
                delivery.capture_module(MOBILE_PROBE + '/' + filename)
        for module in MOBILE_MODULES:
            entry = MOBILE_PROBE + '/' + module + '-landscape-cutout.png'
            with self.subTest(module=module), self.assertRaises(ValueError):
                delivery.reviewed_relative_path('a' * 64, 'cards', entry)

    def test_original_shared_mobile_images_roundtrip_through_archive_and_receipt(self):
        args = self.fixture.review_fixture()
        changes = {}
        selected = {}
        for index, module in enumerate(MOBILE_MODULES):
            filename = module + '-landscape-cutout.png'
            entry = MOBILE_PROBE + '/' + filename
            data = studio_contracts.historical_tests.fixture_png(2400, 1080, 80 + index)
            digest = hashlib.sha256(data).hexdigest()
            # Explicit synthetic archive member, not a native render claim.
            relative = str(delivery.REVIEW_DIRECTORY / (digest + '-' + module + '-' + filename))
            path = args[0] / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
            changes[entry] = data
            selected[entry] = module
            args[1]['images'].append({'path': relative, 'dimensions': [2400, 1080],
                'module': module, 'sha256': digest, 'artifact_entry': entry,
                'findings': 'Synthetic original-archive binding fixture; no visual approval'})
        self.fixture.archive_change(args, changes)
        facts = delivery.verify_visual_review(*args)
        self.assertEqual(facts['images'], len(delivery.CAPTURE_MODULES) + 4)
        self.assertEqual(facts['reviewed_cards_safe_area_capture_probe'], PROBE)
        recorded = self.fixture.record(args)
        actual = {item['artifact_entry']: item['module'] for item in recorded['images']
                  if item['artifact_entry'] in selected}
        self.assertEqual(actual, selected)
        for item in recorded['images']:
            if item['artifact_entry'] in selected:
                copied = self.fixture.base / 'recorded' / item['path']
                self.assertEqual(copied.read_bytes(), changes[item['artifact_entry']])


if __name__ == '__main__':
    unittest.main()
