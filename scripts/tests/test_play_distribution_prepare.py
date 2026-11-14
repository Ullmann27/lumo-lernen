"""Exercise generated host transitions; these tests do not claim an AAB build."""
import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET


SPEC = importlib.util.spec_from_file_location(
    'play_prepare_android', Path(__file__).resolve().parents[1] / 'prepare_android.py')
PREPARE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PREPARE)


class PlayDistributionPreparationTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.directory = Path(self.temporary.name)
        self.root = self.directory / 'source'
        self.main = self.root / 'android/app/src/main'
        self.main.mkdir(parents=True)
        self.manifest = self.main / 'AndroidManifest.xml'
        self.manifest.write_text(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
            '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>'
            '<uses-permission-sdk-23 android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>'
            '<application><activity android:name=".MainActivity"/></application></manifest>')
        self.gradle = self.root / 'android/app/build.gradle.kts'
        self.gradle.write_text('android { namespace = "dev.ullmann.lumo.lumo_lernen"\n'
                               'defaultConfig { applicationId = "dev.ullmann.lumo.lumo_lernen" } }')
        templates = self.root / 'tools/auto_install'
        templates.mkdir(parents=True)
        (templates / 'MainActivity.kt').write_text('package example\nclass MainActivity')
        (templates / 'lumo_file_paths.xml').write_text('<paths/>')
        self.family_key = self.root / 'tools/lumo-debug.keystore'
        self.family_key.write_bytes(b'fixture-public-family-key')
        self.upload_key = self.directory / 'upload.keystore'
        self.upload_key.write_bytes(b'fixture-not-a-real-upload-key')
        self.environment = {
            'LUMO_PLAY_STORE_FILE': str(self.upload_key),
            'LUMO_PLAY_STORE_PASSWORD': 'fixture-store-secret',
            'LUMO_PLAY_KEY_ALIAS': 'fixture-upload',
            'LUMO_PLAY_KEY_PASSWORD': 'fixture-key-secret',
        }
        self.key_directory = self.directory / 'android-user'

    def prepare(self, distribution='play', **kwargs):
        with patch.dict(os.environ, self.environment, clear=True):
            PREPARE.prepare(self.root, self.key_directory,
                            distribution=distribution, **kwargs)

    def snapshot(self):
        return {p.relative_to(self.root).as_posix(): p.read_bytes()
                for p in self.root.rglob('*') if p.is_file()}

    def test_play_removes_installer_permission_at_manifest_merge_and_uses_external_signing(self):
        self.prepare()
        first = self.snapshot()
        self.prepare()
        self.assertEqual(first, self.snapshot())
        doc = ET.parse(self.manifest).getroot()
        permission_name = 'android.permission.REQUEST_INSTALL_PACKAGES'
        for tag in ('uses-permission', 'uses-permission-sdk-23'):
            entries = [e for e in doc.findall(tag)
                       if e.get(PREPARE.attr('name')) == permission_name]
            self.assertEqual(len(entries), 1)
            self.assertEqual(entries[0].get(f'{{{PREPARE.TOOLS}}}node'), 'remove')
        channel = next(e for e in doc.findall('application/meta-data')
                       if e.get(PREPARE.attr('name')) == PREPARE.DISTRIBUTION_METADATA)
        self.assertEqual(channel.get(PREPARE.attr('value')), 'play')
        gradle = self.gradle.read_text()
        self.assertIn('signingConfigs.getByName("lumoPlay")', gradle)
        self.assertNotIn('lumo-debug.keystore', gradle)
        self.assertNotIn('signingConfigs.getByName("debug")', gradle)
        self.assertNotIn('.coachpreview', gradle)
        for value in self.environment.values():
            self.assertNotIn(value, gradle)
        self.assertFalse(self.key_directory.exists())

    def test_switching_between_family_and_play_retains_each_channel_behavior(self):
        self.prepare('family', side_by_side=True)
        self.assertIn('.coachpreview', self.gradle.read_text())
        self.prepare()
        self.assertNotIn('.coachpreview', self.gradle.read_text())
        self.prepare('family', side_by_side=True)
        doc = ET.parse(self.manifest).getroot()
        install = [e for e in doc.findall('uses-permission')
                   if e.get(PREPARE.attr('name')) == 'android.permission.REQUEST_INSTALL_PACKAGES']
        self.assertEqual(len(install), 1)
        self.assertNotIn(f'{{{PREPARE.TOOLS}}}node', install[0].attrib)
        self.assertEqual(doc.findall('uses-permission-sdk-23'), [])
        self.assertIn('signingConfigs.getByName("debug")', self.gradle.read_text())
        self.assertNotIn('lumoPlay', self.gradle.read_text())
        self.assertEqual((self.key_directory / 'debug.keystore').read_bytes(),
                         self.family_key.read_bytes())

    def test_missing_credentials_reject_before_any_host_mutation(self):
        before = self.snapshot()
        for name in self.environment:
            with self.subTest(missing=name):
                values = {k: v for k, v in self.environment.items() if k != name}
                with patch.dict(os.environ, values, clear=True):
                    with self.assertRaisesRegex(ValueError, 'Play upload signing is missing'):
                        PREPARE.prepare(self.root, self.key_directory, distribution='play')
                self.assertEqual(self.snapshot(), before)

    def test_public_family_key_is_rejected_even_when_copied_outside_repository(self):
        self.upload_key.write_bytes(self.family_key.read_bytes())
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, 'public family test key'):
            self.prepare()
        self.assertEqual(self.snapshot(), before)

    def test_debug_alias_and_repository_key_are_rejected(self):
        for change, message in (
            ({'LUMO_PLAY_KEY_ALIAS': 'androiddebugkey'}, 'public family test key'),
            ({'LUMO_PLAY_STORE_FILE': str(self.family_key)}, 'outside the repository'),
            ({'LUMO_PLAY_STORE_FILE': 'relative/upload.keystore'}, 'existing absolute file'),
        ):
            with self.subTest(change=tuple(change)):
                before = self.snapshot()
                with patch.dict(self.environment, change):
                    with self.assertRaisesRegex(ValueError, message):
                        self.prepare()
                self.assertEqual(self.snapshot(), before)

    def test_play_rejects_preview_and_unknown_distribution_without_mutation(self):
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, 'family preview package'):
            self.prepare(side_by_side=True)
        with self.assertRaisesRegex(ValueError, 'family or play'):
            self.prepare('typo')
        self.assertEqual(self.snapshot(), before)

    def test_play_rejects_wrong_namespace_without_rewriting_it(self):
        self.gradle.write_text(self.gradle.read_text().replace(
            'dev.ullmann.lumo.lumo_lernen', 'example.unrelated'))
        before = self.snapshot()
        with self.assertRaisesRegex(ValueError, 'canonical Lumo'):
            self.prepare()
        self.assertEqual(self.snapshot(), before)


if __name__ == '__main__':
    unittest.main()
