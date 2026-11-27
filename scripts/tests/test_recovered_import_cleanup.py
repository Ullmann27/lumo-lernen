"""Strict fixture tests for post-export cleanup of the recovered native assets."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
from unittest.mock import patch

from scripts import lumo_recovered_import_cleanup as cleanup

PNG = b'\x89PNG\r\n\x1a\n' + b'x' * 120 + b'IEND\xaeB\x60\x82'
META = b'[remap]\n\nimporter="scene"\ntype="PackedScene"\npath="res://scene.scn"\n\n[params]\nmeshes/ensure_tangents=true\n'


def identity(raw):
    return len(raw), hashlib.sha256(raw).hexdigest()


def glb(png):
    doc = {'asset': {'version': '2.0'}, 'buffers': [{'byteLength': len(png)}],
           'images': [{'mimeType': 'image/png', 'bufferView': 0}],
           'bufferViews': [{'buffer': 0, 'byteLength': len(png)}]}
    chunk = json.dumps(doc).encode()
    chunk += b' ' * (-len(chunk) % 4)
    binary = png + b'\0' * (-len(png) % 4)
    return (struct.pack('<4sII', b'glTF', 2, 28 + len(chunk) + len(binary))
            + struct.pack('<I4s', len(chunk), b'JSON') + chunk
            + struct.pack('<I4s', len(binary), b'BIN\0') + binary)


class RecoveredImportTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.repo = Path(folder.name)
        subprocess.run(['git', 'init', '-q'], cwd=self.repo, check=True)
        self.models = {name: identity(glb(PNG)) for name in cleanup.WORLD_MODELS}
        self.outputs = []
        for name in self.models:
            path = self.repo / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(glb(PNG))
            self.outputs.append(path.with_name(path.stem + '_0.png'))
        actor = self.repo / cleanup.ACTOR
        actor.parent.mkdir(parents=True, exist_ok=True)
        actor.write_bytes(b'fixture actor')
        self.metadata = self.repo / (cleanup.ACTOR + '.import')
        self.metadata.write_bytes(META)
        subprocess.run(['git', 'add', '.'], cwd=self.repo, check=True)
        subprocess.run(['git', '-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                        'commit', '-qm', 'fixture'], cwd=self.repo, check=True)
        self.changed_meta = META.replace(b'type="PackedScene"\n', b'type="PackedScene"\nuid="uid://babc123"\n')
        self.metadata.write_bytes(self.changed_meta)
        for output in self.outputs:
            output.write_bytes(PNG)
        self.source = {'revision': cleanup.NATIVE_REVISION}
        self.addCleanup(patch.stopall)
        patch.object(cleanup, 'WORLD_MODELS', self.models).start()
        patch.object(cleanup, 'ACTOR_IDENTITY', identity(b'fixture actor')).start()

    def run_cleanup(self, before=None, source=None):
        cleanup.cleanup_recovered_imports(self.repo, before or set(), source or self.source)

    def test_verified_cleanup_restores_exact_tree(self):
        self.run_cleanup()
        self.assertEqual(self.metadata.read_bytes(), META)
        self.assertFalse(any(path.exists() for path in self.outputs))
        self.assertEqual(subprocess.check_output(['git', 'status', '--porcelain'], cwd=self.repo), b'')
        self.run_cleanup()

    def test_padding_only_is_permitted(self):
        self.outputs[0].write_bytes(PNG + b'\0\0\0')
        self.run_cleanup()
        self.assertFalse(self.outputs[0].exists())

    def test_invalid_second_texture_preserves_all_files(self):
        self.outputs[1].write_bytes(PNG.replace(b'x', b'y'))
        with self.assertRaisesRegex(RuntimeError, 'differs'):
            self.run_cleanup()
        self.assertTrue(all(path.exists() for path in self.outputs))
        self.assertEqual(self.metadata.read_bytes(), self.changed_meta)

    def test_tampered_glb_is_rejected(self):
        path = self.repo / next(iter(self.models))
        path.write_bytes(path.read_bytes() + b'tampered')
        with self.assertRaisesRegex(RuntimeError, 'identity mismatch'):
            self.run_cleanup()
        self.assertTrue(all(path.exists() for path in self.outputs))

    def test_material_change_is_not_mistaken_for_uid(self):
        self.metadata.write_bytes(self.changed_meta.replace(b'tangents=true', b'tangents=false'))
        with self.assertRaisesRegex(RuntimeError, 'only generated UID'):
            self.run_cleanup()
        self.assertTrue(all(path.exists() for path in self.outputs))

    def test_unknown_pin_and_existing_outputs_are_preserved(self):
        self.run_cleanup(source={'revision': '0' * 40})
        self.assertTrue(all(path.exists() for path in self.outputs))
        outsider = self.repo / 'other.png'
        outsider.write_bytes(b'untouched')
        self.run_cleanup(before={str(self.outputs[0].relative_to(self.repo))})
        self.assertTrue(self.outputs[0].exists())
        self.assertFalse(self.outputs[1].exists())
        self.assertEqual(outsider.read_bytes(), b'untouched')

    def test_symlink_output_is_rejected(self):
        self.outputs[0].unlink()
        self.outputs[0].symlink_to(self.outputs[1])
        with self.assertRaisesRegex(RuntimeError, 'Unsafe'):
            self.run_cleanup()
        self.assertTrue(self.outputs[0].is_symlink())
        self.assertTrue(self.outputs[1].exists())


if __name__ == '__main__':
    unittest.main()
