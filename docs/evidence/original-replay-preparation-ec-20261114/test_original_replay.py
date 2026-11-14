from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
import warnings
import zipfile

import original_replay as reader


class ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.archive = self.root / "original.zip"
        self.output = self.root / "unpacked"

    def tearDown(self):
        self.temporary.cleanup()

    def make(self, members):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(self.archive, "x", compression=zipfile.ZIP_STORED) as archive:
                for name, value in members:
                    archive.writestr(name, value)
        return self.metadata()

    def metadata(self):
        data = self.archive.read_bytes()
        return {"size_in_bytes": len(data), "digest": "sha256:" + hashlib.sha256(data).hexdigest()}

    def rejected(self, members):
        metadata = self.make(members)
        with self.assertRaises((ValueError, zipfile.BadZipFile)):
            reader.unpack_verified(self.archive, self.output, metadata)
        self.assertFalse(self.output.exists())

    def test_valid_original_bytes_and_all_members_are_preserved(self):
        metadata = self.make([("reports/", b""), ("reports/facts.json", b'{"actual":true}\n'),
                              ("pixels.png", b"fixture bytes, no visual assertion")])
        original = self.archive.read_bytes()
        result = reader.unpack_verified(self.archive, self.output, metadata)
        self.assertEqual(result["member_count"], 3)
        self.assertEqual(len(result["files"]), 2)
        self.assertEqual((self.output / "reports/facts.json").read_bytes(), b'{"actual":true}\n')
        self.assertEqual(self.archive.read_bytes(), original)
        self.assertEqual(result["archive"]["sha256"], metadata["digest"].removeprefix("sha256:"))
        self.assertEqual(set(reader.file_inventory(self.output)), {"reports/facts.json", "pixels.png"})

    def test_wrong_api_digest_is_rejected_before_extracting(self):
        metadata = self.make([("a", b"data")])
        metadata["digest"] = "sha256:" + "0" * 64
        with self.assertRaises(ValueError):
            reader.unpack_verified(self.archive, self.output, metadata)
        self.assertFalse(self.output.exists())

    def test_wrong_api_size_is_rejected_before_extracting(self):
        metadata = self.make([("a", b"data")])
        metadata["size_in_bytes"] += 1
        with self.assertRaises(ValueError):
            reader.unpack_verified(self.archive, self.output, metadata)
        self.assertFalse(self.output.exists())

    def test_boolean_cannot_replace_api_byte_count(self):
        metadata = self.make([("a", b"data")])
        metadata["size_in_bytes"] = True
        with self.assertRaises(ValueError):
            reader.unpack_verified(self.archive, self.output, metadata)
        self.assertFalse(self.output.exists())

    def test_traversal_path_is_rejected(self):
        self.rejected([("../outside", b"data")])

    def test_absolute_path_is_rejected(self):
        self.rejected([("/outside", b"data")])

    def test_backslash_path_is_rejected(self):
        self.rejected([("folder\\outside", b"data")])

    def test_drive_path_is_rejected(self):
        self.rejected([("C:/outside", b"data")])

    def test_noncanonical_dot_and_separator_paths_are_rejected(self):
        for name in (".", "a/./b", "a//b"):
            with self.subTest(name=name):
                self.rejected([(name, b"data")])
                self.archive.unlink()

    def test_duplicate_paths_are_rejected(self):
        self.rejected([("same", b"one"), ("same", b"two")])

    def test_file_directory_parent_collision_is_rejected(self):
        self.rejected([("parent", b"file"), ("parent/child", b"child")])

    def test_symlink_member_is_rejected(self):
        link = zipfile.ZipInfo("linked")
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        self.rejected([(link, b"../../outside")])

    def test_directory_payload_is_rejected(self):
        self.rejected([("folder/", b"hidden payload")])

    def test_existing_extraction_is_not_overwritten(self):
        metadata = self.make([("a", b"new")])
        self.output.mkdir()
        (self.output / "kept").write_bytes(b"original")
        with self.assertRaises(ValueError):
            reader.unpack_verified(self.archive, self.output, metadata)
        self.assertEqual((self.output / "kept").read_bytes(), b"original")
        self.assertFalse((self.output / "a").exists())

    def test_corrupt_member_crc_rejected_even_with_matching_archive_api_hash(self):
        self.make([("payload.txt", b"immutable original")])
        with zipfile.ZipFile(self.archive) as archive:
            member = archive.getinfo("payload.txt")
            offset = member.header_offset + 30 + len(member.filename.encode()) + len(member.extra)
        payload = bytearray(self.archive.read_bytes())
        payload[offset] ^= 1
        self.archive.write_bytes(payload)
        with self.assertRaises((ValueError, zipfile.BadZipFile)):
            reader.unpack_verified(self.archive, self.output, self.metadata())
        self.assertFalse(self.output.exists())

    def test_inventory_detects_changed_added_and_removed_originals(self):
        metadata = self.make([("a", b"original")])
        reader.unpack_verified(self.archive, self.output, metadata)
        original = reader.file_inventory(self.output)
        (self.output / "a").write_bytes(b"changed")
        self.assertNotEqual(reader.file_inventory(self.output), original)
        (self.output / "a").write_bytes(b"original")
        (self.output / "extra").write_bytes(b"new")
        self.assertNotEqual(reader.file_inventory(self.output), original)
        (self.output / "extra").unlink()
        (self.output / "a").unlink()
        self.assertNotEqual(reader.file_inventory(self.output), original)


class SourceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / "proof.txt").write_bytes(b"committed original\n")
        subprocess.run(["git", "-C", str(self.root), "add", "--", "proof.txt"], check=True)
        subprocess.run(["git", "-C", str(self.root), "-c", "user.name=Lumo reader fixture",
                        "-c", "user.email=fixture@invalid", "commit", "-qm", "fixture"], check=True)
        self.head = reader.git_output(self.root, "rev-parse", "HEAD").decode().strip()
        self.tree = reader.git_output(self.root, "rev-parse", "HEAD^{tree}").decode().strip()

    def tearDown(self):
        self.temporary.cleanup()

    def test_clean_materialized_source_and_index_are_unchanged(self):
        before = reader.source_snapshot(self.root, self.head, self.tree)
        after = reader.source_snapshot(self.root, self.head, self.tree)
        self.assertEqual(before, after)
        self.assertEqual(len(before["files"]), 1)
        self.assertEqual(before["files"][0]["path"], "proof.txt")

    def test_foreign_head_is_rejected(self):
        with self.assertRaises(ValueError):
            reader.source_snapshot(self.root, "0" * 40, self.tree)

    def test_foreign_tree_is_rejected(self):
        with self.assertRaises(ValueError):
            reader.source_snapshot(self.root, self.head, "0" * 40)

    def test_changed_source_bytes_are_rejected(self):
        (self.root / "proof.txt").write_bytes(b"changed source\n")
        with self.assertRaises((ValueError, subprocess.CalledProcessError)):
            reader.source_snapshot(self.root, self.head, self.tree)

    def test_staged_changed_source_is_rejected(self):
        (self.root / "proof.txt").write_bytes(b"staged change\n")
        subprocess.run(["git", "-C", str(self.root), "add", "--", "proof.txt"], check=True)
        with self.assertRaises((ValueError, subprocess.CalledProcessError)):
            reader.source_snapshot(self.root, self.head, self.tree)

    def test_changed_executable_mode_is_rejected(self):
        (self.root / "proof.txt").chmod(0o755)
        with self.assertRaises((ValueError, subprocess.CalledProcessError)):
            reader.source_snapshot(self.root, self.head, self.tree)


class JsonTests(unittest.TestCase):
    def test_duplicate_keys_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "facts.json"
            path.write_text('{"status":"PASS","status":"FAIL"}')
            with self.assertRaises(ValueError):
                reader.read(path)

    def test_nonfinite_number_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "facts.json"
            path.write_text('{"size":NaN}')
            with self.assertRaises(ValueError):
                reader.read(path)


if __name__ == "__main__":
    os.environ["GIT_OPTIONAL_LOCKS"] = "0"
    os.environ["PYTHONDONTWRITEBYTECODE"] = "1"
    unittest.main(verbosity=2)
