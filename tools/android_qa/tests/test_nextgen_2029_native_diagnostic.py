"""Small synthetic checker fixtures; these tests do not run Android or claim playback."""
import contextlib
import copy
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
SPEC = importlib.util.spec_from_file_location(
    "native_diagnostic_2029", ROOT / ".github/probes/lumo_nextgen_2029_native_diagnostic.py")
diagnostic = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(diagnostic)
QA = "a" * 40
QA_RUN = 90000000001


def arguments(directory, scene="banana"):
    root = Path(directory)
    return SimpleNamespace(qa_commit=QA, workflow_run_id=QA_RUN, scene=scene, serial=None,
        candidate=root / "candidate/x86", download_evidence=root / "origin", out=root / "runtime")


def environment(scene="banana"):
    return {"GITHUB_REPOSITORY": diagnostic.reference.REPOSITORY, "GITHUB_SHA": QA,
            "GITHUB_RUN_ID": str(QA_RUN), "GITHUB_REF_NAME": diagnostic.QA_BRANCH,
            "LUMO_DIAGNOSTIC_SCENE": scene}


def proof():
    return {"sha256": diagnostic.APK_SHA, "flutter_source_commit": diagnostic.SOURCE,
        "versionCode": diagnostic.VERSION, "versionName": diagnostic.VERSION_NAME,
        "package": diagnostic.learning.PACKAGE, "signingCertificateSha256": diagnostic.CERTIFICATE,
        "tracked_source_clean": True, "abis": ["x86_64"],
        "godot": {"revision": diagnostic.NATIVE, "pck_sha256": diagnostic.PCK_SHA}}


def origins():
    run = {"id": diagnostic.SOURCE_RUN, "head_sha": diagnostic.SOURCE,
        "repository": {"full_name": diagnostic.reference.REPOSITORY, "id": diagnostic.reference.REPOSITORY_ID},
        "path": ".github/workflows/lumo-nextgen-learning-apk.yml", "status": "completed", "conclusion": "failure"}
    artifact = {"id": diagnostic.ARTIFACT_ID, "name": diagnostic.ARTIFACT_NAME,
        "size_in_bytes": diagnostic.ZIP_BYTES, "digest": "sha256:" + diagnostic.ZIP_SHA, "expired": False,
        "workflow_run": {"id": diagnostic.SOURCE_RUN, "head_sha": diagnostic.SOURCE,
            "repository_id": diagnostic.reference.REPOSITORY_ID, "head_repository_id": diagnostic.reference.REPOSITORY_ID}}
    jobs = [{"id": number, "run_id": diagnostic.SOURCE_RUN, "head_sha": diagnostic.SOURCE,
             "name": name, "status": "completed", "conclusion": conclusion}
            for number, name, conclusion in ((diagnostic.VALIDATE_JOB, "validate", "success"),
                (diagnostic.BUILD_JOB, "build", "success"), (diagnostic.ANDROID_JOB, "android", "failure"))]
    jobs[1]["steps"] = [{"name": "Independently verify both produced artifacts", "conclusion": "success"}]
    return [run, artifact, *jobs]


class ObservedStub:
    def __init__(self, args, result, *, failure=False, api=35, absent=True):
        self.args, self.result = args, result
        self.calls, self.failure, self.api, self.absent = [], failure, api, absent

    def run(self):
        raise AssertionError("Never run the full acceptance tour")

    def reset_successful_original(self):
        raise AssertionError("Never reset or manufacture original acceptance")

    def identify_and_install(self):
        self.calls.append("install")
        self.result["device"] = {"api": self.api, "package_absent_before_install": self.absent}

    def onboard(self):
        self.calls.append("onboard")

    def configure_local_voice(self):
        self.calls.append("settings")

    def academy(self):
        self.calls.append("academy")

    def route(self, name):
        self.calls.append(name)
        if self.failure:
            raise RuntimeError("Observed scene failure fixture")

    def banana(self):
        self.route("banana")

    def pattern(self):
        self.route("pattern")

    def native_roundtrip(self):
        self.route("bridge")

    def preferences(self, tag):
        self.calls.append("preferences")
        return {}

    def capture(self, *args, **kwargs):
        self.calls.append("failure_capture")

    def speech_log(self):
        self.calls.append("failure_audio_log")


class IdentityTests(unittest.TestCase):
    def test_fixed_identity_rejects_other_apk_source_version_pack_and_signer(self):
        self.assertEqual(diagnostic.fixed_identity(proof())["sha256"], diagnostic.APK_SHA)
        for key, wrong in (("sha256", "b" * 64), ("flutter_source_commit", "b" * 40),
                ("versionCode", 2028), ("versionName", "0.13.16"), ("package", "other.package"),
                ("signingCertificateSha256", "b" * 64), ("tracked_source_clean", False), ("abis", ["arm64-v8a"])):
            with self.subTest(key=key):
                changed = proof()
                changed[key] = wrong
                with self.assertRaises(RuntimeError):
                    diagnostic.fixed_identity(changed)
        for key in ("revision", "pck_sha256"):
            changed = proof()
            changed["godot"][key] = "b" * (40 if key == "revision" else 64)
            with self.subTest(native=key), self.assertRaises(RuntimeError):
                diagnostic.fixed_identity(changed)

    def test_candidate_hash_and_size_are_read_from_real_fixture_bytes(self):
        data = b"synthetic checker fixture, never an APK"
        sha = hashlib.sha256(data).hexdigest()
        with tempfile.TemporaryDirectory() as directory, patch.object(diagnostic, "APK_BYTES", len(data)), \
             patch.object(diagnostic, "APK_SHA", sha):
            root = Path(directory)
            candidate = root / "Lumo-Lernen-Neu.apk"
            candidate.write_bytes(data)
            (root / "BUILD-PROVENANCE.json").write_text(json.dumps(proof()))
            self.assertEqual(diagnostic.verify_candidate(root)["sha256"], sha)
            for wrong in (data + b"!", b"x" * len(data)):
                candidate.write_bytes(wrong)
                with self.assertRaisesRegex(RuntimeError, "exact already-built"):
                    diagnostic.verify_candidate(root)

    def test_original_jobs_and_artifact_are_bound_and_original_failure_is_required(self):
        diagnostic.verify_origin(*origins())
        mutations = [(0, "head_sha", "b" * 40), (0, "conclusion", "success"),
            (1, "id", 14185954865), (1, "digest", "sha256:" + "b" * 64),
            (1, "size_in_bytes", 1), (1, "expired", True),
            (2, "conclusion", "failure"), (3, "run_id", 1), (3, "head_sha", "b" * 40),
            (4, "conclusion", "success"), (4, "id", 1)]
        for index, key, wrong in mutations:
            rows = origins()
            rows[index][key] = wrong
            with self.subTest(index=index, key=key), self.assertRaises(RuntimeError):
                diagnostic.verify_origin(*rows)
        rows = origins()
        rows[3]["steps"] = []
        with self.assertRaises(RuntimeError):
            diagnostic.verify_origin(*rows)
        rows = origins()
        rows[1]["workflow_run"]["head_sha"] = "b" * 40
        with self.assertRaises(RuntimeError):
            diagnostic.verify_origin(*rows)

    def test_ci_requires_new_run_commit_exact_branch_and_matching_scene(self):
        args = arguments("fixture")
        diagnostic.verify_ci_context(args, environment())
        for key in environment():
            changed = environment()
            changed[key] = "wrong"
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                diagnostic.verify_ci_context(args, changed)
        for key, wrong in (("qa_commit", diagnostic.SOURCE), ("workflow_run_id", diagnostic.SOURCE_RUN),
                           ("workflow_run_id", True), ("scene", "other")):
            changed = copy.copy(args)
            setattr(changed, key, wrong)
            with self.subTest(argument=key), self.assertRaises(RuntimeError):
                diagnostic.verify_ci_context(changed, environment())

    def test_only_new_named_qa_files_may_differ_from_apk_source(self):
        diagnostic.verify_changes([("A", name) for name in diagnostic.NEW_FILES])
        for changes in ([], [("M", next(iter(diagnostic.NEW_FILES)))],
                [("M", ".github/probes/lumo_nextgen_learning_android_probe.py")],
                [("A", "lib/new_runtime.dart")], [("D", "pubspec.yaml")],
                [("A", ".github/probes/../workflows/other.yml")]):
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                diagnostic.verify_changes(changes)

    def test_download_binding_rejects_cross_scene_or_modified_origin_records(self):
        with tempfile.TemporaryDirectory() as directory:
            args = arguments(directory)
            args.download_evidence.mkdir()
            binding = {"qa_commit": QA, "scene": "banana", "fixture": "synthetic source-binding"}
            diagnostic.write_json(args.download_evidence / "qa-source-binding.json", binding)
            for name, row in zip(diagnostic.ORIGIN_FILES, origins()):
                diagnostic.write_json(args.download_evidence / name, row)
            identity = diagnostic.fixed_identity(proof())
            record = {"mode": "diagnostic-only", "qa_commit": QA, "qa_workflow_run": QA_RUN,
                "scene": "banana", "source_build_run": diagnostic.SOURCE_RUN, "source_run_conclusion": "failure",
                "artifact_id": diagnostic.ARTIFACT_ID, "zip_bytes": diagnostic.ZIP_BYTES,
                "zip_sha256": diagnostic.ZIP_SHA, "apk_bytes": diagnostic.APK_BYTES,
                "candidate": identity, "source_binding": binding, "apk_rebuilt": False,
                "origin_files": {name: diagnostic.digest(args.download_evidence / name) for name in diagnostic.ORIGIN_FILES}}
            path = args.download_evidence / "verified-download.json"
            diagnostic.write_json(path, record)
            with patch.object(diagnostic, "verify_candidate", return_value=identity), \
                 patch.object(diagnostic, "source_binding", return_value=binding):
                self.assertEqual(diagnostic.verify_download(args), identity)
                changed = copy.deepcopy(record)
                changed["scene"] = "pattern"
                diagnostic.write_json(path, changed)
                with self.assertRaises(RuntimeError):
                    diagnostic.verify_download(args)
                diagnostic.write_json(path, record)
                origin = args.download_evidence / diagnostic.ORIGIN_FILES[0]
                origin.write_text(origin.read_text() + "\n")
                with self.assertRaises(RuntimeError):
                    diagnostic.verify_download(args)


class IsolationTests(unittest.TestCase):
    def test_each_scene_uses_fresh_install_ui_setup_and_only_its_existing_route(self):
        for scene in diagnostic.SCENES:
            args = arguments("fixture", scene)
            probe = ObservedStub(args, diagnostic.diagnostic_result(args))
            with patch.object(diagnostic.learning, "learning_snapshot", return_value={"profile": {"id": "fixture"}}):
                diagnostic.observe_scene(probe)
            self.assertEqual(probe.calls, ["install", "onboard", "settings"] +
                ([] if scene == "banana" else ["academy"]) + [scene, "preferences"])
            self.assertEqual(probe.result["status"], "DIAGNOSTIC_ONLY")
            self.assertNotIn("previous_complete_probe", probe.result)

    def test_wrong_api_or_existing_package_stops_before_profile_navigation(self):
        for api, absent in ((34, True), (36, True), (35, False)):
            probe = ObservedStub(arguments("fixture"), {}, api=api, absent=absent)
            with self.subTest(api=api, absent=absent), self.assertRaises(RuntimeError):
                diagnostic.observe_scene(probe)
            self.assertEqual(probe.calls, ["install"])

    def test_full_tour_and_reset_methods_cannot_be_invoked(self):
        probe = object.__new__(diagnostic.DiagnosticProbe)
        for name in ("run", "reset_successful_original"):
            with self.subTest(method=name), self.assertRaises(RuntimeError):
                getattr(probe, name)()

    def test_success_and_failure_are_diagnostic_only_and_never_submit_core_answer(self):
        for scene in diagnostic.SCENES:
            for failure in (False, True):
                with self.subTest(scene=scene, failure=failure), tempfile.TemporaryDirectory() as directory:
                    args = arguments(directory, scene)
                    made = []

                    def factory(arguments, result):
                        probe = ObservedStub(arguments, result, failure=failure)
                        made.append(probe)
                        return probe

                    with patch.dict(os.environ, environment(scene)), \
                         patch.object(diagnostic, "verify_download", return_value=proof()), \
                         patch.object(diagnostic, "DiagnosticProbe", side_effect=factory), \
                         patch.object(diagnostic.shutil, "which", return_value="/usr/bin/ffprobe"), \
                         patch.object(diagnostic.learning, "learning_snapshot", return_value={"profile": {"id": "fixture"}}), \
                         contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                        code = diagnostic.run(args)
                    result = diagnostic.load(args.out / "diagnostic-android-result.json")
                    self.assertEqual(code, 1 if failure else 0)
                    self.assertEqual(result["diagnostic_outcome"], "FAILED" if failure else "COMPLETED")
                    self.assertEqual(result["status"], "DIAGNOSTIC_ONLY")
                    for key in ("release_eligible", "original_probe_requirement_satisfied", "original_failed_android_reclassified"):
                        self.assertIs(result[key], False)
                    self.assertFalse(made[0].args.submit_core_answer)
                    self.assertNotIn("previous_complete_probe", result)
                    self.assertFalse((args.out / "learning-android-result.json").exists())
                    self.assertFalse((args.out / "reference-android-result.json").exists())
                    if failure:
                        self.assertIn("failure_capture", made[0].calls)
                        self.assertIn("failure_audio_log", made[0].calls)

    def test_original_acceptance_rejects_even_completed_diagnostic(self):
        result = diagnostic.diagnostic_result(arguments("fixture"))
        result["diagnostic_outcome"] = "COMPLETED"
        with self.assertRaisesRegex(RuntimeError, "Original probe has not passed"):
            diagnostic.reference.verify_complete_original(result, proof())

    def test_wrapper_passes_exact_scene_and_propagates_real_process_exit(self):
        wrapper = ROOT / ".github/probes/run_lumo_nextgen_2029_native_diagnostic.sh"
        subprocess.run(["bash", "-n", str(wrapper)], check=True)
        for code in (0, 17):
            with self.subTest(exit_code=code), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                executable = root / ".probe-venv/bin/python"
                executable.parent.mkdir(parents=True)
                executable.write_text("#!/usr/bin/env python3\nimport json,os,sys\n"
                    "open('argv.json','w').write(json.dumps(sys.argv[1:]))\n"
                    "sys.exit(int(os.environ['FIXTURE_EXIT']))\n")
                executable.chmod(0o755)
                result = subprocess.run(["bash", str(wrapper)], cwd=root,
                    env={**os.environ, **environment("pattern"), "FIXTURE_EXIT": str(code)}, capture_output=True)
                self.assertEqual(result.returncode, code)
                actual = json.loads((root / "argv.json").read_text())
                self.assertEqual(actual[:2], [".github/probes/lumo_nextgen_2029_native_diagnostic.py", "run"])
                self.assertEqual(actual[actual.index("--scene") + 1], "pattern")
                self.assertEqual(actual[actual.index("--qa-commit") + 1], QA)
                self.assertNotIn("--previous-probe-out", actual)
                self.assertNotIn("--submit-core-answer", actual)


if __name__ == "__main__":
    unittest.main()
