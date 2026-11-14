"""Pure contracts for the Android Memory reader; no adb or game writes.

The fixtures are explicitly desktop Dart/Godot originals. Android mode must
reject their fixture observation source. Mutations below are negative test
inputs, never writes to a product save or transport.
"""
from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    'memory_probe_contract', ROOT / '.github/probes/lumo_memory_android_probe.py')
probe = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(probe)
FIXTURES = Path(__file__).with_name('fixtures') / 'memory_android'


class FakeClock:
    def __init__(self):
        self.now = 0.0

    def monotonic(self):
        return self.now

    def sleep(self, seconds):
        self.now += seconds


class MemoryAndroidContracts(unittest.TestCase):
    def setUp(self):
        self.data = json.loads((FIXTURES / 'public-states.json').read_text())
        self.state = self.data['hidden']
        self.face = self.data['face']
        self.layout = json.loads((FIXTURES / 'layout-hidden.json').read_text())
        self.face_layout = json.loads((FIXTURES / 'layout-face.json').read_text())
        self.saved = json.loads((FIXTURES / 'saved-paused.json').read_text())
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)

    def validate(self, layout=None, state=None, **kw):
        l = self.layout if layout is None else layout
        s = self.state if state is None else state
        return probe.check_layout(l, s, [960, 540], 1, self.layout['pid'],
                                  allow_fixture=True, **kw)

    def bare_probe(self):
        p = object.__new__(probe.AndroidProbe)
        p.out = Path(self.tmp.name)
        p.args = SimpleNamespace(serial='emulator-5554')
        p.count = 0
        p.events = []
        p.density = 1
        p.owner = self.state['owner']
        p.deadline = 100
        return p

    def test_actual_pair_geometry_and_first_request(self):
        self.assertEqual(len(self.validate()['cards']), 8)
        self.assertEqual(len(self.validate(self.face_layout, self.face)['cards']), 8)
        receipt = probe.check_ack(self.state, self.data['flip_request'],
                                  self.face, 'flip', {'index': 0})
        self.assertEqual(receipt['sequence'], 1)

    def test_all_exact_tour_names_and_same_binary_runtime_required(self):
        prior = {'status': 'PASS', 'apk_sha256': 'a' * 64, 'android_sdk': '35',
                 'steps': [{'step': name, 'ok': True} for name in sorted(probe.TOUR_STEPS)]}
        probe.check_tour(prior, 'a' * 64, 35)
        for patch in ({'status': 'FAIL'}, {'apk_sha256': 'b' * 64}, {'android_sdk': '37'},
                      {'android_sdk': 35}, {'steps': prior['steps'][:-1]},
                      {'steps': prior['steps'][:-1] + [prior['steps'][0]]},
                      {'steps': prior['steps'][:-1] + [{'step': 'fake-step', 'ok': True}]},
                      {'steps': prior['steps'][:-1] + [{'step': prior['steps'][-1]['step'], 'ok': False}]}):
            with self.subTest(patch=patch), self.assertRaises(RuntimeError):
                probe.check_tour({**prior, **patch}, 'a' * 64, 35)

    def test_desktop_fixture_cannot_pass_android_default(self):
        with self.assertRaisesRegex(RuntimeError, 'Android inset'):
            probe.check_layout(self.layout, self.state, [960, 540], 1, self.layout['pid'])

    def test_false_polygon_and_camera_rotation_rejected(self):
        l = deepcopy(self.layout)
        l['cards'][0]['quad'][0][0] += 3
        with self.assertRaisesRegex(RuntimeError, 'independent projection'):
            self.validate(l)
        l = deepcopy(self.layout)
        l['camera']['basis'][0], l['camera']['basis'][1] = l['camera']['basis'][1], l['camera']['basis'][0]
        with self.assertRaisesRegex(RuntimeError, 'independent projection'):
            self.validate(l)

    def test_actual_rotation_and_density_are_bound(self):
        with self.assertRaisesRegex(RuntimeError, 'Screenshot size'):
            probe.check_layout(self.layout, self.state, [540, 960], 1,
                               self.layout['pid'], allow_fixture=True)
        with self.assertRaisesRegex(RuntimeError, 'density'):
            probe.check_layout(self.layout, self.state, [960, 540], 2,
                               self.layout['pid'], allow_fixture=True)

    def test_stale_identity_and_boolean_counters_rejected(self):
        for key, value in (('owner', 'b' * 64), ('token', 'b' * 32),
                           ('roundId', 'b' * 32), ('revision', 999), ('ack', True),
                           ('pending', True), ('pid', True)):
            with self.subTest(key=key):
                l = deepcopy(self.layout); l[key] = value
                with self.assertRaises(RuntimeError):
                    self.validate(l)

    def test_missing_pending_or_unsettled_snapshot_rejected(self):
        for change in ({'pending': 1}, {'settled': False}, {'layout_sequence': 0}):
            l = deepcopy(self.layout); l.update(change)
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                self.validate(l)

    def test_fake_insets_and_wrong_view_offset_rejected(self):
        l = deepcopy(self.layout); l['android_observation']['system_insets'][1] = 26
        with self.assertRaisesRegex(RuntimeError, 'Insets'):
            self.validate(l)
        l = deepcopy(self.layout); l['android_observation']['render_rect'][0] = 20
        with self.assertRaisesRegex(RuntimeError, 'Render view'):
            self.validate(l)

    def test_card_requires_exposed_48dp_actual_hit_area(self):
        target = probe.control_target(self.layout, 'card_0', 1)
        self.assertGreaterEqual(min(target['size_dp']), 48)
        for key, value in (('visible', False), ('enabled', False), ('clipped', True)):
            l = deepcopy(self.layout); l['cards'][0][key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.control_target(l, 'card_0', 1)
        l = deepcopy(self.layout); l['cards'][0]['hit_rect_px'][2] = 47
        with self.assertRaisesRegex(RuntimeError, '48dp'):
            probe.control_target(l, 'card_0', 1)

    def test_paused_card_cannot_be_a_touch_target(self):
        l = deepcopy(self.layout); l['paused'] = True; l['canFlip'] = False
        with self.assertRaisesRegex(RuntimeError, 'blocked'):
            probe.control_target(l, 'card_0', 1)

    def test_wrong_page_and_card_identity_rejected(self):
        l = deepcopy(self.layout); l['cards'][0]['visible'] = False
        with self.assertRaisesRegex(RuntimeError, 'visibility'):
            self.validate(l)
        l = deepcopy(self.layout); l['cards'][1]['id'] = 'card_0'
        with self.assertRaisesRegex(RuntimeError, '[Aa]mbiguous'):
            self.validate(l)

    def test_hidden_deck_and_impossible_score_rejected(self):
        s = deepcopy(self.state); s['cards'][0]['motif'] = 'truhe'
        with self.assertRaisesRegex(RuntimeError, 'Hidden deck'):
            probe.check_state(s)
        s = deepcopy(self.state); s['kindPairs'] = 1
        with self.assertRaisesRegex(RuntimeError, 'Scores'):
            probe.check_state(s)
        s = deepcopy(self.state); s['rewarded'] = True
        with self.assertRaisesRegex(RuntimeError, 'Unfinished round paid'):
            probe.check_state(s)

    def test_request_needs_current_token_revision_and_positive_ack(self):
        for key, value in (('token', '0' * 32), ('revision', 1), ('sequence', 0),
                           ('index', 7), ('injected_success', True)):
            r = deepcopy(self.data['flip_request']); r[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.check_ack(self.state, r, self.face, 'flip', {'index': 0})
        for change in ({'ack': 0}, {'rejected': 1}, {'recordRevision': 1}):
            s = deepcopy(self.face); s.update(change)
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                probe.check_ack(self.state, self.data['flip_request'], s, 'flip', {'index': 0})

    def test_actual_saved_round_and_private_face_crosscheck(self):
        state = self.data['paused']
        rules = probe.check_saved(self.saved, state)
        self.assertEqual(rules['remainingMs'], 550)
        for key, value in (('owner', 'b' * 64), ('id', 'b' * 32), ('revision', 1), ('schema', True)):
            s = deepcopy(self.saved); s[key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.check_saved(s, state)
        s = deepcopy(self.saved); s['rules']['cards'][0] = 'panda'
        with self.assertRaises(RuntimeError):
            probe.check_saved(s, state)

    def test_pause_reopen_preserves_all_private_rule_data(self):
        after = deepcopy(self.saved); after['revision'] += 1
        probe.frozen_round_equal(self.saved, after)
        for key, value in (('remainingMs', 0), ('known', {}), ('random', {'seed': 1, 'calls': []})):
            after = deepcopy(self.saved); after['rules'][key] = value
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.frozen_round_equal(self.saved, after)

    def test_other_profiles_stats_wallet_and_original_key_are_protected(self):
        owner = self.state['owner']
        original = {'flutter.lumo_memory_v2': 'old', 'flutter.lumo_reward_wallet_v1': 'wallet',
                    probe.ROUND_PREFIX + 'b' * 64: 'other round',
                    'flutter.lumo.memory.stats.v1.' + owner: 'bests',
                    'flutter.lumo_learning_local_student_id_v1': 'existing child'}
        after = {**original, probe.ROUND_PREFIX + owner: 'actual new paused round'}
        self.assertEqual(probe.check_preservation(original, after, owner)['unchanged_keys'], 5)
        for key in original:
            changed = {**after, key: 'changed'}
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.check_preservation(original, changed, owner)

    def test_bot_requires_actual_turn_progress_and_same_child_session(self):
        # The real pair includes an intervening pause/reopen. Only the test
        # transport identity is adapted to model this probe's direct path.
        bot = deepcopy(self.data['bot'])
        bot.update(token=self.face['token'], ack=2, rejected=0)
        deck = self.saved['rules']['cards']
        result = probe.check_bot_reply(self.face, bot, deck, 1, 2)
        self.assertEqual(result['phase'], 'botSecond')
        for change in ({'token': 'b' * 32}, {'owner': 'b' * 64}, {'ack': 1},
                       {'paused': True}, {'turn': 'kind'}, {'recordRevision': 2}):
            changed = deepcopy(bot); changed.update(change)
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                probe.check_bot_reply(self.face, changed, deck, 1, 2)

    def test_read_allowlist_cannot_escape_or_write(self):
        token = self.state['token']
        self.assertTrue(probe.allowed_read(probe.LAYOUT))
        for name in ('state', 'request', 'lifecycle'):
            self.assertTrue(probe.allowed_read(probe.SESSION + token + '/' + name + '.json'))
        for path in (probe.SESSION + '../state.json', probe.LAYOUT + ';echo x',
                     probe.SESSION + token + '/save.json', '/data/local/tmp/state.json'):
            self.assertFalse(probe.allowed_read(path))
        p = self.bare_probe()
        with mock.patch.object(probe.subprocess, 'run') as command:
            with self.assertRaisesRegex(RuntimeError, 'Unapproved'):
                p.raw('/data/local/tmp/state.json', 'bad')
            command.assert_not_called()

    def test_missing_layout_keeps_actual_raw_bytes_for_retry(self):
        p = self.bare_probe()
        raw = b'cat: ' + probe.LAYOUT.encode() + b': No such file or directory\n'
        outcome = subprocess.CompletedProcess([], 0, raw, b'')
        with mock.patch.object(p, 'budget', return_value=10), mock.patch.object(
                probe.subprocess, 'run', return_value=outcome):
            with self.assertRaises(json.JSONDecodeError):
                p.raw(probe.LAYOUT, 'missing')
        self.assertEqual(next(p.out.glob('*.raw')).read_bytes(), raw)

    def test_late_accepted_observation_cannot_pass_deadline(self):
        p = self.bare_probe(); clock = FakeClock()
        def late():
            clock.now += 3
            return True
        with mock.patch.object(probe.time, 'monotonic', clock.monotonic), \
                mock.patch.object(probe.time, 'sleep', clock.sleep):
            with self.assertRaisesRegex(RuntimeError, 'not observed'):
                p.wait('late', late, bool, timeout=2)

    def test_actual_device_command_is_bounded_and_late_return_rejected(self):
        p = self.bare_probe(); p.deadline = 2; clock = FakeClock()
        def late(*args, **kwargs):
            self.assertEqual(kwargs['timeout'], 2)
            clock.now = 3
            return 'late reply'
        p.base = SimpleNamespace(command=late)
        with mock.patch.object(probe.time, 'monotonic', clock.monotonic):
            with self.assertRaisesRegex(RuntimeError, 'after the fixed total deadline'):
                p.adb('shell', 'input', 'tap', '10', '20')

    def test_changed_layout_is_rejected_before_any_adb_touch(self):
        p = self.bare_probe()
        observation = {'layout': self.layout, 'layout_sha256': 'a' * 64,
                       'state': self.state, 'capture': {'file': 'actual.png'}}
        p.raw = mock.Mock(return_value=(self.layout, 'b' * 64))
        p.foreground = mock.Mock(); p.adb = mock.Mock()
        with self.assertRaisesRegex(RuntimeError, 'changed before touch'):
            p.touch(observation, 'card_0')
        p.adb.assert_not_called()
        self.assertEqual(p.events, [])

    def test_pixel_change_rejects_unchanged_and_flat_surfaces(self):
        class Pixels:
            size = (960, 540)
            width, height = size

            def __init__(self, varied=False, solid=30):
                self.varied, self.solid = varied, solid

            def getpixel(self, point):
                x, y = point
                return (100 + x % 120, 100 + y % 120, 180) if self.varied else (self.solid,) * 3

        before, after = Pixels(), Pixels(varied=True)
        result = probe.face_pixel_change(before, after, self.layout, self.face_layout, 0)
        self.assertEqual(result['samples'], 63)
        with self.assertRaisesRegex(RuntimeError, 'no verified face change'):
            probe.face_pixel_change(before, before, self.layout, self.layout, 0)
        with self.assertRaisesRegex(RuntimeError, 'Flat/blank'):
            probe.face_pixel_change(before, Pixels(solid=220), self.layout, self.face_layout, 0)

    def test_requested_page_waits_before_capturing_old_page(self):
        p = self.bare_probe(); p.deadline = probe.time.monotonic() + 60
        old = deepcopy(self.layout); old['page_size'] = 4
        # This is a synthetic transport case using real geometry; it is not
        # evidence that the desktop fixture ran on an Android device.
        old['observation_source'] = 'android_window_insets'
        new = deepcopy(old); new['page'] = 1
        for i, row in enumerate(old['cards']):
            row['visible'] = i < 4
        for i, row in enumerate(new['cards']):
            row['visible'] = i >= 4
        p.raw = mock.Mock(side_effect=[(old, 'old'), (new, 'new'), (new, 'new')])
        p.foreground = mock.Mock(); p.pid = mock.Mock(return_value=self.layout['pid'])
        p.state = mock.Mock(return_value=self.state)
        p.probe = SimpleNamespace(capture=mock.Mock(return_value={'file': 'actual.png'}))
        picture = mock.MagicMock(); picture.__enter__.return_value.size = (960, 540)
        image = SimpleNamespace(open=mock.Mock(return_value=picture))
        with mock.patch.dict(sys.modules, {'PIL': SimpleNamespace(Image=image)}), \
                mock.patch.object(probe.time, 'sleep'):
            observed = p.snapshot('page', expected_page=1)
        self.assertEqual(observed['layout']['page'], 1)
        self.assertEqual(p.probe.capture.call_count, 1)
        self.assertEqual(p.state.call_count, 2)

    def test_nonfinite_and_duplicate_json_fail_closed(self):
        for raw in ('{"x":NaN}', '{"x":1,"x":2}'):
            with self.assertRaises(RuntimeError):
                probe.parse_json(raw)


if __name__ == '__main__':
    unittest.main()
