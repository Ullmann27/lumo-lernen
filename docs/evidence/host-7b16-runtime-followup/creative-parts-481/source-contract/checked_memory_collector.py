#!/usr/bin/env python3
"""Verify one original Actions ZIP in RAM and retain only explicit members.

The API metadata is a separately obtained, unmodified artifact object. This
program checks its archive digest/size; it does not authenticate that object's
origin or make a product/Android acceptance decision.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import re
import shutil
import ssl
import stat
import sys
import urllib.parse
import urllib.request
import zipfile
import zlib
from dataclasses import dataclass


CHUNK = 1024 * 1024
MAX_METADATA = 1024 * 1024
MAX_REPORT = 16 * 1024 * 1024


class Rejected(Exception):
    """A fixed public code, never a raw URL, filename, or network exception."""

    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


@dataclass(frozen=True)
class Limits:
    archive_bytes: int
    materialized_bytes: int
    expanded_bytes: int = 2 * 1024 * 1024 * 1024
    members: int = 20000
    timeout_seconds: int = 120

    def validate(self) -> None:
        for value in (self.archive_bytes, self.expanded_bytes, self.members,
                      self.timeout_seconds):
            if type(value) is not int or value <= 0:
                raise Rejected("INVALID_LIMIT")
        if type(self.materialized_bytes) is not int or self.materialized_bytes < 0:
            raise Rejected("INVALID_LIMIT")


def bounded_file(path: Path, limit: int, *, private: bool = False) -> bytes:
    flags = os.O_RDONLY | (os.O_NOFOLLOW if private else 0)
    with os.fdopen(os.open(path, flags), "rb") as stream:
        before = os.fstat(stream.fileno())
        if not stat.S_ISREG(before.st_mode):
            raise Rejected("INPUT_NOT_REGULAR")
        if private and before.st_mode & 0o077:
            raise Rejected("URL_FILE_NOT_PRIVATE")
        if before.st_size > limit:
            raise Rejected("INPUT_TOO_LARGE")
        raw = stream.read(limit + 1)
        after = os.fstat(stream.fileno())
        if len(raw) > limit or len(raw) != before.st_size:
            raise Rejected("INPUT_SIZE_CHANGED")
        if (before.st_ino, before.st_size, before.st_mtime_ns) != (
                after.st_ino, after.st_size, after.st_mtime_ns):
            raise Rejected("INPUT_CHANGED")
        return raw


def artifact_metadata(path: Path) -> tuple[dict, bytes]:
    raw = bounded_file(path, MAX_METADATA)
    try:
        obj = json.loads(raw)
        run = obj["workflow_run"]
        values = (obj["id"], obj["size_in_bytes"], run["id"])
        if any(type(n) is not int or n <= 0 for n in values):
            raise ValueError
        if not re.fullmatch(r"sha256:[0-9a-f]{64}", obj["digest"]):
            raise ValueError
        if not re.fullmatch(r"[0-9a-f]{40}", run["head_sha"]):
            raise ValueError
    except (KeyError, TypeError, ValueError):
        raise Rejected("INVALID_ARTIFACT_METADATA") from None
    return obj, raw


def validate_https(url: str) -> None:
    try:
        parsed = urllib.parse.urlsplit(url)
        valid = (parsed.scheme == "https" and parsed.hostname and
                 parsed.username is None and parsed.password is None and
                 not parsed.fragment and not any(c.isspace() for c in url))
    except ValueError:
        valid = False
    if not valid:
        raise Rejected("HTTPS_DOWNLOAD_REQUIRED")


class HTTPSRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        validate_https(newurl)
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def buffer_stream(stream, expected_size: int, digest: str, limits: Limits) -> io.BytesIO:
    """Never use a temporary file, a spool, or an unbounded response.read()."""
    buf = io.BytesIO()
    hashed = hashlib.sha256()
    count = 0
    try:
        while True:
            chunk = stream.read(min(CHUNK, expected_size - count + 1))
            if not chunk:
                break
            count += len(chunk)
            if count > expected_size or count > limits.archive_bytes:
                raise Rejected("ARCHIVE_SIZE_MISMATCH")
            hashed.update(chunk)
            buf.write(chunk)
        if count != expected_size:
            raise Rejected("ARCHIVE_SIZE_MISMATCH")
        if hashed.hexdigest() != digest:
            raise Rejected("ARCHIVE_DIGEST_MISMATCH")
        buf.seek(0)
        return buf
    except BaseException:
        buf.close()
        raise


def load_archive(*, local_zip: Path | None, url_file: Path | None,
                 metadata: dict, limits: Limits) -> io.BytesIO:
    if (local_zip is None) == (url_file is None):
        raise Rejected("EXACTLY_ONE_SOURCE_REQUIRED")
    size = metadata["size_in_bytes"]
    if size > limits.archive_bytes:
        raise Rejected("ARCHIVE_LIMIT_EXCEEDED")
    digest = metadata["digest"].removeprefix("sha256:")
    if local_zip is not None:
        with local_zip.open("rb") as stream:
            before = os.fstat(stream.fileno())
            if not stat.S_ISREG(before.st_mode):
                raise Rejected("INPUT_NOT_REGULAR")
            if before.st_size != size:
                raise Rejected("ARCHIVE_SIZE_MISMATCH")
            buf = buffer_stream(stream, size, digest, limits)
            after = os.fstat(stream.fileno())
            if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                buf.close()
                raise Rejected("INPUT_CHANGED")
            return buf
    raw_url = bounded_file(url_file, 65536, private=True)
    try:
        url = raw_url.decode("utf-8").strip()
    except UnicodeError:
        raise Rejected("INVALID_PRIVATE_URL_FILE") from None
    validate_https(url)
    opener = urllib.request.build_opener(
        HTTPSRedirect(), urllib.request.HTTPSHandler(context=ssl.create_default_context()))
    request = urllib.request.Request(url, headers={"Accept-Encoding": "identity"})
    with opener.open(request, timeout=limits.timeout_seconds) as response:
        if response.status != 200:
            raise Rejected("DOWNLOAD_STATUS_REJECTED")
        if response.headers.get("Content-Encoding", "identity").lower() != "identity":
            raise Rejected("ENCODED_HTTP_RESPONSE_REJECTED")
        length = response.headers.get("Content-Length")
        if length is not None and length != str(size):
            raise Rejected("HTTP_SIZE_MISMATCH")
        return buffer_stream(response, size, digest, limits)


def safe_path(name: str, *, directory: bool = False) -> str:
    if (not name or len(name.encode("utf-8")) > 4096 or name.startswith("/") or
            "\\" in name or ":" in name or any(ord(c) < 32 or ord(c) == 127 for c in name)):
        raise Rejected("UNSAFE_MEMBER_PATH")
    path = name[:-1] if directory and name.endswith("/") else name
    if any(part in ("", ".", "..") for part in path.split("/")):
        raise Rejected("UNSAFE_MEMBER_PATH")
    return path


def validate_members(archive: zipfile.ZipFile, selected: list[str], limits: Limits):
    infos = archive.infolist()
    if len(infos) > limits.members:
        raise Rejected("MEMBER_COUNT_LIMIT_EXCEEDED")
    seen = {}
    expanded = 0
    for info in infos:
        directory = info.is_dir()
        key = safe_path(info.filename, directory=directory)
        if info.filename != info.orig_filename:
            raise Rejected("UNSAFE_MEMBER_PATH")
        if key in seen:
            raise Rejected("DUPLICATE_MEMBER_PATH")
        mode = stat.S_IFMT(info.external_attr >> 16)
        if mode not in (0, stat.S_IFREG, stat.S_IFDIR) or info.external_attr & 0x0408:
            raise Rejected("SPECIAL_MEMBER_REJECTED")
        if (mode == stat.S_IFDIR and not directory) or (mode == stat.S_IFREG and directory):
            raise Rejected("MEMBER_KIND_MISMATCH")
        if directory and info.file_size:
            raise Rejected("NONEMPTY_DIRECTORY_MEMBER")
        if info.flag_bits & 1:
            raise Rejected("ENCRYPTED_MEMBER_REJECTED")
        if info.compress_type not in (zipfile.ZIP_STORED, zipfile.ZIP_DEFLATED):
            raise Rejected("UNSUPPORTED_COMPRESSION")
        seen[key] = info
        expanded += info.file_size
        if expanded > limits.expanded_bytes:
            raise Rejected("EXPANDED_SIZE_LIMIT_EXCEEDED")
    for key in seen:
        parts = key.split("/")
        for n in range(1, len(parts)):
            parent = seen.get("/".join(parts[:n]))
            if parent is not None and not parent.is_dir():
                raise Rejected("MEMBER_PATH_COLLISION")
    if len(selected) != len(set(selected)):
        raise Rejected("DUPLICATE_SELECTION")
    for name in selected:
        safe_path(name)
        if name not in seen or seen[name].is_dir():
            raise Rejected("SELECTED_FILE_MISSING")
    materialized = sum(seen[name].file_size for name in selected)
    if materialized > limits.materialized_bytes:
        raise Rejected("MATERIALIZED_SIZE_LIMIT_EXCEEDED")
    return infos, expanded, materialized


def read_member(archive: zipfile.ZipFile, info: zipfile.ZipInfo, sink=None) -> dict:
    hashed = hashlib.sha256()
    crc = 0
    size = 0
    with archive.open(info, "r") as stream:
        while chunk := stream.read(CHUNK):
            size += len(chunk)
            if size > info.file_size:
                raise Rejected("MEMBER_SIZE_MISMATCH")
            hashed.update(chunk)
            crc = zlib.crc32(chunk, crc)
            if sink is not None:
                sink.write(chunk)
    if size != info.file_size or crc != info.CRC:
        raise Rejected("MEMBER_CRC_OR_SIZE_MISMATCH")
    return {"path": info.filename, "kind": "directory" if info.is_dir() else "file",
            "bytes": size, "compressed_bytes": info.compress_size,
            "crc32": f"{crc:08x}", "sha256": hashed.hexdigest()}


def collect(*, metadata_file: Path, local_zip: Path | None, url_file: Path | None,
            output: Path, selected: list[str], limits: Limits) -> dict:
    limits.validate()
    if os.path.lexists(output):
        raise Rejected("OUTPUT_ALREADY_EXISTS")
    if not output.parent.is_dir():
        raise Rejected("OUTPUT_PARENT_MISSING")
    metadata, metadata_raw = artifact_metadata(metadata_file)
    with load_archive(local_zip=local_zip, url_file=url_file, metadata=metadata, limits=limits) as buf:
        # Full archive length and digest have passed before ZipFile sees bytes.
        with zipfile.ZipFile(buf, "r") as archive:
            infos, expanded, materialized = validate_members(archive, selected, limits)
            inventory = [read_member(archive, info) for info in infos]
            report = {"schema": 1, "status": "VERIFIED_ARCHIVE",
                      "scope": "Transport integrity only; no Android or product acceptance.",
                      "artifact": {"id": metadata["id"], "bytes": metadata["size_in_bytes"],
                                   "sha256": metadata["digest"].removeprefix("sha256:"),
                                   "run_id": metadata["workflow_run"]["id"],
                                   "head_sha": metadata["workflow_run"]["head_sha"]},
                      "metadata": {"bytes": len(metadata_raw),
                                   "sha256": hashlib.sha256(metadata_raw).hexdigest()},
                      "input": {"mode": "local_original_zip" if local_zip is not None else "private_https_download",
                                "complete_zip_preexisted_locally": local_zip is not None,
                                "complete_zip_written_by_collector": False,
                                "complete_zip_retention": "Existing local original remains unchanged." if local_zip is not None else "Only the original external Actions artifact retains the complete ZIP; its retention policy is unchanged.",
                                "archive_buffer": "io.BytesIO; no automatic disk spool",
                                "url_recorded": False},
                      "limits": {"archive_bytes": limits.archive_bytes,
                                 "materialized_bytes": limits.materialized_bytes,
                                 "expanded_bytes": limits.expanded_bytes, "members": limits.members},
                      "archive_size_and_sha256_verified_before_zip_parsing": True,
                      "all_members_crc_and_sha256_verified": True,
                      "expanded_bytes": expanded, "members": inventory,
                      "materialized_members": selected, "materialized_bytes": materialized}
            report_raw = (json.dumps(report, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
            if len(report_raw) > MAX_REPORT:
                raise Rejected("REPORT_LIMIT_EXCEEDED")
            # An exclusive new directory is created only after full verification.
            output.mkdir(mode=0o700, exist_ok=False)
            try:
                expected = {row["path"]: row for row in inventory}
                for name in selected:
                    destination = output / "originals" / name
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    with destination.open("xb") as sink:
                        actual = read_member(archive, archive.getinfo(name), sink)
                        sink.flush()
                        os.fsync(sink.fileno())
                    if actual != expected[name]:
                        raise Rejected("MATERIALIZED_MEMBER_CHANGED")
                with (output / "report.json").open("xb") as sink:
                    sink.write(report_raw)
                    sink.flush()
                    os.fsync(sink.fileno())
            except BaseException:
                shutil.rmtree(output)
                raise
    return report


class SafeParser(argparse.ArgumentParser):
    def error(self, message):
        raise Rejected("INVALID_ARGUMENTS")


def main(argv: list[str] | None = None) -> int:
    try:
        parser = SafeParser(description=__doc__)
        parser.add_argument("--metadata", required=True, type=Path)
        source = parser.add_mutually_exclusive_group(required=True)
        source.add_argument("--zip", dest="local_zip", type=Path)
        source.add_argument("--url-file", type=Path)
        parser.add_argument("--out", required=True, type=Path)
        parser.add_argument("--select", action="append", default=[])
        parser.add_argument("--max-archive-bytes", required=True, type=int)
        parser.add_argument("--max-materialized-bytes", required=True, type=int)
        parser.add_argument("--max-expanded-bytes", type=int, default=2 * 1024**3)
        parser.add_argument("--max-members", type=int, default=20000)
        parser.add_argument("--timeout-seconds", type=int, default=120)
        args = parser.parse_args(argv)
        result = collect(metadata_file=args.metadata, local_zip=args.local_zip,
                         url_file=args.url_file, output=args.out, selected=args.select,
                         limits=Limits(args.max_archive_bytes, args.max_materialized_bytes,
                                       args.max_expanded_bytes, args.max_members, args.timeout_seconds))
        print(json.dumps({"status": result["status"], "members": len(result["members"]),
                          "materialized_bytes": result["materialized_bytes"]}))
        return 0
    except Rejected as error:
        code = error.code
    except (zipfile.BadZipFile, EOFError, zlib.error):
        code = "ZIP_INTEGRITY_ERROR"
    except Exception:
        # Do not print raw HTTP/SSL/OSError messages: they may embed signed URLs.
        code = "COLLECTION_IO_OR_FORMAT_ERROR"
    print(json.dumps({"status": "FAIL", "code": code}), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
