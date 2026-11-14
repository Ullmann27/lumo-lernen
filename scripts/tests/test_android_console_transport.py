"""Local Unix-channel contracts and byte-identical PR482 failure observations.

The peer in channel tests is explicitly synthetic. These tests do not execute an
emulator or establish real Android cgroup/console survival; CI must do that.
"""
from __future__ import annotations

import base64
from contextlib import ExitStack
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import socket
import tempfile
import threading
import time
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("console_transport_contract", ROOT / "scripts/android_console_transport.py")
CONSOLE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONSOLE)
FRAMEWORK_SPEC = importlib.util.spec_from_file_location("console_framework_contract", ROOT / "scripts/android_framework_ready.py")
FRAMEWORK = importlib.util.module_from_spec(FRAMEWORK_SPEC)
FRAMEWORK_SPEC.loader.exec_module(FRAMEWORK)
TOKEN = "a" * 32


class PipeChannel:
    """Synthetic socket API over real local pipes; never a Unix peer proof."""
    def __init__(self, reader, writer):
        self.reader, self.writer = reader, writer

    def fileno(self):
        return self.reader

    def connect(self, _path):
        return None

    def settimeout(self, _timeout):
        return None

    def setblocking(self, value):
        os.set_blocking(self.reader, value)

    def sendall(self, data):
        while data:
            data = data[os.write(self.writer, data):]

    def recv(self, size):
        return os.read(self.reader, size)

    def close(self):
        for fd in (self.reader, self.writer):
            try:
                os.close(fd)
            except OSError:
                pass

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        self.close()


class ConsoleTransportTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="lumo-console-")
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        environment = mock.patch.dict(os.environ, {"RUNNER_TEMP": str(self.root), "GITHUB_RUN_ID": "43500000000", "GITHUB_RUN_ATTEMPT": "1"})
        environment.start()
        self.addCleanup(environment.stop)
        self.socket_path = self.root / "lumo-serial-43500000000-1/console.sock"

    def test_prepare_is_private_and_never_reuses_a_previous_directory(self):
        result = CONSOLE.prepare(self.socket_path)
        self.assertEqual(self.socket_path.parent.stat().st_mode & 0o777, 0o700)
        self.assertEqual(result["emulator_option"], "unix:" + str(self.socket_path) + ",server,nowait")
        with self.assertRaises(FileExistsError):
            CONSOLE.prepare(self.socket_path)

    def test_stale_path_symlink_and_regular_file_are_not_console_channels(self):
        CONSOLE.prepare(self.socket_path)
        self.socket_path.write_text("not a socket")
        with self.assertRaisesRegex(ValueError, "Unix socket"):
            CONSOLE.check(self.socket_path)
        self.socket_path.unlink()
        target = self.root / "other"
        target.write_text("ordinary file")
        self.socket_path.symlink_to(target)
        with self.assertRaisesRegex(ValueError, "Unix socket"):
            CONSOLE.check(self.socket_path)

    def test_changed_run_cannot_consume_another_prepared_channel(self):
        CONSOLE.prepare(self.socket_path)
        with mock.patch.dict(os.environ, {"GITHUB_RUN_ATTEMPT": "2"}):
            with self.assertRaisesRegex(ValueError, "actual run/source"):
                CONSOLE.check(self.socket_path)

    def test_echoed_input_is_never_a_positive_launch_frame(self):
        program = FRAMEWORK.device_logger_launch("/data/local/tmp/lumo-runtime-" + TOKEN).encode()
        command = CONSOLE.command_bytes(program, TOKEN)
        self.assertEqual(command.count(b"\n"), 1)
        self.assertIn(base64.b64encode(program), command)
        self.assertIsNone(CONSOLE.launch_frame(command, TOKEN))
        self.assertIn(b'/system/bin/sh -s -- "$$"', command)

    def test_duplicate_reordered_and_nonzero_acknowledgements_fail(self):
        good = f"LUMO_CONSOLE_BEGIN_{TOKEN}\r\n\r\nLUMO_CONSOLE_END_{TOKEN}:0\r\n".encode()
        self.assertEqual(CONSOLE.launch_frame(good, TOKEN)["returncode"], 0)
        for bad in (good + good, good.replace(b":0", b":7"),
                    f"LUMO_CONSOLE_END_{TOKEN}:0\nLUMO_CONSOLE_BEGIN_{TOKEN}\n".encode()):
            with self.subTest(raw=bad), self.assertRaises(ValueError):
                CONSOLE.launch_frame(bad, TOKEN)

    def test_multiplexed_terminal_output_is_preserved_separately_from_program_stderr(self):
        body = b"11-14 05:20:00 kernel: original concurrent output\r\n"
        raw = f"LUMO_CONSOLE_BEGIN_{TOKEN}\r\n".encode() + body + f"LUMO_CONSOLE_END_{TOKEN}:0\r\n".encode()
        frame = CONSOLE.launch_frame(raw, TOKEN)
        self.assertEqual(frame["interleaved_output"], CONSOLE.identity(body))
        self.assertEqual(frame["acknowledged_prefix"], CONSOLE.identity(raw))

    def test_foreign_peer_wrong_executable_and_duplicate_option_are_rejected(self):
        option = "unix:" + str(self.socket_path) + ",server,nowait"
        good = {"pid": 50, "uid": 1000, "start_ticks": "77", "executable": "/sdk/qemu-system-x86_64", "argv": ["/sdk/qemu-system-x86_64", option]}
        CONSOLE.validate_peer(good, self.socket_path, 1000)
        for change in ({"pid": 1}, {"uid": 0}, {"executable": "/bin/sh"}, {"argv": [option, option]}, {"argv": ["unix:/foreign/socket,server,nowait"]}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                CONSOLE.validate_peer({**good, **change}, self.socket_path, 1000)

    def test_oversized_canonical_command_is_not_silently_truncated(self):
        with self.assertRaisesRegex(ValueError, "canonical line limit"):
            CONSOLE.command_bytes(b"x" * 4096, TOKEN)

    def collect_case(self, *, close_early=False, maximum=None, pipe=False):
        CONSOLE.prepare(self.socket_path)
        out = self.root / "collection"
        out.mkdir()
        program = b"printf 'local contract only'\n"
        command = CONSOLE.command_bytes(program, TOKEN)
        (out / "program.sh").write_bytes(program)
        (out / "command.stdin").write_bytes(command)
        CONSOLE.write_new(out / "config.json", {"socket": str(self.socket_path), "token": TOKEN, "program": CONSOLE.identity(program)})
        if pipe:
            input_read, input_write = os.pipe()
            output_read, output_write = os.pipe()
            host_channel = PipeChannel(output_read, input_write)
            guest_channel = PipeChannel(input_read, output_write)
            self.addCleanup(host_channel.close)
            self.addCleanup(guest_channel.close)
        else:
            server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            server.bind(str(self.socket_path))
            server.listen(1)
            self.addCleanup(server.close)
        errors, inputs, returns = [], [], []
        response = (b"synthetic banner\r\n" + command +
                    f"\r\nLUMO_CONSOLE_BEGIN_{TOKEN}\r\n\r\nLUMO_CONSOLE_END_{TOKEN}:0\r\n".encode())
        def guest():
            try:
                connection = guest_channel if pipe else server.accept()[0]
                with connection:
                    connection.settimeout(3)
                    received = b""
                    while not received.endswith(b"\n"):
                        received += connection.recv(4096)
                    inputs.append(received)
                    for index in range(0, len(response), 13):
                        connection.sendall(response[index:index + 13])
                    if close_early:
                        return
                    while connection.recv(4096):
                        raise AssertionError("Unexpected second console command")
            except BrokenPipeError as error:
                if maximum is None:
                    errors.append(error)
            except BaseException as error:
                errors.append(error)
        peer = {**CONSOLE.process_identity(os.getpid()), "uid": os.getuid(), "gid": os.getgid()}
        def host():
            try:
                returns.append(CONSOLE.collect(out))
            except BaseException as error:
                errors.append(error)
        with ExitStack() as stack:
            stack.enter_context(mock.patch.object(CONSOLE, "peer_identity", return_value=peer))
            stack.enter_context(mock.patch.object(CONSOLE, "MAX_TRANSCRIPT_BYTES", maximum or CONSOLE.MAX_TRANSCRIPT_BYTES))
            if pipe:
                stack.enter_context(mock.patch.object(CONSOLE.socket, "socket", return_value=host_channel))
                stack.enter_context(mock.patch.object(CONSOLE, "socket_state", return_value={"path": str(self.socket_path), "synthetic_pipe": True}))
            guest_thread = threading.Thread(target=guest)
            host_thread = threading.Thread(target=host)
            guest_thread.start()
            host_thread.start()
            deadline = time.monotonic() + 3
            while not (out / "launch.json").exists() and not (out / "finished.json").exists() and time.monotonic() < deadline:
                time.sleep(.01)
            if not close_early and maximum is None:
                CONSOLE.write_new(out / "stop-request.json", {"requested_at": CONSOLE.utc(), "token": TOKEN, "logger_exit": 143})
            host_thread.join(4)
            guest_thread.join(4)
            self.assertFalse(host_thread.is_alive(), "Bounded collector must finish")
            self.assertFalse(guest_thread.is_alive(), "Test channel must close")
        self.assertFalse(errors, errors)
        self.assertEqual(inputs, [command])
        return out, response, returns

    def test_real_unix_channel_preserves_every_byte_and_closes_only_after_request(self):
        out, response, returns = self.collect_case()
        self.assertEqual(returns, [0])
        self.assertEqual((out / "transcript.stdout").read_bytes(), response)
        result = CONSOLE.read_json(out / "finished.json")
        self.assertEqual(result["connections"], 1)
        self.assertTrue(result["stop_requested"])
        self.assertEqual(result["status"], "PASS")

    def test_original_channel_eof_is_terminal_without_a_reconnect(self):
        out, response, returns = self.collect_case(close_early=True)
        self.assertEqual(returns, [1])
        self.assertEqual((out / "transcript.stdout").read_bytes(), response)
        result = CONSOLE.read_json(out / "finished.json")
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(result["connections"], 1)
        self.assertIn("ended before its requested close", result["errors"][0])

    def test_transcript_bound_fails_and_does_not_return_a_trimmed_pass(self):
        out, _, returns = self.collect_case(maximum=1)
        self.assertEqual(returns, [1])
        self.assertGreater((out / "transcript.stdout").stat().st_size, 1)
        self.assertIn("preservation bound", CONSOLE.read_json(out / "finished.json")["errors"][0])

    def test_original_three_missing_session_observations_remain_failures(self):
        folder = ROOT / "scripts/tests/fixtures/android37_console_root_482"
        manifest = json.loads((folder / "manifest.json").read_bytes())
        for row in manifest["files"]:
            data = (folder / row["file"]).read_bytes()
            self.assertEqual(len(data), row["bytes"])
            self.assertEqual(hashlib.sha256(data).hexdigest(), row["sha256"])
        for case in ("host", "swiftshader", "swangle"):
            with self.subTest(case=case):
                after = json.loads((folder / f"{case}-0012-after-root.json").read_bytes())
                self.assertEqual(after["returncode"], 1)
                self.assertFalse(after["timed_out"])
                self.assertEqual((folder / f"{case}-0012-after-root.stdout").read_bytes(), b"__session_stat__\n")
                self.assertRegex((folder / f"{case}-0012-after-root.stderr").read_text(), r"cat: /proc/[0-9]+/stat: No such file or directory\n")
                self.assertEqual((folder / f"{case}-0010-root-after-uid.stdout").read_bytes(), b"0\n")
                self.assertEqual((folder / f"{case}-0011-root-boot.stdout").read_bytes(), b"1\n")
                with self.assertRaises(ValueError):
                    FRAMEWORK.parse_device_snapshot("__session_stat__\n", "/data/local/tmp/lumo-runtime-" + TOKEN)


class SyntheticPipeTransportTests(unittest.TestCase):
    """Executable stream-state coverage when this workspace forbids socket()."""
    setUp = ConsoleTransportTests.setUp

    def collect_case(self, **arguments):
        return ConsoleTransportTests.collect_case(self, pipe=True, **arguments)

    test_synthetic_pipe_preserves_full_input_and_output = ConsoleTransportTests.test_real_unix_channel_preserves_every_byte_and_closes_only_after_request
    test_synthetic_pipe_eof_never_reconnects = ConsoleTransportTests.test_original_channel_eof_is_terminal_without_a_reconnect
    test_synthetic_pipe_limit_is_failure_not_trimmed_success = ConsoleTransportTests.test_transcript_bound_fails_and_does_not_return_a_trimmed_pass


if __name__ == "__main__":
    unittest.main()
