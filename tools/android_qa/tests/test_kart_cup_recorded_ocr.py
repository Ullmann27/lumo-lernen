"""Replay original Host51e cup observations, not an Android execution.

The failed API35, API37 and in-place-update jobs all included an OCR line
combining decoration with the cup title. Original JSON bytes stay unchanged;
the negative cases below are explicitly derived from those observations.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import kart_garage_evidence as evidence


FIXTURES = Path(__file__).parent / 'fixtures' / 'kart-cup-host51e'
MANIFEST = json.loads((FIXTURES / 'manifest.json').read_text())


class CupRecordedOcrTests(unittest.TestCase):
    def recording(self, name):
        case = next(item for item in MANIFEST['cases'] if item['name'] == name)
        data = {}
        for kind in ('ocr', 'readiness'):
            raw = (FIXTURES / case[kind]).read_bytes()
            self.assertEqual(len(raw), case['original_files'][kind]['bytes'])
            self.assertEqual(hashlib.sha256(raw).hexdigest(),
                             case['original_files'][kind]['sha256'])
            data[kind] = json.loads(raw)
        self.assertEqual(data['readiness']['status'], 'FAIL')
        frame = data['readiness']['frames'][0]
        self.assertEqual(frame['source_sha256'], case['png']['sha256'])
        self.assertEqual(frame['pixels'], [2400, 1080])
        return frame, data['ocr']

    def assert_original_caption(self, name):
        frame, rows = self.recording(name)
        self.assertIn({'text': '= Grand Prix', 'bounds': [62.0, 240.0, 385.0, 455.0],
                       'variant': 'contrast'}, rows)
        # Reversing OCR variants must not turn the composite into a second
        # control or make its oversized region the selected touch target.
        for observations in (rows, list(reversed(rows))):
            with self.subTest(name=name, first=observations[0]['text']):
                selected = evidence.stage_cup_target_observation(frame, observations)
                self.assertEqual(selected['caption'], 'Grand Prix')
                self.assertEqual(selected['target']['text'], 'Grand Prix')
                self.assertIn(selected['target']['bounds'],
                              ([170.0, 397.0, 385.0, 426.0],
                               [170.0, 395.0, 385.0, 426.0]))
                self.assertEqual(selected['matching_observations'], 2)

    def test_original_api35_cup_caption_is_not_confused_with_decoration(self):
        self.assert_original_caption('api35')

    def test_original_api37_cup_caption_is_not_confused_with_decoration(self):
        self.assert_original_caption('api37')

    def test_original_update_cup_caption_is_not_confused_with_decoration(self):
        self.assert_original_caption('update')

    def test_decoration_without_an_observed_full_caption_is_rejected(self):
        for name in ('api35', 'api37', 'update'):
            frame, rows = self.recording(name)
            # Fault injection: remove both actual text observations, retaining
            # the original decorated line and all original navigation rows.
            rows = [row for row in rows if row['text'] != 'Grand Prix']
            with self.subTest(name=name), self.assertRaisesRegex(
                    RuntimeError, 'No actual Grand Prix or Pokal caption'):
                evidence.stage_cup_target_observation(frame, rows)

    def test_a_second_real_caption_region_still_fails_closed(self):
        for name in ('api35', 'api37', 'update'):
            frame, rows = self.recording(name)
            # Derived negative case: a genuinely distinct exact-title region,
            # above the observed navigation, must remain ambiguous.
            rows.append({'text': 'Grand Prix', 'bounds': [800, 397, 1015, 426]})
            with self.subTest(name=name), self.assertRaisesRegex(
                    RuntimeError, 'Ambiguous cup-caption regions'):
                evidence.stage_cup_target_observation(frame, rows)

    def test_existing_caption_aliases_keep_case_and_whitespace_normalization(self):
        frame, original = self.recording('api35')
        navigation = [row for row in original if row['text'] in ('Fahrer', 'Garage')]
        for text, expected in (('Grand Prix', 'Grand Prix'), ('GrandPrix', 'Grand Prix'),
                               (' GRAND\tPRIX ', 'Grand Prix'),
                               ('Grand\u00a0Prix', 'Grand Prix'),
                               ('Pokal', 'Pokal'), (' POKAL ', 'Pokal')):
            rows = navigation + [{'text': text, 'bounds': [170, 397, 385, 426]}]
            with self.subTest(text=text):
                selected = evidence.stage_cup_target_observation(frame, rows)
                self.assertEqual(selected['caption'], expected)

    def test_symbols_do_not_become_real_caption_aliases(self):
        frame, original = self.recording('api35')
        navigation = [row for row in original if row['text'] in ('Fahrer', 'Garage')]
        for text in ('= Grand Prix', 'Grand Prix =', 'Grand=Prix', '+ Pokal', 'Pokal *'):
            rows = navigation + [{'text': text, 'bounds': [170, 397, 385, 426]}]
            with self.subTest(text=text), self.assertRaisesRegex(
                    RuntimeError, 'No actual Grand Prix or Pokal caption'):
                evidence.stage_cup_target_observation(frame, rows)


if __name__ == '__main__':
    unittest.main()
