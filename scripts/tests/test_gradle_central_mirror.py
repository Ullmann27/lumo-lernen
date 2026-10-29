"""Regression for Actions run 38896179742: throttled Maven Central broke the APK build.

Maven Central answered existing Kotlin artifacts with HTTP 404 + Retry-After
(throttling); Gradle reported "Could not find kotlin-gradle-plugins-bom:2.2.20"
while resolving Flutter's own Gradle plugin build. The build now installs an
init script on CI that puts Google's Maven Central mirror in front of the
declared repositories without changing any version.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / 'scripts' / 'build_unified_apk.sh'
INIT = ROOT / 'scripts' / 'gradle' / 'lumo-maven-central-mirror.init.gradle'
MIRROR = 'https://maven-central.storage-download.googleapis.com/maven2/'


class GradleCentralMirrorTests(unittest.TestCase):
    def test_mirror_is_installed_before_the_first_gradle_invocation(self):
        script = BUILD.read_text()
        install = script.index('cp scripts/gradle/lumo-maven-central-mirror.init.gradle')
        first_gradle = min(script.index('./gradlew'), script.index('flutter build apk'))
        self.assertLess(install, first_gradle)

    def test_mirror_is_only_installed_on_ci_or_explicit_opt_in(self):
        script = BUILD.read_text()
        gate = re.search(
            r'if \[ "\$\{CI:-\}" = true \] \|\| \[ "\$\{LUMO_GRADLE_CENTRAL_MIRROR:-0\}" = 1 \]; then\n'
            r'(?:.*\n){0,3}?\s+cp scripts/gradle/lumo-maven-central-mirror\.init\.gradle', script)
        self.assertIsNotNone(gate, 'local developer builds must keep their own Gradle setup')
        self.assertIn('init.d', script)

    def test_init_script_keeps_declared_repositories_and_versions(self):
        text = INIT.read_text()
        self.assertIn(f"'{MIRROR}'", text)
        self.assertTrue(MIRROR.startswith('https://'))
        # Only the mirror itself may be moved; declared repositories stay.
        self.assertNotIn('.clear()', text)
        self.assertEqual(text.count('repositories.remove('), 1)
        self.assertIn('repositories.remove(mirror)', text)
        # The Flutter plugin build forbids project repositories.
        self.assertIn('RepositoriesMode.PREFER_PROJECT', text)
        # Gradle's implicit plugin portal stays reachable behind the mirror.
        self.assertIn('gradlePluginPortal()', text)
        self.assertNotRegex(text, r'version\s*[:=]')

    @unittest.skipUnless(shutil.which('gradle'), 'Gradle is not installed')
    def test_init_script_runs_and_orders_the_mirror_first(self):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp) / 'gradle-home'
            (home / 'init.d').mkdir(parents=True)
            shutil.copy(INIT, home / 'init.d' / INIT.name)
            build = Path(temp) / 'build'
            build.mkdir()
            (build / 'settings.gradle').write_text(
                "pluginManagement { repositories { google(); mavenCentral() } }\n"
                "rootProject.name = 'mirror-probe'\n")
            (build / 'build.gradle').write_text(
                "repositories { google(); mavenCentral() }\n")
            env = dict(os.environ, GRADLE_USER_HOME=str(home))
            result = subprocess.run(
                ['gradle', '--offline', '--no-daemon', '-q', 'help'],
                cwd=build, env=env, capture_output=True, text=True, timeout=300)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            line = next((l for l in result.stdout.splitlines()
                         if l.startswith('[LumoMavenMirror]')), '')
            self.assertIn('plugins=[LumoMavenCentralMirror, Google, MavenRepo]', line)
            self.assertIn('root=[LumoMavenCentralMirror, Google, MavenRepo]', line)


if __name__ == '__main__':
    unittest.main()
