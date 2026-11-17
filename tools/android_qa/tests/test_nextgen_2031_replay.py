"""Identity/evidence fixtures and actual shell/git processes, not Android PASS."""
from __future__ import annotations

import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


probe = module("replay_2031_under_test", ".github/probes/lumo_nextgen_2031_replay_reference_android_probe.py")
fixtures = module("replay_2031_existing_gate_fixtures", "tools/android_qa/tests/test_nextgen_current_candidate.py")
wrapped = module("replay_2031_existing_pattern_fixture", "tools/android_qa/tests/test_nextgen_native_reader.py")
QA, RUN, RESULT_SHA = "1" * 40, 987654, "2" * 64


def identity():
    return {"sha256": probe.APK_SHA, "flutter_source_commit": probe.SOURCE,
            "versionCode": probe.VERSION, "versionName": probe.VERSION_NAME,
            "package": probe.learning.PACKAGE, "signingCertificateSha256": probe.CERTIFICATE,
            "abis": ["x86_64"], "tracked_source_clean": True,
            "godot": {"revision": probe.NATIVE, "pck_sha256": probe.PCK_SHA}}


def inputs():
    # Explicitly synthetic in-memory fixtures for the shared gate. Never saved
    # among CI Android observations and never used to satisfy the real tour.
    original, extra = fixtures.inputs()
    original.update(candidate=identity(), installed=identity())
    extra.pop("source_workflow_run")
    extra.update(version=1, mode="immutable-replay", candidate=identity(), installed=identity(),
                 qa_commit=QA, apk_source=probe.SOURCE, native_source=probe.NATIVE,
                 source_build_run=probe.SOURCE_RUN, qa_workflow_run=RUN,
                 probe_sha256=probe.digest(Path(probe.__file__)))
    extra["previous_complete_probe"].update(original_result_sha256=RESULT_SHA, installed_before_reset=identity())
    return original, extra


def origin():
    run = {"id": probe.SOURCE_RUN, "head_sha": probe.SOURCE,
           "repository": {"full_name": probe.reference.REPOSITORY, "id": probe.reference.REPOSITORY_ID},
           "path": ".github/workflows/lumo-nextgen-learning-apk.yml", "status": "completed", "conclusion": "failure"}
    artifact = {"id": probe.ARTIFACT_ID, "name": probe.ARTIFACT_NAME, "size_in_bytes": probe.ZIP_BYTES,
                "digest": "sha256:" + probe.ZIP_SHA, "expired": False,
                "workflow_run": {"id": probe.SOURCE_RUN, "head_sha": probe.SOURCE,
                    "repository_id": probe.reference.REPOSITORY_ID, "head_repository_id": probe.reference.REPOSITORY_ID}}
    jobs = [{"id": number, "run_id": probe.SOURCE_RUN, "head_sha": probe.SOURCE, "name": name,
             "status": "completed", "conclusion": "success"}
            for number, name in ((probe.VALIDATION_JOB, "validate"), (probe.BUILD_JOB, "build"))]
    jobs[1]["steps"] = [{"name": "Independently verify both produced artifacts", "conclusion": "success"}]
    return run, artifact, *jobs


class FixedIdentityTest(unittest.TestCase):
    def test_checked_in_config_is_exact_and_only_attempt_can_change(self):
        config = probe.load(probe.CONFIG)
        probe.verify_config(config)
        probe.verify_config({**config, "replayAttempt": 2})
        for field, value in (("schemaVersion", True), ("versionCode", 2027), ("versionName", "0.13.15"),
                             ("apkSource", QA), ("nativeSource", QA), ("sourceBuildRun", RUN),
                             ("sourceValidateJob", 1), ("sourceBuildJob", 2), ("certificate", "0" * 64),
                             ("pckSha256", "0" * 64), ("replayAttempt", True), ("replayAttempt", 0)):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                probe.verify_config({**config, field: value})
        with self.assertRaises(RuntimeError):
            probe.verify_config({**config, "skipOriginal": True})
        for field, value in (("id", 1), ("name", "old"), ("zipBytes", 1), ("zipSha256", "0" * 64),
                             ("apkBytes", 1), ("apkSha256", "0" * 64)):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                probe.verify_config({**config, "x86Artifact": {**config["x86Artifact"], field: value}})

    def test_identity_checks_exact_2031_source_pack_version_certificate(self):
        self.assertEqual(probe.fixed_identity(identity()), identity())
        for field, value in (("sha256", probe.reference.APK_SHA256), ("flutter_source_commit", QA),
                             ("versionCode", 2027), ("versionCode", True), ("versionName", "old"),
                             ("package", "other"), ("signingCertificateSha256", "0" * 64),
                             ("abis", ["arm64-v8a"]), ("tracked_source_clean", False),
                             ("godot", {"revision": probe.NATIVE, "pck_sha256": "0" * 64})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                probe.fixed_identity({**identity(), field: value})

    def test_small_fixture_file_is_never_an_accepted_apk(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "Lumo-Lernen-Neu.apk").write_bytes(b"not an APK")
            (directory / "BUILD-PROVENANCE.json").write_text(json.dumps(identity()))
            with self.assertRaisesRegex(RuntimeError, "exact independently verified"):
                probe.verify_candidate(directory)

    def test_exact_run_environment_and_distinct_qa_identity_required(self):
        environment = {"GITHUB_REPOSITORY": probe.reference.REPOSITORY, "GITHUB_SHA": QA,
                       "GITHUB_RUN_ID": str(RUN), "GITHUB_REF_NAME": probe.QA_BRANCH}
        probe.verify_ci_context(QA, RUN, environment)
        for key in environment:
            with self.subTest(key=key), self.assertRaises(RuntimeError):
                probe.verify_ci_context(QA, RUN, {**environment, key: "other"})
        for qa, run in ((probe.SOURCE, RUN), ("invalid", RUN), (QA, probe.SOURCE_RUN), (QA, True), (QA, 0)):
            with self.subTest(qa=qa, run=run), self.assertRaises(RuntimeError):
                probe.verify_qa_identity(qa, run)

    def test_original_failed_run_and_successful_build_jobs_are_required(self):
        records = origin()
        probe.verify_origin(*records)
        mutations = ((0, "conclusion", "success"), (0, "head_sha", QA), (0, "id", RUN),
                     (1, "id", probe.reference.ARTIFACT_ID), (1, "size_in_bytes", probe.ZIP_BYTES - 1),
                     (1, "digest", "sha256:" + "0" * 64), (1, "expired", True), (1, "expired", 0),
                     (1, "workflow_run", {}), (2, "id", 1), (2, "conclusion", "failure"),
                     (3, "head_sha", QA), (3, "conclusion", "failure"), (3, "steps", []))
        for index, field, value in mutations:
            changed = copy.deepcopy(records)
            changed[index][field] = value
            with self.subTest(index=index, field=field), self.assertRaises(RuntimeError):
                probe.verify_origin(*changed)

    def test_source_allowlist_excludes_runtime_build_and_pin_changes(self):
        for name in (".github/probes/entry.py", ".github/workflows/replay.yml", "tools/android_qa/tests/test.py",
                     "docs/nextgen/evidence/log.txt", "STATUS.md", "CONTINUE.md", *probe.QA_FILES):
            with self.subTest(name=name):
                self.assertTrue(probe.allowed_qa_path(name))
        for name in ("lib/main.dart", "assets/pack.pck", "android/app/build.gradle", "pubspec.yaml",
                     "pubspec.lock", "config/godot-source.json", "scripts/build.sh", "tools/nextgen/other.py",
                     "tools/auto_install/MainActivity.kt", "tools/nextgen/prepare_current_learning_release.py",
                     "tools/nextgen/public_learning_download.py",
                     "docs/../lib/main.dart", "/docs/record.md", "docs\\record.md", "docs//record.md"):
            with self.subTest(name=name):
                self.assertFalse(probe.allowed_qa_path(name))

    def test_real_git_diff_detects_committed_product_changes_even_in_sparse_checkout(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            def git(*args):
                return subprocess.check_output(["git", *args], cwd=root, stderr=subprocess.STDOUT).decode().strip()
            git("init", "-q")
            git("config", "user.name", "QA fixture")
            git("config", "user.email", "qa-fixture@example.invalid")
            (root / "lib").mkdir()
            (root / "lib/main.dart").write_text("unchanged product\n")
            git("add", ".")
            git("commit", "-qm", "fixture product")
            source = git("rev-parse", "HEAD")
            (root / "config").mkdir()
            config = root / "config/nextgen-2031-replay.json"
            config.write_text(json.dumps(probe.load(probe.CONFIG)))
            git("add", ".")
            git("commit", "-qm", "fixture QA config")
            qa = git("rev-parse", "HEAD")
            with patch.object(probe, "ROOT", root), patch.object(probe, "SOURCE", source), patch.object(probe, "CONFIG", config):
                record = probe.verify_source_binding(qa, RUN, root / "evidence/first.json")
                self.assertEqual(record["changed_paths"], ["config/nextgen-2031-replay.json"])
                (root / "lib/main.dart").write_text("changed product\n")
                git("add", "lib/main.dart")
                git("commit", "-qm", "fixture forbidden runtime delta")
                git("sparse-checkout", "set", "config")
                self.assertFalse((root / "lib/main.dart").exists())
                with self.assertRaisesRegex(RuntimeError, "unapproved path"):
                    probe.verify_source_binding(git("rev-parse", "HEAD"), RUN, root / "evidence/rejected.json")


class TourGateTest(unittest.TestCase):
    def verify(self, original, extra):
        return probe.verify_2031_tours(original, extra, qa_commit=QA, qa_workflow_run=RUN,
                                       original_result_sha256=RESULT_SHA)

    def test_both_tours_require_actual_gate_records_without_rewriting_current_mode(self):
        original, extra = inputs()
        before = copy.deepcopy((original, extra))
        self.assertEqual(self.verify(original, extra), original["native_learning"]["performance"])
        self.assertEqual((original, extra), before)
        with self.assertRaises(RuntimeError):
            fixtures.release.verify_tours(original, extra, source=probe.SOURCE, native=probe.NATIVE,
                version=probe.VERSION, version_name=probe.VERSION_NAME, certificate=probe.CERTIFICATE,
                x86_sha256=probe.APK_SHA, workflow_run=RUN, original_result_sha256=RESULT_SHA)

    def test_different_stale_historical_or_incomplete_reference_result_is_rejected(self):
        original, extra = inputs()
        changes = (("status", "DIAGNOSTIC_ONLY"), ("version", True), ("mode", "current-build"),
                   ("qa_commit", probe.SOURCE), ("qa_workflow_run", probe.SOURCE_RUN), ("qa_workflow_run", True),
                   ("source_build_run", RUN), ("apk_source", QA), ("native_source", QA),
                   ("candidate", {}), ("installed", {}), ("probe_sha256", "0" * 64),
                   ("reference_probe_sha256", "0" * 64), ("historical_tour_pass_used", True),
                   ("private_app_data_written_by_probe", True), ("apk_rebuilt_by_probe", True),
                   ("fullModernizationComplete", True), ("previous_complete_probe", {}),
                   ("banana", {}), ("pattern", {}), ("device", {}))
        for field, value in changes:
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify(original, {**extra, field: value})

    def test_native_why_performance_and_original_probe_hash_remain_required(self):
        original, extra = inputs()
        for field, value in (("status", "FAIL"), ("candidate", {}), ("installed", {}),
                             ("probe_sha256", "0" * 64), ("native_learning", {})):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify({**original, field: value}, extra)
        for block, field, value in (("why_question", "observed_final_moved", 0),
                    ("why_question", "manual_move_buttons_pressed_after_question", True),
                    ("why_question", "response", {"text": "Okay. Ich passe die Aufgabe an dich an."}),
                    ("why_question", "playback", {}), ("performance", "capture_status", "UNMEASURED"),
                    ("performance", "combined_audio_figure_effect_windows", []),
                    ("performance", "current_step_replay_playback", {}), ("performance", "video", {})):
            changed = copy.deepcopy(original)
            changed["native_learning"][block][field] = value
            with self.subTest(block=block, field=field), self.assertRaises(RuntimeError):
                self.verify(changed, extra)

    def test_reference_reset_stays_bound_to_real_original_profile_device_and_hash(self):
        original, extra = inputs()
        for field, value in (("original_result_sha256", "0" * 64), ("original_run_id", "old"),
                             ("original_status", "FAIL"), ("installed_before_reset", {}),
                             ("synthetic_profile_before_reset", {})):
            changed = copy.deepcopy(extra)
            changed["previous_complete_probe"][field] = value
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify(original, changed)
        with self.assertRaises(RuntimeError):
            self.verify(original, {**extra, "device": {**extra["device"], "serial": "other"}})

    def test_banana_segments_and_ungraded_pattern_return_remain_required(self):
        original, extra = inputs()
        for block, field, value in (("banana", "steps", []), ("banana", "repeat_playback", {}),
                    ("banana", "repeat_video", {}), ("banana", "native_answer_submitted", True),
                    ("banana", "preservation", {}), ("pattern", "returned_task", {}),
                    ("pattern", "native_confirmation_performed", True), ("pattern", "hint_playback", {}),
                    ("pattern", "observed_group_hint", ""), ("pattern", "preservation", {}),
                    ("pattern", "core_answer_submitted", True)):
            changed = copy.deepcopy(extra)
            changed[block][field] = value
            with self.subTest(block=block, field=field), self.assertRaises(RuntimeError):
                self.verify(original, changed)

    def test_reference_subclass_keeps_current_original_guard(self):
        original, _ = inputs()
        instance = probe.ReplayProbe.__new__(probe.ReplayProbe)
        instance.verify_previous_result(original, identity())
        original["native_learning"]["why_question"] = {}
        with self.assertRaises(RuntimeError):
            instance.verify_previous_result(original, identity())

    def test_replay_reads_the_actual_wrapped_pattern_frame_without_changing_identity_gates(self):
        with tempfile.TemporaryDirectory() as temporary, wrapped.original_frame_transport() as (captures, reads):
            instance = object.__new__(probe.ReplayProbe)
            instance.out, instance.counter, instance.reader = Path(temporary), 0, wrapped.historical
            instance.native_see(wrapped.QUESTION, "pattern-native-question")
            self.assertEqual((len(captures), len(reads)), (1, 1))
            evidence = json.loads(next(instance.out.glob("*-wrapped-read.json")).read_text())
            self.assertEqual(evidence["status"], "READ")
            self.assertEqual(evidence["label"], wrapped.QUESTION)
            self.assertFalse(evidence["input_issued"])
            frame = evidence["frames"][0]
            self.assertEqual(frame["source_sha256"], probe.digest(wrapped.FRAME))
            self.assertEqual(len(frame["match"]["rows"]), 2)
            self.assertTrue(all(row["variant"] == frame["match"]["variant"]
                                for row in frame["match"]["rows"]))


class WrapperProcessTest(unittest.TestCase):
    def test_first_failure_stops_second_failure_propagates_and_both_pass(self):
        wrapper = ROOT / ".github/probes/run_lumo_nextgen_2031_replay_android.sh"
        syntax = subprocess.run(["bash", "-n", str(wrapper)], capture_output=True, text=True)
        self.assertEqual(syntax.returncode, 0, syntax.stderr)
        for first, second in ((9, 0), (0, 8), (0, 0)):
            with self.subTest(first=first, second=second), tempfile.TemporaryDirectory() as temporary:
                root = Path(temporary)
                executable = root / ".probe-venv/bin/python"
                executable.parent.mkdir(parents=True)
                executable.write_text("#!/usr/bin/env python3\nimport json,os,sys\n"
                    "with open(os.environ['PROBE_CALLS'],'a') as f: f.write(json.dumps(sys.argv[1:])+'\\n')\n"
                    "first=sys.argv[1].endswith('lumo_nextgen_learning_android_probe.py')\n"
                    "sys.exit(int(os.environ['FIRST' if first else 'SECOND']))\n")
                executable.chmod(0o755)
                calls = root / "calls.jsonl"
                environment = {**os.environ, "PROBE_CALLS": str(calls), "FIRST": str(first), "SECOND": str(second),
                    "LUMO_EXPECTED_SHA256": probe.APK_SHA, "LUMO_EXPECTED_SOURCE": probe.SOURCE,
                    "LUMO_EXPECTED_NATIVE": probe.NATIVE, "LUMO_EXPECTED_VERSION": str(probe.VERSION),
                    "LUMO_CERTIFICATE": probe.CERTIFICATE, "GITHUB_SHA": QA, "GITHUB_RUN_ID": str(RUN)}
                result = subprocess.run(["sh", "-c", 'bash "$1"', "runner", str(wrapper)], cwd=root,
                                        env=environment, capture_output=True, text=True)
                self.assertEqual(result.returncode, first or second, result.stderr)
                rows = [json.loads(line) for line in calls.read_text().splitlines()]
                self.assertEqual(len(rows), 1 if first else 2)
                self.assertEqual(rows[0][rows[0].index("--expected-source") + 1], probe.SOURCE)
                self.assertEqual(rows[0][rows[0].index("--expected-version") + 1], "2031")
                if not first:
                    self.assertEqual(rows[1][0], ".github/probes/lumo_nextgen_2031_replay_reference_android_probe.py")
                    self.assertEqual(rows[1][1], "run")
                    self.assertEqual(rows[1][rows[1].index("--qa-commit") + 1], QA)
                    self.assertEqual(rows[1][rows[1].index("--workflow-run-id") + 1], str(RUN))
                    self.assertIn("evidence/android/original-android", rows[1])


if __name__ == "__main__":
    unittest.main()
