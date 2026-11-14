"""Execute the real Bash builder with fake build tools to check ordering/failure gates.

These tests do not create a keystore, build Android, validate an AAB or prove Play
readiness. Cryptographic and bundle-content checks belong to verify_play_bundle.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest

ROOT = Path(__file__).resolve().parents[2]

SUPPORT = r'''
import json
import os
from pathlib import Path
def record(tool, args):
    with Path(os.environ["PLAY_TEST_EVENTS"]).open("a") as handle:
        handle.write(json.dumps({"tool": tool, "args": args}) + "\n")
'''

PYTHON_TOOL = r'''
import os
from pathlib import Path
import shutil
import sys
sys.path.insert(0, os.environ["PLAY_TEST_SUPPORT"])
from support import record
args = sys.argv[1:]
if args[:2] == ["-m", "venv"]:
    record("venv", args)
    target = Path(args[2]) / "bin/python"
    target.parent.mkdir(parents=True)
    shutil.copyfile(__file__, target)
    target.chmod(0o755)
elif args[:2] in (["-m", "pip"], ["-m", "unittest"]):
    record(args[1], args)
else:
    os.execv(sys.executable, [sys.executable, *args])
'''

FLUTTER_TOOL = r'''
import json
import os
from pathlib import Path
import sys
sys.path.insert(0, os.environ["PLAY_TEST_SUPPORT"])
from support import record
args = sys.argv[1:]
record("flutter", args)
if args == ["config", "--machine"]:
    print(os.environ.get("PLAY_TEST_CONFIG", "{}"))
elif args and args[0] == "create":
    target = Path(args[-1]) / "android/app"
    target.mkdir(parents=True)
    (target / "build.gradle.kts").write_text("fixture Android host\n")
elif args == ["pub", "get", "--enforce-lockfile"]:
    pass
elif args[:2] == ["build", "appbundle"]:
    if os.environ.get("PLAY_TEST_BUILD_FAIL") == "1":
        raise SystemExit(23)
    directory = Path("build/app/outputs/bundle/release")
    directory.mkdir(parents=True, exist_ok=True)
    names = os.environ.get("PLAY_TEST_AAB_NAMES", "app-release.aab")
    for name in filter(None, names.split(",")):
        path = directory / name
        if os.environ.get("PLAY_TEST_SYMLINK") == "1":
            payload = Path("build/fixture-payload.bin").resolve()
            payload.write_bytes(b"not a signed AAB")
            path.symlink_to(payload)
        else:
            path.write_bytes(b"orchestration fixture, NOT an Android App Bundle\n")
    if os.environ.get("PLAY_TEST_BUILD_DIRTY") == "1":
        Path("tracked-source.txt").write_text("changed during the fake build\n")
else:
    raise SystemExit("unexpected Flutter fixture invocation: " + repr(args))
'''

PREPARATION_TOOL = r'''
import json
import os
from pathlib import Path
import sys
sys.path.insert(0, os.environ["PLAY_TEST_SUPPORT"])
from support import record
name = Path(__file__).name
args = sys.argv[1:]
record(name, args)
if name == "prepare_android.py" and args != ["--distribution", "play"]:
    raise SystemExit("the builder did not select Play")
if name == "prepare_launcher_icons.py":
    if len(args) != 2 or args[0] != "--report-dir":
        raise SystemExit("expected a separate launcher report directory")
    report = Path(args[1]) / "LAUNCHER-RESOURCES.json"
    report.write_text(json.dumps({"scope": "launcher orchestration fixture"}))
if name == "export_embedded_game.py":
    repo = Path(args[args.index("--repo") + 1])
    if repo.exists():
        raise SystemExit("native staging must be fresh")
    repo.mkdir()
'''

VERIFIER_TOOL = r'''
import argparse
import json
import os
from pathlib import Path
import sys
sys.path.insert(0, os.environ["PLAY_TEST_SUPPORT"])
from support import record
parser = argparse.ArgumentParser()
parser.add_argument("bundle", nargs="?")
parser.add_argument("--preflight", action="store_true")
parser.add_argument("--bundletool", required=True)
parser.add_argument("--output-json")
args = parser.parse_args()
record("preflight" if args.preflight else "verify", sys.argv[1:])
if args.preflight:
    if args.bundle or args.output_json:
        raise SystemExit("invalid preflight call")
    if os.environ.get("PLAY_TEST_PREFLIGHT_FAIL") == "1":
        raise SystemExit(37)
else:
    if not args.bundle or not args.output_json or not Path(args.bundle).is_file():
        raise SystemExit("missing fixture result")
    report = Path(args.output_json)
    report.write_text(json.dumps({
        "scope": "Orchestration fixture only: no real AAB or signing",
        "bundle": args.bundle,
    }))
    if os.environ.get("PLAY_TEST_VERIFY_FAIL") == "1":
        raise SystemExit(41)
    if os.environ.get("PLAY_TEST_VERIFY_DIRTY") == "1":
        Path("tracked-source.txt").write_text("changed during the fake verification\n")
'''


class PlayBundleBuilderTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix="lumo-builder-tests-")
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.repo = self.directory / "source"
        self.bin = self.directory / "fake tools"
        self.work = self.directory / "private staging"
        self.output = self.directory / "result with spaces"
        self.log = self.directory / "events.jsonl"
        self.bundletool = self.directory / "fixture bundletool.jar"
        self.bundletool.write_bytes(b"fixture, NOT executable bundletool")
        for path in (self.repo / "scripts", self.bin, self.work):
            path.mkdir(parents=True)
        (self.repo / ".gitignore").write_text("android/\nbuild/\ndist/\n__pycache__/\n")
        (self.repo / "tracked-source.txt").write_text("committed fixture\n")
        (self.repo / "pubspec.yaml").write_text("name: fixture\nversion: 0.13.8+2020\n")
        shutil.copyfile(ROOT / "scripts/build_play_bundle.sh",
                        self.repo / "scripts/build_play_bundle.sh")
        shutil.copyfile(ROOT / "scripts/build_version.py",
                        self.repo / "scripts/build_version.py")
        self.write_python(self.bin / "python3", PYTHON_TOOL)
        self.write_python(self.bin / "flutter", FLUTTER_TOOL)
        self.write_python(self.bin / "godot", "raise SystemExit(0)\n")
        self.write_python(self.bin / "curl", "raise SystemExit('unexpected download')\n")
        (self.bin / "support.py").write_text(textwrap.dedent(SUPPORT))
        for name in ("prepare_android.py", "prepare_embedded_games.py",
                     "prepare_offline_voice.py", "prepare_launcher_icons.py",
                     "export_embedded_game.py"):
            self.write_python(self.repo / "scripts" / name, PREPARATION_TOOL)
        self.write_python(self.repo / "scripts/verify_play_bundle.py", VERIFIER_TOOL)
        self.git("init", "-q")
        self.git("add", ".")
        self.git("-c", "user.name=Build Fixture", "-c",
                 "user.email=fixture@example.invalid", "commit", "-qm", "fixture")

    def write_python(self, path, source):
        path.write_text("#!" + sys.executable + "\n" + textwrap.dedent(source))
        path.chmod(0o755)

    def git(self, *args):
        return subprocess.run(
            ["git", *args], cwd=self.repo, check=True, capture_output=True, text=True,
        )

    def invoke(self, extra=(), *, environment=None, output=True, raw=None):
        env = {key: value for key, value in os.environ.items()
               if not key.startswith(("LUMO_PLAY_", "PLAY_TEST_"))
               and key not in ("LUMO_BUILD_NUMBER", "LUMO_VERSION_NAME")}
        env.update(
            PATH=str(self.bin) + os.pathsep + env.get("PATH", ""),
            TMPDIR=str(self.work),
            PYTHONDONTWRITEBYTECODE="1",
            PLAY_TEST_EVENTS=str(self.log),
            PLAY_TEST_SUPPORT=str(self.bin),
        )
        env.update(environment or {})
        args = ["--bundletool", str(self.bundletool)]
        if output:
            args += ["--output-dir", str(self.output)]
        args += list(extra)
        if raw is not None:
            args = list(raw)
        return subprocess.run(
            ["bash", str(self.repo / "scripts/build_play_bundle.sh"), *args],
            cwd=self.directory, env=env, capture_output=True, text=True, timeout=20,
        )

    def events(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def assert_no_preparation(self):
        for name in ("android", "dist"):
            self.assertFalse((self.repo / name).exists(), name)
        self.assertFalse(self.output.exists())
        self.assertEqual(list(self.work.iterdir()), [])

    def test_preflight_failure_stops_before_flutter_and_any_preparation(self):
        result = self.invoke(environment={"PLAY_TEST_PREFLIGHT_FAIL": "1"})
        self.assertEqual(result.returncode, 37, result.stderr)
        self.assertEqual([event["tool"] for event in self.events()], ["preflight"])
        self.assert_no_preparation()
        self.assertFalse((self.repo / "build").exists())

    def test_invalid_arguments_do_not_reach_preflight(self):
        cases = [
            [], ["--bundletool"], ["--bundletool", "--output-dir"],
            ["--bundletool", str(self.bundletool), "--side-by-side"],
            ["--bundletool", str(self.bundletool), "--repo", "elsewhere"],
            ["--bundletool", str(self.bundletool), "--distribution", "family"],
            ["--bundletool", str(self.bundletool), "--bundletool", str(self.bundletool)],
        ]
        for args in cases:
            with self.subTest(args=args):
                result = self.invoke(raw=args)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(self.events(), [])
                self.assert_no_preparation()

    def test_conflicting_version_overrides_stop_before_preflight(self):
        for overrides in ({"LUMO_BUILD_NUMBER": "2021"},
                          {"LUMO_VERSION_NAME": "0.13.9"}):
            with self.subTest(overrides=overrides):
                result = self.invoke(environment=overrides)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("version overrides", result.stderr)
                self.assertEqual(self.events(), [])
                self.assert_no_preparation()

    def test_existing_destination_is_preserved(self):
        self.output.mkdir()
        previous = self.output / "PLAY-BUNDLE-PROVENANCE.json"
        previous.write_bytes(b"previous evidence")
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(previous.read_bytes(), b"previous evidence")
        self.assertEqual(self.events(), [])

    def test_output_inside_sources_is_rejected(self):
        result = self.invoke(
            raw=["--bundletool", str(self.bundletool),
                 "--output-dir", str(self.repo / "scripts/new-result")],
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.events(), [])
        self.assert_no_preparation()

    def test_dirty_or_untracked_build_sources_are_rejected_before_preflight(self):
        (self.repo / "tracked-source.txt").write_text("uncommitted\n")
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.events(), [])
        (self.repo / "tracked-source.txt").write_text("committed fixture\n")
        (self.repo / "scripts/untracked.py").write_text("untracked\n")
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.events(), [])
        self.assert_no_preparation()

    def test_nondefault_or_invalid_flutter_configuration_stops_before_preparation(self):
        for config in ('{"build-dir":"elsewhere"}', "not JSON", "[]"):
            with self.subTest(config=config):
                if self.log.exists():
                    self.log.unlink()
                result = self.invoke(environment={"PLAY_TEST_CONFIG": config})
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual([event["tool"] for event in self.events()],
                                 ["preflight", "flutter"])
                self.assert_no_preparation()

    def test_stale_aab_is_never_removed_or_reused(self):
        stale = self.repo / "build/app/outputs/bundle/release/app-release.aab"
        stale.parent.mkdir(parents=True)
        stale.write_bytes(b"old candidate")
        result = self.invoke()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stale.read_bytes(), b"old candidate")
        self.assert_no_preparation()
        self.assertEqual([event["tool"] for event in self.events()],
                         ["preflight", "flutter"])

    def test_build_failure_never_calls_final_verifier(self):
        result = self.invoke(environment={"PLAY_TEST_BUILD_FAIL": "1"})
        self.assertEqual(result.returncode, 23, result.stderr)
        self.assertNotIn("verify", [event["tool"] for event in self.events()])
        self.assertFalse((self.output / "PLAY-BUNDLE-PROVENANCE.json").exists())
        self.assertEqual(list(self.work.iterdir()), [])

    def test_missing_ambiguous_or_unexpected_bundle_is_rejected(self):
        for names in ("", "app.aab,app-release.aab", "unexpected.aab"):
            with self.subTest(names=names):
                # Each attempt deliberately has its own checkout and output directory.
                other = type(self)("runTest")
                try:
                    other.setUp()
                    result = other.invoke(environment={"PLAY_TEST_AAB_NAMES": names})
                    self.assertNotEqual(result.returncode, 0)
                    self.assertNotIn("verify", [event["tool"] for event in other.events()])
                    self.assertFalse((other.output / "PLAY-BUNDLE-PROVENANCE.json").exists())
                finally:
                    other.doCleanups()

    def test_symbolic_bundle_is_rejected(self):
        result = self.invoke(environment={"PLAY_TEST_SYMLINK": "1"})
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("verify", [event["tool"] for event in self.events()])

    def test_verifier_failure_removes_even_a_partially_written_success_report(self):
        result = self.invoke(environment={"PLAY_TEST_VERIFY_FAIL": "1"})
        self.assertEqual(result.returncode, 41, result.stderr)
        self.assertFalse((self.output / "PLAY-BUNDLE-PROVENANCE.json").exists())
        self.assertEqual(list(self.work.iterdir()), [])

    def test_source_change_after_build_or_verification_prevents_success_report(self):
        for flag in ("PLAY_TEST_BUILD_DIRTY", "PLAY_TEST_VERIFY_DIRTY"):
            with self.subTest(flag=flag):
                other = type(self)("runTest")
                try:
                    other.setUp()
                    result = other.invoke(environment={flag: "1"})
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse((other.output / "PLAY-BUNDLE-PROVENANCE.json").exists())
                finally:
                    other.doCleanups()

    def test_orchestrates_play_only_flow_with_fake_tools_and_fresh_private_native_source(self):
        result = self.invoke(extra=("--godot", str(self.bin / "godot")))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        events = self.events()
        self.assertEqual(events[0]["tool"], "preflight")
        preparation = next(event for event in events if event["tool"] == "prepare_android.py")
        self.assertEqual(preparation["args"], ["--distribution", "play"])
        native = next(event for event in events if event["tool"] == "export_embedded_game.py")
        native_path = Path(native["args"][native["args"].index("--repo") + 1])
        self.assertEqual(native_path.parent.parent, self.work)
        self.assertTrue(native_path.parent.name.startswith("lumo-play-build."))
        build = next(event for event in events
                     if event["tool"] == "flutter" and event["args"][:2] == ["build", "appbundle"])
        self.assertIn("--release", build["args"])
        self.assertIn("--no-pub", build["args"])
        self.assertIn("android-arm64,android-x64", build["args"])
        self.assertFalse(any("SIDE_BY_SIDE=true" in arg for arg in build["args"]))
        self.assertEqual(events[-1]["tool"], "verify")
        self.assertEqual(list(self.work.iterdir()), [])
        report = json.loads((self.output / "PLAY-BUNDLE-PROVENANCE.json").read_text())
        self.assertIn("fixture", report["scope"])
        self.assertEqual(report["bundle"], str(self.output / "Lumo-Lernen-Play.aab"))

    def test_current_documented_app_aab_name_and_default_unique_destination(self):
        result = self.invoke(output=False, environment={"PLAY_TEST_AAB_NAMES": "app.aab"})
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        destinations = list((self.repo / "dist").glob("play-*"))
        self.assertEqual(len(destinations), 1)
        self.assertTrue((destinations[0] / "PLAY-BUNDLE-PROVENANCE.json").is_file())


if __name__ == "__main__":
    unittest.main()
