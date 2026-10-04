"""Logging must preserve failures and continue rejecting actual fatal errors."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from emulator_diagnostics import ContinuousDiagnostics, save_final_logs, verify_emulator


class DiagnosticTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.out = Path(self.tmp.name)
        self.addCleanup(self.tmp.cleanup)

    def test_device_loss_is_not_masked_by_final_logcat_timeout(self):
        device = Mock()
        device.adb.side_effect = subprocess.TimeoutExpired('logcat', 10)
        (self.out/'android-logcat-continuous.txt').write_text('last actual frame\n')
        with self.assertRaisesRegex(RuntimeError, 'device emulator-5554 not found'):
            try:
                raise RuntimeError('device emulator-5554 not found')
            finally:
                save_final_logs(device, self.out, preserve_error=sys.exc_info()[0] is not None)
        self.assertTrue((self.out/'final-logcat-error.txt').exists())
        self.assertEqual((self.out/'android-logcat-continuous.txt').read_text(), 'last actual frame\n')

    def test_failed_final_logging_cannot_pass_a_successful_usage_check(self):
        device = Mock()
        device.adb.side_effect = RuntimeError('device absent')
        with self.assertRaisesRegex(RuntimeError, 'device absent'):
            save_final_logs(device, self.out)

    def test_fatal_before_log_buffer_rollover_still_fails(self):
        device = Mock()
        device.adb.return_value = 'recent clean frame\n'
        (self.out/'android-logcat-continuous.txt').write_text('earlier FATAL EXCEPTION: main\n')
        with self.assertRaisesRegex(RuntimeError, 'errors appeared'):
            save_final_logs(device, self.out)
        self.assertIn('FATAL EXCEPTION', (self.out/'fatal-errors.txt').read_text())

    def test_fatal_is_saved_without_replacing_an_original_failure(self):
        device = Mock()
        device.adb.return_value = 'Fatal signal 6\n'
        save_final_logs(device, self.out, preserve_error=True)
        self.assertTrue((self.out/'fatal-errors.txt').exists())

    def test_unexpected_continuous_logger_exit_cannot_turn_the_run_green(self):
        with patch('emulator_diagnostics.subprocess.Popen') as popen:
            popen.return_value.poll.return_value = 1
            with self.assertRaisesRegex(RuntimeError, 'logcat ended'):
                with ContinuousDiagnostics('adb', 'emulator-5554', self.out):
                    pass
        self.assertTrue((self.out/'continuous-logcat-error.txt').exists())

    def test_continuous_logger_loss_preserves_original_device_failure(self):
        with patch('emulator_diagnostics.subprocess.Popen') as popen:
            popen.return_value.poll.return_value = 1
            with self.assertRaisesRegex(RuntimeError, 'original device loss'):
                with ContinuousDiagnostics('adb', 'emulator-5554', self.out):
                    raise RuntimeError('original device loss')

    def emulator_fixture(self):
        sdk = self.out/'sdk'
        root = sdk/'emulator'
        qemu = root/'qemu/linux-x86_64/qemu-system-x86_64'
        qemu.parent.mkdir(parents=True)
        qemu.write_text('actual binary fixture')
        (root/'source.properties').write_text('Pkg.Revision=36.3.10\nPkg.BuildId=14472402\n')
        proc = self.out/'proc'
        (proc/'42').mkdir(parents=True)
        (proc/'42/comm').write_text('qemu-system-x86\n')
        (proc/'42/exe').symlink_to(qemu)
        results = [subprocess.CompletedProcess([], 0, 'libpulse.so.0 => /usr/lib/libpulse.so.0\n', ''),
                   subprocess.CompletedProcess([], 0, 'Android emulator version 36.3.10.0 (build_id 14472402) (CL:N/A)\n', '')]
        return sdk, proc, results

    def test_version_gate_verifies_running_binary_and_captures_library_paths(self):
        sdk, proc, results = self.emulator_fixture()
        with patch('emulator_diagnostics.subprocess.run', side_effect=results) as run:
            proof = verify_emulator(self.out, sdk, proc)
        self.assertTrue(proof['passed'])
        self.assertEqual(proof['running_qemu'][0]['pid'], 42)
        self.assertIn(str(sdk/'emulator/lib64'), run.call_args.kwargs['env']['LD_LIBRARY_PATH'])
        self.assertTrue((self.out/'emulator-version.txt').exists())
        self.assertTrue((self.out/'emulator-libraries.txt').exists())

    def test_version_gate_rejects_missing_libpulse(self):
        sdk, proc, results = self.emulator_fixture()
        results[0] = subprocess.CompletedProcess([], 0, 'libpulse.so.0 => not found\n', '')
        with patch('emulator_diagnostics.subprocess.run', side_effect=results), self.assertRaisesRegex(RuntimeError, 'dependencies'):
            verify_emulator(self.out, sdk, proc)

    def test_version_gate_rejects_load_failure_even_when_version_text_is_present(self):
        sdk, proc, results = self.emulator_fixture()
        results[1] = subprocess.CompletedProcess([], 1, results[1].stdout, 'libpulse.so.0 missing')
        with patch('emulator_diagnostics.subprocess.run', side_effect=results), self.assertRaisesRegex(RuntimeError, 'binary did not verify'):
            verify_emulator(self.out, sdk, proc)

    def test_version_gate_rejects_wrong_version_and_build(self):
        sdk, proc, results = self.emulator_fixture()
        results[1] = subprocess.CompletedProcess([], 0, 'Android emulator version 37.2.12.0 (build_id 16428233)', '')
        with patch('emulator_diagnostics.subprocess.run', side_effect=results), self.assertRaisesRegex(RuntimeError, 'binary did not verify'):
            verify_emulator(self.out, sdk, proc)

    def test_version_gate_rejects_missing_running_qemu(self):
        sdk, proc, results = self.emulator_fixture()
        (proc/'42/exe').unlink()
        with patch('emulator_diagnostics.subprocess.run', side_effect=results), self.assertRaisesRegex(RuntimeError, 'Running QEMU'):
            verify_emulator(self.out, sdk, proc)

    def test_version_gate_rejects_different_running_binary(self):
        sdk, proc, results = self.emulator_fixture()
        different = self.out/'different-qemu'
        different.write_text('wrong binary')
        (proc/'42/exe').unlink()
        (proc/'42/exe').symlink_to(different)
        with patch('emulator_diagnostics.subprocess.run', side_effect=results), self.assertRaisesRegex(RuntimeError, 'Running QEMU'):
            verify_emulator(self.out, sdk, proc)


if __name__ == '__main__':
    unittest.main()
