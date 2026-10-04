"""An empty Navigator transition is not a settled non-scrollable page."""
from pathlib import Path
import sys
import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from flutter_flows import FlutterChecks


def visible(caption='Plus bis 10'):
    root = ET.Element('hierarchy')
    ET.SubElement(root, 'node', {'content-desc': caption, 'bounds': '[20,379][460,470]'})
    return root


class ReturnTransitionTests(unittest.TestCase):
    def checks(self, frames):
        checks = FlutterChecks(Mock(), Path('/unused'), 'dev.ullmann.lumo.lumo_lernen.coachpreview')
        checks.frame = Mock(side_effect=frames)
        checks.record = Mock()
        checks.scroll = Mock(return_value=True)
        return checks

    def test_empty_transition_is_observed_without_input_before_real_scroll(self):
        blank, actual = ET.Element('hierarchy'), visible()
        checks = self.checks([blank, actual, actual, actual, actual])
        with patch('flutter_flows.time.sleep'), patch('flutter_flows.time.monotonic', return_value=0):
            checks.top()
        self.assertEqual(checks.frame.call_count, 5)
        self.assertEqual(checks.scroll.call_count, 4)
        self.assertTrue(all(call.args[0] is actual and call.kwargs == {'down': False}
                            for call in checks.scroll.call_args_list))
        checks.device.key.assert_not_called()
        checks.record.assert_called_once_with('await_visible_flutter_content')

    def test_settled_non_scrollable_content_keeps_existing_behavior(self):
        checks = self.checks([visible()])
        checks.scroll.return_value = False
        checks.top()
        checks.scroll.assert_called_once()
        checks.record.assert_not_called()

    def test_permanently_empty_content_times_out_without_any_input(self):
        checks = self.checks([ET.Element('hierarchy')])
        with patch('flutter_flows.time.sleep'), patch('flutter_flows.time.monotonic',
                side_effect=[0, 0, 0, 46]):
            with self.assertRaisesRegex(RuntimeError, 'bounded top-scroll'):
                checks.top()
        checks.scroll.assert_not_called()
        checks.device.key.assert_not_called()

    def test_late_content_cannot_pass_after_deadline(self):
        checks = self.checks([visible()])
        with patch('flutter_flows.time.monotonic', side_effect=[0, 0, 46]):
            with self.assertRaisesRegex(RuntimeError, 'bounded top-scroll'):
                checks.top()
        checks.scroll.assert_not_called()


if __name__ == '__main__':
    unittest.main()
