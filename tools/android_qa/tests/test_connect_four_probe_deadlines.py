"""Run the actual C4 observation methods with explicit synthetic clock/device boundaries.

No ADB process, Android device, production save or real game frame is used.
"""
from __future__ import annotations

from contextlib import ExitStack
import importlib.util
import os
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT/'tools/android_qa'))
SOURCE = Path(os.environ.get('LUMO_C4_PROBE_SOURCE',
                             str(ROOT/'.github/probes/lumo_connect_four_android_probe.py')))
SPEC = importlib.util.spec_from_file_location('c4_deadline_subject', SOURCE)
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)


class Clock:
    def __init__(self):
        self.value = 0.0

    def monotonic(self):
        return self.value

    def sleep(self, seconds):
        self.value += seconds


class DeadlineTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.stack = ExitStack(); self.addCleanup(self.stack.close)
        self.clock = Clock()
        self.stack.enter_context(mock.patch.object(PROBE.time, 'monotonic', self.clock.monotonic))
        self.stack.enter_context(mock.patch.object(PROBE.time, 'sleep', self.clock.sleep))

    def probe(self):
        value = PROBE.Probe.__new__(PROBE.Probe)
        value.out = self.out
        value.deadline = 900.0
        value.mailbox = '/synthetic-private-mailbox/'+'a'*32
        value.token = 'a'*32
        value.observations, value.returns = [], []
        return value

    def test_wait_rejects_successful_observation_completed_after_local_90_seconds(self):
        value = self.probe()
        def observation(*_):
            self.clock.value = 90.01
            return {'synthetic': True}
        value.observation = mock.Mock(side_effect=observation)
        with self.assertRaises(TimeoutError): value.wait_observation('late-read', lambda _: True)
        self.assertTrue((self.out/'late-read-wait-failure.json').exists())
        value.observation.assert_called_once()

    def test_wait_rejects_condition_that_finishes_after_the_same_local_deadline(self):
        value = self.probe(); value.observation = mock.Mock(return_value={'synthetic': True})
        def condition(_):
            self.clock.value = 90.01
            return True
        with self.assertRaises(TimeoutError): value.wait_observation('late-condition', condition)
        self.assertTrue((self.out/'late-condition-wait-failure.json').exists())

    def test_wait_keeps_exact_boundary_closed_and_timely_result_unchanged(self):
        for elapsed, accepted in ((89.999, True), (90.0, False)):
            with self.subTest(elapsed=elapsed):
                self.clock.value = 0; value = self.probe(); observed = {'synthetic': elapsed}
                def observation(*_):
                    self.clock.value = elapsed
                    return observed
                value.observation = observation
                if accepted:
                    self.assertIs(value.wait_observation('timely', lambda _: True), observed)
                else:
                    with self.assertRaises(TimeoutError): value.wait_observation('boundary', lambda _: True)

    def test_wait_still_rejects_incomplete_state_and_expired_global_budget(self):
        for elapsed, condition in ((90.01, False), (900.01, True)):
            with self.subTest(elapsed=elapsed):
                self.clock.value = 0; value = self.probe()
                def observation(*_):
                    self.clock.value = elapsed
                    return {'synthetic': True}
                value.observation = observation
                with self.assertRaises(TimeoutError):
                    value.wait_observation('incomplete-'+str(elapsed), lambda _: condition)

    def observation_probe(self, phase=None):
        from PIL import Image
        value = self.probe()
        png = self.out/'current.png'
        Image.new('RGB', (4, 4), (120, 150, 180)).save(png)
        state = {'token': value.token}; layout = {'synthetic_layout': True}
        def read_json(tag, _):
            data = ({'active': True, 'stamp': 1700000000000} if tag.endswith('-lifecycle') else
                    layout if '-layout' in tag else state)
            return data, tag+'.json'
        value.read_json = read_json
        def original(tag, *_args, **_kwargs):
            text = ('1700000000001\n' if tag.endswith('-clock') else
                    '123\n' if tag.endswith('-native-pid') else
                    '456\n' if tag.endswith('-host-pid') else
                    'mResumedActivity: ConnectFourGameActivity\n' if tag.endswith('-activity') else
                    'ConnectFourAuthorityService\n')
            return text, tag+'.stdout'
        value.original = original
        value.read_preferences = lambda _: ({}, 'synthetic-preferences.xml')
        def at_phase(name, result):
            if phase == name: self.clock.value = 900.01
            return result
        value.density = lambda: at_phase('last-read', (1.0, 'synthetic-density.stdout'))
        value.ui = SimpleNamespace(capture=lambda *_a, **_k: {'file': png.name},
                                   inspect_surface=lambda *_a, **_k: {'acceptable_for_target_sampling': True})
        self.stack.enter_context(mock.patch.object(PROBE.contract, 'persisted_round', return_value={}))
        self.stack.enter_context(mock.patch.object(PROBE.contract, 'validate_layout', return_value=None))
        self.stack.enter_context(mock.patch.object(PROBE.contract, 'board_pixels',
            side_effect=lambda *_: at_phase('pixels', {'synthetic_pixel_verdict': True})))
        self.stack.enter_context(mock.patch.object(PROBE.contract, 'touch_target',
            side_effect=lambda *_: at_phase('target', {'point': [2, 2]})))
        return value

    def test_observation_rejects_late_last_read_pixels_or_target_without_accepting_result(self):
        base = self.out
        for phase in ('last-read', 'pixels', 'target'):
            with self.subTest(phase=phase):
                self.out = base/phase; self.out.mkdir()
                self.clock.value = 0
                # Each phase deliberately exercises the actual unchanged method,
                # while device/pixel validation boundaries remain explicit stubs.
                value = self.observation_probe(phase)
                with self.assertRaises(TimeoutError): value.observation('current', control='pause')
                self.assertEqual(value.observations, [])
                self.assertFalse((self.out/'observations/current.json').exists())

    def test_observation_rechecks_after_evidence_write_before_successful_return(self):
        value = self.observation_probe()
        original_write = PROBE.write
        def delayed_write(*args):
            original_write(*args)
            self.clock.value = 900.01
        with mock.patch.object(PROBE, 'write', side_effect=delayed_write), self.assertRaises(TimeoutError):
            value.observation('current', control='pause')
        self.assertEqual(value.observations, [])
        self.assertTrue((self.out/'observations/current.json').is_file())

    def test_timely_observation_preserves_state_target_and_original_record(self):
        value = self.observation_probe()
        result = value.observation('current', control='pause')
        self.assertEqual(result['target'], {'point': [2, 2]})
        self.assertEqual(result['state']['token'], value.token)
        self.assertEqual(value.observations, [result])
        self.assertTrue((self.out/'observations/current.json').is_file())

    def test_incomplete_actual_surface_still_blocks_observation(self):
        value = self.observation_probe()
        value.ui.inspect_surface = lambda *_a, **_k: {'acceptable_for_target_sampling': False}
        with self.assertRaises(ValueError): value.observation('current', control='pause')
        self.assertEqual(value.observations, [])

    def return_probe(self, slow, elapsed):
        value = self.probe()
        before = {'id': 'before', 'state': {'paused': True}}
        value.native_touch = mock.Mock(return_value=before)
        def original(tag, *_a, **_k):
            if tag.endswith(slow): self.clock.value = elapsed
            text = ('mResumedActivity: '+PROBE.contract.PACKAGE+'/MainActivity\n'
                    if tag.endswith('-return-activity') else '')
            return text, tag+'.stdout'
        value.original = mock.Mock(side_effect=original)
        value.read_preferences = mock.Mock(return_value=({}, 'synthetic-preferences.xml'))
        value.ui = SimpleNamespace(capture_flutter_ready=lambda *_a, **_k: {'file': 'synthetic.png'},
            read_live_nodes=lambda *_a: [{'text': 'Spiel pausiert'}, {'text': 'Fortsetzen'}])
        value.flutter_touch = mock.Mock(return_value='synthetic-return-touch.json')
        self.stack.enter_context(mock.patch.object(PROBE.contract, 'persisted_round', return_value={'synthetic': True}))
        return value, before

    def test_return_rejects_slow_pid_or_activity_reads_before_accepting_local_45_second_result(self):
        for stage in ('-native-exit', '-return-activity'):
            with self.subTest(stage=stage):
                self.clock.value = 0; value, _ = self.return_probe(stage, 45.01)
                with self.assertRaises(TimeoutError): value.return_to_flutter('late-return'+stage)
                value.read_preferences.assert_not_called()
                value.flutter_touch.assert_not_called()
                self.assertEqual(value.returns, [])

    def test_return_exact_deadline_is_closed_and_timely_return_keeps_full_checks(self):
        self.clock.value = 0; value, _ = self.return_probe('-return-activity', 45.0)
        with self.assertRaises(TimeoutError): value.return_to_flutter('boundary')
        self.clock.value = 0; value, before = self.return_probe('-return-activity', 44.999)
        self.assertIs(value.return_to_flutter('timely-return'), before)
        value.read_preferences.assert_called_once()
        value.flutter_touch.assert_called_once_with('Zur Spieleauswahl', 'timely-return-to-games', scrolls=3)
        self.assertEqual(len(value.returns), 1)

    def test_return_still_requires_observed_pause(self):
        value, before = self.return_probe('-return-activity', 1.0)
        before['state']['paused'] = False
        with self.assertRaises(ValueError): value.return_to_flutter('not-paused')
        value.original.assert_not_called()


if __name__ == '__main__':
    unittest.main()
