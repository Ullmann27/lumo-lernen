#!/usr/bin/env python3
"""Download and inspect the exact completed 785413 Native archive; never approve images."""
from __future__ import annotations

import datetime
import hashlib
import json
from pathlib import Path
import sys
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[2]
REVIEW = ROOT / "qa/studio-2020-native-785413-review"
NATIVE = "785413d395292a243eaa0a0748671eb15d3f80ff"
RUN_ID = 43570887024
ARCHIVE = Path("/tmp/lumo-studio-2020-785413-native-evidence.zip")
RENDER_CACHE = Path("/tmp/lumo-studio-2020-785413-originals")
sys.path.insert(0, str(ROOT / "qa/studio-2020-integration/test-host/scripts"))
import verify_studio_delivery as gate


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def digest_file(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(4 * 1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest()


def main() -> None:
    run = read_json(REVIEW / "native-run.json")
    jobs = read_json(REVIEW / "native-jobs.json")
    artifact = read_json(REVIEW / "native-artifact.json")
    release = read_json(REVIEW / "native-release.json")
    plan = read_json(REVIEW / "required-image-review-plan.json")
    gate.verify_native_acceptance(NATIVE, artifact, run, jobs, studio_version=2020)
    assert run["id"] == RUN_ID and plan["native"] == NATIVE and plan["run_id"] == RUN_ID
    assert run["run_attempt"] == 1
    assert release["tag_name"] == f"studio-2020-evidence-{NATIVE}-{artifact['id']}"
    assets = [asset for asset in release["assets"] if asset["name"] == "native-evidence.zip"]
    assert len(assets) == 1 and assets[0]["state"] == "uploaded"
    expected_size = artifact["size_in_bytes"]
    assert type(expected_size) is int and 0 < expected_size < 512 * 1024 * 1024
    assert assets[0]["size"] == expected_size
    expected_digest = artifact["digest"].removeprefix("sha256:")
    assert len(expected_digest) == 64 and artifact["digest"] == "sha256:" + expected_digest
    if assets[0].get("digest"):
        assert assets[0]["digest"] == artifact["digest"]
    url = assets[0]["browser_download_url"]
    assert url == f"https://github.com/Ullmann27/lumo-godot/releases/download/{release['tag_name']}/native-evidence.zip"

    if not ARCHIVE.exists():
        partial = ARCHIVE.with_suffix(".zip.partial")
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Lumo-source-evidence-review"}), timeout=45) as response:
            assert response.status == 200
            if response.headers.get("Content-Length"):
                assert int(response.headers["Content-Length"]) == expected_size
            downloaded = 0
            digest = hashlib.sha256()
            with partial.open("xb") as output:
                for chunk in iter(lambda: response.read(4 * 1024 * 1024), b""):
                    downloaded += len(chunk)
                    assert downloaded <= expected_size
                    digest.update(chunk)
                    output.write(chunk)
        assert downloaded == expected_size and digest.hexdigest() == expected_digest
        partial.rename(ARCHIVE)
    assert ARCHIVE.is_file() and not ARCHIVE.is_symlink()
    assert ARCHIVE.stat().st_size == expected_size and digest_file(ARCHIVE) == expected_digest

    previous_index = read_json(ROOT / "qa/studio-2020-native-acf51-review/verified-original-extraction.json")
    extra_names = [entry["artifact_entry"] for entry in previous_index["extra_facial_originals"]]
    assert len(plan["images"]) == 49 and len({entry["artifact_entry"] for entry in plan["images"]}) == 49
    assert len(extra_names) == 8 and len(set(extra_names)) == 8
    images, extras = [], []
    with zipfile.ZipFile(ARCHIVE) as zipped:
        assert zipped.testzip() is None
        sources = gate.verify_archive_sources(zipped, NATIVE)
        count = len(zipped.infolist())
        for requested in plan["images"]:
            entry = requested["artifact_entry"]
            assert gate.capture_module(entry, studio_version=2020) == requested["module"]
            data = gate.archive_member(zipped, entry)
            dimensions = gate.png_dimensions(data)
            path = RENDER_CACHE / "original-images" / entry
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists():
                assert path.read_bytes() == data
            else:
                path.write_bytes(data)
            images.append({**requested, "local_path": str(path), "bytes": len(data),
                           "sha256": hashlib.sha256(data).hexdigest(), "dimensions": dimensions})
        for entry in extra_names:
            assert entry.startswith("studio-evidence/captures/lumo_facial_capture/")
            data = gate.archive_member(zipped, entry)
            path = RENDER_CACHE / "facial-originals" / entry
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists():
                assert path.read_bytes() == data
            else:
                path.write_bytes(data)
            extras.append({"artifact_entry": entry, "local_path": str(path), "bytes": len(data),
                           "sha256": hashlib.sha256(data).hexdigest()})
    result = {
        "schema": 1, "status": "original archive verified; fresh image inspection pending",
        "verified_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "native": NATIVE, "run_id": RUN_ID, "artifact_id": artifact["id"],
        "archive_path": str(ARCHIVE), "download_url": url,
        "bytes": expected_size, "sha256": expected_digest, "zip_entries": count,
        "all_entries_crc_valid": True, "archive_source_stamps": sources,
        "review_images": images, "extra_facial_originals": extras,
        "prior_capture_paths_reused": True, "prior_hashes_or_findings_reused": False,
    }
    (REVIEW / "verified-original-extraction.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: value for key, value in result.items()
                      if key not in ("review_images", "extra_facial_originals")}, ensure_ascii=False))
    print(json.dumps({"images": len(images), "image_bytes": sum(row["bytes"] for row in images),
                      "facial_extras": len(extras), "extra_bytes": sum(row["bytes"] for row in extras)}))


if __name__ == "__main__":
    main()

