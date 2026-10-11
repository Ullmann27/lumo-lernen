#!/usr/bin/env python3
"""Actual APK update, offline inference/player and UI checks, NOT audible timbre.

Uses fictional disposable emulator profiles and real accessible controls only.
No progress injection, gate bypass, microphone recording or public speech API.
The emulator is silent; human emotional and physical-device acceptance stay open.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creative_android_probe as existing
import lumo_speech_android_probe as speech

BASE_SOURCE = "8ba6b1fc9791ede5977d7b624fe692405fd44277"
BASE_SHA = "ce4a72cb2831067401799c7e15f0649057f487b89fb40a54c23db5f52b8d4dd7"
PROFILE = "lumo-free-supertonic-de-v1"
GREETING = "Lumo Frei / F2 / lokale Aufnahme free_b5e456b1bd716ab4.m4a"
ASSENT = ("Als erwachsene Person akzeptiere ich für die lokale Sprachfunktion "
          "die obenstehenden Modellbedingungen einschließlich der Nutzungsbeschränkungen.")


def delivery(path: Path, version: int, source: str) -> dict:
    data = json.loads((path.parent / "BUILD-PROVENANCE.json").read_text())
    if (data["flutter_source_commit"] != source or data["versionCode"] != version
            or data["package"] != existing.PACKAGE or data["abis"] != ["x86_64"]
            or data["tracked_source_clean"] is not True
            or data["signingCertificateSha256"] != existing.CERT
            or data["sha256"] != existing.digest(path)):
        raise RuntimeError("Actual APK does not match the verified test artifact")
    if version == 1929:
        voice = data["offlineVoice"]
        if (voice["profile"] != PROFILE or voice["preset"] != "F2"
                or voice["speakerId"] != 1 or voice["clipCount"] != 155):
            raise RuntimeError("Candidate local voice manifest differs")
    return data


def stats(text: str) -> tuple[int, int]:
    starts = re.findall(r"Bestätigte Wiedergabestarts:\s*(\d+)", text)
    ends = re.findall(r"Native Abschlussmeldungen:\s*(\d+)", text)
    if not starts or not ends:
        raise RuntimeError("Actual native start/completion counters not observed")
    return int(starts[-1]), int(ends[-1])


def status(out: Path, tag: str, required: tuple[str, ...], timeout=45) -> str:
    """Keep each changing voice state and its counters in one actual frame.

    Static build/model notices may need scrolling. An earlier speaking frame
    must never be concatenated with a later idle frame to manufacture success.
    """
    deadline = time.monotonic() + timeout
    attempt = 0
    static_seen: set[str] = set()
    scroll_step = 0
    while time.monotonic() < deadline:
        nodes = existing.live.live_nodes(out, f"{tag}-{attempt}")
        voice_frames = []
        for node in nodes:
            if node.get("package") != existing.PACKAGE:
                continue
            for key in ("text", "content-desc"):
                value = node.get(key, "")
                if not value:
                    continue
                if "Sprachstatus:" in value:
                    if ("Bestätigte Wiedergabestarts:" in value
                            and "Native Abschlussmeldungen:" in value):
                        voice_frames.append(value)
                elif not any(marker in value for marker in (
                        "Zuletzt gestartete Quelle:", "Bestätigte Wiedergabestarts:",
                        "Native Abschlussmeldungen:")):
                    static_seen.add(value)
        # A single real diagnostic paragraph contains state, source and both
        # native counters. Never substitute a saved or partial old paragraph.
        current = max(voice_frames, key=len, default="")
        text = "\n".join(sorted(static_seen)) + "\n" + current
        if all(marker in text for marker in required):
            return text
        waiting_for_static = any(
            marker not in text and not marker.startswith((
                "Sprachstatus:", "Lumo Frei /", "Native Abschlussmeldungen:",
                "Bestätigte Wiedergabestarts:",
            )) for marker in required
        )
        if current and not waiting_for_static:
            if "Sprachstatus: Keine Sprachausgabe verfügbar" in current:
                raise RuntimeError("Actual app reported unavailable speech: " + current)
            # Do not lose the currently visible dynamic state by unnecessary
            # scrolling while waiting for its real source/start/completion.
        else:
            scrolls = []
            for node in nodes:
                if (node.get("scrollable") != "true"
                        or node.get("package") != existing.PACKAGE):
                    continue
                bounds = list(map(int, re.findall(r"\d+", node.get("bounds", ""))))
                if len(bounds) == 4:
                    x0, y0, x1, y1 = bounds
                    if x1 > x0 and y1 > y0:
                        scrolls.append(((x1-x0)*(y1-y0), x0, y0, x1, y1))
            if scrolls:
                _, x0, y0, x1, y1 = max(scrolls)
                low, high = round(y0+(y1-y0)*.2), round(y1-(y1-y0)*.2)
                up = (scroll_step // 12) % 2 == 0
                start, end = (low, high) if up else (high, low)
                existing.base.adb("shell", "input", "swipe", str((x0+x1)//2),
                                  str(start), str(end), "350")
                scroll_step += 1
        attempt += 1
        time.sleep(.25)
    raise TimeoutError(f"Actual speech status not reached: {required}")


def settings(out: Path, tag: str) -> dict:
    return json.loads(existing.prefs(out, tag).get("flutter.lumo_app_settings_v1", "{}"))


def protected(data: dict) -> dict:
    # Read-only preservation of real stored fictional app state.
    return {key: value for key, value in data.items()
            if re.search(r"profile|progress|reward|stars|history", key, re.I)}


def exact_observed_tap(out: Path, label: str, tag: str) -> None:
    existing.flutter_tap(out, label, tag)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {
        "status": "RUNNING", "scope": "Actual Android16 x86_64 test APK",
        "not_tested": ["audible timbre/emotional acceptance", "physical Samsung",
                       "physical hinge events", "ARM64 device playback",
                       "50 spoken situations on Android", "full Kart race"],
        "paid_speech_calls": 0, "microphone_recording": False,
    }
    try:
        candidate = delivery(args.candidate, 1929, os.environ["LUMO_EXPECT_SOURCE"])
        baseline = delivery(args.baseline, 1928, BASE_SOURCE)
        if baseline["sha256"] != BASE_SHA:
            raise RuntimeError("Baseline APK is not the original verified 1928 x86_64 artifact")
        if candidate["sha256"] != os.environ["LUMO_EXPECT_APK_SHA"]:
            raise RuntimeError("Candidate digest differs from build job output")
        result["candidate"] = candidate
        result["baseline"] = baseline
        result["root"] = existing.ensure_rooted_emulator(existing.base.adb, out)
        api = int(existing.base.adb("shell", "getprop", "ro.build.version.sdk"))
        if api != 36:
            raise RuntimeError("Expected actual Android16/API36 emulator")
        result["android_api"] = api
        existing.base.display(1080, 2400, 480)
        installed = existing.base.adb("install", "-r", "--no-streaming",
                                      str(args.baseline), timeout=180)
        if "Success" not in installed:
            raise RuntimeError("Verified baseline install failed")
        existing.base.launch(out, "baseline")
        result["onboarding"] = existing.onboard(out)
        before_identity = existing.package_identity(out, "before-update")
        before_profile = protected(existing.prefs(out, "before-update"))
        before_wallet = existing.wallet(out, "before-update-wallet")
        if "LumoTest" not in before_profile.get("flutter.lumo_active_profile", ""):
            raise RuntimeError("No real persisted fictional baseline profile")
        existing.base.adb("shell", "am", "force-stop", existing.PACKAGE)
        update = existing.base.adb("install", "-r", "--no-streaming",
                                  str(args.candidate), timeout=240)
        after_identity = existing.package_identity(out, "after-update")
        if ("Success" not in update or not after_identity["versionCode"].startswith("1929")
                or after_identity["userId"] != before_identity["userId"]
                or after_identity["firstInstallTime"] != before_identity["firstInstallTime"]):
            raise RuntimeError("Update failed or changed installation identity")
        result["in_place_update"] = {"before": before_identity, "after": after_identity}
        existing.base.adb("shell", "svc", "wifi", "disable")
        existing.base.adb("shell", "svc", "data", "disable")
        existing.base.adb("shell", "cmd", "connectivity", "airplane-mode", "enable")
        existing.base.launch(out, "candidate-offline")
        if protected(existing.prefs(out, "after-update")) != before_profile:
            raise RuntimeError("Stored profile/progress/rewards changed during update")
        speech.parents(out)
        result["parents"] = existing.capture(out, "00_actual_android_phone_parents")
        # Twelve forward swipes did not reach speech in the actual long phone
        # parent view. Keep the real phone entry proof, then use the existing
        # roomy viewport and an explicitly bounded, forward-first search.
        existing.base.display(1200, 896, 160)
        existing.flutter_tap(out, "App und lokale Stimme prüfen", "local-diagnosis",
                             scroll_attempts=48, direction_order=(1, -1))
        text = status(out, "actual-model-diagnosis",
                      ("Build 1929", existing.PACKAGE, existing.CERT,
                       "Das lokale Lumo-Sprachmodell", "Native Abschlussmeldungen:"))
        starts, ends = stats(text)
        if settings(out, "before-local-assent").get("localVoiceLicenseAccepted", False) is not False:
            raise RuntimeError("Migration silently granted model terms")
        existing.capture(out, "01_actual_android_local_voice_diagnosis")

        # Real UI pause/resume; no fake completion injection or native mock.
        existing.flutter_tap(out, "Stimme testen", "free-greeting")
        existing.flutter_tap(out, "Pause", "pause-actual-greeting")
        paused = status(out, "greeting-paused", ("Sprachausgabe pausiert", GREETING,
                                              "Native Abschlussmeldungen:"))
        pause_counts = stats(paused)
        if pause_counts != (starts + 1, ends):
            raise RuntimeError("Greeting did not pause its one actual native start")
        existing.capture(out, "02_actual_android_free_greeting_paused")
        time.sleep(1)
        stable = status(out, "still-paused", ("Sprachausgabe pausiert", GREETING,
                                           "Native Abschlussmeldungen:"))
        if stats(stable) != pause_counts:
            raise RuntimeError("Paused audio completed or restarted")
        existing.flutter_tap(out, "Fortsetzen", "resume-actual-greeting")
        completed = status(out, "greeting-completed", ("Sprachstatus: Ruhe", GREETING,
                                                     "Native Abschlussmeldungen:"))
        if stats(completed) != (starts + 1, ends + 1):
            raise RuntimeError("Native greeting did not finish without a new source")
        result["greeting_player"] = {
            "before": [starts, ends], "paused": list(pause_counts),
            "completed": list(stats(completed)), "source": GREETING,
            "audible_timbre": "NOT TESTED: silent emulator",
        }

        # This is a fictional local test-app license flow, not granting a
        # user's online/privacy/microphone consent or submitting vendor terms.
        existing.base.display(1200, 896, 160)
        existing.flutter_tap(out, "Neue Sätze offline vorlesen", "local-model-terms")
        speech.read_in_scroll(out, "model-license", ("Neue Sätze kostenlos vorlesen",
                                                  "kein Sprach-API-Aufruf"))
        existing.capture(out, "03_actual_android_local_voice_license")
        exact_observed_tap(out, ASSENT, "model-terms-checkbox")
        existing.flutter_tap(out, "Lokale Stimme freigeben", "confirm-local-test-license")
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            saved = settings(out, "local-license-saved")
            if saved.get("localVoiceLicenseAccepted") is True:
                break
            time.sleep(.25)
        else:
            raise RuntimeError("Actual parent UI did not persist its explicit local assent")
        for field in ("cloudVoiceEnabled", "microphoneEnabled", "scannerEnabled", "aiProxyEnabled"):
            if saved.get(field) is not False:
                raise RuntimeError("Local model assent granted unrelated permissions: " + field)
        result["local_assent"] = {
            "explicit_ui_action": True, "unrelated_permissions": "all false",
            "scope": "Fictional disposable test configuration, no identity verification claim",
        }

        text = status(out, "before-fresh-synthesis", ("Sprachstatus: Ruhe",
                                                     "Native Abschlussmeldungen:"))
        starts, ends = stats(text)
        existing.flutter_tap(out, "Neue Rechenhilfe anhören", "fresh-local-math")
        native = status(out, "fresh-native-start",
                        ("Lumo Frei / F2 / lokale Synthese", "Native Abschlussmeldungen:"),
                        timeout=100)
        if stats(native)[0] != starts + 1:
            raise RuntimeError("Fresh on-device inference produced no confirmed player start")
        existing.capture(out, "04_actual_android_fresh_local_math")
        completed = status(out, "fresh-native-completion",
                           ("Sprachstatus: Ruhe", "Lumo Frei / F2 / lokale Synthese",
                            "Native Abschlussmeldungen:"), timeout=100)
        if stats(completed) != (starts + 1, ends + 1):
            raise RuntimeError("Actual newly generated math audio did not complete")
        result["fresh_local_math"] = {
            "confirmed_native_start": True, "confirmed_native_completion": True,
            "cloud_disabled": True, "network_disabled": True,
            "source": "Lumo Frei / F2 / lokale Synthese",
            "audio_content_human_review": "NOT TESTED",
        }
        # Stop a genuinely started local clip; stopping must not manufacture
        # a natural completion or restart it afterwards.
        starts, ends = stats(completed)
        existing.flutter_tap(out, "Stimme testen", "greeting-for-stop")
        existing.flutter_tap(out, "Stopp", "stop-actual-greeting")
        stopped = status(out, "greeting-stopped",
                         ("Sprachstatus: Ruhe", GREETING,
                          "Native Abschlussmeldungen:"))
        if stats(stopped) != (starts + 1, ends):
            raise RuntimeError("Stop did not interrupt exactly one real native start")
        time.sleep(1)
        stable = status(out, "greeting-stays-stopped",
                        ("Sprachstatus: Ruhe", GREETING,
                         "Native Abschlussmeldungen:"))
        if stats(stable) != stats(stopped):
            raise RuntimeError("Stopped greeting completed or restarted later")
        result["stop_control"] = {
            "before": [starts, ends], "after": list(stats(stopped)),
            "natural_completion_not_faked": True,
        }
        existing.capture(out, "04b_actual_android_greeting_stopped")
        result["layouts"] = []
        for name, width, height, density in [
            ("phone", 360, 800, 160), ("fold-target", 2176, 1812, 225),
            ("phone-return", 360, 800, 160),
        ]:
            existing.base.display(width, height, density)
            result["layouts"].append(existing.capture(out, "05_local_voice_" + name))
            if existing.PACKAGE not in existing.base.foreground():
                raise RuntimeError("Speech settings lost foreground during display resize")

        # Preserve the already integrated game without claiming a full race.
        existing.base.adb("shell", "input", "keyevent", "KEYCODE_BACK")
        existing.flutter_tap(out, "Spielen", "home-games")
        existing.base.display(1200, 896, 160)
        existing.enter(out, "Lumo Kart", "Einzelrennen", "preserved-kart",
                       launch_label="Losfahren")
        result["kart_menu"] = existing.capture(out, "06_preserved_kart_menu")
        existing.leave(out, "preserved-kart", already_menu=True,
                       return_label="Zum Lernen")
        result["kart_return"] = existing.flutter_return_capture(out, "07_preserved_kart_return")

        existing.base.adb("shell", "am", "force-stop", existing.PACKAGE)
        existing.base.launch(out, "final-restart")
        if protected(existing.prefs(out, "final-profile-state")) != before_profile:
            raise RuntimeError("Speech, Kart or restart changed profile/progress/rewards")
        if existing.wallet(out, "final-wallet") != before_wallet:
            raise RuntimeError("Voice controls or Kart entry changed the learning wallet")
        if settings(out, "final-settings").get("localVoiceLicenseAccepted") is not True:
            raise RuntimeError("Explicit local model terms did not survive restart")
        result.update(status="PASS", profile_retained=True, wallet_retained=True,
                      package=existing.PACKAGE, certificate_sha256=existing.CERT)
        return 0
    except Exception:
        result["status"] = "FAIL"
        result["error"] = traceback.format_exc()
        return 1
    finally:
        (out / "free-voice-android-result.json").write_text(
            json.dumps(result, ensure_ascii=False, indent=2) + "\n")
        try:
            (out / "logcat.txt").write_text(existing.base.adb("logcat", "-d", "-t", "2000"))
        except Exception:
            pass


if __name__ == "__main__":
    raise SystemExit(main())
