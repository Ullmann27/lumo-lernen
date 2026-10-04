"""A transfer is not a new build and cannot promote a failed QA candidate."""
from copy import deepcopy
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from export_delivery import validate_run, validate_proof


class DeliveryTests(unittest.TestCase):
    def setUp(self):
        self.repo = 'Ullmann27/lumo-lernen'
        self.tag = 'unified-build-280'
        self.sha = 'a'*64
        self.run = {'id': 10, 'run_attempt': 1, 'head_sha': 'b'*40,
                    'head_branch': 'codex/lumo-unified-android-2026-10-03',
                    'path': '.github/workflows/android-integration-qa.yml',
                    'repository': {'full_name': self.repo},
                    'status': 'completed', 'conclusion': 'success'}
        self.metadata = {'run_id': 10, 'attempt': 1, 'repository': self.repo, 'release_tag': self.tag}
        self.result = {'passed': True, 'sha256': self.sha}
        self.uploaded = {'sha256': self.sha, 'passing_test_sha256': self.sha,
                         'qa_harness_commit': self.run['head_sha'], 'source_kind': 'final-apk',
                         'asset_name': 'Lumo-Lernen-Neu.apk', 'release_published': False}
        self.emulator = {'passed': True, 'headless': True}

    def proof(self):
        return validate_proof(self.run, self.metadata, self.result, self.uploaded,
                              self.emulator, self.repo, self.tag, self.sha)

    def test_exact_successful_run_is_accepted(self):
        validate_run(self.run, self.repo, 10, 'b'*40)
        self.assertTrue(self.proof())

    def test_running_run_cannot_be_exported_as_finished(self):
        self.run['status'] = 'in_progress'
        with self.assertRaises(ValueError):
            validate_run(self.run, self.repo, 10, 'b'*40)

    def test_wrong_head_repository_and_workflow_are_rejected(self):
        for key, value in [('head_sha', 'c'*40), ('repository', {'full_name': 'other/repo'}),
                           ('path', '.github/workflows/unrelated.yml')]:
            run = deepcopy(self.run)
            run[key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                validate_run(run, self.repo, 10, 'b'*40)

    def test_failed_run_exports_only_diagnostics_even_with_old_success_proof(self):
        self.run['conclusion'] = 'failure'
        self.assertFalse(self.proof())

    def test_wrong_proof_attempt_is_rejected(self):
        self.metadata['attempt'] = 2
        with self.assertRaises(ValueError):
            self.proof()

    def test_each_required_success_proof_field_is_enforced(self):
        for obj_name in ['result', 'uploaded', 'emulator']:
            original = getattr(self, obj_name)
            for key in original:
                broken = deepcopy(original)
                broken.pop(key)
                setattr(self, obj_name, broken)
                with self.subTest(proof=obj_name, field=key), self.assertRaises(ValueError):
                    self.proof()
            setattr(self, obj_name, original)

    def test_cached_candidate_is_never_delivered_as_final(self):
        self.uploaded['source_kind'] = 'cached-candidate'
        with self.assertRaises(ValueError):
            self.proof()


if __name__ == '__main__':
    unittest.main()
