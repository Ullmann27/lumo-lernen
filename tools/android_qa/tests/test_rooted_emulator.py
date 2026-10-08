"""A root-restart transport loss must not manufacture a ready emulator."""
import json
import hashlib
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

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


class InitialOfflineDevice(Device):
    """Exact original API35 wrapper failure followed by observed transport state."""
    def __init__(self, *, inventories=None, initial_error=None, bound_serial=None,
                 bootstrap_wait=None, **kwargs):
        super().__init__(**kwargs)
        self.initial_error = (initial_error if initial_error is not None else
                              "Command failed (1): ('adb', 'get-serialno')\nerror: device offline\n")
        self.inventories = iter(inventories or [
            'List of devices attached\nemulator-5554\toffline\n',
            'List of devices attached\nemulator-5554\tdevice\n'])
        self.bound_serial = bound_serial or self.serial
        self.bootstrap_wait = bootstrap_wait
        self.wait_calls = 0

    def __call__(self, *args, timeout=60, **kwargs):
        if args == ('get-serialno',):
            self.calls.append((args, timeout))
            raise RuntimeError(self.initial_error)
        if args == ('devices',):
            self.calls.append((args, timeout))
            return next(self.inventories)
        if args == ('-s', self.serial, 'get-serialno'):
            self.calls.append((args, timeout))
            return self.bound_serial
        if args == ('-s', self.serial, 'wait-for-device'):
            self.wait_calls += 1
            if self.wait_calls == 1 and self.bootstrap_wait is not None:
                self.calls.append((args, timeout))
                if isinstance(self.bootstrap_wait, Exception):
                    raise self.bootstrap_wait
                return self.bootstrap_wait(timeout)
        return super().__call__(*args, timeout=timeout)


def previous_proof(serial='emulator-5554'):
    return {'status': 'PASS', 'serial': serial, 'shell_uid': 0,
            'boot_completed': True, 'last_shell_uid': '0', 'last_boot_completed': '1'}


class InitialOfflineBootstrapTests(unittest.TestCase):
    def run_helper(self, device, *, previous=None, absent=False):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        root = Path(directory.name)
        self.out = root / 'new-probe'
        self.clock = Clock()
        source = root / 'rooted-emulator.json'
        self.previous_raw = previous if isinstance(previous, bytes) else json.dumps(
            previous_proof() if previous is None else previous).encode()
        if not absent:
            source.write_bytes(self.previous_raw)
        return ensure_rooted_emulator(device, self.out, timeout=10, previous_readiness=source,
                                      clock=self.clock.time, sleep=self.clock.sleep)

    def evidence(self):
        return json.loads((self.out / 'rooted-emulator.json').read_text())

    def test_exact_offline_preserves_failure_and_proves_same_serial_uid_and_boot(self):
        device = InitialOfflineDevice()
        result = self.run_helper(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertTrue(result['initial_offline_recovered'])
        self.assertEqual(result['serial'], 'emulator-5554')
        self.assertEqual(result['shell_uid'], 0)
        self.assertIs(result['boot_completed'], True)
        self.assertEqual(result['attempts'][0]['status'], 'FAIL')
        self.assertEqual(result['attempts'][0]['return_code'], 1)
        self.assertEqual(result['attempts'][0]['output'], 'error: device offline')
        self.assertEqual(result['attempts'][0]['error'], device.initial_error)
        self.assertEqual(result['previous_readiness']['sha256'], hashlib.sha256(self.previous_raw).hexdigest())
        self.assertEqual((self.out / 'previous-rooted-emulator.json').read_bytes(), self.previous_raw)
        self.assertEqual(result['transport_inventories'], [
            {'serial': 'emulator-5554', 'state': 'offline'},
            {'serial': 'emulator-5554', 'state': 'device'}])
        self.assertEqual(self.evidence(), result)
        allowed_unbound = (('get-serialno',), ('devices',))
        self.assertTrue(all(args in allowed_unbound or args[:2] == ('-s', 'emulator-5554')
                            for args, _ in device.calls))
        self.assertEqual(sum(args[-1] == 'root' for args, _ in device.calls), 1)
        self.assertEqual(sum(args[-1] == 'wait-for-device' for args, _ in device.calls), 2)
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in device.calls))
        forbidden = ('kill-server', 'start-server', 'reconnect', 'reboot', 'install', 'uninstall', 'unroot')
        self.assertFalse(any(word in args for args, _ in device.calls for word in forbidden))

    def test_unknown_initial_offline_does_not_inventory_or_recover_without_previous_pass(self):
        device = InitialOfflineDevice()
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaisesRegex(RuntimeError, 'device offline'):
                ensure_rooted_emulator(device, Path(directory), timeout=10)
            record = json.loads((Path(directory) / 'rooted-emulator.json').read_text())
        self.assertEqual(record['status'], 'FAIL')
        self.assertFalse(record['initial_offline_recovered'])
        self.assertEqual(len(device.calls), 1)

    def test_missing_previous_readiness_is_fatal_before_any_adb_request(self):
        device = InitialOfflineDevice()
        with self.assertRaises(FileNotFoundError):
            self.run_helper(device, absent=True)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertEqual(device.calls, [])

    def test_previous_root_boot_or_serial_claim_must_be_strict_and_unambiguous(self):
        for field, value in (('status', 'RUNNING'), ('shell_uid', False), ('shell_uid', '0'),
                             ('boot_completed', 1), ('last_shell_uid', '2000'),
                             ('last_boot_completed', '0'), ('serial', 'R5REALPHONE'),
                             ('serial', 'emulator-5554\nemulator-5556')):
            previous = previous_proof()
            previous[field] = value
            device = InitialOfflineDevice()
            with self.subTest(field=field, value=value), self.assertRaisesRegex(RuntimeError, 'Previous probe'):
                self.run_helper(device, previous=previous)
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertEqual(device.calls, [])
            self.assertEqual((self.out / 'previous-rooted-emulator.json').read_bytes(), self.previous_raw)

    def test_malformed_or_duplicate_previous_fields_are_retained_as_failure(self):
        for previous in (b'{broken', b'{"serial":"emulator-5554","serial":"emulator-5556"}'):
            device = InitialOfflineDevice()
            with self.subTest(previous=previous), self.assertRaises((RuntimeError, json.JSONDecodeError)):
                self.run_helper(device, previous=previous)
            self.assertEqual(device.calls, [])
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertEqual((self.out / 'previous-rooted-emulator.json').read_bytes(), previous)

    def test_other_initial_errors_return_codes_or_output_are_never_retried(self):
        observed = InitialOfflineDevice().initial_error
        for error in (observed.replace('(1)', '(2)'), observed + 'permission denied\n',
                      observed.replace('get-serialno', 'get-state'), 'permission denied',
                      "Command failed (1): ('adb', 'get-serialno')\nerror: more than one device/emulator\n"):
            device = InitialOfflineDevice(initial_error=error)
            with self.subTest(error=error), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertEqual(len(device.calls), 1)

    def test_empty_multiple_foreign_unauthorized_or_malformed_inventory_is_fatal(self):
        for rows in ('', 'emulator-5554\toffline\nemulator-5556\tdevice',
                     'emulator-5556\toffline', 'R5REALPHONE\tdevice',
                     'emulator-5554\tunauthorized', 'emulator-5554\tdevice extra',
                     'emulator-5554\tunknown'):
            device = InitialOfflineDevice(inventories=['List of devices attached\n' + rows + '\n'])
            with self.subTest(rows=rows), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertFalse(any(args[-1] == 'root' or args[-1] == 'wait-for-device' for args, _ in device.calls))

    def test_wrong_bound_serial_after_wait_cannot_request_root(self):
        device = InitialOfflineDevice(bound_serial='emulator-5556')
        with self.assertRaisesRegex(RuntimeError, 'Recovered emulator identity'):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_transport_inventory_remains_single_same_and_online_after_wait(self):
        for rows in ('emulator-5554\toffline', 'emulator-5556\tdevice',
                     'emulator-5554\tdevice\nR5REALPHONE\tdevice'):
            device = InitialOfflineDevice(inventories=[
                'List of devices attached\nemulator-5554\toffline\n',
                'List of devices attached\n' + rows + '\n'])
            with self.subTest(rows=rows), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_bootstrap_wait_timeout_is_retained_and_never_requests_root(self):
        error = subprocess.TimeoutExpired(['adb', '-s', 'emulator-5554', 'wait-for-device'], 10)
        device = InitialOfflineDevice(bootstrap_wait=error)
        with self.assertRaises(subprocess.TimeoutExpired):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertFalse(self.evidence()['initial_offline_recovered'])
        self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_late_successful_wait_cannot_extend_the_total_readiness_deadline(self):
        def late_wait(timeout):
            self.clock.sleep(timeout)
            return ''
        device = InitialOfflineDevice(bootstrap_wait=late_wait)
        with self.assertRaisesRegex(TimeoutError, 'total deadline'):
            self.run_helper(device)
        self.assertEqual(self.clock.now, 10)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_bootstrap_consumes_the_same_budget_before_root_boot_verification(self):
        def wait(timeout):
            self.clock.sleep(9)
            return ''
        device = InitialOfflineDevice(bootstrap_wait=wait, uid='2000')
        with self.assertRaises(TimeoutError):
            self.run_helper(device)
        self.assertEqual(self.clock.now, 10)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertTrue(self.evidence()['initial_offline_recovered'])
        self.assertEqual(sum(args[-1] == 'root' for args, _ in device.calls), 1)
        wait_index = next(i for i, (args, _) in enumerate(device.calls) if args[-1] == 'wait-for-device')
        self.assertTrue(all(timeout <= 1 for _, timeout in device.calls[wait_index + 1:]))

    def test_already_online_serial_still_must_match_previous_probe(self):
        device = Device(serial='emulator-5556')
        with self.assertRaisesRegex(RuntimeError, 'Initial emulator serial differs'):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertEqual(len(device.calls), 1)


class InitialOfflineFullraceIntegrationTests(unittest.TestCase):
    def test_previous_creative_pass_bootstraps_initial_offline_before_any_installed_apk_read(self):
        path = Path(__file__).resolve().parents[3] / '.github/probes/kart_complete_android_probe.py'
        spec = importlib.util.spec_from_file_location('fullrace_bootstrap_test', path)
        probe = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(probe)
        device = InitialOfflineDevice(inventories=[
            'List of devices attached\nemulator-5554\toffline\n',
            'List of devices attached\nemulator-5554\tdevice\n',
            'List of devices attached\nemulator-5554\tdevice\n'])
        calls = []
        stop = 'TEST_STOP_AFTER_VERIFIED_ROOT_BEFORE_INSTALLED_APK_READ'

        def adb(*arguments, **kwargs):
            calls.append(arguments)
            if arguments == ('-s', 'emulator-5554', 'shell', 'getprop', 'ro.build.version.sdk'):
                return '35'
            if arguments == ('shell', 'pm', 'path', 'test.package'):
                raise RuntimeError(stop)
            if arguments == ('logcat', '-d'):
                return ''
            return device(*arguments, **kwargs)

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            out = root / 'full-race'
            (root / 'rooted-emulator.json').write_text(json.dumps(previous_proof()) + '\n')
            candidate = root / 'fixture.apk'
            candidate.write_bytes(b'independent readiness unit fixture, not a runtime APK')
            apk_sha = hashlib.sha256(candidate.read_bytes()).hexdigest()
            source_sha, godot_sha = 'a' * 40, 'b' * 40
            (root / 'result.json').write_text(json.dumps({
                'status': 'PASS', 'source': source_sha, 'godot': godot_sha,
                'apk_sha256': apk_sha, 'android_sdk': 35,
                'emulator_root_readiness': previous_proof()}) + '\n')
            cert = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
            (root / 'BUILD-PROVENANCE.json').write_text(json.dumps({
                'flutter_source_commit': source_sha, 'godot': {'revision': godot_sha},
                'versionCode': 1903, 'sha256': apk_sha, 'tracked_source_clean': True,
                'signingCertificateSha256': cert}))
            base = SimpleNamespace(adb=adb, command=lambda *args: 'test-harness')
            creative = SimpleNamespace(base=base, PACKAGE='test.package', CERT=cert,
                                       digest=lambda path: hashlib.sha256(path.read_bytes()).hexdigest(),
                                       ensure_rooted_emulator=ensure_rooted_emulator,
                                       capture=lambda *args: None)
            env = {'LUMO_EXPECT_SOURCE': source_sha, 'LUMO_EXPECT_GODOT': godot_sha,
                   'LUMO_EXPECT_VERSION': '1903', 'LUMO_EXPECT_ANDROID_API': '35'}
            with patch.object(probe, 'load_creative', return_value=creative), \
                    patch.object(sys, 'argv', ['fullrace', '--candidate', str(candidate), '--out', str(out)]), \
                    patch.dict(probe.os.environ, env), patch.object(probe.signal, 'alarm'), \
                    patch.object(probe.signal, 'signal'):
                self.assertEqual(probe.main(), 1)  # Explicit stop; never a manufactured race PASS.
            result = json.loads((out / 'result.json').read_text())
            self.assertEqual(result['error'], stop)
            self.assertEqual(result['emulator_root_readiness']['status'], 'PASS')
            self.assertEqual(result['serial'], 'emulator-5554')
            self.assertEqual(result['source'], source_sha)
            self.assertEqual(calls[0], ('get-serialno',))
            first_app_read = calls.index(('shell', 'pm', 'path', 'test.package'))
            self.assertLess(calls.index(('-s', 'emulator-5554', 'shell', 'id', '-u')), first_app_read)
            self.assertLess(calls.index(('-s', 'emulator-5554', 'shell', 'getprop', 'sys.boot_completed')), first_app_read)
            self.assertEqual(sum(arguments[-1] == 'root' for arguments in calls), 1)
            self.assertFalse(any('install' in args or 'kill-server' in args or 'reconnect' in args for args in calls))


if __name__ == '__main__':
    unittest.main()
