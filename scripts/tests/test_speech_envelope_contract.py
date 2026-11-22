"""Compile the actual PCM speech sources against explicit synthetic JVM fixtures.

The two producer contracts and original voice WAV are preserved byte for byte.
This gate proves neither Android playback nor an audible/visual device result.
It uses only already installed Gradle Kotlin libraries and never downloads tools.
"""
from pathlib import Path
import os
import shutil
import struct
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).resolve().parent / 'fixtures/speech_envelope_contract'


class SpeechEnvelopeContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        configured = Path(os.environ.get('JAVA_HOME', '/nonexistent')) / 'bin/java'
        cls.java = str(configured) if configured.is_file() else shutil.which('java')
        candidates = [Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent')),
                      Path(os.environ.get('GRADLE_HOME', '/nonexistent')) / 'lib']
        gradle = shutil.which('gradle')
        if gradle:
            candidates.append(Path(gradle).resolve().parents[1] / 'lib')
        libraries = next((p for p in candidates
                          if list(p.glob('kotlin-compiler-embeddable-*.jar'))), None)
        if not cls.java or libraries is None:
            raise RuntimeError('Use the existing JDK and verified Gradle Kotlin libraries; no compiler download')
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-speech-envelope-')
        cls.addClassCleanup(cls.temp.cleanup)
        classes = Path(cls.temp.name) / 'classes'
        classes.mkdir()
        stdlib = next(libraries.glob('kotlin-stdlib-*.jar'))
        cls.classpath = os.pathsep.join(map(str, (classes, stdlib)))
        sources = [ROOT / 'tools/auto_install/LumoSpeechEnvelope.kt',
                   ROOT / 'tools/auto_install/LumoLearningSpeech.kt',
                   *sorted(FIXTURES.glob('*.kt')),
                   *sorted((FIXTURES / 'platform').glob('*.kt'))]
        cls.run_checked([
            cls.java, '-cp', os.pathsep.join(map(str, sorted(libraries.glob('*.jar')))),
            'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
            '-classpath', cls.classpath, '-jvm-target', '1.8', '-d', str(classes),
            *map(str, sources),
        ])
        # A declared PCM boundary fixture, never an English voice recording:
        # audible first segment, silent gap, audible second segment.
        frames = 44100 * 4 // 5
        pcm = b''.join(struct.pack('<h', 6000 if n < 8820 else 0 if n < 19845 else 9000)
                       for n in range(frames))
        cls.joined_pcm = Path(cls.temp.name) / 'synthetic-joined-pcm-no-speech.wav'
        cls.joined_pcm.write_bytes(
            b'RIFF' + struct.pack('<I', 36 + len(pcm)) + b'WAVEfmt ' +
            struct.pack('<IHHIIHH', 16, 1, 1, 44100, 88200, 2, 16) +
            b'data' + struct.pack('<I', len(pcm)) + pcm)

    @classmethod
    def run_checked(cls, command):
        result = subprocess.run(command, capture_output=True, text=True, timeout=90)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        return result

    def run_contract(self, main, marker):
        result = self.run_checked([
            self.java, '-cp', self.classpath, 'dev.ullmann.lumo.' + main,
            str(FIXTURES / 'apfel.wav'),
        ])
        self.assertIn(marker, result.stdout.splitlines())
        print(result.stdout, end='')

    def test_original_pcm_envelope_contract(self):
        self.run_contract(
            'SpeechEnvelopeContractKt',
            'LUMO_SPEECH_ENVELOPE_PASS checks=23 original_apfel_duration_ms=929 bins=47',
        )

    def test_original_learning_lifecycle_contract(self):
        self.run_contract(
            'LearningSpeechLifecycleContractKt',
            'LUMO_SPEECH_LIFECYCLE_PASS checks=17 platform=synthetic_JVM_boundary no_Android_playback_claim=true',
        )

    def test_build_consent_rate_and_activity_contract(self):
        self.run_contract(
            'LearningSpeechBuildContractKt',
            'LUMO_BUILD_SPEECH_PASS checks=30 platform=synthetic_JVM_boundary no_Android_playback_claim=true',
        )

    def test_current_failure_has_private_content_free_owner_and_stale_guard(self):
        self.run_contract(
            'LearningSpeechFailureContractKt',
            'LUMO_SPEECH_FAILURE_PASS checks=15 platform=synthetic_JVM_boundary no_Android_playback_claim=true',
        )

    def english_scenario(self, name):
        result = self.run_checked([
            self.java, '-cp', self.classpath,
            'dev.ullmann.lumo.EnglishLessonLifecycleContractKt',
            name, str(self.joined_pcm),
        ])
        self.assertIn('ENGLISH_LESSON_LIFECYCLE_PASS scenario=' + name, result.stdout)
        print(result.stdout, end='')

    def test_english_host_binds_all_twenty_current_words(self):
        self.english_scenario('binding')

    def test_english_invalid_task_descriptor_never_synthesizes(self):
        self.english_scenario('invalid-descriptor')

    def test_english_parent_guards_and_default_german_path(self):
        self.english_scenario('parent-and-default')

    def test_english_sequence_uses_one_player_and_measured_silent_gap(self):
        self.english_scenario('one-player')

    def test_english_late_callbacks_cannot_outlive_pause_or_task(self):
        self.english_scenario('late-callback')

    def test_english_result_identity_cannot_change_word_or_voice(self):
        self.english_scenario('result-identity')


if __name__ == '__main__':
    unittest.main()
