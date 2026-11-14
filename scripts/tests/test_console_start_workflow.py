"""Fixed API37-only followup routing; no APK build or device-result claim."""
from __future__ import annotations

import copy
import importlib.util
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = '.github/workflows/lumo-console-start-7b16.yml'
OLD_WORKFLOW = '.github/workflows/lumo-console-joystick-7b16.yml'
BRANCH = 'qa/lumo-console-start-7b16-20261114'
SOURCE, TREE, RUN = 'a' * 40, 'b' * 40, 900001
SPEC = importlib.util.spec_from_file_location('console_start_binding', ROOT / 'scripts/verify_unchanged_apk_diagnostic.py')
BINDING = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(BINDING)
NAMES = ('unchanged-apk-console-start-api37-host',
         'unchanged-apk-console-start-api37-swiftshader',
         'unchanged-apk-console-start-api37-swangle')


def job(text, name):
    return re.search(r'^  ' + re.escape(name) + r':\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)',
                     text, re.M | re.S)[1]


def condition(value, values):
    expression = value.replace('&&', 'and').replace('||', 'or').replace('\n', ' ')
    for key in sorted(values, key=len, reverse=True):
        expression = expression.replace(key, repr(values[key]))
    return eval(expression, {'__builtins__': {}}, {})


def metadata():
    run = {'id': RUN, 'head_sha': SOURCE, 'run_attempt': 1,
           'status': 'in_progress', 'conclusion': None, 'path': WORKFLOW,
           'head_branch': BRANCH,
           'repository': {'id': BINDING.REPOSITORY_ID, 'full_name': BINDING.REPOSITORY},
           'head_commit': {'id': SOURCE, 'tree_id': TREE}}
    rows = [{'id': 900100 + i, 'run_id': RUN, 'head_sha': SOURCE,
             'run_attempt': 1, 'name': name, 'status': 'in_progress', 'conclusion': None}
            for i, name in enumerate(NAMES)]
    return run, {'total_count': len(rows), 'jobs': rows}


def verify(run, jobs, name):
    return BINDING.verify_qa(run, jobs, source=SOURCE, run_id=RUN, attempt=1, job_name=name)


class ConsoleStartWorkflowTests(unittest.TestCase):
    def setUp(self):
        self.text = (ROOT / WORKFLOW).read_text()
        self.old = (ROOT / OLD_WORKFLOW).read_text()

    def test_exact_internal_head_base_event_and_dispatch_are_required(self):
        expression = job(self.text, 'probe-contracts').split('    if: >-\n', 1)[1].split('\n    name:', 1)[0]
        values = {'github.repository': 'Ullmann27/lumo-lernen', 'github.event_name': 'pull_request',
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
            with self.subTest(key=key):
                self.assertFalse(condition(expression, {**values, key: value}))

    def test_exact_three_jobs_bind_distinct_qa_source_and_route(self):
        self.assertEqual(BINDING.CONSOLE_START_QA_JOBS, NAMES)
        for name in NAMES:
            result = verify(*metadata(), name)
            self.assertEqual((result['workflow_path'], result['branch']), (WORKFLOW, BRANCH))
            self.assertEqual(result['job_name'], name)
            self.assertEqual((result['source'], result['tree']), (SOURCE, TREE))
            self.assertNotEqual(result['source'], BINDING.HOST)
            self.assertIsNone(result['job_conclusion'])
        for suffix in ('api35', 'update2017', 'creative-api35', 'api37-angle', 'api37-host-extra'):
            with self.assertRaises(RuntimeError):
                verify(*metadata(), 'unchanged-apk-console-start-' + suffix)

    def test_new_route_rejects_old_workflow_wrong_source_attempt_and_duplicate_job(self):
        changes = ({'path': OLD_WORKFLOW}, {'head_branch': BRANCH + '-extra'},
                   {'head_sha': BINDING.HOST}, {'run_attempt': 2})
        for change in changes:
            run, jobs = metadata()
            run.update(change)
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                verify(run, jobs, NAMES[0])
        run, jobs = metadata()
        jobs['jobs'].append({**copy.deepcopy(jobs['jobs'][0]), 'id': 900999})
        jobs['total_count'] += 1
        with self.assertRaises(RuntimeError):
            verify(run, jobs, NAMES[0])

    def test_all_existing_routes_keep_their_exact_workflow_and_branch(self):
        groups = ((BINDING.QA_JOBS, BINDING.QA_WORKFLOW, BINDING.QA_BRANCH),
                  ((BINDING.CREATIVE_QA_JOB,), BINDING.CREATIVE_QA_WORKFLOW, BINDING.CREATIVE_QA_BRANCH),
                  (BINDING.FOLLOWUP_QA_JOBS, BINDING.FOLLOWUP_QA_WORKFLOW, BINDING.FOLLOWUP_QA_BRANCH),
                  (BINDING.CONSOLE_JOYSTICK_QA_JOBS, BINDING.CONSOLE_JOYSTICK_QA_WORKFLOW, BINDING.CONSOLE_JOYSTICK_QA_BRANCH))
        for names, workflow, branch in groups:
            for name in names:
                self.assertEqual(BINDING.QA_ROUTES[name], (workflow, branch))
                run, jobs = metadata()
                run.update(path=workflow, head_branch=branch)
                jobs = {'total_count': 1, 'jobs': [{**jobs['jobs'][0], 'name': name}]}
                self.assertEqual(verify(run, jobs, name)['workflow_path'], workflow)

    def test_three_renderer_job_preserves_entire_original_runtime_body(self):
        actual = job(self.text, 'android-diagnostic').rstrip()
        original = job(self.old, 'android-diagnostic').rstrip()
        self.assertEqual(actual, original.replace('console-joystick', 'console-start'))
        cases = re.findall(r'^          - case: (\S+)\n            api: (\d+)\n'
                           r'            renderer: (\S+)\n            minutes: (\d+)$', self.text, re.M)
        self.assertEqual(cases, [('api37-host', '37', 'host', '65'),
                                ('api37-swiftshader', '37', 'swiftshader', '65'),
                                ('api37-swangle', '37', 'swangle', '65')])
        self.assertEqual(re.findall(r'^  ([\w-]+):$', self.text, re.M)[-2:],
                         ['probe-contracts', 'android-diagnostic'])
        self.assertIn('    needs: [probe-contracts]', actual)
        for forbidden in ('creative-android:', 'flutter build', 'update-2019-from-2017', 'continue-on-error:'):
            self.assertNotIn(forbidden, self.text)

    def test_all_86_console_and_7_parser_and_9_diagnostic_cases_are_required(self):
        text = job(self.text, 'probe-contracts')
        block = text.split('.probe-venv/bin/python -B -m unittest -v \\\n', 1)[1].split('2>&1 | tee console-contracts.log', 1)[0]
        self.assertEqual(re.findall(r'scripts\.tests\.(\w+)', block), [
            'test_android_console_transport', 'test_android_runtime_device_logger',
            'test_runtime_logcat_sections', 'test_android_framework_ready', 'test_verify_android_runtime_anr'])
        for label, count in (('console', 86), ('parser', 7), ('launch-diagnostic', 9), ('printf', 6)):
            self.assertIn(f"grep -Eq '^Ran {count} tests in ' {label}-contracts.log", text)
            self.assertIn(f"grep -Fx 'OK' {label}-contracts.log", text)
        for module in ('test_console_launch_originals', 'test_console_launch_failure_diagnostics', 'test_console_logger_printf', 'test_console_start_workflow'):
            self.assertIn('scripts.tests.' + module, text)
        self.assertIn('set -euo pipefail', text)
        self.assertIn("'^OK \\(skipped=|^FAILED.*skipped='", text)
        self.assertNotIn('test_synthetic_pipe', text)
        self.assertNotIn('excluded', text)
        # Keep all existing source/identity neighbours; only the new module is added.
        marker = '            scripts.tests.test_android_framework_ready_android17 \\\n'
        old = job(self.old, 'probe-contracts').split(marker, 1)[1].split('2>&1 | tee diagnostic-contracts.log', 1)[0]
        new = text.split(marker, 1)[1].split('2>&1 | tee diagnostic-contracts.log', 1)[0]
        self.assertEqual(new.replace('            scripts.tests.test_console_start_workflow \\\n', ''), old)

    def test_candidate_identity_and_binding_run_before_any_device_launch(self):
        text = job(self.text, 'android-diagnostic')
        self.assertIn('QA_SOURCE: ${{ github.event.pull_request.head.sha || github.sha }}', self.text)
        self.assertIn('CANDIDATE_SOURCE: ' + BINDING.HOST, self.text)
        self.assertIn('NATIVE_SOURCE: ' + BINDING.NATIVE, self.text)
        self.assertIn("artifact-ids: '14093773196'", text)
        self.assertIn('run-id: 43540111465', text)
        self.assertLess(text.index('scripts/verify_unchanged_apk_diagnostic.py'), text.index('uses: ./runner-actions/android-emulator-runner'))
        self.assertIn('--qa-job-name "$DIAGNOSTIC_JOB_NAME"', text)
        self.assertIn('DIAGNOSTIC_JOB_NAME: unchanged-apk-console-start-${{ matrix.case }}', text)
        self.assertIn("api-level: '37.0'", text)
        self.assertIn('pre-emulator-launch-script:', text)
        self.assertIn('script: bash "$GITHUB_WORKSPACE/scripts/run_unchanged_apk_diagnostic.sh" "${{ matrix.case }}"', text)

    def test_broad_workflow_exclusions_only_add_this_exact_branch(self):
        for path, name in (('.github/workflows/lumo-unified-integration-2026.yml', 'verify-and-build'),
                           ('.github/workflows/lumo-astra-script-recovery.yml', 'full-app-script-regression'),
                           ('.github/workflows/lumo-1966-cards-route-kart-qa.yml', 'cards-route-and-probe')):
            expression = job((ROOT / path).read_text(), name).split('    if: >-\n', 1)[1].split('\n    runs-on:', 1)[0]
            for head, ref, expected in ((BRANCH, '900/merge', False), ('', BRANCH, False),
                                       ('some-existing-work', '900/merge', True), (BRANCH + '-other', '900/merge', True)):
                self.assertEqual(condition(expression, {'github.head_ref': head, 'github.ref_name': ref}), expected)

    def test_failed_observations_and_all_contract_logs_are_always_retained(self):
        device = job(self.text, 'android-diagnostic')
        self.assertIn("      - uses: actions/upload-artifact@v4\n        if: always()", device)
        self.assertIn('name: lumo-console-start-7b16-${{ matrix.case }}', device)
        self.assertIn('          path: tour/', device)
        contracts = job(self.text, 'probe-contracts')
        self.assertIn('        if: always()', contracts)
        for name in ('diagnostic-contracts.log', 'console-contracts.log', 'parser-contracts.log', 'launch-diagnostic-contracts.log', 'printf-contracts.log'):
            self.assertIn('            ' + name, contracts)
        self.assertIn('if-no-files-found: error', device)
        self.assertIn('cancel-in-progress: false', self.text)
        self.assertIn('  contents: read\n  actions: read', self.text)


if __name__ == '__main__':
    unittest.main()
