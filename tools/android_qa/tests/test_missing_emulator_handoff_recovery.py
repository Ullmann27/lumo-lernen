"""New recovery contracts for the exact recorded missing-emulator handoff.

Mocks exercise setup only. They do not prove ADB, Android gameplay, or an APK.
The published original root/offline tests remain unchanged.
"""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import test_rooted_emulator as original
from rooted_emulator import ensure_rooted_emulator


MISSING = "Command failed (1): ('adb', 'get-serialno')\nerror: device 'emulator-5554' not found\n"
READY = 'List of devices attached\nemulator-5554\tdevice\n'
EMPTY = 'List of devices attached\n\n'
IDENTITY = {'source': 'a' * 40, 'godot': 'b' * 40, 'apk_sha256': 'c' * 64, 'android_sdk': 35}


class MissingDevice(original.InitialOfflineDevice):
    def __init__(self, *, sdk='35', inventories=None, **kwargs):
        self.sdk = sdk
        kwargs.setdefault('initial_error', MISSING)
        super().__init__(inventories=inventories or [EMPTY, READY, READY], **kwargs)

    def __call__(self, *args, timeout=60, **kwargs):
        if args == ('-s', self.serial, 'shell', 'getprop', 'ro.build.version.sdk'):
            self.calls.append((args, timeout))
            return self.sdk
        return super().__call__(*args, timeout=timeout, **kwargs)


class MissingEmulatorHandoffRecoveryTests(unittest.TestCase):
    def run_helper(self, device, *, prior=True, creative=True, identity=None):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root = Path(temporary.name)
        self.out = root / 'full-race'
        self.clock = original.Clock()
        readiness = root / 'rooted-emulator.json'
        readiness.write_text(json.dumps(original.previous_proof()) + '\n')
        proof = root / 'result.json'
        proof.write_text(json.dumps({'status': 'PASS', **IDENTITY,
                                     'emulator_root_readiness': original.previous_proof()}) + '\n')
        return ensure_rooted_emulator(
            device, self.out, timeout=10,
            previous_readiness=readiness if prior else None,
            previous_probe=proof if creative else None,
            expected_identity=(dict(IDENTITY) if identity is None else identity) if creative else None,
            clock=self.clock.time, sleep=self.clock.sleep)

    def evidence(self):
        return json.loads((self.out / 'rooted-emulator.json').read_text())

    def assert_ready(self, device):
        result = self.run_helper(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertTrue(result['initial_missing_recovered'])
        self.assertFalse(result['initial_offline_recovered'])
        self.assertEqual(result['serial'], 'emulator-5554')
        self.assertEqual(result['android_sdk'], 35)
        self.assertIs(type(result['shell_uid']), int)
        self.assertEqual(result['shell_uid'], 0)
        self.assertIs(result['boot_completed'], True)
        self.assertEqual(result['attempts'][0]['status'], 'FAIL')
        self.assertEqual(result['attempts'][0]['return_code'], 1)
        self.assertEqual(result['attempts'][0]['error'], MISSING)
        self.assertEqual(result['attempts'][0]['output'], "error: device 'emulator-5554' not found")
        self.assertEqual(result['transport_inventories'][-1], {'serial': 'emulator-5554', 'state': 'device'})
        self.assertEqual(sum(args[-1] == 'root' for args, _ in device.calls), 1)
        self.assertEqual(sum(args[-1] == 'wait-for-device' for args, _ in device.calls), 2)
        self.assertTrue(all(args in (('get-serialno',), ('devices',)) or
                            args[:2] == ('-s', 'emulator-5554') for args, _ in device.calls))
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in device.calls))
        self.assertFalse(any(action in args for args, _ in device.calls
                             for action in ('kill-server', 'reconnect', 'install', 'reboot', 'unroot')))
        self.assertEqual(self.evidence(), result)

    def test_exact_missing_transport_may_be_temporarily_absent(self):
        device = MissingDevice()
        self.assert_ready(device)
        self.assertEqual(self.evidence()['transport_inventories'][0], {'serial': None, 'state': 'absent'})

    def test_exact_missing_transport_may_reappear_offline_before_bounded_wait(self):
        self.assert_ready(MissingDevice(inventories=[
            'List of devices attached\nemulator-5554\toffline\n', READY, READY]))

    def test_exact_missing_transport_may_already_be_online_in_inventory(self):
        self.assert_ready(MissingDevice(inventories=[READY, READY, READY]))

    def test_fullrace_entrypoint_consumes_previous_creative_identity_before_app_read(self):
        factory = original.InitialOfflineDevice
        def missing_factory(**kwargs):
            rows = kwargs.pop('inventories')
            return factory(initial_error=MISSING, inventories=[EMPTY, *rows[1:]], **kwargs)
        with patch.object(original, 'InitialOfflineDevice', side_effect=missing_factory):
            case = original.InitialOfflineFullraceIntegrationTests()
            case.test_previous_creative_pass_bootstraps_initial_offline_before_any_installed_apk_read()

    def test_other_serial_return_code_command_or_extra_output_are_not_retried(self):
        errors = [MISSING.replace('5554', '5556'), MISSING.replace('(1)', '(2)'),
                  MISSING.replace('get-serialno', 'get-state'), MISSING + 'permission denied\n',
                  'error: device not found', MISSING.replace("'emulator-5554'", 'emulator-5554')]
        for error in errors:
            with self.subTest(error=error), self.assertRaises(RuntimeError):
                device = MissingDevice(initial_error=error)
                self.run_helper(device)
            self.assertEqual(len(device.calls), 1)
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_missing_without_previous_readiness_or_creative_pass_is_not_recoverable(self):
        for prior, creative in ((False, False), (True, False), (False, True)):
            device = MissingDevice()
            with self.subTest(prior=prior, creative=creative), self.assertRaises(RuntimeError):
                self.run_helper(device, prior=prior, creative=creative)
            self.assertFalse(any(args[-1] == 'wait-for-device' for args, _ in device.calls))

    def test_mismatching_candidate_provenance_fails_before_adb(self):
        for key, value in (('source', 'd' * 40), ('godot', 'd' * 40),
                           ('apk_sha256', 'd' * 64), ('android_sdk', 36)):
            identity = dict(IDENTITY, **{key: value})
            device = MissingDevice()
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                self.run_helper(device, identity=identity)
            self.assertEqual(device.calls, [])

    def test_foreign_multiple_unauthorized_malformed_initial_inventory_fails_before_wait(self):
        inventories = ['emulator-5556\tdevice', 'R5REALPHONE\tdevice',
                       'emulator-5554\tdevice\nemulator-5556\toffline',
                       'emulator-5554\tunauthorized', 'emulator-5554\tdevice extra',
                       'emulator-5554\tunknown']
        for rows in inventories:
            device = MissingDevice(inventories=['List of devices attached\n' + rows + '\n'])
            with self.subTest(rows=rows), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertFalse(any(args[-1] == 'root' or args[-1] == 'wait-for-device'
                                 for args, _ in device.calls))

    def test_headerless_empty_inventory_is_not_an_observed_empty_adb_inventory(self):
        for raw in ('', 'garbage\n', 'List of devices attached extra\n'):
            device = MissingDevice(inventories=[raw])
            with self.subTest(raw=raw), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertFalse(any(args[-1] == 'wait-for-device' for args, _ in device.calls))

    def test_empty_offline_foreign_or_multiple_inventory_after_wait_is_fatal(self):
        for raw in (EMPTY, 'List of devices attached\nemulator-5554\toffline\n',
                    'List of devices attached\nemulator-5556\tdevice\n',
                    READY + 'R5REALPHONE\tdevice\n'):
            device = MissingDevice(inventories=[EMPTY, raw])
            with self.subTest(raw=raw), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_final_unique_inventory_is_reverified_after_root_boot_and_api(self):
        device = MissingDevice(inventories=[EMPTY, READY, READY + 'emulator-5556\tdevice\n'])
        with self.assertRaises(RuntimeError):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertIn(('-s', 'emulator-5554', 'shell', 'getprop', 'ro.build.version.sdk'),
                      [args for args, _ in device.calls])

    def test_bound_serial_or_actual_android_api_mismatch_is_fatal(self):
        for device in (MissingDevice(bound_serial='emulator-5556'), MissingDevice(sdk='36'),
                       MissingDevice(sdk='35extra')):
            with self.subTest(device=device), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_wait_failure_cannot_request_root(self):
        device = MissingDevice(bootstrap_wait=subprocess.TimeoutExpired(['adb', 'wait-for-device'], 10))
        with self.assertRaises(subprocess.TimeoutExpired):
            self.run_helper(device)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_wait_cannot_extend_the_shared_deadline(self):
        def late_wait(timeout):
            self.clock.sleep(timeout)
            return ''
        device = MissingDevice(bootstrap_wait=late_wait)
        with self.assertRaises(TimeoutError):
            self.run_helper(device)
        self.assertEqual(self.clock.now, 10)
        self.assertFalse(any(args[-1] == 'root' for args, _ in device.calls))

    def test_boot_and_uid_share_the_time_remaining_after_missing_transport_wait(self):
        def slow_wait(timeout):
            self.clock.sleep(9)
            return ''
        device = MissingDevice(bootstrap_wait=slow_wait, uid='2000')
        with self.assertRaises(TimeoutError):
            self.run_helper(device)
        self.assertEqual(self.clock.now, 10)
        first_wait = next(i for i, (args, _) in enumerate(device.calls) if args[-1] == 'wait-for-device')
        self.assertTrue(all(timeout <= 1 for _, timeout in device.calls[first_wait + 1:]))
        self.assertEqual(self.evidence()['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
