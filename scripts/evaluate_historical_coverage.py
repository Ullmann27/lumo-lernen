#!/usr/bin/env python3
"""Analyze the historical audit CSV without pretending that missing paths equal missing features."""
import csv
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

def category(path):
    p = path.lower()
    parts = p.split("/")
    name = parts[-1]
    suffix = Path(name).suffix
    if any(x in parts for x in ("evidence", "proof", "captures", "screenshots", "test-results", "build-proof", ".ci-results")):
        return "evidence"
    if p.startswith(("test/", "tests/", "scripts/tests/", "tools/android_qa/tests/", "integration_test/")) or "/tests/" in p or name.endswith("_test.dart"):
        return "tests"
    if p.startswith(("docs/", ".github/")) or suffix in (".md", ".rst"):
        return "documentation_or_ci"
    if p.startswith(("art/", "tools/")) or suffix in (".blend", ".blend1", ".psd"):
        return "production_source_or_tools"
    if suffix in (".uid", ".import"):
        return "import_metadata"
    if p.startswith(("assets/", "res/")) and suffix in (".glb", ".gltf", ".png", ".jpg", ".jpeg", ".webp", ".svg", ".ogg", ".wav", ".mp3", ".m4a", ".ttf", ".otf", ".tres", ".res", ".gdshader", ".gdshaderinc", ".json"):
        return "runtime_asset_candidate"
    if p.startswith(("lib/", "scripts/", "scenes/", "android/", "server/")) and suffix in (".dart", ".gd", ".tscn", ".kt", ".java", ".js", ".ts", ".gdshader", ".gdshaderinc", ".tres"):
        return "runtime_code_candidate"
    return "other_review"

def analyze(root):
    path_rows = defaultdict(set)
    counts = Counter()
    branches = defaultdict(set)
    grouped = defaultdict(set)
    examples = defaultdict(dict)
    with (root / "unmatched-files.csv").open(encoding="utf-8", newline="") as stream:
        for row in csv.DictReader(stream):
            path = row["path"]
            status = row["status"]
            kind = category(path)
            oid = row["historical_oid"]
            path_rows[(status, kind)].add(path)
            counts[(status, kind)] += 1
            grouped[(status, kind)].add((path, oid))
            if kind.startswith("runtime_"):
                for branch in json.loads(row["branch_aliases"]):
                    branches[branch].add((status, path))
                if status == "historical_path_absent":
                    examples[kind].setdefault(path, row["tip"])
    print("LUMO_CATEGORY_SUMMARY " + json.dumps([
        {"status": status, "category": kind, "observations": n,
         "distinct_paths": len(path_rows[(status,kind)]),
         "distinct_path_blob_pairs": len(grouped[(status,kind)])}
        for (status,kind),n in sorted(counts.items())], ensure_ascii=False))
    # Same path may be absent in one historical comparison, modified in another;
    # counts below deduplicate only within the stated status and category.
    print("LUMO_RUNTIME_BRANCHES " + json.dumps(
        [{"branch": branch, "distinct_runtime_path_statuses": len(paths)}
         for branch,paths in sorted(branches.items(), key=lambda pair: (-len(pair[1]),pair[0]))[:35]],
        ensure_ascii=False))
    for kind,paths in sorted(examples.items()):
        # Prefer application source over test/evidence names; samples are leads,
        # not a claim that a runtime feature is absent.
        sorted_paths = sorted(paths.items(), key=lambda item: (item[0].count("/"),item[0]))
        print("LUMO_RUNTIME_ABSENT_EXAMPLES " + json.dumps(
            {"category": kind,"distinct_paths":len(paths),
             "examples":[{"path": p, "historical_tip":t} for p,t in sorted_paths[:60]]},
            ensure_ascii=False))
    summary = json.loads((root / "summary.json").read_text(encoding="utf-8"))
    print("LUMO_AUDIT_SOURCE " + json.dumps(summary, ensure_ascii=False))

if __name__ == "__main__":
    for directory in sys.argv[1:]:
        print("LUMO_REPOSITORY " + directory)
        analyze(Path(directory))
