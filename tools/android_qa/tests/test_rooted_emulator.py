"""A root-restart transport loss must not manufacture a ready emulator."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rooted_emulator import ROOT_CLOSED, ROOT_REFUSED, ensure_rooted_emulator


class Clock:
    def __init__(self):
        self.now = 0.0

    def time(self):
        return self.now

    def sleep(self, duration):
        self.now += duration


class Device:
    def __init__(self, *, serial='emulator-5554', root='restarting adbd as root\n',
                 uid='0', boot='1', wait='', root_error=None):
        self.serial, self.root, self.uid, self.boot, self.wait = serial, root, uid, boot, wait
        self.root_error = root_error
        self.calls = []

    def __call__(self, *args, timeout):
        self.calls.append((args, timeout))
        if args == ('get-serialno',):
            return self.serial
        if args[:2] != ('-s', self.serial):
            raise AssertionError('Recovery command is not bound to the original emulator')
        command = args[2:]
        if command == ('root',):
            if self.root_error:
                raise RuntimeError(self.root_error(args))
            value = self.root
        elif command == ('wait-for-device',):
            value = self.wait
        elif command == ('shell', 'id', '-u'):
            value = self.uid
        elif command == ('shell', 'getprop', 'sys.boot_completed'):
            value = self.boot
        else:
            raise AssertionError('Unexpected command: ' + repr(command))
        if isinstance(value, Exception):
            raise value
        return value


def closed_error(args, *, code=1, extra=''):
    return f'Command failed ({code}): ' + repr(('adb', *args)) + '\n' + ROOT_CLOSED + extra + '\n'


class RootedEmulatorTests(unittest.TestCase):
    def run_helper(self, device):
        clock = Clock()
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        out = Path(directory.name)
        self.out = out
        self.clock = clock
        return ensure_rooted_emulator(device, out, timeout=10, clock=clock.time, sleep=clock.sleep)

    def evidence(self):
        return json.loads((self.out / 'rooted-emulator.json').read_text())

    def test_normal_root_requires_real_uid_zero_and_boot_one(self):
        device = Device()
        result = self.run_helper(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['shell_uid'], 0)
        self.assertIs(result['boot_completed'], True)
        self.assertFalse(result['root_transport_recovered'])
        self.assertEqual(self.evidence(), result)

    def test_exact_recorded_rc1_closed_is_retained_then_uid_and_boot_verified(self):
        device = Device(root_error=closed_error)
        result = self.run_helper(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertTrue(result['root_transport_recovered'])
        root_attempt = next(row for row in result['attempts'] if row['arguments'][-1] == 'root')
        self.assertEqual(root_attempt['status'], 'FAIL')
        self.assertEqual(root_attempt['return_code'], 1)
        self.assertEqual(root_attempt['output'], ROOT_CLOSED)
        self.assertIn(ROOT_CLOSED, root_attempt['error'])
        self.assertEqual(sum(args[-1] == 'root' for args, _ in device.calls), 1)

    def test_all_recovery_commands_remain_bound_to_the_same_emulator_serial(self):
        device = Device(root_error=closed_error)
        self.run_helper(device)
        self.assertEqual(device.calls[0][0], ('get-serialno',))
        self.assertTrue(all(args[:2] == ('-s', 'emulator-5554') for args, _ in device.calls[1:]))
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in device.calls))
        self.assertFalse(any('kill-server' in args for args, _ in device.calls))

    def test_production_root_refusal_is_fatal_even_when_command_returns_zero(self):
        device = Device(root=ROOT_REFUSED)
        with self.assertRaisesRegex(RuntimeError, 'explicitly refuses'):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertFalse(any('wait-for-device' in args for args, _ in device.calls))

    def test_arbitrary_errors_and_other_rcs_are_not_recovered(self):
        errors = (lambda args: 'permission denied',
                  lambda args: closed_error(args, code=2),
                  lambda args: closed_error(args, extra='\npermission denied'),
                  lambda args: closed_error(args).replace('root', 'unroot', 1))
        for factory in errors:
            with self.subTest(factory=factory):
                device = Device(root_error=factory)
                with self.assertRaises(RuntimeError):
                    self.run_helper(device)
                self.assertEqual(self.evidence()['status'], 'FAIL')
                self.assertFalse(any('wait-for-device' in args for args, _ in device.calls))

    def test_non_root_shell_or_unfinished_boot_cannot_pass_or_reroot_forever(self):
        for device in (Device(uid='2000'), Device(boot='0')):
            with self.subTest(uid=device.uid, boot=device.boot), self.assertRaises(TimeoutError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertEqual(self.clock.now, 10)
            self.assertEqual(sum(args[-1] == 'root' for args, _ in device.calls), 1)

    def test_malformed_uid_and_failed_verification_are_fatal(self):
        for device in (Device(uid='uid=0(root)'), Device(uid='0.0'),
                       Device(uid=RuntimeError('adb: closed')),
                       Device(boot=RuntimeError('permission denied'))):
            with self.subTest(uid=device.uid, boot=device.boot), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_reconnect_timeout_remains_a_failure_after_exact_root_disconnect(self):
        device = Device(root_error=closed_error,
                        wait=subprocess.TimeoutExpired(['adb', 'wait-for-device'], 10))
        with self.assertRaises(subprocess.TimeoutExpired):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertTrue(self.evidence()['root_transport_recovered'])
        self.assertFalse(any('id' in args for args, _ in device.calls))

    def test_physical_devices_are_rejected_before_root_request(self):
        device = Device(serial='R5CXREALPHONE')
        with self.assertRaisesRegex(RuntimeError, 'disposable emulator'):
            self.run_helper(device)
        self.assertEqual(len(device.calls), 1)
        self.assertEqual(self.evidence()['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
