"""Replay preserved 7b failures; synthetic state/ambiguity cases are explicit.

Recorded TSVs come from real local deu+eng OCR of the original Android PNG.
These tests execute its current readers, but never operate an Android device.
"""
import ast
from collections import deque
import copy
import csv
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import re
import shutil
import sys
import tempfile
import time
from types import ModuleType, SimpleNamespace
import unicodedata
import unittest
from unittest.mock import Mock, patch

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'tools/android_qa/tests/fixtures/studio_creative_7b'
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from native_ocr_tiles import observed_matches, read_tiled_word
from native_surface_readiness import inspect_surface, target_observation


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


probe = load('studio_creative_7b_repair', ROOT / '.github/probes/studio_creative_android_probe.py')
candidate = ModuleType('creative_7b_reader')
candidate.__dict__.update(Path=Path, csv=csv, hashlib=hashlib, json=json,
    math=math, re=re, time=time, unicodedata=unicodedata, deque=deque,
    Image=Image, ImageChops=ImageChops, observed_matches=observed_matches,
    read_tiled_word=read_tiled_word, base=SimpleNamespace(command=Mock()),
    inspect_surface=inspect_surface, target_observation=target_observation)
tree = ast.parse((ROOT / '.github/probes/creative_android_probe.py').read_text())
functions = [node for node in tree.body if isinstance(node, ast.FunctionDef)
             and node.name in ('digest', 'normalized', 'gold_caption_boxes',
                               'read_component_caption', 'image_lines')]
exec(compile(ast.Module(body=functions, type_ignores=[]),
             '.github/probes/creative_android_probe.py', 'exec'), candidate.__dict__)


class OriginalCreativeReplays(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)

    def test_current_original_and_local_ocr_bytes_are_bound_separately(self):
        manifest = json.loads((FIXTURE / 'provenance.json').read_text())
        self.assertEqual(manifest['run_id'], 43540111465)
        self.assertEqual(manifest['job_id'], 132298281135)
        self.assertEqual(manifest['host_source'], '7b16f2f5ab16f3d913ee170aefd9807c87216260')
        self.assertEqual(manifest['native_source'], '17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845')
        for directory in (FIXTURE, FIXTURE / 'local-ocr', FIXTURE / 'learning-qa61c'):
            for item in json.loads((directory / 'provenance.json').read_text())['files']:
                with self.subTest(path=item['path']):
                    raw = (directory / item['path']).read_bytes()
                    self.assertEqual(len(raw), item['bytes'])
                    self.assertEqual(hashlib.sha256(raw).hexdigest(), item['sha256'])

    def test_current_jump_reads_beyond_original_instruction_word(self):
        source = FIXTURE / '0017-observe-springen.png'
        old = json.loads((FIXTURE / '0017-observe-springen-ocr.json').read_text())
        with self.assertRaisesRegex(RuntimeError, 'No complete'):
            probe.jump_action_choice(old, [1080, 1920], candidate.normalized)
        observed_variants = []

        def replay(*args, **kwargs):
            self.assertEqual(args[0], 'tesseract')
            prefix = Path(args[2])
            recorded = FIXTURE / 'local-ocr' / prefix.with_suffix('.tsv').name
            self.assertTrue(recorded.is_file(), 'Every mocked OCR output must be a bound actual TSV')
            shutil.copyfile(recorded, prefix.with_suffix('.tsv'))
            observed_variants.append(prefix.name)
            self.assertGreater(kwargs['timeout'], 0)
            return ''

        tour = probe.Tour.__new__(probe.Tour)
        tour.probe, tour.out, tour.surface_orientation = candidate, self.out, 'responsive'
        tour.shot = Mock(return_value=(source, {'file': source.name, 'width': 1080, 'height': 1920,
                                               'sha256': probe.sha(source)}))
        with patch.object(candidate.base, 'command', side_effect=replay), patch.object(probe.time, 'sleep'):
            actual = tour.observe('SPRINGEN', exact=True, control='jump-action')
        self.assertEqual(actual['bounds'], [895.0, 1777.5, 1010.0, 1793.0])
        self.assertTrue(actual['stable']['stable_observed_target'])
        self.assertTrue(any(name.endswith('-raw') for name in observed_variants))
        self.assertTrue(any('gold-component' in name for name in observed_variants))
        self.assertEqual(tour.shot.call_count, 2)

    def test_ordinary_success_keeps_its_first_variant_and_never_starts_gold_fallback(self):
        source = FIXTURE / '0017-observe-springen.png'

        def replay(*args, **kwargs):
            prefix = Path(args[2])
            self.assertTrue(prefix.name.endswith('-contrast'))
            recorded = FIXTURE / 'local-ocr' / '0017-observe-springen-ocr-contrast.tsv'
            shutil.copyfile(recorded, prefix.with_suffix('.tsv'))
            return ''

        with patch.object(candidate.base, 'command', side_effect=replay) as command, \
                patch.object(candidate, 'read_component_caption') as components:
            rows = candidate.image_lines(self.out, 'ordinary', 'springen',
                                         source_path=source, timeout=60, exact=True)
        command.assert_called_once()
        components.assert_not_called()
        self.assertTrue(any(candidate.normalized(row['text']) == 'springen' for row in rows))

    def test_current_qa61c_learning_uses_actual_gold_ocr_without_extending_budget(self):
        fixture = FIXTURE / 'learning-qa61c'
        source = fixture / 'learning-move-1-0.png'
        original = json.loads((fixture / 'learning-move-1-0-ocr.json').read_text())
        self.assertFalse(any(candidate.normalized(row['text']) == 'einobjektzeigen' for row in original))
        readiness = json.loads((fixture / 'learning-move-1-surface-readiness.json').read_text())
        self.assertEqual(readiness['status'], 'FAIL')
        self.assertEqual(readiness['timeout_seconds'], 120)

        def replay(*args, **kwargs):
            self.assertGreater(kwargs['timeout'], 0)
            self.assertLessEqual(kwargs['timeout'], 45)
            prefix = Path(args[2])
            shutil.copyfile(fixture / prefix.with_suffix('.tsv').name, prefix.with_suffix('.tsv'))
            return ''

        with patch.object(candidate.base, 'command', side_effect=replay):
            rows = candidate.image_lines(self.out, source.stem, 'einobjektzeigen',
                                         source_path=source, timeout=60, exact=True)
        matches = [row for row in rows if candidate.normalized(row['text']) == 'einobjektzeigen']
        self.assertEqual(len(matches), 1)
        self.assertEqual(matches[0]['bounds'], [104.0, 2029.0, 467.0, 2071.0])
        self.assertTrue(matches[0]['variant'].startswith('gold-component-'))

    def test_actual_empty_board_uses_contour_and_keeps_real_tray_projection(self):
        image = probe.read_image(FIXTURE / '0125-puzzle-observed-board.png')
        saved = json.loads((FIXTURE / '0122-puzzle-save-lumo_puzzle_p_0768095c1da522693b0639510a4d3037.json').read_text())
        actual = probe.puzzle_piece_target(image, saved)
        self.assertTrue(440 < actual['point'][0] < 460)
        self.assertTrue(490 < actual['point'][1] < 515)
        self.assertGreater(actual['board_contour']['interior_coverage'], .99)
        self.assertEqual(actual['board_contour']['gold_side_rim_fractions'], [1.0, 1.0])
        self.assertEqual(actual['world_tray_center'], [-7.0, .15, -2.2])
        changed = copy.deepcopy(saved)
        changed['pieces'][0]['tray'] = False
        with self.assertRaisesRegex(RuntimeError, 'empty six-piece'):
            probe.puzzle_piece_target(image, changed)
        changed = copy.deepcopy(saved)
        changed['pieces'][0]['x'] += .5
        with self.assertRaisesRegex(RuntimeError, 'initial slot'):
            probe.puzzle_piece_target(image, changed)

    def test_puzzle_rejects_occlusion_plain_colour_and_duplicate_contours(self):
        original = probe.read_image(FIXTURE / '0125-puzzle-observed-board.png')
        occluded = original.copy()
        ImageDraw.Draw(occluded).rectangle((850, 600, 1050, 720), fill=(150, 30, 20))
        plain = Image.new('RGB', original.size, (45, 53, 87))
        rectangle = Image.new('RGB', original.size, (170, 110, 50))
        ImageDraw.Draw(rectangle).rectangle((600, 470, 1320, 820), fill=(45, 53, 87))
        red, green, blue = original.split()
        rim = ImageChops.multiply(
            ImageChops.subtract(red, green).point(lambda value: 255 if value >= 10 else 0),
            ImageChops.subtract(green, blue).point(lambda value: 255 if value >= 10 else 0))
        no_rim = Image.composite(Image.new('RGB', original.size, (100, 100, 100)), original, rim)
        duplicate = Image.new('RGB', original.size, (180, 120, 60))
        board = original.crop((510, 450, 1410, 850)).resize((495, 220))
        for y in (290, 630):
            separate = Image.new('RGB', original.size, (180, 120, 60))
            separate.paste(board, (712, y))
            self.assertTrue(probe.puzzle_board_contour(separate)['corners'])
            duplicate.paste(board, (712, y))
        for name, image in [('occluded', occluded), ('plain', plain),
                            ('rectangle', rectangle), ('missing rims', no_rim), ('duplicate', duplicate)]:
            with self.subTest(case=name), self.assertRaisesRegex(RuntimeError, 'unique complete'):
                probe.puzzle_board_contour(image)


class CompleteGoldRegions(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.source = self.out / 'explicit-synthetic-two-controls.png'
        image = Image.new('RGB', (400, 300), (10, 20, 40))
        draw = ImageDraw.Draw(image)
        draw.rectangle((20, 45, 185, 105), fill=(220, 160, 50))
        draw.rectangle((210, 190, 380, 250), fill=(220, 160, 50))
        image.save(self.source)
        self.calls = []

    def ocr(self, *args, **kwargs):
        self.calls.append(args)
        Path(args[2]).with_suffix('.tsv').write_text(
            'level\tpage_num\tblock_num\tpar_num\tline_num\tword_num\tleft\ttop\twidth\theight\tconf\ttext\n'
            '5\t1\t1\t1\t1\t1\t15\t15\t100\t20\t96\tSPRINGEN\n')
        return ''

    def test_second_equal_region_is_retained_and_same_control_gate_rejects_it(self):
        rows = candidate.read_component_caption(self.source, self.out, 'two', 'springen', self.ocr)
        self.assertEqual(len(self.calls), 2)
        self.assertEqual(len(rows), 2)
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            probe.full_caption_choice(rows, ('SPRINGEN',), candidate.normalized)

    def test_deadline_after_first_match_fails_instead_of_hiding_next_region(self):
        now = [0.0]

        def first_then_expire(*args, **kwargs):
            result = self.ocr(*args, **kwargs)
            now[0] = 16
            return result

        with self.assertRaises(TimeoutError):
            candidate.read_component_caption(self.source, self.out, 'timeout', 'springen',
                                             first_then_expire, clock=lambda: now[0])
        self.assertEqual(len(self.calls), 1)
        self.assertEqual(json.loads((self.out / 'timeout-ocr-components.json').read_text())['status'], 'FAIL')

    def test_changed_source_and_absent_caption_never_create_a_match(self):
        def mutate(*args, **kwargs):
            result = self.ocr(*args, **kwargs)
            Image.new('RGB', (400, 300), 'black').save(self.source)
            return result
        with self.assertRaisesRegex(RuntimeError, 'changed during OCR'):
            candidate.read_component_caption(self.source, self.out, 'mutated', 'springen', mutate)
        with self.assertRaises(ValueError):
            candidate.read_component_caption(self.source, self.out, 'empty', '', self.ocr)


class BuildEntryAndPauseBoundary(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.blank = FIXTURE / '0081-entered-bauwelt.png'
        self.active = FIXTURE / '0082-native-weiterbauen-9.png'
        self.active_lines = json.loads((FIXTURE / '0082-native-weiterbauen-9-ocr.json').read_text())
        # Synthetic transition, explicitly not a captured Android pause PASS.
        self.paused_lines = self.active_lines + [
            {'text': 'Deine Welt wartet auf dich', 'bounds': [710, 360, 1210, 390]},
            {'text': 'Weiterbauen', 'bounds': [870, 420, 1050, 450]}]
        self.now = 0.0

    def tour(self, states):
        states = iter(states)
        last = [self.blank, []]
        tour = probe.Tour.__new__(probe.Tour)
        tour.counter, tour.out = 0, self.out
        tour.base = SimpleNamespace(adb=Mock(return_value=''))
        tour.saved = Mock(return_value={'source': 'explicit-synthetic-state-save'})
        tour.native = Mock()
        current_lines = []

        def shot(label, **kwargs):
            nonlocal current_lines
            self.now += 2
            try:
                state = next(states)
                last[:] = state
            except StopIteration:
                pass
            source, current_lines = last
            with Image.open(source) as image:
                width, height = image.size
            return source, {'file': source.name, 'width': width, 'height': height,
                            'sha256': probe.sha(source)}

        tour.shot = Mock(side_effect=shot)
        tour.probe = SimpleNamespace(normalized=candidate.normalized,
            inspect_surface=inspect_surface, target_observation=target_observation,
            image_lines=Mock(side_effect=lambda *a, **k: current_lines))
        return tour

    def sleep(self, seconds):
        self.now += seconds

    def test_original_blank_entry_never_sends_back(self):
        tour = self.tour([(self.blank, [])])
        tour.native.side_effect = RuntimeError('Current native screenshot lacks Weiterbauen')
        with patch.object(probe.time, 'monotonic', side_effect=lambda: self.now), \
                patch.object(probe.time, 'sleep', side_effect=self.sleep):
            with self.assertRaises(RuntimeError):
                tour.pause_save('build')
        tour.base.adb.assert_not_called()
        tour.saved.assert_not_called()

    def test_actual_active_hud_must_stabilize_before_one_back_and_paired_pause(self):
        tour = self.tour([(self.blank, []), (self.active, self.active_lines),
                          (self.active, self.active_lines), (self.active, self.paused_lines),
                          (self.active, self.paused_lines)])
        with patch.object(probe.time, 'monotonic', side_effect=lambda: self.now), \
                patch.object(probe.time, 'sleep', side_effect=self.sleep):
            result = tour.pause_save('build')
        self.assertEqual(tour.shot.call_count, 5)
        tour.base.adb.assert_called_once()
        self.assertEqual(tour.base.adb.call_args.args, ('shell', 'input', 'keyevent', 'KEYCODE_BACK'))
        tour.native.assert_called_once_with('Weiterbauen', tap=True, exact=True)
        self.assertEqual(result, tour.saved.return_value)

    def test_already_observed_pause_is_not_toggled_and_failed_pause_never_retries_back(self):
        tour = self.tour([(self.active, self.paused_lines)] * 2)
        with patch.object(probe.time, 'monotonic', side_effect=lambda: self.now), \
                patch.object(probe.time, 'sleep', side_effect=self.sleep):
            tour.pause_save('build', resume=False)
        tour.base.adb.assert_not_called()
        tour.native.assert_not_called()
        self.now = 0
        tour = self.tour([(self.active, self.active_lines)] * 2)
        with patch.object(probe.time, 'monotonic', side_effect=lambda: self.now), \
                patch.object(probe.time, 'sleep', side_effect=self.sleep):
            with self.assertRaises(RuntimeError):
                tour.pause_save('build')
        tour.base.adb.assert_called_once()
        tour.saved.assert_not_called()

    def test_header_walk_caption_or_incomplete_panel_cannot_fake_pause(self):
        frame = inspect_surface(self.active)
        heading = {'text': 'LUMO BAUWELT', 'bounds': [150, 76, 408, 99]}
        walk = {'text': 'Weiterbauen', 'bounds': [1696, 79, 1882, 97]}
        for rows in ([heading], [heading, walk], self.active_lines + self.paused_lines[-2:-1]):
            with self.subTest(rows=rows):
                self.assertIsNone(probe.build_pause_observation(rows, frame, candidate.normalized))
        duplicate = self.paused_lines + [{'text': 'Weiterbauen', 'bounds': [870, 550, 1050, 580]}]
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            probe.build_pause_observation(duplicate, frame, candidate.normalized)


if __name__ == '__main__':
    unittest.main()
