#!/usr/bin/env python3
"""DIAGNOSTIC_ONLY: three independent UI routes on the exact existing 2029 APK.

This entry never executes or replaces either complete acceptance tour. It cannot
produce a release-eligible result. Each scene uses its own fresh API35 emulator,
real onboarding and the unchanged observed-UI/audio/reference helpers.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import traceback
import urllib.error
import urllib.parse
import urllib.request
import uuid

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SPEC = importlib.util.spec_from_file_location("diagnostic_2029_reference", HERE / "lumo_nextgen_reference_android_probe.py")
reference = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(reference)
learning = reference.learning
require, digest, read_json, write_json = reference.require, reference.digest, reference.read_json, reference.write_json

SOURCE = "684f54a6d11cfb5eccaec30f39fe34d6c17c82cc"
NATIVE = "678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef"
SOURCE_RUN, VALIDATE_JOB, BUILD_JOB, ANDROID_JOB = 43785937519, 133033472392, 133037491223, 133040408296
ARTIFACT_ID, ARTIFACT_NAME = 14191466126, "lumo-nextgen-x86"
ZIP_BYTES, APK_BYTES = 538198271, 538184171
ZIP_SHA = "059ac8a9e2d13d1c52ac35237a465fbfaeba7d7cb6d3de352f47ae6a5113e2c9"
APK_SHA = "01e0c126930b48cb8089f0671ed9238b5dc6ded903e288ad7c1fda452ed3cf0f"
PCK_SHA = "9aeb88d1dc52f612ea591c04d7651ccc3eef8b807b33b8b78c2f82b4e4eea303"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
VERSION, VERSION_NAME = 2029, "0.13.17"
QA_BRANCH = "qa/lumo-nextgen-2029-native-diagnostic-20261116"
SCENES = ("banana", "pattern", "bridge")
NEW_FILES = frozenset((
    ".github/probes/lumo_nextgen_2029_native_diagnostic.py",
    ".github/probes/run_lumo_nextgen_2029_native_diagnostic.sh",
    ".github/workflows/lumo-nextgen-2029-native-diagnostic.yml",
    "tools/android_qa/tests/test_nextgen_2029_native_diagnostic.py",
    "docs/nextgen/NATIVE_DIAGNOSTIC_2029.md",
))
ORIGIN_FILES = ("source-run.json", "source-artifact.json", "source-validate-job.json",
                "source-build-job.json", "source-failed-android-job.json")


def load(path):
    return read_json(Path(path).read_text(encoding="utf-8"))


def verify_ci_context(args, environment):
    require(learning.valid_hex(args.qa_commit, 40) and args.qa_commit != SOURCE,
            "Diagnostic QA must have its own exact commit")
    require(type(args.workflow_run_id) is int and args.workflow_run_id > 0 and args.workflow_run_id != SOURCE_RUN,
            "Diagnostic requires its own workflow run")
    require(args.scene in SCENES and environment.get("LUMO_DIAGNOSTIC_SCENE") == args.scene,
            "Wrong independent diagnostic scene")
    require(environment.get("GITHUB_REPOSITORY") == reference.REPOSITORY and
            environment.get("GITHUB_SHA") == args.qa_commit and
            environment.get("GITHUB_RUN_ID") == str(args.workflow_run_id) and
            environment.get("GITHUB_REF_NAME") == QA_BRANCH,
            "Diagnostic checkout/run/branch/repository mismatch")


def verify_changes(changes):
    require(changes and all(status == "A" and name in NEW_FILES for status, name in changes),
            "Diagnostic may only add its five named QA/handoff files; existing gates/product must be unchanged")


def source_binding(args):
    def git(*arguments):
        return subprocess.check_output(["git", *arguments], cwd=ROOT)

    require(git("rev-parse", "HEAD").decode().strip() == args.qa_commit, "Wrong QA checkout")
    require(not git("status", "--porcelain", "--untracked-files=no").strip(), "Tracked QA checkout changed")
    git("merge-base", "--is-ancestor", SOURCE, args.qa_commit)
    parts = git("diff", "--name-status", "--no-renames", "-z", SOURCE, args.qa_commit).decode().split("\0")
    require(parts[-1] == "" and len(parts) % 2 == 1, "Unexpected source-diff output")
    changes = list(zip(parts[0:-1:2], parts[1:-1:2]))
    verify_changes(changes)
    return {"qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id, "scene": args.scene,
            "apk_source": SOURCE, "source_build_run": SOURCE_RUN,
            "apk_source_tree": git("rev-parse", SOURCE + "^{tree}").decode().strip(),
            "qa_tree": git("rev-parse", args.qa_commit + "^{tree}").decode().strip(),
            "changes": [{"status": status, "path": name} for status, name in changes],
            "runtime_source_changed": False, "existing_acceptance_gates_changed": False}


def fixed_identity(proof):
    identity = learning.verify_provenance(proof, sha256=APK_SHA, source=SOURCE, native=NATIVE,
                                          version=VERSION, certificate=CERTIFICATE)
    require(identity["versionName"] == VERSION_NAME and identity["godot"]["pck_sha256"] == PCK_SHA,
            "Wrong immutable 2029 versionName/native pack")
    return identity


def verify_candidate(directory):
    apk = directory / "Lumo-Lernen-Neu.apk"
    require(apk.is_file() and apk.stat().st_size == APK_BYTES and digest(apk) == APK_SHA,
            "Candidate is not the exact already-built 2029 APK bytes")
    return fixed_identity(load(directory / "BUILD-PROVENANCE.json"))


def verify_origin(run, artifact, validation, build, android):
    require(run.get("id") == SOURCE_RUN and run.get("head_sha") == SOURCE and
            run.get("repository", {}).get("full_name") == reference.REPOSITORY and
            run.get("repository", {}).get("id") == reference.REPOSITORY_ID and
            run.get("path") == ".github/workflows/lumo-nextgen-learning-apk.yml" and
            run.get("status") == "completed" and run.get("conclusion") == "failure",
            "Original source run identity/outcome mismatch; its FAIL is retained")
    for job, number, name, conclusion in ((validation, VALIDATE_JOB, "validate", "success"),
            (build, BUILD_JOB, "build", "success"), (android, ANDROID_JOB, "android", "failure")):
        require(job.get("id") == number and job.get("run_id") == SOURCE_RUN and
                job.get("head_sha") == SOURCE and job.get("name") == name and
                job.get("status") == "completed" and job.get("conclusion") == conclusion,
                "Original source job identity/outcome mismatch: " + name)
    require(any(step.get("name") == "Independently verify both produced artifacts" and
                step.get("conclusion") == "success" for step in build.get("steps", [])),
            "Original independent APK verification did not succeed")
    for key, expected in {"id": ARTIFACT_ID, "name": ARTIFACT_NAME, "size_in_bytes": ZIP_BYTES,
                          "digest": "sha256:" + ZIP_SHA, "expired": False}.items():
        require(type(artifact.get(key)) is type(expected) and artifact[key] == expected,
                "Wrong immutable 2029 artifact field: " + key)
    origin = artifact.get("workflow_run", {})
    require(origin.get("id") == SOURCE_RUN and origin.get("head_sha") == SOURCE and
            origin.get("repository_id") == reference.REPOSITORY_ID and
            origin.get("head_repository_id") == reference.REPOSITORY_ID,
            "Artifact belongs to another source/run/repository")


def download(args):
    verify_ci_context(args, os.environ)
    require(not args.out.exists() or not any(args.out.iterdir()), "Download evidence must be new")
    require(not args.candidate.exists(), "Candidate directory must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    binding = source_binding(args)
    write_json(args.out / "qa-source-binding.json", binding)
    prefix = "/repos/" + reference.REPOSITORY + "/actions/"
    endpoints = ("runs/" + str(SOURCE_RUN), "artifacts/" + str(ARTIFACT_ID),
                 "jobs/" + str(VALIDATE_JOB), "jobs/" + str(BUILD_JOB), "jobs/" + str(ANDROID_JOB))
    records = []
    for name, endpoint in zip(ORIGIN_FILES, endpoints):
        record = reference.api_json(prefix + endpoint)
        write_json(args.out / name, record)
        records.append(record)
    verify_origin(*records)
    try:
        response = urllib.request.build_opener(reference.NoRedirect()).open(
            reference.github_request(prefix + "artifacts/" + str(ARTIFACT_ID) + "/zip"), timeout=45)
    except urllib.error.HTTPError as redirect:
        require(redirect.code == 302, "Artifact redirect failed with HTTP " + str(redirect.code))
        url = redirect.headers.get("Location", "")
        target = urllib.parse.urlsplit(url)
        require(target.scheme == "https" and target.hostname and not target.username and not target.password,
                "Unsafe artifact redirect")
        # The signed storage request has no Authorization header.
        response = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "lumo-2029-diagnostic"}), timeout=90)
    archive = args.candidate.parent / ("artifact-" + str(ARTIFACT_ID) + ".zip")
    archive.parent.mkdir(parents=True, exist_ok=True)
    require(not archive.exists(), "Artifact ZIP must be new")
    size = 0
    with response, archive.open("xb") as stream:
        while block := response.read(1024 * 1024):
            size += len(block)
            require(size <= ZIP_BYTES, "Artifact ZIP exceeds immutable size")
            stream.write(block)
    require(size == ZIP_BYTES and digest(archive) == ZIP_SHA, "Immutable ZIP digest/size mismatch")
    reference.extract_zip(archive, args.candidate)
    identity = verify_candidate(args.candidate)
    write_json(args.out / "verified-download.json", {
        "mode": "diagnostic-only", "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
        "scene": args.scene, "source_build_run": SOURCE_RUN, "source_run_conclusion": "failure",
        "artifact_id": ARTIFACT_ID, "zip_bytes": size, "zip_sha256": ZIP_SHA, "apk_bytes": APK_BYTES,
        "candidate": identity, "source_binding": binding, "apk_rebuilt": False,
        "origin_files": {name: digest(args.out / name) for name in ORIGIN_FILES}})


def verify_download(args):
    identity = verify_candidate(args.candidate)
    verify_origin(*(load(args.download_evidence / name) for name in ORIGIN_FILES))
    record = load(args.download_evidence / "verified-download.json")
    expected = {"mode": "diagnostic-only", "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
        "scene": args.scene, "source_build_run": SOURCE_RUN, "source_run_conclusion": "failure",
        "artifact_id": ARTIFACT_ID, "zip_bytes": ZIP_BYTES, "zip_sha256": ZIP_SHA, "apk_bytes": APK_BYTES,
        "candidate": identity, "source_binding": source_binding(args), "apk_rebuilt": False,
        "origin_files": {name: digest(args.download_evidence / name) for name in ORIGIN_FILES}}
    require(record == expected and record["source_binding"] == load(args.download_evidence / "qa-source-binding.json"),
            "Downloaded identity/evidence is not bound to this diagnostic scene/run/checkout")
    return identity


def diagnostic_result(args):
    return {"schema": "lumo.nextgen.2029.native.diagnostic", "version": 1,
        "status": "DIAGNOSTIC_ONLY", "mode": "diagnostic-only", "diagnostic_outcome": "RUNNING",
        "scene": args.scene, "run_id": uuid.uuid4().hex,
        "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
        "apk_source": SOURCE, "native_source": NATIVE, "source_build_run": SOURCE_RUN,
        "source_artifact_id": ARTIFACT_ID, "original_android_job": ANDROID_JOB,
        "original_failed_android_reclassified": False, "original_probe_requirement_satisfied": False,
        "release_eligible": False, "historical_tour_pass_used": False,
        "private_app_data_written_by_probe": False, "apk_rebuilt_by_probe": False,
        "probe_sha256": digest(Path(__file__)),
        "reference_helper_sha256": digest(HERE / "lumo_nextgen_reference_android_probe.py"),
        "learning_helper_sha256": digest(HERE / "lumo_nextgen_learning_android_probe.py"),
        "limitations": [
            "DIAGNOSTIC_ONLY: neither complete acceptance tour nor release approval is performed.",
            "Original 2029 source run and Android job remain FAIL, even if this scene completes.",
            "Each scene has a separate fresh API35 emulator and real UI-created fictional grade-1 profile.",
            "Native MediaPlayer callbacks are playback evidence, not acoustic word quality or lip-sync proof; videos have no audio track.",
            "Banane repeat checks four current segments, not native slower speed or actual STT.",
            "Pattern native proposal is ungraded; this diagnostic never submits the optional Core answer.",
            "Bridge may report actual emulator performance windows; no physical-device/60fps or mouth/paw-stop claim follows.",
        ]}


class DiagnosticProbe(reference.ReferenceProbe):
    def run(self):
        raise RuntimeError("Diagnostic cannot invoke the complete acceptance tour")

    def reset_successful_original(self):
        raise RuntimeError("Diagnostic cannot invent an original PASS or reset an installation")


def observe_scene(probe):
    probe.identify_and_install()
    require(probe.result["device"]["api"] == 35 and
            probe.result["device"].get("package_absent_before_install") is True,
            "Diagnostic requires its own fresh API35 installation")
    probe.result["phase"] = "onboarding"
    probe.onboard()
    probe.result["phase"] = "voice-settings"
    probe.configure_local_voice()
    probe.result["phase"] = probe.args.scene
    if probe.args.scene == "banana":
        probe.banana()
    else:
        probe.academy()
        if probe.args.scene == "pattern":
            probe.pattern()
        elif probe.args.scene == "bridge":
            probe.native_roundtrip()
        else:
            raise RuntimeError("Unsupported diagnostic scene")
    probe.result["final_profile"] = learning.learning_snapshot(
        probe.preferences("diagnostic-final-profile-and-progress"))["profile"]
    probe.result["phase"] = "observed-route-complete"


def run(args):
    require(not args.out.exists() or not any(args.out.iterdir()), "Diagnostic evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result, probe = diagnostic_result(args), None
    try:
        verify_ci_context(args, os.environ)
        verify_download(args)
        args.apk, args.provenance = args.candidate / "Lumo-Lernen-Neu.apk", args.candidate / "BUILD-PROVENANCE.json"
        args.expected_sha256, args.expected_source, args.expected_native = APK_SHA, SOURCE, NATIVE
        args.expected_version, args.expected_certificate, args.conversation_ui = VERSION, CERTIFICATE, "ea"
        args.submit_core_answer = False
        require(shutil.which("ffprobe"), "ffprobe required for actual video validation")
        probe = DiagnosticProbe(args, result)
        observe_scene(probe)
        result["diagnostic_outcome"] = "COMPLETED"
        return 0
    except Exception as error:
        result.update(diagnostic_outcome="FAILED", error=str(error), traceback=traceback.format_exc())
        if probe:
            for name, capture in (("failure_capture", lambda: probe.capture("diagnostic-failure-screen", native=True)),
                                  ("failure_audio_log", probe.speech_log)):
                try:
                    capture()
                except Exception as failure:
                    result[name + "_error"] = str(failure)
        print(traceback.format_exc(), file=sys.stderr, flush=True)
        return 1
    finally:
        result.update(status="DIAGNOSTIC_ONLY", original_probe_requirement_satisfied=False, release_eligible=False,
                      finished_utc=time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))
        write_json(args.out / "diagnostic-android-result.json", result)
        print(json.dumps({key: result[key] for key in ("status", "diagnostic_outcome", "scene", "qa_commit", "apk_source")}), flush=True)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("download", "run"):
        command = commands.add_parser(name)
        for flag in ("candidate", "out"):
            command.add_argument("--" + flag, type=Path, required=True)
        command.add_argument("--qa-commit", required=True)
        command.add_argument("--workflow-run-id", type=int, required=True)
        command.add_argument("--scene", choices=SCENES, required=True)
        if name == "run":
            command.add_argument("--download-evidence", type=Path, required=True)
            command.add_argument("--serial")
    args = parser.parse_args(argv)
    if args.command == "run":
        return run(args)
    download(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
