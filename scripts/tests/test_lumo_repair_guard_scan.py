"""Exercise the actual Bash scan helper only; no Flutter/tool-suite substitutes."""
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
GUARD = ROOT / 'scripts/lumo_repair_guard.sh'
WORKFLOW = ROOT / '.github/workflows/lumo-runtime-apk.yml'
PATTERN = 'ParentPin|ParentalGate|initialParentPin|parentPin|parentRecoveryCode|requiresParentPin'


class RepairGuardScanTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix='lumo scan helper ')
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        self.code = self.directory / 'active source'
        self.code.mkdir()
        source = GUARD.read_text()
        functions = []
        for name in ('fail', 'require_no_obsolete_gate'):
            match = re.search(r'(?ms)^' + name + r'\(\) \{\n.*?^\}', source)
            self.assertIsNotNone(match, 'Expected actual guard helper: ' + name)
            functions.append(match.group())
        self.fixture = self.directory / 'actual-helper.sh'
        self.fixture.write_text('set -euo pipefail\n' + '\n\n'.join(functions) +
                                '\nrequire_no_obsolete_gate "$1"\n'
                                'echo FIXTURE_SCAN_CONTINUED\n')

    def scan(self, target=None, path=None):
        environment = dict(os.environ)
        if path is not None:
            environment['PATH'] = str(path)
        return subprocess.run(['/bin/bash', str(self.fixture),
                               str(target or self.code)], env=environment,
                              capture_output=True, text=True, timeout=10)

    def fake_rg(self, status):
        # Fault injection only: these exit codes never stand for a real source scan.
        directory = self.directory / ('fault tool ' + str(status))
        directory.mkdir()
        executable = directory / 'rg'
        executable.write_text('#!/bin/bash\necho INJECTED_RG_ERROR >&2\nexit ' +
                              str(status) + '\n')
        executable.chmod(0o755)
        return directory

    def require_actual_rg(self):
        self.assertIsNotNone(shutil.which('rg'), 'Real ripgrep is required for scan tests')

    def test_actual_ripgrep_no_hits_is_the_only_continuation(self):
        self.require_actual_rg()
        (self.code / 'clean.dart').write_text('class CurrentProfile {}\n')
        result = self.scan()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('(no matches)', result.stdout)
        self.assertIn('FIXTURE_SCAN_CONTINUED', result.stdout)

    def test_actual_ripgrep_rejects_every_original_obsolete_pattern(self):
        self.require_actual_rg()
        for word in PATTERN.split('|'):
            with self.subTest(word=word):
                (self.code / 'obsolete.dart').write_text('final marker = "' + word + '";\n')
                result = self.scan()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('obsolete.dart:1:', result.stdout)
                self.assertIn(word, result.stdout)
                self.assertIn('Obsolete access-code gate remains', result.stderr)
                self.assertNotIn('FIXTURE_SCAN_CONTINUED', result.stdout)

    def test_actual_ripgrep_missing_target_is_fatal_and_preserves_error(self):
        self.require_actual_rg()
        target = self.directory / 'missing source'
        result = self.scan(target)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(str(target), result.stderr)
        self.assertIn('rg exit 2', result.stderr)
        self.assertNotIn('FIXTURE_SCAN_CONTINUED', result.stdout)

    def test_missing_ripgrep_is_fatal_before_any_scan(self):
        empty_path = self.directory / 'no executables'
        empty_path.mkdir()
        result = self.scan(path=empty_path)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Required source-scan tool is missing: rg', result.stderr)
        self.assertNotIn('FIXTURE_SCAN_CONTINUED', result.stdout)

    def test_non_match_non_hit_exit_codes_are_fatal(self):
        for status in (2, 3, 64, 127):
            with self.subTest(status=status):
                result = self.scan(path=self.fake_rg(status))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('INJECTED_RG_ERROR', result.stderr)
                self.assertIn('rg exit ' + str(status), result.stderr)
                self.assertNotIn('FIXTURE_SCAN_CONTINUED', result.stdout)

    def test_original_pattern_and_active_scan_call_are_preserved(self):
        source = GUARD.read_text()
        self.assertEqual(source.count("rg -n '" + PATTERN + "'"), 1)
        self.assertEqual(source.count('require_no_obsolete_gate lib'), 1)

    def test_workflow_installs_and_verifies_rg_before_repair_guard(self):
        workflow = WORKFLOW.read_text()
        start = workflow.index('      - name: Install ripgrep before source guards\n')
        end = workflow.index('      - name:', start + 1)
        step = workflow[start:end]
        self.assertIn('timeout-minutes: 5', step)
        self.assertIn('set -euo pipefail', step)
        self.assertIn('install -y ripgrep', step)
        self.assertIn('command -v rg\n', step)
        self.assertIn('rg --version\n', step)
        self.assertLess(end, workflow.index('bash scripts/lumo_repair_guard.sh'))


if __name__ == '__main__':
    unittest.main()
