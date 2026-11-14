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

    def arm_native_opt_in(self, tag, *, controls=None, after_portal=None):
        """Synthetic navigation boundary; real target/frame methods stay active."""
        def dispatch(name, *args, **kwargs):
            result = self.original(name, *args, **kwargs)
            if name == tag + '-touch':
                self.destination = ([node(PROBE.contract.NATIVE_ENTRY, bounds='[820,100][970,250]')]
                                    if controls is None else controls)
                if after_portal is not None:
                    after_portal()
            return result
        self.value.original = mock.Mock(side_effect=dispatch)

    def test_first_opening_uses_fresh_portal_and_enabled_native_opt_in(self):
        self.direct_destination()
        self.arm_native_opt_in('open-c4')
        result = self.value.open_native_from_flutter('open-c4')
        self.assertEqual(self.inputs, [
            ('open-c4-touch', ('shell','input','swipe','283','1905','283','1905','120')),
            ('open-c4-native-touch', ('shell','input','swipe','895','175','895','175','120')),
        ])
        portal = json.loads((self.out/result['portal_touch']).read_text())
        readiness = json.loads((self.out/result['native_ready']).read_text())
        native = json.loads((self.out/result['native_touch']).read_text())
        self.assertEqual(portal['target']['label'], PROBE.contract.PORTAL)
        self.assertEqual(readiness['label'], PROBE.contract.NATIVE_ENTRY)
        self.assertEqual(len(readiness['observations']), 1)
        self.assertEqual(native['target']['label'], PROBE.contract.NATIVE_ENTRY)
        frames = [portal['first'],portal['second'],*readiness['observations'],native['first'],native['second']]
        self.assertEqual(len({frame['ui'] for frame in frames}), 5)
        self.assertEqual(len({frame['capture']['file'] for frame in frames}), 5)
        self.assertTrue(all(first['observed_monotonic'] < second['observed_monotonic']
                            for first, second in zip(frames, frames[1:])))
        self.assertEqual(len(self.capture_timeouts), 5)

    def test_reopening_after_one_return_requires_another_actual_opt_in_touch(self):
        self.arm_native_opt_in('reopen-c4')
        self.value.return_to_flutter('return-first')
        self.value.native_touch.assert_called_once_with('return-first', 'back')
        self.assertEqual(len(self.inputs), 1)
        ready = json.loads((self.out/self.value.returns[0]['games_ready']).read_text())
        result = self.value.open_native_from_flutter('reopen-c4')
        self.assertEqual([entry[0] for entry in self.inputs],
                         ['return-first-to-games-touch','reopen-c4-touch','reopen-c4-native-touch'])
        portal = json.loads((self.out/result['portal_touch']).read_text())
        native_ready = json.loads((self.out/result['native_ready']).read_text())
        native = json.loads((self.out/result['native_touch']).read_text())
        self.assertGreater(portal['first']['observed_monotonic'],
                           ready['observations'][-1]['observed_monotonic'])
        self.assertGreater(native_ready['observations'][0]['observed_monotonic'],
                           portal['second']['observed_monotonic'])
        self.assertGreater(native['first']['observed_monotonic'],
                           native_ready['observations'][-1]['observed_monotonic'])
        self.assertEqual(len(self.value.returns), 1)

    def test_ineligible_native_opt_in_never_dispatches_native_input(self):
        valid = node(PROBE.contract.NATIVE_ENTRY, bounds='[820,100][970,250]')
        cases = {
            'missing':[], 'disabled':[{**valid,'enabled':'false'}],
            'ambiguous':[valid,valid], 'not-clickable':[{**valid,'clickable':'false'}],
            'clipped':[{**valid,'bounds':'[950,100][1100,250]'}],
            'too-small':[{**valid,'bounds':'[820,100][920,200]'}],
            'foreign-package':[{**valid,'package':'another.app'}],
            'wrong-caption':[{**valid,'content-desc':'3D'}],
        }
        for name, controls in cases.items():
            with self.subTest(name=name):
                self.now=0.0; self.direct_destination(); self.inputs.clear()
                self.value.deadline=5.0
                self.destination=[node(PROBE.contract.PORTAL)]
                tag='ineligible-'+name
                self.arm_native_opt_in(tag,controls=controls)
                with self.assertRaises(TimeoutError):
                    self.value.open_native_from_flutter(tag)
                self.assertEqual([entry[0] for entry in self.inputs], [tag+'-touch'])

    def test_native_opt_in_must_remain_enabled_for_its_second_observation(self):
        self.direct_destination()
        self.arm_native_opt_in('changed')
        read = self.read_nodes
        count = 0
        def changing_nodes(out, name):
            nonlocal count
            if name.startswith('changed-native-') and not name.startswith('changed-native-ready-'):
                count += 1
                if count == 2:
                    self.destination=[node(PROBE.contract.NATIVE_ENTRY, enabled='false',
                                           bounds='[820,100][970,250]')]
            return read(out,name)
        self.value.ui.read_live_nodes = changing_nodes
        with self.assertRaises(ValueError):
            self.value.open_native_from_flutter('changed')
        self.assertEqual(count, 2)
        self.assertEqual([entry[0] for entry in self.inputs], ['changed-touch'])

    def test_native_opt_in_frame_change_blocks_dispatch_after_portal(self):
        self.direct_destination()
        self.arm_native_opt_in('frame-change')
        wait = self.value.wait_for_flutter_control
        def tamper_after_readiness(*args, **kwargs):
            result = wait(*args, **kwargs)
            self.tamper_frame=True
            return result
        self.value.wait_for_flutter_control = tamper_after_readiness
        with self.assertRaisesRegex(ValueError,'Flutter frame changed before touch'):
            self.value.open_native_from_flutter('frame-change')
        self.assertEqual([entry[0] for entry in self.inputs], ['frame-change-touch'])

    def test_existing_global_budget_expires_between_portal_and_opt_in(self):
        self.direct_destination()
        def expire():
            self.now=900.0
        self.arm_native_opt_in('expired-after-portal',after_portal=expire)
        with self.assertRaisesRegex(TimeoutError,'exceeded 900 seconds'):
            self.value.open_native_from_flutter('expired-after-portal')
        self.assertEqual([entry[0] for entry in self.inputs], ['expired-after-portal-touch'])
        self.assertEqual(len(self.capture_timeouts), 2)

    def test_delayed_native_button_is_observed_without_another_portal_touch(self):
        self.direct_destination()
        portal_at = None
        def remember_portal():
            nonlocal portal_at
            portal_at = self.now
        self.arm_native_opt_in('delayed', controls=[], after_portal=remember_portal)
        read = self.read_nodes
        def delayed_nodes(out, name):
            if portal_at is not None and self.now - portal_at >= 4.5:
                self.destination=[node(PROBE.contract.NATIVE_ENTRY, bounds='[820,100][970,250]')]
            if name.startswith('delayed-native-ready-'):
                self.assertEqual([entry[0] for entry in self.inputs], ['delayed-touch'])
            return read(out, name)
        self.value.ui.read_live_nodes = delayed_nodes
        result = self.value.open_native_from_flutter('delayed')
        ready = json.loads((self.out/result['native_ready']).read_text())
        self.assertGreater(len(ready['observations']), 1)
        self.assertTrue(all('reason' in item and 'target' not in item
                            for item in ready['observations'][:-1]))
        self.assertEqual(ready['observations'][-1]['target']['label'], PROBE.contract.NATIVE_ENTRY)
        native = json.loads((self.out/result['native_touch']).read_text())
        self.assertLess(ready['observations'][-1]['observed_monotonic'],
                        native['first']['observed_monotonic'])
        self.assertEqual(len(self.capture_timeouts), len(ready['observations']) + 4)
        self.assertTrue(all(0 < value <= 30 for value in self.capture_timeouts))
        self.assertEqual([entry[0] for entry in self.inputs], ['delayed-touch','delayed-native-touch'])

    def test_native_button_timeout_keeps_one_portal_touch_and_no_native_input(self):
        self.direct_destination()
        portal_at = None
        def remember_portal():
            nonlocal portal_at
            portal_at = self.now
        self.arm_native_opt_in('never-ready', controls=[], after_portal=remember_portal)
        with self.assertRaisesRegex(TimeoutError, 'No qualifying actual Flutter destination'):
            self.value.open_native_from_flutter('never-ready')
        self.assertEqual([entry[0] for entry in self.inputs], ['never-ready-touch'])
        self.assertGreaterEqual(self.now - portal_at, 30.0)
        self.assertLess(self.now - portal_at, 30.25)
        failure = json.loads((self.out/'never-ready-native-ready-wait-failure.json').read_text())
        self.assertEqual(failure['timeout_seconds'], 30)
        self.assertTrue(failure['observations'])
        self.assertTrue(all('target' not in item for item in failure['observations']))
        self.assertFalse((self.out/'never-ready-native-flutter-touch.json').exists())
        self.assertFalse((self.out/'never-ready-native-ready-flutter-ready.json').exists())
        self.value.native_touch.assert_not_called()


if __name__ == '__main__':
    unittest.main()
