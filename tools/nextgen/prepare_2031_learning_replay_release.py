#!/usr/bin/env python3
"""Publish the immutable 2031 ARM64 build only after its complete fresh QA replay.

APK source, build run, replay source and publication source remain distinct.
The failed original Android run is retained; no result is rewritten as a pass.
"""
from __future__ import annotations

import argparse
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
artifacts = module("replay_2031_archive_helpers", Path(__file__).with_name("prepare_learning_replay_release.py"))
public = module("replay_2031_public_helpers", Path(__file__).with_name("public_learning_download.py"))
require, digest, read_json, write_json = artifacts.require, artifacts.digest, artifacts.read_json, artifacts.write_json
REPOSITORY = "Ullmann27/lumo-lernen"
SOURCE = "e05a96a52aaf57e466e79831f15aaffd144284ee"
NATIVE = "678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef"
SOURCE_RUN = 43800892196
VALIDATION_JOB, BUILD_JOB, ORIGINAL_ANDROID_JOB = 133080632526, 133085378884, 133088843594
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
CERTIFICATE = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
VERSION, VERSION_NAME = 2031, "0.13.19"
ARM64_SHA = "e6ca8e512ddc56755ae8664b3438b0e78b87a7f0e77f1cd55cac592b20b316d7"
ARM64_BYTES = 535026362
X86_SHA = "8e96a05c51fc12504a19831cee14b64c6a8e9a35a8a36863db455bed0e2cec1a"
PCK_SHA = "94b0a84b8715537fff9ff84e451c889ca1fe1b8440a4448ded93989b3feb0aef"
ARM64_ARTIFACT = {"id": 14197576182, "name": "lumo-nextgen-arm64", "size_in_bytes": 535040468,
                  "digest": "sha256:0c254fbc74c13c4ecd98bec2f31203ee93c6c51818150d0fa115a10fad192fa4"}
ORIGINAL_FAILURE_ARTIFACT = {"id": 14197925395, "name": "lumo-nextgen-android-evidence",
    "size_in_bytes": 29373558,
    "digest": "sha256:f2d1ca9232685fe4d25fcd8d6bd745a687f08ac7eb4ef1c5ec36e469d0ba03f4"}
REPLAY_WORKFLOW = ".github/workflows/lumo-nextgen-2031-replay.yml"
REPLAY_BRANCH = "qa/lumo-nextgen-2031-android-20261116"
REPLAY_ARTIFACT_NAME = "lumo-nextgen-2031-replay-evidence"
PUBLICATION_WORKFLOW = ".github/workflows/lumo-nextgen-2031-replay-publish.yml"
PUBLICATION_BRANCH = "delivery/lumo-nextgen-2031-replay-20261116"
TAG = "lumo-nextgen-learning-0.13.19-2031"
APK_NAME = "Lumo-Lernen-Neu-0.13.19-2031.apk"
REPLAY_ENTRY = ".github/probes/lumo_nextgen_2031_replay_reference_android_probe.py"
QA_BOUND_FILES = (
    REPLAY_WORKFLOW,
    PUBLICATION_WORKFLOW,
    ".github/probes/run_lumo_nextgen_2031_replay_android.sh",
    ".github/probes/lumo_nextgen_learning_android_probe.py",
    ".github/probes/lumo_nextgen_current_reference_android_probe.py",
    ".github/probes/lumo_nextgen_reference_android_probe.py",
    ".github/probes/lumo_nextgen_native_reader.py",
    ".github/probes/creative_android_probe.py",
    ".github/probes/flutter_surface_readiness.py",
    "scripts/probes/pr207_android_smoke.py",
    "scripts/probes/pr207_android_ui_probe.py",
    "scripts/verify_android_apk.py",
    "tools/android_qa/rooted_emulator.py",
    "tools/android_qa/native_ocr_tiles.py",
    "tools/android_qa/native_surface_readiness.py",
    REPLAY_ENTRY,
    "tools/nextgen/prepare_current_learning_release.py",
    "tools/nextgen/prepare_learning_replay_release.py",
    "tools/nextgen/prepare_2031_learning_replay_release.py",
    "tools/nextgen/public_learning_download.py",
    "tools/nextgen/test_prepare_2031_learning_replay_release.py",
    "tools/nextgen/test_public_learning_download.py",
    "tools/android_qa/tests/test_nextgen_2031_replay.py",
    "tools/android_qa/tests/test_nextgen_learning_android_probe.py",
    "tools/android_qa/tests/test_nextgen_reference_android_probe.py",
    "tools/android_qa/tests/test_nextgen_current_candidate.py",
    "tools/android_qa/tests/test_nextgen_native_reader.py",
    "tools/android_qa/tests/fixtures/nextgen_pattern_wrapped_43790709991/0114-pattern-native-question-9.png",
    "tools/android_qa/tests/fixtures/nextgen_pattern_wrapped_43790709991/0114-pattern-native-question-9-ocr.json",
    "tools/android_qa/tests/fixtures/nextgen_pattern_wrapped_43790709991/manifest.json",
    "config/nextgen-2031-replay.json",
)


def verify_config(config):
    require(type(config.get("schemaVersion")) is int and config["schemaVersion"] == 1 and
            config.get("apkSourceCommit") == SOURCE,
            "Wrong immutable 2031 publication configuration")
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
            "Original 2031 build run must retain its actual failed Android outcome")
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
            "Exact complete 2031 Android replay has not succeeded")


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


def public_candidate():
    """Immutable APK identity, never the distinct QA/publication commit."""
    return {"repository": REPOSITORY, "source": SOURCE, "native": NATIVE,
            "workflowRun": SOURCE_RUN, "versionName": VERSION_NAME, "versionCode": VERSION,
            "package": PACKAGE, "signingCertificateSha256": CERTIFICATE,
            "tag": TAG, "asset": APK_NAME, "sha256": ARM64_SHA, "bytes": ARM64_BYTES,
            "url": f"https://github.com/{REPOSITORY}/releases/download/{TAG}/{APK_NAME}"}


def verify_publication_context():
    require(os.environ.get("GITHUB_REPOSITORY") == REPOSITORY and
            os.environ.get("GITHUB_REF_NAME") == PUBLICATION_BRANCH,
            "Wrong publication repository or branch")


def prepare():
    verify_publication_context()
    config = read_json(ROOT / "config/nextgen-2031-replay-publish.json")
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
    replay = module("replay_2031_publication_gate", ROOT / REPLAY_ENTRY)
    performance = replay.verify_2031_tours(original, extra, qa_commit=qa_commit,
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
        "# LUMO Lernwelt 0.13.19 (2031)\n\n"
        "Neue einzelne ARM64-Test-APK mit bestehender Paketkennung und bestehender Testsignatur.\n\n"
        f"Appquelle: `{SOURCE}`\n\nGodot: `{NATIVE}`\n\n"
        f"APK SHA-256: `{ARM64_SHA}`\n\nSignatur: `{CERTIFICATE}`\n\n"
        f"Android-Prüfquelle: `{qa_commit}`, [vollständige Wiederholungsprüfung](https://github.com/{REPOSITORY}/actions/runs/{qa_run}).\n\n"
        f"[Originaler Quell- und Buildlauf](https://github.com/{REPOSITORY}/actions/runs/{SOURCE_RUN}): "
        "Quellvalidierung und beide Builds erfolgreich; erste Androidtour bei der unmittelbaren "
        "Vordergrundabfrage nach Home in der Wortpause abgebrochen. Eine sekundäre Aufnahmeprüfung "
        "mit Dauer null überlagerte die primäre Ausnahme. Das spätere Originalbild zeigt den Launcher; "
        "der ursprüngliche frühe Activity-Dump wurde nicht gespeichert. Dieses FAIL bleibt unverändert erhalten. "
        "Der eng korrigierte Leser wurde anschließend mit der gesamten Originaltour und den nativen "
        "Banane-/Musterszenen an exakt derselben x86-APK geprüft. Keine APK wurde für die Wiederholung neu gebaut.\n\n"
        "Die Appquelle bleibt der bereits validierte Stand 2031. Nur die getrennte QA-Quelle enthält "
        "die Leser-/Fehlererhaltkorrektur. Figuren-, Audio- und Effektfenster stammen aus tatsächlichen "
        "Androidaufnahmen; Messwerte und Grenzen stehen in DELIVERY.json.\n\n"
        "Prüfumgebung: Android 35 x86_64 mit Software-Grafik. Das belegt keine physische ARM64-/Fold7-Abnahme, "
        "echte gesprochene Erkennung, menschlich geprüfte Klangqualität oder 60 FPS. "
        "Die vollständige Modernisierung aller Aufgabenvarianten bleibt offen; zahlreiche Einstiege nutzen "
        "die gemeinsame native Aufgabenkarte. Geschützte Schreib-/Journalmodule bleiben intern unverändert.\n",
        encoding="utf-8")
    public.require_absent(public_candidate(), proof / "PUBLIC-ABSENCE.json")
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"tag={TAG}\nsource={SOURCE}\napk={APK_NAME}\n")
    print(json.dumps({"prepared": True, "tag": TAG, "apkSource": SOURCE, "qaCommit": qa_commit,
                      "apkSha256": ARM64_SHA, "fullModernizationComplete": False}))


def verify_public_download():
    """Retain source/tag metadata and hash every anonymously downloaded byte."""
    verify_publication_context()
    config = read_json(ROOT / "config/nextgen-2031-replay-publish.json")
    qa_commit, qa_run, _ = verify_config(config)
    verify_publisher_sources(qa_commit)
    delivery = read_json("release/DELIVERY.json")
    require(delivery.get("mode") == "immutable-replay" and
            delivery.get("apkSourceCommit") == SOURCE and delivery.get("qaCommit") == qa_commit and
            delivery.get("qaRun") == qa_run and delivery.get("sourceBuildRun") == SOURCE_RUN and
            delivery.get("publicationCommit") == os.environ.get("GITHUB_SHA") and
            delivery.get("arm64Sha256") == ARM64_SHA and delivery.get("arm64Bytes") == ARM64_BYTES,
            "Prepared release belongs to a different immutable APK or publication")
    proof = Path("publication-proof")
    verified = proof / "PUBLIC-DOWNLOAD-VERIFIED.json"
    require(not verified.exists(), "Refusing to reuse an earlier public verification")
    expected, records = public_candidate(), {}
    for name, endpoint in (("PUBLIC-DOWNLOAD.json", "releases/tags/"),
                           ("PUBLIC-TAG.json", "git/ref/tags/")):
        path = proof / name
        require(not path.exists(), "Refusing to overwrite a public metadata observation")
        records[name] = artifacts.api(endpoint + TAG)
        write_json(path, records[name])
    public.verify_release(records["PUBLIC-DOWNLOAD.json"], records["PUBLIC-TAG.json"], expected)
    write_json(verified, public.download_public(expected))


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", choices=("prepare", "verify-public"), default="prepare")
    command = parser.parse_args(argv).command
    (prepare if command == "prepare" else verify_public_download)()


if __name__ == "__main__":
    main()
