from __future__ import annotations
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("additional", ROOT / "verify_additional_acceptance.py")
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
ORIGINALS = {
    name: {kind: json.loads((ROOT / "original-metadata" / f"{name}-{kind}.json").read_text())
           for kind in ("run", "jobs", "artifacts")}
    for name in ("native", "feature")
}

def verify(name, payload):
    return gate.verify_payloads(gate.BINDINGS[name], payload["run"], payload["jobs"], payload["artifacts"])

class AdditionalAcceptanceTests(unittest.TestCase):
    def test_original_native_metadata(self):
        result = verify("native", ORIGINALS["native"])
        self.assertEqual(result["source"], gate.BINDINGS["native"]["source"])

    def test_original_feature_metadata(self):
        result = verify("feature", ORIGINALS["feature"])
        self.assertEqual(result["source"], gate.BINDINGS["feature"]["source"])

    def test_original_feature_cannot_replace_native(self):
        with self.assertRaises(ValueError):
            verify("native", ORIGINALS["feature"])

    def test_original_native_cannot_replace_feature(self):
        with self.assertRaises(ValueError):
            verify("feature", ORIGINALS["native"])

    def test_duplicate_metadata_key_is_rejected(self):
        with tempfile.TemporaryDirectory(prefix="lumo-publication-json-") as directory:
            path = Path(directory) / "run.json"
            path.write_text('{"conclusion":"failure","conclusion":"success"}')
            with self.assertRaisesRegex(ValueError, "Duplicate metadata key"):
                gate.read_json(path)

    def test_missing_job_even_with_consistent_empty_count_is_rejected(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        payload["jobs"] = {"total_count": 0, "jobs": []}
        with self.assertRaises(ValueError):
            verify("feature", payload)

    def test_added_job_even_with_consistent_count_is_rejected(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        payload["jobs"]["jobs"].append(copy.deepcopy(payload["jobs"]["jobs"][0]))
        payload["jobs"]["total_count"] = 2
        with self.assertRaises(ValueError):
            verify("feature", payload)

    def test_missing_artifact_even_with_consistent_empty_count_is_rejected(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        payload["artifacts"] = {"total_count": 0, "artifacts": []}
        with self.assertRaises(ValueError):
            verify("feature", payload)

    def test_extra_artifact_even_with_consistent_count_is_rejected(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        payload["artifacts"]["artifacts"].append(copy.deepcopy(payload["artifacts"]["artifacts"][0]))
        payload["artifacts"]["total_count"] = 2
        with self.assertRaises(ValueError):
            verify("feature", payload)

    def test_omitted_mandatory_step_is_rejected(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        del payload["jobs"]["jobs"][0]["steps"][7]
        with self.assertRaises(ValueError):
            verify("feature", payload)

    def test_duplicate_step_cannot_replace_mandatory_original(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        steps = payload["jobs"]["jobs"][0]["steps"]
        steps[7] = copy.deepcopy(steps[6])
        with self.assertRaises(ValueError):
            verify("feature", payload)

MUTATIONS = [
    ("foreign_run", ("run", "id"), 1),
    ("rerun_attempt", ("run", "run_attempt"), 2),
    ("boolean_attempt", ("run", "run_attempt"), True),
    ("stale_host", ("run", "head_sha"), "93bd9b7804e2c352303d58552cc48e0a89a1c3cb"),
    ("foreign_branch", ("run", "head_branch"), "main"),
    ("foreign_event", ("run", "event"), "pull_request"),
    ("different_workflow", ("run", "path"), ".github/workflows/unreviewed.yml"),
    ("nonterminal_run", ("run", "status"), "in_progress"),
    ("failed_run", ("run", "conclusion"), "failure"),
    ("skipped_run", ("run", "conclusion"), "skipped"),
    ("foreign_repository_id", ("run", "repository", "id"), 1),
    ("foreign_repository_name", ("run", "repository", "full_name"), "foreign/lumo-lernen"),
    ("foreign_head_repository", ("run", "head_repository", "full_name"), "foreign/lumo-lernen"),
    ("foreign_head_repository_id", ("run", "head_repository", "id"), 1),
    ("truncated_job_page", ("jobs", "total_count"), 2),
    ("foreign_job_id", ("jobs", "jobs", 0, "id"), 1),
    ("foreign_job_run", ("jobs", "jobs", 0, "run_id"), 1),
    ("job_rerun", ("jobs", "jobs", 0, "run_attempt"), 2),
    ("foreign_job_source", ("jobs", "jobs", 0, "head_sha"), "0" * 40),
    ("foreign_job_name", ("jobs", "jobs", 0, "name"), "unreviewed-job"),
    ("nonterminal_job", ("jobs", "jobs", 0, "status"), "in_progress"),
    ("failed_job", ("jobs", "jobs", 0, "conclusion"), "failure"),
    ("skipped_job", ("jobs", "jobs", 0, "conclusion"), "skipped"),
    ("renamed_step", ("jobs", "jobs", 0, "steps", 7, "name"), "Unreviewed replacement"),
    ("renumbered_step", ("jobs", "jobs", 0, "steps", 7, "number"), 99),
    ("nonterminal_step", ("jobs", "jobs", 0, "steps", 7, "status"), "in_progress"),
    ("failed_step", ("jobs", "jobs", 0, "steps", 7, "conclusion"), "failure"),
    ("skipped_step", ("jobs", "jobs", 0, "steps", 7, "conclusion"), "skipped"),
    ("truncated_artifact_page", ("artifacts", "total_count"), 2),
    ("different_artifact_id", ("artifacts", "artifacts", 0, "id"), 1),
    ("renamed_artifact", ("artifacts", "artifacts", 0, "name"), "unreviewed.zip"),
    ("changed_artifact_size", ("artifacts", "artifacts", 0, "size_in_bytes"), 1),
    ("changed_artifact_digest", ("artifacts", "artifacts", 0, "digest"), "sha256:" + "0" * 64),
    ("expired_artifact", ("artifacts", "artifacts", 0, "expired"), True),
    ("numeric_expiration_is_not_boolean", ("artifacts", "artifacts", 0, "expired"), 0),
    ("foreign_artifact_run", ("artifacts", "artifacts", 0, "workflow_run", "id"), 1),
    ("stale_artifact_source", ("artifacts", "artifacts", 0, "workflow_run", "head_sha"), "0" * 40),
    ("foreign_artifact_branch", ("artifacts", "artifacts", 0, "workflow_run", "head_branch"), "main"),
    ("foreign_artifact_repository", ("artifacts", "artifacts", 0, "workflow_run", "repository_id"), 1),
    ("foreign_artifact_head_repository", ("artifacts", "artifacts", 0, "workflow_run", "head_repository_id"), 1),
]

def rejection_case(path, value):
    def test(self):
        payload = copy.deepcopy(ORIGINALS["feature"])
        target = payload
        for key in path[:-1]:
            target = target[key]
        target[path[-1]] = value
        with self.assertRaises(ValueError):
            verify("feature", payload)
    return test

for name, path, value in MUTATIONS:
    setattr(AdditionalAcceptanceTests, "test_reject_" + name, rejection_case(path, value))

if __name__ == "__main__":
    unittest.main()
