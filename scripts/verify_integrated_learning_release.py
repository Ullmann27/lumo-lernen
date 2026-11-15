#!/usr/bin/env python3
"""Validate one source-bound learning release without changing application data."""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess


PROTECTED_BASELINE = "6f4a8c4753f4d06d0b392da0789b8162b2faa71b"
PROTECTED_FILES = frozenset((
    "lib/core/writing_progress_repository.dart",
    "lib/core/writing_target_parser.dart",
    "lib/domain/writing/expanded_writing_template_repository.dart",
    "lib/domain/writing/letter_practice_rules.dart",
    "lib/domain/writing/writing_domain.dart",
    "lib/domain/writing/writing_path_geometry.dart",
    "lib/domain/writing/writing_progress.dart",
    "lib/domain/writing/writing_word_bank.dart",
    "lib/features/journal/journal_repository.dart",
    "lib/features/journal/lumo_journal_screen.dart",
    "lib/features/learning/renderers/writing_task_renderer.dart",
    "lib/features/teacher_mode/letter_writing_screen.dart",
    "lib/features/writing/lumo_writing_coach_screen.dart",
    "lib/features/writing/lumo_writing_word_coach_screen.dart",
    "lib/features/writing/widgets/lumo_ink_surface.dart",
    "lib/features/writing/widgets/lumo_letter_practice_board.dart",
    "lib/features/writing/writing_engine.dart",
    "lib/features/writing/writing_feature_flags.dart",
))


def read_json(path: Path) -> dict:
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"Duplicate JSON key in {path.name}: {key}")
            result[key] = value
        return result

    value = json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=unique)
    if not isinstance(value, dict):
        raise ValueError(f"Expected an object in {path.name}")
    return value


def validate_manifest(release: dict, pubspec: str) -> None:
    if set(release) != {"schemaVersion", "versionName", "versionCode", "releaseTag"}:
        raise ValueError("Unexpected release manifest fields")
    if type(release["schemaVersion"]) is not int or release["schemaVersion"] != 1:
        raise ValueError("Unsupported release manifest schema")
    code, name = release["versionCode"], release["versionName"]
    if type(code) is not int or not 2027 <= code <= 2147483647:
        raise ValueError("Learning release needs an explicit versionCode >= 2027")
    if not isinstance(name, str) or not re.fullmatch(r"\d+\.\d+\.\d+", name):
        raise ValueError("versionName must contain three numeric components")
    versions = re.findall(r"^version:\s*(\S+)\+(\d+)\s*$", pubspec, re.MULTILINE)
    if versions != [(name, str(code))]:
        raise ValueError("pubspec.yaml and release manifest must identify exactly one identical version")
    if release["releaseTag"] != f"lumo-nextgen-learning-{name}-{code}":
        raise ValueError("Release tag must identify the same version as the manifest")


def verify_protected_sources(root: Path, coverage: dict, baseline: str = PROTECTED_BASELINE) -> list[dict]:
    entries = coverage.get("protectedSourceHashes")
    if not isinstance(entries, list) or any(not isinstance(entry, dict) for entry in entries):
        raise ValueError("Missing writing/journal preservation inventory")
    paths = [entry.get("path") for entry in entries]
    if (any(not isinstance(path, str) for path in paths)
            or len(paths) != len(PROTECTED_FILES)
            or set(paths) != PROTECTED_FILES):
        raise ValueError("Preservation inventory must contain exactly the reviewed writing/journal sources")
    if any(entry.get("unchangedFromBase") is not True for entry in entries):
        raise ValueError("Writing/journal inventory must retain its preservation declaration")
    result = []
    for relative in sorted(PROTECTED_FILES):
        path = root / relative
        if path.is_symlink() or not path.is_file():
            raise ValueError("Protected source is missing or is a symbolic link: " + relative)
        original = subprocess.check_output(["git", "show", baseline + ":" + relative], cwd=root)
        actual = path.read_bytes()
        if original != actual:
            raise ValueError("Protected writing/journal source changed: " + relative)
        result.append({"path": relative, "sha256": hashlib.sha256(actual).hexdigest()})
    return result


def verify_release(root: Path, expected_source: str | None = None) -> dict:
    release = read_json(root / "config/nextgen-release.json")
    pubspec = (root / "pubspec.yaml").read_text(encoding="utf-8")
    validate_manifest(release, pubspec)
    native_path = root / "config/godot-source.json"
    native = read_json(native_path)
    if not isinstance(native.get("revision"), str) or not re.fullmatch(r"[0-9a-f]{40}", native["revision"]):
        raise ValueError("Native release needs a full immutable commit SHA")
    policy_path = root / "scripts/verify_legacy_release_pin.py"
    spec = importlib.util.spec_from_file_location("lumo_reviewed_native_policy", policy_path)
    if spec is None or spec.loader is None:
        raise ValueError("Reviewed native source policy cannot be loaded")
    policy = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(policy)
    policy.verify(pubspec, json.dumps(native))
    source = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=root, text=True).strip()
    if expected_source is not None and source != expected_source:
        raise ValueError("Checked-out Flutter source differs from the requested candidate")
    status = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"],
                                     cwd=root, text=True).strip()
    if status:
        raise ValueError("Tracked sources differ from the candidate commit")
    required = ["pubspec.yaml", "config/nextgen-release.json", "config/godot-source.json",
                "scripts/verify_legacy_release_pin.py", "docs/nextgen/COVERAGE.json"]
    subprocess.run(["git", "ls-files", "--error-unmatch", "--", *required], cwd=root,
                   check=True, stdout=subprocess.DEVNULL)
    protected = verify_protected_sources(root, read_json(root / "docs/nextgen/COVERAGE.json"))
    return {"flutter": source, "godot": native, "release": release,
            "protectedBaseline": PROTECTED_BASELINE, "protectedModules": protected,
            "trackedSourceClean": True, "coverageIsAcceptance": False}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--expected-source")
    parser.add_argument("--out", type=Path)
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()
    result = verify_release(args.root.resolve(), args.expected_source)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    if args.github_output:
        values = {"native": result["godot"]["revision"], "version": result["release"]["versionCode"],
                  "version_name": result["release"]["versionName"], "tag": result["release"]["releaseTag"]}
        with args.github_output.open("a", encoding="utf-8") as stream:
            for key, value in values.items():
                stream.write(f"{key}={value}\n")
    print(json.dumps({"status": "PASS", "source": result["flutter"],
                      "versionCode": result["release"]["versionCode"],
                      "protectedFiles": len(result["protectedModules"])}))


if __name__ == "__main__":
    main()
