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


def initial_pincheck() -> str:
    step = NEXTGEN.read_text().split(
        '      - name: Save source identity and validate exact Godot integration pin\n', 1)[1]
    step = step.split('      - uses:', 1)[0]
    match = re.search(r"<<'PY'\n(.*?)\n          PY(?:\n|$)", step, re.S)
    if match is None:
        raise AssertionError('Missing actual workflow source identity gate')
    return textwrap.dedent(match[1])


class NextgenWorkflowContractTests(unittest.TestCase):
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
