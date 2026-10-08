"""Resource evidence cannot invent values or touch a different Android process."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from runtime_resource_evidence import PROCESS, capture_resources, parse_meminfo, parse_proc_stat

PID = 9171
IDENTITY = {'source': '5f7f48d2689a70873b888f65774c2ea0cac9c372',
            'godot': '6873c0723d6e6c0587cdf06d990cb6c49502a33a',
            'apk_sha256': '6' * 64, 'android_sdk': 35, 'serial': 'emulator-5554'}
READY = {'status': 'PASS', 'shell_uid': 0, 'boot_completed': True, 'serial': 'emulator-5554'}


def stat(comm='lumo ) game worker'):
    # Fixed Linux field sequence, not generated with the parser's index map.
    return (f'{PID} ({comm}) S 560 9171 560 0 -1 4194560 3145 0 1 0 '
            '624 72 0 0 20 0 8 0 93450 1134202880 65231 18446744073709551615 '
            '1 2 3 0 0 0 0 0 0 0 0 0 17 1 0 0 0 0 0 0 0 0 0 0 0\n')


MODERN = f'''Applications Memory Usage (in Kilobytes):
** MEMINFO in pid {PID} [{PROCESS}] **
 App Summary
                       Pss(KB)                         Rss(KB)
           TOTAL PSS:   187321            TOTAL RSS:   260924       TOTAL SWAP PSS: 0
'''
# Documented Android PSS table format; RSS is genuinely absent here.
TABLE = f'''** MEMINFO in pid {PID} [{PROCESS}] **
                   Pss  Private  Private  Swapped     Heap     Heap     Heap
                 Total    Dirty    Clean    Dirty     Size    Alloc     Free
         TOTAL   216524   208232     4384        0    82916    68345    14570
'''


class FakeDevice:
    def __init__(self, pid=str(PID), proc=None, mem=MODERN, durations=(0, 0, 0)):
        self.responses = [pid, stat() if proc is None else proc, mem]
        self.durations, self.now, self.calls = durations, 0, []

    def clock(self):
        return self.now

    def __call__(self, *args, timeout):
        self.calls.append((args, timeout))
        index = len(self.calls) - 1
        self.now += self.durations[index]
        value = self.responses[index]
        if isinstance(value, Exception):
            raise value
        return value


class ResourceParserTests(unittest.TestCase):
    def test_proc_stat_comm_spaces_and_closing_parentheses_do_not_shift_metrics(self):
        self.assertEqual(parse_proc_stat(stat(), PID),
                         {'user_cpu_ticks': 624, 'system_cpu_ticks': 72,
                          'process_start_ticks': 93450, 'rss_pages': 65231})

    def test_proc_wrong_pid_truncated_state_and_numeric_corruption_fail(self):
        cases = (stat().replace('9171 ', '9172 ', 1), '9171 (game) S 0 0',
                 stat().replace(') S ', ') RS ', 1), stat().replace(' 624 ', ' NaN ', 1),
                 stat().replace(' 65231 ', ' -1 ', 1), 'permission denied')
        for raw in cases:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse_proc_stat(raw, PID)

    def test_modern_android_pss_rss_summary_uses_raw_kib_values(self):
        self.assertEqual(parse_meminfo(MODERN, PID),
                         {'pss_kib': 187321, 'rss_kib': 260924, 'rss_kib_status': 'PASS'})

    def test_documented_pss_table_marks_absent_rss_unavailable_not_zero(self):
        self.assertEqual(parse_meminfo(TABLE, PID),
                         {'pss_kib': 216524, 'rss_kib': None, 'rss_kib_status': 'UNAVAILABLE'})

    def test_meminfo_wrong_pid_or_process_and_malformed_totals_fail(self):
        cases = (MODERN.replace('9171', '9172'), MODERN.replace(PROCESS, PROCESS + '_other'),
                 MODERN.replace('187321', '-1'), MODERN.replace('260924', 'NaN'),
                 MODERN + '\nTOTAL PSS: 1', 'No process found for: 9171',
                 TABLE.replace('Pss', 'Unknown'), TABLE.replace('216524', 'NaN'))
        for raw in cases:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                parse_meminfo(raw, PID)


class ResourceCaptureTests(unittest.TestCase):
    def capture(self, device, **kwargs):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)
        result = capture_resources(device, self.out, kwargs.pop('label', 'first-driving'),
                                   kwargs.pop('identity', IDENTITY), kwargs.pop('readiness', READY),
                                   clock=device.clock, **kwargs)
        self.assertEqual(json.loads(next(self.out.glob('resources-*.json')).read_text()), result)
        return result

    def test_only_three_serial_bound_reads_keep_raw_provenance_and_unknown_conversions(self):
        device = FakeDevice()
        result = self.capture(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual([args for args, _ in device.calls],
                         [('-s', 'emulator-5554', 'shell', 'pidof', PROCESS),
                          ('-s', 'emulator-5554', 'shell', 'cat', '/proc/9171/stat'),
                          ('-s', 'emulator-5554', 'shell', 'dumpsys', 'meminfo', '9171')])
        self.assertEqual([limit for _, limit in device.calls], [5, 5, 10])
        self.assertEqual(result['identity'], IDENTITY)
        self.assertEqual([row['raw'] for row in result['reads']], [str(PID), stat(), MODERN])
        self.assertTrue(all(row['started_utc'] and row['finished_utc'] for row in result['reads']))
        self.assertIsNone(result['cpu_ticks_per_second'])
        self.assertIsNone(result['page_size_bytes'])
        self.assertNotIn('fps', result)

    def test_no_pid_or_multiple_pids_stop_before_stat_and_meminfo(self):
        for pid in ('', '9171 9172', '0', '9171; echo 1'):
            with self.subTest(pid=pid):
                device = FakeDevice(pid=pid)
                result = self.capture(device)
                self.assertEqual(result['status'], 'FAIL')
                self.assertEqual(len(device.calls), 1)
                self.assertNotIn('user_cpu_ticks', result)

    def test_prior_root_identity_serial_and_provenance_fail_without_device_calls(self):
        bad = ({'readiness': {**READY, 'shell_uid': False}},
               {'readiness': {**READY, 'boot_completed': False}},
               {'identity': {**IDENTITY, 'serial': 'emulator-5556'}},
               {'identity': {**IDENTITY, 'source': 'stale-head'}},
               {'identity': {**IDENTITY, 'android_sdk': True}})
        for args in bad:
            with self.subTest(args=args):
                device = FakeDevice()
                self.assertEqual(self.capture(device, **args)['status'], 'FAIL')
                self.assertEqual(device.calls, [])

    def test_shared_deadline_decreases_caps_and_post_command_overrun_preserves_raw(self):
        device = FakeDevice(durations=(3, 4, 0))
        self.assertEqual(self.capture(device, timeout=8)['status'], 'PASS')
        self.assertEqual([limit for _, limit in device.calls], [5, 5, 1])
        device = FakeDevice(durations=(0, 0, 21))
        result = self.capture(device)
        self.assertEqual(result['status'], 'FAIL')
        self.assertIn('exceeded shared deadline', result['error'])
        self.assertEqual(result['reads'][-1]['raw'], MODERN)
        self.assertNotIn('pss_kib', result)

    def test_adb_error_and_bad_meminfo_are_metric_failures_with_raw_evidence(self):
        for mem in (RuntimeError('service unavailable'), 'No process found for: 9171'):
            with self.subTest(mem=mem):
                result = self.capture(FakeDevice(mem=mem))
                self.assertEqual(result['status'], 'FAIL')
                self.assertNotIn('pss_kib', result)
                self.assertIn('error', result)
                self.assertEqual(result['user_cpu_ticks'], 624)

    def test_invalid_label_and_timeout_never_call_device_or_escape_output(self):
        for args in ({'label': '../escape'}, {'timeout': 0}, {'timeout': 21}, {'timeout': True}):
            with self.subTest(args=args):
                device = FakeDevice()
                self.assertEqual(self.capture(device, **args)['status'], 'FAIL')
                self.assertEqual(device.calls, [])


if __name__ == '__main__':
    unittest.main()
