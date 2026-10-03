import hashlib
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import android_ui

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
BASE = '/data/app/~~fixture/lumo/base.apk'


class InstalledApkBytesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.apk = self.root/'input.apk'; self.apk.write_bytes(b'APK input bytes')
        with patch('android_ui.QA_ROOT', self.root):
            self.device = android_ui.Android()

    def adb(self, content, paths=None):
        def call(*args, **kwargs):
            if args[0] == 'install':
                self.assertEqual(args[1:3], ('--no-incremental', '-r'))
                return 'Performing Streamed Install\nSuccess\n'
            if args[:3] == ('shell', 'pm', 'path'):
                self.assertEqual(args[3], PACKAGE)
                return paths if paths is not None else f'package:{BASE}\n'
            if args[0] == 'pull':
                self.assertEqual(args[1], BASE)
                Path(args[2]).write_bytes(content)
                return '1 file pulled'
            self.fail(f'Unexpected ADB mutation/read: {args}')
        return call

    def test_actual_pulled_base_is_hashed_and_split_paths_are_recorded(self):
        content = self.apk.read_bytes()
        split = '/data/app/~~fixture/lumo/split_config.en.apk'
        with patch('android_ui.package_from_apk', return_value=PACKAGE), patch.object(
                self.device, 'adb', side_effect=self.adb(content, f'package:{split}\npackage:{BASE}\n')):
            proof = self.device.install(self.apk)
        self.assertEqual(proof['installed_base_apk'], {
            'remote_path': BASE, 'bytes': len(content),
            'sha256': hashlib.sha256(content).hexdigest(), 'matches_input': True})
        self.assertEqual(proof['package'], PACKAGE)
        self.assertEqual(proof['installed_split_paths'], [split])

    def test_wrong_bytes_or_size_fail_despite_successful_install_output(self):
        for content in [b'other APK bytes', b'short']:
            with self.subTest(content=content), patch('android_ui.package_from_apk', return_value=PACKAGE), \
                    patch.object(self.device, 'adb', side_effect=self.adb(content)):
                with self.assertRaisesRegex(RuntimeError, 'Installed base.apk differs'):
                    self.device.install(self.apk)

    def test_missing_or_ambiguous_base_fails_before_pull(self):
        for paths in ['', f'package:{BASE}\npackage:/data/app/other/base.apk\n']:
            with self.subTest(paths=paths), patch('android_ui.package_from_apk', return_value=PACKAGE), \
                    patch.object(self.device, 'adb', side_effect=self.adb(b'unused', paths)) as adb:
                with self.assertRaisesRegex(RuntimeError, 'no unique base.apk'):
                    self.device.install(self.apk)
                self.assertEqual(adb.call_count, 2)

    def test_package_is_derived_uniquely_from_apk_before_adb(self):
        with patch('android_ui.shutil.which', return_value='/sdk/aapt'), \
                patch('android_ui.subprocess.run', return_value=SimpleNamespace(
                    stdout=f"package: name='{PACKAGE}' versionCode='275'\n")) as metadata:
            self.assertEqual(android_ui.package_from_apk(self.apk), PACKAGE)
            self.assertEqual(metadata.call_args.args[0], ['/sdk/aapt', 'dump', 'badging', str(self.apk)])
        for output in ["package: name='bad;command'\n", "no manifest\n",
                       f"package: name='{PACKAGE}'\npackage: name='dev.other'\n"]:
            with self.subTest(output=output), patch('android_ui.shutil.which', return_value='/sdk/aapt'), \
                    patch('android_ui.subprocess.run', return_value=SimpleNamespace(stdout=output)), \
                    patch.object(self.device, 'adb') as adb:
                with self.assertRaisesRegex(RuntimeError, 'unambiguous'):
                    self.device.install(self.apk)
                adb.assert_not_called()

    def test_sdk_build_tools_fallback_identifies_package_without_path_aapt(self):
        tool = self.root/'sdk/build-tools/35.0.0/aapt'
        tool.parent.mkdir(parents=True); tool.touch()
        with patch('android_ui.shutil.which', return_value=None), \
                patch.dict('os.environ', {'ANDROID_HOME': str(self.root/'sdk')}, clear=True), \
                patch('android_ui.subprocess.run', return_value=SimpleNamespace(
                    stdout=f"package: name='{PACKAGE}' versionCode='275'\n")) as metadata:
            self.assertEqual(android_ui.package_from_apk(self.apk), PACKAGE)
            self.assertEqual(metadata.call_args.args[0][0], str(tool))


if __name__ == '__main__':
    unittest.main()
