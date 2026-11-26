#!/usr/bin/env python3
"""Read-only historical branch coverage audit. Blob identity is evidence of
source presence, not of UI reachability, semantic equivalence or runtime QA.
Never checks out or executes historical branch code; never merges or deletes.
"""
import argparse
import csv
import json
import pathlib
import subprocess
from collections import Counter, defaultdict

def git(repo, *args):
    return subprocess.check_output(
        ["git", "-C", str(repo), *args], stderr=subprocess.PIPE
    )

def tree(repo, ref):
    result = {}
    for record in git(repo, "ls-tree", "-r", "-z", ref).split(b"\0"):
        if not record:
            continue
        metadata, path = record.split(b"\t", 1)
        mode, kind, oid = metadata.decode("ascii").split()
        result[path] = (mode, oid)
    return result

def changes(repo, base, tip):
    data = git(repo, "diff", "--raw", "--no-abbrev", "--no-renames",
               "--no-ext-diff", "-z", base, tip).split(b"\0")
    for i in range(0, len(data)-1, 2):
        if not data[i]:
            continue
        oldmode, newmode, oldoid, newoid, status = data[i][1:].decode("ascii").split()
        yield data[i+1], status, (newmode, newoid)

def audit(repo, candidate, output):
    candidate = git(repo, "rev-parse", candidate + "^{commit}").decode().strip()
    target = tree(repo, candidate)
    tips = defaultdict(list)
    for line in git(repo, "for-each-ref", "--format=%(objectname) %(refname)",
                    "refs/remotes/origin").decode().splitlines():
        sha, ref = line.split(" ", 1)
        if ref != "refs/remotes/origin/HEAD":
            tips[sha].append(ref.removeprefix("refs/remotes/origin/"))
    output.mkdir(parents=True, exist_ok=True)
    counts = Counter()
    classifications = Counter()
    errors = []
    with (output/"branches.jsonl").open("w", encoding="utf-8") as branches, \
         (output/"unmatched-files.csv").open("w", encoding="utf-8", newline="") as files:
        writer = csv.writer(files)
        writer.writerow(["tip", "merge_base", "branch_aliases", "status",
                         "path", "historical_mode", "historical_oid",
                         "candidate_mode", "candidate_oid"])
        for tip, aliases in sorted(tips.items(), key=lambda item: item[1][0]):
            row = {"tip": tip, "branches": aliases, "counts": {}}
            try:
                ancestry = subprocess.run(
                    ["git", "-C", str(repo), "merge-base", "--is-ancestor", tip, candidate],
                    stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                if ancestry.returncode == 0:
                    row["classification"] = "ancestor"
                elif ancestry.returncode == 1:
                    base = git(repo, "merge-base", candidate, tip).decode().strip()
                    row["merge_base"] = base
                    local = Counter()
                    for path, status, historical in changes(repo, base, tip):
                        present = target.get(path)
                        if status.startswith("D"):
                            label = "same_deletion" if present is None else "historical_deletion_not_applied"
                        elif historical == present:
                            label = "identical_blob"
                        elif present is None:
                            label = "historical_path_absent"
                        else:
                            label = "different_blob_review"
                        local[label] += 1
                        if label not in ("same_deletion", "identical_blob"):
                            writer.writerow([tip, base, json.dumps(aliases, ensure_ascii=False),
                                             label, path.decode("utf-8", "backslashreplace"),
                                             *historical, *(present or ("", ""))])
                    counts.update(local)
                    row["counts"] = dict(local)
                    row["classification"] = (
                        "review_needed" if any(local[x] for x in
                            ("historical_deletion_not_applied", "historical_path_absent",
                             "different_blob_review")) else "tip_changes_present")
                else:
                    raise RuntimeError(ancestry.stderr.decode(errors="replace"))
            except (subprocess.CalledProcessError, RuntimeError, ValueError) as exc:
                row["classification"] = "audit_error"
                row["error"] = str(exc)
                errors.append(tip)
            classifications[row["classification"]] += len(aliases)
            branches.write(json.dumps(row, ensure_ascii=False)+"\n")
    summary = {"candidate": candidate, "branch_count": sum(map(len, tips.values())),
               "distinct_tip_count": len(tips), "branch_classifications": dict(classifications),
               "changed_path_classifications": dict(counts), "errors": errors,
               "scope": "Remote branch tips only; equivalent rewrites and runtime wiring require review. Deleted remote branches and private archives are outside this scan."}
    (output/"summary.json").write_text(json.dumps(summary, indent=2)+"\n")
    print(json.dumps(summary, indent=2))
    return not errors

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("repo", type=pathlib.Path)
    parser.add_argument("candidate")
    parser.add_argument("output", type=pathlib.Path)
    args = parser.parse_args()
    raise SystemExit(0 if audit(args.repo, args.candidate, args.output) else 1)

if __name__ == "__main__":
    main()
