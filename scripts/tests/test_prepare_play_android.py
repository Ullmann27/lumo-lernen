"""Fail-closed and reversible production AAB host preparation tests."""
from pathlib import Path
import importlib.util
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
import prepare_android
import prepare_play_android

APP_ID = 'dev.ullmann.lumo.lumo_lernen'


class PlayHostTests(unittest.TestCase):
    def _fixture(self, directory: Path) -> tuple[Path, Path]:
        root = directory
        main = root / 'android/app/src/main'
        main.mkdir(parents=True)
        manifest = main / 'AndroidManifest.xml'
        manifest.write_text(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>'
            '<uses-permission android:name="android.permission.CAMERA"/>'
            '<application android:label="Lumo Lernen"><activity '
            'android:name=".MainActivity" android:exported="true"/></application>'
            '</manifest>', encoding='utf-8')
        gradle = root / 'android/app/build.gradle.kts'
        gradle.write_text(
            'android {\n'
            '    namespace = "dev.ullmann.lumo.lumo_lernen"\n'
            '    compileSdk = flutter.compileSdkVersion\n'
            '    defaultConfig {\n'
            '        applicationId = "dev.ullmann.lumo.lumo_lernen.coachpreview"\n'
            '        targetSdk = flutter.targetSdkVersion\n'
            '    }\n'
            '}\n' + prepare_android.SIGNING_BLOCK + '\n',
            encoding='utf-8')
        return manifest, gradle

    def test_removes_install_permission_and_debug_keys_and_targets_api36(self):
        with tempfile.TemporaryDirectory() as temp:
            manifest, gradle = self._fixture(Path(temp))
            prepare_play_android.prepare(Path(temp), APP_ID)
            doc = ET.parse(manifest).getroot()
            permissions = [
                x.get(prepare_android.attr('name'))
                for x in doc.findall('uses-permission')
            ]
            self.assertNotIn('android.permission.REQUEST_INSTALL_PACKAGES', permissions)
            self.assertIn('android.permission.CAMERA', permissions)
            text = gradle.read_text()
            self.assertIn('applicationId = "' + APP_ID + '"', text)
            self.assertIn('targetSdk = 36', text)
            self.assertIn('compileSdk = 36', text)
            self.assertIn('create("lumoPlayUpload")', text)
            self.assertIn('LUMO_PLAY_UPLOAD_KEYSTORE', text)
            self.assertIn('getByName("release")', text)
            self.assertNotIn('androiddebugkey', text)
            self.assertNotIn('coachpreview', text)
            self.assertNotIn('storePassword = "android"', text)
            with self.assertRaisesRegex(ValueError, 'Expected unchanged'):
                prepare_play_android.prepare(Path(temp), APP_ID)

    def test_rejects_invalid_ids_without_touching_files(self):
        for value in ('', 'lumo', 'dev.ullmann.lumo.coachpreview',
                      'com.Example.app', 'com.ullmann.app;rm -rf /'):
            with self.subTest(value=value), tempfile.TemporaryDirectory() as temp:
                manifest, gradle = self._fixture(Path(temp))
                first = (manifest.read_bytes(), gradle.read_bytes())
                with self.assertRaises(ValueError):
                    prepare_play_android.prepare(Path(temp), value)
                self.assertEqual(first, (manifest.read_bytes(), gradle.read_bytes()))

    def test_missing_target_sdk_fails_before_rewriting_manifest(self):
        with tempfile.TemporaryDirectory() as temp:
            manifest, gradle = self._fixture(Path(temp))
            gradle.write_text(gradle.read_text().replace(
                'targetSdk = flutter.targetSdkVersion',
                'targetSdkVersion flutter.targetSdkVersion'))
            before = manifest.read_bytes(), gradle.read_bytes()
            with self.assertRaisesRegex(ValueError, 'targetSdk'):
                prepare_play_android.prepare(Path(temp), APP_ID)
            self.assertEqual(before, (manifest.read_bytes(), gradle.read_bytes()))


if __name__ == '__main__':
    unittest.main()
