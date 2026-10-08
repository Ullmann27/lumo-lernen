"""The prior Creative PASS must belong to this candidate and this transport.

These are fault-injected readiness tests, not an Android or APK runtime proof.
"""
import copy
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from rooted_emulator import ensure_rooted_emulator
from test_rooted_emulator import Clock, Device, InitialOfflineDevice, previous_proof


IDENTITY = {'source': 'a' * 40, 'godot': 'b' * 40,
            'apk_sha256': 'c' * 64, 'android_sdk': 35}
PREVIOUS = {'status': 'PASS', **IDENTITY, 'emulator_root_readiness': previous_proof()}
ONLINE = 'List of devices attached\nemulator-5554\tdevice\n'


class IdentityDevice(Device):
    def __init__(self, *, sdk='35', inventories=None, delay=None, **kwargs):
        super().__init__(**kwargs)
        self.sdk = sdk
        self.inventories = iter(inventories or [ONLINE, ONLINE])
        self.delay = delay

    def __call__(self, *args, timeout):
        if args == ('devices',):
            self.calls.append((args, timeout))
            value = next(self.inventories)
        elif args == ('-s', self.serial, 'shell', 'getprop', 'ro.build.version.sdk'):
            self.calls.append((args, timeout))
            value = self.sdk
        else:
            value = super().__call__(*args, timeout=timeout)
        if self.delay:
            self.delay(args, timeout)
        return value


class CreativeIdentityTests(unittest.TestCase):
    def run_helper(self, device, *, previous=None, root=None, expected=None,
                   absent=False, clock=None):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        location = Path(directory.name)
        self.out = location / 'full-race'
        self.clock = clock or Clock()
        self.previous_raw = previous if isinstance(previous, bytes) else json.dumps(
            PREVIOUS if previous is None else previous).encode()
        self.root_raw = json.dumps(previous_proof() if root is None else root).encode()
        (location / 'rooted-emulator.json').write_bytes(self.root_raw)
        if not absent:
            (location / 'result.json').write_bytes(self.previous_raw)
        return ensure_rooted_emulator(
            device, self.out, timeout=10,
            previous_readiness=location / 'rooted-emulator.json',
            previous_probe=location / 'result.json',
            expected_identity=IDENTITY if expected is None else expected,
            clock=self.clock.time, sleep=self.clock.sleep)

    def evidence(self):
        return json.loads((self.out / 'rooted-emulator.json').read_text())

    def test_healthy_handoff_retains_both_raw_proofs_and_rechecks_unique_serial_api_uid_boot(self):
        device = IdentityDevice()
        result = self.run_helper(device)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(result['expected_identity'], IDENTITY)
        self.assertEqual(result['android_sdk'], 35)
        self.assertEqual(result['shell_uid'], 0)
        self.assertIs(result['boot_completed'], True)
        self.assertEqual((self.out / 'previous-rooted-emulator.json').read_bytes(), self.root_raw)
        self.assertEqual((self.out / 'previous-creative-result.json').read_bytes(), self.previous_raw)
        self.assertEqual(result['previous_probe']['sha256'], hashlib.sha256(self.previous_raw).hexdigest())
        self.assertEqual(result['previous_readiness']['sha256'], hashlib.sha256(self.root_raw).hexdigest())
        self.assertEqual(sum(args == ('devices',) for args, _ in device.calls), 2)
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in device.calls))
        self.assertEqual(self.evidence(), result)

    def test_exact_offline_preserves_one_shared_readiness_budget_and_original_failure(self):
        device = InitialOfflineDevice(inventories=[
            'List of devices attached\nemulator-5554\toffline\n', ONLINE, ONLINE])
        original = device.__call__

        def adb(*args, timeout):
            if args == ('-s', 'emulator-5554', 'shell', 'getprop', 'ro.build.version.sdk'):
                device.calls.append((args, timeout))
                return '35'
            return original(*args, timeout=timeout)

        result = self.run_helper(adb)
        self.assertTrue(result['initial_offline_recovered'])
        self.assertEqual(result['attempts'][0]['error'], device.initial_error)
        self.assertEqual(sum(args[-1] == 'root' for args, _ in device.calls), 1)
        self.assertFalse(any('reconnect' in args or 'kill-server' in args for args, _ in device.calls))
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in device.calls))

    def test_wrong_creative_status_apk_source_pin_or_api_rejects_before_any_adb(self):
        for key, value in (('status', 'FAIL'), ('source', 'd' * 40), ('godot', 'd' * 40),
                           ('apk_sha256', 'd' * 64), ('android_sdk', 36), ('android_sdk', 35.0)):
            device = IdentityDevice()
            previous = {**copy.deepcopy(PREVIOUS), key: value}
            with self.subTest(key=key, value=value), self.assertRaisesRegex(RuntimeError, 'identity/provenance'):
                self.run_helper(device, previous=previous)
            self.assertEqual(device.calls, [])
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_missing_previous_creative_result_rejects_before_adb_and_keeps_root_proof(self):
        device = IdentityDevice()
        with self.assertRaises(FileNotFoundError):
            self.run_helper(device, absent=True)
        self.assertEqual(device.calls, [])
        self.assertEqual((self.out / 'previous-rooted-emulator.json').read_bytes(), self.root_raw)
        self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_malformed_duplicate_or_non_object_creative_proof_is_retained_and_rejected(self):
        for raw in (b'{broken', b'{"status":"PASS","status":"FAIL"}', b'[]'):
            device = IdentityDevice()
            with self.subTest(raw=raw), self.assertRaises((RuntimeError, json.JSONDecodeError)):
                self.run_helper(device, previous=raw)
            self.assertEqual(device.calls, [])
            self.assertEqual((self.out / 'previous-creative-result.json').read_bytes(), raw)
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_prior_root_object_must_match_raw_readiness_not_only_claim_a_pass(self):
        for key, value in (('serial', 'emulator-5556'), ('shell_uid', 2000),
                           ('shell_uid', False), ('boot_completed', 1),
                           ('last_boot_completed', '0'), ('status', 'FAIL')):
            previous = copy.deepcopy(PREVIOUS)
            previous['emulator_root_readiness'][key] = value
            device = IdentityDevice()
            with self.subTest(key=key), self.assertRaisesRegex(RuntimeError, 'identity/provenance'):
                self.run_helper(device, previous=previous)
            self.assertEqual(device.calls, [])

    def test_expected_identity_must_have_exact_commits_digest_and_integer_api(self):
        for expected in ({}, {**IDENTITY, 'android_sdk': True}, {**IDENTITY, 'source': 'test-app'},
                         {**IDENTITY, 'apk_sha256': 'c' * 63}, {**IDENTITY, 'unexpected': 'value'}):
            device = IdentityDevice()
            with self.subTest(expected=expected), self.assertRaisesRegex(RuntimeError, 'Exact candidate'):
                self.run_helper(device, expected=expected)
            self.assertEqual(device.calls, [])

    def test_identity_inputs_cannot_be_supplied_without_the_matching_prior_files(self):
        for arguments in ({'previous_probe': Path('result.json')}, {'expected_identity': IDENTITY},
                          {'previous_probe': Path('result.json'), 'expected_identity': IDENTITY}):
            device = IdentityDevice()
            with tempfile.TemporaryDirectory() as directory, self.assertRaises(RuntimeError):
                ensure_rooted_emulator(device, Path(directory), timeout=10, **arguments)
            self.assertEqual(device.calls, [])

    def test_already_online_handoff_still_rejects_second_foreign_or_unauthorized_device_before_root(self):
        for inventory in ('List of devices attached\nemulator-5554 device\nREALPHONE device\n',
                          'List of devices attached\nemulator-5556 device\n',
                          'List of devices attached\nemulator-5554 unauthorized\n'):
            device = IdentityDevice(inventories=[inventory])
            with self.subTest(inventory=inventory), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertFalse(any('root' in args for args, _ in device.calls))
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_actual_api_change_or_malformed_api_stays_fatal_after_uid_boot_verification(self):
        for sdk in ('36', '35.0', 'true', ''):
            device = IdentityDevice(sdk=sdk)
            with self.subTest(sdk=sdk), self.assertRaisesRegex(RuntimeError, 'Actual Android API'):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')
            self.assertEqual(self.evidence()['last_shell_uid'], '0')

    def test_final_transport_inventory_cannot_gain_an_extra_or_offline_device(self):
        for final in ('List of devices attached\nemulator-5554 device\nREALPHONE device\n',
                      'List of devices attached\nemulator-5554 offline\n'):
            device = IdentityDevice(inventories=[ONLINE, final])
            with self.subTest(final=final), self.assertRaises(RuntimeError):
                self.run_helper(device)
            self.assertEqual(self.evidence()['status'], 'FAIL')

    def test_late_successful_api_read_cannot_overrun_the_shared_total_deadline(self):
        clock = Clock()

        def delay(args, timeout):
            if args[-1] == 'ro.build.version.sdk':
                clock.sleep(timeout)

        device = IdentityDevice(delay=delay)
        with self.assertRaisesRegex(TimeoutError, 'total deadline'):
            self.run_helper(device, clock=clock)
        self.assertEqual(clock.now, 10)
        self.assertEqual(self.evidence()['status'], 'FAIL')
        self.assertEqual(self.evidence()['attempts'][-1]['status'], 'FAIL')

    def test_late_successful_final_inventory_cannot_be_reported_as_pass(self):
        clock = Clock()
        inventories = 0

        def delay(args, timeout):
            nonlocal inventories
            if args == ('devices',):
                inventories += 1
                if inventories == 2:
                    clock.sleep(timeout)

        device = IdentityDevice(delay=delay)
        with self.assertRaisesRegex(TimeoutError, 'total deadline'):
            self.run_helper(device, clock=clock)
        self.assertEqual(clock.now, 10)
        self.assertEqual(self.evidence()['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
