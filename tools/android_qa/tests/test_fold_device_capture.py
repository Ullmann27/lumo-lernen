"""Synthetic boundary tests only: no adb, APK installation or device is used."""
import hashlib
import json
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
from types import SimpleNamespace
import unittest
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import fold_device_capture as capture

REMOTE = '/data/app/~~opaque==/dev.ullmann.lumo-random==/base.apk'
HOST = '1234567890abcdef1234567890abcdef12345678'
NATIVE = 'abcdef1234567890abcdef1234567890abcdef12'
THERMAL = 'IsStatusOverride: false\nThermal Status: 0\nHAL Ready: true\n'
HWUI = ('---PROFILEDATA---\nFlags,IntendedVsync,FrameCompleted\n'
        '0,1000000000,1016666667\n0,1016666667,1033333334\n---PROFILEDATA---\n')


def proc_stat(pid, start=93450):
    # Linux fields 14/15/22/24; fixed input, independent of the parser's map.
    return (f'{pid} (lumo ) worker) S 560 9171 560 0 -1 4194560 3145 0 1 0 '
            f'624 72 0 0 20 0 8 0 {start} 1134202880 65231 18446744073709551615\n')


class FakeAdb:
    def __init__(self, args, overrides=None, duration=0.01):
        self.args, self.overrides = args, overrides or {}
        self.calls, self.now, self.duration = [], 0.0, duration
        self.properties = dict(zip(capture.PROPERTIES, ('Synthetic', 'Fixture only', '37', '17',
                                                        'synthetic/fingerprint', 'arm64-v8a', '')))

    def clock(self):
        return self.now

    def sleep(self, duration):
        self.now += duration

    def __call__(self, argv, *, stdin, stdout, stderr, timeout, check):
        assert argv[:3] == [self.args.adb, '-s', self.args.serial]
        assert stdin == subprocess.DEVNULL and check is False
        words = tuple(shlex.split(argv[4])) if argv[3] == 'shell' else tuple(argv[3:])
        self.calls.append((words, timeout, list(argv)))
        value = self.overrides.get(words)
        if isinstance(value, list):
            value = value.pop(0)
        if value is None:
            value = self.default(words)
        self.now += min(self.duration, timeout)
        if self.duration > timeout:
            value = subprocess.TimeoutExpired(argv, timeout)
        if isinstance(value, BaseException):
            stdout.write(b'partial original stdout\n')
            stderr.write(b'partial original stderr\n')
            raise value
        out, err, code = value if isinstance(value, tuple) else (value, b'', 0)
        stdout.write(out.encode() if isinstance(out, str) else out)
        stderr.write(err.encode() if isinstance(err, str) else err)
        return SimpleNamespace(returncode=code)

    def default(self, words):
        if words == ('get-state',):
            return 'device\n'
        if words == ('get-serialno',):
            return self.args.serial + '\n'
        if words == ('id', '-u'):
            return '2000\n'
        if words == ('pm', 'path', capture.PACKAGE):
            return 'package:' + REMOTE + '\n'
        if words == ('toybox', 'sha256sum', REMOTE):
            return self.args.expected_apk_sha256 + '  ' + REMOTE + '\n'
        if words == ('toybox', 'stat', '-c', '%s', REMOTE):
            return str(self.args.apk.stat().st_size) + '\n'
        if words[0] == 'getprop':
            return self.properties[words[1]]
        if words == ('pidof', capture.PACKAGE):
            return '111\n'
        if words == ('pidof', capture.PROCESS):
            return '222\n'
        if words[:1] == ('cat',) and words[1].endswith('/cmdline'):
            return (capture.PROCESS if '/222/' in words[1] else capture.PACKAGE) + '\0'
        if words[:1] == ('cat',) and words[1].endswith('/stat'):
            return proc_stat(words[1].split('/')[2])
        if words[:2] == ('dumpsys', 'meminfo'):
            process = capture.PROCESS if words[2] == '222' else capture.PACKAGE
            return (f'** MEMINFO in pid {words[2]} [{process}] **\n'
                    'TOTAL PSS: 187321 TOTAL RSS: 260924 TOTAL SWAP PSS: 0\n')
        if words == ('dumpsys', 'thermalservice'):
            return THERMAL
        if words == ('dumpsys', 'gfxinfo', capture.PACKAGE, 'framestats'):
            return HWUI
        return 'Synthetic raw response; no device was queried\n'


class DeviceCaptureTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.args = SimpleNamespace(
            apk=self.root / 'synthetic.apk', provenance=self.root / 'BUILD-PROVENANCE.json',
            out=self.root / 'capture', serial='SYNTHETIC-SERIAL', package=capture.PACKAGE,
            source=HOST, native_source=NATIVE, expected_apk_sha256='', adb='adb-not-executed',
            expected_api=37, samples=1, interval=1, command_timeout=10, budget=180, surface_layer=None)
        self.pck = b'synthetic PCK bytes, not an executable Godot package'
        self.pck_sha = hashlib.sha256(self.pck).hexdigest()
        self.info = {'package': capture.PACKAGE, 'versionCode': 2019, 'versionName': '0.13.7',
                     'abis': ['arm64-v8a'], 'signingCertificateSha256': capture.CERTIFICATE,
                     'flutter_source_commit': HOST, 'tracked_source_clean': True,
                     'godot': {'revision': NATIVE, 'pck_sha256': self.pck_sha}}
        self.write_apk()

    def write_apk(self, *, embedded=None, pck=None, duplicate=False):
        source = {'revision': NATIVE, 'pck_sha256': self.pck_sha} if embedded is None else embedded
        with zipfile.ZipFile(self.args.apk, 'w') as archive:
            archive.writestr('assets/lumo_game_source.json', json.dumps(source))
            archive.writestr('assets/lumo_game.pck', self.pck if pck is None else pck)
            if duplicate:
                with warnings.catch_warnings():
                    warnings.simplefilter('ignore', UserWarning)
                    archive.writestr('assets/lumo_game_source.json', json.dumps(source))
        self.args.expected_apk_sha256 = hashlib.sha256(self.args.apk.read_bytes()).hexdigest()
        self.info.update(sha256=self.args.expected_apk_sha256, bytes=self.args.apk.stat().st_size)
        self.write_info()

    def write_info(self):
        self.args.provenance.write_text(json.dumps(self.info))

    def collect(self, fake=None):
        fake = fake or FakeAdb(self.args)
        report = capture.collect(self.args, runner=fake, clock=fake.clock, sleeper=fake.sleep)
        self.assertEqual(report, json.loads((self.args.out / 'capture.json').read_text()))
        return report, fake

    def recorder(self, fake):
        self.args.out.mkdir()
        return capture.Recorder(self.args, runner=fake, clock=fake.clock)

    def test_valid_synthetic_capture_binds_before_after_and_hashes_every_original(self):
        report, fake = self.collect()
        self.assertEqual(report['status'], 'RECORDED_WITH_LIMITATIONS')
        self.assertEqual(report['binding_before'], report['binding_after'])
        self.assertEqual(report['artifact']['flutter_source_commit'], HOST)
        self.assertEqual(report['artifact']['godot']['revision'], NATIVE)
        self.assertEqual(report['provenance']['sha256'], hashlib.sha256(self.args.provenance.read_bytes()).hexdigest())
        self.assertIsNone(report['native_fps']['value'])
        self.assertIsNone(report['gpu_frame_time']['value'])
        self.assertIsNone(report['touch_latency']['value'])
        native = report['samples'][0]['processes'][1]
        self.assertEqual(native['counters']['user_cpu_ticks'], 624)
        self.assertEqual(native['native_memory']['pss_kib'], 187321)
        self.assertIsNone(native['cpu_percent'])
        manifest = json.loads((self.args.out / 'MANIFEST.json').read_text())
        paths = {row['path'] for row in manifest['files']}
        self.assertEqual(paths, {str(p.relative_to(self.args.out)) for p in self.args.out.rglob('*')
                                 if p.is_file() and p.name != 'MANIFEST.json'})
        for row in manifest['files']:
            raw = (self.args.out / row['path']).read_bytes()
            self.assertEqual((len(raw), hashlib.sha256(raw).hexdigest()), (row['bytes'], row['sha256']))
        self.assertTrue(all(capture.allowed_read(words) or words in {('get-state',), ('get-serialno',)}
                            for words, _, _ in fake.calls))

    def test_wrong_local_identity_stops_before_any_device_read(self):
        self.args.expected_apk_sha256 = 'f' * 64
        report, fake = self.collect()
        self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')
        self.assertEqual(fake.calls, [])
        self.assertIn('digest mismatch', report['error'])

    def test_host_native_clean_certificate_abi_and_metadata_types_are_required(self):
        cases = [('flutter_source_commit', '0' * 40), ('tracked_source_clean', False),
                 ('signingCertificateSha256', 'a' * 64), ('abis', ['x86_64']),
                 ('bytes', True), ('versionCode', True), ('godot', []), ('package', 'other.app')]
        original = dict(self.info)
        for key, value in cases:
            with self.subTest(key=key):
                self.info = {**original, key: value}
                self.write_info()
                with self.assertRaises(ValueError):
                    capture.validate_local_artifact(self.args)
        self.info = original
        self.write_info()
        self.args.native_source = '0' * 40
        with self.assertRaises(ValueError):
            capture.validate_local_artifact(self.args)

    def test_wrong_actual_pack_embedded_identity_and_duplicate_entries_are_rejected(self):
        for kwargs in ({'pck': b'different actual pack'}, {'embedded': {'revision': '0' * 40,
                       'pck_sha256': self.pck_sha}}, {'duplicate': True}):
            with self.subTest(kwargs=kwargs):
                self.write_apk(**kwargs)
                with self.assertRaises(ValueError):
                    capture.validate_local_artifact(self.args)

    def test_ambiguous_json_keys_and_nonobject_provenance_are_not_accepted(self):
        with self.assertRaises(ValueError):
            capture.unique_json('{"sha256":"one","sha256":"two"}')
        self.args.provenance.write_text('[]')
        report, fake = self.collect()
        self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')
        self.assertEqual(fake.calls, [])

    def test_split_missing_and_unsafe_remote_paths_are_refused(self):
        for value in ('', 'package:' + REMOTE + '\npackage:/data/app/split.apk',
                      'package:/data/app/a/../base.apk', 'package:/data/app/a/base.apk;id',
                      'package:/data/local/tmp/base.apk'):
            with self.subTest(value=value), self.assertRaises(ValueError):
                capture.base_apk_path(value)

    def test_mutating_or_escaping_commands_and_serials_never_reach_runner(self):
        for words in [('root',), ('install', 'app.apk'), ('pm', 'clear', capture.PACKAGE),
                      ('am', 'force-stop', capture.PACKAGE), ('input', 'tap', '1', '2'),
                      ('settings', 'put', 'global', 'x', '1'), ('wm', 'size', '1080x2400'),
                      ('dumpsys', 'gfxinfo', capture.PACKAGE, 'reset'),
                      ('dumpsys', 'SurfaceFlinger', '--latency-clear'),
                      ('dumpsys', 'thermalservice', 'override-status', '0')]:
            with self.subTest(words=words):
                self.assertFalse(capture.allowed_read(words))
        self.args.serial = 'SERIAL;reboot'
        report, fake = self.collect()
        self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')
        self.assertEqual(fake.calls, [])

    def test_required_installed_hash_serial_size_and_nonroot_checks_fail_closed(self):
        cases = [(('toybox', 'sha256sum', REMOTE), '0' * 64 + '  ' + REMOTE),
                 (('toybox', 'stat', '-c', '%s', REMOTE), '1'),
                 (('get-serialno',), 'DIFFERENT'), (('id', '-u'), '0'),
                 (('pm', 'path', capture.PACKAGE), '')]
        for index, (words, value) in enumerate(cases):
            with self.subTest(words=words):
                self.args.out = self.root / ('failure-' + str(index))
                report, _ = self.collect(FakeAdb(self.args, {words: value}))
                self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')
                self.assertEqual(report['samples'], [])

    def test_changed_apk_at_end_retains_raw_samples_without_accepting_binding(self):
        expected = self.args.expected_apk_sha256 + '  ' + REMOTE
        report, _ = self.collect(FakeAdb(self.args, {('toybox', 'sha256sum', REMOTE):
                                                    [expected, '0' * 64 + '  ' + REMOTE]}))
        self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')
        self.assertEqual(len(report['samples']), 1)
        self.assertNotIn('binding_after', report)

    def test_actual_sdk_release_and_abi_are_checked_without_changing_device(self):
        for index, (key, value) in enumerate([('ro.build.version.sdk', '35'),
                                            ('ro.build.version.release', '16'),
                                            ('ro.product.cpu.abilist', 'x86_64')]):
            with self.subTest(key=key):
                self.args.out = self.root / ('runtime-' + str(index))
                fake = FakeAdb(self.args)
                fake.properties[key] = value
                report, _ = self.collect(fake)
                self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')
                self.assertEqual(report['samples'], [])

    def test_optional_permission_failures_remain_missing_and_preserve_exact_stderr(self):
        report, _ = self.collect(FakeAdb(self.args, {('dumpsys', 'thermalservice'):
                                     ('', 'Permission Denial: shell cannot read thermalservice\n', 1),
                                     ('cat', '/proc/222/stat'): ('', 'Permission denied\n', 1)}))
        self.assertEqual(report['status'], 'RECORDED_WITH_LIMITATIONS')
        observation = report['samples'][0]['observations']['thermalservice']
        self.assertEqual(observation['status'], 'UNSUPPORTED_OR_ERROR')
        self.assertNotIn('interpretation', observation)
        native = report['samples'][0]['processes'][1]
        self.assertEqual(native['status'], 'NOT_MEASURED')
        self.assertNotIn('counters', native)
        self.assertEqual(native['native_memory']['pid_lifetime_check'], 'NOT_MEASURED')
        stderr = next((self.args.out / 'raw').glob('*thermalservice.stderr')).read_bytes()
        self.assertEqual(stderr, b'Permission Denial: shell cannot read thermalservice\n')

    def test_timeout_and_missing_executable_keep_partial_original_outputs_and_status(self):
        for index, error in enumerate((subprocess.TimeoutExpired('adb', 2), FileNotFoundError('missing adb'))):
            with self.subTest(error=error):
                self.args.out = self.root / ('command-' + str(index))
                fake = FakeAdb(self.args, {('dumpsys', 'window'): error})
                recorder = self.recorder(fake)
                row, _ = recorder.read('window', 'dumpsys', 'window')
                self.assertEqual(row['status'], 'TIMEOUT' if index == 0 else 'ERROR')
                self.assertIsNone(row['exit_code'])
                self.assertEqual((self.args.out / row['stdout']['path']).read_bytes(), b'partial original stdout\n')
                self.assertEqual((self.args.out / row['stderr']['path']).read_bytes(), b'partial original stderr\n')

    def test_interruption_keeps_command_status_and_partial_bytes_without_end_binding(self):
        report, _ = self.collect(FakeAdb(self.args, {('dumpsys', 'window'): KeyboardInterrupt()}))
        self.assertEqual(report['status'], 'INTERRUPTED_UNVERIFIED_END')
        self.assertNotIn('binding_after', report)
        rows = [json.loads(line) for line in (self.args.out / 'commands.jsonl').read_text().splitlines()]
        self.assertEqual(rows[-1]['status'], 'INTERRUPTED')
        self.assertEqual((self.args.out / rows[-1]['stdout']['path']).read_bytes(), b'partial original stdout\n')

    def test_zero_exit_missing_service_is_not_observed_and_deadline_does_not_succeed(self):
        fake = FakeAdb(self.args, {('dumpsys', 'thermalservice'): "Can't find service: thermalservice\n"})
        recorder = self.recorder(fake)
        row, _ = recorder.read('thermal', 'dumpsys', 'thermalservice')
        self.assertEqual(row['status'], 'UNSUPPORTED_OR_EMPTY')
        fake.now = recorder.deadline + 1
        count = len(fake.calls)
        row, _ = recorder.read('deadline', 'dumpsys', 'window')
        self.assertEqual(row['status'], 'TIMEOUT')
        self.assertEqual(len(fake.calls), count)
        self.args.out = self.root / 'budget-run'
        self.args.budget = 10
        report, _ = self.collect(FakeAdb(self.args, duration=2))
        self.assertEqual(report['status'], 'FAILED_BINDING_OR_COLLECTION')

    def test_pid_reuse_during_memory_read_does_not_claim_a_stable_measurement(self):
        fake = FakeAdb(self.args, {('cat', '/proc/222/stat'): [proc_stat(222), proc_stat(222, 100000)]})
        recorder = self.recorder(fake)
        result = capture.process_sample(recorder, 'native', capture.PROCESS)
        self.assertEqual(result['status'], 'NOT_MEASURED')
        self.assertIn('reused', result['reason'])
        self.assertNotIn('native_memory', result)
        self.assertIsNone(result['cpu_percent'])

    def test_thermal_override_missing_hal_and_ambiguous_values_are_not_real_measurements(self):
        self.assertEqual(capture.thermal_observation(THERMAL)['thermal_severity'], 0)
        for value in (THERMAL.replace('Override: false', 'Override: true'),
                      THERMAL.replace('Ready: true', 'Ready: false'),
                      THERMAL + 'Thermal Status: 1\n', 'Unrecognized OEM text'):
            with self.subTest(value=value):
                self.assertIn(capture.thermal_observation(value)['status'], ('UNSUITABLE', 'UNSUPPORTED'))

    def test_hwui_rows_cannot_turn_into_native_fps_even_with_regular_60hz_timestamps(self):
        observed = capture.hwui_observation(HWUI)
        self.assertEqual(observed['recognized_hwui_rows'], 2)
        self.assertIsNone(observed['native_fps'])
        self.assertEqual(capture.hwui_observation('no rows')['status'], 'NOT_MEASURED')

    def test_optional_surface_layer_is_quoted_as_one_argument_and_remains_raw(self):
        self.args.surface_layer = 'SurfaceView[' + capture.PACKAGE + '/Activity]#1; $(false)'
        report, fake = self.collect()
        calls = [row for row in fake.calls if row[0][:3] == ('dumpsys', 'SurfaceFlinger', '--latency')]
        self.assertEqual(len(calls), 1)
        self.assertEqual(calls[0][0][3], self.args.surface_layer)
        self.assertIn("'", calls[0][2][-1])
        self.assertEqual(report['samples'][0]['observations']['layer-latency']['status'], 'OBSERVED')
        self.assertIsNone(report['native_fps']['value'])

    def test_existing_output_and_invalid_budget_do_not_overwrite_or_call_adb(self):
        self.args.out.mkdir()
        marker = self.args.out / 'keep.txt'
        marker.write_bytes(b'original')
        fake = FakeAdb(self.args)
        with self.assertRaises(FileExistsError):
            capture.collect(self.args, runner=fake)
        self.assertEqual(marker.read_bytes(), b'original')
        self.assertEqual(fake.calls, [])
        self.args.budget = float('nan')
        with self.assertRaises(ValueError):
            capture.collect(self.args, runner=fake)


if __name__ == '__main__':
    unittest.main()
