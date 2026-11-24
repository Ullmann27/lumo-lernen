"""Exercise the real lossless exporter and its additional workflow uploads.

These are filesystem/transport fixtures, not Android or gameplay evidence.
"""
from __future__ import annotations

import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/export_creative_evidence_parts.py"
SPEC = importlib.util.spec_from_file_location("creative_evidence_parts", SCRIPT)
EXPORT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(EXPORT)
BINDING = {"repository": "Ullmann27/lumo-lernen",
           "workflow_path": ".github/workflows/lumo-kart-graphics-2019.yml",
           "source_sha": "a" * 40, "run_id": 123456, "run_attempt": 1}


class CreativeEvidencePartsTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.source = self.base / "creative"
        self.source.mkdir()
        self.output = self.base / "parts"

    def write_files(self, files, source=None):
        source = source or self.source
        for name, data in files.items():
            path = source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)

    def export(self, **overrides):
        return EXPORT.export_parts(overrides.pop("source", self.source),
                                   overrides.pop("output", self.output),
                                   **{**BINDING, **overrides})

    def test_real_cli_roundtrip_covers_every_original_byte_and_hidden_path(self):
        originals = {".hidden/state.json": b'{"observed":true}\n',
                     "empty.log": b"", "nested/clip.mp4": bytes(range(90)),
                     "nested/frame.png": bytes(range(128)),
                     "export-index.json": b"original manifest is not overwritten",
                     "notes/Gr\u00f6\u00dfe.txt": b"full original text\n"}
        self.write_files(originals)
        github_output = self.base / "github-output"
        command = [sys.executable, "-B", str(SCRIPT), "--source", str(self.source),
                   "--output", str(self.output), "--repository", BINDING["repository"],
                   "--workflow-path", BINDING["workflow_path"], "--source-sha", BINDING["source_sha"],
                   "--run-id", "123456", "--run-attempt", "1", "--max-part-bytes", "160",
                   "--github-output", str(github_output)]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=20)
        self.assertEqual(completed.returncode, 0, completed.stderr)
        summary = json.loads(completed.stdout)
        self.assertGreater(summary["part_count"], 1)
        reference = None
        recovered = {}
        for part in sorted(self.output.iterdir()):
            index_bytes = (part / "export-index.json").read_bytes()
            reference = index_bytes if reference is None else reference
            self.assertEqual(index_bytes, reference)
            self.assertLessEqual(len(index_bytes), EXPORT.MAX_INDEX_BYTES)
            index = json.loads(index_bytes)
            binding = dict(BINDING)
            binding["host_source_sha"] = binding.pop("source_sha")
            self.assertEqual(index["binding"], binding)
            manifest_bytes = (part / "part.json").read_bytes()
            self.assertLessEqual(len(manifest_bytes), EXPORT.MAX_PART_MANIFEST_BYTES)
            manifest = json.loads(manifest_bytes)
            self.assertEqual(manifest["index_sha256"], hashlib.sha256(index_bytes).hexdigest())
            self.assertLessEqual(manifest["payload_bytes"], 160)
            # Reconstruct from independently zipped part directories, preserving
            # hidden paths. This is a local byte roundtrip, not an Actions upload.
            archive = io.BytesIO()
            with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_STORED) as zipped:
                for file in sorted(part.rglob("*")):
                    if file.is_file():
                        zipped.write(file, file.relative_to(part).as_posix())
            with zipfile.ZipFile(io.BytesIO(archive.getvalue())) as zipped:
                expected = [item for item in index["files"] if item["part"] == manifest["part"]]
                self.assertEqual(set(zipped.namelist()), {"export-index.json", "part.json"} |
                                 {"originals/" + item["path"] for item in expected})
                for item in expected:
                    data = zipped.read("originals/" + item["path"])
                    self.assertNotIn(item["path"], recovered)
                    self.assertEqual(len(data), item["bytes"])
                    self.assertEqual(hashlib.sha256(data).hexdigest(), item["sha256"])
                    recovered[item["path"]] = data
        self.assertEqual(recovered, originals)
        self.assertEqual({name: (self.source / name).read_bytes() for name in originals}, originals)
        outputs = dict(line.split("=", 1) for line in github_output.read_text().splitlines())
        self.assertEqual(outputs["index_sha256"], summary["index_sha256"])
        for number in range(1, 9):
            self.assertEqual(outputs[f"part_{number:02d}"],
                             "true" if number <= summary["part_count"] else "false")

    def test_diagnostic_index_names_the_probe_source_without_claiming_an_apk_source(self):
        self.write_files({"qa-metadata/run.json": b'{"synthetic":true}\n',
                          "tour/failed-before-input.txt": b"No Android acceptance.\n"})
        result = self.export(workflow_path=EXPORT.DIAGNOSTIC_WORKFLOW)
        index_path = self.output / "part-01/export-index.json"
        index = json.loads(index_path.read_bytes())
        self.assertEqual(index["schema"], 2)
        self.assertEqual(index["binding"]["probe_source_sha"], BINDING["source_sha"])
        self.assertNotIn("host_source_sha", index["binding"])
        self.assertEqual(index["binding"]["workflow_path"], EXPORT.DIAGNOSTIC_WORKFLOW)
        self.assertEqual(index["binding"]["run_id"], BINDING["run_id"])
        self.assertEqual(result["index_sha256"], hashlib.sha256(index_path.read_bytes()).hexdigest())

    def test_identical_inputs_produce_identical_parts_and_are_independent_copies(self):
        self.write_files({"a.txt": b"1234", "nested/b.txt": b"5678"})
        first = self.export(max_part_bytes=5)
        second_path = self.base / "second-parts"
        second = self.export(output=second_path, max_part_bytes=5)
        self.assertEqual(first["index_sha256"], second["index_sha256"])
        first_files = {str(p.relative_to(self.output)): p.read_bytes()
                       for p in self.output.rglob("*") if p.is_file()}
        second_files = {str(p.relative_to(second_path)): p.read_bytes()
                        for p in second_path.rglob("*") if p.is_file()}
        self.assertEqual(first_files, second_files)
        (self.source / "a.txt").write_bytes(b"later log write")
        self.assertEqual((self.output / "part-01/originals/a.txt").read_bytes(), b"1234")

    def test_exact_payload_boundary_and_zero_byte_file_are_not_dropped(self):
        self.write_files({"a": b"12345678", "b-empty": b"", "c": b"abcdefgh"})
        result = self.export(max_part_bytes=8)
        self.assertEqual(result["part_count"], 2)
        index = json.loads((self.output / "part-01/export-index.json").read_bytes())
        self.assertEqual([(x["file_count"], x["payload_bytes"]) for x in index["parts"]], [(2, 8), (1, 8)])

    def test_eight_parts_succeed_and_ninth_fails_without_published_output(self):
        self.write_files({str(i): b"x" for i in range(8)})
        self.assertEqual(self.export(max_part_bytes=1)["part_count"], 8)
        (self.source / "8").write_bytes(b"x")
        other = self.base / "too-many"
        with self.assertRaisesRegex(ValueError, "more than 8 parts"):
            self.export(output=other, max_part_bytes=1)
        self.assertFalse(other.exists())
        self.assertFalse(list(self.base.glob(".too-many-*")))

    def test_single_oversized_file_fails_without_partial_output_or_success_outputs(self):
        self.write_files({"frame.png": b"12345"})
        marker = self.base / "github-output"
        marker.write_text("previous=kept\n")
        command = [sys.executable, "-B", str(SCRIPT), "--source", str(self.source),
                   "--output", str(self.output), "--repository", BINDING["repository"],
                   "--workflow-path", BINDING["workflow_path"], "--source-sha", BINDING["source_sha"],
                   "--run-id", "123456", "--run-attempt", "1", "--max-part-bytes", "4",
                   "--github-output", str(marker)]
        result = subprocess.run(command, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 1)
        self.assertIn("Single file exceeds", result.stderr)
        self.assertNotIn("READY", result.stdout)
        self.assertFalse(self.output.exists())
        self.assertEqual(marker.read_text(), "previous=kept\n")

    def test_production_size_limit_cannot_be_raised_or_disabled(self):
        self.write_files({"a": b"x"})
        for value in (0, -1, EXPORT.DEFAULT_PART_BYTES + 1, True):
            with self.subTest(limit=value), self.assertRaisesRegex(ValueError, "Part byte limit"):
                self.export(max_part_bytes=value)
        self.assertFalse(self.output.exists())

    def test_existing_output_and_inside_source_output_are_rejected(self):
        self.write_files({"a": b"original"})
        self.output.mkdir()
        (self.output / "keep").write_bytes(b"untouched")
        with self.assertRaisesRegex(ValueError, "already exists"):
            self.export()
        self.assertEqual((self.output / "keep").read_bytes(), b"untouched")
        with self.assertRaisesRegex(ValueError, "outside"):
            self.export(output=self.source / "parts")
        self.assertFalse((self.source / "parts").exists())

    def test_symlink_file_directory_root_and_output_parent_are_rejected(self):
        self.write_files({"a": b"x"})
        for target in (self.source / "a", self.base):
            link = self.source / "link"
            link.symlink_to(target)
            with self.subTest(target=str(target)), self.assertRaisesRegex(ValueError, "Symlink"):
                self.export()
            link.unlink()
        source_link = self.base / "source-link"
        source_link.symlink_to(self.source)
        with self.assertRaisesRegex(ValueError, "Symlink"):
            self.export(source=source_link)
        parent_link = self.base / "parent-link"
        parent_link.symlink_to(self.base)
        with self.assertRaisesRegex(ValueError, "Symlink"):
            self.export(output=parent_link / "out")
        self.assertFalse(self.output.exists())

    def test_special_files_and_empty_sources_fail_closed(self):
        with self.assertRaisesRegex(ValueError, "No regular"):
            self.export()
        os.mkfifo(self.source / "pipe")
        with self.assertRaisesRegex(ValueError, "non-regular"):
            self.export()
        self.assertFalse(self.output.exists())

    def test_source_rewrite_addition_and_removal_during_real_copy_are_detected(self):
        read = EXPORT._read_verified
        for change in ("rewrite", "add", "remove"):
            with self.subTest(change=change):
                source = self.base / change
                source.mkdir()
                self.write_files({"a": b"abcd", "b": b"efgh"}, source)
                output = self.base / (change + "-parts")
                mutated = False

                def changing(path, expected, target=None):
                    nonlocal mutated
                    digest = read(path, expected, target)
                    if target is not None and not mutated:
                        mutated = True
                        if change == "rewrite":
                            old = (source / "a").stat()
                            (source / "a").write_bytes(b"WXYZ")
                            os.utime(source / "a", ns=(old.st_atime_ns, old.st_mtime_ns))
                        elif change == "add":
                            (source / "new-hidden-proof").write_bytes(b"new")
                        else:
                            (source / "b").unlink()
                    return digest

                with mock.patch.object(EXPORT, "_read_verified", side_effect=changing):
                    with self.assertRaises((ValueError, OSError)):
                        self.export(source=source, output=output)
                self.assertTrue(mutated)
                self.assertFalse(output.exists())
                self.assertFalse(list(self.base.glob(f".{output.name}-*")))

    def test_corrupted_export_copy_is_rejected_without_mutating_originals(self):
        self.write_files({"proof.json": b"original"})
        read = EXPORT._read_verified

        def corrupting(path, expected, target=None):
            digest = read(path, expected, target)
            if target is not None:
                target.write_bytes(b"tampered")
            return digest

        with mock.patch.object(EXPORT, "_read_verified", side_effect=corrupting):
            with self.assertRaisesRegex(ValueError, "Exported bytes differ"):
                self.export()
        self.assertFalse(self.output.exists())
        self.assertFalse(list(self.base.glob(".parts-*")))
        self.assertEqual((self.source / "proof.json").read_bytes(), b"original")

    def test_global_index_size_limit_is_enforced_on_real_long_paths(self):
        nested = self.source
        for number in range(16):
            nested /= str(number) + "x" * 198
        nested.mkdir(parents=True)
        for number in range(1400):
            (nested / f"{number:04d}").write_bytes(b"")
        with self.assertRaisesRegex(ValueError, "manifest exceeds"):
            self.export()
        self.assertFalse(self.output.exists())

    def test_file_count_and_source_run_binding_are_mandatory(self):
        with self.assertRaisesRegex(ValueError, "between 1 and"):
            EXPORT.plan_parts({str(i): 0 for i in range(EXPORT.MAX_FILES + 1)}, 1)
        self.write_files({"a": b"x"})
        for change in ({"repository": "missing-owner"}, {"source_sha": "abc"},
                       {"workflow_path": ".github/workflows/unrelated.yml"},
                       {"run_id": 0}, {"run_attempt": 0}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.export(**change)
        self.assertFalse(self.output.exists())


class CreativeEvidenceWorkflowTests(unittest.TestCase):
    def test_additional_parts_follow_the_unchanged_complete_upload_in_each_workflow(self):
        for workflow in EXPORT.WORKFLOWS:
            with self.subTest(workflow=workflow):
                prefix = Path(workflow).stem
                text = (ROOT / workflow).read_text()
                creative = re.search(r"^  creative-android:\n(.*?)(?=^  [a-z][\w-]*:\n|\Z)",
                                     text, re.M | re.S)[1]
                original = ("      - name: Preserve actual creative Android evidence on success or failure\n"
                            "        if: always()\n"
                            "        uses: actions/upload-artifact@v4\n"
                            "        with:\n"
                            f"          name: {prefix}-creative-android\n"
                            "          path: creative/\n"
                            "          if-no-files-found: error\n"
                            "          retention-days: 30\n"
                            "          compression-level: 6\n")
                self.assertEqual(creative.count(original), 1)
                name = "      - name: Export complete creative evidence into bounded additional parts\n"
                self.assertGreater(creative.index(name), creative.index(original))
                preparation = creative.split(name, 1)[1].split("\n      - name:", 1)[0]
                self.assertIn("id: creative-parts\n        if: always()", preparation)
                self.assertIn('test "$(git rev-parse HEAD)" = "$SOURCE_SHA"', preparation)
                command = preparation.split("python3 -B ", 1)[1].replace("\\\n", " ")
                args = shlex.split(command)
                self.assertEqual(args[0], "scripts/export_creative_evidence_parts.py")
                for flag, value in (("--source", "creative"),
                                    ("--output", "$RUNNER_TEMP/lumo-creative-evidence-parts"),
                                    ("--repository", "$GITHUB_REPOSITORY"),
                                    ("--workflow-path", workflow), ("--source-sha", "$SOURCE_SHA"),
                                    ("--run-id", "$GITHUB_RUN_ID"),
                                    ("--run-attempt", "$GITHUB_RUN_ATTEMPT"),
                                    ("--github-output", "$GITHUB_OUTPUT")):
                    self.assertEqual(args.count(flag), 1)
                    self.assertEqual(args[args.index(flag) + 1], value)
                self.assertNotIn("--max-part-bytes", args)
                self.assertNotIn("continue-on-error", creative)
                self.assertEqual(creative.count("uses: actions/upload-artifact@v4"), 9)
                self.assertEqual(creative.count("include-hidden-files: true"), 8)
                for number in range(1, 9):
                    part = f"{number:02d}"
                    block = creative.split(f"      - name: Preserve complete creative evidence part {part}\n", 1)[1]
                    block = block.split("\n      - name:", 1)[0]
                    self.assertIn("if: always() && steps.creative-parts.outcome == 'success' && "
                                  f"steps.creative-parts.outputs.part_{part} == 'true'", block)
                    self.assertIn(f"name: {prefix}-creative-part-{part}", block)
                    self.assertIn("path: ${{ runner.temp }}/lumo-creative-evidence-parts/part-" + part + "/", block)
                    for setting in ("include-hidden-files: true", "if-no-files-found: error",
                                    "compression-level: 0", "retention-days: 30"):
                        self.assertIn(setting, block)


if __name__ == "__main__":
    unittest.main()
