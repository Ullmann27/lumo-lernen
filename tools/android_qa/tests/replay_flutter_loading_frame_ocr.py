"""Explicit real-Tesseract replay of original 3e08 return PNGs, not Android QA.

Requires actual deu+eng models. Kept outside test_ discovery so general host
contracts do not acquire an unadvertised Tesseract dependency.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
import unittest

from test_flutter_loading_frame_rejection import (
    FIXTURES, HELPER, LOADING, OriginalFixtureCase, invoke, reader)

os.environ.setdefault('OMP_THREAD_LIMIT', '1')


class OriginalLoadingRasterReplay(OriginalFixtureCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        listing = subprocess.check_output(['tesseract', '--list-langs'], text=True)
        if not {'deu', 'eng'} <= set(listing.splitlines()):
            raise RuntimeError('Real loading-frame replay requires actual deu and eng models')

    def setUp(self):
        super().setUp()
        self.commands = []
        if os.environ.get('LUMO_LOADING_REPLAY_DIR'):
            self.out = Path(os.environ['LUMO_LOADING_REPLAY_DIR']) / self._testMethodName
            self.out.mkdir(parents=True, exist_ok=False)

    def command(self, *args, timeout):
        started = time.monotonic()
        result = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, timeout=timeout, check=True)
        self.commands.append({'command': list(args), 'timeout': timeout,
                              'elapsed_seconds': time.monotonic() - started,
                              'returncode': result.returncode,
                              'stdout': result.stdout, 'stderr': result.stderr})
        return result.stdout + result.stderr

    def tearDown(self):
        (self.out / 'executed-ocr.json').write_text(json.dumps({
            'source': str(HELPER), 'source_sha256': hashlib.sha256(HELPER.read_bytes()).hexdigest(),
            'commands': self.commands, 'scope': 'Actual local OCR, no Android/device run'}, indent=2) + '\n')

    def test_actual_loading_caption_rejects_after_first_pass(self):
        scope = reader(self.command)
        source = FIXTURES / 'android37-loading.png'
        before = source.read_bytes()
        with self.assertRaisesRegex(RuntimeError, 'Rejected.*caption'):
            invoke(scope, self.out, source)
        self.assertEqual(len(self.commands), 1)
        self.assertEqual(source.read_bytes(), before)
        rows = json.loads((self.out / 'frame-ocr.json').read_text())
        self.assertTrue(any(scope['normalized'](x['text']) == scope['normalized'](LOADING) for x in rows))
        report = json.loads((self.out / 'frame-ocr-rejected.json').read_text())
        self.assertEqual(report['status'], 'REJECTED_FRAME')
        self.assertEqual(report['source_sha256'], hashlib.sha256(before).hexdigest())
        self.assertFalse(list(self.out.glob('*component*.tsv')))
        self.assertFalse(list(self.out.glob('*tile*.tsv')))

    def test_actual_loading_has_priority_even_over_an_observed_positive_title(self):
        scope = reader(self.command)
        with self.assertRaisesRegex(RuntimeError, 'Rejected.*caption'):
            invoke(scope, self.out, FIXTURES / 'android37-loading.png', 'lumocards')
        self.assertEqual(len(self.commands), 1)

    def check_pause(self, name):
        scope = reader(self.command)
        source = FIXTURES / name
        before = source.read_bytes()
        rows = invoke(scope, self.out, source)
        matches = [x for x in rows if scope['normalized'](x['text']) == 'spielpausiert']
        self.assertTrue(matches)
        for line in matches:
            x0, y0, x1, y1 = line['bounds']
            self.assertTrue(0 <= x0 < x1 <= 1080 and 0 <= y0 < y1 <= 2400)
        self.assertEqual(len(self.commands), 1, 'No separate negative-caption OCR search')
        self.assertEqual(source.read_bytes(), before)
        self.assertFalse((self.out / 'frame-ocr-rejected.json').exists())

    def test_actual_api35_first_pause_still_matches(self):
        self.check_pause('android35-first-return-pause.png')

    def test_actual_api35_final_pause_still_matches(self):
        self.check_pause('android35-final-return-pause.png')

    def test_actual_api37_eventual_pause_still_matches(self):
        self.check_pause('android37-eventual-pause.png')

    def test_default_reader_does_not_apply_loading_rejection(self):
        scope = reader(self.command)
        rows = invoke(scope, self.out, FIXTURES / 'android37-loading.png', 'lumocards', reject=False)
        self.assertTrue(any(scope['normalized'](x['text']) == 'lumocards' for x in rows))
        self.assertEqual(len(self.commands), 1)
        self.assertFalse((self.out / 'frame-ocr-rejected.json').exists())


if __name__ == '__main__':
    unittest.main()
