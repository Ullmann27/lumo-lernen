"""Generated Godot metadata must not poison a second managed export."""
import importlib.util
import contextlib
import io
import os
import hashlib
import json
import struct
from unittest.mock import patch
from pathlib import Path
import subprocess
import signal
import sys
import tempfile
import textwrap
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

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

    def test_1999_visible_hub_fix_cleans_only_original_verified_images(self):
        self.generate_images()
        self.cleanup(source={'revision': '4d0fd40fdf188be6ca86057596c7b51f41701fa3'})
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



class GeneratedProductionMeshyImportsTests(unittest.TestCase):
    """Meshy import byproducts are cleaned only for reviewed immutable pins."""

    VEHICLES = (
        'blitz', 'boru_rally', 'comet', 'gecko_velo', 'glider', 'iva_aurora',
        'koloss', 'nala_comet', 'noa_tide', 'phantom', 'stella', 'terra',
        'turbo', 'zuri_volt',
    )
    GARAGE = ('meshy_tool_workbench', 'meshy_turntable')

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        self.rows = []
        for identifier in self.VEHICLES:
            self.rows.append(self._make_glb(
                identifier, f'assets/kart/production/meshy/{identifier}.glb'))
        garage_rows = []
        for identifier in self.GARAGE:
            garage_rows.append(self._make_glb(
                identifier, f'assets/kart/production/garage/{identifier}.glb'))
        manifest = {
            'schema_version': 1,
            'vehicles': self.rows,
            'garage': garage_rows,
            'runtime_policy': 'fixture',
        }
        manifest_path = self.repo / 'assets/kart/production/meshy/manifest.json'
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')
        subprocess.run(['git', 'add', '.'], cwd=self.repo, check=True)
        self.source = {'revision': MODULE.PRODUCTION_MESHY_REVISION}
        self.all_rows = self.rows + garage_rows

    def _make_glb(self, identifier, relative):
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        content = json.dumps({
            'asset': {'version': '2.0'},
            'images': [{'name': 'meshTexture', 'mimeType': 'image/png', 'bufferView': 0}],
            'bufferViews': [{'buffer': 0, 'byteLength': len(self._fixture_png())}],
        }).encode()
        padding = b' ' * ((-len(content)) % 4)
        chunk = content + padding
        texture = self._fixture_png()
        raw = (
            struct.pack('<4s4I', b'glTF', 2, 28 + len(chunk) + len(texture), len(chunk), 0x4e4f534a)
            + chunk + struct.pack('<2I', len(texture), 0x004e4942) + texture
        )
        path.write_bytes(raw)
        return {
            'id': identifier,
            'path': relative,
            'bytes': len(raw),
            'sha256': hashlib.sha256(raw).hexdigest(),
        }

    def generate_outputs(self):
        for row in self.all_rows:
            glb = self.repo / row['path']
            import_path = glb.with_suffix(glb.suffix + '.import')
            import_path.write_text(
                '[remap]\nimporter="scene"\ntype="PackedScene"\n\n[deps]\n'
                f'source_file="res://{row["path"]}"\n'
            )
            texture_path = glb.with_name(glb.stem + '_0.png')
            texture_path.write_bytes(self._fixture_png())

    @staticmethod
    def _fixture_png():
        return b'\x89PNG\r\n\x1a\n' + b'x' * 120 + b'IEND\xaeB\x60\x82'

    def cleanup(self, before=None, source=None):
        MODULE.remove_generated_production_meshy_imports(
            self.repo,
            set() if before is None else before,
            self.source if source is None else source,
        )

    def test_exact_2077_meshy_import_outputs_are_cleaned_and_sources_stay_tracked(self):
        self.generate_outputs()
        self.cleanup()
        self.assertEqual(
            MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard'),
            set(),
        )
        for row in self.all_rows:
            self.assertTrue((self.repo / row['path']).is_file())

    def test_current_2081_pin_cleans_outputs_and_preserves_exact_sources(self):
        source = {'revision': 'c814e35249e4038f903d1fca3e19bb4751040a43'}
        self.assertEqual(source['revision'], 'c814e35249e4038f903d1fca3e19bb4751040a43')
        tracked = MODULE.git_paths(self.repo, 'ls-files')
        original = {name: (self.repo / name).read_bytes() for name in tracked}
        self.generate_outputs()
        self.assertEqual(len(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard')), 32)
        self.cleanup(source=source)
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in tracked}, original)
        self.assertEqual(subprocess.check_output(
            ['git', 'diff', '--name-only'], cwd=self.repo, text=True), '')

    def test_current_2081_pin_still_rejects_changed_manifest_glb(self):
        source = {'revision': 'c814e35249e4038f903d1fca3e19bb4751040a43'}
        self.generate_outputs()
        outputs = MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard')
        original = {name: (self.repo / name).read_bytes() for name in outputs}
        target = self.repo / self.all_rows[0]['path']
        target.write_bytes(target.read_bytes() + b'tamper')
        with self.assertRaisesRegex(RuntimeError, 'manifest GLB mismatch'):
            self.cleanup(source=source)
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in outputs}, original)

    def test_2082_pin_cleans_outputs_and_preserves_exact_sources(self):
        source = {'revision': '62108c0355f860ab9a0a020ecb5f3f941f1032e9'}
        self.assertEqual(source['revision'], '62108c0355f860ab9a0a020ecb5f3f941f1032e9')
        tracked = MODULE.git_paths(self.repo, 'ls-files')
        original = {name: (self.repo / name).read_bytes() for name in tracked}
        self.generate_outputs()
        self.assertEqual(len(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard')), 32)
        self.cleanup(source=source)
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in tracked}, original)
        self.assertEqual(subprocess.check_output(
            ['git', 'diff', '--name-only'], cwd=self.repo, text=True), '')

    def test_2082_pin_still_rejects_changed_manifest_glb(self):
        source = {'revision': '62108c0355f860ab9a0a020ecb5f3f941f1032e9'}
        self.generate_outputs()
        outputs = MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard')
        original = {name: (self.repo / name).read_bytes() for name in outputs}
        target = self.repo / self.all_rows[0]['path']
        target.write_bytes(target.read_bytes() + b'tamper')
        with self.assertRaisesRegex(RuntimeError, 'manifest GLB mismatch'):
            self.cleanup(source=source)
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in outputs}, original)

    def test_2083_pin_cleans_outputs_and_preserves_exact_sources(self):
        source = {'revision': 'dedc588cd0862069fe22863f671877042aa7c53c'}
        self.assertEqual(source['revision'], 'dedc588cd0862069fe22863f671877042aa7c53c')
        tracked = MODULE.git_paths(self.repo, 'ls-files')
        original = {name: (self.repo / name).read_bytes() for name in tracked}
        self.generate_outputs()
        self.assertEqual(len(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard')), 32)
        self.cleanup(source=source)
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in tracked}, original)
        self.assertEqual(subprocess.check_output(
            ['git', 'diff', '--name-only'], cwd=self.repo, text=True), '')

    def test_2083_pin_still_rejects_changed_manifest_glb(self):
        source = {'revision': 'dedc588cd0862069fe22863f671877042aa7c53c'}
        self.generate_outputs()
        outputs = MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard')
        original = {name: (self.repo / name).read_bytes() for name in outputs}
        target = self.repo / self.all_rows[0]['path']
        target.write_bytes(target.read_bytes() + b'tamper')
        with self.assertRaisesRegex(RuntimeError, 'manifest GLB mismatch'):
            self.cleanup(source=source)
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in outputs}, original)

    def test_historical_release_pin_cleans_outputs_and_preserves_exact_sources(self):
        source = {'revision': '0c36dbaa2e778dc982550989159bf70efbf1d47c'}
        tracked = MODULE.git_paths(self.repo, 'ls-files')
        original = {name: (self.repo / name).read_bytes() for name in tracked}
        self.generate_outputs()
        self.assertEqual(len(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard')), 32)
        self.cleanup(source=source)
        self.assertEqual(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard'), set())
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in tracked}, original)
        self.assertEqual(subprocess.check_output(
            ['git', 'diff', '--name-only'], cwd=self.repo, text=True), '')

    def test_new_pin_cleans_only_preapproved_assets_and_fresh_outputs(self):
        locked_digest = hashlib.sha256((self.repo / MODULE.PRODUCTION_MESHY_MANIFEST).read_bytes()).hexdigest()
        self.generate_outputs()
        preexisting = Path(self.all_rows[0]['path'] + '.import')
        unknown = self.repo / 'other.png'
        unknown.write_bytes(self._fixture_png())
        with patch.object(MODULE, 'PRODUCTION_MESHY_MANIFEST_SHA256', locked_digest):
            self.cleanup(source={'revision': 'c' * 40}, before={str(preexisting)})
        self.assertEqual(MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard'),
                         {str(preexisting), 'other.png'})

    def test_new_pin_rejects_valid_png_that_does_not_match_the_embedded_bytes(self):
        locked_digest = hashlib.sha256((self.repo / MODULE.PRODUCTION_MESHY_MANIFEST).read_bytes()).hexdigest()
        self.generate_outputs()
        glb = self.repo / self.all_rows[0]['path']
        glb.with_name(glb.stem + '_0.png').write_bytes(self._fixture_png().replace(b'x', b'y'))
        with patch.object(MODULE, 'PRODUCTION_MESHY_MANIFEST_SHA256', locked_digest):
            with self.assertRaisesRegex(RuntimeError, 'extracted PNG differs from GLB'):
                self.cleanup(source={'revision': 'c' * 40})
        self.assertEqual(len(MODULE.git_paths(
            self.repo, 'ls-files', '--others', '--exclude-standard')), 32)

    def test_current_reviewed_pin_still_rejects_changed_manifest_glb(self):
        source = json.loads((MODULE.ROOT / 'config/godot-source.json').read_text())
        # The fixture contains tiny synthetic GLBs, not the production assets.
        # Approve only its original manifest digest for this test, then tamper
        # with a GLB. Exercise the current pin's real verification path.
        fixture_digest = hashlib.sha256(
            (self.repo / MODULE.PRODUCTION_MESHY_MANIFEST).read_bytes()).hexdigest()
        self.generate_outputs()
        outputs = MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard')
        original = {name: (self.repo / name).read_bytes() for name in outputs}
        target = self.repo / self.all_rows[0]['path']
        target.write_bytes(target.read_bytes() + b'tamper')
        with patch.object(MODULE, 'PRODUCTION_MESHY_MANIFEST_SHA256', fixture_digest):
            with self.assertRaisesRegex(RuntimeError, 'manifest GLB mismatch'):
                self.cleanup(source=source)
        self.assertEqual(
            {name: (self.repo / name).read_bytes() for name in outputs}, original)

    def test_unknown_untracked_file_is_preserved(self):
        self.generate_outputs()
        outsider = self.repo / 'assets/kart/production/meshy/notes.png'
        outsider.write_bytes(b'keep me')
        self.cleanup()
        self.assertTrue(outsider.is_file())

    def test_glb_alignment_padding_after_png_is_cleaned(self):
        self.generate_outputs()
        for row in self.all_rows:
            glb = self.repo / row['path']
            texture = glb.with_name(glb.stem + '_0.png')
            texture.write_bytes(texture.read_bytes() + b'\x00\x00\x00')
        self.cleanup()
        self.assertEqual(
            MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard'),
            set(),
        )

    def test_more_than_three_alignment_bytes_are_rejected(self):
        self.generate_outputs()
        first = self.all_rows[0]
        glb = self.repo / first['path']
        texture = glb.with_name(glb.stem + '_0.png')
        texture.write_bytes(texture.read_bytes() + b'\x00\x00\x00\x00')
        with self.assertRaisesRegex(RuntimeError, 'invalid PNG output'):
            self.cleanup()
        self.assertTrue(texture.is_file())

    def test_unreviewed_revision_preserves_every_meshy_import_output(self):
        self.generate_outputs()
        outputs = MODULE.git_paths(self.repo, 'ls-files', '--others', '--exclude-standard')
        original = {name: (self.repo / name).read_bytes() for name in outputs}
        self.assertEqual(len(outputs), 32)
        for revision in ('0' * 40, 'c3f459eca88f659da1a9e4af1c990c804e715529',
                         'c814e35249e4038f903d1fca3e19bb4751040a44'):
            with self.subTest(revision=revision):
                self.cleanup(source={'revision': revision})
                self.assertEqual(MODULE.git_paths(
                    self.repo, 'ls-files', '--others', '--exclude-standard'), outputs)
                self.assertEqual(
                    {name: (self.repo / name).read_bytes() for name in outputs}, original)

    def test_manifest_hash_mismatch_fails_closed_without_deleting_outputs(self):
        self.generate_outputs()
        target = self.repo / self.all_rows[0]['path']
        target.write_bytes(target.read_bytes() + b'tamper')
        with self.assertRaisesRegex(RuntimeError, 'manifest'):
            self.cleanup()
        self.assertTrue(target.with_suffix(target.suffix + '.import').is_file())
        self.assertTrue(target.with_name(target.stem + '_0.png').is_file())

    def test_preexisting_import_output_is_preserved(self):
        self.generate_outputs()
        first = self.all_rows[0]
        relative = first['path'] + '.import'
        self.cleanup(before={relative})
        self.assertTrue((self.repo / relative).is_file())



class ImportCrashRecoveryTests(unittest.TestCase):
    """A recoverable editor SIGSEGV never bypasses source/export checking."""

    def test_transient_editor_sigsegv_retries_exact_same_command(self):
        crashed = subprocess.CalledProcessError(-11, ['godot', '--import'])
        with patch.object(MODULE, 'run_godot', side_effect=[crashed, None]) as execute, \
             patch.object(MODULE.time, 'sleep') as sleep:
            MODULE.import_with_sigsegv_retry('godot', Path('/fixed/pinned/source'))
        self.assertEqual(execute.call_count, 2)
        self.assertEqual(execute.call_args_list[0].args, execute.call_args_list[1].args)
        self.assertNotEqual(execute.call_args_list[0].kwargs['log'],
                            execute.call_args_list[1].kwargs['log'])
        self.assertIn('--single-threaded-scene', execute.call_args.args)
        self.assertIn('--import', execute.call_args.args)
        sleep.assert_called_once_with(2)

    def test_other_import_failure_is_not_retried_or_silenced(self):
        invalid = subprocess.CalledProcessError(1, ['godot', '--import'])
        with patch.object(MODULE, 'run_godot', side_effect=invalid) as execute, \
             patch.object(MODULE.time, 'sleep') as sleep:
            with self.assertRaises(subprocess.CalledProcessError):
                MODULE.import_with_sigsegv_retry('godot', Path('/fixed/pinned/source'))
        execute.assert_called_once()
        sleep.assert_not_called()

    def test_persistent_segmentation_fault_still_blocks_release(self):
        crashed = subprocess.CalledProcessError(-11, ['godot', '--import'])
        with patch.object(MODULE, 'run_godot', side_effect=crashed) as execute, \
             patch.object(MODULE.time, 'sleep') as sleep:
            with self.assertRaises(subprocess.CalledProcessError):
                MODULE.import_with_sigsegv_retry('godot', Path('/fixed/pinned/source'))
        self.assertEqual(execute.call_count, 3)
        self.assertEqual(sleep.call_count, 2)
        self.assertEqual([entry.args for entry in sleep.call_args_list], [(2,), (4,)])

    def test_successful_editor_import_needs_no_retry(self):
        with patch.object(MODULE, 'run_godot', return_value=None) as execute, \
             patch.object(MODULE.time, 'sleep') as sleep:
            MODULE.import_with_sigsegv_retry('godot', Path('/fixed/pinned/source'))
        execute.assert_called_once()
        sleep.assert_not_called()



@unittest.skipUnless(os.name == 'posix', 'Native SIGSEGV is a POSIX process result')
class GuardedGodotProcessTests(unittest.TestCase):
    """Exercise real child processes, native signals, full logs and the watchdog."""

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.sequence = 0
        self.real_sleep = time.sleep

    def make_engine(self, body):
        self.sequence += 1
        self.case = self.directory / str(self.sequence)
        self.case.mkdir()
        self.repo = self.case / 'source'
        self.repo.mkdir()
        self.logs = self.case / 'logs'
        self.calls = self.case / 'calls'
        engine = self.case / 'fake-godot'
        engine.write_text(
            f'#!{sys.executable}\n'
            'import os, resource, signal, sys, time\n'
            'from pathlib import Path\n'
            'resource.setrlimit(resource.RLIMIT_CORE, (0, 0))\n'
            'calls = Path(__file__).with_name("calls")\n'
            'attempt = int(calls.read_text()) + 1 if calls.exists() else 1\n'
            'calls.write_text(str(attempt))\n'
            + textwrap.dedent(body)
        )
        engine.chmod(0o755)
        return str(engine)

    def import_engine(self, engine, timeout=5):
        # The four contract tests above verify the real 2/4-second backoff.
        # Keep the watchdog's polling sleeps, but omit only backoff in these tests.
        with contextlib.redirect_stdout(io.StringIO()), \
             patch.object(MODULE.time, 'sleep',
                          side_effect=lambda delay: self.real_sleep(delay)
                          if delay < 1 else None):
            MODULE.import_with_sigsegv_retry(
                engine, self.repo, log_dir=self.logs, timeout=timeout,
            )

    def assert_import_logs(self, count):
        self.assertEqual(
            sorted(path.name for path in self.logs.glob('*.txt')),
            [f'GODOT-package-import-{index}.txt' for index in range(1, count + 1)],
        )

    def test_two_native_crashes_then_success_keep_all_logs_and_existing_cache(self):
        engine = self.make_engine("""
            repo = Path(sys.argv[sys.argv.index('--path') + 1])
            cache = repo / '.godot' / 'imported' / 'partial-cache'
            if attempt == 1:
                cache.parent.mkdir(parents=True)
                cache.write_text('same checked source')
            else:
                assert cache.read_text() == 'same checked source'
            print(f'import attempt {attempt}', flush=True)
            print(f'stderr attempt {attempt}', file=sys.stderr, flush=True)
            if attempt < 3:
                os.kill(os.getpid(), signal.SIGSEGV)
            print('completed import', flush=True)
        """)
        self.import_engine(engine)
        self.assertEqual(self.calls.read_text(), '3')
        self.assert_import_logs(3)
        for index in (1, 2, 3):
            log = (self.logs / f'GODOT-package-import-{index}.txt').read_text()
            self.assertIn(f'import attempt {index}', log)
            self.assertIn(f'stderr attempt {index}', log)
        self.assertIn('completed import',
                      (self.logs / 'GODOT-package-import-3.txt').read_text())

    def test_three_native_crashes_fail_and_keep_every_attempt_log(self):
        engine = self.make_engine("""
            print(f'native crash {attempt}', flush=True)
            os.kill(os.getpid(), signal.SIGSEGV)
        """)
        with self.assertRaises(subprocess.CalledProcessError) as result:
            self.import_engine(engine)
        self.assertEqual(result.exception.returncode, -signal.SIGSEGV)
        self.assertEqual(self.calls.read_text(), '3')
        self.assert_import_logs(3)
        for index in (1, 2, 3):
            self.assertIn(f'native crash {index}',
                          (self.logs / f'GODOT-package-import-{index}.txt').read_text())

    def test_non_native_failure_is_not_retried(self):
        engine = self.make_engine("""
            print('invalid import', file=sys.stderr, flush=True)
            sys.exit(2)
        """)
        with self.assertRaises(subprocess.CalledProcessError) as result:
            self.import_engine(engine)
        self.assertEqual(result.exception.returncode, 2)
        self.assertEqual(self.calls.read_text(), '1')
        self.assert_import_logs(1)
        self.assertIn('invalid import',
                      (self.logs / 'GODOT-package-import-1.txt').read_text())

    def test_explicit_exit_139_is_not_mistaken_for_a_native_signal(self):
        engine = self.make_engine("sys.exit(139)\n")
        with self.assertRaises(subprocess.CalledProcessError) as result:
            self.import_engine(engine)
        self.assertEqual(result.exception.returncode, 139)
        self.assertEqual(self.calls.read_text(), '1')
        self.assert_import_logs(1)

    def test_runtime_faults_fail_even_when_the_engine_exits_zero(self):
        for fault in (
            'SCRIPT ERROR: Invalid access',
            'Parse Error: Expected expression',
            'Compile Error: Failed to compile',
            'ERROR: Condition "p_size <= 0" is true',
        ):
            with self.subTest(fault=fault):
                engine = self.make_engine(
                    f'print({fault!r}, file=sys.stderr, end="", flush=True)\n'
                )
                with self.assertRaisesRegex(RuntimeError, 'complete log'):
                    self.import_engine(engine)
                self.assertEqual(self.calls.read_text(), '1')
                self.assert_import_logs(1)
                self.assertEqual(
                    (self.logs / 'GODOT-package-import-1.txt').read_text(), fault,
                )

    def test_script_fault_followed_by_sigsegv_is_never_retried(self):
        engine = self.make_engine("""
            print('SCRIPT ERROR: Not a recoverable import', flush=True)
            os.kill(os.getpid(), signal.SIGSEGV)
        """)
        with self.assertRaisesRegex(RuntimeError, 'complete log'):
            self.import_engine(engine)
        self.assertEqual(self.calls.read_text(), '1')
        self.assert_import_logs(1)

    def test_watchdog_timeout_is_not_retried_and_preserves_output(self):
        engine = self.make_engine("""
            print('stalled importer', flush=True)
            time.sleep(30)
        """)
        with self.assertRaises(subprocess.TimeoutExpired):
            self.import_engine(engine, timeout=1)
        self.assertEqual(self.calls.read_text(), '1')
        self.assert_import_logs(1)
        self.assertIn('stalled importer',
                      (self.logs / 'GODOT-package-import-1.txt').read_text())

    def test_error_split_across_reads_in_a_long_line_still_fails(self):
        engine = self.make_engine("""
            print('ERROR: ' + 'x' * 12000, end='', flush=True)
            time.sleep(0.15)
            print('p_size <= 0', end='', flush=True)
        """)
        with self.assertRaisesRegex(RuntimeError, 'complete log'):
            self.import_engine(engine)
        self.assertEqual(self.calls.read_text(), '1')
        self.assert_import_logs(1)
        self.assertEqual(
            (self.logs / 'GODOT-package-import-1.txt').read_text(),
            'ERROR: ' + 'x' * 12000 + 'p_size <= 0',
        )

    def test_export_pack_native_crash_is_not_retried(self):
        engine = self.make_engine("""
            if '--version' in sys.argv:
                print('4.6.3.stable.official.test')
                sys.exit(0)
            phase = 'import' if '--import' in sys.argv else 'export'
            marker = Path(__file__).with_name(phase + '-calls')
            marker.write_text(str(int(marker.read_text()) + 1)
                              if marker.exists() else '1')
            print('running ' + phase, flush=True)
            if phase == 'export':
                os.kill(os.getpid(), signal.SIGSEGV)
        """)
        subprocess.run(['git', 'init', '-q', str(self.repo)], check=True)
        (self.repo / 'project.godot').write_text('config_version=5\n')
        subprocess.run(['git', 'add', '.'], cwd=self.repo, check=True)
        subprocess.run(
            ['git', '-c', 'user.name=Exporter Test',
             '-c', 'user.email=exporter@example.invalid',
             'commit', '-qm', 'Fixture source'],
            cwd=self.repo, check=True,
        )
        revision = subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=self.repo, text=True,
        ).strip()
        host = self.case / 'host'
        (host / 'config').mkdir(parents=True)
        (host / 'config/godot-source.json').write_text(json.dumps({
            'repository': 'https://example.invalid/not-used',
            'revision': revision, 'engine': '4.6.3',
        }))
        with patch.object(MODULE, 'ROOT', host), \
             contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(subprocess.CalledProcessError) as result:
                MODULE.export(self.repo, engine)
        self.assertEqual(result.exception.returncode, -signal.SIGSEGV)
        self.assertEqual((self.case / 'import-calls').read_text(), '1')
        self.assertEqual((self.case / 'export-calls').read_text(), '1')
        self.assertIn(
            'running export',
            (host / 'build-proof/GODOT-package-export.txt').read_text(),
        )
        self.assertEqual(subprocess.check_output(
            ['git', 'status', '--porcelain'], cwd=self.repo, text=True,
        ), '')


if __name__ == '__main__':
    unittest.main()

