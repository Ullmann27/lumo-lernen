"""Logging must preserve failures and continue rejecting actual fatal errors."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from emulator_diagnostics import ContinuousDiagnostics, save_final_logs


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


if __name__ == '__main__':
    unittest.main()
