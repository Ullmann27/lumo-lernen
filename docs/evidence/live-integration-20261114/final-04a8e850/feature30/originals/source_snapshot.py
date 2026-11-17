import hashlib, json, os, stat, subprocess, sys
from pathlib import Path

phase = sys.argv[1]
if phase not in ("before", "after"):
    raise SystemExit("Unknown source snapshot phase")
output = Path(os.environ["FEATURE_EVIDENCE_DIR"])
def git(*args):
    return subprocess.check_output(["git", *args])
def sha(data):
    return hashlib.sha256(data).hexdigest()
head = git("rev-parse", "HEAD").decode().strip()
tree = git("rev-parse", "HEAD^{tree}").decode().strip()
index = git("ls-files", "--stage", "-z")
status = git("status", "--porcelain=v1", "--untracked-files=no")
(output / f"git-status-{phase}.txt").write_bytes(status)
(output / f"git-index-{phase}.original").write_bytes(index)
files, errors = [], []
for entry in index.split(b"\0"):
    if not entry:
        continue
    metadata, raw_path = entry.split(b"\t", 1)
    mode, blob, stage = metadata.decode("ascii").split()
    path = Path(os.fsdecode(raw_path))
    try:
        observed = path.lstat()
        if mode == "120000" and stat.S_ISLNK(observed.st_mode):
            data = os.fsencode(os.readlink(path))
        elif mode in ("100644", "100755") and stat.S_ISREG(observed.st_mode):
            data = path.read_bytes()
            expected_executable = mode == "100755"
            if bool(observed.st_mode & 0o111) != expected_executable:
                errors.append(f"Tracked executable mode changed: {path}")
        else:
            raise ValueError("Unexpected tracked file type")
        actual_blob = hashlib.sha1(
            b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
        if stage != "0" or actual_blob != blob:
            errors.append(f"Tracked bytes or stage changed: {path}")
        files.append({"path": str(path), "mode": mode, "blob": blob,
                      "actual_blob": actual_blob, "bytes": len(data),
                      "sha256": sha(data)})
    except (OSError, ValueError) as exc:
        errors.append(f"{path}: {type(exc).__name__}: {exc}")
if head != os.environ["EXPECTED_SOURCE_SHA"]:
    errors.append("Checkout differs from the original push SHA")
if status:
    errors.append("Tracked checkout is not clean")
report = {
    "schema": 1, "phase": phase, "head": head, "tree": tree,
    "expected_source_sha": os.environ["EXPECTED_SOURCE_SHA"],
    "run_id": os.environ["GITHUB_RUN_ID"],
    "run_attempt": os.environ["GITHUB_RUN_ATTEMPT"],
    "ref": os.environ["GITHUB_REF"],
    "workflow": os.environ["GITHUB_WORKFLOW"],
    "index_sha256": sha(index), "files": files, "errors": errors,
}
if phase == "after":
    before = json.loads((output / "source-before.json").read_text())
    for field in ("head", "tree", "index_sha256", "files"):
        if report[field] != before[field]:
            errors.append(f"Before/after source mismatch: {field}")
(output / f"source-{phase}.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"phase": phase, "head": head,
                  "tracked_files": len(files), "errors": errors}))
raise SystemExit(1 if errors else 0)
