import importlib.util
from pathlib import Path
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('embedded', ROOT / 'scripts/prepare_embedded_games.py')
embedded = importlib.util.module_from_spec(spec)
spec.loader.exec_module(embedded)


class EmbeddedAndroidTest(unittest.TestCase):
    def test_same_package_private_engine_repeatable_preparation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            main = root / 'android/app/src/main'
            main.mkdir(parents=True)
            manifest = main / 'AndroidManifest.xml'
            manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android"><application><activity android:name=".MainActivity" android:exported="true" /></application><queries><package android:name="dev.ullmann.lumo3d" /></queries></manifest>')
            gradle = root / 'android/app/build.gradle.kts'
            gradle.write_text('android { namespace = "dev.ullmann.lumo.lumo_lernen"\n defaultConfig { applicationId = "dev.ullmann.lumo.lumo_lernen.coachpreview" } }')
            templates = root / 'tools/auto_install'
            templates.mkdir(parents=True)
            for filename in ('GameEventStore.kt', 'LumoGameActivity.kt'):
                (templates / filename).write_text((ROOT / 'tools/auto_install' / filename).read_text())
            embedded.prepare(root)
            first_manifest, first_gradle = manifest.read_bytes(), gradle.read_bytes()
            embedded.prepare(root)
            self.assertEqual(first_manifest, manifest.read_bytes())
            self.assertEqual(first_gradle, gradle.read_bytes())
            doc = ET.parse(manifest).getroot()
            attr = lambda name: '{http://schemas.android.com/apk/res/android}' + name
            activities = doc.findall('application/activity')
            self.assertEqual(len(activities), 2)
            engine = activities[1]
            self.assertEqual(engine.get(attr('exported')), 'false')
            self.assertEqual(engine.get(attr('process')), ':lumo_game')
            self.assertEqual(engine.get(attr('resizeableActivity')), 'true')
            self.assertFalse(doc.findall('queries/package'))
            renderer = [entry for entry in doc.findall('application/meta-data')
                        if entry.get(attr('name')) == 'io.flutter.embedding.android.EnableImpeller']
            self.assertEqual(len(renderer), 1)
            self.assertEqual(renderer[0].get(attr('value')), 'false')
            self.assertIn('org.godotengine:godot:4.6.3.stable', gradle.read_text())
            self.assertIn('.coachpreview', gradle.read_text())
            self.assertIn('noCompress += "pck"', gradle.read_text())


if __name__ == '__main__':
    unittest.main()
