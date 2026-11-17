"""Original ANR regressions and explicit synthetic recording-lifetime contracts.

No emulator, APK or device acceptance is claimed by these local tests. Existing
7b16 original fixtures are read without changes. The subprocess test uses a
clearly synthetic local adb executable to exercise actual monitor stop semantics.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("runtime_anr", ROOT / "scripts/verify_android_runtime_anr.py")
ANR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ANR)
READY = ANR.FRAMEWORK
FIXTURES = ROOT / "scripts/tests/fixtures/android37_window_7b16"
INPUT_READY = "Input Manager State:\nInput Dispatcher State:\n  DispatchEnabled: true\n  DispatchFrozen: false\n"
FINGERPRINT = "synthetic/android37/monitor-contract-only"
PROPERTIES = ("[sys.boot_completed]: [1]\n[sys.system_server.start_count]: [1]\n"
              "[ro.build.version.sdk]: [37]\n[ro.build.version.release]: [17]\n"
              f"[ro.build.fingerprint]: [{FINGERPRINT}]\n")
# Exact ActivityManager line 32405 of original artifact 14093659058/logcat-all.stdout.
# Full original SHA256: 0e484eaaac9909f544740cec58728122d7abf0de1a7b914f4790b733d8a254e7.
ORIGINAL_ACTIVITY_MANAGER_ANR = (
    "11-14 02:29:52.506   627  2563 E ActivityManager: ANR in com.google.android.gms.persistent\n"
)
# Exact 77 original bytes from artifact14093659058/framework-start/wait-for-device.stderr.
# SHA256 d84aaa3222b49c6dfc6c07666347890c6ad2ff255b911fa83525c5814e54963c.
ORIGINAL_ADB_START = (
    b"* daemon not running; starting now at tcp:5037\n"
    b"* daemon started successfully\n"
)


def put(path: Path, value: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2) + "\n")


def at(seconds: float) -> str:
    return (datetime(2026, 11, 14, 2, 28, 38, tzinfo=timezone.utc) + timedelta(seconds=seconds)).isoformat()


class RuntimeAnrTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads((FIXTURES / "manifest.json").read_text())
        if manifest["host_sha"] != "7b16f2f5ab16f3d913ee170aefd9807c87216260" or manifest["artifact_id"] != 14093659058:
            raise AssertionError("Unexpected real ANR source")
        for item in manifest["files"]:
            raw = (FIXTURES / item["path"]).read_bytes()
            if len(raw) != item["bytes"] or hashlib.sha256(raw).hexdigest() != item["sha256"]:
                raise AssertionError("Changed original fixture: " + item["path"])

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="lumo-runtime-anr-contract-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.framework, self.out = self.root / "framework-start", self.root / "runtime-anr"
        self.framework.mkdir()
        self.out.mkdir()
        self.adb = "/synthetic-sdk/platform-tools/adb"
        self.serial = "emulator-5554"
        self.make_evidence()

    def make_evidence(self):
        monitor = {"pid": 1234, "start_ticks": "100", "serial": self.serial, "adb": self.adb,
                   "started_at": at(0), "budget_seconds": 450, "command": ["synthetic-monitor"]}
        ready = {"schema": 1, "status": "PASS", "finished_at": at(65), "serial": self.serial,
                 "adb": self.adb, "monitor_alive_at_finish": True,
                 "samples": [{"pid": "627", "start_count": "1", "android_runtime": {"fingerprint": FINGERPRINT}}]}
        put(self.framework / "monitor-process.json", monitor)
        put(self.framework / "framework-readiness.json", ready)
        for name in ("wait-for-device.stdout", "wait-for-device.stderr", "logcat-all.stderr", "monitor.stdout", "monitor.stderr"):
            (self.framework / name).write_bytes(b"")
        (self.framework / "logcat-all.stdout").write_text(
            "--------- beginning of main\n"
            "11-14 02:28:50.000   627   627 I SyntheticBoot: observer fixture only\n"
            "11-14 02:30:10.000   627   627 I SyntheticTour: endpoint fixture only\n")
        wait = {"command": [self.adb, "-s", self.serial, "wait-for-device"], "started_at": at(.1),
                "finished_at": at(10), "returncode": 0, "ended_by_observer": False, "stop_requested": False,
                "stdout": "wait-for-device.stdout", "stderr": "wait-for-device.stderr"}
        log = {"command": [self.adb, "-s", self.serial, "logcat", "-b", "all", "-v", "threadtime"],
               "started_at": at(11), "finished_at": at(96), "returncode": -15,
               "ended_by_observer": False, "stop_requested": True,
               "stdout": "logcat-all.stdout", "stderr": "logcat-all.stderr"}
        put(self.framework / "monitor-commands.json", {"commands": [wait, log]})
        put(self.framework / "monitor-finished.json", {"finished_at": at(97), "stop_requested": True,
                                                       "budget_exhausted": False, "commands": [wait, log]})
        start = {"schema": 1, "began_at": at(66), "serial": self.serial, "monitor_identity": monitor,
                 "monitor_process": ANR.file_identity(self.framework / "monitor-process.json"),
                 "framework_readiness": ANR.file_identity(self.framework / "framework-readiness.json")}
        put(self.out / "runtime-start.json", start)
        end = {"schema": 1, "started_at": at(90), "finished_at": at(95), "serial": self.serial,
               "tour_exit_code": 0, "monitor_alive_before": True, "monitor_alive_after": True,
               "errors": [], "commands": {}, "files": {},
               "runtime_start": ANR.file_identity(self.out / "runtime-start.json")}
        outputs = {"properties": PROPERTIES, "system-server-pid": "627\n", "input-state": INPUT_READY,
                   "window-state": (FIXTURES / "0014-window-state.stdout").read_text(),
                   "events-anr": "--------- beginning of events\n"}
        for index, (name, arguments) in enumerate(ANR.FINAL_COMMANDS.items(), 1):
            prefix = f"commands/{index:04d}-{name}"
            record = {"command": [self.adb, "-s", self.serial, "shell", *arguments],
                      "started_at": at(90 + index * .2), "finished_at": at(90.1 + index * .2),
                      "returncode": 0, "timed_out": False, "stdout_file": prefix + ".stdout", "stderr_file": prefix + ".stderr"}
            put(self.out / (prefix + ".json"), record)
            (self.out / record["stdout_file"]).write_text(outputs[name])
            (self.out / record["stderr_file"]).write_bytes(b"")
            end["commands"][name] = record
        put(self.out / "runtime-end.json", end)
        self.seal_endpoint()
        self.seal_framework()

    def seal_framework(self):
        value = {"stopped_at": at(98), "monitor_identity": ANR.read_json(self.framework / "monitor-process.json"),
                 "files": {p.name: ANR.file_identity(p) for p in self.framework.iterdir()
                           if p.is_file() and p.name != "monitor-stop.json"}}
        put(self.framework / "monitor-stop.json", value)

    def seal_endpoint(self):
        end = ANR.read_json(self.out / "runtime-end.json")
        end["files"] = {str(p.relative_to(self.out)): ANR.file_identity(p) for p in (self.out / "commands").iterdir()}
        put(self.out / "runtime-end.json", end)

    def result(self):
        return ANR.verify(self.framework, self.out, self.serial)

    def test_complete_synthetic_recording_passes_without_device_claim(self):
        result = self.result()
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertIn("No APK functionality", result["scope"])

    def test_exact_original_successful_adb_start_stderr_is_accepted(self):
        self.assertEqual(len(ORIGINAL_ADB_START), 77)
        self.assertEqual(hashlib.sha256(ORIGINAL_ADB_START).hexdigest(),
                         "d84aaa3222b49c6dfc6c07666347890c6ad2ff255b911fa83525c5814e54963c")
        (self.framework / "wait-for-device.stderr").write_bytes(ORIGINAL_ADB_START)
        self.seal_framework()
        result = self.result()
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertEqual(result["adb_start"]["classification"], "exact_observed_successful_daemon_start")
        self.assertEqual(result["adb_start"]["original"], ANR.file_identity(self.framework / "wait-for-device.stderr"))

    def test_other_adb_start_stderr_or_failed_wait_remains_terminal(self):
        for raw in (ORIGINAL_ADB_START.splitlines(keepends=True)[0],
                    b"error: cannot connect to daemon\n", ORIGINAL_ADB_START + b"error: refused\n"):
            with self.subTest(stderr=raw):
                (self.framework / "wait-for-device.stderr").write_bytes(raw)
                self.seal_framework()
                self.assertEqual(self.result()["status"], "FAIL")
        (self.framework / "wait-for-device.stderr").write_bytes(ORIGINAL_ADB_START)
        finished = ANR.read_json(self.framework / "monitor-finished.json")
        finished["commands"][0]["returncode"] = 1
        put(self.framework / "monitor-finished.json", finished)
        put(self.framework / "monitor-commands.json", {"commands": finished["commands"]})
        self.seal_framework()
        self.assertIn("wait_for_device_incomplete", self.result()["errors"])

    def test_original_gms_anr_after_early_guard_pass_cannot_be_overridden(self):
        before = (self.framework / "framework-readiness.json").read_bytes()
        with (self.framework / "logcat-all.stdout").open("ab") as stream:
            stream.write((FIXTURES / "0071-events-anr.stdout").read_bytes())
        self.seal_framework()
        result = self.result()
        self.assertIn("recorded_android_anr", result["errors"])
        self.assertEqual(result["logcat"]["anr_record_count"], 1)
        self.assertIn("SIM_STATE_CHANGED", result["logcat"]["findings"][0]["original_line"])
        self.assertEqual((self.framework / "framework-readiness.json").read_bytes(), before)

    def test_original_activity_manager_record_alone_is_terminal(self):
        with (self.framework / "logcat-all.stdout").open("a") as stream:
            stream.write(ORIGINAL_ACTIVITY_MANAGER_ANR)
        self.seal_framework()
        self.assertIn("recorded_android_anr", self.result()["errors"])

    def test_anr_marker_with_unknown_prefix_is_not_silently_ignored(self):
        with (self.framework / "logcat-all.stdout").open("a") as stream:
            stream.write("UNKNOWN PREFIX am_anr : [0,1411,com.google.android.gms.persistent]\n")
        self.seal_framework()
        self.assertIn("recorded_android_anr", self.result()["errors"])

    def test_later_cleared_events_do_not_remove_already_streamed_original(self):
        with (self.framework / "logcat-all.stdout").open("ab") as stream:
            stream.write((FIXTURES / "0071-events-anr.stdout").read_bytes())
        self.seal_framework()
        self.assertEqual(self.result()["status"], "FAIL")
        events = self.out / ANR.read_json(self.out / "runtime-end.json")["commands"]["events-anr"]["stdout_file"]
        self.assertEqual(events.read_text(), "--------- beginning of events\n")

    def test_dispatcher_anr_history_vetoes_current_positive_dispatch(self):
        end = ANR.read_json(self.out / "runtime-end.json")
        path = self.out / end["commands"]["input-state"]["stdout_file"]
        path.write_text(INPUT_READY + "Input Dispatcher State at time of last ANR:\n  DispatchEnabled: true\n  DispatchFrozen: false\n")
        self.seal_endpoint()
        result = self.result()
        self.assertIn("endpoint_android_anr_or_error_history", result["errors"])

    def test_original_final_window_and_event_anr_are_terminal_without_log_marker(self):
        end = ANR.read_json(self.out / "runtime-end.json")
        for name, source in [("window-state", "0070-window-state.stdout"), ("events-anr", "0071-events-anr.stdout")]:
            (self.out / end["commands"][name]["stdout_file"]).write_bytes((FIXTURES / source).read_bytes())
        self.seal_endpoint()
        self.assertIn("endpoint_android_anr_or_error_history", self.result()["errors"])

    def test_missing_observations_never_pass(self):
        for root, name in [(self.framework, "monitor-finished.json"), (self.framework, "monitor-stop.json"),
                           (self.framework, "logcat-all.stdout"), (self.out, "runtime-start.json"),
                           (self.out, "commands/0003-input-state.stdout")]:
            with self.subTest(name=name):
                path = root / name
                raw = path.read_bytes()
                path.unlink()
                self.assertEqual(self.result()["status"], "FAIL")
                path.write_bytes(raw)

    def test_budget_exhaustion_or_early_logcat_end_is_not_a_complete_session(self):
        original = ANR.read_json(self.framework / "monitor-finished.json")
        cases = [dict(budget_exhausted=True), dict(stop_requested=False)]
        for change in cases:
            with self.subTest(change=change):
                put(self.framework / "monitor-finished.json", {**original, **change})
                self.seal_framework()
                self.assertEqual(self.result()["status"], "FAIL")
        early = json.loads(json.dumps(original))
        early["commands"][1].update(finished_at=at(80), returncode=0, stop_requested=False)
        put(self.framework / "monitor-finished.json", early)
        put(self.framework / "monitor-commands.json", {"commands": early["commands"]})
        self.seal_framework()
        result = self.result()
        self.assertIn("recording_does_not_cover_full_interval", result["errors"])
        self.assertIn("logcat_terminated_early_or_abnormally", result["errors"])

    def test_changed_stream_and_truncated_stream_are_rejected(self):
        path = self.framework / "logcat-all.stdout"
        original = path.read_bytes()
        path.write_bytes(original + b"changed\n")
        self.assertIn("stopped_original_changed:logcat-all.stdout", self.result()["errors"])
        path.write_bytes(original.rstrip(b"\n"))
        self.seal_framework()
        self.assertIn("empty_or_truncated_logcat", self.result()["errors"])

    def test_endpoint_timeout_unknown_dispatch_and_tour_failure_are_rejected(self):
        end = ANR.read_json(self.out / "runtime-end.json")
        end["tour_exit_code"] = 1
        end["commands"]["input-state"]["timed_out"] = True
        record = end["commands"]["input-state"]
        put(self.out / (record["stdout_file"].removesuffix(".stdout") + ".json"), record)
        (self.out / record["stdout_file"]).write_text("Input Dispatcher State:\n")
        put(self.out / "runtime-end.json", end)
        self.seal_endpoint()
        errors = self.result()["errors"]
        self.assertIn("tour_command_failed_or_missing", errors)
        self.assertIn("endpoint_command_failed:input-state", errors)
        self.assertIn("endpoint_dispatch_state_unknown_frozen_or_anr", errors)

    def test_new_monitor_identity_cannot_replace_original_session(self):
        monitor = ANR.read_json(self.framework / "monitor-process.json")
        monitor["pid"] += 1
        put(self.framework / "monitor-process.json", monitor)
        self.seal_framework()
        self.assertIn("monitor_identity_changed", self.result()["errors"])

    def test_offline_cli_reports_actual_original_failure(self):
        with (self.framework / "logcat-all.stdout").open("ab") as stream:
            stream.write((FIXTURES / "0071-events-anr.stdout").read_bytes())
        self.seal_framework()
        process = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/verify_android_runtime_anr.py"),
                                  "verify", "--framework-out", str(self.framework), "--out", str(self.out)],
                                 capture_output=True, text=True, check=False)
        self.assertEqual(process.returncode, 1, process.stderr)
        self.assertEqual(json.loads(process.stdout)["result"], "ANDROID_RUNTIME_ANR_REJECTED")
        self.assertIn("recorded_android_anr", ANR.read_json(self.out / "runtime-anr-verification.json")["errors"])


class MonitorDurationTests(unittest.TestCase):
    def test_monitor_start_stamp_precedes_child_with_delayed_parent(self):
        clock, child = [0], {}

        def launch(*args, **kwargs):
            child["wait_started_at"] = at(1)
            clock[0] = 5
            return type("SyntheticChild", (), {"pid": 1234})()

        def delayed_parent_identity(pid):
            self.assertEqual(pid, 1234)
            clock[0] = 10
            return "S", "synthetic-start-ticks"

        with tempfile.TemporaryDirectory() as directory, \
             mock.patch.object(READY, "utc", side_effect=lambda: at(clock[0])), \
             mock.patch.object(READY, "adb_path", return_value="/synthetic/adb"), \
             mock.patch.object(READY, "process_identity", side_effect=delayed_parent_identity), \
             mock.patch.object(READY.subprocess, "Popen", side_effect=launch):
            READY.start_monitor(Path(directory), "emulator-5554")
            info = ANR.read_json(Path(directory) / "monitor-process.json")
            self.assertLessEqual(ANR.timestamp(info["started_at"]), ANR.timestamp(child["wait_started_at"]))
            self.assertEqual(info["budget_seconds"], 450)

    def test_cli_rejects_unbounded_monitor_and_unchanged_guard_budget(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory) / "never-created"
            for options in (["--monitor-seconds", "7201"],
                            ["--monitor-seconds", "3600", "--timeout", "121"]):
                with self.subTest(options=options):
                    result = subprocess.run([sys.executable, "-B", str(ROOT / "scripts/android_framework_ready.py"),
                                             "start", "--out", str(out), *options], capture_output=True, check=False)
                    self.assertEqual(result.returncode, 2)
                    self.assertFalse(out.exists())

    def test_default_and_explicit_duration_preserve_bounded_monitor_lifetime(self):
        class Process:
            def __init__(self, command):
                self.returncode = 0 if command[-1] == "wait-for-device" else None

            def poll(self):
                return self.returncode

            def terminate(self):
                self.returncode = -15

            def wait(self, timeout):
                return self.returncode

        for duration, expected in [(450, 1), (900, 0)]:
            with self.subTest(duration=duration), tempfile.TemporaryDirectory() as directory:
                clock = [0.0]

                def advance(seconds):
                    clock[0] += seconds
                    if clock[0] >= 500:
                        READY.STOP_REQUESTED = True

                READY.STOP_REQUESTED = False
                with mock.patch.object(READY, "adb_path", return_value="/synthetic/adb"), \
                     mock.patch.object(READY.signal, "signal"), \
                     mock.patch.object(READY.subprocess, "Popen", side_effect=lambda command, **kwargs: Process(command)), \
                     mock.patch.object(READY.time, "monotonic", side_effect=lambda: clock[0]), \
                     mock.patch.object(READY.time, "sleep", side_effect=advance):
                    result = READY.collect_monitor(Path(directory), "emulator-5554", duration)
                self.assertEqual(result, expected)
                finished = ANR.read_json(Path(directory) / "monitor-finished.json")
                self.assertEqual(finished["budget_exhausted"], duration == 450)
                self.assertEqual(finished["stop_requested"], duration == 900)
        READY.STOP_REQUESTED = False
        self.assertEqual(READY.DEFAULT_MONITOR_SECONDS, 450)
        for invalid in (0, -1, True, 7201, 1.5):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                READY.monitor_budget(invalid)

    def test_real_local_monitor_and_recorder_stop_after_endpoint(self):
        with tempfile.TemporaryDirectory(prefix="lumo-synthetic-monitor-") as directory:
            root = Path(directory)
            adb = root / "sdk/platform-tools/adb"
            adb.parent.mkdir(parents=True)
            window = (FIXTURES / "0014-window-state.stdout").read_text()
            responses = {"getprop": PROPERTIES, "pidof system_server": "627\n", "dumpsys input": INPUT_READY,
                         "dumpsys window -a": window, "logcat -b events -d -v threadtime -s am_anr": "--------- beginning of events\n"}
            adb.write_text("#!/usr/bin/env python3\nimport sys,time\n"
                           "args=sys.argv[3:]\n"
                           "if args==['wait-for-device']: sys.exit(0)\n"
                           "if args==['logcat','-b','all','-v','threadtime']:\n"
                           " while True:\n"
                           "  print('11-14 02:30:00.000   627   627 I SyntheticMonitor: local contract only',flush=True)\n"
                           "  time.sleep(.05)\n"
                           f"responses={responses!r}\n"
                           "if args and args[0]=='shell' and ' '.join(args[1:]) in responses:\n"
                           " print(responses[' '.join(args[1:])],end=''); sys.exit(0)\n"
                           "sys.exit(2)\n")
            adb.chmod(0o755)
            framework, out = root / "framework", root / "runtime"
            info = None
            processes = []
            real_popen = subprocess.Popen

            def retain_process(*args, **kwargs):
                process = real_popen(*args, **kwargs)
                processes.append(process)
                return process

            with mock.patch.dict(os.environ, {"ANDROID_HOME": str(root / "sdk"), "PYTHONDONTWRITEBYTECODE": "1"}), \
                 mock.patch.object(READY.subprocess, "Popen", side_effect=retain_process):
                try:
                    READY.start_monitor(framework, "emulator-5554", 60)
                    info = ANR.read_json(framework / "monitor-process.json")
                    self.assertEqual(info["budget_seconds"], 60)
                    self.assertEqual(info["command"][-2:], ["--monitor-seconds", "60"])
                    deadline = time.monotonic() + 5
                    log = framework / "logcat-all.stdout"
                    while time.monotonic() < deadline and not (log.exists() and log.stat().st_size):
                        time.sleep(.02)
                    self.assertTrue(log.exists() and log.stat().st_size)
                    put(framework / "framework-readiness.json", {
                        "schema": 1, "status": "PASS", "serial": "emulator-5554", "adb": str(adb.resolve()),
                        "finished_at": READY.utc(), "monitor_alive_at_finish": True,
                        "samples": [{"pid": "627", "start_count": "1", "android_runtime": {"fingerprint": FINGERPRINT}}],
                        "scope": "Synthetic readiness for monitor subprocess test only."})
                    ANR.begin(framework, out, "emulator-5554")
                    end = ANR.capture_end(framework, out, "emulator-5554", 0)
                    self.assertTrue(end["monitor_alive_after"])
                    READY.stop_monitor(framework)
                    result = ANR.verify(framework, out, "emulator-5554")
                    self.assertEqual(result["status"], "PASS", result["errors"])
                    self.assertFalse(READY.monitor_alive(framework))
                finally:
                    if info is not None:
                        READY.stop_monitor(framework)
                    for process in processes:
                        process.wait(timeout=5)


if __name__ == "__main__":
    unittest.main()
