"""The 2052 tour must run Godot on an emulator GL that can link its shaders.

Run 44473804677 used ``-gpu swiftshader_indirect``. Its logcat shows
``CanvasShaderGLES3: Program linking failed: Fragment shader active uniforms
exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`` and every Godot screenshot was the
project clear colour only, so the Kart tour could not find a single button.
The other Android tours run ``-gpu host`` on Mesa llvmpipe; this contract keeps
the test-APK tour on that path.
"""
from pathlib import Path
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[3]
WORKFLOW = ROOT / '.github/workflows/lumo-test-apk.yml'


class TestApkTourRenderer(unittest.TestCase):
    def setUp(self):
        self.job = yaml.safe_load(WORKFLOW.read_text())['jobs']['android-tour']
        self.steps = self.job['steps']
        self.emulator = next(step for step in self.steps
                             if str(step.get('uses', '')).startswith('reactivecircus/android-emulator-runner'))

    def test_emulator_uses_host_gl_not_swiftshader(self):
        options = self.emulator['with']['emulator-options']
        self.assertIn('-gpu host', options)
        self.assertNotIn('swiftshader', options)

    def test_host_gl_is_mesa_llvmpipe_on_a_virtual_display(self):
        env = self.emulator['env']
        self.assertEqual(env['DISPLAY'], ':99')
        self.assertEqual(env['GALLIUM_DRIVER'], 'llvmpipe')
        self.assertEqual(env['LIBGL_ALWAYS_SOFTWARE'], 'true')
        index = self.steps.index(self.emulator)
        display = [step for step in self.steps[:index] if 'Xvfb :99' in str(step.get('run', ''))]
        self.assertEqual(len(display), 1, 'Xvfb must start before the emulator')
        self.assertIn("grep -Fi 'llvmpipe'", display[0]['run'])
        prepare = next(step for step in self.steps if step.get('name') == 'Emulator und Prüftools vorbereiten')
        for package in ('xvfb', 'mesa-utils', 'libgl1-mesa-dri', 'libglx-mesa0'):
            self.assertIn(package, prepare['run'])

    def test_renderer_evidence_is_uploaded_with_the_tour(self):
        upload = self.steps[-1]
        self.assertIn('tour/', upload['with']['path'].splitlines())
        display = next(step for step in self.steps if 'Xvfb :99' in str(step.get('run', '')))
        self.assertIn('tour/mesa-renderer.txt', display['run'])

    def test_software_rendering_has_time(self):
        self.assertGreaterEqual(self.job['timeout-minutes'], 70)


if __name__ == '__main__':
    unittest.main()
