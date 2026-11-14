"""Original 3d91 card/OCR replay and bounded synthetic counterexamples.

No Android run, OCR rerun, vehicle selection or race completion is claimed.
"""
from __future__ import annotations

import ast
import copy
import csv
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = Path(os.environ.get('LUMO_KART_WORD_SOURCE_ROOT', ROOT))
HELPER = SOURCE_ROOT / 'tools/android_qa/kart_garage_evidence.py'
TOUR = SOURCE_ROOT / '.github/probes/modernization_android_tour.py'
SPEC = importlib.util.spec_from_file_location('kart_scroll_word_subject', HELPER)
evidence = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(evidence)
FIXTURES = Path(__file__).parent / 'fixtures/kart-scroll-3d91'
TAG = '21_stage_select_gecko_velo-2'
FIELDS = ['level', 'page_num', 'block_num', 'par_num', 'line_num', 'word_num',
          'left', 'top', 'width', 'height', 'conf', 'text']


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class GarageOriginalWordSequenceTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        for source in FIXTURES.glob(TAG + '*'):
            shutil.copyfile(source, self.out / source.name)
        self.source = self.out / (TAG + '.png')
        self.lines = json.loads((self.out / (TAG + '-ocr.json')).read_text())
        readiness = json.loads((FIXTURES / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        self.frame = copy.deepcopy(readiness['frames'][2])
        self.adb = Mock()
        self.clock = SimpleNamespace(monotonic=lambda: 0.0)

    def controller(self):
        module = ast.parse(TOUR.read_text())
        function = next(node for node in module.body if isinstance(node, ast.FunctionDef)
                        and node.name == '_stage_kart_scroll_recovery')
        scope = {'garage_evidence': evidence, 'probe': SimpleNamespace(digest=digest),
                 'base': SimpleNamespace(adb=self.adb), 'time': self.clock, 'Path': Path}
        exec(compile(ast.Module(body=[function], type_ignores=[]), str(TOUR), 'exec'), scope)
        return scope['_stage_kart_scroll_recovery']()

    def recovered(self):
        return evidence.stage_garage_word_observations(self.out, TAG, self.lines)

    def observe(self):
        return evidence.stage_garage_scroll_observation(
            self.frame, self.lines, source=self.source,
            caption_words=self.recovered()['captions'])

    def fresh_observation(self, number):
        # Distinct replay paths model two captures of the unchanged original.
        # They are controlled observations, never a second claimed Android PNG.
        tag = f'current-word-observation-{number}'
        for source in list(self.out.glob(TAG + '*')):
            destination = self.out / (tag + source.name[len(TAG):])
            shutil.copyfile(source, destination)
        source = self.out / (tag + '.png')
        return dict(self.frame, source=source.name), source

    def tsv_rows(self):
        source = self.out / (TAG + '-ocr-raw.tsv')
        reader = csv.DictReader(io.StringIO(source.read_text()), delimiter='\t',
                                quoting=csv.QUOTE_NONE)
        return list(reader)

    def write_rows(self, rows, variant='raw'):
        stream = io.StringIO()
        writer = csv.DictWriter(stream, FIELDS, delimiter='\t', quoting=csv.QUOTE_NONE,
                                quotechar=None, lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)
        (self.out / (TAG + '-ocr-' + variant + '.tsv')).write_text(stream.getvalue())

    @staticmethod
    def synthetic_words(tokens, *, block='900', top=1186, left=629):
        rows = []
        for index, token in enumerate(tokens, 1):
            width = max(20, len(token) * 25)
            rows.append(dict(zip(FIELDS, ['5', '1', block, '1', '1', str(index),
                                         str(left), str(top), str(width), '56', '95', token])))
            left += width + 20
        return rows

    def test_original_boru_frame_recovers_only_scroll_after_two_bound_frames(self):
        callback = self.controller()
        first_frame, first_source = self.fresh_observation(1)
        second_frame, second_source = self.fresh_observation(2)
        first = callback(first_frame, self.lines, first_source, deadline=10,
                         previous_missing_frame=None)
        self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
        self.adb.assert_not_called()
        second = callback(second_frame, self.lines, second_source, deadline=10,
                          previous_missing_frame=first_frame)
        self.assertEqual(second['status'], 'SWIPE_SENT')
        self.assertEqual(second['card']['text'], 'Boru Rally')
        self.assertEqual(second['card']['bounds'], [314.5, 593.0, 511.0, 629.0])
        self.assertEqual(second['direction'], 'backward')
        x0, y0, x1, y1 = second['gesture']
        self.assertEqual(x0, x1)
        self.assertLess(y0, y1)
        self.assertGreaterEqual(y1 - y0, 15)
        self.assertLess(y1 - y0, 40)
        # The unchanged original has its clipped list between y416 and665.
        self.assertTrue(42 < x0 < 750 and 416 < y0 < y1 < 665)
        self.assertEqual(second['caption_source'], 'original_tsv_word_sequences')
        self.assertEqual(len(second['ocr_sources']), 7)
        for source in second['ocr_sources']:
            self.assertEqual(source['sha256'], digest(self.out / source['file']))
        self.adb.assert_called_once_with('shell', 'input', 'swipe',
                                         *map(str, second['gesture']), '650', timeout=10)

    def test_all_original_fixture_bytes_and_pixels_are_bound_to_the_failed_job(self):
        provenance = json.loads((FIXTURES / 'provenance.json').read_text())
        self.assertEqual(provenance['run_id'], 43589206933)
        self.assertEqual(provenance['job_id'], 132447694895)
        self.assertEqual(provenance['artifact_id'], 14114895060)
        self.assertEqual(provenance['host'], '3d91bd8355a539c3c2413760959684cd3fee985a')
        self.assertEqual(provenance['native'], 'bd0712259bb64908a5649ee1999638826c9eb597')
        self.assertEqual(provenance['archive_sha256'],
                         '5a2bcf963a14ac300e1cab483a59c68fd77c1dbcf711110e2fcdab7102a0c790')
        for item in provenance['files']:
            source = FIXTURES / item['path']
            self.assertEqual(source.stat().st_size, item['bytes'])
            self.assertEqual(digest(source), item['sha256'])
            if source.suffix == '.png':
                with Image.open(source) as image:
                    self.assertEqual(image.size, (2400, 1080))
                    image.verify()

    def test_original_line_gap_and_exact_comet_path_use_the_current_clip(self):
        current = evidence.stage_garage_scroll_observation(
            self.frame, self.lines, source=self.source)
        self.assertEqual(current['visible_cards'], [])
        self.assertIsNone(current['card'])
        self.assertIsNone(evidence.stage_kart_target_observation(
            self.frame, self.lines, 'gecko_velo', current['viewport_bounds']))
        # Exact Comet lines remain useful for direction, but the old long
        # gesture is no longer accepted as the geometry of this actual list.
        lines = json.loads((FIXTURES / '21_stage_select_gecko_velo-0-ocr.json').read_text())
        readiness = json.loads((FIXTURES / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        current = evidence.stage_garage_scroll_observation(
            readiness['frames'][0], lines, source=FIXTURES / '21_stage_select_gecko_velo-0.png')
        self.assertEqual(current['card']['text'], 'Comet')
        self.assertEqual(current['direction'], 'forward')
        self.assertNotEqual(current['gesture'], [374, 486, 374, 351])
        self.assertLess(351, current['viewport_bounds'][1])

    def test_known_complete_names_keep_case_whitespace_and_longest_caption(self):
        for caption in ('Comet', 'Gecko Velo', 'Boru Rally', 'Glider', 'Nala Comet', 'Noa Tide'):
            with self.subTest(caption=caption):
                tokens = ['decoration'] + ['  ' + token.swapcase() + '  '
                                           for token in caption.split()] + ['detail']
                self.write_rows(self.synthetic_words(tokens, left=10))
                current = evidence.stage_garage_word_observations(
                    self.out, TAG, [dict(self.lines[0], variant='raw')])
                self.assertEqual([item['text'] for item in current['captions']], [caption])
        # In particular Nala Comet must not yield an additional Comet card.

    def test_partial_interrupted_cross_line_and_word_number_gap_are_rejected(self):
        cases = [
            self.synthetic_words(['BoruX', 'Rally']),
            self.synthetic_words(['Boru', 'extra', 'Rally']),
            self.synthetic_words(['BoruRally']),
        ]
        cross_line = self.synthetic_words(['Boru', 'Rally'])
        cross_line[1]['line_num'] = '2'
        cases.append(cross_line)
        cross_block = self.synthetic_words(['Boru', 'Rally'])
        cross_block[1]['block_num'] = '901'
        cases.append(cross_block)
        gap = self.synthetic_words(['Boru', 'Rally'])
        gap[1]['word_num'] = '3'
        cases.append(gap)
        for rows in cases:
            with self.subTest(rows=rows):
                self.write_rows(rows)
                self.assertEqual(self.recovered()['captions'], [])
                with self.assertRaisesRegex(RuntimeError, 'No currently visible vehicle card'):
                    self.observe()
        self.adb.assert_not_called()

    def test_distant_columns_or_disjoint_word_rows_are_not_joined(self):
        for field, value in [('left', '1800'), ('top', '1300')]:
            with self.subTest(field=field):
                rows = self.synthetic_words(['Boru', 'Rally'])
                rows[1][field] = value
                self.write_rows(rows)
                self.assertEqual(self.recovered()['captions'], [])

    def test_word_confidence_and_original_tsv_presence_remain_mandatory(self):
        rows = self.synthetic_words(['Boru', 'Rally'])
        rows[0]['conf'] = '14.999'
        self.write_rows(rows)
        self.assertEqual(self.recovered()['captions'], [])
        rows[0]['conf'] = 'nan'
        self.write_rows(rows)
        with self.assertRaisesRegex(RuntimeError, 'Nonfinite'):
            self.recovered()
        (self.out / (TAG + '-ocr-raw.tsv')).unlink()
        with self.assertRaisesRegex(RuntimeError, 'TSV is missing'):
            self.recovered()

    def test_invalid_or_outside_word_rectangles_are_rejected(self):
        for field, value in [('width', '0'), ('height', '-1'), ('left', '-2')]:
            with self.subTest(field=field):
                rows = self.synthetic_words(['Boru', 'Rally'])
                rows[0][field] = value
                self.write_rows(rows)
                with self.assertRaisesRegex(RuntimeError, 'Invalid original vehicle word rectangle'):
                    self.recovered()
        self.write_rows(self.synthetic_words(['Boru', 'Rally'], left=5000))
        with self.assertRaisesRegex(RuntimeError, 'bounds exceed'):
            self.observe()

    def test_right_preview_header_and_footer_captions_cannot_be_scroll_cards(self):
        for top, left in [(1186, 3000), (400, 629), (1900, 629)]:
            with self.subTest(top=top, left=left):
                self.write_rows(self.synthetic_words(['Boru', 'Rally'], top=top, left=left))
                with self.assertRaisesRegex(RuntimeError, 'No currently visible vehicle card'):
                    self.observe()
        self.adb.assert_not_called()

    def test_duplicate_real_regions_and_conflicting_names_are_ambiguous(self):
        original = self.tsv_rows()
        duplicate = [dict(row, block_num='999', top=str(int(row['top']) - 160))
                     for row in original if row['level'] == '5' and row['text'] in ('Boru', 'Rally')]
        self.write_rows(original + duplicate)
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous repeated vehicle caption'):
            self.observe()
        self.write_rows(original + self.synthetic_words(['Gecko', 'Velo'], block='998'))
        with self.assertRaisesRegex(RuntimeError, 'Conflicting vehicle captions'):
            self.observe()

    def test_same_card_ocr_variants_remain_one_region_and_top_card_order_is_preserved(self):
        captions = self.recovered()['captions']
        self.assertEqual(len(captions), 1)
        second = dict(captions[0], variant='contrast', bounds=[315.0, 593.0, 511.0, 629.0])
        proof = evidence.stage_garage_scroll_observation(
            self.frame, self.lines, source=self.source, caption_words=captions + [second])
        self.assertEqual(proof['card']['text'], 'Boru Rally')
        comet = {'text': 'Comet', 'bounds': [314.0, 472.0, 434.0, 499.0], 'variant': 'contrast'}
        proof = evidence.stage_garage_scroll_observation(
            self.frame, self.lines, source=self.source, caption_words=captions + [comet])
        self.assertEqual(proof['card'], comet)

    def test_unstable_words_need_a_new_pair_and_changed_png_or_deadline_never_swipe(self):
        callback = self.controller()
        first_frame, first_source = self.fresh_observation(1)
        callback(first_frame, self.lines, first_source, deadline=10, previous_missing_frame=None)
        rows = self.tsv_rows()
        for row in rows:
            if row['level'] == '5' and row['text'] in ('Boru', 'Rally'):
                row['left'] = str(int(row['left']) + 40)
        self.write_rows(rows)
        second_frame, second_source = self.fresh_observation(2)
        observed = callback(second_frame, self.lines, second_source, deadline=10,
                            previous_missing_frame=first_frame)
        self.assertEqual(observed['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
        self.adb.assert_not_called()
        third_frame, third_source = self.fresh_observation(3)
        third_source.write_bytes(b'changed after observation')
        with self.assertRaisesRegex(RuntimeError, 'screenshot.*changed'):
            callback(third_frame, self.lines, third_source, deadline=10,
                     previous_missing_frame=second_frame)
        self.adb.assert_not_called()
        fourth_frame, fourth_source = self.fresh_observation(4)
        self.clock.monotonic = lambda: 10.0
        with self.assertRaisesRegex(RuntimeError, 'bounded deadline'):
            callback(fourth_frame, self.lines, fourth_source, deadline=10,
                     previous_missing_frame=second_frame)
        self.adb.assert_not_called()

    def test_five_gesture_limit_remains_hard_after_word_recovery(self):
        callback = self.controller()
        for number in range(1, 6):
            first_frame, first_source = self.fresh_observation(number * 2)
            second_frame, second_source = self.fresh_observation(number * 2 + 1)
            callback(first_frame, self.lines, first_source, deadline=10,
                     previous_missing_frame=None)
            result = callback(second_frame, self.lines, second_source, deadline=10,
                              previous_missing_frame=first_frame)
            self.assertEqual(result['swipe_number'], number)
        first_frame, first_source = self.fresh_observation(12)
        second_frame, second_source = self.fresh_observation(13)
        callback(first_frame, self.lines, first_source, deadline=10, previous_missing_frame=None)
        with self.assertRaisesRegex(RuntimeError, 'after five observed list gestures'):
            callback(second_frame, self.lines, second_source, deadline=10,
                     previous_missing_frame=first_frame)
        self.assertEqual(self.adb.call_count, 5)

    def test_missing_anchors_or_incomplete_surface_never_activate_word_recovery(self):
        missing = [row for row in self.lines if evidence.normalize(row['text']) not in
                   ('kartmenu', 'menu', 'start', 'rennenstarten')]
        cases = [(self.frame, missing),
                 (dict(self.frame, acceptable_for_target_sampling=False), self.lines),
                 (dict(self.frame, pixels=[1080, 2400]), self.lines)]
        with patch.object(evidence, 'stage_garage_word_observations',
                          side_effect=AssertionError('must not reach word reader')) as words:
            for frame, lines in cases:
                with self.subTest(frame=frame, lines=lines), self.assertRaises(RuntimeError):
                    self.controller()(frame, lines, self.source, deadline=10,
                                      previous_missing_frame=None)
            words.assert_not_called()
        self.adb.assert_not_called()


if __name__ == '__main__':
    unittest.main()
