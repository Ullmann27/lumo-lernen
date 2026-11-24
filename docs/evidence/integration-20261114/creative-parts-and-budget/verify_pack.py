#!/usr/bin/env python3
"""Verify the complete compact evidence archive against the original-byte index."""
from pathlib import Path, PurePosixPath
import gzip, hashlib, io, json, tarfile

root = Path(__file__).resolve().parent
index = json.loads((root / "index.json").read_bytes())
archive = (root / index["archive"]["path"]).read_bytes()
assert len(archive) == index["archive"]["bytes"]
assert hashlib.sha256(archive).hexdigest() == index["archive"]["sha256"]
excluded = {row["archive_path"] for row in index["excluded"]}
expected = {row["archive_path"]: row for row in index["files"] if row["archive_path"] not in excluded}
assert len(expected) == index["included_file_count"]
seen = set()
with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
    for member in tar:
        path = PurePosixPath(member.name)
        assert member.isfile() and not path.is_absolute() and ".." not in path.parts
        assert member.name not in seen and member.name in expected
        seen.add(member.name)
        data = tar.extractfile(member).read()
        assert len(data) == expected[member.name]["bytes"]
        assert hashlib.sha256(data).hexdigest() == expected[member.name]["sha256"]
assert seen == set(expected)
gzip.decompress(archive)
print(json.dumps({"status": "ORIGINAL_BYTE_ROUNDTRIP_PASS", "members": len(seen),
                  "archive_sha256": index["archive"]["sha256"],
                  "scope": "Evidence integrity only; no product, device or release acceptance"}, sort_keys=True))
