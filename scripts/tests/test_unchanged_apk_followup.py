"""Synthetic metadata counterexamples for the distinct second runtime QA route.

These checks neither run Android nor assert that the requested GLES backend is
available. The original runtime and Creative routes keep their exact identities.
"""
from __future__ import annotations

import copy
import importlib.util
from pathlib import Path
import unittest

from scripts.tests.test_verify_unchanged_apk_diagnostic import (
    QA_SOURCE, QA_RUN, qa_metadata,
)


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    'followup_diagnostic_contract', ROOT / 'scripts/verify_unchanged_apk_diagnostic.py')
diagnostic = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(diagnostic)


def followup_metadata():
    run, original = qa_metadata()
    run.update(path=diagnostic.FOLLOWUP_QA_WORKFLOW,
               head_branch=diagnostic.FOLLOWUP_QA_BRANCH)
    jobs = []
    for index, name in enumerate(diagnostic.FOLLOWUP_QA_JOBS):
        row = copy.deepcopy(original['jobs'][0])
        row.update(id=910100 + index, name=name)
        jobs.append(row)
    return run, {'total_count': len(jobs), 'jobs': jobs}


def verify(run, jobs, name):
    return diagnostic.verify_qa(run, jobs, source=QA_SOURCE, run_id=QA_RUN,
                                attempt=1, job_name=name)


class FollowupRouteContracts(unittest.TestCase):
    def test_exact_five_new_jobs_bind_only_the_followup_workflow_and_branch(self):
        expected = {
            'unchanged-apk-followup-api35', 'unchanged-apk-followup-api37-host',
            'unchanged-apk-followup-api37-swiftshader', 'unchanged-apk-followup-api37-swangle',
            'unchanged-apk-followup-update2017',
        }
        self.assertEqual(set(diagnostic.FOLLOWUP_QA_JOBS), expected)
        for name in expected:
            with self.subTest(job=name):
                value = verify(*followup_metadata(), name)
                self.assertEqual(value['workflow_path'], diagnostic.FOLLOWUP_QA_WORKFLOW)
                self.assertEqual(value['branch'], diagnostic.FOLLOWUP_QA_BRANCH)
                self.assertEqual(value['job_name'], name)
                self.assertNotEqual(value['source'], diagnostic.HOST)

    def test_followup_cannot_borrow_historical_or_creative_run_identity(self):
        for key, wrong in (
            ('path', diagnostic.QA_WORKFLOW), ('head_branch', diagnostic.QA_BRANCH),
            ('path', diagnostic.CREATIVE_QA_WORKFLOW),
            ('head_branch', diagnostic.CREATIVE_QA_BRANCH), ('head_branch', 'main'),
            ('run_attempt', 2), ('head_sha', diagnostic.HOST),
        ):
            for name in diagnostic.FOLLOWUP_QA_JOBS:
                run, jobs = followup_metadata()
                run[key] = wrong
                with self.subTest(field=key, value=wrong, job=name), self.assertRaises(RuntimeError):
                    verify(run, jobs, name)

    def test_missing_duplicate_wrong_named_or_wrong_attempt_job_never_binds(self):
        for problem in ('missing', 'duplicate', 'wrong-name', 'wrong-attempt'):
            run, jobs = followup_metadata()
            name = diagnostic.FOLLOWUP_QA_JOBS[3]
            if problem == 'missing':
                jobs['jobs'].pop(3)
                jobs['total_count'] -= 1
            elif problem == 'duplicate':
                row = copy.deepcopy(jobs['jobs'][3])
                row['id'] += 100
                jobs['jobs'].append(row)
                jobs['total_count'] += 1
            elif problem == 'wrong-name':
                jobs['jobs'][3]['name'] = 'unchanged-apk-followup-api37-angle'
            else:
                jobs['jobs'][3]['run_attempt'] = 2
            with self.subTest(problem=problem), self.assertRaises(RuntimeError):
                verify(run, jobs, name)

    def test_original_runtime_and_creative_routes_are_unchanged(self):
        self.assertEqual(len(diagnostic.QA_JOBS), 4)
        for name in diagnostic.QA_JOBS:
            result = verify(*qa_metadata(), name)
            self.assertEqual((result['workflow_path'], result['branch']),
                             (diagnostic.QA_WORKFLOW, diagnostic.QA_BRANCH))
            run, jobs = followup_metadata()
            jobs['jobs'][0]['name'] = name
            with self.assertRaises(RuntimeError):
                verify(run, jobs, name)
        self.assertEqual(diagnostic.QA_ROUTES[diagnostic.CREATIVE_QA_JOB],
                         (diagnostic.CREATIVE_QA_WORKFLOW, diagnostic.CREATIVE_QA_BRANCH))


if __name__ == '__main__':
    unittest.main()
