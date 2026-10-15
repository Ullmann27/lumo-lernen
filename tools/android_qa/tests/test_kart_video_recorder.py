"""Constructed process schedules for the real VideoRecorder._run implementation.

These are deterministic unit tests, not a replay of the unknown pidof response
from API36 run 37987900281, and not application/gameplay or real-video evidence.
Only operating-system/ADB boundaries are substituted; the recorder runs intact.
"""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SOURCE = Path(os.environ.get(
    'LUMO_RECORDER_PROBE_SOURCE',
    Path(__file__).resolve().parents[3] / '.github/probes/kart_complete_android_probe.py',
)).resolve()
SPEC = importlib.util.spec_from_file_location('kart_video_probe_under_test', SOURCE)
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)

# Deliberately synthetic unit-test transport bytes; never put in Android proof.
VIDEO_BYTES = b'unit-test-only-not-Android-footage\x00' * 80


class ScheduledProcess:
    """One owned ADB client; completion becomes visible at communicate()."""
    def __init__(self, scenario, args):
        self.scenario, self.args = scenario, args
        self.returncode = scenario.exit_code if scenario.already_finished else None
        self.terminated = False

    def poll(self):
        return self.returncode

    def communicate(self, timeout):
        self.scenario.communicate_timeouts.append(timeout)
        if self.scenario.wait_timeout:
            raise subprocess.TimeoutExpired(self.args, timeout)
        self.scenario.now += self.scenario.communicate_elapsed
        self.returncode = self.scenario.exit_code
        return b'constructed screenrecord transport output\n', None

    def terminate(self):
        self.terminated = True
        self.returncode = -15


class StopAtObservation:
    def __init__(self, scenario):
        self.scenario, self.requested = scenario, False

    def is_set(self):
        return self.requested

    def set(self):
        self.requested = True

    def wait(self, seconds):
        if self.scenario.segment_timeout:
            self.scenario.now += 201
            return False
        self.requested = True
        return True


class ProcessSchedule:
    """Fake OS boundary with explicit outcomes, not replacements of recorder logic."""
    def __init__(self, *, pid_stdout=b'', pid_stderr=b'', pid_rc=1,
                 foreign_target=False, malformed_cmdline=False,
                 command_error=False, exit_code=0, already_finished=False,
                 wait_timeout=False, communicate_elapsed=0,
                 segment_timeout=False, tiny_video=False, query_elapsed=0,
                 later_start_failure=False):
        self.pid_stdout, self.pid_stderr, self.pid_rc = pid_stdout, pid_stderr, pid_rc
        self.foreign_target, self.malformed_cmdline = foreign_target, malformed_cmdline
        self.command_error, self.exit_code = command_error, exit_code
        self.already_finished, self.wait_timeout = already_finished, wait_timeout
        self.communicate_elapsed, self.segment_timeout = communicate_elapsed, segment_timeout
        self.tiny_video, self.query_elapsed = tiny_video, query_elapsed
        self.later_start_failure, self.escaped_launch_error = later_start_failure, None
        self.now = 0.0
        self.process = None
        self.signals, self.calls, self.communicate_timeouts = [], [], []
        self.recorder = None

    def popen(self, args, **kwargs):
        if self.process is not None:
            if self.later_start_failure:
                raise OSError('constructed later ADB-client launch failure')
            raise AssertionError('The stop schedule must start only one segment')
        self.process = ScheduledProcess(self, args)
        return self.process

    def run(self, args, **kwargs):
        self.calls.append((list(args), dict(kwargs)))
        command = list(args)[1:]
        if command == ['shell', 'pidof', 'screenrecord']:
            self.now += self.query_elapsed
            return subprocess.CompletedProcess(args, self.pid_rc, self.pid_stdout, self.pid_stderr)
        if command[:3] == ['exec-out', 'cat', '/proc/31415/cmdline']:
            if self.command_error:
                return subprocess.CompletedProcess(args, 1, b'', b'error: device offline\n')
            expected = [str(arg).encode() for arg in self.process.args[2:]]
            if self.foreign_target:
                expected[-1] = b'/sdcard/another-recording.mp4'
            result = b'\x00'.join(expected) + (b'' if self.malformed_cmdline else b'\x00')
            return subprocess.CompletedProcess(args, 0, result, b'')
        if command[:3] == ['shell', 'kill', '-2'] and len(command) == 4:
            self.signals.append(command[3])
            return subprocess.CompletedProcess(args, 0, b'', b'')
        raise AssertionError('Unexpected external command: ' + repr(args))

    def legacy_adb(self, *args, **kwargs):
        if args[0] == 'pull':
            Path(args[2]).write_bytes(b'x' if self.tiny_video else VIDEO_BYTES)
            if not self.later_start_failure:
                self.recorder.stop_event.set()
            return 'synthetic unit-test pull'
        result = self.run(['adb', *args], **kwargs)
        # Match the actual old command() boundary: merged stderr, ignored rc if
        # check=False. This is why diagnostic prefixes must not be PID data.
        output = result.stdout + result.stderr
        if kwargs.get('check', True) and result.returncode:
            raise RuntimeError('ADB command failed: ' + output.decode())
        return output.decode().strip()


class VideoRecorderProcessTests(unittest.TestCase):
    def run_schedule(self, *, capture_launch_error=False, **kwargs):
        schedule = ProcessSchedule(**kwargs)
        temporary = tempfile.TemporaryDirectory(prefix='lumo-recorder-unit-')
        self.addCleanup(temporary.cleanup)
        out = Path(temporary.name)
        recorder = PROBE.VideoRecorder(out, schedule.legacy_adb)
        schedule.recorder = recorder
        recorder.stop_event = StopAtObservation(schedule)
        with patch.object(PROBE.subprocess, 'Popen', schedule.popen), \
                patch.object(PROBE.subprocess, 'run', schedule.run), \
                patch.object(PROBE.time, 'monotonic', lambda: schedule.now):
            try:
                recorder._run()
            except OSError as error:
                if not capture_launch_error:
                    raise
                schedule.escaped_launch_error = error
        return recorder, schedule, out

    def test_clean_remote_exit_with_delayed_host_observation_collects_without_signal(self):
        recorder, schedule, out = self.run_schedule()
        self.assertEqual(recorder.errors, [], 'A normal remote exit must not become an ownership failure')
        self.assertEqual(len(recorder.records), 1)
        self.assertEqual(schedule.signals, [])
        self.assertEqual(recorder.records[0]['sha256'], hashlib.sha256(VIDEO_BYTES).hexdigest())
        self.assertEqual((out / recorder.records[0]['file']).read_bytes(), VIDEO_BYTES)
        self.assertGreater(schedule.communicate_timeouts[0], 0)
        self.assertLessEqual(schedule.communicate_timeouts[0], 20)

    def test_already_finished_own_client_collects_without_process_discovery(self):
        recorder, schedule, _ = self.run_schedule(already_finished=True)
        self.assertEqual(recorder.errors, [])
        self.assertEqual(len(recorder.records), 1)
        self.assertEqual(schedule.calls, [])
        self.assertEqual(schedule.signals, [])

    def test_live_single_matching_target_receives_only_its_own_sigint(self):
        recorder, schedule, _ = self.run_schedule(pid_stdout=b'31415\n', pid_rc=0)
        self.assertEqual(recorder.errors, [])
        self.assertEqual(len(recorder.records), 1)
        self.assertEqual(schedule.signals, ['31415'])
        self.assertTrue(any('/proc/31415/cmdline' in row[0] for row in schedule.calls),
                        'A single pidof result alone does not prove ownership')

    def test_single_pid_for_another_remote_recording_is_never_signalled(self):
        recorder, schedule, _ = self.run_schedule(pid_stdout=b'31415', pid_rc=0, foreign_target=True)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_multiple_pids_are_not_resolved_by_picking_one(self):
        recorder, schedule, _ = self.run_schedule(pid_stdout=b'31415 31416\n', pid_rc=0)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_invalid_or_group_pid_cannot_receive_a_signal(self):
        for value in (b'0', b'-1', b'00', b'31415 extra', b'adb: device offline', b'\xff'):
            with self.subTest(value=value):
                recorder, schedule, _ = self.run_schedule(pid_stdout=value, pid_rc=0)
                self.assertTrue(recorder.errors)
                self.assertEqual(recorder.records, [])
                self.assertEqual(schedule.signals, [])

    def test_pidof_transport_errors_remain_fatal_even_with_empty_stdout(self):
        for returncode, stderr in ((1, b'error: device offline\n'), (255, b''),
                                   (0, b'* daemon started successfully\n')):
            with self.subTest(returncode=returncode, stderr=stderr):
                recorder, schedule, _ = self.run_schedule(pid_rc=returncode, pid_stderr=stderr)
                self.assertTrue(recorder.errors)
                self.assertEqual(recorder.records, [])
                self.assertEqual(schedule.signals, [])

    def test_pidof_nonzero_status_with_a_numeric_stdout_is_not_success(self):
        recorder, schedule, _ = self.run_schedule(pid_stdout=b'31415', pid_rc=1)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_cmdline_read_error_cannot_authorize_sigint(self):
        recorder, schedule, _ = self.run_schedule(pid_stdout=b'31415', pid_rc=0, command_error=True)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_truncated_cmdline_cannot_authorize_sigint(self):
        recorder, schedule, _ = self.run_schedule(pid_stdout=b'31415', pid_rc=0, malformed_cmdline=True)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_own_client_nonzero_exit_is_never_usable_footage(self):
        recorder, schedule, _ = self.run_schedule(already_finished=True, exit_code=1)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_missing_remote_pid_does_not_allow_an_unbounded_client_wait(self):
        recorder, schedule, _ = self.run_schedule(wait_timeout=True)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])
        self.assertTrue(schedule.process.terminated)
        self.assertTrue(all(0 < timeout <= 20 for timeout in schedule.communicate_timeouts))

    def test_pid_observation_and_client_wait_share_one_20_second_budget(self):
        recorder, schedule, _ = self.run_schedule(query_elapsed=19, communicate_elapsed=0)
        self.assertEqual(recorder.errors, [])
        self.assertEqual(schedule.communicate_timeouts, [1])

    def test_late_successful_client_reply_cannot_bypass_finish_deadline(self):
        recorder, schedule, _ = self.run_schedule(query_elapsed=19, communicate_elapsed=2)
        self.assertTrue(recorder.errors)
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_segment_still_fails_after_its_original_200_second_limit(self):
        recorder, schedule, _ = self.run_schedule(segment_timeout=True)
        self.assertTrue(any('segment deadline' in error for error in recorder.errors))
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_empty_video_cannot_pass_after_a_successful_process_exit(self):
        recorder, schedule, _ = self.run_schedule(already_finished=True, tiny_video=True)
        self.assertTrue(any('no usable footage' in error for error in recorder.errors))
        self.assertEqual(recorder.records, [])
        self.assertEqual(schedule.signals, [])

    def test_actual_command_observations_are_retained_on_transport_failure(self):
        recorder, schedule, out = self.run_schedule(pid_rc=1, pid_stderr=b'error: device offline\n')
        self.assertTrue(recorder.errors)
        path = out / 'android-screenrecord-processes.jsonl'
        self.assertTrue(path.is_file(), 'Preserve stdout, stderr and status that were missing in the real failure')
        rows = [json.loads(line) for line in path.read_text().splitlines()]
        query = next(row for row in rows if row.get('phase') == 'pidof')
        self.assertEqual(query['stdout'], '')
        self.assertEqual(query['stderr'], 'error: device offline\n')
        self.assertEqual(query['returncode'], 1)

    def test_non_utf8_process_response_retains_the_exact_observed_bytes(self):
        raw = b'\xff\x00\xfe'
        recorder, schedule, out = self.run_schedule(pid_stdout=raw, pid_rc=0)
        self.assertTrue(recorder.errors)
        path = out / 'android-screenrecord-processes.jsonl'
        self.assertTrue(path.is_file())
        rows = [json.loads(line) for line in path.read_text().splitlines()]
        query = next(row for row in rows if row.get('phase') == 'pidof')
        self.assertIn('stdout_hex', query, 'UTF-8 replacement text alone loses the original response bytes')
        self.assertEqual(query['stdout_hex'], raw.hex())
        self.assertEqual(query['stderr_hex'], '')
        self.assertEqual(schedule.signals, [])

    def test_later_segment_launch_failure_cannot_pass_using_earlier_footage(self):
        recorder, schedule, _ = self.run_schedule(
            already_finished=True, later_start_failure=True, capture_launch_error=True)
        self.assertIsNone(schedule.escaped_launch_error,
                          'A background thread launch error must be recorded, not disappear after earlier segments')
        self.assertEqual(len(recorder.records), 1)
        self.assertTrue(any('constructed later ADB-client launch failure' in error for error in recorder.errors))
        with patch.object(recorder.thread, 'join', lambda timeout: None):
            result = recorder.stop()
        self.assertEqual(result['status'], 'NOT_EXECUTED_OR_FAILED')
        self.assertEqual(schedule.signals, [])


if __name__ == '__main__':
    program = unittest.main(exit=False)
    report = os.environ.get('LUMO_RECORDER_TEST_REPORT')
    if report:
        result = program.result
        evidence = {
            'schema': 'lumo.screenrecord-constructed-schedules.v1',
            'status': 'PASS' if result.wasSuccessful() else 'FAIL',
            'application_or_gameplay_pass': False,
            'fixture_kind': 'constructed deterministic subprocess schedules; actual failure PID response was not saved',
            'source': {'path': str(SOURCE), 'sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest()},
            'test': {'path': str(Path(__file__).resolve()), 'sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},
            'tests_run': result.testsRun,
            'failures': [{'test': test.id(), 'traceback': detail} for test, detail in result.failures],
            'errors': [{'test': test.id(), 'traceback': detail} for test, detail in result.errors],
            'skipped': [{'test': test.id(), 'reason': reason} for test, reason in result.skipped],
        }
        destination = Path(report)
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(evidence, indent=2) + '\n')
    raise SystemExit(0 if program.result.wasSuccessful() else 1)
