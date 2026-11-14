"""Replay the two real 1e22 Garage failures without running Android or OCR.

The fixtures are unchanged API35 captures and OCR outputs. These regression
checks constrain proposed touches; they do not establish a successful race.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import unittest

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence


FIXTURES = Path(__file__).with_name('fixtures') / 'kart-scroll-1e22'


class RealGarageScrollObservationsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.provenance = json.loads((FIXTURES / 'provenance.json').read_text())
        for name, series in cls.provenance['series'].items():
            for entry in series['files']:
                raw = (FIXTURES / name / entry['file']).read_bytes()
                if len(raw) != entry['bytes'] or hashlib.sha256(raw).hexdigest() != entry['sha256']:
                    raise AssertionError('Original fixture bytes changed: ' + name + '/' + entry['file'])

    def original(self, name, index):
        folder = FIXTURES / name
        journal = json.loads((folder / '21_stage_select_gecko_velo-surface-readiness.json').read_text())
        frame = journal['frames'][index]
        source = folder / frame['source']
        self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), frame['source_sha256'])
        with Image.open(source) as image:
            self.assertEqual(list(image.size), frame['pixels'])
        lines = json.loads((folder / f'21_stage_select_gecko_velo-{index}-ocr.json').read_text())
        return frame, lines, source

    def test_real_original_sources_keep_every_drag_inside_the_visible_caption(self):
        for name in ('android', 'update'):
            with self.subTest(original=name):
                frame, lines, _ = self.original(name, 0)
                plan = evidence.stage_garage_scroll_observation(frame, lines)
                original_card = frame['missing_caption_recovery']['card']['bounds']
                x0, y0, x1, y1 = original_card
                x, start, end_x, end = plan['gesture']
                self.assertTrue(x0 < x == end_x < x1)
                self.assertTrue(y0 < end < start < y1,
                                f'{name}: {plan["gesture"]} leaves observed caption {original_card}')
                self.assertGreaterEqual(start - end, 15)


if __name__ == '__main__':
    unittest.main()
