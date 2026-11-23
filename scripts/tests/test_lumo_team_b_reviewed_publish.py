"""Local gate tests only; fixtures are never Android or publication evidence."""
import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.request import Request
import zipfile


SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location('team_b_reviewed_publish', SCRIPTS / 'lumo_team_b_reviewed_publish.py')
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


def request():
    return {**publisher.EXPECTED, 'build_run_attempt': 1, 'build_job_id': 100,
            'android_job_id': 101, 'android_artifact_id': 102,
            'publisher_login': 'approved-user', 'publisher_user_id': 103}


def api_evidence(order):
    repository = {'id': 200, 'full_name': order['repository'], 'private': False}
    run = {'id': order['build_run_id'], 'head_sha': order['flutter_commit'],
           'head_branch': order['branch'], 'event': 'push', 'path': publisher.WORKFLOW,
           'run_attempt': 1, 'status': 'completed', 'conclusion': 'failure',
           'repository': repository, 'head_repository': repository.copy()}
    jobs = [{'id': order[key], 'run_id': order['build_run_id'], 'head_sha': order['flutter_commit'],
             'name': name, 'status': 'completed', 'conclusion': 'success'}
            for key, name in publisher.JOB_NAMES.items()]
    artifacts = {}
    for field, prefix in [('apk_artifact_id', 'LUMO-WORLD-APK'),
                          ('metadata_artifact_id', 'LUMO-WORLD-METADATA'),
                          ('android_artifact_id', 'LUMO-ANDROID-TOUR')]:
        artifacts[field] = {'id': order[field], 'name': f'{prefix}-{order["build_run_id"]}',
            'expired': False, 'workflow_run': {'id': order['build_run_id'],
            'head_sha': order['flutter_commit'], 'head_branch': order['branch'],
            'repository_id': 200, 'head_repository_id': 200}}
    return {'run': run, 'jobs': {'total_count': len(jobs), 'jobs': jobs}, 'artifacts': artifacts}


def metadata(order):
    godot = {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
             'revision': order['godot_commit'], 'engine': '4.6.3',
             'pck_sha256': order['pck_sha256'], 'bytes': order['pck_bytes']}
    proof = {'package': publisher.PACKAGE, 'versionCode': order['version_code'],
        'versionName': order['version_name'], 'abis': ['arm64-v8a'],
        'bytes': order['apk_bytes'], 'sha256': order['apk_sha256'],
        'signingCertificateSha256': order['certificate_sha256'],
        'elf16KiBAligned': True, 'resourcesArscAligned': True, 'godot': godot,
        'flutter_source_commit': order['flutter_commit'], 'tracked_source_clean': True}
    packages = {abi: {'abi': abi, 'sha256': order['apk_sha256'] if abi == 'arm64-v8a' else '2' * 64,
        'bytes': order['apk_bytes'], 'signingCertificateSha256': order['certificate_sha256'],
        'godot_pck_sha256': order['pck_sha256'], 'godot_pck_bytes': order['pck_bytes']}
        for abi in ('arm64-v8a', 'x86_64')}
    split = {'flutter_source_commit': order['flutter_commit'], 'versionName': order['version_name'],
             'versionCode': order['version_code'], 'same_pck': True, 'packages': packages,
             'godot': {key: godot[key] for key in ('repository', 'revision', 'engine')}}
    return proof, copy.deepcopy(proof), split


def android_evidence(order):
    identity = {'apk_sha256': '2' * 64, 'flutter_source_commit': order['flutter_commit'],
        'godot_revision': order['godot_commit'], 'godot_pck_sha256': order['pck_sha256'],
        'versionName': order['version_name'], 'versionCode': order['version_code'],
        'signingCertificateSha256': order['certificate_sha256'],
        'checks': {key: True for key in publisher.IDENTITY_CHECKS}}
    tour = {'status': 'PASS', 'apk_sha256': '2' * 64, 'installed_package': publisher.PACKAGE,
            'fatal_crashes': 0, 'steps': [{'step': name, 'ok': True}
                                       for name in publisher.TOUR_STEPS]}
    next(row for row in tour['steps'] if row['step'] == 'apk-identity').update(identity)
    backup = {'status': 'PASS', 'identity': copy.deepcopy(identity),
              'installed': {'sha256': '2' * 64}, 'installed_after': {'sha256': '2' * 64},
              'steps': [{'step': name, 'ok': True} for name in publisher.BACKUP_STEPS]}
    next(row for row in backup['steps'] if row['step'] == 'apk-identity')['installed_sha256'] = '2' * 64
    native = {'status': 'DONE', 'package': publisher.PACKAGE, 'scenes': []}
    for name in ('run', 'quiz', 'memory', 'chess', 'kart', 'cards', 'world'):
        native['scenes'].append({'id': name, 'scene': name, 'path': 'ui', 'tapped': True,
            'router_loaded': True, 'game_process_alive_at_end': True, 'app_alive_at_end': True,
            'native_pid_at_end': 321, 'native_process_name': publisher.PACKAGE + ':lumo_game',
            'process_snapshot_at_end': {publisher.PACKAGE: 123, publisher.PACKAGE + ':lumo_game': 321},
            'router_loaded_pid': 321, 'router_loaded_line': f'11-23 12:00:00 321 400 I Godot: [Router] loaded:{name} live',
            'issues': {key: 0 for key in ('script_error', 'fatal', 'android_runtime', 'fatal_signal',
                                        'boot_load_error', 'process_died')}})
    return tour, backup, native, publisher.verify_native_starts(native)


class TeamBReviewedPublishTests(unittest.TestCase):
    def setUp(self):
        self.order = request()

    def test_complete_order_is_specific_to_original_candidate(self):
        self.assertEqual(publisher.validate_request(self.order), self.order)
        for field in publisher.EXPECTED:
            changed = copy.deepcopy(self.order)
            changed[field] = 'different' if not isinstance(changed[field], int) else changed[field] + 1
            with self.subTest(field=field), self.assertRaises(ValueError):
                publisher.validate_request(changed)

    def test_order_rejects_missing_unknown_or_boolean_identity(self):
        for change in ({'extra': True}, {'android_artifact_id': True}, {'publisher_login': 'bad\nlogin'}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                publisher.validate_request({**self.order, **change})
        del self.order['android_artifact_id']
        with self.assertRaises(ValueError):
            publisher.validate_request(self.order)

    def test_duplicate_json_fields_fail_closed(self):
        with self.assertRaises(ValueError):
            publisher.decode('{"schema":1,"schema":2}')

    def test_failed_old_publish_does_not_invalidate_successful_build_and_android(self):
        publisher.verify_api(self.order, api_evidence(self.order))

    def test_wrong_pending_or_retried_run_is_rejected(self):
        for field, value in [('head_sha', '0' * 40), ('status', 'in_progress'), ('run_attempt', 2)]:
            evidence = api_evidence(self.order)
            evidence['run'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                publisher.verify_api(self.order, evidence)

    def test_private_repository_cannot_be_claimed_as_public_delivery(self):
        evidence = api_evidence(self.order)
        evidence['run']['repository']['private'] = True
        with self.assertRaises(ValueError):
            publisher.verify_api(self.order, evidence)

    def test_failed_or_unbound_job_is_rejected(self):
        for field, value in [('conclusion', 'failure'), ('id', 999), ('head_sha', '0' * 40)]:
            evidence = api_evidence(self.order)
            evidence['jobs']['jobs'][1][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                publisher.verify_api(self.order, evidence)

    def test_same_named_artifact_from_another_run_or_fork_is_rejected(self):
        for field, value in [('id', 999), ('head_repository_id', 999), ('head_sha', '0' * 40)]:
            evidence = api_evidence(self.order)
            evidence['artifacts']['android_artifact_id']['workflow_run'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                publisher.verify_api(self.order, evidence)

    def test_expired_or_different_artifact_id_is_rejected(self):
        for field, value in [('expired', True), ('id', 999), ('name', 'newer-APK')]:
            evidence = api_evidence(self.order)
            evidence['artifacts']['apk_artifact_id'][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                publisher.verify_api(self.order, evidence)

    def test_original_metadata_and_split_are_accepted(self):
        publisher.verify_metadata(self.order, *metadata(self.order))

    def test_changed_certificate_pck_or_arm64_hash_is_rejected(self):
        for field in ('signingCertificateSha256', 'godot_pck_sha256', 'sha256'):
            docs = metadata(self.order)
            docs[2]['packages']['arm64-v8a'][field] = '0' * 64
            with self.subTest(field=field), self.assertRaises(ValueError):
                publisher.verify_metadata(self.order, *docs)
        docs = metadata(self.order)
        docs[2]['packages']['x86_64']['godot_pck_sha256'] = '0' * 64
        with self.assertRaises(ValueError):
            publisher.verify_metadata(self.order, *docs)

    def test_full_tour_backup_and_real_world_start_are_required(self):
        publisher.verify_android(self.order, metadata(self.order)[2], *android_evidence(self.order))

    def test_pass_label_cannot_hide_failed_or_missing_backup_step(self):
        for mode in ('missing', 'failed', 'duplicate'):
            docs = android_evidence(self.order)
            row = next(row for row in docs[1]['steps'] if row['step'] == 'restore-and-preservation')
            if mode == 'missing':
                docs[1]['steps'].remove(row)
            elif mode == 'failed':
                row['ok'] = False
            else:
                docs[1]['steps'].append(row.copy())
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                publisher.verify_android(self.order, metadata(self.order)[2], *docs)

    def test_tour_for_another_apk_cannot_be_reused(self):
        docs = android_evidence(self.order)
        docs[0]['apk_sha256'] = '0' * 64
        with self.assertRaises(ValueError):
            publisher.verify_android(self.order, metadata(self.order)[2], *docs)

    def test_post_backup_installed_apk_must_match(self):
        docs = android_evidence(self.order)
        docs[1]['installed_after']['sha256'] = '0' * 64
        with self.assertRaises(ValueError):
            publisher.verify_android(self.order, metadata(self.order)[2], *docs)

    def test_precomputed_pass_cannot_replace_world_observation(self):
        docs = android_evidence(self.order)
        docs[2]['scenes'][-1]['skipped'] = True
        with self.assertRaises(ValueError):
            publisher.verify_android(self.order, metadata(self.order)[2], *docs)

    def test_archived_evidence_must_equal_the_checked_files(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            original = root / 'report.json'
            original.write_text('{"status":"PASS"}')
            with zipfile.ZipFile(root / 'evidence.zip', 'w') as archive:
                archive.writestr('tour/report.json', '{"status":"FAIL"}')
            with self.assertRaises(ValueError):
                publisher.archive_matches(root / 'evidence.zip', {'tour/report.json': original})

    def test_builtin_token_is_never_a_publisher_fallback(self):
        with patch.dict('os.environ', {'GITHUB_TOKEN': 'insufficient', 'GH_TOKEN': 'insufficient'}, clear=True), \
             patch.object(publisher, 'github_json') as api, \
             patch.object(publisher.subprocess, 'run') as process, self.assertRaises(ValueError):
            publisher.publish(self.order)
        api.assert_not_called()
        process.assert_not_called()

    def test_wrong_publisher_identity_stops_before_any_write(self):
        with patch.dict('os.environ', {'LUMO_RELEASE_PUBLISH_TOKEN': 'unit-test-only'}, clear=True), \
             patch.object(publisher, 'github_json', return_value={'login': 'someone-else', 'id': 999}), \
             patch.object(publisher.subprocess, 'run') as process, self.assertRaises(ValueError):
            publisher.publish(self.order)
        process.assert_not_called()

    def publication_fixture(self, root):
        paths = publisher.release_files(self.order)
        for path in paths:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(b'unit-test asset ' + path.name.encode())
        publisher.save(root / 'proof/PREPUBLICATION-VERIFICATION.json', {
            'status': 'PASS', 'request': self.order,
            'assets': {str(path): {'bytes': path.stat().st_size, 'sha256': publisher.digest(path)}
                       for path in paths}})

    def test_existing_release_or_tag_never_reaches_create(self):
        for existing in ('release', 'tag'):
            with tempfile.TemporaryDirectory() as folder, patch.object(publisher, 'ROOT', Path(folder)), \
                 patch.dict('os.environ', {'LUMO_RELEASE_PUBLISH_TOKEN': 'unit-test-only'}, clear=True):
                self.publication_fixture(Path(folder))
                replies = [{'login': self.order['publisher_login'], 'id': self.order['publisher_user_id']}]
                replies += [{'id': 777}] if existing == 'release' else [None, {'ref': 'existing-tag'}]
                with patch.object(publisher, 'github_json', side_effect=replies), \
                     patch.object(publisher.subprocess, 'run') as process, \
                     self.subTest(existing=existing), self.assertRaises(ValueError):
                    publisher.publish(self.order)
                process.assert_not_called()

    def test_asset_changed_after_verification_stops_before_create(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(publisher, 'ROOT', Path(folder)), \
             patch.dict('os.environ', {'LUMO_RELEASE_PUBLISH_TOKEN': 'unit-test-only'}, clear=True):
            self.publication_fixture(Path(folder))
            publisher.release_files(self.order)[0].write_bytes(b'changed bytes')
            with patch.object(publisher, 'github_json', return_value={
                    'login': self.order['publisher_login'], 'id': self.order['publisher_user_id']}), \
                 patch.object(publisher.subprocess, 'run') as process, self.assertRaises(ValueError):
                publisher.publish(self.order)
            process.assert_not_called()

    def test_public_download_has_no_auth_or_cookie_header(self):
        payload = b'fixture-apk-bytes'
        response = io.BytesIO(payload)
        response.status = 200
        opener = Mock()
        opener.open.return_value = response
        with tempfile.TemporaryDirectory() as folder, patch.object(publisher, 'build_opener', return_value=opener):
            publisher.anonymous_download('https://github.com/example.apk', Path(folder) / 'apk',
                                         len(payload), hashlib.sha256(payload).hexdigest())
        sent = opener.open.call_args.args[0]
        self.assertNotIn('Authorization', sent.headers)
        self.assertNotIn('Cookie', sent.headers)

    def test_public_download_checks_actual_size_and_sha(self):
        for size, sha in [(1, '0' * 64), (8, '0' * 64), (9, '0' * 64)]:
            response = io.BytesIO(b'contents')
            response.status = 200
            opener = Mock()
            opener.open.return_value = response
            with tempfile.TemporaryDirectory() as folder, \
                 patch.object(publisher, 'build_opener', return_value=opener), \
                 self.subTest(size=size), self.assertRaises(ValueError):
                publisher.anonymous_download('https://github.com/example.apk', Path(folder) / 'apk', size, sha)

    def test_public_download_rejects_http_redirect(self):
        with self.assertRaises(ValueError):
            publisher.HttpsRedirects().redirect_request(Request('https://github.com/example.apk'),
                None, 302, '', {}, 'http://example.com/file.apk')


if __name__ == '__main__':
    unittest.main()
