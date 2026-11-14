"""Replay current C2 Android frames; mock input never proves device acceptance."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence
from test_modernization_tour_identity import TOUR_MODULE as tour
from test_kart_garage_evidence import list_frame, list_lines, race


FIXTURES = Path(__file__).with_name('fixtures') / 'kart-scroll-c2f2'


def fixture(case):
    root = FIXTURES / case
    frame = json.loads((root / 'surface-frame.json').read_text())
    lines = json.loads((root / '21_stage_select_gecko_velo-2-ocr.json').read_text())
    return root / frame['source'], frame, lines


def command(*args, timeout):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout, check=True)
    return result.stdout + result.stderr


def synthetic_tsv(prefix, words):
    # Synthetic negative inputs, never substitutes for the original OCR replay.
    header = 'level page_num block_num par_num line_num word_num left top width height conf text'.split()
    rows = ['\t'.join(header)]
    for number, (text, left, top, width, height, line, confidence) in enumerate(words, 1):
        values = [5, 1, 1, 1, line, number, left, top, width, height, confidence, text]
        rows.append('\t'.join(map(str, values)))
    Path(prefix).with_suffix('.tsv').write_text('\n'.join(rows) + '\n')


BORU_WORDS = [('Boru', 902, 594, 173, 56, 1, 96),
              ('Rally', 1106, 594, 189, 72, 1, 96)]


class GarageCurrentFrameOCRTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        original, self.frame, self.lines = fixture('main')
        self.source = self.out / original.name
        shutil.copyfile(original, self.source)
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(), self.frame['source_sha256'])

    def fake_command(self, words=BORU_WORDS):
        def run(*args, **kwargs):
            self.assertEqual(args[0], 'tesseract')
            self.assertEqual(args[3:], ('--psm', '11', '-l', 'eng', 'tsv'))
            self.assertGreater(kwargs['timeout'], 0)
            synthetic_tsv(args[2], words)
            return 'synthetic OCR response for a rejection test'
        return run

    @unittest.skipUnless(shutil.which('tesseract'), 'The original-frame replay requires Tesseract')
    def test_current_original_boru_frame_recovers_full_name_and_bounded_reverse_anchor(self):
        with self.assertRaisesRegex(RuntimeError, 'No currently visible vehicle card'):
            evidence.stage_garage_scroll_observation(self.frame, self.lines)
        callback = tour._stage_kart_scroll_recovery('gecko_velo')
        with patch.object(tour.base, 'command', side_effect=command), patch.object(tour.base, 'adb') as adb:
            result = callback(self.frame, self.lines, self.source,
                              deadline=time.monotonic() + 30, previous_missing_frame=None)
        adb.assert_not_called()
        self.assertEqual(result['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
        self.assertEqual(result['direction'], 'earlier')
        self.assertEqual(evidence.normalize(result['card']['text']), 'borurally')
        # Bounds are measured by OCR from the full original PNG, not supplied
        # to the reader. This envelope covers the actual visible glyphs.
        x0, y0, x1, y1 = result['card']['bounds']
        self.assertTrue(449 <= x0 <= 453 and 618 <= y0 <= 622)
        self.assertTrue(646 <= x1 <= 650 and 654 <= y1 <= 658)
        x, start, end_x, end = result['gesture']
        self.assertEqual(x, end_x)
        self.assertTrue(x0 < x < x1 and y0 < start < end < y1)
        self.assertEqual(result['card_ocr']['crop'], [0, 323, 1200, 899])
        self.assertEqual(result['card_ocr']['source_sha256'], self.frame['source_sha256'])
        self.assertEqual(hashlib.sha256(self.source.read_bytes()).hexdigest(), self.frame['source_sha256'])

    def test_partial_similar_or_cross_line_names_never_supply_a_scroll_anchor(self):
        cases = [BORU_WORDS[:1],
                 [BORU_WORDS[0], ('Rallye', 1106, 594, 189, 72, 1, 96)],
                 [BORU_WORDS[0], ('Rally', 1106, 594, 189, 72, 2, 96)],
                 [BORU_WORDS[0], ('Rally', 1106, 594, 189, 72, 1, 14)],
                 [('Super', 700, 594, 180, 56, 1, 96), *BORU_WORDS],
                 [BORU_WORDS[0], ('Unknown', 1080, 594, 20, 56, 1, 14), BORU_WORDS[1]],
                 [('Unknown', 902, 594, 173, 56, 1, 96)]]
        for words in cases:
            with self.subTest(words=words), patch.object(tour.base, 'command', side_effect=self.fake_command(words)), \
                    patch.object(tour.base, 'adb') as adb, \
                    self.assertRaisesRegex(RuntimeError, 'No currently visible vehicle card'):
                tour._stage_kart_scroll_recovery('gecko_velo')(
                    self.frame, self.lines, self.source, deadline=time.monotonic() + 10,
                    previous_missing_frame=None)
            adb.assert_not_called()

    def test_complete_nala_comet_does_not_also_create_a_partial_comet_card(self):
        words = [('Nala', 902, 594, 173, 56, 1, 96),
                 ('Comet', 1106, 594, 189, 72, 1, 96)]
        observed = evidence.stage_garage_card_observations(
            self.source, self.frame, self.lines, self.fake_command(words))
        self.assertEqual([evidence.normalize(row['text']) for row in observed['cards']], ['nalacomet'])

    def test_outside_or_crop_clipped_words_do_not_create_a_card(self):
        outside = [('Boru', 2450, 594, 173, 56, 1, 96),
                   ('Rally', 2650, 594, 189, 72, 1, 96)]
        with self.assertRaisesRegex(RuntimeError, 'bounds exceed'):
            evidence.stage_garage_card_observations(
                self.source, self.frame, self.lines, self.fake_command(outside))
        clipped = [('Boru', 2100, 594, 100, 56, 1, 96),
                   ('Rally', 2200, 594, 200, 72, 1, 96)]
        observed = evidence.stage_garage_card_observations(
            self.source, self.frame, self.lines, self.fake_command(clipped))
        self.assertEqual(observed['cards'], [])

    def test_stale_source_incomplete_surface_dimensions_and_missing_anchors_prevent_ocr(self):
        invalid_bounds = copy.deepcopy(self.lines)
        next(row for row in invalid_bounds if evidence.normalize(row['text']) == 'karts')['bounds'][3] = float('nan')
        cases = [(dict(self.frame, source_sha256='0' * 64), self.lines),
                 (dict(self.frame, source='another-frame.png'), self.lines),
                 (dict(self.frame, acceptable_for_target_sampling=False), self.lines),
                 (dict(self.frame, pixels=[1200, 540]), self.lines),
                 (self.frame, [row for row in self.lines if evidence.normalize(row['text']) != 'karts']),
                 (self.frame, invalid_bounds)]
        for frame, lines in cases:
            with self.subTest(frame=frame), patch.object(tour.base, 'command') as process, self.assertRaises(RuntimeError):
                evidence.stage_garage_card_observations(self.source, frame, lines, process)
            process.assert_not_called()

    def test_changed_source_and_expired_deadline_reject_observed_words(self):
        def replace(*args, **kwargs):
            self.fake_command()(*args, **kwargs)
            self.source.write_bytes(b'replaced after sampling')
            return ''
        with self.assertRaisesRegex(RuntimeError, 'screenshot changed during OCR'):
            evidence.stage_garage_card_observations(self.source, self.frame, self.lines, replace)
        shutil.copyfile(fixture('main')[0], self.source)
        ticks = iter([0, 16, 16])
        with patch.object(tour.base, 'command') as process, self.assertRaises(TimeoutError):
            evidence.stage_garage_card_observations(self.source, self.frame, self.lines, process,
                                                    timeout=15, clock=lambda: next(ticks))
        process.assert_not_called()
        ticks = iter([0, 0, 16, 16])
        with self.assertRaises(TimeoutError):
            evidence.stage_garage_card_observations(self.source, self.frame, self.lines,
                                                    self.fake_command(), timeout=15,
                                                    clock=lambda: next(ticks))


class GarageDirectionAndTouchTests(unittest.TestCase):
    def test_current_successful_update_uses_real_full_gecko_without_recovery(self):
        original, frame, lines = fixture('update')
        with tempfile.TemporaryDirectory() as folder:
            out = Path(folder)
            def capture(_out, tag, **_kwargs):
                shutil.copyfile(original, out / (tag + '.png'))
                return {'file': tag + '.png'}
            with patch.object(tour.probe, 'capture', side_effect=capture), \
                    patch.object(tour.probe, 'image_lines', return_value=lines), \
                    patch.object(evidence, 'stage_garage_card_observations') as fallback, \
                    patch.object(tour.base, 'adb') as adb, patch.object(tour.probe.time, 'sleep'):
                result = tour._select_stage_kart(out, 'gecko_velo')
            fallback.assert_not_called()
            self.assertEqual(result['touch'], [554, 528])
            adb.assert_called_once_with('shell', 'input', 'swipe', '554', '528', '554', '528', '120',
                                        timeout=unittest.mock.ANY)
            journal = json.loads((out / result['readiness']).read_text())
            self.assertEqual([row['target']['stable_observed_target'] for row in journal['frames']], [False, True])
            self.assertTrue(all(row['source_sha256'] == frame['source_sha256'] for row in journal['frames']))

    def test_comet_before_gecko_scrolls_forward_and_boru_after_it_scrolls_back(self):
        before = evidence.stage_garage_scroll_observation(list_frame(), list_lines(), target_kart='gecko_velo')
        self.assertEqual(before['gesture'], [175, 320, 175, 208])
        after = copy.deepcopy(list_lines())
        after[1]['text'] = 'Boru Rally'
        back = evidence.stage_garage_scroll_observation(list_frame(), after, target_kart='gecko_velo')
        self.assertEqual(back['direction'], 'earlier')
        self.assertTrue(300 < back['gesture'][1] < back['gesture'][3] < 340)
        # The original native selection contract still excludes the locked kart.
        with self.assertRaises(RuntimeError):
            evidence.require_selected_race(race(selected_kart='boru_rally'), 'gecko_velo')

    def test_unknown_ambiguous_duplicate_or_already_visible_cards_do_not_scroll(self):
        wrong_side = list_lines()
        wrong_side[1]['bounds'] = [1500, 300, 1700, 340]
        cases = []
        for label in ('Boru', 'Boru Rallye', 'Unknown', 'Gecko Velo'):
            lines = list_lines()
            lines[1]['text'] = label
            cases.append(lines)
        cases.extend([wrong_side,
                      list_lines() + [{'text': 'Boru Rally', 'bounds': [100, 450, 250, 490]}],
                      list_lines() + [{'text': 'Comet', 'bounds': [100, 450, 250, 490]}]])
        conflicting = list_lines()
        conflicting[1]['text'] = 'Boru Rally'
        conflicting.append({'text': 'Glider', 'bounds': [100, 300, 250, 340]})
        cases.append(conflicting)
        for lines in cases:
            with self.subTest(lines=lines), self.assertRaises(RuntimeError):
                evidence.stage_garage_scroll_observation(list_frame(), lines, target_kart='gecko_velo')
        with self.assertRaises(RuntimeError):
            evidence.stage_garage_scroll_observation(list_frame(), list_lines(), target_kart='boru_rally')

    def test_direction_changes_reduce_current_span_and_keep_two_frames_hash_deadline_and_budget(self):
        with tempfile.TemporaryDirectory() as folder:
            source = Path(folder) / 'synthetic-observation.png'
            source.write_bytes(b'synthetic current-frame bytes')
            frame = dict(list_frame(), source_sha256=hashlib.sha256(source.read_bytes()).hexdigest())
            callback = tour._stage_kart_scroll_recovery('gecko_velo')
            spans = []
            with patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'monotonic', return_value=0):
                for index, name in enumerate(('Comet', 'Boru Rally', 'Comet', 'Boru Rally', 'Comet')):
                    lines = list_lines()
                    lines[1]['text'] = name
                    first = callback(frame, lines, source, deadline=10, previous_missing_frame=None)
                    self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
                    self.assertEqual(adb.call_count, index)
                    second = callback(frame, lines, source, deadline=10, previous_missing_frame=frame)
                    self.assertEqual(second['status'], 'SWIPE_SENT')
                    self.assertEqual(second['direction_changes'], index)
                    span = abs(second['gesture'][3] - second['gesture'][1])
                    spans.append(span)
                    if index:
                        self.assertTrue(300 < min(second['gesture'][1::2]) < max(second['gesture'][1::2]) < 340)
                self.assertGreater(spans[0], spans[1])
                self.assertGreater(spans[1], spans[2])
                self.assertTrue(all(left >= right for left, right in zip(spans, spans[1:])))
                callback(frame, lines, source, deadline=10, previous_missing_frame=None)
                with self.assertRaisesRegex(RuntimeError, 'five observed list gestures'):
                    callback(frame, lines, source, deadline=10, previous_missing_frame=frame)
                self.assertEqual(adb.call_count, 5)
                for changed, deadline in ((False, 0), (True, 10)):
                    fresh = tour._stage_kart_scroll_recovery('gecko_velo')
                    fresh(frame, lines, source, deadline=10, previous_missing_frame=None)
                    if changed:
                        source.write_bytes(b'changed after sampling')
                    with self.assertRaises(RuntimeError):
                        fresh(frame, lines, source, deadline=deadline, previous_missing_frame=frame)
                    self.assertEqual(adb.call_count, 5)


if __name__ == '__main__':
    unittest.main()
