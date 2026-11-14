"""Isolated workflow routing and the real renderer-report program.

Synthetic inputs and one byte-preserved CI snapshot exercise the embedded
report program. This local replay is not an emulator/backend acceptance result.
"""
from __future__ import annotations

import base64
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
OLD = '.github/workflows/lumo-unchanged-apk-diagnostic.yml'
NEW = '.github/workflows/lumo-android-runtime-7b16-followup.yml'
BRANCH = 'qa/lumo-android-runtime-7b16-followup-20261114'
ADDED_CONTRACTS = (
    'scripts.tests.test_android_runtime_device_logger',
    'scripts.tests.test_runtime_logcat_sections',
    'scripts.tests.test_runtime_followup_workflow',
    'scripts.tests.test_unchanged_apk_followup',
    'tools.android_qa.tests.test_nextgen_speech_logcat_recovery',
    'tools.android_qa.tests.test_studio_speech_logcat_recovery',
)


class RuntimeFollowupWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.old = (ROOT / OLD).read_text()
        self.source = (ROOT / NEW).read_text()

    def test_entire_original_workflow_is_preserved_outside_the_named_additions(self):
        value = self.source
        for original, replacement in (
            ('name: LUMO unchanged 7b16 APK Android diagnostic',
             'name: LUMO unchanged 7b16 APK Android runtime follow-up'),
            ('lumo-unchanged-7b16-diagnostic-${{', 'lumo-unchanged-7b16-followup-${{'),
            ('qa/lumo-android-runtime-7b16-20261114', BRANCH),
            ('name: diagnostic-probe-contracts', 'name: followup-diagnostic-probe-contracts'),
            ('lumo-7b16-diagnostic-', 'lumo-7b16-followup-diagnostic-'),
            ('unchanged-apk-${{ matrix.case }}', 'unchanged-apk-followup-${{ matrix.case }}'),
            ('--workflow ' + OLD, '--workflow ' + NEW),
            ('          # between the two API37 jobs. The observers are identical in both.',
             '          # between the three API37 jobs. All use the same strict observers.'),
        ):
            self.assertIn(replacement, value)
            value = value.replace(replacement, original)
        for name in ADDED_CONTRACTS:
            line = '            ' + name + ' \\\n'
            self.assertEqual(value.count(line), 1)
            value = value.replace(line, '')
        extra = ('          - case: api37-swangle\n            api: 37\n'
                 '            renderer: swangle\n            minutes: 65\n')
        self.assertEqual(value.count(extra), 1)
        self.assertEqual(value.replace(extra, ''), self.old)

    def test_actual_contract_condition_accepts_only_the_own_trusted_branch(self):
        expression = self.source.split('    if: >-\n', 1)[1].split('\n    name:', 1)[0]
        expression = expression.replace('&&', 'and').replace('||', 'or').replace('\n', ' ')
        defaults = {'github.repository': 'Ullmann27/lumo-lernen',
                    'github.event_name': 'pull_request',
                    'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
                    'github.head_ref': BRANCH, 'github.ref_name': '480/merge'}
        def evaluate(**overrides):
            values = {**defaults, **overrides}
            result = expression
            for key in sorted(values, key=len, reverse=True):
                result = result.replace(key, repr(values[key]))
            return eval(result, {'__builtins__': {}}, {})
        self.assertTrue(evaluate())
        self.assertTrue(evaluate(**{'github.event_name': 'workflow_dispatch',
                                   'github.head_ref': '', 'github.ref_name': BRANCH}))
        for key, value in (('github.head_ref', 'qa/lumo-android-runtime-7b16-20261114'),
                           ('github.head_ref', 'main'),
                           ('github.event.pull_request.head.repo.full_name', 'foreign/fork'),
                           ('github.repository', 'foreign/fork'),
                           ('github.event_name', 'push')):
            with self.subTest(key=key, value=value):
                self.assertFalse(evaluate(**{key: value}))

    def test_five_separate_jobs_keep_same_apk_and_one_axis_renderer_configuration(self):
        cases = re.findall(r'^          - case: (\S+)\n            api: (\d+)\n'
                           r'            renderer: (\S+)\n            minutes: (\d+)$',
                           self.source, re.M)
        self.assertEqual(cases, [('api35', '35', 'host', '65'),
                                 ('api37-host', '37', 'host', '65'),
                                 ('api37-swiftshader', '37', 'swiftshader', '65'),
                                 ('api37-swangle', '37', 'swangle', '65'),
                                 ('update2017', '35', 'host', '55')])
        names = ['unchanged-apk-followup-' + case[0] for case in cases]
        self.assertEqual(len(set(names)), 5)
        self.assertIn('    name: unchanged-apk-followup-${{ matrix.case }}', self.source)
        self.assertIn('DIAGNOSTIC_JOB_NAME: unchanged-apk-followup-${{ matrix.case }}', self.source)
        self.assertEqual(re.findall(r'^  ([\w-]+):$', self.source, re.M)[-2:],
                         ['probe-contracts', 'android-diagnostic'])
        self.assertIn('    needs: [probe-contracts]', self.source)
        self.assertIn('      fail-fast: false', self.source)
        self.assertIn("artifact-ids: '14093773196'", self.source)
        self.assertIn('run-id: 43540111465', self.source)
        self.assertIn('CANDIDATE_SOURCE: 7b16f2f5ab16f3d913ee170aefd9807c87216260', self.source)
        self.assertIn('--workflow ' + NEW, self.source)
        self.assertIn('-gpu ${{ matrix.renderer }} -no-snapshot', self.source)
        self.assertNotIn('continue-on-error:', self.source)


class ActualRendererReportTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        wrapper = (ROOT / 'scripts/run_unchanged_apk_diagnostic.sh').read_text()
        self.program = wrapper.split('<<\'PY\'\n', 1)[1].split('\nPY\n', 1)[0]
        self.baseline = json.loads((ROOT / 'config/diagnostic-baselines/android37-7b16.json').read_text())
        self.framework = self.root / 'tour/framework-start'
        for relative in self.baseline['package_files']:
            target = self.framework / 'cli22/packages-guard' / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            data = ('SYNTHETIC package file for report contract: ' + relative).encode()
            target.write_bytes(data)
            self.baseline['package_files'][relative] = {
                'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        path = self.root / 'config/diagnostic-baselines/android37-7b16.json'
        path.parent.mkdir(parents=True)
        path.write_text(json.dumps(self.baseline))
        (self.framework / 'framework-readiness.json').write_text(json.dumps({
            'status': 'PASS', 'samples': [{'android_runtime': self.baseline['android_runtime']}]}))

    def observe(self, case, gpu, gles, *, changed_hardware=None, launch=None):
        values = {**self.baseline['effective_hardware_unchanged'], 'hw.gpu.mode': gpu,
                  **(changed_hardware or {})}
        path = self.framework / 'cli22/avd-guard/configuration/hardware-qemu.ini'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(''.join(key + '=' + value + '\n' for key, value in values.items()))
        if launch is None:
            requested = {'api37-host': 'host', 'api37-swiftshader': 'swiftshader',
                         'api37-swangle': 'swangle'}[case]
            launch = self.launch_fixture(['/synthetic/sdk/emulator/emulator', '-gpu', requested])
        path.with_name('emu-launch-params.txt').write_text(launch)
        (self.root / 'tour/surfaceflinger-start.stdout').write_text(gles)
        return self.report(case)

    @staticmethod
    def launch_fixture(argv, *, count=None, executable=None):
        return '\n'.join(['/synthetic/workspace', executable or argv[0],
                          str(len(argv) if count is None else count), *argv]) + '\n'

    def report(self, case):
        result = subprocess.run([sys.executable, '-B', '-c', self.program, str(self.root), case],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        report = json.loads((self.root / 'tour/renderer-comparison-binding.json').read_text())
        return result, report

    def test_actual_report_requires_angle_and_swiftshader_with_effective_swiftshader_backend(self):
        result, report = self.observe('api37-swangle', 'swiftshader',
            'GLES: Synthetic Google renderer, ANGLE (Google, SwiftShader Device), OpenGL ES 3.0\n')
        self.assertEqual(result.returncode, 0, result.stdout.decode())
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['requested_gpu'], 'swangle')
        self.assertTrue(all(report['checks'].values()))

    def test_pure_swiftshader_unproven_swangle_or_multiple_gles_lines_cannot_pass(self):
        for text in ('GLES: Google SwiftShader, OpenGL ES 3.0 SwiftShader 4.0.0.1\n',
                     'GLES: SWANGLE\n', 'GLES: ANGLE Vulkan\n', '',
                     'GLES: ANGLE SwiftShader\nGLES: ANGLE SwiftShader\n'):
            with self.subTest(gles=text):
                result, report = self.observe('api37-swangle', 'swiftshader', text)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(report['status'], 'FAIL')
                self.assertFalse(report['checks']['one_actual_gles_renderer_matches_case'])

    def test_actual_gpu_or_unchanged_hardware_mismatch_remains_failure(self):
        result, report = self.observe('api37-swangle', 'host', 'GLES: ANGLE SwiftShader\n')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(report['checks']['effective_gpu_mode_matches_requested_case'])
        key = next(iter(self.baseline['effective_hardware_unchanged']))
        result, report = self.observe('api37-swangle', 'swiftshader', 'GLES: ANGLE SwiftShader\n',
                                      changed_hardware={key: 'CHANGED'})
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(report['checks']['same_effective_non_graphics_hardware'])

    def test_existing_host_and_swiftshader_positive_requirements_are_preserved(self):
        for case, gpu, text in (('api37-host', 'host', 'GLES: Mesa llvmpipe\n'),
                                ('api37-swiftshader', 'swiftshader', 'GLES: Google SwiftShader\n')):
            with self.subTest(case=case):
                result, report = self.observe(case, gpu, text)
                self.assertEqual(result.returncode, 0, result.stdout.decode())
                self.assertTrue(all(report['checks'].values()))

    def test_original08e_swangle_snapshot_preserves_bytes_and_passes_only_backend_binding(self):
        fixture_path = ROOT / 'scripts/tests/fixtures/api37-swangle-08e63bd3-renderer.json.gz'
        fixture = json.loads(gzip.decompress(fixture_path.read_bytes()))
        self.assertEqual(fixture['artifact']['id'], 14105941453)
        self.assertEqual(fixture['artifact']['sha256'],
                         '18346b2b68cf72ab0d5423365dfef7ca66f998b7a8f215feddbdb75f9505f3e1')
        self.assertEqual(fixture['source'], '08e63bd32917a6672ae99b66a17c3fa57c83977a')
        self.assertEqual(fixture['tree'], '04859a04ad84d14120109bdc1bb27684f534a5f3')
        self.assertEqual((fixture['run'], fixture['attempt'], fixture['job']),
                         (43574161418, 1, 132384862707))
        expected = {
            'renderer-comparison-binding.json', 'surfaceflinger-start.stdout',
            'framework-start/framework-readiness.json',
            'framework-start/cli22/avd-guard/configuration/hardware-qemu.ini',
            'framework-start/cli22/avd-guard/configuration/emu-launch-params.txt',
            'framework-start/cli22/packages-guard/emulator/source.properties',
            'framework-start/cli22/packages-guard/emulator/package.xml',
            'framework-start/cli22/packages-guard/image/source.properties',
            'framework-start/cli22/packages-guard/image/package.xml',
        }
        self.assertEqual(set(fixture['files']), expected)
        originals = {}
        for relative, entry in fixture['files'].items():
            data = base64.b64decode(entry['base64'], validate=True)
            self.assertEqual(len(data), entry['bytes'])
            self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'])
            originals[relative] = data
            path = self.root / 'tour' / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        baseline = (ROOT / 'config/diagnostic-baselines/android37-7b16.json').read_bytes()
        self.assertEqual(hashlib.sha256(baseline).hexdigest(), fixture['baseline_sha256'])
        (self.root / 'config/diagnostic-baselines/android37-7b16.json').write_bytes(baseline)
        original_report = json.loads(originals['renderer-comparison-binding.json'])
        self.assertEqual(original_report['status'], 'FAIL')
        self.assertEqual([name for name, passed in original_report['checks'].items() if not passed],
                         ['effective_gpu_mode_matches_requested_case'])
        result, report = self.report('api37-swangle')
        self.assertEqual(result.returncode, 0, result.stdout.decode())
        self.assertEqual(report['status'], 'PASS')
        self.assertEqual(report['requested_gpu'], 'swangle')
        self.assertEqual(report['expected_effective_gpu_mode'], 'swiftshader')
        self.assertEqual(report['effective_hardware'], original_report['effective_hardware'])
        self.assertEqual(report['observed_gles'], original_report['observed_gles'])
        self.assertEqual(report['package_files'], original_report['package_files'])
        self.assertEqual(report['hardware_sha256'], original_report['hardware_sha256'])
        self.assertEqual(report['emulator_launch']['argc'], 19)
        self.assertEqual(report['emulator_launch']['gpu_options'], ['swangle'])
        launch = originals['framework-start/cli22/avd-guard/configuration/emu-launch-params.txt']
        self.assertEqual(report['emulator_launch']['sha256'], hashlib.sha256(launch).hexdigest())
        self.assertTrue(all(report['checks'].values()))
        for relative, data in originals.items():
            if relative != 'renderer-comparison-binding.json':
                self.assertEqual((self.root / 'tour' / relative).read_bytes(), data)

    def test_wrong_missing_or_ambiguous_recorded_gpu_request_cannot_pass(self):
        binary = '/synthetic/sdk/emulator/emulator'
        correct = [binary, '-gpu', 'swangle']
        launches = {
            'missing': self.launch_fixture([binary]),
            'wrong-case': self.launch_fixture([binary, '-gpu', 'swiftshader']),
            'duplicate-same': self.launch_fixture([*correct, '-gpu', 'swangle']),
            'duplicate-other': self.launch_fixture([*correct, '-gpu', 'host']),
            'inline-override': self.launch_fixture([*correct, '-gpu=host']),
            'legacy-alias': self.launch_fixture([binary, '-gpu', 'swangle_indirect']),
            'missing-value': self.launch_fixture([binary, '-gpu']),
            'wrong-argc': self.launch_fixture(correct, count=2),
            'different-executable': self.launch_fixture(correct, executable='/different/emulator'),
            'empty-record': '',
        }
        for name, launch in launches.items():
            with self.subTest(mutation=name):
                result, report = self.observe('api37-swangle', 'swiftshader',
                    'GLES: ANGLE SwiftShader\n', launch=launch)
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(report['checks']['recorded_emulator_launch_matches_requested_case'])
                self.assertEqual(report['status'], 'FAIL')
        launch_path = self.framework / 'cli22/avd-guard/configuration/emu-launch-params.txt'
        launch_path.unlink()
        report_path = self.root / 'tour/renderer-comparison-binding.json'
        report_path.unlink()
        result = subprocess.run([sys.executable, '-B', '-c', self.program, str(self.root),
                                 'api37-swangle'], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(report_path.exists())
        self.assertIn(b'emu-launch-params.txt', result.stdout)

    def test_swangle_effective_backend_is_exact_not_a_permissive_alias_set(self):
        for backend in ('swangle', 'auto', 'host', 'swiftshader_indirect', ''):
            with self.subTest(backend=backend):
                result, report = self.observe('api37-swangle', backend, 'GLES: ANGLE SwiftShader\n')
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(report['checks']['effective_gpu_mode_matches_requested_case'])
                self.assertTrue(report['checks']['recorded_emulator_launch_matches_requested_case'])
                self.assertTrue(report['checks']['one_actual_gles_renderer_matches_case'])



if __name__ == '__main__':
    unittest.main()
