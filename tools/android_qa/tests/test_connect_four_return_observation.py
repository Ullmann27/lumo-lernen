"""Controlled replay of the final-return boundary, not Android acceptance.

The original diagnostic ended with a current mailbox still present. No later
empty answer was observed there; later empty find answers and repeated answers
in these tests are explicitly synthetic. ADB execution, clock, the two native
pre-touch observations/PNG and Flutter UI/navigation boundaries are controlled.
The actual native_touch/stable_target, original, return_to_flutter,
read_preferences and persisted_round paths execute. Original paused state and
preferences predate the Back touch; their reuse afterward is synthetic.
"""
from __future__ import annotations

from contextlib import ExitStack
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
SOURCE = Path(os.environ.get('LUMO_C4_PROBE_SOURCE',
    str(ROOT / '.github/probes/lumo_connect_four_android_probe.py')))
SPEC = importlib.util.spec_from_file_location('c4_return_subject', SOURCE)
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)
C4 = PROBE.contract
FIXTURE = Path(__file__).with_name('fixtures') / 'c4-final-return-7c5'


def original(name):
    return {
        'metadata': json.loads((FIXTURE / (name + '.json')).read_text()),
        'stdout': (FIXTURE / (name + '.stdout')).read_bytes(),
        'stderr': (FIXTURE / (name + '.stderr')).read_bytes(),
    }


TOUCH = original('0404-return-final-touch')
LIVE = original('0405-return-final-native-exit')
NATIVE = original('0406-return-final-return-activity')
DEAD = original('0407-return-final-native-exit')
MAIN = original('0408-return-final-return-activity')
REMAINDER = original('0409-return-final-closed-mailbox')
STATE = json.loads(original('0392-return-final-second-000-state')['stdout'])
PREFERENCES = original('0400-return-final-second-000-preferences')
PREFS_PATH = PREFERENCES['metadata']['command'][-1]
FIND_COMMAND = REMAINDER['metadata']['command']


def derived(response, *, stdout=None, stderr=None, returncode=None):
    """Explicit synthetic later/negative response, leaving fixture bytes intact."""
    result = copy.deepcopy(response)
    for key, value in (('stdout', stdout), ('stderr', stderr)):
        if value is not None:
            result[key] = value
    if returncode is not None:
        result['metadata']['returncode'] = returncode
    return result


def sample(*, pid=DEAD, activity=MAIN, mailbox=REMAINDER):
    return {'pid': pid, 'activity': activity, 'mailbox': mailbox}


class Clock:
    def __init__(self, start=0.0):
        self.value = start

    def monotonic(self):
        return self.value

    def sleep(self, seconds):
        self.value += seconds


class ReturnBoundary:
    def __init__(self, out, clock, samples, frame):
        self.out, self.clock, self.samples = out, clock, samples
        self.commands, self.inputs = [], []
        self.round = -1
        self.find_at = None
        self.stage_at = {}
        self.return_start = None
        self.after_preferences = PREFERENCES
        self.value = PROBE.Probe.__new__(PROBE.Probe)
        value = self.value
        value.out, value.deadline, value.counter = out, 900.0, 0
        value.token = STATE['token']
        value.mailbox = FIND_COMMAND[3] + '/' + value.token
        value.observations, value.transitions, value.returns = [], [], []
        png = out / 'synthetic-pre-touch.png'
        png.write_bytes(frame)
        point = list(map(int, TOUCH['metadata']['command'][4:6]))
        x, y = point
        target = {'id': 'back', 'text': 'Zurück', 'point': point,
                  'bounds': [x-24, y-24, x+24, y+24], 'size_dp': [48.0, 48.0]}
        observations = [
            {'id': 'controlled-pre-touch-' + str(index),
             'state': copy.deepcopy(STATE), 'pid': 7113, 'density': 1.0,
             'pixels': [1080, 2400], 'target': copy.deepcopy(target),
             'lifecycle': {'active': True, 'stamp': index+1},
             'frame': png.name, 'frame_sha256': C4.sha256(png)}
            for index in range(2)
        ]
        self.before = observations[-1]
        value.wait_observation = mock.Mock(side_effect=observations)
        value.native_touch = mock.Mock(wraps=value.native_touch)
        value.ui = SimpleNamespace(
            capture_flutter_ready=mock.Mock(return_value={'file': 'synthetic-flutter.png'}),
            read_live_nodes=mock.Mock(return_value=[
                {'text': 'Spiel pausiert'}, {'text': 'Fortsetzen'}]))
        value.flutter_touch = mock.Mock(return_value='synthetic-leave-touch.json')
        value.wait_for_flutter_control = mock.Mock(return_value='synthetic-games-ready.json')

    def command(self, arguments, *, stdout, stderr, timeout, check):
        if arguments[:4] == ['adb', 'shell', 'input', 'swipe']:
            if arguments != TOUCH['metadata']['command']:
                raise AssertionError('Unexpected synthetic input: ' + repr(arguments))
            response, kind = TOUCH, 'touch'
            self.inputs.append(list(arguments))
        elif arguments[:3] == ['adb', 'shell', 'pidof']:
            self.round += 1
            response, kind = self.samples[min(self.round, len(self.samples)-1)]['pid'], 'pid'
        elif arguments[:4] == ['adb', 'shell', 'dumpsys', 'activity']:
            response, kind = self.samples[min(self.round, len(self.samples)-1)]['activity'], 'activity'
        elif arguments[:3] == ['adb', 'shell', 'find']:
            if arguments != FIND_COMMAND:
                raise AssertionError('The original mailbox search changed: ' + repr(arguments))
            response, kind = self.samples[min(self.round, len(self.samples)-1)]['mailbox'], 'find'
        elif arguments == ['adb', 'exec-out', 'cat', PREFS_PATH]:
            response, kind = self.after_preferences, 'preferences'
        else:
            raise AssertionError('Unexpected device command: ' + repr(arguments))
        self.clock.value += response['metadata']['elapsed_seconds']
        if kind == 'touch':
            self.return_start = self.clock.value
        if kind in self.stage_at:
            self.clock.value = self.stage_at[kind]
        if kind == 'find' and self.find_at is not None:
            self.clock.value = self.find_at(self)
        self.commands.append({'arguments': list(arguments), 'kind': kind,
                              'stdout': response['stdout'], 'stderr': response['stderr']})
        return subprocess.CompletedProcess(arguments, response['metadata']['returncode'],
                                           response['stdout'], response['stderr'])


class ReturnObservationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        output = io.BytesIO()
        Image.new('RGB', (1080, 2400), '#647880').save(output, format='PNG')
        cls.synthetic_frame = output.getvalue()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.count = 0

    def boundary(self, samples, *, start=0.0):
        self.count += 1
        out = self.root / str(self.count)
        out.mkdir()
        clock = Clock(start)
        result = ReturnBoundary(out, clock, samples, self.synthetic_frame)
        self.stack.enter_context(mock.patch.object(PROBE.time, 'monotonic', clock.monotonic))
        self.stack.enter_context(mock.patch.object(PROBE.time, 'sleep', clock.sleep))
        self.stack.enter_context(mock.patch.object(PROBE.subprocess, 'run', result.command))
        return result

    def assert_one_back(self, boundary):
        boundary.value.native_touch.assert_called_once_with('return-final', 'back')
        self.assertEqual(boundary.inputs, [TOUCH['metadata']['command']])
        receipt = json.loads((boundary.out / 'return-final-touch.json').read_text())
        self.assertEqual((boundary.out / receipt['command_original']).read_bytes(), b'')

    def assert_no_acceptance(self, boundary):
        self.assert_one_back(boundary)
        self.assertEqual(boundary.value.returns, [])
        boundary.value.ui.capture_flutter_ready.assert_not_called()
        boundary.value.flutter_touch.assert_not_called()
        boundary.value.wait_for_flutter_control.assert_not_called()
        self.assertFalse(any(item['kind'] == 'preferences' for item in boundary.commands))
        self.assertFalse((boundary.out / 'return-final-return.json').exists())

    def test_fixture_bytes_metadata_and_actual_token_are_bound_to_originals(self):
        manifest = json.loads((FIXTURE / 'source.json').read_text())
        for item in manifest['files']:
            data = (FIXTURE / item['path']).read_bytes()
            self.assertEqual(len(data), item['bytes'])
            self.assertEqual(hashlib.sha256(data).hexdigest(), item['sha256'])
        for path in FIXTURE.glob('*.json'):
            if path.name == 'source.json':
                continue
            metadata = json.loads(path.read_text())
            for stream in ('stdout', 'stderr'):
                data = path.with_suffix('.' + stream).read_bytes()
                self.assertEqual(len(data), metadata[stream + '_bytes'])
                self.assertEqual(hashlib.sha256(data).hexdigest(), metadata[stream + '_sha256'])
        self.assertEqual(REMAINDER['stdout'],
            (FIND_COMMAND[3] + '/' + STATE['token'] + '/state.json\n').encode())
        self.assertTrue(STATE['paused'])
        C4.validate_state(STATE)
        C4.persisted_round(C4.preferences(PREFERENCES['stdout'].decode()), STATE)

    def test_original_current_mailbox_remainder_requires_a_fresh_later_empty_observation(self):
        boundary = self.boundary([
            sample(pid=LIVE, activity=NATIVE), sample(),
            sample(mailbox=derived(REMAINDER, stdout=b''))])
        result = boundary.value.return_to_flutter('return-final')
        self.assertIs(result, boundary.before)
        self.assert_one_back(boundary)
        self.assertEqual([item['kind'] for item in boundary.commands],
            ['touch', 'pid', 'activity', 'pid', 'activity', 'find',
             'pid', 'activity', 'find', 'preferences'])
        finds = sorted((boundary.out / 'commands').glob('*-closed-mailbox.stdout'))
        self.assertEqual([p.read_bytes() for p in finds], [REMAINDER['stdout'], b''])
        self.assertEqual(len(list((boundary.out / 'commands').glob('*.json'))), len(boundary.commands))
        for metadata_path, command in zip(sorted((boundary.out / 'commands').glob('*.json')), boundary.commands):
            metadata = json.loads(metadata_path.read_text())
            self.assertEqual(metadata['command'], command['arguments'])
            for stream in ('stdout', 'stderr'):
                data = metadata_path.with_suffix('.' + stream).read_bytes()
                self.assertEqual(data, command[stream])
                self.assertEqual(metadata[stream + '_sha256'], hashlib.sha256(data).hexdigest())
        item = boundary.value.returns[0]
        self.assertEqual(boundary.out / item['closed_mailbox'], finds[-1])
        self.assertEqual(Path(item['native_exit']).name, '0007-return-final-native-exit.stdout')
        self.assertEqual(Path(item['activity']).name, '0008-return-final-return-activity.stdout')
        boundary.value.flutter_touch.assert_called_once_with('Zur Spieleauswahl', 'return-final-to-games', scrolls=3)
        boundary.value.wait_for_flutter_control.assert_called_once_with(C4.PORTAL, 'return-final-games')
        self.assertLess(boundary.clock.value - boundary.return_start, 45)

    def test_permanent_current_or_foreign_mailbox_remains_failure_without_input_repetition(self):
        foreign = REMAINDER['stdout'].replace(STATE['token'].encode(), b'f' * 32)
        for raw in (REMAINDER['stdout'], foreign):
            with self.subTest(raw=raw):
                boundary = self.boundary([sample(mailbox=derived(REMAINDER, stdout=raw))])
                with self.assertRaises((RuntimeError, TimeoutError)):
                    boundary.value.return_to_flutter('return-final')
                self.assert_no_acceptance(boundary)
                files = sorted((boundary.out / 'commands').glob('*-closed-mailbox.stdout'))
                self.assertGreater(len(files), 1)
                self.assertTrue(all(p.read_bytes() == raw for p in files))
                self.assertGreaterEqual(boundary.clock.value - boundary.return_start, 45.0)

    def test_empty_mailbox_never_substitutes_for_native_exit_or_correct_main_activity(self):
        foreign_main = derived(MAIN, stdout=b'topResumedActivity: foreign.app/MainActivity\n')
        missing = derived(MAIN, stdout=b'No resumed activity\n')
        mixed = derived(MAIN, stdout=MAIN['stdout'] + b'\nmResumedActivity: ' +
                        C4.PACKAGE.encode() + b'/ConnectFourGameActivity\n')
        for pid, activity in ((LIVE, MAIN), (DEAD, NATIVE), (DEAD, foreign_main),
                              (DEAD, missing), (DEAD, mixed)):
            with self.subTest(pid=pid['stdout'], activity=activity['stdout'][-100:]):
                boundary = self.boundary([sample(pid=pid, activity=activity,
                    mailbox=derived(REMAINDER, stdout=b''))])
                with self.assertRaises(RuntimeError):
                    boundary.value.return_to_flutter('return-final')
                self.assert_no_acceptance(boundary)
                self.assertFalse(any(item['kind'] == 'find' for item in boundary.commands))

    def test_each_retry_reobserves_pid_and_activity_instead_of_reusing_prior_success(self):
        for later in (sample(pid=LIVE, mailbox=derived(REMAINDER, stdout=b'')),
                      sample(activity=NATIVE, mailbox=derived(REMAINDER, stdout=b''))):
            with self.subTest(later=later['pid']['stdout']):
                boundary = self.boundary([sample(), later])
                with self.assertRaises(RuntimeError):
                    boundary.value.return_to_flutter('return-final')
                self.assert_no_acceptance(boundary)
                self.assertEqual([item['stdout'] for item in boundary.commands if item['kind'] == 'find'],
                                 [REMAINDER['stdout']])

    def test_find_finished_at_or_after_local_deadline_cannot_accept_empty_output(self):
        for elapsed, accepted in ((44.999, True), (45.0, False), (45.001, False)):
            with self.subTest(elapsed=elapsed):
                boundary = self.boundary([sample(mailbox=derived(REMAINDER, stdout=b''))])
                boundary.find_at = lambda value, seconds=elapsed: value.return_start + seconds
                if accepted:
                    self.assertIs(boundary.value.return_to_flutter('return-final'), boundary.before)
                    self.assert_one_back(boundary)
                else:
                    with self.assertRaisesRegex(TimeoutError, '45-second observation deadline'):
                        boundary.value.return_to_flutter('return-final')
                    self.assert_no_acceptance(boundary)
                files = list((boundary.out / 'commands').glob('*-closed-mailbox.stdout'))
                self.assertEqual(len(files), 1)
                self.assertEqual(files[0].read_bytes(), b'')

    def test_global_deadline_during_find_saves_raw_answer_but_cannot_accept_it(self):
        for finished in (900.0, 900.001):
            with self.subTest(finished=finished):
                boundary = self.boundary([sample(mailbox=derived(REMAINDER, stdout=b''))], start=890)
                boundary.find_at = lambda _, seconds=finished: seconds
                with self.assertRaisesRegex(TimeoutError, '900 seconds'):
                    boundary.value.return_to_flutter('return-final')
                self.assert_no_acceptance(boundary)
                files = list((boundary.out / 'commands').glob('*-closed-mailbox.json'))
                self.assertEqual(len(files), 1)
                self.assertEqual(files[0].with_suffix('.stdout').read_bytes(), b'')
                self.assertEqual(files[0].with_suffix('.stderr').read_bytes(), b'')

    def test_expired_global_or_local_activity_read_never_starts_an_additional_find(self):
        for finished in (900.0, 45.0):
            with self.subTest(finished=finished):
                boundary = self.boundary([sample(mailbox=derived(REMAINDER, stdout=b''))])
                # The return starts after the controlled real native_touch path.
                def stage_after_touch(arguments, **kwargs):
                    response = boundary.command(arguments, **kwargs)
                    if arguments[:4] == ['adb', 'shell', 'dumpsys', 'activity']:
                        boundary.clock.value = (900.0 if finished == 900.0
                                                else boundary.return_start + finished)
                    return response
                with mock.patch.object(PROBE.subprocess, 'run', stage_after_touch):
                    with self.assertRaises(TimeoutError):
                        boundary.value.return_to_flutter('return-final')
                self.assert_no_acceptance(boundary)
                self.assertFalse(any(item['kind'] == 'find' for item in boundary.commands))

    def test_failed_find_is_not_an_empty_mailbox_proof(self):
        for response in (derived(REMAINDER, stdout=b'', returncode=1),
                         derived(REMAINDER, stdout=b'', stderr=b'Permission denied\n')):
            with self.subTest(returncode=response['metadata']['returncode']):
                boundary = self.boundary([sample(mailbox=response)])
                with self.assertRaisesRegex(ValueError, 'Original read failed'):
                    boundary.value.return_to_flutter('return-final')
                self.assert_no_acceptance(boundary)
                self.assertEqual(sum(item['kind'] == 'find' for item in boundary.commands), 1)


if __name__ == '__main__':
    unittest.main()
