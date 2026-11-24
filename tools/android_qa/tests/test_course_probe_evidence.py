"""Reproduce rc255 evidence failures without an emulator or weakening gameplay gates."""
import importlib.util
import io
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
from contextlib import redirect_stdout

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
spec = importlib.util.spec_from_file_location('course_probe_evidence_under_test',
                                              HERE / 'run_course_android_probe.py')
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


def logs(name, *, movement=True):
    text = ('[LumoRun] ready: grade=1 courses=3\n'
            f'[LumoRun] course {name}: 1939 m, 9 checkpoints\n')
    return text + (f'[LumoRun] running {name} s=23.06\n' if movement else '')


def failed(code=255, stdout='partial log\n', stderr=''):
    return subprocess.CalledProcessError(code, ['adb', 'logcat', '-b', 'all', '-d'],
                                         output=stdout, stderr=stderr)


class CourseEvidenceTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.out = Path(folder.name)
        self.addCleanup(patch.stopall)
        patch.object(probe, 'OUT', self.out).start()
        patch.object(probe.time, 'sleep', lambda _: None).start()

    def flow(self, responses=None, primary=None, *, movement=True):
        responses = {key: list(values) for key, values in (responses or {}).items()}
        primary = primary or {}
        observed, calls, active = [], [], {}

        def gameplay(index, name, require_movement, *, environment):
            self.assertEqual(require_movement, movement)
            if 'environment' in active:
                self.assertIs(environment, active['environment'])
            active['environment'] = environment
            active['name'] = name
            observed.append(name)
            if name in primary:
                raise primary[name]

        def read(*arguments, timeout):
            name = active['name']
            kind = 'logcat' if arguments[0] == 'logcat' else 'exit-info'
            calls.append((name, kind, tuple(arguments), timeout))
            sequence = responses.get((name, kind), [])
            response = sequence.pop(0) if sequence else (
                logs(name, movement=movement) if kind == 'logcat' else 'ACTIVITY MANAGER PROCESS EXIT INFO\n')
            if isinstance(response, Exception):
                raise response
            return SimpleNamespace(returncode=0, stdout=response, stderr='')

        output = io.StringIO()
        with patch.object(probe, 'course', side_effect=gameplay), \
                patch.object(probe, 'captured_adb', side_effect=read), redirect_stdout(output):
            result = probe.run_courses(movement)
        return result, observed, calls, output.getvalue()

    def test_adb_wrapper_preserves_both_failed_original_streams(self):
        def runner(command, **kwargs):
            self.assertTrue(kwargs['capture_output'])
            return subprocess.CompletedProcess(command, 255, 'original stdout\n', 'original stderr\n')
        with self.assertRaises(subprocess.CalledProcessError) as raised:
            probe.captured_adb('logcat', '-b', 'all', '-d', run=runner)
        self.assertEqual(raised.exception.stdout, 'original stdout\n')
        self.assertEqual(raised.exception.stderr, 'original stderr\n')
        self.assertEqual(raised.exception.returncode, 255)

    def test_transient_observed_rc255_is_retained_then_all_three_courses_pass(self):
        result, observed, calls, output = self.flow({('zauberwald', 'logcat'): [failed(), logs('zauberwald')]})
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(observed, probe.COURSES)
        retries = [call for call in calls if call[:2] == ('zauberwald', 'logcat')]
        self.assertEqual(len(retries), 2)
        self.assertEqual((self.out / 'zauberwald-logcat-attempt-1-stdout.txt').read_text(), 'partial log\n')
        self.assertEqual((self.out / 'zauberwald-logcat-attempt-1-stderr.txt').read_bytes(), b'')
        report = json.loads((self.out / 'zauberwald-logcat-attempts.json').read_text())
        self.assertEqual(report['attempts'][0]['error']['return_code'], 255)
        self.assertEqual(report['status'], 'PASS')
        self.assertIn('zauberwald passed', output)
        self.assertTrue((self.out / 'sonnenhafen-exit-info.txt').is_file())

    def test_persistent_rc255_keeps_fail_and_observes_exit_info_and_sonnenhafen(self):
        errors = [failed(stdout=f'partial-{i}\n', stderr=f'err-{i}\n') for i in range(3)]
        result, observed, calls, output = self.flow({('zauberwald', 'logcat'): errors})
        self.assertEqual(result['status'], 'FAIL')
        self.assertEqual(observed, probe.COURSES)
        self.assertEqual(len([call for call in calls if call[:2] == ('zauberwald', 'logcat')]), 3)
        self.assertFalse((self.out / 'zauberwald-logcat.txt').exists())
        self.assertTrue((self.out / 'zauberwald-exit-info.txt').is_file())
        self.assertEqual(result['courses'][2]['status'], 'PASS')
        self.assertNotIn('zauberwald passed', output)
        for i in range(3):
            self.assertEqual((self.out / f'zauberwald-logcat-attempt-{i+1}-stdout.txt').read_text(), f'partial-{i}\n')
            self.assertEqual((self.out / f'zauberwald-logcat-attempt-{i+1}-stderr.txt').read_text(), f'err-{i}\n')

    def test_primary_game_failure_is_not_replaced_by_diagnostic_failure(self):
        primary = subprocess.CalledProcessError(1, ['adb', 'shell', 'pidof', 'game'],
                                                 output='primary stdout\n', stderr='primary stderr\n')
        result, observed, _, _ = self.flow(
            {('dschungelherz', 'logcat'): [failed(), failed(), failed()]},
            {'dschungelherz': primary})
        record = result['courses'][0]
        self.assertEqual(result['status'], 'FAIL')
        self.assertEqual(record['primary_failure']['return_code'], 1)
        self.assertEqual(record['primary_failure']['command'], ['adb', 'shell', 'pidof', 'game'])
        self.assertIn('Required logcat evidence', record['evidence_failures'][0]['message'])
        self.assertEqual((self.out / 'dschungelherz-primary-stdout.txt').read_text(), 'primary stdout\n')
        self.assertEqual((self.out / 'dschungelherz-primary-stderr.txt').read_text(), 'primary stderr\n')
        self.assertEqual(observed, probe.COURSES)

    def test_primary_game_failure_cannot_be_cleared_by_successful_logs(self):
        result, _, _, _ = self.flow(primary={'zauberwald': RuntimeError('Rendered gameplay stayed frozen')})
        record = result['courses'][1]
        self.assertEqual(record['status'], 'FAIL')
        self.assertEqual(record['evidence_failures'], [])
        self.assertEqual(record['primary_failure']['message'], 'Rendered gameplay stayed frozen')

    def test_exit_info_is_mandatory_even_after_successful_gameplay_and_logcat(self):
        result, observed, calls, _ = self.flow({('zauberwald', 'exit-info'): [failed(), failed(), failed()]})
        self.assertEqual(result['status'], 'FAIL')
        self.assertTrue((self.out / 'zauberwald-logcat.txt').exists())
        self.assertFalse((self.out / 'zauberwald-exit-info.txt').exists())
        self.assertEqual(result['courses'][1]['evidence_failures'][0]['kind'], 'exit-info')
        self.assertEqual(observed, probe.COURSES)
        self.assertEqual(len([call for call in calls if call[:2] == ('zauberwald', 'exit-info')]), 3)

    def test_nontransport_permission_failure_is_not_retried(self):
        result, _, calls, _ = self.flow({('zauberwald', 'logcat'): [failed(1, stderr='Permission denied\n')]})
        self.assertEqual(result['status'], 'FAIL')
        self.assertEqual(len([call for call in calls if call[:2] == ('zauberwald', 'logcat')]), 1)

    def test_known_offline_transport_can_recover_with_a_complete_log(self):
        result, _, calls, _ = self.flow({('zauberwald', 'logcat'): [failed(1, stderr='error: device offline\n')]})
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(len([call for call in calls if call[:2] == ('zauberwald', 'logcat')]), 2)
        self.assertFalse(any(call[2][0] in ('root', 'reconnect', 'kill-server') for call in calls))

    def test_zero_exit_with_empty_output_never_reuses_stale_evidence(self):
        (self.out / 'zauberwald-logcat.txt').write_text(logs('zauberwald'))
        result, _, calls, _ = self.flow({('zauberwald', 'logcat'): ['']})
        self.assertEqual(result['status'], 'FAIL')
        self.assertFalse((self.out / 'zauberwald-logcat.txt').exists())
        self.assertEqual(len([call for call in calls if call[:2] == ('zauberwald', 'logcat')]), 1)

    def test_unrelated_nonempty_log_is_not_course_evidence(self):
        result, _, _, _ = self.flow({('zauberwald', 'logcat'): [logs('dschungelherz')]})
        self.assertEqual(result['courses'][1]['status'], 'FAIL')
        self.assertIn('course/movement markers', result['courses'][1]['evidence_failures'][0]['message'])

    def test_movement_marker_stays_required_with_movement_flag(self):
        result, _, _, _ = self.flow({('zauberwald', 'logcat'): [logs('zauberwald', movement=False)]})
        self.assertEqual(result['status'], 'FAIL')
        result, _, _, _ = self.flow(movement=False)
        self.assertEqual(result['status'], 'PASS')

    def test_native_error_in_complete_log_fails(self):
        result, _, _, _ = self.flow({('zauberwald', 'logcat'): [logs('zauberwald') + 'Fatal signal 11\n']})
        self.assertEqual(result['status'], 'FAIL')
        self.assertIn('Fatal signal 11', (self.out / 'zauberwald-native-errors.txt').read_text())

    def test_native_error_in_failed_partial_log_cannot_be_erased_by_retry(self):
        error = failed(stdout='SCRIPT ERROR: native failure\n', stderr='logcat disconnected\n')
        result, _, _, _ = self.flow({('zauberwald', 'logcat'): [error, logs('zauberwald')]})
        self.assertEqual(result['status'], 'FAIL')
        self.assertIn('SCRIPT ERROR', (self.out / 'zauberwald-native-errors.txt').read_text())

    def test_timeout_retains_original_binary_streams_before_retry(self):
        error = subprocess.TimeoutExpired(['adb', 'logcat', '-b', 'all', '-d'], 20,
                                           output=b'raw\xff\n', stderr=b'timed out\n')
        result, _, _, _ = self.flow({('zauberwald', 'logcat'): [error]})
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual((self.out / 'zauberwald-logcat-attempt-1-stdout.txt').read_bytes(), b'raw\xff\n')
        self.assertEqual((self.out / 'zauberwald-logcat-attempt-1-stderr.txt').read_bytes(), b'timed out\n')

    def test_shared_deadline_prevents_an_extra_retry_after_timeout(self):
        now = [0.0]
        calls = []
        def read(*arguments, timeout):
            calls.append(timeout)
            now[0] += timeout
            raise subprocess.TimeoutExpired(['adb', *arguments], timeout,
                                             output=b'partial', stderr=b'waiting')
        with patch.object(probe, 'captured_adb', side_effect=read), self.assertRaises(RuntimeError):
            probe.collect_adb_evidence('zauberwald', 'logcat', ('logcat', '-b', 'all', '-d'),
                                       timeout=1, clock=lambda: now[0], sleep=lambda _: None)
        self.assertEqual(calls, [1.0])
        self.assertFalse((self.out / 'zauberwald-logcat.txt').exists())

    def test_main_exits_nonzero_for_a_retained_evidence_failure(self):
        with patch.object(probe, 'ensure_rooted_emulator'), \
                patch.object(probe, 'adb', return_value='Success'), \
                patch.object(probe, 'run_courses', return_value={
                    'status': 'FAIL', 'courses': [{'status': 'FAIL', 'course': 'zauberwald',
                    'primary_failure': None, 'evidence_failures': [{'kind': 'logcat', 'message': 'missing'}]}]}), \
                patch.object(sys, 'argv', ['probe.py', 'candidate.apk', '--movement']), \
                self.assertRaises(SystemExit) as stopped:
            probe.main()
        self.assertIn('logcat', str(stopped.exception))

    def test_summary_storage_failure_preserves_original_game_failure(self):
        original = Path.write_text
        def write(path, *args, **kwargs):
            if path.name == 'COURSE-PROBE.json':
                raise OSError('diagnostic disk full')
            return original(path, *args, **kwargs)
        with patch.object(Path, 'write_text', new=write):
            result, observed, _, _ = self.flow(
                primary={'zauberwald': RuntimeError('Native game exited')})
        self.assertEqual(result['status'], 'FAIL')
        self.assertEqual(result['courses'][1]['primary_failure']['message'], 'Native game exited')
        self.assertEqual(result['report_failure']['message'], 'diagnostic disk full')
        self.assertEqual(observed, probe.COURSES)


if __name__ == '__main__':
    unittest.main()
