"""Publication safety tests use synthetic metadata; they perform no network writes."""
from copy import deepcopy
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError

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
