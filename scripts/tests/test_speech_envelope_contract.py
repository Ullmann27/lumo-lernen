"""Compile the actual PCM speech sources against explicit synthetic JVM fixtures.

The two producer contracts and original voice WAV are preserved byte for byte.
This gate proves neither Android playback nor an audible/visual device result.
It uses only already installed Gradle Kotlin libraries and never downloads tools.
"""
from pathlib import Path
import os
import shutil
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


if __name__ == '__main__':
    unittest.main()
