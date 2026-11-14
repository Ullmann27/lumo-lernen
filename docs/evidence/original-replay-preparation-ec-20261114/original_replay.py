#!/usr/bin/env python3
"""Read the exact accepted ec original archives without executing games or Android."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import re
import stat
import subprocess
import sys
from types import SimpleNamespace
import zipfile

HOST = "ec936873a45ffeb9ab347cc6bdb10951e38fac5e"
HOST_TREE = "c7d6541e474f8d8ba64b204beb6466c811fb246b"
NATIVE = "84789d0c2c6fb4b6ecd2897ce1951b89f958b604"
NATIVE_TREE = "91cc8fc1c6f8a36336b7ac9a12585284a983a6f6"
RUN = 43633922088
ATTEMPT = 1
PR = 497
REPOSITORY = "Ullmann27/lumo-lernen"
ROOT = Path.cwd().resolve()
OUTPUT = ROOT / "publication/reader-replay"
EXTRACTED = ROOT / "original-review/extracted"
ARCHIVES = ROOT / "original-review/archives"
MAX_ARCHIVE = 4 * 1024**3
MAX_MEMBER = 2 * 1024**3
MAX_UNCOMPRESSED = 12 * 1024**3
DESTINATIONS = {
    "lumo-connect-four-2020-candidate": "candidate/dist",
    "lumo-connect-four-2020-desktop-runtime": "proofs/runtime",
    "lumo-connect-four-2020-android-host-compile": "proofs/host",
    "lumo-connect-four-2020-android-c4": "proofs/android",
    "lumo-connect-four-2020-in-place-update-proof": "proofs/update",
    "lumo-connect-four-2020-candidate-verification": "proofs/final",
    "lumo-connect-four-2020-build-contracts": "proofs/contracts",
    "lumo-candidate-pinned-native-gameplay": "proofs/native",
    "lumo-connect-four-2020-learning-curriculum-audit": "proofs/learning",
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def unique_json(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "Duplicate JSON key: " + key)
        result[key] = value
    return result


def read(path):
    require(path.is_file() and not path.is_symlink(), "Regular JSON file required")
    return json.loads(
        path.read_bytes(), object_pairs_hook=unique_json,
        parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)),
    )


def record(path):
    require(path.is_file() and not path.is_symlink(), "Regular file required: " + str(path))
    with path.open("rb") as handle:
        digest = hashlib.file_digest(handle, "sha256").hexdigest()
    return {"bytes": path.stat().st_size, "sha256": digest}


def write_new(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8") as handle:
        handle.write(json.dumps(value, indent=2, sort_keys=True) + "\n")


def safe_members(archive):
    members = archive.infolist()
    require(bool(members), "Empty original archive")
    require(len(members) <= 100000, "Original archive member limit exceeded")
    names = set()
    directories = set()
    expanded = 0
    for member in members:
        raw = member.filename
        name = raw[:-1] if member.is_dir() else raw
        path = PurePosixPath(name)
        require(raw == member.orig_filename and bool(name) and "\x00" not in raw,
                "Invalid ZIP member name")
        require("\\" not in raw and ":" not in raw and not path.is_absolute()
                and bool(path.parts) and all(part not in ("", ".", "..") for part in path.parts)
                and str(path) == name, "Unsafe ZIP member path: " + repr(raw))
        require(name not in names, "Duplicate ZIP member path: " + name)
        names.add(name)
        if member.is_dir():
            require(member.file_size == 0, "Directory ZIP member contains payload")
            directories.add(name)
        kind = stat.S_IFMT(member.external_attr >> 16)
        expected = (0, stat.S_IFDIR) if member.is_dir() else (0, stat.S_IFREG)
        require(kind in expected and not (member.flag_bits & 1),
                "Special or encrypted ZIP member rejected: " + name)
        require(0 <= member.file_size <= MAX_MEMBER, "ZIP member exceeds byte limit")
        expanded += member.file_size
        require(expanded <= MAX_UNCOMPRESSED, "Original archive expansion exceeds byte limit")
    for member in members:
        path = PurePosixPath(member.filename.rstrip("/"))
        for parent in path.parents:
            if str(parent) == ".":
                continue
            require(str(parent) not in names or str(parent) in directories,
                    "ZIP file is also used as a parent directory")
    return members


def unpack_verified(archive_path, destination, metadata):
    original = record(archive_path)
    require(type(metadata.get("size_in_bytes")) is int
            and 0 < metadata["size_in_bytes"] <= MAX_ARCHIVE
            and original["bytes"] == metadata["size_in_bytes"],
            "Original ZIP byte count differs from API metadata")
    require(metadata.get("digest") == "sha256:" + original["sha256"],
            "Original ZIP digest differs from API metadata")
    require(not destination.exists() and not destination.is_symlink(),
            "Refusing to replace an extraction directory")
    with zipfile.ZipFile(archive_path) as archive:
        members = safe_members(archive)
        require(archive.testzip() is None, "Original ZIP CRC failure")
        destination.mkdir(parents=True)
        files = []
        for member in members:
            target = destination / member.filename
            require(target.resolve().is_relative_to(destination.resolve()),
                    "ZIP target escapes extraction root")
            if member.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            digest = hashlib.sha256()
            count = 0
            with archive.open(member) as source, target.open("xb") as output:
                for block in iter(lambda: source.read(1024 * 1024), b""):
                    count += len(block)
                    require(count <= member.file_size, "ZIP stream exceeds declared size")
                    digest.update(block)
                    output.write(block)
            require(count == member.file_size, "Truncated original ZIP member")
            files.append({
                "path": member.filename, "bytes": count,
                "sha256": digest.hexdigest(), "zip_crc32": format(member.CRC, "08x"),
                "zip_mode": member.external_attr >> 16,
            })
    require(record(archive_path) == original, "Original ZIP changed during extraction")
    return {"archive": original, "member_count": len(members),
            "files": sorted(files, key=lambda row: row["path"])}


def file_inventory(root):
    require(root.is_dir() and not root.is_symlink(), "Regular original directory required")
    result = {}
    for path in sorted(root.rglob("*")):
        require(not path.is_symlink(), "Original evidence symlink rejected")
        if path.is_file():
            result[path.relative_to(root).as_posix()] = {
                **record(path), "mode": stat.S_IMODE(path.stat().st_mode),
            }
        else:
            require(path.is_dir(), "Special original evidence entry rejected")
    return result


def git_output(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args])


def source_snapshot(root, expected_head, expected_tree):
    head = git_output(root, "rev-parse", "HEAD").decode().strip()
    tree = git_output(root, "rev-parse", "HEAD^{tree}").decode().strip()
    require(head == expected_head and tree == expected_tree, "Source checkout identity differs")
    subprocess.run(["git", "-C", str(root), "diff", "--exit-code", "HEAD", "--"], check=True)
    staged = git_output(root, "ls-files", "--stage", "-z")
    rows = []
    for entry in staged.split(b"\0"):
        if not entry:
            continue
        metadata, encoded_path = entry.split(b"\t", 1)
        git_mode, blob, stage = metadata.decode("ascii").split()
        require(stage == "0" and git_mode in ("100644", "100755", "120000"),
                "Unmerged or unsupported source entry")
        name = os.fsdecode(encoded_path)
        path = root / name
        if git_mode == "120000":
            require(path.is_symlink(), "Tracked source symlink changed type")
            payload = os.fsencode(os.readlink(path))
            actual_mode = "symlink"
        else:
            require(path.is_file() and not path.is_symlink(), "Tracked source file changed type")
            payload = path.read_bytes()
            actual_mode = stat.S_IMODE(path.stat().st_mode)
            require(bool(actual_mode & 0o111) == (git_mode == "100755"),
                    "Tracked source executable mode differs")
        object_hash = hashlib.sha1(b"blob " + str(len(payload)).encode() + b"\0" + payload).hexdigest()
        require(object_hash == blob, "Materialized source bytes differ from committed Git blob: " + name)
        rows.append({"path": name, "git_mode": git_mode, "blob": blob,
                     "bytes": len(payload), "sha256": hashlib.sha256(payload).hexdigest(),
                     "materialized_mode": actual_mode})
    index_path = Path(os.fsdecode(git_output(root, "rev-parse", "--git-path", "index")).strip())
    if not index_path.is_absolute():
        index_path = root / index_path
    return {"head": head, "tree": tree, "raw_index": record(index_path),
            "files": sorted(rows, key=lambda row: row["path"])}


def modules():
    require(os.environ.get("PYTHONDONTWRITEBYTECODE") == "1"
            and os.environ.get("GIT_OPTIONAL_LOCKS") == "0",
            "Read-only Python and Git settings are required")
    sys.dont_write_bytecode = True
    sys.path.insert(0, str(ROOT / "scripts"))
    import verify_connect_four_delivery as delivery
    import verify_connect_four_candidate as candidate
    require(Path(delivery.__file__).resolve() == ROOT / "scripts/verify_connect_four_delivery.py"
            and Path(candidate.__file__).resolve() == ROOT / "scripts/verify_connect_four_candidate.py",
            "Verifier imports escaped the accepted checkout")
    return delivery, candidate


def identity():
    require(os.environ.get("GITHUB_REPOSITORY") == REPOSITORY
            and os.environ.get("SOURCE_SHA") == HOST
            and os.environ.get("ACCEPTANCE_RUN") == str(RUN)
            and os.environ.get("ACCEPTANCE_ATTEMPT") == str(ATTEMPT)
            and os.environ.get("ACCEPTANCE_PR") == str(PR), "Reader environment binding differs")
    require(git_output(ROOT, "rev-parse", "HEAD").decode().strip() == HOST,
            "Original host source is not checked out")
    require(read(ROOT / "config/godot-source.json")["revision"] == NATIVE,
            "Host native pin differs")


def extract():
    identity()
    delivery, _ = modules()
    facts = delivery.read(ROOT / "publication/delivery/assets/C4-DELIVERY-FACTS.json")
    metadata = delivery.read(ROOT / "publication/metadata/artifacts.json")
    originals = delivery.checked_artifacts(metadata, facts["binding"])
    require(originals == facts["original_artifacts"]
            and set(originals) == set(DESTINATIONS) == set(delivery.ARTIFACT_NAMES),
            "Original artifact roster differs from delivery")
    require(not ARCHIVES.exists() and not EXTRACTED.exists(), "Original archive area already exists")
    ARCHIVES.mkdir(parents=True)
    outputs = {}
    for name, destination in DESTINATIONS.items():
        row = originals[name]
        archive_path = ARCHIVES / (name + ".zip")
        with archive_path.open("xb") as output:
            subprocess.run(["gh", "api", f"repos/{REPOSITORY}/actions/artifacts/{row['id']}/zip"],
                           stdout=output, check=True)
        manifest = unpack_verified(archive_path, EXTRACTED / destination, row)
        outputs[name] = {"metadata": row, "destination": destination, **manifest}
        print("ORIGINAL_ARCHIVE_VERIFIED " + json.dumps({
            "name": name, "artifact_id": row["id"], "bytes": row["size_in_bytes"],
            "sha256": manifest["archive"]["sha256"], "files": len(manifest["files"]),
        }, sort_keys=True), flush=True)
    write_new(OUTPUT / "original-archives.json", {"artifacts": outputs})
    write_new(OUTPUT / "original-files-before.json", file_inventory(EXTRACTED))


def replay():
    identity()
    delivery, candidate = modules()
    native_source = ROOT / "native-source"
    before = {"host": source_snapshot(ROOT, HOST, HOST_TREE),
              "native": source_snapshot(native_source, NATIVE, NATIVE_TREE)}
    write_new(OUTPUT / "source-snapshots-before.json", before)
    original_files = read(OUTPUT / "original-files-before.json")
    require(file_inventory(EXTRACTED) == original_files, "Original evidence changed before replay")
    facts = delivery.read(ROOT / "publication/delivery/assets/C4-DELIVERY-FACTS.json")
    originals = read(OUTPUT / "original-archives.json")["artifacts"]
    upload = originals["lumo-connect-four-2020-candidate"]["metadata"]
    args = SimpleNamespace(
        source=HOST, build_run=RUN, run_attempt=ATTEMPT,
        artifact_id=upload["id"], artifact_digest=upload["digest"],
        candidate=EXTRACTED / "candidate/dist", runtime=EXTRACTED / "proofs/runtime/runtime",
        host_compile=EXTRACTED / "proofs/host", android=EXTRACTED / "proofs/android",
        update=EXTRACTED / "proofs/update", metadata=ROOT / "publication/metadata",
    )
    fresh = candidate.verify(args)
    expected_candidate = delivery.read(EXTRACTED / "proofs/final/C4-CANDIDATE-FACTS.json")
    require(fresh == expected_candidate
            and delivery.record(EXTRACTED / "proofs/final/C4-CANDIDATE-FACTS.json")
            == facts["original_candidate_facts"], "Fresh full candidate replay differs")
    require(fresh == delivery.read(ROOT / "publication/delivery/assets/C4-CANDIDATE-FACTS.json"),
            "Delivery candidate facts differ from original candidate artifact")
    native = delivery.checked_native(EXTRACTED / "proofs/native", native_source, NATIVE)
    require(native == facts["native"], "Fresh Native original replay differs")
    pcm = delivery.checked_pcm_log(EXTRACTED / "proofs/contracts/build-contracts.log")
    pcm["sources"] = delivery.committed_pcm_sources()
    require(pcm == facts["pcm"], "Fresh complete scripts/PCM replay differs")
    additional = delivery.checked_additional_native_logs(args.runtime)
    require(additional == facts["additional_native_regressions"], "Fresh additional runtime replay differs")
    learning = delivery.checked_learning_audit(EXTRACTED / "proofs/learning", facts["binding"])
    require(learning == facts["learning_audit"], "Fresh original learning audit differs")
    return_path = EXTRACTED / "proofs/native/connect-four-return.log"
    return_lines = return_path.read_text(encoding="utf-8").splitlines()
    require(return_lines.count("CONNECT_FOUR_RETURN_PASS checks=21") == 1
            and sum(line.startswith("CONNECT_FOUR_RETURN_") for line in return_lines) == 1
            and not re.search(r"ERROR:|SCRIPT ERROR:|Parse Error:", "\n".join(return_lines)),
            "Separate original Native return log fails its existing strict contract")
    require(fresh["apks"]["arm64-v8a"] == facts["apks"]["arm64-v8a"]
            and fresh["apks"]["x86_64"] == facts["apks"]["x86_64"],
            "Both freshly verified original APK facts must match delivery")
    after = {"host": source_snapshot(ROOT, HOST, HOST_TREE),
             "native": source_snapshot(native_source, NATIVE, NATIVE_TREE)}
    write_new(OUTPUT / "source-snapshots-after.json", after)
    require(before == after, "Source bytes, modes or raw Git index changed during reader replay")
    files_after = file_inventory(EXTRACTED)
    write_new(OUTPUT / "original-files-after.json", files_after)
    require(files_after == original_files, "Original evidence bytes or modes changed during reader replay")
    for name, row in originals.items():
        require(record(ARCHIVES / (name + ".zip")) == row["archive"],
                "Original downloaded archive changed during replay")
    results = {
        "schema": 1, "status": "ORIGINAL_READERS_REPLAYED_AWAITING_FINAL_METADATA",
        "host_source": HOST, "host_tree": HOST_TREE, "native_source": NATIVE,
        "native_tree": NATIVE_TREE, "acceptance_run": RUN, "acceptance_attempt": ATTEMPT,
        "reader_run": int(os.environ["GITHUB_RUN_ID"]),
        "reader_attempt": int(os.environ["GITHUB_RUN_ATTEMPT"]),
        "reader_workflow_commit": os.environ["GITHUB_SHA"],
        "original_archives": {name: row["metadata"] for name, row in originals.items()},
        "original_file_count": len(original_files), "all_originals_unchanged": True,
        "sources_unchanged": True,
        "tracked_source_counts": {name: len(row["files"]) for name, row in before.items()},
        "candidate": fresh, "native": native, "pcm": pcm,
        "additional_native_regressions": additional, "learning_audit": learning,
        "separate_native_return": {"checks": 21, "original": record(return_path)},
        "python_version": platform.python_version(),
        "scope": "Additional automatic read-only replay of exact current original archives on a separate GitHub runner.",
        "new_game_execution": False, "new_android_execution": False,
        "new_human_visual_review": False, "fresh_movie_decode": False,
        "physical_arm64_tested": False, "measured_device_fps": None,
        "audible_android_pcm_approved": False, "published": False,
    }
    write_new(OUTPUT / "reader-results.json", results)


def finalize():
    identity()
    delivery, _ = modules()
    original_bundle = delivery.read(ROOT / "publication/metadata/bundle.json")
    checked = delivery.checked_current(
        ROOT / "publication/delivery", ROOT / "publication/metadata-after",
        ROOT / "publication/original-bundle.zip", original_bundle["id"], PR,
    )
    results = read(OUTPUT / "reader-results.json")
    require(results["status"] == "ORIGINAL_READERS_REPLAYED_AWAITING_FINAL_METADATA"
            and results["host_source"] == HOST and results["native_source"] == NATIVE
            and results["acceptance_run"] == RUN and results["acceptance_attempt"] == ATTEMPT,
            "Reader result binding differs")
    results["status"] = "PASS_EXACT_ORIGINALS_REPLAYED"
    results["fresh_current_acceptance"] = checked
    write_new(OUTPUT / "ORIGINAL-REPLAY-RECEIPT.json", results)
    summary = {
        "status": results["status"], "host_source": HOST, "native_source": NATIVE,
        "acceptance_run": RUN, "acceptance_attempt": ATTEMPT,
        "reader_run": results["reader_run"], "reader_attempt": results["reader_attempt"],
        "original_archives": len(results["original_archives"]),
        "original_files": results["original_file_count"],
        "native_modes": results["native"]["core_modes"], "script_tests": results["pcm"]["tests"],
        "source_files": results["tracked_source_counts"],
        "all_originals_unchanged": results["all_originals_unchanged"],
        "sources_unchanged": results["sources_unchanged"],
        "apks": {abi: {key: row[key] for key in ("bytes", "sha256", "versionCode",
                 "versionName", "signingCertificateSha256")}
                 for abi, row in results["candidate"]["apks"].items()},
        "receipt": record(OUTPUT / "ORIGINAL-REPLAY-RECEIPT.json"),
        "new_human_visual_review": False, "new_game_execution": False,
        "new_android_execution": False, "fresh_movie_decode": False, "published": False,
    }
    write_new(OUTPUT / "summary.json", summary)
    print("LUMO_ORIGINAL_REPLAY_RESULT " + json.dumps(summary, sort_keys=True), flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("extract", "replay", "finalize"))
    args = parser.parse_args()
    {"extract": extract, "replay": replay, "finalize": finalize}[args.command]()


if __name__ == "__main__":
    main()
