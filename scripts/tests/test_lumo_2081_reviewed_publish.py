"""Publication safety tests use synthetic metadata; they perform no network writes."""
from copy import deepcopy
from contextlib import redirect_stderr
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

from test_lumo_team_b_reviewed_publish import android_evidence, metadata

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location('reviewed2081', SCRIPTS / 'lumo_2081_reviewed_publish.py')
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)


def order():
    result = dict(publisher.FIXED)
    result.update({key: index + 1 for index, key in enumerate(sorted(publisher.INTEGER_FIELDS))})
    result.update({key: 'a' * 64 for key in publisher.HASH_FIELDS})
    return result


def evidence(request):
    repository = {'full_name': publisher.REPOSITORY, 'id': 1222433959, 'private': False}
    jobs = []
    for field, name in publisher.JOB_NAMES.items():
        names = publisher.BUILD_STEPS if field == 'build_job_id' else publisher.ANDROID_STEPS
        jobs.append({'id': request[field], 'name': name, 'run_id': publisher.RUN,
                     'head_sha': publisher.SOURCE, 'status': 'completed', 'conclusion': 'success',
                     'steps': [{'name': step, 'status': 'completed', 'conclusion': 'success'}
                               for step in sorted(names)]})
    artifacts = {}
    for label, prefix in (('apk', 'LUMO-TEST-APK'), ('android', 'LUMO-ANDROID-TOUR')):
        artifacts[label] = {
            'id': request[label + '_artifact_id'], 'name': f'{prefix}-{publisher.RUN}', 'expired': False,
            'size_in_bytes': request[label + '_artifact_bytes'],
            'digest': 'sha256:' + request[label + '_artifact_sha256'],
            'workflow_run': {'id': publisher.RUN, 'head_sha': publisher.SOURCE,
                             'head_branch': publisher.SOURCE_BRANCH,
                             'repository_id': 1222433959, 'head_repository_id': 1222433959}}
    return {
        'run': {'id': publisher.RUN, 'head_sha': publisher.SOURCE, 'head_branch': publisher.SOURCE_BRANCH,
                'event': 'push', 'path': '.github/workflows/lumo-abschluss-apk.yml',
                'run_attempt': request['build_run_attempt'], 'status': 'completed', 'conclusion': 'success',
                'repository': repository, 'head_repository': repository},
        'jobs': {'total_count': 2, 'jobs': jobs}, 'artifacts': artifacts}


def release_fixture(draft):
    owner = {'login': 'Ullmann27', 'id': 64243701}
    assets = {publisher.APK: {'bytes': 19, 'sha256': 'b' * 64}}
    release = {
        'tag_name': publisher.TAG, 'draft': draft, 'prerelease': True, 'author': owner,
        'html_url': f'https://github.com/{publisher.REPOSITORY}/releases/tag/{publisher.TAG}',
        'assets': [{'name': publisher.APK, 'uploader': owner, 'size': 19, 'state': 'uploaded',
                    'digest': 'sha256:' + 'b' * 64,
                    'browser_download_url': f'https://github.com/{publisher.REPOSITORY}/releases/download/{publisher.TAG}/{publisher.APK}'}]}
    ref = {'ref': 'refs/tags/' + publisher.TAG,
           'object': {'type': 'commit', 'sha': publisher.SOURCE}}
    return release, ref, assets


class OrderTests(unittest.TestCase):
    def test_accepts_only_exact_known_source_version_and_shape(self):
        request = order()
        self.assertIs(publisher.validate_order(request), request)
        for key, value in [('flutter_commit', 'f' * 40), ('version_code', 2080),
                           ('publisher_user_id', 1), ('repository', 'other/repo')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                publisher.validate_order({**request, key: value})
        with self.assertRaises(ValueError):
            publisher.validate_order({**request, 'extra': True})

    def test_rejects_boolean_ids_reused_ids_and_malformed_digests(self):
        request = order()
        for changes in ({'build_job_id': True}, {'apk_bytes': 0},
                        {'android_job_id': request['build_job_id']},
                        {'android_artifact_id': request['apk_artifact_id']},
                        {'apk_sha256': 'A' * 64}, {'pck_sha256': '../elsewhere'}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                publisher.validate_order({**request, **changes})


class SourceGateTests(unittest.TestCase):
    def test_accepts_complete_source_bound_success(self):
        request = order()
        publisher.verify_api(request, evidence(request))

    def test_rejects_cancelled_failed_wrong_commit_and_incomplete_jobs(self):
        request = order()
        modifications = [
            lambda e: e['run'].update(conclusion='cancelled'),
            lambda e: e['run'].update(head_sha='0' * 40),
            lambda e: e['jobs']['jobs'][0].update(conclusion='failure'),
            lambda e: e['jobs'].update(total_count=3),
            lambda e: e['jobs']['jobs'].pop(),
            lambda e: e['jobs']['jobs'][0]['steps'][0].update(conclusion='skipped'),
            lambda e: e['jobs']['jobs'][0]['steps'].pop(),
        ]
        for change in modifications:
            sample = evidence(request)
            change(sample)
            with self.assertRaises(ValueError):
                publisher.verify_api(request, sample)

    def test_rejects_other_artifact_run_expiry_size_or_digest(self):
        request = order()
        modifications = [
            lambda a: a.update(expired=True),
            lambda a: a.update(size_in_bytes=123456),
            lambda a: a.update(digest='sha256:' + 'c' * 64),
            lambda a: a['workflow_run'].update(head_sha='c' * 40),
            lambda a: a['workflow_run'].update(repository_id=1),
        ]
        for change in modifications:
            sample = evidence(request)
            change(sample['artifacts']['apk'])
            with self.assertRaises(ValueError):
                publisher.verify_api(request, sample)


class AndroidPackageSchemaTests(unittest.TestCase):
    def reports(self):
        request = order()
        tour, backup, native, gate = android_evidence(request)
        # Shape captured from the original 2081 emulator artifact. This remains
        # a unit-test fixture, never substituted for runtime publication proof.
        tour['installed_package'] = {
            'userId': '10209', 'firstInstallTime': '2026-11-24 17:45:08',
            'versionCode': '2081 minSdk=24 targetSdk=36', 'versionName': '0.14.8',
        }
        return request, metadata(request)[2], [tour, backup, native, gate,
            'package:' + publisher.PACKAGE + ' uid:10209']

    def test_accepts_actual_package_manager_shape_without_rewriting_reports(self):
        request, split, reports = self.reports()
        original = deepcopy(reports)
        publisher.verify_android(request, split, *reports)
        self.assertEqual(reports, original)

    def test_rejects_old_string_shape_and_wrong_installed_version_or_sdks(self):
        changes = [
            lambda r: r[0].update(installed_package=publisher.PACKAGE),
            lambda r: r[0].update(installed_package=None),
            lambda r: r[0]['installed_package'].update(versionCode='2080 minSdk=24 targetSdk=36'),
            lambda r: r[0]['installed_package'].update(versionCode='2081 minSdk=24 targetSdk=35'),
            lambda r: r[0]['installed_package'].update(versionCode=2081),
            lambda r: r[0]['installed_package'].update(versionName='0.14.7'),
            lambda r: r[0]['installed_package'].pop('userId'),
        ]
        for change in changes:
            request, split, reports = self.reports()
            change(reports)
            with self.assertRaises(ValueError):
                publisher.verify_android(request, split, *reports)

    def test_rejects_wrong_package_uid_and_non_package_manager_captures(self):
        for output in ('package:other.package uid:10209',
                       'package:' + publisher.PACKAGE + ' uid:10210',
                       'package:' + publisher.PACKAGE + ' uid:-1', '',
                       'package:' + publisher.PACKAGE + ' uid:10209\npackage:other uid:10210'):
            request, split, reports = self.reports()
            reports[-1] = output
            with self.subTest(output=output), self.assertRaises(ValueError):
                publisher.verify_android(request, split, *reports)

    def test_package_record_does_not_bypass_source_backup_or_native_gates(self):
        changes = [
            lambda r: r[0].update(apk_sha256='0' * 64),
            lambda r: r[0].update(fatal_crashes=1),
            lambda r: next(s for s in r[0]['steps'] if s['step'] == 'apk-identity').update(
                flutter_source_commit='0' * 40),
            lambda r: next(s for s in r[0]['steps'] if s['step'] == 'apk-identity').update(
                signingCertificateSha256='0' * 64),
            lambda r: r[1].update(status='FAIL'),
            lambda r: r[1]['installed_after'].update(sha256='0' * 64),
            lambda r: next(s for s in r[1]['steps'] if s['step'] == 'restore-and-preservation').update(ok=False),
            lambda r: r[2].update(package='other.package'),
            lambda r: r[2]['scenes'].pop(),
            lambda r: r[2]['scenes'][0]['issues'].update(fatal_signal=1),
        ]
        for change in changes:
            request, split, reports = self.reports()
            change(reports)
            with self.assertRaises(ValueError):
                publisher.verify_android(request, split, *reports)


class ReleaseTests(unittest.TestCase):
    def test_draft_and_public_release_require_exact_owner_tag_and_asset_digest(self):
        for draft in (True, False):
            release, ref, assets = release_fixture(draft)
            publisher.verify_release(release, ref, assets, draft)
            for change in (lambda r: r['assets'][0].pop('digest'),
                           lambda r: r['assets'][0].update(size=20),
                           lambda r: r['author'].update(id=1),
                           lambda r: r['assets'].append(deepcopy(r['assets'][0]))):
                modified = deepcopy(release)
                change(modified)
                with self.assertRaises(ValueError):
                    publisher.verify_release(modified, ref, assets, draft)
            ref['object']['sha'] = '0' * 40
            with self.assertRaises(ValueError):
                publisher.verify_release(release, ref, assets, draft)

    def test_draft_download_url_is_not_confused_with_final_public_url(self):
        release, ref, assets = release_fixture(True)
        release['assets'][0]['browser_download_url'] = 'https://github.com/temporary-draft-url'
        publisher.verify_release(release, ref, assets, True)
        release['draft'] = False
        with self.assertRaises(ValueError):
            publisher.verify_release(release, ref, assets, False)

    def test_missing_publisher_token_never_uses_read_token(self):
        with patch.dict(os.environ, {'GH_TOKEN': 'synthetic-read', 'LUMO_SOURCE_READ_TOKEN': 'synthetic-read'}, clear=True), \
                patch.object(publisher, 'github_json') as fetch, \
                patch.object(publisher, 'publisher_cli') as write, self.assertRaises(ValueError):
            publisher.publish(order())
        fetch.assert_not_called()
        write.assert_not_called()


class ClientTests(unittest.TestCase):
    def test_failed_cli_records_only_allowlisted_cause_status_and_exit(self):
        for reason, message in (
                ('workflow_scope', 'refusing workflow update without workflow scope (HTTP 403)'),
                ('permission', 'Resource not accessible by personal access token (HTTP 403)'),
                ('rate_limit', 'API rate limit exceeded (HTTP 403)'),
                ('authentication', 'Bad credentials (HTTP 401)'),
                ('command_error', 'unrecognized response')):
            with self.subTest(reason=reason), tempfile.TemporaryDirectory() as folder, \
                    patch.object(publisher, 'ROOT', Path(folder)), \
                    patch.object(publisher, 'CURRENT_PHASE', 'create-tag'), \
                    patch.object(publisher.subprocess, 'run', return_value=subprocess.CompletedProcess(
                        [], 1, 'sensitive-stdout', message + '\nAuthorization: sensitive-token')), \
                    redirect_stderr(io.StringIO()) as captured:
                with self.assertRaises(publisher.PublicationOperationError) as raised:
                    publisher.publisher_cli('sensitive-token', ['api', '--method', 'POST', 'repos/test'])
                report = publisher.report_failure(raised.exception)
                self.assertEqual(report['phase'], 'create-tag')
                self.assertEqual(report['reason'], reason)
                self.assertEqual(report['exit_code'], 1)
                saved = (Path(folder) / 'proof/PUBLICATION-FAILURE.json').read_text()
                for secret in ('sensitive-token', 'sensitive-stdout', 'Authorization', message):
                    self.assertNotIn(secret, saved + captured.getvalue())

    def test_http_error_body_and_unexpected_exception_message_are_not_disclosed(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(publisher, 'ROOT', Path(folder)), \
                patch.object(publisher, 'CURRENT_PHASE', 'publisher-identity'), \
                patch.object(publisher.API_OPENER, 'open', side_effect=HTTPError(
                    'https://api.github.com/sensitive-url', 401, 'sensitive-reason', {},
                    io.BytesIO(b'Bad credentials sensitive-token'))), \
                redirect_stderr(io.StringIO()) as captured:
            with self.assertRaises(publisher.PublicationOperationError) as raised:
                publisher.github_json('user', 'sensitive-token')
            report = publisher.report_failure(raised.exception)
            self.assertEqual(report['http_status'], 401)
            self.assertEqual(report['reason'], 'authentication')
            publisher.report_failure(ValueError('sensitive-exception-message'))
            saved = (Path(folder) / 'proof/PUBLICATION-FAILURE.json').read_text()
            self.assertNotIn('sensitive', saved + captured.getvalue())

    def test_diagnostics_do_not_retry_commands_or_use_another_credential(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(publisher, 'ROOT', Path(folder)), \
                patch.object(publisher.subprocess, 'run', side_effect=subprocess.TimeoutExpired(
                    ['sensitive-command'], 900)) as run:
            with self.assertRaises(publisher.PublicationOperationError) as raised:
                publisher.publisher_cli('synthetic-publisher', ['api'])
            self.assertEqual(raised.exception.reason, 'timeout')
            self.assertEqual(run.call_count, 1)
            self.assertEqual(run.call_args.kwargs['env']['GH_TOKEN'], 'synthetic-publisher')

    def test_existing_release_or_tag_still_stops_before_any_write(self):
        for existing in ('releases/tags/', 'git/ref/tags/'):
            with self.subTest(existing=existing), tempfile.TemporaryDirectory() as folder, \
                    patch.object(publisher, 'ROOT', Path(folder)), \
                    patch.dict(os.environ, {'LUMO_RELEASE_PUBLISH_TOKEN': 'synthetic-publisher',
                                          'LUMO_SOURCE_READ_TOKEN': 'synthetic-reader'}, clear=True), \
                    patch.object(publisher, 'observe_api'), \
                    patch.object(publisher, 'publisher_cli') as write:
                request = order()
                content = b'Unit-test APK fixture, not delivery evidence'
                request.update(apk_bytes=len(content), apk_sha256=hashlib.sha256(content).hexdigest())
                release = Path(folder) / 'release'
                release.mkdir()
                (release / publisher.APK).write_bytes(content)
                publisher.save(Path(folder) / 'proof/PREPUBLICATION-VERIFICATION.json', {
                    'status': 'PASS', 'order': request,
                    'assets': {publisher.APK: {'bytes': len(content), 'sha256': request['apk_sha256']}}})
                owner = {'login': 'Ullmann27', 'id': 64243701}
                def observed(path, token, **kwargs):
                    if path == 'user':
                        return owner
                    if path == 'repos/' + publisher.REPOSITORY:
                        return {'full_name': publisher.REPOSITORY, 'private': False, 'owner': owner}
                    return {'id': 123} if existing in path else None
                with patch.object(publisher, 'github_json', side_effect=observed), \
                        self.assertRaises(ValueError):
                    publisher.publish(request)
                write.assert_not_called()

    def test_only_observed_404_is_absence_no_redirect_or_permission_fallback(self):
        for status in (302, 403, 500):
            with patch.object(publisher.API_OPENER, 'open', side_effect=HTTPError('https://api.github.com', status, '', {}, None)) as opening:
                with self.assertRaises(ValueError):
                    publisher.github_json('repos/' + publisher.REPOSITORY + '/releases/tags/x', 'synthetic', absent_ok=True)
                self.assertEqual(opening.call_count, 1)
        with patch.object(publisher.API_OPENER, 'open', side_effect=HTTPError('https://api.github.com', 404, '', {}, None)):
            self.assertIsNone(publisher.github_json('repos/' + publisher.REPOSITORY + '/releases/tags/x', 'synthetic', absent_ok=True))

    def test_other_repository_path_is_rejected_before_io(self):
        with patch.object(publisher.API_OPENER, 'open') as opening, self.assertRaises(ValueError):
            publisher.github_json('repos/other/repo', 'synthetic')
        opening.assert_not_called()

    def test_publisher_cli_isolated_from_other_hosts_proxies_and_read_tokens(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(publisher, 'ROOT', Path(folder)), \
                patch.dict(os.environ, {'GH_HOST': 'example.invalid', 'GH_TOKEN': 'synthetic-read',
                    'HTTPS_PROXY': 'https://example.invalid', 'LUMO_SOURCE_READ_TOKEN': 'synthetic-read',
                    'LUMO_RELEASE_PUBLISH_TOKEN': 'synthetic-publisher'}, clear=True), \
                patch.object(publisher.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, '{}', '')) as run:
            publisher.publisher_cli('synthetic-publisher', ['api', '--method', 'POST', 'repos/' + publisher.REPOSITORY + '/git/refs', '--input', '-'], {'x': 1})
            environment = run.call_args.kwargs['env']
            self.assertEqual(environment['GH_HOST'], 'github.com')
            self.assertEqual(environment['GH_TOKEN'], 'synthetic-publisher')
            self.assertNotIn('HTTPS_PROXY', environment)
            self.assertNotIn('LUMO_SOURCE_READ_TOKEN', environment)
            self.assertNotIn('LUMO_RELEASE_PUBLISH_TOKEN', environment)
            self.assertIn('--input', run.call_args.args[0])


if __name__ == '__main__':
    unittest.main()
