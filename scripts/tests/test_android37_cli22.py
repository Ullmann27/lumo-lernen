"""Local parser/source counterexamples only; no SDK install or Android claim."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


CLI = load('cli22_comparison', ROOT / 'scripts/prepare_android37_cli22.py')
READY = load('cli22_framework_ready', ROOT / 'scripts/android_framework_ready.py')


class ActualFileBindingTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-cli22-parser-only-')
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.sdk, self.out, self.avds = self.root / 'sdk', self.root / 'proof', self.root / 'avds'
        tools = self.sdk / 'cmdline-tools/22.0'
        for path, text in {'source.properties': 'Pkg.Revision=22.0\n',
                           'bin/sdkmanager': 'synthetic sdkmanager fixture, never executed',
                           'bin/avdmanager': 'synthetic avdmanager fixture, never executed'}.items():
            target = tools / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
        (self.sdk / 'cmdline-tools/latest').symlink_to('22.0')
        for relative, revision in [('emulator', '37.2.13'), (CLI.IMAGE_RELATIVE, '8'),
                                   ('platforms/android-37.0', '2'), ('platform-tools', '37.0.0')]:
            folder = self.sdk / relative
            folder.mkdir(parents=True, exist_ok=True)
            (folder / 'source.properties').write_text('Pkg.Revision=' + revision + '\n')
        self.avd = self.avds / 'test.avd'
        self.avd.mkdir(parents=True)
        (self.avds / 'test.ini').write_text('path=' + str(self.avd) + '\ntarget=android-37.0\n')
        (self.avd / 'config.ini').write_text('image.sysdir.1=' + CLI.IMAGE_RELATIVE + '/\n'
            'hw.cpu.ncore=2\nhw.ramSize=4096M\nhw.heapSize=512M\n'
            'disk.dataPartition.size=6442450944\nhw.gpu.mode=auto\n')
        self.out.mkdir()
        packages = CLI.package_records(self.sdk, self.out / 'original-package-fixtures')
        self.binding = {'sdk_root': str(self.sdk), 'tools_zip_sha256': CLI.TOOLS_SHA256,
                        'installed_tools_files': CLI.tools_manifest(tools),
                        'source_commit': subprocess.check_output(['git', '--no-replace-objects', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                        'expected_actual_avd_name': 'test', 'packages': packages}
        (self.out / 'prepared.json').write_text(json.dumps(self.binding))
        environment = patch.dict(os.environ, {'ANDROID_HOME': str(self.sdk), 'ANDROID_AVD_HOME': str(self.avds)})
        environment.start(); self.addCleanup(environment.stop)

    def test_generated_configuration_is_read_not_repaired(self):
        before = {p: p.read_bytes() for p in (self.avds / 'test.ini', self.avd / 'config.ini')}
        result = CLI.verify_current_avd(self.out)
        self.assertEqual(result['status'], 'ACTUAL_CLI22_AVD_BINDING_VERIFIED')
        self.assertEqual(result['configuration']['disk.dataPartition.size'], '6442450944')
        for path, data in before.items():
            self.assertEqual(path.read_bytes(), data)
        self.assertEqual((self.out / 'avd-guard/configuration/config.ini').read_bytes(), before[self.avd / 'config.ini'])

    def test_android_zero_pointer_cannot_pass_even_with_android37_image(self):
        pointer = self.avds / 'test.ini'
        pointer.write_text(pointer.read_text().replace('android-37.0', 'android-0'))
        before = pointer.read_bytes()
        with self.assertRaisesRegex(ValueError, 'target is not android-37.0'):
            CLI.verify_current_avd(self.out)
        self.assertEqual(pointer.read_bytes(), before)
        self.assertEqual((self.out / 'avd-guard/avd.ini').read_bytes(), before)

    def test_different_image_or_official_tool_bytes_fail_closed(self):
        tool = self.sdk / 'cmdline-tools/22.0/bin/avdmanager'
        tool.write_text('modified fixture')
        with self.assertRaisesRegex(ValueError, 'tool bytes changed'):
            CLI.verify_current_avd(self.out)
        # A new isolated proof phase tests a different risk without overwriting evidence.
        tool.write_text('synthetic avdmanager fixture, never executed')
        config = self.avd / 'config.ini'
        config.write_text(config.read_text().replace('android-37.0', 'android-35'))
        with self.assertRaisesRegex(ValueError, 'another system image'):
            CLI.verify_current_avd(self.out, phase='different-image')

    def test_foreign_probe_source_or_missing_preparation_is_rejected(self):
        self.binding['source_commit'] = '0' * 40
        (self.out / 'prepared.json').write_text(json.dumps(self.binding))
        with self.assertRaisesRegex(ValueError, 'another probe source'):
            CLI.verify_current_avd(self.out)
        (self.out / 'prepared.json').unlink()
        with self.assertRaises(FileNotFoundError):
            CLI.verify_current_avd(self.out, phase='missing')

    def test_unverified_zip_is_not_extracted_or_executed(self):
        archive = self.root / 'untrusted.zip'
        with zipfile.ZipFile(archive, 'w') as output:
            output.writestr('cmdline-tools/source.properties', 'Pkg.Revision=22.0\n')
        destination = self.root / 'unpacked'
        with self.assertRaisesRegex(ValueError, 'SHA256 mismatch'):
            CLI.extract_verified_tools(archive, destination)
        self.assertFalse(destination.exists())

    def test_sdk_registration_metadata_does_not_allow_changed_official_files(self):
        tools = self.sdk / 'cmdline-tools/22.0'
        expected = self.binding['installed_tools_files']
        (tools / 'package.xml').write_text('<synthetic-sdk-registration/>')
        CLI.require_official_tools(tools, expected)
        (tools / 'bin/unreviewed-command').write_text('extra program')
        with self.assertRaisesRegex(ValueError, 'tool bytes changed'):
            CLI.require_official_tools(tools, expected)


class FrameworkBindingTests(unittest.TestCase):
    def test_resources_are_exactly_three_read_only_observations(self):
        calls = []
        def run(name, arguments, timeout):
            calls.append((name, arguments, timeout))
            return {'returncode': 0, 'timed_out': False, 'stdout': 'synthetic', 'stderr': ''}
        READY.observe_resources(SimpleNamespace(run=run), 10, clock=lambda: 0)
        self.assertEqual([args for _, args, _ in calls],
                         [['df', '-k', '/data'], ['cat', '/proc/meminfo'], ['cat', '/proc/mounts']])
        self.assertTrue(all(0 < timeout <= 2 for _, _, timeout in calls))

    def test_failed_actual_avd_binding_cannot_reach_framework_acceptance(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            (out / 'monitor-process.json').write_text(json.dumps({'serial': 'emulator-5554', 'adb': '/synthetic/adb'}))
            with patch.object(READY, 'monitor_alive', return_value=True), \
                    patch.object(READY, 'adb_path', return_value='/synthetic/adb'), \
                    patch.object(READY, 'observe_resources', return_value={'synthetic': True}) as resources, \
                    patch.object(READY.subprocess, 'run', return_value=SimpleNamespace(returncode=1)), \
                    patch.object(READY, 'poll_framework') as framework:
                result = READY.wait_for_framework(out, 'emulator-5554', 120, 10, 3, out / 'cli22')
            self.assertEqual(result, 1)
            framework.assert_not_called()
            resources.assert_called_once()
            self.assertEqual(json.loads((out / 'framework-readiness.json').read_text())['reason'],
                             'actual_cli22_avd_binding_not_verified')


if __name__ == '__main__':
    unittest.main()
