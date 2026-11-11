"""Negative fixtures for new acceptance claims; no emulator or mocked PASS."""
import copy
import importlib.util
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import Mock

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


class ObservedInputAndLogTests(unittest.TestCase):
    @staticmethod
    def observed_list():
        frame = {'pixels': [2400, 1080], 'acceptable_for_target_sampling': True,
                 'source_sha256': 'actual-image-hash'}
        lines = [{'text': 'Dein Kart. Dein Stil.', 'bounds': [40, 220, 700, 260]},
                 {'text': 'Comet', 'bounds': [300, 410, 420, 450]},
                 {'text': 'Weiter →', 'bounds': [2050, 940, 2200, 980]}]
        return frame, lines

    def test_list_gesture_uses_actual_visible_card_inside_observed_title_footer(self):
        frame, lines = self.observed_list()
        observation = qa.garage_scroll_observation(frame, lines)
        x0, y0, x1, y1 = observation['gesture']
        self.assertTrue(300 <= x0 <= 420)
        self.assertEqual(x0, x1)
        self.assertTrue(260 < y1 < y0 < 940)

    def test_no_gesture_for_wrong_surface_missing_anchors_or_preview_summary(self):
        frame, lines = self.observed_list()
        variants = [({**frame, 'acceptable_for_target_sampling': False}, lines),
                    (frame, lines[1:]), (frame, lines[:-1]),
                    (frame, [lines[0], {**lines[1], 'bounds': [1600, 410, 1720, 450]}, lines[2]])]
        for current, captions in variants:
            with self.assertRaises(RuntimeError):
                qa.garage_scroll_observation(current, captions)

    def test_scroll_requires_two_current_stable_frames_and_unchanged_image(self):
        frame, lines = self.observed_list()
        runner = qa.GarageQA.__new__(qa.GarageQA)
        runner.base = SimpleNamespace(adb=Mock())
        runner.probe = SimpleNamespace(digest=Mock(return_value='actual-image-hash'))
        recovery = runner.card_scroll_recovery()
        first = recovery(frame, lines, Path('observed.png'), deadline=qa.time.monotonic()+30,
                         previous_missing_frame=None)
        self.assertEqual(first['status'], 'WAITING_FOR_SECOND_LIST_FRAME')
        runner.base.adb.assert_not_called()
        second = recovery(frame, lines, Path('observed.png'), deadline=qa.time.monotonic()+30,
                          previous_missing_frame=frame)
        self.assertEqual(second['status'], 'SWIPE_SENT')
        self.assertEqual(runner.base.adb.call_count, 1)

    def test_failed_or_empty_logcat_cannot_be_reported_as_no_crash(self):
        runner = qa.GarageQA.__new__(qa.GarageQA)
        runner.log_reads = 0
        with tempfile.TemporaryDirectory() as folder:
            runner.out = Path(folder)
            runner.base = SimpleNamespace(adb=Mock(side_effect=RuntimeError('ADB transport failed')))
            with self.assertRaisesRegex(RuntimeError, 'ADB transport failed'):
                runner.read_required_logcat('crash-check')
            self.assertTrue(runner.base.adb.call_args.kwargs['check'])
            runner.base.adb = Mock(return_value='')
            with self.assertRaisesRegex(RuntimeError, 'empty log'):
                runner.read_required_logcat('crash-check')

    def test_actual_fatal_event_is_not_replaced_by_a_normal_process_line(self):
        self.assertEqual(qa.fatal_events('I/ActivityManager: lumo activity running'), [])
        fatal = 'E/AndroidRuntime: FATAL EXCEPTION: main\nE/AndroidRuntime: Process: ' + qa.PACKAGE
        self.assertEqual(len(qa.fatal_events(fatal)), 1)


if __name__ == '__main__':
    unittest.main()
