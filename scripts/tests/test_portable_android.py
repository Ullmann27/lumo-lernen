"""Contract of the GitHub-independent Android entry point and its Godot download."""
import os
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PORTABLE = ROOT / 'scripts/portable-android.sh'
GODOT = ROOT / 'scripts/install_godot_for_build.sh'


def run(*args, env=None):
    return subprocess.run(['bash', str(PORTABLE), *args], cwd=ROOT, env=env,
                          capture_output=True, text=True, timeout=300)


class PortableAndroidTests(unittest.TestCase):
    def test_scripts_parse(self):
        for script in (PORTABLE, GODOT):
            with self.subTest(script=script.name):
                subprocess.run(['bash', '-n', str(script)], check=True)

    def test_unknown_mode_prints_usage(self):
        result = run('build-everything')
        self.assertEqual(result.returncode, 2)
        self.assertIn('doctor|tests|godot-tests|preview-apk', result.stderr)

    def test_doctor_reports_a_missing_sdk_and_builds_nothing(self):
        env = dict(os.environ, ANDROID_SDK_ROOT='/nonexistent/lumo-sdk', ANDROID_HOME='')
        result = run('doctor', env=env)
        self.assertEqual(result.returncode, 3, result.stdout + result.stderr)
        self.assertIn('[doctor] FAIL  ANDROID_SDK_ROOT or ANDROID_HOME', result.stdout)
        self.assertIn('nothing was built', result.stderr)

    def test_preview_build_runs_every_gate_before_and_after_the_apk(self):
        body = PORTABLE.read_text()
        preview = body[body.index('  preview-apk)'):]
        order = ['doctor android', 'clean_source', 'run_tests', 'run_godot_tests',
                 'install_ndk_for_build.sh', 'build_unified_apk.sh', 'verify_unified_apk.py',
                 'source_unchanged build', 'write_evidence']
        positions = [preview.index(step) for step in order]
        self.assertEqual(positions, sorted(positions))
        self.assertIn("'device_test': 'NOT EXECUTED", body)

    def test_godot_archive_is_checked_before_it_is_unpacked(self):
        body = GODOT.read_text()
        self.assertRegex(body, re.compile(r"GODOT_ZIP_SHA256='[0-9a-f]{64}'"))
        self.assertLess(body.index('sha256sum -c'), body.index('unzip -qo'))


if __name__ == '__main__':
    unittest.main()
