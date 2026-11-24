"""Fail-closed SAF reader contracts. Fixtures are never real Android evidence."""
import base64
from copy import deepcopy
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[3]
PATH = ROOT / '.github/probes/lumo_local_backup_android_probe.py'
STUB = SimpleNamespace(base=SimpleNamespace(adb=Mock()),
    live=SimpleNamespace(live_nodes=Mock()), PACKAGE='dev.lumo.fixture',
    capture=Mock(return_value={'file': 'synthetic-reader-contract.png'}),
    prefs=Mock())
spec = importlib.util.spec_from_file_location('local_backup_probe_contract', PATH)
PROBE = importlib.util.module_from_spec(spec)
with patch.dict(sys.modules, {'creative_android_probe': STUB,
        'modernization_android_tour': SimpleNamespace(verify_apk_identity=Mock())}):
    spec.loader.exec_module(PROBE)

DOCS = 'com.android.documentsui'
FILENAME = 'Lumo-Sicherung-2026-11-22-2359.json'


def encoded(body):
    payload = json.dumps(body, ensure_ascii=False, separators=(',', ':'))
    return json.dumps({'format': 'lumo-local-backup', 'version': 1,
        'createdAt': '2026-11-22T23:59:10.123456Z', 'payload': payload,
        'sha256': hashlib.sha256(payload.encode()).hexdigest()}).encode()


def body():
    native = b'[race]\ntrack="sonnenhafen"\n\n'
    prefs = {PROBE.PROFILE: json.dumps({'id': 'fixture', 'name': 'LumoTest'}),
             PROBE.WALLET: json.dumps({'stars': 7, 'xp': 20, 'gameResultIds': ['paid']}),
             PROBE.SETTINGS: json.dumps({'reduceAnimations': False}),
             'lumo_learning_local_student_id_v1': 'local-fixture'}
    return {'preferences': {key: {'type': 'string', 'value': value}
                            for key, value in prefs.items()},
        'nativeFiles': [{'path': 'kart_sonnenhafen_session.cfg', 'bytes': len(native),
            'sha256': hashlib.sha256(native).hexdigest(),
            'data': base64.b64encode(native).decode()}]}


def node(text, *, package=DOCS, clickable='true', area='[10,20][210,80]', cls='android.widget.Button'):
    return ET.Element('node', {'text': text, 'content-desc': '', 'package': package,
        'enabled': 'true', 'clickable': clickable, 'bounds': area, 'class': cls})


def activities(current='CREATE_DOCUMENT', stale='OPEN_DOCUMENT'):
    return f'''topResumedActivity=ActivityRecord{{a12 u0 {DOCS}/.picker.PickActivity t10}}
    * Hist  #0: ActivityRecord{{a12 u0 {DOCS}/.picker.PickActivity t10}}
      Intent {{ act=android.intent.action.{current} typ=application/json cmp={DOCS}/.picker.PickActivity }}
    * Hist #1: ActivityRecord{{b34 u0 {DOCS}/.picker.PickActivity t9}}
      Intent {{ act=android.intent.action.{stale} typ=application/json cmp={DOCS}/.picker.PickActivity }}
'''


class BackupArchiveContracts(unittest.TestCase):
    def test_world_mission_save_is_preserved_in_the_portable_archive(self):
        changed = body()
        path = 'lumo_world_0123456789abcdef0123456789abcdef.json'
        world = b'{"version":1,"completed":["school"]}'
        changed['nativeFiles'].append({
            'path': path, 'bytes': len(world),
            'sha256': hashlib.sha256(world).hexdigest(),
            'data': base64.b64encode(world).decode(),
        })
        archive = PROBE.validate_archive(encoded(changed))
        self.assertEqual(archive['nativeFiles'][path], world)

    def test_real_format_hashes_utf8_payload_and_preserves_exact_native_bytes(self):
        archive = PROBE.validate_archive(encoded(body()))
        self.assertEqual(archive['nativeFiles']['kart_sonnenhafen_session.cfg'],
                         b'[race]\ntrack="sonnenhafen"\n\n')
        physical = {'flutter.' + key: value for key, value in archive['preferences'].items()}
        result = PROBE.verify_preferences(archive, physical)
        self.assertEqual(result['profile']['name'], 'LumoTest')
        self.assertIs(result['reduceAnimations'], False)

    def test_payload_checksum_and_native_checksum_are_independent_required_checks(self):
        outer = json.loads(encoded(body()))
        outer['payload'] += ' '
        with self.assertRaisesRegex(ValueError, 'payload checksum'):
            PROBE.validate_archive(json.dumps(outer).encode())
        changed = body()
        changed['nativeFiles'][0]['sha256'] = '0' * 64
        with self.assertRaisesRegex(ValueError, 'Native file checksum'):
            PROBE.validate_archive(encoded(changed))
        changed = body()
        changed['nativeFiles'][0]['bytes'] -= 1
        with self.assertRaisesRegex(ValueError, 'Native file checksum'):
            PROBE.validate_archive(encoded(changed))

    def test_wrong_version_duplicate_keys_invalid_types_and_no_kart_fail(self):
        raw = encoded(body())
        outer = json.loads(raw)
        outer['version'] = True
        with self.assertRaises(ValueError):
            PROBE.validate_archive(json.dumps(outer).encode())
        with self.assertRaisesRegex(ValueError, 'Duplicate'):
            PROBE.strict_json('{"version":1,"version":1}')
        changed = body()
        changed['preferences']['lumo_bad'] = {'type': 'int', 'value': True}
        with self.assertRaisesRegex(ValueError, 'Wrong preference type'):
            PROBE.validate_archive(encoded(changed))
        changed['preferences'].pop('lumo_bad')
        changed['nativeFiles'] = []
        with self.assertRaisesRegex(ValueError, 'no exported Kart save'):
            PROBE.validate_archive(encoded(changed))

    def test_native_paths_and_duplicate_entries_fail_closed(self):
        for path in ('../profile.cfg', '/settings.cfg', 'kart_geister/../a.json',
                     'kart_geister/x/y.json', 'kart_a.cfg\x00', 'preferences.xml'):
            with self.subTest(path=path):
                changed = body()
                changed['nativeFiles'][0]['path'] = path
                with self.assertRaises(ValueError):
                    PROBE.validate_archive(encoded(changed))
        changed = body()
        changed['nativeFiles'].append(deepcopy(changed['nativeFiles'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate native'):
            PROBE.validate_archive(encoded(changed))

    def test_profile_wallet_and_setting_must_really_match_export(self):
        archive = PROBE.validate_archive(encoded(body()))
        physical = {'flutter.' + key: value for key, value in archive['preferences'].items()}
        for key, replacement in ((PROBE.PROFILE, {'id': 'other', 'name': 'LumoTest'}),
                (PROBE.WALLET, {'stars': 8}), (PROBE.SETTINGS, {'reduceAnimations': True})):
            with self.subTest(key=key), self.assertRaises(ValueError):
                PROBE.verify_preferences(archive, {**physical, 'flutter.' + key: json.dumps(replacement)})
        del physical['flutter.' + PROBE.SETTINGS]
        with self.assertRaisesRegex(ValueError, 'Missing persisted JSON'):
            PROBE.verify_preferences(archive, physical)

    def test_only_wallet_proven_event_ack_and_navigation_removal_are_allowed(self):
        paid, pending = {'resultId': 'paid', 'stars': 6}, {'resultId': 'pending', 'stars': 2}
        before = {'results': [paid, pending], 'destination': 'games', 'callerReturnSession': 'session'}
        wallet = {'gameResultIds': ['paid']}
        check = lambda new: PROBE.event_ack_only(json.dumps(before), json.dumps(new), wallet)
        self.assertTrue(check({'results': [pending]}))
        self.assertFalse(check({'results': []}))
        self.assertFalse(check({'results': [pending, {'resultId': 'new'}]}))
        self.assertFalse(check({'results': [pending], 'destination': 'learn'}))
        self.assertFalse(check({'results': [pending], 'destination': 'games'}))
        self.assertFalse(check({'results': [pending], 'unproven': True}))

    def test_export_navigation_normalization_never_allows_added_routes_after_restore(self):
        expected = b'{"results":[]}'
        native = b'{"results":[],"destination":"games","callerReturnSession":"old-session"}'
        self.assertEqual(PROBE.native_comparison('lumo_game_events.json', expected,
            native, {}, exporting=True), 'export-navigation-normalized-and-proven-acks')
        with self.assertRaisesRegex(ValueError, 'Unproven native event'):
            PROBE.native_comparison('lumo_game_events.json', expected, native, {})
        with self.assertRaisesRegex(ValueError, 'Native save differs'):
            PROBE.native_comparison('kart_a.cfg', expected, native, {}, exporting=True)

    def test_native_owner_mapping_and_salt_must_survive_restore(self):
        archive = PROBE.validate_archive(encoded(body()))
        archive['preferences'].update(lumo_3d_save_salt_v1='owner-salt',
            lumo_3d_profile_keys_v1='{"version":1,"owners":{}}')
        physical = {'flutter.' + key: value for key, value in archive['preferences'].items()}
        PROBE.verify_preferences(archive, physical)
        for key in ('lumo_3d_save_salt_v1', 'lumo_3d_profile_keys_v1'):
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, 'Profile ownership'):
                PROBE.verify_preferences(archive, {**physical, 'flutter.' + key: 'changed'})

    def test_remote_read_does_not_strip_newlines_or_mix_stderr_into_archive(self):
        data = b' [cfg]\n\n'
        with patch.object(PROBE.subprocess, 'run', return_value=SimpleNamespace(stdout=data)) as run:
            self.assertEqual(PROBE.remote_bytes('/sdcard/Download/' + FILENAME), data)
        self.assertEqual(run.call_args.args[0][:3], ['adb', 'exec-out', 'cat'])
        self.assertTrue(run.call_args.kwargs['check'])
        self.assertEqual(run.call_args.kwargs['stderr'], subprocess_pipe())


def subprocess_pipe():
    return PROBE.subprocess.PIPE


class DocumentsUiContracts(unittest.TestCase):
    def test_downloads_child_uses_its_real_clickable_ancestor(self):
        row = node('', area='[0,100][300,180]')
        title = node('Downloads', clickable='false', area='[60,110][200,160]', cls='android.widget.TextView')
        row.append(title)
        toolbar = node('Downloads', clickable='false', area='[0,0][300,80]')
        self.assertIs(PROBE.native_target([row, title, toolbar], DOCS, ['Downloads']), row)

    def test_foreign_or_ambiguous_or_disabled_native_controls_cannot_be_tapped(self):
        foreign = node('Save', package='unrelated.app')
        self.assertIsNone(PROBE.native_target([foreign], DOCS, ['Save']))
        a, b = node('Save'), node('SAVE', area='[210,20][400,80]')
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            PROBE.native_target([a, b], DOCS, ['Save'])
        a.set('enabled', 'false')
        b.set('bounds', '[10,20][10,80]')
        self.assertIsNone(PROBE.native_target([a, b], DOCS, ['Save']))

    def test_suggested_name_is_read_from_unique_current_edittext(self):
        field = node(FILENAME, cls='android.widget.EditText')
        self.assertEqual(PROBE.suggested_filename([field], DOCS), FILENAME)
        with self.assertRaises(RuntimeError):
            PROBE.suggested_filename([field, deepcopy(field)], DOCS)
        field.set('text', '../' + FILENAME)
        with self.assertRaises(RuntimeError):
            PROBE.suggested_filename([field], DOCS)


    def test_systemui_tree_is_reobserved_until_the_actual_picker_field_exists(self):
        for package in ('com.android.documentsui', 'com.google.android.documentsui'):
            with self.subTest(package=package):
                # The observed failure had only SystemUI after the SAF intent
                # was already resumed; a later tree contained this real field.
                initial = [node('11:00', package='com.android.systemui',
                                cls='android.widget.TextView')]
                field = node(FILENAME, package=package, cls='android.widget.EditText')
                field.set('resource-id', 'android:id/title')
                with patch.object(PROBE.live, 'live_nodes',
                        side_effect=[initial, [field]]) as read, \
                     patch.object(PROBE.time, 'sleep') as sleep, \
                     patch.object(PROBE.base, 'adb') as adb:
                    self.assertEqual(
                        PROBE.wait_suggested_filename(Path('.'), package, 'suggested'),
                        FILENAME,
                    )
                    self.assertEqual(read.call_count, 2)
                    self.assertEqual(
                        [call.args for call in read.call_args_list],
                        [(Path('.'), 'suggested-0'), (Path('.'), 'suggested-1')],
                    )
                    sleep.assert_called_once_with(.5)
                    adb.assert_not_called()

    def test_incomplete_picker_field_must_become_nonempty_enabled_visible_and_sized(self):
        for attributes in (
                {'text': ''}, {'enabled': 'false'},
                {'visible-to-user': 'false'}, {'bounds': '[10,20][10,80]'}):
            with self.subTest(attributes=attributes):
                ready = node(FILENAME, cls='android.widget.EditText')
                incomplete = deepcopy(ready)
                incomplete.attrib.update(attributes)
                with patch.object(PROBE.live, 'live_nodes',
                        side_effect=[[incomplete], [ready]]) as read, \
                     patch.object(PROBE.time, 'sleep') as sleep:
                    self.assertEqual(
                        PROBE.wait_suggested_filename(Path('.'), DOCS, 'ready'),
                        FILENAME,
                    )
                    self.assertEqual(read.call_count, 2)
                    sleep.assert_called_once_with(.5)

    def test_filename_readiness_is_bounded_and_never_invents_a_value(self):
        foreign = node(FILENAME, package='com.android.systemui',
                       cls='android.widget.EditText')
        with patch.object(PROBE.live, 'live_nodes', return_value=[foreign]) as read, \
             patch.object(PROBE.time, 'sleep') as sleep, \
             patch.object(PROBE.base, 'adb') as adb:
            with self.assertRaisesRegex(TimeoutError, 'did not become ready'):
                PROBE.wait_suggested_filename(Path('.'), DOCS, 'missing')
            self.assertEqual(read.call_count, 25)
            self.assertEqual(sleep.call_count, 24)
            self.assertEqual(read.call_args.args, (Path('.'), 'missing-24'))
            adb.assert_not_called()

    def test_wrong_nonempty_names_fail_immediately_instead_of_waiting_for_a_valid_one(self):
        for wrong in ('../' + FILENAME, FILENAME + '.json', 'Lumo-Sicherung-', 'notes.json'):
            with self.subTest(wrong=wrong):
                invalid = node(wrong, cls='android.widget.EditText')
                valid = node(FILENAME, cls='android.widget.EditText')
                with patch.object(PROBE.live, 'live_nodes',
                        side_effect=[[invalid], [valid]]) as read, \
                     patch.object(PROBE.time, 'sleep') as sleep:
                    with self.assertRaisesRegex(RuntimeError, 'Exactly one'):
                        PROBE.wait_suggested_filename(Path('.'), DOCS, 'wrong')
                    read.assert_called_once()
                    sleep.assert_not_called()

    def test_multiple_fields_fail_immediately_even_if_one_is_not_yet_ready(self):
        for duplicate_ready in (True, False):
            with self.subTest(duplicate_ready=duplicate_ready):
                field = node(FILENAME, cls='android.widget.EditText')
                duplicate = deepcopy(field)
                if not duplicate_ready:
                    duplicate.set('text', '')
                    duplicate.set('enabled', 'false')
                with patch.object(PROBE.live, 'live_nodes',
                        side_effect=[[field, duplicate], [field]]) as read, \
                     patch.object(PROBE.time, 'sleep') as sleep:
                    with self.assertRaisesRegex(RuntimeError, 'Exactly one'):
                        PROBE.wait_suggested_filename(Path('.'), DOCS, 'ambiguous')
                    read.assert_called_once()
                    sleep.assert_not_called()

    def test_ready_filename_returns_the_observed_value_without_extra_reads(self):
        filename = 'Lumo-Sicherung-2026-11-23-1058.json'
        field = node(filename, cls='android.widget.EditText')
        with patch.object(PROBE.live, 'live_nodes', return_value=[field]) as read, \
             patch.object(PROBE.time, 'sleep') as sleep:
            self.assertEqual(
                PROBE.wait_suggested_filename(Path('.'), DOCS, 'current'),
                filename,
            )
            read.assert_called_once_with(Path('.'), 'current-0')
            sleep.assert_not_called()

    def test_saf_intent_must_belong_to_current_resumed_activity(self):
        self.assertEqual(PROBE.picker_identity(activities(), 'CREATE_DOCUMENT')['activity_token'], 'a12')
        with self.assertRaisesRegex(RuntimeError, 'expected JSON SAF intent'):
            PROBE.picker_identity(activities(current='OPEN_DOCUMENT', stale='CREATE_DOCUMENT'), 'CREATE_DOCUMENT')
        with self.assertRaises(RuntimeError):
            PROBE.picker_identity(activities().replace('typ=application/json', 'typ=text/plain'), 'CREATE_DOCUMENT')

    def test_touch_rereads_bounds_and_never_uses_changed_old_coordinates(self):
        before, current = node('Save'), node('Save', area='[300,100][500,200]')
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(PROBE.live, 'live_nodes', side_effect=[[before], [current], [current], [current]]), \
                patch.object(PROBE.base, 'adb') as adb, patch.object(PROBE.time, 'sleep'):
            PROBE.tap_native(Path(folder), DOCS, ['Save'], 'save')
            adb.assert_called_once_with('shell', 'input', 'tap', '400', '150')

    def test_missing_first_settings_write_is_polled_not_inferred_as_false(self):
        current = {'flutter.' + PROBE.SETTINGS: json.dumps({'reduceAnimations': False})}
        with patch.object(PROBE.probe, 'prefs', side_effect=[{}, current]), \
                patch.object(PROBE.time, 'sleep'):
            self.assertEqual(PROBE.wait_setting(Path('.'), False, 'test'), current)

    def test_identity_failure_produces_nonzero_fail_report_not_a_partial_pass(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(PROBE, 'verify_apk_identity', side_effect=RuntimeError('wrong candidate')), \
                patch.object(PROBE.live, 'live_nodes', return_value=[]), \
                patch.object(sys, 'argv', ['probe', '--apk', 'candidate.apk',
                    '--provenance', 'source.json', '--sums', 'SHA256SUMS', '--out', folder]):
            self.assertEqual(PROBE.main(), 1)
            report = json.loads((Path(folder) / 'backup-result.json').read_text())
            self.assertEqual(report['status'], 'FAIL')
            self.assertEqual(report['steps'], [{'step': 'apk-identity', 'ok': False, 'error': 'wrong candidate'}])


if __name__ == '__main__':
    unittest.main()

