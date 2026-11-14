"""Synthetic readiness counterexamples and the exact upstream JS control flow.

These tests do not run an emulator and never certify Android or an APK. The
upstream fixture comes from the separately pinned action checkout in CI.
"""

from __future__ import annotations

import importlib.util
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


READY = load("framework_ready", ROOT / "scripts/android_framework_ready.py")
PATCH = load("action_patch", ROOT / "scripts/prepare_android37_emulator_action.py")


class Clock:
    def __init__(self):
        self.value = 0.0

    def now(self):
        return self.value

    def sleep(self, seconds):
        self.value += seconds


class SyntheticRecorder:
    def __init__(self, clock, samples):
        self.clock, self.samples = clock, samples
        self.index = -1
        self.commands = []

    def run(self, name, arguments, timeout):
        if name == "properties":
            self.index += 1
        sample = self.samples[min(self.index, len(self.samples) - 1)]
        self.clock.value += min(0.01, timeout)
        self.commands.append((name, arguments, timeout))
        pid = sample.get("pid", "812")
        count = sample.get("count", "1")
        values = {
            "properties": f"[sys.boot_completed]: [1]\n[sys.system_server.start_count]: [{count}]\n[ro.build.version.sdk]: [{sample.get('sdk', '37')}]\n[ro.build.version.release]: [{sample.get('release', '17')}]\n[ro.build.fingerprint]: [synthetic/android37/test-only]\n",
            "pid-before": pid,
            "pid-after": sample.get("end_pid", pid),
            "count-after": count,
            "settings-read": sample.get("boot_count", "1"),
            "package-read": "package:/system/framework/framework-res.apk",
            "window-read": "Physical size: 1080x2340",
            "window-state": self.window_state(sample),
            "input-state": sample.get("input_dump", "Input Dispatcher State:\n"
                                      + "  DispatchEnabled: " + ("false" if sample.get("input_disabled") else "true") + "\n"
                                      + "  DispatchFrozen: " + ("true" if sample.get("input_frozen") else "false") + "\n"),
            "events-anr": sample.get("anr_events", "--------- beginning of events\n"),
            "unlock-keyguard": "",
        }
        values.update({f"service-{service}": f"Service {service}: found" for service in READY.SERVICES})
        for missing in sample.get("missing", []):
            values[f"service-{missing}"] = f"Service {missing}: not found"
        if sample.get("settings_failure"):
            values["settings-read"] = ""
        failed = ((sample.get("settings_failure") and name == "settings-read")
                  or (sample.get("input_failure") and name == "input-state")
                  or (sample.get("unlock_failure") and name == "unlock-keyguard"))
        timed_out = sample.get("timeout_command") == name
        return {"returncode": 20 if failed or timed_out else 0, "timed_out": timed_out,
                "stdout": values[name], "stderr": "", "stdout_file": f"synthetic/{self.index}/{name}"}

    @staticmethod
    def window_state(sample):
        """AOSP-format synthetic states; these are not emulator captures."""
        truth = lambda value: "true" if value else "false"
        locked = sample.get("locked", False)
        component = sample.get("component", "com.example.launcher/.Home")
        token = sample.get("focus_token", "12ab")
        focus = f"Window{{{token} u0 {component}}}" if sample.get("focus", True) else "null"
        if locked:
            focus = f"Window{{{token} u0 NotificationShade}}"
        last_anr = sample.get("last_anr", "  <no ANR has occurred since boot>")
        state = f"""WINDOW MANAGER LAST ANR (dumpsys window lastanr)
{last_anr}

{'-' * 79}
WINDOW MANAGER POLICY STATE (dumpsys window policy)
  KeyguardServiceDelegate
    showing={truth(locked)}
    inputRestricted={truth(sample.get('input_restricted', locked))}
    occluded=false
    secure={truth(sample.get('secure', False))}
    dreaming=false
    systemIsReady=true
    deviceHasKeyguard=true
    enabled=true
    bootCompleted=true
    screenState={'SCREEN_STATE_ON' if sample.get('awake', True) else 'SCREEN_STATE_OFF'}
    interactiveState={'INTERACTIVE_STATE_AWAKE' if sample.get('awake', True) else 'INTERACTIVE_STATE_SLEEP'}

{'-' * 79}
WINDOW MANAGER DISPLAY CONTENTS (dumpsys window displays)
  mCurrentFocus={focus}
  mFocusedApp=ActivityRecord{{34cd u0 {sample.get('focused_app', component)} t1}}

{'-' * 79}
WINDOW MANAGER WINDOWS (dumpsys window windows)
  Window #0 {focus}:
    mHasSurface={truth(sample.get('surface', True))} isReadyForDisplay()={truth(sample.get('surface', True))} mWindowRemovalAllowed=false
  mSystemBooted=true mDisplayEnabled=true
  mDisplayFrozen={truth(sample.get('display_frozen', False))} windows=0 client=false apps=0
"""
        if sample.get("ambiguous_focus"):
            state += "  mCurrentFocus=Window{99ef u0 com.example.other/.Other}\n"
        if sample.get("unknown_keyguard"):
            state = state.replace("  KeyguardServiceDelegate\n", "  UnknownKeyguardFormat\n")
        if sample.get("unknown_secure"):
            state = state.replace("    secure=false\n", "")
        if sample.get("input_freeze"):
            state += "  mInputFreezeReason=synthetic resize\n"
        return state


class FrameworkReadinessTests(unittest.TestCase):
    def poll(self, samples, timeout=14):
        clock = Clock()
        recorder = SyntheticRecorder(clock, samples)
        return READY.poll_framework(recorder, timeout, 10, 3, 2, clock.now, clock.sleep), recorder

    def test_boot_property_cannot_replace_input_or_settings_service(self):
        for service in ("input", "settings"):
            with self.subTest(service=service):
                result, _ = self.poll([{"missing": [service]}])
                self.assertEqual(result["status"], "FAIL")
                self.assertEqual(result["reason"], "framework_readiness_deadline_exceeded")
                self.assertIn(f"service_not_registered:{service}", result["samples"][0]["errors"])
                self.assertLessEqual(result["elapsed_seconds"], 14.000001)

    def test_registered_service_without_real_settings_read_still_fails(self):
        result, _ = self.poll([{"settings_failure": True}])
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("settings_provider_not_readable", result["samples"][0]["errors"])

    def test_changed_system_server_identity_is_failure_not_a_new_success_window(self):
        result, _ = self.poll([{}, {"pid": "903", "count": "2"}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["reason"], "observed_system_server_identity_changed")
        self.assertTrue(result["observed_start_count_greater_than_one"])

    def test_android35_cannot_satisfy_android37_framework_guard(self):
        result, _ = self.poll([{"sdk": "35", "release": "15"}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["reason"], "wrong_android_runtime")

    def test_transient_missing_service_must_be_followed_by_full_stable_window(self):
        result, recorder = self.poll([{"missing": ["input"]}, {"boot_count": "0"}], timeout=18)
        self.assertEqual(result["status"], "PASS")
        self.assertGreaterEqual(result["stable_observed_seconds"], 10)
        self.assertGreaterEqual(result["consecutive_ready_samples"], 3)
        self.assertFalse(result["samples"][0]["ready"])
        self.assertTrue(all(name not in ("install", "setprop") for name, _, _ in recorder.commands))

    def test_real_command_timeout_preserves_raw_stdout_and_stderr(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            command = root / "synthetic_command.py"
            command.write_text("import sys,time\nsys.stdout.buffer.write(b'raw-out\\x00\\n');sys.stdout.flush()\nsys.stderr.write('raw-error\\n');sys.stderr.flush()\ntime.sleep(30)\n")
            recorder = READY.Recorder(root, sys.executable, str(command))
            result = recorder.run("timeout-counterexample", [], 0.15)
            self.assertTrue(result["timed_out"])
            self.assertNotEqual(result["returncode"], 0)
            self.assertEqual((root / result["stdout_file"]).read_bytes(), b"raw-out\x00\n")
            self.assertEqual((root / result["stderr_file"]).read_bytes(), b"raw-error\n")

    def test_unlocked_visible_focused_activity_needs_no_input(self):
        result, recorder = self.poll([{}])
        self.assertEqual(result["status"], "PASS")
        self.assertTrue(result["samples"][-1]["interactive"]["ready"])
        self.assertFalse(result["unlock_action"]["attempted"])
        self.assertFalse(any(name == "unlock-keyguard" or args[:1] == ["input"]
                             for name, args, _ in recorder.commands))

    def test_actual_848_anr_events_reject_service_positive_counterexample(self):
        folder = ROOT / "scripts/tests/fixtures/android37_system_anr_848"
        meta = json.loads((folder / "manifest.json").read_text())
        original = (folder / meta["fixture"]).read_bytes()
        self.assertEqual(hashlib.sha256(original).hexdigest(), meta["fixture_sha256"])
        self.assertIn(b"keyCode=MENU(82)", original)
        result, recorder = self.poll([{"anr_events": original.decode()}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["reason"], "observed_android_anr")
        self.assertEqual(result["consecutive_ready_samples"], 0)
        self.assertFalse(any(name == "unlock-keyguard" for name, _, _ in recorder.commands))

    def test_window_last_anr_cannot_be_hidden_by_empty_event_buffer(self):
        result, _ = self.poll([{"last_anr": "  ANR in system: missing focused window"}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["reason"], "observed_android_anr")

    def test_unknown_ambiguous_or_unready_surface_is_not_a_pass(self):
        for sample in ({"focus": False}, {"ambiguous_focus": True},
                       {"unknown_keyguard": True}, {"surface": False},
                       {"focused_app": "com.example.other/.Other"},
                       {"input_restricted": True}, {"awake": False},
                       {"display_frozen": True}, {"input_freeze": True},
                       {"timeout_command": "window-state"}):
            with self.subTest(sample=sample):
                result, recorder = self.poll([sample])
                self.assertEqual(result["status"], "FAIL")
                self.assertLessEqual(result["elapsed_seconds"], 14.000001)
                self.assertFalse(any(name == "unlock-keyguard" for name, _, _ in recorder.commands))

    def test_one_observed_nonsecure_unlock_requires_new_stable_surface(self):
        result, recorder = self.poll([{"locked": True}, {}], timeout=18)
        self.assertEqual(result["status"], "PASS")
        unlocks = [(args, timeout) for name, args, timeout in recorder.commands if name == "unlock-keyguard"]
        self.assertEqual(len(unlocks), 1)
        self.assertEqual(unlocks[0][0], ["wm", "dismiss-keyguard"])
        self.assertLessEqual(unlocks[0][1], 5)
        self.assertTrue(result["unlock_action"]["attempted"])
        self.assertFalse(result["samples"][0]["ready"])
        self.assertGreaterEqual(result["stable_observed_seconds"], 10)
        self.assertGreaterEqual(result["consecutive_ready_samples"], 3)

    def test_zero_exit_from_unlock_is_not_a_surface_acknowledgment(self):
        result, recorder = self.poll([{"locked": True}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(sum(name == "unlock-keyguard" for name, _, _ in recorder.commands), 1)
        self.assertEqual(result["consecutive_ready_samples"], 0)

    def test_secure_unknown_or_sleeping_keyguard_never_gets_blind_input(self):
        for sample in ({"locked": True, "secure": True},
                       {"locked": True, "unknown_secure": True},
                       {"locked": True, "awake": False}):
            with self.subTest(sample=sample):
                result, recorder = self.poll([sample])
                self.assertEqual(result["status"], "FAIL")
                self.assertFalse(any(name == "unlock-keyguard" for name, _, _ in recorder.commands))

    def test_failed_unlock_stops_and_preserves_the_failure(self):
        result, recorder = self.poll([{"locked": True, "unlock_failure": True}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["reason"], "keyguard_unlock_command_failed")
        self.assertEqual(sum(name == "unlock-keyguard" for name, _, _ in recorder.commands), 1)

    def test_focus_change_restarts_the_same_stability_requirement(self):
        result, _ = self.poll([{"focus_token": f"token{i}"} for i in range(20)])
        self.assertEqual(result["status"], "FAIL")
        self.assertLess(result["stable_observed_seconds"], 10)

    def test_anr_after_unlock_is_terminal_without_another_unlock(self):
        result, recorder = self.poll([{"locked": True}, {"last_anr": "  ANR in system"}])
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["reason"], "observed_android_anr")
        self.assertEqual(sum(name == "unlock-keyguard" for name, _, _ in recorder.commands), 1)


class ExactUpstreamActionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fixture = ROOT / "scripts/tests/fixtures/android_emulator_runner_a421"
        cls.source = Path(os.environ.get("LUMO_ACTION_TEST_SOURCE", str(fixture)))
        for path, digest in PATCH.ORIGINAL_HASHES.items():
            actual = PATCH.sha256((cls.source / path).read_bytes())
            if actual != digest:
                raise AssertionError(f"Unreviewed upstream fixture: {path}")

    def test_only_observed_setup_replaces_menu_and_tampered_upstream_is_rejected(self):
        for path in PATCH.MODIFIED_PATHS:
            original = (self.source / path).read_bytes()
            patched = PATCH.patch_bytes(path, original)
            lines = patched.decode().splitlines(keepends=True)
            stripped = "".join(line for line in lines if not any(line.strip() == guard for guard in PATCH.GUARD_LINES)).encode()
            menu = b"await adb(port, `shell input keyevent 82`);\n"
            original_lines = original.splitlines(keepends=True)
            self.assertEqual(sum(line.strip() == menu.strip() for line in original_lines), 1)
            self.assertEqual(stripped, b"".join(line for line in original_lines if line.strip() != menu.strip()))
            with self.assertRaises(ValueError):
                PATCH.patch_bytes(path, original + b"\n")
        self.assertEqual(PATCH.sha256((self.source / "LICENSE").read_bytes()), PATCH.ORIGINAL_HASHES["LICENSE"])

    def test_exact_original_main_keeps_settings_tour_and_cleanup_after_observed_setup(self):
        node = r'''
const fs = require('fs'), vm = require('vm');
const [managerPath, mainPath, scenario] = process.argv.slice(2);
const calls = [], failures = [];
const env = {GITHUB_WORKSPACE:'/synthetic-probe',ANDROID_HOME:'/synthetic-sdk',ANDROID_AVD_HOME:'/synthetic-avd'};
const inputs = {'api-level':'37.0','target':'google_apis','arch':'x86_64','profile':'pixel_5','cores':'2','ram-size':'4096M','heap-size':'512M','avd-name':'test','force-avd-creation':'true','emulator-boot-timeout':'300','emulator-port':'5554','emulator-options':'-no-window','disable-animations':'true','disable-spellchecker':'false','disable-linux-hw-accel':'false','enable-hw-keyboard':'false','channel':'stable','script':'unchanged-tour-command'};
const exec = {exec:async(command,args=[],options={})=>{
  calls.push({command,args});
  if(command.includes('getprop sys.boot_completed')) options.listeners.stdout(Buffer.from('1\n'));
  if(command==='python3' && scenario==='guard-failure') throw Error('synthetic missing input service');
  if(command.includes('shell input keyevent 82') && scenario==='keyevent-failure') throw Error('synthetic original keyevent failure');
  return 0;
}};
const quiet={log:()=>{},warn:()=>{}};
const sandbox = {exports:{},require:(id)=>id==='@actions/exec'?exec:require(id),console:quiet,process:{env,platform:'linux'},setTimeout};
vm.runInNewContext(fs.readFileSync(managerPath,'utf8'),sandbox);
const validators = new Proxy({MIN_PORT:5554,playstoreTargetSubstitution:(value)=>value},{get:(target,key)=>target[key]||(()=>{})});
const main = {exports:{},console:quiet,process:{env,platform:'linux',chdir:()=>{}},setTimeout,require:(id)=>({
  '@actions/core':{getInput:(name)=>inputs[name]||'',setFailed:(message)=>failures.push(message)},
  '@actions/exec':exec,'./sdk-installer':{installAndroidSdk:async()=>{}},'./input-validator':validators,
  './emulator-manager':sandbox.exports,'./script-parser':{parseScript:(s)=>[s]},'./channel-id-mapper':{getChannelId:()=>0},
  'fs':{accessSync:()=>{},constants:{R_OK:4,W_OK:2}}
}[id] || require(id))};
const originalMain=fs.readFileSync(mainPath,'utf8');
if(!originalMain.endsWith('run();\n')) throw Error('unexpected original main entry point');
vm.runInNewContext(originalMain.slice(0,-7)+'globalThis.finished = run();\n', main);
main.finished.then(()=>process.stdout.write(JSON.stringify({calls,failures}))).catch((error)=>{console.error(error);process.exit(1);});
'''
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            runner = folder / "run-exact-action.js"
            runner.write_text(node)
            manager = folder / "emulator-manager.js"
            manager.write_bytes(PATCH.patch_bytes("lib/emulator-manager.js", (self.source / "lib/emulator-manager.js").read_bytes()))
            for scenario in ("success", "guard-failure", "keyevent-failure"):
                with self.subTest(scenario=scenario):
                    result = subprocess.run(["node", str(runner), str(manager), str(self.source / "lib/main.js"), scenario], check=True, capture_output=True, text=True)
                    record = json.loads(result.stdout)
                    commands = [item["command"] for item in record["calls"]]
                    self.assertIn("python3", commands, "The original boot property must not bypass framework readiness")
                    guard = commands.index("python3")
                    kills = [i for i, command in enumerate(commands) if "emu kill" in command]
                    self.assertEqual(len(kills), 1)
                    self.assertGreater(kills[0], guard)
                    keys = [i for i, command in enumerate(commands) if "shell input keyevent 82" in command]
                    self.assertEqual(keys, [], "A positively confirmed unlocked surface must not receive redundant MENU82")
                    settings = [command for command in commands if "settings put global" in command]
                    self.assertEqual(len(settings), 0 if scenario == "guard-failure" else 3)
                    self.assertEqual(bool(record["failures"]), scenario == "guard-failure")
                    tours = [item for item in record["calls"]
                             if item["command"] == "sh" and item["args"] == ["-c", "unchanged-tour-command"]]
                    self.assertEqual(len(tours), 0 if scenario == "guard-failure" else 1)


if __name__ == "__main__":
    unittest.main()
