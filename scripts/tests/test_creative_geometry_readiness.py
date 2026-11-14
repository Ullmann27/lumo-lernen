"""Original Android image replays and bounded scene-entry transport contracts."""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import re
import sys
import tempfile
from types import SimpleNamespace
import unicodedata
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(os.environ.get('LUMO_CREATIVE_PROBE_SOURCE',
                            str(ROOT / '.github/probes/studio_creative_android_probe.py')))
SPEC = importlib.util.spec_from_file_location('creative_geometry_subject', SOURCE)
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from native_surface_readiness import inspect_surface, target_observation

FIXTURES = Path(__file__).parent / 'fixtures/creative_geometry_86445'


def normalized(value):
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode()
    return re.sub('[^a-z0-9]', '', value.lower())


class GeometryReplays(unittest.TestCase):
    def test_original_portrait_has_one_real_ring(self):
        with probe.read_image(FIXTURES / 'jump-portrait.png') as image:
            target = probe.stick_target(image)
        self.assertAlmostEqual(target['center'][0], 138, delta=2)
        self.assertAlmostEqual(target['center'][1], 1726.5, delta=2)
        self.assertAlmostEqual(target['diameter'], 186, delta=2)
        self.assertGreater(target['ring_fraction'], .95)

    def test_ring_still_rejects_blank_filled_and_duplicate_targets(self):
        with Image.new('RGB', (1080, 1920), (100, 180, 220)) as image:
            with self.assertRaises(RuntimeError):
                probe.stick_target(image)
            draw = ImageDraw.Draw(image)
            draw.ellipse((45, 1634, 231, 1820), fill=(0, 160, 240))
            with self.assertRaises(RuntimeError):
                probe.stick_target(image)
            draw.ellipse((62, 1651, 214, 1803), fill=(12, 30, 70))
            self.assertGreater(probe.stick_target(image)['diameter'], 180)
            draw.ellipse((270, 1634, 456, 1820), fill=(0, 160, 240))
            draw.ellipse((287, 1651, 439, 1803), fill=(12, 30, 70))
            with self.assertRaises(RuntimeError):
                probe.stick_target(image)

    def test_original_puzzle_uses_actual_visible_navy_and_piece(self):
        saved = json.loads((FIXTURES / 'puzzle-save.json').read_text())
        with probe.read_image(FIXTURES / 'puzzle-board.png') as image:
            target = probe.puzzle_piece_target(image, saved)
        # The independent human-reviewed original tray is left of the board.
        self.assertTrue(300 < target['point'][0] < 630)
        self.assertTrue(440 < target['point'][1] < 700)
        self.assertEqual(target['world_tray_center'], [-7.0, .15, -2.2])
        self.assertEqual(len(target['board_corners']), 4)

    def test_puzzle_rejects_blank_wrong_hue_and_duplicate_central_contours(self):
        saved = {'count': 6, 'motif': 1}
        for fill in ('white', (45, 70, 40), (95, 45, 100)):
            with self.subTest(fill=fill), Image.new('RGB', (1920, 1080), fill) as image:
                with self.assertRaises(RuntimeError):
                    probe.puzzle_piece_target(image, saved)
        with Image.new('RGB', (1920, 1080), 'white') as image:
            draw = ImageDraw.Draw(image)
            draw.rectangle((650, 330, 1250, 540), fill=(47, 55, 87))
            draw.rectangle((650, 630, 1250, 840), fill=(47, 55, 87))
            with self.assertRaisesRegex(RuntimeError, 'unique empty navy'):
                probe.puzzle_piece_target(image, saved)

    def test_puzzle_rejects_unobserved_tray_even_with_one_navy_board(self):
        with Image.new('RGB', (1920, 1080), 'white') as image:
            ImageDraw.Draw(image).rectangle((650, 420, 1250, 780), fill=(47, 55, 87))
            with self.assertRaisesRegex(RuntimeError, 'tray center is blank'):
                probe.puzzle_piece_target(image, {'count': 6, 'motif': 1})


class SceneEntryContracts(unittest.TestCase):
    def make_tour(self, directory, frames, *, ocr_seconds=0):
        """Only capture/OCR transport and clock are doubled; no app input."""
        clock = {'now': 0.0}
        observed = {'captures': 0, 'ocr_calls': 0, 'adb': [], 'old_native_calls': 0}
        cursor = {'index': -1}
        cover_lines = json.loads((FIXTURES / 'build-loading-ocr.json').read_text())
        # Synthetic recognized boxes in a real complete production frame. This
        # tests the lifecycle wait, not Tesseract accuracy or Android execution.
        ready_lines = [{'text': 'LUMO BAUWELT', 'bounds': [260, 73, 525, 100]}]

        def capture(_out, _tag, timeout=None):
            self.assertTrue(timeout is None or 0 < timeout <= 45)
            observed['captures'] += 1
            cursor['index'] = min(cursor['index'] + 1, len(frames) - 1)
            name = frames[cursor['index']]
            filename = 'build-loading.png' if name.startswith('cover') else 'build-playing.png'
            path = (FIXTURES / filename).resolve()
            with Image.open(path) as image:
                width, height = image.size
            clock['now'] += .5
            return {'file': str(path), 'width': width, 'height': height,
                    'sha256': probe.sha(path)}

        def image_lines(_out, _tag, _wanted, **kwargs):
            observed['ocr_calls'] += 1
            if 'source_path' not in kwargs:
                capture(_out, _tag)
            clock['now'] += ocr_seconds
            name = frames[cursor['index']]
            if name.startswith('cover'):
                return cover_lines
            if name == 'missing':
                return [{'text': 'An unrelated title', 'bounds': [260, 73, 525, 100]}]
            return ready_lines

        def legacy_native_text(out, label, tag, **_):
            # Exact historical native_text control flow for non-tap entry;
            # its original reader result is the saved loading-cover OCR.
            for _ in range(10):
                lines = image_lines(out, tag, normalized(label))
                if any(normalized(label) in normalized(line['text']) for line in lines):
                    return
                clock['now'] += 2
            raise RuntimeError('Current native screenshot lacks ' + label)

        def inspect(path, **kwargs):
            value = inspect_surface(path, **kwargs)
            # A separate synthetic landscape-cover case proves the cover
            # text check is independently required, not just rotation.
            if frames[cursor['index']] == 'cover-landscape':
                value.update(pixels=[1920, 1080], acceptable_for_target_sampling=True, reasons=[])
            return value

        tour = probe.Tour.__new__(probe.Tour)
        tour.out, tour.counter = Path(directory), 0
        tour.portal = lambda _title: None
        tour.probe = SimpleNamespace(normalized=normalized, capture=capture,
            image_lines=image_lines, inspect_surface=inspect,
            target_observation=target_observation, native_text=legacy_native_text)
        def adb(*args, **_):
            observed['adb'].append(args)
            self.assertNotEqual(args[:2], ('shell', 'input'))
            return '12345'
        tour.base = SimpleNamespace(foreground=lambda: 'LumoGameActivity', adb=adb)
        return tour, clock, observed

    def call_enter(self, tour, clock):
        with patch.object(probe.time, 'monotonic', side_effect=lambda: clock['now']), \
             patch.object(probe.time, 'sleep', side_effect=lambda seconds: clock.__setitem__('now', clock['now'] + seconds)):
            return tour.enter('Bauwelt', 'LUMO BAUWELT')

    def test_original_boot_title_is_not_scene_readiness(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, clock, observed = self.make_tour(directory, ['cover'])
            with self.assertRaises(RuntimeError):
                self.call_enter(tour, clock)
            self.assertLessEqual(observed['captures'], 10)
            self.assertLessEqual(clock['now'], 120)

    def test_landscape_cover_is_rejected_even_when_surface_is_complete(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, clock, observed = self.make_tour(directory, ['cover-landscape'])
            with self.assertRaises(RuntimeError):
                self.call_enter(tour, clock)
            self.assertGreater(observed['ocr_calls'], 0)

    def test_cover_then_two_complete_scene_observations_without_input(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, clock, observed = self.make_tour(directory, ['cover', 'ready', 'ready'])
            self.call_enter(tour, clock)
            journals = list(Path(directory).glob('*-readiness.json'))
            self.assertEqual(len(journals), 1)
            report = json.loads(journals[0].read_text())
            self.assertEqual(report['status'], 'READY')
            self.assertEqual(len(report['frames']), 3)
            self.assertFalse(report['frames'][1]['stable_observed_target'])
            self.assertTrue(report['frames'][2]['stable_observed_target'])
            self.assertFalse(report['input_sent'])

    def test_missing_caption_does_not_pass_or_send_input(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, clock, observed = self.make_tour(directory, ['missing'])
            with self.assertRaises(RuntimeError):
                self.call_enter(tour, clock)
            self.assertLessEqual(clock['now'], 120)

    def test_returning_cover_breaks_the_pair_of_stable_frames(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, clock, observed = self.make_tour(directory, ['ready', 'cover-landscape', 'ready', 'ready'])
            self.call_enter(tour, clock)
            report = json.loads(next(Path(directory).glob('*-readiness.json')).read_text())
            self.assertEqual(len(report['frames']), 4)
            self.assertFalse(report['frames'][2]['stable_observed_target'])

    def test_ocr_finishing_after_deadline_cannot_make_scene_ready(self):
        with tempfile.TemporaryDirectory() as directory:
            tour, clock, observed = self.make_tour(directory, ['ready'], ocr_seconds=60)
            with self.assertRaises(RuntimeError):
                self.call_enter(tour, clock)
            self.assertLessEqual(observed['ocr_calls'], 2)
            self.assertLessEqual(observed['captures'], 2)


if __name__ == '__main__':
    unittest.main()
