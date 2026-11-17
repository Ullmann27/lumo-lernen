"""Local parser/source counterexamples only; no SDK install or Android claim."""
import importlib.util
import copy
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


CLI = load('cli22_comparison', ROOT / 'scripts/prepare_android37_cli22.py')
READY = load('cli22_framework_ready', ROOT / 'scripts/android_framework_ready.py')
IMAGE_FIXTURE = ROOT / 'scripts/tests/fixtures/android37_image_43494312623'


def metadata_sdk(sdk):
    for relative, package, revision in [('emulator', 'emulator', '37.2.13'),
            (CLI.IMAGE_RELATIVE, CLI.IMAGE_PACKAGE, '8'),
            ('platforms/android-37.0', 'platforms;android-37.0', '2'),
            ('platform-tools', 'platform-tools', '37.0.0')]:
        folder = sdk / relative
        folder.mkdir(parents=True, exist_ok=True)
        (folder / 'source.properties').write_text('Pkg.Revision=' + revision + '\n')
        parts = revision.split('.')
        version = ''.join('<' + label + '>' + part + '</' + label + '>'
                          for label, part in zip(('major', 'minor', 'micro'), parts))
        (folder / 'package.xml').write_text('<repository><localPackage path="' + package +
            '"><revision>' + version + '</revision></localPackage></repository>')
    expected = {'source.properties': '1f50787fdc2c40508ba14e4bfb1e402c8a71bf435a59f9301e0f841807a07f8e',
                'package.xml': 'fab86f3ea14657cb035acaaa1da9c41be83cc89095dd7ef5aef68c3be40ad062'}
    for name, digest in expected.items():
        raw = (IMAGE_FIXTURE / name).read_bytes()
        if hashlib.sha256(raw).hexdigest() != digest:
            raise AssertionError('The original installed-image fixture was changed: ' + name)
        (sdk / CLI.IMAGE_RELATIVE / name).write_bytes(raw)


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
        metadata_sdk(self.sdk)
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

    def test_later_changed_properties_still_fail_with_same_package_descriptor(self):
        path = self.sdk / CLI.IMAGE_RELATIVE / 'source.properties'
        path.write_text(path.read_text().replace('Pkg.Revision=7', 'Pkg.Revision=8'))
        with self.assertRaisesRegex(ValueError, 'image/emulator properties'):
            CLI.verify_current_avd(self.out)

    def test_later_changed_package_descriptor_fails_with_unchanged_properties(self):
        path = self.sdk / CLI.IMAGE_RELATIVE / 'package.xml'
        tree = ET.parse(path)
        package = next(e for e in tree.getroot() if e.tag.split('}')[-1] == 'localPackage')
        revision = next(e for e in package if e.tag.split('}')[-1] == 'revision')
        next(iter(revision)).text = '9'
        tree.write(path, encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'package descriptor'):
            CLI.verify_current_avd(self.out)


class InstalledPackageMetadataTests(unittest.TestCase):
    def test_official_r08_descriptor_is_distinct_from_embedded_properties(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            metadata_sdk(root / 'sdk')
            observed = CLI.package_records(root / 'sdk', root / 'observed')
            image = observed['image']
            self.assertEqual(image['properties']['Pkg.Revision'], '7')
            self.assertEqual(image['installed_package'], {'path': CLI.IMAGE_PACKAGE,
                'revision': {'major': 8, 'minor': 0, 'micro': 0, 'preview': 0}})
            for name in ('source.properties', 'package.xml'):
                self.assertEqual((root / 'observed/image' / name).read_bytes(), (IMAGE_FIXTURE / name).read_bytes())

    def test_other_revision_path_missing_or_ambiguous_descriptor_is_rejected(self):
        for mutation in ('major', 'minor', 'path', 'missing', 'duplicate'):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                metadata_sdk(root / 'sdk')
                path = root / 'sdk' / CLI.IMAGE_RELATIVE / 'package.xml'
                tree = ET.parse(path)
                package = next(e for e in tree.getroot() if e.tag.split('}')[-1] == 'localPackage')
                revision = next(e for e in package if e.tag.split('}')[-1] == 'revision')
                if mutation == 'major': next(iter(revision)).text = '9'
                if mutation == 'minor': ET.SubElement(revision, 'minor').text = '1'
                if mutation == 'path': package.set('path', CLI.IMAGE_PACKAGE.replace('37.0', '35'))
                if mutation == 'missing': tree.getroot().remove(package)
                if mutation == 'duplicate': tree.getroot().append(copy.deepcopy(package))
                tree.write(path, encoding='utf-8')
                with self.assertRaises(ValueError):
                    CLI.package_records(root / 'sdk', root / 'observed')


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
