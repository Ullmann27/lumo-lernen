#!/usr/bin/env python3
"""Complete Android replay of the already built, immutable 2028 x86 APK.

This QA commit is distinct from the APK source. No APK is rebuilt and no
historical result is promoted to PASS. The complete original tour runs first;
the existing reference tour then rechecks its live installation and fictional
profile before its own fresh installation. All observed acceptance gates remain.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
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


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


current = module("immutable_2028_current_gates", HERE / "lumo_nextgen_current_reference_android_probe.py")
shared = module("immutable_2028_observed_gates", ROOT / "tools/nextgen/prepare_current_learning_release.py")
reference, learning = current.reference, current.learning
require, digest, read_json, write_json = reference.require, reference.digest, reference.read_json, reference.write_json

SOURCE = "fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242"
NATIVE = "678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef"
SOURCE_RUN, VALIDATION_JOB, BUILD_JOB = 43774460935, 132997440685, 133001842592
VERSION, VERSION_NAME = 2028, "0.13.16"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
PCK_SHA = "69899113f134c04550a5073cd9657315e0cb0bb418f9e06fa76a482041757bc0"
ARTIFACT_ID, ARTIFACT_NAME = 14185954865, "lumo-nextgen-x86"
ZIP_BYTES, APK_BYTES = 538198415, 538184315
ZIP_SHA = "de4cb804fe00293f8a89adb58c1c9eec51f08e96731c3247b6e9741497fb7717"
APK_SHA = "6b3a2f62ea80144b5af397e6353d1a52f2210109531a1edd49a1b22ec2bc4fa9"
QA_BRANCH = "qa/lumo-nextgen-2028-android-20261116"
CONFIG = ROOT / "config/nextgen-2028-replay.json"
IMMUTABLE_CONFIG = {
    "schemaVersion": 1, "apkSource": SOURCE, "nativeSource": NATIVE,
    "sourceBuildRun": SOURCE_RUN, "sourceValidateJob": VALIDATION_JOB, "sourceBuildJob": BUILD_JOB,
    "package": learning.PACKAGE, "versionName": VERSION_NAME, "versionCode": VERSION,
    "certificate": CERTIFICATE, "pckSha256": PCK_SHA,
    "x86Artifact": {"id": ARTIFACT_ID, "name": ARTIFACT_NAME, "zipBytes": ZIP_BYTES,
                    "zipSha256": ZIP_SHA, "apkBytes": APK_BYTES, "apkSha256": APK_SHA},
}
QA_PREFIXES = (".github/probes/", ".github/workflows/", "tools/android_qa/", "docs/")
QA_FILES = frozenset((
    "config/nextgen-2028-replay.json", "config/nextgen-2028-replay-publish.json",
    "tools/nextgen/prepare_current_learning_release.py",
    "tools/nextgen/prepare_2028_learning_replay_release.py",
    "tools/nextgen/test_prepare_2028_learning_replay_release.py",
    "STATUS.md", "CONTINUE.md",
))


def load(path):
    return read_json(Path(path).read_text(encoding="utf-8"))


def verify_config(config):
    require(isinstance(config, dict) and set(config) == set(IMMUTABLE_CONFIG) | {"replayAttempt"},
            "Unexpected immutable replay configuration fields")
    for key, expected in IMMUTABLE_CONFIG.items():
        actual = config.get(key)
        require(type(actual) is type(expected) and actual == expected, "Wrong immutable replay field: " + key)
        if isinstance(expected, dict):
            require(all(type(actual.get(k)) is type(v) for k, v in expected.items()),
                    "Wrong immutable artifact field type")
    require(type(config["replayAttempt"]) is int and config["replayAttempt"] > 0,
            "Replay attempt must be a positive integer")
    return config


def verify_qa_identity(qa_commit, qa_workflow_run):
    require(learning.valid_hex(qa_commit, 40) and qa_commit != SOURCE,
            "Replay requires a distinct exact QA commit, not the APK source")
    require(type(qa_workflow_run) is int and qa_workflow_run > 0 and qa_workflow_run != SOURCE_RUN,
            "Replay requires its own workflow run, not the failed original run")


def verify_ci_context(qa_commit, qa_workflow_run, environment):
    verify_qa_identity(qa_commit, qa_workflow_run)
    require(environment.get("GITHUB_REPOSITORY") == reference.REPOSITORY and
            environment.get("GITHUB_SHA") == qa_commit and
            environment.get("GITHUB_RUN_ID") == str(qa_workflow_run) and
            environment.get("GITHUB_REF_NAME") == QA_BRANCH,
            "Replay must run in its exact QA repository, branch, commit and workflow")


def allowed_qa_path(name):
    path = PurePosixPath(name)
    return (isinstance(name, str) and bool(name) and "\\" not in name and
            not path.is_absolute() and all(p not in ("", ".", "..") for p in name.split("/")) and
            (name in QA_FILES or name.startswith(QA_PREFIXES)))


def verify_source_binding(qa_commit, qa_workflow_run, output):
    """Compare committed trees; sparse checkout must not hide a product delta."""
    def git(*arguments):
        return subprocess.check_output(["git", *arguments], cwd=ROOT)

    require(git("rev-parse", "HEAD").decode().strip() == qa_commit, "Checkout is not the requested QA commit")
    require(not git("status", "--porcelain", "--untracked-files=no").strip(), "Tracked QA checkout is modified")
    changed = git("diff", "--name-only", "--no-renames", "-z", SOURCE, qa_commit).decode().split("\0")
    changed = [name for name in changed if name]
    require(changed and all(allowed_qa_path(name) for name in changed),
            "QA source differs in a runtime or unapproved path: " + repr([n for n in changed if not allowed_qa_path(n)]))
    record = {"mode": "immutable-replay", "qa_commit": qa_commit, "qa_workflow_run": qa_workflow_run,
              "apk_source": SOURCE, "source_build_run": SOURCE_RUN,
              "apk_source_tree": git("rev-parse", SOURCE + "^{tree}").decode().strip(),
              "qa_tree": git("rev-parse", qa_commit + "^{tree}").decode().strip(),
              "changed_paths": changed, "runtime_source_changed": False, "config_sha256": digest(CONFIG)}
    output.parent.mkdir(parents=True, exist_ok=True)
    require(not output.exists(), "Source binding evidence must be new")
    write_json(output, record)
    return record


def fixed_identity(proof):
    identity = learning.verify_provenance(proof, sha256=APK_SHA, source=SOURCE, native=NATIVE,
                                          version=VERSION, certificate=CERTIFICATE)
    require(identity["versionName"] == VERSION_NAME and identity["godot"]["pck_sha256"] == PCK_SHA,
            "Wrong immutable 2028 versionName/native pack")
    return identity


def verify_candidate(directory):
    apk = directory / "Lumo-Lernen-Neu.apk"
    require(apk.is_file() and apk.stat().st_size == APK_BYTES and digest(apk) == APK_SHA,
            "Candidate is not the exact independently verified 2028 APK bytes")
    return fixed_identity(load(directory / "BUILD-PROVENANCE.json"))


def verify_origin(run, artifact, validation, build):
    require(run.get("id") == SOURCE_RUN and run.get("head_sha") == SOURCE and
            run.get("repository", {}).get("full_name") == reference.REPOSITORY and
            run.get("repository", {}).get("id") == reference.REPOSITORY_ID and
            run.get("path") == ".github/workflows/lumo-nextgen-learning-apk.yml" and
            run.get("status") == "completed" and run.get("conclusion") == "failure",
            "Original source run identity/outcome mismatch; its Android FAIL must remain")
    for job, number, name in ((validation, VALIDATION_JOB, "validate"), (build, BUILD_JOB, "build")):
        require(job.get("id") == number and job.get("run_id") == SOURCE_RUN and
                job.get("head_sha") == SOURCE and job.get("name") == name and
                job.get("status") == "completed" and job.get("conclusion") == "success",
                "Original source job did not succeed: " + name)
    require(any(step.get("name") == "Independently verify both produced artifacts" and
                step.get("conclusion") == "success" for step in build.get("steps", [])),
            "Original independent APK verification did not succeed")
    for key, expected in {"id": ARTIFACT_ID, "name": ARTIFACT_NAME, "size_in_bytes": ZIP_BYTES,
                          "digest": "sha256:" + ZIP_SHA, "expired": False}.items():
        require(type(artifact.get(key)) is type(expected) and artifact[key] == expected,
                "Wrong immutable 2028 artifact field: " + key)
    origin = artifact.get("workflow_run", {})
    require(origin.get("id") == SOURCE_RUN and origin.get("head_sha") == SOURCE and
            origin.get("repository_id") == reference.REPOSITORY_ID and
            origin.get("head_repository_id") == reference.REPOSITORY_ID,
            "Artifact belongs to a different run/source/repository")


ORIGIN_FILES = ("original-run.json", "original-x86-artifact.json",
                "original-validate-job.json", "original-build-job.json")


def download(args):
    verify_config(load(CONFIG))
    verify_ci_context(args.qa_commit, args.workflow_run_id, os.environ)
    require(not args.out.exists() or not any(args.out.iterdir()), "Download evidence must be new")
    require(not args.candidate.exists(), "Candidate directory must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    binding = verify_source_binding(args.qa_commit, args.workflow_run_id,
                                    args.out.parent / "source/qa-source-binding.json")
    prefix = "/repos/" + reference.REPOSITORY + "/actions/"
    endpoints = ("runs/" + str(SOURCE_RUN), "artifacts/" + str(ARTIFACT_ID),
                 "jobs/" + str(VALIDATION_JOB), "jobs/" + str(BUILD_JOB))
    records = []
    for name, endpoint in zip(ORIGIN_FILES, endpoints):
        record = reference.api_json(prefix + endpoint)
        write_json(args.out / name, record)
        records.append(record)
    verify_origin(*records)
    # Keep repository credentials on api.github.com; signed storage gets none.
    try:
        response = urllib.request.build_opener(reference.NoRedirect()).open(
            reference.github_request(prefix + "artifacts/" + str(ARTIFACT_ID) + "/zip"), timeout=45)
    except urllib.error.HTTPError as redirect:
        require(redirect.code == 302, "GitHub artifact redirect failed with HTTP " + str(redirect.code))
        url = redirect.headers.get("Location", "")
        target = urllib.parse.urlsplit(url)
        require(target.scheme == "https" and target.hostname and not target.username and not target.password,
                "Unsafe artifact redirect")
        response = urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "lumo-2028-replay"}), timeout=90)
    archive = args.candidate.parent / ("artifact-" + str(ARTIFACT_ID) + ".zip")
    archive.parent.mkdir(parents=True, exist_ok=True)
    require(not archive.exists(), "Immutable ZIP may not overwrite an earlier download")
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
        "mode": "immutable-replay", "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
        "source_build_run": SOURCE_RUN, "source_run_conclusion": records[0]["conclusion"],
        "artifact_id": ARTIFACT_ID, "artifact_name": ARTIFACT_NAME, "zip_bytes": size,
        "zip_sha256": digest(archive), "apk_bytes": APK_BYTES, "candidate": identity,
        "apk_rebuilt": False, "config_sha256": digest(CONFIG), "source_binding": binding,
        "origin_files": {name: digest(args.out / name) for name in ORIGIN_FILES},
        "zip_members": sorted(str(p.relative_to(args.candidate)) for p in args.candidate.rglob("*") if p.is_file()),
    })


def verify_download_record(directory, candidate, qa_commit, qa_workflow_run):
    verify_config(load(CONFIG))
    identity = verify_candidate(candidate)
    records = [load(directory / name) for name in ORIGIN_FILES]
    verify_origin(*records)
    record = load(directory / "verified-download.json")
    require(record.get("mode") == "immutable-replay" and record.get("qa_commit") == qa_commit and
            record.get("qa_workflow_run") == qa_workflow_run and record.get("source_build_run") == SOURCE_RUN and
            record.get("source_run_conclusion") == "failure" and record.get("artifact_id") == ARTIFACT_ID and
            record.get("artifact_name") == ARTIFACT_NAME and record.get("zip_sha256") == ZIP_SHA and
            record.get("zip_bytes") == ZIP_BYTES and record.get("apk_bytes") == APK_BYTES and
            record.get("candidate") == identity and record.get("apk_rebuilt") is False and
            record.get("config_sha256") == digest(CONFIG) and
            record.get("origin_files") == {name: digest(directory / name) for name in ORIGIN_FILES},
            "Download evidence does not belong to this immutable candidate and QA run")
    binding = load(directory.parent / "source/qa-source-binding.json")
    require(record.get("source_binding") == binding and binding.get("qa_commit") == qa_commit and
            binding.get("qa_workflow_run") == qa_workflow_run and binding.get("apk_source") == SOURCE and
            binding.get("source_build_run") == SOURCE_RUN and binding.get("runtime_source_changed") is False and
            binding.get("config_sha256") == digest(CONFIG) and binding.get("changed_paths") and
            all(allowed_qa_path(path) for path in binding["changed_paths"]),
            "Replay source binding is absent or includes runtime changes")
    return identity


def verify_2028_tours(original, extra, *, qa_commit, qa_workflow_run, original_result_sha256):
    """Shared pure acceptance gate for this replay and its separate publisher."""
    verify_qa_identity(qa_commit, qa_workflow_run)
    identity = fixed_identity(original.get("candidate", {}))
    current.verify_current_original(original, identity, digest(HERE / "lumo_nextgen_learning_android_probe.py"))
    require(extra.get("schema") == "lumo.nextgen.reference.android.probe" and
            type(extra.get("version")) is int and extra["version"] == 1 and
            extra.get("status") in ("PASS", "PASS_WITH_LIMITATIONS") and
            extra.get("mode") == "immutable-replay", "Complete immutable 2028 reference tour has not passed")
    require(extra.get("candidate") == identity and extra.get("qa_commit") == qa_commit and
            extra.get("apk_source") == SOURCE and extra.get("native_source") == NATIVE and
            type(extra.get("source_build_run")) is int and extra["source_build_run"] == SOURCE_RUN and
            type(extra.get("qa_workflow_run")) is int and extra["qa_workflow_run"] == qa_workflow_run,
            "Reference result does not belong to this distinct QA run and immutable APK source")
    require(extra.get("probe_sha256") == digest(Path(__file__)) and
            extra.get("reference_probe_sha256") == digest(HERE / "lumo_nextgen_reference_android_probe.py"),
            "Reference result was produced by different probe sources")
    return shared.verify_observed_execution(original, extra, identity=identity,
                                             original_result_sha256=original_result_sha256)


class ReplayProbe(reference.ReferenceProbe):
    def candidate_identity(self):
        return verify_candidate(self.args.candidate)

    def verify_previous_result(self, original, identity):
        current.verify_current_original(original, identity, digest(HERE / "lumo_nextgen_learning_android_probe.py"))


def run(args):
    require(not args.out.exists() or not any(args.out.iterdir()), "Reference evidence must be new")
    args.out.mkdir(parents=True, exist_ok=True)
    result = {"schema": "lumo.nextgen.reference.android.probe", "version": 1, "status": "RUNNING",
              "mode": "immutable-replay", "run_id": uuid.uuid4().hex,
              "started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
              "apk_source": SOURCE, "native_source": NATIVE, "source_build_run": SOURCE_RUN,
              "probe_sha256": digest(Path(__file__)),
              "reference_probe_sha256": digest(HERE / "lumo_nextgen_reference_android_probe.py"),
              "historical_tour_pass_used": False, "private_app_data_written_by_probe": False,
              "apk_rebuilt_by_probe": False, "fullModernizationComplete": False}
    probe = None
    try:
        verify_ci_context(args.qa_commit, args.workflow_run_id, os.environ)
        verify_download_record(args.download_evidence, args.candidate, args.qa_commit, args.workflow_run_id)
        args.apk, args.provenance = args.candidate / "Lumo-Lernen-Neu.apk", args.candidate / "BUILD-PROVENANCE.json"
        args.expected_sha256, args.expected_source, args.expected_native = APK_SHA, SOURCE, NATIVE
        args.expected_version, args.expected_certificate, args.conversation_ui = VERSION, CERTIFICATE, "ea"
        require(shutil.which("ffprobe"), "ffprobe is required for actual video validation")
        probe = ReplayProbe(args, result)
        probe.run()
        return 0
    except Exception as error:
        result.update(status="FAIL", error=str(error), traceback=traceback.format_exc())
        if probe:
            try:
                probe.capture("failure-current-screen", native=True)
            except Exception as failure:
                result["failure_capture_error"] = str(failure)
        print(traceback.format_exc(), file=sys.stderr, flush=True)
        return 1
    finally:
        result["finished_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        write_json(args.out / "reference-android-result.json", result)
        print(json.dumps({key: result[key] for key in ("status", "run_id", "qa_commit", "apk_source")}), flush=True)


def verify_results(args):
    verify_config(load(CONFIG))
    verify_ci_context(args.qa_commit, args.workflow_run_id, os.environ)
    original, extra = load(args.original), load(args.reference)
    performance = verify_2028_tours(original, extra, qa_commit=args.qa_commit,
        qa_workflow_run=args.workflow_run_id, original_result_sha256=digest(args.original))
    require(not args.out.exists(), "Replay summary must be new")
    args.out.parent.mkdir(parents=True, exist_ok=True)
    write_json(args.out, {"schema": "lumo.nextgen.2028.replay", "version": 1,
        "mode": "immutable-replay", "status": "PASS_WITH_LIMITATIONS",
        "qa_commit": args.qa_commit, "qa_workflow_run": args.workflow_run_id,
        "apk_source": SOURCE, "native_source": NATIVE, "source_build_run": SOURCE_RUN,
        "source_build_run_conclusion": "failure", "original_failed_android_reclassified": False,
        "candidate": original["candidate"], "original_status": original["status"], "reference_status": extra["status"],
        "original_result_sha256": digest(args.original), "reference_result_sha256": digest(args.reference),
        "apk_rebuilt_by_probe": False, "fullModernizationComplete": False,
        "performance": performance, "limitations": list(dict.fromkeys(original.get("limitations", []) + extra.get("limitations", [])))})


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("download", "run", "verify"):
        command = commands.add_parser(name)
        command.add_argument("--qa-commit", required=True)
        command.add_argument("--workflow-run-id", required=True, type=int)
        command.add_argument("--out", required=True, type=Path)
        if name in ("download", "run"):
            command.add_argument("--candidate", required=True, type=Path)
        if name == "run":
            command.add_argument("--download-evidence", required=True, type=Path)
            command.add_argument("--previous-probe-out", required=True, type=Path)
            command.add_argument("--submit-core-answer", action="store_true")
            command.add_argument("--serial")
        if name == "verify":
            command.add_argument("--original", required=True, type=Path)
            command.add_argument("--reference", required=True, type=Path)
    args = parser.parse_args(argv)
    if args.command == "run":
        return run(args)
    (download if args.command == "download" else verify_results)(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
