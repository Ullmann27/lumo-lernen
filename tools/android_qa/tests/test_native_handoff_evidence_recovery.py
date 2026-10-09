"""New lifecycle contract guards with explicitly synthetic, non-runtime inputs.

The fixture describes source-assigned cases, not an executed GL or Android run.
Summary positives mock only source-byte checks; exact three path/hash calls are
asserted. Source negatives use the real unchanged SHA256 binding utility.
Temporary JSON and logs are controlled test input, never runtime evidence.
"""
from __future__ import annotations

import copy
import hashlib
import importlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import call, patch

sys.dont_write_bytecode = True
QA = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(QA))
FIXTURE = Path(__file__).with_name('fixtures') / 'native_handoff_lifecycle_10_synthetic.json'
PROVENANCE = 'SYNTHETIC_SOURCE_CONTRACT_NOT_RUNTIME'
SOURCE_SHA = '7247dd551b900194936d60d31e4436d0e2a9dc74fb4c91e2306d94f6d8689c8c'
PROBE_SHA = 'f82c717207786cf666f66ff33dbbda5992e11b17623f5481ab58750dc263441f'
HELPER_SHA = 'fb78dcba3a212ef8b540a2b125fe7baabe123d1f85975451ebaddde9a3d96cef'
PROBE_PATH = 'res://scripts/tests/kart_race_continuity_regression.gd'
SCOPE = ('Assigned elapsed/checkpoint/distance state; real _finish, return, '
         'natural queue_free and fresh garage; no driven-lap claim')
LIFECYCLE_PASS = '[KartHandoffLifecycle] PASS: 10 checks, 0 failures'
CONTINUITY_PASS = ('[KartContinuity] PASS: quality change, save/reopen, next lap, '
                   'rival states, legacy saves and flight reset')
NAMES = (
    'accepted completed return initially removes the session',
    'accepted return retains one reward and original result ID',
    'natural scene teardown cannot recreate an accepted completed session',
    'fresh garage cannot offer an already handed-off result',
    'failed host return retains a durable completed session after teardown',
    'accepted unfinished paused return retains resumable progress',
    'accepted cup result retains continuation state',
    'new race after handoff can persist its fresh identity',
    'standalone return performs the real SceneRouter transition',
    'standalone accepted route teardown cannot recreate its completed session',
)
STATIC_VALUES = {0: False, 2: False, 3: False, 4: True, 5: True, 6: True,
                 7: True, 8: 'res://scenes/games/game_hub.tscn', 9: False}
SOURCES = (
    ('scripts/games/kart_island.gd', SOURCE_SHA),
    ('scripts/tests/kart_race_continuity_regression.gd', PROBE_SHA),
    ('scripts/tests/kart_handoff_lifecycle_fixtures.gd', HELPER_SHA),
)
SUMMARY_KEYS = {'handoff_lifecycle_checks', 'handoff_lifecycle_evidence_sha256',
                'handoff_lifecycle_source_sha256', 'handoff_lifecycle_probe_sha256',
                'handoff_lifecycle_helper_sha256'}


def validator():
    return importlib.import_module('native_handoff_evidence_recovery')


def fixture():
    return json.loads(FIXTURE.read_text(encoding='utf-8'))


def set_path(data, path, value):
    target = data
    for part in path[:-1]:
        target = target[part]
    target[path[-1]] = value


class HandoffLifecycleContractTests(unittest.TestCase):
    def setUp(self):
        self.data = fixture()['evidence']

    def rejects(self, path, value):
        data = copy.deepcopy(self.data)
        set_path(data, path, value)
        with self.assertRaises(ValueError):
            validator().validate_handoff_lifecycle(data)

    def test_fixture_explicitly_marks_synthetic_scope_and_valid_source_contract(self):
        envelope = fixture()
        self.assertEqual(set(envelope), {'fixture_provenance', 'evidence'})
        self.assertEqual(envelope['fixture_provenance'], PROVENANCE)
        self.assertEqual(tuple(row['name'] for row in self.data['checks']), NAMES)
        self.assertEqual(validator().SOURCE_SHA256, SOURCE_SHA)
        self.assertEqual(validator().PROBE_SHA256, PROBE_SHA)
        self.assertEqual(validator().HELPER_SHA256, HELPER_SHA)
        self.assertIsNone(validator().validate_handoff_lifecycle(self.data))

    def test_dynamic_identity_accepts_distinct_source_generated_ids(self):
        for result_id in ('natural-ack-state-fixture-1700000000000-12345',
                          'natural-ack-state-fixture-1700000000001-54321'):
            with self.subTest(result_id=result_id):
                data = copy.deepcopy(self.data)
                for side in ('expected', 'actual'):
                    data['checks'][1][side]['resultId'] = result_id
                self.assertIsNone(validator().validate_handoff_lifecycle(data))

    def test_non_object_roots_and_synthetic_envelope_are_not_runtime_evidence(self):
        for data in (None, [], 10, True, 'PASS', fixture()):
            with self.subTest(data=data), self.assertRaises(ValueError):
                validator().validate_handoff_lifecycle(data)

    def test_exact_nine_root_fields_cannot_be_missing_or_extended(self):
        for key in self.data:
            with self.subTest(missing=key):
                data = copy.deepcopy(self.data)
                del data[key]
                with self.assertRaises(ValueError):
                    validator().validate_handoff_lifecycle(data)
        for key, value in (('check_count', 10), ('failed_checks', 0),
                           ('fixture_provenance', PROVENANCE), ('runtime_fps', 60)):
            with self.subTest(extra=key):
                data = copy.deepcopy(self.data)
                data[key] = value
                with self.assertRaises(ValueError):
                    validator().validate_handoff_lifecycle(data)

    def test_status_and_rendered_display_require_exact_strings(self):
        for path, bad in ((('status',), 'FAIL'), (('status',), True),
                          (('status',), 'pass'), (('display_server',), 'headless'),
                          (('display_server',), 'Android'), (('display_server',), True)):
            with self.subTest(path=path, bad=bad):
                self.rejects(path, bad)

    def test_ten_ordered_rows_reject_missing_extra_reordered_and_non_list_checks(self):
        variants = [None, {}, tuple(self.data['checks']), self.data['checks'][:-1],
                    self.data['checks'] + [copy.deepcopy(self.data['checks'][-1])]]
        reordered = copy.deepcopy(self.data['checks'])
        reordered[2], reordered[3] = reordered[3], reordered[2]
        variants.append(reordered)
        for index, bad in enumerate(variants):
            with self.subTest(index=index):
                self.rejects(('checks',), bad)

    def test_each_row_has_exact_object_fields(self):
        for index in range(10):
            for bad in (None, [], 'PASS', True):
                with self.subTest(index=index, bad=bad):
                    self.rejects(('checks', index), bad)
            for key in ('name', 'passed', 'expected', 'actual'):
                with self.subTest(index=index, missing=key):
                    data = copy.deepcopy(self.data)
                    del data['checks'][index][key]
                    with self.assertRaises(ValueError):
                        validator().validate_handoff_lifecycle(data)
            data = copy.deepcopy(self.data)
            data['checks'][index]['extra'] = 'invented observation'
            with self.subTest(index=index, extra=True), self.assertRaises(ValueError):
                validator().validate_handoff_lifecycle(data)

    def test_source_ordered_labels_cannot_be_changed_duplicated_or_coerced(self):
        for index in range(10):
            for bad in ('invented lifecycle case', NAMES[(index + 1) % 10], True, index):
                with self.subTest(index=index, bad=bad):
                    self.rejects(('checks', index, 'name'), bad)

    def test_every_passed_flag_requires_true_boolean(self):
        for index in range(10):
            for bad in (False, 1, 1.0, 'true', None, {}, {'passed': True}):
                with self.subTest(index=index, bad=bad):
                    self.rejects(('checks', index, 'passed'), bad)

    def test_each_static_expectation_and_observation_is_source_bound_and_typed(self):
        for index, expected in STATIC_VALUES.items():
            bad_values = ((not expected, int(expected), str(expected), None)
                          if type(expected) is bool else
                          ('res://scenes/games/kart_island.tscn', '', True, None))
            for side in ('expected', 'actual'):
                for bad in bad_values:
                    with self.subTest(index=index, side=side, bad=bad):
                        self.rejects(('checks', index, side), bad)

    def test_mirrored_static_forgeries_do_not_gain_validity_from_passed_true(self):
        for index, expected in STATIC_VALUES.items():
            bad_values = ((not expected, int(expected)) if type(expected) is bool else
                          ('res://scenes/games/kart_island.tscn', True))
            for bad in bad_values:
                with self.subTest(index=index, bad=bad):
                    data = copy.deepcopy(self.data)
                    for side in ('expected', 'actual'):
                        data['checks'][index][side] = bad
                    with self.assertRaises(ValueError):
                        validator().validate_handoff_lifecycle(data)

    def test_dynamic_handoff_objects_require_exact_three_keys(self):
        for side in ('expected', 'actual'):
            for bad in (None, [], True, 1, 'same ID'):
                with self.subTest(side=side, bad=bad):
                    self.rejects(('checks', 1, side), bad)
            for key in ('reward_calls', 'returns', 'resultId'):
                with self.subTest(side=side, missing=key):
                    data = copy.deepcopy(self.data)
                    del data['checks'][1][side][key]
                    with self.assertRaises(ValueError):
                        validator().validate_handoff_lifecycle(data)
            data = copy.deepcopy(self.data)
            data['checks'][1][side]['duplicate_reward'] = False
            with self.subTest(side=side, extra=True), self.assertRaises(ValueError):
                validator().validate_handoff_lifecycle(data)

    def test_reward_and_return_counts_require_integer_one_even_when_mirrored(self):
        for key in ('reward_calls', 'returns'):
            for bad in (0, 2, True, False, 1.0, '1', None):
                for sides in (('expected',), ('actual',), ('expected', 'actual')):
                    with self.subTest(key=key, bad=bad, sides=sides):
                        data = copy.deepcopy(self.data)
                        for side in sides:
                            data['checks'][1][side][key] = bad
                        with self.assertRaises(ValueError):
                            validator().validate_handoff_lifecycle(data)

    def test_result_identity_requires_source_session_prefix_and_two_digit_fields(self):
        for bad in ('', 'foreign-session-1700000000000-12345', 'natural-ack-state-fixture',
                    'natural-ack-state-fixture-1', 'natural-ack-state-fixture--1-2',
                    'natural-ack-state-fixture-1-2-extra', 'natural-ack-state-fixture-1.0-2',
                    'natural-ack-state-fixture-1-x', 'natural-ack-state-fixture-1-2\n',
                    True, 123, None):
            with self.subTest(bad=bad):
                data = copy.deepcopy(self.data)
                for side in ('expected', 'actual'):
                    data['checks'][1][side]['resultId'] = bad
                with self.assertRaises(ValueError):
                    validator().validate_handoff_lifecycle(data)

    def test_actual_result_identity_cannot_switch_to_another_valid_generated_id(self):
        self.rejects(('checks', 1, 'actual', 'resultId'),
                     'natural-ack-state-fixture-1700000000001-54321')

    def test_three_source_identities_require_actual_digests_not_only_digest_shape(self):
        for key in ('source_sha256', 'probe_sha256', 'helper_sha256'):
            for bad in ('', 'abc', 'f' * 64, 'g' * 64, True, 1, None):
                with self.subTest(key=key, bad=bad):
                    self.rejects((key,), bad)

    def test_producer_path_binds_active_continuity_and_never_inactive_bridge(self):
        for bad in ('res://scripts/tests/kart_host_bridge_regression.gd',
                    'res://scripts/tests/kart_handoff_lifecycle_fixtures.gd',
                    'scripts/tests/kart_race_continuity_regression.gd', '', True):
            with self.subTest(bad=bad):
                self.rejects(('probe_path',), bad)

    def test_scope_cannot_claim_physical_driving_or_suppress_assigned_state(self):
        for bad in ('physically driven laps', SCOPE.replace('Assigned ', ''),
                    SCOPE.replace('no driven-lap claim', 'driven lap passed'),
                    SCOPE + ' and Android 60 FPS', True):
            with self.subTest(bad=bad):
                self.rejects(('fixture_scope',), bad)

    def test_official_engine_fields_are_required_typed_and_source_bound(self):
        for bad in (None, [], '4.6.3-stable (official)', True):
            with self.subTest(engine=bad):
                self.rejects(('engine',), bad)
        values = {'major': (3, True, 4.0), 'minor': (5, True, 6.0),
                  'patch': (2, True, 3.0), 'status': ('dev', True),
                  'build': ('custom', True), 'string': ('4.6.2-stable (official)', True),
                  'hash': ('f' * 40, True), 'hex': (263682, True, 263683.0)}
        for key, bad_values in values.items():
            data = copy.deepcopy(self.data)
            del data['engine'][key]
            with self.subTest(missing=key), self.assertRaises(ValueError):
                validator().validate_handoff_lifecycle(data)
            for bad in bad_values:
                with self.subTest(key=key, bad=bad):
                    self.rejects(('engine', key), bad)


class HandoffLifecycleSummaryTests(unittest.TestCase):
    """Controlled files and source-check mocks are not new probe execution."""
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.out = Path(self.temporary.name)
        self.godot = self.out / 'controlled-godot'
        self.data = fixture()['evidence']
        self.directory = self.godot / 'exports/race-bridge'
        self.evidence_path = self.directory / 'handoff-lifecycle-evidence.json'
        self.log_path = self.godot / 'exports/fold-controls/kart_race_continuity_regression.log'
        self.write(self.evidence_path, json.dumps(self.data, indent=2).encode())
        result_id = self.data['checks'][1]['actual']['resultId']
        self.reward_line = '[LumoHost] reward reported: ' + result_id
        self.log = '\n'.join((self.reward_line, LIFECYCLE_PASS, CONTINUITY_PASS)) + '\n'
        self.write(self.log_path, self.log.encode())

    @staticmethod
    def write(path, raw):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(raw)
        return path

    def controlled_summary(self, **kwargs):
        with patch.object(validator(), 'bound_file') as source_checks:
            result = validator().summarize_handoff_lifecycle(self.godot, **kwargs)
        self.assertEqual(source_checks.call_args_list,
                         [call(self.godot / relative, digest) for relative, digest in SOURCES])
        return result

    def rejects_summary(self, **kwargs):
        with patch.object(validator(), 'bound_file'), self.assertRaises(ValueError):
            validator().summarize_handoff_lifecycle(self.godot, **kwargs)

    def test_controlled_default_summary_returns_exact_five_keys_and_source_bindings(self):
        result = self.controlled_summary()
        self.assertEqual(set(result), SUMMARY_KEYS)
        self.assertIs(type(result['handoff_lifecycle_checks']), int)
        self.assertEqual(result['handoff_lifecycle_checks'], 10)
        self.assertEqual(result['handoff_lifecycle_evidence_sha256'],
                         hashlib.sha256(self.evidence_path.read_bytes()).hexdigest())
        self.assertEqual(result['handoff_lifecycle_source_sha256'], SOURCE_SHA)
        self.assertEqual(result['handoff_lifecycle_probe_sha256'], PROBE_SHA)
        self.assertEqual(result['handoff_lifecycle_helper_sha256'], HELPER_SHA)

    def test_explicit_artifact_and_log_paths_work_with_other_fixture_reward_ids(self):
        directory = self.out / 'controlled-override-evidence'
        path = self.write(directory / self.evidence_path.name, self.evidence_path.read_bytes())
        log = self.out / 'controlled-override.log'
        self.write(log, (self.log + '[LumoHost] reward reported: '
                         'natural-ack-state-fixture-1700000000001-999\n').encode())
        self.evidence_path.unlink()
        self.log_path.unlink()
        result = self.controlled_summary(lifecycle_directory=directory, continuity_log=log)
        self.assertEqual(result['handoff_lifecycle_evidence_sha256'],
                         hashlib.sha256(path.read_bytes()).hexdigest())

    def test_each_real_hash_binding_rejects_foreign_bytes_before_artifact_loading(self):
        utility = importlib.import_module('native_lap_evidence_recovery')
        for relative, expected_sha in SOURCES:
            with self.subTest(relative=relative):
                target = self.write(self.godot / relative,
                                    b'controlled foreign source; no runtime executed\n')
                observed = []

                def checked_binding(path, digest):
                    self.assertIn((str(path.relative_to(self.godot)), digest), SOURCES)
                    observed.append((path, digest))
                    if path == target:
                        utility.bound_file(path, digest)

                with patch.object(validator(), 'bound_file', side_effect=checked_binding), \
                     patch.object(validator(), 'load_evidence') as artifacts, \
                     self.assertRaisesRegex(ValueError, 'SHA256 mismatch'):
                    validator().summarize_handoff_lifecycle(self.godot)
                artifacts.assert_not_called()
                self.assertIn((target, expected_sha), observed)

    def test_real_source_binding_rejects_missing_empty_directory_and_symlink(self):
        path = self.godot / SOURCES[0][0]
        path.parent.mkdir(parents=True, exist_ok=True)
        with self.assertRaises(ValueError):
            validator().summarize_handoff_lifecycle(self.godot)
        path.write_bytes(b'')
        with self.assertRaises(ValueError):
            validator().summarize_handoff_lifecycle(self.godot)
        path.unlink()
        path.mkdir()
        with self.assertRaises(ValueError):
            validator().summarize_handoff_lifecycle(self.godot)
        path.rmdir()
        target = self.write(self.out / 'controlled-source-target', b'nonempty foreign bytes')
        path.symlink_to(target)
        with self.assertRaises(ValueError):
            validator().summarize_handoff_lifecycle(self.godot)

    def test_artifact_loader_rejects_missing_empty_malformed_duplicate_and_nonfinite_json(self):
        self.evidence_path.unlink()
        self.rejects_summary()
        for raw in (b'', b'{', b'\xff', b'{"status":"PASS","status":"FAIL"}',
                    b'{"status":NaN}', b'{"status":Infinity}', b'{"status":-Infinity}',
                    json.dumps(fixture()).encode()):
            with self.subTest(raw=raw):
                self.write(self.evidence_path, raw)
                self.rejects_summary()
        self.evidence_path.unlink()
        target = self.write(self.out / 'controlled-evidence-target.json',
                            json.dumps(self.data).encode())
        self.evidence_path.symlink_to(target)
        self.rejects_summary()

    def test_log_loader_rejects_missing_empty_invalid_utf8_directory_and_symlink(self):
        self.log_path.unlink()
        self.rejects_summary()
        for raw in (b'', b'\xff'):
            with self.subTest(raw=raw):
                self.write(self.log_path, raw)
                self.rejects_summary()
        self.log_path.unlink()
        self.log_path.mkdir()
        self.rejects_summary()
        self.log_path.rmdir()
        target = self.write(self.out / 'controlled-log-target', self.log.encode())
        self.log_path.symlink_to(target)
        self.rejects_summary()

    def test_summary_requires_both_original_continuity_and_lifecycle_pass_markers(self):
        for absent in (LIFECYCLE_PASS, CONTINUITY_PASS):
            with self.subTest(absent=absent):
                self.write(self.log_path, self.log.replace(absent, '').encode())
                self.rejects_summary()
        for bad in ('[KartHandoffLifecycle] PASS: 9 checks, 0 failures',
                    '[KartHandoffLifecycle] PASS: 10 checks, 1 failures'):
            with self.subTest(bad=bad):
                self.write(self.log_path, self.log.replace(LIFECYCLE_PASS, bad).encode())
                self.rejects_summary()

    def test_exact_once_lifecycle_line_rejects_duplicate_embedded_or_prefixed_pass(self):
        logs = (self.log + LIFECYCLE_PASS + '\n',
                self.log.replace(LIFECYCLE_PASS, 'quoted ' + LIFECYCLE_PASS),
                self.log.replace(LIFECYCLE_PASS, LIFECYCLE_PASS + ' extra'),
                self.log.replace(LIFECYCLE_PASS, ' ' + LIFECYCLE_PASS))
        for index, log in enumerate(logs):
            with self.subTest(index=index):
                self.write(self.log_path, log.encode())
                self.rejects_summary()

    def test_error_timeout_and_exit_leak_logs_cannot_be_hidden_by_pass_markers(self):
        errors = ('SCRIPT ERROR: controlled exception', 'Parse Error: controlled parse',
                  'ERROR: controlled renderer error', 'Assertion failed: controlled failure',
                  '[ProbeRunner] FAIL: missing final closure', '[ProbeRunner] timeout after 240s',
                  '[KartHandoffLifecycle] FAIL: natural scene teardown',
                  'WARNING: ObjectDB instances leaked at exit',
                  'ERROR: 2 resources still in use at exit')
        for error in errors:
            with self.subTest(error=error):
                self.write(self.log_path, (self.log + error + '\n').encode())
                self.rejects_summary()

    def test_matching_first_result_reward_log_is_required_exactly_once(self):
        logs = (self.log.replace(self.reward_line, ''), self.log + self.reward_line + '\n',
                self.log.replace(self.reward_line,
                                 '[LumoHost] reward reported: natural-ack-state-fixture-1-999'),
                self.log.replace(self.reward_line, 'quoted ' + self.reward_line),
                self.log.replace(self.reward_line, self.reward_line + ' extra'))
        for index, log in enumerate(logs):
            with self.subTest(index=index):
                self.write(self.log_path, log.encode())
                self.rejects_summary()

    def test_invalid_artifact_semantics_cannot_be_summarized_even_with_clean_pass_log(self):
        for path, bad in ((('checks', 2, 'actual'), True),
                          (('helper_sha256',), 'f' * 64),
                          (('probe_path',), 'res://scripts/tests/kart_host_bridge_regression.gd'),
                          (('checks', 1, 'actual', 'reward_calls'), 2)):
            with self.subTest(path=path):
                data = copy.deepcopy(self.data)
                set_path(data, path, bad)
                self.write(self.evidence_path, json.dumps(data).encode())
                self.rejects_summary()


if __name__ == '__main__':
    unittest.main(verbosity=2)
