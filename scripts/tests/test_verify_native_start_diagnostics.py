"""A green general tour cannot substitute for missing native game observations."""

import copy
import importlib.util
from pathlib import Path
import unittest


spec = importlib.util.spec_from_file_location(
    'native_start_gate', Path(__file__).resolve().parents[1] / 'verify_native_start_diagnostics.py')
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)
PACKAGE = 'dev.example.app'


class NativeStartGateTests(unittest.TestCase):
    def setUp(self):
        self.report = {'status': 'DONE', 'package': PACKAGE, 'scenes': [
            {'id': name, 'scene': name, 'path': 'ui', 'tapped': True,
             'router_loaded': True, 'game_process_alive_at_end': True,
             'app_alive_at_end': True, 'router_loaded_after_s': 5.0,
             'native_process_name': PACKAGE + ':lumo_game',
             'native_pid_at_end': 1234, 'router_loaded_pid': 1234,
             'process_snapshot_at_end': {PACKAGE: 5678, PACKAGE + ':lumo_game': 1234},
             'router_loaded_line': ('11-22 19:00:00.000  1234  1234 I godot: '
                                    f'[Router] loaded:{name} (res://scene.tscn)'),
             'issues': dict.fromkeys(gate.FATAL_ISSUES, 0)}
            for name in gate.REQUIRED]}

    def test_all_observed_native_ui_starts_pass_with_explicit_scope(self):
        result = gate.verify(self.report)
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(set(result['required_scenes']), set(gate.REQUIRED))
        self.assertIn('not full gameplay', result['scope'])
        self.assertEqual(result['required_scenes']['memory']['native_pid'], 1234)

    def test_flutter_memory_landing_is_not_a_native_table_proof(self):
        memory = next(e for e in self.report['scenes'] if e['id'] == 'memory')
        memory['router_loaded'] = False
        with self.assertRaisesRegex(ValueError, 'memory.*router_loaded'):
            gate.verify(self.report)

    def test_every_required_observation_must_exist_and_not_be_skipped(self):
        for name in gate.REQUIRED:
            with self.subTest(name=name):
                missing = copy.deepcopy(self.report)
                missing['scenes'] = [e for e in missing['scenes'] if e['id'] != name]
                with self.assertRaisesRegex(ValueError, name):
                    gate.verify(missing)
                skipped = copy.deepcopy(self.report)
                next(e for e in skipped['scenes'] if e['id'] == name)['skipped'] = 'Zeitbudget'
                with self.assertRaisesRegex(ValueError, name + '.*skipped'):
                    gate.verify(skipped)

    def test_crash_or_dead_game_is_rejected_even_if_router_loaded(self):
        for issue in gate.FATAL_ISSUES:
            with self.subTest(issue=issue):
                report = copy.deepcopy(self.report)
                report['scenes'][0]['issues'][issue] = 1
                with self.assertRaisesRegex(ValueError, issue):
                    gate.verify(report)
        self.report['scenes'][0]['game_process_alive_at_end'] = False
        with self.assertRaisesRegex(ValueError, 'game_process_alive_at_end'):
            gate.verify(self.report)

    def test_duplicate_or_intent_only_start_cannot_satisfy_ui_requirement(self):
        duplicate = copy.deepcopy(self.report)
        duplicate['scenes'].append(copy.deepcopy(duplicate['scenes'][0]))
        with self.assertRaisesRegex(ValueError, 'exactly one'):
            gate.verify(duplicate)
        self.report['scenes'][0]['path'] = 'intent'
        with self.assertRaisesRegex(ValueError, 'actual UI route'):
            gate.verify(self.report)

    def test_missing_crash_measurements_or_unfinished_diagnostics_are_rejected(self):
        self.report['scenes'][0]['issues'] = {}
        with self.assertRaisesRegex(ValueError, 'not measured'):
            gate.verify(self.report)
        self.report['status'] = 'RUNNING'
        with self.assertRaisesRegex(ValueError, 'did not finish'):
            gate.verify(self.report)

    def test_router_marker_must_belong_to_the_same_live_native_process_and_scene(self):
        for replacement in (
                {'router_loaded_pid': 9999},
                {'router_loaded_line': '11-22 19:00:00.000  9999  9999 I godot: [Router] loaded:run (x)'},
                {'router_loaded_line': '11-22 19:00:00.000  1234  1234 I godot: [Router] loaded:quiz (x)'},
                {'router_loaded_line': None}):
            with self.subTest(replacement=replacement):
                report = copy.deepcopy(self.report)
                report['scenes'][0].update(replacement)
                with self.assertRaisesRegex(ValueError, 'router scene and live native PID'):
                    gate.verify(report)

    def test_package_prefix_or_other_child_process_cannot_stand_in_for_native_engine(self):
        for process in (PACKAGE + '.other:lumo_game', PACKAGE + ':helper'):
            with self.subTest(process=process):
                report = copy.deepcopy(self.report)
                report['scenes'][0]['native_process_name'] = process
                report['scenes'][0]['process_snapshot_at_end'] = {PACKAGE: 5678, process: 1234}
                with self.assertRaisesRegex(ValueError, 'native process identity'):
                    gate.verify(report)


if __name__ == '__main__':
    unittest.main()
