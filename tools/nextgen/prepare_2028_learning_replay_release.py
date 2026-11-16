#!/usr/bin/env python3
"""Publish the immutable 2028 ARM64 build only after its complete fresh QA replay.

APK source, build run, replay source and publication source remain distinct.
The failed original Android run is retained; no result is rewritten as a pass.
"""
from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[2]


def module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


# Only the generic, byte-verifying archive helpers are reused from the historical
# publisher. Its rejected 2027 identity and release gates are never called.
artifacts = module("replay_2028_archive_helpers", Path(__file__).with_name("prepare_learning_replay_release.py"))
require, digest, read_json, write_json = artifacts.require, artifacts.digest, artifacts.read_json, artifacts.write_json
REPOSITORY = "Ullmann27/lumo-lernen"
SOURCE = "fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242"
NATIVE = "678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef"
SOURCE_RUN = 43774460935
VALIDATION_JOB, BUILD_JOB, ORIGINAL_ANDROID_JOB = 132997440685, 133001842592, 133004691086
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
VERSION, VERSION_NAME = 2028, "0.13.16"
ARM64_SHA = "3bc5255101fe28ad62881a8aab478fd02650dc6e92a6abbe0d0d137367f06238"
ARM64_BYTES = 535020882
X86_SHA = "6b3a2f62ea80144b5af397e6353d1a52f2210109531a1edd49a1b22ec2bc4fa9"
PCK_SHA = "69899113f134c04550a5073cd9657315e0cb0bb418f9e06fa76a482041757bc0"
ARM64_ARTIFACT = {"id": 14186034500, "name": "lumo-nextgen-arm64", "size_in_bytes": 535034988,
                  "digest": "sha256:a6c05bbf76cfe61cb449207cb27d4ed7f8266269c965deca8efcebd79208ca52"}
ORIGINAL_FAILURE_ARTIFACT = {"id": 14186359772, "name": "lumo-nextgen-android-evidence",
    "size_in_bytes": 13472105,
    "digest": "sha256:275aed0ea814438c8e4ddb845fc3a5e12eb835586866823036930696c94821f7"}
REPLAY_WORKFLOW = ".github/workflows/lumo-nextgen-2028-replay.yml"
REPLAY_BRANCH = "qa/lumo-nextgen-2028-android-20261116"
REPLAY_ARTIFACT_NAME = "lumo-nextgen-2028-replay-evidence"
PUBLICATION_WORKFLOW = ".github/workflows/lumo-nextgen-2028-replay-publish.yml"
PUBLICATION_BRANCH = "delivery/lumo-nextgen-2028-replay-20261116"
TAG = "lumo-nextgen-learning-0.13.16-2028"
APK_NAME = "Lumo-Lernen-Neu-0.13.16-2028.apk"
REPLAY_ENTRY = ".github/probes/lumo_nextgen_2028_replay_reference_android_probe.py"
QA_BOUND_FILES = (
    ".github/probes/lumo_nextgen_learning_android_probe.py",
    ".github/probes/lumo_nextgen_current_reference_android_probe.py",
    ".github/probes/lumo_nextgen_reference_android_probe.py",
    REPLAY_ENTRY,
    "tools/nextgen/prepare_current_learning_release.py",
    "tools/nextgen/prepare_learning_replay_release.py",
    "tools/nextgen/prepare_2028_learning_replay_release.py",
    "config/nextgen-2028-replay.json",
)


def verify_config(config):
    require(config.get("schemaVersion") == 1 and config.get("apkSourceCommit") == SOURCE,
            "Wrong immutable 2028 publication configuration")
    qa, run = config.get("qaCommit"), config.get("qaRun")
    require(isinstance(qa, str) and re.fullmatch(r"[0-9a-f]{40}", qa) and qa != SOURCE and
            type(run) is int and run > 0 and run != SOURCE_RUN,
            "A distinct exact QA commit and replay workflow run are required")
    expected = config.get("qaArtifact", {})
    require(type(expected.get("id")) is int and expected["id"] > 0 and
            expected.get("name") == REPLAY_ARTIFACT_NAME and
            type(expected.get("size_in_bytes")) is int and 0 < expected["size_in_bytes"] < 2500000000 and
            isinstance(expected.get("digest"), str) and
            re.fullmatch(r"sha256:[0-9a-f]{64}", expected["digest"]),
            "Exact replay artifact metadata is required")
    return qa, run, expected


def verify_source_run(run, jobs):
    require(run.get("id") == SOURCE_RUN and run.get("head_sha") == SOURCE and
            run.get("path") == ".github/workflows/lumo-nextgen-learning-apk.yml" and
            run.get("status") == "completed" and run.get("conclusion") == "failure",
            "Original 2028 build run must retain its actual failed Android outcome")
    for job_id, name, outcome in ((VALIDATION_JOB, "validate", "success"),
                                  (BUILD_JOB, "build", "success"),
                                  (ORIGINAL_ANDROID_JOB, "android", "failure")):
        job = jobs.get(job_id, {})
        require(job.get("id") == job_id and job.get("run_id") == SOURCE_RUN and
                job.get("name") == name and job.get("status") == "completed" and
                job.get("conclusion") == outcome,
                "Original source job identity/outcome changed: " + name)


def verify_qa_run(run, qa_commit, qa_run):
    require(run.get("id") == qa_run and run.get("head_sha") == qa_commit and
            run.get("head_branch") == REPLAY_BRANCH and run.get("path") == REPLAY_WORKFLOW and
            run.get("status") == "completed" and run.get("conclusion") == "success",
            "Exact complete 2028 Android replay has not succeeded")


def verify_publisher_sources(qa_commit):
    records = []
    for name in QA_BOUND_FILES:
        original = subprocess.check_output(["git", "show", qa_commit + ":" + name], cwd=ROOT)
        current = (ROOT / name).read_bytes()
        require(original == current, "Publication gates differ from the tested QA commit: " + name)
        records.append({"path": name, "sha256": digest(ROOT / name), "identicalToQaCommit": True})
    return records


def verify_arm64(proof, *, actual_sha256, actual_bytes, x86_candidate):
    require(actual_bytes == ARM64_BYTES and actual_sha256 == ARM64_SHA == proof.get("sha256") and
            proof.get("flutter_source_commit") == SOURCE and proof.get("tracked_source_clean") is True and
            proof.get("godot", {}).get("revision") == NATIVE and
            proof.get("godot", {}).get("pck_sha256") == PCK_SHA and
            proof.get("package") == PACKAGE and proof.get("signingCertificateSha256") == CERTIFICATE and
            proof.get("abis") == ["arm64-v8a"] and proof.get("versionName") == VERSION_NAME and
            type(proof.get("versionCode")) is int and proof["versionCode"] == VERSION,
            "Immutable ARM64 bytes or provenance mismatch")
    require(x86_candidate.get("sha256") == X86_SHA and
            x86_candidate.get("godot", {}).get("pck_sha256") == PCK_SHA,
            "ARM64 and actually tested x86 candidates must contain the same learning pack")


def require_absent_github_resource(path):
    result = subprocess.run(["gh", "api", "--include", "repos/" + REPOSITORY + "/" + path],
                            capture_output=True, text=True)
    status = re.search(r"^HTTP/\S+\s+(\d{3})\b", result.stdout, re.MULTILINE)
    require(status is not None and status.group(1) == "404" and result.returncode != 0,
            "Release/tag already exists or its absence could not be verified: " + path)


def main():
    require(os.environ.get("GITHUB_REPOSITORY") == REPOSITORY and
            os.environ.get("GITHUB_REF_NAME") == PUBLICATION_BRANCH,
            "Wrong publication repository or branch")
    config = read_json(ROOT / "config/nextgen-2028-replay-publish.json")
    qa_commit, qa_run, expected_replay = verify_config(config)
    proof = Path("publication-proof")
    require(not proof.exists(), "Publication proof directory must be new")
    proof.mkdir()
    write_json(proof / "qa-publisher-source-binding.json", verify_publisher_sources(qa_commit))
    source_run = artifacts.api("actions/runs/" + str(SOURCE_RUN))
    jobs = {number: artifacts.api("actions/jobs/" + str(number))
            for number in (VALIDATION_JOB, BUILD_JOB, ORIGINAL_ANDROID_JOB)}
    verify_source_run(source_run, jobs)
    write_json(proof / "source-run.json", source_run)
    for number, job in jobs.items():
        write_json(proof / (str(number) + "-job.json"), job)
    replay_run = artifacts.api("actions/runs/" + str(qa_run))
    verify_qa_run(replay_run, qa_commit, qa_run)
    write_json(proof / "replay-run.json", replay_run)
    artifacts.download_artifact(expected_replay, qa_run, qa_commit, Path("android-evidence"), proof)
    original_path = Path("android-evidence/android/original-android/learning-android-result.json")
    extra_path = Path("android-evidence/android/reference-android/reference-android-result.json")
    original, extra = read_json(original_path), read_json(extra_path)
    replay = module("replay_2028_publication_gate", ROOT / REPLAY_ENTRY)
    performance = replay.verify_2028_tours(original, extra, qa_commit=qa_commit,
        qa_workflow_run=qa_run, original_result_sha256=digest(original_path))
    artifacts.download_artifact(ORIGINAL_FAILURE_ARTIFACT, SOURCE_RUN, SOURCE,
                                Path("original-failed-android"), proof)
    failed = read_json("original-failed-android/original-android/learning-android-result.json")
    require(failed.get("status") == "FAIL" and failed.get("candidate", {}).get("sha256") == X86_SHA and
            failed.get("candidate", {}).get("flutter_source_commit") == SOURCE,
            "Original failed Android evidence was not retained unchanged")
    artifacts.download_artifact(ARM64_ARTIFACT, SOURCE_RUN, SOURCE, Path("release"), proof)
    release = Path("release")
    provenance = read_json(release / "BUILD-PROVENANCE.json")
    apk = release / "Lumo-Lernen-Neu.apk"
    verify_arm64(provenance, actual_sha256=digest(apk), actual_bytes=apk.stat().st_size,
                 x86_candidate=original["candidate"])
    coverage_bytes = subprocess.check_output(["git", "show", SOURCE + ":docs/nextgen/COVERAGE.json"], cwd=ROOT)
    coverage = json.loads(coverage_bytes)
    require(coverage.get("scope", {}).get("fullModernizationComplete") is False,
            "Complete modernization has not been accepted")
    limitations = list(dict.fromkeys(original.get("limitations", []) + extra.get("limitations", []) + [
        "Many inventoried routes use the shared task card, not individual spatial learning simulations.",
        "The figure runs in the existing separate Godot Activity, not inline on every Flutter task screen.",
        "ARM64 bytes are independently verified; runtime captures are from the x86 APK of the same source.",
        "Physical Fold7 hinge behavior, preserved upgrade/process-death recovery, sustained hardware FPS and acoustic speech quality remain unverified.",
    ]))
    delivery = {"schemaVersion": 1, "mode": "immutable-replay", "apkSourceCommit": SOURCE,
        "godotCommit": NATIVE, "qaCommit": qa_commit, "qaRun": qa_run, "sourceBuildRun": SOURCE_RUN,
        "publicationCommit": os.environ["GITHUB_SHA"], "versionCode": VERSION, "versionName": VERSION_NAME,
        "package": PACKAGE, "signingCertificateSha256": CERTIFICATE, "arm64Sha256": ARM64_SHA,
        "arm64Bytes": ARM64_BYTES, "x86Sha256": X86_SHA, "pckSha256": PCK_SHA,
        "apkRebuilt": False, "originalFailedAndroidStatus": failed["status"],
        "originalAndroidStatus": original["status"], "referenceAndroidStatus": extra["status"],
        "originalResultSha256": digest(original_path), "referenceResultSha256": digest(extra_path),
        "fullModernizationComplete": False, "performance": performance, "limitations": limitations}
    write_json(release / "DELIVERY.json", delivery)
    (release / "COVERAGE.json").write_bytes(coverage_bytes)
    with tarfile.open(release / "Android-Lernpruefung.tar.gz", "w:gz") as archive:
        archive.add("android-evidence", arcname="replay")
        archive.add("original-failed-android", arcname="original-failed-android")
    require(not (release / APK_NAME).exists(), "Refusing to overwrite release APK")
    apk.rename(release / APK_NAME)
    Path("release-notes.md").write_text(
        "# LUMO Lernwelt 0.13.16 (2028)\n\n"
        "Neue einzelne ARM64-Test-APK mit bestehender Paketkennung und bestehender Testsignatur.\n\n"
        f"Appquelle: `{SOURCE}`\n\nGodot: `{NATIVE}`\n\n"
        f"APK SHA-256: `{ARM64_SHA}`\n\nSignatur: `{CERTIFICATE}`\n\n"
        f"Android-Prüfquelle: `{qa_commit}`, [vollständige Wiederholungsprüfung](https://github.com/{REPOSITORY}/actions/runs/{qa_run}).\n\n"
        f"[Originaler Quell- und Buildlauf](https://github.com/{REPOSITORY}/actions/runs/{SOURCE_RUN}): "
        "Quellvalidierung und beide Builds erfolgreich; erste Androidtour an der noch einblendenden "
        "Mikrofon-Berechtigungsoberfläche abgebrochen. Dieses FAIL bleibt mit allen Originalen erhalten. "
        "Der eng korrigierte Leser wurde anschließend mit der gesamten Originaltour und den nativen "
        "Banane-/Musterszenen an exakt derselben x86-APK geprüft. Keine APK wurde für die Wiederholung neu gebaut.\n\n"
        "Die App enthält die korrigierte Aufgabenbindung im Lab-Gespräch, die native Android-Schnittstellenabfrage "
        "für Audio und den geprüften Musterkontext. Figuren-, Audio- und Effektfenster stammen aus tatsächlichen "
        "Androidaufnahmen; Messwerte und Grenzen stehen in DELIVERY.json.\n\n"
        "Prüfumgebung: Android 35 x86_64 mit Software-Grafik. Das belegt keine physische ARM64-/Fold7-Abnahme, "
        "echte gesprochene Erkennung, menschlich geprüfte Klangqualität oder 60 FPS. "
        "Die vollständige Modernisierung aller Aufgabenvarianten bleibt offen; zahlreiche Einstiege nutzen "
        "die gemeinsame native Aufgabenkarte. Geschützte Schreib-/Journalmodule bleiben intern unverändert.\n",
        encoding="utf-8")
    require_absent_github_resource("releases/tags/" + TAG)
    require_absent_github_resource("git/ref/tags/" + TAG)
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"tag={TAG}\nsource={SOURCE}\napk={APK_NAME}\n")
    print(json.dumps({"prepared": True, "tag": TAG, "apkSource": SOURCE, "qaCommit": qa_commit,
                      "apkSha256": ARM64_SHA, "fullModernizationComplete": False}))


if __name__ == "__main__":
    main()
