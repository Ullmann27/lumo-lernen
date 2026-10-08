"""A stale partial viewport must never authorize a native touch."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from native_surface_readiness import inspect_surface, target_observation


class NativeSurfaceReadinessTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)
        self.full = self.out / 'full.png'
        self.stale = self.out / 'stale.png'
        Image.new('RGB', (192, 108), (8, 27, 67)).save(self.full)
        image = Image.new('RGB', (192, 108), (0, 0, 0))
        image.paste((8, 27, 67), (0, 0, 108, 108))
        # System status icons must not disguise the missing native viewport.
        image.paste((255, 255, 255), (178, 0, 184, 4))
        image.save(self.stale)

    def test_two_identical_original_shape_frames_remain_partial_not_settled(self):
        frame = inspect_surface(self.stale)
        self.assertFalse(frame['acceptable_for_target_sampling'])
        self.assertEqual(frame['blank_edge_columns']['right'], 84)
        first = target_observation(frame, [95.2, 5.8, 101, 6.8], anchor='right-toolbar')
        second = target_observation(frame, [95.2, 5.8, 101, 6.8], first,
                                    anchor='right-toolbar')
        self.assertFalse(first['target_geometry_valid'])
        self.assertFalse(second['stable_observed_target'])

    def test_portrait_or_blank_frame_cannot_authorize_a_landscape_touch(self):
        for dimensions, color in [((108, 192), (8, 27, 67)), ((192, 108), 'black')]:
            Image.new('RGB', dimensions, color).save(self.out / 'invalid.png')
            self.assertFalse(inspect_surface(self.out / 'invalid.png')
                             ['acceptable_for_target_sampling'])

    def test_real_world_dark_regions_and_system_bars_are_not_blank_edge_bands(self):
        image = Image.open(self.full).convert('RGB')
        image.paste('black', (0, 0, 192, 10))
        image.paste('black', (0, 99, 192, 108))
        image.paste('black', (150, 30, 192, 58))
        image.save(self.full)
        self.assertTrue(inspect_surface(self.full)['acceptable_for_target_sampling'])

    def test_blank_left_edge_is_rejected_without_assuming_a_right_only_failure(self):
        image = Image.open(self.full).convert('RGB')
        image.paste('black', (0, 0, 60, 108))
        image.save(self.full)
        self.assertFalse(inspect_surface(self.full)['acceptable_for_target_sampling'])

    def test_treasure_and_puzzle_observed_final_targets_require_two_stable_frames(self):
        frame = inspect_surface(self.full)
        for bounds, anchor in [([157.9, 7.7, 168.3, 9.5], 'right-toolbar'),
                               ([82, 52, 98, 54], 'center-panel'),
                               ([30, 20, 70, 28], '')]:
            first = target_observation(frame, bounds, anchor=anchor)
            second = target_observation(frame, bounds, first, anchor=anchor)
            self.assertFalse(first['stable_observed_target'])
            self.assertTrue(second['stable_observed_target'])

    def test_no_black_band_is_not_enough_to_accept_a_source_inconsistent_target(self):
        frame = inspect_surface(self.full)
        # Exact relative coordinates from failed Treasure/Puzzle frames.
        for bounds, anchor in [([95.2, 5.8, 101, 6.8], 'right-toolbar'),
                               ([46.5, 52.3, 61.4, 53.7], 'center-panel')]:
            first = target_observation(frame, bounds, anchor=anchor)
            self.assertFalse(target_observation(frame, bounds, first, anchor=anchor)
                             ['stable_observed_target'])

    def test_invalid_or_offscreen_bounds_never_generate_a_touch(self):
        frame = inspect_surface(self.full)
        for bounds in ([0, 0, 0, 1], [-1, 0, 4, 4], [190, 10, 200, 20],
                       [10, 100, 20, 120], [float('nan'), 0, 10, 10],
                       [0, 0, float('inf'), 10], [False, 0, 10, 10], [0, 1]):
            self.assertFalse(target_observation(frame, bounds)['target_geometry_valid'])

    def test_resize_or_moving_target_requires_a_new_stable_pair(self):
        frame = inspect_surface(self.full)
        first = target_observation(frame, [20, 20, 30, 30])
        moved = target_observation(frame, [45, 20, 55, 30], first)
        self.assertFalse(moved['stable_observed_target'])
        self.assertTrue(target_observation(frame, [45, 20, 55, 30], moved)
                        ['stable_observed_target'])
        resized = dict(frame, pixels=[240, 108])
        self.assertFalse(target_observation(resized, [45, 20, 55, 30], moved)
                         ['stable_observed_target'])

    def load_probe(self):
        path = Path(__file__).resolve().parents[3] / '.github/probes/creative_android_probe.py'
        spec = importlib.util.spec_from_file_location('creative_surface_guard', path)
        probe = importlib.util.module_from_spec(spec)
        sys.path.insert(0, str(path.parents[2] / 'scripts/probes'))
        base = importlib.import_module('pr207_android_smoke')
        adapter = SimpleNamespace(live_nodes=lambda *_: [], live_tap_label=lambda *_: None)
        with patch.dict(sys.modules, {'pr207_android_ui_probe': adapter}), \
                patch.object(base, 'ui_nodes'), patch.object(base, 'tap_label'):
            spec.loader.exec_module(probe)
        return probe

    def test_generic_puzzle_start_waits_past_two_stale_frames_and_ten_seconds(self):
        probe = self.load_probe()
        now = [0.0]
        sequence = iter([self.stale, self.stale, self.full, self.full])
        calls = []

        def capture(out, tag, timeout=None):
            now[0] += 5
            source = next(sequence)
            current = out / (tag + '.png')
            current.write_bytes(source.read_bytes())
            return {'file': current.name}

        def sleep(seconds):
            now[0] += seconds

        with patch.object(probe, 'capture', capture), \
                patch.object(probe, 'image_lines', return_value=[
                    {'text': 'Neues Puzzle beginnen', 'bounds': [82, 52, 98, 54]}]) as reader, \
                patch.object(probe.base, 'adb', side_effect=lambda *a, **k: calls.append((a, k))), \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe.time, 'sleep', sleep):
            probe.native_text(self.out, 'Neues Puzzle beginnen', 'start', tap=True, settle=False)
        self.assertEqual(reader.call_count, 2)
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][0][3:7], ('90', '53', '90', '53'))
        evidence = json.loads((self.out / 'start-surface-readiness.json').read_text())
        self.assertEqual(evidence['status'], 'TOUCH_SENT')
        self.assertEqual(len(evidence['frames']), 4)
        self.assertGreater(evidence['elapsed_seconds'], 10)
        self.assertEqual(evidence['final_observed_bounds'], [82, 52, 98, 54])

    def test_persistently_partial_surface_times_out_without_ocr_or_any_tap(self):
        probe = self.load_probe()
        now = [0.0]

        def capture(out, tag, timeout=None):
            current = out / (tag + '.png')
            current.write_bytes(self.stale.read_bytes())
            return {'file': current.name}

        def sleep(seconds):
            now[0] += seconds

        with patch.object(probe, 'capture', capture), \
                patch.object(probe, 'image_lines') as reader, \
                patch.object(probe.base, 'adb') as adb, \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe.time, 'sleep', sleep):
            with self.assertRaisesRegex(TimeoutError, 'did not settle'):
                probe.native_tap(self.out, 'Rucksack', 'never', timeout=12)
        reader.assert_not_called()
        adb.assert_not_called()
        evidence = json.loads((self.out / 'never-surface-readiness.json').read_text())
        self.assertEqual(evidence['status'], 'FAIL')
        self.assertEqual(evidence['elapsed_seconds'], 12)

    def test_incomplete_capture_retries_share_elapsed_budget_and_preserve_original_png(self):
        probe = self.load_probe()
        now = [0.0]
        raw = self.full.read_bytes()
        calls = []

        def command(*args, timeout, **kwargs):
            calls.append(timeout)
            now[0] += 2
            return SimpleNamespace(stdout=b'incomplete' if len(calls) == 1 else raw)

        with patch.object(probe.subprocess, 'run', command), \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe.time, 'sleep', side_effect=lambda seconds: now.__setitem__(0, now[0]+seconds)):
            actual = probe.capture(self.out, 'bounded', timeout=10)
        self.assertEqual(calls, [10, 7])
        self.assertEqual((self.out / actual['file']).read_bytes(), raw)

    def test_capture_exhaustion_fails_without_target_read_or_touch(self):
        probe = self.load_probe()
        now = [0.0]

        def command(*args, timeout, **kwargs):
            now[0] += timeout
            return SimpleNamespace(stdout=self.full.read_bytes())

        with patch.object(probe.subprocess, 'run', command), \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe, 'image_lines') as reader, \
                patch.object(probe.base, 'adb') as adb:
            with self.assertRaisesRegex(TimeoutError, 'capture deadline'):
                probe.native_tap(self.out, 'Rucksack', 'late-capture', timeout=10)
        reader.assert_not_called()
        adb.assert_not_called()
        self.assertEqual(json.loads((self.out / 'late-capture-surface-readiness.json').read_text())
                         ['status'], 'FAIL')

    def test_exact_fullrace_press_ignores_substring_before_two_current_exact_observations(self):
        probe = self.load_probe()
        now = [0.0]

        def capture(out, tag, timeout=None):
            current = out / (tag + '.png')
            current.write_bytes(self.full.read_bytes())
            return {'file': current.name}

        reads = [[{'text': 'Weiter erkunden', 'bounds': [10, 10, 30, 20]}],
                 [{'text': 'Weiter', 'bounds': [80, 30, 100, 40]}],
                 [{'text': 'Weiter', 'bounds': [80, 30, 100, 40]}]]
        with patch.object(probe, 'capture', capture), \
                patch.object(probe, 'image_lines', side_effect=reads), \
                patch.object(probe.base, 'adb') as adb, \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe.time, 'sleep', side_effect=lambda seconds: now.__setitem__(0, now[0]+seconds)):
            probe.native_text(self.out, 'Weiter', 'exact', tap=True, exact=True)
        adb.assert_called_once()
        self.assertEqual(adb.call_args.args[3:7], ('90', '35', '90', '35'))
        evidence = json.loads((self.out / 'exact-surface-readiness.json').read_text())
        self.assertTrue(evidence['exact_caption_required'])
        self.assertEqual(len(evidence['frames']), 3)

    def test_only_substring_captions_cannot_authorize_an_exact_fullrace_touch(self):
        probe = self.load_probe()
        now = [0.0]

        def capture(out, tag, timeout=None):
            current = out / (tag + '.png')
            current.write_bytes(self.full.read_bytes())
            return {'file': current.name}

        with patch.object(probe, 'capture', capture), \
                patch.object(probe, 'image_lines', return_value=[
                    {'text': 'Weiter erkunden', 'bounds': [10, 10, 30, 20]}]), \
                patch.object(probe.base, 'adb') as adb, \
                patch.object(probe.time, 'monotonic', side_effect=lambda: now[0]), \
                patch.object(probe.time, 'sleep', side_effect=lambda seconds: now.__setitem__(0, now[0]+seconds)):
            with self.assertRaises(TimeoutError):
                probe.native_tap(self.out, 'Weiter', 'no-exact', timeout=6, exact=True)
        adb.assert_not_called()

    def test_exact_ocr_continues_to_next_actual_tsv_variant_while_default_keeps_substring(self):
        probe = self.load_probe()
        header = 'page_num\tblock_num\tpar_num\tline_num\tleft\ttop\twidth\theight\tconf\ttext\n'
        for exact, expected_reads in [(True, 2), (False, 1)]:
            with self.subTest(exact=exact):
                calls = []

                def command(*args, **kwargs):
                    calls.append(args)
                    text = 'Weiterfahren' if len(calls) == 1 else 'Weiter'
                    Path(args[2]).with_suffix('.tsv').write_text(
                        header + '1\t1\t1\t1\t160\t60\t40\t20\t95\t' + text + '\n')

                with patch.object(probe.base, 'command', command), \
                        patch.object(probe, 'read_tiled_word') as tiles:
                    result = probe.image_lines(self.out, 'variants-'+str(exact), 'weiter',
                                               source_path=self.full, exact=exact)
                self.assertEqual(len(calls), expected_reads)
                tiles.assert_not_called()
                expected_text = 'Weiter' if exact else 'Weiterfahren'
                self.assertTrue(any(line['text'] == expected_text for line in result))

    def test_exact_ocr_reaches_tile_fallback_when_all_actual_variants_only_have_prefix(self):
        probe = self.load_probe()
        header = 'page_num\tblock_num\tpar_num\tline_num\tleft\ttop\twidth\theight\tconf\ttext\n'

        def command(*args, **kwargs):
            Path(args[2]).with_suffix('.tsv').write_text(
                header + '1\t1\t1\t1\t160\t60\t40\t20\t95\tWeiterfahren\n')

        with patch.object(probe.base, 'command', side_effect=command) as reader, \
                patch.object(probe, 'read_tiled_word', return_value=[
                    {'text': 'Weiter', 'bounds': [80, 30, 100, 40], 'variant': 'tile'}]) as tiles:
            result = probe.image_lines(self.out, 'fallback-exact', 'weiter',
                                       source_path=self.full, exact=True)
        self.assertEqual(reader.call_count, 4)
        tiles.assert_called_once()
        self.assertEqual(tiles.call_args.args[0], self.full)
        self.assertTrue(any(line['text'] == 'Weiter' for line in result))


if __name__ == '__main__':
    unittest.main()
