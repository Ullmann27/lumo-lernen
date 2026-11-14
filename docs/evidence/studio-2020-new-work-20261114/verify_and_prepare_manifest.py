"""Hash-check explicit frozen evidence lists; reference originals without copying.

This command performs no Git operation, no test execution and no recursive
discovery. It preserves original report bytes and maps only documentation paths
to the Host repository. Product entries are checked but deliberately excluded.
"""
from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import datetime, timezone
import filecmp
import hashlib
import json
from pathlib import Path, PurePosixPath


PREFIX = "docs/evidence/studio-2020-new-work-20261114/"
VIDEO_SUFFIXES = {".mp4", ".avi", ".mov", ".mkv", ".webm"}
FORBIDDEN_SUFFIXES = {".zip", ".apk", ".aab", ".pck"}


def identity(path: Path) -> dict:
    size = path.stat().st_size
    digest = hashlib.sha256()
    blob = hashlib.sha1(b"blob " + str(size).encode("ascii") + b"\0")
    actual_size = 0
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            actual_size += len(block)
            digest.update(block)
            blob.update(block)
    if actual_size != size or path.stat().st_size != size:
        raise ValueError(f"File changed while reading: {path}")
    return {"bytes": size, "sha256": digest.hexdigest(), "git_blob": blob.hexdigest()}


def source_path(row: dict) -> Path:
    value = row.get("local_path", row.get("source"))
    if not isinstance(value, str) or not Path(value).is_absolute():
        raise ValueError(f"Expected explicit absolute original source path: {row}")
    return Path(value)


def verify_expected(row: dict, actual: dict, label: str) -> None:
    if type(row.get("bytes")) is not int or row["bytes"] != actual["bytes"]:
        raise ValueError(f"Byte count mismatch: {label}")
    if row.get("sha256") != actual["sha256"]:
        raise ValueError(f"SHA256 mismatch: {label}")
    for key in ("git_blob", "git_blob_sha1", "git_blob_sha"):
        if key in row and row[key] != actual["git_blob"]:
            raise ValueError(f"Git blob mismatch ({key}): {label}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    args.registry = args.registry.resolve()
    args.output = args.output.resolve()
    registry_raw = args.registry.read_bytes()
    registry = json.loads(registry_raw)
    args.output.mkdir(exist_ok=True)
    files: dict[str, dict] = {}
    checked = []
    excluded = []
    duplicates = []
    groups = []
    videos = []

    def add(path: Path, target: str, mode: str, origin: dict, actual: dict) -> None:
        name = PurePosixPath(target)
        if not target.startswith("docs/evidence/") or name.is_absolute() or ".." in name.parts:
            raise ValueError(f"Refusing non-documentation destination: {target}")
        if mode not in {"100644", "100755"}:
            raise ValueError(f"Unexpected Git mode: {mode} ({target})")
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            raise ValueError(f"Archive or release binary is outside the explicit scope: {path}")
        if path.suffix.lower() in VIDEO_SUFFIXES:
            if actual["bytes"] > 10_000_000:
                raise ValueError(f"Movie needs the explicitly requested <=5MB lossless chunk package: {path}")
            videos.append({"source": str(path), "target": target, **actual})
        # Every selected original presently fits individually in the Git tool's
        # 16MiB request envelope after base64, with more than 1MiB headroom.
        if ((actual["bytes"] + 2) // 3) * 4 > 15 * 1024 * 1024:
            raise ValueError(f"Git request budget exceeded: {path}")
        old = files.get(target)
        if old is not None:
            if (old["bytes"], old["sha256"], old["git_blob"], old["mode"]) != (
                actual["bytes"], actual["sha256"], actual["git_blob"], mode
            ) or not filecmp.cmp(old["source"], path, shallow=False):
                raise ValueError(f"Conflicting same-target originals: {target}")
            old["origins"].append(origin)
            duplicates.append({"target": target, "origin": origin, "decision": "byte-identical target reused"})
            return
        files[target] = {
            "repository": registry["target_repository"],
            "source": str(path),
            "local_path": str(path),
            "path": target,
            "mode": mode,
            "type": "blob",
            **actual,
            "origins": [origin],
        }

    for spec in registry["sources"]:
        manifest = Path(spec["manifest"])
        original = manifest.read_bytes()
        if hashlib.sha256(original).hexdigest() != spec["manifest_sha256"]:
            raise ValueError(f"Frozen input manifest changed: {manifest}")
        document = json.loads(original)
        rows = document["files"]
        if len(rows) != spec["entries_expected"]:
            raise ValueError(f"Input roster count changed: {manifest}")
        selected = 0
        selected_bytes = 0
        for index, row in enumerate(rows):
            path = source_path(row)
            actual = identity(path)
            verify_expected(row, actual, f"{spec['id']}[{index}] {path}")
            target = row.get("path", row.get("target"))
            origin = {
                "group": spec["id"], "manifest": str(manifest),
                "manifest_sha256": spec["manifest_sha256"], "entry_index": index,
                "original_repository": row.get("repository"),
                "original_target": target,
            }
            observation = {"source": str(path), "origin": origin, **actual}
            checked.append(observation)
            if row.get("role") == "source" or row.get("category") == "source":
                excluded.append(dict(observation, reason="product/harness source already handled by source integration"))
                continue
            if not isinstance(target, str):
                raise ValueError(f"Missing explicit documentation target: {path}")
            add(path, target, row.get("mode", "100644"), origin, actual)
            selected += 1
            selected_bytes += actual["bytes"]
        if selected != spec["evidence_expected"]:
            raise ValueError(f"Evidence selection mismatch: {spec['id']} {selected}")
        if manifest.read_bytes() != original:
            raise ValueError(f"Input manifest changed during verification: {manifest}")
        groups.append({"id": spec["id"], "manifest": str(manifest),
                       "manifest_sha256": spec["manifest_sha256"],
                       "all_rows_checked": len(rows), "selected_evidence_rows": selected,
                       "selected_evidence_bytes": selected_bytes})
        add(manifest, PREFIX + "manifests/" + spec["id"] + "/" + manifest.name, "100644",
            {"group": spec["id"], "kind": "unchanged original input manifest"}, identity(manifest))

    content_groups: dict[str, list[str]] = defaultdict(list)
    for target, row in files.items():
        content_groups[row["git_blob"]].append(target)
    verification = {
        "schema": 1, "verified_utc": datetime.now(timezone.utc).isoformat(),
        "registry_sha256": hashlib.sha256(registry_raw).hexdigest(),
        "host_evidence_parent": registry["host_evidence_parent"],
        "scope": "Rehashed original bytes only; no Git mutation, file/archive copy or test rerun.",
        "groups": groups, "checked_manifest_rows": len(checked),
        "selected_manifest_rows": sum(row["selected_evidence_rows"] for row in groups),
        "excluded_source_rows": excluded, "same_target_identical_deduplications": duplicates,
        "large_video_split_required": False, "selected_videos": videos,
        "shared_git_content": [{"git_blob": key, "targets": value}
                               for key, value in content_groups.items() if len(value) > 1],
        "deduplication_policy": "Same-target overlap is merged only after direct byte equality. Different original documentation paths are preserved for relative references; identical Git blobs are uploaded only once.",
        "files_verified": checked,
    }
    (args.output / "verification.json").write_text(json.dumps(verification, indent=2) + "\n")
    for name in ("input-manifests.json", "verification.json", "verify_and_prepare_manifest.py", "README.md"):
        path = args.output / name
        add(path, PREFIX + name, "100644", {"kind": "new packaging provenance"}, identity(path))
    entries = sorted(files.values(), key=lambda row: row["path"])
    result = {
        "schema": 1, "kind": "explicit_hash_checked_host_documentation_upload",
        "repository": registry["target_repository"],
        "expected_evidence_parent": registry["host_evidence_parent"],
        "expected_evidence_parent_tree": registry["host_evidence_parent_tree"],
        "scope": registry["scope"], "source_file_count": 0,
        "evidence_file_count": len(entries), "bytes": sum(row["bytes"] for row in entries),
        "unique_git_blob_count": len({row["git_blob"] for row in entries}),
        "input_manifest_count": len(groups),
        "new_native_ci_pass_claimed": False, "new_android2020_pass_claimed": False,
        "source_installation_or_git_mutation_performed": False,
        "verification_sha256": identity(args.output / "verification.json")["sha256"],
        "files": entries,
    }
    destination = args.output / "upload-manifest.json"
    destination.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"manifest": str(destination), **identity(destination),
                      "evidence_files": len(entries), "payload_bytes": result["bytes"],
                      "checked_rows": len(checked), "excluded_sources": len(excluded),
                      "same_target_deduplications": len(duplicates)}, indent=2))


if __name__ == "__main__":
    main()
