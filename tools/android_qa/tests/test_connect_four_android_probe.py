"""Pure contracts; never installs, launches or represents an Android device."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch
import warnings
import zipfile

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    'connect_four_android_probe', ROOT / '.github/probes/lumo_connect_four_android_probe.py')
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)
FIXTURE = Path(__file__).parent / 'fixtures/connect_four_android/phone-playing.layout.json'


def fixture():
    return json.loads(FIXTURE.read_text())


def state_with(columns):
    state = fixture()
    state['columns'] = list(columns)
    state.update(PROBE.replay(list(columns)))
    state['canDrop'] = state['phase'] == 'playing' and state['turn'] == 1
    return state


def layout_with(columns):
    layout = state_with(columns)
    for cell in layout['cells']:
        cell['piece'] = layout['board'][cell['row'] * 7 + cell['column']]
    return layout


def checked(layout, state=None, image_size=(1080, 2400)):
    return PROBE.check_layout(layout, state or layout, image_size,
                              layout['density'], layout['pid'], allow_fixture=True)


class LegalStateContracts(unittest.TestCase):
    def test_actual_renderer_sidecar_is_unchanged_and_projects_all_42_cells(self):
        self.assertEqual(hashlib.sha256(FIXTURE.read_bytes()).hexdigest(),
                         '6bc6ec736379fae23fa641543704017a3514036c66de2d2c5e2badd436d867ff')
        result = checked(fixture())
        self.assertEqual(len(result['cells']), 42)
        self.assertGreaterEqual(min(min(x['size_dp']) for x in result['visible_targets']), 48)

    def test_gravity_turns_and_full_column_are_reconstructed_independently(self):
        result = PROBE.replay([3, 3, 3, 3, 3, 3])
        self.assertEqual([result['board'][r * 7 + 3] for r in range(6)], [2, 1, 2, 1, 2, 1])
        self.assertEqual(result['turn'], 1)
        self.assertNotIn(3, result['validColumns'])
        with self.assertRaisesRegex(RuntimeError, 'full column'):
            PROBE.replay([3] * 7)

    def test_terminal_win_cannot_accept_another_move(self):
        moves = [0, 6, 1, 6, 2, 5, 3]
        result = PROBE.replay(moves)
        self.assertEqual(result['phase'], 'won')
        self.assertEqual(result['winningLine'], [[5, 0], [5, 1], [5, 2], [5, 3]])
        with self.assertRaisesRegex(RuntimeError, 'terminal'):
            PROBE.replay(moves + [4])

    def test_owner_history_and_illegal_permissions_are_rejected(self):
        state = state_with([3, 2])
        PROBE.check_state(state, state['owner'])
        with self.assertRaisesRegex(RuntimeError, 'another child'):
            PROBE.check_state(state, 'b' * 64)
        for field, value in (('board', [0] * 42), ('paused', True), ('rewarded', True)):
            bad = copy.deepcopy(state)
            bad[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                PROBE.check_state(bad)

    def test_boolean_coordinates_and_nonfinite_or_duplicate_json_fail(self):
        for text in ('{"revision":1,"revision":2}', '{"x":NaN}', '{"x":Infinity}'):
            with self.subTest(text=text), self.assertRaises(RuntimeError):
                PROBE.parse_json(text)
        with self.assertRaises(RuntimeError):
            PROBE.replay([True])
        state = fixture()
        state['board'][0] = False
        with self.assertRaisesRegex(RuntimeError, 'public board'):
            PROBE.check_state(state)

    def test_drop_requires_actual_ack_child_and_bot_history(self):
        before = fixture()
        request = {'token': before['token'], 'roundId': before['roundId'],
                   'revision': before['revision'], 'sequence': 1, 'action': 'drop', 'column': 3}
        after = state_with([3, 2])
        after.update(ack=1, revision=before['revision'] + 2, recordRevision=3)
        self.assertEqual(PROBE.check_drop(before, request, after, 3)['bot_column'], 2)
        variants = []
        rejected = copy.deepcopy(after); rejected['rejected'] = 1; variants.append(rejected)
        no_bot = state_with([3]); no_bot.update(ack=1, revision=4); variants.append(no_bot)
        different = copy.deepcopy(after); different['roundId'] = 'b' * 32; variants.append(different)
        for value in variants:
            with self.subTest(columns=value['columns']), self.assertRaises(RuntimeError):
                PROBE.check_drop(before, request, value, 3)
        stale = dict(request, revision=before['revision'] - 1)
        with self.assertRaisesRegex(RuntimeError, 'intended current drop'):
            PROBE.check_drop(before, stale, after, 3)

    def test_saved_round_owner_revision_and_history_must_match(self):
        state = state_with([3, 2])
        saved = {'schema': 1, 'owner': state['owner'], 'id': state['roundId'],
                 'revision': state['recordRevision'], 'columns': state['columns'],
                 'twoPlayers': False, 'level': 'mittel', 'rewarded': False}
        saved['level'] = state['level']
        PROBE.check_saved(saved, state)
        for field, value in (('owner', 'f' * 64), ('revision', 99), ('columns', [3, 1])):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                PROBE.check_saved(dict(saved, **{field: value}), state)


class GeometryAndTouchContracts(unittest.TestCase):
    def test_platform_fixture_is_never_an_actual_android_observation(self):
        layout = fixture()
        with self.assertRaisesRegex(RuntimeError, 'actual Android'):
            PROBE.check_layout(layout, layout, (1080, 2400), 2.625, layout['pid'])

    def test_real_desktop_one_pixel_difference_is_not_silently_accepted(self):
        with self.assertRaisesRegex(RuntimeError, 'Screenshot/decor size'):
            checked(fixture(), image_size=(1079, 2400))

    def test_inset_overlap_must_come_from_actual_render_geometry(self):
        layout = fixture()
        layout['android_observation']['insets'][1] = 32
        with self.assertRaisesRegex(RuntimeError, 'real|overlap'):
            checked(layout)
        layout = fixture()
        layout['safe_rect'][1] = 32
        with self.assertRaisesRegex(RuntimeError, 'Safe layout'):
            checked(layout)

    def test_already_padded_view_is_not_double_inset(self):
        layout = fixture()
        obs = layout['android_observation']
        obs['view_size'] = [1080, 2201]
        obs['render_rect'] = [0, 136, 1080, 2201]
        obs['insets'] = [0, 0, 0, 0]
        layout['safe_rect'] = [0, 0, 1080, 2400]
        # A smaller native viewport changes decor target sizes. Restrict this
        # synthetic transform case to a 160px-high header target. Keeping the
        # original 136.54px height here correctly falls below 48dp after the
        # additional view/window scaling; that is not an inset-parser defect.
        for button in layout['buttons']:
            button['enabled'] = button['id'] == 'back'
            if button['id'] == 'back':
                button['rect_px'][3] = button['hit_rect_px'][3] = 160
        result = checked(layout)
        self.assertEqual(result['safe_rect'], [0, 0, 1080, 2400])
        self.assertEqual(PROBE.to_decor(layout, [0, 0]), [0, 136])
        self.assertEqual(PROBE.to_decor(layout, [1080, 2400]), [1080, 2337])

    def test_stale_state_pending_or_hidden_surface_cannot_supply_coordinates(self):
        for field, value in (('revision', 77), ('settled', False), ('pending', 1),
                             ('ui_visible', False), ('owner', 'b' * 64)):
            original = fixture(); altered = copy.deepcopy(original); altered[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                checked(altered, original)

    def test_fake_centers_quads_and_world_geometry_fail_independent_projection(self):
        for field, value in (('center_px', [1, 1]), ('disc_quad', [[1, 1]] * 4),
                             ('world_center', [0, 0, 0])):
            layout = fixture(); layout['cells'][0][field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                checked(layout)

    def test_duplicate_missing_cells_and_invalid_camera_rejected(self):
        layouts = []
        a = fixture(); a['cells'][1] = copy.deepcopy(a['cells'][0]); layouts.append(a)
        b = fixture(); b['cells'].pop(); layouts.append(b)
        c = fixture(); c['camera']['basis'][0][0] = 5; layouts.append(c)
        for layout in layouts:
            with self.assertRaises(RuntimeError):
                checked(layout)

    def test_hidden_clipped_and_small_exposed_touch_targets_are_rejected(self):
        layout = fixture()
        target = PROBE.button_target(layout, 'back', 2.625)
        self.assertGreaterEqual(min(target['size_dp']), 48)
        for field, value in (('visible', False), ('enabled', False), ('clipped', True),
                             ('hit_rect_px', [60, 180, 125, 125])):
            altered = fixture(); button = next(x for x in altered['buttons'] if x['id'] == 'back')
            button[field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                PROBE.button_target(altered, 'back', 2.625)

    def test_system_bar_touch_and_ambiguous_button_are_rejected(self):
        layout = fixture(); button = next(x for x in layout['buttons'] if x['id'] == 'back')
        button['rect_px'] = button['hit_rect_px'] = [0, 0, 180, 180]
        with self.assertRaisesRegex(RuntimeError, 'safe view'):
            PROBE.button_target(layout, 'back', 2.625)
        layout = fixture(); layout['buttons'].append(copy.deepcopy(layout['buttons'][0]))
        with self.assertRaisesRegex(RuntimeError, 'ambiguous'):
            PROBE.button_target(layout, 'back', 2.625)

    def test_synthetic_disc_pixels_have_to_match_both_sides_and_real_projection(self):
        layout = layout_with([3, 2]); geometry = checked(layout)
        image = Image.new('RGB', (1080, 2400), '#123555')
        draw = ImageDraw.Draw(image)
        for cell in geometry['cells']:
            if cell['piece']:
                x, y = cell['center']
                draw.ellipse((x-32, y-32, x+32, y+32),
                             fill='#53ddfd' if cell['piece'] == 1 else '#ffd166')
        self.assertEqual(len(PROBE.check_pixels(image, layout, geometry)), 2)
        with self.assertRaisesRegex(RuntimeError, 'disc pixels absent'):
            PROBE.check_pixels(Image.new('RGB', image.size, '#123555'), layout, geometry)
        with self.assertRaisesRegex(RuntimeError, 'disc pixels absent'):
            PROBE.check_pixels(Image.new('RGB', image.size, '#ffd166'), layout, geometry)


class ReadOnlyAndIdentityContracts(unittest.TestCase):
    def test_private_reads_are_an_exact_observation_allowlist(self):
        self.assertTrue(PROBE.allowed_read(PROBE.LAYOUT))
        for name in ('state', 'request', 'lifecycle'):
            self.assertTrue(PROBE.allowed_read(PROBE.SESSION + 'a' * 32 + '/' + name + '.json'))
        for path in ('/data/user/0/another/files/state.json', PROBE.SESSION + '../state.json',
                     PROBE.SESSION + 'a' * 32 + '/save.json', PROBE.LAYOUT + '.tmp'):
            self.assertFalse(PROBE.allowed_read(path))

    def test_actual_read_retains_raw_bytes_and_serial_without_writing_device(self):
        with tempfile.TemporaryDirectory() as temp:
            instance = object.__new__(PROBE.AndroidProbe)
            instance.out = Path(temp); instance.count = 0
            instance.args = SimpleNamespace(serial='emulator-5554')
            raw = b'{"schema":1,"example":"synthetic boundary response"}'
            reply = SimpleNamespace(returncode=0, stdout=raw, stderr=b'')
            with patch.object(PROBE.subprocess, 'run', return_value=reply) as call:
                value, digest = instance.raw(PROBE.LAYOUT, 'read')
            self.assertEqual(value['schema'], 1)
            self.assertEqual(digest, hashlib.sha256(raw).hexdigest())
            self.assertEqual((Path(temp) / '0001-read.raw').read_bytes(), raw)
            self.assertEqual(call.call_args.args[0],
                             ['adb', '-s', 'emulator-5554', 'exec-out', 'cat', PROBE.LAYOUT])
            self.assertEqual(json.loads((Path(temp) / '0001-read-read.json').read_text())['returncode'], 0)

    def test_partial_or_failed_read_is_saved_but_not_accepted(self):
        with tempfile.TemporaryDirectory() as temp:
            instance = object.__new__(PROBE.AndroidProbe)
            instance.out = Path(temp); instance.count = 0
            instance.args = SimpleNamespace(serial='emulator-5554')
            for response in (SimpleNamespace(returncode=0, stdout=b'{"schema":', stderr=b''),
                             SimpleNamespace(returncode=1, stdout=b'', stderr=b'permission denied')):
                with patch.object(PROBE.subprocess, 'run', return_value=response), self.assertRaises(Exception):
                    instance.raw(PROBE.LAYOUT, 'invalid')
            self.assertEqual(len(list(Path(temp).glob('*.raw'))), 2)

    def test_target_change_after_capture_cannot_send_a_touch(self):
        with tempfile.TemporaryDirectory() as temp:
            instance = object.__new__(PROBE.AndroidProbe)
            instance.out = Path(temp); instance.density = 2.625; instance.events = []
            instance.raw = lambda *args: (fixture(), 'new-layout-digest')
            instance.foreground = lambda: None
            instance.adb = unittest.mock.Mock()
            observation = {'layout': fixture(), 'layout_sha256': 'old-layout-digest', 'capture': {}}
            with self.assertRaisesRegex(RuntimeError, 'Target changed'):
                instance.touch(observation, 'back')
            instance.adb.assert_not_called()

    def test_current_target_generates_only_one_real_touch_command(self):
        with tempfile.TemporaryDirectory() as temp:
            instance = object.__new__(PROBE.AndroidProbe)
            instance.out = Path(temp); instance.density = 2.625; instance.events = []
            instance.raw = lambda *args: (fixture(), 'stable')
            instance.foreground = lambda: None; instance.adb = unittest.mock.Mock()
            observation = {'layout': fixture(), 'layout_sha256': 'stable', 'capture': {'file': 'synthetic.png'}}
            instance.touch(observation, 'back')
            self.assertEqual(instance.adb.call_count, 1)
            self.assertEqual(instance.adb.call_args.args[:3], ('shell', 'input', 'tap'))
            self.assertEqual(len(json.loads((Path(temp) / 'input-events.json').read_text())), 1)

    def test_real_archive_member_is_hashed_and_wrong_pck_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = Path(temp) / 'synthetic.zip'
            payload = b'synthetic unit bytes, not an Android APK'
            with zipfile.ZipFile(archive, 'w') as z:
                z.writestr('assets/lumo_game.pck', payload)
            expected = hashlib.sha256(payload).hexdigest()
            self.assertEqual(PROBE.verified_pck(archive, expected), expected)
            with self.assertRaisesRegex(RuntimeError, 'PCK differs'):
                PROBE.verified_pck(archive, '0' * 64)

    def test_duplicate_or_wrong_embedded_pack_cannot_bind_a_candidate(self):
        with tempfile.TemporaryDirectory() as temp:
            archive = Path(temp) / 'synthetic.zip'; payload = b'test'
            for names in (['assets/wrong.pck'], [PROBE.PCK_PATH, PROBE.PCK_PATH]):
                with zipfile.ZipFile(archive, 'w') as z, warnings.catch_warnings():
                    warnings.simplefilter('ignore', UserWarning)
                    for name in names:
                        z.writestr(name, payload)
                with self.assertRaisesRegex(RuntimeError, 'absent/ambiguous'):
                    PROBE.verified_pck(archive, hashlib.sha256(payload).hexdigest())

    def test_preexisting_result_cannot_be_overwritten_by_failure_reporting(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); result = root / 'result.json'; original = b'{"historical":"unchanged"}'
            result.write_bytes(original)
            args = []
            for name in ('candidate-source', 'native-source', 'apk', 'provenance', 'sums', 'tour-result', 'out'):
                args += ['--' + name, str(root)]
            args += ['--expected-source', 'a' * 40, '--expected-native', 'b' * 40,
                     '--serial', 'emulator-5554', '--expected-api', '37']
            with patch.object(PROBE, 'AndroidProbe') as constructor:
                self.assertEqual(PROBE.main(args), 2)
                constructor.assert_not_called()
            self.assertEqual(result.read_bytes(), original)


class DeadlineReadbackContracts(unittest.TestCase):
    def test_slow_last_observation_cannot_pass_after_unchanged_wait_deadline(self):
        with tempfile.TemporaryDirectory() as temp:
            instance = object.__new__(PROBE.AndroidProbe)
            instance.out = Path(temp); instance.count = 0
            clock = [0.0]
            def late_observation():
                clock[0] = 46.0
                return {'synthetic': 'otherwise acceptable observation'}
            with patch.object(PROBE.time, 'monotonic', side_effect=lambda: clock[0]), \
                    patch.object(PROBE.time, 'sleep'), self.assertRaises(RuntimeError):
                instance.wait('deadline-bound state', late_observation, lambda value: True, timeout=45)
            self.assertTrue(list(Path(temp).glob('*-failure.json')))

    def test_late_post_capture_state_read_cannot_publish_successful_snapshot(self):
        with tempfile.TemporaryDirectory() as temp:
            instance = object.__new__(PROBE.AndroidProbe)
            instance.out = Path(temp); instance.count = 0; instance.density = 2.625
            clock = [0.0]; calls = [0]
            layout = fixture(); layout['observation_source'] = 'android_window_insets'
            path = Path(temp) / 'synthetic-deadline.png'
            Image.new('RGB', (1080, 2400), '#123555').save(path)
            instance.probe = SimpleNamespace(capture=lambda *args, **kwargs: {'file': path.name})
            instance.foreground = lambda: None
            instance.pid = lambda: layout['pid']
            instance.raw = lambda *args: (layout, 'unchanged synthetic readback hash')
            def read_state(_token):
                calls[0] += 1
                if calls[0] == 2:
                    clock[0] = 46.0
                return layout
            instance.state = read_state
            with patch.object(PROBE.time, 'monotonic', side_effect=lambda: clock[0]), \
                    patch.object(PROBE.time, 'sleep'), self.assertRaises(RuntimeError):
                instance.snapshot('deadline-snapshot')
            self.assertEqual(list(Path(temp).glob('*-observation.json')), [])
            self.assertTrue(list(Path(temp).glob('*-rejected.json')))


if __name__ == '__main__':
    unittest.main()
