"""Compile production local recognition against Android36 and execute JVM cases.

The JVM fixtures model method-channel/recognizer boundaries, not Android audio.
No test downloads a recognizer, calls a provider, or captures a child's voice.
"""
import hashlib
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
FIXTURES = Path(__file__).resolve().parent / 'fixtures/local_recognition'
SOURCE = ROOT / 'tools/auto_install/LumoLocalRecognition.kt'
JSON_SHA256 = '3cf6cd6892e32e2b4c1c39e0f52f5248a2f5b37646fdfbb79a66b46b618414ed'


class LocalRecognitionContractTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        candidates = [Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent')),
                      Path(os.environ.get('GRADLE_HOME', '/nonexistent')) / 'lib']
        if shutil.which('gradle'):
            candidates.append(Path(shutil.which('gradle')).resolve().parents[1] / 'lib')
        cls.libraries = next((p for p in candidates
                              if list(p.glob('kotlin-compiler-embeddable-*.jar'))), None)
        cls.java = shutil.which('java')
        if cls.libraries is None or cls.java is None:
            raise RuntimeError('Use existing JDK/Gradle Kotlin libraries; set LUMO_KOTLIN_LIB_DIR')
        cls.stdlib = next(cls.libraries.glob('kotlin-stdlib-*.jar'))
        cls.temp = tempfile.TemporaryDirectory(prefix='lumo-local-recognition-')
        cls.addClassCleanup(cls.temp.cleanup)
        cls.directory = Path(cls.temp.name)

    @classmethod
    def compile(cls, destination, sources, dependencies):
        destination.mkdir()
        command = [cls.java, '-cp', os.pathsep.join(map(str, cls.libraries.glob('*.jar'))),
                   'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                   '-classpath', os.pathsep.join(map(str, [cls.stdlib, *dependencies])),
                   '-jvm-target', '17', '-d', str(destination), *map(str, sources)]
        result = subprocess.run(command, capture_output=True, text=True, timeout=90)
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)

    def test_actual_android36_flutter_api_compilation(self):
        sdk = Path(os.environ.get('ANDROID_SDK_ROOT',
                   os.environ.get('ANDROID_HOME', '/nonexistent')))
        flutter = Path(os.environ.get('FLUTTER_ROOT', '/nonexistent'))
        if not flutter.is_dir() and shutil.which('flutter'):
            flutter = Path(shutil.which('flutter')).resolve().parents[1]
        android_jar = sdk / 'platforms/android-36/android.jar'
        flutter_jar = flutter / 'bin/cache/artifacts/engine/android-x64/flutter.jar'
        if not android_jar.is_file() or not flutter_jar.is_file():
            raise RuntimeError('Existing Android36 SDK and Flutter engine JAR required; no download fallback')
        output = self.directory / 'android36'
        self.compile(output, [SOURCE], [android_jar, flutter_jar])
        compiled = output / 'dev/ullmann/lumo/LumoLocalRecognition.class'
        self.assertTrue(compiled.read_bytes().startswith(bytes.fromhex('cafebabe')))
        print('LUMO_LOCAL_RECOGNITION_ANDROID36_COMPILE_PASS genuine_sdk=true no_runtime_claim=true')

    def test_production_boundary_behavior(self):
        configured = Path(os.environ.get('LUMO_JSON_JAR', '/nonexistent'))
        cache = Path(os.environ.get('GRADLE_USER_HOME', Path.home() / '.gradle'))
        candidates = [configured, *cache.glob(
            'caches/modules-2/files-2.1/org.json/json/20240303/*/json-20240303.jar')]
        json_jar = next((p for p in candidates if p.is_file() and
                        hashlib.sha256(p.read_bytes()).hexdigest() == JSON_SHA256), None)
        if json_jar is None:
            raise RuntimeError('Use the existing digest-pinned JSON20240303 JAR; set LUMO_JSON_JAR')
        output = self.directory / 'jvm'
        self.compile(output, [SOURCE, *sorted(FIXTURES.glob('*.kt'))], [json_jar])
        result = subprocess.run([self.java, '-cp', os.pathsep.join(map(str,
                                 [output, self.stdlib, json_jar])),
                                 'dev.ullmann.lumo.LocalRecognitionContractKt'],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertRegex(result.stdout, r'LUMO_LOCAL_RECOGNITION_PASS checks=\d+')
        print(result.stdout, end='')

    def test_pinned_channel_wiring_and_no_remote_constructor(self):
        source = SOURCE.read_text()
        activity = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        prepare = (ROOT / 'scripts/prepare_android.py').read_text()
        lock = (ROOT / 'pubspec.lock').read_text()
        package = re.search(r'^  speech_to_text:\n(.*?)(?=^  \S|\Z)', lock,
                            flags=re.MULTILINE | re.DOTALL)
        self.assertIsNotNone(package)
        self.assertIn('version: "7.5.0"', package.group(1))
        self.assertIn('plugin.csdcorp.com/speech_to_text', source)
        for method in ('initialize', 'has_permission', 'has_on_device_support',
                       'listen', 'stop', 'cancel', 'locales'):
            self.assertIn(f'"{method}" ->', source)
        for event in ('notifyStatus', 'notifyError', 'textRecognition', 'soundLevelChange'):
            self.assertIn(f'"{event}"', source)
        self.assertNotRegex(source, r'\bcreateSpeechRecognizer\s*\(')
        self.assertNotIn('ACTION_GET_LANGUAGE_DETAILS', source)
        self.assertNotIn('triggerModelDownload', source)
        self.assertLess(activity.index('super.configureFlutterEngine(flutterEngine)'),
                        activity.index('localRecognition = LumoLocalRecognition('))
        for hook in ('localRecognition?.setForeground(false)',
                     'localRecognition?.setForeground(true)',
                     'localRecognition?.onRequestPermissionsResult(',
                     'localRecognition?.destroy()'):
            self.assertIn(hook, activity)
        self.assertIn("('LumoLocalRecognition.kt', 'kotlin')", prepare)


if __name__ == '__main__':
    unittest.main()
