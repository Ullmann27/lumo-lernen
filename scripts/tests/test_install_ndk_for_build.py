"""Run the actual shell preflight against an isolated, observable fake SDK."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REVISION = '28.2.13676358'
SCRIPT = Path(__file__).resolve().parents[1] / 'install_ndk_for_build.sh'
FAKE_MANAGER = r'''#!/usr/bin/env python3
import json, os
from pathlib import Path
import sys, time
sdk = Path(os.environ['FAKE_SDK_ROOT'])
calls = sdk / 'calls.jsonl'
previous = [json.loads(line) for line in calls.read_text().splitlines()] if calls.exists() else []
with calls.open('a') as stream:
    stream.write(json.dumps(sys.argv[1:]) + '\n')
assert '--sdk_root=' + str(sdk.resolve()) in sys.argv
assert 'ndk;28.2.13676358' in sys.argv
assert sys.stdin.read() == '', 'License answers must not be injected'
scenario = os.environ['FAKE_NDK_SCENARIO']
if '--uninstall' in sys.argv:
    # Deliberately leave incomplete files: the exact directory must be retained,
    # while an unrelated installed version and licenses must never be changed.
    print('Exact package uninstall requested')
    sys.exit(9 if scenario == 'uninstall-fails' else 0)
assert '--install' in sys.argv
attempt = 1 + sum('--install' in item for item in previous)
target = sdk / 'ndk' / '28.2.13676358'
target.mkdir(parents=True, exist_ok=True)
if scenario in ('first-invalid', 'first-invalid-exit-zero', 'permanent-invalid', 'uninstall-fails') and (
        attempt == 1 or scenario == 'permanent-invalid'):
    (target / 'source.properties').write_text('Pkg.Revision = 28.2.13676358\n')
    print('Warning: Error reading Zip content from a SeekableByteChannel.')
    print('java.util.zip.ZipException: Archive is not a ZIP archive')
    sys.exit(0 if scenario == 'first-invalid-exit-zero' else 1)
if scenario == 'permission-failure':
    print('Permission denied; actual failure remains fatal')
    sys.exit(7)
if scenario == 'timeout-with-invalid':
    print('Archive is not a ZIP archive', flush=True)
if scenario in ('timeout', 'timeout-with-invalid'):
    time.sleep(3)
if scenario in ('zip-complete', 'zip-compiler-fails', 'zip-compiler-timeout', 'zip-wrong-version'):
    print('Warning: Error reading Zip content from a SeekableByteChannel.', flush=True)
revision = '27.0.12077973' if scenario in ('wrong-version', 'zip-wrong-version') else '28.2.13676358'
(target / 'source.properties').write_text('Pkg.Revision = ' + revision + '\n')
if scenario == 'partial':
    print('SDK manager exit0 without an actual compiler')
    sys.exit(0)
compiler = target / 'toolchains/llvm/prebuilt/linux-x86_64/bin/clang'
compiler.parent.mkdir(parents=True, exist_ok=True)
body = "#!/usr/bin/env bash\n[[ $1 == --version ]] || exit 3\nprintf 'Android clang version 19.1.7\\n'\n"
if scenario in ('compiler-fails', 'zip-compiler-fails'):
    body = '#!/usr/bin/env bash\necho broken-loader >&2\nexit 17\n'
if scenario == 'not-clang':
    body = "#!/usr/bin/env bash\nprintf 'gcc version 14.2.0\\n'\n"
if scenario == 'zip-compiler-timeout':
    body = '#!/usr/bin/env bash\nsleep 3\n'
compiler.write_text(body)
compiler.chmod(0o755)
print('SDK package installed')
'''


class InstallNdkForBuildTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix='lumo ndk integration ')
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.sdk = self.root / 'sdk with spaces'
        self.sdk.mkdir()
        manager = self.sdk / 'cmdline-tools/latest/bin/sdkmanager'
        manager.parent.mkdir(parents=True)
        manager.write_text(FAKE_MANAGER)
        manager.chmod(0o755)
        self.evidence = self.root / 'original evidence'
        self.target = self.sdk / 'ndk' / REVISION
        self.foreign = self.sdk / 'ndk/27.0.12077973/do-not-change'
        self.foreign.parent.mkdir(parents=True)
        self.foreign.write_text('another actual package')
        self.license = self.sdk / 'licenses/android-sdk-license'
        self.license.parent.mkdir()
        self.license.write_text('already accepted by runner provisioning')

    def run_preflight(self, scenario='valid', allow_reinstall=True, timeout=600,
                      path_prefix=None, total_timeout=540):
        environment = dict(os.environ, ANDROID_SDK_ROOT=str(self.sdk),
                           FAKE_SDK_ROOT=str(self.sdk), FAKE_NDK_SCENARIO=scenario,
                           LUMO_NDK_DISPOSABLE_RUNNER='1' if allow_reinstall else '0',
                           LUMO_NDK_TIMEOUT_SECONDS=str(timeout),
                           LUMO_NDK_TOTAL_TIMEOUT_SECONDS=str(total_timeout))
        if path_prefix:
            environment['PATH'] = str(path_prefix) + os.pathsep + environment['PATH']
        result = subprocess.run(['bash', str(SCRIPT), str(self.evidence)],
                                env=environment, capture_output=True, text=True,
                                timeout=12)
        self.assertEqual(self.foreign.read_text(), 'another actual package')
        self.assertEqual(self.license.read_text(), 'already accepted by runner provisioning')
        self.assertNotIn('--licenses', (self.sdk / 'calls.jsonl').read_text()
                         if (self.sdk / 'calls.jsonl').exists() else '')
        return result

    def calls(self):
        path = self.sdk / 'calls.jsonl'
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def verified_existing(self, revision=REVISION):
        self.target.mkdir(parents=True)
        (self.target / 'source.properties').write_text('Pkg.Revision = ' + revision + '\n')
        compiler = self.target / 'toolchains/llvm/prebuilt/linux-x86_64/bin/clang'
        compiler.parent.mkdir(parents=True)
        compiler.write_text("#!/usr/bin/env bash\n[[ $1 == --version ]] || exit 4\nprintf 'Android clang version 19.1.7\\n'\n")
        compiler.chmod(0o755)

    def test_verified_existing_package_reuses_actual_compiler_without_sdkmanager_call(self):
        self.verified_existing()
        result = self.run_preflight()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls(), [])
        self.assertIn('no installation', result.stdout)
        self.assertTrue(list(self.evidence.rglob('clang-reuse.log')))

    def test_fresh_install_checks_exact_revision_and_runs_actual_compiler(self):
        result = self.run_preflight()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(self.calls()), 1)
        self.assertTrue(list(self.evidence.rglob('clang-1.log')))

    def test_first_invalid_zip_has_one_reinstall_and_retains_both_original_logs(self):
        for scenario in ('first-invalid', 'first-invalid-exit-zero'):
            with self.subTest(scenario=scenario):
                if self.target.exists():
                    # Start the second integration case in its own new temporary
                    # SDK; never erase packages to make a test pass.
                    self.setUp()
                result = self.run_preflight(scenario)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual([call[-2] for call in self.calls()],
                                 ['--install', '--uninstall', '--install'])
                first = list(self.evidence.rglob('sdkmanager-install-1.log'))
                second = list(self.evidence.rglob('sdkmanager-install-2.log'))
                self.assertEqual(len(first), 1)
                self.assertEqual(len(second), 1)
                self.assertIn('Archive is not a ZIP archive', first[0].read_text())
                self.assertIn('SDK package installed', second[0].read_text())
                self.assertTrue(list(self.evidence.rglob('incomplete-ndk-'+REVISION)))

    def test_sdkmanager_exit_zero_partial_package_is_rejected_without_retry(self):
        result = self.run_preflight('partial')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertNotIn('[NDKPreflight] PASS', result.stdout)

    def test_wrong_package_version_is_rejected_even_with_working_compiler(self):
        result = self.run_preflight('wrong-version')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('expected Pkg.Revision', result.stderr)

    def test_existing_wrong_package_never_invokes_installer_or_claims_pass(self):
        self.verified_existing('28.2.136763580')
        result = self.run_preflight()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_permanent_invalid_zip_stops_after_exactly_two_installations(self):
        result = self.run_preflight('permanent-invalid')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 3)
        self.assertEqual(sum('--install' in call for call in self.calls()), 2)
        self.assertNotIn('[NDKPreflight] PASS', result.stdout)

    def test_non_zip_sdk_failure_is_fatal_without_any_reinstall(self):
        result = self.run_preflight('permission-failure')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('Permission denied', result.stdout)

    def test_invalid_zip_does_not_modify_sdk_without_explicit_disposable_flag(self):
        result = self.run_preflight('first-invalid', allow_reinstall=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertTrue(self.target.exists())

    def test_uninstall_failure_stops_before_second_install(self):
        result = self.run_preflight('uninstall-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual(sum('--install' in call for call in self.calls()), 1)

    def test_broken_or_non_clang_executable_never_passes(self):
        for scenario in ('compiler-fails', 'not-clang'):
            with self.subTest(scenario=scenario):
                if self.target.exists():
                    self.setUp()
                result = self.run_preflight(scenario)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('[NDKPreflight] PASS', result.stdout)
                self.assertEqual(len(self.calls()), 1)

    def test_sdkmanager_timeout_is_fatal_and_original_log_remains(self):
        result = self.run_preflight('timeout', timeout=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('sdkmanager exit 124', result.stderr)
        self.assertTrue(list(self.evidence.rglob('sdkmanager-install-1.log')))

    def test_timeout_after_zip_warning_does_not_authorize_another_install(self):
        result = self.run_preflight('timeout-with-invalid', timeout=1)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('sdkmanager exit 124', result.stderr)

    def test_original_log_write_failure_is_fatal_even_after_zip_warning(self):
        fake_bin = self.root / 'failing-log-writer'
        fake_bin.mkdir()
        tee = fake_bin / 'tee'
        tee.write_text('#!/usr/bin/env python3\nimport pathlib,sys\ntext=sys.stdin.read()\n'
                       'pathlib.Path(sys.argv[1]).write_text(text)\nprint(text,end="")\nsys.exit(1)\n')
        tee.chmod(0o755)
        result = self.run_preflight('first-invalid', path_prefix=fake_bin)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('original command log could not be retained', result.stderr)

    def test_duplicate_revision_properties_cannot_certify_existing_package(self):
        self.verified_existing()
        with (self.target / 'source.properties').open('a') as stream:
            stream.write('Pkg.Revision = ' + REVISION + '\n')
        result = self.run_preflight()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_compiler_log_loss_after_sdk_zip_warning_is_fatal_without_reinstall(self):
        fake_bin = self.root / 'compiler-only-failing-log-writer'
        fake_bin.mkdir()
        tee = fake_bin / 'tee'
        tee.write_text('#!/usr/bin/env python3\nimport pathlib,sys\ntext=sys.stdin.read()\n'
                       'pathlib.Path(sys.argv[1]).write_text(text)\nprint(text,end="")\n'
                       'sys.exit(1 if "clang-" in pathlib.Path(sys.argv[1]).name else 0)\n')
        tee.chmod(0o755)
        result = self.run_preflight('zip-complete', path_prefix=fake_bin)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('original command log could not be retained', result.stderr)
        self.assertIn('verification 126', result.stderr)
        self.assertFalse(list(self.evidence.rglob('sdkmanager-uninstall.log')))

    def test_actual_compiler_failure_after_sdk_zip_warning_is_not_retryable(self):
        result = self.run_preflight('zip-compiler-fails')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('verification 126', result.stderr)

    def test_wrong_identity_after_sdk_zip_warning_is_not_retryable(self):
        result = self.run_preflight('zip-wrong-version')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('verification 2', result.stderr)

    def test_shared_deadline_bounds_default_600_second_installation(self):
        result = self.run_preflight('timeout', total_timeout=11)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('sdkmanager exit 124', result.stderr)

    def test_compiler_timeout_after_zip_warning_cannot_reinstall(self):
        result = self.run_preflight('zip-compiler-timeout', total_timeout=11)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 1)
        self.assertIn('verification 126', result.stderr)


if __name__ == '__main__':
    unittest.main()
