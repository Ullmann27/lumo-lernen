#!/usr/bin/env python3
"""Bundle the pinned local speech model in the existing generated Android host.

Public model download is build-only, never a child's runtime network request.
No paid speech API, provider key, system TTS or second audio player is added.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import tarfile
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GRADLE_START = "// BEGIN LUMO OFFLINE SPEECH"
GRADLE_END = "// END LUMO OFFLINE SPEECH"


def digest(path: Path) -> str:
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def bundle(root: Path, supplied: Path | None = None) -> dict:
    config = json.loads((root / "config/lumo-offline-voice.json").read_text())
    main = root / "android/app/src/main"
    if not (main / "AndroidManifest.xml").is_file():
        raise ValueError("Prepare the existing Android host first")
    target = main / "assets/lumo_offline_voice"
    target.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="lumo-local-voice-") as scratch:
        archive = supplied or Path(scratch) / "model.tar.bz2"
        if supplied is None:
            subprocess.run(
                ["curl", "-fSL", "--retry", "0", "--max-time", "180",
                 config["bundle_url"], "-o", str(archive)], check=True,
            )
        if digest(archive) != config["bundle_sha256"]:
            raise ValueError("Local model archive digest mismatch")
        with tarfile.open(archive, "r:bz2") as source:
            for name, expected in config["file_sha256"].items():
                member = source.getmember(f'{config["bundle_directory"]}/{name}')
                if not member.isfile() or member.size > 85_000_000:
                    raise ValueError("Unexpected model archive member")
                payload = source.extractfile(member)
                if payload is None:
                    raise ValueError("Missing model payload")
                destination = target / name
                with payload, destination.open("wb") as output:
                    shutil.copyfileobj(payload, output)
                if digest(destination) != expected:
                    raise ValueError(f"Model component digest mismatch: {name}")
    license_source = root / "assets/audio/voice/lumo_free/LICENSE-MODEL.txt"
    if digest(license_source) != config["model_license_sha256"]:
        raise ValueError("Original Open RAIL-M license missing or modified")
    shutil.copyfile(license_source, target / "LICENSE-MODEL.txt")
    shutil.copyfile(root / "assets/audio/voice/lumo_free/LICENSE-CODE.txt",
                    target / "LICENSE-CODE.txt")
    (target / "model-manifest.json").write_text(
        json.dumps(config, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    gradle = next(path for path in (
        root / "android/app/build.gradle.kts", root / "android/app/build.gradle",
    ) if path.is_file())
    existing = gradle.read_text(encoding="utf-8")
    dependency = f'com.microsoft.onnxruntime:onnxruntime-android:{config["onnxruntime_version"]}'
    statement = (f'implementation("{dependency}")' if gradle.suffix == ".kts"
                 else f"implementation '{dependency}'")
    block = (f"{GRADLE_START}\n"
             f"dependencies {{\n    {statement}\n}}\n{GRADLE_END}")
    if GRADLE_START not in existing and GRADLE_END not in existing:
        gradle.write_text(
            existing.rstrip() + f"\n\n{block}\n",
            encoding="utf-8",
        )
    elif existing.count(GRADLE_START) != 1 or existing.count(GRADLE_END) != 1:
        raise ValueError("Invalid local voice dependency markers")
    else:
        start = existing.index(GRADLE_START)
        end = existing.index(GRADLE_END) + len(GRADLE_END)
        if start >= end or existing[start:end].split() != block.split():
            # A previously generated marker is not permission to accept a
            # changed runtime, injected dependency or incomplete block.
            raise ValueError("Local voice dependency does not match the pinned runtime")
    proguard = root / "android/app/proguard-rules.pro"
    rules = proguard.read_text() if proguard.exists() else ""
    keep = "-keep class ai.onnxruntime.** { *; }"
    if keep not in rules:
        proguard.write_text(rules.rstrip() + "\n" + keep + "\n")
    result = {
        "profile": config["profile"], "preset": config["preset"],
        "model_sha256": config["file_sha256"],
        "runtime_cloud_calls": 0, "system_tts": False,
        "model_asset_bytes": sum((target / name).stat().st_size
                                 for name in config["file_sha256"]),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bundle", type=Path)
    args = parser.parse_args()
    bundle(ROOT, args.bundle)
