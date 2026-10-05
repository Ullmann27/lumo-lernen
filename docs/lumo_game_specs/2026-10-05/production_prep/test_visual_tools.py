import hashlib
import json
import struct
import tempfile
import unittest
import zipfile
from pathlib import Path
from PIL import Image
import visual_tools as v


class VisualToolsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        Image.new('RGB', (30, 20), '#2080c0').save(self.root/'ref.png')
        Image.new('RGB', (10, 40), '#e09020').save(self.root/'run.png')

    def manifest(self, **changes):
        row = dict(path='ref.png', **v.image_info(self.root/'ref.png'))
        row.update(changes)
        path = self.root/'manifest.json'
        path.write_text(json.dumps({'files':[row]}),encoding='utf-8')
        return path

    def glb(self, doc=None, suffix=b''):
        if doc is None: doc={'asset':{'version':'2.0'}}
        data=json.dumps(doc).encode(); data+=b' '*((-len(data))%4)
        body=struct.pack('<II',len(data),0x4e4f534a)+data+suffix
        p=self.root/'model.glb'; p.write_bytes(struct.pack('<4sII',b'glTF',2,len(body)+12)+body)
        return p

    def compare(self, **kw):
        return v.comparison(self.root/'ref.png',self.root/'run.png',self.root/'pair','a'*40,kw.get('kind','widget_test'))

    def test_hash(self):
        p=self.root/'hello.txt'; p.write_bytes(b'hello')
        self.assertEqual(v.sha256(p),hashlib.sha256(b'hello').hexdigest())
    def test_contained(self): self.assertEqual(v.contained(self.root,'ref.png'),self.root/'ref.png')
    def test_traversal(self):
        for name in ('../x','/tmp/a','a\\b','C:a',''):
            with self.subTest(name=name), self.assertRaises(ValueError): v.contained(self.root,name)
    def test_missing(self):
        with self.assertRaises(ValueError): v.contained(self.root,'missing.png')
    def test_symlink_escape(self):
        outside=self.root.parent/'forbidden_lumo_test.txt'; outside.write_text('x')
        self.addCleanup(outside.unlink)
        (self.root/'link').symlink_to(outside)
        with self.assertRaises(ValueError): v.contained(self.root,'link')
    def test_rgb_opaque(self): self.assertFalse(v.image_info(self.root/'ref.png')['has_transparent_pixels'])
    def test_rgba_opaque(self):
        p=self.root/'a.png'; Image.new('RGBA',(5,5),(0,0,0,255)).save(p)
        self.assertFalse(v.image_info(p)['has_transparent_pixels'])
    def test_rgba_alpha(self):
        p=self.root/'a.png'; im=Image.new('RGBA',(5,5),(0,0,0,255));im.putpixel((0,0),(0,0,0,0));im.save(p)
        self.assertTrue(v.image_info(p)['has_transparent_pixels'])
    def test_corrupt_image(self):
        p=self.root/'bad.png';p.write_bytes(b'not png')
        with self.assertRaises(OSError):v.image_info(p)
    def test_manifest_pass(self):self.assertEqual(v.verify(self.root,self.manifest())['status'],'PASS')
    def test_manifest_bad_hash(self):self.assertEqual(v.verify(self.root,self.manifest(sha256='0'*64))['status'],'FAIL')
    def test_manifest_bad_dimensions(self):self.assertEqual(v.verify(self.root,self.manifest(width=99))['status'],'FAIL')
    def test_manifest_false_alpha(self):self.assertEqual(v.verify(self.root,self.manifest(has_transparent_pixels=True))['status'],'FAIL')
    def test_manifest_bad_hash_syntax(self):
        with self.assertRaises(ValueError):v.verify(self.root,self.manifest(sha256='fake'))
    def test_manifest_empty(self):
        p=self.root/'empty.json';p.write_text('{"files":[]}')
        with self.assertRaises(ValueError):v.verify(self.root,p)
    def test_manifest_duplicate(self):
        p=self.manifest();d=json.loads(p.read_text());d['files']*=2;p.write_text(json.dumps(d))
        with self.assertRaises(ValueError):v.verify(self.root,p)
    def test_compare_keeps_aspect(self):
        r=self.compare();self.assertFalse(r['cropped']);self.assertEqual(r['runtime']['width'],10)
        with Image.open(self.root/'pair/comparison.png') as im:
            self.assertEqual(im.size,(1600,700))
    def test_compare_no_pass_claim(self):
        r=self.compare();self.assertEqual(r['verdict'],'NOT_ASSESSED')
        self.assertEqual(r['physical_device_performance'],'NOT_EXECUTED')
    def test_compare_identical_flag(self):
        r=v.comparison(self.root/'ref.png',self.root/'ref.png',self.root/'pair','b'*40,'desktop')
        self.assertTrue(r['same_input_bytes']);self.assertEqual(r['verdict'],'NOT_ASSESSED')
    def test_compare_needs_full_sha(self):
        with self.assertRaises(ValueError):v.comparison(self.root/'ref.png',self.root/'run.png',self.root/'pair','abc','android')
    def test_compare_kind(self):
        with self.assertRaises(ValueError):self.compare(kind='generated_mockup')
    def test_compare_no_overwrite(self):
        self.compare()
        with self.assertRaises(FileExistsError):self.compare()
    def test_glb_minimal_not_rig_pass(self):
        r=v.glb_inventory(self.glb());self.assertEqual(r['skins'],0);self.assertEqual(r['rig_fidelity'],'NOT_ASSESSED')
    def test_glb_inventory(self):
        r=v.glb_inventory(self.glb({'asset':{'version':'2.0'},'skins':[{'joints':[0,1]}],'animations':[{'name':'walk'}]}))
        self.assertEqual(r['skin_joint_counts'],[2]);self.assertEqual(r['animation_names'],['walk'])
    def test_glb_magic(self):
        p=self.glb();d=p.read_bytes();p.write_bytes(b'fail'+d[4:])
        with self.assertRaises(ValueError):v.glb_inventory(p)
    def test_glb_total_length(self):
        p=self.glb();p.write_bytes(p.read_bytes()+b'xxxx')
        with self.assertRaises(ValueError):v.glb_inventory(p)
    def test_glb_json_version(self):
        with self.assertRaises(ValueError):v.glb_inventory(self.glb({'asset':{'version':'1.0'}}))
    def test_glb_duplicate_json(self):
        p=self.glb(suffix=struct.pack('<II',4,0x4e4f534a)+b'{}  ')
        with self.assertRaises(ValueError):v.glb_inventory(p)
    def test_glb_bad_chunk(self):
        p=self.glb(suffix=struct.pack('<II',100,0x004e4942)+b'1234')
        with self.assertRaises(ValueError):v.glb_inventory(p)
    def test_pack_bounds_members(self):
        for name in ('a','b','c'):(self.root/name).write_bytes(b'k'*300)
        packs=v.pack(self.root,['a','b','c'],self.root/'packs',500)
        self.assertEqual(len(packs),3)
        for pack in packs:
            self.assertLessEqual(pack['bytes'],500)
            with zipfile.ZipFile(self.root/'packs'/pack['name']) as z:self.assertIsNone(z.testzip())
    def test_pack_unicode(self):
        (self.root/'Übung.txt').write_bytes(b'x'*100)
        packs=v.pack(self.root,['Übung.txt'],self.root/'packs',250)
        self.assertLessEqual(packs[0]['bytes'],250)
        with zipfile.ZipFile(self.root/'packs'/packs[0]['name']) as z:self.assertEqual(z.read('Übung.txt'),b'x'*100)
    def test_pack_oversize(self):
        (self.root/'big').write_bytes(b'x'*1000)
        with self.assertRaises(ValueError):v.pack(self.root,['big'],self.root/'packs',500)
        self.assertFalse((self.root/'packs').exists())
    def test_pack_duplicate(self):
        with self.assertRaises(ValueError):v.pack(self.root,['ref.png','ref.png'],self.root/'packs')
    def test_pack_no_overwrite(self):
        v.pack(self.root,['ref.png'],self.root/'packs')
        with self.assertRaises(FileExistsError):v.pack(self.root,['ref.png'],self.root/'packs')


if __name__=='__main__':unittest.main(verbosity=2)
