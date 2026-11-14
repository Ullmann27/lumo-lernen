"""Replay original failed Android navigation observations without Android I/O."""

from copy import deepcopy
import ast
import importlib.util
import json
from pathlib import Path
import re
import tempfile
from types import ModuleType, SimpleNamespace
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'c4_navigation_under_test', ROOT / '.github/probes/lumo_connect_four_android_probe.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)
FIXTURES = Path(__file__).parent / 'fixtures/studio_c4_navigation'


def nodes(name):
    return [dict(n.attrib) for n in ET.parse(FIXTURES / name).iter('node')]


class CurrentFlutterNavigation(unittest.TestCase):
    def target(self, values, density=2.625, size=(1080, 2400)):
        return MODULE.flutter_hub_navigation_target(values, size, density)

    def test_both_original_paused_cards_pages_require_their_visible_exit(self):
        for api in (35, 37):
            with self.subTest(api=api):
                value = self.target(nodes(f'api{api}-paused.xml'))
                self.assertEqual(value['action'], 'leave_paused_game')
                self.assertEqual(value['caption'], 'Zur Spieleauswahl')

    def test_both_actual_failure_pages_require_showcase_back_instead_of_hidden_tabs(self):
        for api in (35, 37):
            with self.subTest(api=api):
                value = self.target(nodes(f'api{api}-showcase.xml'))
                self.assertEqual(value['action'], 'leave_cards_showcase')
                self.assertEqual(value['caption'], 'Zur Spielwelt zurück')
                self.assertEqual(value['bounds'], [32, 157, 158, 283])

    def test_original_home_and_hub_are_distinct_current_routes(self):
        self.assertEqual(self.target(nodes('api35-home.xml'))['action'], 'open_games_tab')
        self.assertEqual(self.target(nodes('api35-hub.xml')), {'action': 'hub_ready'})

    def test_hidden_disabled_foreign_and_undersized_back_controls_cannot_pass(self):
        source = nodes('api35-showcase.xml')
        for change in ({'clickable': 'false'}, {'enabled': 'false'},
                       {'package': 'foreign.app'}, {'bounds': '[32,157][157,283]'}):
            with self.subTest(change=change):
                values = deepcopy(source)
                for node in values:
                    if node.get('content-desc') == 'Zur Spielwelt zurück':
                        node.update(change)
                self.assertIsNone(self.target(values))
        self.assertIsNone(self.target(source, density=3))
        self.assertIsNone(self.target(source, size=(120, 2400)))

    def test_ambiguous_target_and_unknown_page_are_rejected(self):
        values = nodes('api35-showcase.xml')
        other = deepcopy(next(n for n in values if n.get('content-desc') == 'Zur Spielwelt zurück'))
        other['bounds'] = '[200,157][326,283]'
        values.append(other)
        with self.assertRaisesRegex(RuntimeError, 'Ambiguous'):
            self.target(values)
        self.assertIsNone(self.target([]))


def actual_hub_helper():
    """Load the production selector without its unrelated Android dependencies."""
    source = (ROOT / '.github/probes/studio_creative_android_probe.py').read_text()
    definitions = [node for node in ast.parse(source).body
                   if isinstance(node, ast.FunctionDef)
                   and node.name in {'require', 'bounds', 'hub_choice'}]
    if len(definitions) != 3:
        raise AssertionError('Actual hub selector dependencies changed')
    namespace = {'PACKAGE': MODULE.PACKAGE, 're': re}
    exec(compile(ast.Module(body=definitions, type_ignores=[]),
                 'actual-studio-hub-selector', 'exec'), namespace)
    return SimpleNamespace(**{name: namespace[name]
                              for name in ('bounds', 'hub_choice')})


class HubTransportReplay:
    """Only transport/size are doubled; selectors use byte-identical original XML.

    This is a Python control-flow replay, not an Android run or screenshot OCR.
    The original top viewport transitions to the actual 0006 viewport after the
    first recorded swipe. Negative variants change only the subsequent read.
    """
    def __init__(self, output, *, changed_target=False, changed_viewport=False,
                 changed_activity=False, failed_swipe=False):
        self.top = nodes('api35-28462-hub-top.xml')
        self.visible = nodes('api35-28462-c4-visible.xml')
        self.changed_target = changed_target
        self.changed_viewport = changed_viewport
        self.changed_activity = changed_activity
        self.failed_swipe = failed_swipe
        self.swipes = 0
        self.trace = []
        self.last_nodes = ''
        self.last_nodes_visible = False
        self.subject = MODULE.AndroidProbe.__new__(MODULE.AndroidProbe)
        self.subject.out = output
        self.subject.count = 0
        self.subject.events = []
        self.subject.density = 2.625
        self.subject.creative = actual_hub_helper()
        self.subject.live = SimpleNamespace(live_nodes=self.read_nodes)
        self.subject.probe = SimpleNamespace(capture=self.capture)
        self.subject.surfaces = SimpleNamespace(resumed_activity=self.activity)
        self.subject.adb = self.adb

    def read_nodes(self, output, tag):
        self.last_nodes = tag
        self.last_nodes_visible = bool(self.swipes)
        self.trace.append(('nodes', tag))
        values = deepcopy(self.visible if self.swipes else self.top)
        if 'actual-c4-hub' in tag and tag.endswith('-confirmed'):
            for node in values:
                if self.changed_target and node.get('content-desc', '').startswith('Lumo 4 Gewinnt. '):
                    node['bounds'] = '[43,1072][525,1536]'
                if self.changed_viewport and node.get('scrollable') == 'true':
                    node['bounds'] = '[1,136][1080,1993]'
        hierarchy = ET.Element('hierarchy')
        for value in values:
            ET.SubElement(hierarchy, 'node', value)
        ET.ElementTree(hierarchy).write(output / (tag + '.xml'), encoding='utf-8')
        return values

    def capture(self, output, tag, **kwargs):
        self.trace.append(('capture', tag))
        return {'file': tag + '.png'}

    def activity(self):
        value = 'MainActivity'
        if (self.changed_activity and self.last_nodes_visible
                and 'actual-c4-hub' in self.last_nodes
                and self.last_nodes.endswith('-confirmed')):
            value = 'ConnectFourGameActivity'
        self.trace.append(('activity', value))
        return value

    def adb(self, *args, **kwargs):
        self.trace.append(('adb', args))
        if args[:3] == ('shell', 'input', 'swipe'):
            if self.failed_swipe:
                raise RuntimeError('Recorded transport failure')
            self.swipes += 1
        return ''

    def run(self):
        class OriginalScreenSize:
            size = (1080, 2400)

            def __enter__(self):
                return self

            def __exit__(self, *args):
                return False

        pil = ModuleType('PIL')
        pil.Image = SimpleNamespace(open=lambda _: OriginalScreenSize())
        with patch.dict('sys.modules', {'PIL': pil}), patch.object(MODULE.time, 'sleep'):
            self.subject.navigate()


class CurrentC4HubNavigation(unittest.TestCase):
    def test_original_visible_caption_resolves_only_its_current_interactive_tile(self):
        helper = actual_hub_helper()
        original = nodes('api35-28462-c4-visible.xml')
        expected = {'caption': 'Lumo 4 Gewinnt. Vier in einer Reihe · gegen Lumo oder zu zweit Spielen',
                    'bounds': [42, 1072, 524, 1536]}
        self.assertEqual(helper.hub_choice(original, 'Lumo 4 Gewinnt', (1080, 2400), 126), expected)
        self.assertIsNone(helper.hub_choice(original, 'Vier gewinnt', (1080, 2400), 126))
        for change in ({'package': 'foreign.app'}, {'enabled': 'false'},
                       {'clickable': 'false'}, {'bounds': '[42,1072][167,1536]'},
                       {'content-desc': 'Vier gewinnt. Vier in einer Reihe Spielen'}):
            with self.subTest(change=change):
                values = deepcopy(original)
                for node in values:
                    if node.get('content-desc') == expected['caption']:
                        node.update(change)
                self.assertIsNone(helper.hub_choice(values, 'Lumo 4 Gewinnt', (1080, 2400), 126))

    def test_original_top_to_visible_replay_records_scroll_and_fresh_confirmed_tap(self):
        with tempfile.TemporaryDirectory() as directory:
            replay = HubTransportReplay(Path(directory))
            replay.run()
            self.assertEqual(replay.swipes, 1)
            events = json.loads((Path(directory) / 'input-events.json').read_text())
            self.assertEqual([event['kind'] for event in events],
                             ['actual_hub_scroll', 'actual_hub_touch'])
            scroll, touch = events
            self.assertEqual(scroll['viewport_bounds'], [0, 136, 1080, 1993])
            self.assertEqual((scroll['start'], scroll['end'], scroll['duration_ms']),
                             ([540, 1529], [540, 600], 450))
            self.assertIs(scroll['adb_completed'], True)
            self.assertEqual(touch['target']['bounds'], [42, 1072, 524, 1536])
            self.assertEqual(touch['point'], [283, 1304])
            self.assertTrue((Path(directory) / touch['confirmed_xml']).is_file())
            self.assertEqual(replay.trace[-3:],
                             [('nodes', touch['confirmed_xml'][:-4]),
                              ('activity', 'MainActivity'),
                              ('adb', ('shell', 'input', 'tap', '283', '1304'))])

    def test_changed_tile_between_capture_and_confirmation_is_never_tapped(self):
        with tempfile.TemporaryDirectory() as directory:
            replay = HubTransportReplay(Path(directory), changed_target=True)
            with self.assertRaisesRegex(RuntimeError, 'tile never appeared'):
                replay.run()
            self.assertEqual(replay.swipes, 1)
            self.assertFalse(any(event['kind'] == 'actual_hub_touch'
                                 for event in replay.subject.events))

    def test_changed_foreground_after_fresh_ui_read_prevents_tap(self):
        with tempfile.TemporaryDirectory() as directory:
            replay = HubTransportReplay(Path(directory), changed_activity=True)
            with self.assertRaisesRegex(RuntimeError, 'activity changed during observation'):
                replay.run()
            self.assertFalse(any(event['kind'] == 'actual_hub_touch'
                                 for event in replay.subject.events))

    def test_failed_swipe_keeps_attempt_unconfirmed_and_stops(self):
        with tempfile.TemporaryDirectory() as directory:
            replay = HubTransportReplay(Path(directory), failed_swipe=True)
            with self.assertRaisesRegex(RuntimeError, 'Recorded transport failure'):
                replay.run()
            events = json.loads((Path(directory) / 'input-events.json').read_text())
            self.assertEqual(len(events), 1)
            self.assertEqual(events[0]['kind'], 'actual_hub_scroll')
            self.assertIs(events[0]['adb_completed'], False)
            self.assertEqual(replay.swipes, 0)

    def test_changed_scroll_viewport_is_never_used_for_input(self):
        with tempfile.TemporaryDirectory() as directory:
            replay = HubTransportReplay(Path(directory), changed_viewport=True)
            with self.assertRaisesRegex(RuntimeError, 'tile never appeared'):
                replay.run()
            self.assertEqual(replay.swipes, 0)
            self.assertEqual(replay.subject.events, [])


if __name__ == '__main__':
    unittest.main()
