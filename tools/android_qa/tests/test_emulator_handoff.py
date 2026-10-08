"""A probe boundary may recover only the exact observed disposable transport."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from emulator_handoff import OFFLINE_ERROR, ensure_emulator_handoff

EXPECTED = {'source': 'a'*40, 'godot': 'b'*40, 'apk_sha256': 'c'*64, 'android_sdk': 35}
PREVIOUS = {**EXPECTED, 'status': 'PASS', 'emulator_root_readiness': {
    'status': 'PASS', 'serial': 'emulator-5554', 'shell_uid': 0, 'boot_completed': True}}


class Clock:
    now = 0

    def time(self):
        return self.now

    def sleep(self, duration):
        self.now += duration


class Device:
    def __init__(self, *, error=None, state='device', extra='', serial='emulator-5554',
                 uid='0', boot='1', sdk='35', wait_error=None, reconnect_error=None):
        self.error, self.state, self.extra, self.serial = error, state, extra, serial
        self.uid, self.boot, self.sdk = uid, boot, sdk
        self.wait_error, self.reconnect_error = wait_error, reconnect_error
        self.calls = []

    def __call__(self, *args, timeout):
        self.calls.append((args, timeout))
        if args == ('get-serialno',):
            if self.error:
                raise RuntimeError(self.error)
            return self.serial
        if args == ('devices', '-l'):
            return 'List of devices attached\n' + self.serial + ' ' + self.state + self.extra
        if args == ('reconnect', 'offline'):
            if self.reconnect_error:
                raise self.reconnect_error
            self.state = 'device'
            return 'reconnecting emulator-5554'
        if args[:2] != ('-s', 'emulator-5554'):
            raise AssertionError('Command is not bound to the observed emulator: ' + repr(args))
        command = args[2:]
        if command == ('wait-for-device',):
            if self.wait_error:
                raise self.wait_error
            return ''
        if command == ('get-serialno',):
            return self.serial
        if command == ('get-state',):
            return self.state
        if command == ('shell', 'id', '-u'):
            return self.uid
        if command == ('shell', 'getprop', 'sys.boot_completed'):
            return self.boot
        if command == ('shell', 'getprop', 'ro.build.version.sdk'):
            return self.sdk
        raise AssertionError('Unexpected command: ' + repr(args))


class EmulatorHandoffTests(unittest.TestCase):
    def run_helper(self, device, previous=None):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.out, self.clock = Path(directory.name), Clock()
        return ensure_emulator_handoff(device, self.out,
            copy.deepcopy(PREVIOUS if previous is None else previous), EXPECTED,
            timeout=10, clock=self.clock.time, sleep=self.clock.sleep)

    def proof(self):
        return json.loads((self.out / 'emulator-handoff.json').read_text())

    def test_healthy_device_needs_no_reconnect_but_real_unique_identity_uid_boot_api(self):
        result = self.run_helper(Device())
        self.assertEqual(self.proof(), result)
        self.assertEqual(result['status'], 'PASS')
        self.assertFalse(result['observed_offline'])
        self.assertEqual(result['offline_reconnects'], 0)
        self.assertEqual(result['android_sdk'], 35)

    def test_exact_original_offline_error_is_retained_before_one_reconnect(self):
        device = Device(error=OFFLINE_ERROR+'\n', state='offline')
        result = self.run_helper(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertTrue(result['observed_offline'])
        self.assertEqual(result['offline_reconnects'], 1)
        self.assertEqual(result['attempts'][0]['status'], 'FAIL')
        self.assertEqual(result['attempts'][0]['error'].strip(), OFFLINE_ERROR)
        self.assertEqual(sum(args == ('reconnect', 'offline') for args, _ in device.calls), 1)
        forbidden = {'root', 'reboot', 'kill-server', 'install', 'push', 'am', 'input'}
        self.assertFalse(any(forbidden.intersection(args) for args, _ in device.calls))
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in device.calls))

    def test_already_recovered_transport_does_not_request_a_reset(self):
        result = self.run_helper(Device(error=OFFLINE_ERROR))
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['offline_reconnects'], 0)

    def test_unknown_error_return_code_or_extra_output_stays_fatal(self):
        for error in ('permission denied', OFFLINE_ERROR.replace('(1)', '(2)'),
                      OFFLINE_ERROR+'\nunauthorized', OFFLINE_ERROR.replace('get-serialno', 'shell')):
            device = Device(error=error, state='offline')
            with self.subTest(error=error), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(len(device.calls), 1)
            self.assertEqual(self.proof()['status'], 'FAIL')

    def test_second_device_changed_serial_or_unauthorized_cannot_be_reconnected(self):
        for device in (Device(error=OFFLINE_ERROR, state='offline', extra='\nREALPHONE offline'),
                       Device(serial='emulator-5556'),
                       Device(error=OFFLINE_ERROR, state='unauthorized')):
            with self.subTest(device=device), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertFalse(any(args == ('reconnect', 'offline') for args, _ in device.calls))
            self.assertEqual(self.proof()['status'], 'FAIL')

    def test_prior_failure_wrong_apk_source_api_or_physical_serial_rejects_before_adb(self):
        variants = []
        for key, value in [('status', 'FAIL'), ('source', 'd'*40), ('godot', 'd'*40),
                           ('apk_sha256', 'd'*64), ('android_sdk', 36)]:
            variants.append({**copy.deepcopy(PREVIOUS), key: value})
        for key, value in [('serial', 'REALPHONE'), ('status', 'FAIL'),
                           ('shell_uid', 2000), ('shell_uid', False), ('boot_completed', False)]:
            previous = copy.deepcopy(PREVIOUS)
            previous['emulator_root_readiness'][key] = value
            variants.append(previous)
        for previous in variants:
            device = Device()
            with self.subTest(previous=previous), self.assertRaises(RuntimeError):
                self.run_helper(device, previous)
            self.assertEqual(device.calls, [])

    def test_wait_timeout_and_reconnect_error_never_prove_readiness(self):
        for device in (Device(error=OFFLINE_ERROR, state='offline', reconnect_error=RuntimeError('closed')),
                       Device(wait_error=subprocess.TimeoutExpired(['adb', 'wait-for-device'], 10))):
            with self.subTest(device=device), self.assertRaises((RuntimeError, subprocess.TimeoutExpired)):
                self.run_helper(device)
            self.assertEqual(self.proof()['status'], 'FAIL')
            self.assertFalse(any('id' in args for args, _ in device.calls))

    def test_non_root_unfinished_or_malformed_boot_and_wrong_api_do_not_pass(self):
        for device in (Device(uid='2000'), Device(uid='uid=0(root)'), Device(boot='true'),
                       Device(boot='0'), Device(sdk='36')):
            with self.subTest(device=device), self.assertRaises((RuntimeError, TimeoutError)):
                self.run_helper(device)
            self.assertEqual(self.proof()['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
