"""Studio layout-file publication contracts, with explicit synthetic sessions.

Original PNG bytes remain hash-bound renderer fixtures. The draw sequence and
Android observations assembled here are parser fixtures, never device proof.
The default 2018 publisher path still verifies its unchanged old fixtures.
"""
from __future__ import annotations

import copy
import hashlib
import inspect
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_nextgen_delivery as historical_tests
import verify_nextgen_delivery as delivery
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tools/android_qa'))
from nextgen_evidence import require_cards_face_pixels

FIXTURES = Path(__file__).resolve().parents[2] / 'tools/android_qa/tests/fixtures/cards_safe_area_2019'


def attach_synthetic_layouts(cards, output: Path, *, actual_safe_area_renderer=False):
    """Add mandatory sidecars to temporary parser fixtures, never real reports.

    StudioDeliveryTests can call this after constructing its historical
    proof_fixture. Historical tests themselves keep their original no-layout
    records and the default verifier behavior.
    """
    for stage_index, report in enumerate(cards['front_face_pixels']):
        for frame in report['frames']:
            public, pixels = frame['public_after'], frame['pixels']
            if actual_safe_area_renderer:
                name = 'android35_portrait-playing'
                raw = (FIXTURES / (name + '.png')).read_bytes()
                frame['source_sha256'] = hashlib.sha256(raw).hexdigest()
                (output / frame['source']).write_bytes(raw)
                frame['observations'] = copy.deepcopy(json.loads(
                    (FIXTURES / 'observations.json').read_text())[name])
                layout = json.loads((FIXTURES / (name + '.layout.json')).read_text())
                density = layout['density']
            else:
                width, height = pixels['pixels']
                density = pixels['density']
                layout = {'schema': 1, 'window_px': [width, height],
                    'viewport_px': [width, height], 'density': density,
                    'ui_rect': [0, 0, width, height],
                    'android_observation': {'view_size': [width, height],
                        'decor_size': [width, height], 'render_rect': [0, 0, width, height],
                        'system_insets': [0, 0, 0, 0], 'insets': [0, 0, 0, 0]},
                    'hand': [{'id': item['card_id'], 'quad': item['quad']}
                             for item in pixels['faces'][:-1]],
                    'discard': {'id': pixels['faces'][-1]['card_id'],
                                'quad': pixels['faces'][-1]['quad']}}
            # These are intentionally synthetic state/transport bindings; only
            # the imported original PNG and renderer geometry are real.
            layout.update(observation_source='android_window_insets',
                test_fixture='synthetic publisher parser fixture, not an Android observation',
                token=public['token'], roundId=public['roundId'],
                revision=public['revision'], ack=public['ack'], viewer=public['viewer'],
                phase=public['phase'], paused=public['paused'], pending=0,
                selected_card_id='', settled=True, ui_visible=True,
                page=0, page_size=len(layout['hand']), layout_sequence=stage_index + 1,
                ticks_msec=1000 + stage_index)
            for edge in ('before', 'after'):
                source = Path(frame['source']).stem + '-' + edge + '-layout.json'
                path = output / source
                path.write_text(json.dumps(layout, sort_keys=True) + '\n')
                frame['layout_' + edge] = {'layout': copy.deepcopy(layout), 'source': source,
                    'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
            frame['pixels'] = require_cards_face_pixels(output / frame['source'], public,
                density=density, observations=frame['observations'], layout=layout)
        final = report['frames'][-1]
        (output / report['source']).write_bytes((output / final['source']).read_bytes())
        report['source_sha256'] = final['source_sha256']
        report['layout_sha256'] = final['pixels']['layout_binding']['layout_sha256']
        report['layout_sequence'] = final['pixels']['layout_binding']['layout_sequence']
    historical_tests.NextgenDeliveryTests.write_pixel_reports(cards, output)


class StudioCardsDeliveryTests(unittest.TestCase):
    cards_pixel_fixture = historical_tests.NextgenDeliveryTests.cards_pixel_fixture
    write_pixel_reports = staticmethod(historical_tests.NextgenDeliveryTests.write_pixel_reports)

    def fixture(self, *, layout=True, actual_safe_area_renderer=False):
        args = historical_tests.NextgenDeliveryTests.proof_fixture(self)
        cards, output = args[10]['cards'], args[12]
        if layout:
            attach_synthetic_layouts(cards, output, actual_safe_area_renderer=actual_safe_area_renderer)
        return cards, output

    def verify(self, cards, output):
        # Red replay of the exact old verifier remains executable. Removing
        # the new required option cannot pass the missing-layout countercase.
        if 'require_layout' not in inspect.signature(delivery.verify_cards_front_faces).parameters:
            return delivery.verify_cards_front_faces(cards, output)
        return delivery.verify_cards_front_faces(cards, output, require_layout=True)

    def test_legacy_default_still_accepts_unchanged_no_layout_records(self):
        cards, output = self.fixture(layout=False)
        original = copy.deepcopy(cards)
        result = delivery.verify_cards_front_faces(cards, output)
        self.assertEqual(cards, original)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(len(result['stages']), 4)

    def test_studio_requires_layout_even_when_legacy_pixel_report_is_valid(self):
        cards, output = self.fixture(layout=False)
        with self.assertRaisesRegex(ValueError, 'layout'):
            self.verify(cards, output)

    def test_studio_recomputes_original_pixels_and_both_raw_layout_files(self):
        for real_geometry in (False, True):
            cards, output = self.fixture(actual_safe_area_renderer=real_geometry)
            original = copy.deepcopy(cards)
            hashes = {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                      for path in output.iterdir()}
            result = self.verify(cards, output)
            self.assertEqual(result['status'], 'PASS')
            self.assertEqual(len(result['stages']), 4)
            self.assertEqual(cards, original)
            self.assertEqual(hashes, {path.name: hashlib.sha256(path.read_bytes()).hexdigest()
                                     for path in output.iterdir()})

    def test_missing_modified_symlinked_or_foreign_layout_files_are_rejected(self):
        for mutation in ('absent-record', 'missing-file', 'symlink', 'path', 'hash',
                         'changed-raw-bytes', 'embedded-different', 'changed-during-frame'):
            cards, output = self.fixture()
            frame = cards['front_face_pixels'][0]['frames'][-1]
            item = frame['layout_after']
            path = output / item['source']
            if mutation == 'absent-record':
                del frame['layout_after']
            elif mutation == 'missing-file':
                path.unlink()
            elif mutation == 'symlink':
                path.unlink()
                path.symlink_to(output / frame['layout_before']['source'])
            elif mutation == 'path':
                item['source'] = '../outside-layout.json'
            elif mutation == 'hash':
                item['source_sha256'] = '0' * 64
            elif mutation == 'changed-raw-bytes':
                path.write_bytes(path.read_bytes() + b' ')
            elif mutation == 'embedded-different':
                item['layout']['ui_rect'][1] = 9
            elif mutation == 'changed-during-frame':
                item['layout']['layout_sequence'] += 1
                path.write_text(json.dumps(item['layout']))
                item['source_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
            self.write_pixel_reports(cards, output)
            with self.subTest(mutation=mutation), self.assertRaisesRegex(ValueError, 'layout'):
                self.verify(cards, output)

    def test_forged_but_consistently_hashed_measurements_do_not_replace_geometry(self):
        for field, value in (('revision', 99), ('observation_source', 'fixture'),
                             ('settled', False), ('window_px', [2400, 1080]),
                             ('ui_rect', [0, 32, 1080, 2320])):
            cards, output = self.fixture(actual_safe_area_renderer=True)
            frame = cards['front_face_pixels'][0]['frames'][-1]
            for edge in ('before', 'after'):
                item = frame['layout_' + edge]
                item['layout'][field] = value
                path = output / item['source']
                path.write_text(json.dumps(item['layout']))
                item['source_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
            self.write_pixel_reports(cards, output)
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.verify(cards, output)

    def test_two_frame_layout_sequence_and_report_binding_cannot_be_changed(self):
        for field in ('layout_sha256', 'layout_sequence'):
            cards, output = self.fixture()
            report = cards['front_face_pixels'][0]
            report[field] = '0' * 64 if field == 'layout_sha256' else report[field] + 1
            self.write_pixel_reports(cards, output)
            with self.subTest(field=field), self.assertRaisesRegex(ValueError, 'layout'):
                self.verify(cards, output)


if __name__ == '__main__':
    unittest.main()
