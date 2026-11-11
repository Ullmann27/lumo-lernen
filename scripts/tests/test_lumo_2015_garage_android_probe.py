"""Negative fixtures for new acceptance claims; no emulator or mocked PASS."""
import copy
import importlib.util
from pathlib import Path
import unittest

PATH = Path(__file__).resolve().parents[2] / '.github/probes/lumo_2015_garage_android_probe.py'
SPEC = importlib.util.spec_from_file_location('garage_2015_probe', PATH)
qa = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(qa)


def source_fixture():
    repository = {'id': qa.REPOSITORY_ID, 'full_name': qa.REPOSITORY}
    run = {'id': qa.SOURCE_RUN, 'head_sha': qa.SOURCE, 'workflow_id': qa.SOURCE_WORKFLOW,
           'path': '.github/workflows/lumo-unified-integration-2026.yml',
           'event': 'pull_request', 'head_branch': qa.BRANCH, 'repository': repository,
           'head_repository': repository, 'run_attempt': 1}
    jobs = [{'id': 130535492985, 'name': 'verify-and-build', 'run_id': qa.SOURCE_RUN,
             'head_sha': qa.SOURCE, 'run_attempt': 1, 'status': 'completed', 'conclusion': 'success'}]
    artifacts = [{'id': qa.ARTIFACT_ID, 'name': qa.ARTIFACT_NAME, 'digest': qa.ARTIFACT_DIGEST,
                  'expired': False, 'size_in_bytes': 640594081,
                  'workflow_run': {'id': qa.SOURCE_RUN, 'head_sha': qa.SOURCE,
                                   'repository_id': qa.REPOSITORY_ID,
                                   'head_repository_id': qa.REPOSITORY_ID}}]
    return run, jobs, artifacts


def state(**changes):
    result = {'result_id': 'real-race-a', 'selected_kart': 'comet', 'selected_driver': 'fox',
              'mode': 'cup', 'track_id': 'sonnenhafen', 'distance': 20.0,
              'elapsed': 5.0, 'countdown': 0.0, 'finished': False, 'completed_race': False}
    result.update(changes)
    return result


class ImmutableSourceTests(unittest.TestCase):
    def test_exact_successful_build_can_supply_supplemental_probe(self):
        self.assertEqual(qa.source_run_guard(*source_fixture())['status'], 'PASS')

    def test_rejects_foreign_head_workflow_event_branch_or_attempt(self):
        for key, wrong in [('head_sha', '0'*40), ('workflow_id', 1), ('event', 'push'),
                           ('path', '.github/workflows/other.yml'), ('head_branch', 'main'),
                           ('run_attempt', 2), ('run_attempt', True)]:
            with self.subTest(key=key, wrong=wrong):
                run, jobs, artifacts = source_fixture()
                run[key] = wrong
                with self.assertRaises(RuntimeError):
                    qa.source_run_guard(run, jobs, artifacts)

    def test_rejects_failed_skipped_missing_or_ambiguous_build(self):
        for mutation in ('failure', 'skipped', 'missing', 'duplicate'):
            with self.subTest(mutation=mutation):
                run, jobs, artifacts = source_fixture()
                if mutation == 'missing':
                    jobs.clear()
                elif mutation == 'duplicate':
                    jobs.append(copy.deepcopy(jobs[0]))
                else:
                    jobs[0]['conclusion'] = mutation
                with self.assertRaises(RuntimeError):
                    qa.source_run_guard(run, jobs, artifacts)

    def test_rejects_replaced_expired_or_foreign_artifact(self):
        for key, wrong in [('id', 1), ('digest', 'sha256:' + '0'*64),
                           ('expired', True), ('size_in_bytes', 0)]:
            with self.subTest(key=key):
                run, jobs, artifacts = source_fixture()
                artifacts[0][key] = wrong
                with self.assertRaises(RuntimeError):
                    qa.source_run_guard(run, jobs, artifacts)
        run, jobs, artifacts = source_fixture()
        artifacts[0]['workflow_run']['head_repository_id'] = 1
        with self.assertRaises(RuntimeError):
            qa.source_run_guard(run, jobs, artifacts)


class ActualSelectionTests(unittest.TestCase):
    def test_original_free_cars_must_appear_in_the_started_race(self):
        for kart in qa.KARTS:
            qa.require_selected_race(state(selected_kart=kart), kart)

    def test_screenshot_or_touch_does_not_override_wrong_saved_car(self):
        with self.assertRaises(RuntimeError):
            qa.require_selected_race(state(), 'gecko_velo')

    def test_reused_save_wrong_world_driver_or_finished_race_is_rejected(self):
        for change in ({'selected_driver': 'rabbit'}, {'track_id': 'other'}, {'mode': 'race'},
                       {'finished': True}, {'completed_race': True}, {'elapsed': float('nan')},
                       {'distance': True}, {'result_id': ''}):
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                qa.require_selected_race(state(**change), 'comet')
        with self.assertRaises(RuntimeError):
            qa.require_selected_race(state(), 'comet', previous_id='real-race-a')

    def test_continue_requires_new_distance_and_time_in_same_race(self):
        proof = qa.require_resumed_progress(state(), state(distance=28, elapsed=7.5), 'comet')
        self.assertEqual(proof['distance_gain_after_continue'], 8)
        for change in ({'distance': 27.9, 'elapsed': 8}, {'distance': 30, 'elapsed': 7.4},
                       {'distance': 30, 'elapsed': 8, 'result_id': 'other'},
                       {'distance': 30, 'elapsed': 8, 'countdown': 1},
                       {'distance': 30, 'elapsed': 8, 'selected_kart': 'gecko_velo'}):
            with self.subTest(change=change), self.assertRaises(RuntimeError):
                qa.require_resumed_progress(state(), state(**change), 'comet')

    def test_no_partial_missing_fold_or_duplicate_step_can_report_pass(self):
        steps = [{'step': name, 'status': 'PASS'} for name in qa.REQUIRED_STEPS]
        races = [state(), state(result_id='real-race-b', selected_kart='gecko_velo')]
        qa.require_complete(steps, races)
        for bad in (steps[:-1], steps + [steps[0]],
                    [item for item in steps if not item['step'].startswith('fold')]):
            with self.assertRaises(RuntimeError):
                qa.require_complete(bad, races)
        steps[0]['status'] = 'FAIL'
        with self.assertRaises(RuntimeError):
            qa.require_complete(steps, races)

    def test_same_car_or_same_race_twice_cannot_satisfy_two_selections(self):
        steps = [{'step': name, 'status': 'PASS'} for name in qa.REQUIRED_STEPS]
        for races in ([state(), state(result_id='b')],
                      [state(), state(selected_kart='gecko_velo')]):
            with self.assertRaises(RuntimeError):
                qa.require_complete(steps, races)


if __name__ == '__main__':
    unittest.main()
