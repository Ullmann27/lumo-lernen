#!/usr/bin/env python3
"""Independently recount the unchanged Feature30 Actions artifact; run no tests."""
from __future__ import annotations

import hashlib
import json
from collections import Counter
from pathlib import Path

BASE = Path(__file__).resolve().parent
ORIGINALS = BASE / "originals"
HEAD = "04a8e850d4c198e16ff758df614ce6e53eab4524"
TREE = "80a797c2b547ed72fc496600f7959f6ac4f5f9e6"
RUN_ID = 43628830465
JOB_ID = 132550661600
ARTIFACT_ID = 14126808268


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def identity(path: Path):
    raw = path.read_bytes()
    return {
        "path": str(path.relative_to(BASE)),
        "bytes": len(raw),
        "sha256": hashlib.sha256(raw).hexdigest(),
        "git_blob": hashlib.sha1(
            b"blob " + str(len(raw)).encode() + b"\0" + raw
        ).hexdigest(),
    }


def main():
    run = load(BASE / "metadata/run-original.json")
    jobs = load(BASE / "metadata/jobs-original.json")["jobs"]
    artifacts = load(BASE / "metadata/artifacts-original.json")["artifacts"]
    assert run["id"] == RUN_ID and run["run_attempt"] == 1
    assert run["head_sha"] == HEAD and run["conclusion"] == "success"
    assert run["event"] == "push"
    assert run["path"] == ".github/workflows/lumo-feature-connections.yml"
    assert len(jobs) == 1 and jobs[0]["id"] == JOB_ID
    job = jobs[0]
    assert job["head_sha"] == HEAD and job["conclusion"] == "success"
    assert len(artifacts) == 1 and artifacts[0]["id"] == ARTIFACT_ID
    artifact = artifacts[0]
    assert artifact["workflow_run"]["id"] == RUN_ID
    assert artifact["workflow_run"]["head_sha"] == HEAD
    archive = identity(BASE / f"original-artifact-{ARTIFACT_ID}.zip")
    assert archive["bytes"] == artifact["size_in_bytes"]
    assert "sha256:" + archive["sha256"] == artifact["digest"]

    events = []
    non_events = []
    for lineno, line in enumerate(
        (ORIGINALS / "flutter.stdout.jsonl").read_text(encoding="utf-8").splitlines(), 1
    ):
        if not line.strip():
            non_events.append({"line": lineno, "kind": "blank", "text": line})
            continue
        item = json.loads(line)
        if isinstance(item, list):
            assert item == [{"event": "test.startedProcess", "params": {"vmServiceUri": None}}]
            non_events.append({"line": lineno, "kind": "flutter-process-protocol", "value": item})
            continue
        assert isinstance(item, dict) and isinstance(item.get("type"), str)
        events.append((lineno, item))

    starts = {}
    completions = {}
    for lineno, event in events:
        if event["type"] == "testStart":
            test = event["test"]
            assert test["id"] not in starts
            starts[test["id"]] = {"jsonl_line": lineno, "event": event}
        elif event["type"] == "testDone":
            assert event["testID"] not in completions
            completions[event["testID"]] = {"jsonl_line": lineno, "event": event}
    assert set(starts) == set(completions)
    assert not [event for _, event in events if event["type"] == "error"]
    final = [(lineno, event) for lineno, event in events if event["type"] == "done"]
    assert len(final) == 1 and final[0][1]["success"] is True
    assert events[-1] == final[0]

    cases = []
    hidden = []
    for test_id, result in completions.items():
        done = result["event"]
        start = starts[test_id]
        assert start["jsonl_line"] < result["jsonl_line"]
        assert done["result"] == "success" and done.get("skipped") is False
        case = {
            "test_id": test_id,
            "name": start["event"]["test"]["name"],
            "source_url": start["event"]["test"].get("url"),
            "source_line": start["event"]["test"].get("line"),
            "start_jsonl_line": start["jsonl_line"],
            "done_jsonl_line": result["jsonl_line"],
            "result": done["result"],
            "skipped": done["skipped"],
            "hidden": done["hidden"],
        }
        (hidden if done["hidden"] else cases).append(case)
    assert len(cases) == 30
    expected_safari = {
        f"Live safari {answer} answer keeps its delayed continuation bound during {context}"
        for answer in ("correct", "wrong")
        for context in ("word magic", "safari round trip", "unchanged safari", "profile change")
    }
    safari = [case for case in cases if case["name"] in expected_safari]
    assert len(safari) == 8 and {case["name"] for case in safari} == expected_safari
    summary = load(ORIGINALS / "feature-test-summary.json")
    assert summary["status"] == "PASS" and summary["passed"] == len(cases)
    assert summary["expected_cases"] == 30 and summary["source_sha"] == HEAD
    assert summary["failed"] == summary["skipped"] == summary["event_errors"] == []
    assert summary["capture_error_files"] == []
    assert summary["flutter_exit_code"] == 0 and summary["runner_completed_successfully"] is True
    assert summary["non_event_stdout_lines"] == [item["line"] for item in non_events]
    assert load(ORIGINALS / "flutter-result.json")["exit_code"] == 0
    assert load(ORIGINALS / "setup-result.json")["exit_code"] == 0
    assert (ORIGINALS / "flutter.stderr.log").read_bytes() == b""

    before = load(ORIGINALS / "source-before.json")
    after = load(ORIGINALS / "source-after.json")
    differences = sorted(key for key in before.keys() | after.keys() if before.get(key) != after.get(key))
    assert differences == ["phase"]
    for snapshot in (before, after):
        assert snapshot["head"] == snapshot["expected_source_sha"] == HEAD
        assert snapshot["tree"] == TREE
        assert snapshot["run_id"] == str(RUN_ID) and snapshot["run_attempt"] == "1"
        assert snapshot["errors"] == []
        assert all(entry["blob"] == entry["actual_blob"] for entry in snapshot["files"])
    assert len(before["files"]) == 4986
    before_index = (ORIGINALS / "git-index-before.original").read_bytes()
    after_index = (ORIGINALS / "git-index-after.original").read_bytes()
    assert before_index == after_index
    assert hashlib.sha256(before_index).hexdigest() == before["index_sha256"] == after["index_sha256"]
    assert (ORIGINALS / "git-status-before.txt").read_bytes() == b""
    assert (ORIGINALS / "git-status-after.txt").read_bytes() == b""

    report = {
        "schema": 1,
        "kind": "independent-original-jsonl-recount",
        "repository": "Ullmann27/lumo-lernen",
        "source_sha": HEAD, "source_tree": TREE,
        "run_id": RUN_ID, "attempt": 1, "job_id": JOB_ID,
        "artifact_id": ARTIFACT_ID,
        "status": "PASS", "passed": len(cases), "failed": 0, "skipped": 0,
        "safari_delayed_continuation": safari,
        "visible_cases": cases,
        "hidden_loading_events": hidden,
        "event_type_counts": dict(Counter(event["type"] for _, event in events)),
        "non_event_stdout_lines": non_events,
        "terminal_event": {"jsonl_line": final[0][0], **final[0][1]},
        "source_preservation": {
            "tracked_files": len(before["files"]),
            "before_after_differences": differences,
            "all_recorded_blob_ids_match_actual_bytes": True,
            "before_after_file_records_identical": True,
            "index_bytes_identical": True,
            "index_sha256": before["index_sha256"],
            "before_after_git_status_empty": True,
        },
        "archive": archive,
        "original_files": [identity(path) for path in sorted(ORIGINALS.iterdir()) if path.is_file()],
        "metadata_files": [identity(path) for path in sorted((BASE / "metadata").iterdir()) if path.is_file()],
        "limitations": [
            "This recount reads the completed Feature30 Actions originals; it starts no Flutter process.",
            "This focused result is not the complete Flutter suite or Android acceptance.",
            "The archive preserves all original source snapshots and both original Git indexes.",
        ],
    }
    (BASE / "independent-recount.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": report["status"], "passed": len(cases), "failed": 0, "skipped": 0, "safari_cases": len(safari), "source_files": len(before["files"]), "output": str(BASE / "independent-recount.json")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
