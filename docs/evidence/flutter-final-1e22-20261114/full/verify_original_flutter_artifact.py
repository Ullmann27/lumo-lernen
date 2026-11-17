#!/usr/bin/env python3
"""Verify an original current-run Flutter artifact without executing its content."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import struct
import zipfile

p = argparse.ArgumentParser()
p.add_argument("--archive", type=Path, required=True)
p.add_argument("--artifact-metadata", type=Path, required=True)
p.add_argument("--output", type=Path, required=True)
args = p.parse_args()
metadata = json.loads(args.artifact_metadata.read_text())
expected_head = "1e22d2455937e2640d1e44e153d290746f3afe49"
expected_run = 43596913210
assert metadata["workflow_run"]["id"] == expected_run
assert metadata["workflow_run"]["head_sha"] == expected_head
assert metadata["expired"] is False
assert args.archive.stat().st_size == metadata["size_in_bytes"]
with args.archive.open("rb") as stream:
    archive_sha256 = hashlib.file_digest(stream, "sha256").hexdigest()
assert metadata["digest"] == "sha256:" + archive_sha256
args.output.mkdir(parents=True, exist_ok=False)
files = []
pngs = []
raw_summary = None
raw_machine = None
errors = []
names = {}
finished = {}
machine_done = False
error_events = []
done_events = []
text_events = []
critical_patterns = (
    "d1_woerter real registry answer",
    "actual Diktat canvas and duplicate self-ratings",
    "two complete actual Diktat sessions",
    "all allowed cumulative math topics preserve exact selection",
    "Four in a row delayed native refusal",
)
with zipfile.ZipFile(args.archive) as archive:
    infos = archive.infolist()
    summary_names = [i.filename for i in infos if PurePosixPath(i.filename).name == "acceptance-summary.json"]
    machine_names = [i.filename for i in infos if PurePosixPath(i.filename).name == "flutter-machine.jsonl"]
    assert len(summary_names) == len(machine_names) == 1
    prefix = str(PurePosixPath(summary_names[0]).parent)
    prefix = "" if prefix == "." else prefix + "/"
    seen = set()
    for info in infos:
        path = PurePosixPath(info.filename)
        assert path.parts and not path.is_absolute() and ".." not in path.parts
        assert "\\" not in info.filename and info.filename not in seen
        assert not info.flag_bits & 1
        seen.add(info.filename)
        if info.is_dir():
            continue
        assert info.filename.startswith(prefix)
        relative = info.filename[len(prefix):]
        data = archive.read(info)  # ZipFile checks the stored CRC while reading.
        digest = hashlib.sha256(data).hexdigest()
        record = {"path": relative, "bytes": len(data), "sha256": digest}
        files.append(record)
        if relative.endswith(".error.txt"):
            errors.append(relative)
            output = args.output / "original-errors" / relative
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
        if relative == "acceptance-summary.json":
            raw_summary = data
            (args.output / relative).write_bytes(data)
        if relative == "flutter-machine.jsonl":
            raw_machine = data
            (args.output / relative).write_bytes(data)
        if path.suffix.lower() != ".png":
            continue
        assert data[:8] == b"\x89PNG\r\n\x1a\n"
        width, height = struct.unpack(">II", data[16:24])
        assert width > 0 and height > 0
        pngs.append({**record, "width": width, "height": height})
        if relative.startswith(("village/", "home-premium/", "games/")):
            output = args.output / "original-pngs" / relative
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(data)
assert raw_summary is not None and raw_machine is not None
report = json.loads(raw_summary)
for line_number, line in enumerate(raw_machine.decode("utf-8").splitlines(), 1):
    try:
        event = json.loads(line)
    except json.JSONDecodeError:
        continue
    if not isinstance(event, dict):
        continue
    kind = event.get("type")
    if kind == "testStart":
        names[event["test"]["id"]] = event["test"]["name"]
    elif kind == "testDone":
        finished[event["testID"]] = event
    elif kind == "done":
        machine_done = event.get("success") is True
        done_events.append({"line": line_number, "event": event})
    elif kind == "error":
        error_events.append({"line": line_number, "event": event})
    elif kind == "print":
        text_events.append({"line": line_number, "event": event})
failed = [names.get(i, str(i)) for i, e in finished.items() if e.get("result") != "success"]
skipped = [names.get(i, str(i)) for i, e in finished.items() if e.get("skipped") is True]
passed = sum(e.get("result") == "success" and not e.get("skipped") and not e.get("hidden") for e in finished.values())
assert report["passed"] == passed
assert report["failed"] == failed
assert report["skipped"] == skipped
assert report["runner_completed_successfully"] == machine_done
assert report["capture_error_files"] == sorted(errors)
assert report["rendered_png_count"] == len(pngs)
for value in report["capture_png_counts"].values():
    assert value["pngs"] == sum(p["path"].startswith(value["directory"] + "/") for p in pngs)
critical = {}
for pattern in critical_patterns:
    critical[pattern] = [
        {"id": test_id, "name": name, "testDone": finished.get(test_id)}
        for test_id, name in names.items() if pattern in name
    ]
failed_ids = {i for i, e in finished.items() if e.get("result") != "success"}
failure_details = [
    {"line": entry["line"], "test_name": names.get(entry["event"].get("testID")), "event": entry["event"]}
    for entry in error_events + text_events
    if entry["event"].get("testID") in failed_ids or entry in error_events
]
(args.output / "failure-details.json").write_text(json.dumps(failure_details, ensure_ascii=False, indent=2) + "\n")
result = {
    "schema": 1, "repository": "Ullmann27/lumo-lernen",
    "source": expected_head, "source_tree": "7fcc3748f8178bff91176ff27f11f7e86ca165ca",
    "run": expected_run, "attempt": 1, "job": 132454178537,
    "artifact": metadata, "archive_sha256": archive_sha256,
    "archive_bytes": args.archive.stat().st_size, "all_member_crc_verified": True,
    "original_summary": report, "independent_event_counts": {
        "passed": passed, "failed": failed, "skipped": skipped, "done": machine_done,
    },
    "critical_actual_test_events": critical, "done_events": done_events,
    "png_count": len(pngs), "png_files": pngs, "all_files": files,
    "scope": "Original Flutter artifact only; not an Android or release acceptance.",
    "visual_review_completed": False,
}
(args.output / "original-artifact-manifest.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({
    "artifact": metadata["id"], "archive_sha256": archive_sha256,
    "status": report["status"], "passed": passed, "failed": failed,
    "skipped": skipped, "rendered_png_count": len(pngs),
    "critical_actual_test_events": critical,
    "output": str(args.output),
}, ensure_ascii=False, indent=2))
