"""Read-only reassessment of one already completed Android artifact.

This runs no device command, network operation or test suite. Imported pure
readers/guards are the unchanged committed QA versions. Only this review folder
receives derived reports; source and original evidence remain unchanged.
"""
from pathlib import Path
import datetime
import hashlib
import importlib.util
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True
QA = "ce8458e88d16e7c3b97fafcf34c4d29b0c1d9fdc"
WORK = Path("/workspace/scratch/4fa97167812c/agent-2032-runtime-cases")
ROOT = Path("/dev/shm/lumo-2032-runtime-cases-originals")
ORIGINAL = ROOT / "original"
OUT = Path(__file__).parent
BASE = "android/runtime-cases/"
PROBE = WORK / ".github/probes/lumo_nextgen_2032_runtime_cases_android_probe.py"
spec = importlib.util.spec_from_file_location("review_current_runtime_cases", PROBE)
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)
learning, reference, legacy, native = probe.learning, probe.reference, probe.legacy, probe.native


def sha(data):
    return hashlib.sha256(data).hexdigest()


def canon(value):
    return json.loads(json.dumps(value))


def git(*args):
    return subprocess.check_output(["git", *args], cwd=WORK)


manifest_bytes = (ROOT / "artifact-verification.json").read_bytes()
manifest = json.loads(manifest_bytes)
members = {row["path"]: row for row in manifest["members"]}
assert len(members) == 1889
bound = {}


def raw(path):
    data = (ORIGINAL / path).read_bytes()
    record = members[path]
    assert len(data) == record["bytes"] and sha(data) == record["sha256"], path
    bound[path] = {"path": path, "bytes": len(data), "sha256": sha(data), "matchesRootArtifactManifest": True}
    return data


def load(name):
    # Saved OCR observations are arrays; result/control files are objects.
    return json.loads(raw(BASE + name).decode(), object_pairs_hook=learning.unique_object)


def prefs(name):
    # Exactly the existing creative_android_probe.prefs() representation.
    return {node.get("name"): node.text for node in ET.fromstring(raw(BASE + name))}


def snapshot(name):
    return learning.learning_snapshot(prefs(name))


def checkpoint(name, topic):
    return learning.checkpoint(prefs(name), topic)


def nodes(name):
    return list(ET.fromstring(raw(BASE + name)).iter("node"))


def save(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


result = load("runtime-cases-result.json")
assert git("rev-parse", "HEAD").decode().strip() == QA
assert not git("status", "--porcelain").strip()
sources = []
source_paths = [str(PROBE.relative_to(WORK)), str(probe.CONFIG.relative_to(WORK)), *probe.HELPERS]
for path in source_paths:
    actual = (WORK / path).read_bytes()
    assert actual == git("show", QA + ":" + path), path
    if path in probe.HELPERS:
        assert actual == git("show", probe.SOURCE + ":" + path), path
        assert sha(actual) == result["helper_sha256"][path]
    sources.append({"path": path, "commit": QA, "bytes": len(actual), "sha256": sha(actual),
                    "sameAsApkSource": path in probe.HELPERS})
for path, expected in probe.RATE_HOST_HASHES.items():
    actual = git("show", probe.SOURCE + ":" + path)
    assert sha(actual) == expected
    sources.append({"path": path, "commit": probe.SOURCE, "bytes": len(actual), "sha256": expected})
changed = [p for p in git("diff", "--name-only", "--no-renames", "-z", probe.SOURCE, QA).decode().split("\0") if p]
assert changed == result["source_binding"]["changed_paths"]
assert all(probe.allowed_qa_path(p) for p in changed)
assert load("qa-source-binding.json") == result["source_binding"]
assert probe.read_json(raw("source/qa-source-binding.json").decode()) == result["source_binding"]
download = probe.read_json(raw("download/verified-download.json").decode())
candidate = load("candidate-BUILD-PROVENANCE.json")
identity = probe.fixed_identity(candidate)
assert identity == result["candidate"]
installed_sha = raw(BASE + "installed-apk-sha256.txt").decode().split()[0]
assert installed_sha == probe.APK_SHA == result["installed"]["sha256"]
installed_path = learning.installed_base_apk_path(raw(BASE + "installed-pm-path.txt").decode())
assert installed_path in raw(BASE + "installed-apk-sha256.txt").decode()
package = raw(BASE + "installed-package.txt").decode()
assert "versionCode=2032" in package and "versionName=0.13.20" in package
assert "Success" in raw(BASE + "fresh-install.txt").decode()
for name in ["candidate-signature.txt", "candidate-manifest.txt", "rooted-emulator.json"]:
    raw(BASE + name)
save("source-installation-review.json", {"status": "PASS", "qaCommit": QA,
    "qaTree": git("rev-parse", "HEAD^{tree}").decode().strip(), "apkSource": probe.SOURCE,
    "nativeSource": probe.NATIVE, "candidate": identity, "actualInstalledSha256": installed_sha,
    "installedPath": installed_path, "changedPaths": changed, "sources": sources,
    "downloadEvidence": download, "limits": ["No second APK download or signature execution; existing independently verified build identity is joined to the current installed base.apk hash.",
    "Native source-rate formula is a source contract, not acoustic measurement."]})

# Match the stored numeric summary to the actual original preference dumps.
number = result["numeric_wrong_then_correct"]
numeric_maps = [
    (number["pre_submission_capture"], "before", "0145-numeric-before-first-check-preferences.xml", "0144-bridge-checkpoint-preferences.xml"),
    (number["pre_submission_capture"], "after", "0148-numeric-after-build-video-preferences.xml", "0147-bridge-checkpoint-preferences.xml"),
    (number["wrong"], "before", "0148-numeric-after-build-video-preferences.xml", "0147-bridge-checkpoint-preferences.xml"),
    (number["wrong"], "after", "0162-numeric-wrong-stored-preferences.xml", "0159-bridge-checkpoint-preferences.xml"),
    (number["corrected"], "before", "0162-numeric-wrong-stored-preferences.xml", "0159-bridge-checkpoint-preferences.xml"),
    (number["corrected"], "after", "0176-numeric-corrected-stored-preferences.xml", "0173-bridge-checkpoint-preferences.xml"),
]
for item, side, pref, cp in numeric_maps:
    assert item[side] == snapshot(pref), pref
    assert item["checkpoint_" + side] == checkpoint(cp, "bridge"), cp
numeric_checks = {}
for correct, stage, input_xml, check_xml, touch_json in [
    (False, "wrong", "0153-numeric-wrong-input-written.xml", "0156-numeric-wrong-explicit-check.xml", "0158-numeric-wrong-explicit-check-touch.json"),
    (True, "corrected", "0167-numeric-corrected-input-written.xml", "0170-numeric-corrected-explicit-check.xml", "0172-numeric-corrected-explicit-check-touch.json"),
]:
    item = number[stage]
    checked = legacy.verify_numeric_submission(item["before"], item["after"], item["checkpoint_before"], item["checkpoint_after"], correct=correct)
    assert checked == item["verification"]
    edit = [n for n in nodes(input_xml) if n.get("class") == "android.widget.EditText" and n.get("text") == ("16" if correct else "15")]
    assert len(edit) == 1
    control = learning.observed_control(nodes(check_xml), "Antwort prüfen")
    touch = load(touch_json)
    assert list(control) == touch["observed_bounds"] and touch["label"] == "Antwort prüfen"
    numeric_checks[stage] = {"verification": checked, "attemptCountBefore": len(reference.attempts(item["before"])),
        "attemptCountAfter": len(reference.attempts(item["after"])), "inputXml": input_xml, "checkXml": check_xml,
        "touch": touch, "checkpointBefore": item["checkpoint_before"], "checkpointAfter": item["checkpoint_after"]}
probe.verify_numeric_case(number)
save("numeric-raw-review.json", {"status": "PASS", "prompt": number["prompt"], "problemId": number["problem_id"],
    "beforeAfterSnapshotSources": [{"side": side, "preferences": pref, "checkpoint": cp} for _, side, pref, cp in numeric_maps],
    "preSubmissionCapture": {"unansweredTaskPreserved": True, "captureAfterVideoFinalization": True,
        "orderingEvidence": "unchanged source order plus completed recording metadata and matching fresh preference/checkpoint originals",
        "video": number["pre_submission_capture"]["video"]}, "submissions": numeric_checks,
    "limits": ["Real typed 9+7 answers 15 and 16; no speech recognition, misheard spoken number or 8+5 numeric submission.",
        "Lab journey IDs and attempt-log IDs are separate existing storage identities."]})

# Re-evaluate the observed active-cue/Next hierarchy and same-session change.
switch = result["flutter_switch_during_syllable_playback"]
for item, side, pref, cp in [
    (switch, "before", "0214-switch-learning-before-preferences.xml", "0213-words-checkpoint-preferences.xml"),
    (switch, "after", "0248-switch-learning-after-preferences.xml", "0244-words-checkpoint-preferences.xml"),
]:
    assert item[side] == snapshot(pref)
    assert item["checkpoint_" + side] == checkpoint(cp, "words")
for key, pref, cp in [("prepared", "0219-switch-density-320-learning-preferences.xml", "0218-words-checkpoint-preferences.xml"),
                      ("restored", "0252-switch-restored-learning-preferences.xml", "0251-words-checkpoint-preferences.xml")]:
    assert switch["viewport"][key]["snapshot"] == snapshot(pref)
    assert switch["viewport"][key]["checkpoint"] == checkpoint(cp, "words")
observation = switch["observation"]
active_nodes = nodes(observation["xml"])
assert sha(raw(BASE + observation["xml"])) == observation["xml_sha256"]
active = legacy.observed_active_next(active_nodes)
assert canon(active) == {k: observation[k] for k in active}
touch = load("0243-switch-first-active-next-touch.json")
assert touch["label"] == legacy.NEXT and touch["observed_bounds"] == observation["next_bounds"]
ready = switch["replay_preparation"]
assert sha(raw(BASE + ready["xml"])) == ready["xml_sha256"]
actual_ready = legacy.observed_switch_ready(nodes(ready["xml"]))
assert canon(actual_ready) == {k: ready[k] for k in actual_ready}
assert load("0225-switch-start-observed-syllable-replay-touch.json")["observed_bounds"] == ready["replay_bounds"]
after_labels = learning.node_labels(nodes("0247-switch-no-old-active-syllable.xml"))
assert not any("gerade aktiv" in label for label in after_labels)
rakete_labels = learning.node_labels(nodes("0245-switch-new-rakete-prompt.xml"))
assert any(legacy.WORD_RECALL_PROMPT in label.splitlines() for label in rakete_labels)
assert legacy.verify_word_switch(switch["before"], switch["after"], switch["checkpoint_before"], switch["checkpoint_after"]) == switch["verification"]
probe.verify_switch_case(switch)
before_settings = learning.read_json(prefs("0081-runtime-auto-read-before-preferences.xml")["flutter.lumo_app_settings_v1"])
off_settings = learning.read_json(prefs("0100-runtime-auto-read-after-preferences.xml")["flutter.lumo_app_settings_v1"])
restored_settings = learning.read_json(prefs("0296-runtime-auto-read-restored-preferences.xml")["flutter.lumo_app_settings_v1"])
assert before_settings == result["runtime_auto_read_ui_changes"][0]["before"]
assert off_settings == result["runtime_auto_read_ui_changes"][0]["after"]
assert before_settings == restored_settings
save("switch-raw-review.json", {"status": "PASS_WITH_LIMITATIONS", "activeObservation": observation,
    "captureToRequestedTouchSeconds": observation["touch_requested_monotonic"] - observation["capture_started_monotonic"],
    "replayRequestToNextRequestSeconds": observation["touch_requested_monotonic"] - ready["replay_requested_monotonic"],
    "explicitReplayTaps": ready["replay_taps"], "explicitNextTaps": 1, "explicitStopBeforeSwitch": False,
    "checkpointBefore": switch["checkpoint_before"], "checkpointAfter": switch["checkpoint_after"],
    "sameSession": True, "unchangedProfileLearningReward": True, "learningKeysCompared": len(switch["before"]["learning"]),
    "oldActiveMarkerAbsentInFreshXml": True, "displayBefore": switch["viewport"]["original"]["display"],
    "displayPrepared": switch["viewport"]["prepared"]["display"], "displayRestored": switch["viewport"]["restored"]["display"],
    "autoReadDisabledAndExactlyRestored": True,
    "limits": ["Active Flutter accessibility cue and actual requested UI switch; no acoustic recording or native MediaPlayer log of this Flutter voice.",
        "Timing measures capture start to requested tap; OS input delivery and acoustic stop latency are not measured.",
        "The 45-second code budget remains unchanged; the request-to-request observations are about 4.25 seconds apart.",
        "1080x2340 at temporary 320dpi, restored to440dpi; not physical-device proof."]})

# Native slower uses four new ordered current-PID callbacks, not spoken text logs.
banana = result["native_banana_slower"]
before = snapshot("0329-runtime-banana-before-native-preferences.xml")
after = snapshot("0402-runtime-banana-after-native-preferences.xml")
assert learning.require_preserved(before, after, banana["model_before"], banana["model_after"]) == banana["preservation"]
speech_before = raw(BASE + "0349-native-speech.txt").decode()
speech_after = raw(BASE + "0386-native-speech.txt").decode()
pid = banana["playback"]["pid"]
prior_ids = sorted({int(turn) for seen_pid, _, turn, _ in learning.speech_events(speech_before) if int(seen_pid) == pid})
assert prior_ids == banana["previous_ids"]
assert reference.action_playback(speech_after, pid, prior_ids, segments=4) == banana["playback"]
sequence = [{"state": state, "id": int(turn), "profile": profile or None} for seen_pid, state, turn, profile in learning.speech_events(speech_after)
            if int(seen_pid) == pid and int(turn) not in prior_ids]
model_ocr = []
for name in ["0341-runtime-banana-model-before-0-ocr.json", "0388-runtime-banana-model-after-0-ocr.json"]:
    rows = load(name)
    matched = [row for row in rows if re.fullmatch(r"0\s*/\s*3\s+bewegt", row.get("text", ""))]
    assert matched
    model_ocr.append({"file": name, "matchingRows": matched})
panels = [load(name) for name in ["0347-runtime-banana-slower-panel-target.json", "0348-runtime-banana-slower-panel-target.json"]]
targets = [native.slower_target(panel["captions"], panel["panel_bounds"]) for panel in panels]
assert targets[0] == targets[1] and targets[0] is not None
assert panels[-1]["target"]["stable_observed_target"] is True
assert load("0351-runtime-banana-slower-touch.json")["observed_bounds"] == list(targets[-1])
probe.verify_banana_case(banana, result["onboarding"]["profile"]["id"])
save("native-banana-raw-review.json", {"status": "PASS_WITH_LIMITATIONS", "pid": pid, "previousIds": prior_ids,
    "utteranceIds": banana["playback"]["utterance_ids"], "events": sequence, "modelOCR": model_ocr,
    "sameVisibleModel": banana["model_after"], "profileLearningPreservation": banana["preservation"],
    "stablePanelTarget": targets[-1], "currentSourceRateContract": banana["source_rate_contract"],
    "rawBefore": "0349-native-speech.txt", "rawAfter": "0386-native-speech.txt",
    "limits": ["Four ordered MediaPlayer callback pairs in PID6177; speech logs contain no spoken words or rate.",
        "Banane/Ba/na/ne order and max(0.70,baseRate*0.75) are source-bound; no acoustic correctness or tempo measurement.",
        "same_task_checkpoint here compares the observed native0/3 model; it is not a newly saved native mastery record."]})

# The native proposal itself stays ungraded; only one fresh Core card is submitted.
pattern = result["pattern"]
evidence = result["pattern_core_evidence"]
native_before = snapshot("0427-pattern-before-native-preferences.xml")
native_returned = snapshot("0477-pattern-after-native-preferences.xml")
submitted = snapshot("0491-pattern-after-explicit-core-answer-preferences.xml")
final = snapshot("0493-runtime-final-profile-preferences.xml")
assert native_before == native_returned == evidence["before"]
assert submitted == evidence["after"] == final
assert load("pattern-ungraded-roundtrip.json")["core_answer_submitted"] is False
selection_xml = evidence["selection_xml"]
assert sha(raw(BASE + selection_xml)) == evidence["selection_xml_sha256"]
actual_selection = probe.observed_pattern_answer(nodes(selection_xml), pattern["task"])
assert canon(actual_selection) == evidence["selection"]
selection_touch = load("0490-pattern-explicit-core-answer-touch.json")
assert selection_touch["observed_bounds"] == evidence["selection"]["target"]
assert selection_touch["label"] == probe.HEADER + " / " + pattern["task"]["next"]
assert len(list((ORIGINAL / BASE).glob('*-pattern-explicit-core-answer-touch.json'))) == 1
actual_assessed = reference.verify_core_submission(native_returned, submitted, pattern["task"])
assert actual_assessed == pattern["core_submission"]
assert actual_assessed["stored_attempt"]["sid"] == "self"
journey_key, journey = legacy.journey(submitted, "Logik", "Muster")
assert journey["attempts"] == 1 and journey["assistedCorrect"] == 1 and journey["independentCorrect"] == 0 and journey["transferCorrect"] == 0
speech = raw(BASE + "0459-native-speech.txt").decode()
assert reference.action_playback(speech, pattern["hint_playback"]["pid"], pattern["initial_playback"]["utterance_ids"]) == pattern["hint_playback"]
probe.verify_pattern_case(pattern, evidence)
save("pattern-raw-review.json", {"status": "PASS", "task": pattern["task"], "nativeReturnUngraded": True,
    "attemptCounts": {"beforeNative": len(reference.attempts(native_before)), "afterNative": len(reference.attempts(native_returned)),
                      "afterExplicitCard": len(reference.attempts(submitted)), "final": len(reference.attempts(final))},
    "selection": evidence["selection"], "selectionXml": selection_xml, "selectionXmlSha256": evidence["selection_xml_sha256"],
    "explicitAnswerTaps": 1, "rawTouch": selection_touch, "storedAttempt": actual_assessed["stored_attempt"],
    "journeyKey": journey_key, "journey": journey,
    "walletBefore": learning.read_json(native_returned["learning"]["flutter.lumo_reward_wallet_v1"]),
    "walletAfter": learning.read_json(submitted["learning"]["flutter.lumo_reward_wallet_v1"]),
    "nativeHintPlayback": pattern["hint_playback"], "profileUnchanged": True,
    "limits": ["One observed Quadrat/Kreis period2 task, not all pattern families.",
        "An actual Core answer-card tap is the existing direct submission; no invented separate confirmation step.",
        "Assisted correct evidence is not independent mastery or transfer evidence."]})

assert snapshot("0022-synthetic-profile-preferences.xml")["profile"] == result["final_profile"]
save("raw-input-binding.json", {"artifactId": manifest["artifactId"], "workflowRun": manifest["workflowRun"],
    "archiveBytes": manifest["archiveBytes"], "archiveSha256": manifest["archiveSha256"],
    "rootManifest": {"path": str(ROOT / "artifact-verification.json"), "bytes": len(manifest_bytes), "sha256": sha(manifest_bytes)},
    "rootAllMemberCRCsVerified": manifest["allMemberCRCsVerified"], "independentSecondArchiveCRCScan": False,
    "usedOriginalFiles": sorted(bound.values(), key=lambda x: x["path"]), "usedOriginalCount": len(bound),
    "mediaReview": "Separate independent owner; no video decoding or new image inspection in this raw/domain review."})
save("raw-reassessment-summary.json", {"status": "PASS_WITH_LIMITATIONS", "reviewedUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "workflowRun": 43853317375, "androidJob": 133251156609, "qaCommit": QA, "resultSha256": sha(raw(BASE + "runtime-cases-result.json")),
    "numeric": {"wrongId": numeric_checks["wrong"]["verification"]["stored_attempt"]["id"],
                "correctedId": numeric_checks["corrected"]["verification"]["stored_attempt"]["id"], "newAttempts": 2},
    "switch": {"activeLabel": observation["active_label"], "captureToRequestedTouchSeconds": switch["capture_to_touch_seconds"],
               "sameSession": True, "newAttemptOrReward": False},
    "banana": {"pid": pid, "newOrderedPlaybackIds": banana["playback"]["utterance_ids"], "acousticTempoVerified": False},
    "pattern": {"assessedAttempt": actual_assessed["stored_attempt"], "newAttempts": 1, "assisted": True},
    "usedOriginalFiles": len(bound), "releaseEligible": False, "fullReplayReplaced": False,
    "newAndroidRun": False, "newNetworkCalls": False, "testSuiteExecuted": False, "sourceOrOriginalMutation": False})
print(json.dumps({"status": "PASS_WITH_LIMITATIONS", "originalFilesBound": len(bound),
    "numericAttempts": [numeric_checks[k]["verification"]["stored_attempt"]["id"] for k in ["wrong", "corrected"]],
    "activeCaptureToTouchSeconds": switch["capture_to_touch_seconds"], "nativePid": pid,
    "nativeSlowerIds": banana["playback"]["utterance_ids"], "patternAttempt": actual_assessed["stored_attempt"]["id"]}, indent=2))
