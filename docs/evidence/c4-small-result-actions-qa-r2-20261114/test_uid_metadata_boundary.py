"""Execute the actual QA runner's UID boundary against isolated Git fixtures.

These are metadata-contract tests, not Godot or game-runtime observations.
"""
from __future__ import annotations

import hashlib
import importlib.util
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


RUNNER = Path(os.environ["LUMO_QA_RUNNER"])
SPEC = importlib.util.spec_from_file_location("actual_small_result_qa_runner", RUNNER)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
PATHS = ("scripts", "scenes", "assets", "project.godot")


class UidMetadataBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-uid-boundary-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.script = self.root / "scripts/example.gd"
        self.shader = self.root / "assets/example.gdshader"
        self.script.parent.mkdir()
        self.shader.parent.mkdir()
        self.script.write_text("extends RefCounted\n")
        self.shader.write_text("shader_type canvas_item;\n")
        self.git("init", "--quiet")
        self.git("config", "user.name", "Synthetic metadata fixture")
        self.git("config", "user.email", "metadata-fixture@example.invalid")
        self.git("add", "scripts", "assets")
        self.git("commit", "--quiet", "-m", "Exact source fixture, no runtime")
        self.script_uid = Path(str(self.script) + ".uid")
        self.shader_uid = Path(str(self.shader) + ".uid")
        self.script_uid.write_bytes(b"uid://beky6sltfwvka\n")
        self.shader_uid.write_bytes(b"uid://bfvf32yjeur48\n")

    def git(self, *arguments):
        return subprocess.check_output(
            ["git", "-C", str(self.root), *arguments], stderr=subprocess.STDOUT, text=True
        ).strip()

    def snapshot(self):
        return {"generated_native_uid_metadata": MODULE.native_untracked_metadata(self.root, PATHS, set())}

    def test_regular_sidecars_bind_both_exact_tracked_source_blobs(self):
        rows = self.snapshot()["generated_native_uid_metadata"]
        self.assertEqual({row["path"] for row in rows},
                         {"scripts/example.gd.uid", "assets/example.gdshader.uid"})
        for row in rows:
            self.assertEqual(row["source_git_blob"], self.git("rev-parse", "HEAD:" + row["source"]))
            self.assertEqual(row["sha256"], hashlib.sha256((self.root / row["path"]).read_bytes()).hexdigest())
        MODULE.require_unchanged_sources(self.snapshot(), self.snapshot())

    def test_untracked_executable_still_rejected(self):
        (self.root / "scripts/extra.gd").write_text("extends Node\n")
        with self.assertRaisesRegex(ValueError, "Unexpected untracked executable/input source"):
            self.snapshot()

    def test_malformed_or_noncanonical_uid_rejected(self):
        for raw in (b"uid://b\npayload\n", b"uid://b", b"uid://z\n",
                    b"uid://9\n", b"uid://ab\n", b"uid://8888888888888\n"):
            with self.subTest(raw=raw):
                self.script_uid.write_bytes(raw)
                with self.assertRaises(ValueError):
                    self.snapshot()

    def test_missing_or_untracked_source_cannot_authorize_uid(self):
        for create_untracked_source in (False, True):
            with self.subTest(untracked_source=create_untracked_source):
                source = self.root / "scripts/a_orphan.gd"
                if create_untracked_source:
                    source.write_text("extends Node\n")
                Path(str(source) + ".uid").write_bytes(b"uid://b\n")
                with self.assertRaises(ValueError):
                    self.snapshot()

    def test_changed_tracked_source_cannot_authorize_uid(self):
        self.script.write_text("extends Node\n")
        with self.assertRaisesRegex(ValueError, "counterpart differs from its committed blob"):
            self.snapshot()

    def test_symlink_sidecar_rejected_even_with_valid_target_bytes(self):
        self.script_uid.unlink()
        self.script_uid.symlink_to(self.shader_uid)
        with self.assertRaisesRegex(ValueError, "Nonregular evidence/source"):
            self.snapshot()

    def test_other_uid_suffix_does_not_allow_new_input(self):
        (self.root / "assets/example.txt.uid").write_bytes(b"uid://b\n")
        with self.assertRaisesRegex(ValueError, "Unexpected untracked executable/input source"):
            self.snapshot()

    def test_changed_or_removed_uid_fails_actual_after_snapshot_check(self):
        before = self.snapshot()
        self.script_uid.write_bytes(b"uid://b\n")
        with self.assertRaisesRegex(ValueError, "UID metadata identity changed"):
            MODULE.require_unchanged_sources(before, self.snapshot())
        self.script_uid.unlink()
        with self.assertRaisesRegex(ValueError, "UID metadata identity changed"):
            MODULE.require_unchanged_sources(before, self.snapshot())

    def test_already_tracked_uid_is_not_reinterpreted_as_generated_metadata(self):
        self.script_uid.write_text("uid://existing-readable-legacy-source-label\n")
        self.git("add", "scripts/example.gd.uid")
        self.git("commit", "--quiet", "-m", "Tracked historical fixture metadata")
        rows = self.snapshot()["generated_native_uid_metadata"]
        self.assertEqual([row["path"] for row in rows], ["assets/example.gdshader.uid"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
