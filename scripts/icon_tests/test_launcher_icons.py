import hashlib
import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('launcher_icons', ROOT/'scripts/prepare_launcher_icons.py')
icons = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(icons)


class LauncherTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        source = self.root / icons.SOURCE
        source.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / icons.SOURCE, source)
        self.manifest = self.root / 'android/app/src/main/AndroidManifest.xml'
        self.manifest.parent.mkdir(parents=True)
        self.manifest.write_text('<manifest xmlns:android="'+icons.ANDROID+'"><application android:label="Lumo Lernen Neu" android:icon="@mipmap/ic_launcher"><activity android:name=".MainActivity"/></application></manifest>')

    def test_all_densities_correct_dimensions(self):
        report = icons.prepare(self.root)
        res = self.manifest.parent/'res'
        for name, scale in icons.DENSITIES.items():
            for file, dp in [('ic_lumo',48), ('ic_lumo_round',48), ('lumo_foreground',108), ('lumo_monochrome',108)]:
                with Image.open(res/f'mipmap-{name}/{file}.png') as image:
                    self.assertEqual(image.size,(round(dp*scale),round(dp*scale)))
        self.assertEqual(len(report['files']),25)

    def test_adaptive_artwork_stays_inside_safe_zone(self):
        icons.prepare(self.root)
        for name, scale in icons.DENSITIES.items():
            with Image.open(self.manifest.parent/f'res/mipmap-{name}/lumo_foreground.png') as image:
                x0,y0,x1,y1 = image.getchannel('A').getbbox()
                inset = (image.width - round(60*scale))//2
                self.assertGreaterEqual(min(x0,y0),inset)
                self.assertLessEqual(max(x1,y1),inset+round(60*scale))

    def test_manifest_links_only_lumo_and_preserves_host(self):
        icons.prepare(self.root)
        app = ET.parse(self.manifest).getroot().find('application')
        attr = lambda key: '{'+icons.ANDROID+'}'+key
        self.assertEqual(app.get(attr('icon')),'@mipmap/ic_lumo')
        self.assertEqual(app.get(attr('roundIcon')),'@mipmap/ic_lumo_round')
        self.assertEqual(app.get(attr('label')),'Lumo Lernen Neu')
        self.assertEqual(app.find('activity').get(attr('name')),'.MainActivity')

    def test_monochrome_is_white_alpha_without_fake_background(self):
        icons.prepare(self.root)
        res = self.manifest.parent/'res/mipmap-xxxhdpi'
        with Image.open(res/'lumo_foreground.png') as fg, Image.open(res/'lumo_monochrome.png') as mono:
            self.assertEqual(fg.getchannel('A').tobytes(),mono.getchannel('A').tobytes())
            self.assertEqual(mono.getextrema()[:3],((255,255),(255,255),(255,255)))
            self.assertEqual(mono.getpixel((0,0))[3],0)

    def test_versioned_layers_resolve(self):
        icons.prepare(self.root)
        for api in (26,33):
            xml = ET.parse(self.manifest.parent/f'res/mipmap-anydpi-v{api}/ic_lumo.xml').getroot()
            self.assertEqual(xml.tag,'adaptive-icon')
            self.assertIsNotNone(xml.find('background'))
            self.assertIsNotNone(xml.find('foreground'))
            self.assertEqual(xml.find('monochrome') is not None,api==33)

    def test_idempotence_and_source_not_modified(self):
        before = (self.root/icons.SOURCE).read_bytes()
        one = icons.prepare(self.root)
        manifest = self.manifest.read_bytes()
        two = icons.prepare(self.root)
        self.assertEqual(one,two)
        self.assertEqual(manifest,self.manifest.read_bytes())
        self.assertEqual(before,(self.root/icons.SOURCE).read_bytes())
        for entry in one['files']:
            data = (self.manifest.parent/'res'/entry['path']).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(),entry['sha256'])

    def test_wrong_source_fails_before_manifest_change(self):
        before = self.manifest.read_bytes()
        (self.root/icons.SOURCE).write_bytes(b'not-the-reviewed-source')
        with self.assertRaises(ValueError):
            icons.prepare(self.root)
        self.assertEqual(before,self.manifest.read_bytes())
        self.assertFalse((self.manifest.parent/'res').exists())

    def test_missing_application_fails_before_resources_created(self):
        self.manifest.write_text('<manifest/>')
        with self.assertRaises(ValueError):
            icons.prepare(self.root)
        self.assertFalse((self.manifest.parent/'res').exists())


if __name__ == '__main__':
    unittest.main()
