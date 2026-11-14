"""Collect exactly two original API37 journals using the existing strict range reader.
No tests or Android processes run. The signed download URL is read from stdin
and is intentionally absent from persisted evidence.
"""
import hashlib
import importlib.util
import json
import sys
import zipfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parent
READER_SOURCE = ROOT.parent / "host-28462-flutter-acceptance-20261114/read_original_member_ranges.py"
EXPECTED_SIZE = 65852093
EXPECTED_DIGEST = "c5dd800aae41db9b21120fddcd15dece15f8c01ade98397fa236ca7ddaad5dd1"
REQUESTED = (
    "21_kart_preview_skip.json",
    "21_kart_preview_skip_touch-surface-readiness.json",
)

def main():
    url = json.loads(sys.stdin.read())["download_url"]
    spec = importlib.util.spec_from_file_location("existing_artifact_ranges", READER_SOURCE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    # Artifact-specific bounds, not a change to the existing reader algorithm.
    module.SIZE = EXPECTED_SIZE
    out = ROOT / "selected-journal-transfer"
    out.mkdir(exist_ok=False)
    (out / "ranges").mkdir()
    reader = module.Ranges(url, out)
    report = {
        "schema": 1, "artifact_id": 14128934085, "run_id": 43626348519,
        "job_id": 132563694495, "expected_archive_bytes": EXPECTED_SIZE,
        "published_archive_sha256": EXPECTED_DIGEST,
        "reader_source": str(READER_SOURCE),
        "reader_source_sha256": hashlib.sha256(READER_SOURCE.read_bytes()).hexdigest(),
        "full_archive_locally_downloaded": False,
        "full_archive_sha256_locally_verified": False,
        "whole_archive_crc_verified": False,
        "temporary_url_saved": False, "members": [],
    }
    try:
        with zipfile.ZipFile(reader) as archive:
            items = archive.infolist()
            names = [i.filename for i in items]
            if len(names) != len(set(names)):
                raise ValueError("Duplicate archive entry")
            if any(n.startswith("/") or ".." in Path(n).parts or "\\" in n for n in names):
                raise ValueError("Unsafe archive path")
            report["entry_count"] = len(items)
            report["central_directory_start"] = archive.start_dir
            inventory = [
                {"name": i.filename, "crc32": f"{i.CRC:08x}",
                 "compressed_bytes": i.compress_size, "bytes": i.file_size,
                 "header_offset": i.header_offset}
                for i in items
            ]
            (out / "central-directory.json").write_text(json.dumps(inventory, indent=2) + "\n")
            for basename in REQUESTED:
                matches = [i for i in items if Path(i.filename).name == basename]
                if len(matches) != 1:
                    raise ValueError("Required unique original journal not found: " + basename)
                item = matches[0]
                if item.file_size > 1024 * 1024:
                    raise ValueError("Journal exceeds the explicit 1 MiB bound")
                payload = archive.read(item)
                if zlib.crc32(payload) != item.CRC:
                    raise ValueError("Original member CRC mismatch")
                json.loads(payload)
                target = out / "originals" / basename
                target.parent.mkdir(exist_ok=True)
                target.write_bytes(payload)
                report["members"].append({
                    "artifact_entry": item.filename, "bytes": len(payload),
                    "sha256": hashlib.sha256(payload).hexdigest(),
                    "git_blob_sha": hashlib.sha1(b"blob " + str(len(payload)).encode() + b"\0" + payload).hexdigest(),
                    "crc32": f"{item.CRC:08x}", "member_crc_verified": True,
                    "local_file": "originals/" + basename,
                })
        report["status"] = "TWO_ORIGINAL_JOURNALS_VERIFIED"
    except Exception as error:
        report["status"] = "FAILED"
        report["error_type"] = type(error).__name__
        # No signed URL or exception text can leak into a permanent record.
        raise RuntimeError("Strict original-journal collection failed: " + type(error).__name__) from None
    finally:
        report["range_requests"] = reader.records
        report["transferred_bytes"] = reader.transferred
        (out / "range-download-report.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({key: report[key] for key in ["status", "entry_count", "transferred_bytes", "members"]}))

if __name__ == "__main__":
    main()
