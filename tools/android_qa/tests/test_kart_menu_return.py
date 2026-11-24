"""Exercise real tour control flow with unchanged Update848/API35 observations.

The garage frames are the actual failed return. The earlier landing frames are
used only as a synthetic future observation; these tests do not prove a live
Android transition or invent a successful frame in either original artifact.
"""
from __future__ import annotations

from contextlib import ExitStack
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from test_modernization_tour_identity import load_tour


FIXTURES = Path(__file__).parent / 'fixtures/kart-return-host848'
MANIFEST = json.loads((FIXTURES / 'manifest.json').read_text())
TOUR = load_tour()


class RecordedFrames:
    """Script observation timing, never APK state or coordinates."""
    def __init__(self, out: Path, case: str, *, succeeds_on=1):
        self.out, self.clock = out, 0.0
        self.state, self.pending = 'landing', None
        self.succeeds_on = succeeds_on
        self.section_gestures = 0
        self.gestures, self.observations = [], []
        self.by_tag = {}
        entry = next(item for item in MANIFEST['cases'] if item['name'] == case)
        self.frames = {}
        for state, files in entry['states'].items():
            values = {}
            for kind, metadata in files.items():
                raw = (FIXTURES / metadata['path']).read_bytes()
                assert len(raw) == metadata['bytes']
                assert hashlib.sha256(raw).hexdigest() == metadata['sha256']
                values[kind] = raw if kind == 'png' else json.loads(raw)
            self.frames[state] = values

    def capture(self, out, tag, **_kwargs):
        self.clock += .1
        if self.pending is not None:
            self.pending += 1
            if (self.succeeds_on is not None and self.section_gestures >= self.succeeds_on
                    and self.pending >= 2):
                self.state, self.pending = 'landing', None
        self.by_tag[tag] = self.state
        self.observations.append((tag, self.state, self.section_gestures))
        data = self.frames[self.state]['png']
        target = out / (tag + '.png')
        target.write_bytes(data)
        return {'file': target.name, 'width': 2400, 'height': 1080,
                'sha256': hashlib.sha256(data).hexdigest()}

    def lines(self, _out, tag, *_args, **_kwargs):
        return copy.deepcopy(self.frames[self.by_tag[tag]]['ocr'])

    def native_text(self, _out, label, _tag, *, tap=False, **_kwargs):
        if tap and label in ('Garage', 'Fahrer'):
            self.state, self.pending, self.section_gestures = 'garage', None, 0

    def adb(self, *args, **_kwargs):
        if self.state == 'landing':
            return ''  # The existing actual-cup reader's initial mode touch.
        if args[:3] not in (('shell', 'input', 'tap'), ('shell', 'input', 'swipe')):
            raise AssertionError('Unexpected fixture device command: ' + repr(args))
        self.gestures.append(args)
        self.section_gestures += 1
        self.pending = 0
        return ''

    def sleep(self, seconds):
        self.clock += seconds

    def patches(self):
        stack = ExitStack()
        stack.enter_context(patch.object(TOUR.probe, 'capture', self.capture))
        stack.enter_context(patch.object(TOUR.probe, 'image_lines', self.lines))
        stack.enter_context(patch.object(TOUR.probe, 'native_text', self.native_text))
        stack.enter_context(patch.object(TOUR, '_screencap',
                                        side_effect=lambda: self.frames[self.state]['png']))
        stack.enter_context(patch.object(TOUR, '_select_stage_kart',
                                        side_effect=lambda _out, kart: {'kart': kart}))
        stack.enter_context(patch.object(TOUR, '_select_stage_driver', return_value={'driver': 'fox'}))
        stack.enter_context(patch.object(TOUR.base, 'adb', self.adb))
        stack.enter_context(patch.object(TOUR.time, 'sleep', self.sleep))
        stack.enter_context(patch.object(TOUR.time, 'monotonic', side_effect=lambda: self.clock))
        return stack


class RecordedKartMenuReturnTests(unittest.TestCase):
    def test_delayed_observed_return_is_confirmed_before_the_next_section(self):
        for case in ('update', 'api35'):
            with self.subTest(case=case), tempfile.TemporaryDirectory() as folder:
                out = Path(folder)
                fixture = RecordedFrames(out, case)
                with fixture.patches():
                    try:
                        report = TOUR._inspect_spatial_kart_menu(out)
                    except Exception:
                        print(json.dumps({'case': case, 'gestures': fixture.gestures,
                                          'observations': fixture.observations}))
                        raise
                self.assertEqual(report['status'], 'PASS')
                self.assertEqual([item['section'] for item in report['sections']], ['garage', 'driver'])
                self.assertEqual(len(fixture.gestures), 2)
                for command in fixture.gestures:
                    self.assertEqual(command[:3], ('shell', 'input', 'swipe'))
                    self.assertEqual(command[3:5], command[5:7])
                    self.assertEqual(command[-1], '120')
                for item in report['sections']:
                    evidence = json.loads((out / item['return_evidence']).read_text())
                    self.assertEqual(evidence['status'], 'PASS')
                    self.assertEqual(len(evidence['touches']), 1)
                    self.assertEqual([frame['state'] for frame in evidence['frames']][-2:],
                                     ['landing', 'landing'])
                    self.assertTrue(evidence['frames'][-1]['target']['stable_observed_target'])

    def test_original_fixture_bytes_and_states_stay_separate(self):
        for case in ('update', 'api35'):
            with self.subTest(case=case), tempfile.TemporaryDirectory() as folder:
                fixture = RecordedFrames(Path(folder), case)
                for state, original in fixture.frames.items():
                    frame = original['readiness']['frames'][-1]
                    self.assertEqual(hashlib.sha256(original['png']).hexdigest(), frame['source_sha256'])
                    self.assertEqual(frame['pixels'], [2400, 1080])
                    if state == 'garage':
                        self.assertEqual(original['readiness']['status'], 'FAIL')
                        with self.assertRaisesRegex(RuntimeError, 'Actual landing Fahrer/Garage'):
                            TOUR.garage_evidence.stage_cup_target_observation(frame, original['ocr'])
                    else:
                        self.assertEqual(TOUR.garage_evidence.stage_cup_target_observation(
                            frame, original['ocr'])['caption'], 'Grand Prix')

    def return_fixture(self, folder, *, succeeds_on=1):
        fixture = RecordedFrames(Path(folder), 'update', succeeds_on=succeeds_on)
        fixture.state = 'garage'
        return fixture

    def test_last_permitted_gesture_still_gets_actual_landing_observations(self):
        with tempfile.TemporaryDirectory() as folder:
            fixture = self.return_fixture(folder, succeeds_on=3)
            with fixture.patches():
                result = TOUR._return_stage_kart_menu(Path(folder), 'return', timeout=40)
            evidence = json.loads((Path(folder) / result['readiness']).read_text())
            self.assertEqual(len(fixture.gestures), 3)
            self.assertEqual(evidence['status'], 'PASS')
            self.assertEqual(evidence['frames'][-1]['state'], 'landing')

    def test_unchanged_garage_stops_at_three_observed_gestures_without_pass(self):
        with tempfile.TemporaryDirectory() as folder:
            fixture = self.return_fixture(folder, succeeds_on=None)
            with fixture.patches(), self.assertRaisesRegex(RuntimeError, 'did not return'):
                TOUR._return_stage_kart_menu(Path(folder), 'return', timeout=40)
            evidence = json.loads((Path(folder) / 'return-return-readiness.json').read_text())
            self.assertEqual(evidence['status'], 'FAIL')
            self.assertEqual(len(fixture.gestures), 3)
            for index in [item['frame_index'] for item in evidence['touches']]:
                self.assertEqual(evidence['frames'][index]['state'], 'section')
                self.assertTrue(evidence['frames'][index]['target']['stable_observed_target'])
                self.assertEqual(evidence['frames'][index - 1]['state'], 'section')
            self.assertGreater(len(evidence['frames']) - 1, evidence['touches'][-1]['frame_index'])

    def test_missing_or_ambiguous_footer_never_authorizes_a_touch(self):
        for negative in ('missing', 'ambiguous', 'outside'):
            with self.subTest(negative=negative), tempfile.TemporaryDirectory() as folder:
                fixture = self.return_fixture(folder)
                rows = fixture.frames['garage']['ocr']
                if negative == 'missing':
                    rows[:] = [r for r in rows if TOUR.probe.normalized(r['text']) not in ('kartmenu', 'menu')]
                else:
                    rows.append({'text': 'Kart-Menü', 'bounds':
                                 ([900, 836, 1189, 870] if negative == 'ambiguous' else [2390, 836, 2500, 870])})
                with fixture.patches(), self.assertRaises((RuntimeError, TimeoutError)):
                    TOUR._return_stage_kart_menu(Path(folder), 'return', timeout=4)
                self.assertFalse(fixture.gestures)

    def test_changed_source_or_partial_frame_never_authorizes_a_touch(self):
        for negative in ('changed', 'partial'):
            with self.subTest(negative=negative), tempfile.TemporaryDirectory() as folder:
                fixture = self.return_fixture(folder)
                with fixture.patches(), ExitStack() as stack:
                    if negative == 'changed':
                        stack.enter_context(patch.object(TOUR.probe, 'digest', return_value='changed'))
                    else:
                        original = TOUR.probe.inspect_surface
                        stack.enter_context(patch.object(TOUR.probe, 'inspect_surface', side_effect=
                            lambda *a, **k: dict(original(*a, **k), acceptable_for_target_sampling=False,
                                               reasons=['derived partial surface negative'])))
                    with self.assertRaises((RuntimeError, TimeoutError)):
                        TOUR._return_stage_kart_menu(Path(folder), 'return', timeout=4)
                self.assertFalse(fixture.gestures)

    def test_ambiguous_actual_landing_keeps_the_existing_cup_guard(self):
        with tempfile.TemporaryDirectory() as folder:
            fixture = self.return_fixture(folder)
            fixture.state = 'landing'
            fixture.frames['landing']['ocr'].append(
                {'text': 'Grand Prix', 'bounds': [800, 397, 1015, 426]})
            with fixture.patches(), self.assertRaisesRegex(RuntimeError, 'Ambiguous cup-caption'):
                TOUR._return_stage_kart_menu(Path(folder), 'return', timeout=4)
            self.assertFalse(fixture.gestures)

    def test_input_error_keeps_requested_coordinates_without_claiming_a_sent_touch(self):
        with tempfile.TemporaryDirectory() as folder:
            fixture = self.return_fixture(folder)
            with fixture.patches(), patch.object(TOUR.base, 'adb',
                    side_effect=RuntimeError('derived input transport failure')), \
                    self.assertRaisesRegex(RuntimeError, 'derived input transport failure'):
                TOUR._return_stage_kart_menu(Path(folder), 'return', timeout=4)
            report = json.loads((Path(folder) / 'return-return-readiness.json').read_text())
            self.assertEqual(report['status'], 'FAIL')
            self.assertEqual(len(report['touches']), 1)
            attempt = report['touches'][0]
            self.assertEqual(attempt['status'], 'REQUESTED')
            frame = report['frames'][attempt['frame_index']]
            self.assertEqual(attempt['source_sha256'], frame['source_sha256'])
            x0, y0, x1, y1 = frame['target']['bounds']
            self.assertEqual(attempt['point'], [round((x0 + x1) / 2), round((y0 + y1) / 2)])


if __name__ == '__main__':
    unittest.main()
