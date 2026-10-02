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
            (root/'android/app/build.gradle.kts').write_text('android { namespace = "dev.ullmann.lumo.lumo_lernen" }')
            (root/'tools/auto_install').mkdir(parents=True)
            (root/'tools/auto_install/MainActivity.kt').write_text('package dev.ullmann.lumo\nclass MainActivity')
            (root/'tools/auto_install/lumo_file_paths.xml').write_text('<paths/>')
            (root/'tools/lumo-debug.keystore').write_bytes(b'test-fixture')
            for _ in range(2): module.prepare(root,root/'keystore')
            doc=ET.parse(main/'AndroidManifest.xml').getroot(); attr=module.attr
            self.assertEqual(len(doc.findall('uses-permission')),4)
            self.assertEqual(len(doc.findall('application/provider')),1)
            self.assertEqual(len(doc.findall('application/activity/intent-filter')),1)
            self.assertEqual(doc.find('queries/package').get(attr('name')),'dev.ullmann.lumo3d')
            activity=main/'kotlin/dev/ullmann/lumo/lumo_lernen/MainActivity.kt'
            self.assertTrue(activity.read_text().startswith('package dev.ullmann.lumo.lumo_lernen'))
            self.assertEqual((root/'keystore/debug.keystore').read_bytes(),b'test-fixture')
