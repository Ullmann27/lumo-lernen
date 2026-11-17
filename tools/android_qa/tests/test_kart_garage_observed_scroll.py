"""Replay the two real 1e22 Garage failures without running Android or OCR.

The fixtures are unchanged API35 captures and OCR outputs. These regression
checks constrain proposed touches; they do not establish a successful race.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence
from test_modernization_tour_identity import TOUR_MODULE as tour


FIXTURES = Path(__file__).with_name('fixtures') / 'kart-scroll-1e22'


class RealGarageScrollObservationsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.provenance = json.loads((FIXTURES / 'provenance.json').read_text())
        for name, series in cls.provenance['series'].items():
            for entry in series['files']:
                raw = (FIXTURES / name / entry['file']).read_bytes()
                if len(raw) != entry['bytes'] or hashlib.sha256(raw).hexdigest() != entry['sha256']:
                    raise AssertionError('Original fixture bytes changed: ' + name + '/' + entry['file'])

    def original(self, name, index):
        folder = FIXTURES / name
        journal = json.loads((folder / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        frame = journal['frames'][index]
        source = folder / frame['source']
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), frame['source_sha256'])
        with Image.open(source) as image:
            self.assertEqual(list(image.size), frame['pixels'])
        lines = json.loads((folder / f'21_stage_select_gecko_velo-{index}-ocr.json').read_text())
        return frame, lines, source

    def test_real_original_sources_keep_every_drag_inside_the_visible_caption(self):
        for name in ('android', 'update'):
            with self.subTest(original=name):
                frame, lines, _ = self.original(name, 0)
                plan = evidence.stage_garage_scroll_observation(frame, lines)
                original_card = frame['missing_caption_recovery']['card']['bounds']
                x0, y0, x1, y1 = original_card
                x, start, end_x, end = plan['gesture']
                self.assertTrue(x0 < x == end_x < x1)
                self.assertTrue(y0 < end < start < y1,
                                f'{name}: {plan["gesture"]} leaves observed caption {original_card}')
                self.assertGreaterEqual(start - end, 15)

    def test_both_actual_clipped_name_frames_have_a_complete_current_pixel_anchor(self):
        for name in ('android', 'update'):
            with self.subTest(original=name):
                frame, lines, source = self.original(name, 2)
                self.assertFalse(any(evidence.normalize(row['text']) in
                                     {'comet', 'geckovelo', 'borurally', 'glider', 'nalacomet', 'noatide'}
                                     for row in lines))
                plan = evidence.stage_garage_scroll_observation(frame, lines, source=source)
                self.assertEqual(plan['anchor_kind'], 'current-stat-bars')
                self.assertEqual(len(plan['bars']), 5)
                self.assertEqual(plan['pixel_source']['sha256'], frame['source_sha256'])
                self.assertEqual(plan['pixel_source']['bytes'], source.stat().st_size)
                self.assertNotIn('card', plan)
                self.assertNotIn('kart', plan)
                self.assertNotIn('selected_kart', plan)
                x, start, end_x, end = plan['gesture']
                self.assertEqual(x, end_x)
                self.assertTrue(all(box[0] < x < box[2] for box in plan['bars']))
                self.assertTrue(plan['bars'][0][1] < end < plan['bars'][0][3])
                self.assertTrue(plan['bars'][-1][1] < start < plan['bars'][-1][3])
                with Image.open(source) as image:
                    for y in (start, end):
                        self.assertIn(image.getpixel((x, y))[:3], ((95, 227, 255), (130, 233, 255)))

    def test_changed_anchor_kind_needs_two_current_observations_before_any_drag(self):
        frame, lines, source = self.original('android', 0)
        clipped, clipped_lines, clipped_source = self.original('android', 2)
        callback = tour._stage_kart_scroll_recovery()
        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', return_value=0):
            first = callback(frame, lines, source, deadline=150, previous_missing_frame=None)
            self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
            changed = callback(clipped, clipped_lines, clipped_source,
                               deadline=150, previous_missing_frame=frame)
            self.assertEqual(changed['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
            adb.assert_not_called()
            stable = callback(clipped, clipped_lines, clipped_source,
                              deadline=150, previous_missing_frame=clipped)
            self.assertEqual(stable['status'], 'SWIPE_SENT')
            adb.assert_called_once_with('shell', 'input', 'swipe',
                                        *map(str, stable['gesture']), '650', timeout=15)

    def test_existing_five_gesture_limit_and_deadline_are_still_hard_boundaries(self):
        frame, lines, source = self.original('update', 0)
        callback = tour._stage_kart_scroll_recovery()
        with patch.object(tour.base, 'adb') as adb, \
                patch.object(tour.time, 'monotonic', return_value=0):
            for number in range(5):
                callback(frame, lines, source, deadline=150, previous_missing_frame=None)
                result = callback(frame, lines, source, deadline=150, previous_missing_frame=frame)
                self.assertEqual(result['swipe_number'], number + 1)
            callback(frame, lines, source, deadline=150, previous_missing_frame=None)
            with self.assertRaisesRegex(RuntimeError, 'five observed'):
                callback(frame, lines, source, deadline=150, previous_missing_frame=frame)
            self.assertEqual(adb.call_count, 5)
            adb.reset_mock()
            callback = tour._stage_kart_scroll_recovery()
            callback(frame, lines, source, deadline=150, previous_missing_frame=None)
            with self.assertRaisesRegex(RuntimeError, 'deadline'):
                callback(frame, lines, source, deadline=0, previous_missing_frame=frame)
            adb.assert_not_called()

    def test_unbound_original_png_never_supplies_a_pixel_fallback(self):
        frame, lines, source = self.original('android', 2)
        with self.assertRaisesRegex(RuntimeError, 'surface observation'):
            evidence.stage_garage_scroll_observation(
                dict(frame, source_sha256='0' * 64), lines, source=source)


class GaragePixelAnchorRejectionTests(unittest.TestCase):
    """Synthetic negative geometry; these images are not Android evidence."""

    def setUp(self):
        self.folder = tempfile.TemporaryDirectory()
        self.addCleanup(self.folder.cleanup)
        self.root = Path(self.folder.name)
        self.lines = [
            {'text': 'Karts', 'bounds': [1153, 295, 1246, 323]},
            {'text': 'Lack, Teile & Effekte', 'bounds': [213, 727, 594, 762]},
            {'text': 'Kart-Menü', 'bounds': [469, 899, 758, 933]},
            {'text': 'Rennen starten', 'bounds': [1614, 899, 1966, 934]},
        ]
        self.bars = [[312, 421 + row * 18, 312 + width, 428 + row * 18]
                     for row, width in enumerate((237, 237, 169, 271, 169))]

    def observe(self, bars, *, color=(95, 227, 255), lines=None):
        image = Image.new('RGB', (2400, 1080), (6, 21, 44))
        draw = ImageDraw.Draw(image)
        for x0, y0, x1, y1 in bars:
            draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=color)
        source = self.root / 'synthetic-stat-block.png'
        image.save(source)
        raw = source.read_bytes()
        frame = {'acceptable_for_target_sampling': True, 'pixels': [2400, 1080],
                 'source_sha256': hashlib.sha256(raw).hexdigest(), 'source_bytes': len(raw)}
        return evidence.stage_garage_scroll_observation(
            frame, self.lines if lines is None else lines, source=source)

    def test_synthetic_control_has_one_geometry_only_anchor(self):
        result = self.observe(self.bars)
        self.assertEqual(result['anchor_kind'], 'current-stat-bars')
        self.assertEqual(result['bars'], self.bars)
        self.assertNotIn('anchor_caption', result)

    def test_missing_partial_misaligned_and_irregular_blocks_are_rejected(self):
        clipped = [list(box) for box in self.bars]
        clipped[0][1] += 4
        misaligned = [list(box) for box in self.bars]
        misaligned[2][0] += 40
        irregular = [list(box) for box in self.bars]
        irregular[2][1] += 5
        irregular[2][3] += 5
        for bars in ([], self.bars[:-1], clipped, misaligned, irregular):
            with self.subTest(bars=bars), self.assertRaises(RuntimeError):
                self.observe(bars)

    def test_right_hand_and_duplicate_left_blocks_are_rejected(self):
        right = [[x0 + 1300, y0, x1 + 1300, y1] for x0, y0, x1, y1 in self.bars]
        duplicate = self.bars + [[x0, y0 + 110, x1, y1 + 110]
                                 for x0, y0, x1, y1 in self.bars]
        for bars in (right, duplicate):
            with self.subTest(bars=bars), self.assertRaises(RuntimeError):
                self.observe(bars)

    def test_wrong_color_and_missing_local_context_are_rejected(self):
        with self.assertRaises(RuntimeError):
            self.observe(self.bars, color=(95, 190, 255))
        for lines in (self.lines[1:], self.lines[:1] + self.lines[2:], self.lines[:2]):
            with self.subTest(lines=lines), self.assertRaises(RuntimeError):
                self.observe(self.bars, lines=lines)


if __name__ == '__main__':
    unittest.main()
