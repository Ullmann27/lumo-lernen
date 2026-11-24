"""Source and actual APK identity failures must block the driver package proof."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_kart_driver_package import (DRIVERS, DRIVER_MANIFEST, LOD_FILES,
                                        extract_verified_pack, source_inventory)


class DriverSourceInventoryTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.drivers = []
        for identifier in sorted(DRIVERS):
            lods = []
            for level, name in LOD_FILES.items():
                relative = f'assets/kart/production/drivers/{identifier}/{name}'
                path = self.root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                raw = f'identity fixture for {identifier} {level}'.encode()
                path.write_bytes(raw)
                lods.append({'level': level, 'file': relative, 'bytes': len(raw),
                             'sha256': hashlib.sha256(raw).hexdigest()})
            self.drivers.append({'id': identifier, 'lods': lods,
                                 'bones': ['Root', 'Pelvis', 'Spine', 'Chest', 'Neck', 'Head', 'Tail',
                                           'UpperArm.L', 'Forearm.L', 'Hand.L', 'Thigh.L', 'Shin.L', 'Foot.L', 'Ear.L',
                                           'UpperArm.R', 'Forearm.R', 'Hand.R', 'Thigh.R', 'Shin.R', 'Foot.R', 'Ear.R',
                                           'Jaw', 'Eye.L', 'Eye.R', 'Lid.L', 'Lid.R'],
                                 'animations': {clip: {} for clip in (
                                     'idle', 'kart_seated', 'kart_steer_left', 'kart_steer_right',
                                     'kart_jump', 'celebrate', 'kart_celebrate', 'kart_hit',
                                     'greeting_wave', 'agree_nod', 'point_portal', 'card_play')}})
        self.write_manifest()

    def write_manifest(self):
        (self.root / DRIVER_MANIFEST).write_text(json.dumps({'drivers': self.drivers}))

    def test_all_twenty_seven_source_bytes_are_bound_to_the_manifest(self):
        report = source_inventory(self.root)
        self.assertEqual(len(report['source_files']), 27)
        self.assertEqual({row['driver'] for row in report['source_files']}, DRIVERS)
        self.assertEqual(report['source_manifest_sha256'],
                         hashlib.sha256((self.root / DRIVER_MANIFEST).read_bytes()).hexdigest())

    def test_missing_driver_never_passes_as_a_complete_package(self):
        self.drivers.pop()
        self.write_manifest()
        with self.assertRaisesRegex(RuntimeError, 'all nine'):
            source_inventory(self.root)

    def test_duplicated_driver_never_replaces_a_missing_one(self):
        self.drivers[-1] = self.drivers[0]
        self.write_manifest()
        with self.assertRaisesRegex(RuntimeError, 'duplicate'):
            source_inventory(self.root)

    def test_missing_lod_is_rejected(self):
        self.drivers[0]['lods'].pop()
        self.write_manifest()
        with self.assertRaisesRegex(RuntimeError, 'three distinct'):
            source_inventory(self.root)

    def test_art_only_path_cannot_stand_in_for_the_runtime_asset(self):
        self.drivers[0]['lods'][0]['file'] = 'art/driver.glb'
        self.write_manifest()
        with self.assertRaisesRegex(RuntimeError, 'production asset path'):
            source_inventory(self.root)

    def test_changed_source_bytes_are_rejected(self):
        path = self.root / self.drivers[0]['lods'][0]['file']
        path.write_bytes(path.read_bytes() + b'changed')
        with self.assertRaisesRegex(RuntimeError, 'actual source GLB differs'):
            source_inventory(self.root)

    def test_symlink_cannot_redirect_an_approved_source_file(self):
        path = self.root / self.drivers[0]['lods'][0]['file']
        replacement = self.root / 'redirected.glb'
        path.rename(replacement)
        path.symlink_to(replacement)
        with self.assertRaisesRegex(RuntimeError, 'redirected'):
            source_inventory(self.root)


class ActualApkPackIdentityTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.apk = self.root / 'candidate.apk'
        self.output = self.root / 'actual.pck'
        self.raw_pack = b'pack identity fixture; actual scenes are checked by Godot'
        self.source = {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                       'revision': 'a' * 40, 'engine': '4.6.3'}
        self.receipt = {**self.source, 'bytes': len(self.raw_pack),
                        'pck_sha256': hashlib.sha256(self.raw_pack).hexdigest()}

    def write_apk(self, *, duplicate=False):
        with warnings.catch_warnings():
            warnings.simplefilter('ignore', UserWarning)
            with zipfile.ZipFile(self.apk, 'w') as archive:
                archive.writestr('assets/lumo_game.pck', self.raw_pack)
                archive.writestr('assets/lumo_game_source.json', json.dumps(self.receipt))
                if duplicate:
                    archive.writestr('assets/lumo_game_source.json', json.dumps(self.receipt))

    def test_receipt_binds_the_extracted_bytes_to_the_exact_source(self):
        self.write_apk()
        self.assertEqual(extract_verified_pack(self.apk, self.output, self.source), self.receipt)
        self.assertEqual(self.output.read_bytes(), self.raw_pack)

    def test_a_stale_apk_cannot_verify_a_new_source(self):
        self.receipt['revision'] = 'b' * 40
        self.write_apk()
        with self.assertRaisesRegex(RuntimeError, 'source identity differs'):
            extract_verified_pack(self.apk, self.output, self.source)

    def test_a_mismatching_pack_is_rejected(self):
        self.receipt['pck_sha256'] = '0' * 64
        self.write_apk()
        with self.assertRaisesRegex(RuntimeError, 'Actual APK PCK differs'):
            extract_verified_pack(self.apk, self.output, self.source)

    def test_duplicate_source_receipts_are_rejected(self):
        self.write_apk(duplicate=True)
        with self.assertRaisesRegex(RuntimeError, 'duplicate'):
            extract_verified_pack(self.apk, self.output, self.source)


if __name__ == '__main__':
    unittest.main()
