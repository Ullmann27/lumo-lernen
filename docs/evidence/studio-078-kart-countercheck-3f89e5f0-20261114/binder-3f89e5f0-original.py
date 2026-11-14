#!/usr/bin/env python3
"""Bind a real intro-skip countercheck to the unchanged failed-tour APK.

QA and APK sources remain separate. No product is built, edited or published.
The original failed attempt remains a required, immutable input.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import unicodedata
import zipfile


@dataclass(frozen=True)
class Expected:
    host: str = "078774ddaf64808addaa4c6406f6a3c85b1f239a"
    native: str = "785413d395292a243eaa0a0748671eb15d3f80ff"
    run: int = 43580229005
    build_job: int = 132403230395
    failed_tour_job: int = 132408947901
    artifact: int = 14109135482
    artifact_bytes: int = 664429953
    artifact_sha256: str = "08d9a1bfe7e5c0e7316830df1ba8b8b1b0cd1d3157a56fd24820051d1717c3b9"
    apk_bytes: int = 333778826
    apk_sha256: str = "51af20ad5f0ac6a7196e1f703877805509b39a0ac27303619bc8adde5e0d00fe"
    pck_bytes: int = 74691068
    pck_sha256: str = "aafe4afc0c5c38656b08b86ec382762d0af6b1ae7116b1187db4f2b04bb949a3"
    package: str = "dev.ullmann.lumo.lumo_lernen.coachpreview"
    certificate: str = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"


EXPECTED = Expected()
PROBE = ".github/probes/modernization_android_tour.py"
ALLOWLIST = frozenset({
    PROBE,
    "tools/android_qa/tests/test_kart_preview_skip.py",
    ".github/workflows/lumo-studio-078-kart-recheck.yml",
    "scripts/recheck_studio_078_kart.py",
    "scripts/tests/test_studio_078_kart_recheck.py",
})
HARD_STEPS = (
    "apk-identity", "launch", "onboarding", "navigate-start", "navigate-lernen",
    "atelier-roundtrip", "navigate-spiele", "open-kart", "start-kart-race",
    "race-running", "race-hud", "race-drive", "pause-menu", "return-from-kart",
    "learning-state-after-kart", "lernen-usable-after-kart", "profile-after-kart",
    "restart-keeps-learning-state",
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


def git_tree(root: Path, revision: str = "HEAD") -> dict[str, dict]:
    result = {}
    for entry in git(root, "ls-tree", "-r", "-z", revision).split(b"\0"):
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


def verify_sources(qa: Path, candidate: Path, expected_qa: str,
                   runtime_roots: tuple[Path, ...], expected: Expected = EXPECTED) -> dict:
    require(qa != candidate and not qa.is_relative_to(candidate), "Separate QA and product roots required")
    qa_report, qa_tree = source_checkout(qa, expected_qa, runtime_roots)
    product_report, product_tree = source_checkout(candidate, expected.host)
    require(git(qa, "merge-base", expected.host, expected_qa).decode().strip() == expected.host,
            "QA does not descend from the unchanged APK source")
    changed = {name for name in qa_tree.keys() | product_tree.keys()
               if qa_tree.get(name) != product_tree.get(name)}
    require(changed == ALLOWLIST,
            f"Unreviewed QA delta: unexpected={sorted(changed - ALLOWLIST)}, missing={sorted(ALLOWLIST - changed)}")
    require(all(qa_tree[name]["mode"] == "100644" for name in changed), "QA file mode changed")
    for root in (qa, candidate):
        require(read_json(root / "config/godot-source.json").get("revision") == expected.native,
                "Native source pin changed")
        match = re.search(r"^version:\s*(\S+)\s*$", (root / "pubspec.yaml").read_text(), re.M)
        require(match is not None and match[1] == "0.13.8+2020", "Product version changed")
    return {"qa": qa_report, "product": product_report,
            "reviewed_qa_delta": {name: qa_tree[name] for name in sorted(changed)},
            "unchanged_other_git_entries": len((qa_tree.keys() | product_tree.keys()) - changed)}


def verify_metadata(metadata: Path, expected: Expected = EXPECTED) -> dict:
    run = read_json(metadata / "run.json")
    artifact = read_json(metadata / "artifact.json")
    builder = read_json(metadata / "build-job.json")
    failed = read_json(metadata / "failed-tour-job.json")
    require(run.get("id") == expected.run and run.get("head_sha") == expected.host
            and run.get("run_attempt") == 1 and run.get("status") == "completed"
            and run.get("conclusion") == "failure"
            and run.get("repository", {}).get("full_name") == "Ullmann27/lumo-lernen"
            and run.get("path") == ".github/workflows/lumo-unified-integration-2026.yml",
            "Original failed run identity or immutable attempt changed")
    require(artifact.get("id") == expected.artifact and artifact.get("expired") is False
            and artifact.get("name") == "lumo-lernen-kart-unified-2026-candidate"
            and artifact.get("size_in_bytes") == expected.artifact_bytes
            and artifact.get("digest") == "sha256:" + expected.artifact_sha256
            and artifact.get("workflow_run", {}).get("id") == expected.run
            and artifact.get("workflow_run", {}).get("head_sha") == expected.host,
            "Original APK artifact identity changed")
    for job, job_id, name, conclusion in (
        (builder, expected.build_job, "verify-and-build", "success"),
        (failed, expected.failed_tour_job, "android-tour", "failure"),
    ):
        require(job.get("id") == job_id and job.get("run_id") == expected.run
                and job.get("head_sha") == expected.host and job.get("name") == name
                and job.get("status") == "completed" and job.get("conclusion") == conclusion,
                "Original build or failed tour job identity changed")
    for name in ("Build unified real Android APK",
                 "Verify APK archive and collect reproducible source hashes",
                 "Upload exact candidate (no release or synthetic screenshots)"):
        steps = [step for step in builder.get("steps", []) if step.get("name") == name]
        require(len(steps) == 1 and steps[0].get("conclusion") == "success",
                f"Original successful APK build step missing: {name}")
    return {"original_run": expected.run, "original_conclusion": "failure",
            "original_builder": expected.build_job, "original_failed_tour": expected.failed_tour_job,
            "artifact": expected.artifact,
            "original_metadata": [file_record(metadata / name) for name in
                                  ("run.json", "artifact.json", "build-job.json", "failed-tour-job.json")]}


def verify_apk(apk: Path, provenance: Path, sums: Path, expected: Expected = EXPECTED) -> dict:
    measured = sha256(apk)
    require(apk.stat().st_size == expected.apk_bytes and measured == expected.apk_sha256,
            "Actual APK bytes differ from the original 078 binary")
    proof = read_json(provenance)
    fields = {"package": expected.package, "versionName": "0.13.8", "versionCode": 2020,
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


def verify_preview_skip(out: Path, skip: dict) -> dict:
    require(skip.get("status") == "TOUCH_SENT", "NOT_ISOLATED: no observed intro touch")
    readiness = skip.get("readiness", {})
    require(readiness.get("status") == "TOUCH_SENT"
            and readiness.get("exact_caption_required") is True
            and readiness.get("orientation_policy") == "landscape"
            and readiness.get("label") == skip.get("caption") == "Tippen zum Überspringen"
            and skip.get("countercheck_scope") == "OBSERVED_UI_TOUCH_ONLY"
            and "LumoGameActivity" in skip.get("foreground_before_touch", ""),
            "NOT_ISOLATED: exact observed touch readiness is missing")
    frames = readiness.get("frames", [])
    targets = [frame for frame in frames if frame.get("acceptable_for_target_sampling") is True
               and frame.get("target", {}).get("target_geometry_valid") is True]
    require(len(targets) >= 2 and targets[-1]["target"].get("stable_observed_target") is True,
            "NOT_ISOLATED: two observed stable touch targets are required")
    require(targets[-1].get("source") != targets[-2].get("source"),
            "NOT_ISOLATED: the same capture cannot be counted twice")
    witnesses = []
    for frame in targets[-2:]:
        name = frame.get("source", "")
        require(bool(name) and Path(name).name == name, "Unexpected preview capture path")
        path = out / name
        require(path.is_file() and path.stat().st_size == frame.get("source_bytes")
                and sha256(path) == frame.get("source_sha256")
                and frame["target"].get("surface_sha256") == frame.get("source_sha256"),
                "Observed preview image bytes or target binding changed")
        witnesses.append(file_record(path))
    bounds = readiness.get("final_observed_bounds")
    touch = readiness.get("touch")
    require(isinstance(bounds, list) and len(bounds) == 4 and isinstance(touch, list) and len(touch) == 2
            and bounds == targets[-1]["target"].get("bounds")
            and all(type(value) in (int, float) for value in bounds + touch)
            and all(math.isfinite(value) for value in bounds + touch)
            and bounds[0] <= touch[0] <= bounds[2] and bounds[1] <= touch[1] <= bounds[3],
            "Actual preview touch is not inside the final observed target")
    require(skip.get("touch") == touch, "Preview touch differs between runtime journals")
    require(skip.get("readiness_file") == "21_kart_preview_skip_touch-surface-readiness.json"
            and read_json(out / skip["readiness_file"]) == readiness,
            "Original two-frame readiness journal is missing or different")
    cue = skip.get("cue", {})
    require(cue.get("source") == targets[-1].get("source")
            and sha256(out / cue["source"]) == cue.get("source_sha256")
            and bool(cue.get("observed_matches")), "Final observed preview cue is missing or changed")
    ocr_name = Path(cue["source"]).stem + "-ocr.json"
    require(cue.get("ocr_file") == ocr_name, "Preview cue is not bound to the final actual OCR journal")
    observed_lines = json.loads((out / ocr_name).read_text())
    require(isinstance(observed_lines, list), "Expected original OCR line array")
    wanted = "tippenzumuberspringen"
    matching = [line for line in observed_lines if isinstance(line, dict)
                and re.sub("[^a-z0-9]", "", unicodedata.normalize("NFKD", str(line.get("text", "")))
                           .encode("ascii", "ignore").decode().lower()) == wanted
                and line.get("bounds") == bounds]
    require(bool(matching) and all(line in matching for line in cue["observed_matches"]),
            "Preview cue text or bounds were not actually read from the final image")
    after = skip.get("after_capture", {})
    require(after.get("file") == "21_kart_preview_after_touch.png"
            and sha256(out / after["file"]) == after.get("sha256"),
            "Actual after-touch capture is missing or changed")
    journal = read_json(out / "21_kart_preview_skip.json")
    require(journal == skip, "Tour preview evidence differs from the original skip journal")
    return {"status": "OBSERVED_TOUCH_VERIFIED", "touch": touch,
            "source_frames": witnesses, "cue": file_record(out / cue["source"]),
            "cue_ocr": file_record(out / ocr_name),
            "after_touch": file_record(out / after["file"]),
            "journal": file_record(out / "21_kart_preview_skip.json")}


def verify_runtime_report(out: Path, expected: Expected = EXPECTED) -> dict:
    report = read_json(out / "tour-result.json")
    require(report.get("status") == "PASS" and report.get("apk_sha256") == expected.apk_sha256
            and str(report.get("android_sdk")) == "35" and report.get("fatal_crashes") == 0,
            "The complete real Android 35 tour did not pass")
    steps = report.get("steps", [])
    for name in HARD_STEPS:
        observed = [step for step in steps if step.get("step") == name]
        require(len(observed) == 1 and observed[0].get("ok") is True,
                f"Unchanged hard runtime gate did not pass exactly once: {name}")
    identity = next(step for step in steps if step["step"] == "apk-identity")
    fields = {"apk_sha256": expected.apk_sha256, "flutter_source_commit": expected.host,
              "godot_revision": expected.native, "godot_pck_sha256": expected.pck_sha256,
              "versionCode": 2020, "versionName": "0.13.8",
              "signingCertificateSha256": expected.certificate}
    require(all(identity.get(k) == v for k, v in fields.items())
            and set(identity.get("checks", {})) == IDENTITY_CHECKS
            and all(v is True for v in identity["checks"].values()), "Installed APK identity differs")
    start = next(step for step in steps if step["step"] == "start-kart-race")
    skip = verify_preview_skip(out, start.get("preview_skip", {}))
    return {"tour": file_record(out / "tour-result.json"), "hard_steps": list(HARD_STEPS),
            "preview_skip": skip, "android_api": 35,
            "scope": "Exact existing APK; no physical Fold7 performance acceptance"}


def collect_binding(args: argparse.Namespace) -> dict:
    runtime = (args.candidate_source, args.apk.parent.parent.parent, args.out,
               args.qa_source / ".probe-venv")
    return {"sources": verify_sources(args.qa_source, args.candidate_source,
                                      args.expected_qa_source, runtime),
            "original_build": verify_metadata(args.out / "build-metadata"),
            "binary": verify_apk(args.apk, args.provenance, args.sums)}


def execute(args: argparse.Namespace) -> int:
    expected_paths = {
        "candidate_source": "candidate-source", "apk": "candidate/dist/x86_64/Lumo-Lernen-Neu.apk",
        "provenance": "candidate/dist/x86_64/BUILD-PROVENANCE.json",
        "sums": "candidate/dist/ANDROID-TOUR-SHA256SUMS.txt", "out": "tour",
    }
    require(all(getattr(args, key) == args.qa_source / relative for key, relative in expected_paths.items()),
            "Only separate workflow-declared source, APK and output paths are accepted")
    target = args.out / "recheck"
    require(not (target / "result.json").exists() and not (args.out / "tour-result.json").exists(),
            "Existing runtime results cannot be reused")
    record = {"status": "RUNNING", "diagnostic_only": True, "original_failure_replaced": False,
              "built_or_published_apk": False, "qa_source": args.expected_qa_source,
              "apk_source": EXPECTED.host, "started_at": datetime.now(timezone.utc).isoformat(),
              "run_id": os.environ.get("GITHUB_RUN_ID"), "run_attempt": os.environ.get("GITHUB_RUN_ATTEMPT")}
    before = after = None
    try:
        before = collect_binding(args)
        if args.verify_only:
            require(not (target / "preflight.json").exists(), "Existing preflight cannot be replaced")
            write_json(target / "preflight.json", {**record, "status": "IDENTITY_PREFLIGHT_PASS", "binding": before})
            return 0
        write_json(target / "before.json", before)
        command = [sys.executable, "-B", str(args.qa_source / PROBE), "--apk", str(args.apk),
                   "--provenance", str(args.provenance), "--sums", str(args.sums), "--out", str(args.out),
                   "--skip-observed-kart-preview"]
        record["command"] = command
        record["cwd"] = str(args.candidate_source)
        completed = subprocess.run(command, cwd=args.candidate_source, check=False)
        record["probe_returncode"] = completed.returncode
        after = collect_binding(args)
        write_json(target / "after.json", after)
        require(after == before, "APK or source binding changed during the actual tour")
        require(completed.returncode == 0, "Actual APK countercheck failed")
        record["runtime"] = verify_runtime_report(args.out)
        record["status"] = "PASS"
    except Exception as error:
        record.update(status="FAIL", error=f"{type(error).__name__}: {error}")
        if "NOT_ISOLATED" in str(error):
            record["countercheck_scope"] = "NOT_ISOLATED"
    record.update(finished_at=datetime.now(timezone.utc).isoformat(),
                  before_binding_verified=before is not None,
                  after_binding_matches=after is not None and after == before)
    write_json(target / "result.json", record)
    print(json.dumps(record, ensure_ascii=False, indent=2), flush=True)
    return 0 if record["status"] == "PASS" else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("qa-source", "candidate-source", "apk", "provenance", "sums", "out"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--expected-qa-source", required=True)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args()
    for name in ("qa_source", "candidate_source", "apk", "provenance", "sums", "out"):
        setattr(args, name, getattr(args, name).resolve())
    require(Path(__file__).resolve() == args.qa_source / "scripts/recheck_studio_078_kart.py",
            "The running binder is not from the declared QA checkout")
    return execute(args)


if __name__ == "__main__":
    raise SystemExit(main())
