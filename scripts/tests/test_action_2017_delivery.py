"""Fail-closed 2017 delivery contracts using synthetic metadata, never APK proof.

The workflow separately reruns the real APK signature/manifest/PCK verifier and
uses Android emulator artifacts. These unit tests mutate those binding records
and execute the actual initial source and publication checks without a network
or release write.
"""
from __future__ import annotations

import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / '.github/workflows/lumo-unified-integration-2026.yml'
POLICY_SPEC = importlib.util.spec_from_file_location(
    'action_2017_policy', ROOT / 'scripts/verify_legacy_release_pin.py')
POLICY = importlib.util.module_from_spec(POLICY_SPEC)
POLICY_SPEC.loader.exec_module(POLICY)
OLD_POLICY_SHA256 = '6577810bda4d3811422fc9df47733f1d2e698ede56206d9c11f850dc6150b0db'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
SYNTHETIC_SOURCE = 'a' * 40
SYNTHETIC_PCK = 'b' * 64


def publication_job() -> str:
    return WORKFLOW.read_text().split('  publish-0-13-5-2017:\n', 1)[1]


def workflow_python(step_name: str) -> str:
    section = publication_job().split('      - name: ' + step_name + '\n', 1)[1]
    section = section.split('      - name:', 1)[0]
    match = re.search(r"<<'PY'\n(.*?)\n          PY(?:\n|$)", section, re.S)
    if match is None:
        raise AssertionError('Publication guard is not present: ' + step_name)
    return textwrap.dedent(match[1])


def initial_pincheck_python() -> str:
    section = WORKFLOW.read_text().split('  verify-and-build:\n', 1)[1]
    section = section.split(
        '      - name: Save source identity and validate exact Godot integration pin\n', 1)[1]
    section = section.split('      - uses:', 1)[0]
    match = re.search(r"<<'PY'\n(.*?)\n          PY(?:\n|$)", section, re.S)
    if match is None:
        raise AssertionError('Initial workflow pincheck is not present')
    return textwrap.dedent(match[1])


BUNDLE_STEP = 'Reverify actual ARM64 bytes and bind all successful proofs to build 2017'
IMMUTABLE_STEP = 'Preserve existing releases and select create-or-verify'
RECEIPT_STEP = 'Verify the published release, immutable tag and unauthenticated Chrome APK bytes'


class Action2017InitialPincheckTests(unittest.TestCase):
    def run_pincheck(self, revision):
        source = json.loads((ROOT / 'config/godot-source.json').read_text())
        source['revision'] = revision
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            root.joinpath('config').mkdir()
            root.joinpath('config/godot-source.json').write_text(json.dumps(source))
            return subprocess.run(
                [sys.executable, '-c', initial_pincheck_python()], cwd=root,
                capture_output=True, text=True, check=False)

    def test_actual_initial_pincheck_rejects_measured_android_layout_failure(self):
        result = self.run_pincheck('0aa89cdea3a07d0c2bc0a31a153737a1fee41454')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(
            'Rejected Android menu layout: Android 2400x1080: '
            'header/tab overlap and landing model occlusion', result.stderr)

    def test_actual_initial_pincheck_accepts_the_current_reviewed_pin(self):
        result = self.run_pincheck(POLICY.APPROVED[2017])
        self.assertEqual(result.returncode, 0, result.stderr)


class Action2017PinTests(unittest.TestCase):
    def test_every_1950_through_2016_policy_entry_stays_unchanged(self):
        previous = {build: sha for build, sha in POLICY.APPROVED.items() if build < 2017}
        digest = hashlib.sha256(json.dumps(
            previous, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        self.assertEqual(digest, OLD_POLICY_SHA256)

    def test_2017_update_wrapper_requires_the_exact_reviewed_new_candidate(self):
        spec = importlib.util.spec_from_file_location(
            'action_2017_update', ROOT / '.github/probes/lumo_2017_update_android_probe.py')
        wrapper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(wrapper)
        pubspec = (ROOT / 'pubspec.yaml').read_text()
        source = (ROOT / 'config/godot-source.json').read_text()
        self.assertEqual(wrapper.reviewed_candidate_native(pubspec, source), POLICY.APPROVED[2017])
        self.assertEqual(wrapper.BASELINE_SOURCE, '2718f405e69c193d0121c6f6447fe53769d7c803')
        self.assertEqual(wrapper.BASELINE_NATIVE, POLICY.APPROVED[2015])
        for build in (2015, 2016):
            with self.subTest(build=build), self.assertRaisesRegex(ValueError, 'requires candidate version 2017'):
                old_source = json.loads(source)
                old_source['revision'] = POLICY.APPROVED[build]
                wrapper.reviewed_candidate_native(f'version: 0.13.4+{build}\n', json.dumps(old_source))
        for revision in set(POLICY.APPROVED.values()) - {POLICY.APPROVED[2017]}:
            with self.subTest(revision=revision), self.assertRaisesRegex(ValueError, 'revision mismatch'):
                wrong = json.loads(source)
                wrong['revision'] = revision
                wrapper.reviewed_candidate_native(pubspec, json.dumps(wrong))


class Action2017PublicationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.source = json.loads((ROOT / 'config/godot-source.json').read_text())
        self.native = self.source['revision']
        self.apk_bytes = b'SYNTHETIC METADATA TEST INPUT; NOT AN ANDROID APK'
        self.digest = hashlib.sha256(self.apk_bytes).hexdigest()
        self.arm = {
            'package': PACKAGE, 'versionCode': 2017, 'versionName': '0.13.5',
            'signingCertificateSha256': CERTIFICATE, 'abis': ['arm64-v8a'],
            'sha256': self.digest, 'bytes': len(self.apk_bytes),
            'godot': {'revision': self.native, 'pck_sha256': SYNTHETIC_PCK},
        }
        self.proof = dict(copy.deepcopy(self.arm), flutter_source_commit=SYNTHETIC_SOURCE,
                          tracked_source_clean=True)
        self.x86 = dict(copy.deepcopy(self.proof), abis=['x86_64'], sha256='c' * 64)
        self.update = {
            'status': 'PASS', 'candidate_source': SYNTHETIC_SOURCE,
            'baseline': {'versionCode': 2015,
                         'flutter_source_commit': '2718f405e69c193d0121c6f6447fe53769d7c803',
                         'godot': {'revision': POLICY.APPROVED[2015]}},
            'candidate': self.x86, 'offline': True, 'fatal_crashes': 0,
        }
        self.tour = {
            'status': 'PASS', 'apk_sha256': self.x86['sha256'], 'fatal_crashes': 0,
            'steps': [
                {'step': 'apk-identity', 'ok': True, 'flutter_source_commit': SYNTHETIC_SOURCE,
                 'godot_revision': self.native, 'versionCode': 2017, 'versionName': '0.13.5',
                 'signingCertificateSha256': CERTIFICATE, 'apk_sha256': self.x86['sha256'],
                 'godot_pck_sha256': SYNTHETIC_PCK},
                {'step': 'start-kart-race', 'ok': True,
                 'spatial_menu_navigation': {'status': 'PASS', 'selected_mode': 'cup',
                     'sections': [{'section': 'garage'}, {'section': 'driver'}]}},
            ],
        }
        self.documents = {
            'dist/BUILD-PROVENANCE.json': self.proof,
            'dist/APK-VERIFICATION.json': copy.deepcopy(self.arm),
            'dist/PUBLISH-VERIFICATION.json': copy.deepcopy(self.arm),
            'dist/GODOT-SOURCE.json': self.source,
            'proofs/update/update-result.json': self.update,
            'proofs/tour/tour-result.json': self.tour,
        }
        self.root.joinpath('scripts').symlink_to(ROOT / 'scripts', target_is_directory=True)
        self.root.joinpath('config').mkdir()
        self.root.joinpath('config/godot-source.json').write_text(json.dumps(self.source))
        self.root.joinpath('pubspec.yaml').write_text((ROOT / 'pubspec.yaml').read_text())
        self.root.joinpath('dist').mkdir()
        self.root.joinpath('dist/APP-VERSION.txt').write_text('version: 0.13.5+2017\n')
        self.root.joinpath('dist/Lumo-Lernen-Neu.apk').write_bytes(self.apk_bytes)

    def execute(self, step_name, documents=None):
        for name, document in (self.documents if documents is None else documents).items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(document))
        before = Path.cwd()
        try:
            os.chdir(self.root)
            with patch.dict(os.environ, {'SOURCE_SHA': SYNTHETIC_SOURCE, 'GITHUB_OUTPUT': str(self.root / 'github-output')}), \
                    patch.object(sys, 'path', list(sys.path)), contextlib.redirect_stdout(io.StringIO()):
                exec(compile(workflow_python(step_name), str(WORKFLOW), 'exec'), {})
        finally:
            os.chdir(before)

    def test_matching_measured_bytes_and_both_live_android_proofs_are_bound(self):
        self.execute(BUNDLE_STEP)
        facts = json.loads(self.root.joinpath('dist/RELEASE-FACTS.json').read_text())
        self.assertEqual(facts['apkSha256'], self.digest)
        self.assertEqual(facts['versionCode'], 2017)
        self.assertEqual(facts['godotSourceCommit'], POLICY.APPROVED[2017])
        self.assertIn('not Google Play', facts['signingScope'])

    def test_any_arm64_identity_byte_or_signature_mismatch_fails_closed(self):
        for file in ('dist/BUILD-PROVENANCE.json', 'dist/APK-VERIFICATION.json',
                     'dist/PUBLISH-VERIFICATION.json'):
            for key, wrong in (
                ('versionCode', 2016), ('versionName', '0.13.4'), ('package', 'wrong.app'),
                ('signingCertificateSha256', 'd' * 64), ('abis', ['x86_64']),
                ('sha256', '0' * 64), ('bytes', len(self.apk_bytes) + 1),
                ('godot', {'revision': POLICY.APPROVED[2016]}),
            ):
                with self.subTest(file=file, key=key), self.assertRaises((AssertionError, KeyError)):
                    changed = copy.deepcopy(self.documents)
                    changed[file][key] = wrong
                    self.execute(BUNDLE_STEP, changed)
        self.root.joinpath('dist/Lumo-Lernen-Neu.apk').write_bytes(b'CHANGED BYTES')
        with self.assertRaises(AssertionError):
            self.execute(BUNDLE_STEP)

    def test_old_source_failed_upgrade_missing_menu_and_other_tested_apk_are_rejected(self):
        changes = [
            ('dist/BUILD-PROVENANCE.json', ('flutter_source_commit',), 'e' * 40),
            ('dist/BUILD-PROVENANCE.json', ('tracked_source_clean',), False),
            ('proofs/update/update-result.json', ('status',), 'FAIL'),
            ('proofs/update/update-result.json', ('candidate_source',), 'e' * 40),
            ('proofs/update/update-result.json', ('baseline', 'versionCode'), 2014),
            ('proofs/update/update-result.json', ('candidate', 'sha256'), 'f' * 64),
            ('proofs/update/update-result.json', ('candidate', 'godot', 'revision'), POLICY.APPROVED[2016]),
            ('proofs/update/update-result.json', ('offline',), False),
            ('proofs/update/update-result.json', ('fatal_crashes',), 1),
            ('proofs/tour/tour-result.json', ('status',), 'FAIL'),
            ('proofs/tour/tour-result.json', ('apk_sha256',), 'f' * 64),
            ('proofs/tour/tour-result.json', ('steps',), []),
            ('proofs/tour/tour-result.json', ('steps',), [copy.deepcopy(self.tour['steps'][0])]),
            ('proofs/tour/tour-result.json', ('fatal_crashes',), 1),
        ]
        for file, path, wrong in changes:
            with self.subTest(file=file, path=path), self.assertRaises((AssertionError, KeyError)):
                changed = copy.deepcopy(self.documents)
                target = changed[file]
                for key in path[:-1]:
                    target = target[key]
                target[path[-1]] = wrong
                self.execute(BUNDLE_STEP, changed)

    def test_existing_release_or_version_tag_cannot_be_replaced(self):
        good = {'dist/RELEASE-PAGES.json': [[{'tag_name': 'coachpreview-build-2015'}]],
                'dist/EXISTING-TAGS.json': []}
        self.execute(IMMUTABLE_STEP, good)
        for file, bad in (
            ('dist/RELEASE-PAGES.json', [[{'tag_name': 'coachpreview-build-2017'}]]),
            ('dist/EXISTING-TAGS.json', [{'ref': 'refs/tags/coachpreview-build-2017'}]),
        ):
            with self.subTest(file=file), self.assertRaises(AssertionError):
                self.execute(IMMUTABLE_STEP, dict(copy.deepcopy(good), **{file: bad}))

    def test_same_source_completed_release_selects_verification_without_asset_mutation(self):
        documents = {
            'dist/RELEASE-PAGES.json': [[{
                'tag_name': 'coachpreview-build-2017', 'draft': False, 'prerelease': True,
                'assets': [{'name': 'Lumo-Lernen-Neu.apk', 'state': 'uploaded'}],
            }]],
            'dist/EXISTING-TAGS.json': [{
                'ref': 'refs/tags/coachpreview-build-2017',
                'object': {'type': 'commit', 'sha': SYNTHETIC_SOURCE},
            }],
        }
        self.execute(IMMUTABLE_STEP, documents)
        state = json.loads(self.root.joinpath('dist/RELEASE-STATE.json').read_text())
        self.assertEqual(state, {'mode': 'verify-existing'})
        for sha in ('e' * 40, ''):
            with self.subTest(sha=sha), self.assertRaises(AssertionError):
                changed = copy.deepcopy(documents)
                changed['dist/EXISTING-TAGS.json'][0]['object']['sha'] = sha
                self.execute(IMMUTABLE_STEP, changed)

    def test_public_receipt_requires_exact_tag_commit_size_and_direct_asset(self):
        good = {
            'dist/RELEASE-FACTS.json': {'apkBytes': len(self.apk_bytes)},
            'dist/PUBLISHED-TAG.json': {'object': {'type': 'commit', 'sha': SYNTHETIC_SOURCE}},
            'dist/PUBLISHED-RELEASE.json': {
                'draft': False, 'prerelease': True, 'tag_name': 'coachpreview-build-2017',
                'assets': [{'name': 'Lumo-Lernen-Neu.apk', 'state': 'uploaded', 'size': len(self.apk_bytes),
                    'browser_download_url': 'https://github.com/Ullmann27/lumo-lernen/releases/download/coachpreview-build-2017/Lumo-Lernen-Neu.apk'}]},
        }
        self.execute(RECEIPT_STEP, good)
        for field, wrong in (('draft', True), ('prerelease', False), ('tag_name', 'coachpreview-build-2016'),
                             ('assets', [])):
            with self.subTest(field=field), self.assertRaises(AssertionError):
                changed = copy.deepcopy(good)
                changed['dist/PUBLISHED-RELEASE.json'][field] = wrong
                self.execute(RECEIPT_STEP, changed)
        wrong_tag = copy.deepcopy(good)
        wrong_tag['dist/PUBLISHED-TAG.json']['object']['sha'] = 'e' * 40
        with self.assertRaises(AssertionError):
            self.execute(RECEIPT_STEP, wrong_tag)


if __name__ == '__main__':
    unittest.main()
