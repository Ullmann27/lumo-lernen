"""Exact isolated Console/Joystick routing and retained transport contracts.

Metadata and tiny exporter files are explicitly synthetic. The prepare shell
step executes the actual transport CLI without starting a socket or emulator.
These tests do not establish Android, renderer or runtime-ANR acceptance.
"""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = '.github/workflows/lumo-console-joystick-7b16.yml'
BRANCH = 'qa/lumo-console-joystick-7b16-20261114'
OLD_RUNTIME = '.github/workflows/lumo-android-runtime-7b16-followup.yml'
OLD_CREATIVE = '.github/workflows/lumo-creative-7b16-diagnostic.yml'
SOURCE, TREE, RUN = 'a' * 40, 'b' * 40, 900001


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


common = load('console_joystick_binding', 'scripts/verify_unchanged_apk_diagnostic.py')
creative = load('console_joystick_creative', 'scripts/run_unchanged_creative_diagnostic.py')
exporter = load('console_joystick_exporter', 'scripts/export_creative_evidence_parts.py')


def original_metadata():
    run = {'id': RUN, 'head_sha': SOURCE, 'run_attempt': 1,
           'status': 'in_progress', 'conclusion': None, 'path': WORKFLOW,
           'head_branch': BRANCH,
           'repository': {'id': common.REPOSITORY_ID, 'full_name': common.REPOSITORY},
           'head_commit': {'id': SOURCE, 'tree_id': TREE}}
    rows = [{'id': 900100 + i, 'run_id': RUN, 'head_sha': SOURCE,
             'run_attempt': 1, 'name': name, 'status': 'in_progress', 'conclusion': None}
            for i, name in enumerate(common.CONSOLE_JOYSTICK_QA_JOBS)]
    return run, {'total_count': len(rows), 'jobs': rows}


def verify(run, jobs, name):
    return common.verify_qa(run, jobs, source=SOURCE, run_id=RUN, attempt=1, job_name=name)


def job(text, name):
    return re.search(r'^  ' + re.escape(name) + r':\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)',
                     text, re.M | re.S)[1]


def step(text, name):
    return text.split('      - name: ' + name + '\n', 1)[1].split('\n      - ', 1)[0]


def condition(value, values):
    expression = value.replace('&&', 'and').replace('||', 'or').replace('\n', ' ')
    for key in sorted(values, key=len, reverse=True):
        expression = expression.replace(key, repr(values[key]))
    return eval(expression, {'__builtins__': {}}, {})


class ConsoleJoystickRouteTests(unittest.TestCase):
    def test_four_exact_jobs_bind_new_workflow_without_repeating_api35_or_update(self):
        expected = (
            'unchanged-apk-console-joystick-api37-host',
            'unchanged-apk-console-joystick-api37-swiftshader',
            'unchanged-apk-console-joystick-api37-swangle',
            'unchanged-apk-console-joystick-creative-api35',
        )
        self.assertEqual(common.CONSOLE_JOYSTICK_QA_JOBS, expected)
        for name in expected:
            value = verify(*original_metadata(), name)
            self.assertEqual((value['workflow_path'], value['branch']), (WORKFLOW, BRANCH))
            self.assertEqual(value['job_name'], name)
            self.assertNotEqual(value['source'], common.HOST)
            self.assertIsNone(value['job_conclusion'])
        for case in ('api35', 'update2017', 'api37-angle', 'api37-swangle-extra'):
            with self.subTest(case=case), self.assertRaises(RuntimeError):
                verify(*original_metadata(), 'unchanged-apk-console-joystick-' + case)

    def test_old_routes_keep_exact_original_bindings(self):
        for names, workflow, branch in (
            (common.QA_JOBS, common.QA_WORKFLOW, common.QA_BRANCH),
            (common.FOLLOWUP_QA_JOBS, common.FOLLOWUP_QA_WORKFLOW, common.FOLLOWUP_QA_BRANCH),
            ((common.CREATIVE_QA_JOB,), common.CREATIVE_QA_WORKFLOW, common.CREATIVE_QA_BRANCH),
        ):
            for name in names:
                self.assertEqual(common.QA_ROUTES[name], (workflow, branch))
                run, jobs = original_metadata()
                jobs['jobs'][0]['name'] = name
                with self.subTest(name=name), self.assertRaises(RuntimeError):
                    verify(run, jobs, name)

    def test_changed_workflow_branch_source_attempt_or_missing_job_stays_failure(self):
        name = common.CONSOLE_JOYSTICK_QA_JOBS[0]
        for key, wrong in (('path', OLD_RUNTIME), ('path', OLD_CREATIVE),
                           ('head_branch', common.FOLLOWUP_QA_BRANCH),
                           ('head_branch', BRANCH + '-suffix'), ('head_branch', 'main'),
                           ('head_sha', common.HOST), ('run_attempt', 2)):
            run, jobs = original_metadata()
            run[key] = wrong
            with self.subTest(field=key, value=wrong), self.assertRaises(RuntimeError):
                verify(run, jobs, name)
        for problem in ('missing', 'duplicate', 'wrong-attempt'):
            run, jobs = original_metadata()
            if problem == 'missing':
                jobs['jobs'].pop(0)
            elif problem == 'duplicate':
                extra = copy.deepcopy(jobs['jobs'][0])
                extra['id'] += 100
                jobs['jobs'].append(extra)
            else:
                jobs['jobs'][0]['run_attempt'] = 2
            jobs['total_count'] = len(jobs['jobs'])
            with self.subTest(problem=problem), self.assertRaises(RuntimeError):
                verify(run, jobs, name)

    def test_creative_cli_keeps_old_default_and_only_accepts_exact_creative_routes(self):
        arguments = []
        for flag in ('qa-source', 'candidate-source', 'native-source', 'candidate-metadata-dir',
                     'qa-metadata-dir', 'apk', 'provenance', 'sums', 'out'):
            arguments.extend(('--' + flag, '/explicit/synthetic/' + flag))
        arguments.extend(('--expected-qa-source', SOURCE, '--expected-qa-run', str(RUN),
                          '--expected-qa-attempt', '1'))
        fake = unittest.mock.Mock()
        fake.Tour.return_value.run.return_value = 0
        for name in (None, common.CONSOLE_JOYSTICK_CREATIVE_JOB):
            with patch.object(creative, 'prepare', return_value=fake) as prepare:
                actual = arguments + ([] if name is None else ['--qa-job-name', name])
                self.assertEqual(creative.main(actual), 0)
                self.assertEqual(prepare.call_args.args[0].qa_job_name,
                                 common.CREATIVE_QA_JOB if name is None else name)
        with patch.object(creative, 'prepare') as prepare, \
                self.assertRaises(SystemExit) as failure:
            creative.main(arguments + ['--qa-job-name', common.CONSOLE_JOYSTICK_QA_JOBS[0]])
        self.assertEqual(failure.exception.code, 2)
        prepare.assert_not_called()

    def test_new_creative_context_rechecks_new_route_before_inputs(self):
        # Reuse the existing explicit source/metadata doubles and actual guard;
        # no device or APK verifier is replaced by a positive runtime result.
        from scripts.tests.test_unchanged_creative_diagnostic import TourContextContracts
        case = TourContextContracts('test_complete_context_returns_only_the_separate_qa_head')
        case.setUp()
        try:
            args, context = case.args, case.context
            new_name = common.CONSOLE_JOYSTICK_CREATIVE_JOB
            run_path = args.qa_metadata_dir / 'run.json'
            jobs_path = args.qa_metadata_dir / 'jobs.json'
            run = json.loads(run_path.read_bytes())
            jobs = json.loads(jobs_path.read_bytes())
            run.update(path=WORKFLOW, head_branch=BRANCH)
            jobs['jobs'][0]['name'] = new_name
            run_path.write_text(json.dumps(run))
            jobs_path.write_text(json.dumps(jobs))
            args.qa_job_name = new_name
            context['diagnostic_qa'] = verify(run, jobs, new_name)
            for key, path in (('qa/run.json', run_path), ('qa/jobs.json', jobs_path)):
                context['input_hashes'][key] = {'path': str(path), 'bytes': path.stat().st_size,
                                               'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
            case.save()
            self.assertEqual(case.verify(), SOURCE)
            args.qa_job_name = common.CREATIVE_QA_JOB
            with self.assertRaises(RuntimeError):
                case.verify()
        finally:
            case.doCleanups()


class ConsoleJoystickWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.text = (ROOT / WORKFLOW).read_text()

    def test_exact_internal_branch_base_and_event_are_required(self):
        block = job(self.text, 'probe-contracts')
        expression = block.split('    if: >-\n', 1)[1].split('\n    name:', 1)[0]
        values = {'github.repository': 'Ullmann27/lumo-lernen',
                  'github.event_name': 'pull_request',
                  'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
                  'github.event.pull_request.base.ref': 'integration/lumo-connections-20261113',
                  'github.head_ref': BRANCH, 'github.ref_name': '900/merge'}
        self.assertTrue(condition(expression, values))
        self.assertTrue(condition(expression, {**values, 'github.event_name': 'workflow_dispatch',
                                              'github.head_ref': '', 'github.ref_name': BRANCH}))
        for key, value in (('github.repository', 'foreign/fork'),
                           ('github.event.pull_request.head.repo.full_name', 'foreign/fork'),
                           ('github.event.pull_request.base.ref', 'main'),
                           ('github.head_ref', BRANCH + '-extra'), ('github.event_name', 'push')):
            self.assertFalse(condition(expression, {**values, key: value}))

    def test_four_cases_preserve_actual_hardware_and_unchanged_wrapper_calls(self):
        cases = re.findall(r'^          - case: (\S+)\n            api: (\d+)\n'
                           r'            renderer: (\S+)\n            minutes: (\d+)$', self.text, re.M)
        self.assertEqual(cases, [('api37-host', '37', 'host', '65'),
                                 ('api37-swiftshader', '37', 'swiftshader', '65'),
                                 ('api37-swangle', '37', 'swangle', '65')])
        self.assertEqual(re.findall(r'^  ([\w-]+):$', self.text, re.M)[-3:],
                         ['probe-contracts', 'android-diagnostic', 'creative-android'])
        for name in ('android-diagnostic', 'creative-android'):
            self.assertIn('    needs: [probe-contracts]', job(self.text, name))
        for title, old_path in (
            ('Run the Android17 renderer comparison with continuous ANR observation', OLD_RUNTIME),
            ('Observe actual Jump Build Puzzle Treasure inputs on the unchanged APK', OLD_CREATIVE),
        ):
            actual = step(self.text, title).split('        with:\n', 1)[1]
            original = step((ROOT / old_path).read_text(), title).split('        with:\n', 1)[1]
            actual = actual.replace(' -shell-serial unix:${{ env.LUMO_ANDROID_CONSOLE_SOCKET }},server,nowait', '')
            actual = actual.replace(' --qa-job-name unchanged-apk-console-joystick-creative-api35', '')
            self.assertEqual(actual, original)
        self.assertNotIn('continue-on-error:', self.text)
        self.assertNotIn('flutter build', self.text)

    def test_full_console_discovery_and_portrait_contracts_are_mandatory(self):
        text = job(self.text, 'probe-contracts')
        group = text.split('.probe-venv/bin/python -B -m unittest -v \\\n', 1)[1]
        group = group.split('2>&1 | tee console-contracts.log', 1)[0]
        self.assertEqual(re.findall(r'scripts\.tests\.(\w+)', group), [
            'test_android_console_transport', 'test_android_runtime_device_logger',
            'test_runtime_logcat_sections', 'test_android_framework_ready',
            'test_verify_android_runtime_anr'])
        for name, count in (('console', 86), ('joystick', 7)):
            self.assertIn(f"grep -Eq '^Ran {count} tests in ' {name}-contracts.log", text)
            self.assertIn(f"grep -Fx 'OK' {name}-contracts.log", text)
        self.assertNotIn('excluded', text)
        self.assertNotIn('test_synthetic_pipe', text)
        self.assertIn('scripts.tests.test_studio_joystick_portrait', text)

    def test_prepare_runs_before_emulator_and_retains_receipt_if_launch_never_happens(self):
        for job_name, directory in (('android-diagnostic', 'tour/framework-start'),):
            block = job(self.text, job_name)
            title = 'Prepare the private init-console channel before emulator launch'
            prepare = step(block, title)
            self.assertLess(block.index(title), block.index('          emulator-options:'))
            self.assertIn('LUMO_ANDROID_CONSOLE_SOCKET: ${{ runner.temp }}/lumo-serial-${{ github.run_id }}-${{ github.run_attempt }}/console.sock', prepare)
            self.assertIn('-shell-serial unix:${{ env.LUMO_ANDROID_CONSOLE_SOCKET }},server,nowait', block)
            command = '\n'.join(line[10:] for line in prepare.split('        run: |\n', 1)[1].splitlines())
            with tempfile.TemporaryDirectory(prefix='lumo-cj-') as folder:
                root = Path(folder)
                runtime = root / 'scripts/android_console_transport.py'
                runtime.parent.mkdir()
                runtime.write_bytes((ROOT / 'scripts/android_console_transport.py').read_bytes())
                socket_path = root / 'lumo-serial-900001-1/console.sock'
                env_file = root / 'github-env'
                environment = {**os.environ, 'RUNNER_TEMP': str(root), 'GITHUB_RUN_ID': str(RUN),
                               'GITHUB_RUN_ATTEMPT': '1', 'GITHUB_ENV': str(env_file),
                               'LUMO_ANDROID_CONSOLE_SOCKET': str(socket_path),
                               'PYTHONDONTWRITEBYTECODE': '1'}
                result = subprocess.run(['bash', '-c', command], cwd=root, env=environment,
                                        capture_output=True, timeout=10)
                self.assertEqual(result.returncode, 0, result.stderr.decode())
                receipt = socket_path.parent / 'prepare.json'
                retained = root / directory / 'console-prepare.json'
                self.assertEqual(receipt.read_bytes(), retained.read_bytes())
                self.assertEqual(json.loads(retained.read_bytes())['emulator_option'],
                                 'unix:' + str(socket_path) + ',server,nowait')
                self.assertEqual(env_file.read_text(), 'LUMO_ANDROID_CONSOLE_SOCKET=' + str(socket_path) + '\n')
                self.assertFalse(socket_path.exists(), 'No emulator or console socket was started by this fixture')
                retry = subprocess.run(['bash', '-c', command], cwd=root, env=environment,
                                       capture_output=True, timeout=10)
                self.assertNotEqual(retry.returncode, 0)
                self.assertEqual(receipt.read_bytes(), retained.read_bytes())

        creative = job(self.text, 'creative-android')
        self.assertNotIn('android_console_transport.py prepare', creative)
        self.assertNotIn('LUMO_ANDROID_CONSOLE_SOCKET', creative)
        self.assertNotIn('-shell-serial', creative)

    def test_old_auto_trigger_exclusions_affect_only_the_exact_new_branch(self):
        for path, name in (
            ('.github/workflows/lumo-unified-integration-2026.yml', 'verify-and-build'),
            ('.github/workflows/lumo-astra-script-recovery.yml', 'full-app-script-regression'),
            ('.github/workflows/lumo-1966-cards-route-kart-qa.yml', 'cards-route-and-probe'),
        ):
            text = job((ROOT / path).read_text(), name)
            expression = text.split('    if: >-\n', 1)[1].split('\n    runs-on:', 1)[0]
            for head, ref, expected in ((BRANCH, '900/merge', False), ('', BRANCH, False),
                                        ('some-existing-work', '900/merge', True),
                                        (BRANCH + '-other', '900/merge', True)):
                self.assertEqual(condition(expression, {'github.head_ref': head, 'github.ref_name': ref}), expected)


class ConsoleJoystickExportTests(unittest.TestCase):
    def test_real_new_diagnostic_export_binds_probe_and_preserves_all_original_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = root / 'creative'
            source.mkdir()
            data = {'failure.json': b'{"status":"FAIL"}\n', '.original.log': b'full original failure\n'}
            for name, payload in data.items():
                (source / name).write_bytes(payload)
            output = root / 'parts'
            result = exporter.export_parts(source, output, repository=common.REPOSITORY,
                                            workflow_path=WORKFLOW, source_sha=SOURCE,
                                            run_id=RUN, run_attempt=1)
            self.assertEqual(result['part_count'], 1)
            index_bytes = (output / 'part-01/export-index.json').read_bytes()
            index = json.loads(index_bytes)
            self.assertEqual(index['schema'], 2)
            self.assertEqual(index['binding'], {'repository': common.REPOSITORY, 'workflow_path': WORKFLOW,
                                                'probe_source_sha': SOURCE, 'run_id': RUN, 'run_attempt': 1})
            self.assertNotIn('host_source_sha', index['binding'])
            self.assertEqual(index['limits']['part_payload_bytes'], 256 * 1024 * 1024)
            self.assertEqual(index['limits']['max_parts'], 8)
            self.assertEqual(index['file_count'], 2)
            for row in index['files']:
                payload = data[row['path']]
                self.assertEqual((output / 'part-01/originals' / row['path']).read_bytes(), payload)
                self.assertEqual(row['sha256'], hashlib.sha256(payload).hexdigest())
            part = json.loads((output / 'part-01/part.json').read_bytes())
            self.assertEqual(part['index_sha256'], hashlib.sha256(index_bytes).hexdigest())
            with self.assertRaises(ValueError):
                exporter.export_parts(source, root / 'wrong', repository=common.REPOSITORY,
                                      workflow_path=WORKFLOW + '-suffix', source_sha=SOURCE,
                                      run_id=RUN, run_attempt=1)


if __name__ == '__main__':
    unittest.main()
