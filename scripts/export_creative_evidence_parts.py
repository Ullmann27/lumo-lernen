#!/usr/bin/env python3
"""Copy complete Creative evidence into bounded, independently uploaded parts.

This is an additional lossless transport, not an acceptance or selection gate.
Every part carries the same complete source/run-bound index. The existing full
artifact remains independent. No input is linked, trimmed, or re-encoded.
"""
from __future__ import annotations

import argparse
from contextlib import ExitStack
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile


DEFAULT_PART_BYTES = 256 * 1024 * 1024
MAX_PARTS = 8
MAX_FILES = 20_000
MAX_INDEX_BYTES = 4 * 1024 * 1024
MAX_PART_MANIFEST_BYTES = 16 * 1024
WORKFLOWS = (
    ".github/workflows/lumo-kart-graphics-2019.yml",
    ".github/workflows/lumo-studio-2019.yml",
)


def _signature(value: os.stat_result) -> tuple[int, ...]:
    return (value.st_dev, value.st_ino, value.st_mode, value.st_size,
            value.st_mtime_ns, value.st_ctime_ns)


def _directory_without_links(path: Path) -> Path:
    absolute = Path(os.path.abspath(path))
    for component in (absolute, *absolute.parents):
        if component.is_symlink():
            raise ValueError(f"Symlink is not allowed: {component}")
    if not absolute.is_dir():
        raise ValueError(f"Existing regular directory required: {absolute}")
    return absolute


def _snapshot(source: Path, *, max_files: int = MAX_FILES) -> tuple[dict[str, tuple[int, ...]], dict[str, tuple[int, ...]]]:
    files: dict[str, tuple[int, ...]] = {}
    directories: dict[str, tuple[int, ...]] = {}
    pending = [source]
    while pending:
        directory = pending.pop()
        info = directory.lstat()
        if not stat.S_ISDIR(info.st_mode):
            raise ValueError(f"Source directory changed or is a symlink: {directory}")
        directories[directory.relative_to(source).as_posix()] = _signature(info)
        with os.scandir(directory) as iterator:
            entries = sorted(iterator, key=lambda item: item.name)
        for entry in entries:
            info = entry.stat(follow_symlinks=False)
            path = Path(entry.path)
            relative = path.relative_to(source).as_posix()
            if stat.S_ISDIR(info.st_mode):
                pending.append(path)
            elif stat.S_ISREG(info.st_mode):
                if relative in files:
                    raise ValueError(f"Duplicate original path: {relative}")
                files[relative] = _signature(info)
                if len(files) > max_files:
                    raise ValueError(f"Evidence exceeds {max_files} regular files")
            else:
                raise ValueError(f"Symlink or non-regular source entry: {relative}")
    if not files:
        raise ValueError("No regular Creative evidence files")
    return dict(sorted(files.items())), directories


def plan_parts(sizes: dict[str, int], limit: int) -> list[list[str]]:
    """Use sorted original paths; a file is never divided between parts."""
    if type(limit) is not int or not 0 < limit <= DEFAULT_PART_BYTES:
        raise ValueError(f"Part byte limit must be between 1 and {DEFAULT_PART_BYTES}")
    if not sizes or len(sizes) > MAX_FILES:
        raise ValueError(f"Evidence must contain between 1 and {MAX_FILES} files")
    parts: list[list[str]] = [[]]
    used = 0
    for path, size in sorted(sizes.items()):
        if type(size) is not int or size < 0 or size > limit:
            raise ValueError(f"Single file exceeds part byte limit or has invalid size: {path}")
        if used + size > limit:
            if len(parts) == MAX_PARTS:
                raise ValueError(f"Complete evidence requires more than {MAX_PARTS} parts")
            parts.append([])
            used = 0
        parts[-1].append(path)
        used += size
    return parts


def _read_verified(path: Path, expected: tuple[int, ...], target: Path | None = None) -> str:
    flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK
    descriptor = os.open(path, flags)
    with ExitStack() as stack:
        reader = stack.enter_context(os.fdopen(descriptor, "rb"))
        if _signature(os.fstat(reader.fileno())) != expected:
            raise ValueError(f"Source changed before reading: {path}")
        writer = stack.enter_context(target.open("xb")) if target is not None else None
        digest = hashlib.sha256()
        for data in iter(lambda: reader.read(1024 * 1024), b""):
            digest.update(data)
            if writer is not None:
                writer.write(data)
        if _signature(os.fstat(reader.fileno())) != expected:
            raise ValueError(f"Source changed while reading: {path}")
    if _signature(path.lstat()) != expected:
        raise ValueError(f"Source path changed after reading: {path}")
    return digest.hexdigest()


def _json_bytes(value: dict, limit: int) -> bytes:
    data = (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")
    if len(data) > limit:
        raise ValueError(f"Evidence manifest exceeds {limit} bytes")
    return data


def export_parts(source: Path, output: Path, *, repository: str, workflow_path: str,
                 source_sha: str, run_id: int, run_attempt: int,
                 max_part_bytes: int = DEFAULT_PART_BYTES) -> dict:
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repository):
        raise ValueError("Exact owner/repository binding required")
    if workflow_path not in WORKFLOWS:
        raise ValueError("Unapproved Creative workflow path")
    if not re.fullmatch(r"[a-f0-9]{40}", source_sha):
        raise ValueError("Exact lowercase 40-character Host source SHA required")
    if type(run_id) is not int or run_id <= 0 or type(run_attempt) is not int or run_attempt <= 0:
        raise ValueError("Positive integer workflow run and attempt required")
    source = _directory_without_links(source)
    output = Path(os.path.abspath(output))
    _directory_without_links(output.parent)
    if output == source or source in output.parents or output in source.parents:
        raise ValueError("Export output must be outside the original evidence tree")
    if os.path.lexists(output):
        raise ValueError(f"Export output already exists: {output}")

    snapshot = _snapshot(source)
    signatures = snapshot[0]
    sizes = {path: signature[3] for path, signature in signatures.items()}
    groups = plan_parts(sizes, max_part_bytes)
    assigned = {path: number for number, group in enumerate(groups, 1) for path in group}
    index = {
        "schema": 1,
        "binding": {"repository": repository, "workflow_path": workflow_path,
                    "host_source_sha": source_sha, "run_id": run_id, "run_attempt": run_attempt},
        "original_path_prefix": "originals/",
        "limits": {"part_payload_bytes": max_part_bytes, "max_parts": MAX_PARTS,
                   "max_files": MAX_FILES, "index_bytes": MAX_INDEX_BYTES,
                   "part_manifest_bytes": MAX_PART_MANIFEST_BYTES},
        "file_count": len(sizes), "total_bytes": sum(sizes.values()), "part_count": len(groups),
        "parts": [{"part": number, "directory": f"part-{number:02d}",
                   "file_count": len(group), "payload_bytes": sum(sizes[path] for path in group)}
                  for number, group in enumerate(groups, 1)],
        "files": [{"path": path, "bytes": sizes[path], "sha256": "0" * 64, "part": assigned[path]}
                  for path in signatures],
    }
    # Hash placeholders have the exact eventual width: reject excessive metadata
    # before creating or copying any output payload.
    _json_bytes(index, MAX_INDEX_BYTES)
    staging = Path(tempfile.mkdtemp(prefix=f".{output.name}-", dir=output.parent))
    try:
        for record in index["files"]:
            original = source / record["path"]
            target = staging / f"part-{record['part']:02d}" / "originals" / record["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            record["sha256"] = _read_verified(original, signatures[record["path"]], target)
        index_bytes = _json_bytes(index, MAX_INDEX_BYTES)
        index_digest = hashlib.sha256(index_bytes).hexdigest()
        manifests = {}
        for part in index["parts"]:
            directory = staging / part["directory"]
            (directory / "export-index.json").write_bytes(index_bytes)
            manifest = {"schema": 1, **part, "total_parts": len(groups),
                        "index_sha256": index_digest, "index_bytes": len(index_bytes)}
            manifests[part["directory"]] = _json_bytes(manifest, MAX_PART_MANIFEST_BYTES)
            (directory / "part.json").write_bytes(manifests[part["directory"]])
        for record in index["files"]:
            target = staging / f"part-{record['part']:02d}" / "originals" / record["path"]
            signature = _signature(target.lstat())
            if signature[3] != record["bytes"] or _read_verified(target, signature) != record["sha256"]:
                raise ValueError(f"Exported bytes differ: {record['path']}")
            if _read_verified(source / record["path"], signatures[record["path"]]) != record["sha256"]:
                raise ValueError(f"Original bytes changed: {record['path']}")
        if _snapshot(source) != snapshot:
            raise ValueError("Original evidence tree changed during export")
        for part in index["parts"]:
            directory = staging / part["directory"]
            actual = _snapshot(directory, max_files=MAX_FILES + 2)[0]
            expected = {"export-index.json", "part.json"} | {
                "originals/" + path for path in groups[part["part"] - 1]
            }
            if set(actual) != expected:
                raise ValueError(f"Incomplete or unexpected exported files: {part['directory']}")
            if (directory / "export-index.json").read_bytes() != index_bytes:
                raise ValueError("Export index differs between parts")
            if (directory / "part.json").read_bytes() != manifests[part["directory"]]:
                raise ValueError("Export part manifest changed")
        if os.path.lexists(output):
            raise ValueError(f"Export output appeared during preparation: {output}")
        staging.rename(output)
    except BaseException:
        shutil.rmtree(staging)
        raise
    return {"status": "CREATIVE_EVIDENCE_PARTS_READY", "output_directory": str(output),
            "part_count": len(groups), "file_count": len(sizes), "total_bytes": sum(sizes.values()),
            "index_sha256": index_digest, "index_bytes": len(index_bytes)}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--workflow-path", required=True, choices=WORKFLOWS)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--run-id", required=True, type=int)
    parser.add_argument("--run-attempt", required=True, type=int)
    parser.add_argument("--max-part-bytes", type=int, default=DEFAULT_PART_BYTES,
                        help="Lower only for boundary tests; cannot exceed the 256 MiB transport limit")
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()
    try:
        result = export_parts(args.source, args.output, repository=args.repository,
                              workflow_path=args.workflow_path, source_sha=args.source_sha,
                              run_id=args.run_id, run_attempt=args.run_attempt,
                              max_part_bytes=args.max_part_bytes)
        if args.github_output is not None:
            flags = os.O_WRONLY | os.O_APPEND | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK
            with os.fdopen(os.open(args.github_output, flags, 0o600), "w", encoding="utf-8") as stream:
                if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
                    raise ValueError("GitHub output must be a regular file")
                stream.write(f"part_count={result['part_count']}\nindex_sha256={result['index_sha256']}\n")
                for number in range(1, MAX_PARTS + 1):
                    stream.write(f"part_{number:02d}={'true' if number <= result['part_count'] else 'false'}\n")
        print(json.dumps(result, sort_keys=True))
        return 0
    except (OSError, ValueError) as error:
        print(f"FAIL Creative evidence transport: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
