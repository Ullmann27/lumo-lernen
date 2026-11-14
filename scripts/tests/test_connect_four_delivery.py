"""Offline delivery counterexamples; never an APK, device or release claim."""
from __future__ import annotations

import copy
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import re
import sys
import stat
import tempfile
from types import SimpleNamespace
import unittest
from unittest import mock
import zipfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'scripts'))
import verify_connect_four_delivery as delivery


def job_block(text, name):
    match = re.search(r'^  '+re.escape(name)+r':\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)', text, re.M|re.S)
    if match is None:
        raise AssertionError('Missing actual job: '+name)
    return match[1]


def fixture():
    binding = {'host_source': 'a'*40, 'native_source': 'b'*40, 'versionCode': 2020,
               'versionName': '0.13.8', 'workflow': delivery.WORKFLOW,
               'run_id': 12345, 'run_attempt': 1, 'candidate_artifact_id': 100,
               'candidate_artifact_digest': 'sha256:'+'c'*64}
    run = {'id': 12345, 'run_attempt': 1, 'head_sha': 'a'*40,
           'head_branch': delivery.BRANCH, 'path': delivery.WORKFLOW, 'event': 'pull_request',
           'repository': {'full_name': delivery.REPOSITORY}, 'status': 'in_progress', 'conclusion': None}
    pull = {'number': 999, 'state': 'open',
            'head': {'sha': 'a'*40, 'ref': delivery.BRANCH, 'repo': {'full_name': delivery.REPOSITORY}},
            'base': {'repo': {'full_name': delivery.REPOSITORY}}}
    rows = []
    for index, (name, steps) in enumerate(delivery.REQUIRED_STEPS.items()):
        rows.append({'id': index+20, 'name': name, 'run_id': 12345, 'run_attempt': 1,
                     'head_sha': 'a'*40, 'status': 'completed', 'conclusion': 'success',
                     'completed_at': 'synthetic-original-time', 'steps': [
                         {'name': step, 'status': 'completed', 'conclusion': 'success'} for step in steps]})
    rows.append({'id': 50, 'name': delivery.DELIVERY_JOB, 'run_id': 12345, 'run_attempt': 1,
                 'head_sha': 'a'*40, 'status': 'in_progress', 'conclusion': None, 'steps': []})
    jobs = {'total_count': len(rows), 'jobs': rows}
    artifacts = {'total_count': len(delivery.ARTIFACT_NAMES), 'artifacts': [
        {'id': 100+index, 'name': name, 'size_in_bytes': 42, 'digest': 'sha256:'+'c'*64,
         'expired': False, 'workflow_run': {'id': 12345, 'head_sha': 'a'*40}}
        for index, name in enumerate(delivery.ARTIFACT_NAMES)]}
    return binding, run, pull, jobs, artifacts


class OriginalAcceptanceTests(unittest.TestCase):
    def setUp(self):
        self.binding, self.run, self.pull, self.jobs, self.artifacts = fixture()

    def check(self):
        return delivery.checked_jobs(self.run, self.jobs, self.pull, self.binding, 999)

    def test_exact_current_six_completed_jobs_and_readonly_preparation_are_required(self):
        self.assertEqual(set(self.check()), set(delivery.REQUIRED_STEPS))
        self.assertEqual(set(delivery.checked_artifacts(self.artifacts, self.binding)), set(delivery.ARTIFACT_NAMES))

    def test_each_failure_skip_cancel_and_foreign_attempt_blocks_delivery(self):
        for row in self.jobs['jobs'][:-1]:
            for field, value in [('conclusion', 'failure'), ('conclusion', 'skipped'),
                                 ('conclusion', 'cancelled'), ('run_attempt', 2),
                                 ('head_sha', 'd'*40), ('run_id', 99999), ('status', 'in_progress')]:
                original = row[field]; row[field] = value
                with self.subTest(job=row['name'], field=field, value=value), self.assertRaises(ValueError):
                    self.check()
                row[field] = original

    def test_reported_job_success_cannot_hide_a_skipped_or_failed_real_gate(self):
        for row in self.jobs['jobs'][:-1]:
            for step in row['steps']:
                for value in ('skipped', 'failure'):
                    step['conclusion'] = value
                    with self.subTest(step=step['name'], value=value), self.assertRaises(ValueError):
                        self.check()
                step['conclusion'] = 'success'

    def test_stale_or_foreign_branch_event_or_pull_request_is_rejected(self):
        for obj, key, value in [(self.run, 'event', 'workflow_dispatch'),
                                (self.run, 'path', '.github/workflows/lumo-kart-graphics-2019.yml'),
                                (self.run, 'status', 'completed'), (self.pull, 'state', 'closed'),
                                (self.pull['head'], 'sha', 'd'*40),
                                (self.pull['head'], 'ref', 'main'),
                                (self.pull['head']['repo'], 'full_name', 'outside/fork')]:
            previous = obj[key]; obj[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                self.check()
            obj[key] = previous

    def test_incomplete_duplicate_or_extra_jobs_cannot_hide_an_unchecked_gate(self):
        original = copy.deepcopy(self.jobs)
        for changed in ({'total_count': 8, 'jobs': self.jobs['jobs']},
                        {'total_count': 8, 'jobs': self.jobs['jobs']+[self.jobs['jobs'][0]]},
                        {'total_count': 8, 'jobs': self.jobs['jobs']+[{'name': 'unreviewed-extra-gate'}]}):
            self.jobs = changed
            with self.assertRaises(ValueError): self.check()
        self.jobs = original

    def test_every_original_artifact_requires_exact_source_run_digest_and_availability(self):
        for row in self.artifacts['artifacts']:
            for key, value in [('expired', True), ('digest', None), ('size_in_bytes', 0)]:
                previous = row[key]; row[key] = value
                with self.subTest(artifact=row['name'], key=key), self.assertRaises(ValueError):
                    delivery.checked_artifacts(self.artifacts, self.binding)
                row[key] = previous
            row['workflow_run']['head_sha'] = 'f'*40
            with self.assertRaises(ValueError): delivery.checked_artifacts(self.artifacts, self.binding)
            row['workflow_run']['head_sha'] = 'a'*40
        self.artifacts['artifacts'][0]['id'] = 10101
        with self.assertRaises(ValueError): delivery.checked_artifacts(self.artifacts, self.binding)

    def test_later_publication_requires_complete_success_and_actual_bundle_upload(self):
        with self.assertRaises(ValueError):
            delivery.checked_jobs(self.run, self.jobs, self.pull, self.binding, 999, publication=True)
        self.run.update(status='completed', conclusion='success')
        last = self.jobs['jobs'][-1]
        last.update(status='completed', conclusion='success', steps=[
            {'name': label, 'status': 'completed', 'conclusion': 'success'} for label in (
                'Reverify actual current APKs C4 update PCM and complete native originals',
                'Preserve the complete verified 2020 ARM64 delivery bundle without publication')])
        delivery.checked_jobs(self.run, self.jobs, self.pull, self.binding, 999, publication=True)
        for obj, key, value in ((self.run, 'conclusion', 'failure'), (last, 'conclusion', 'failure'),
                                 (last['steps'][0], 'conclusion', 'skipped'),
                                 (last['steps'][1], 'conclusion', 'skipped')):
            old = obj[key]; obj[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                delivery.checked_jobs(self.run, self.jobs, self.pull, self.binding, 999, publication=True)
            obj[key] = old


class PcmOriginalLogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name)/'build-contracts.log'
        self.valid = '\n'.join(
            [method+' (test_speech_envelope_contract.SpeechEnvelopeContractTest.'+method+') ... ok'
             for method in delivery.PCM_CONTRACTS]
            +['Ran 600 tests in 120.005s', '', 'OK', *delivery.PCM_CONTRACTS.values(), ''])
        self.path.write_text(self.valid)

    def test_complete_actual_stdout_contract_is_preserved_with_70_scoped_assertions(self):
        result = delivery.checked_pcm_log(self.path)
        self.assertEqual((result['tests'], result['pcm_assertions'], result['skips']), (600, 70, 0))
        self.assertIn('no Android audio claim', result['scope'])
        self.assertEqual(result['original_log']['sha256'], hashlib.sha256(self.valid.encode()).hexdigest())

    def test_missing_marker_unexecuted_method_skip_failure_or_duplicate_completion_fails(self):
        method, marker = next(iter(delivery.PCM_CONTRACTS.items()))
        variants = [self.valid.replace(marker, ''), self.valid.replace(method+' (', 'different_method ('),
                    self.valid.replace('\nOK\n', '\nOK (skipped=1)\n'),
                    self.valid.replace(' ... ok', ' ... skipped no compiler', 1),
                    self.valid+'FAILED (errors=1)\n', self.valid+'OK\n',
                    self.valid+'Ran 600 tests in 120.005s\n']
        for text in variants:
            self.path.write_text(text)
            with self.subTest(text=text[-100:]), self.assertRaises(ValueError):
                delivery.checked_pcm_log(self.path)


class NewReleaseOnlyTests(unittest.TestCase):
    def setUp(self):
        self.facts = {'versionName': '0.13.8', 'versionCode': 2020}
        self.plan = {'host_source': 'a'*40, 'tag': 'coachpreview-build-2020',
                     'download_url': 'https://github.com/Ullmann27/lumo-lernen/releases/download/coachpreview-build-2020/Lumo-Lernen-Neu.apk',
                     'assets': {'Lumo-Lernen-Neu.apk': {'bytes': 10, 'sha256': 'c'*64}}}
        self.tag = {'ref': 'refs/tags/coachpreview-build-2020', 'object': {'type': 'commit', 'sha': 'a'*40}}
        self.created = {'id': 20, 'tag_name': self.plan['tag'], 'target_commitish': 'a'*40,
                        'draft': True, 'prerelease': True, 'assets': [],
                        'upload_url': 'https://uploads.github.com/repos/Ullmann27/lumo-lernen/releases/20/assets{?name,label}'}

    def release(self, published=False):
        return {**self.created, 'draft': not published,
                'published_at': 'synthetic-publication-time' if published else None,
                'assets': [{'id': 30, 'name': 'Lumo-Lernen-Neu.apk', 'state': 'uploaded',
                            'size': 10, 'digest': 'sha256:'+'c'*64,
                            'browser_download_url': self.plan['download_url']}], 'immutable': False}

    def test_new_version_requires_complete_catalog_and_rejects_any_existing_tag_or_release(self):
        self.assertEqual(delivery.checked_release_catalog([[]], [], self.facts)['tag'], self.plan['tag'])
        for pages, refs in [([[{'tag_name': self.plan['tag'], 'draft': True}]], []),
                            ([[{'tag_name': self.plan['tag'], 'draft': False}]], []),
                            ([[]], [self.tag]),
                            ([[]], [{**self.tag, 'object': {'type': 'commit', 'sha': 'f'*40}}]),
                            ([], {}), ([], []), ({'items': []}, [])]:
            with self.subTest(pages=pages, refs=refs), self.assertRaises(ValueError):
                delivery.checked_release_catalog(pages, refs, self.facts)

    def test_newer_published_family_version_cannot_be_downgraded(self):
        current = {'tag_name': 'coachpreview-build-2021', 'draft': False, 'prerelease': True,
                   'assets': [{'name': 'Lumo-Lernen-Neu.apk'}]}
        with self.assertRaises(ValueError): delivery.checked_release_catalog([[current]], [], self.facts)
        with self.assertRaises(ValueError):
            delivery.checked_release_catalog([[]], [], {'versionName': '0.13.7', 'versionCode': 2019})

    def test_new_draft_then_exact_uploaded_assets_then_publication_are_distinct(self):
        delivery.checked_release(self.created, self.tag, self.created, self.plan, 'empty-draft')
        delivery.checked_release(self.release(), self.tag, self.created, self.plan, 'uploaded-draft')
        receipt = delivery.checked_release(self.release(True), self.tag, self.created, self.plan, 'published')
        self.assertIs(receipt['github_immutable'], False)
        self.assertIs(receipt['no_replacement_policy'], True)
        with self.assertRaises(ValueError):
            delivery.checked_release(self.release(), self.tag, self.created, self.plan, 'published')

    def test_asset_metadata_must_prove_actual_hash_size_uploaded_state_and_direct_url(self):
        for key, value in [('digest', 'sha256:'+'d'*64), ('digest', None), ('size', 11),
                            ('state', 'starter'), ('browser_download_url', 'https://example.test/fake.apk')]:
            release = self.release(); release['assets'][0][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.checked_release(release, self.tag, self.created, self.plan, 'uploaded-draft')
        for assets in ([], self.release()['assets']*2):
            with self.assertRaises(ValueError):
                delivery.checked_release({**self.release(), 'assets': assets}, self.tag, self.created, self.plan, 'uploaded-draft')

    def test_wrong_source_tag_release_identity_or_reused_nonempty_draft_fails(self):
        for key, value in [('id', 21), ('target_commitish', 'd'*40), ('prerelease', False),
                            ('tag_name', 'coachpreview-build-2019'), ('upload_url', 'https://outside.test/assets')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                delivery.checked_release({**self.release(), key: value}, self.tag, self.created, self.plan, 'uploaded-draft')
        with self.assertRaises(ValueError):
            delivery.checked_release(self.release(), {**self.tag, 'object': {'type': 'tag', 'sha': 'a'*40}},
                                     self.created, self.plan, 'uploaded-draft')
        with self.assertRaises(ValueError):
            delivery.checked_release(self.release(), self.tag, self.release(), self.plan, 'uploaded-draft')


class NativeOriginalLogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        # Explicitly synthetic mode names, never engine observations.
        self.modes = [('synthetic_'+str(i), 'headless') for i in range(48)] + sorted(delivery.NEW_NATIVE)
        self.runner = '\n'.join('check_probe '+name+" '["+name+"] PASS' "+mode
                                 for name, mode in self.modes)
        self.lines = ['probe\tmode\tresult']+[name+'\t'+mode+'\tPASS' for name, mode in self.modes]
        (self.root/'results.tsv').write_text('\n'.join(self.lines)+'\n')
        for name, mode in self.modes:
            (self.root/(name+'-'+mode+'.log')).write_text('['+name+'] PASS\n')

    def test_exact_52_order_and_four_additive_modes_are_required(self):
        self.assertEqual(len(delivery.checked_native_results(self.root, self.runner)), 52)
        with self.assertRaises(ValueError):
            delivery.checked_native_results(self.root, '\n'.join(self.runner.splitlines()[:-1]))
        with self.assertRaises(ValueError):
            delivery.checked_native_results(self.root, self.runner.replace('lumo_facial_capture', 'another_probe'))
        (self.root/'results.tsv').write_text('\n'.join(self.lines[:-1])+'\n')
        with self.assertRaises(ValueError): delivery.checked_native_results(self.root, self.runner)

    def test_reported_pass_never_overrides_post_pass_engine_error_or_missing_original(self):
        path = self.root/(self.modes[-1][0]+'-'+self.modes[-1][1]+'.log')
        original = path.read_bytes()
        for error in ('ERROR: 4 resources still in use at exit', 'SCRIPT ERROR: broken',
                      'Parse Error: invalid script', 'ObjectDB instances leaked'):
            path.write_bytes(original+error.encode()+b'\n')
            with self.subTest(error=error), self.assertRaises(ValueError):
                delivery.checked_native_results(self.root, self.runner)
        path.unlink()
        with self.assertRaises(ValueError): delivery.checked_native_results(self.root, self.runner)

    def test_actual_facial_runner_multiline_command_keeps_one_mode(self):
        original = "check_probe lumo_facial_capture '[lumo_facial_capture] PASS' rendered"
        replacement = original+' \\\n  --resolution 640x640 --fixed-fps 24 \\\n  --write-movie "$LOG_DIR/captures/lumo_facial_capture/facial-runtime.avi"'
        self.assertEqual(self.runner.count(original), 1)
        multiline = self.runner.replace(original, replacement)
        self.assertEqual(len(delivery.checked_native_results(self.root, multiline)), 52)


class OriginalBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name); self.root = self.base/'unpacked'; self.root.mkdir()
        self.archive = self.base/'original.zip'
        self.binding, _, _, _, self.artifacts = fixture()
        self.members = {'assets/sample.bin': b'explicit synthetic byte fixture\x00\xff',
                        'audit/.original.json': b'{"synthetic":true}\n'}
        for name, data in self.members.items():
            path = self.root/name; path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(data)
        self.rebuild()

    def rebuild(self, extras=()):
        with zipfile.ZipFile(self.archive, 'w', compression=zipfile.ZIP_STORED) as archive:
            for name, data in self.members.items(): archive.writestr(name, data)
            for name, data in extras: archive.writestr(name, data)
        self.api = {'id': 200, 'name': delivery.BUNDLE_ARTIFACT, 'expired': False,
                    'size_in_bytes': self.archive.stat().st_size, 'digest': 'sha256:'+delivery.digest(self.archive),
                    'workflow_run': {'id': 12345, 'head_sha': 'a'*40}}
        self.artifacts['artifacts'] = [row for row in self.artifacts['artifacts']
                                       if row['name'] != delivery.BUNDLE_ARTIFACT] + [self.api]
        self.artifacts['total_count'] = len(self.artifacts['artifacts'])

    def check(self):
        return delivery.checked_bundle(self.archive, self.root, self.artifacts, self.binding, 200)

    def test_complete_original_zip_crc_hash_and_hidden_member_roundtrip(self):
        result = self.check()
        self.assertEqual(result['artifact_id'], 200)
        self.assertEqual(set(result['members']), set(self.members))
        self.assertEqual(result['archive'], delivery.record(self.archive))

    def test_wrong_api_source_size_digest_or_identity_cannot_authorize_bundle(self):
        for obj, field, value in ((self.api, 'id', 999), (self.api, 'size_in_bytes', 1),
                                  (self.api, 'digest', 'sha256:'+'f'*64), (self.api, 'expired', True),
                                  (self.api['workflow_run'], 'head_sha', 'f'*40),
                                  (self.api['workflow_run'], 'id', 99999)):
            old = obj[field]; obj[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError): self.check()
            obj[field] = old

    def test_extra_missing_changed_or_symlinked_local_member_is_rejected(self):
        target = self.root/'assets/sample.bin'
        target.write_bytes(b'changed')
        with self.assertRaises(ValueError): self.check()
        target.unlink()
        with self.assertRaises(ValueError): self.check()
        target.symlink_to(self.root/'audit/.original.json')
        with self.assertRaises(ValueError): self.check()
        target.unlink(); target.write_bytes(self.members['assets/sample.bin'])
        (self.root/'extra.txt').write_text('not from the archive')
        with self.assertRaises(ValueError): self.check()

    def test_unsafe_or_nonregular_original_member_never_matches_a_local_bundle(self):
        for name in ('../escape', '/absolute', 'audit/./different', 'audit\\different'):
            self.rebuild([(name, b'bad')])
            with self.subTest(name=name), self.assertRaises(ValueError): self.check()
        link = zipfile.ZipInfo('link'); link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        self.rebuild([(link, b'audit/.original.json')])
        with self.assertRaises(ValueError): self.check()

    def test_actual_zip_payload_crc_error_is_rejected_even_when_api_digest_matches(self):
        raw = self.archive.read_bytes()
        old = self.members['assets/sample.bin']
        self.archive.write_bytes(raw.replace(old, b'X'+old[1:], 1))
        self.api['digest'] = 'sha256:'+delivery.digest(self.archive)
        with self.assertRaises(zipfile.BadZipFile): self.check()


class RealFilesAndCommandsTests(unittest.TestCase):
    def complete_asset_fixture(self, root, payload):
        (root/'assets').mkdir()
        for name in sorted(delivery.DELIVERY_ASSETS):
            (root/'assets'/name).write_bytes(payload if name.endswith('.apk') else b'explicit synthetic proof fixture\n')
        plan = {'schema': 1, 'versionCode': 2020, 'versionName': '0.13.8',
                'tag': 'coachpreview-build-2020', 'host_source': 'a'*40,
                'download_url': 'https://github.com/Ullmann27/lumo-lernen/releases/download/coachpreview-build-2020/Lumo-Lernen-Neu.apk',
                'assets': {p.name: delivery.record(p) for p in (root/'assets').iterdir()}}
        delivery.write_new(root/'publication-plan.json', plan)
        return plan

    def preparation_fixture(self, root):
        binding, run, pull, jobs, artifacts = fixture()
        source = root/'source'; (source/'config').mkdir(parents=True)
        pin = {'revision': binding['native_source'], 'repository': 'https://github.com/Ullmann27/lumo-godot.git'}
        delivery.write_new(source/'config/godot-source.json', pin)
        for name in ('candidate', 'runtime', 'host_compile', 'android', 'update', 'metadata',
                     'build_contracts', 'native_evidence', 'native_source'):
            (root/name).mkdir()
        (root/'android/c4').mkdir()
        payload = b'explicitly-synthetic-byte-transport-fixture-not-a-real-signed-APK'
        (root/'candidate/Lumo-Lernen-Neu.apk').write_bytes(payload)
        apk = {'package': 'dev.ullmann.lumo.lumo_lernen.coachpreview', 'versionCode': 2020,
               'versionName': '0.13.8', 'abis': ['arm64-v8a'], 'bytes': len(payload),
               'sha256': hashlib.sha256(payload).hexdigest(),
               'signingCertificateSha256': 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702',
               'godot': {'revision': 'b'*40, 'pck_sha256': 'd'*64}}
        facts = {'schema': 1, 'status': 'PASS', 'versionCode': 2020, 'versionName': '0.13.8',
                 'binding': binding, 'apks': {'arm64-v8a': apk, 'x86_64': {**apk, 'abis': ['x86_64']}}}
        delivery.write_new(root/'facts.json', facts)
        for name, value in [('run', run), ('jobs', jobs), ('artifacts', artifacts), ('pull', pull),
                            ('releases', [[]]), ('tags', [])]:
            delivery.write_new(root/'metadata'/(name+'.json'), value)
        for path, value in [('candidate/BUILD-PROVENANCE.json', {'synthetic_fixture': True}),
                            ('candidate/GODOT-SOURCE.json', pin),
                            ('android/c4/c4-result.json', {'synthetic_fixture': True}),
                            ('runtime/runtime-gate.json', {'synthetic_fixture': True}),
                            ('update/update-result.json', {'synthetic_fixture': True})]:
            delivery.write_new(root/path, value)
        log = '\n'.join([method+' (test_speech_envelope_contract.SpeechEnvelopeContractTest.'+method+') ... ok'
                         for method in delivery.PCM_CONTRACTS]
                        +['Ran 600 tests in 120.005s', 'OK', *delivery.PCM_CONTRACTS.values(), ''])
        (root/'build_contracts/build-contracts.log').write_text(log)
        args = SimpleNamespace(**{name: root/name for name in ('candidate', 'runtime', 'host_compile', 'android',
                               'update', 'metadata', 'build_contracts', 'native_evidence', 'native_source')},
                               source='a'*40, build_run=12345, run_attempt=1, artifact_id=100,
                               artifact_digest='c'*64, pull_request=999, facts=root/'facts.json', out=root/'delivery')
        return source, args, facts

    def test_prepare_reexecutes_existing_candidate_validator_and_requires_native_before_writes(self):
        with tempfile.TemporaryDirectory() as temporary:
            source, args, facts = self.preparation_fixture(Path(temporary))
            # Only the expensive real APK/runtime/device verifier is stubbed at
            # its explicit boundary. This is not an APK/device acceptance run.
            with mock.patch('verify_connect_four_candidate.verify', return_value=facts) as candidate, \
                 mock.patch.object(delivery, 'committed_pcm_sources', return_value={'fixture': {}}), \
                 mock.patch.object(delivery, 'checked_native', side_effect=ValueError('actual native evidence missing')):
                with self.assertRaisesRegex(ValueError, 'actual native evidence missing'):
                    delivery.prepare(args)
                candidate.assert_called_once_with(args)
                self.assertFalse(args.out.exists())
            with mock.patch('verify_connect_four_candidate.verify', return_value={**facts, 'versionCode': 2019}):
                with self.assertRaisesRegex(ValueError, 'Fresh complete candidate replay differs'):
                    delivery.prepare(args)
                self.assertFalse(args.out.exists())

    def test_preparation_preserves_originals_and_writes_only_unpublished_bundle_inputs(self):
        with tempfile.TemporaryDirectory() as temporary:
            source, args, facts = self.preparation_fixture(Path(temporary))
            with mock.patch('verify_connect_four_candidate.verify', return_value=facts), \
                 mock.patch.object(delivery, 'committed_pcm_sources', return_value={'fixture': {}}), \
                 mock.patch.object(delivery, 'checked_native', return_value={'fixture': True, 'core_modes': 52}) as native, \
                 mock.patch.object(delivery, 'ROOT', source), \
                 mock.patch.object(delivery.subprocess, 'check_output', return_value='e'*40+'\n'), \
                 contextlib.redirect_stdout(io.StringIO()):
                plan = delivery.prepare(args)
            native.assert_called_once_with(args.native_evidence, args.native_source, 'b'*40)
            self.assertEqual(delivery.read(args.out/'audit/create-tag.json'),
                             {'ref': 'refs/tags/coachpreview-build-2020', 'sha': 'a'*40})
            self.assertEqual(delivery.read(args.out/'audit/create-release.json')['draft'], True)
            self.assertEqual(delivery.read(args.out/'audit/publish-release.json'), {'draft': False, 'make_latest': 'false'})
            self.assertEqual(delivery.checked_plan(args.out), plan)
            self.assertEqual((args.out/'assets/C4-CANDIDATE-FACTS.json').read_bytes(), args.facts.read_bytes())
            self.assertEqual((args.out/'assets/Lumo-Lernen-Neu.apk').read_bytes(), (args.candidate/'Lumo-Lernen-Neu.apk').read_bytes())
            self.assertEqual((args.out/'audit/original-run.json').read_bytes(), (args.metadata/'run.json').read_bytes())
            self.assertFalse((args.out/'PUBLIC-DELIVERY-RECEIPT.json').exists())
            report = delivery.read(args.out/'assets/C4-DELIVERY-FACTS.json')
            self.assertEqual(report['status'], 'VERIFIED_TEST_BUNDLE_NOT_PUBLISHED')
            self.assertIs(report['published'], False)
            self.assertIs(report['release_approved'], False)

    def test_current_publication_gate_replays_completed_source_and_whole_original_bundle(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary); source, args, facts = self.preparation_fixture(root)
            with mock.patch('verify_connect_four_candidate.verify', return_value=facts), \
                 mock.patch.object(delivery, 'committed_pcm_sources', return_value={'fixture': {}}), \
                 mock.patch.object(delivery, 'checked_native', return_value={'core_modes': 52}), \
                 mock.patch.object(delivery, 'ROOT', source), \
                 mock.patch.object(delivery.subprocess, 'check_output', return_value='e'*40+'\n'), \
                 contextlib.redirect_stdout(io.StringIO()):
                delivery.prepare(args)
            archive = root/'delivery-original.zip'
            with zipfile.ZipFile(archive, 'w') as zipped:
                for path in args.out.rglob('*'):
                    if path.is_file(): zipped.write(path, path.relative_to(args.out).as_posix())
            run = delivery.read(args.metadata/'run.json'); run.update(status='completed', conclusion='success')
            jobs = delivery.read(args.metadata/'jobs.json')
            jobs['jobs'][-1].update(status='completed', conclusion='success', steps=[
                {'name': label, 'status': 'completed', 'conclusion': 'success'} for label in (
                    'Reverify actual current APKs C4 update PCM and complete native originals',
                    'Preserve the complete verified 2020 ARM64 delivery bundle without publication')])
            artifacts = delivery.read(args.metadata/'artifacts.json')
            artifacts['artifacts'].append({'id': 200, 'name': delivery.BUNDLE_ARTIFACT,
                'expired': False, 'size_in_bytes': archive.stat().st_size,
                'digest': 'sha256:'+delivery.digest(archive),
                'workflow_run': {'id': 12345, 'head_sha': 'a'*40}})
            artifacts['total_count'] += 1
            for name, value in (('run', run), ('jobs', jobs), ('artifacts', artifacts)):
                (args.metadata/(name+'.json')).write_text(json.dumps(value))
            def check(head='a'*40):
                with mock.patch.object(delivery, 'ROOT', source), \
                     mock.patch.object(delivery.subprocess, 'check_output', side_effect=[head+'\n', 'e'*40+'\n']), \
                     mock.patch.object(delivery.subprocess, 'run'):
                    return delivery.checked_current(args.out, args.metadata, archive, 200, 999)
            self.assertEqual(check()['status'], 'COMPLETE_CURRENT_ACCEPTANCE_VERIFIED_NOT_PUBLISHED')
            with self.assertRaisesRegex(ValueError, 'checkout differs'): check('f'*40)
            run['conclusion'] = 'failure'; (args.metadata/'run.json').write_text(json.dumps(run))
            with self.assertRaises(ValueError): check()

    def test_staged_bytes_cannot_change_or_hide_extra_or_symlinked_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            plan = self.complete_asset_fixture(root, b'synthetic-transport-fixture-only')
            apk = root/'assets/Lumo-Lernen-Neu.apk'
            self.assertEqual(delivery.checked_plan(root), plan)
            apk.write_bytes(b'changed')
            with self.assertRaises(ValueError): delivery.checked_plan(root)
            apk.unlink(); apk.symlink_to(root/'publication-plan.json')
            with self.assertRaises(ValueError): delivery.checked_plan(root)

    def test_duplicate_json_keys_and_overwriting_prior_delivery_metadata_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary)/'original.json'; path.write_text('{"status":"FAIL","status":"PASS"}')
            with self.assertRaises(ValueError): delivery.read(path)
            with self.assertRaises(FileExistsError): delivery.write_new(path, {'status': 'PASS'})

    def test_readonly_preparation_and_every_explicit_success_input_are_required(self):
        text = (ROOT/'.github/workflows/lumo-connect-four-2020.yml').read_text()
        block = job_block(text, delivery.DELIVERY_JOB)
        self.assertNotIn('contents: write', text)
        self.assertNotIn('actions: write', text)
        self.assertIn('contents: read', block)
        self.assertIn('actions: read', block)
        head = block.split('    steps:', 1)[0]
        expression = head.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0].replace('\n', ' ')
        values = {'github.repository': delivery.REPOSITORY, 'github.event_name': 'pull_request',
                  'github.event.pull_request.head.repo.full_name': delivery.REPOSITORY,
                  'github.head_ref': delivery.BRANCH,
                  **{'needs.'+name+'.result': 'success' for name in delivery.REQUIRED_STEPS}}
        def allowed(conditions):
            code = expression.replace('&&', 'and')
            for key in sorted(conditions, key=len, reverse=True): code = code.replace(key, repr(conditions[key]))
            return eval(code.strip(), {'__builtins__': {}}, {})
        self.assertTrue(allowed(values))
        for key in values:
            with self.subTest(key=key): self.assertFalse(allowed({**values, key: 'different'}))
        self.assertNotIn('if: always()', head)
        for name in delivery.ARTIFACT_NAMES[1:]: self.assertIn('name: '+name, block)

    def test_active_workflow_never_attempts_publication_and_uploads_complete_separate_bundle(self):
        text = (ROOT/'.github/workflows/lumo-connect-four-2020.yml').read_text()
        block = job_block(text, delivery.DELIVERY_JOB)
        for forbidden in ('--force', '--clobber', '--method DELETE', 'git push', 'verify-existing',
                          'publish-reviewed-2019', 'release_approved: true', 'gh release',
                          '--method POST', '--method PATCH', 'verify_connect_four_delivery.py verify-public',
                          'secrets.', 'contents: write'):
            self.assertNotIn(forbidden, block)
        positions = [block.index(needle) for needle in (
            'Read exact current original acceptance and release catalog',
            'verify_connect_four_delivery.py prepare', 'id: upload-delivery',
            'name: '+delivery.BUNDLE_ARTIFACT, 'path: delivery/',
            'name: lumo-connect-four-2020-delivery-verification')]
        self.assertEqual(positions, sorted(positions))
        self.assertIn('include-hidden-files: true', block)
        self.assertIn('delivery-artifact-id: ${{ steps.upload-delivery.outputs.artifact-id }}', block)
        self.assertIn('delivery-artifact-digest: ${{ steps.upload-delivery.outputs.artifact-digest }}', block)

    def test_cli_receipt_requires_actual_public_file_hash_after_release_and_tag_checks(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            payload = b'synthetic-transport-fixture-not-an-APK'
            bundle = root/'bundle'; bundle.mkdir()
            plan = self.complete_asset_fixture(bundle, payload)
            original = bundle/'assets/Lumo-Lernen-Neu.apk'
            tag = {'ref': 'refs/tags/'+plan['tag'], 'object': {'type': 'commit', 'sha': 'a'*40}}
            created = {'id': 200, 'tag_name': plan['tag'], 'target_commitish': 'a'*40,
                       'draft': True, 'prerelease': True, 'assets': [],
                       'upload_url': 'https://uploads.github.com/repos/Ullmann27/lumo-lernen/releases/200/assets{?name,label}'}
            release = {**created, 'draft': False, 'published_at': 'synthetic-time', 'immutable': False,
                       'assets': [{'id': 300+i, 'name': name, 'state': 'uploaded',
                                   'size': ident['bytes'], 'digest': 'sha256:'+ident['sha256'],
                                   'browser_download_url': plan['download_url'].rsplit('/', 1)[0]+'/'+name}
                                  for i, (name, ident) in enumerate(plan['assets'].items())]}
            for name, data in [('tag', tag), ('created', created), ('release', release)]:
                delivery.write_new(root/(name+'.json'), data)
            public = root/'actual-public-download'; public.write_bytes(b'wrong')
            receipt_path = root/'publication/PUBLIC-DELIVERY-RECEIPT.json'
            command = ['verify_connect_four_delivery.py', 'verify-public', '--delivery', str(bundle),
                       '--tag', str(root/'tag.json'), '--created', str(root/'created.json'),
                       '--release', str(root/'release.json'), '--apk', str(public), '--receipt', str(receipt_path)]
            with mock.patch.object(sys, 'argv', command), self.assertRaises(ValueError): delivery.main()
            self.assertFalse(receipt_path.exists())
            public.write_bytes(payload)
            with mock.patch.object(sys, 'argv', command), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(delivery.main(), 0)
            receipt = delivery.read(receipt_path)
            self.assertEqual(receipt['public_apk'], delivery.record(original))
            self.assertIs(receipt['github_immutable'], False)
            self.assertFalse((bundle/'PUBLIC-DELIVERY-RECEIPT.json').exists())


if __name__ == '__main__':
    unittest.main()
