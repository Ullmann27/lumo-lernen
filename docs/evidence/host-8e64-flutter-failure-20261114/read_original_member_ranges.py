"""Read selected original artifact members through strict HTTP 206 ranges.

One-off evidence collection only: does not run Flutter or claim a full archive hash.
The temporary URL is supplied in memory and is deliberately absent from records.
"""
import hashlib
import io
import json
import re
import urllib.request
import zipfile
from pathlib import Path

SIZE = 342973028
ARTIFACT_ID = 14129347799
PUBLISHED_DIGEST = "8e3b3ef1f4967e4dbdfb507d8672b9e9f776e571d13030b4deee5a010a017d0a"
SELECTED = (
    "feature-evidence/HOST-SOURCE.txt",
    "feature-evidence/flutter-version.txt",
    "feature-evidence/full-flutter/acceptance-summary.json",
    "feature-evidence/full-flutter/flutter-machine.jsonl",
)


class Ranges(io.RawIOBase):
    def __init__(self, url, root):
        self.url = url
        self.root = root
        self.pos = 0
        self.records = []
        self.transferred = 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, offset, whence=0):
        value = offset if whence == 0 else self.pos + offset if whence == 1 else SIZE + offset if whence == 2 else -1
        if not 0 <= value <= SIZE:
            raise ValueError("invalid artifact seek")
        self.pos = value
        return value

    def read(self, count=-1):
        if count < 0:
            count = SIZE - self.pos
        count = min(count, SIZE - self.pos)
        if count == 0:
            return b""
        if count > 2 * 1024 * 1024 or self.transferred + count > 8 * 1024 * 1024:
            raise ValueError("bounded selective transfer exceeded")
        start, end = self.pos, self.pos + count - 1
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={start}-{end}", "Accept-Encoding": "identity"})
        with urllib.request.urlopen(request, timeout=45) as response:
            if response.status != 206:
                raise ValueError(f"range request requires 206; received {response.status}")
            expected = f"bytes {start}-{end}/{SIZE}"
            if response.headers.get("Content-Range") != expected:
                raise ValueError("Content-Range does not match exact requested bytes and artifact size")
            if response.headers.get("Content-Encoding", "identity") != "identity":
                raise ValueError("encoded range response unsupported")
            if response.headers.get("Content-Length") != str(count):
                raise ValueError("Content-Length does not match exact requested range")
            payload = response.read(count + 1)
            if len(payload) != count:
                raise ValueError("short or excessive range response")
        name = f"range-{len(self.records):03d}-{start}-{end}.bin"
        (self.root / "ranges" / name).write_bytes(payload)
        self.records.append({"start": start, "end": end, "bytes": count, "status": 206, "content_range": expected, "sha256": hashlib.sha256(payload).hexdigest(), "local_file": "ranges/" + name})
        self.transferred += count
        self.pos += count
        return payload


def run(url, out):
    root = Path(out)
    root.mkdir(parents=True, exist_ok=False)
    (root / "ranges").mkdir()
    reader = Ranges(url, root)
    report = {"schema": 1, "artifact_id": ARTIFACT_ID, "expected_archive_bytes": SIZE, "published_archive_sha256": PUBLISHED_DIGEST, "full_archive_downloaded": False, "full_archive_sha256_locally_verified": False, "whole_archive_crc_verified": False, "temporary_url_saved": False, "members": []}
    try:
        with zipfile.ZipFile(reader) as archive:
            items = archive.infolist()
            names = [item.filename for item in items]
            if len(names) != len(set(names)):
                raise ValueError("duplicate archive entry")
            if any(name.startswith("/") or ".." in Path(name).parts or "\\" in name for name in names):
                raise ValueError("unsafe archive path")
            report["central_directory_start"] = archive.start_dir
            report["entry_count"] = len(items)
            cd = [record for record in reader.records if record["start"] == archive.start_dir]
            if len(cd) != 1:
                raise ValueError("expected one exact central-directory range")
            report["central_directory_range"] = cd[0]
            (root / "central-directory.json").write_text(json.dumps([{"name": item.filename, "crc32": f"{item.CRC:08x}", "compressed_bytes": item.compress_size, "bytes": item.file_size, "header_offset": item.header_offset, "compression": item.compress_type, "flag_bits": item.flag_bits} for item in items], indent=2) + "\n")
            for name in SELECTED:
                if names.count(name) != 1:
                    raise ValueError("required original member missing or duplicated: " + name)
                item = archive.getinfo(name)
                if item.file_size > 16 * 1024 * 1024:
                    raise ValueError("selected member exceeds bounded expected size")
                payload = archive.read(item)  # zipfile checks uncompressed CRC after the complete read.
                target = root / "originals" / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(payload)
                report["members"].append({"artifact_entry": name, "bytes": len(payload), "sha256": hashlib.sha256(payload).hexdigest(), "crc32": f"{item.CRC:08x}", "crc_verified_by_full_member_read": True, "local_file": "originals/" + name})
        report["status"] = "SELECTED_ORIGINAL_MEMBERS_VERIFIED"
    except Exception as error:
        report["status"] = "FAILED"
        report["error_type"] = type(error).__name__
        report["error"] = str(error) if not isinstance(error, urllib.error.URLError) else "HTTP transport failure; URL withheld"
        raise
    finally:
        report["range_requests"] = reader.records
        report["transferred_bytes"] = reader.transferred
        (root / "range-download-report.json").write_text(json.dumps(report, indent=2) + "\n")
    return report
