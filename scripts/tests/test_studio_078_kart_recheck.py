"""Reject plausible but wrong sources, APKs and partial runtime acceptance."""
from __future__ import annotations

from dataclasses import replace
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import warnings
import zipfile


SOURCE = Path(__file__).resolve().parents[1] / "recheck_studio_078_kart.py"
SPEC = importlib.util.spec_from_file_location("studio_078_countercheck", SOURCE)
assert SPEC and SPEC.loader
BINDER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = BINDER
SPEC.loader.exec_module(BINDER)


def write_json(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value) + "\n")


class BoundSourceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-078-source-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.qa = self.root / "qa"
        self.qa.mkdir()
        self.command(self.qa, "init", "-q")
        self.command(self.qa, "config", "user.name", "QA fixture")
        self.command(self.qa, "config", "user.email", "qa@example.invalid")
        for name, value in {
            "pubspec.yaml": "version: 0.13.8+2020\n",
            "config/godot-source.json": json.dumps({"revision": BINDER.EXPECTED.native}),
            "lib/app.dart": "const originalProduct = true;\n",
            BINDER.PROBE: "original probe\n",
        }.items():
            path = self.qa / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(value)
        self.command(self.qa, "add", ".")
        self.command(self.qa, "commit", "-qm", "immutable APK source fixture")
        host = self.command(self.qa, "rev-parse", "HEAD").strip()
        self.expected = replace(BINDER.EXPECTED, host=host)
        self.product = self.root / "candidate-source"
        self.command(self.root, "clone", "-q", str(self.qa), str(self.product))
        for name in BINDER.ALLOWLIST:
            path = self.qa / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("reviewed QA change\n")
        self.command(self.qa, "add", ".")
        self.command(self.qa, "commit", "-qm", "QA-only fixture")
        self.head = self.command(self.qa, "rev-parse", "HEAD").strip()

    @staticmethod
    def command(root, *args):
        return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE).decode()

    def verify(self):
        return BINDER.verify_sources(self.qa, self.product, self.head, (), self.expected)

    def test_separate_exact_sources_keep_all_product_entries(self):
        result = self.verify()
        self.assertEqual(result["product"]["head"], self.expected.host)
        self.assertEqual(set(result["reviewed_qa_delta"]), BINDER.ALLOWLIST)
        self.assertEqual(result["unchanged_other_git_entries"], 3)

    def test_uncommitted_product_change_is_rejected(self):
        (self.product / "lib/app.dart").write_text("changed product\n")
        with self.assertRaisesRegex(RuntimeError, "Tracked checkout"):
            self.verify()

    def test_committed_product_change_on_qa_branch_is_rejected(self):
        (self.qa / "lib/app.dart").write_text("unreviewed product\n")
        self.command(self.qa, "add", "lib/app.dart")
        self.command(self.qa, "commit", "-qm", "wrong product edit")
        self.head = self.command(self.qa, "rev-parse", "HEAD").strip()
        with self.assertRaisesRegex(RuntimeError, "Unreviewed QA delta"):
            self.verify()

    def test_untracked_import_is_rejected(self):
        (self.qa / "scripts/unreviewed.py").write_text("pass\n")
        with self.assertRaisesRegex(RuntimeError, "Untracked source"):
            self.verify()

    def test_wrong_declared_qa_head_is_rejected(self):
        self.head = self.expected.host
        with self.assertRaisesRegex(RuntimeError, "Actual source HEAD"):
            self.verify()


class ArtifactMetadataTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-078-metadata-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        expected = BINDER.EXPECTED
        self.files = {
            "run.json": {"id": expected.run, "head_sha": expected.host, "run_attempt": 1,
                         "status": "completed", "conclusion": "failure",
                         "repository": {"full_name": "Ullmann27/lumo-lernen"},
                         "path": ".github/workflows/lumo-unified-integration-2026.yml"},
            "artifact.json": {"id": expected.artifact, "expired": False,
                              "name": "lumo-lernen-kart-unified-2026-candidate",
                              "size_in_bytes": expected.artifact_bytes,
                              "digest": "sha256:" + expected.artifact_sha256,
                              "workflow_run": {"id": expected.run, "head_sha": expected.host}},
            "build-job.json": {"id": expected.build_job, "run_id": expected.run,
                               "head_sha": expected.host, "name": "verify-and-build",
                               "status": "completed", "conclusion": "success", "steps": [
                                   {"name": name, "conclusion": "success"} for name in (
                                       "Build unified real Android APK",
                                       "Verify APK archive and collect reproducible source hashes",
                                       "Upload exact candidate (no release or synthetic screenshots)")]},
            "failed-tour-job.json": {"id": expected.failed_tour_job, "run_id": expected.run,
                                     "head_sha": expected.host, "name": "android-tour",
                                     "status": "completed", "conclusion": "failure"},
        }
        for name, data in self.files.items():
            write_json(self.root / name, data)

    def test_original_failure_and_successful_builder_are_both_retained(self):
        result = BINDER.verify_metadata(self.root)
        self.assertEqual(result["original_conclusion"], "failure")
        self.assertEqual(result["original_failed_tour"], BINDER.EXPECTED.failed_tour_job)

    def test_wrong_attempt_artifact_or_relabelled_failure_is_rejected(self):
        mutations = (("run.json", "run_attempt", 2),
                     ("run.json", "conclusion", "success"),
                     ("artifact.json", "id", 14108549235),
                     ("artifact.json", "expired", True),
                     ("artifact.json", "digest", "sha256:" + "f" * 64),
                     ("build-job.json", "conclusion", "failure"),
                     ("failed-tour-job.json", "conclusion", "success"))
        for filename, key, value in mutations:
            with self.subTest(filename=filename, key=key):
                changed = dict(self.files[filename], **{key: value})
                write_json(self.root / filename, changed)
                with self.assertRaises(RuntimeError):
                    BINDER.verify_metadata(self.root)
                write_json(self.root / filename, self.files[filename])


class ActualArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-078-archive-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.apk = self.root / "candidate.apk"
        self.provenance = self.root / "BUILD-PROVENANCE.json"
        self.sums = self.root / "sums.txt"
        self.pack = b"GDPC" + bytes(16) + b"small structural fixture, not a runnable APK"
        self.native = {"revision": BINDER.EXPECTED.native, "engine": "4.6.3",
                       "pck_sha256": hashlib.sha256(self.pack).hexdigest(), "bytes": len(self.pack)}
        with zipfile.ZipFile(self.apk, "w") as archive:
            archive.writestr("assets/lumo_game.pck", self.pack)
            archive.writestr("assets/lumo_game_source.json", json.dumps(self.native))
        self.expected = replace(BINDER.EXPECTED, apk_bytes=self.apk.stat().st_size,
                                apk_sha256=BINDER.sha256(self.apk), pck_bytes=len(self.pack),
                                pck_sha256=self.native["pck_sha256"])
        self.proof = {"package": self.expected.package, "versionName": "0.13.8", "versionCode": 2020,
                      "flutter_source_commit": self.expected.host, "tracked_source_clean": True,
                      "abis": ["x86_64"], "bytes": self.expected.apk_bytes, "sha256": self.expected.apk_sha256,
                      "signingCertificateSha256": self.expected.certificate, "godot": self.native}
        write_json(self.provenance, self.proof)
        self.sums.write_text(self.expected.apk_sha256 + "  dist/x86_64/Lumo-Lernen-Neu.apk\n")

    def verify(self):
        return BINDER.verify_apk(self.apk, self.provenance, self.sums, self.expected)

    def test_reads_actual_embedded_pack_bytes(self):
        result = self.verify()
        self.assertEqual(result["pck_sha256"], hashlib.sha256(self.pack).hexdigest())

    def test_rejects_appended_apk_bytes(self):
        with self.apk.open("ab") as stream:
            stream.write(b"altered")
        with self.assertRaisesRegex(RuntimeError, "Actual APK bytes"):
            self.verify()

    def test_rejects_same_version_different_source_provenance(self):
        self.proof["flutter_source_commit"] = "f" * 40
        write_json(self.provenance, self.proof)
        with self.assertRaisesRegex(RuntimeError, "provenance"):
            self.verify()

    def test_rejects_valid_outer_digest_with_wrong_embedded_pack(self):
        self.expected = replace(self.expected, pck_sha256="f" * 64)
        self.native["pck_sha256"] = self.expected.pck_sha256
        self.proof["godot"] = self.native
        write_json(self.provenance, self.proof)
        with self.assertRaisesRegex(RuntimeError, "Actual embedded PCK"):
            self.verify()

    def test_duplicate_embedded_pack_is_rejected_even_with_matching_outer_digest(self):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(self.apk, "a") as archive:
                archive.writestr("assets/lumo_game.pck", self.pack)
        self.expected = replace(self.expected, apk_bytes=self.apk.stat().st_size,
                                apk_sha256=BINDER.sha256(self.apk))
        self.proof.update(bytes=self.expected.apk_bytes, sha256=self.expected.apk_sha256)
        write_json(self.provenance, self.proof)
        self.sums.write_text(self.expected.apk_sha256 + "  dist/x86_64/Lumo-Lernen-Neu.apk\n")
        with self.assertRaisesRegex(RuntimeError, "duplicated embedded asset"):
            self.verify()


class RuntimeGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-078-runtime-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        expected = BINDER.EXPECTED
        identity = {"step": "apk-identity", "ok": True, "apk_sha256": expected.apk_sha256,
                    "flutter_source_commit": expected.host, "godot_revision": expected.native,
                    "godot_pck_sha256": expected.pck_sha256, "versionCode": 2020, "versionName": "0.13.8",
                    "signingCertificateSha256": expected.certificate,
                    "checks": {name: True for name in BINDER.IDENTITY_CHECKS}}
        self.report = {"status": "PASS", "apk_sha256": expected.apk_sha256, "android_sdk": "35",
                       "fatal_crashes": 0, "steps": [identity] + [
                           {"step": name, "ok": True} for name in BINDER.HARD_STEPS if name != "apk-identity"]}
        frames = []
        for index in range(2):
            # Structural witness bytes only; these unit fixtures claim no Android capture.
            path = self.root / f"preview-{index}.png"
            path.write_bytes(f"unit witness {index}".encode())
            checksum = BINDER.sha256(path)
            frames.append({"source": path.name, "source_bytes": path.stat().st_size,
                           "source_sha256": checksum, "acceptable_for_target_sampling": True,
                           "target": {"target_geometry_valid": True, "surface_sha256": checksum,
                                      "bounds": [100, 100, 200, 140], "stable_observed_target": index == 1}})
        self.skip = {"status": "TOUCH_SENT", "countercheck_scope": "OBSERVED_UI_TOUCH_ONLY",
                     "caption": "Tippen zum Überspringen", "foreground_before_touch": "app/LumoGameActivity",
                     "touch": [150, 120], "readiness_file": "21_kart_preview_skip_touch-surface-readiness.json",
                     "readiness": {
            "status": "TOUCH_SENT", "exact_caption_required": True, "orientation_policy": "landscape",
            "label": "Tippen zum Überspringen",
            "frames": frames, "final_observed_bounds": [100, 100, 200, 140], "touch": [150, 120]}}
        cue = self.root / frames[-1]["source"]
        after = self.root / "21_kart_preview_after_touch.png"
        after.write_bytes(b"structural after-touch fixture")
        ocr_name = cue.stem + "-ocr.json"
        observed = [{"text": "Tippen zum Überspringen", "bounds": [100, 100, 200, 140],
                     "variant": "contrast"}]
        self.skip["cue"] = {"source": cue.name, "source_sha256": BINDER.sha256(cue),
                            "ocr_file": ocr_name, "observed_matches": observed}
        write_json(self.root / ocr_name, observed)
        self.skip["after_capture"] = {"file": after.name, "sha256": BINDER.sha256(after)}
        write_json(self.root / self.skip["readiness_file"], self.skip["readiness"])
        next(s for s in self.report["steps"] if s["step"] == "start-kart-race")["preview_skip"] = self.skip
        write_json(self.root / "21_kart_preview_skip.json", self.skip)

    def verify(self):
        write_json(self.root / "tour-result.json", self.report)
        return BINDER.verify_runtime_report(self.root)

    def test_all_original_runtime_gates_are_required(self):
        self.assertEqual(self.verify()["hard_steps"], list(BINDER.HARD_STEPS))

    def test_green_report_cannot_hide_missing_or_failed_driving(self):
        self.report["steps"] = [s for s in self.report["steps"] if s["step"] != "race-drive"]
        with self.assertRaisesRegex(RuntimeError, "race-drive"):
            self.verify()
        self.report["steps"].append({"step": "race-drive", "ok": False})
        with self.assertRaisesRegex(RuntimeError, "race-drive"):
            self.verify()

    def test_duplicate_success_cannot_replace_single_unambiguous_gate(self):
        self.report["steps"].append({"step": "pause-menu", "ok": True})
        with self.assertRaisesRegex(RuntimeError, "pause-menu"):
            self.verify()

    def test_runtime_other_apk_source_is_rejected(self):
        self.report["steps"][0]["flutter_source_commit"] = "f" * 40
        with self.assertRaisesRegex(RuntimeError, "Installed APK identity"):
            self.verify()

    def test_passing_tour_without_observed_intro_touch_is_not_isolated(self):
        self.skip["status"] = "CUE_NOT_OBSERVED"
        with self.assertRaisesRegex(RuntimeError, "NOT_ISOLATED"):
            self.verify()

    def test_two_copies_of_one_frame_are_not_two_observations(self):
        self.skip["readiness"]["frames"][0] = self.skip["readiness"]["frames"][1]
        with self.assertRaisesRegex(RuntimeError, "same capture"):
            self.verify()

    def test_changed_witness_bytes_are_rejected(self):
        (self.root / "preview-1.png").write_bytes(b"changed")
        with self.assertRaisesRegex(RuntimeError, "image bytes"):
            self.verify()

    def test_touch_outside_observed_caption_is_rejected(self):
        self.skip["readiness"]["touch"] = [700, 700]
        with self.assertRaisesRegex(RuntimeError, "not inside"):
            self.verify()

    def test_different_visible_control_cannot_count_as_intro_skip(self):
        self.skip["caption"] = self.skip["readiness"]["label"] = "START"
        with self.assertRaisesRegex(RuntimeError, "NOT_ISOLATED"):
            self.verify()

    def test_after_touch_frame_is_required_as_actual_file(self):
        (self.root / "21_kart_preview_after_touch.png").write_bytes(b"changed after frame")
        with self.assertRaisesRegex(RuntimeError, "after-touch capture"):
            self.verify()

    def test_claimed_cue_cannot_replace_different_actual_ocr_output(self):
        write_json(self.root / self.skip["cue"]["ocr_file"],
                   [{"text": "START", "bounds": [100, 100, 200, 140]}])
        with self.assertRaisesRegex(RuntimeError, "not actually read"):
            self.verify()

    def test_read_text_at_other_bounds_does_not_authorize_this_touch(self):
        write_json(self.root / self.skip["cue"]["ocr_file"],
                   [{"text": "Tippen zum Überspringen", "bounds": [900, 500, 1000, 540]}])
        with self.assertRaisesRegex(RuntimeError, "not actually read"):
            self.verify()


if __name__ == "__main__":
    unittest.main()
