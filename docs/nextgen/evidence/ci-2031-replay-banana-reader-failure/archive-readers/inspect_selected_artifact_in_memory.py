"""Verify a complete Actions ZIP in RAM; retain only explicitly selected files.

Pass the same JSON metadata as download_verified_artifact.py, plus a nonempty
selected_paths list. Read JSON from a file argument or from stdin with '-'.
The tool-provided download_url is used only for transport, never for evidence.
Artifact/run IDs are caller-supplied metadata bound to the checked ZIP digest;
this reader does not independently query GitHub. No ZIP is written to disk.
"""
from __future__ import annotations

import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import urllib.parse
import urllib.request
import zipfile
import zlib


MAX_ARCHIVE_BYTES = 1_200_000_000
MAX_MEMBERS = 20_000
MAX_UNCOMPRESSED_BYTES = 2_500_000_000
DISK_RESERVE_BYTES = 10 * 1024 * 1024
CHUNK_BYTES = 1024 * 1024


class ArtifactError(Exception):
    """A fixed, URL-free diagnostic suitable for the caller's raw log."""


def require(condition, message):
    if not condition:
        raise ArtifactError(message)


def checked_name(name, *, directory=False):
    require(isinstance(name, str) and bool(name), "Empty or invalid member name")
    require(not any(ord(c) < 32 or ord(c) == 127 for c in name),
            "Control character in member name")
    require("\\" not in name and ":" not in name and not name.startswith("/"),
            "Non-relative POSIX member name")
    body = name[:-1] if directory and name.endswith("/") else name
    parts = body.split("/")
    require(all(part not in ("", ".", "..") for part in parts),
            "Non-canonical or traversing member name")
    return tuple(parts)


def checked_specification(specification):
    require(isinstance(specification, dict), "Expected a JSON object")
    for key in ("artifact_id", "run_id", "bytes"):
        value = specification.get(key)
        require(type(value) is int and value > 0, "Positive integer identity/size required")
    require(specification["bytes"] <= MAX_ARCHIVE_BYTES, "Archive exceeds RAM size limit")
    digest = specification.get("sha256")
    require(isinstance(digest, str), "Archive SHA-256 required")
    digest = digest.removeprefix("sha256:")
    require(re.fullmatch(r"[0-9a-f]{64}", digest) is not None, "Invalid archive SHA-256")
    selected = specification.get("selected_paths")
    require(type(selected) is list and 0 < len(selected) <= MAX_MEMBERS,
            "Explicit nonempty selected_paths list required")
    for name in selected:
        checked_name(name)
    require(len(set(selected)) == len(selected), "Duplicate selected path")
    destination = specification.get("destination")
    require(isinstance(destination, str) and bool(destination), "Destination required")
    destination = Path(destination)
    require(not os.path.lexists(destination), "Destination must not exist")
    require(destination.parent.is_dir(), "Destination parent must already exist")
    return destination, selected, digest


def require_https(url):
    require(isinstance(url, str), "HTTPS download URL required")
    parsed = urllib.parse.urlsplit(url)
    require(parsed.scheme == "https" and bool(parsed.hostname) and
            parsed.username is None and parsed.password is None and not parsed.fragment,
            "Tool download URL/redirect must be credential-free HTTPS")


class HttpsRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, url):
        require_https(url)
        return super().redirect_request(request, response, code, message, headers, url)


def download_to_memory(specification):
    checked_specification(specification)
    url = specification.get("download_url")
    require_https(url)
    memory = io.BytesIO()
    try:
        request = urllib.request.Request(
            url, headers={"User-Agent": "Lumo-selected-artifact-verification/1"})
        opener = urllib.request.build_opener(HttpsRedirect())
        with opener.open(request, timeout=60) as response:
            require(response.status == 200, "Artifact transport must return HTTP 200")
            require_https(response.geturl())
            length = response.headers.get("Content-Length")
            if length is not None:
                require(int(length) == specification["bytes"], "Transport size differs")
            while chunk := response.read(CHUNK_BYTES):
                require(memory.tell() + len(chunk) <= specification["bytes"],
                        "Artifact exceeded its declared archive size")
                memory.write(chunk)
        require(memory.tell() == specification["bytes"], "Artifact transport is incomplete")
        memory.seek(0)
        return memory
    except Exception:
        memory.close()
        raise


def read_member(archive, entry, *, output=None):
    digest, crc, size = hashlib.sha256(), 0, 0
    with archive.open(entry) as source:
        while chunk := source.read(CHUNK_BYTES):
            size += len(chunk)
            require(size <= entry.file_size, "Member exceeds its declared size")
            digest.update(chunk)
            crc = zlib.crc32(chunk, crc)
            if output is not None:
                output.write(chunk)
    require(size == entry.file_size, "Member size differs")
    require(crc & 0xffffffff == entry.CRC, "Member CRC differs")
    return {"bytes": size, "sha256": digest.hexdigest(), "crc32": f"{crc & 0xffffffff:08x}"}


def inspect_archive(memory, specification):
    """Verify every entry before creating the selected-originals directory."""
    destination, selected, expected_digest = checked_specification(specification)
    memory.seek(0, io.SEEK_END)
    require(memory.tell() == specification["bytes"], "Archive byte count differs")
    memory.seek(0)
    archive_digest = hashlib.file_digest(memory, "sha256").hexdigest()
    require(archive_digest == expected_digest, "Archive SHA-256 differs")
    memory.seek(0)
    with zipfile.ZipFile(memory) as archive:
        entries = archive.infolist()
        require(0 < len(entries) <= MAX_MEMBERS, "Archive member-count limit exceeded")
        by_name, canonical = {}, {}
        total = 0
        for entry in entries:
            require(entry.orig_filename == entry.filename, "ZIP member name was truncated")
            parts = checked_name(entry.filename, directory=entry.is_dir())
            require(parts not in canonical, "Duplicate/colliding ZIP member name")
            mode = stat.S_IFMT(entry.external_attr >> 16)
            require(mode != stat.S_IFLNK, "Archive symlink rejected")
            require(mode in (0, stat.S_IFREG, stat.S_IFDIR), "Special archive file rejected")
            require(mode != stat.S_IFDIR or entry.is_dir(), "Directory member type differs")
            require(mode != stat.S_IFREG or not entry.is_dir(), "Regular member type differs")
            require(not entry.flag_bits & 1, "Encrypted ZIP member rejected")
            require(not entry.is_dir() or entry.file_size == 0, "Directory member contains data")
            require(entry.file_size >= 0 and entry.compress_size >= 0, "Invalid member size")
            total += entry.file_size
            require(total <= MAX_UNCOMPRESSED_BYTES, "Uncompressed archive limit exceeded")
            canonical[parts] = entry
            by_name[entry.filename] = entry
        for parts in canonical:
            for length in range(1, len(parts)):
                ancestor = canonical.get(parts[:length])
                require(ancestor is None or ancestor.is_dir(), "File/directory path collision")
        require(all(name in by_name and not by_name[name].is_dir() for name in selected),
                "An explicitly selected file is absent from the archive")
        selected_set = set(selected)
        manifest, verified = [], {}
        for entry in entries:
            proof = read_member(archive, entry)
            verified[entry.filename] = proof
            manifest.append({"path": entry.filename, "directory": entry.is_dir(),
                             "compressedBytes": entry.compress_size,
                             "selected": entry.filename in selected_set, **proof})
        selected_bytes = sum(by_name[name].file_size for name in selected)
        report = {
            "artifactId": specification["artifact_id"], "workflowRun": specification["run_id"],
            "identityMetadataSource": "caller-provided Actions metadata; exact archive bytes verified",
            "archiveBytes": specification["bytes"], "archiveSha256": archive_digest,
            "wholeArchiveVerified": True, "allMemberSizesVerified": True,
            "allMemberCRCsVerified": True, "allMemberSha256Computed": True,
            "archiveRetainedLocally": False, "allOriginalsRetainedLocally": False,
            "selectedOriginalsOnly": True, "memberCount": len(entries),
            "uncompressedBytes": total, "selectedPaths": selected,
            "selectedFileCount": len(selected), "selectedBytes": selected_bytes,
            "diskReserveBytes": DISK_RESERVE_BYTES, "members": manifest,
        }
        report_bytes = (json.dumps(report, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
        required = selected_bytes + len(report_bytes) + DISK_RESERVE_BYTES
        require(shutil.disk_usage(destination.parent).free >= required,
                "Insufficient space for selected originals, manifest and reserve")
        # All members, including unselected entries, have passed before any write.
        destination.mkdir(exist_ok=False)
        originals = destination / "original"
        originals.mkdir()
        for index, name in enumerate(selected):
            target = originals.joinpath(*checked_name(name))
            target.parent.mkdir(parents=True, exist_ok=True)
            temporary = destination / f"selected-member-{index}.part"
            with temporary.open("xb") as output:
                proof = read_member(archive, by_name[name], output=output)
            require(proof == verified[name], "Selected file copy differs from verified member")
            require(not os.path.lexists(target), "Selected target unexpectedly exists")
            temporary.rename(target)
        with (destination / "artifact-verification.json").open("xb") as output:
            output.write(report_bytes)
    return report


def main(argv=None):
    args = sys.argv[1:] if argv is None else argv
    try:
        require(len(args) == 1, "Usage: inspect_selected_artifact_in_memory.py SPEC.json or -")
        specification = json.load(sys.stdin) if args[0] == "-" else json.loads(Path(args[0]).read_text())
        with download_to_memory(specification) as memory:
            report = inspect_archive(memory, specification)
        print(json.dumps({key: report[key] for key in (
            "artifactId", "workflowRun", "archiveBytes", "archiveSha256", "wholeArchiveVerified",
            "selectedOriginalsOnly", "memberCount", "selectedFileCount", "selectedBytes")}))
        return 0
    except ArtifactError as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}), file=sys.stderr)
    except Exception as error:
        # HTTPError/URLError messages may contain the SAS URL. Never print them,
        # tracebacks, input JSON or exception reprs, even on failed downloads.
        print(json.dumps({"status": "FAIL", "errorClass": type(error).__name__}), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
