"""Replay real Android hierarchy boundaries; not a substitute for a live tour.

The closed academy XML is unchanged from run 43368260144, artifact 14014710846,
nextgen/guided-hub-19--1-0.xml, APK source 8f2925b2. The course card fixture is
the previously recorded Android 1933 hierarchy. No app progress is fabricated.
"""
import ast
import json
from pathlib import Path
import re
import tempfile
import types
import unittest
from unittest.mock import Mock
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[3]
PROBE = ROOT / '.github/probes/lumo_nextgen_surfaces_android_probe.py'
COURSES = ROOT / '.github/probes/lumo_education_android_probe.py'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CLOSED = Path(__file__).parent / 'fixtures/android_2018_academy_tools_closed.xml'
HUB = ROOT / 'scripts/tests/fixtures/android_1933_course_hub.xml'


def functions(path, names):
    body = [node for node in ast.parse(path.read_text()).body
            if isinstance(node, ast.FunctionDef) and node.name in names]
    return compile(ast.Module(body=body, type_ignores=[]), str(path), 'exec')


class NextgenLearningRouteTests(unittest.TestCase):
    def setUp(self):
        self.closed = [node.attrib for node in ET.parse(CLOSED).iter('node')]
        self.hub = [node.attrib for node in ET.parse(HUB).iter('node')]
        self.adb = Mock()
        existing = types.SimpleNamespace(
            PACKAGE=PACKAGE, live=types.SimpleNamespace(live_nodes=Mock(return_value=self.hub)),
            base=types.SimpleNamespace(adb=self.adb), capture=Mock())
        self.course_scope = {'existing': existing, 're': re, 'Path': Path, 'json': json,
                             'time': types.SimpleNamespace(sleep=lambda _: None)}
        exec(functions(COURSES, {'_enabled_control_bounds', 'tap_named_course'}), self.course_scope)

    def test_recorded_closed_academy_requires_the_visible_tools_toggle(self):
        select = self.course_scope['_enabled_control_bounds']
        self.assertEqual(select(self.closed, 'Lernwerkzeuge & Geschichten'), [89, 1034, 991, 1170])
        self.assertIsNone(select(self.closed, 'Lumo erklärt es mir'))

    def test_real_route_opens_tools_then_the_named_course_action(self):
        tools_open = False
        hub_open = False

        def tap(_out, captions, _tag):
            nonlocal tools_open, hub_open
            caption = captions[0]
            if caption == 'Lernen':
                self.assertIsNotNone(self.course_scope['_enabled_control_bounds'](self.closed, caption))
            elif caption == 'Lernwerkzeuge & Geschichten':
                self.assertIsNotNone(self.course_scope['_enabled_control_bounds'](self.closed, caption))
                tools_open = True
            elif caption == 'Lumo erklärt es mir':
                if not tools_open:
                    raise RuntimeError('Recorded academy tools are closed')
                hub_open = True
            else:
                raise RuntimeError('Cannot tap a static course heading: ' + caption)

        class ObservedLessonStart(Exception):
            pass

        def see(_out, caption, _tag):
            if caption == 'Dein Lernatelier':
                self.assertTrue(tools_open)
            elif caption == 'Über den Zehner':
                self.assertTrue(hub_open)
                self.assertTrue(any(caption in node.get('content-desc', '').splitlines()
                                    for node in self.hub))
            elif caption == 'Heute lernen wir einen Rechentrick':
                self.adb.assert_called_once_with('shell', 'input', 'swipe',
                                                '600', '405', '600', '405', '120')
                raise ObservedLessonStart()
            else:
                self.fail('Unexpected state before the actual course action: ' + caption)

        scope = {'Path': Path, 'tap_flutter': tap, 'must_see': see,
                 'education': types.SimpleNamespace(tap_named_course=self.course_scope['tap_named_course'])}
        exec(functions(PROBE, {'learning_roundtrip'}), scope)
        with tempfile.TemporaryDirectory() as folder, self.assertRaises(ObservedLessonStart):
            scope['learning_roundtrip'](Path(folder))

    def test_named_course_never_taps_the_static_heading_or_other_course(self):
        self.assertIsNone(self.course_scope['_enabled_control_bounds'](self.hub, 'Über den Zehner'))
        with tempfile.TemporaryDirectory() as folder:
            self.course_scope['tap_named_course'](Path(folder), 'Über den Zehner', 'bridge')
            selected = json.loads((Path(folder) / 'bridge-actual-target.json').read_text())
        self.assertEqual(selected['courseTitle'], 'Über den Zehner')
        self.assertEqual(selected['buttonBounds'], [35, 377, 1165, 433])
        self.adb.assert_called_once_with('shell', 'input', 'swipe', '600', '405', '600', '405', '120')

    def return_scope(self, *, native_alive=False):
        def wait(_description, observe, accept, **_options):
            value = observe()
            if not accept(value):
                raise RuntimeError('Native activity has not returned to Flutter')
            return value
        education = types.SimpleNamespace(wait_text=Mock())
        capture = Mock()
        scope = {'Path': Path, 'wait_for': wait,
                 'tour': types.SimpleNamespace(godot_alive=lambda: native_alive, alive=lambda: True),
                 'resumed_activity': lambda: 'MainActivity',
                 'education': education, 'probe': types.SimpleNamespace(capture_flutter_ready=capture),
                 'must_see': Mock(side_effect=RuntimeError('Actual saved title is above the viewport'))}
        exec(functions(PROBE, {'returned_to_flutter'}), scope)
        return scope, education, capture

    def test_lesson_return_scrolls_to_exact_preserved_title_before_capturing(self):
        # Actual 412x915 widget geometry at native launch placed the retained
        # title at y=-90.5..-56.5 while its real 3D button was y=491..547.
        # Derive this call's options from production so omission reproduces the
        # offscreen-observation error instead of assuming a new default.
        lesson = next(node for node in ast.parse(PROBE.read_text()).body
                      if isinstance(node, ast.FunctionDef) and node.name == 'learning_roundtrip')
        call = next(node for node in ast.walk(lesson) if isinstance(node, ast.Call)
                    and isinstance(node.func, ast.Name) and node.func.id == 'returned_to_flutter')
        options = {item.arg: ast.literal_eval(item.value) for item in call.keywords}
        scope, education, capture = self.return_scope()
        scope['returned_to_flutter'](Path('/fixture'), 'Acht und fünf', 'same-lesson', **options)
        education.wait_text.assert_called_once_with(Path('/fixture'), 'Acht und fünf',
                                                   'same-lesson', timeout=45, scroll=True)
        scope['must_see'].assert_not_called()
        capture.assert_called_once_with(Path('/fixture'), 'same-lesson')

    def test_scrolling_cannot_replace_actual_native_exit_and_flutter_resume(self):
        scope, education, capture = self.return_scope(native_alive=True)
        with self.assertRaisesRegex(RuntimeError, 'has not returned'):
            scope['returned_to_flutter'](Path('/fixture'), 'Acht und fünf', 'same-lesson')
        education.wait_text.assert_not_called()
        capture.assert_not_called()


if __name__ == '__main__':
    unittest.main()
