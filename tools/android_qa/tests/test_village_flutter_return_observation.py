"""Controlled original-frame/transport regressions; never Android acceptance.

The good Flutter frame predates the failed Village return. Reordering it after
the actual Village frame is only a contract test, not evidence of later recovery.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
SOURCE_ROOT = Path(os.environ.get('LUMO_VILLAGE_SOURCE_ROOT', ROOT))
sys.path.insert(0, str(SOURCE_ROOT/'.github/probes'))
sys.path.insert(0, str(ROOT/'tools/android_qa'))
import lumo_village_android_probe as observed
import flutter_surface_readiness as readiness
import village_android_evidence as village

FIXTURES = Path(__file__).with_name('fixtures')/'village-return-5ad'
VILLAGE_FRAME = 'village/returned-flutter-frame.png'
FLUTTER_FRAME = 'main/23_zurueck_in_flutter-flutter-visible-0.png'
UI_ORIGINAL = 'village/open-village-01.xml'


class Clock:
    def __init__(self):
        self.now = 0.0

    def monotonic(self):
        return self.now

    def advance(self, seconds):
        self.now += seconds


class ControlledOriginalSequence:
    """Transport doubles only; PNG, OCR, XML and command fixtures keep real bytes."""
    def __init__(self, root, sequence, *, total=900):
        self.root, self.sequence = root, sequence
        self.clock = Clock()
        self.probe = observed.VillageProbe.__new__(observed.VillageProbe)
        self.probe.out, self.probe.deadline, self.probe.counter = root, total, 0
        self.captures, self.ocr_calls, self.ui_calls, self.inputs = [], [], [], []
        self.capture_cost, self.ocr_cost, self.ui_cost = 1.0, 2.0, 1.0
        self.ui_bytes = (FIXTURES/UI_ORIGINAL).read_bytes()
        self.wrong_host = False
        self.base_adb = mock.Mock(side_effect=AssertionError('Unexpected additional Android input'))
        self.probe.base = SimpleNamespace(adb=self.base_adb)
        self.probe.processes = self.processes
        self.probe.read_preferences = self.preferences
        self.probe.original = self.input_original
        self.probe.ui = SimpleNamespace(
            native_tap=self.return_touch, capture=self.capture,
            capture_flutter_ready=self.capture_entropy_ready,
            image_lines=self.ocr, read_live_nodes=self.old_live_nodes)

    def original_command(self, source_stem, tag):
        name = 'commands/'+tag
        for suffix in ('.stdout', '.stderr', '.json'):
            destination = self.root/(name+suffix)
            destination.parent.mkdir(parents=True, exist_ok=True)
            with destination.open('xb') as stream:
                stream.write((FIXTURES/'village/commands'/(source_stem+suffix)).read_bytes())
        return name+'.stdout'

    def processes(self, tag, *, native):
        self.probe.remaining()
        self.clock.advance(.1)
        if self.wrong_host and not native:
            raise ValueError('Controlled changed host PID cannot establish a return')
        prefix = 'village-before-return' if native else 'returned-flutter-0'
        first = 64 if native else 68
        row = {}
        for offset, key in enumerate(('host_pid', 'native_pid', 'activity')):
            row[key] = self.original_command(
                f'{first+offset:04d}-{prefix}-{key}', tag+'-'+key)
        village.process(self.root, row, native=native)
        return row

    def preferences(self, tag):
        self.probe.remaining()
        self.clock.advance(.1)
        name = self.original_command('0071-returned-flutter-preferences', tag+'-preferences')
        return observed.c4.preferences((self.root/name).read_text()), name

    def input_original(self, tag, *args, **kwargs):
        expected = tuple(json.loads((FIXTURES/'village/commands/0067-village-visible-return-touch.json').read_text())['command'][1:])
        if args != expected:
            raise AssertionError('Only the unchanged observed return touch is allowed')
        self.inputs.append(args)
        return '', self.original_command('0067-village-visible-return-touch', tag)

    def return_touch(self, out, label, tag, **kwargs):
        if (label, tag, kwargs['exact'], kwargs['orientation']) != ('Spiele', 'village-return', True, 'responsive'):
            raise AssertionError('Original visible return contract changed')
        args = json.loads((FIXTURES/'village/commands/0067-village-visible-return-touch.json').read_text())['command'][1:]
        self.probe.base.adb(*args)
        shutil.copyfile(FIXTURES/'village/village-return-surface-readiness.json',
                        out/'village-return-surface-readiness.json')

    def capture(self, out, tag, timeout=None):
        phase = self.sequence[min(len(self.captures), len(self.sequence)-1)]
        source = FIXTURES/(VILLAGE_FRAME if phase == 'village' else FLUTTER_FRAME)
        self.captures.append({'tag': tag, 'timeout': timeout,
                              'at': self.clock.now, 'phase': phase})
        self.clock.advance(self.capture_cost)
        target = out/(tag+'.png')
        with target.open('xb') as stream:
            stream.write(source.read_bytes())
        with Image.open(target) as image:
            dimensions = image.size
        return {'file': target.name, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
                'width': dimensions[0], 'height': dimensions[1]}

    def capture_entropy_ready(self, out, tag, *, timeout):
        return readiness.capture_when_ready(out, tag, self.capture,
            timeout=timeout, wait=self.clock.advance, clock=self.clock.monotonic)

    def ocr(self, out, tag, wanted, *, source_path, timeout, exact):
        self.ocr_calls.append({'tag': tag, 'timeout': timeout, 'at': self.clock.now})
        if (wanted, exact) != ('spielen', True):
            raise AssertionError('Caption must remain exact Spielen')
        self.clock.advance(self.ocr_cost)
        is_village = hashlib.sha256(source_path.read_bytes()).digest() == hashlib.sha256((FIXTURES/VILLAGE_FRAME).read_bytes()).digest()
        prefix = ('village/returned-flutter-visible' if is_village
                  else 'main/23_zurueck_in_flutter-flutter-visible-0')
        for suffix in (['-ocr.json'] if is_village else ['-ocr.json', '-ocr-contrast.tsv']):
            with (out/(tag+suffix)).open('xb') as stream:
                stream.write((FIXTURES/(prefix+suffix)).read_bytes())
        # The shared OCR helper uses this derivative scratch image. The loop
        # must preserve it under this attempt's unique name before the next read.
        (out/'ocr-work.png').write_bytes(source_path.read_bytes())
        return json.loads((out/(tag+'-ocr.json')).read_text())

    def old_live_nodes(self, out, tag):
        (out/(tag+'.xml')).write_bytes(self.ui_bytes)
        return list(ET.fromstring(self.ui_bytes).iter('node'))

    def child_reader(self, command, *, stdout, stderr, timeout, check):
        self.ui_calls.append({'command': command, 'timeout': timeout, 'at': self.clock.now})
        if command[:3] != [sys.executable, '-B', '-c'] or 'live.live_nodes' not in command[3]:
            raise AssertionError('Expected the same read-only accessibility helper')
        self.clock.advance(self.ui_cost)
        (Path(command[-1])/'hierarchy.xml').write_bytes(self.ui_bytes)
        return SimpleNamespace(returncode=0, stdout=b'', stderr=b'')

    def run(self):
        with mock.patch.object(observed.time, 'monotonic', side_effect=self.clock.monotonic), \
             mock.patch.object(observed.time, 'sleep', side_effect=self.clock.advance), \
             mock.patch.object(observed.subprocess, 'run', side_effect=self.child_reader):
            return self.probe.visible_return(6511)


class VillageReturnObservationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def fixture_sequence(self, phases, **kwargs):
        return ControlledOriginalSequence(self.root, phases, **kwargs)

    def test_archived_village_entropy_does_not_establish_spielen(self):
        frame = FIXTURES/VILLAGE_FRAME
        original = json.loads((FIXTURES/'village/returned-flutter-frame-render-readiness.json').read_text())
        actual = readiness.inspect_flutter_frame(frame)
        self.assertEqual(actual['content_entropy_bits'], original['attempts'][0]['content_entropy_bits'])
        self.assertTrue(actual['visually_ready'])
        with self.assertRaisesRegex(ValueError, 'does not establish caption: Spielen'):
            village.caption(FIXTURES/'village', frame, 'returned-flutter-visible', 'Spielen')

    def test_earlier_original_main_frame_and_tsv_are_only_controlled_inputs(self):
        bounds = village.caption(FIXTURES/'main', FIXTURES/FLUTTER_FRAME,
            '23_zurueck_in_flutter-flutter-visible-0', 'Spielen')
        self.assertEqual(bounds, [399.0, 2277.0, 503.0, 2304.0])
        self.assertIn('EARLIER MAIN-TOUR', json.loads((FIXTURES/'provenance.json').read_text())['scope'])

    def test_controlled_archived_village_then_flutter_requires_new_observation(self):
        sequence = self.fixture_sequence(['village', 'flutter'])
        row = sequence.run()
        self.assertEqual(len(sequence.inputs), 1)
        self.assertEqual(row['frame']['file'], 'returned-flutter-001-frame.png')
        journal = json.loads((self.root/'returned-flutter-observations.json').read_text())
        self.assertEqual([item['status'] for item in journal['attempts']], ['REJECTED', 'OBSERVED'])
        self.assertEqual((self.root/'returned-flutter-000-frame.png').read_bytes(), (FIXTURES/VILLAGE_FRAME).read_bytes())
        self.assertEqual((self.root/row['frame']['file']).read_bytes(), (FIXTURES/FLUTTER_FRAME).read_bytes())
        self.assertEqual((self.root/row['ui']).read_bytes(), (FIXTURES/UI_ORIGINAL).read_bytes())
        self.assertEqual(len(sequence.ui_calls), 1)
        self.assertIs(sequence.probe.base.adb, sequence.base_adb)

    def test_persistent_original_village_fails_with_one_touch_and_all_frames_kept(self):
        sequence = self.fixture_sequence(['village'])
        with self.assertRaises(TimeoutError):
            sequence.run()
        journal = json.loads((self.root/'returned-flutter-observations.json').read_text())
        self.assertEqual(journal['status'], 'FAIL')
        self.assertEqual(len(sequence.inputs), 1)
        self.assertGreater(len(sequence.captures), 1)
        self.assertFalse(sequence.ui_calls)
        for item in sequence.captures:
            self.assertEqual((self.root/(item['tag']+'.png')).read_bytes(), (FIXTURES/VILLAGE_FRAME).read_bytes())
        self.assertEqual(sequence.probe.deadline, 900)
        self.assertFalse(hasattr(sequence.probe, '_flutter_return_deadline'))

    def test_caption_with_disabled_wrong_package_or_malformed_ui_is_not_accepted(self):
        original = (FIXTURES/UI_ORIGINAL).read_bytes()
        invalid = (original.replace(b'enabled="true"', b'enabled="false"'),
                   original.replace(observed.c4.PACKAGE.encode(), b'controlled.other.package'),
                   original[:45])
        for number, raw in enumerate(invalid):
            with self.subTest(case=number), tempfile.TemporaryDirectory() as temp:
                sequence = ControlledOriginalSequence(Path(temp), ['flutter'])
                sequence.ui_bytes = raw
                sequence.ui_cost = 20
                with self.assertRaises(TimeoutError):
                    sequence.run()
                self.assertEqual(len(sequence.inputs), 1)
                self.assertGreater(len(sequence.ui_calls), 1)
                for call in sequence.ui_calls:
                    self.assertEqual((Path(call['command'][-1])/'hierarchy.xml').read_bytes(), raw)

    def test_frame_arriving_exactly_at_return_deadline_cannot_reach_caption_success(self):
        sequence = self.fixture_sequence(['flutter'])
        sequence.capture_cost = 60
        with self.assertRaises(TimeoutError):
            sequence.run()
        self.assertFalse(sequence.ocr_calls)
        self.assertFalse(sequence.ui_calls)
        self.assertEqual(len(sequence.inputs), 1)

    def test_accessibility_result_after_common_deadline_cannot_succeed(self):
        sequence = self.fixture_sequence(['flutter'])
        sequence.ui_cost = 60
        with self.assertRaises(TimeoutError):
            sequence.run()
        self.assertEqual(len(sequence.ui_calls), 1)
        invocation = json.loads((Path(sequence.ui_calls[0]['command'][-1])/'invocation.json').read_text())
        self.assertEqual(invocation['returncode'], 0)
        self.assertEqual(json.loads((self.root/'returned-flutter-observations.json').read_text())['status'], 'FAIL')

    def test_shrinking_global_budget_is_forwarded_to_frame_ocr_and_live_reader(self):
        sequence = self.fixture_sequence(['flutter'], total=9)
        sequence.run()
        calls = sequence.captures+sequence.ocr_calls+sequence.ui_calls
        for call in calls:
            self.assertGreater(call['timeout'], 0)
            self.assertLessEqual(call['timeout'], 9-call['at'])
        self.assertLess(sequence.clock.now, 9)
        self.assertEqual(sequence.probe.deadline, 9)

    def test_real_original_command_uses_the_shared_return_deadline_and_keeps_output(self):
        probe = observed.VillageProbe.__new__(observed.VillageProbe)
        probe.out, probe.deadline, probe._flutter_return_deadline, probe.counter = self.root, 900, 12, 0
        result = SimpleNamespace(stdout=b'6203\n', stderr=b'', returncode=0)
        with mock.patch.object(observed.time, 'monotonic', return_value=11.5), \
             mock.patch.object(observed.subprocess, 'run', return_value=result) as run:
            raw, name = probe.original('shared-budget', 'shell', 'pidof', observed.c4.PACKAGE)
        self.assertEqual(run.call_args.kwargs['timeout'], .5)
        self.assertEqual(raw, '6203\n')
        self.assertEqual((self.root/name).read_bytes(), b'6203\n')

    def test_accessibility_timeout_retains_partial_original_streams(self):
        probe = observed.VillageProbe.__new__(observed.VillageProbe)
        probe.out, probe.deadline, probe._flutter_return_deadline = self.root, 900, 12
        error = subprocess.TimeoutExpired(['controlled-reader'], .5,
            output=b'partial controlled stdout', stderr=b'partial controlled stderr')
        with mock.patch.object(observed.time, 'monotonic', return_value=11.5), \
             mock.patch.object(observed.subprocess, 'run', side_effect=error) as run:
            with self.assertRaises(TimeoutError):
                probe.read_return_ui('timeout-fixture')
        self.assertEqual(run.call_args.kwargs['timeout'], .5)
        directory = self.root/'timeout-fixture-live-ui'
        self.assertEqual((directory/'stdout.original').read_bytes(), error.stdout)
        self.assertEqual((directory/'stderr.original').read_bytes(), error.stderr)
        self.assertIsNone(json.loads((directory/'invocation.json').read_text())['returncode'])

    def test_changed_host_cannot_pass_even_with_correct_archived_flutter_inputs(self):
        sequence = self.fixture_sequence(['flutter'])
        sequence.wrong_host = True
        with self.assertRaises(TimeoutError):
            sequence.run()
        self.assertEqual(len(sequence.inputs), 1)
        self.assertFalse(sequence.captures)
        self.assertFalse(sequence.ui_calls)

    def test_each_rejected_frame_and_ocr_derivative_keeps_a_unique_path(self):
        sequence = self.fixture_sequence(['village', 'village', 'flutter'])
        sequence.run()
        self.assertEqual(len(sequence.inputs), 1)
        for number in range(3):
            tag = f'returned-flutter-{number:03d}'
            expected = (FIXTURES/(VILLAGE_FRAME if number < 2 else FLUTTER_FRAME)).read_bytes()
            self.assertEqual((self.root/(tag+'-frame.png')).read_bytes(), expected)
            self.assertEqual((self.root/(tag+'-ocr-work.png')).read_bytes(), expected)
            self.assertTrue((self.root/(tag+'-visible-ocr.json')).is_file())
        self.assertFalse((self.root/'ocr-work.png').exists())


if __name__ == '__main__':
    unittest.main()
