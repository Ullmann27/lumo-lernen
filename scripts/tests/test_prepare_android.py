import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

spec = importlib.util.spec_from_file_location('prepare_android', Path(__file__).resolve().parents[1] / 'prepare_android.py')
module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)

class AndroidHostTest(unittest.TestCase):
    def test_namespace_permissions_signing_and_idempotence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp); main=root/'android/app/src/main'; main.mkdir(parents=True)
            (main/'AndroidManifest.xml').write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application><activity android:name=".MainActivity" android:exported="true"/></application></manifest>')
            (root/'android/app/build.gradle.kts').write_text('android { namespace = "dev.ullmann.lumo.lumo_lernen"\n defaultConfig { applicationId = "dev.ullmann.lumo.lumo_lernen" } }')
            (root/'tools/auto_install').mkdir(parents=True)
            (root/'tools/auto_install/MainActivity.kt').write_text('package dev.ullmann.lumo\nclass MainActivity')
            (root/'tools/auto_install/lumo_file_paths.xml').write_text('<paths/>')
            (root/'tools/lumo-debug.keystore').write_bytes(b'test-fixture')
            for _ in range(2): module.prepare(root,root/'keystore')
            proguard = (root/'android/app/proguard-rules.pro').read_text()
            expected_rules = {
                f'-dontwarn com.google.mlkit.vision.text.{language}.**'
                for language in ('chinese', 'devanagari', 'japanese', 'korean')
            }
            actual_rules = [line for line in proguard.splitlines() if line.startswith('-')]
            self.assertEqual(set(actual_rules), expected_rules)
            self.assertEqual(len(actual_rules), len(expected_rules))

            # Preserve unrelated rules and a preexisting optional-language rule,
            # including its indentation/comment and missing final newline.
            existing = '# App rules\r\n-keep class example.NativeBridge { *; }\r\n  -dontwarn com.google.mlkit.vision.text.chinese.** # already configured'
            proguard_path = root/'android/app/proguard-rules.pro'
            proguard_path.write_bytes(existing.encode())
            module.prepare(root,root/'keystore')
            first_preparation = proguard_path.read_bytes()
            module.prepare(root,root/'keystore')
            self.assertEqual(proguard_path.read_bytes(), first_preparation)
            self.assertTrue(first_preparation.startswith(existing.encode()))
            actual_rules = [line.split('#',1)[0].strip() for line in first_preparation.decode().splitlines()]
            for rule in expected_rules:
                self.assertEqual(actual_rules.count(rule), 1)
            doc=ET.parse(main/'AndroidManifest.xml').getroot(); attr=module.attr
            self.assertEqual(len(doc.findall('uses-permission')),4)
            self.assertEqual(len(doc.findall('application/provider')),1)
            self.assertEqual(len(doc.findall('application/activity/intent-filter')),1)
            self.assertEqual(doc.find('queries/package').get(attr('name')),'dev.ullmann.lumo3d')
            activity=main/'kotlin/dev/ullmann/lumo/lumo_lernen/MainActivity.kt'
            self.assertTrue(activity.read_text().startswith('package dev.ullmann.lumo.lumo_lernen'))
            self.assertEqual((root/'keystore/debug.keystore').read_bytes(),b'test-fixture')

    def test_kotlin_and_groovy_identity_transitions_and_explicit_signing(self):
        namespace = 'dev.ullmann.lumo.lumo_lernen'
        templates = {
            'build.gradle.kts': f'android {{ namespace = "{namespace}"\n defaultConfig {{ applicationId = "{namespace}" }} }}',
            'build.gradle': f"android {{ namespace '{namespace}'\n defaultConfig {{ applicationId '{namespace}' }} }}",
        }
        for gradle_name, template in templates.items():
            with self.subTest(gradle=gradle_name), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                main = root/'android/app/src/main'
                main.mkdir(parents=True)
                (main/'AndroidManifest.xml').write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application android:label="old"><activity android:name=".MainActivity"/></application></manifest>')
                gradle = root/'android/app'/gradle_name
                gradle.write_text(template)
                (root/'tools/auto_install').mkdir(parents=True)
                (root/'tools/auto_install/MainActivity.kt').write_text('package example\nclass MainActivity')
                (root/'tools/auto_install/lumo_file_paths.xml').write_text('<paths/>')
                (root/'tools/lumo-debug.keystore').write_bytes(b'test-fixture')
                normal_gradle = None
                for side_by_side in (False, True, False):
                    module.prepare(root, root/'unrelated-home', side_by_side=side_by_side)
                    prepared = gradle.read_text()
                    module.prepare(root, root/'unrelated-home', side_by_side=side_by_side)
                    self.assertEqual(gradle.read_text(), prepared)
                    expected_id = namespace + ('.coachpreview' if side_by_side else '')
                    self.assertRegex(prepared, rf'applicationId\s*(?:=\s*)?[\"\x27]{expected_id}[\"\x27]')
                    self.assertEqual(prepared.count(module.SIGNING_START), 1)
                    self.assertIn('storeFile = file("../../tools/lumo-debug.keystore")', prepared)
                    self.assertIn('storePassword = "android"', prepared)
                    self.assertIn('keyAlias = "androiddebugkey"', prepared)
                    self.assertIn('keyPassword = "android"', prepared)
                    self.assertEqual(prepared.count('signingConfig = signingConfigs.getByName("debug")'), 2)
                    self.assertIn('getByName("release")', prepared)
                    self.assertTrue(prepared.startswith(template.replace(namespace + '" }', expected_id + '" }').replace(namespace + "' }", expected_id + "' }")))
                    application = ET.parse(main/'AndroidManifest.xml').getroot().find('application')
                    self.assertEqual(application.get(module.attr('label')), 'Lumo Lernen Neu' if side_by_side else 'Lumo Lernen')
                    self.assertEqual(application.find('provider').get(module.attr('authorities')), '${applicationId}.fileprovider')
                    activity = main/'kotlin'/Path(*namespace.split('.'))/'MainActivity.kt'
                    self.assertTrue(activity.read_text().startswith(f'package {namespace}\n'))
                    if not side_by_side:
                        if normal_gradle is not None:
                            self.assertEqual(prepared, normal_gradle)
                        normal_gradle = prepared
