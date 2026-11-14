#!/usr/bin/env python3
"""Run the unchanged Studio tours against the immutable 4ab APK with a bound QA helper.

This is a diagnostic on an existing binary, never a build, publication or replacement
for the original Studio workflow. Metadata comes from authenticated GitHub read calls.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import zipfile


@dataclass(frozen=True)
class Expected:
    host: str = "4ab96666f954baf258422d6ed277fc297b7ddeef"
    native: str = "803e7a626ea6ef0aeeda9c37010e844033d3a8e3"
    run: int = 43530667812
    build_job: int = 132247240154
    artifact: int = 14089507933
    artifact_bytes: int = 647462973
    artifact_sha256: str = "2bc81726454a0b79e3e7ab9c0668c9359745e4d308e5af6f8b49072e7600ae7c"
    apk_bytes: int = 325295610
    apk_sha256: str = "7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6"
    pck_bytes: int = 66234596
    pck_sha256: str = "28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e"
    package: str = "dev.ullmann.lumo.lumo_lernen.coachpreview"
    certificate: str = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"


EXPECTED = Expected()
ALLOWLIST = frozenset({
    ".github/probes/creative_android_probe.py",
    "tools/android_qa/tests/test_native_caption_ocr.py",
    "tools/android_qa/tests/fixtures/native_caption_ocr/learning-api35-first.png",
    "tools/android_qa/tests/fixtures/native_caption_ocr/learning-api35-last.png",
    "tools/android_qa/tests/fixtures/native_caption_ocr/learning-api37-first.png",
    "tools/android_qa/tests/fixtures/native_caption_ocr/learning-api37-last.png",
    "scripts/recheck_studio_4ab.py",
    "scripts/tests/test_studio_4ab_recheck.py",
    ".github/workflows/lumo-studio-4ab-ocr-recheck.yml",
})
TOURS = (
    ".github/probes/modernization_android_tour.py",
    ".github/probes/lumo_studio_surfaces_android_probe.py",
)
BUILD_STEPS = (
    "Build unified real Android APK",
    "Verify APK archive and collect reproducible source hashes",
    "Upload exact candidate (no release or synthetic screenshots)",
)
IDENTITY_CHECKS = frozenset({
    "sha256_matches_provenance", "sha256_matches_build_sums",
    "flutter_source_is_this_commit", "tracked_source_clean", "godot_revision_is_pinned",
    "signing_certificate", "version_matches_pubspec", "x86_64_native_code",
})


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def read_json(path: Path) -> dict:
    result = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(result, dict), f"JSON object required: {path}")
    return result


def sha256(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def file_record(path: Path) -> dict:
    return {"path": str(path), "bytes": path.stat().st_size, "sha256": sha256(path)}


def write_json(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def git(root: Path, *arguments: str) -> bytes:
    env = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
    return subprocess.check_output(
        ["git", "--no-replace-objects", "-C", str(root), *arguments], env=env,
        stderr=subprocess.PIPE,
    )


def git_tree(root: Path) -> dict[str, dict]:
    result = {}
    for entry in git(root, "ls-tree", "-r", "-z", "HEAD").split(b"\0"):
        if not entry:
            continue
        header, name = entry.split(b"\t", 1)
        mode, kind, blob = header.decode("ascii").split()
        require(kind == "blob" and mode in {"100644", "100755", "120000"},
                "Unreviewed source object or submodule")
        result[name.decode("utf-8")] = {"mode": mode, "git_blob": blob}
    require(bool(result), "Empty source tree")
    return result


def working_blob(path: Path, mode: str) -> tuple[str, int]:
    info = path.lstat()
    if mode == "120000":
        require(stat.S_ISLNK(info.st_mode), f"Tracked symlink mode changed: {path}")
        data = os.fsencode(os.readlink(path))
        return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest(), len(data)
    require(stat.S_ISREG(info.st_mode), f"Tracked regular file replaced: {path}")
    require(bool(info.st_mode & 0o111) == (mode == "100755"), f"Tracked executable mode changed: {path}")
    checksum = hashlib.sha1(b"blob " + str(info.st_size).encode() + b"\0")
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
    return checksum.hexdigest(), info.st_size


def source_checkout(root: Path, expected_head: str, runtime_roots: tuple[Path, ...] = ()) -> tuple[dict, dict]:
    require(bool(re.fullmatch(r"[0-9a-f]{40}", expected_head)), "A complete expected source SHA is required")
    require(Path(git(root, "rev-parse", "--show-toplevel").decode().strip()).resolve() == root,
            "Source argument is not the actual checkout root")
    head = git(root, "rev-parse", "HEAD").decode().strip()
    require(head == expected_head, "Actual source HEAD differs from the declared source")
    require(not git(root, "status", "--porcelain", "--untracked-files=no"),
            "Tracked checkout has staged or unstaged changes")
    tree = git_tree(root)
    checked = []
    for name, entry in sorted(tree.items()):
        path = root / name
        # Parent symlinks must not redirect a nominal source path outside this checkout.
        require(path.parent.resolve().is_relative_to(root), f"Source parent escapes checkout: {name}")
        measured, size = working_blob(path, entry["mode"])
        require(measured == entry["git_blob"], f"Actual tracked source bytes changed: {name}")
        checked.append([name, entry["mode"], measured, size])
    tracked_directories = {(root / name).parent for name in tree}
    for raw in git(root, "ls-files", "--others", "-z").split(b"\0"):
        if not raw:
            continue
        name = raw.decode("utf-8")
        path = root / name
        generated_bytecode = (path.suffix == ".pyc" and path.parent.name == "__pycache__"
                              and path.parent.parent in tracked_directories)
        allowed_runtime = any(path == allowed or path.is_relative_to(allowed) for allowed in runtime_roots)
        require(generated_bytecode or allowed_runtime, f"Untracked source or undeclared runtime path: {name}")
    report = {
        "path": str(root), "head": head,
        "tree": git(root, "rev-parse", "HEAD^{tree}").decode().strip(),
        "tracked_source_clean": True, "actual_blob_and_mode_checks": len(checked),
        "working_files_manifest_sha256": hashlib.sha256(
            json.dumps(checked, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest(),
        "separate_runtime_roots": [str(path) for path in runtime_roots],
        "untracked_scope": "Only declared artifact/checkouts/output/venv/action roots and generated Python bytecode",
    }
    return report, tree


def verify_sources(qa: Path, candidate: Path, expected_qa: str, runtime_roots: tuple[Path, ...],
                   expected: Expected = EXPECTED) -> dict:
    require(qa != candidate and not qa.is_relative_to(candidate), "QA and product checkouts must be distinct")
    qa_report, qa_tree = source_checkout(qa, expected_qa, runtime_roots)
    product_report, product_tree = source_checkout(candidate, expected.host)
    changed = {name for name in qa_tree.keys() | product_tree.keys()
               if qa_tree.get(name) != product_tree.get(name)}
    require(changed == ALLOWLIST,
            f"QA delta differs from the exact nine reviewed paths: unexpected={sorted(changed - ALLOWLIST)}, missing={sorted(ALLOWLIST - changed)}")
    for name in ALLOWLIST:
        require(qa_tree.get(name, {}).get("mode") in {"100644", "100755"},
                f"Allowed QA file is missing or not regular: {name}")
    for root in (qa, candidate):
        require(read_json(root / "config/godot-source.json").get("revision") == expected.native,
                "Actual checkout native pin changed")
        match = re.search(r"^version:\s*(\S+)\s*$", (root / "pubspec.yaml").read_text(), re.M)
        require(match is not None and match[1] == "0.13.7+2019", "Actual checkout version changed")
    for name in TOURS:
        require(name in product_tree and qa_tree[name] == product_tree[name], "An original tour changed")
    return {
        "qa": qa_report, "product": product_report,
        "unchanged_other_git_entries": len((qa_tree.keys() | product_tree.keys()) - changed),
        "reviewed_delta": [{"path": name, "before": product_tree.get(name), "after": qa_tree[name],
                            "sha256": sha256(qa / name)} for name in sorted(changed)],
        "executed_tour_files": [file_record(qa / name) for name in TOURS],
        "helper": file_record(qa / ".github/probes/creative_android_probe.py"),
    }


def verify_metadata(metadata: Path, expected: Expected = EXPECTED) -> dict:
    artifact = read_json(metadata / "artifact.json")
    run = read_json(metadata / "run.json")
    job = read_json(metadata / "build-job.json")
    require(artifact.get("id") == expected.artifact and artifact.get("name") == "lumo-studio-2019-candidate"
            and artifact.get("size_in_bytes") == expected.artifact_bytes
            and artifact.get("digest") == "sha256:" + expected.artifact_sha256
            and artifact.get("expired") is False, "Original artifact identity differs")
    origin = artifact.get("workflow_run", {})
    require(origin.get("id") == expected.run and origin.get("head_sha") == expected.host,
            "Original artifact source or run differs")
    require(run.get("id") == expected.run and type(run.get("run_attempt")) is int and run["run_attempt"] == 1
            and run.get("head_sha") == expected.host
            and run.get("repository", {}).get("full_name") == "Ullmann27/lumo-lernen"
            and run.get("path") == ".github/workflows/lumo-studio-2019.yml",
            "Original workflow source, identity or attempt differs")
    # The original run failed later Android checks; only its immutable builder must be successful.
    require(job.get("id") == expected.build_job and job.get("run_id") == expected.run
            and type(job.get("run_attempt")) is int and job["run_attempt"] == 1 and job.get("head_sha") == expected.host
            and job.get("name") == "verify-and-build" and job.get("status") == "completed"
            and job.get("conclusion") == "success", "The exact original builder did not succeed")
    for name in BUILD_STEPS:
        matches = [step for step in job.get("steps", []) if step.get("name") == name]
        require(len(matches) == 1 and matches[0].get("status") == "completed"
                and matches[0].get("conclusion") == "success", f"Original build step did not succeed: {name}")
    return {"original_run": expected.run, "original_build_job": expected.build_job,
            "original_artifact": expected.artifact, "artifact_archive_digest_from_github_metadata": expected.artifact_sha256,
            "original_run_conclusion": run.get("conclusion"),
            "original_metadata_files": [file_record(metadata / name) for name in ("artifact.json", "run.json", "build-job.json")]}


def verify_apk(apk: Path, provenance: Path, sums: Path, expected: Expected = EXPECTED) -> dict:
    measured = sha256(apk)
    require(apk.stat().st_size == expected.apk_bytes and measured == expected.apk_sha256,
            "Actual APK bytes differ from the original 4ab binary")
    proof = read_json(provenance)
    fields = {"package": expected.package, "versionName": "0.13.7", "versionCode": 2019,
              "flutter_source_commit": expected.host, "tracked_source_clean": True,
              "abis": ["x86_64"], "bytes": expected.apk_bytes, "sha256": measured,
              "signingCertificateSha256": expected.certificate}
    require(all(type(proof.get(k)) is type(v) and proof.get(k) == v for k, v in fields.items()),
            "Actual original provenance differs")
    native = proof.get("godot", {})
    require(native.get("revision") == expected.native and native.get("engine") == "4.6.3"
            and native.get("pck_sha256") == expected.pck_sha256
            and type(native.get("bytes")) is int and native["bytes"] == expected.pck_bytes,
            "Native provenance differs")
    lines = [line.split(maxsplit=1) for line in sums.read_text().splitlines() if line.strip()]
    require(len(lines) == 1 and len(lines[0]) == 2 and lines[0][0] == measured
            and lines[0][1].lstrip("*") == "dist/x86_64/Lumo-Lernen-Neu.apk", "Original tour checksum differs")
    with zipfile.ZipFile(apk) as archive:
        for name in ("assets/lumo_game.pck", "assets/lumo_game_source.json"):
            require(archive.namelist().count(name) == 1, f"Missing or duplicated embedded asset: {name}")
        checksum = hashlib.sha256()
        size = 0
        with archive.open("assets/lumo_game.pck") as stream:
            header = stream.read(20)
            require(len(header) == 20 and header[:4] == b"GDPC", "Embedded pack is not a Godot PCK")
            checksum.update(header)
            size += len(header)
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                checksum.update(chunk)
                size += len(chunk)
        require(size == expected.pck_bytes and checksum.hexdigest() == expected.pck_sha256,
                "Actual embedded PCK differs")
        require(json.loads(archive.read("assets/lumo_game_source.json")) == native,
                "Embedded native source differs from original provenance")
    return {"host": expected.host, "native": expected.native,
            "apk": {"path": str(apk), "bytes": apk.stat().st_size, "sha256": measured},
            "pck_bytes": size, "pck_sha256": checksum.hexdigest(),
            "provenance": file_record(provenance), "sums": file_record(sums),
            "signature_scope": "Exact original signed APK bytes; certificate from original verified build provenance. No new signing claim."}


def verify_runtime_reports(qa: Path, out: Path, api: int, expected: Expected = EXPECTED) -> dict:
    tour = read_json(out / "tour-result.json")
    surfaces = read_json(out / "nextgen/native-surfaces-result.json")
    require(tour.get("status") == "PASS" and tour.get("apk_sha256") == expected.apk_sha256,
            "Original complete tour did not pass")
    require(surfaces.get("status") == "PASS" and isinstance(surfaces.get("learning"), dict)
            and isinstance(surfaces.get("cards"), dict), "Studio learning and Cards did not both complete")
    identities = [step for step in tour.get("steps", []) if step.get("step") == "apk-identity"]
    require(len(identities) == 1 and identities[0].get("ok") is True, "Missing original runtime APK identity")
    for identity in (identities[0], surfaces.get("apk_identity", {})):
        expected_fields = {"apk_sha256": expected.apk_sha256, "flutter_source_commit": expected.host,
                           "godot_revision": expected.native, "godot_pck_sha256": expected.pck_sha256,
                           "versionCode": 2019, "versionName": "0.13.7",
                           "signingCertificateSha256": expected.certificate}
        require(all(identity.get(k) == v for k, v in expected_fields.items())
                and set(identity.get("checks", {})) == IDENTITY_CHECKS
                and all(v is True for v in identity["checks"].values()), "Runtime APK/PCK identity differs")
    # This file is covered by the all-other-files equality check. Reuse its unchanged rules.
    spec = importlib.util.spec_from_file_location("_studio_4ab_runtime_verifier", qa / "scripts/verify_studio_delivery.py")
    require(spec is not None and spec.loader is not None, "Original runtime verifier unavailable")
    verifier = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(verifier)
    runtime = verifier.verify_android_runtime(surfaces, api)
    verifier.verify_tour_android_runtime(tour, runtime)
    return {"android_runtime": runtime, "tour": file_record(out / "tour-result.json"),
            "surfaces": file_record(out / "nextgen/native-surfaces-result.json")}


def collect_binding(args: argparse.Namespace, expected: Expected = EXPECTED) -> dict:
    runtime_roots = (args.candidate_source, args.apk.parent.parent, args.out,
                     args.qa_source / ".probe-venv", args.qa_source / "runner-actions/android-emulator-runner")
    return {"sources": verify_sources(args.qa_source, args.candidate_source, args.expected_qa_source,
                                      runtime_roots, expected),
            "original_build": verify_metadata(args.metadata_dir, expected),
            "binary": verify_apk(args.apk, args.provenance, args.sums, expected),
            "expected_api": args.expected_api}


def run_tours(args: argparse.Namespace, commands: list, runner=subprocess.run) -> None:
    common = ["--apk", str(args.apk), "--provenance", str(args.provenance), "--sums", str(args.sums)]
    tasks = [
        [sys.executable, "-B", str(args.qa_source / TOURS[0]), *common, "--out", str(args.out)],
        [sys.executable, "-B", str(args.qa_source / TOURS[1]), *common,
         "--prior-tour", str(args.out / "tour-result.json"), "--expected-api", str(args.expected_api),
         "--out", str(args.out / "nextgen")],
    ]
    for command in tasks:
        entry = {"command": command, "cwd": str(args.candidate_source),
                 "started_at": datetime.now(timezone.utc).isoformat()}
        commands.append(entry)
        completed = runner(command, cwd=args.candidate_source, check=False)
        entry.update(returncode=completed.returncode, finished_at=datetime.now(timezone.utc).isoformat())
        require(completed.returncode == 0, f"Unchanged original tour failed with exit {completed.returncode}: {command[2]}")


def execute(args: argparse.Namespace) -> int:
    target = args.out / "recheck"
    # Reject invalid output locations before any diagnostic write can touch source.
    declared = {
        "candidate_source": "candidate-source", "metadata_dir": "tour/build-metadata",
        "apk": "candidate/dist/x86_64/Lumo-Lernen-Neu.apk",
        "provenance": "candidate/dist/x86_64/BUILD-PROVENANCE.json",
        "sums": "candidate/dist/ANDROID-TOUR-SHA256SUMS.txt", "out": "tour",
    }
    if any(getattr(args, key) != args.qa_source / value for key, value in declared.items()):
        print("Only the workflow's explicit, separate product/artifact/output paths are accepted", file=sys.stderr)
        return 1
    if (target / "result.json").exists() or (args.verify_only and (target / "preflight.json").exists()):
        print("Original diagnostic result already exists; use a fresh output", file=sys.stderr)
        return 1
    report = {"status": "RUNNING", "diagnostic_only": True, "build_or_publish_performed": False,
              "physical_fold7_performance_measured": False, "commands": [],
              "expected_qa_source": args.expected_qa_source, "apk_source": EXPECTED.host,
              "native_source": EXPECTED.native, "requested_api": args.expected_api,
              "diagnostic_github_run": os.environ.get("GITHUB_RUN_ID"),
              "diagnostic_github_attempt": os.environ.get("GITHUB_RUN_ATTEMPT")}
    before = None
    after = None
    try:
        declared_ci = os.environ.get("GITHUB_SHA")
        require(not declared_ci or declared_ci == args.expected_qa_source, "Expected QA source differs from actual CI source")
        before = collect_binding(args)
        if args.verify_only:
            write_json(target / "preflight.json", {**report, "status": "PASS", "binding": before,
                                                   "scope": "Identity only; Android has not been tested"})
            print(json.dumps({"status": "IDENTITY_PREFLIGHT_PASS", "report": str(target / "preflight.json")}))
            return 0
        preflight = read_json(target / "preflight.json")
        require(preflight.get("status") == "PASS" and preflight.get("binding") == before,
                "Measured preflight binding changed before emulator tour")
        require(not (args.out / "tour-result.json").exists()
                and not (args.out / "nextgen/native-surfaces-result.json").exists(),
                "Old runtime reports cannot be reused")
        write_json(target / "before.json", {"status": "PASS", "binding": before})
        try:
            run_tours(args, report["commands"])
        finally:
            # Preserve a genuine post-execution binding even when the original tour fails.
            after = collect_binding(args)
            write_json(target / "after.json", {"status": "PASS" if after == before else "FAIL", "binding": after})
            require(after == before, "Sources, original metadata or binary bytes changed during the tour")
        report["runtime_reports"] = verify_runtime_reports(args.qa_source, args.out, args.expected_api)
        report["status"] = "PASS"
    except Exception as error:
        report.update(status="FAIL", error=f"{type(error).__name__}: {error}")
        if not args.verify_only and before is not None and after is None:
            write_json(target / "after.json", {"status": "UNVERIFIED", "error": report["error"]})
    report["finished_at"] = datetime.now(timezone.utc).isoformat()
    report["before_binding_verified"] = before is not None
    report["after_binding_matches"] = after is not None and after == before
    output = target / ("preflight.json" if args.verify_only else "result.json")
    write_json(output, report)
    print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
    return 0 if report["status"] == "PASS" else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("qa-source", "candidate-source", "metadata-dir", "apk", "provenance", "sums", "out"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--expected-qa-source", required=True)
    parser.add_argument("--expected-api", type=int, choices=(35, 37), required=True)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    for name in ("qa_source", "candidate_source", "metadata_dir", "apk", "provenance", "sums", "out"):
        setattr(args, name, getattr(args, name).resolve())
    require(Path(__file__).resolve() == args.qa_source / "scripts/recheck_studio_4ab.py",
            "The running binder must belong to the measured QA checkout")
    return execute(args)


if __name__ == "__main__":
    raise SystemExit(main())
