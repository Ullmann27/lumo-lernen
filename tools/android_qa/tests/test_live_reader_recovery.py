"""Replay incomplete reader transport; these are not new Android acceptance runs."""
from __future__ import annotations

import ast
from http.client import RemoteDisconnected
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[3]
XML = '<hierarchy><node package="dev.lumo.fixture" text="L"/></hierarchy>'


def truncated_json() -> json.JSONDecodeError:
    # Same exception and unterminated result string as the original 2077 run;
    # the incomplete network payload itself was not retained in that run.
    try:
        json.loads('{"jsonrpc":"2.0","id":1,"result":"<hierarchy>')
    except json.JSONDecodeError as error:
        return error
    raise AssertionError('Fixture must be an incomplete JSON response')


class LiveReaderRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.out = Path(self.temp.name)
        self.calls = []
        self.broken = False
        self.always_broken = False
        self.transport_error = truncated_json
        self.xml = XML
        self.device = SimpleNamespace(
            dump_hierarchy=self.dump_hierarchy,
            stop_uiautomator=self.stop_reader,
            start_uiautomator=self.start_reader,
            jsonrpc=SimpleNamespace(
                setConfigurator=self.configure,
                getConfigurator=lambda: {'waitForIdleTimeout':0, 'waitForSelectorTimeout':0}),
        )
        self.connect = Mock(return_value=self.device)
        reader_path = ROOT / 'scripts/probes/pr207_android_ui_probe.py'
        spec = importlib.util.spec_from_file_location('reader_recovery_under_test', reader_path)
        self.reader = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {
                'uiautomator2':SimpleNamespace(connect=self.connect),
                'pr207_android_smoke':SimpleNamespace(tap_label=self.forbidden_input)}):
            spec.loader.exec_module(self.reader)
        # Execute the exact production retry wrapper with the actual adapter.
        # Only the external Android transport is substituted, never the parser.
        source = ROOT / '.github/probes/creative_android_probe.py'
        function = next(node for node in ast.parse(source.read_text()).body
                        if isinstance(node, ast.FunctionDef) and node.name == 'read_live_nodes')
        scope = {'Path':Path, 'json':json, 'RemoteDisconnected':RemoteDisconnected,
                 '_original_live_nodes':self.reader.live_nodes, 'live':self.reader,
                 'time':SimpleNamespace(sleep=lambda seconds:self.calls.append(('sleep',seconds)))}
        exec(compile(ast.Module(body=[function], type_ignores=[]), str(source), 'exec'), scope)
        self.read = scope['read_live_nodes']

    def forbidden_input(self, *_args, **_kwargs):
        raise AssertionError('Reader recovery must not issue application input')

    def configure(self, value):
        self.assertEqual(value, {'waitForIdleTimeout':0, 'waitForSelectorTimeout':0})
        self.calls.append(('configure',))

    def dump_hierarchy(self, **kwargs):
        self.assertEqual(kwargs, {'compressed':False, 'pretty':False})
        self.calls.append(('read',))
        if self.broken:
            raise self.transport_error()
        return self.xml

    def stop_reader(self):
        self.calls.append(('stop',))

    def start_reader(self):
        self.calls.append(('start',))
        self.broken = self.always_broken

    def test_complete_live_read_keeps_original_parser_without_recovery(self):
        nodes = self.read(self.out, 'onboard-name')
        self.assertEqual(nodes[0].get('text'), 'L')
        self.assertEqual((self.out/'onboard-name.xml').read_text(), XML)
        self.assertFalse((self.out/'ui-reader-recovery.json').exists())
        self.assertEqual(self.calls, [('configure',), ('read',)])

    def test_truncated_json_restarts_the_owned_server_and_reads_fresh_xml(self):
        self.broken = True
        (self.out/'onboard-name.xml').write_text('<hierarchy><node text="stale"/></hierarchy>')
        nodes = self.read(self.out, 'onboard-name')
        self.assertEqual(nodes[0].get('text'), 'L')
        self.assertEqual((self.out/'onboard-name.xml').read_text(), XML)
        self.connect.assert_called_once_with()
        self.assertEqual(self.calls, [('configure',), ('read',), ('stop',), ('start',),
                                     ('configure',), ('sleep',1), ('read',)])
        events = json.loads((self.out/'ui-reader-recovery.json').read_text())
        self.assertEqual(len(events), 1)
        self.assertEqual(events[0]['error_type'], 'JSONDecodeError')
        self.assertTrue(events[0]['reader_restarted'])
        self.assertTrue(events[0]['retry'])

    def test_remote_disconnect_uses_the_same_bounded_reader_recovery(self):
        self.broken = True
        self.transport_error = lambda:RemoteDisconnected('reader disconnected')
        self.assertEqual(self.read(self.out, 'remote')[0].get('text'), 'L')
        self.assertEqual(self.calls.count(('read',)), 2)
        self.assertEqual(self.calls.count(('start',)), 1)

    def test_persistent_transport_error_still_fails_after_exactly_three_reads(self):
        self.broken = self.always_broken = True
        stale = '<hierarchy><node text="never accept this old observation"/></hierarchy>'
        (self.out/'persistent.xml').write_text(stale)
        with self.assertRaises(json.JSONDecodeError):
            self.read(self.out, 'persistent')
        self.assertEqual(self.calls.count(('read',)), 3)
        self.assertEqual(self.calls.count(('start',)), 2)
        self.assertEqual((self.out/'persistent.xml').read_text(), stale)
        events = json.loads((self.out/'ui-reader-recovery.json').read_text())
        self.assertEqual([event['attempt'] for event in events], [1,2,3])
        self.assertEqual([event['reader_restarted'] for event in events], [True,True,False])
        self.assertEqual([event['retry'] for event in events], [True,True,False])

    def test_wrong_xml_root_still_fails_without_reader_restart(self):
        self.xml = '<not-a-hierarchy><node text="L"/></not-a-hierarchy>'
        with self.assertRaisesRegex(RuntimeError, 'Unexpected live accessibility hierarchy root'):
            self.read(self.out, 'wrong-root')
        self.assertEqual(self.calls.count(('read',)), 1)
        self.assertNotIn(('start',), self.calls)

    def test_incomplete_xml_still_fails_without_inventing_nodes(self):
        self.xml = '<hierarchy><node text="L"'
        with self.assertRaises(ET.ParseError):
            self.read(self.out, 'bad-xml')
        self.assertEqual(self.calls.count(('read',)), 1)
        self.assertNotIn(('start',), self.calls)

    def test_failed_server_restart_does_not_authorize_another_read(self):
        self.broken = True
        self.device.start_uiautomator = Mock(side_effect=RuntimeError('reader did not restart'))
        with self.assertRaisesRegex(RuntimeError, 'reader did not restart'):
            self.read(self.out, 'restart-failed')
        self.assertEqual(self.calls.count(('read',)), 1)
        self.assertFalse((self.out/'restart-failed.xml').exists())
        event = json.loads((self.out/'ui-reader-recovery.json').read_text())[0]
        self.assertFalse(event['reader_restarted'])

    def test_configuration_is_restored_after_restart_before_fresh_read(self):
        self.broken = True
        self.read(self.out, 'configured')
        config = json.loads((self.out/'uiautomator-config.json').read_text())
        self.assertEqual(config, {'waitForIdleTimeout':0, 'waitForSelectorTimeout':0})
        self.assertLess(self.calls.index(('start',)), len(self.calls)-2)
        self.assertEqual(self.calls[-3:], [('configure',), ('sleep',1), ('read',)])


if __name__ == '__main__':
    unittest.main()
