"""Publication safety tests use synthetic metadata; they perform no network writes."""
from copy import deepcopy
from contextlib import redirect_stderr
import hashlib
import importlib.util
import io
import json
import stat
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import zipfile
from unittest.mock import Mock, patch
from urllib.error import HTTPError

from scripts.tests.test_lumo_team_b_reviewed_publish import android_evidence, metadata

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location('reviewed2082', SCRIPTS / 'lumo_2082_reviewed_publish.py')
publisher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(publisher)



def repository_fixture():
    return {'full_name': publisher.REPOSITORY, 'id': publisher.REPOSITORY_ID,
            'private': False, 'owner': {'login': 'Ullmann27', 'id': publisher.OWNER_ID, 'type': 'User'}}


def publisher_environment(job='publish'):
    return {
        'GITHUB_ACTIONS': 'true', 'GITHUB_REPOSITORY': publisher.REPOSITORY,
        'GITHUB_REPOSITORY_ID': str(publisher.REPOSITORY_ID),
        'GITHUB_REPOSITORY_OWNER': 'Ullmann27', 'GITHUB_REPOSITORY_OWNER_ID': str(publisher.OWNER_ID),
        'GITHUB_REF': 'refs/heads/' + publisher.PUBLISHER_BRANCH,
        'GITHUB_EVENT_NAME': 'push', 'GITHUB_SERVER_URL': 'https://github.com',
        'GITHUB_API_URL': 'https://api.github.com',
        'GITHUB_WORKFLOW_REF': publisher.REPOSITORY + '/' + publisher.PUBLISHER_WORKFLOW
                               + '@refs/heads/' + publisher.PUBLISHER_BRANCH,
        'GITHUB_SHA': 'c' * 40, 'GITHUB_WORKFLOW_SHA': 'c' * 40,
        'GITHUB_RUN_ID': '1000', 'GITHUB_RUN_ATTEMPT': '1', 'GITHUB_JOB': job,
        'GITHUB_TOKEN': 'synthetic-workflow-token',
    }


def current_run():
    ctx = publisher.context()
    return {
        'id': ctx['publisher_run_id'], 'run_attempt': ctx['publisher_run_attempt'],
        'head_sha': ctx['publisher_commit'], 'head_branch': publisher.PUBLISHER_BRANCH,
        'event': 'push', 'path': publisher.PUBLISHER_WORKFLOW, 'status': 'in_progress',
        'repository': repository_fixture(), 'head_repository': repository_fixture(),
    }


def local_payload(folder, request):
    content = b'Unit-test APK fixture, not delivery evidence'
    request.update(apk_bytes=len(content), apk_sha256=hashlib.sha256(content).hexdigest())
    release = Path(folder) / 'release'
    release.mkdir()
    (release / publisher.APK).write_bytes(content)
    (release / 'LIESMICH.md').write_text('Synthetic test release, not an acceptance claim.')
    assets = {path.name: {'bytes': path.stat().st_size, 'sha256': publisher.digest(path)}
              for path in release.iterdir()}
    publisher.save(Path(folder) / 'proof/PREPUBLICATION-VERIFICATION.json', {
        'status': 'PASS', 'order': request, 'assets': assets})
    publisher.save(Path(folder) / 'proof/PUBLISHER-CONTEXT.json', publisher.context())
    publisher.save(Path(folder) / 'proof/STAGE-ARTIFACT-VERIFICATION.json', {
        'publisher': publisher.context(),
        'manifest_sha256': publisher.digest(Path(folder) / 'proof/PREPUBLICATION-VERIFICATION.json')})
    return assets


def publication_reads(path, token, **kwargs):
    if path == 'repos/' + publisher.REPOSITORY:
        return repository_fixture()
    if '/actions/runs/' in path:
        return current_run()
    return None


def order():
    result = dict(publisher.FIXED)
    result.update({key: index + 1 for index, key in enumerate(sorted(publisher.INTEGER_FIELDS))})
    result.update({key: 'a' * 64 for key in publisher.HASH_FIELDS})
    result.update(flutter_commit='a' * 40, godot_commit='b' * 40)
    result['release_tag'] = f'lumo-{result["version_name"]}-{result["version_code"]}-{result["build_run_id"]}'
    return result


def evidence(request):
    repository = repository_fixture()
    jobs = []
    for field, name in publisher.JOB_NAMES.items():
        names = {'intelligence_job_id': publisher.INTELLIGENCE_STEPS,
                 'build_job_id': publisher.BUILD_STEPS, 'android_job_id': publisher.ANDROID_STEPS}[field]
        jobs.append({'id': request[field], 'name': name, 'run_id': request['build_run_id'],
                     'head_sha': request['flutter_commit'], 'status': 'completed', 'conclusion': 'success',
                     'steps': [{'name': step, 'status': 'completed', 'conclusion': 'success'}
                               for step in sorted(names)]})
    artifacts = {}
    for label, prefix in publisher.ARTIFACT_PREFIXES.items():
        artifacts[label] = {
            'id': request[label + '_artifact_id'], 'name': f'{prefix}-{request["build_run_id"]}', 'expired': False,
            'size_in_bytes': request[label + '_artifact_bytes'],
            'digest': 'sha256:' + request[label + '_artifact_sha256'],
            'workflow_run': {'id': request['build_run_id'], 'head_sha': request['flutter_commit'],
                             'head_branch': publisher.SOURCE_BRANCH,
                             'repository_id': 1222433959, 'head_repository_id': 1222433959}}
    return {
        'run': {'id': request['build_run_id'], 'head_sha': request['flutter_commit'], 'head_branch': publisher.SOURCE_BRANCH,
                'event': 'push', 'path': publisher.SOURCE_WORKFLOW,
                'run_attempt': request['build_run_attempt'], 'status': 'completed', 'conclusion': 'success',
                'repository': repository, 'head_repository': repository},
        'jobs': {'total_count': 3, 'jobs': jobs}, 'artifacts': artifacts}


def release_fixture(draft, request=None):
    request = request or order()
    owner = {'login': 'github-actions[bot]', 'id': 41898282, 'type': 'Bot'}
    assets = {publisher.APK: {'bytes': 19, 'sha256': 'b' * 64}}
    release = {
        'id': 101, 'target_commitish': request['flutter_commit'],
        'tag_name': request['release_tag'], 'draft': draft, 'prerelease': True, 'author': owner,
        'html_url': f'https://github.com/{publisher.REPOSITORY}/releases/tag/{request["release_tag"]}',
        'assets': [{'id': 102, 'name': publisher.APK, 'uploader': owner, 'size': 19, 'state': 'uploaded',
                    'digest': 'sha256:' + 'b' * 64,
                    'browser_download_url': f'https://github.com/{publisher.REPOSITORY}/releases/download/{request["release_tag"]}/{publisher.APK}'}]}
    ref = {'ref': 'refs/tags/' + request['release_tag'],
           'object': {'type': 'commit', 'sha': request['flutter_commit']}}
    return release, ref, assets


class OrderTests(unittest.TestCase):
    def test_accepts_only_checked_version_and_complete_order_shape(self):
        request = order()
        self.assertIs(publisher.validate_order(request), request)
        for key, value in [('flutter_commit', 'f' * 39), ('version_code', 2080),
                           ('publisher_authentication', 'personal-token'), ('repository', 'other/repo')]:
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
            lambda e: e['jobs'].update(total_count=2),
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
        # Existing PackageManager schema, with synthetic 2082 values below.
        # This fixture is never substituted for runtime publication evidence.
        tour['installed_package'] = {
            'userId': '10209', 'firstInstallTime': '2026-11-24 17:45:08',
            'versionCode': '2082 minSdk=24 targetSdk=36', 'versionName': '0.14.9',
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
            lambda r: r[0]['installed_package'].update(versionCode='2082 minSdk=24 targetSdk=35'),
            lambda r: r[0]['installed_package'].update(versionCode=2082),
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
            publisher.verify_release(order(), release, ref, assets, draft)
            for change in (lambda r: r['assets'][0].pop('digest'),
                           lambda r: r['assets'][0].update(size=20),
                           lambda r: r['author'].update(id=1),
                           lambda r: r['assets'].append(deepcopy(r['assets'][0]))):
                modified = deepcopy(release)
                change(modified)
                with self.assertRaises(ValueError):
                    publisher.verify_release(order(), modified, ref, assets, draft)
            ref['object']['sha'] = '0' * 40
            with self.assertRaises(ValueError):
                publisher.verify_release(order(), release, ref, assets, draft)

    def test_draft_download_url_is_not_confused_with_final_public_url(self):
        release, ref, assets = release_fixture(True)
        release['assets'][0]['browser_download_url'] = 'https://github.com/temporary-draft-url'
        publisher.verify_release(order(), release, ref, assets, True)
        release['draft'] = False
        with self.assertRaises(ValueError):
            publisher.verify_release(order(), release, ref, assets, False)

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
                publisher.github_json('repos/' + publisher.REPOSITORY, 'sensitive-token')
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
                    patch.dict(os.environ, publisher_environment(), clear=True), \
                    patch.object(publisher, 'observe_api'), \
                    patch.object(publisher, 'publisher_cli') as write:
                request = order()
                local_payload(folder, request)
                def observed(path, token, **kwargs):
                    if existing in path:
                        return {'id': 123}
                    return publication_reads(path, token, **kwargs)
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



class ContextAndOrderTests(unittest.TestCase):
    def test_repository_owner_and_actions_bot_are_distinct_identities(self):
        publisher.verify_owner(repository_fixture()['owner'])
        publisher.verify_actions_identity({'login': 'github-actions[bot]', 'id': 41898282, 'type': 'Bot'})
        with self.assertRaises(ValueError):
            publisher.verify_actions_identity(repository_fixture()['owner'])
        with self.assertRaises(ValueError):
            publisher.verify_owner({'login': 'github-actions[bot]', 'id': 41898282, 'type': 'Bot'})

    def test_missing_or_wrong_publisher_context_fails_closed(self):
        with patch.dict(os.environ, publisher_environment(), clear=True):
            context = publisher.context()
            self.assertEqual(context['publisher_run_id'], 1000)
            for field, value in (
                    ('GITHUB_REPOSITORY_ID', '2'), ('GITHUB_REPOSITORY_OWNER_ID', '3'),
                    ('GITHUB_REF', 'refs/heads/main'), ('GITHUB_EVENT_NAME', 'pull_request'),
                    ('GITHUB_API_URL', 'https://other.invalid'), ('GITHUB_WORKFLOW_SHA', 'd' * 40),
                    ('GITHUB_RUN_ATTEMPT', '0')):
                with self.subTest(field=field), patch.dict(os.environ, {field: value}), \
                        self.assertRaises(ValueError):
                    publisher.context()

    def test_tag_run_and_all_three_quality_ids_are_bound(self):
        request = order()
        for change in (
                {'release_tag': 'lumo-0.14.9-2082-999999'},
                {'intelligence_job_id': request['build_job_id']},
                {'intelligence_artifact_id': request['apk_artifact_id']},
                {'godot_commit': 'f' * 39}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                publisher.validate_order({**request, **change})

    def test_wrong_owner_or_third_job_failure_blocks_source(self):
        for change in (
                lambda e: e['run']['repository']['owner'].update(id=999),
                lambda e: e['run']['head_repository'].update(private=True),
                lambda e: e['run'].update(path='unreviewed.yml'),
                lambda e: e['run'].update(run_attempt=999),
                lambda e: e['jobs']['jobs'][0].update(conclusion='skipped'),
                lambda e: e['artifacts']['intelligence'].update(digest='sha256:' + 'f' * 64)):
            request = order()
            sample = evidence(request)
            change(sample)
            with self.assertRaises(ValueError):
                publisher.verify_api(request, sample)

    def test_changed_or_old_publication_order_cannot_reactivate(self):
        for changed in ('M\t' + str(publisher.REQUEST), '', 'D\t' + str(publisher.REQUEST)):
            with tempfile.TemporaryDirectory() as folder, \
                    patch.object(publisher, 'ROOT', Path(folder)), \
                    patch.dict(os.environ, publisher_environment('verify'), clear=True), \
                    patch.object(publisher.subprocess, 'check_output',
                                 side_effect=['c' * 40 + '\n', changed + '\n']), \
                    patch.object(publisher, 'observe_api') as observe, \
                    self.assertRaises(ValueError):
                publisher.prepare(order())
            observe.assert_not_called()

    def test_source_pubspec_and_native_pin_are_observed_at_exact_commit(self):
        request = order()
        correct = {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                   'revision': request['godot_commit'], 'engine': '4.6.3'}
        for version, native, passes in (
                ('0.14.9+2082', correct, True),
                ('0.14.8+2081', correct, False),
                ('0.14.9+2082', {**correct, 'revision': 'd' * 40}, False)):
            with tempfile.TemporaryDirectory() as folder, \
                    patch.object(publisher, 'ROOT', Path(folder)), \
                    patch.dict(os.environ, {**publisher_environment('verify'), 'GH_TOKEN': 'reader'}, clear=True), \
                    patch.object(publisher.subprocess, 'check_output',
                                 side_effect=['c' * 40 + '\n', 'A\t' + str(publisher.REQUEST) + '\n']), \
                    patch.object(publisher, 'observe_api', return_value=evidence(request)), \
                    patch.object(publisher, 'source_document',
                                 side_effect=['name: test\nversion: ' + version + '\n', json.dumps(native)]) as source:
                if passes:
                    publisher.prepare(request)
                    saved = publisher.read(Path(folder) / 'proof/PUBLICATION-ORDER.json')
                    self.assertEqual(saved, request)
                    self.assertTrue(all(call.args[1] == request['flutter_commit']
                                        for call in source.call_args_list))
                else:
                    with self.assertRaises(ValueError):
                        publisher.prepare(request)


class ArchiveTests(unittest.TestCase):
    class Response(io.BytesIO):
        status = 200

        def geturl(self):
            return 'https://artifact-storage.invalid/download'

    def test_entire_archive_is_hashed_and_api_authorization_never_reaches_storage(self):
        content = b'Complete synthetic artifact ZIP bytes'
        sha = hashlib.sha256(content).hexdigest()
        redirect = HTTPError('https://api.github.com/artifact', 302, '',
                             {'Location': 'https://artifact-storage.invalid/download'}, None)
        opening = Mock()
        opening.open.return_value = self.Response(content)
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(publisher.API_OPENER, 'open', side_effect=redirect) as api, \
                patch.object(publisher, 'build_opener', return_value=opening):
            result = publisher.download_archive(101, len(content), sha, Path(folder) / 'artifact.zip', 'secret-api-token')
            self.assertEqual(result['sha256'], sha)
            self.assertFalse(result['storage_authorization_header_sent'])
            self.assertEqual(api.call_args.args[0].get_header('Authorization'), 'Bearer secret-api-token')
            self.assertIsNone(opening.open.call_args.args[0].get_header('Authorization'))
            self.assertEqual((Path(folder) / 'artifact.zip').read_bytes(), content)

    def test_changed_truncated_or_oversized_archive_never_passes(self):
        original = b'original archive'
        for content in (b'changed archive!', original[:-1], original + b'!'):
            redirect = HTTPError('https://api.github.com/artifact', 302, '',
                                 {'Location': 'https://artifact-storage.invalid/download'}, None)
            opening = Mock()
            opening.open.return_value = self.Response(content)
            with tempfile.TemporaryDirectory() as folder, \
                    patch.object(publisher.API_OPENER, 'open', side_effect=redirect), \
                    patch.object(publisher, 'build_opener', return_value=opening), \
                    self.assertRaises(ValueError):
                publisher.download_archive(101, len(original), hashlib.sha256(original).hexdigest(),
                                           Path(folder) / 'artifact.zip', 'reader')

    def test_download_rejects_permission_error_without_anonymous_fallback(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(publisher.API_OPENER, 'open', side_effect=HTTPError(
                    'https://api.github.com/artifact', 403, '', {}, None)) as api, \
                patch.object(publisher, 'build_opener') as storage:
            with self.assertRaises(publisher.PublicationOperationError) as raised:
                publisher.download_archive(101, 20, 'a' * 64, Path(folder) / 'artifact.zip', 'reader')
            self.assertEqual(raised.exception.http_status, 403)
            self.assertEqual(api.call_count, 1)
            storage.assert_not_called()

    def test_redirect_must_be_credential_free_https(self):
        for target in ('http://storage.invalid/file', 'https://secret:password@storage.invalid/file'):
            redirect = HTTPError('https://api.github.com/artifact', 302, '', {'Location': target}, None)
            with tempfile.TemporaryDirectory() as folder, \
                    patch.object(publisher.API_OPENER, 'open', side_effect=redirect), \
                    patch.object(publisher, 'build_opener') as storage, \
                    self.assertRaises(RuntimeError):
                publisher.download_archive(101, 20, 'a' * 64, Path(folder) / 'artifact.zip', 'reader')
            storage.assert_not_called()

    def test_regular_archive_preserves_nested_original_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            archive = Path(folder) / 'original.zip'
            with zipfile.ZipFile(archive, 'w') as output:
                output.writestr('release/', b'')
                output.writestr('release/original.apk', b'exact fixture bytes')
                output.writestr('tour/deep/result.json', b'{}')
            publisher.extract_archive(archive, Path(folder) / 'unpacked')
            self.assertEqual((Path(folder) / 'unpacked/release/original.apk').read_bytes(), b'exact fixture bytes')

    def test_traversal_alias_duplicate_and_symlink_are_rejected(self):
        entries = [
            ['../outside'], ['/absolute'], ['./alias'], ['folder/../outside'],
            ['folder//alias'], [r'folder\escape'], ['same', 'same/'],
        ]
        for names in entries:
            with self.subTest(names=names), tempfile.TemporaryDirectory() as folder:
                archive = Path(folder) / 'original.zip'
                with zipfile.ZipFile(archive, 'w') as output:
                    for name in names:
                        output.writestr(name, b'')
                with self.assertRaises(ValueError):
                    publisher.extract_archive(archive, Path(folder) / 'unpacked')
                self.assertFalse((Path(folder) / 'unpacked').exists())
        with tempfile.TemporaryDirectory() as folder:
            archive = Path(folder) / 'link.zip'
            with zipfile.ZipFile(archive, 'w') as output:
                info = zipfile.ZipInfo('link')
                info.create_system = 3
                info.external_attr = (stat.S_IFLNK | 0o777) << 16
                output.writestr(info, '../outside')
            with self.assertRaises(ValueError):
                publisher.extract_archive(archive, Path(folder) / 'unpacked')


class StageTests(unittest.TestCase):
    def fixture(self, folder, request):
        source = Path(folder) / 'source'
        source.mkdir()
        assets = local_payload(source, request)
        manifest = source / 'proof/PREPUBLICATION-VERIFICATION.json'
        archive = Path(folder) / 'stage.zip'
        with zipfile.ZipFile(archive, 'w') as output:
            for path in source.rglob('*'):
                if path.is_file():
                    output.write(path, path.relative_to(source).as_posix())
        ctx = publisher.context()
        metadata = {
            'id': 987, 'expired': False, 'size_in_bytes': archive.stat().st_size,
            'digest': 'sha256:' + publisher.digest(archive),
            'name': f'LUMO-2082-REVIEWED-STAGE-{ctx["publisher_run_id"]}-{ctx["publisher_run_attempt"]}',
            'workflow_run': {'id': ctx['publisher_run_id'], 'head_sha': ctx['publisher_commit'],
                             'head_branch': publisher.PUBLISHER_BRANCH,
                             'repository_id': publisher.REPOSITORY_ID,
                             'head_repository_id': publisher.REPOSITORY_ID}}
        return archive, metadata, publisher.digest(manifest), assets

    def download_fixture(self, archive):
        def copy(artifact_id, expected_bytes, expected_sha256, destination, token):
            self.assertEqual(expected_bytes, archive.stat().st_size)
            self.assertEqual(expected_sha256, publisher.digest(archive))
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(archive.read_bytes())
            return {'artifact_id': artifact_id, 'bytes': expected_bytes, 'sha256': expected_sha256,
                    'storage_authorization_header_sent': False}
        return copy

    def test_exact_same_run_handoff_preserves_assets_and_manifest(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.dict(os.environ, publisher_environment(), clear=True):
            request = order()
            archive, meta, manifest, assets = self.fixture(folder, request)
            with patch.object(publisher, 'ROOT', Path(folder) / 'target'), \
                    patch.object(publisher, 'github_json', return_value=meta), \
                    patch.object(publisher, 'download_archive', side_effect=self.download_fixture(archive)):
                (publisher.ROOT / 'proof').mkdir(parents=True)
                publisher.stage(request, meta['id'], meta['digest'], manifest)
                self.assertEqual(publisher.verify_local_assets(request), assets)
                self.assertEqual(publisher.digest(publisher.ROOT / 'proof/PREPUBLICATION-VERIFICATION.json'), manifest)

    def test_wrong_run_commit_attempt_archive_or_manifest_blocks_handoff(self):
        changes = [
            lambda m: m.update(expired=True),
            lambda m: m['workflow_run'].update(id=1001),
            lambda m: m['workflow_run'].update(head_sha='d' * 40),
            lambda m: m['workflow_run'].update(head_repository_id=1),
            lambda m: m.update(name='LUMO-2082-REVIEWED-STAGE-1000-2'),
            lambda m: m.update(digest='sha256:' + 'd' * 64),
        ]
        for change in changes:
            with tempfile.TemporaryDirectory() as folder, \
                    patch.dict(os.environ, publisher_environment(), clear=True):
                request = order()
                archive, meta, manifest, _ = self.fixture(folder, request)
                expected_digest = publisher.digest(archive)
                change(meta)
                with patch.object(publisher, 'ROOT', Path(folder) / 'target'), \
                        patch.object(publisher, 'github_json', return_value=meta), \
                        patch.object(publisher, 'download_archive') as download, \
                        self.assertRaises(ValueError):
                    publisher.stage(request, meta['id'], expected_digest, manifest)
                download.assert_not_called()
        with tempfile.TemporaryDirectory() as folder, \
                patch.dict(os.environ, publisher_environment(), clear=True):
            request = order()
            archive, meta, manifest, _ = self.fixture(folder, request)
            with patch.object(publisher, 'ROOT', Path(folder) / 'target'), \
                    patch.object(publisher, 'github_json', return_value=meta), \
                    patch.object(publisher, 'download_archive', side_effect=self.download_fixture(archive)), \
                    self.assertRaises(ValueError):
                publisher.stage(request, meta['id'], meta['digest'], 'd' * 64)
            self.assertFalse((Path(folder) / 'target/release').exists())

    def test_changed_or_additional_local_bytes_block_publication(self):
        for mutate in (
                lambda directory: (directory / publisher.APK).write_bytes(b'changed'),
                lambda directory: (directory / 'extra.apk').write_bytes(b'extra')):
            with tempfile.TemporaryDirectory() as folder, \
                    patch.dict(os.environ, publisher_environment(), clear=True), \
                    patch.object(publisher, 'ROOT', Path(folder)):
                request = order()
                local_payload(folder, request)
                mutate(Path(folder) / 'release')
                with self.assertRaises(ValueError):
                    publisher.verify_local_assets(request)


class PublicationFlowTests(unittest.TestCase):
    def test_workflow_permission_failure_is_one_attempt_without_another_token_or_source(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(publisher, 'ROOT', Path(folder)), \
                patch.dict(os.environ, {**publisher_environment(),
                                       'LUMO_RELEASE_PUBLISH_TOKEN': 'must-never-be-used'}, clear=True), \
                patch.object(publisher, 'observe_api') as observe, \
                patch.object(publisher, 'github_json', side_effect=publication_reads), \
                patch.object(publisher, 'publisher_cli', side_effect=publisher.PublicationOperationError(
                    'workflow_scope', http_status=403, exit_code=1)) as write:
            request = order()
            local_payload(folder, request)
            with self.assertRaises(publisher.PublicationOperationError) as raised:
                publisher.publish(request)
            self.assertEqual(write.call_count, 1)
            self.assertEqual(write.call_args.args[0], 'synthetic-workflow-token')
            self.assertEqual(write.call_args.args[2],
                             {'ref': 'refs/tags/' + request['release_tag'], 'sha': request['flutter_commit']})
            self.assertEqual(observe.call_args.args[1], 'synthetic-workflow-token')
            with redirect_stderr(io.StringIO()):
                diagnostic = publisher.report_failure(raised.exception)
            self.assertEqual(diagnostic['phase'], 'create-tag')
            self.assertEqual(diagnostic['reason'], 'workflow_scope')
            self.assertEqual(diagnostic['http_status'], 403)

    def test_success_requires_exact_uploaded_assets_and_complete_anonymous_download(self):
        with tempfile.TemporaryDirectory() as folder, \
                patch.object(publisher, 'ROOT', Path(folder)), \
                patch.dict(os.environ, publisher_environment(), clear=True), \
                patch.object(publisher, 'observe_api'):
            request = order()
            assets = local_payload(folder, request)
            bot = {'login': 'github-actions[bot]', 'id': 41898282, 'type': 'Bot'}
            ref = {'ref': 'refs/tags/' + request['release_tag'],
                   'object': {'type': 'commit', 'sha': request['flutter_commit']}}
            state = {'tag': False, 'published': False}
            def release():
                return {
                    'id': 201, 'tag_name': request['release_tag'],
                    'target_commitish': request['flutter_commit'], 'draft': not state['published'],
                    'prerelease': True, 'author': bot, 'immutable': False,
                    'html_url': f'https://github.com/{publisher.REPOSITORY}/releases/tag/{request["release_tag"]}',
                    'assets': [{'id': 300 + index, 'name': name, 'uploader': bot,
                                'state': 'uploaded', 'size': item['bytes'], 'digest': 'sha256:' + item['sha256'],
                                'browser_download_url': f'https://github.com/{publisher.REPOSITORY}/releases/download/{request["release_tag"]}/{name}'}
                               for index, (name, item) in enumerate(assets.items())]}
            def fetch(path, token, **kwargs):
                if '/git/ref/tags/' in path:
                    return ref if state['tag'] else None
                if '/releases/201' in path:
                    return release()
                return publication_reads(path, token, **kwargs)
            def write(token, arguments, payload=None):
                self.assertEqual(token, 'synthetic-workflow-token')
                if arguments[0] == 'api' and arguments[2] == 'POST' and arguments[3].endswith('/git/refs'):
                    state['tag'] = True
                    return ref
                if arguments[0] == 'api' and arguments[2] == 'POST' and arguments[3].endswith('/releases'):
                    return {'id': 201, 'draft': True, 'author': bot, 'tag_name': request['release_tag'],
                            'target_commitish': request['flutter_commit'], 'prerelease': True, 'assets': []}
                if arguments[0] == 'api' and arguments[2] == 'PATCH':
                    state['published'] = True
                    return release()
                self.assertEqual(arguments[:2], ['release', 'upload'])
                self.assertNotIn('--clobber', arguments)
                return None
            observation = {'httpStatus': 200, 'entireFileRead': True, 'authorizationHeaderSent': False,
                           'sha256': request['apk_sha256'], 'bytes': request['apk_bytes']}
            with patch.object(publisher, 'github_json', side_effect=fetch), \
                    patch.object(publisher, 'publisher_cli', side_effect=write) as mutation, \
                    patch.object(publisher, 'download_public', return_value=observation) as anonymous:
                publisher.publish(request)
            self.assertEqual(mutation.call_count, 4)
            self.assertEqual(anonymous.call_args.args[0]['sha256'], request['apk_sha256'])
            result = publisher.read(Path(folder) / 'proof/PUBLIC-DOWNLOAD-VERIFICATION.json')
            self.assertEqual(result['download'], observation)
            self.assertEqual(result['source'], request['flutter_commit'])
            self.assertIs(result['server_immutable_observed'], False)
            self.assertEqual(result['publication_policy'], 'new-tag-new-release-no-overwrite')


if __name__ == '__main__':
    unittest.main()
