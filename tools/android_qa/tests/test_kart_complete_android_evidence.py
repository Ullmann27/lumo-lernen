"""Guard full-race evidence against stale saves and falsely completed rewards."""
import copy
import importlib.util
import json
from pathlib import Path
import unittest

PATH = Path(__file__).resolve().parents[3] / '.github/probes/kart_complete_android_probe.py'
SPEC = importlib.util.spec_from_file_location('kart_complete_android_probe', PATH)
PROBE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROBE)


def state(checkpoint=0, *, finished=False, result_id='actual-test-race'):
    return {
        'version': 4, 'distance': checkpoint * 70.0, 'result_id': result_id,
        'checkpoint_index': checkpoint, 'lane': 0.4, 'speed': 17.0,
        'countdown': 0.0, 'elapsed': checkpoint * 5.0, 'difficulty': 'gemuetlich',
        'mode': 'race', 'track_id': 'sonnenhafen', 'selected_driver': 'fox',
        'selected_kart': 'comet', 'finished': finished, 'completed_race': finished,
        'reset_count': 0, 'player_heading': 0.2, 'previous_road_distance': 200.0,
        'result_payload': ({
            'resultId': result_id, 'status': 'completed', 'game': 'kart', 'mode': 'race',
            'track': 'sonnenhafen', 'driver': 'fox', 'kart': 'comet', 'checkpoints': 16,
            'solved': 0, 'stars': 3, 'place': 1, 'elapsedSeconds': 80.0,
        } if finished else {}),
    }


def raw_session(value):
    fields = ['[race]', '']
    for key, data in value.items():
        fields.append(key + '=' + json.dumps(data, indent=2) if key == 'result_payload'
                      else key + '=' + json.dumps(data))
    # Real ConfigFiles also contain Godot Variant values which must not be eval'd.
    fields += ['player_position=Vector3(1, 2, 3)',
               'opponent_positions=Array[Vector3]([Vector3(4, 5, 6)])',
               'collected={', '5: true,', '11: true', '}']
    return '\n'.join(fields) + '\n'


class ReadOnlyKartSaveTests(unittest.TestCase):
    def test_actual_configfile_shapes_preserve_scalar_and_multiline_result_fields(self):
        expected = state(16, finished=True)
        self.assertEqual(PROBE.parse_session(raw_session(expected)), expected)

    def test_invalid_nonfinite_numeric_fields_cannot_prove_real_progress(self):
        for value in ('NaN', 'Infinity', 'true', '"17"'):
            with self.subTest(value=value), self.assertRaisesRegex(RuntimeError, 'Non-finite race field'):
                PROBE.parse_session(raw_session(state()).replace('speed=17.0', 'speed=' + value))

    def test_duplicate_or_missing_ids_are_rejected_instead_of_using_stale_data(self):
        with self.assertRaisesRegex(RuntimeError, 'one field: result_id'):
            PROBE.parse_session(raw_session(state()) + 'result_id="stale"\n')
        with self.assertRaisesRegex(RuntimeError, 'one field: result_id'):
            PROBE.parse_session(raw_session(state()).replace('result_id="actual-test-race"\n', ''))

    def test_typed_checkpoint_and_finish_state_cannot_be_string_or_boolean_coerced(self):
        for old, new, error in (('checkpoint_index=0', 'checkpoint_index=true', 'Non-integer'),
                                ('finished=false', 'finished="false"', 'Non-boolean')):
            with self.subTest(new=new), self.assertRaisesRegex(RuntimeError, error):
                PROBE.parse_session(raw_session(state()).replace(old, new))

    def test_no_python_or_godot_expression_is_executed(self):
        with self.assertRaisesRegex(RuntimeError, 'Invalid scalar'):
            PROBE.parse_session(raw_session(state()).replace('speed=17.0', 'speed=__import__("os")'))


class FreshRaceReadinessTests(unittest.TestCase):
    def setUp(self):
        self.now = 0.0
        self.records = []
        self.calls = []

    def record(self, evidence):
        self.records.append(json.loads(json.dumps(evidence)))

    def sleep(self, duration):
        self.now += duration

    def poll(self, states, *, timeout=10):
        states = iter(states)

        def read(tag, *, timeout):
            self.calls.append((tag, timeout))
            return next(states)

        return PROBE.wait_fresh_race(read, 'old', self.record, timeout=timeout,
                                    clock=lambda: self.now, sleep=self.sleep)

    def test_earlier_countdown_zero_session_cannot_identify_the_new_race(self):
        old = {**state(result_id='old'), 'elapsed': 15.0, 'countdown': 0.0}
        self.assertFalse(PROBE.fresh_race_ready(old, 'old'))

    def test_fresh_identity_must_finish_countdown_and_green_start_phase_naturally(self):
        fresh = {**state(result_id='fresh'), 'elapsed': 5.0}
        for pending in ({**fresh, 'countdown': 3.5, 'elapsed': 0.0},
                        {**fresh, 'elapsed': 0.5}):
            self.assertFalse(PROBE.fresh_race_ready(pending, 'old'))
        self.assertTrue(PROBE.fresh_race_ready(fresh, 'old'))

    def test_wrong_setup_completed_or_already_advanced_race_is_fatal(self):
        fresh = {**state(result_id='fresh'), 'elapsed': 5.0}
        for changes in ({'mode': 'training'}, {'track_id': 'bergwelt'},
                        {'checkpoint_index': 1}, {'finished': True},
                        {'completed_race': True}, {'result_payload': {'stars': 3}},
                        {'countdown': -1.0}):
            with self.subTest(changes=changes), self.assertRaises(RuntimeError):
                PROBE.fresh_race_ready({**fresh, **changes}, 'old')

    def test_poll_retains_old_pending_and_two_stable_fresh_ready_observations(self):
        old = {**state(result_id='old'), 'elapsed': 15.0}
        pending = {**state(result_id='fresh'), 'countdown': 3.5}
        ready = {**state(result_id='fresh'), 'elapsed': 5.0}
        self.assertEqual(self.poll([old, pending, ready, ready]), ready)
        final = self.records[-1]
        self.assertEqual(final['status'], 'READY')
        self.assertEqual(final['previous_result_id'], 'old')
        self.assertEqual(final['fresh_result_id'], 'fresh')
        self.assertEqual([row['ready'] for row in final['observations']], [False, False, True, True])
        self.assertEqual(final['observations'][-1]['consecutive_ready_reads'], 2)
        self.assertTrue(all(0 < timeout <= 10 for _, timeout in self.calls))
        self.assertEqual(final['observations'][0]['snapshot'], '02-race-readiness-000-session.cfg')

    def test_another_fresh_identity_change_cannot_satisfy_stable_readiness(self):
        fresh = {**state(result_id='fresh'), 'elapsed': 5.0}
        other = {**fresh, 'result_id': 'different-new-race'}
        with self.assertRaisesRegex(RuntimeError, 'changed again'):
            self.poll([fresh, other])
        self.assertEqual(self.records[-1]['status'], 'FAIL')

    def test_runtime_cannot_revert_to_the_prior_saved_race_after_new_identity_seen(self):
        fresh = {**state(result_id='fresh'), 'countdown': 3.5}
        with self.assertRaisesRegex(RuntimeError, 'reverted'):
            self.poll([fresh, state(result_id='old')])
        self.assertEqual(self.records[-1]['status'], 'FAIL')

    def test_stale_save_wait_is_bounded_and_does_not_manufacture_new_state(self):
        with self.assertRaises(TimeoutError):
            self.poll([state(result_id='old')] * 6)
        self.assertEqual(self.now, 10)
        self.assertEqual(len(self.calls), 5)
        self.assertEqual(self.records[-1]['status'], 'FAIL')
        self.assertNotIn('fresh_result_id', self.records[-1])

    def test_actual_read_failure_is_retained_and_never_treated_as_pending_readiness(self):
        def read(*args, **kwargs):
            raise RuntimeError('actual CFG read failed: permission denied')

        with self.assertRaisesRegex(RuntimeError, 'permission denied'):
            PROBE.wait_fresh_race(read, 'old', self.record, clock=lambda: self.now, sleep=self.sleep)
        self.assertEqual(self.records[-1]['status'], 'FAIL')
        self.assertIn('permission denied', self.records[-1]['error'])

    def test_late_command_result_cannot_pass_after_the_readiness_deadline(self):
        def read(*args, **kwargs):
            self.now = 11
            return {**state(result_id='fresh'), 'elapsed': 5.0}

        with self.assertRaises(TimeoutError):
            PROBE.wait_fresh_race(read, 'old', self.record, timeout=10,
                                 clock=lambda: self.now, sleep=self.sleep)
        self.assertEqual(self.records[-1]['status'], 'FAIL')


class NaturalKartCompletionTests(unittest.TestCase):
    def test_requires_both_genuinely_in_progress_laps_and_complete_native_result(self):
        final = state(16, finished=True)
        self.assertEqual(PROBE.require_completion([state(), state(3), state(10), final], final,
                                                 'actual-test-race'), final['result_payload'])

    def test_final_save_alone_and_missing_second_lap_cannot_prove_a_driven_race(self):
        final = state(16, finished=True)
        for trace, error in (([final], 'first lap'),
                             ([state(), state(2), final], 'second lap'),
                             ([state(), state(9), final], 'first lap')):
            with self.subTest(error=error), self.assertRaisesRegex(RuntimeError, error):
                PROBE.require_completion(trace, final, 'actual-test-race')

    def test_wrong_result_id_or_training_mode_cannot_pass_a_two_lap_race(self):
        for key, value in (('result_id', 'stale-race'), ('mode', 'training'),
                           ('track_id', 'bergwelt'), ('difficulty', 'flott')):
            with self.subTest(key=key), self.assertRaisesRegex(RuntimeError, 'different race/setup'):
                PROBE.require_race_identity({**state(), key: value}, 'actual-test-race')

    def test_unfinished_state_or_forged_payload_checkpoint_is_rejected(self):
        final = state(16, finished=True)
        with self.assertRaisesRegex(RuntimeError, 'not completed'):
            PROBE.require_completion([state(), state(3), state(10)], state(16), 'actual-test-race')
        bad_final = {**final, 'result_payload': {**final['result_payload'], 'checkpoints': 15}}
        with self.assertRaisesRegex(RuntimeError, 'does not match'):
            PROBE.require_completion([state(), state(3), state(10), bad_final], bad_final, 'actual-test-race')


class HostRewardEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.payload = state(16, finished=True)['result_payload']
        self.before = {'stars': 8, 'totalEarnedStars': 12, 'xp': 50, 'gameResultIds': ['old-result']}
        self.after = {'stars': 11, 'totalEarnedStars': 15, 'xp': 50,
                      'gameResultIds': ['old-result', 'actual-test-race']}

    def test_race_with_no_learning_questions_awards_exactly_three_stars_and_no_xp(self):
        PROBE.require_reward(self.before, self.after, self.payload)
        for key in ('stars', 'totalEarnedStars', 'xp'):
            with self.subTest(key=key), self.assertRaisesRegex(RuntimeError, 'wallet delta'):
                PROBE.require_reward(self.before, {**self.after, key: self.after[key] + 1}, self.payload)

    def test_old_duplicate_or_missing_result_cannot_be_counted_as_new_reward(self):
        for ids in (['old-result'], ['old-result', 'actual-test-race', 'actual-test-race']):
            with self.subTest(ids=ids), self.assertRaisesRegex(RuntimeError, 'missing, old or duplicated'):
                PROBE.require_reward(self.before, {**self.after, 'gameResultIds': ids}, self.payload)
        with self.assertRaisesRegex(RuntimeError, 'missing, old or duplicated'):
            PROBE.require_reward(self.after, self.after, self.payload)

    def test_unrelated_result_cannot_explain_the_wallet_delta(self):
        after = {**self.after, 'gameResultIds': self.after['gameResultIds'] + ['unrelated-result']}
        with self.assertRaisesRegex(RuntimeError, 'unrelated result'):
            PROBE.require_reward(self.before, after, self.payload)

    def test_host_event_must_equal_the_actual_payload_and_occur_only_once(self):
        PROBE.require_event({'results': [self.payload]}, self.payload)
        for rows in ([], [self.payload, self.payload], [{**self.payload, 'stars': 0}]):
            with self.subTest(rows=rows), self.assertRaisesRegex(RuntimeError, 'exactly this native finish'):
                PROBE.require_event({'results': rows}, self.payload)

    def test_real_android35_native_and_host_round_trip_may_differ_only_in_last_float_bits(self):
        # Immutable API35 1908 run 37913484330, forensic run 37922144067:
        # ConfigFile 75.35000000000001 vs durable Android JSON 75.35.
        native = {**self.payload, 'elapsedSeconds': 75.35000000000001,
                  'bestLapSeconds': 37.675000000000004}
        host = {**native, 'elapsedSeconds': 75.35, 'bestLapSeconds': 37.675}
        PROBE.require_event({'results': [host]}, native)
        PROBE.require_event({'results': [native]}, native)

    def test_only_two_actual_timing_fields_accept_sub_nanosecond_json_variance(self):
        native = {**self.payload, 'elapsedSeconds': 75.35000000000001,
                  'bestLapSeconds': 37.675000000000004}
        for updates in (
            {'elapsedSeconds': 75.350001},
            {'elapsedSeconds': 75.349999},
            {'elapsedSeconds': float('nan')},
            {'elapsedSeconds': float('inf')},
            {'elapsedSeconds': '75.35'},
            {'elapsedSeconds': 75},
            {'bestLapSeconds': 37.675001},
            {'bestLapSeconds': float('-inf')},
            {'bestLapSeconds': '37.675'},
            {'stars': 2},
            {'resultId': 'another-finish-id'},
            {'sessionId': 'wrong-session'},
            {'checkpoints': 15},
        ):
            with self.subTest(updates=updates), self.assertRaisesRegex(
                    RuntimeError, 'exactly this native finish'):
                PROBE.require_event({'results': [{**native, **updates}]}, native)
        with self.assertRaisesRegex(RuntimeError, 'exactly this native finish'):
            PROBE.require_event({'results': [{k: v for k, v in native.items()
                                              if k != 'stars'}]}, native)
        with self.assertRaisesRegex(RuntimeError, 'exactly this native finish'):
            PROBE.require_event({'results': [native, native]}, native)

    def test_ack_requires_the_actual_result_to_leave_the_pending_host_queue(self):
        PROBE.require_ack({'results': []}, 'actual-test-race')
        PROBE.require_ack({'results': [{'resultId': 'unrelated'}]}, 'actual-test-race')
        with self.assertRaisesRegex(RuntimeError, 'not acknowledged'):
            PROBE.require_ack({'results': [self.payload]}, 'actual-test-race')


class ActualNativeInteractionEvidenceTests(unittest.TestCase):
    def test_resize_cannot_replace_saved_identity_or_advance_paused_progress(self):
        original = state(4)
        PROBE.require_saved_progress_unchanged(original, dict(original), 'pause')
        for key, value in (('result_id', 'replacement-race'), ('distance', original['distance'] + 1),
                           ('elapsed', original['elapsed'] + 0.1), ('checkpoint_index', 5),
                           ('mode', 'training'), ('finished', True)):
            with self.subTest(key=key), self.assertRaisesRegex(RuntimeError, 'pause resize changed saved race state'):
                PROBE.require_saved_progress_unchanged(original, {**original, key: value}, 'pause')

    def test_resize_cannot_replace_completed_payload_or_drop_finished_state(self):
        original = state(16, finished=True)
        changed = {**original, 'result_payload': {**original['result_payload'], 'stars': 0}}
        with self.assertRaisesRegex(RuntimeError, 'result_payload'):
            PROBE.require_saved_progress_unchanged(original, changed, 'result')
        with self.assertRaisesRegex(RuntimeError, 'completed_race'):
            PROBE.require_saved_progress_unchanged(original, {**original, 'completed_race': False}, 'result')

    def test_scroll_uses_only_observed_modal_caption_positions(self):
        lines = [{'text': 'Eine kleine Pause', 'bounds': [300, 200, 500, 220]},
                 {'text': 'Grafik: Hoch', 'bounds': [360, 500, 440, 520]},
                 # Pinned navigation and underlying HUD are outside the settings scroller.
                 {'text': 'Zur Spieleauswahl', 'bounds': [300, 650, 450, 680]},
                 {'text': 'Zum Lernen', 'bounds': [500, 650, 650, 680]},
                 {'text': 'RUNDE 1 / 2', 'bounds': [10, 10, 200, 35]}]
        self.assertEqual(PROBE.observed_scroll(lines, 'down', 'pause'), [400, 510, 400, 210])
        self.assertEqual(PROBE.observed_scroll(lines, 'up', 'pause'), [400, 210, 400, 510])

    def test_unreadable_world_labels_do_not_invent_scroll_targets(self):
        with self.assertRaisesRegex(RuntimeError, 'No observed central modal captions'):
            PROBE.observed_scroll([{'text': 'Sonnenhafen', 'bounds': [200, 300, 600, 340]}], 'down', 'pause')

    def test_actual_godot_errors_fail_but_unsupported_renderer_warnings_are_retained(self):
        PROBE.require_no_runtime_error('I godot : WARNING: Volumetric fog is only available when using Forward+\n')
        PROBE.require_no_runtime_error('E AndroidSystem: background system error\n')
        for line in ('E godot : ERROR: Shader compilation failed',
                     'E godot : SCRIPT ERROR: Invalid call', 'E Godot : USER ERROR: Assertion failed'):
            with self.subTest(line=line), self.assertRaisesRegex(RuntimeError, 'native runtime logged an error'):
                PROBE.require_no_runtime_error(line)


class ModalScrollReadinessTests(unittest.TestCase):
    def captions(self):
        # Caption geometry from both actual failed API35/API36 1902 frames.
        return [
            {'text': 'Eine kleine Pause', 'bounds': [625, 260, 861, 280]},
            {'text': 'Dein Rennen wartet. Du kannst später hier weiterfahren.', 'bounds': [624, 313, 1161, 331]},
            {'text': 'Weiterfahren', 'bounds': [849, 377, 976, 393]},
            {'text': 'Ruhige Bewegung: aus', 'bounds': [803, 464, 1023, 484]},
            {'text': 'Ton: an', 'bounds': [878, 551, 947, 567]},
            {'text': 'Zur Spieleauswahl', 'bounds': [687, 676, 841, 692]},
            {'text': 'Zum Lernen', 'bounds': [1027, 676, 1124, 689]},
            {'text': 'GAS', 'bounds': [1681.5, 870, 1730.5, 886]},
        ]

    def frame(self, *, pixels=None, complete=True):
        return {'source_sha256': 'actual-current-frame', 'pixels': pixels or [1920, 1080],
                'acceptable_for_target_sampling': complete}

    def observation(self):
        return PROBE.scroll_observation(self.captions(), 'down', 'pause')

    def test_real_hud_gas_cannot_authorize_the_outside_modal_swipe(self):
        observation = self.observation()
        self.assertEqual(observation['gesture'], [912, 559, 912, 322])
        self.assertNotIn('gas', [row['caption'] for row in observation['selected_captions']])
        self.assertLess(observation['gesture'][0], 1027)
        self.assertLess(max(observation['gesture'][1::2]), 676)

    def test_full_gas_setting_caption_outside_footer_geometry_is_also_excluded(self):
        rows = self.captions() + [{'text': 'Gas: automatisch', 'bounds': [1670, 900, 1830, 925]}]
        self.assertEqual(PROBE.observed_scroll(rows, 'down', 'pause'), self.observation()['gesture'])

    def test_both_visible_gas_modes_are_settings_only_inside_the_modal(self):
        for caption in ('Gas: automatisch', 'Gas: GAS-Taste halten'):
            rows = self.captions() + [{'text': caption, 'bounds': [800, 610, 1030, 630]}]
            with self.subTest(caption=caption):
                self.assertEqual(PROBE.observed_scroll(rows, 'down', 'pause')[1], 620)

    def test_missing_or_ambiguous_pinned_footer_never_guesses_modal_geometry(self):
        for rows in (self.captions()[:-2], self.captions() + [
                {'text': 'Zum Lernen', 'bounds': [100, 800, 230, 820]}]):
            with self.subTest(rows=rows), self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
                PROBE.observed_scroll(rows, 'down', 'pause')

    def test_different_ocr_variants_of_one_footer_are_deduplicated_without_guessing(self):
        rows = self.captions() + [{'text': 'Zum Lernen', 'bounds': [1026, 675, 1124, 690]}]
        self.assertEqual(PROBE.observed_scroll(rows, 'down', 'pause'), self.observation()['gesture'])

    def test_disordered_or_separate_footer_rows_cannot_bound_the_scroll_content(self):
        for bounds in ([1027, 750, 1124, 770], [500, 676, 600, 689]):
            rows = self.captions()
            rows[6] = {'text': 'Zum Lernen', 'bounds': bounds}
            with self.subTest(bounds=bounds), self.assertRaisesRegex(RuntimeError, 'ordered navigation row'):
                PROBE.observed_scroll(rows, 'down', 'pause')

    def test_invalid_relevant_bounds_fail_instead_of_becoming_input_coordinates(self):
        for bounds in (None, [True, 313, 1161, 331], [624, float('nan'), 1161, 331],
                       [624, 331, 1161, 313], [-1, 313, 1161, 331]):
            rows = self.captions()
            rows[1] = {'text': rows[1]['text'], 'bounds': bounds}
            with self.subTest(bounds=bounds), self.assertRaisesRegex(RuntimeError, 'Invalid observed modal caption bounds'):
                PROBE.observed_scroll(rows, 'down', 'pause')

    def test_settings_below_or_beside_the_footer_cannot_supply_a_scroll_path(self):
        rows = self.captions()[5:7] + [
            {'text': 'Ton: an', 'bounds': [1600, 500, 1670, 520]},
            {'text': 'Grafik: Hoch', 'bounds': [800, 800, 1000, 820]}]
        with self.assertRaisesRegex(RuntimeError, 'No observed central modal captions'):
            PROBE.observed_scroll(rows, 'down', 'pause')

    def test_one_full_frame_is_insufficient_but_two_stable_current_frames_authorize_swipe(self):
        first = PROBE.stable_scroll_observation(self.frame(), self.observation())
        self.assertTrue(first['valid'])
        self.assertFalse(first['stable'])
        second = PROBE.stable_scroll_observation(self.frame(), self.observation(), first)
        self.assertTrue(second['stable'])

    def test_partial_surface_or_resizing_never_reuses_previous_geometry(self):
        first = PROBE.stable_scroll_observation(self.frame(), self.observation())
        rejected = PROBE.stable_scroll_observation(self.frame(complete=False), self.observation(), first)
        self.assertFalse(rejected['valid'])
        self.assertFalse(PROBE.stable_scroll_observation(self.frame(), self.observation(), rejected)['stable'])
        self.assertFalse(PROBE.stable_scroll_observation(self.frame(pixels=[2316, 904]), self.observation(), first)['stable'])

    def test_modal_or_footer_movement_requires_new_stable_frames(self):
        first = PROBE.stable_scroll_observation(self.frame(), self.observation())
        for key in ('content_bounds', 'footer_bounds', 'gesture'):
            changed = json.loads(json.dumps(self.observation()))
            if key == 'footer_bounds':
                changed[key][0] = [value + 13 for value in changed[key][0]]
            elif key == 'content_bounds':
                changed[key][2] += 13
                changed[key][3] += 13
            else:
                changed[key][0] += 13
                changed[key][2] += 13
            with self.subTest(key=key):
                self.assertFalse(PROBE.stable_scroll_observation(self.frame(), changed, first)['stable'])

    def test_clipped_geometry_and_gestures_outside_the_seen_content_fail(self):
        with self.assertRaisesRegex(RuntimeError, 'exceeds the current screenshot'):
            PROBE.stable_scroll_observation(self.frame(pixels=[1080, 700]), self.observation())
        changed = {**self.observation(), 'gesture': [1706, 878, 1706, 270]}
        with self.assertRaisesRegex(RuntimeError, 'leaves the visible modal content'):
            PROBE.stable_scroll_observation(self.frame(), changed)


class CorroboratedPauseFooterOcrTests(unittest.TestCase):
    """Replay saved actual OCR and keep genuinely ambiguous positions fatal."""
    def setUp(self):
        fixture = Path(__file__).with_name('fixtures') / 'kart-modal-footer-api36-37833445834.json'
        self.fixture = json.loads(fixture.read_text())
        self.rows = copy.deepcopy(self.fixture['frames'][1]['ocr_rows'])

    def observation(self, rows=None):
        return PROBE.scroll_observation(self.rows if rows is None else rows, 'up', 'pause')

    def raw_overread(self, rows):
        return next(row for row in rows if row['text'] == 'Zur Spieleauswahl } (')

    def test_fixture_records_original_android_artifact_and_both_frame_hashes(self):
        self.assertEqual(self.fixture['run_id'], 37833445834)
        self.assertEqual(self.fixture['job_id'], 113515871897)
        self.assertEqual(self.fixture['artifact_id'], 11576563808)
        self.assertEqual(self.fixture['artifact_sha256'],
                         'a6cbaaab3eb34268d33cf2ca2a2924c6777376d335cd1b9c72f6905ef7503b63')
        self.assertEqual([frame['source_png_sha256'] for frame in self.fixture['frames']], [
            '614fb046536914e2b98579b061ea455c48a3cc52300972978d75121bc072048e',
            '3a8c6a0c7299e58378390a160414fa653d4047bd1cf0248eee38735286f6c392'])
        self.assertEqual([frame['source_ocr_sha256'] for frame in self.fixture['frames']], [
            '2be81f7fb023aa024b195eaac1bbee9e0fccf968e8332480047399c8f930b0c4',
            'b109c767c9ce30bd12efa574b96da9918b45c1fa13fdb727f10c0bf84d267cce'])
        self.assertIn('no new Android execution', self.fixture['scope'])

    def test_actual_raw_outline_overread_uses_corroborated_unchanged_footer_bounds(self):
        result = self.observation()
        self.assertEqual(result['footer_bounds'], [[687, 676, 841, 692], [1027, 676, 1124, 689]])
        self.assertEqual(result['gesture'], [914, 325, 914, 586])
        left = result['footer_ocr_evidence'][0]
        self.assertEqual({reading['variant'] for reading in left['selected']['ocr_readings']},
                         {'contrast', 'white-text', 'white-latin'})
        self.assertEqual(left['contained_raw_overreads'][0]['ocr_readings'][0], self.raw_overread(self.rows))

    def test_both_actual_saved_frames_keep_two_stable_full_surface_gate(self):
        previous = None
        for index, frame in enumerate(self.fixture['frames']):
            observed = PROBE.scroll_observation(frame['ocr_rows'], 'up', 'pause')
            # Offline replay of recorded surface dimensions; no ADB input occurs.
            surface = {'pixels': frame['pixels'], 'source_sha256': frame['source_png_sha256'],
                       'acceptable_for_target_sampling': True}
            previous = PROBE.stable_scroll_observation(surface, observed, previous)
            self.assertIs(previous['stable'], index == 1)
        self.assertTrue(previous['valid'])

    def test_missing_corroboration_cannot_discard_a_conflicting_raw_box(self):
        rows = [row for row in self.rows if not (row['text'] == 'Zur Spieleauswahl' and
                                                 row['variant'] in ('white-text', 'white-latin'))]
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_repeating_one_variant_does_not_manufacture_independent_corroboration(self):
        rows = copy.deepcopy(self.rows)
        for row in rows:
            if row['text'] == 'Zur Spieleauswahl':
                row['variant'] = 'contrast'
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_unknown_variant_names_cannot_supply_corroboration(self):
        rows = copy.deepcopy(self.rows)
        for row in rows:
            if row['text'] == 'Zur Spieleauswahl' and row['variant'] != 'contrast':
                row['variant'] = 'unverified-reader'
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_spatially_separate_raw_duplicate_remains_fatal_despite_other_consensus(self):
        rows = copy.deepcopy(self.rows)
        self.raw_overread(rows)['bounds'] = [100, 800, 300, 830]
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_partly_overlapping_raw_box_cannot_override_the_confirmed_caption(self):
        rows = copy.deepcopy(self.rows)
        self.raw_overread(rows)['bounds'] = [686, 648.5, 820, 718.5]
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_multiple_nested_raw_overreads_remain_ambiguous(self):
        extra = copy.deepcopy(self.raw_overread(self.rows))
        extra['bounds'] = [680, 640, 952, 730]
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(self.rows + [extra])

    def test_even_three_pixel_clipping_cannot_count_as_full_containment(self):
        for bounds in ([690, 648.5, 944, 718.5], [686, 679, 944, 718.5],
                       [686, 648.5, 838, 718.5], [686, 648.5, 944, 689]):
            rows = copy.deepcopy(self.rows)
            self.raw_overread(rows)['bounds'] = bounds
            with self.subTest(bounds=bounds), self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
                self.observation(rows)

    def test_two_independently_corroborated_boxes_cannot_be_resolved_by_a_majority(self):
        rows = copy.deepcopy(self.rows)
        extra = copy.deepcopy(self.raw_overread(rows))
        extra['variant'] = 'contrast'
        rows.append(extra)
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_non_raw_expanded_box_remains_ambiguous(self):
        rows = copy.deepcopy(self.rows)
        self.raw_overread(rows)['variant'] = 'white-text'
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_a_new_distinct_duplicate_is_not_hidden_by_a_contained_overread(self):
        rows = self.rows + [{'text': 'Zur Spieleauswahl', 'bounds': [50, 100, 250, 120], 'variant': 'raw'}]
        with self.assertRaisesRegex(RuntimeError, 'missing or ambiguous pause footer'):
            self.observation(rows)

    def test_same_geometry_still_rejects_partial_second_surface(self):
        observation = self.observation()
        complete = {'pixels': [1920, 1080], 'source_sha256': 'first',
                    'acceptable_for_target_sampling': True}
        first = PROBE.stable_scroll_observation(complete, observation)
        second = PROBE.stable_scroll_observation({**complete, 'acceptable_for_target_sampling': False},
                                               observation, first)
        self.assertFalse(second['valid'])
        self.assertFalse(second['stable'])


if __name__ == '__main__':
    unittest.main()
