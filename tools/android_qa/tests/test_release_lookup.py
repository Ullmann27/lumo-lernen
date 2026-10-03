import json
from pathlib import Path
import sys
import unittest
from unittest.mock import call, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from release_lookup import resolve_draft

REPOSITORY = 'Ullmann27/lumo-lernen'
TAG = 'unified-build-275'


class DraftReleaseLookupTest(unittest.TestCase):
    def test_unpublished_tag_resolves_by_id_and_returns_fresh_assets(self):
        draft = {'id': 402391903, 'tag_name': TAG, 'draft': True}
        fresh = {**draft, 'assets': [{'id': 42, 'name': 'proof.zip'}]}
        with patch('release_lookup._get', side_effect=[[draft], fresh]) as get:
            self.assertEqual(resolve_draft(REPOSITORY, TAG), fresh)
        self.assertEqual(get.call_args_list, [
            call(f'repos/{REPOSITORY}/releases?per_page=100&page=1'),
            call(f'repos/{REPOSITORY}/releases/402391903'),
        ])

    def test_later_page_and_cross_page_ambiguity(self):
        filler = [{'id': i + 1, 'tag_name': f'other-{i}', 'draft': False} for i in range(100)]
        draft = {'id': 402391903, 'tag_name': TAG, 'draft': True}
        with patch('release_lookup._get', side_effect=[filler, [draft], draft]) as get:
            self.assertEqual(resolve_draft(REPOSITORY, TAG), draft)
            self.assertEqual(get.call_args_list[1],
                             call(f'repos/{REPOSITORY}/releases?per_page=100&page=2'))
        first_page = [draft, *filler[:99]]
        with patch('release_lookup._get', side_effect=[first_page, [{**draft, 'id': 402391904}]]):
            with self.assertRaisesRegex(ValueError, 'Ambiguous'):
                resolve_draft(REPOSITORY, TAG)

    def test_published_or_missing_release_is_rejected(self):
        with patch('release_lookup._get', return_value=[{'id': 1, 'tag_name': TAG, 'draft': False}]):
            with self.assertRaisesRegex(ValueError, 'already published'):
                resolve_draft(REPOSITORY, TAG)
        with patch('release_lookup._get', return_value=[]):
            with self.assertRaisesRegex(ValueError, 'not found'):
                resolve_draft(REPOSITORY, TAG)

    def test_publishing_during_lookup_is_rejected(self):
        draft = {'id': 1, 'tag_name': TAG, 'draft': True}
        with patch('release_lookup._get', side_effect=[[draft], {**draft, 'draft': False}]):
            with self.assertRaisesRegex(ValueError, 'no longer'):
                resolve_draft(REPOSITORY, TAG)

    def test_gh_failure_propagates(self):
        with patch('release_lookup.subprocess.check_output', side_effect=OSError('gh failed')):
            with self.assertRaisesRegex(OSError, 'gh failed'):
                resolve_draft(REPOSITORY, TAG)

    def test_gh_json_pages_are_read_without_shell_interpolation(self):
        draft = {'id': 1, 'tag_name': TAG, 'draft': True}
        with patch('release_lookup.subprocess.check_output',
                   side_effect=[json.dumps([draft]), json.dumps(draft)]) as command:
            self.assertEqual(resolve_draft(REPOSITORY, TAG), draft)
            self.assertEqual(command.call_args_list[0], call(
                ['gh', 'api', f'repos/{REPOSITORY}/releases?per_page=100&page=1'], text=True))


if __name__ == '__main__':
    unittest.main()
