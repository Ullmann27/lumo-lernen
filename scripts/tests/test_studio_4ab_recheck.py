"""Synthetic identity counterexamples; no APK build, emulator or Android PASS.

Temporary Git repositories exercise real tree/worktree/mode checks. Tiny ZIPs
exercise the binary binder with explicitly injected synthetic expectations only.
The production CLI has no argument for overriding the immutable 4ab identities.
"""
from __future__ import annotations

import argparse
from dataclasses import replace
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


SCRIPT = Path(__file__).resolve().parents[1] / "recheck_studio_4ab.py"
SPEC = importlib.util.spec_from_file_location("studio_4ab_recheck_under_test", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


def put(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(value, bytes):
        path.write_bytes(value)
    elif isinstance(value, str):
        path.write_text(value)
    else:
        path.write_text(json.dumps(value))


def command(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   stderr=subprocess.PIPE, text=True).strip()


def configure(root: Path) -> None:
    command(root, "config", "user.name", "Synthetic binding test")
    command(root, "config", "user.email", "synthetic-test@example.invalid")


class GitBindingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-4ab-binding-")
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name) / "base"
        base.mkdir()
        command(base, "init", "-q")
        configure(base)
        for name in MODULE.TOURS:
            put(base / name, "# unchanged original CLI fixture\n")
        put(base / ".github/probes/creative_android_probe.py", "# original helper\n")
        put(base / "lib/product.dart", "void main() {}\n")
        put(base / "config/godot-source.json", {"revision": MODULE.EXPECTED.native})
        put(base / "pubspec.yaml", "version: 0.13.7+2019\n")
        command(base, "add", ".")
        command(base, "commit", "-qm", "Synthetic immutable product")
        self.expected = replace(MODULE.EXPECTED, host=command(base, "rev-parse", "HEAD"),
                                original_surfaces_sha256=MODULE.sha256(base / MODULE.SURFACES_PATH))
        self.qa = Path(self.temp.name) / "qa"
        subprocess.run(["git", "clone", "-q", "--no-hardlinks", str(base), str(self.qa)], check=True)
        configure(self.qa)
        for name in MODULE.OCR_FILES | MODULE.BINDER_FILES:
            put(self.qa / name, ("# reviewed QA-only fixture " + name + "\n").encode())
            command(self.qa, "add", "--", name)
        command(self.qa, "commit", "-qm", "Synthetic original nine-path QA basis")
        for name in MODULE.CARDS_FILES:
            put(self.qa / name, ("# reviewed Cards-only fixture " + name + "\n").encode())
            command(self.qa, "add", "--", name)
        command(self.qa, "commit", "-qm", "Synthetic reviewed sixteen-path 3e08 basis")
        self.expected = replace(self.expected,
                                qa_basis=command(self.qa, "rev-parse", "HEAD"),
                                basis_helper_sha256=MODULE.sha256(self.qa / MODULE.HELPER_PATH),
                                basis_surfaces_sha256=MODULE.sha256(self.qa / MODULE.SURFACES_PATH))
        for name in MODULE.RETURN_FILES | {MODULE.HELPER_PATH, MODULE.SURFACES_PATH}:
            put(self.qa / name, ("# reviewed return-only fixture " + name + "\n").encode())
            command(self.qa, "add", "--", name)
        self.expected = replace(self.expected,
                                approved_helper_sha256=MODULE.sha256(self.qa / MODULE.HELPER_PATH),
                                approved_surfaces_sha256=MODULE.sha256(self.qa / MODULE.SURFACES_PATH),
                                approved_return_files=tuple((name, MODULE.sha256(self.qa / name))
                                                            for name in sorted(MODULE.RETURN_FILES)))
        command(self.qa, "commit", "-qm", "Synthetic exact twenty-six-path QA delta")
        self.qa_head = command(self.qa, "rev-parse", "HEAD")
        self.product = self.qa / "candidate-source"
        subprocess.run(["git", "clone", "-q", "--no-hardlinks", str(base), str(self.product)], check=True)
        self.runtime = (self.product, self.qa / "tour", self.qa / "candidate/dist")

    def verify(self):
        return MODULE.verify_sources(self.qa, self.product, self.qa_head, self.runtime, self.expected)

    def test_exact_twenty_six_file_delta_and_real_worktree_pass(self):
        result = self.verify()
        self.assertEqual(len(result["reviewed_delta"]), 26)
        self.assertEqual(result["product"]["head"], self.expected.host)
        self.assertEqual(result["qa"]["head"], self.qa_head)
        self.assertTrue(result["qa"]["tracked_source_clean"])
        self.assertEqual(result["unchanged_other_git_entries"], 4)
        self.assertEqual(result["qa_basis"], self.expected.qa_basis)
        self.assertEqual(result["surface_reader_binding"]["original_sha256"],
                         self.expected.original_surfaces_sha256)
        self.assertEqual(result["surface_reader_binding"]["approved_sha256"],
                         self.expected.approved_surfaces_sha256)

    def test_committed_reviewed_paths_cannot_authorize_wrong_source_or_fixture_bytes(self):
        # Even clean commits on explicitly allowed paths must have reviewed bytes.
        cases = [(MODULE.SURFACES_PATH, "exact approved read-only correction"),
                 (MODULE.HELPER_PATH, "exact approved loading-frame correction"),
                 ("tools/android_qa/tests/test_flutter_loading_frame_rejection.py",
                  "exact reviewed bytes"),
                 ("tools/android_qa/tests/fixtures/flutter_loading_frame_3e08/android37-loading.png",
                  "exact reviewed bytes")]
        for name, message in cases:
            with self.subTest(path=name):
                original = (self.qa / name).read_bytes()
                put(self.qa / name, b"# unrelated clean committed modification\n")
                command(self.qa, "add", "--", name)
                command(self.qa, "commit", "-qm", "Tampered explicitly allowed source path")
                self.qa_head = command(self.qa, "rev-parse", "HEAD")
                with self.assertRaisesRegex(RuntimeError, message):
                    self.verify()
                put(self.qa / name, original)
                command(self.qa, "add", "--", name)
                command(self.qa, "commit", "-qm", "Restore reviewed bytes for next counterexample")
                self.qa_head = command(self.qa, "rev-parse", "HEAD")

    def test_product_change_outside_allowlist_is_rejected(self):
        put(self.qa / "lib/product.dart", "void main() { throw 1; }\n")
        command(self.qa, "add", "lib/product.dart")
        command(self.qa, "commit", "-qm", "Unreviewed product mutation")
        self.qa_head = command(self.qa, "rev-parse", "HEAD")
        with self.assertRaisesRegex(RuntimeError, "unexpected=.*lib/product.dart"):
            self.verify()

    def test_committed_mode_change_is_not_a_qa_exception(self):
        path = self.qa / "lib/product.dart"
        path.chmod(0o755)
        command(self.qa, "add", "lib/product.dart")
        command(self.qa, "commit", "-qm", "Unreviewed mode mutation")
        self.qa_head = command(self.qa, "rev-parse", "HEAD")
        with self.assertRaisesRegex(RuntimeError, "QA delta"):
            self.verify()

    def test_assume_unchanged_cannot_hide_actual_dirty_source(self):
        path = self.qa / "lib/product.dart"
        command(self.qa, "update-index", "--assume-unchanged", "lib/product.dart")
        put(path, "void main() { return; }\n")
        self.assertEqual(command(self.qa, "status", "--porcelain", "--untracked-files=no"), "")
        with self.assertRaisesRegex(RuntimeError, "Actual tracked source bytes changed"):
            self.verify()

    def test_wrong_candidate_head_and_undeclared_source_are_rejected(self):
        with self.assertRaisesRegex(RuntimeError, "Actual source HEAD"):
            MODULE.verify_sources(self.qa, self.product, self.qa_head, self.runtime,
                                  replace(self.expected, host="1" * 40))
        put(self.qa / ".github/probes/unreviewed.py", "raise SystemExit(0)\n")
        with self.assertRaisesRegex(RuntimeError, "Untracked source"):
            self.verify()

    def test_output_growth_does_not_change_bound_source_identity(self):
        before = self.verify()
        put(self.qa / "tour" / "actual-frame.json", {"scope": "synthetic output"})
        after = self.verify()
        self.assertEqual(before, after)
        put(self.product / "untracked.py", "# forbidden product-source addition\n")
        with self.assertRaisesRegex(RuntimeError, "Untracked source"):
            self.verify()


class MetadataAndBinaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-4ab-binary-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.expected = MODULE.EXPECTED
        self.metadata = self.root / "metadata"
        self.artifact = {"id": self.expected.artifact, "name": "lumo-studio-2019-candidate",
                         "size_in_bytes": self.expected.artifact_bytes,
                         "digest": "sha256:" + self.expected.artifact_sha256, "expired": False,
                         "workflow_run": {"id": self.expected.run, "head_sha": self.expected.host}}
        self.run = {"id": self.expected.run, "run_attempt": 1, "head_sha": self.expected.host,
                    "repository": {"full_name": "Ullmann27/lumo-lernen"},
                    "path": ".github/workflows/lumo-studio-2019.yml", "conclusion": "failure"}
        self.job = {"id": self.expected.build_job, "run_id": self.expected.run, "run_attempt": 1,
                    "head_sha": self.expected.host, "name": "verify-and-build",
                    "status": "completed", "conclusion": "success", "steps": [
                        {"name": name, "status": "completed", "conclusion": "success"}
                        for name in MODULE.BUILD_STEPS]}
        self.write_metadata()

    def write_metadata(self):
        for name, value in [("artifact.json", self.artifact), ("run.json", self.run), ("build-job.json", self.job)]:
            put(self.metadata / name, value)

    def build_binary(self, pck=None, native=None):
        pck = pck if pck is not None else b"GDPC" + b"\x00" * 16 + b"synthetic pack, not playable"
        native = native or {"revision": self.expected.native, "engine": "4.6.3",
                            "pck_sha256": hashlib.sha256(pck).hexdigest(), "bytes": len(pck)}
        self.apk = self.root / "candidate.apk"
        with zipfile.ZipFile(self.apk, "w") as z:
            z.writestr("assets/lumo_game.pck", pck)
            z.writestr("assets/lumo_game_source.json", json.dumps(native))
        self.binary_expected = replace(self.expected, apk_bytes=self.apk.stat().st_size,
                                       apk_sha256=MODULE.sha256(self.apk), pck_bytes=native["bytes"],
                                       pck_sha256=native["pck_sha256"])
        self.provenance = self.root / "provenance.json"
        self.sums = self.root / "sums.txt"
        self.proof = {"package": self.expected.package, "versionName": "0.13.7", "versionCode": 2019,
                      "flutter_source_commit": self.expected.host, "tracked_source_clean": True,
                      "abis": ["x86_64"], "bytes": self.binary_expected.apk_bytes,
                      "sha256": self.binary_expected.apk_sha256,
                      "signingCertificateSha256": self.expected.certificate, "godot": native}
        put(self.provenance, self.proof)
        put(self.sums, self.binary_expected.apk_sha256 + "  dist/x86_64/Lumo-Lernen-Neu.apk\n")

    def verify_binary(self):
        return MODULE.verify_apk(self.apk, self.provenance, self.sums, self.binary_expected)

    def test_failed_later_original_gates_do_not_disguise_successful_builder(self):
        result = MODULE.verify_metadata(self.metadata)
        self.assertEqual(result["original_run_conclusion"], "failure")
        self.assertEqual(result["original_build_job"], 132247240154)

    def test_foreign_artifact_run_attempt_and_failed_build_are_rejected(self):
        cases = [(self.artifact, "id", 14061222588),
                 (self.artifact, "digest", "sha256:" + "0" * 64),
                 (self.run, "head_sha", "0" * 40), (self.run, "run_attempt", True),
                 (self.job, "run_id", 1), (self.job, "conclusion", "failure")]
        for obj, key, value in cases:
            with self.subTest(key=key, value=value):
                previous = obj[key]
                obj[key] = value
                self.write_metadata()
                with self.assertRaises(RuntimeError):
                    MODULE.verify_metadata(self.metadata)
                obj[key] = previous
        self.job["steps"][0]["conclusion"] = "failure"
        self.write_metadata()
        with self.assertRaisesRegex(RuntimeError, "build step"):
            MODULE.verify_metadata(self.metadata)

    def test_real_small_zip_bytes_are_measured_and_later_tampering_fails(self):
        self.build_binary()
        result = self.verify_binary()
        self.assertEqual(result["pck_sha256"], self.binary_expected.pck_sha256)
        with self.apk.open("ab") as stream:
            stream.write(b"changed after preflight")
        with self.assertRaisesRegex(RuntimeError, "Actual APK bytes"):
            self.verify_binary()

    def test_changed_pck_rejected_even_with_new_matching_outer_apk_digest(self):
        self.build_binary()
        native = self.proof["godot"]
        self.build_binary(b"GDPC" + b"\x00" * 16 + b"different synthetic pack", native)
        with self.assertRaisesRegex(RuntimeError, "Actual embedded PCK"):
            self.verify_binary()

    def test_foreign_provenance_signature_and_duplicate_sums_are_rejected(self):
        self.build_binary()
        for key, value in [("flutter_source_commit", "0" * 40), ("tracked_source_clean", 1),
                           ("signingCertificateSha256", "0" * 64), ("abis", ["arm64-v8a"])]:
            with self.subTest(key=key):
                original = self.proof[key]
                self.proof[key] = value
                put(self.provenance, self.proof)
                with self.assertRaisesRegex(RuntimeError, "provenance"):
                    self.verify_binary()
                self.proof[key] = original
        put(self.provenance, self.proof)
        put(self.sums, self.sums.read_text() * 2)
        with self.assertRaisesRegex(RuntimeError, "checksum"):
            self.verify_binary()


class ExecutionBoundaryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-4ab-orchestration-")
        self.addCleanup(self.temp.cleanup)
        qa = Path(self.temp.name)
        self.args = argparse.Namespace(qa_source=qa, candidate_source=qa / "candidate-source",
                                      metadata_dir=qa / "tour/build-metadata", apk=qa / "candidate/dist/x86_64/Lumo-Lernen-Neu.apk",
                                      provenance=qa / "candidate/dist/x86_64/BUILD-PROVENANCE.json",
                                      sums=qa / "candidate/dist/ANDROID-TOUR-SHA256SUMS.txt", out=qa / "tour",
                                      expected_qa_source="a" * 40, expected_api=37, verify_only=False)

    def test_both_bound_clis_use_absolute_qa_paths_and_product_cwd(self):
        calls = []
        def runner(cmd, **kwargs):
            calls.append((cmd, kwargs))
            return subprocess.CompletedProcess(cmd, 0)
        reports = []
        MODULE.run_tours(self.args, reports, runner)
        self.assertEqual(len(calls), 2)
        for index, (cmd, kwargs) in enumerate(calls):
            self.assertEqual(cmd[2], str(self.args.qa_source / MODULE.TOURS[index]))
            self.assertTrue(Path(cmd[2]).is_absolute())
            self.assertEqual(kwargs["cwd"], self.args.candidate_source)
        self.assertIn("--expected-api", calls[1][0])
        self.assertEqual(calls[1][0][calls[1][0].index("--expected-api") + 1], "37")

    def test_failed_first_original_tour_never_invokes_cards_tour(self):
        calls = []
        def runner(cmd, **kwargs):
            calls.append(cmd)
            return subprocess.CompletedProcess(cmd, 7)
        with self.assertRaisesRegex(RuntimeError, "exit 7"):
            MODULE.run_tours(self.args, [], runner)
        self.assertEqual(len(calls), 1)

    def test_post_execution_identity_change_cannot_pass(self):
        before = {"synthetic_binding": "before"}
        put(self.args.out / "recheck/preflight.json", {"status": "PASS", "binding": before})
        with mock.patch.dict(os.environ, {"GITHUB_SHA": self.args.expected_qa_source}), \
                mock.patch.object(MODULE, "collect_binding", side_effect=[before, {"synthetic_binding": "changed"}]), \
                mock.patch.object(MODULE, "run_tours"), \
                mock.patch.object(MODULE, "verify_runtime_reports") as runtime:
            self.assertEqual(MODULE.execute(self.args), 1)
            runtime.assert_not_called()
        result = MODULE.read_json(self.args.out / "recheck/result.json")
        self.assertFalse(result["after_binding_matches"])
        self.assertEqual(MODULE.read_json(self.args.out / "recheck/after.json")["status"], "FAIL")

    def test_failed_tour_still_records_actual_post_binding(self):
        binding = {"synthetic_binding": "same"}
        put(self.args.out / "recheck/preflight.json", {"status": "PASS", "binding": binding})
        with mock.patch.dict(os.environ, {"GITHUB_SHA": self.args.expected_qa_source}), \
                mock.patch.object(MODULE, "collect_binding", return_value=binding) as collect, \
                mock.patch.object(MODULE, "run_tours", side_effect=RuntimeError("original tour failed")):
            self.assertEqual(MODULE.execute(self.args), 1)
            self.assertEqual(collect.call_count, 2)
        self.assertEqual(MODULE.read_json(self.args.out / "recheck/result.json")["status"], "FAIL")
        self.assertEqual(MODULE.read_json(self.args.out / "recheck/after.json")["status"], "PASS")

    def test_stale_reports_and_source_output_do_not_trigger_android(self):
        binding = {"synthetic_binding": "same"}
        put(self.args.out / "recheck/preflight.json", {"status": "PASS", "binding": binding})
        put(self.args.out / "tour-result.json", {"status": "PASS", "scope": "stale synthetic report"})
        with mock.patch.dict(os.environ, {"GITHUB_SHA": self.args.expected_qa_source}), \
                mock.patch.object(MODULE, "collect_binding", return_value=binding), \
                mock.patch.object(MODULE, "run_tours") as tours:
            self.assertEqual(MODULE.execute(self.args), 1)
            tours.assert_not_called()
        previous = (self.args.out / "recheck/result.json").read_bytes()
        self.assertEqual(MODULE.execute(self.args), 1)
        self.assertEqual((self.args.out / "recheck/result.json").read_bytes(), previous)
        self.args.out = self.args.candidate_source / "tour"
        self.assertEqual(MODULE.execute(self.args), 1)
        self.assertFalse(self.args.out.exists())

    def test_declared_artifact_path_cannot_create_a_source_directory_exception(self):
        self.args.apk = self.args.qa_source / ".github/probes/x86_64/Lumo-Lernen-Neu.apk"
        with mock.patch.object(MODULE, "collect_binding") as collect:
            self.assertEqual(MODULE.execute(self.args), 1)
            collect.assert_not_called()
        self.assertFalse(self.args.out.exists())


if __name__ == "__main__":
    unittest.main()
