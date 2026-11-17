"""Exercise the real C4 navigation observer with explicit synthetic device boundaries.

No emulator, real screenshot, production save or Android acceptance is implied.
The source methods and strict Flutter target contract remain unmodified by tests.
"""
from __future__ import annotations

from contextlib import ExitStack
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
SPEC = importlib.util.spec_from_file_location('c4_navigation_subject',
    ROOT / '.github/probes/lumo_connect_four_android_probe.py')
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)


def node(label, *, bounds='[42,1817][524,1993]', **changes):
    value = {'package':PROBE.contract.PACKAGE, 'text':'', 'content-desc':label,
             'enabled':'true', 'clickable':'true', 'bounds':bounds, 'scrollable':'false'}
    value.update(changes)
    return value


class NavigationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.frames = {}
        for phase, colour in (('pause', '#786060'), ('games', '#608078')):
            image = io.BytesIO()
            Image.new('RGB', (1080, 2400), colour).save(image, format='PNG')
            cls.frames[phase] = image.getvalue()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.stack = ExitStack()
        self.addCleanup(self.stack.close)
        self.now = 0.0
        self.left_at = None
        self.delay = 4.5
        self.destination = [node(PROBE.contract.PORTAL)]
        self.inputs = []
        self.capture_timeouts = []
        self.slow_stage = None
        self.slow_time = 2.0
        self.tamper_frame = False
        self.stack.enter_context(mock.patch.object(PROBE.time, 'monotonic', lambda: self.now))
        self.stack.enter_context(mock.patch.object(PROBE.time, 'sleep', self.advance))
        self.value = PROBE.Probe.__new__(PROBE.Probe)
        self.value.out = self.out
        self.value.deadline = 900.0
        self.value.mailbox = '/synthetic-private-mailbox/' + 'a' * 32
        self.value.token = 'a' * 32
        self.value.returns = []
        self.value.original = mock.Mock(side_effect=self.original)
        self.value.density = self.density
        self.value.ui = SimpleNamespace(read_live_nodes=self.read_nodes,
            capture_flutter_ready=self.capture)
        self.before = {'id':'synthetic-native-pause', 'state':{'paused':True}}
        self.value.native_touch = mock.Mock(return_value=self.before)
        self.value.read_preferences = mock.Mock(return_value=({}, 'synthetic-preferences.xml'))
        self.stack.enter_context(mock.patch.object(PROBE.contract, 'persisted_round',
                                                   return_value={'synthetic':True}))

    def advance(self, seconds):
        self.now += seconds

    def stage(self, name):
        if self.slow_stage == name:
            self.now = self.slow_time

    def paused(self):
        return self.left_at is None or self.now - self.left_at < self.delay

    def read_nodes(self, out, name):
        self.advance(.1)
        self.stage('hierarchy')
        nodes = ([node('Spiel pausiert', clickable='false'),
                  node('Fortsetzen', bounds='[116,1220][964,1346]'),
                  node('Zur Spieleauswahl', bounds='[116,1377][964,1503]')]
                 if self.paused() else self.destination)
        root = ET.Element('hierarchy')
        for value in nodes:
            ET.SubElement(root, 'node', value)
        (out / (name + '.xml')).write_bytes(ET.tostring(root))
        return nodes

    def capture(self, out, name, **kwargs):
        self.capture_timeouts.append(kwargs['timeout'])
        self.advance(.1)
        self.stage('frame')
        data = self.frames['pause' if self.paused() else 'games']
        path = out / (name + '.png')
        path.write_bytes(data + (b'changed-after-capture' if self.tamper_frame else b''))
        return {'file':path.name, 'width':1080, 'height':2400,
                'sha256':hashlib.sha256(data).hexdigest()}

    def density(self):
        self.advance(.01)
        self.stage('density')
        return 2.625, 'synthetic-density.stdout'

    def original(self, tag, *args, **_kwargs):
        if args[:2] == ('shell', 'input'):
            self.inputs.append((tag, args))
            if tag.endswith('-to-games-touch'):
                self.left_at = self.now
        value = ('topResumedActivity: ' + PROBE.contract.PACKAGE + '/MainActivity\n'
                 if tag.endswith('-return-activity') else '')
        return value, 'commands/' + tag + '.stdout'

    def direct_destination(self):
        self.left_at = -10.0

    def test_one_leave_tap_waits_for_delayed_games_before_fresh_portal_touch(self):
        result = self.value.return_to_flutter('return-first')
        self.assertIs(result, self.before)
        self.assertEqual(len(self.inputs), 1)
        self.assertEqual(self.inputs[0], ('return-first-to-games-touch',
            ('shell', 'input', 'swipe', '540', '1440', '540', '1440', '120')))
        ready = self.out / self.value.returns[0]['games_ready']
        evidence = json.loads(ready.read_text())
        self.assertGreaterEqual(self.now - self.left_at, self.delay)
        self.assertTrue(any('pause is still visible' in item.get('reason', '')
                            for item in evidence['observations']))
        self.assertEqual(evidence['observations'][-1]['target']['label'], PROBE.contract.PORTAL)
        self.value.flutter_touch(PROBE.contract.PORTAL, 'reopen-c4')
        self.assertEqual(len(self.inputs), 2)
        self.assertEqual(self.inputs[-1], ('reopen-c4-touch',
            ('shell', 'input', 'swipe', '283', '1905', '283', '1905', '120')))
        reopened = json.loads((self.out / 'reopen-c4-flutter-touch.json').read_text())
        self.assertNotEqual(reopened['first']['ui'], reopened['second']['ui'])
        self.assertTrue(all(0 < timeout <= 30 for timeout in self.capture_timeouts))

    def test_permanent_pause_fails_without_repeating_leave_or_opening_a_route(self):
        self.delay = 100.0
        with self.assertRaisesRegex(TimeoutError, 'No qualifying actual Flutter destination'):
            self.value.return_to_flutter('return-first')
        self.assertEqual(len(self.inputs), 1)
        self.assertEqual(self.inputs[0][0], 'return-first-to-games-touch')
        self.assertEqual(len(self.value.returns), 1)
        self.assertNotIn('games_ready', self.value.returns[0])
        failure = json.loads((self.out / 'return-first-games-wait-failure.json').read_text())
        self.assertTrue(failure['observations'])
        self.assertTrue(all('target' not in item for item in failure['observations']))

    def test_invalid_destinations_never_authorize_input(self):
        cases = {
            'ambiguous':[node(PROBE.contract.PORTAL), node(PROBE.contract.PORTAL)],
            'disabled':[node(PROBE.contract.PORTAL, enabled='false')],
            'not-clickable':[node(PROBE.contract.PORTAL, clickable='false')],
            'clipped':[node(PROBE.contract.PORTAL, bounds='[42,2300][524,2501]')],
            'too-small':[node(PROBE.contract.PORTAL, bounds='[42,1817][142,1917]')],
            'foreign-package':[node(PROBE.contract.PORTAL, package='another.app')],
            'wrong-caption':[node('Spiele')],
            'pause-over-games':[node(PROBE.contract.PORTAL), node('Spiel pausiert')],
        }
        for tag, nodes in cases.items():
            with self.subTest(tag=tag):
                self.now = 0.0
                self.direct_destination()
                self.destination = nodes
                with self.assertRaises(TimeoutError):
                    self.value.wait_for_flutter_control(PROBE.contract.PORTAL, tag, timeout=2)
                self.assertTrue((self.out / (tag + '-wait-failure.json')).exists())
                self.assertEqual(self.inputs, [])

    def test_ready_observation_is_not_reused_as_a_portal_touch_authorization(self):
        self.direct_destination()
        self.value.wait_for_flutter_control(PROBE.contract.PORTAL, 'ready')
        self.destination = [node(PROBE.contract.PORTAL, enabled='false')]
        with self.assertRaises(ValueError):
            self.value.flutter_touch(PROBE.contract.PORTAL, 'changed-before-touch')
        self.assertEqual(self.inputs, [])

    def test_exact_deadline_rejects_late_hierarchy_frame_and_density(self):
        for stage in ('hierarchy', 'frame', 'density'):
            with self.subTest(stage=stage):
                self.now = 0.0
                self.direct_destination()
                self.slow_stage = stage
                with self.assertRaises(TimeoutError):
                    self.value.wait_for_flutter_control(PROBE.contract.PORTAL, stage, timeout=2)
                self.assertTrue((self.out / (stage + '-wait-failure.json')).exists())
                self.assertEqual(self.inputs, [])

    def test_evidence_write_cannot_turn_an_expired_observation_into_success(self):
        self.direct_destination()
        write = PROBE.write
        def delayed_write(path, value):
            write(path, value)
            if path.name.endswith('-flutter-ready.json'):
                self.now = 2.0
        with mock.patch.object(PROBE, 'write', side_effect=delayed_write):
            with self.assertRaises(TimeoutError):
                self.value.wait_for_flutter_control(PROBE.contract.PORTAL, 'late-write', timeout=2)
        self.assertTrue((self.out / 'late-write-wait-failure.json').exists())
        self.assertEqual(self.inputs, [])

    def test_global_deadline_remains_mandatory(self):
        self.direct_destination()
        self.value.deadline = 0.0
        with self.assertRaises(TimeoutError):
            self.value.wait_for_flutter_control(PROBE.contract.PORTAL, 'expired')
        self.assertEqual(self.capture_timeouts, [])
        self.assertEqual(self.inputs, [])

    def test_current_frame_integrity_failure_is_not_retried_or_accepted(self):
        self.direct_destination()
        self.tamper_frame = True
        with self.assertRaisesRegex(ValueError, 'frame changed before acceptance'):
            self.value.wait_for_flutter_control(PROBE.contract.PORTAL, 'tampered')
        self.assertEqual(len(self.capture_timeouts), 1)
        self.assertEqual(self.inputs, [])


if __name__ == '__main__':
    unittest.main()
