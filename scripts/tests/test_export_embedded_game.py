"""Generated Godot metadata must not poison a second managed export."""
import importlib.util
import hashlib
import json
import struct
from unittest.mock import patch
from pathlib import Path
import subprocess
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    'export_embedded_game',
    Path(__file__).resolve().parents[1] / 'export_embedded_game.py',
)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class GeneratedSidecarTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        for name in ('scene.gd', 'effect.gdshader', 'tracked.gd', 'tracked.gd.uid'):
            (self.repo / name).write_text('uid://alreadytracked\n' if name.endswith('.uid') else '# source\n')
        subprocess.run(['git', 'add', '.'], cwd=self.repo, check=True)

    def test_new_generated_sidecars_are_removed(self):
        for name in ('scene.gd.uid', 'effect.gdshader.uid'):
            (self.repo / name).write_text('uid://babc123\n')
        MODULE.remove_generated_sidecars(self.repo, set())
        self.assertFalse((self.repo / 'scene.gd.uid').exists())
        self.assertFalse((self.repo / 'effect.gdshader.uid').exists())
        self.assertTrue((self.repo / 'scene.gd').exists())
        # Running cleanup twice is harmless.
        MODULE.remove_generated_sidecars(self.repo, set())

    def test_preexisting_sidecar_is_preserved(self):
        path = self.repo / 'scene.gd.uid'
        path.write_text('uid://babc123\n')
        MODULE.remove_generated_sidecars(self.repo, {'scene.gd.uid'})
        self.assertTrue(path.exists())

    def test_tracked_sidecar_is_preserved(self):
        path = self.repo / 'tracked.gd.uid'
        path.write_text('uid://changed\n')
        MODULE.remove_generated_sidecars(self.repo, set())
        self.assertEqual(path.read_text(), 'uid://changed\n')

    def test_untracked_source_and_non_metadata_are_preserved(self):
        for name, content in (
            ('new.gd', '# developer work'),
            ('new.gd.uid', 'uid://babc123\n'),
            ('scene.gd.uid', 'developer notes, not generated metadata'),
            ('notes.txt', 'keep'),
        ):
            (self.repo / name).write_text(content)
        MODULE.remove_generated_sidecars(self.repo, set())
        for name in ('new.gd', 'new.gd.uid', 'scene.gd.uid', 'notes.txt'):
            self.assertTrue((self.repo / name).exists())

    def test_symlink_is_preserved(self):
        path = self.repo / 'scene.gd.uid'
        path.symlink_to(self.repo / 'tracked.gd.uid')
        MODULE.remove_generated_sidecars(self.repo, set())
        self.assertTrue(path.is_symlink())



class GeneratedMeshyGateTexturesTests(unittest.TestCase):
    """Regression for Godot extracting three in-GLB JPEGs beside the model."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        self.glb = self.repo / MODULE.GROUNDED_GATE_FILE
        self.glb.parent.mkdir(parents=True)
        content = json.dumps({
            'asset': {'version': '2.0'},
            'images': [
                {'name': name, 'mimeType': 'image/jpeg', 'bufferView': i}
                for i, name in enumerate(
                    ('LumoBaseColor', 'LumoMetallicRoughness', 'LumoNormal')
                )
            ],
        }).encode()
        padding = b' ' * ((-len(content)) % 4)
        chunk = content + padding
        self.glb.write_bytes(
            struct.pack('<4s4I', b'glTF', 2, 20 + len(chunk), len(chunk), 0x4e4f534a)
            + chunk
        )
        subprocess.run(['git', 'add', '.'], cwd=self.repo, check=True)
        self.source = {'revision': MODULE.GROUNDED_GATE_REVISION}
        self.files = sorted(MODULE.GROUNDED_GATE_GENERATED_IMAGES)
        self.digest = hashlib.sha256(self.glb.read_bytes()).hexdigest()

    def generate_images(self):
        for name in self.files:
            path = self.repo / name
            path.write_bytes(b'\xff\xd8\xff' + b'x' * 120 + b'\xff\xd9')

    def cleanup(self, before=None, source=None):
        with patch.object(MODULE, 'GROUNDED_GATE_GLB_SHA256', self.digest):
            MODULE.remove_generated_gate_images(
                self.repo,
                set() if before is None else before,
                self.source if source is None else source,
            )

    def test_exact_1975_imported_jpegs_are_cleaned(self):
        self.generate_images()
        self.cleanup()
        self.assertTrue(self.glb.is_file())
        for name in self.files:
            self.assertFalse((self.repo / name).exists())
        self.assertEqual(MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard'), set())

    def test_unknown_untracked_file_is_not_deleted(self):
        self.generate_images()
        outsider = self.glb.parent / 'lumo_kart_start_finish_gate_mobile_Hacked.jpg'
        outsider.write_bytes(b'\xff\xd8\xff' + b'x' * 120 + b'\xff\xd9')
        self.cleanup()
        self.assertTrue(outsider.exists())
        self.assertIn(
            str(outsider.relative_to(self.repo)),
            MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard'),
        )

    def test_exact_1976_same_trusted_glb_jpegs_are_cleaned(self):
        self.generate_images()
        self.assertIn("6518a13fb8eb30c81c8a2115d14791cbe7ddd24a", MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source={'revision': "6518a13fb8eb30c81c8a2115d14791cbe7ddd24a"})
        self.assertTrue(all(not (self.repo / name).exists() for name in self.files))
        self.assertTrue(self.glb.is_file())

    def test_1977_original_gate_images_are_safe_to_clean(self):
        self.generate_images()
        revision = "efa1f69b4128a047e6196ee85762447e412db266"
        self.cleanup(source={"revision": revision})
        self.assertTrue(all(not (self.repo / name).exists() for name in self.files))
        self.assertTrue(self.glb.is_file())

    def test_1979_cinema_source_only_cleans_hash_checked_gate_images(self):
        self.generate_images()
        source = {'revision': '20652880eda687c67cfa72301dad5a173b1fe6c5'}
        self.assertIn(source['revision'], MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source=source)
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / name).exists() for name in self.files))

    def test_1985_pinned_kart_preserves_gate_and_cleans_only_verified_images(self):
        self.generate_images()
        current = 'ffd2955ca9222daf02e6b602b3f213fd9383204a'
        self.assertIn(current, MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source={'revision': current})
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / path).exists() for path in self.files))
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())

    def test_1991_scene_quality_regression_pin_only_cleans_verified_gate_jpegs(self):
        # Native PR #108 adds only the scene-switch QA script and workflow hook.
        # The tracked gate GLB is byte-identical to the checksum-verified 1985 pin.
        self.generate_images()
        source = {'revision': '63cecf09fa89dd504cc468ebd121b4ec71a0f36c'}
        self.assertIn(source['revision'], MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source=source)
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / filename).exists() for filename in self.files))
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())

    def test_1993_cinematic_kart_only_cleans_original_digest_verified_gate_images(self):
        self.generate_images()
        source = {'revision': '8342a2f10b2ecb8cf9cf1cb9566093fbc4d0b07c'}
        self.assertIn(source['revision'], MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source=source)
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / filename).exists() for filename in self.files))
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())

    def test_1994_premium_kart_preserves_meshy_gate_hash_guard(self):
        self.generate_images()
        source = {'revision': '928fed3c7f0b39357e0f06463ce13c8d5677d6e1'}
        self.assertIn(source['revision'], MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source=source)
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / path).exists() for path in self.files))
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())

    def test_1995_sol_kart_keeps_immutable_gate_and_fails_closed(self):
        self.generate_images()
        source = {'revision': '700baf49828eda693ecce15b415847818b1b56d3'}
        self.assertIn(source['revision'], MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source=source)
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / name).exists() for name in self.files))
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())

    def test_1997_landing_fit_kart_keeps_immutable_gate(self):
        self.generate_images()
        source = {'revision': '3a3142608f6b150ee251373ba81e6face2eed4b3'}
        self.assertIn(source['revision'], MODULE.GROUNDED_GATE_ALLOWED_REVISIONS)
        self.cleanup(source=source)
        self.assertTrue(self.glb.is_file())
        self.assertTrue(all(not (self.repo / name).exists() for name in self.files))

    def test_future_unknown_pin_must_not_remove_images(self):
        self.generate_images()
        self.cleanup(source={'revision': '0' * 40})
        self.assertTrue(all((self.repo / name).exists() for name in self.files))

    def test_old_release_does_not_cleanup(self):
        self.generate_images()
        self.cleanup(source={'revision': '42b011dc23abffc24a5df2e13171fa5ada22d6eb'})
        self.assertTrue(all((self.repo / name).exists() for name in self.files))

    def test_existing_before_import_is_preserved(self):
        self.generate_images()
        self.cleanup(before={self.files[0]})
        self.assertTrue((self.repo / self.files[0]).exists())
        self.assertFalse((self.repo / self.files[1]).exists())

    def test_modified_glb_is_not_trusted(self):
        self.generate_images()
        with self.assertRaisesRegex(RuntimeError, 'hash mismatch'):
            MODULE.remove_generated_gate_images(self.repo, set(), self.source)
        self.assertTrue(all((self.repo / name).exists() for name in self.files))

    def test_non_jpeg_generated_output_fails_closed(self):
        self.generate_images()
        path = self.repo / self.files[0]
        path.write_bytes(b'not really a JPEG' * 10)
        with self.assertRaisesRegex(RuntimeError, 'non-JPEG'):
            self.cleanup()
        self.assertTrue(all((self.repo / name).exists() for name in self.files))

    def test_symlink_is_not_deleted(self):
        self.generate_images()
        path = self.repo / self.files[0]
        path.unlink()
        path.symlink_to(self.glb)
        with self.assertRaisesRegex(RuntimeError, 'unsafe output'):
            self.cleanup()
        self.assertTrue(path.is_symlink())



if __name__ == '__main__':
    unittest.main()
