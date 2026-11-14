"""Real failed Android pixels through the actual OCR reader, plus error guards.

The five PNGs are unchanged members of artifact14129993358/run43626348519.
This is offline image recognition, never an Android input or gameplay PASS.
Missing Tesseract, Pillow, German or English data is an error, never a skip.
"""
from __future__ import annotations

import ast
from collections import deque
import csv
import hashlib
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import threading
from types import SimpleNamespace
import time
import unicodedata
import unittest
from unittest.mock import patch

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from native_ocr_tiles import observed_matches, read_tiled_word

os.environ.setdefault('OMP_THREAD_LIMIT', '1')
FIXTURES = Path(__file__).parent / 'fixtures/creative_caption_28462'
SOURCE = Path(os.environ.get('LUMO_CREATIVE_REPLAY_SOURCE',
                            str(ROOT / '.github/probes/creative_android_probe.py')))
STUDIO = ROOT / '.github/probes/studio_creative_android_probe.py'
JUMP = 'Zur Spieleauswahl · Abenteuer behalten'
HASHES = {
    'jump-pause-first.png': 'bdfe7eec79b5ad1b68b5be2fb0dc4f752cf10e8a4b5f91e086f6ccf9d2ed0272',
    'jump-pause-last.png': '63ce9a216f709c054d44eb55d0383ae55d6d7221fae06f4184da806ab964925b',
    'treasure-playable-first.png': '436eae27d1d70a08f9698626d5e329848412bee9e0a3f02cddf92d874052bbd8',
    'treasure-playable-last.png': 'c24e640f928eac3c8f8d99759c38d9bfb3dafb6d30dec76926eb1c2aa154b743',
    'treasure-paused.png': 'e26ebed7edd1053c61d8fd06d07dfacb2d94231706fa5033b896f5cfacf6b1e1',
}


def command(*args, timeout):
    result = subprocess.run(args, check=True, capture_output=True, text=True, timeout=timeout)
    return result.stdout + result.stderr


def reader():
    # Execute the real definitions without opening an unrelated UI-automator
    # connection. Actual image processing, Tesseract and TSV parsing are intact.
    names = {'digest', 'normalized', 'image_lines', 'gold_caption_boxes',
             'read_component_caption'}
    definitions = [node for node in ast.parse(SOURCE.read_text()).body
                   if isinstance(node, ast.FunctionDef) and node.name in names]
    if {node.name for node in definitions} != names:
        raise RuntimeError('Actual OCR definitions are incomplete')
    namespace = dict(Path=Path, Image=Image, ImageChops=ImageChops, deque=deque,
                     math=math, time=time, csv=csv, json=json, re=re,
                     unicodedata=unicodedata, hashlib=hashlib,
                     base=SimpleNamespace(command=command),
                     observed_matches=observed_matches, read_tiled_word=read_tiled_word)
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(SOURCE), 'exec'), namespace)
    predicates = [node for node in ast.parse(STUDIO.read_text()).body
                  if isinstance(node, ast.FunctionDef) and node.name == 'treasure_playing_captions']
    if len(predicates) != 1:
        raise RuntimeError('Actual Treasure caption contract is unavailable')
    exec(compile(ast.Module(body=predicates, type_ignores=[]), str(STUDIO), 'exec'), namespace)
    return SimpleNamespace(**namespace)


class CreativeOriginalPixels(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        available = subprocess.check_output(['tesseract', '--list-langs'], text=True)
        if not {'deu', 'eng'} <= {line.strip() for line in available.splitlines()}:
            raise RuntimeError('Original-pixel replay requires installed deu and eng language data')
        cls.version = subprocess.check_output(['tesseract', '--version'], text=True).splitlines()[0]

    def replay(self, name, *, jump):
        probe = reader()
        source = FIXTURES / name
        before = hashlib.sha256(source.read_bytes()).hexdigest()
        self.assertEqual(before, HASHES[name])
        helper_before = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
        if os.environ.get('LUMO_CREATIVE_REPLAY_OUT'):
            out = Path(os.environ['LUMO_CREATIVE_REPLAY_OUT']) / Path(name).stem
            out.mkdir(parents=True, exist_ok=False)
        else:
            temporary = tempfile.TemporaryDirectory()
            self.addCleanup(temporary.cleanup)
            out = Path(temporary.name)
        started = time.monotonic()
        options = {} if jump else {'parallel_inventory': True}
        lines = probe.image_lines(out, Path(name).stem,
                                  probe.normalized(JUMP) if jump else '',
                                  source_path=source, timeout=120 if jump else 20,
                                  exact=jump, **options)
        elapsed = time.monotonic() - started
        with Image.open(source) as image:
            dimensions = list(image.size)
        report = {'scope': 'Offline original-pixel OCR; no Android, input or gameplay claim',
                  'artifact_id': 14129993358, 'run_id': 43626348519,
                  'file': name, 'sha256': before, 'dimensions': dimensions,
                  'helper_sha256': helper_before, 'tesseract': self.version,
                  'elapsed_seconds': elapsed, 'recognized_lines': lines}
        (out / 'replay.json').write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), before)
        self.assertEqual(hashlib.sha256(SOURCE.read_bytes()).hexdigest(), helper_before)
        self.assertLess(elapsed, 120 if jump else 20)
        if jump:
            matches = [line for line in lines if probe.normalized(line['text']) == probe.normalized(JUMP)]
            self.assertTrue(matches, 'The actual complete Jump return caption was not recognized')
            self.assertEqual(dimensions, [1080, 1920])
            for line in matches:
                x0, y0, x1, y1 = line['bounds']
                # Human-reviewed original caption area, assertion only. These
                # bounds are never supplied to the reader or an input driver.
                self.assertTrue(240 < x0 < x1 < 840 and 920 < y0 < y1 < 970)
        else:
            self.assertEqual(dimensions, [1920, 1080])
            self.assertTrue(probe.treasure_playing_captions(lines),
                            'The unchanged Treasure HUD/modal predicate rejected the real frame')
            # Sparse OCR can group the observed border glyphs with a label.
            # Check the actual complete HUD control area, not an invented
            # glyph-only box; these regions are assertions, never reader input.
            for text, area in [('rucksack', (1640, 40, 1905, 140)),
                               ('ansehen', (1680, 790, 1900, 1005))]:
                matches = [line for line in lines if text in probe.normalized(line['text'])]
                self.assertTrue(matches)
                self.assertTrue(any(area[0] < line['bounds'][0] < line['bounds'][2] < area[2]
                                    and area[1] < line['bounds'][1] < line['bounds'][3] < area[3]
                                    for line in matches), 'Recognized HUD must have current original pixel bounds')

    def test_original_jump_first(self):
        self.replay('jump-pause-first.png', jump=True)

    def test_original_jump_last(self):
        self.replay('jump-pause-last.png', jump=True)

    def test_original_treasure_first(self):
        self.replay('treasure-playable-first.png', jump=False)

    def test_original_treasure_last(self):
        self.replay('treasure-playable-last.png', jump=False)

    def test_original_pause_with_visible_background_hud_cannot_complete(self):
        probe = reader()
        source = FIXTURES / 'treasure-paused.png'
        before = hashlib.sha256(source.read_bytes()).hexdigest()
        self.assertEqual(before, HASHES[source.name])
        if os.environ.get('LUMO_CREATIVE_REPLAY_OUT'):
            out = Path(os.environ['LUMO_CREATIVE_REPLAY_OUT']) / 'treasure-paused'
            out.mkdir(parents=True, exist_ok=False)
        else:
            temporary = tempfile.TemporaryDirectory()
            self.addCleanup(temporary.cleanup)
            out = Path(temporary.name)
        lines = probe.image_lines(out, 'treasure-paused', source_path=source,
                                  timeout=20, parallel_inventory=True)
        (out / 'negative-replay.json').write_text(json.dumps({
            'scope': 'Real paused original pixels with visible background HUD, no Android run',
            'sha256': before, 'tesseract': self.version, 'lines': lines,
        }, indent=2, ensure_ascii=False) + '\n')
        self.assertFalse(probe.treasure_playing_captions(lines))
        first = [line for line in lines if line['variant'] == 'neutral-ink-1x']
        self.assertTrue(any('rucksack' in probe.normalized(line['text']) for line in first))
        self.assertTrue(any('ansehen' in probe.normalized(line['text']) for line in first))
        self.assertTrue(any('weitererkunden' in probe.normalized(line['text'])
                            or 'deinabenteuerwartet' in probe.normalized(line['text']) for line in first))
        for variant in ('neutral-ink-1x', 'contrast', 'raw', 'white-text', 'white-latin',
                        'navy-latin', 'navy-latin-1x', 'teal-text-1x'):
            self.assertTrue((out / ('treasure-paused-ocr-' + variant + '.tsv')).is_file())
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), before)


class CreativeCaptionGuards(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)
        self.source = self.out / 'synthetic-transport-only.png'
        Image.new('RGB', (400, 300), '#7766dd').save(self.source)
        self.probe = reader()
        self.calls = []

    def tsv_command(self, text='', confidence=90):
        def call(*args, timeout):
            self.calls.append((Path(args[2]).name, timeout))
            columns = ['page_num', 'block_num', 'par_num', 'line_num', 'left', 'top',
                       'width', 'height', 'conf', 'text']
            with Path(args[2]).with_suffix('.tsv').open('w') as stream:
                writer = csv.DictWriter(stream, fieldnames=columns, delimiter='\t')
                writer.writeheader()
                if text:
                    writer.writerow(dict(page_num=1, block_num=1, par_num=1, line_num=1,
                                         left=20, top=30, width=120, height=20,
                                         conf=confidence, text=text))
            return 'Synthetic OCR transport boundary; not a captured caption'
        return call

    def read(self, text, *, exact=True, timeout=5):
        return self.probe.image_lines(self.out, 'boundary', self.probe.normalized(text),
                                      source_path=self.source, timeout=timeout, exact=exact)

    def no_fallback(self, *_args, **_kwargs):
        self.fail('The existing Kart cue must not enter general OCR fallbacks')

    def test_wrong_return_caption_is_not_replaced_by_requested_text(self):
        with patch.object(self.probe.base, 'command', self.tsv_command('Zum Lernen · Abenteuer behalten')), \
             patch.dict(self.probe.image_lines.__globals__,
                        read_component_caption=lambda *_a, **_k: [],
                        read_tiled_word=lambda *_a, **_k: []):
            lines = self.read(JUMP)
        self.assertFalse(any(self.probe.normalized(line['text']) == self.probe.normalized(JUMP)
                             for line in lines))

    def test_low_confidence_return_does_not_bypass_existing_minimum(self):
        with patch.object(self.probe.base, 'command', self.tsv_command(JUMP, confidence=14.99)), \
             patch.dict(self.probe.image_lines.__globals__,
                        read_component_caption=lambda *_a, **_k: [],
                        read_tiled_word=lambda *_a, **_k: []):
            self.assertEqual(self.read(JUMP), [])

    def test_kart_missing_cue_keeps_two_original_variants_without_fallback(self):
        with patch.object(self.probe.base, 'command', self.tsv_command()), \
             patch.dict(self.probe.image_lines.__globals__,
                        read_component_caption=self.no_fallback, read_tiled_word=self.no_fallback):
            self.assertEqual(self.read('Tippen zum Überspringen'), [])
        self.assertEqual([name for name, _ in self.calls],
                         ['boundary-ocr-preview-muted-blue', 'boundary-ocr-preview-raw-1x'])

    def test_other_target_keeps_original_first_reader(self):
        with patch.object(self.probe.base, 'command', self.tsv_command('Pause')):
            lines = self.read('Pause')
        self.assertTrue(lines)
        self.assertTrue(all(self.probe.normalized(line['text']) == 'pause' for line in lines))
        self.assertEqual([name for name, _ in self.calls], ['boundary-ocr-contrast'])

    def test_expired_budget_never_starts_a_tesseract_process(self):
        with patch.object(self.probe.base, 'command', self.tsv_command(JUMP)), \
             self.assertRaises(TimeoutError):
            self.read(JUMP, timeout=0)
        self.assertEqual(self.calls, [])

    def test_parallel_inventory_finishing_after_deadline_cannot_return(self):
        now = [0.0]
        write_tsv = self.tsv_command('Rucksack ANSEHEN')

        def slow(*args, timeout):
            result = write_tsv(*args, timeout=timeout)
            now[0] = 2
            return result

        with patch.object(self.probe.base, 'command', slow), \
             patch.dict(self.probe.image_lines.__globals__,
                        time=SimpleNamespace(monotonic=lambda: now[0])), \
             self.assertRaises(TimeoutError):
            self.probe.image_lines(self.out, 'late', source_path=self.source,
                                   timeout=1, parallel_inventory=True)
        self.assertTrue(self.calls)
        self.assertFalse((self.out / 'late-ocr.json').exists())

    def test_late_modal_variant_cannot_be_hidden_by_first_positive_hud(self):
        def command_for_variant(*args, timeout):
            text = 'Weiter erkunden' if str(args[2]).endswith('navy-latin-1x') else 'Rucksack ANSEHEN'
            return self.tsv_command(text)(*args, timeout=timeout)

        with patch.object(self.probe.base, 'command', command_for_variant):
            lines = self.probe.image_lines(self.out, 'inventory', source_path=self.source,
                                           timeout=5, parallel_inventory=True)
        self.assertFalse(self.probe.treasure_playing_captions(lines))
        self.assertEqual([line['variant'] for line in lines],
                         ['neutral-ink-1x', 'contrast', 'raw', 'white-text', 'white-latin',
                          'navy-latin', 'navy-latin-1x'])
        self.assertEqual(lines[-1]['text'], 'Weiter erkunden')
        self.assertEqual(len({name for name, _ in self.calls}), 7)
        self.assertEqual(len(list(self.out.glob('inventory-ocr-*.png'))), 7)

    def test_failed_variant_returns_no_partial_inventory_and_leaves_no_worker(self):
        active = [0]
        peak = [0]
        lock = threading.Lock()

        def one_failure(*args, timeout):
            with lock:
                active[0] += 1
                peak[0] = max(peak[0], active[0])
            try:
                if str(args[2]).endswith('-raw'):
                    raise RuntimeError('Synthetic OCR process failure')
                return self.tsv_command('Rucksack ANSEHEN')(*args, timeout=timeout)
            finally:
                with lock:
                    active[0] -= 1

        with patch.object(self.probe.base, 'command', one_failure), \
             self.assertRaisesRegex(RuntimeError, 'Synthetic OCR process failure'):
            self.probe.image_lines(self.out, 'failed', source_path=self.source,
                                   timeout=5, parallel_inventory=True)
        self.assertEqual(active[0], 0)
        self.assertLessEqual(peak[0], 3)
        self.assertFalse((self.out / 'failed-ocr.json').exists())

    def test_negative_caption_retains_precedence_over_target_search(self):
        with patch.object(self.probe.base, 'command', self.tsv_command('Die Spielwelt wird geöffnet')), \
             self.assertRaisesRegex(RuntimeError, 'Rejected captured Flutter frame'):
            self.probe.image_lines(self.out, 'negative', self.probe.normalized(JUMP),
                                   source_path=self.source, timeout=5, exact=True,
                                   reject_captions=('Die Spielwelt wird geöffnet',))

    def test_existing_treasure_modal_and_missing_hud_still_reject(self):
        predicate = self.probe.treasure_playing_captions
        self.assertFalse(predicate([{'text': 'Rucksack'}]))
        self.assertFalse(predicate([{'text': 'ANSEHEN'}]))
        for modal in ('Weiter erkunden', 'Dein Abenteuer wartet', 'Zur Spielewelt',
                      'Dein Abenteuer-Rucksack', 'Dein nächster Hinweis'):
            with self.subTest(modal=modal):
                self.assertFalse(predicate([{'text': 'Rucksack'}, {'text': 'ANSEHEN'}, {'text': modal}]))


if __name__ == '__main__':
    unittest.main()
