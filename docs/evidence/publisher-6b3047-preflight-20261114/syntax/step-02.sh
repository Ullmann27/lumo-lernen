set -euo pipefail
mkdir -p publication
cat > publication/verify-additional-acceptance.py <<'PY'
#!/usr/bin/env python3
"""Revalidate exact additional gates against reviewed immutable run bindings.

This verifies fresh GitHub metadata for the original Native and Feature artifacts.
It does not rerun a game, Flutter, or an image reader.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess

BINDINGS = json.loads("{\"native\":{\"repository\":\"Ullmann27/lumo-godot\",\"repository_id\":1251414584,\"run\":43613299144,\"attempt\":1,\"source\":\"84789d0c2c6fb4b6ecd2897ce1951b89f958b604\",\"branch\":\"integration/lumo-live-connections-20261114\",\"event\":\"push\",\"workflow\":\".github/workflows/lumo-discovery-connections.yml\",\"job_id\":132502826135,\"job_name\":\"discovery-native-acceptance\",\"steps\":[{\"number\":1,\"name\":\"Set up job\"},{\"number\":2,\"name\":\"Check out the exact internal Discovery push\"},{\"number\":3,\"name\":\"Bind the original source and external evidence directories\"},{\"number\":4,\"name\":\"Install the verified engine and external Pillow environment\"},{\"number\":5,\"name\":\"Bind the unchanged helpers before any import or test\"},{\"number\":6,\"name\":\"Require the separate Dream raster counterexamples\"},{\"number\":7,\"name\":\"Require the strict Discovery counterexamples and original reader tests\"},{\"number\":8,\"name\":\"Import the exact production project with a strict error guard\"},{\"number\":9,\"name\":\"Preserve the four existing exact headless acceptance gates\"},{\"number\":10,\"name\":\"Collect all five new Dream gates and seven original renderer images\"},{\"number\":11,\"name\":\"Require ten source-bound Discovery probes and all original 38 PNGs and two reports\"},{\"number\":12,\"name\":\"Require exact village save schema and bounded original renderer evidence\"},{\"number\":13,\"name\":\"Render the exact MobileSafeArea and live minimap observations\"},{\"number\":14,\"name\":\"Always preserve final source and index identities\"},{\"number\":15,\"name\":\"Preserve all separate Discovery and Dream originals even after failure\"},{\"number\":30,\"name\":\"Post Check out the exact internal Discovery push\"},{\"number\":31,\"name\":\"Complete job\"}],\"artifact\":{\"id\":14122180486,\"name\":\"lumo-discovery-connections-native-evidence-43613299144-1\",\"bytes\":66954397,\"digest\":\"sha256:af8a7b6f08d59f52dd25c2b061b4119b369f3793845132bb39ef9fca6b0446f0\"}},\"feature\":{\"repository\":\"Ullmann27/lumo-lernen\",\"repository_id\":1222433959,\"run\":43616035099,\"attempt\":1,\"source\":\"6b3047b7979dfb86d837e74a21b0fd890e4f9e66\",\"branch\":\"integration/lumo-live-connections-20261114\",\"event\":\"push\",\"workflow\":\".github/workflows/lumo-feature-connections.yml\",\"job_id\":132511176199,\"job_name\":\"feature-widget-contracts\",\"steps\":[{\"number\":1,\"name\":\"Set up job\"},{\"number\":2,\"name\":\"Checkout the exact feature push\"},{\"number\":3,\"name\":\"Bind original source and lock bytes before setup\"},{\"number\":4,\"name\":\"Install the repository Flutter version\"},{\"number\":5,\"name\":\"Prepare fonts, Pillow and the immutable locked packages\"},{\"number\":6,\"name\":\"Bind the six original test assets\"},{\"number\":7,\"name\":\"Execute exactly the 30 feature cases\"},{\"number\":8,\"name\":\"Require completed tests, zero skips and the exact case count\"},{\"number\":9,\"name\":\"Require identical source and lock bytes after the attempt\"},{\"number\":10,\"name\":\"Preserve complete original logs and source stamps\"},{\"number\":19,\"name\":\"Post Install the repository Flutter version\"},{\"number\":20,\"name\":\"Post Checkout the exact feature push\"},{\"number\":21,\"name\":\"Complete job\"}],\"artifact\":{\"id\":14122252221,\"name\":\"lumo-feature-connections-6b3047b7979dfb86d837e74a21b0fd890e4f9e66-attempt-1\",\"bytes\":1167242,\"digest\":\"sha256:aa3acbb92e89b5e8c3723d35ffb0ea8e07f6405b8dbe7821a6a3ce9b085b9075\"}}}")

def equal(actual, expected, label):
    if type(actual) is not type(expected) or actual != expected:
        raise ValueError(f"{label}: observed value differs from the reviewed binding")

def object_value(value, label):
    if type(value) is not dict:
        raise ValueError(f"{label}: expected a JSON object")
    return value

def catalog(value, key, label):
    value = object_value(value, label)
    rows = value.get(key)
    if type(rows) is not list:
        raise ValueError(f"{label}: expected a complete list")
    equal(value.get("total_count"), len(rows), label + " complete count")
    equal(len(rows), 1, label + " exact one original")
    return object_value(rows[0], label + " original")

def unique_json(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate metadata key: {key}")
        result[key] = value
    return result

def read_json(path):
    return json.loads(path.read_bytes(), object_pairs_hook=unique_json)

def verify_payloads(binding, run, jobs, artifacts):
    run = object_value(run, "run")
    fields = {
        "id": binding["run"], "run_attempt": binding["attempt"],
        "head_sha": binding["source"], "head_branch": binding["branch"],
        "event": binding["event"], "path": binding["workflow"],
        "status": "completed", "conclusion": "success",
    }
    for key, expected in fields.items():
        equal(run.get(key), expected, "run." + key)
    for key in ("repository", "head_repository"):
        repository = object_value(run.get(key), key)
        equal(repository.get("id"), binding["repository_id"], key + ".id")
        equal(repository.get("full_name"), binding["repository"], key + ".full_name")

    job = catalog(jobs, "jobs", "jobs")
    fields = {
        "id": binding["job_id"], "run_id": binding["run"],
        "run_attempt": binding["attempt"], "head_sha": binding["source"],
        "name": binding["job_name"], "status": "completed", "conclusion": "success",
    }
    for key, expected in fields.items():
        equal(job.get(key), expected, "job." + key)
    steps = job.get("steps")
    if type(steps) is not list:
        raise ValueError("job.steps: expected the complete original steps")
    equal(len(steps), len(binding["steps"]), "job.steps exact count")
    for observed, original in zip(steps, binding["steps"], strict=True):
        observed = object_value(observed, "step")
        for key in ("number", "name"):
            equal(observed.get(key), original[key], "step." + key)
        equal(observed.get("status"), "completed", "step.status")
        equal(observed.get("conclusion"), "success", "step.conclusion")

    artifact = catalog(artifacts, "artifacts", "artifacts")
    fields = {
        "id": binding["artifact"]["id"], "name": binding["artifact"]["name"],
        "size_in_bytes": binding["artifact"]["bytes"],
        "digest": binding["artifact"]["digest"], "expired": False,
    }
    for key, expected in fields.items():
        equal(artifact.get(key), expected, "artifact." + key)
    owner = object_value(artifact.get("workflow_run"), "artifact.workflow_run")
    fields = {
        "id": binding["run"], "head_sha": binding["source"],
        "head_branch": binding["branch"], "repository_id": binding["repository_id"],
        "head_repository_id": binding["repository_id"],
    }
    for key, expected in fields.items():
        equal(owner.get(key), expected, "artifact.workflow_run." + key)
    return {
        "repository": binding["repository"], "source": binding["source"],
        "run": binding["run"], "attempt": binding["attempt"],
        "job": binding["job_id"], "artifact": binding["artifact"],
        "all_exact_original_steps_successful": True,
    }

def verify_directory(root):
    receipts, digests = {}, {}
    for name, binding in BINDINGS.items():
        values = []
        for kind in ("run", "jobs", "artifacts"):
            filename = f"{name}-{kind}.json"
            path = root / filename
            values.append(read_json(path))
            digests[filename] = hashlib.sha256(path.read_bytes()).hexdigest()
        receipts[name] = verify_payloads(binding, *values)
    return {
        "schema": 1,
        "status": "FRESH_ADDITIONAL_METADATA_MATCHES_REVIEWED_ORIGINALS",
        "checks": receipts, "metadata_sha256": digests,
        "original_artifacts_replayed_here": False,
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--metadata", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
    equal(source, BINDINGS["feature"]["source"], "checked-out Host source")
    equal(os.environ["SOURCE_SHA"], source, "workflow Host source")
    pin = read_json(Path("config/godot-source.json"))
    equal(pin["revision"], BINDINGS["native"]["source"], "Host Native pin")
    subprocess.run(["git", "diff", "--exit-code", "HEAD", "--"], check=True)
    receipt = verify_directory(args.metadata)
    receipt["host_source"] = source
    receipt["native_source"] = pin["revision"]
    with args.output.open("x", encoding="utf-8") as stream:
        stream.write(json.dumps(receipt, indent=2) + "\n")
    print(receipt["status"])

if __name__ == "__main__":
    main()
PY
mkdir -p publication/additional/before
gh api "repos/Ullmann27/lumo-godot/actions/runs/43613299144" > publication/additional/before/native-run.json
gh api "repos/Ullmann27/lumo-godot/actions/runs/43613299144/jobs?per_page=100" > publication/additional/before/native-jobs.json
gh api "repos/Ullmann27/lumo-godot/actions/runs/43613299144/artifacts?per_page=100" > publication/additional/before/native-artifacts.json
gh api "repos/Ullmann27/lumo-lernen/actions/runs/43616035099" > publication/additional/before/feature-run.json
gh api "repos/Ullmann27/lumo-lernen/actions/runs/43616035099/jobs?per_page=100" > publication/additional/before/feature-jobs.json
gh api "repos/Ullmann27/lumo-lernen/actions/runs/43616035099/artifacts?per_page=100" > publication/additional/before/feature-artifacts.json
python3 publication/verify-additional-acceptance.py --metadata publication/additional/before --output publication/additional/before/verified-metadata.json
