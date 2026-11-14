"""Replay exact 7b16 failed frames/TSV; these are not new Android runs."""
from __future__ import annotations

import copy
import csv
import hashlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence
from test_modernization_tour_identity import TOUR_MODULE as tour


FIXTURES = Path(__file__).parent / 'fixtures' / 'kart-driver-7b16'
ORIGINAL_TAG = '21_stage_driver-select-original-lumo-0'


class ActualDriverWordEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.out = Path(self.temporary.name)
        self.capture_count = 0

    def replay(self, scope, *, tsv_mutation=None, lines_mutation=None):
        source = FIXTURES / scope
        png = (source / (ORIGINAL_TAG + '.png')).read_bytes()
        lines = json.loads((source / (ORIGINAL_TAG + '-ocr.json')).read_text())

        def capture(_out, tag, **_kwargs):
            self.capture_count += 1
            target = self.out / (tag + '.png')
            target.write_bytes(png)
            return {'file': target.name}

        def read_lines(_out, tag, **_kwargs):
            for original in source.glob(ORIGINAL_TAG + '-ocr-*.tsv'):
                suffix = original.name[len(ORIGINAL_TAG):]
                raw = original.read_bytes()
                if tsv_mutation is not None:
                    raw = tsv_mutation(original.name, raw)
                (self.out / (tag + suffix)).write_bytes(raw)
            current = copy.deepcopy(lines)
            return lines_mutation(current) if lines_mutation else current

        with patch.object(tour.probe, 'capture', side_effect=capture), \
                patch.object(tour.probe, 'image_lines', side_effect=read_lines), \
                patch.object(tour.base, 'adb') as adb, patch.object(tour.time, 'sleep'):
            self.adb = adb
            return tour._select_stage_driver(self.out)

    def assert_original_word_touch(self, scope, bounds, point):
        result = self.replay(scope)
        self.assertEqual(self.capture_count, 2)
        self.adb.assert_called_once()
        x, y = map(str, point)
        self.assertEqual(self.adb.call_args.args,
                         ('shell', 'input', 'swipe', x, y, x, y, '120'))
        self.assertEqual(result['driver'], 'fox')
        journal = json.loads((self.out / result['readiness']).read_text())
        self.assertEqual(journal['status'], 'TOUCH_SENT')
        self.assertEqual(journal['final_observed_bounds'], bounds)
        self.assertEqual([f['target']['stable_observed_target'] for f in journal['frames']],
                         [False, True])
        for frame in journal['frames']:
            self.assertEqual(frame['source_sha256'],
                             hashlib.sha256((self.out / frame['source']).read_bytes()).hexdigest())
            region = frame['driver_region']
            self.assertEqual(region['caption_source'], 'original_tsv_words')
            self.assertEqual(region['matching_observations'], 3)
            self.assertEqual(region['target']['text'], 'Lumo')
            for item in region['ocr_sources']:
                raw = (self.out / item['file']).read_bytes()
                self.assertEqual(item['sha256'], hashlib.sha256(raw).hexdigest())

    def test_actual_api35_icon_line_uses_exact_word_after_two_original_frames(self):
        self.assert_original_word_touch('api35', [168.0, 490.0, 276.0, 519.0], [222, 504])

    def test_actual_update_overlapping_icon_line_uses_exact_word_after_two_original_frames(self):
        self.assert_original_word_touch('update', [304.0, 490.0, 412.0, 519.0], [358, 504])

    def test_original_line_only_failures_remain_reproducible_and_distinct(self):
        for scope, error in [('api35', 'No exact Lumo driver caption'),
                             ('update', 'Ambiguous Lumo driver captions')]:
            with self.subTest(scope=scope):
                source = FIXTURES / scope
                lines = json.loads((source / (ORIGINAL_TAG + '-ocr.json')).read_text())
                frame = json.loads((source / '21_stage_driver-select-original-lumo-surface-readiness.json')
                                   .read_text())['frames'][0]
                with self.assertRaisesRegex(RuntimeError, error):
                    evidence.stage_driver_target_observation(frame, lines)

    def test_all_twenty_original_fixture_bytes_are_bound_to_both_failed_jobs(self):
        manifest = json.loads((FIXTURES / 'provenance.json').read_text())
        self.assertEqual(manifest['run_id'], 43540111465)
        self.assertEqual(manifest['host'], '7b16f2f5ab16f3d913ee170aefd9807c87216260')
        self.assertEqual(manifest['native'], '17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845')
        self.assertEqual({x['artifact_id'] for x in manifest['sources']}, {14094566042, 14093704788})
        self.assertEqual({x['job_id'] for x in manifest['sources']}, {132298281143, 132298281120})
        count = 0
        for source in manifest['sources']:
            for item in source['files']:
                raw = (FIXTURES / item['path']).read_bytes()
                self.assertEqual(len(raw), item['bytes'])
                self.assertEqual(hashlib.sha256(raw).hexdigest(), item['sha256'])
                count += 1
        self.assertEqual(count, 20)

    @staticmethod
    def mutated_words(name, raw, change):
        """Synthetic counterexample derived in temp files; originals stay exact."""
        stream = io.StringIO(raw.decode('utf-8'))
        reader = csv.DictReader(stream, delimiter='\t', quoting=csv.QUOTE_NONE)
        rows = list(reader)
        scale = 1 if name.endswith('-1x.tsv') else 2
        for row in list(rows):
            if row.get('text', '').strip().casefold() == 'lumo' and int(row['top']) / scale > 350:
                change(row, rows, scale)
        output = io.StringIO()
        writer = csv.DictWriter(output, reader.fieldnames, delimiter='\t',
                                quoting=csv.QUOTE_NONE, quotechar=None, lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)
        return output.getvalue().encode('utf-8')

    def assert_no_touch(self, scope, mutation, message=None):
        context = self.assertRaisesRegex(RuntimeError, message) if message else self.assertRaises(RuntimeError)
        with context:
            self.replay(scope, tsv_mutation=mutation)
        self.adb.assert_not_called()
        journal = json.loads((self.out / '21_stage_driver-select-original-lumo-surface-readiness.json').read_text())
        self.assertEqual(journal['status'], 'FAIL')

    def test_real_second_card_region_is_still_ambiguous_after_word_recovery(self):
        def add_second(row, rows, scale):
            second = dict(row, top=str(650 * scale), block_num='999')
            rows.append(second)
        self.assert_no_touch('update', lambda n, b: self.mutated_words(n, b, add_second),
                             'Ambiguous Lumo driver captions')

    def test_only_logo_and_nonexact_driver_words_cannot_produce_a_touch(self):
        self.assert_no_touch('api35', lambda n, b: self.mutated_words(
            n, b, lambda row, _rows, _scale: row.update(text='LumoKart')),
            'No exact Lumo driver caption')

    def test_word_in_right_preview_cannot_become_a_driver_card(self):
        self.assert_no_touch('update', lambda n, b: self.mutated_words(
            n, b, lambda row, _rows, scale: row.update(left=str(1600 * scale))),
            'No exact Lumo driver caption')

    def test_existing_ocr_confidence_floor_remains_required(self):
        self.assert_no_touch('api35', lambda n, b: self.mutated_words(
            n, b, lambda row, _rows, _scale: row.update(conf='14.999')),
            'No exact Lumo driver caption')

    def test_missing_real_footer_does_not_activate_a_word_fallback(self):
        def no_footer(lines):
            return [row for row in lines if evidence.normalize(row['text']) not in
                    ('kartmenu', 'menu', 'start', 'rennenstarten')]
        with self.assertRaisesRegex(RuntimeError, 'tabs and menu/start footer required'):
            self.replay('api35', lines_mutation=no_footer)
        self.adb.assert_not_called()


if __name__ == '__main__':
    unittest.main()
