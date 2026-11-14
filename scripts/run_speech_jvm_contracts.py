#!/usr/bin/env python3
"""Run the exact speech contracts after the real Android host compilation.

No compiler is installed. The already populated wrapper distribution is selected
from its actual properties, then invoked directly with --offline: invoking an
unpopulated gradlew could download a distribution before Gradle sees --offline.
The JVM contracts use explicit Android/ONNX boundaries, not device playback.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
from urllib.parse import unquote, urlparse
import zipfile


FIXTURE_DIR = "scripts/tests/fixtures/learning_english_speech"
CONTRACT_DIR = "scripts/speech_contracts"
APFEL_SHA256 = "39aba71e80a9230d832f038630eaff8fa0fc0c5eae104581ce487bce9ebbd586"
HISTORICAL_SHA256 = {
    "LearningSpeechLifecycleContract.kt": "d7649f5ce36771c1cf886279f2cbc81fca8e6032dd13d935738d869cc6024523",
    "SpeechEnvelopeContract.kt": "6cb28dd0820679705bc9ee39ff9aced59ec4191aeec00a286916fb660bba6dc6",
    "apfel-original.wav": APFEL_SHA256,
}
JAVA_MODES = ("tags", "join", "malformed", "bounds", "sequence", "before",
              "between", "before-join", "after-join", "thread")
KOTLIN_MODES = ("binding", "invalid-descriptor", "parent-and-default", "one-player",
               "late-callback", "result-identity")
GROUPS = {
    "test_english_lesson_speech": {
        "cases": 11,
        "markers": ("PASS local voice Java guards: 11",) + tuple(
            "ENGLISH_LESSON_JAVA_PASS scenario=" + name + " checks=" for name in JAVA_MODES),
        "timeout_seconds": 300,
    },
    "test_learning_english_speech_lifecycle": {
        "cases": 8,
        "markers": ("LUMO_SPEECH_LIFECYCLE_PASS checks=17",
                    "LUMO_SPEECH_ENVELOPE_PASS checks=23") + tuple(
            "ENGLISH_LESSON_LIFECYCLE_PASS scenario=" + name + " checks=" for name in KOTLIN_MODES),
        "timeout_seconds": 420,
    },
}
PRODUCTS = ("LumoLearningSpeech", "LumoOfflineSpeechBridge",
            "LumoOfflineSpeechEngine", "LumoSpeechEnvelope")
SOURCE_PATHS = (
    "scripts/run_speech_jvm_contracts.py",
    "scripts/compile_android_host.sh",
    "scripts/gradle/lumo-maven-central-mirror.init.gradle",
    CONTRACT_DIR + "/test_english_lesson_speech.py",
    CONTRACT_DIR + "/test_learning_english_speech_lifecycle.py",
    "scripts/voice/LumoOfflineSpeechEngineProbe.java",
    *("tools/auto_install/" + name + (".java" if name.endswith("Engine") else ".kt")
      for name in PRODUCTS),
    *(FIXTURE_DIR + "/" + name for name in (
        "LearningSpeechLifecycleContract.kt", "SpeechEnvelopeContract.kt",
        "EnglishLessonLifecycleContract.kt", "platform_fixture.py", "apfel-original.wav")),
)

GRADLE_INIT = r'''
import groovy.json.JsonOutput
gradle.rootProject { project ->
    if (project.projectDir.canonicalFile != new File(System.getenv('LUMO_SPEECH_ANDROID_ROOT')).canonicalFile) return
    project.tasks.register('lumoSpeechJvmToolchain') {
        doLast {
            def home = gradle.gradleHomeDir
            if (home == null) throw new GradleException('No actual Gradle distribution home')
            def destination = new File(System.getenv('LUMO_SPEECH_TOOLCHAIN_FILE'))
            destination.text = JsonOutput.toJson([
                gradle_home: home.canonicalPath,
                gradle_version: gradle.gradleVersion,
                kotlin_lib_dir: new File(home, 'lib').canonicalPath,
                java_home: System.getProperty('java.home'),
                java_version: System.getProperty('java.version')
            ]) + '\n'
        }
    }
}
'''

CHILD = r'''
import importlib.util,json,pathlib,sys,time,unittest
module_name,root,output=sys.argv[1:]
root=pathlib.Path(root)
sys.path.insert(0,str(root/'scripts/speech_contracts'))
spec=importlib.util.spec_from_file_location(module_name,root/'scripts/speech_contracts'/(module_name+'.py'))
module=importlib.util.module_from_spec(spec)
sys.modules[module_name]=module
spec.loader.exec_module(module)
suite=unittest.defaultTestLoader.loadTestsFromModule(module)
def identities(node):
    if isinstance(node,unittest.TestSuite):
        return [value for child in node for value in identities(child)]
    return [node.id()]
test_ids=identities(suite)
started=time.monotonic()
result=unittest.TextTestRunner(verbosity=2).run(suite)
report={'module':module_name,'test_ids':test_ids,'tests_run':result.testsRun,
        'failures':len(result.failures),'errors':len(result.errors),
        'skips':len(result.skipped),'expected_failures':len(result.expectedFailures),
        'unexpected_successes':len(result.unexpectedSuccesses),
        'successful':result.wasSuccessful(),'duration_seconds':time.monotonic()-started}
pathlib.Path(output).write_text(json.dumps(report,indent=2)+'\n')
sys.exit(0 if result.wasSuccessful() and not result.skipped and not result.expectedFailures else 1)
'''


def utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def measure(path: Path) -> dict:
    data = path.read_bytes()
    return {"bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
            "git_blob_sha": hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()}


def require(value: bool, message: str) -> None:
    if not value:
        raise RuntimeError(message)


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True,
                                   stderr=subprocess.STDOUT, timeout=15).strip()


def verify_contract_layout(root: Path) -> None:
    for name in GROUPS:
        require((root / CONTRACT_DIR / (name + ".py")).is_file(),
                "Missing dedicated speech contract: " + name)
        require(not (root / "scripts/tests" / (name + ".py")).exists(),
                "Speech contracts must not also enter broad unittest discovery: " + name)


def expected_ci_source(environment: dict) -> str | None:
    if environment.get("GITHUB_EVENT_NAME") == "pull_request":
        event_path = environment.get("GITHUB_EVENT_PATH")
        require(bool(event_path), "Pull-request checkout needs the original event payload")
        event = json.loads(Path(event_path).read_text())
        pull_head = event["pull_request"]["head"]
        require(bool(environment.get("GITHUB_REPOSITORY")) and
                pull_head["repo"]["full_name"] == environment["GITHUB_REPOSITORY"],
                "Only the same-repository pull-request head may supply speech sources")
        revision = pull_head["sha"]
    else:
        revision = environment.get("GITHUB_SHA")
    if revision is not None:
        require(isinstance(revision, str) and bool(re.fullmatch(r"[0-9a-f]{40}", revision)),
                "Invalid original CI checkout identity")
    return revision


def snapshot(root: Path) -> dict:
    head = git(root, "rev-parse", "HEAD")
    require(bool(re.fullmatch(r"[0-9a-f]{40}", head)), "Invalid checkout identity")
    expected = expected_ci_source(os.environ)
    if expected is not None:
        require(head == expected, "Checkout differs from this CI source")
    git(root, "diff", "--exit-code", "HEAD", "--")
    verify_contract_layout(root)
    files = []
    for relative in SOURCE_PATHS:
        path = root / relative
        current = measure(path)
        require(current["git_blob_sha"] == git(root, "rev-parse", "HEAD:" + relative),
                "Uncommitted or foreign speech source: " + relative)
        files.append({"path": relative, **current})
    for name, digest in HISTORICAL_SHA256.items():
        require(measure(root / FIXTURE_DIR / name)["sha256"] == digest,
                "Historical speech fixture changed: " + name)
    return {"head": head, "ci_source": expected, "files": files}


def verify_host_compile(root: Path, head: str) -> dict:
    path = root / "host-compile-evidence/result.json"
    result = json.loads(path.read_text())
    require(result.get("status") == "PASS" and result.get("flutter_source_commit") == head,
            "A completed actual Android compile for this exact checkout is required")
    classes = result.get("classes", {})
    for name in PRODUCTS:
        entries = classes.get(name)
        require(isinstance(entries, list) and bool(entries), "Missing real Android class: " + name)
        for entry in entries:
            compiled = (root / entry["path"]).resolve()
            require(compiled.is_relative_to(root / "build/app"), "Compiled class escapes the actual build")
            actual = measure(compiled)
            require(actual["bytes"] == entry["bytes"] and actual["sha256"] == entry["sha256"],
                    "Compiled class changed: " + name)
            require(compiled.read_bytes()[:4] == bytes.fromhex("cafebabe"), "Not JVM bytecode: " + name)
    return {"path": str(path.relative_to(root)), **measure(path)}


def validate_libraries(home: Path) -> dict:
    libraries = home / "lib"
    jars = sorted(libraries.glob("*.jar"))
    compilers = [p for p in jars if re.fullmatch(r"kotlin-compiler-embeddable-[0-9].*\.jar", p.name)]
    standard = [p for p in jars if re.fullmatch(r"kotlin-stdlib-[0-9].*\.jar", p.name)]
    require(len(compilers) == 1 and len(standard) == 1,
            "One existing Kotlin compiler and standard library are required; nothing will be installed")
    for path, member in ((compilers[0], "org/jetbrains/kotlin/cli/jvm/K2JVMCompiler.class"),
                         (standard[0], "kotlin/Unit.class")):
        with zipfile.ZipFile(path) as archive:
            require(archive.read(member)[:4] == bytes.fromhex("cafebabe"),
                    "Invalid existing Kotlin library: " + path.name)
    return {"directory": str(libraries.resolve()), "compiler": compilers[0].name,
            "stdlib": standard[0].name,
            "jars": [{"name": p.name, **measure(p)} for p in jars]}


def existing_distribution(root: Path, environment: dict) -> dict:
    properties_path = root / "android/gradle/wrapper/gradle-wrapper.properties"
    properties = {}
    for line in properties_path.read_text().splitlines():
        if "=" in line and not line.lstrip().startswith(("#", "!")):
            key, value = line.split("=", 1)
            properties[key.strip()] = value.strip().replace(r"\:", ":")
    require(properties.get("distributionBase", "GRADLE_USER_HOME") == "GRADLE_USER_HOME" and
            properties.get("distributionPath", "wrapper/dists") == "wrapper/dists",
            "Unsupported wrapper cache layout; refuse to bootstrap or install a distribution")
    url = properties.get("distributionUrl", "")
    parsed = urlparse(url)
    name = Path(unquote(parsed.path)).name
    match = re.fullmatch(r"gradle-([0-9][0-9A-Za-z.+-]*)-(?:bin|all)\.zip", name)
    require(parsed.scheme == "https" and match is not None, "Unrecognized wrapper distribution identity")
    version = match.group(1)
    user_home = Path(environment.get("GRADLE_USER_HOME") or Path.home() / ".gradle").resolve()
    directory = user_home / "wrapper/dists" / name[:-4]
    candidates = sorted({p.resolve() for p in directory.glob("*/gradle-" + version + "/bin/gradle")
                         if p.is_file() and os.access(p, os.X_OK) and p.resolve().is_relative_to(directory)})
    require(len(candidates) == 1,
            "Exactly one already installed wrapper distribution is required; no download or global Gradle fallback")
    executable = candidates[0]
    home = executable.parent.parent
    libraries = validate_libraries(home)
    return {"home": str(home), "executable": str(executable), "version": version,
            "distribution_url": url, "wrapper_properties": measure(properties_path),
            "libraries": libraries}


def run_command(command: list[str], cwd: Path, environment: dict, log: Path,
                timeout_seconds: float) -> dict:
    started = utc()
    clock = time.monotonic()
    timed_out = False
    with log.open("wb") as stream:
        process = subprocess.Popen(command, cwd=cwd, env=environment, stdout=stream,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=timeout_seconds)
        except (subprocess.TimeoutExpired, KeyboardInterrupt):
            timed_out = True
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                code = process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                code = process.wait(timeout=3)
    return {"command": command, "started_utc": started, "completed_utc": utc(),
            "duration_seconds": time.monotonic() - clock, "exit_code": code,
            "timed_out": timed_out, "log": str(log), "log_binding": measure(log)}


def offline_gradle_command(distribution: dict, root: Path, init: Path) -> list[str]:
    return [distribution["executable"], "--offline", "--no-daemon", "--no-configuration-cache",
            "--console=plain", "-Ptarget-platform=android-arm64,android-x64", "-q",
            "-p", str(root / "android"), "-I", str(init),
            "lumoSpeechJvmToolchain"]


def bound_environment(environment: dict, toolchain: dict) -> dict:
    result = dict(environment)
    java_home = Path(toolchain["java_home"]).resolve()
    require((java_home / "bin/java").is_file() and (java_home / "bin/javac").is_file(),
            "Actual Gradle JDK does not contain java and javac")
    result.update(JAVA_HOME=str(java_home), LUMO_KOTLIN_LIB_DIR=toolchain["kotlin_lib_dir"],
                  REQUIRE_ALL_TESTS="true", PYTHONDONTWRITEBYTECODE="1")
    result["PATH"] = str(java_home / "bin") + os.pathsep + result.get("PATH", "")
    return result


def validate_group(name: str, result: dict, log: str) -> None:
    expected = GROUPS[name]
    ids = result.get("test_ids", [])
    require(result.get("module") == name and result.get("successful") is True and
            result.get("tests_run") == expected["cases"] and len(ids) == expected["cases"] and
            len(set(ids)) == len(ids) and all(value.startswith(name + ".") for value in ids),
            "Speech contract roster is incomplete: " + name)
    require(all(result.get(key) == 0 for key in
                ("failures", "errors", "skips", "expected_failures", "unexpected_successes")),
            "Speech contracts may not fail, skip or declare expected failures: " + name)
    for marker in expected["markers"]:
        require(sum(line.startswith(marker) for line in log.splitlines()) == 1,
                "Missing or duplicate actual contract marker: " + marker)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, default=Path("host-compile-evidence/speech"))
    args = parser.parse_args()
    root = args.repo_root.resolve()
    output = (root / args.output).resolve()
    require(output.is_relative_to(root / "host-compile-evidence"),
            "Evidence output must stay inside host-compile-evidence")
    require(not output.exists() or not any(output.iterdir()), "Refuse to replace existing speech evidence")
    output.mkdir(parents=True, exist_ok=True)
    report = {"schema": 1, "started_utc": utc(), "status": "FAIL", "groups": {},
              "scope": "Production Java/Kotlin contracts with explicit synthetic ONNX/Android boundaries; no inference, heard audio, APK or device claim"}
    before = None
    try:
        before = snapshot(root)
        report["source_before"] = before
        report["actual_android_compile"] = verify_host_compile(root, before["head"])
        distribution = existing_distribution(root, os.environ)
        report["existing_distribution"] = distribution
        with tempfile.TemporaryDirectory(prefix="lumo-speech-jvm-runner-") as temporary:
            work = Path(temporary)
            init = work / "toolchain.init.gradle"
            init.write_text(GRADLE_INIT)
            toolchain_path = output / "resolved-toolchain.json"
            environment = dict(os.environ)
            environment.update(LUMO_SPEECH_ANDROID_ROOT=str(root / "android"),
                               LUMO_SPEECH_TOOLCHAIN_FILE=str(toolchain_path))
            resolution = run_command(offline_gradle_command(distribution, root, init), root,
                                     environment, output / "toolchain-original.log", 120)
            report["toolchain_execution"] = resolution
            require(resolution["exit_code"] == 0 and not resolution["timed_out"], "Offline Gradle resolution failed")
            toolchain = json.loads(toolchain_path.read_text())
            require(Path(toolchain["gradle_home"]).resolve() == Path(distribution["home"]) and
                    toolchain["gradle_version"] == distribution["version"] and
                    Path(toolchain["kotlin_lib_dir"]).resolve() == Path(distribution["libraries"]["directory"]),
                    "Running Gradle differs from the selected existing distribution")
            report["resolved_toolchain"] = toolchain
            environment = bound_environment(environment, toolchain)
            child = work / "run_contract.py"
            child.write_text(CHILD)
            for name in GROUPS:
                result_path = output / (name + ".json")
                log_path = output / (name + ".log")
                execution = run_command([sys.executable, "-B", str(child), name, str(root), str(result_path)],
                                        root, environment, log_path, GROUPS[name]["timeout_seconds"])
                report["groups"][name] = {"execution": execution}
                require(execution["exit_code"] == 0 and not execution["timed_out"], "Contract process failed: " + name)
                result = json.loads(result_path.read_text())
                report["groups"][name]["result"] = result
                validate_group(name, result, log_path.read_text(errors="replace"))
            require(validate_libraries(Path(distribution["home"])) == distribution["libraries"],
                    "Compiler libraries changed during contracts")
            report["status"] = "PASS"
    except Exception as error:
        report["error"] = type(error).__name__ + ": " + str(error)
    finally:
        if before is not None:
            try:
                after = snapshot(root)
                report["source_after"] = after
                require(before == after, "Tracked speech source changed during contracts")
            except Exception as error:
                report["status"] = "FAIL"
                report["source_after_error"] = type(error).__name__ + ": " + str(error)
        report["completed_utc"] = utc()
        (output / "result.json").write_text(json.dumps(report, indent=2) + "\n")
    if report["status"] != "PASS":
        print("[SpeechJvmContracts] FAIL: " + report.get("error", report.get("source_after_error", "unknown")), file=sys.stderr)
        return 1
    print("[SpeechJvmContracts] PASS: 11 Java and 8 Kotlin cases, original 23/17 assertions; synthetic boundaries only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
