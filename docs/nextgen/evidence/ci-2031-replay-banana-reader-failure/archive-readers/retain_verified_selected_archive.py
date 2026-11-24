"""Retain a fully checked Actions archive as bounded Git blobs plus selected originals."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import sys

READER = Path(__file__).with_name("inspect_selected_artifact_in_memory.py")
module_spec = importlib.util.spec_from_file_location("checked_artifact_reader", READER)
reader = importlib.util.module_from_spec(module_spec)
module_spec.loader.exec_module(reader)
PART_BYTES = 8 * 1024 * 1024


def main():
    try:
        specification = json.load(sys.stdin)
        destination, _, _ = reader.checked_specification(specification)
        reader.require(shutil.disk_usage(destination.parent).free >=
                       specification["bytes"] * 2 + reader.DISK_RESERVE_BYTES,
                       "Insufficient archive-retention reserve")
        with reader.download_to_memory(specification) as memory:
            report = reader.inspect_archive(memory, specification)
            reader.require(shutil.disk_usage(destination).free >=
                           specification["bytes"] + reader.DISK_RESERVE_BYTES,
                           "Insufficient space for complete verified archive")
            parts = destination / "archive-parts"
            parts.mkdir(exist_ok=False)
            memory.seek(0)
            manifest = []
            whole_digest = hashlib.sha256()
            whole_size = 0
            while chunk := memory.read(PART_BYTES):
                name = f"artifact.zip.part{len(manifest) + 1:03d}"
                path = parts / name
                with path.open("xb") as output:
                    output.write(chunk)
                actual = path.read_bytes()
                reader.require(actual == chunk, "Retained archive part differs")
                whole_digest.update(actual)
                whole_size += len(actual)
                manifest.append({"path": "archive-parts/" + name,
                                 "bytes": len(actual),
                                 "sha256": hashlib.sha256(actual).hexdigest()})
            reader.require(whole_size == report["archiveBytes"] and
                           whole_digest.hexdigest() == report["archiveSha256"],
                           "Retained complete archive differs")
            proof = {
                "artifactId": report["artifactId"],
                "workflowRun": report["workflowRun"],
                "archiveBytes": whole_size,
                "archiveSha256": whole_digest.hexdigest(),
                "format": "Ordered byte-exact concatenation of listed parts reconstructs original ZIP",
                "partSizeLimit": PART_BYTES,
                "allOriginalsRetainedInArchiveParts": True,
                "memberVerification": "artifact-verification.json",
                "parts": manifest,
            }
            with (destination / "archive-retention.json").open("x") as output:
                json.dump(proof, output, indent=2)
                output.write("\n")
        print(json.dumps({"artifactId": report["artifactId"],
                          "workflowRun": report["workflowRun"],
                          "archiveBytes": whole_size,
                          "archiveSha256": whole_digest.hexdigest(),
                          "memberCount": report["memberCount"],
                          "uncompressedBytes": report["uncompressedBytes"],
                          "allOriginalsRetainedInArchiveParts": True,
                          "selectedPaths": report["selectedPaths"],
                          "parts": len(manifest)}))
        return 0
    except reader.ArtifactError as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}), file=sys.stderr)
    except Exception as error:
        print(json.dumps({"status": "FAIL", "errorClass": type(error).__name__}), file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
