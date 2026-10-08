"""A missing/invalid OCR word must never become a live touch target."""
import csv
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_ocr_tiles import observed_bounds, observed_matches, read_tiled_word, tile_boxes


def normalize(value):
    return re.sub('[^a-z0-9]', '', value.lower())


def word(text='ITEM', **fields):
    return {'page_num': '1', 'block_num': '1', 'par_num': '1', 'line_num': '1',
            'left': '12', 'top': '12', 'width': '15', 'height': '9',
            'conf': '90', 'text': text, **fields}


def write_tsv(path, words):
    with path.open('w') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(word()), delimiter='\t')
        writer.writeheader()
        writer.writerows(words)


class NativeOCRTileGuards(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)
        self.source = self.out / 'current.png'
        Image.new('RGB', (120, 90), (4, 8, 16)).save(self.source)

    def test_grid_covers_entire_current_frame_and_stays_inside_all_surface_sizes(self):
        for width, height in ((2316, 904), (2176, 1812), (1920, 1080), (1, 1)):
            boxes = tile_boxes(width, height)
            self.assertEqual(len(boxes), 6)
            self.assertTrue(all(0 <= x0 < x1 <= width and 0 <= y0 < y1 <= height
                                for x0, y0, x1, y1 in boxes))
            for x, y in ((0, 0), (width - 1, height - 1), (width // 3, height // 2),
                         (2 * width // 3, height // 2)):
                self.assertTrue(any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in boxes))
        with self.assertRaises(ValueError):
            tile_boxes(0, 904)

    def test_original_failed_cover_word_maps_scale_and_offset_to_actual_screen(self):
        # Exact raw TSV geometry from run 37793715220, artifact 11559239783.
        actual = word(left='1026', top='888', width='147', height='84', conf='18.321091')
        self.assertEqual(observed_bounds(actual, (1464, 372, 2316, 904), 3, (2316, 904)),
                         [1806, 668, 1855, 696])

    def test_clipped_negative_or_nonpositive_bounds_cannot_generate_a_touch_target(self):
        for fields in ({'left': '-1'}, {'top': '-1'}, {'width': '0'}, {'height': '-1'},
                       {'left': '297', 'width': '15'}, {'top': '298', 'height': '9'}):
            with self.subTest(fields=fields), self.assertRaises(RuntimeError):
                observed_bounds(word(**fields), (20, 10, 120, 110), 3, (120, 110))
        with self.assertRaises(RuntimeError):
            observed_bounds(word(), (20, 10, 121, 110), 3, (120, 110))

    def test_exact_observed_word_required_without_jtem_substring_or_low_confidence_alias(self):
        for candidate in (word('JTEM'), word('missingITEM'), word('ITEM', conf='14.99')):
            self.assertEqual(observed_matches([candidate], (0, 0, 120, 90), 3,
                                             (120, 90), 'item', normalize, 'tile'), [])
        for confidence in ('NaN', 'Infinity'):
            with self.subTest(confidence=confidence), self.assertRaises(RuntimeError):
                observed_matches([word(conf=confidence)], (0, 0, 120, 90), 3,
                                 (120, 90), 'item', normalize, 'tile')

    def test_a_tile_boundary_cannot_turn_a_clipped_word_into_a_shorter_requested_caption(self):
        for fields in ({'left': '0'}, {'top': '0'}, {'left': '285'}, {'top': '291'}):
            with self.subTest(fields=fields), self.assertRaisesRegex(RuntimeError, 'may be clipped'):
                observed_bounds(word(**fields), (20, 10, 120, 110), 3, (140, 130))
        rows = [word('ITEM', left='0'), word('GAS', left='45')]
        self.assertEqual(observed_matches(rows, (20, 10, 120, 110), 3,
                                          (140, 130), 'item', normalize, 'tile'), [])

    def test_adjacent_words_use_only_the_requested_phrases_own_observed_bounds(self):
        rows = [word('ITEM', left='12'), word('GAS', left='45')]
        result = observed_matches(rows, (0, 0, 120, 90), 3, (120, 90), 'item', normalize, 'tile')
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]['bounds'], [4, 4, 9, 7])
        self.assertEqual(result[0]['text'], 'ITEM')

    def test_missing_caption_and_blank_reads_exhaust_six_tiles_without_visibility_pass(self):
        for rows in ([], [word('JTEM')], [word('GAS')]):
            calls = []

            def command(*args, timeout):
                calls.append((args, timeout))
                write_tsv(Path(args[2]).with_suffix('.tsv'), rows)
                return ''

            self.assertEqual(read_tiled_word(self.source, self.out, 'missing', 'item',
                                            normalize, command), [])
            evidence = json.loads((self.out / 'missing-ocr-tiles.json').read_text())
            self.assertEqual(len(calls), 6)
            self.assertEqual(evidence['status'], 'READ')
            self.assertFalse(evidence['matched'])
            self.assertTrue(all(0 < duration <= 15 for _, duration in calls))

    def test_command_failure_keeps_raw_error_and_never_returns_a_match(self):
        def command(*args, timeout):
            raise RuntimeError('actual reader failure: permission denied')

        with self.assertRaisesRegex(RuntimeError, 'permission denied'):
            read_tiled_word(self.source, self.out, 'failed', 'item', normalize, command)
        evidence = json.loads((self.out / 'failed-ocr-tiles.json').read_text())
        self.assertEqual(evidence['status'], 'FAIL')
        self.assertEqual(evidence['tiles'][0]['error'], 'actual reader failure: permission denied')
        self.assertEqual(evidence['matches'], [])

    def test_total_deadline_and_mutated_current_frame_fail_instead_of_using_stale_words(self):
        now = [0]

        def expired_command(*args, timeout):
            write_tsv(Path(args[2]).with_suffix('.tsv'), [word()])
            now[0] = 46
            return ''

        with self.assertRaises(TimeoutError):
            read_tiled_word(self.source, self.out, 'expired', 'item', normalize,
                            expired_command, clock=lambda: now[0])

        def mutating_command(*args, timeout):
            write_tsv(Path(args[2]).with_suffix('.tsv'), [word()])
            Image.new('RGB', (120, 90), 'white').save(self.source)
            return ''

        with self.assertRaisesRegex(RuntimeError, 'changed during OCR'):
            read_tiled_word(self.source, self.out, 'mutated', 'item', normalize, mutating_command)

    def test_fallback_runs_only_after_all_four_whole_frame_variants_miss_requested_word(self):
        path = Path(__file__).resolve().parents[3] / '.github/probes/creative_android_probe.py'
        spec = importlib.util.spec_from_file_location('creative_ocr_guard', path)
        probe = importlib.util.module_from_spec(spec)
        # This reader-only test must also run before the Android workflow
        # installs uiautomator2. Do not initialize or fake an Android session.
        sys.path.insert(0, str(path.parents[2] / 'scripts/probes'))
        base = importlib.import_module('pr207_android_smoke')
        adapter = SimpleNamespace(live_nodes=lambda *_: [], live_tap_label=lambda *_: None)
        with patch.dict(sys.modules, {'pr207_android_ui_probe': adapter}), \
                patch.object(base, 'ui_nodes'), patch.object(base, 'tap_label'):
            spec.loader.exec_module(probe)
        calls = []

        def command(*args, timeout):
            calls.append(args)
            write_tsv(Path(args[2]).with_suffix('.tsv'), [word('JTEM')])
            return ''

        with patch.object(probe.base, 'command', command), \
                patch.object(probe, 'read_tiled_word', return_value=[]) as fallback:
            probe.image_lines(self.out, 'miss', 'item', self.source)
            self.assertEqual(len(calls), 4)
            fallback.assert_called_once()
        calls.clear()

        def found_command(*args, timeout):
            calls.append(args)
            write_tsv(Path(args[2]).with_suffix('.tsv'), [word()])
            return ''

        with patch.object(probe.base, 'command', found_command), \
                patch.object(probe, 'read_tiled_word') as fallback:
            probe.image_lines(self.out, 'found', 'item', self.source)
            self.assertEqual(len(calls), 1)
            fallback.assert_not_called()


if __name__ == '__main__':
    unittest.main()
