"""Extract explicitly selected original files from a digest-checked split Actions ZIP."""
from __future__ import annotations
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile


def extract(root: Path, selected: list[str], record_name: str):
    retention = json.loads((root / "archive-retention.json").read_text())
    verification = json.loads((root / "artifact-verification.json").read_text())
    assert retention["archiveSha256"] == verification["archiveSha256"]
    assert len(set(selected)) == len(selected) and selected
    assert Path(record_name).name == record_name
    members = {entry["path"]: entry for entry in verification["members"]}
    memory = io.BytesIO()
    for part in retention["parts"]:
        data = (root / part["path"]).read_bytes()
        assert len(data) == part["bytes"]
        assert hashlib.sha256(data).hexdigest() == part["sha256"]
        memory.write(data)
    assert memory.tell() == retention["archiveBytes"]
    memory.seek(0)
    assert hashlib.file_digest(memory, "sha256").hexdigest() == retention["archiveSha256"]
    memory.seek(0)
    records = []
    with zipfile.ZipFile(memory) as archive:
        for name in selected:
            parts = name.split("/")
            assert all(part not in ("", ".", "..") for part in parts)
            assert not any("\\" in part or ":" in part for part in parts)
            entry = members[name]
            assert not entry["directory"]
            data = archive.read(name)
            assert len(data) == entry["bytes"]
            assert hashlib.sha256(data).hexdigest() == entry["sha256"]
            target = root / "original" / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists():
                assert target.read_bytes() == data
            else:
                with target.open("xb") as output:
                    output.write(data)
            records.append({"path": name, "bytes": entry["bytes"], "sha256": entry["sha256"]})
    memory.close()
    with (root / record_name).open("x") as output:
        json.dump({"artifactId": retention["artifactId"], "workflowRun": retention["workflowRun"],
                   "archiveSha256": retention["archiveSha256"], "byteExactOriginals": records},
                  output, indent=2)
        output.write("\n")
    print(json.dumps({"extracted": len(records), "originalBytes": sum(x["bytes"] for x in records)}))


if __name__ == "__main__":
    specification = json.load(sys.stdin)
    extract(Path(specification["root"]), specification["selected"], specification["record_name"])
