"""Original-frame/TSV boundary contracts, without Android or an OCR dependency.

The scheduler replays unchanged captured pixels and their actual saved OCR rows.
Adverse row edits are synthetic rejection cases, never visual acceptance.
The separate replay_flutter_loading_frame_ocr.py runs real Tesseract explicitly.
"""
import ast
from collections import deque
import csv
import hashlib
import importlib.util
import inspect
import io
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

from PIL import Image, ImageChops

ROOT = Path(__file__).resolve().parents[3]
FIXTURES = Path(__file__).parent / 'fixtures/flutter_loading_frame_3e08'
HELPER = ROOT / '.github/probes/creative_android_probe.py'
SURFACES = ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'
LOADING = 'Die Spielwelt wird geöffnet'
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
from native_ocr_tiles import observed_matches, read_tiled_word


def reader(command, *, clock=time, source=HELPER):
    names = {'digest', 'normalized', 'image_lines', 'gold_caption_boxes',
             'read_component_caption'}
    functions = [n for n in ast.parse(source.read_text()).body
                 if isinstance(n, ast.FunctionDef) and n.name in names]
    scope = dict(Path=Path, Image=Image, ImageChops=ImageChops, deque=deque,
                 csv=csv, hashlib=hashlib, json=json, math=math, re=re,
                 time=clock, unicodedata=unicodedata,
                 base=SimpleNamespace(command=command),
                 observed_matches=observed_matches, read_tiled_word=read_tiled_word)
    exec(compile(ast.Module(body=functions, type_ignores=[]), str(source), 'exec'), scope)
    return scope


def invoke(scope, out, source, wanted='spielpausiert', *, reject=True):
    # Baseline red replay exercises the old actual reader instead of failing
    # merely on an unsupported keyword. Production never uses this adapter.
    options = {}
    if 'reject_captions' in inspect.signature(scope['image_lines']).parameters:
        options['reject_captions'] = (LOADING,) if reject else ()
    return scope['image_lines'](out, 'frame', wanted, source_path=source,
                                exact=True, timeout=30, **options)


class OriginalFixtureCase(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads((FIXTURES / 'manifest.json').read_text())
        for record in manifest['files']:
            data = (FIXTURES / record['file']).read_bytes()
            if hashlib.sha256(data).hexdigest() != record['sha256']:
                raise RuntimeError('Original loading/return fixture changed: ' + record['file'])

    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)


class LoadingCaptionBoundaries(OriginalFixtureCase):
    def boundary(self, mutate):
        raw = (FIXTURES / 'android37-loading-contrast.tsv').read_text()
        rows = list(csv.DictReader(io.StringIO(raw), delimiter='\t', quoting=csv.QUOTE_NONE))
        groups = {}
        for row in rows:
            if row.get('text', '').strip():
                key = tuple(row[x] for x in ('page_num', 'block_num', 'par_num', 'line_num'))
                groups.setdefault(key, []).append(row)
        target = next(group for group in groups.values()
                      if ' '.join(row['text'] for row in group) == LOADING)
        mutate(rows, target)
        calls = []

        def command(*args, timeout):
            calls.append(list(args))
            with Path(args[2]).with_suffix('.tsv').open('w') as stream:
                writer = csv.DictWriter(stream, fieldnames=rows[0].keys(), delimiter='\t')
                writer.writeheader()
                writer.writerows(rows)
            return 'Controlled original-TSV boundary transport, not new OCR'

        scope = reader(command)
        # Fallbacks are deliberately empty only for these adverse-row cases;
        # no positive caption or successful return is produced by this test.
        scope['read_component_caption'] = lambda *_args, **_kwargs: []
        scope['read_tiled_word'] = lambda *_args, **_kwargs: []
        lines = invoke(scope, self.out, FIXTURES / 'android37-loading.png')
        self.assertGreater(len(calls), 1)
        self.assertFalse((self.out / 'frame-ocr-rejected.json').exists())
        self.assertFalse(any(scope['normalized'](x['text']) == 'spielpausiert' for x in lines))

    def test_out_of_image_negative_bounds_cannot_reject(self):
        self.boundary(lambda _rows, target: [row.update(left='999999') for row in target])

    def test_low_confidence_negative_words_cannot_reject(self):
        self.boundary(lambda _rows, target: [row.update(conf='14.99') for row in target])

    def test_partial_observed_phrase_cannot_reject(self):
        self.boundary(lambda rows, target: rows.remove(target[-1]))


class ReturnedFrameSequence(OriginalFixtureCase):
    def sequence(self, names):
        clock_value = [0.0]
        clock = SimpleNamespace(monotonic=lambda: clock_value[0],
            sleep=lambda seconds: clock_value.__setitem__(0, clock_value[0] + seconds))
        captures = []
        current = ['']
        commands = []
        tsvs = {
            'android37-loading.png': 'android37-loading-contrast.tsv',
            'android35-first-return-pause.png': 'android35-first-return-pause-contrast.tsv',
            'android35-final-return-pause.png': 'android35-final-return-pause-contrast.tsv',
        }

        def command(*args, timeout):
            commands.append(list(args))
            Path(args[2]).with_suffix('.tsv').write_bytes((FIXTURES / tsvs[current[0]]).read_bytes())
            clock_value[0] += .2
            return 'Original saved OCR rows for the exact selected PNG; no new OCR'

        scope = reader(command, clock=clock)

        def capture(out, tag, **_kwargs):
            current[0] = names[min(len(captures), len(names) - 1)]
            path = out / (tag + '.png')
            path.write_bytes((FIXTURES / current[0]).read_bytes())
            captures.append(path)
            clock_value[0] += .2
            return {'file': path.name}

        spec = importlib.util.spec_from_file_location('return_frame_readiness',
            ROOT / '.github/probes/flutter_surface_readiness.py')
        readiness = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(readiness)
        guard_scope = dict(Path=Path, json=json, time=clock,
            inspect_flutter_frame=readiness.inspect_flutter_frame,
            tour=SimpleNamespace(godot_alive=lambda: False, alive=lambda: True),
            resumed_activity=lambda: 'MainActivity',
            probe=SimpleNamespace(capture=capture, digest=scope['digest'],
                normalized=scope['normalized'], image_lines=scope['image_lines']))
        function = next(n for n in ast.parse(SURFACES.read_text()).body
                        if isinstance(n, ast.FunctionDef) and n.name == 'capture_returned_flutter')
        exec(compile(ast.Module(body=[function], type_ignores=[]), str(SURFACES), 'exec'), guard_scope)
        return guard_scope, captures, commands

    def test_loading_frame_then_two_fresh_positive_frames(self):
        scope, captures, commands = self.sequence(['android37-loading.png',
            'android35-first-return-pause.png', 'android35-final-return-pause.png'])
        scope['capture_returned_flutter'](self.out, 'return', ['Spiel pausiert'])
        report = json.loads((self.out / 'return-return-pixels.json').read_text())
        self.assertEqual([f['status'] for f in report['frames']],
                         ['REJECTED', 'CONFIRMED_FLUTTER_PIXELS', 'CONFIRMED_FLUTTER_PIXELS'])
        self.assertEqual(len(captures), 3)
        self.assertEqual(len(commands), 3, 'Rejected loading raster must not consume fallback passes')
        self.assertEqual(report['consecutive_confirmed_frames'], 2)
        self.assertEqual((self.out / 'return.png').read_bytes(),
                         (FIXTURES / 'android35-final-return-pause.png').read_bytes())

    def test_loading_observation_resets_prior_confirmation(self):
        scope, captures, commands = self.sequence(['android35-first-return-pause.png',
            'android37-loading.png', 'android35-first-return-pause.png',
            'android35-final-return-pause.png'])
        scope['capture_returned_flutter'](self.out, 'return', ['Spiel pausiert'])
        self.assertEqual(len(captures), 4)
        self.assertEqual(len(commands), 4)
        report = json.loads((self.out / 'return-return-pixels.json').read_text())
        self.assertEqual(report['frames'][1]['status'], 'REJECTED')
        self.assertEqual(report['consecutive_confirmed_frames'], 2)

    def test_only_loading_rasters_never_pass_or_extend_observation_cap(self):
        scope, captures, commands = self.sequence(['android37-loading.png'])
        with self.assertRaisesRegex(RuntimeError, 'twice before deadline'):
            scope['capture_returned_flutter'](self.out, 'return', ['Spiel pausiert'])
        self.assertEqual(len(captures), 12)
        self.assertEqual(len(commands), 12)
        report = json.loads((self.out / 'return-return-pixels.json').read_text())
        self.assertEqual(report['status'], 'FAIL')
        self.assertTrue(all(x['status'] == 'REJECTED' for x in report['frames']))
        self.assertFalse((self.out / 'return.png').exists())


if __name__ == '__main__':
    unittest.main()
