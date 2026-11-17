"""Execute the current Graphics publisher guard and its workflow dependencies.

Fixtures exercise orchestration only; they are not APK or Android acceptance.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
GRAPHICS = '.github/workflows/lumo-kart-graphics-2019.yml'
STUDIO = '.github/workflows/lumo-studio-2019.yml'
SOURCE = 'a' * 40
NATIVE = 'b' * 40
PCK = 'c' * 64
DIGEST = 'd' * 64
BASE_GATES = ['verify-and-build', 'android-host-compile', 'android-tour',
              'update-2019-from-2017']


def job(source, name):
    match = re.search(r'^  ' + re.escape(name) + r':\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)',
                      source, re.M | re.S)
    if match is None:
        raise AssertionError('Missing real workflow job: ' + name)
    return match[1]


def step(source, name):
    return source.split('      - name: ' + name + '\n', 1)[1].split('\n      - ', 1)[0]


def condition(source, values):
    expression = source.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0]
    expression = expression.replace('\n', ' ').replace('&&', 'and').replace('||', 'or').strip()
    for key in sorted(values, key=len, reverse=True):
        expression = expression.replace(key, repr(values[key]))
    return eval(expression, {'__builtins__': {}}, {})


class GraphicsCreativePipelineTests(unittest.TestCase):
    def setUp(self):
        self.source = (ROOT / GRAPHICS).read_text()
        self.verifier = job(self.source, 'verify-reviewed-2019')
        self.publisher = job(self.source, 'publish-reviewed-2019')

    def values(self, gates, branch='chatgpt/lumo-kart-graphics-apk-20261113'):
        return {'github.event_name': 'pull_request', 'github.repository': 'Ullmann27/lumo-lernen',
                'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
                'github.event.pull_request.head.ref': branch,
                **{'needs.' + gate + '.result': 'success' for gate in gates}}

    def test_both_workflows_bind_probe_calls_to_actual_upload_outputs(self):
        for workflow, candidate in [(GRAPHICS, 'lumo-kart-graphics-2019-candidate'),
                                    (STUDIO, 'lumo-studio-2019-candidate')]:
            with self.subTest(workflow=workflow):
                source = (ROOT / workflow).read_text()
                build = job(source, 'verify-and-build')
                creative = job(source, 'creative-android')
                upload = step(build, 'Upload exact candidate (no release or synthetic screenshots)')
                self.assertIn('id: upload-candidate', upload)
                self.assertIn('name: ' + candidate, upload)
                for field in ('artifact-id', 'artifact-digest'):
                    self.assertIn('${{ steps.upload-candidate.outputs.' + field + ' }}', build)
                    self.assertIn('${{ needs.verify-and-build.outputs.candidate-' + field + ' }}', creative)
                self.assertIn('needs: [verify-and-build, android-host-compile]', creative)
                self.assertIn('ref: ${{ github.event.pull_request.head.sha || github.sha }}', creative)
                self.assertIn('ref: ${{ steps.native-pin.outputs.revision }}', creative)
                self.assertIn('artifact-ids: ${{ needs.verify-and-build.outputs.candidate-artifact-id }}', creative)
                self.assertNotIn('run-id:', creative)
                self.assertNotIn('continue-on-error', creative)
                commands = [line.strip().removeprefix('script: ') for line in creative.splitlines()
                            if '.github/probes/studio_creative_android_probe.py ' in line]
                self.assertEqual(len(commands), 2)
                for command in commands:
                    args = shlex.split(command)
                    self.assertEqual(args.count('--workflow-path'), 1)
                    self.assertEqual(args[args.index('--workflow-path') + 1], workflow)
                    for flag, value in [('--build-run', '$GITHUB_RUN_ID'),
                                        ('--artifact-id', '$CANDIDATE_ARTIFACT_ID'),
                                        ('--artifact-digest', '$CANDIDATE_ARTIFACT_DIGEST')]:
                        self.assertEqual(args[args.index(flag) + 1], value)

    def test_every_independent_gate_must_succeed_before_verify_or_publish(self):
        for block, gates in [(self.verifier, BASE_GATES + ['creative-android']),
                             (self.publisher, BASE_GATES + ['verify-reviewed-2019', 'creative-android'])]:
            actual = re.search(r'^    needs: \[(.*?)\]$', block, re.M)[1].split(', ')
            self.assertEqual(actual, gates)
            values = self.values(gates)
            self.assertTrue(condition(block, values))
            for gate in gates:
                for state in ('failure', 'skipped', 'cancelled'):
                    with self.subTest(gate=gate, state=state, publisher=block is self.publisher):
                        changed = {**values, 'needs.' + gate + '.result': state}
                        self.assertFalse(condition(block, changed))

    def test_integration_verifies_but_cannot_publish_and_foreign_sources_are_rejected(self):
        gates = BASE_GATES + ['verify-reviewed-2019', 'creative-android']
        values = self.values(gates, 'integration/lumo-connections-20261113')
        self.assertTrue(condition(self.verifier, values))
        self.assertFalse(condition(self.publisher, values))
        for key, value in [('github.event_name', 'workflow_dispatch'),
                           ('github.event.pull_request.head.repo.full_name', 'external/fork'),
                           ('github.event.pull_request.head.ref', 'unreviewed-branch')]:
            with self.subTest(key=key):
                changed = {**self.values(gates), key: value}
                self.assertFalse(condition(self.verifier, changed))
                self.assertFalse(condition(self.publisher, changed))

    def test_final_verify_runs_the_real_creative_verifier_before_delivery_upload(self):
        for workflow, block in [(GRAPHICS, self.verifier),
                                (STUDIO, job((ROOT / STUDIO).read_text(), 'publish-reviewed-2019'))]:
            with self.subTest(workflow=workflow):
                invocation = next(line.strip() for line in block.splitlines()
                                  if 'scripts/verify_studio_creative_android.py ' in line)
                args = shlex.split(invocation)
                for flag, value in [('--workflow-path', workflow), ('--source-sha', '$SOURCE_SHA'),
                                    ('--build-run', '$GITHUB_RUN_ID'),
                                    ('--artifact-id', '$CANDIDATE_ARTIFACT_ID'),
                                    ('--artifact-digest', '$CANDIDATE_ARTIFACT_DIGEST'),
                                    ('--creative', 'proofs/creative'),
                                    ('--main-tour', 'proofs/tour/tour-result.json'),
                                    ('--out', 'dist/CREATIVE-ANDROID-FACTS.json')]:
                    self.assertEqual(args[args.index(flag) + 1], value)
                verification = step(block, 'Reverify actual ARM64 bytes and bind all live proofs to the reviewed 2019 source')
                self.assertIn('set -euo pipefail', verification)
                self.assertNotIn('||', invocation)
                self.assertLess(block.index('path: proofs/creative/'), block.index(invocation))
                destination = ('name: lumo-kart-graphics-2019-delivery-verified'
                               if workflow == GRAPHICS else 'gh release create')
                self.assertLess(block.index(invocation), block.index(destination))
        self.assertIn('dist/CREATIVE-ANDROID-FACTS.json', self.verifier)
        self.assertIn('dist/CREATIVE-ANDROID-FACTS.json \\', self.publisher)

    def run_publisher_guard(self, creative_change=None, missing=False, altered_pck=False):
        current_step = step(self.publisher, 'Recheck accepted artifact bytes and exact sources before publication')
        code = re.search(r"python3 - <<'PY'\n(.*?)^          PY$", current_step, re.M | re.S)
        self.assertIsNotNone(code)
        executable = textwrap.dedent(code[1])
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'dist').mkdir()
            (root / 'config').mkdir()
            apk = b'publisher guard fixture; not an installable APK'
            (root / 'dist/Lumo-Lernen-Neu.apk').write_bytes(apk)
            facts = {'flutterSourceCommit': SOURCE, 'godotSourceCommit': NATIVE,
                     'versionCode': 2019, 'versionName': '0.13.7',
                     'apkBytes': len(apk), 'apkSha256': hashlib.sha256(apk).hexdigest()}
            creative = {'status': 'FUNCTIONAL_CONTRACTS_PASSED_VISUAL_REVIEW_PENDING',
                        'visual_motion_review': 'REQUIRED', 'host_source': SOURCE,
                        'native_source': NATIVE, 'workflow_path': GRAPHICS, 'build_run': 123,
                        'artifact_id': 456, 'artifact_digest': 'sha256:' + DIGEST,
                        'pck_sha256': PCK}
            creative.update(creative_change or {})
            files = {'config/godot-source.json': {'revision': NATIVE},
                     'dist/RELEASE-FACTS.json': facts,
                     'dist/CREATIVE-ANDROID-FACTS.json': creative,
                     'dist/PUBLISH-VERIFICATION.json': {'godot': {'pck_sha256': PCK}},
                     'dist/BUILD-PROVENANCE.json': {'godot': {'pck_sha256': '0' * 64 if altered_pck else PCK}}}
            if missing:
                del files['dist/CREATIVE-ANDROID-FACTS.json']
            for name, data in files.items():
                (root / name).write_text(json.dumps(data))
            env = {**os.environ, 'SOURCE_SHA': SOURCE, 'GITHUB_RUN_ID': '123',
                   'CANDIDATE_ARTIFACT_ID': '456', 'CANDIDATE_ARTIFACT_DIGEST': DIGEST}
            return subprocess.run([sys.executable, '-B', '-c', executable], cwd=root,
                                  env=env, text=True, capture_output=True, check=False)

    def test_actual_publisher_guard_accepts_bound_functional_facts(self):
        result = self.run_publisher_guard()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_actual_publisher_guard_rejects_missing_stale_or_false_creative_facts(self):
        self.assertNotEqual(self.run_publisher_guard(missing=True).returncode, 0)
        changes = {'host_source': '0' * 40, 'native_source': '0' * 40,
                   'workflow_path': STUDIO, 'build_run': 122, 'artifact_id': 455,
                   'artifact_digest': 'sha256:' + '0' * 64, 'pck_sha256': '0' * 64,
                   'status': 'PASS', 'visual_motion_review': 'APPROVED'}
        for key, value in changes.items():
            with self.subTest(field=key):
                self.assertNotEqual(self.run_publisher_guard({key: value}).returncode, 0)
        self.assertNotEqual(self.run_publisher_guard(altered_pck=True).returncode, 0)


if __name__ == '__main__':
    unittest.main()
