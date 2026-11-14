"""Synthetic publication protocol tests: no GitHub writes, credentials or APKs.

The actual existing delivery verifier is exercised on synthetic bytes. Only its
Git process boundary and the remote API are substituted. These tests cannot
establish a successful real candidate run, Android behavior or publication.
"""
from __future__ import annotations

from contextlib import redirect_stderr, redirect_stdout
from dataclasses import replace
import hashlib
import io
import json
import os
from pathlib import Path
import socket
import stat
import struct
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import urllib.parse
import zipfile

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
import publish_connect_four_delivery as p
import verify_connect_four_delivery as existing


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(value if isinstance(value, bytes) else p.encoded(value))
    return path


class FakeSource:
    def __init__(self, path, sha, tree):
        self.path, self.sha, self.tree = path, sha, tree
        self.changed = False
        self.before = self.snapshot()

    def snapshot(self):
        return {'head': self.sha, 'tree': self.tree, 'synthetic_git_boundary': True}

    def check(self):
        p.require(not self.changed, 'SOURCE_OR_INDEX_CHANGED')


class OriginalVerifierWithFakeGit:
    def __init__(self, fixture):
        self.fixture, self.calls, self.reject = fixture, [], None

    def call(self, command, **arguments):
        self.calls.append((command, dict(arguments)))
        if command == self.reject:
            raise p.PublicationError('UNCHANGED_VERIFIER_REJECTED')
        argv = ['verify_connect_four_delivery.py', command]
        for key, value in arguments.items():
            argv.extend(['--' + key.replace('_', '-'), str(value)])

        def git_output(argv, **kwargs):
            if argv == ['git', 'rev-parse', 'HEAD']:
                return self.fixture.args.host_sha + '\n'
            if argv == ['git', 'rev-parse', 'HEAD^{tree}']:
                return self.fixture.args.host_tree + '\n'
            raise AssertionError('Unexpected synthetic Git call: ' + repr(argv))

        def git_run(argv, **kwargs):
            if argv != ['git', 'diff', '--exit-code', 'HEAD', '--']:
                raise AssertionError('Unexpected synthetic Git call: ' + repr(argv))
            return subprocess.CompletedProcess(argv, 0)

        with mock.patch.object(sys, 'argv', argv), \
                mock.patch.object(existing, 'ROOT', self.fixture.candidate.path), \
                mock.patch.object(existing.subprocess, 'check_output', side_effect=git_output), \
                mock.patch.object(existing.subprocess, 'run', side_effect=git_run), \
                redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            try:
                p.require(existing.main() == 0, 'UNCHANGED_VERIFIER_REJECTED')
            except ValueError as exc:
                raise p.PublicationError('UNCHANGED_VERIFIER_REJECTED') from exc


class FakeAPI:
    def __init__(self, fixture):
        self.f = fixture
        self.mutations, self.downloads = [], []
        self.tag, self.release = None, None
        self.old_releases, self.old_tags = [], []
        self.move_after_tag = False
        self.attempt_after_assets = False
        self.corrupt_upload = False
        self.extra_asset = False
        self.swapped_asset_id = False
        self.changed_tag = False
        self.corrupt_public = False
        self.fail_mutation = None
        self.incomplete_jobs = False
        self.incomplete_tags = False
        self.fail_job = False
        self.skip_required_step = False
        self.seen_raw = []

    def reply(self, value):
        raw = p.encoded(value)
        path = self.f.evidence.entry('fake-api')/'response.json'
        self.f.evidence.write(path, raw)
        self.seen_raw.append(raw)
        return p.Reply(p.strict_json(raw), raw, path)

    def call(self, method, path, *, payload=None, upload=None, expected=200):
        parsed = urllib.parse.urlsplit(path)
        route, query = parsed.path, urllib.parse.parse_qs(parsed.query)
        if method != 'GET':
            self.mutations.append((method, path, p.record(payload or upload)))
            if len(self.mutations) == self.fail_mutation:
                raise p.PublicationError('HTTP_TRANSPORT_FAILED_NO_RETRY')
            if path == '/git/refs':
                data = p.strict_json(payload.read_bytes())
                self.tag = {'ref': data['ref'], 'object': {'type': 'commit', 'sha': data['sha']}}
                return self.reply(self.tag)
            if path == '/releases':
                data = p.strict_json(payload.read_bytes())
                self.release = {**data, 'id': 700, 'assets': [], 'published_at': None,
                    'upload_url': p.UPLOAD + '/releases/700/assets{?name,label}'}
                return self.reply(self.release)
            if route == '/releases/700/assets':
                name = query['name'][0]
                actual = p.record(upload)
                row = {'id': 800 + len(self.release['assets']), 'name': name, 'state': 'uploaded',
                       'size': actual['bytes'], 'digest': 'sha256:' + actual['sha256'],
                       'browser_download_url': f'https://github.com/{p.REPOSITORY}/releases/download/{p.TAG}/{name}'}
                if self.corrupt_upload:
                    row['digest'] = 'sha256:' + '0' * 64
                self.release['assets'].append(row)
                return self.reply(row)
            if method == 'PATCH' and path == '/releases/700':
                self.release.update(p.strict_json(payload.read_bytes()))
                self.release['published_at'] = '2000-01-01T00:00:00Z'
                return self.reply(self.release)
            raise AssertionError('Unexpected mutation')
        if route == '/actions/runs/101' or route == '/actions/runs/101/attempts/1':
            data = dict(self.f.run)
            if self.attempt_after_assets and self.release and len(self.release['assets']) == 11:
                data['run_attempt'] = 2
            return self.reply(data)
        if route == '/pulls/485':
            data = p.strict_json(p.encoded(self.f.pull))
            if self.move_after_tag and self.tag:
                data['head']['sha'] = 'f' * 40
            return self.reply(data)
        if route == '/actions/runs/101/attempts/1/jobs':
            jobs = p.strict_json(p.encoded(self.f.jobs))
            if self.fail_job:
                jobs[0]['conclusion'] = 'failure'
            if self.skip_required_step:
                jobs[0]['steps'][0]['conclusion'] = 'skipped'
            if int(query['page'][0]) != 1 or self.incomplete_jobs:
                jobs = []
            return self.reply({'total_count': len(self.f.jobs), 'jobs': jobs})
        if route == '/actions/runs/101/artifacts':
            return self.reply({'total_count': len(self.f.artifacts),
                'artifacts': self.f.artifacts if int(query['page'][0]) == 1 else []})
        if route == '/git/matching-refs/tags/':
            return self.reply(self.old_tags + ([self.tag] if self.tag else []))
        if route == '/tags':
            refs = self.old_tags + ([self.tag] if self.tag else [])
            rows = [{'name': row['ref'][10:]} for row in refs]
            if int(query['page'][0]) != 1 or self.incomplete_tags:
                rows = []
            return self.reply(rows)
        if route == '/releases':
            rows = self.old_releases + ([self.release] if self.release else [])
            return self.reply(rows if int(query['page'][0]) == 1 else [])
        if route == '/git/ref/tags/' + p.TAG:
            row = p.strict_json(p.encoded(self.tag))
            if self.changed_tag and self.release and len(self.release['assets']) == 11:
                row['object']['sha'] = 'f' * 40
            return self.reply(row)
        if route == '/releases/700':
            row = p.strict_json(p.encoded(self.release))
            if self.extra_asset and len(row['assets']) == 11:
                row['assets'].append({**row['assets'][0], 'id': 9999, 'name': 'unexpected.txt'})
            if self.swapped_asset_id and len(row['assets']) == 11:
                row['assets'][0]['id'] = 9999
            return self.reply(row)
        if route == '/releases/700/assets':
            rows = p.strict_json(p.encoded(self.release['assets'])) if int(query['page'][0]) == 1 else []
            if self.swapped_asset_id and len(rows) == 11:
                rows[0]['id'] = 9999
            return self.reply(rows)
        raise AssertionError('Unexpected GET ' + path)

    def download(self, url, destination, expected, *, authenticated):
        self.downloads.append((url, authenticated))
        raw = self.f.zip_path.read_bytes() if authenticated else self.f.apk
        if not authenticated and self.corrupt_public:
            raw += b'corruption'
        with destination.open('xb') as handle:
            handle.write(raw)
        p.require(p.record(destination) == expected, 'DOWNLOAD_BYTES_DIFFER')
        return p.record(destination)


class Fixture:
    """All IDs/content here are explicitly synthetic and never sent to a server."""
    def __init__(self, root):
        self.root = root
        self.apk = b'SYNTHETIC TEST BYTES; NOT AN ANDROID APK\n'
        self.native = 'e' * 40
        self.candidate = FakeSource(root/'candidate', 'a' * 40, 'b' * 40)
        self.publisher_source = FakeSource(root/'publisher', 'c' * 40, 'd' * 40)
        self.output = root/'output'
        self.output.mkdir()
        self.evidence = p.Evidence(self.output, 'synthetic-private-token')
        self.zip_path = root/'synthetic-original.zip'
        self.run = {'id': 101, 'run_attempt': 1, 'head_sha': 'a' * 40, 'head_branch': p.BRANCH,
                    'path': p.WORKFLOW, 'event': 'pull_request', 'status': 'completed',
                    'conclusion': 'success', 'repository': {'full_name': p.REPOSITORY}}
        self.pull = {'number': 485, 'state': 'open',
                     'head': {'sha': 'a' * 40, 'ref': p.BRANCH, 'repo': {'full_name': p.REPOSITORY}},
                     'base': {'repo': {'full_name': p.REPOSITORY}}}
        self.jobs = []
        required = dict(existing.REQUIRED_STEPS)
        required[existing.DELIVERY_JOB] = (
            'Reverify actual current APKs C4 update PCM and complete native originals',
            'Preserve the complete verified 2020 ARM64 delivery bundle without publication')
        for index, (name, labels) in enumerate(required.items(), 1):
            self.jobs.append({'id': 200 + index, 'run_id': 101, 'run_attempt': 1,
                'head_sha': 'a' * 40, 'name': name, 'status': 'completed', 'conclusion': 'success',
                'steps': [{'name': label, 'status': 'completed', 'conclusion': 'success'} for label in labels]})
        self.artifacts = [{'id': 300 + index, 'name': name, 'size_in_bytes': 1,
            'digest': 'sha256:' + '1' * 64, 'expired': False,
            'workflow_run': {'id': 101, 'head_sha': 'a' * 40}}
            for index, name in enumerate(existing.ARTIFACT_NAMES)]
        self.binding = {'host_source': 'a' * 40, 'run_id': 101, 'run_attempt': 1,
                        'native_source': self.native, 'candidate_artifact_id': 300,
                        'candidate_artifact_digest': 'sha256:' + '1' * 64}
        facts = {'schema': 1, 'status': 'VERIFIED_TEST_BUNDLE_NOT_PUBLISHED',
                 'published': False, 'release_approved': False, 'host_source': 'a' * 40,
                 'host_tree': 'b' * 40, 'native_source': self.native, 'binding': self.binding,
                 'versionName': '0.13.8', 'versionCode': 2020,
                 'original_artifacts': existing.checked_artifacts(
                     {'total_count': len(self.artifacts), 'artifacts': self.artifacts}, self.binding)}
        self.members = {'assets/' + name: p.encoded({'synthetic': name}) for name in p.ASSETS}
        self.members['assets/Lumo-Lernen-Neu.apk'] = self.apk
        self.members['assets/Lumo-Lernen-Neu.apk.sha256'] = \
            (hashlib.sha256(self.apk).hexdigest() + '  Lumo-Lernen-Neu.apk\n').encode()
        self.members['assets/C4-DELIVERY-FACTS.json'] = p.encoded(facts)
        self.plan = {'schema': 1, 'host_source': 'a' * 40, 'tag': p.TAG,
                     'versionName': '0.13.8', 'versionCode': 2020,
                     'download_url': f'https://github.com/{p.REPOSITORY}/releases/download/{p.TAG}/Lumo-Lernen-Neu.apk',
                     'assets': {name: {'bytes': len(self.members['assets/' + name]),
                         'sha256': hashlib.sha256(self.members['assets/' + name]).hexdigest()}
                         for name in p.ASSETS}}
        self.members.update({
            'publication-plan.json': p.encoded(self.plan),
            'audit/create-tag.json': p.encoded({'ref': 'refs/tags/' + p.TAG, 'sha': 'a' * 40}),
            'audit/create-release.json': p.encoded({'tag_name': p.TAG, 'target_commitish': 'a' * 40,
                'name': 'Lumo 2020 ARM64 Test-APK', 'body': 'Synthetic fixture, no runtime or publication result.',
                'draft': True, 'prerelease': True, 'make_latest': 'false', 'generate_release_notes': False}),
            'audit/publish-release.json': p.encoded({'draft': False, 'make_latest': 'false'}),
            'audit/asset-names.txt': ''.join(name + '\n' for name in sorted(p.ASSETS)).encode(),
        })
        save(self.candidate.path/'config/godot-source.json', {'revision': self.native})
        self.rebuild()
        self.args = p.Inputs(self.candidate.path, self.publisher_source.path, 'a' * 40, 'b' * 40,
            'c' * 40, 'd' * 40, 101, 1, 500, 'sha256:' + p.record(self.zip_path)['sha256'],
            self.zip_path.stat().st_size, 485, self.output, self.zip_path)
        self.api = FakeAPI(self)
        self.verifier = OriginalVerifierWithFakeGit(self)

    def rebuild(self):
        with zipfile.ZipFile(self.zip_path, 'w', compression=zipfile.ZIP_STORED) as archive:
            for name, data in sorted(self.members.items()):
                info = zipfile.ZipInfo(name, date_time=(2000, 1, 1, 0, 0, 0))
                info.external_attr = (stat.S_IFREG | 0o600) << 16
                archive.writestr(info, data)
        identity = p.record(self.zip_path)
        self.artifacts = [row for row in self.artifacts if row['name'] != p.BUNDLE]
        self.artifacts.append({'id': 500, 'name': p.BUNDLE, 'size_in_bytes': identity['bytes'],
            'digest': 'sha256:' + identity['sha256'], 'expired': False,
            'workflow_run': {'id': 101, 'head_sha': 'a' * 40}})
        if hasattr(self, 'args'):
            self.args = replace(self.args, bundle_artifact_size=identity['bytes'],
                                bundle_artifact_digest='sha256:' + identity['sha256'])

    def runner(self):
        return p.Publisher(self.args, self.api, self.verifier, self.candidate,
                           self.publisher_source, self.evidence)


class PublicationProtocolTests(unittest.TestCase):
    def setUp(self):
        network = mock.patch.object(socket, 'create_connection', side_effect=AssertionError('LIVE_NETWORK_FORBIDDEN'))
        network.start()
        self.addCleanup(network.stop)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.f = Fixture(Path(self.temp.name))

    def fails_without_publication(self, *, no_writes=False):
        with self.assertRaises((p.PublicationError, ValueError)):
            self.f.runner().run()
        self.assertFalse(any(method == 'PATCH' for method, _, _ in self.f.api.mutations))
        if no_writes:
            self.assertEqual(self.f.api.mutations, [])

    def test_complete_protocol_uses_original_verifier_and_exactly_eleven_assets(self):
        url = self.f.runner().run()
        self.assertEqual(url, self.f.plan['download_url'])
        writes = self.f.api.mutations
        self.assertEqual(len(writes), 14)
        self.assertEqual([row[:2] for row in writes[:2]], [('POST', '/git/refs'), ('POST', '/releases')])
        self.assertEqual([urllib.parse.parse_qs(urllib.parse.urlsplit(row[1]).query)['name'][0]
                          for row in writes[2:-1]], sorted(p.ASSETS))
        self.assertEqual(writes[-1][:2], ('PATCH', '/releases/700'))
        commands = [name for name, _ in self.f.verifier.calls]
        self.assertEqual(commands.count('check-current'), 3)
        self.assertEqual(commands.count('check-vacant'), 1)
        self.assertEqual(commands[-1], 'verify-public')
        stages = [args['stage'] for name, args in self.f.verifier.calls if name == 'check-release']
        self.assertEqual(stages, ['empty-draft', 'uploaded-draft', 'published', 'published'])
        self.assertEqual(self.f.api.downloads, [(url, False)])
        self.assertEqual(p.strict_json((self.f.output/'public-verification.json').read_bytes())['public_apk'],
                         self.f.plan['assets']['Lumo-Lernen-Neu.apk'])

    def test_failed_or_rerun_candidate_stops_before_archive_or_writes(self):
        for key, value in [('conclusion', 'failure'), ('run_attempt', 2), ('head_sha', 'f' * 40)]:
            with self.subTest(key=key):
                before = self.f.run[key]
                self.f.run[key] = value
                self.fails_without_publication(no_writes=True)
                self.f.run[key] = before
        self.assertEqual(self.f.api.downloads, [])

    def test_missing_job_page_is_not_a_complete_success(self):
        self.f.api.incomplete_jobs = True
        self.fails_without_publication(no_writes=True)

    def test_actual_failed_job_stops_before_writes(self):
        self.f.api.fail_job = True
        self.fails_without_publication(no_writes=True)

    def test_required_step_skip_is_rejected_by_unchanged_verifier(self):
        self.f.api.skip_required_step = True
        self.fails_without_publication(no_writes=True)
        self.assertIn('check-current', [name for name, _ in self.f.verifier.calls])

    def test_wrong_explicit_bundle_digest_stops_before_writes(self):
        self.f.args = replace(self.f.args, bundle_artifact_digest='sha256:' + '0' * 64)
        self.fails_without_publication(no_writes=True)

    def test_changed_local_bundle_is_not_accepted_by_correct_api_identity(self):
        with self.f.zip_path.open('ab') as handle:
            handle.write(b'changed')
        self.fails_without_publication(no_writes=True)

    def test_prepared_tree_differs_stops_before_writes(self):
        facts = p.strict_json(self.f.members['assets/C4-DELIVERY-FACTS.json'])
        facts['host_tree'] = 'f' * 40
        self.f.members['assets/C4-DELIVERY-FACTS.json'] = p.encoded(facts)
        self.f.rebuild()
        self.fails_without_publication(no_writes=True)

    def test_prepared_native_differs_from_candidate_pin(self):
        save(self.f.candidate.path/'config/godot-source.json', {'revision': 'f' * 40})
        self.fails_without_publication(no_writes=True)

    def test_existing_release_is_never_resumed(self):
        self.f.api.old_releases = [{'id': 600, 'tag_name': p.TAG, 'draft': True}]
        self.fails_without_publication(no_writes=True)

    def test_existing_tag_is_never_replaced(self):
        self.f.api.old_tags = [{'ref': 'refs/tags/' + p.TAG,
                               'object': {'type': 'commit', 'sha': 'a' * 40}}]
        self.fails_without_publication(no_writes=True)

    def test_tag_catalog_omission_is_rejected(self):
        self.f.api.old_tags = [{'ref': 'refs/tags/older', 'object': {'type': 'commit', 'sha': 'f' * 40}}]
        self.f.api.incomplete_tags = True
        self.fails_without_publication(no_writes=True)

    def test_moved_pr_after_new_tag_stops_before_release_creation(self):
        self.f.api.move_after_tag = True
        self.fails_without_publication()
        self.assertEqual([row[:2] for row in self.f.api.mutations], [('POST', '/git/refs')])

    def test_unknown_mutation_outcome_has_no_retry_cleanup_or_publish(self):
        self.f.api.fail_mutation = 2
        self.fails_without_publication()
        self.assertEqual([row[:2] for row in self.f.api.mutations], [('POST', '/git/refs'), ('POST', '/releases')])

    def test_changed_upload_digest_never_reaches_publication(self):
        self.f.api.corrupt_upload = True
        self.fails_without_publication()
        self.assertEqual(len(self.f.api.mutations), 3)

    def test_unexpected_draft_asset_never_reaches_publication(self):
        self.f.api.extra_asset = True
        self.fails_without_publication()
        self.assertEqual(len(self.f.api.mutations), 13)

    def test_changed_tag_after_upload_never_reaches_publication(self):
        self.f.api.changed_tag = True
        self.fails_without_publication()

    def test_replaced_asset_with_same_bytes_but_new_id_is_not_accepted(self):
        self.f.api.swapped_asset_id = True
        self.fails_without_publication()
        self.assertEqual(len(self.f.api.mutations), 13)

    def test_new_attempt_during_upload_stops_publication(self):
        self.f.api.attempt_after_assets = True
        self.fails_without_publication()

    def test_public_download_mismatch_never_creates_success_receipt(self):
        self.f.api.corrupt_public = True
        with self.assertRaises(p.PublicationError):
            self.f.runner().run()
        self.assertEqual(len([row for row in self.f.api.mutations if row[0] == 'PATCH']), 1)
        self.assertFalse((self.f.output/'public-verification.json').exists())
        self.assertFalse((self.f.output/'completed.json').exists())

    def test_payload_cannot_enable_non_draft_release(self):
        create = p.strict_json(self.f.members['audit/create-release.json'])
        create['draft'] = False
        self.f.members['audit/create-release.json'] = p.encoded(create)
        self.f.rebuild()
        self.fails_without_publication(no_writes=True)

    def test_source_change_stops_without_any_write(self):
        self.f.candidate.changed = True
        self.fails_without_publication(no_writes=True)

    def test_output_reuse_and_output_inside_checkout_are_rejected(self):
        with self.assertRaises(p.PublicationError):
            self.f.args.validate()
        with self.assertRaises(p.PublicationError):
            replace(self.f.args, output=self.f.candidate.path/'evidence').validate()


class ArchiveAndTransportTests(unittest.TestCase):
    def setUp(self):
        network = mock.patch.object(socket, 'create_connection', side_effect=AssertionError('LIVE_NETWORK_FORBIDDEN'))
        network.start()
        self.addCleanup(network.stop)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_zip_crc_failure_is_checked_even_with_matching_archive_digest(self):
        archive = self.root/'crc.zip'
        with zipfile.ZipFile(archive, 'w', compression=zipfile.ZIP_STORED) as zipped:
            zipped.writestr('payload.txt', b'original-member')
        data = bytearray(archive.read_bytes())
        offset = 30 + struct.unpack_from('<H', data, 26)[0] + struct.unpack_from('<H', data, 28)[0]
        data[offset] ^= 1
        archive.write_bytes(data)
        with self.assertRaises(p.PublicationError):
            p.extract_bundle(archive, self.root/'out', p.record(archive))

    def test_unsafe_duplicate_symlink_and_oversize_members_are_rejected(self):
        cases = ['traversal', 'duplicate', 'symlink', 'oversize']
        for case in cases:
            with self.subTest(case=case):
                archive = self.root/(case + '.zip')
                with zipfile.ZipFile(archive, 'w') as zipped:
                    if case == 'traversal':
                        zipped.writestr('../escape', b'bad')
                    elif case == 'duplicate':
                        zipped.writestr('same', b'one')
                        with self.assertWarns(UserWarning):
                            zipped.writestr('same', b'two')
                    elif case == 'symlink':
                        info = zipfile.ZipInfo('link')
                        info.external_attr = (stat.S_IFLNK | 0o777) << 16
                        zipped.writestr(info, b'../outside')
                    else:
                        zipped.writestr('large', b'abc')
                with mock.patch.object(p, 'MAX_UNPACKED', 2 if case == 'oversize' else p.MAX_UNPACKED):
                    with self.assertRaises(p.PublicationError):
                        p.extract_bundle(archive, self.root/(case + '-out'), p.record(archive))
        self.assertFalse((self.root.parent/'escape').exists())

    def test_direct_and_redirect_download_never_forward_authorization(self):
        class Response(io.BytesIO):
            def __init__(self, code, data=b'', **headers):
                super().__init__(data)
                self.code, self.headers = code, headers
        for authenticated in (False, True):
            with self.subTest(authenticated=authenticated):
                output = self.root/str(authenticated)
                output.mkdir()
                token = 'private-test-token-123456'
                evidence = p.Evidence(output, token)
                api = p.GitHub(evidence, token)
                data = b'full original download'
                expected = {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
                redirect = 'https://release-assets.githubusercontent.com/file?X-Amz-Signature=secret-signature'
                responses = [Response(302, Location=redirect), Response(200, data, **{'Content-Length': str(len(data))})]
                requests = []
                def opened(request, timeout):
                    requests.append(request)
                    return responses.pop(0)
                first = p.API + '/actions/artifacts/500/zip' if authenticated else \
                    f'https://github.com/{p.REPOSITORY}/releases/download/{p.TAG}/Lumo-Lernen-Neu.apk'
                with mock.patch.object(api, '_open', side_effect=opened):
                    api.download(first, output/'original.bin', expected, authenticated=authenticated)
                self.assertEqual(requests[0].get_header('Authorization'), 'Bearer ' + token if authenticated else None)
                self.assertIsNone(requests[1].get_header('Authorization'))
                logs = b''.join(path.read_bytes() for path in output.rglob('*') if path.is_file())
                self.assertNotIn(token.encode(), logs)
                self.assertNotIn(b'secret-signature', logs)

    def test_mutation_timeout_is_one_attempt_and_does_not_log_exception_url(self):
        evidence = p.Evidence(self.root, 'private-test-token-123456')
        api = p.GitHub(evidence, 'private-test-token-123456')
        payload = save(self.root/'payload.json', {'ref': 'refs/tags/' + p.TAG, 'sha': 'a' * 40})
        with mock.patch.object(api, '_open', side_effect=socket.timeout('https://secret/?sig=HIDDEN')) as opened:
            with self.assertRaises(p.PublicationError):
                api.call('POST', '/git/refs', payload=payload, expected=201)
        self.assertEqual(opened.call_count, 1)
        logs = b''.join(path.read_bytes() for path in self.root.rglob('*') if path.is_file())
        self.assertNotIn(b'HIDDEN', logs)
        error = next(self.root.rglob('transport-error.json'))
        self.assertTrue(p.strict_json(error.read_bytes())['mutation_outcome_may_be_unknown'])

    def test_secret_response_is_hash_only_and_forbidden_mutation_is_blocked(self):
        evidence = p.Evidence(self.root, 'private-test-token-123456')
        secret = b'{"url":"https://example.test/a?sig=hidden"}'
        with self.assertRaises(p.PublicationError):
            evidence.write(self.root/'response.json', secret)
        self.assertFalse((self.root/'response.json').exists())
        omitted = p.strict_json((self.root/'response.json.omitted.json').read_bytes())
        self.assertEqual(omitted['sha256'], hashlib.sha256(secret).hexdigest())
        api = p.GitHub(evidence, 'private-test-token-123456')
        with mock.patch.object(api, '_open') as opened:
            with self.assertRaises(p.PublicationError):
                api.call('DELETE', '/releases/700')
        opened.assert_not_called()

    def test_mutation_redirect_is_never_followed(self):
        class Redirect(io.BytesIO):
            code = 302
            headers = {'Location': 'https://uploads.github.com/other?sig=HIDDEN'}
        evidence = p.Evidence(self.root, 'private-test-token-123456')
        api = p.GitHub(evidence, 'private-test-token-123456')
        payload = save(self.root/'payload.json', {'ref': 'refs/tags/' + p.TAG, 'sha': 'a' * 40})
        with mock.patch.object(api, '_open', return_value=Redirect(b'{}')) as opened:
            with self.assertRaises(p.PublicationError):
                api.call('POST', '/git/refs', payload=payload, expected=201)
        self.assertEqual(opened.call_count, 1)
        logs = b''.join(path.read_bytes() for path in self.root.rglob('*') if path.is_file())
        self.assertNotIn(b'HIDDEN', logs)

    def test_verifier_child_does_not_receive_publication_credentials(self):
        with mock.patch.dict(os.environ, {'GITHUB_TOKEN': 'private', 'GH_PAT': 'private-pat',
                                         'CUSTOM_SECRET': 'secret', 'PYTHONPATH': '/untrusted'}):
            env = p.child_environment()
        for name in ('GITHUB_TOKEN', 'GH_PAT', 'CUSTOM_SECRET', 'PYTHONPATH'):
            self.assertNotIn(name, env)

    def test_changed_source_rejected_before_verifier_subprocess(self):
        candidate = FakeSource(self.root/'candidate', 'a' * 40, 'b' * 40)
        publisher = FakeSource(self.root/'publisher', 'c' * 40, 'd' * 40)
        candidate.changed = True
        verifier = p.Verifier(candidate, publisher, p.Evidence(self.root))
        with mock.patch.object(p.subprocess, 'run') as invoked:
            with self.assertRaises(p.PublicationError):
                verifier.call('check-tag', delivery=self.root, tag=self.root/'tag.json')
        invoked.assert_not_called()

    def test_source_guard_binds_real_verifier_bytes_and_raw_index(self):
        candidate = self.root/'candidate'
        candidate.mkdir()
        files = {}
        for name in (*p.VERIFIER_SOURCES, 'config/godot-source.json', 'pubspec.yaml', p.WORKFLOW):
            files[name] = (SCRIPTS.parent/name).read_bytes()
            save(candidate/name, files[name])
        index = save(self.root/'synthetic-index', b'explicit synthetic Git index boundary')

        def git(guard, *argv):
            if argv == ('rev-parse', '--show-toplevel'):
                return (str(candidate) + '\n').encode()
            if argv == ('rev-parse', 'HEAD'):
                return ('a' * 40 + '\n').encode()
            if argv == ('rev-parse', 'HEAD^{tree}'):
                return ('b' * 40 + '\n').encode()
            if argv == ('status', '--porcelain=v1', '-z', '--untracked-files=all'):
                return b''
            if argv == ('diff', '--exit-code', 'HEAD', '--'):
                return b''
            if argv == ('rev-parse', '--git-path', 'index'):
                return (str(index) + '\n').encode()
            if argv == ('ls-files', '--stage', '-z'):
                return b'explicit synthetic stage boundary'
            if argv[0] == 'show':
                return files[argv[1][5:]]
            raise AssertionError('Unexpected synthetic Git boundary')

        with mock.patch.object(p.SourceGuard, 'git', autospec=True, side_effect=git):
            guard = p.SourceGuard(candidate, 'a' * 40, 'b' * 40, candidate=True)
            guard.check()
            original_index = index.read_bytes()
            index.write_bytes(original_index + b'changed')
            with self.assertRaises(p.PublicationError):
                guard.check()
            index.write_bytes(original_index)
            target = candidate/'scripts/verify_connect_four_delivery.py'
            target.write_bytes(files['scripts/verify_connect_four_delivery.py'] + b'\n# changed\n')
            with self.assertRaises(p.PublicationError):
                guard.check()


if __name__ == '__main__':
    unittest.main()
