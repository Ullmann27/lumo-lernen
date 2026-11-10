"""A skipped or incomplete Flutter run must never approve an APK candidate."""
import importlib.util
from pathlib import Path
import unittest

SPEC = importlib.util.spec_from_file_location(
    'acceptance', Path(__file__).resolve().parents[1] / 'run_full_flutter_acceptance.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FullFlutterAcceptanceTests(unittest.TestCase):
    def events(self, **changes):
        return [
            {'type': 'testStart', 'test': {'id': 1, 'name': 'real game round'}},
            dict(type='testDone', testID=1, result='success', skipped=False,
                 hidden=False, **changes),
            {'type': 'done', 'success': True},
        ]

    def test_complete_success_passes(self):
        self.assertEqual(MODULE.summarize(self.events(), 0, [])['status'], 'PASS')

    def test_skipped_test_rejects_candidate_even_when_flutter_exits_zero(self):
        events = self.events()
        events[1]['skipped'] = True
        report = MODULE.summarize(events, 0, [])
        self.assertEqual(report['status'], 'FAIL')
        self.assertEqual(report['skipped'], ['real game round'])

    def test_hidden_compilation_failure_is_not_lost(self):
        events = self.events()
        events.insert(2, {'type': 'testDone', 'testID': 2,
                          'result': 'error', 'hidden': True})
        self.assertEqual(MODULE.summarize(events, 0, [])['status'], 'FAIL')

    def test_missing_runner_completion_rejects_truncated_log(self):
        self.assertEqual(MODULE.summarize(self.events()[:-1], 0, [])['status'], 'FAIL')

    def test_capture_overflow_evidence_rejects_false_green(self):
        self.assertEqual(MODULE.summarize(self.events(), 0, ['phone.error.txt'])['status'], 'FAIL')

    def test_nonzero_process_cannot_be_hidden_by_done_event(self):
        self.assertEqual(MODULE.summarize(self.events(), 1, [])['status'], 'FAIL')


if __name__ == '__main__':
    unittest.main()
