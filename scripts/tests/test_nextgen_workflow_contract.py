"""Check actual candidate routing and fail-closed Nextgen source validation."""
from __future__ import annotations

import importlib.util
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
LEGACY = ROOT / '.github/workflows/lumo-unified-integration-2026.yml'
NEXTGEN = ROOT / '.github/workflows/lumo-nextgen-2018.yml'


def initial_pincheck(workflow: Path = NEXTGEN) -> str:
    step = workflow.read_text().split(
        '      - name: Save source identity and validate exact Godot integration pin\n', 1)[1]
    step = step.split('      - uses:', 1)[0]
    match = re.search(r"<<'PY'\n(.*?)\n          PY(?:\n|$)", step, re.S)
    if match is None:
        raise AssertionError('Missing actual workflow source identity gate')
    return textwrap.dedent(match[1])


class NextgenWorkflowContractTests(unittest.TestCase):
    def test_nextgen_has_one_automatic_apk_event_and_shared_branch_concurrency(self):
        source = NEXTGEN.read_text()
        triggers = source.split('on:\n', 1)[1].split('\npermissions:', 1)[0]
        self.assertEqual(set(re.findall(r'^  ([a-z_]+):', triggers, re.M)),
                         {'pull_request', 'workflow_dispatch'})
        self.assertIn('branches: [chatgpt/lumo-spielewelt-stage-20261112]', triggers)
        self.assertIn('group: lumo-nextgen-2018-${{ github.head_ref || github.ref_name }}', source)
        for name in ('android-host-compile', 'verify-and-build'):
            # Extract the job gate directly from the real workflow, not a
            # duplicate expected implementation.
            job = source.split('  ' + name + ':\n', 1)[1]
            expression = job.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0]
            self.assertNotIn('steps:', expression)
            expression = expression.replace('\n', ' ').replace('&&', 'and').replace('||', 'or').strip()
            base = {'github.repository': 'Ullmann27/lumo-lernen',
                    'github.event_name': 'pull_request',
                    'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
                    'github.head_ref': 'chatgpt/lumo-nextgen-20261113',
                    'github.ref_name': '461/merge'}
            cases = [({}, True), ({'github.event_name': 'push'}, False),
                     ({'github.head_ref': 'different-branch'}, False),
                     ({'github.event.pull_request.head.repo.full_name': 'other/fork'}, False),
                     ({'github.event_name': 'workflow_dispatch', 'github.head_ref': '',
                       'github.ref_name': 'chatgpt/lumo-nextgen-20261113'}, True),
                     ({'github.event_name': 'workflow_dispatch', 'github.head_ref': '',
                       'github.ref_name': 'main'}, False)]
            for changes, expected in cases:
                values = dict(base, **changes)
                executable = expression
                for key in sorted(values, key=len, reverse=True):
                    executable = executable.replace(key, repr(values[key]))
                with self.subTest(job=name, changes=changes):
                    self.assertIs(eval(executable, {'__builtins__': {}}, {}), expected)

    def test_historical_unified_workflow_cannot_build_2018_under_another_branch(self):
        for version, expected in (('0.13.6+2018', 1), ('0.13.5+2017', 0)):
            with self.subTest(version=version), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                root.joinpath('config').mkdir()
                root.joinpath('pubspec.yaml').write_text('version: ' + version + '\n')
                root.joinpath('config/godot-source.json').write_text(json.dumps({
                    'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                    'engine': '4.6.3', 'revision': '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57'}))
                result = subprocess.run([sys.executable, '-c', initial_pincheck(LEGACY)],
                                        cwd=root, capture_output=True, text=True, check=False)
                self.assertEqual(result.returncode, expected, result.stderr)
                if expected:
                    self.assertIn('Build 2018 requires the dedicated Nextgen workflow', result.stderr)

    def test_android_tour_keeps_full_original_and_new_surface_gates(self):
        job = NEXTGEN.read_text().split('  android-tour:\n', 1)[1].split('  update-2018-from-2017:', 1)[0]
        self.assertIn("-p 'test_nextgen*.py'", job)
        old = job.index('python .github/probes/modernization_android_tour.py --apk')
        new = job.index('python .github/probes/lumo_nextgen_surfaces_android_probe.py --apk')
        self.assertLess(old, new)
        self.assertIn('--prior-tour tour/tour-result.json', job)

    def test_publication_stays_blocked_until_review_and_keeps_all_actual_dependencies(self):
        publisher = NEXTGEN.read_text().split('  publish-reviewed-2018:\n', 1)[1]
        self.assertIn('needs: [verify-and-build, android-host-compile, android-tour, update-2018-from-2017]', publisher)
        expression = publisher.split('    if: >-\n', 1)[1].split('    runs-on:', 1)[0].strip()
        expression = expression.replace('\n', ' ').replace('&&', 'and').replace('false', 'False')
        defaults = {
            'github.event_name': 'pull_request', 'github.repository': 'Ullmann27/lumo-lernen',
            'github.event.pull_request.head.repo.full_name': 'Ullmann27/lumo-lernen',
            'github.event.pull_request.head.ref': 'chatgpt/lumo-nextgen-20261113',
            'needs.verify-and-build.result': 'success', 'needs.android-tour.result': 'success',
            'needs.android-host-compile.result': 'success', 'needs.update-2018-from-2017.result': 'success',
        }
        receipt = json.loads((ROOT / 'config/nextgen-2018-visual-review.json').read_text())
        cases = [(key, 'failure') for key in defaults if key.startswith('needs.')]
        cases += [('github.event_name', 'push'), ('github.event.pull_request.head.ref', 'main'),
                  ('github.event.pull_request.head.repo.full_name', 'someone/fork')]
        if receipt['status'] != 'approved':
            cases.append(('github.event_name', 'pull_request'))
        for field, value in cases:
            executable = expression
            values = dict(defaults, **{field: value})
            for key in sorted(values, key=len, reverse=True):
                executable = executable.replace(key, repr(values[key]))
            with self.subTest(field=field, value=value):
                self.assertFalse(eval(executable, {'__builtins__': {}}, {}))

    def test_historical_release_pins_remain_byte_equivalent_as_2018_is_added(self):
        spec = importlib.util.spec_from_file_location(
            'nextgen_pin_policy', ROOT / 'scripts/verify_legacy_release_pin.py')
        policy = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(policy)
        historical = {version: sha for version, sha in policy.APPROVED.items() if version < 2018}
        digest = hashlib.sha256(json.dumps(
            historical, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
        self.assertEqual(digest, 'f20f1d3a33f9380e5731cd015ae29d02367b9417da8f3232961a26070d8ada9b')

    def test_new_branch_uses_one_candidate_pipeline_without_disabling_old_branches(self):
        guard = LEGACY.read_text().split('  verify-and-build:\n', 1)[1]
        expression = guard.split('    if: ', 1)[1].splitlines()[0]
        for head, ref, expected in (
            ('chatgpt/lumo-nextgen-20261113', '461/merge', False),
            ('', 'chatgpt/lumo-nextgen-20261113', False),
            ('chatgpt/lumo-2018-android-acceptance-20261113', '462/merge', False),
            ('', 'chatgpt/lumo-2018-android-acceptance-20261113', False),
            ('chatgpt/lumo-spielewelt-stage-20261112', '459/merge', True),
            ('', 'chatgpt/lumo-spielewelt-stage-20261112', True),
            ('another-review-branch', '462/merge', True),
        ):
            with self.subTest(head=head, ref=ref):
                executable = expression.replace('github.head_ref', repr(head))
                executable = executable.replace('github.ref_name', repr(ref)).replace('&&', 'and')
                self.assertIs(eval(executable, {'__builtins__': {}}, {}), expected)

    def test_nextgen_rejects_an_otherwise_valid_historical_candidate(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            root.joinpath('scripts').symlink_to(ROOT / 'scripts', target_is_directory=True)
            root.joinpath('config').mkdir()
            root.joinpath('pubspec.yaml').write_text('version: 0.13.5+2017\n')
            root.joinpath('config/godot-source.json').write_text(json.dumps({
                'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                'engine': '4.6.3',
                'revision': '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57',
            }))
            result = subprocess.run([sys.executable, '-c', initial_pincheck()],
                                    cwd=root, capture_output=True, text=True, check=False)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Nextgen workflow requires build 2018', result.stderr)

    def test_update_wrapper_binds_the_real_2017_baseline_and_rejects_old_candidate(self):
        spec = importlib.util.spec_from_file_location(
            'nextgen_update', ROOT / '.github/probes/lumo_2018_update_android_probe.py')
        wrapper = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(wrapper)
        self.assertEqual(wrapper.BASELINE_SOURCE, '47889f74a651b073965def70743417cf320b1eb9')
        self.assertEqual(wrapper.BASELINE_NATIVE, '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57')
        source = json.dumps({'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                             'engine': '4.6.3', 'revision': wrapper.BASELINE_NATIVE})
        with self.assertRaisesRegex(ValueError, 'requires candidate version 2018'):
            wrapper.reviewed_candidate_native('version: 0.13.5+2017\n', source)


if __name__ == '__main__':
    unittest.main()
