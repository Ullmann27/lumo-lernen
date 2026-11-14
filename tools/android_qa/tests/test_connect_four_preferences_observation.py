"""Controlled replay of the original missing-preferences read, not Android acceptance.

The ADB process, clock, screenshot producer and surface-readiness boundary are
synthetic. The real
original/read_preferences/observation/native_touch/transition/wait methods and
strict state, XML, layout, pixel, target and acknowledgment checks execute.
The original valid XML predates the touch. Any later successful response in
these tests is explicitly derived test data, never a claimed device recovery.
"""
from __future__ import annotations

from contextlib import contextmanager
import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_connect_four_android_evidence as fixtures

SOURCE = Path(os.environ.get('LUMO_C4_PROBE_SOURCE',
    str(ROOT / '.github/probes/lumo_connect_four_android_probe.py')))
SPEC = importlib.util.spec_from_file_location('c4_preferences_subject', SOURCE)
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)
C4 = PROBE.contract
FIXTURE = Path(__file__).with_name('fixtures') / 'c4-preferences-read-51ec'
MISSING_NAME = '0087-child-first-confirmed-000-preferences'
VALID_NAME = '0074-child-first-second-000-preferences'
MISSING = (FIXTURE / (MISSING_NAME + '.stdout')).read_bytes()
VALID = (FIXTURE / (VALID_NAME + '.stdout')).read_bytes()
PREFS_PATH = f'/data/user/0/{C4.PACKAGE}/shared_prefs/FlutterSharedPreferences.xml'


def sample(value, raw=VALID, *, read_seconds=0.0):
    return {'state': copy.deepcopy(value), 'raw': raw, 'read_seconds': read_seconds}


def states():
    """Derive synthetic native states from the actual prior durable record."""
    prefs = C4.preferences(VALID.decode())
    owner = C4.owner_from_preferences(prefs)
    record = json.loads(prefs[C4.ROUND_PREFIX + owner])
    before = fixtures.state(record['columns'], revision=2, ack=0)
    before.update(owner=owner, roundId=record['id'], level=record['level'],
                  twoPlayers=record['twoPlayers'], recordRevision=record['revision'])
    after = fixtures.state([*record['columns'], 3, 4], revision=3, ack=1)
    after.update(owner=owner, roundId=record['id'], level=record['level'],
                 twoPlayers=record['twoPlayers'], recordRevision=record['revision'] + 2)
    return before, after


def derived_xml(value, *, wrong=None):
    """Create a labelled synthetic later response without changing originals."""
    root = ET.fromstring(VALID)
    saved = fixtures.stored(value)
    if wrong == 'round':
        saved['id'] = ('0' if saved['id'] != '0' * 32 else '1') * 32
    elif wrong == 'revision':
        saved['revision'] += 1
    key = C4.ROUND_PREFIX + value['owner']
    node = next(n for n in root if n.get('name') == key)
    node.text = json.dumps(saved)
    if wrong == 'owner':
        prefs = C4.preferences(VALID.decode())
        active = ('flutter.lumo_school_active_student_v1'
                  if (prefs.get('flutter.lumo_school_active_student_v1') or '').strip()
                  else 'flutter.lumo_learning_local_student_id_v1')
        next(n for n in root if n.get('name') == active).text = 'synthetic-foreign-owner'
    return ET.tostring(root, encoding='utf-8', xml_declaration=True)


class Clock:
    def __init__(self):
        self.value = 0.0

    def monotonic(self):
        return self.value

    def sleep(self, seconds):
        self.value += seconds


class ScriptedBoundary:
    """Explicit fake device responses; never launches ADB or writes an app save."""
    def __init__(self, out, clock, samples):
        self.out, self.clock, self.samples = out, clock, samples
        self.before, self.after = states()
        self.current = sample(self.before)
        self.geometry = fixtures.layout(self.before)
        self.synthetic_frames = fixtures.SyntheticEvidence(out)
        self.commands, self.touches, self.attempts = [], [], []
        self.confirmation_start = None
        self.confirming = False
        self.on_preferences = None
        self.direct_raw = None
        self.device_ms = 1_700_000_000_000
        value = PROBE.Probe.__new__(PROBE.Probe)
        value.out, value.deadline, value.counter = out, 900.0, 0
        value.token = self.before['token']
        value.mailbox = f'/synthetic-private-mailbox/{value.token}'
        value.observations, value.transitions, value.returns = [], [], []
        value.ui = SimpleNamespace(capture=self.capture,
            inspect_surface=lambda *_a, **_k: {'acceptable_for_target_sampling': True})
        self.probe = value
        self.actual_observation = value.observation
        value.observation = self.observe

    def observe(self, tag, control=None):
        self.confirming = '-confirmed-' in tag
        if self.confirming:
            if self.confirmation_start is None:
                self.confirmation_start = self.clock.value
            index = int(tag.rsplit('-', 1)[1])
            self.current = self.samples[min(index, len(self.samples) - 1)]
        else:
            self.current = sample(self.before)
        self.attempts.append(tag)
        self.device_ms = 1_700_000_000_000 + round(self.clock.value * 1000)
        self.geometry = fixtures.layout(self.current['state'], sequence=len(self.attempts))
        return self.actual_observation(tag, control)

    def capture(self, _out, tag, *, timeout):
        return self.synthetic_frames.screenshot(tag, self.current['state'], self.geometry)

    def command(self, arguments, *, stdout, stderr, timeout, check):
        self.commands.append(list(arguments))
        self.clock.value += .01
        state = self.current['state']
        command = arguments[1:]
        if command[:2] == ['exec-out', 'cat']:
            path = command[2]
            if path == PREFS_PATH:
                self.clock.value += self.current['read_seconds']
                if self.on_preferences is not None:
                    self.on_preferences(self)
                data = self.direct_raw if self.direct_raw is not None else self.current['raw']
            elif path.endswith('/state.json'):
                data = json.dumps(state).encode()
            elif path.endswith('/connect_four_layout_v1.json'):
                data = json.dumps(self.geometry).encode()
            elif path.endswith('/lifecycle.json'):
                data = json.dumps({'active': True, 'stamp': self.device_ms}).encode()
            elif path.endswith('/request.json'):
                data = json.dumps({'action': 'drop', 'token': self.before['token'],
                    'roundId': self.before['roundId'], 'revision': self.before['revision'],
                    'sequence': 1, 'column': 3}).encode()
            else:
                raise AssertionError('Unexpected synthetic read: ' + path)
        elif command[:3] == ['shell', 'input', 'swipe']:
            self.touches.append(list(arguments))
            data = b''
        elif command == ['shell', 'date', '+%s%3N']:
            data = str(self.device_ms + 50).encode()
        elif command == ['shell', 'pidof', C4.PACKAGE + ':lumo_game']:
            data = b'200\n'
        elif command == ['shell', 'pidof', C4.PACKAGE]:
            data = b'100\n'
        elif command == ['shell', 'dumpsys', 'activity', 'activities']:
            data = ('mResumedActivity: ' + C4.PACKAGE + '/.ConnectFourGameActivity\n').encode()
        elif command == ['shell', 'dumpsys', 'activity', 'services', C4.PACKAGE]:
            data = b'ConnectFourAuthorityService\n'
        elif command == ['shell', 'wm', 'density']:
            data = b'Physical density: 420\nOverride density: 400\n'
        else:
            raise AssertionError('Unexpected synthetic command: ' + repr(arguments))
        return subprocess.CompletedProcess(arguments, 0, data, b'')


class OriginalPreferencesObservationTests(unittest.TestCase):
    @contextmanager
    def device(self, samples):
        with tempfile.TemporaryDirectory() as folder:
            clock = Clock()
            device = ScriptedBoundary(Path(folder), clock, samples)
            with mock.patch.object(PROBE.time, 'monotonic', clock.monotonic), \
                    mock.patch.object(PROBE.time, 'sleep', clock.sleep), \
                    mock.patch.object(PROBE.subprocess, 'run', side_effect=device.command):
                yield device

    def test_original_fixture_bytes_and_metadata_remain_exact(self):
        self.assertEqual(len(MISSING), 129)
        self.assertEqual(hashlib.sha256(MISSING).hexdigest(),
            '18cc4a1f125474c5c4f1f3bf5f414a2e05095b766b5254c2cab20a0db7a4f4ac')
        self.assertEqual(len(VALID), 2485)
        self.assertEqual(hashlib.sha256(VALID).hexdigest(),
            'c1f6883e8047900e28981cd7d6bde7b379bd18edd80693b51ff4fd5d88f8811e')
        for name, raw in ((MISSING_NAME, MISSING), (VALID_NAME, VALID)):
            metadata = json.loads((FIXTURE / (name + '.json')).read_text())
            self.assertEqual(metadata['command'], ['adb', 'exec-out', 'cat', PREFS_PATH])
            self.assertEqual(metadata['returncode'], 0)
            self.assertEqual(metadata['stderr_bytes'], 0)
            self.assertEqual((FIXTURE / (name + '.stderr')).read_bytes(), b'')
            self.assertEqual(metadata['stdout_bytes'], len(raw))
            self.assertEqual(metadata['stdout_sha256'], hashlib.sha256(raw).hexdigest())

    def test_reader_preserves_original_bytes_and_parse_cause_without_fallback(self):
        before, _ = states()
        with self.device([sample(before)]) as d:
            d.direct_raw = MISSING
            with self.assertRaises(ValueError) as caught:
                d.probe.read_preferences('direct')
            self.assertIsInstance(caught.exception.__cause__, ET.ParseError)
            source = 'commands/0001-direct-preferences.stdout'
            self.assertIn(source, str(caught.exception))
            self.assertEqual((d.out / source).read_bytes(), MISSING)
            metadata = json.loads((d.out / 'commands/0001-direct-preferences.json').read_text())
            self.assertEqual(metadata['returncode'], 0)
            self.assertEqual(metadata['stdout_sha256'], hashlib.sha256(MISSING).hexdigest())
            self.assertEqual(d.touches, [])
            self.assertEqual(d.probe.observations, [])
        with self.assertRaises(ET.ParseError):
            C4.preferences(MISSING.decode())

    def test_one_touch_missing_then_old_data_requires_fresh_matching_ack(self):
        before, after = states()
        sequence = [sample(before, MISSING), sample(before, VALID),
                    sample(after, VALID), sample(after, derived_xml(after))]
        with self.device(sequence) as d:
            result = d.probe.transition('child-first', 'drop', 'column_3')
            self.assertTrue(result['id'].endswith('confirmed-003'))
            self.assertEqual(result['state']['ack'], 1)
            self.assertEqual(result['state']['columns'], [3, 4])
            self.assertEqual(len(d.touches), 1)
            self.assertEqual(d.touches[0][1:4], ['shell', 'input', 'swipe'])
            self.assertEqual(d.touches[0][4:6], d.touches[0][6:8])
            self.assertEqual(d.touches[0][-1], '120')
            self.assertEqual(len(d.probe.transitions), 1)
            recorded = [v['id'] for v in d.probe.observations]
            self.assertNotIn('child-first-confirmed-000', recorded)
            self.assertIn('child-first-confirmed-001', recorded)
            self.assertNotIn('child-first-confirmed-002', recorded)
            original = next(d.out.glob('commands/*child-first-confirmed-000-preferences.stdout'))
            self.assertEqual(original.read_bytes(), MISSING)
            self.assertEqual(d.probe.transitions[0]['after'], result['id'])

    def test_permanently_missing_or_broken_xml_fails_with_one_touch(self):
        before, _ = states()
        for raw in (MISSING, b'<map><string', b''):
            with self.subTest(raw=raw), self.device([sample(before, raw, read_seconds=30)]) as d:
                with self.assertRaises(TimeoutError):
                    d.probe.transition('child-first', 'drop', 'column_3')
                self.assertEqual(len(d.touches), 1)
                self.assertEqual(d.probe.transitions, [])
                self.assertEqual(len(d.probe.observations), 2)
                failure = json.loads((d.out / 'child-first-confirmed-wait-failure.json').read_text())
                self.assertTrue(failure)
                self.assertTrue(all('Original SharedPreferences' in f['reason'] for f in failure))
                for original in d.out.glob('commands/*confirmed-*-preferences.stdout'):
                    self.assertEqual(original.read_bytes(), raw)

    def test_valid_xml_with_wrong_owner_round_or_revision_never_confirms(self):
        before, after = states()
        for wrong in ('owner', 'round', 'revision'):
            sequence = [sample(before, MISSING),
                        sample(after, derived_xml(after, wrong=wrong), read_seconds=30)]
            with self.subTest(wrong=wrong), self.device(sequence) as d:
                with self.assertRaises(TimeoutError):
                    d.probe.transition('child-first', 'drop', 'column_3')
                self.assertEqual(len(d.touches), 1)
                self.assertEqual(d.probe.transitions, [])
                self.assertEqual(len(d.probe.observations), 2)
                failure = (d.out / 'child-first-confirmed-wait-failure.json').read_text()
                self.assertIn('different child' if wrong == 'owner' else
                              'Mailbox differs from durable Dart round', failure)

    def test_valid_old_state_and_ack_never_confirm_the_touch(self):
        before, _ = states()
        with self.device([sample(before, VALID, read_seconds=30)]) as d:
            with self.assertRaises(TimeoutError):
                d.probe.transition('child-first', 'drop', 'column_3')
            self.assertEqual(len(d.touches), 1)
            self.assertEqual(d.probe.transitions, [])
            self.assertTrue(all(v['state']['ack'] == 0 for v in d.probe.observations))

    def test_existing_120_second_boundary_after_real_pixel_analysis_stays_closed(self):
        _, after = states()
        for elapsed, accepted in ((119.999, True), (120.0, False)):
            with self.subTest(elapsed=elapsed), self.device([sample(after, derived_xml(after))]) as d:
                original_pixels = C4.board_pixels
                def pixels(*args):
                    result = original_pixels(*args)
                    if d.confirming:
                        d.clock.value = d.confirmation_start + elapsed
                    return result
                with mock.patch.object(PROBE.contract, 'board_pixels', side_effect=pixels):
                    if accepted:
                        self.assertEqual(d.probe.transition('child-first', 'drop', 'column_3')['state']['ack'], 1)
                    else:
                        with self.assertRaises(TimeoutError):
                            d.probe.transition('child-first', 'drop', 'column_3')
                        self.assertEqual(d.probe.transitions, [])
                self.assertEqual(len(d.touches), 1)

    def test_global_budget_expiring_during_original_read_blocks_parse(self):
        _, after = states()
        with self.device([sample(after, derived_xml(after))]) as d:
            def expire(device):
                if device.confirming:
                    device.clock.value = 900.0
            d.on_preferences = expire
            with mock.patch.object(PROBE.contract, 'preferences', wraps=C4.preferences) as parser:
                with self.assertRaises(TimeoutError):
                    d.probe.transition('child-first', 'drop', 'column_3')
                self.assertEqual(parser.call_count, 2)
            self.assertEqual(len(d.touches), 1)
            self.assertEqual(d.probe.transitions, [])
            self.assertEqual(len(d.probe.observations), 2)
            self.assertTrue(list(d.out.glob('commands/*confirmed-*-preferences.stdout')))

    def test_global_budget_after_actual_pixel_analysis_cannot_accept_result(self):
        _, after = states()
        with self.device([sample(after, derived_xml(after))]) as d:
            original_pixels = C4.board_pixels
            def pixels(*args):
                result = original_pixels(*args)
                if d.confirming:
                    d.clock.value = 900.0
                return result
            with mock.patch.object(PROBE.contract, 'board_pixels', side_effect=pixels):
                with self.assertRaises(TimeoutError):
                    d.probe.transition('child-first', 'drop', 'column_3')
            self.assertEqual(len(d.touches), 1)
            self.assertEqual(d.probe.transitions, [])
            self.assertEqual(len(d.probe.observations), 2)


if __name__ == '__main__':
    unittest.main()
