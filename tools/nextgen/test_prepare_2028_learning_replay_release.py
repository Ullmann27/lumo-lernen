"""Strict publication metadata checks; fixtures are not Android observations."""
from __future__ import annotations

import copy
import importlib.util
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("publication_2028_test",
    Path(__file__).with_name("prepare_2028_learning_replay_release.py"))
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


class ImmutablePublicationTest(unittest.TestCase):
    def setUp(self):
        self.qa, self.run = "f" * 40, 123456
        self.config = {"schemaVersion": 1, "apkSourceCommit": release.SOURCE,
            "qaCommit": self.qa, "qaRun": self.run,
            "qaArtifact": {"id": 123, "name": release.REPLAY_ARTIFACT_NAME,
                           "size_in_bytes": 321, "digest": "sha256:" + "d" * 64}}
        self.source_run = {"id": release.SOURCE_RUN, "head_sha": release.SOURCE,
            "path": ".github/workflows/lumo-nextgen-learning-apk.yml", "status": "completed", "conclusion": "failure"}
        self.jobs = {number: {"id": number, "run_id": release.SOURCE_RUN, "name": name,
                             "status": "completed", "conclusion": outcome}
            for number, name, outcome in ((release.VALIDATION_JOB, "validate", "success"),
                (release.BUILD_JOB, "build", "success"), (release.ORIGINAL_ANDROID_JOB, "android", "failure"))}
        self.qa_run = {"id": self.run, "head_sha": self.qa, "head_branch": release.REPLAY_BRANCH,
            "path": release.REPLAY_WORKFLOW, "status": "completed", "conclusion": "success"}
        self.arm64 = {"sha256": release.ARM64_SHA, "flutter_source_commit": release.SOURCE,
            "tracked_source_clean": True, "godot": {"revision": release.NATIVE, "pck_sha256": release.PCK_SHA},
            "package": release.PACKAGE, "signingCertificateSha256": release.CERTIFICATE,
            "abis": ["arm64-v8a"], "versionName": release.VERSION_NAME, "versionCode": release.VERSION}
        self.x86 = {"sha256": release.X86_SHA, "godot": {"pck_sha256": release.PCK_SHA}}

    def test_qa_identity_cannot_be_substituted_for_apk_source_or_build_run(self):
        self.assertEqual(release.verify_config(self.config)[:2], (self.qa, self.run))
        for field, value in (("schemaVersion", 2), ("schemaVersion", True), ("apkSourceCommit", self.qa),
                              ("qaCommit", release.SOURCE), ("qaCommit", "not-a-commit"),
                              ("qaRun", release.SOURCE_RUN), ("qaRun", True), ("qaRun", -1)):
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                release.verify_config({**self.config, field: value})

    def test_artifact_requires_exact_downloadable_metadata(self):
        for field, value in (("id", True), ("id", -1), ("name", "historical-replay"),
                            ("size_in_bytes", 0), ("size_in_bytes", True),
                            ("size_in_bytes", 2500000000), ("digest", "sha256:unknown")):
            config = copy.deepcopy(self.config)
            config["qaArtifact"][field] = value
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                release.verify_config(config)

    def test_original_failed_run_is_preserved_and_build_jobs_must_have_passed(self):
        release.verify_source_run(self.source_run, self.jobs)
        for field, value in (("id", self.run), ("head_sha", self.qa), ("path", release.REPLAY_WORKFLOW),
                            ("status", "in_progress"), ("conclusion", "success")):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                release.verify_source_run({**self.source_run, field: value}, self.jobs)
        for number in self.jobs:
            for field, value in (("id", 1), ("run_id", self.run), ("name", "other"),
                                ("status", "queued"), ("conclusion", "skipped")):
                jobs = copy.deepcopy(self.jobs)
                jobs[number][field] = value
                with self.subTest(number=number, field=field), self.assertRaises(RuntimeError):
                    release.verify_source_run(self.source_run, jobs)

    def test_only_the_exact_successful_replay_can_publish(self):
        release.verify_qa_run(self.qa_run, self.qa, self.run)
        for field, value in (("id", release.SOURCE_RUN), ("head_sha", release.SOURCE),
                            ("head_branch", "main"), ("path", release.PUBLICATION_WORKFLOW),
                            ("status", "in_progress"), ("conclusion", "failure"), ("conclusion", "skipped")):
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                release.verify_qa_run({**self.qa_run, field: value}, self.qa, self.run)

    def verify_arm64(self, proof=None, **changes):
        values = {"actual_sha256": release.ARM64_SHA, "actual_bytes": release.ARM64_BYTES,
                  "x86_candidate": self.x86, **changes}
        return release.verify_arm64(self.arm64 if proof is None else proof, **values)

    def test_original_arm64_hash_source_certificate_version_and_pack_are_required(self):
        self.verify_arm64()
        for field, value in (("sha256", "0" * 64), ("flutter_source_commit", self.qa),
                            ("tracked_source_clean", False), ("godot", {}), ("package", "other"),
                            ("signingCertificateSha256", "1" * 64), ("abis", ["x86_64"]),
                            ("versionName", "0.13.15"), ("versionCode", 2027), ("versionCode", True)):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                self.verify_arm64({**self.arm64, field: value})
        for kwargs in ({"actual_sha256": "2" * 64}, {"actual_bytes": release.ARM64_BYTES - 1},
                       {"x86_candidate": {**self.x86, "sha256": "3" * 64}},
                       {"x86_candidate": {**self.x86, "godot": {"pck_sha256": "4" * 64}}}):
            with self.subTest(kwargs=kwargs), self.assertRaises(RuntimeError):
                self.verify_arm64(**kwargs)

    def test_gates_cannot_change_between_replay_and_publication(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "gate.py").write_bytes(b"exact tested source\n")
            with patch.object(release, "ROOT", root), patch.object(release, "QA_BOUND_FILES", ("gate.py",)), \
                    patch.object(release.subprocess, "check_output", return_value=b"exact tested source\n"):
                self.assertTrue(release.verify_publisher_sources(self.qa)[0]["identicalToQaCommit"])
                (root / "gate.py").write_bytes(b"changed acceptance after the run\n")
                with self.assertRaisesRegex(RuntimeError, "differ from the tested QA"):
                    release.verify_publisher_sources(self.qa)

    def test_only_an_observed_404_allows_a_new_release_and_tag(self):
        with patch.object(release.subprocess, "run", return_value=SimpleNamespace(
                returncode=1, stdout='HTTP/2.0 404 Not Found\r\n\r\n{"message":"Not Found"}')):
            release.require_absent_github_resource("releases/tags/test")
        for code, output in ((0, "HTTP/2.0 200 OK\n"), (1, "HTTP/2.0 403 Forbidden\n"),
                             (1, "HTTP/2.0 500 Server Error\n"), (1, "network failed"),
                             (0, "HTTP/2.0 404 Not Found\n")):
            with self.subTest(code=code, output=output), patch.object(release.subprocess, "run",
                    return_value=SimpleNamespace(returncode=code, stdout=output)), self.assertRaises(RuntimeError):
                release.require_absent_github_resource("git/ref/tags/test")


if __name__ == "__main__":
    unittest.main()
