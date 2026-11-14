"""Replay actual failed Android frames; never an Android/gameplay acceptance.

Fixtures are byte-identical captures from run 43530667812: API35 artifact
14090824265 and API37 artifact 14090694722. The real reader uses real Tesseract.
Small synthetic cases exercise only error boundaries, never visual acceptance.
"""
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
from types import SimpleNamespace
import time
import unicodedata
import unittest

from PIL import Image, ImageChops, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
sys.path.insert(0, str(ROOT / 'scripts/probes'))
from native_ocr_tiles import observed_matches, read_tiled_word
import pr207_android_smoke as base

os.environ.setdefault('OMP_THREAD_LIMIT', '1')
FIXTURES = Path(__file__).parent / 'fixtures/native_caption_ocr'
FIXTURE_HASHES = {
    'learning-api35-first.png': '761ded680660bcb672d15168b01f788ddcda6f57b3d676ba81c9add3f471355e',
    'learning-api35-last.png': '1f8324a6ff73aff74f556b3dc585e580b9c8cac1e7321b08ee777fccab607108',
    'learning-api37-first.png': '36ee08a760694952bdbcdc13b7919bf34d82874e0dd35c83f4a66a13401ac843',
    'learning-api37-last.png': '1ed7f16afc03cba564df016f08f9dfec053a7e6ae12213561a54ea08d3e0c435',
}


def reader():
    # Execute the actual reader definitions without importing the unrelated
    # uiautomator connection. No OCR output or source image is mocked here.
    source = ROOT / '.github/probes/creative_android_probe.py'
    names = {'digest', 'normalized', 'image_lines', 'gold_caption_boxes',
             'read_component_caption'}
    definitions = [node for node in ast.parse(source.read_text()).body
                   if isinstance(node, ast.FunctionDef) and node.name in names]
    namespace = dict(Path=Path, Image=Image, ImageChops=ImageChops, deque=deque,
                     math=math, time=time, csv=csv, json=json, re=re,
                     unicodedata=unicodedata, hashlib=hashlib, base=base,
                     observed_matches=observed_matches, read_tiled_word=read_tiled_word)
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(source), 'exec'), namespace)
    return SimpleNamespace(**namespace)


class NativeCaptionOriginals(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        available = subprocess.check_output(['tesseract', '--list-langs'], text=True)
        if not {'deu', 'eng'} <= set(available.splitlines()):
            raise RuntimeError('The actual caption replay requires both installed deu and eng models')

    def check_original(self, name):
        probe = reader()
        source = FIXTURES / name
        before = hashlib.sha256(source.read_bytes()).hexdigest()
        self.assertEqual(before, FIXTURE_HASHES[name])
        with tempfile.TemporaryDirectory() as folder:
            lines = probe.image_lines(Path(folder), name[:-4], 'einobjektzeigen',
                                      source_path=source, timeout=120, exact=True)
        matches = [line for line in lines if probe.normalized(line['text']) == 'einobjektzeigen']
        self.assertTrue(matches, 'Actual original frame did not yield the exact requested caption')
        for line in matches:
            x0, y0, x1, y1 = line['bounds']
            # Human-inspected caption area in these original fixtures only.
            # It is an assertion, never an input region for the reader.
            self.assertTrue(70 < x0 < x1 < 502 and 1975 < y0 < y1 < 2112)
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), before)

    def test_original_api35_first_frame(self):
        self.check_original('learning-api35-first.png')

    def test_original_api35_last_frame(self):
        self.check_original('learning-api35-last.png')

    def test_original_api37_first_frame(self):
        self.check_original('learning-api37-first.png')

    def test_original_api37_last_frame(self):
        self.check_original('learning-api37-last.png')


class NativeCaptionBoundaries(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)
        self.probe = reader()
        self.source = self.out / 'synthetic-blank-gold.png'
        image = Image.new('RGB', (400, 300), '#102f45')
        ImageDraw.Draw(image).rectangle((90, 110, 310, 180), fill='#e3ae43')
        image.save(self.source)

    def tsv(self, prefix, text='Ein Objekt zeigen', *, left=12, confidence=90):
        columns = ['page_num', 'block_num', 'par_num', 'line_num', 'left', 'top',
                   'width', 'height', 'conf', 'text']
        with Path(prefix).with_suffix('.tsv').open('w') as stream:
            writer = csv.DictWriter(stream, fieldnames=columns, delimiter='\t')
            writer.writeheader()
            writer.writerow(dict(page_num=1, block_num=1, par_num=1, line_num=1,
                                 left=left, top=14, width=170, height=28,
                                 conf=confidence, text=text))

    def read(self, command=base.command, **kwargs):
        return self.probe.read_component_caption(self.source, self.out, 'observed',
                                                'einobjektzeigen', command=command, **kwargs)

    def test_decorative_gold_without_letters_does_not_fabricate_requested_caption(self):
        self.assertEqual(self.read(), [])
        evidence = json.loads((self.out / 'observed-ocr-components.json').read_text())
        self.assertFalse(evidence['matched'])
        self.assertEqual(evidence['scope'], 'Independent OCR; no gameplay or visibility PASS')

    def test_colour_components_follow_observed_pixels_in_unrelated_locations(self):
        image = Image.new('RGB', (400, 300), '#102f45')
        draw = ImageDraw.Draw(image)
        draw.rectangle((10, 20, 180, 60), fill='#e3ae43')
        draw.rectangle((200, 210, 380, 270), fill='#e3ae43')
        boxes = self.probe.gold_caption_boxes(image)
        for px, py in ((80, 40), (280, 240)):
            self.assertTrue(any(x0 < px < x1 and y0 < py < y1 for x0, y0, x1, y1 in boxes))
        self.assertTrue(all(0 <= x0 < x1 <= 400 and 0 <= y0 < y1 <= 300
                            for x0, y0, x1, y1 in boxes))
        self.assertLessEqual(len(boxes), 16)

    def test_exact_observed_text_and_confidence_cannot_be_replaced_by_requested_text(self):
        for text, confidence in [('Ein Objeks zeigen', 90), ('Ein Objekt zeigenn', 90),
                                 ('Ein Objekt zeigen', 14.99)]:
            with self.subTest(text=text, confidence=confidence):
                def command(*args, timeout):
                    self.tsv(args[2], text, confidence=confidence)
                    return 'synthetic boundary only'
                self.assertEqual(self.read(command), [])

    def test_internal_crop_edge_cannot_create_an_accepted_short_caption(self):
        def command(*args, timeout):
            self.tsv(args[2], left=0)
            return 'synthetic boundary only'
        self.assertEqual(self.read(command), [])

    def test_outside_word_bounds_are_a_hard_failure(self):
        def command(*args, timeout):
            self.tsv(args[2], left=-1)
            return 'synthetic boundary only'
        with self.assertRaisesRegex(RuntimeError, 'bounds exceed'):
            self.read(command)

    def test_actual_reader_exception_is_preserved_in_the_journal(self):
        def command(*args, timeout):
            raise RuntimeError('actual reader unavailable')
        with self.assertRaisesRegex(RuntimeError, 'actual reader unavailable'):
            self.read(command)
        report = json.loads((self.out / 'observed-ocr-components.json').read_text())
        self.assertEqual(report['status'], 'FAIL')
        self.assertIn('actual reader unavailable', report['error'])

    def test_remaining_total_budget_cannot_return_a_match_after_expiry(self):
        now = [0.0]
        calls = []
        def command(*args, timeout):
            calls.append(timeout)
            self.tsv(args[2])
            now[0] = 0.251
            return 'synthetic boundary only'
        with self.assertRaises(TimeoutError):
            self.read(command, timeout=0.25, clock=lambda: now[0])
        self.assertEqual(calls, [0.25])
        with self.assertRaises(ValueError):
            self.read(command, timeout=0)

    def test_modified_source_cannot_be_used_as_a_touch_target(self):
        def command(*args, timeout):
            self.tsv(args[2])
            Image.new('RGB', (400, 300), 'black').save(self.source)
            return 'synthetic boundary only'
        with self.assertRaisesRegex(RuntimeError, 'changed during OCR'):
            self.read(command)


if __name__ == '__main__':
    unittest.main()
