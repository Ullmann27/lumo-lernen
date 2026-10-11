#!/usr/bin/env python3
"""Real version-pinned Android learning/update acceptance, never fake progress.

Reuses the passed native voice/update/Kart probe. All subsequent learning
answers and parent choices are entered through actual visible app controls.
Uses only a fictional profile in a disposable emulator. No microphone, paid
speech call, identity verification or physical-device approval is claimed.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import time
import traceback

import lumo_free_voice_android_probe as voice

existing = voice.existing


def current_text(out: Path, tag: str) -> str:
    nodes = existing.live.live_nodes(out, tag)
    return existing.base.accessible_text(
        [node for node in nodes if node.get("package") == existing.PACKAGE])


def wait_text(out: Path, marker: str, tag: str, timeout: float = 30) -> str:
    deadline = time.monotonic() + timeout
    attempt = 0
    while time.monotonic() < deadline:
        text = current_text(out, f"{tag}-{attempt}")
        if marker in text:
            return text
        attempt += 1
        time.sleep(.5)
    existing.capture(out, f"{tag}-missing")
    raise RuntimeError("Current real app state not observed: " + marker)


def _enabled_control_bounds(nodes: list[dict], caption: str) -> list[int] | None:
    """Select a real enabled tap action, never a same-named static heading.

    The saved 1930 hierarchy contains a small non-clickable "Lernen" logo and
    larger clickable navigation controls. Choosing the smallest text rectangle
    first silently tapped the logo instead of navigating.
    """
    choices = []
    for node in nodes:
        if (node.get("package") != existing.PACKAGE
                or node.get("enabled") != "true"
                or node.get("clickable") != "true"):
            continue
        values = (node.get("text", ""), node.get("content-desc", ""))
        if not any(caption == value or caption in value.splitlines()
                   for value in values):
            continue
        bounds = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
        if (len(bounds) == 4 and bounds[2] > bounds[0]
                and bounds[3] > bounds[1]):
            choices.append(bounds)
    return min(choices, key=lambda b: (b[2]-b[0])*(b[3]-b[1]), default=None)


def tap(out: Path, caption: str, tag: str) -> None:
    # Scope the correction to this new course probe. The already passed native
    # voice/update/Kart probe and the application itself remain unchanged.
    settling = 0
    for direction in (1, -1):
        for attempt in range(32):
            nodes = existing.live.live_nodes(out, f"{tag}-{direction}-{attempt}")
            if existing.recover_launcher_dialog(out, nodes, tag):
                continue
            bounds = _enabled_control_bounds(nodes, caption)
            if bounds is not None:
                x, y = str((bounds[0]+bounds[2])//2), str((bounds[1]+bounds[3])//2)
                existing.base.adb("shell", "input", "swipe", x, y, x, y, "120")
                time.sleep(2)
                return
            visible_label = any(
                node.get("package") == existing.PACKAGE
                and any(caption == value or caption in value.splitlines()
                        for value in (node.get("text", ""), node.get("content-desc", "")))
                for node in nodes
            )
            if visible_label and settling < 10:
                settling += 1
                time.sleep(.6)
                continue
            scrolls = []
            for node in nodes:
                if (node.get("package") != existing.PACKAGE
                        or node.get("scrollable") != "true"):
                    continue
                box = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
                if len(box) == 4 and box[2] > box[0] and box[3] > box[1]:
                    scrolls.append(box)
            if not scrolls:
                time.sleep(.5)
                continue
            box = max(scrolls, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))
            x = str((box[0]+box[2])//2)
            low, high = round(box[1]+.2*(box[3]-box[1])), round(box[1]+.8*(box[3]-box[1]))
            start, end = (high, low) if direction == 1 else (low, high)
            existing.base.adb("shell", "input", "swipe", x, str(start), x, str(end), "400")
            time.sleep(.4)
    existing.capture(out, tag + "-missing")
    raise RuntimeError("No enabled live Flutter course control: " + caption)


def school_data(data: dict) -> dict:
    return {key: value for key, value in voice.protected(data).items()
            if "lumo_progress_discovery_v1" not in key}


def discoveries(out: Path, tag: str) -> list[dict]:
    return [json.loads(value) for key, value in existing.prefs(out, tag).items()
            if "lumo_progress_discovery_v1::" in key]


def answer(out: Path, title: str, value: str, tag: str) -> None:
    wait_text(out, title, tag + "-question")
    tap(out, value, tag + "-answer")
    wait_text(out, "Weiter", tag + "-accepted")
    text = current_text(out, tag + "-feedback")
    if not any(message in text for message in
               ("Das passt!", "Du hast selbst gerechnet.")):
        raise RuntimeError("Actual correct feedback not observed for " + title)
    tap(out, "Weiter", tag + "-continue")


def school_course(out: Path) -> dict:
    tap(out, "Lernen", "school-overview")
    tap(out, "Lumo erklärt es mir", "school-hub")
    wait_text(out, "Über den Zehner", "school-hub-visible")
    tap(out, "Mit Lumo anfangen", "school-course-start")
    wait_text(out, "Heute lernen wir einen Rechentrick", "school-introduction")
    intro = existing.capture(out, "08_actual_android_school_introduction")
    tap(out, "Weiter", "school-introduction-next")
    answer(out, "Was kannst du schon?", "6", "school-foundation")
    wait_text(out, "Sieben und fünf", "school-example")
    tap(out, "Erklärung lesen", "school-example-explanation")
    wait_text(out, "Sieben plus drei ist zehn", "school-example-actual-text")
    # Let any automatic narration finish before the explicit real player test.
    # No fake completion, native event or cached hierarchy is injected.
    tap(out, "Vorlesen", "school-example-read")
    wait_text(out, "Pause", "school-example-native-start", timeout=120)
    tap(out, "Pause", "school-example-pause")
    wait_text(out, "Fortsetzen", "school-example-paused")
    paused = existing.capture(out, "09_actual_android_course_voice_paused")
    tap(out, "Fortsetzen", "school-example-resume")
    wait_text(out, "Vorlesen", "school-example-finished", timeout=120)
    existing.base.display(2176, 1812, 225)
    example = existing.capture(out, "10_actual_android_fold_target_seven_plus_five")
    existing.base.display(1200, 896, 160)
    tap(out, "Weiter", "school-example-next")
    answer(out, "Gemeinsam zum Zehner", "1", "school-gap")
    answer(out, "Was bleibt übrig?", "3", "school-remainder")
    wait_text(out, "Jetzt probierst du", "school-independent-question")
    tap(out, "13", "school-real-incorrect-answer")
    wait_text(out, "Fast! Probiere es noch einmal", "school-incorrect-feedback")
    tap(out, "Tipp", "school-real-hint-request")
    wait_text(out, "Fülle zuerst den Zehner", "school-real-hint")
    hint = existing.capture(out, "11_actual_android_learning_hint_after_error")
    tap(out, "14", "school-correct-after-hint")
    wait_text(out, "Du hast selbst gerechnet.", "school-correct-feedback")
    tap(out, "Weiter", "school-independent-next")
    answer(out, "Ein neues Beispiel", "11", "school-independent-check")
    wait_text(out, "2 neue Aufgaben selbst gelöst", "school-complete-recap")
    recap = existing.capture(out, "12_actual_android_complete_school_course")
    tap(out, "Zur Lernübersicht", "school-course-return")
    wait_text(out, "Erst verstehen, dann selbst ausprobieren.", "school-return-hub")
    existing.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
    data = existing.prefs(out, "school-actually-saved")
    matching = []
    for key, raw in data.items():
        if "lumo_progress_skills::" in key:
            for record in json.loads(raw).values():
                if record.get("unit") == "Plus bis 20":
                    matching.append(record)
    if len(matching) != 1 or matching[0].get("correct") != 2 or matching[0].get("wrong") != 1:
        raise RuntimeError("Actual independent school answers not stored exactly once")
    return {
        "status": "PASS", "complete_eight_step_course": True,
        "actual_wrong_answer_and_child_requested_hint": True,
        "school_record": matching[0],
        "course_player": {
            "explicit_real_read_pause_resume": True,
            "returned_to_read_after_playback": True,
            "audible_semantic_or_emotional_review": "NOT TESTED: silent emulator",
        },
        "screenshots": [intro, paused, example, hint, recap],
    }


def discovery_course(out: Path) -> dict:
    tap(out, "Mit Lumo Neues entdecken", "discovery-default-off")
    wait_text(out, "Elternfreigabe erforderlich", "discovery-locked")
    locked = existing.capture(out, "13_actual_android_discovery_parent_gate")
    if any(value.get("enabled") is True
           for value in discoveries(out, "discovery-not-silently-granted")):
        raise RuntimeError("Discovery was granted without the adult choice")
    existing.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
    voice.speech.parents(out)
    tap(out, "Bis zur 1. Schulstufe", "discovery-current-limit")
    tap(out, "Bis zur 2. Schulstufe", "discovery-explicit-limit")
    tap(out, "Vorlernen erlauben", "discovery-explicit-switch")
    wait_text(out, "Neues entdecken freigeben", "discovery-local-parent-confirmation")
    consent = existing.capture(out, "14_actual_android_discovery_explicit_parent_choice")
    tap(out, "Als Erwachsene:r freigeben", "discovery-local-confirm")
    choices = discoveries(out, "discovery-actual-saved-parent-choice")
    if len(choices) != 1 or choices[0]["enabled"] is not True or choices[0]["maxGrade"] != 2:
        raise RuntimeError("Actual local parent choice was not saved")
    permissions = voice.settings(out, "discovery-unrelated-permissions")
    for field in ("cloudVoiceEnabled", "microphoneEnabled", "scannerEnabled", "aiProxyEnabled"):
        if permissions.get(field) is not False:
            raise RuntimeError("Discovery granted an unrelated permission: " + field)
    existing.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
    tap(out, "Lernen", "discovery-learning-overview")
    before = school_data(existing.prefs(out, "before-discovery-course"))
    before_wallet = existing.wallet(out, "before-discovery-wallet")
    tap(out, "Mit Lumo Neues entdecken", "discovery-open-hub")
    wait_text(out, "Dein Schulstoff bleibt bei der 1. Klasse.", "discovery-class-unchanged")
    # Two courses expose the same start caption. Identify the correct enabled
    # button from the current real accessibility geometry below its own title.
    tap_named_course(out, "Das Einmaleins entdecken", "discovery-equal-groups")
    wait_text(out, "Neue Dinge entdecken", "discovery-introduction")
    tap(out, "Weiter", "discovery-introduction-next")
    answer(out, "Zählen als Grundlage", "4", "discovery-foundation")
    wait_text(out, "Drei gleiche Gruppen", "discovery-three-groups")
    groups = existing.capture(out, "15_actual_android_higher_grade_equal_groups")
    tap(out, "Weiter", "discovery-example-next")
    answer(out, "Wir zählen zusammen", "6", "discovery-guided-groups")
    answer(out, "Deine Gruppenaufgabe", "8", "discovery-independent-groups")
    answer(out, "Verstehst du die Gruppen?", "3 + 3 + 3", "discovery-groups-check")
    wait_text(out, "Ein neues Prinzip entdeckt", "discovery-complete")
    recap = existing.capture(out, "16_actual_android_complete_discovery_course")
    after = school_data(existing.prefs(out, "after-discovery-school-protection"))
    if after != before or existing.wallet(out, "after-discovery-wallet") != before_wallet:
        raise RuntimeError("Voluntary higher-grade course changed regular school progress or wallet")
    values = discoveries(out, "discovery-actually-saved")
    topic = values[0].get("topics", {}).get("equal_groups", {}) if len(values) == 1 else {}
    if (topic.get("grade") != 2 or topic.get("introduced") is not True
            or topic.get("foundationCorrect") != 1 or topic.get("guidedCorrect") != 1
            or topic.get("independentCorrect") != 1 or topic.get("checkCorrect") != 1):
        raise RuntimeError("Separate actual discovery steps not persisted exactly once")
    return {
        "status": "PASS", "complete_seven_step_course": True,
        "default_parent_gate": True, "explicit_local_parent_choice": True,
        "verified_adult_identity": False, "regular_school_and_wallet_unchanged": True,
        "higher_grade": 2, "regular_grade": 1, "separate_topic": topic,
        "screenshots": [locked, consent, groups, recap],
    }


def tap_named_course(out: Path, title: str, tag: str) -> None:
    # Read real, unmodified accessibility rows; never guess a fixed screen area.
    for attempt in range(20):
        nodes = existing.live.live_nodes(out, f"{tag}-observed-{attempt}")
        titles, buttons = [], []
        for node in nodes:
            if node.get("package") != existing.PACKAGE or node.get("enabled") == "false":
                continue
            value = node.get("text", "") or node.get("content-desc", "")
            bounds = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
            if len(bounds) != 4 or bounds[3] <= bounds[1] or bounds[2] <= bounds[0]:
                continue
            if title in value.splitlines():
                titles.append(bounds)
            if ("Mit Lumo anfangen" in value.splitlines()
                    and node.get("clickable") == "true"):
                buttons.append(bounds)
        if titles and buttons:
            title_box = min(titles, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))
            below = [box for box in buttons if box[1] >= title_box[3]]
            if below:
                box = min(below, key=lambda b: b[1]-title_box[3])
                (out / f"{tag}-actual-target.json").write_text(json.dumps({
                    "courseTitle": title, "titleBounds": title_box, "buttonBounds": box,
                    "method": "Current accessible course title and next enabled start control",
                }, indent=2) + "\n")
                existing.base.adb("shell", "input", "swipe",
                                  str((box[0]+box[2])//2), str((box[1]+box[3])//2),
                                  str((box[0]+box[2])//2), str((box[1]+box[3])//2), "120")
                return
        scrolls = []
        for node in nodes:
            if node.get("scrollable") != "true" or node.get("package") != existing.PACKAGE:
                continue
            box = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
            if len(box) == 4 and box[3] > box[1] and box[2] > box[0]:
                scrolls.append(box)
        if scrolls:
            box = max(scrolls, key=lambda b: (b[2]-b[0])*(b[3]-b[1]))
            x = str((box[0]+box[2])//2)
            existing.base.adb("shell", "input", "swipe", x,
                              str(round(box[1]+.8*(box[3]-box[1]))), x,
                              str(round(box[1]+.25*(box[3]-box[1]))), "350")
        time.sleep(.5)
    existing.capture(out, tag + "-unresolved")
    raise RuntimeError("Named course control not observed: " + title)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {"status": "RUNNING", "test_profile": "Fictional disposable LumoTest",
              "physical_device": False, "paid_api_calls": 0,
              "qa_source": os.environ.get("LUMO_QA_SOURCE")}
    try:
        if voice.main() != 0:
            raise RuntimeError("Existing native update/voice/Kart acceptance failed")
        previous = json.loads((out / "free-voice-android-result.json").read_text())
        result["voice_update_kart"] = previous
        result["candidate_source"] = previous["candidate"]["flutter_source_commit"]
        result["candidate_apk_sha256"] = previous["candidate"]["sha256"]
        existing.base.display(1200, 896, 160)
        result["school_course"] = school_course(out)
        result["discovery_course"] = discovery_course(out)
        tap(out, "Zur Lernübersicht", "discovery-return")
        existing.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        saved_school = school_data(existing.prefs(out, "before-learning-restart"))
        saved_discovery = discoveries(out, "before-discovery-restart")
        saved_wallet = existing.wallet(out, "before-learning-wallet-restart")
        existing.base.adb("shell", "am", "force-stop", existing.PACKAGE)
        existing.base.launch(out, "learning-final-restart")
        if (school_data(existing.prefs(out, "after-learning-restart")) != saved_school
                or discoveries(out, "after-discovery-restart") != saved_discovery
                or existing.wallet(out, "after-learning-wallet-restart") != saved_wallet):
            raise RuntimeError("Actually saved school/discovery progress did not survive restart")
        result["restart_school_discovery_wallet"] = "PASS"
        result["status"] = "PASS"
        result["limitations"] = previous["not_tested"] + [
            "Full curriculum and external Austrian pedagogical sign-off",
            "Production adult identity/security approval",
            "Google Play publication, payments and commercial voice license approval",
        ]
        return 0
    except Exception:
        result["status"] = "FAIL"
        result["error"] = traceback.format_exc()
        return 1
    finally:
        (out / "education-android-result.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        try:
            (out / "education-logcat.txt").write_text(
                existing.base.adb("logcat", "-d", "-t", "2500"))
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
