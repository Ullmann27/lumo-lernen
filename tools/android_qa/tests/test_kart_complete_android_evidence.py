"""Guard full-race evidence against stale saves and falsely completed rewards."""
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


if __name__ == '__main__':
    unittest.main()
