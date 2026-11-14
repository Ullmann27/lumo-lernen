"""Complete production learning-player lifecycle with declared Android boundaries.

Uses the same installed Gradle Kotlin compiler as the existing Cards contract;
downloads nothing. REQUIRE_ALL_TESTS=true makes missing tools an error. The two
historical Kotlin contracts are byte-for-byte preserved. No Android or speech
inference success is inferred from these JVM boundary tests.
"""
from pathlib import Path
import hashlib
import importlib.util
import os
import shutil
import struct
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / "scripts/tests/fixtures/learning_english_speech"


def missing_toolchain(message):
    if os.environ.get("REQUIRE_ALL_TESTS", "").lower() == "true":
        raise RuntimeError(message)
    raise unittest.SkipTest(message)


class EnglishLearningSpeechLifecycleTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        configured = Path(os.environ.get("JAVA_HOME", "/nonexistent")) / "bin/java"
        cls.java = str(configured) if configured.is_file() else shutil.which("java")
        if not cls.java:
            missing_toolchain("JDK required; this contract downloads nothing")
        candidates = [Path(os.environ.get("LUMO_KOTLIN_LIB_DIR", "/nonexistent")),
                      Path(os.environ.get("GRADLE_HOME", "/nonexistent")) / "lib"]
        gradle = shutil.which("gradle")
        if gradle:
            candidates.append(Path(gradle).resolve().parents[1] / "lib")
        libraries = next((p for p in candidates
                          if list(p.glob("kotlin-compiler-embeddable-*.jar"))), None)
        if libraries is None:
            missing_toolchain("Use the existing validated Gradle compiler or LUMO_KOTLIN_LIB_DIR; no download")
        cls.temp = tempfile.TemporaryDirectory(prefix="lumo-learning-english-jvm-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.work = Path(cls.temp.name)
        cls.classes = cls.work / "classes"
        cls.classes.mkdir()
        spec = importlib.util.spec_from_file_location("learning_platform_fixture", FIXTURES / "platform_fixture.py")
        platform = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(platform)
        paths = []
        for name, source in platform.STUBS.items():
            path = cls.work / name
            path.write_text(source)
            paths.append(path)
        production = [ROOT / "tools/auto_install" / name for name in
                      ("LumoLearningSpeech.kt", "LumoSpeechEnvelope.kt")]
        cls.classpath = os.pathsep.join(map(str, [cls.classes, next(libraries.glob("kotlin-stdlib-*.jar"))]))
        compiler = [cls.java, "-cp", os.pathsep.join(map(str, sorted(libraries.glob("*.jar")))),
                    "org.jetbrains.kotlin.cli.jvm.K2JVMCompiler", "-no-stdlib", "-no-reflect"]
        def compile_sources(sources, destination):
            result = subprocess.run([
                *compiler, "-classpath", cls.classpath, "-jvm-target", "1.8", "-d", str(destination),
                *map(str, sources),
            ], capture_output=True, text=True, timeout=60)
            if result.returncode:
                raise AssertionError(result.stdout + result.stderr)
            if result.stdout or result.stderr:
                print(result.stdout + result.stderr)
        compile_sources(production + paths, cls.classes)
        cls.main_classpaths = {}
        for name in ("LearningSpeechLifecycleContract", "SpeechEnvelopeContract", "EnglishLessonLifecycleContract"):
            destination = cls.work / name
            destination.mkdir()
            compile_sources([FIXTURES / (name + ".kt")], destination)
            cls.main_classpaths[name + "Kt"] = os.pathsep.join([str(destination), cls.classpath])
        for path in production:
            print("Complete production Kotlin " + path.name + " SHA256=" + hashlib.sha256(path.read_bytes()).hexdigest())
        original = (FIXTURES / "apfel-original.wav").read_bytes()
        if hashlib.sha256(original).hexdigest() != "39aba71e80a9230d832f038630eaff8fa0fc0c5eae104581ce487bce9ebbd586":
            raise AssertionError("Historical apfel WAV identity changed")
        frames = 44100 * 4 // 5
        pcm = b"".join(struct.pack("<h", 6000 if n < 8820 else 0 if n < 19845 else 9000)
                       for n in range(frames))
        cls.synthetic = cls.work / "synthetic-joined-pcm-no-speech.wav"
        cls.synthetic.write_bytes(b"RIFF" + struct.pack("<I", 36 + len(pcm)) + b"WAVEfmt " +
                                  struct.pack("<IHHIIHH", 16, 1, 1, 44100, 88200, 2, 16) +
                                  b"data" + struct.pack("<I", len(pcm)) + pcm)

    def run_contract(self, main, arguments, marker):
        result = subprocess.run([self.java, "-cp", self.main_classpaths[main], "dev.ullmann.lumo." + main,
                                 *map(str, arguments)], capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(marker, result.stdout)
        print(result.stdout.strip())

    def scenario(self, name):
        self.run_contract("EnglishLessonLifecycleContractKt", [name, self.synthetic],
                          "ENGLISH_LESSON_LIFECYCLE_PASS scenario=" + name)

    def test_original_seventeen_lifecycle_assertions(self):
        self.run_contract("LearningSpeechLifecycleContractKt", [FIXTURES / "apfel-original.wav"],
                          "LUMO_SPEECH_LIFECYCLE_PASS checks=17")

    def test_original_twenty_three_envelope_assertions(self):
        self.run_contract("SpeechEnvelopeContractKt", [FIXTURES / "apfel-original.wav"],
                          "LUMO_SPEECH_ENVELOPE_PASS checks=23")

    def test_host_descriptor_owns_word_and_language(self): self.scenario("binding")
    def test_malformed_current_lesson_refused(self): self.scenario("invalid-descriptor")
    def test_parent_guards_and_old_german_signature(self): self.scenario("parent-and-default")
    def test_one_player_real_position_and_pcm_gap(self): self.scenario("one-player")
    def test_late_results_after_pause_replace_and_destroy(self): self.scenario("late-callback")
    def test_wrong_result_word_locale_identity_refused(self): self.scenario("result-identity")


if __name__ == "__main__":
    unittest.main()
