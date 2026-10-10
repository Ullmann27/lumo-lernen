"""Generated Godot metadata must not poison a second managed export."""
import importlib.util
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


if __name__ == '__main__':
    unittest.main()
