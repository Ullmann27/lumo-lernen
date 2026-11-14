#!/usr/bin/env python3
"""Reconstruct and verify the exact original lossless C4 renderer movie."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent
manifest = json.loads((root / "runtime-lossless.parts.json").read_text())
output = root / "runtime-lossless.mkv"
if output.exists():
    raise SystemExit("Refusing to overwrite an existing movie")
assembled = bytearray()
for part in manifest["parts"]:
    data = (root / part["name"]).read_bytes()
    if len(data) != part["bytes"] or hashlib.sha256(data).hexdigest() != part["sha256"]:
        raise SystemExit("Part failed verification: " + part["name"])
    assembled.extend(data)
if len(assembled) != manifest["original"]["bytes"] or hashlib.sha256(assembled).hexdigest() != manifest["original"]["sha256"]:
    raise SystemExit("Reassembled movie failed original SHA256/size verification")
output.write_bytes(assembled)
print(output)
print(manifest["original"]["sha256"])
