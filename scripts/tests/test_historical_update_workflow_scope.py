"""Route the immutable 1997-to-1999 APK check only to its original branch."""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / '.github/workflows/lumo-1999-update-gate.yml'
LEGACY_BRANCH = 'repair/lumo-1999-update-learning-hub-20261026'
REPOSITORY = 'Ullmann27/lumo-lernen'


class HistoricalUpdateWorkflowScopeTests(unittest.TestCase):
    def accepts(self, **changes):
        job = WORKFLOW.read_text().split('  update-and-tour:\n', 1)[1]
        header = job.split('    runs-on:', 1)[0]
        self.assertIn('    if: >-\n', header,
                      'Historical APKs must not be checked against unrelated app versions')
        expression = header.split('    if: >-\n', 1)[1]
        expression = expression.replace('\n', ' ').replace('&&', 'and').replace('||', 'or').strip()
        values = {
            'github.repository': REPOSITORY,
            'github.event_name': 'pull_request',
            'github.event.pull_request.head.repo.full_name': REPOSITORY,
            'github.event.pull_request.head.ref': LEGACY_BRANCH,
            'github.ref_name': '350/merge',
        }
        values.update(changes)
        for key in sorted(values, key=len, reverse=True):
            expression = expression.replace(key, repr(values[key]))
        return eval(expression, {'__builtins__': {}}, {})

    def test_original_pull_request_and_manual_branch_run_remain_available(self):
        self.assertTrue(self.accepts())
        self.assertTrue(self.accepts(**{
            'github.event_name': 'workflow_dispatch',
            'github.event.pull_request.head.repo.full_name': '',
            'github.event.pull_request.head.ref': '',
            'github.ref_name': LEGACY_BRANCH,
        }))

    def test_new_candidates_forks_and_unrelated_events_do_not_run_old_apks(self):
        cases = [
            {'github.event.pull_request.head.ref': 'chatgpt/lumo-nextgen-20261113'},
            {'github.event.pull_request.head.ref': 'integration/lumo-connections-20261113'},
            {'github.event.pull_request.head.ref': 'main'},
            {'github.event.pull_request.head.ref': LEGACY_BRANCH + '-other'},
            {'github.event.pull_request.head.repo.full_name': 'other/lumo-lernen'},
            {'github.repository': 'other/lumo-lernen'},
            {'github.event_name': 'push', 'github.ref_name': LEGACY_BRANCH},
            {'github.event_name': 'workflow_run', 'github.ref_name': LEGACY_BRANCH},
            {'github.event_name': 'workflow_dispatch', 'github.ref_name': 'main'},
            {'github.event_name': 'workflow_dispatch',
             'github.ref_name': 'chatgpt/lumo-nextgen-20261113'},
        ]
        for case in cases:
            with self.subTest(context=case):
                self.assertFalse(self.accepts(**case))


if __name__ == '__main__':
    unittest.main()
