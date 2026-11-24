"""Real Python collection/verification with an explicitly synthetic ADB transport.

The subprocess answers below are contract fixtures, not an emulator. The exact
61c GMS event and monitor exits are original bytes. No test claims Android
session survival; that still needs the subsequent unchanged-APK device job.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import shlex
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = Path(os.environ.get("LUMO_RUNTIME_ANR_SOURCE_ROOT", str(ROOT)))


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ANR = load(SOURCE_ROOT / "scripts/verify_android_runtime_anr.py", "device_anr_contract")
FRAMEWORK = ANR.FRAMEWORK
OLD = load(ROOT / "scripts/tests/test_verify_android_runtime_anr.py", "device_legacy_fixtures")
FIXTURES = ROOT / "scripts/tests/fixtures/android37_root_monitor_61c"


class Clock:
    def __init__(self):
        self.value = 66.0

    def utc(self):
        self.value += .01
        return (datetime(2026, 11, 14, 2, 28, 38, tzinfo=timezone.utc) + timedelta(seconds=self.value)).isoformat()

    def monotonic(self):
        return self.value

    def sleep(self, seconds):
        self.value += seconds


class SyntheticAdb:
    """Deterministic transport double; production recorders still write bytes."""

    def __init__(self, case, clock):
        self.case, self.clock = case, clock
        self.remote = None
        self.script = b""
        self.log = b"11-14 02:29:00.000   621   621 I SyntheticBoot: contract only\n"
        self.rooted, self.alive = False, True
        self.root_calls = 0
        self.corrupt_identity = False
        self.corrupt_inode = False
        self.filtered = False
        self.missing_overlap = False
        self.bad_exit = False
        self.root_stderr = None
        self.wait_stderr = b""
        self.stdout = b""
        self.stderr = b""
        self.returncode = 0
        self.session = 3000
        self.child = 3001
        self.console = 200
        self.console_cgroup = "/uid_2000/pid_200"
        self.shared_adbd_cgroup = False
        self.console_launch = False
        self.launch_stderr = b""

    def files(self):
        return {"logcat.stdout": self.log, "logcat.stderr": b"", "session.stdout": b"",
                "session.stderr": b"", "wait.stderr": self.wait_stderr, "run.sh": self.script,
                "console.pid": (str(self.console) + "\n").encode(), "launch.stdout": b"", "launch.stderr": self.launch_stderr}

    def stat(self, pid, ppid, ticks, argv):
        fields = ["S", str(ppid), "3000", "3000"] + ["0"] * 15 + [str(ticks)]
        return f"{pid} (synthetic) " + " ".join(fields) + "\n", b"\0".join(x.encode() for x in argv) + b"\0"

    def snapshot(self, live):
        output = ""
        if live:
            if not self.alive:
                raise RuntimeError("Synthetic logger is dead")
            output += "__console_service__\nrunning\n"
            adbd = 501 if self.rooted else 500
            for role, pid, ppid, ticks, argv in (
                ("console", self.console, 1, 90, ["/system/bin/sh"]),
                ("session", self.session, 1, 101, ["/system/bin/sh", self.remote + "/run.sh"]),
                ("logger", self.child, self.session, 999 if self.rooted and self.corrupt_identity else 102,
                 ["/system/bin/logcat", "-b", "main" if self.filtered else "all", "-v", "threadtime"]),
                ("adbd", adbd, 1, 120 if self.rooted else 80, ["/apex/com.android.adbd/bin/adbd"]),
            ):
                stat, raw = self.stat(pid, ppid, ticks, argv)
                output += "__" + role + "_stat__\n" + stat + "__" + role + "_argv__\n" + raw.hex() + "\n"
                uid = "0" if role == "adbd" and self.rooted else "2000"
                group = f"/uid_0/pid_{adbd}" if role == "adbd" or self.shared_adbd_cgroup else self.console_cgroup
                output += "__" + role + "_uid__\n" + " ".join([uid] * 4) + "\n"
                output += "__" + role + "_cgroup__\n0::" + group + "\n"
        for index, (name, data) in enumerate(self.files().items(), 10):
            inode = index + (100 if self.rooted and self.corrupt_inode else 0)
            output += f"__file_{name}__\n1:{inode}:{len(data)}:8180\n"
        output += "__script_hash__\n" + hashlib.sha256(self.script).hexdigest() + "  run.sh\n"
        return output.encode()

    def dispatch(self, command):
        self.stdout, self.stderr, self.returncode = b"", b"", 0
        args = command[3:]
        if command[:3] != [self.case.adb, "-s", self.case.serial]:
            raise AssertionError("Unexpected ADB/device binding")
        if args == ["root"]:
            self.root_calls += 1
            self.rooted = True
            self.case.transport_ends(self.clock.utc())
            if not self.console_launch:
                self.alive = False
            if self.root_stderr is not None:
                self.returncode, self.stderr = 1, self.root_stderr
            else:
                self.stdout = b"restarting adbd as root\n"
        elif args == ["wait-for-device"]:
            pass
        elif args == ["shell", "id", "-u"]:
            self.stdout = b"0\n" if self.rooted else b"2000\n"
        elif args == ["shell", "getprop", "sys.boot_completed"]:
            self.stdout = b"1\n"
        elif args[:3] == ["shell", "sh", "-c"]:
            script = shlex.split(args[3])[0]
            if "LUMO_LOGGER_SOURCE" in script:
                self.remote = re.search(r"/data/local/tmp/lumo-runtime-[0-9a-f]{32}", script)[0]
                self.script = FRAMEWORK.device_logger_script(self.remote).encode()
            elif "__script_hash__" in script:
                self.stdout = self.snapshot("__session_stat__" in script)
            elif "/logger.exit" in script:
                self.stdout = (b"1\n" if self.bad_exit else b"143\n") if not self.alive else b""
            else:
                raise AssertionError("Unexpected remote shell program")
        elif args[:6] == ["shell", "log", "-p", "i", "-t", "LumoRuntimeRecorder"]:
            line = ("11-14 02:30:00.000   3010   3010 I LumoRuntimeRecorder: " + args[6] + "\n").encode()
            self.log += line
            if args[6].endswith("-start") and not self.missing_overlap:
                with (self.case.framework / "logcat-all.stdout").open("ab") as stream:
                    stream.write(line)
        elif args[:3] == ["shell", "grep", "-F"]:
            self.stdout = b"".join(line + b"\n" for line in self.log.splitlines() if args[3].encode() in line)
            self.returncode = 0 if self.stdout else 1
        elif args[:2] == ["shell", "cat"]:
            self.stdout = self.files()[args[2].rsplit("/", 1)[1]]
        elif args[:3] == ["shell", "kill", "-TERM"]:
            if args[3] != str(self.child):
                raise AssertionError("Wrong process was signalled")
            self.alive = False
            self.wait_stderr = b"Terminated\n"
        elif args == ["shell", "getprop"]:
            self.stdout = OLD.PROPERTIES.encode()
        elif args == ["shell", "pidof", "system_server"]:
            self.stdout = b"627\n"
        elif args == ["shell", "dumpsys", "input"]:
            self.stdout = OLD.INPUT_READY.encode()
        elif args == ["shell", "dumpsys", "window", "-a"]:
            self.stdout = (OLD.FIXTURES / "0014-window-state.stdout").read_bytes()
        elif args == ["shell", "logcat", "-b", "events", "-d", "-v", "threadtime", "-s", "am_anr"]:
            self.stdout = b"--------- beginning of events\n"
        else:
            raise AssertionError("Unexpected command: " + repr(args))
        return self

    def communicate(self, timeout=None):
        return self.stdout, self.stderr


class SyntheticConsole:
    """Only the external console/process transport is synthetic, not verification."""
    def __init__(self, case):
        self.case = case

    def start(self, out, program, token, serial):
        console = FRAMEWORK.CONSOLE
        self.out, self.token = out, token
        out.mkdir()
        raw_socket = "/tmp/lumo-serial-43500000000-1/console.sock"
        self.peer = {"pid": 50, "start_ticks": "77", "argv": ["/sdk/qemu-system-x86_64", "unix:" + raw_socket + ",server,nowait"], "executable": "/sdk/qemu-system-x86_64", "uid": 1000, "gid": 1000}
        self.process = {"pid": 60, "start_ticks": "88", "argv": ["python", "android_console_transport.py", "_hold", "--out", str(out)], "executable": "/python", "command": ["python", "android_console_transport.py", "_hold", "--out", str(out)], "started_at": self.case.clock.utc()}
        self.started = self.case.clock.utc()
        self.socket = {"path": raw_socket, "device": 1, "inode": 2, "mode": 0o140600, "uid": 1000, "parent_device": 1, "parent_inode": 1, "parent_mode": 0o40700}
        prepare = {"schema": 1, "run_id": "43500000000", "run_attempt": "1", "socket": raw_socket, "emulator_option": "unix:" + raw_socket + ",server,nowait", "uid": 1000, "source": console.identity(Path(console.__file__).read_bytes())}
        OLD.put(out / "prepare.json", prepare)
        OLD.put(out / "process.json", self.process)
        OLD.put(out / "config.json", {"schema": 1, "socket": raw_socket, "serial": serial, "token": token, "program": console.identity(program), "preparation": console.identity((out / "prepare.json").read_bytes())})
        (out / "program.sh").write_bytes(program)
        (out / "command.stdin").write_bytes(console.command_bytes(program, token))
        self.transcript = (f"LUMO_CONSOLE_BEGIN_{token}\n\nLUMO_CONSOLE_END_{token}:0\n").encode()
        (out / "transcript.stdout").write_bytes(self.transcript)
        (out / "holder.stdout").write_bytes(b"")
        (out / "holder.stderr").write_bytes(b"")
        self.launch = {"schema": 1, "status": "PASS", "sent_at": self.case.clock.utc(), "observed_at": self.case.clock.utc(), "socket": self.socket, "peer": self.peer, "frame": console.launch_frame(self.transcript, token)}
        OLD.put(out / "launch.json", self.launch)
        fake = self.case.fake
        fake.remote = re.search(rb"/data/local/tmp/lumo-runtime-[0-9a-f]{32}", program)[0].decode()
        fake.script = FRAMEWORK.device_logger_script(fake.remote).encode()
        fake.console_launch = True
        return self.observe(out, "launched")

    def observe(self, out, label):
        value = {"observed_at": self.case.clock.utc(), "label": label, "holder": {key: self.process[key] for key in ("pid", "start_ticks", "argv", "executable")}, "peer": {key: self.peer[key] for key in ("pid", "start_ticks", "argv", "executable")}, "socket": self.socket, "transcript_prefix": FRAMEWORK.CONSOLE.identity(self.transcript)}
        OLD.put(out / "observations" / (label + ".json"), value)
        return value

    def finish(self, out, token, logger_exit):
        self.observe(out, "before-close")
        stop = {"requested_at": self.case.clock.utc(), "token": token, "logger_exit": logger_exit}
        OLD.put(out / "stop-request.json", stop)
        result = {"schema": 1, "status": "PASS", "started_at": self.started, "finished_at": self.case.clock.utc(), "sent_at": self.launch["sent_at"], "connections": 1, "stop_requested": True, "stop_request": stop, "peer": self.peer, "socket": self.socket, "token": token, "errors": [], "source": FRAMEWORK.CONSOLE.identity(Path(FRAMEWORK.CONSOLE.__file__).read_bytes())}
        OLD.put(out / "finished.json", result)
        return result


class DeviceLogContracts(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        manifest = json.loads((FIXTURES / "manifest.json").read_bytes())
        if manifest["run_id"] != 43551424080:
            raise AssertionError("Incorrect original source")
        for row in manifest["files"]:
            data = (FIXTURES / row["file"]).read_bytes()
            if len(data) != row["bytes"] or hashlib.sha256(data).hexdigest() != row["sha256"]:
                raise AssertionError("Changed original fixture")

    def setUp(self):
        self.old = OLD.RuntimeAnrTests()
        self.old.setUp()
        self.addCleanup(self.old.doCleanups)
        self.framework, self.out = self.old.framework, self.old.out
        self.adb, self.serial = self.old.adb, self.old.serial
        self.old_finished = ANR.read_json(self.framework / "monitor-finished.json")
        for name in ("monitor-finished.json", "monitor-stop.json"):
            (self.framework / name).unlink()
        import shutil
        shutil.rmtree(self.out)
        self.out.mkdir()
        self.clock = Clock()
        self.fake = SyntheticAdb(self, self.clock)
        self.console_transport = SyntheticConsole(self)
        for patcher in (mock.patch.object(FRAMEWORK, "utc", side_effect=self.clock.utc),
                        mock.patch.object(FRAMEWORK.CONSOLE, "start", side_effect=self.console_transport.start),
                        mock.patch.object(FRAMEWORK.CONSOLE, "observe", side_effect=self.console_transport.observe),
                        mock.patch.object(FRAMEWORK.CONSOLE, "finish", side_effect=self.console_transport.finish),
                        mock.patch.object(FRAMEWORK, "adb_path", return_value=self.adb),
                        mock.patch.object(FRAMEWORK, "monitor_alive", side_effect=lambda _p: not self.fake.rooted),
                        mock.patch.object(FRAMEWORK, "process_identity", return_value=None),
                        mock.patch.object(FRAMEWORK.time, "monotonic", side_effect=self.clock.monotonic),
                        mock.patch.object(FRAMEWORK.time, "sleep", side_effect=self.clock.sleep),
                        mock.patch.object(FRAMEWORK.subprocess, "Popen", side_effect=lambda command, **_kw: self.fake.dispatch(command))):
            patcher.start()
            self.addCleanup(patcher.stop)

    def transport_ends(self, stamp):
        finished = json.loads(json.dumps(self.old_finished))
        finished.update(finished_at=stamp, stop_requested=False, budget_exhausted=False)
        finished["commands"][1].update(finished_at=stamp, stop_requested=False, returncode=255, ended_by_observer=False)
        OLD.put(self.framework / "monitor-finished.json", finished)
        OLD.put(self.framework / "monitor-commands.json", {"commands": finished["commands"]})

    def start(self):
        return ANR.begin(self.framework, self.out, self.serial, preserve_through_adb_root=True)

    def complete(self, *, tour_exit=0):
        self.start()
        self.clock.sleep(5)
        self.fake.log += b"11-14 02:31:00.000   999   999 I SyntheticTour: contract-only event\n"
        ANR.capture_end(self.framework, self.out, self.serial, tour_exit)
        FRAMEWORK.finish_device_log(self.out / "device-logger")
        FRAMEWORK.stop_monitor(self.framework)
        return ANR.verify(self.framework, self.out, self.serial)

    def test_production_protocol_covers_simulated_root_disconnect_without_restarting_logger(self):
        result = self.complete()
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertEqual(self.fake.root_calls, 1)
        self.assertEqual(result["device_recording"]["start_identity"]["logger"]["pid"], 3001)
        self.assertEqual(ANR.read_json(self.framework / "monitor-finished.json")["commands"][1]["returncode"], 255)
        self.assertEqual(result["device_recording"]["logcat"]["anr_record_count"], 0)
        self.assertFalse(self.fake.alive)

    def test_real_gms_original_is_terminal_even_when_later_events_are_empty(self):
        self.start()
        self.fake.log += (FIXTURES / "host-gms-events-anr.stdout").read_bytes()
        ANR.capture_end(self.framework, self.out, self.serial, 0)
        FRAMEWORK.finish_device_log(self.out / "device-logger")
        FRAMEWORK.stop_monitor(self.framework)
        result = ANR.verify(self.framework, self.out, self.serial)
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("recorded_android_anr_in_device_session", result["errors"])
        self.assertIn("com.google.android.gms.persistent", result["device_recording"]["logcat"]["findings"][0]["original_line"])

    def test_missing_positive_host_device_overlap_fails_before_root(self):
        self.fake.missing_overlap = True
        with self.assertRaisesRegex(TimeoutError, "marker"):
            self.start()
        self.assertEqual(self.fake.root_calls, 0)
        self.assertFalse((self.out / "runtime-start.json").exists())

    def test_process_birth_change_at_root_is_not_a_reconnect(self):
        self.fake.corrupt_identity = True
        with self.assertRaisesRegex(ValueError, "identity changed"):
            self.start()
        self.assertFalse((self.out / "runtime-start.json").exists())

    def test_file_inode_change_at_root_is_not_tolerated(self):
        self.fake.corrupt_inode = True
        with self.assertRaisesRegex(ValueError, "file identity changed"):
            self.start()

    def test_filtered_device_command_cannot_establish_the_session(self):
        self.fake.filtered = True
        with self.assertRaisesRegex(ValueError, "command changed"):
            self.start()

    def test_changed_pre_root_prefix_remains_a_failure(self):
        self.start()
        self.fake.log = self.fake.log.replace(b"contract only", b"altered bytes")
        ANR.capture_end(self.framework, self.out, self.serial, 0)
        FRAMEWORK.finish_device_log(self.out / "device-logger")
        FRAMEWORK.stop_monitor(self.framework)
        result = ANR.verify(self.framework, self.out, self.serial)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("pre-root original" in error for error in result["errors"]), result["errors"])

    def test_unsolicited_device_exit_is_not_accepted(self):
        self.start()
        ANR.capture_end(self.framework, self.out, self.serial, 0)
        self.fake.bad_exit = True
        with self.assertRaisesRegex(ValueError, "requested TERM"):
            FRAMEWORK.finish_device_log(self.out / "device-logger")

    def test_tour_failure_cannot_be_overridden_by_continuous_logs(self):
        result = self.complete(tour_exit=1)
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("tour_command_failed_or_missing", result["errors"])

    def test_actual_root_closed_response_requires_independent_uid0(self):
        self.fake.root_stderr = b"adb: unable to connect for root: closed\n"
        result = self.complete()
        self.assertEqual(result["status"], "PASS", result["errors"])
        self.assertEqual(result["device_recording"]["root"]["uid_after"], "0")

    def test_other_root_stderr_is_not_ignored(self):
        self.fake.root_stderr = b"error: device offline\n"
        with self.assertRaisesRegex(RuntimeError, "command failed"):
            self.start()

    def test_current_original_monitor_failures_are_not_relabelled(self):
        for name in ("host-monitor-finished.json", "swiftshader-monitor-finished.json"):
            original = ANR.read_json(FIXTURES / name)
            self.assertFalse(original["stop_requested"])
            self.assertFalse(original["budget_exhausted"])
            self.assertEqual(original["commands"][1]["returncode"], 255)
            self.assertFalse(original["commands"][1]["ended_by_observer"])

    def test_protocol_cannot_be_enabled_by_changing_a_report_only(self):
        result = self.complete()
        self.assertEqual(result["status"], "PASS", result["errors"])
        paths = list((self.out / "device-logger/start/commands").glob('*-initial.stdout'))
        self.assertEqual(len(paths), 1)
        paths[0].write_bytes(b"changed")
        result = ANR.verify(self.framework, self.out, self.serial)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("Original device command bytes changed" in error for error in result["errors"]))

    def test_raw_shell_wait_notification_is_preserved_and_bound_to_term(self):
        result = self.complete()
        self.assertEqual(result["status"], "PASS", result["errors"])
        final = ANR.read_json(self.out / "device-logger/finish.json")
        raw = self.out / "device-logger/finish" / final["wait.stderr"]
        self.assertEqual(raw.read_bytes(), b"Terminated\n")
        self.assertEqual(final["exit_code"], 143)

    def test_device_observation_phases_cannot_replace_existing_originals(self):
        self.complete()
        with self.assertRaisesRegex(ValueError, "overwrite"):
            FRAMEWORK.finish_device_log(self.out / "device-logger")

    def test_host_transport_termination_outside_the_root_phase_stays_a_failure(self):
        self.complete()
        finished = ANR.read_json(self.framework / "monitor-finished.json")
        finished["commands"][1]["finished_at"] = OLD.at(66)
        OLD.put(self.framework / "monitor-finished.json", finished)
        OLD.put(self.framework / "monitor-commands.json", {"commands": finished["commands"]})
        stopped = ANR.read_json(self.framework / "monitor-stop.json")
        for name in ("monitor-finished.json", "monitor-commands.json"):
            stopped["files"][name] = ANR.file_identity(self.framework / name)
        OLD.put(self.framework / "monitor-stop.json", stopped)
        self.assertIn("recording_does_not_cover_full_interval", ANR.verify(self.framework, self.out, self.serial)["errors"])

    def test_actual_diagnostic_runner_requires_the_new_positive_protocol(self):
        script = (ROOT / "scripts/run_unchanged_apk_diagnostic.sh").read_text()
        self.assertEqual(script.count("--preserve-through-adb-root"), 1)
        self.assertIn('if [[ "$diagnostic_case" == api37-* ]]; then', script)
        self.assertIn("trap finish_android17 EXIT", script)

    def test_actual_adbd_group_cannot_be_accepted_as_console_independence(self):
        self.fake.shared_adbd_cgroup = True
        with self.assertRaisesRegex(ValueError, "distinct actual init-console cgroup"):
            self.start()
        self.assertEqual(self.fake.root_calls, 0)

    def test_console_cgroup_change_after_root_is_terminal(self):
        dispatch = self.fake.dispatch
        def root_changes_group(command):
            result = dispatch(command)
            if command[3:] == ["root"]:
                self.fake.console_cgroup = "/uid_2000/pid_201"
            return result
        with mock.patch.object(self.fake, "dispatch", side_effect=root_changes_group):
            with self.assertRaisesRegex(ValueError, "identity changed: console:cgroups"):
                self.start()

    def test_lost_console_channel_cannot_be_hidden_by_live_device_log(self):
        self.start()
        with mock.patch.object(FRAMEWORK.CONSOLE, "observe", side_effect=ValueError("Original console channel ended")):
            endpoint = ANR.capture_end(self.framework, self.out, self.serial, 0)
        self.assertTrue(endpoint["errors"])
        self.assertIn("Original console channel ended", endpoint["errors"][0])

    def test_console_original_input_change_is_rejected_offline(self):
        self.complete()
        (self.out / "device-logger/console/command.stdin").write_bytes(b"echo fake\n")
        result = ANR.verify(self.framework, self.out, self.serial)
        self.assertEqual(result["status"], "FAIL")
        self.assertTrue(any("exact input" in error for error in result["errors"]), result["errors"])

    def test_old_recording_protocol_is_not_relabelled_as_console_evidence(self):
        self.complete()
        path = self.out / "runtime-start.json"
        value = ANR.read_json(path)
        value["recording_protocol"] = "independent-device-session-v1"
        OLD.put(path, value)
        result = ANR.verify(self.framework, self.out, self.serial)
        self.assertEqual(result["status"], "FAIL")
        self.assertIn("unknown_recording_protocol", result["errors"])

    def test_console_launch_program_stderr_is_not_hidden_by_terminal_noise(self):
        self.fake.launch_stderr = b"actual launch error\n"
        with self.assertRaisesRegex(ValueError, "launch program emitted"):
            self.start()
        self.assertEqual(self.fake.root_calls, 0)


if __name__ == "__main__":
    unittest.main()
