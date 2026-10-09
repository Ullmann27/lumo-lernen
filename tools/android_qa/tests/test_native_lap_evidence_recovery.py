"""New strict-reader guards using byte-exact closed native evidence fixtures.

The fixtures originate from separately executed Linux GL probes. The mutations
and temporary source/PNG roots in these unit tests are controlled inputs and
must never be reported as new Android, gameplay or performance execution.
"""
from __future__ import annotations

import copy
import hashlib
import importlib
import json
import os
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zlib

sys.dont_write_bytecode = True
QA = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QA))
FIXTURES = Path(__file__).with_name('fixtures')


def validator():
    return importlib.import_module('native_lap_evidence_recovery')


def fixture(name):
    return json.loads((FIXTURES / name).read_text())


def set_path(data, path, value):
    target = data
    for part in path[:-1]:
        target = target[part]
    target[path[-1]] = value


class ContinuityEvidenceRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.data = fixture('native_lap_continuity_104.json')

    def rejects(self, path, value):
        data = copy.deepcopy(self.data)
        set_path(data, path, value)
        with self.assertRaises(ValueError):
            validator().validate_lap_session(data)

    def test_closed_actual_fixture_is_byte_exact_and_valid(self):
        raw = (FIXTURES / 'native_lap_continuity_104.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),
                         '6b572c4bf1258a163702fa623032d0278aef593f6f6588e8f0e26566c72970da')
        self.assertIsNone(validator().validate_lap_session(self.data))

    def test_projection_checks_are_accepted_without_invented_full_equality(self):
        check = self.data['checks'][9]
        self.assertNotEqual(check['actual'], check['expected'])
        self.assertEqual(set(check['actual']), {'lap_times', 'lap_started_at'})
        self.assertIsNone(validator().validate_lap_session(self.data))

    def test_root_and_required_field_errors_use_value_error(self):
        for value in (None, [], 'PASS', 104):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validator().validate_lap_session(value)
        for key in ('status', 'checks', 'expected_laps', 'ordered_gates', 'lap2_before',
                    'lap2_restored', 'finished_payload', 'reopened_result_ui', 'fixture_scope'):
            with self.subTest(key=key):
                data = copy.deepcopy(self.data)
                del data[key]
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(data)

    def test_status_count_failure_metadata_is_strict(self):
        for path, bad in ((('status',), 'FAIL'), (('check_count',), 103),
                          (('check_count',), '104'), (('check_count',), True),
                          (('failed_checks',), 1), (('failed_checks',), False)):
            with self.subTest(path=path, bad=bad):
                self.rejects(path, bad)

    def test_runtime_metadata_cannot_claim_headless_or_foreign_engine(self):
        for key, bad in (('display_server', 'headless'), ('engine', '4.6.2-stable (official)'),
                         ('rendering_method', 'forward_plus'),
                         ('physical_device_performance', '60 FPS')):
            with self.subTest(key=key):
                self.rejects((key,), bad)

    def test_source_probe_fixture_hashes_require_digest_shape(self):
        for key in ('source_sha256', 'probe_sha256', 'fixture_probe_sha256', 'result_reopen_png_sha256'):
            for bad in ('', 'abc', 'g' * 64, False):
                with self.subTest(key=key, bad=bad):
                    self.rejects((key,), bad)

    def test_missing_extra_or_reordered_check_is_rejected(self):
        for action in ('missing', 'extra', 'reordered'):
            with self.subTest(action=action):
                data = copy.deepcopy(self.data)
                if action == 'missing':
                    data['checks'].pop()
                elif action == 'extra':
                    data['checks'].append(copy.deepcopy(data['checks'][-1]))
                else:
                    data['checks'][3], data['checks'][4] = data['checks'][4], data['checks'][3]
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(data)

    def test_check_name_pass_flag_and_expected_type_are_strict(self):
        for path, bad in ((('checks', 1, 'name'), 'unknown physical driving'),
                          (('checks', 2, 'name'), self.data['checks'][1]['name']),
                          (('checks', 0, 'passed'), False), (('checks', 0, 'passed'), 1),
                          (('checks', 11, 'actual'), 1), (('checks', 11, 'expected'), 1)):
            with self.subTest(path=path):
                self.rejects(path, bad)

    def test_passed_true_cannot_mask_contradictory_recorded_values(self):
        self.rejects(('checks', 77, 'actual'), [[], 90.0])
        self.rejects(('checks', 27, 'actual'), [True, False])
        self.rejects(('checks', 22, 'actual'), 2)

    def test_expected_values_cannot_be_changed_with_actual_values_to_forge_pass(self):
        for index, bad in ((22, 2), (8, True), (11, 1), (72, 0.0)):
            with self.subTest(index=index):
                data = copy.deepcopy(self.data)
                data['checks'][index]['actual'] = copy.deepcopy(bad)
                data['checks'][index]['expected'] = copy.deepcopy(bad)
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(data)

    def test_driven_gate_order_and_integer_gate_identity_are_required(self):
        for action in ('reversed', 'missing', 'duplicate', 'boolean'):
            with self.subTest(action=action):
                data = copy.deepcopy(self.data)
                gates = data['ordered_gates']
                if action == 'reversed':
                    gates[2], gates[3] = gates[3], gates[2]
                elif action == 'missing':
                    gates.pop()
                elif action == 'duplicate':
                    gates[7]['gate'] = 7
                else:
                    gates[0]['gate'] = True
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(data)

    def test_driven_gate_seconds_and_distance_must_advance_and_be_finite(self):
        for path, bad in ((('ordered_gates', 3, 'seconds'), self.data['ordered_gates'][2]['seconds']),
                          (('ordered_gates', 3, 'distance'), self.data['ordered_gates'][2]['distance']),
                          (('ordered_gates', 0, 'seconds'), float('nan')),
                          (('ordered_gates', 0, 'distance'), float('inf')),
                          (('ordered_gates', 0, 'seconds'), False),
                          (('ordered_gates', 0, 'distance'), -1.0)):
            with self.subTest(path=path, bad=bad):
                self.rejects(path, bad)

    def test_driven_check_rows_cannot_disagree_with_top_level_gate_trace(self):
        self.rejects(('checks', 1, 'actual', 0, 'gate'), 2)
        self.rejects(('checks', 17, 'actual', 15, 'seconds'), 500.0)

    def test_lap_two_restored_progress_and_identity_cannot_change(self):
        for key, bad in (('checkpoint_index', 11), ('result_id', 'foreign-session'),
                         ('distance', 1.0), ('elapsed', 0.0), ('lap_started_at', 0.0), ('lap_times', [])):
            with self.subTest(key=key):
                self.rejects(('lap2_restored', key), bad)

    def test_lap_two_history_and_origin_cannot_be_missing_or_invented(self):
        for key, bad in (('lap_times', []), ('lap_times', [1.0]),
                         ('lap_started_at', 0.0), ('lap_started_at', 1000.0)):
            with self.subTest(key=key, bad=bad):
                self.rejects(('lap2_before', key), bad)

    def test_expected_laps_derive_from_gate_eight_and_sixteen(self):
        self.rejects(('expected_laps', 0), self.data['expected_laps'][0] + .01)
        self.rejects(('expected_laps', 1), self.data['expected_laps'][1] + .01)
        self.rejects(('checks', 18, 'actual', 1), self.data['expected_laps'][1] + .01)

    def test_reviewed_timing_comparison_accepts_small_serialization_difference(self):
        data = copy.deepcopy(self.data)
        data['checks'][6]['actual']['lap_started_at'] += 5e-10
        self.assertIsNone(validator().validate_lap_session(data))

    def test_timing_comparison_rejects_difference_above_one_nanosecond(self):
        self.rejects(('checks', 6, 'actual', 'lap_started_at'),
                     self.data['checks'][6]['actual']['lap_started_at'] + 2e-9)

    def test_exact_live_start_check_does_not_gain_serialization_tolerance(self):
        self.rejects(('checks', 4, 'actual'), self.data['checks'][4]['actual'] + 5e-10)

    def test_public_payload_times_preserve_millisecond_precision(self):
        self.rejects(('finished_payload', 'elapsedSeconds'), 51.2)
        self.rejects(('finished_payload', 'bestLapSeconds'), 25.0)
        self.rejects(('reopened_result_elapsed_seconds',), self.data['finished_elapsed_seconds'] + .01)

    def test_public_solved_zero_requires_integer_and_reward_identity(self):
        for key, bad in (('solved', False), ('solved', 0.0), ('solved', 1), ('stars', 2),
                         ('resets', 1), ('resultId', 'foreign-race'), ('status', 'aborted')):
            with self.subTest(key=key, bad=bad):
                self.rejects(('finished_payload', key), bad)

    def test_reopened_payload_cannot_change_or_repeat_reward(self):
        self.rejects(('reopened_result_payload', 'stars'), 6)
        self.rejects(('reward_calls',), 2)
        self.rejects(('reward_calls',), True)
        self.rejects(('checks', 26, 'actual', 'local_stars'), 6)

    def test_visible_best_and_total_require_unique_consistent_lines(self):
        text = self.data['reopened_result_stats_text']
        for bad in (text.replace('00:25.100', '00:28.000'), text + '\nBeste Runde   00:25.100',
                    text + '\n Gesamtzeit   00:00.000', text.replace('Gesamtzeit   ', 'Time   ')):
            with self.subTest(bad=bad):
                self.rejects(('reopened_result_stats_text',), bad)
        self.rejects(('reopened_result_stats_visible',), False)

    def test_result_ui_both_frames_hide_controls_and_disable_each_action(self):
        for key in ('direct_result_ui', 'reopened_result_ui'):
            for stage in ((), ('after_tick',)):
                with self.subTest(key=key, stage=stage):
                    self.rejects((key, *stage, 'controls_visible'), True)
                    for action in ('gas', 'brake', 'drift', 'boost', 'item'):
                        self.rejects((key, *stage, 'action_disabled', action), False)

    def test_result_ui_parses_actual_hud_zero_and_rejects_boolean_metadata(self):
        for key in ('direct_result_ui', 'reopened_result_ui'):
            for stage in ((), ('after_tick',)):
                for text in ('RUNDE 2    43 km/h', 'RUNDE 2    0 km/h    43 km/h', 'RUNDE 2'):
                    with self.subTest(key=key, stage=stage, text=text):
                        self.rejects((key, *stage, 'hud_text'), text)
                self.rejects((key, *stage, 'displayed_speed_kmh'), False)

    def test_result_ui_keeps_correct_title_and_underlying_raw_speed(self):
        for key in ('direct_result_ui', 'reopened_result_ui'):
            for stage in ((), ('after_tick',)):
                with self.subTest(key=key, stage=stage):
                    self.rejects((key, *stage, 'message_text'), 'Paused')
                    self.rejects((key, *stage, 'expected_message_text'), 'Paused')
            self.rejects((key, 'after_tick', 'raw_speed'), 0.0)

    def test_time_trial_ui_checks_preserve_drive_pause_and_raw_speed(self):
        for stage, bad in (('driving', 0), ('paused', 0), ('finished', 43), ('after_tick', 43)):
            with self.subTest(stage=stage):
                self.rejects(('checks', 100, 'actual', stage, 'displayed_speed_kmh'), bad)
        self.rejects(('checks', 100, 'actual', 'finished', 'raw_speed'), 0.0)
        self.rejects(('checks', 100, 'expected', 'raw_speed'), False)

    def test_legacy_fixture_scope_cannot_be_relabelled_as_driven_laps(self):
        self.rejects(('fixture_scope',), '20 actually driven compatibility laps')
        self.rejects(('fixture_scope',), '20 ConfigFile pair fixtures are actually driven performance laps')

    def test_legacy_fixture_pairs_keep_unknown_sentinel_and_strict_types(self):
        for index, bad in ((34, [[], 0.0]), (40, [[30.0], 30.0]),
                           (31, 1), (32, [[True], 30.0]), (72, False), (77, [[], 90.0])):
            with self.subTest(index=index):
                self.rejects(('checks', index, 'actual'), bad)

    def test_legacy_fixture_expected_sentinel_cannot_be_forged_with_actual(self):
        data = copy.deepcopy(self.data)
        data['checks'][34]['actual'] = [[], 0.0]
        data['checks'][34]['expected'] = [[], 0.0]
        with self.assertRaises(ValueError):
            validator().validate_lap_session(data)

    def test_legacy_visible_best_uses_valid_payload_only(self):
        self.rejects(('checks', 89, 'actual', 'text'),
                     self.data['checks'][89]['actual']['text'] + '\nBeste Runde   00:28.000')
        self.rejects(('checks', 88, 'expected', 'has_best'), 1)

    def test_ack_allows_only_completed_normalized_payload_and_fixed_session_transition(self):
        ack = self.data['checks'][30]['actual']['returns'][0]
        self.assertEqual(ack['solved'], 0.0)
        self.assertEqual(ack['sessionId'], 'recovered-lap-continuity')
        self.assertIsNone(validator().validate_lap_session(self.data))
        for key, bad in (('solved', False), ('stars', 2.0), ('sessionId', 'foreign'),
                         ('resultId', 'foreign'), ('status', 'aborted')):
            with self.subTest(key=key):
                self.rejects(('checks', 30, 'actual', 'returns', 0, key), bad)

    def test_ack_requires_one_return_and_removed_durable_save(self):
        self.rejects(('checks', 30, 'actual', 'returns'), [])
        self.rejects(('checks', 30, 'actual', 'returns'),
                     self.data['checks'][30]['actual']['returns'] * 2)
        self.rejects(('checks', 30, 'actual', 'save_exists'), True)
        self.rejects(('checks', 30, 'actual', 'save_exists'), 0)

    def test_malformed_projection_shapes_fail_with_value_error(self):
        for index, bad in ((0, None), (0, {'lap_times': []}), (30, None),
                           (30, {'returns': []}), (88, {}), (100, {})):
            with self.subTest(index=index, bad=bad):
                self.rejects(('checks', index, 'actual'), bad)


class CompleteFlowEvidenceRecoveryTests(unittest.TestCase):
    """Closed schema-rerun fixture; final runtime acceptance is separate."""
    def setUp(self):
        self.data = fixture('native_lap_flow_9.json')

    def rejects(self, path, value):
        data = copy.deepcopy(self.data)
        set_path(data, path, value)
        with self.assertRaises(ValueError):
            validator().validate_complete_flow(data)

    def test_closed_schema_rerun_fixture_is_byte_exact_and_valid(self):
        raw = (FIXTURES / 'native_lap_flow_9.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),
                         'fbab2cf1e62dc11436675081ca6569afe34fe6a889d30d0210c096ef81205b08')
        self.assertIsNone(validator().validate_complete_flow(self.data))

    def test_root_and_missing_shape_errors_use_value_error(self):
        for value in (None, [], True):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validator().validate_complete_flow(value)
        for key in ('checks', 'ordered_gates', 'lap2_before', 'lap2_restored',
                    'result', 'reopened_result_payload', 'reopened_result_ui'):
            with self.subTest(key=key):
                data = copy.deepcopy(self.data)
                del data[key]
                with self.assertRaises(ValueError):
                    validator().validate_complete_flow(data)

    def test_count_status_source_and_rendering_are_bound(self):
        for key, bad in (('check_count', 8), ('check_count', '9'), ('failed_checks', False),
                         ('status', 'FAIL'), ('source_sha256', 'f' * 64),
                         ('probe_sha256', 'a' * 64), ('display_server', 'headless'),
                         ('rendering_method', 'forward_plus'), ('physical_device_performance', '60 FPS')):
            with self.subTest(key=key):
                self.rejects((key,), bad)

    def test_nine_ordered_check_names_and_true_boolean_flags_are_required(self):
        for action in ('missing', 'extra', 'reordered', 'unknown', 'untyped-pass'):
            with self.subTest(action=action):
                data = copy.deepcopy(self.data)
                if action == 'missing':
                    data['checks'].pop()
                elif action == 'extra':
                    data['checks'].append(copy.deepcopy(data['checks'][-1]))
                elif action == 'reordered':
                    data['checks'][1], data['checks'][2] = data['checks'][2], data['checks'][1]
                elif action == 'unknown':
                    data['checks'][0]['name'] = 'unknown touch pause'
                else:
                    data['checks'][0]['passed'] = 1
                with self.assertRaises(ValueError):
                    validator().validate_complete_flow(data)

    def test_paused_touch_result_has_correct_zero_reward_identity_and_session(self):
        for key, bad in (('status', 'completed'), ('resultId', 'foreign'), ('sessionId', 'foreign'),
                         ('solved', False), ('stars', False), ('stars', 3.0), ('game', 'puzzle')):
            with self.subTest(key=key):
                self.rejects(('checks', 0, 'actual', key), bad)
        self.rejects(('checks', 0, 'expected'), 1)

    def test_saved_second_lap_restores_checkpoint_timing_and_identity(self):
        for key, bad in (('checkpoint_index', 11), ('result_id', 'foreign'), ('distance', 0.0),
                         ('elapsed', 0.0), ('lap_times', []), ('lap_started_at', 0.0)):
            with self.subTest(key=key):
                self.rejects(('lap2_restored', key), bad)
        self.rejects(('lap2_save_reopen_resume',), False)

    def test_touch_gate_trace_is_ordered_monotonic_and_finite(self):
        self.rejects(('ordered_gates', 0, 'gate'), True)
        self.rejects(('ordered_gates', 7, 'gate'), 7)
        self.rejects(('ordered_gates', 3, 'seconds'), self.data['ordered_gates'][2]['seconds'])
        self.rejects(('ordered_gates', 3, 'distance'), float('nan'))

    def test_touch_lap_intervals_and_unrounded_best_derive_from_gates(self):
        self.rejects(('expected_laps', 0), self.data['expected_laps'][0] + .01)
        self.rejects(('lap_times', 1), self.data['lap_times'][1] + .01)
        self.rejects(('best_lap_seconds_unrounded',), self.data['best_lap_seconds_unrounded'] + .01)
        self.rejects(('checks', 3, 'actual'), [])

    def test_published_touch_times_keep_milliseconds_and_frozen_raw_elapsed(self):
        self.rejects(('result', 'elapsedSeconds'), 83.0)
        self.rejects(('result', 'bestLapSeconds'), 41.2)
        self.rejects(('finished_elapsed_seconds',), self.data['finished_elapsed_seconds'] + .01)
        self.rejects(('reopened_result_elapsed_seconds',), self.data['finished_elapsed_seconds'] + .01)

    def test_touch_public_solved_zero_is_integer_and_reward_is_legitimate(self):
        for key, bad in (('solved', False), ('solved', 0.0), ('solved', 1), ('stars', 2),
                         ('resets', 1), ('checkpoints', 15), ('place', True)):
            with self.subTest(key=key, bad=bad):
                self.rejects(('result', key), bad)

    def test_reopened_touch_payload_cannot_change_identity_or_award(self):
        self.rejects(('reopened_result_payload', 'resultId'), 'foreign')
        self.rejects(('reopened_result_payload', 'stars'), 6)
        self.rejects(('reward_calls',), 2)
        self.rejects(('reward_calls',), True)
        self.rejects(('checks', 8, 'actual', 'local_stars'), 6)

    def test_touch_expected_and_actual_cannot_both_forge_duplicate_reward(self):
        data = copy.deepcopy(self.data)
        data['checks'][8]['actual']['host_rewards'] = 2
        data['checks'][8]['expected']['host_rewards'] = 2
        with self.assertRaises(ValueError):
            validator().validate_complete_flow(data)

    def test_visible_touch_result_lines_remain_unique_and_agree_with_payload(self):
        text = self.data['reopened_result_stats_text']
        for bad in (text.replace('00:41.183', '00:42.000'), text + '\nBeste Runde   00:41.183',
                    text + '\nGesamtzeit   01:22.983'):
            with self.subTest(bad=bad):
                self.rejects(('reopened_result_stats_text',), bad)
        self.rejects(('reopened_result_stats_visible',), False)
        self.rejects(('actual_result_stats_text',), text.replace('01:22.983', '01:23.000'))

    def test_touch_reopened_controls_actions_and_title_are_correct_in_both_frames(self):
        for stage in ((), ('after_tick',)):
            with self.subTest(stage=stage):
                self.rejects(('reopened_result_ui', *stage, 'controls_visible'), True)
                self.rejects(('reopened_result_ui', *stage, 'message_text'), 'Paused')
                for action in ('gas', 'brake', 'drift', 'boost', 'item'):
                    self.rejects(('reopened_result_ui', *stage, 'action_disabled', action), False)

    def test_touch_hud_uses_actual_zero_text_and_preserves_raw_speed(self):
        for stage in ((), ('after_tick',)):
            for text in ('43 km/h', '0 km/h 43 km/h', 'RUNDE 2'):
                with self.subTest(stage=stage, text=text):
                    self.rejects(('reopened_result_ui', *stage, 'hud_text'), text)
            self.rejects(('reopened_result_ui', *stage, 'displayed_speed_kmh'), False)
        self.rejects(('reopened_result_ui', 'after_tick', 'raw_speed'), 10.0)

    def test_touch_png_roles_are_exact_six_and_reopened_digest_agrees(self):
        for action in ('missing', 'extra', 'invalid-digest', 'mismatched-reopen', 'wrong-role'):
            with self.subTest(action=action):
                data = copy.deepcopy(self.data)
                if action == 'missing':
                    del data['screenshot_sha256']['06-reopened-result.png']
                elif action == 'extra':
                    data['screenshot_sha256']['07-invented.png'] = 'a' * 64
                elif action == 'invalid-digest':
                    data['screenshot_sha256']['01-start-grid.png'] = False
                elif action == 'mismatched-reopen':
                    data['reopened_result_screenshot_sha256'] = 'a' * 64
                else:
                    data['reopened_result_screenshot'] = '../result.png'
                with self.assertRaises(ValueError):
                    validator().validate_complete_flow(data)

    def test_malformed_touch_check_shapes_fail_with_value_error(self):
        for index, bad in ((0, None), (1, {}), (4, None), (7, {}), (8, [])):
            with self.subTest(index=index):
                self.rejects(('checks', index, 'actual'), bad)


class TimeFormatEvidenceRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.data = fixture('native_time_format_29.json')

    def rejects(self, path, value):
        data = copy.deepcopy(self.data)
        set_path(data, path, value)
        with self.assertRaises(ValueError):
            validator().validate_time_format(data)

    def test_closed_actual_time_fixture_is_byte_exact_and_valid(self):
        raw = (FIXTURES / 'native_time_format_29.json').read_bytes()
        self.assertEqual(hashlib.sha256(raw).hexdigest(),
                         'b0265280ff7f9575847811a91c416ecb1ea9508bf3a3acb53cc503297abeae1e')
        self.assertIsNone(validator().validate_time_format(self.data))

    def test_formatter_root_and_counts_are_strict(self):
        for value in (None, [], True):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validator().validate_time_format(value)
        self.rejects(('passed',), 28)
        self.rejects(('failed',), False)
        self.rejects(('status',), 'FAIL')

    def test_formatter_engine_and_scope_cannot_be_reclassified(self):
        self.rejects(('engine', 'patch'), 2)
        self.rejects(('engine', 'patch'), True)
        self.rejects(('scope',), 'Android race performance verified')

    def test_formatter_carries_seconds_and_minutes_after_millisecond_rounding(self):
        self.rejects(('checks', 7, 'observed'), '00:00.1000')
        self.rejects(('checks', 18, 'observed'), '00:59.1000')
        self.rejects(('checks', 25, 'observed'), '59:59.1000')

    def test_formatter_half_millisecond_boundary_is_preserved(self):
        self.rejects(('checks', 2, 'observed'), '00:00.000')
        self.rejects(('checks', 1, 'observed'), '00:00.001')

    def test_formatter_known_actual_lap_and_payload_do_not_retain_float_noise(self):
        self.rejects(('checks', 15, 'observed'), '00:40.1000')
        self.rejects(('checks', 16, 'observed'), '00:40.999')

    def test_formatter_missing_extra_or_reordered_boundary_cases_are_rejected(self):
        for action in ('missing', 'extra', 'reordered'):
            with self.subTest(action=action):
                data = copy.deepcopy(self.data)
                if action == 'missing':
                    data['checks'].pop()
                elif action == 'extra':
                    data['checks'].append(copy.deepcopy(data['checks'][0]))
                else:
                    data['checks'][1], data['checks'][2] = data['checks'][2], data['checks'][1]
                with self.assertRaises(ValueError):
                    validator().validate_time_format(data)

    def test_formatter_flags_numbers_and_sources_are_not_coerced(self):
        for path, bad in ((('checks', 0, 'pass'), 1), (('checks', 0, 'seconds'), False),
                          (('checks', 0, 'seconds'), float('nan')),
                          (('checks', 0, 'source'), 'forced race state')):
            with self.subTest(path=path):
                self.rejects(path, bad)

    def test_formatter_expected_and_observed_cannot_both_be_forged(self):
        data = copy.deepcopy(self.data)
        data['checks'][2]['expected'] = '00:00.000'
        data['checks'][2]['observed'] = '00:00.000'
        with self.assertRaises(ValueError):
            validator().validate_time_format(data)

    def test_malformed_formatter_case_shape_fails_with_value_error(self):
        self.rejects(('checks', 0), None)
        data = copy.deepcopy(self.data)
        del data['checks'][0]['seconds']
        with self.assertRaises(ValueError):
            validator().validate_time_format(data)


class EvidenceFileBindingRecoveryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-evidence-binding-unit-')
        self.addCleanup(temporary.cleanup)
        self.out = Path(temporary.name)

    def write(self, name, raw):
        path = self.out / name
        path.write_bytes(raw)
        return path

    def png_bytes(self, width=1280, height=720):
        """A complete generated unit fixture; this is never a runtime image."""
        def chunk(kind, raw):
            return (struct.pack('>I', len(raw)) + kind + raw
                    + struct.pack('>I', zlib.crc32(kind + raw) & 0xffffffff))
        ihdr = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
        # Even invalid-dimension fixtures stay small and never decode to an app.
        rows = (b'\x00' + bytes((8, 27, 67)) * width) * height
        return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr)
                + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))

    def test_json_loader_binds_actual_fixture_bytes_and_digest(self):
        path = FIXTURES / 'native_lap_continuity_104.json'
        value, sha = validator().load_evidence(path)
        self.assertEqual(value, fixture(path.name))
        self.assertEqual(sha, hashlib.sha256(path.read_bytes()).hexdigest())

    def test_json_loader_rejects_duplicate_keys_at_root_and_nested_levels(self):
        for index, raw in enumerate((b'{"status":"PASS","status":"FAIL"}',
                                    b'{"nested":{"solved":0,"solved":false}}')):
            with self.subTest(index=index), self.assertRaises(ValueError):
                validator().load_evidence(self.write(f'duplicate-{index}.json', raw))

    def test_json_loader_rejects_nonfinite_constants(self):
        for index, value in enumerate(('NaN', 'Infinity', '-Infinity')):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validator().load_evidence(self.write(f'nonfinite-{index}.json',
                                                    ('{"time":' + value + '}').encode()))

    def test_json_loader_rejects_empty_invalid_utf8_and_malformed_json(self):
        for index, raw in enumerate((b'', b'\xff', b'{"status":')):
            with self.subTest(index=index), self.assertRaises(ValueError):
                validator().load_evidence(self.write(f'bad-{index}.json', raw))

    def test_file_binding_accepts_only_actual_nonempty_regular_bytes(self):
        raw = b'controlled source bytes\n'
        path = self.write('controlled.gd', raw)
        self.assertIsNone(validator().bound_file(path, hashlib.sha256(raw).hexdigest()))

    def test_file_binding_rejects_mismatched_and_changed_source_bytes(self):
        raw = b'controlled source bytes\n'
        path = self.write('changed.gd', raw)
        with self.assertRaises(ValueError):
            validator().bound_file(path, 'a' * 64)
        expected = hashlib.sha256(raw).hexdigest()
        path.write_bytes(raw + b'changed')
        with self.assertRaises(ValueError):
            validator().bound_file(path, expected)

    def test_file_binding_rejects_missing_empty_directory_symlink_and_fifo(self):
        regular = self.write('regular.gd', b'controlled source')
        paths = [self.out / 'missing.gd', self.write('empty.gd', b''), self.out / 'directory',
                 self.out / 'alias.gd', self.out / 'pipe.gd']
        paths[2].mkdir()
        paths[3].symlink_to(regular)
        os.mkfifo(paths[4])
        expected = hashlib.sha256(regular.read_bytes()).hexdigest()
        for path in paths:
            with self.subTest(path=path.name), self.assertRaises(ValueError):
                validator().bound_file(path, expected)

    def test_png_binding_accepts_complete_generated_fixture_of_actual_viewport(self):
        raw = self.png_bytes()
        path = self.write('controlled.png', raw)
        self.assertIsNone(validator().bound_png(path, hashlib.sha256(raw).hexdigest()))

    def test_png_binding_rejects_changed_bytes_and_wrong_declared_digest(self):
        raw = self.png_bytes()
        path = self.write('changed.png', raw)
        with self.assertRaises(ValueError):
            validator().bound_png(path, 'a' * 64)
        expected = hashlib.sha256(raw).hexdigest()
        path.write_bytes(raw + b'changed')
        with self.assertRaises(ValueError):
            validator().bound_png(path, expected)

    def test_png_binding_rejects_wrong_signature_ihdr_and_dimensions(self):
        good = self.png_bytes()
        variants = [b'not-png' + good[7:], good[:12] + b'WRNG' + good[16:],
                    self.png_bytes(640, 360), self.png_bytes(1280, 0), good[:24]]
        for index, raw in enumerate(variants):
            with self.subTest(index=index), self.assertRaises(ValueError):
                validator().bound_png(self.write(f'invalid-{index}.png', raw),
                                      hashlib.sha256(raw).hexdigest())

    def test_png_binding_rejects_unclosed_truncated_or_crc_corrupt_declared_bytes(self):
        good = self.png_bytes()
        corrupted = bytearray(good)
        corrupted[-13] ^= 1
        variants = [good[:-12], good[:40], bytes(corrupted), good + b'after-IEND']
        for index, raw in enumerate(variants):
            with self.subTest(index=index), self.assertRaises(ValueError):
                validator().bound_png(self.write(f'incomplete-{index}.png', raw),
                                      hashlib.sha256(raw).hexdigest())

    def test_summary_aborts_on_wrong_source_before_reading_runtime_artifacts(self):
        godot = self.out / 'godot'
        games = godot / 'scripts/games'
        games.mkdir(parents=True)
        (games / 'kart_island.gd').write_bytes(b'controlled foreign source, never a runtime')
        with self.assertRaisesRegex(ValueError, 'SHA256 mismatch'):
            validator().summarize_native_lap_evidence(godot)

    def test_summary_missing_source_is_value_error_and_never_creates_a_pass(self):
        with self.assertRaises(ValueError):
            validator().summarize_native_lap_evidence(self.out / 'missing-godot')


class MirroredHudAndPhysicalObservationRecoveryTests(unittest.TestCase):
    """Mirror the recorded checks so rejection tests the observation itself."""
    @staticmethod
    def mirror_ui(data, key, check_index):
        state = data[key]
        data['checks'][check_index]['actual'] = {
            'immediate': {name: copy.deepcopy(value) for name, value in state.items()
                          if name != 'after_tick'},
            'after_tick': copy.deepcopy(state['after_tick']),
        }

    def assert_continuity_hud_rejected(self, key, check_index):
        malformed = ('-0 km/h', '+0 km/h', 'x0 km/h', '0 km/hx',
                     '0 km/h extra km/h', '0 km/h -8 km/h')
        for stage in ((), ('after_tick',)):
            for text in malformed:
                with self.subTest(key=key, stage=stage, text=text):
                    data = fixture('native_lap_continuity_104.json')
                    set_path(data, (key, *stage, 'hud_text'), text)
                    self.mirror_ui(data, key, check_index)
                    with self.assertRaises(ValueError):
                        validator().validate_lap_session(data)

    def test_mirrored_ranked_result_rejects_signed_embedded_suffixed_and_extra_hud_tokens(self):
        self.assert_continuity_hud_rejected('reopened_result_ui', 29)

    def test_mirrored_direct_result_rejects_signed_embedded_suffixed_and_extra_hud_tokens(self):
        self.assert_continuity_hud_rejected('direct_result_ui', 103)

    def test_mirrored_touch_result_rejects_invalid_hud_tokens_in_both_frames(self):
        for stage in ((), ('after_tick',)):
            for text in ('-0 km/h', '+0 km/h', 'x0 km/h', '0 km/hx',
                         '0 km/h extra km/h', '0 km/h -8 km/h'):
                with self.subTest(stage=stage, text=text):
                    data = fixture('native_lap_flow_9.json')
                    set_path(data, ('reopened_result_ui', *stage, 'hud_text'), text)
                    self.mirror_ui(data, 'reopened_result_ui', 7)
                    with self.assertRaises(ValueError):
                        validator().validate_complete_flow(data)

    def test_time_trial_drive_and_pause_reject_signed_embedded_and_extra_43_tokens(self):
        for stage in ('driving', 'paused'):
            for text in ('-43 km/h', '+43 km/h', 'x43 km/h', '43 km/hx',
                         '43 km/h extra km/h', '43 km/h -8 km/h'):
                with self.subTest(stage=stage, text=text):
                    data = fixture('native_lap_continuity_104.json')
                    data['checks'][100]['actual'][stage]['hud_text'] = text
                    with self.assertRaises(ValueError):
                        validator().validate_lap_session(data)

    def test_mirrored_touch_raw_speed_requires_float_even_for_numeric_zero(self):
        for value in (0, False):
            with self.subTest(value=value):
                data = fixture('native_lap_flow_9.json')
                data['reopened_result_ui']['raw_speed'] = value
                data['reopened_result_ui']['after_tick']['raw_speed'] = value
                self.mirror_ui(data, 'reopened_result_ui', 7)
                with self.assertRaises(ValueError):
                    validator().validate_complete_flow(data)

    def test_mirrored_driven_gate_observations_require_float_not_integer_or_boolean(self):
        for key, value in (('seconds', 1), ('distance', 10),
                           ('seconds', True), ('distance', True)):
            with self.subTest(key=key, value=value):
                data = fixture('native_lap_continuity_104.json')
                data['ordered_gates'][0][key] = value
                data['checks'][1]['actual'] = copy.deepcopy(data['ordered_gates'][:10])
                data['checks'][17]['actual'] = copy.deepcopy(data['ordered_gates'])
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(data)

    def test_driven_frame_count_must_match_raw_elapsed_at_60_physics_steps(self):
        for value in (3072, 3074, 1, 12000, True, 3073.0):
            with self.subTest(value=value):
                data = fixture('native_lap_continuity_104.json')
                data['driven_frames'] = value
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(data)

    def test_source_correct_place_titles_support_all_six_integer_ranks_only(self):
        expected = {1: '1. PLATZ!', 2: '2. Platz!', 3: '3. Platz!',
                    4: 'Platz 4', 5: 'Platz 5', 6: 'Platz 6'}
        for place, title in expected.items():
            with self.subTest(place=place):
                self.assertEqual(validator().place_title(place), title)
        for value in (0, 7, -1, True, False, 1.0, '1', None):
            with self.subTest(value=value), self.assertRaises(ValueError):
                validator().place_title(value)

    def test_existing_wallet_star_counter_is_dynamic_but_typed_and_unchanged(self):
        data = fixture('native_lap_continuity_104.json')
        data['checks'][26]['expected']['local_stars'] = 58
        data['checks'][26]['actual']['local_stars'] = 58
        self.assertIsNone(validator().validate_lap_session(data))
        for value in (2, 58.0, True):
            with self.subTest(value=value):
                bad = copy.deepcopy(data)
                bad['checks'][26]['expected']['local_stars'] = value
                bad['checks'][26]['actual']['local_stars'] = value
                with self.assertRaises(ValueError):
                    validator().validate_lap_session(bad)

    def test_actual_driven_raw_speed_is_dynamic_when_float_and_frozen_across_ticks(self):
        for key, index, speed in (('reopened_result_ui', 29, 17.0),
                                  ('direct_result_ui', 103, 8.0)):
            with self.subTest(key=key, speed=speed):
                data = fixture('native_lap_continuity_104.json')
                data[key]['raw_speed'] = speed
                data[key]['after_tick']['raw_speed'] = speed
                self.mirror_ui(data, key, index)
                self.assertIsNone(validator().validate_lap_session(data))

    def test_dynamic_driven_raw_speed_rejects_type_negative_and_after_tick_mutation(self):
        for key, index in (('reopened_result_ui', 29), ('direct_result_ui', 103)):
            for value in (True, 17, -1.0, float('nan')):
                with self.subTest(key=key, value=value):
                    data = fixture('native_lap_continuity_104.json')
                    data[key]['raw_speed'] = value
                    data[key]['after_tick']['raw_speed'] = value
                    self.mirror_ui(data, key, index)
                    with self.assertRaises(ValueError):
                        validator().validate_lap_session(data)
            data = fixture('native_lap_continuity_104.json')
            data[key]['raw_speed'] = 17.0
            data[key]['after_tick']['raw_speed'] = 8.0
            self.mirror_ui(data, key, index)
            with self.assertRaises(ValueError):
                validator().validate_lap_session(data)

    def test_formatter_official_engine_hash_and_hex_are_source_bound(self):
        for key, value in (('hash', 'f' * 40), ('hash', False),
                           ('hex', 263682), ('hex', True), ('hex', 263683.0)):
            with self.subTest(key=key, value=value):
                data = fixture('native_time_format_29.json')
                data['engine'][key] = value
                with self.assertRaises(ValueError):
                    validator().validate_time_format(data)
        for key in ('hash', 'hex'):
            with self.subTest(missing=key):
                data = fixture('native_time_format_29.json')
                del data['engine'][key]
                with self.assertRaises(ValueError):
                    validator().validate_time_format(data)


if __name__ == '__main__':
    unittest.main(verbosity=2)
