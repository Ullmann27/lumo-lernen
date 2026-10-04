"""A transient empty Semantics snapshot must not fail a real tap (run 37181279924)."""
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from flutter_flows import FlutterChecks
from android_ui import Android


def empty_flutter_view():
    # Exact shape of flutter-022-find-control.xml: app window, no semantics.
    root = ET.Element('hierarchy')
    window = ET.SubElement(root, 'node', {'bounds': '[0,0][480,800]'})
    ET.SubElement(window, 'node', {'bounds': '[0,0][480,800]'})
    return root


def answers():
    root = ET.Element('hierarchy')
    for caption, bounds in (('3 + 5 = ?', '[20,200][460,300]'), ('6', '[20,637][234,756]')):
        ET.SubElement(root, 'node', {'content-desc': caption, 'bounds': bounds, 'clickable': 'true'})
    return root


class EmptySemanticsTests(unittest.TestCase):
    def checks(self, frames):
        checks = FlutterChecks(Mock(), Path('/unused'), 'dev.ullmann.lumo.lumo_lernen.coachpreview')
        checks.device.bounds = Android.bounds
        checks.frame = Mock(side_effect=frames)
        checks.record = Mock()
        checks.scroll = Mock(return_value=False)
        return checks

    def test_transient_empty_frame_is_reobserved_then_tapped(self):
        checks = self.checks([empty_flutter_view(), empty_flutter_view(), answers()])
        with patch('flutter_flows.time.sleep'):
            checks.click('6', scroll=True)
        self.assertEqual(checks.frame.call_count, 3)
        checks.device.tap.assert_called_once_with(127, 696)
        checks.scroll.assert_not_called()
        self.assertEqual([c.args[0] for c in checks.record.call_args_list],
                         ['await_visible_flutter_content', 'await_visible_flutter_content', 'real_flutter_touch'])

    def test_permanently_empty_ui_still_fails_without_input(self):
        checks = self.checks([empty_flutter_view()] * (FlutterChecks.EMPTY_FRAME_RETRIES + 1))
        with patch('flutter_flows.time.sleep'):
            with self.assertRaisesRegex(RuntimeError, "control absent: '6'"):
                checks.click('6', scroll=True)
        self.assertEqual(checks.frame.call_count, FlutterChecks.EMPTY_FRAME_RETRIES + 1)
        checks.device.tap.assert_not_called()
        checks.device.swipe.assert_not_called()

    def test_visible_frame_needs_no_extra_observation(self):
        checks = self.checks([answers()])
        checks.click('6')
        self.assertEqual(checks.frame.call_count, 1)
        checks.device.tap.assert_called_once()


if __name__ == '__main__':
    unittest.main()
