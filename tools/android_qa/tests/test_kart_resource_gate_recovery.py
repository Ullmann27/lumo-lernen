"""Exercise the actual Kart final-PASS tail with controlled resource reads only.

No emulator, ADB or performance measurement occurs. Positive raw inputs reuse
unchanged repository parser fixtures; fake values are never device evidence.
"""
import ast
import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve()
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE.parents[1]))
from runtime_resource_evidence import capture_resources
from test_runtime_resource_evidence import FakeDevice, IDENTITY, READY, TABLE

PROBE = HERE.parents[3] / '.github/probes/kart_complete_android_probe.py'


def actual_pass_tail():
    tree = ast.parse(PROBE.read_text())
    main = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == 'main')
    outer = next(node for node in reversed(main.body) if isinstance(node, ast.Try))
    def assignment(node, key):
        return (isinstance(node, ast.Assign) and len(node.targets) == 1 and
                isinstance(node.targets[0], ast.Subscript) and
                isinstance(node.targets[0].value, ast.Name) and node.targets[0].value.id == 'result' and
                isinstance(node.targets[0].slice, ast.Constant) and node.targets[0].slice.value == key)
    end = next(index for index, node in enumerate(outer.body) if assignment(node, 'status'))
    start = max(index for index, node in enumerate(outer.body[:end]) if assignment(node, 'video'))
    nodes = copy.deepcopy(outer.body[start:end + 1])
    function = ast.FunctionDef(name='actual_tail', args=ast.arguments(posonlyargs=[], args=[ast.arg(arg='result'), ast.arg(arg='video')], vararg=None, kwonlyargs=[], kw_defaults=[], kwarg=None, defaults=[]), body=nodes, decorator_list=[])
    module = ast.Module(body=[function], type_ignores=[])
    spec = importlib.util.spec_from_file_location('kart_resource_gate_controlled', PROBE)
    production = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(production)
    namespace = dict(production.__dict__)
    exec(compile(ast.fix_missing_locations(module), str(PROBE), 'exec'), namespace)
    return namespace['actual_tail'], nodes


class FakeVideo:
    def stop(self):
        return {'status': 'PASS', 'errors': []}


class KartResourceGateRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.tail, self.nodes = actual_pass_tail()
        directory = tempfile.TemporaryDirectory(prefix='resource gate controlled ')
        self.addCleanup(directory.cleanup)
        self.out = Path(directory.name)
        self.record = dict(IDENTITY)
        self.record['status'] = 'FAIL'
        self.record['resource_snapshots'] = {}
        for phase in ('first-driving', 'completed-before-fold'):
            device = FakeDevice()
            value = capture_resources(device, self.out, phase, IDENTITY, READY, clock=device.clock)
            self.assertEqual(value['status'], 'PASS')
            self.record['resource_snapshots'][phase] = value

    def rejects(self, mutate):
        data = copy.deepcopy(self.record)
        mutate(data)
        with self.assertRaises(RuntimeError):
            self.tail(data, FakeVideo())
        self.assertNotEqual(data['status'], 'PASS')

    def test_both_real_parser_controlled_snapshots_allow_actual_final_pass(self):
        self.tail(self.record, FakeVideo())
        self.assertEqual(self.record['status'], 'PASS')

    def test_legitimate_meminfo_without_rss_remains_unavailable(self):
        for phase in self.record['resource_snapshots']:
            device = FakeDevice(mem=TABLE)
            self.record['resource_snapshots'][phase] = capture_resources(device, self.out, phase, IDENTITY, READY, clock=device.clock)
            self.assertIsNone(self.record['resource_snapshots'][phase]['rss_kib'])
        self.tail(self.record, FakeVideo())
        self.assertEqual(self.record['status'], 'PASS')

    def test_snapshots_missing_from_final_report_cannot_pass(self):
        self.rejects(lambda d: d.pop('resource_snapshots'))

    def test_either_missing_existing_phase_cannot_pass(self):
        for phase in self.record['resource_snapshots']:
            with self.subTest(phase=phase):
                self.rejects(lambda d: d['resource_snapshots'].pop(phase))

    def test_each_failed_or_not_executed_phase_blocks_final_pass(self):
        for phase in self.record['resource_snapshots']:
            for status in ('FAIL', 'NOT_EXECUTED', 'UNAVAILABLE', '', True, None):
                with self.subTest(phase=phase, status=status):
                    self.rejects(lambda d: d['resource_snapshots'][phase].update(status=status))

    def test_extra_or_replaced_phase_cannot_substitute_for_two_required_reads(self):
        self.rejects(lambda d: d['resource_snapshots'].update(other=copy.deepcopy(d['resource_snapshots']['first-driving'])))
        self.rejects(lambda d: d['resource_snapshots'].__setitem__('after-load', d['resource_snapshots'].pop('first-driving')))

    def test_nonobject_snapshot_container_or_phase_cannot_pass(self):
        for bad in (None, [], True, 'PASS'):
            with self.subTest(container=bad):
                self.rejects(lambda d: d.update(resource_snapshots=bad))
            with self.subTest(phase=bad):
                self.rejects(lambda d: d['resource_snapshots'].__setitem__('first-driving', bad))

    def test_each_snapshot_identity_is_bound_to_exact_current_result(self):
        for key, bad in (('source', 'f' * 40), ('godot', 'f' * 40), ('apk_sha256', 'a' * 64), ('android_sdk', 36), ('android_sdk', True), ('serial', 'emulator-5556')):
            with self.subTest(key=key):
                self.rejects(lambda d: d['resource_snapshots']['first-driving']['identity'].__setitem__(key, bad))

    def test_phase_field_and_failure_error_are_not_ignored(self):
        self.rejects(lambda d: d['resource_snapshots']['first-driving'].update(phase='completed-before-fold'))
        self.rejects(lambda d: d['resource_snapshots']['first-driving'].update(error='actual resource failure'))

    def test_all_three_raw_reads_and_exact_command_arguments_are_required(self):
        for index in range(3):
            with self.subTest(index=index, fault='missing'):
                self.rejects(lambda d: d['resource_snapshots']['first-driving']['reads'].pop(index))
            with self.subTest(index=index, fault='emptyraw'):
                self.rejects(lambda d: d['resource_snapshots']['first-driving']['reads'][index].update(raw=''))
            with self.subTest(index=index, fault='foreignserial'):
                self.rejects(lambda d: d['resource_snapshots']['first-driving']['reads'][index]['arguments'].__setitem__(1, 'emulator-5556'))
        self.rejects(lambda d: d['resource_snapshots']['first-driving']['reads'].reverse())

    def test_failed_resource_producer_return_cannot_become_fullrace_pass(self):
        device = FakeDevice(mem=RuntimeError('controlled read unavailable'))
        value = capture_resources(device, self.out, 'first-driving', IDENTITY, READY, clock=device.clock)
        self.assertEqual(value['status'], 'FAIL')
        self.rejects(lambda d: d['resource_snapshots'].__setitem__('first-driving', value))

    def test_reported_metrics_cannot_disagree_with_captured_raw_inputs(self):
        for key in ('pid', 'user_cpu_ticks', 'system_cpu_ticks', 'process_start_ticks', 'rss_pages', 'pss_kib', 'rss_kib'):
            with self.subTest(key=key):
                self.rejects(lambda d: d['resource_snapshots']['first-driving'].__setitem__(key, 12345))
        self.rejects(lambda d: d['resource_snapshots']['first-driving'].__setitem__('user_cpu_ticks', True))
        self.rejects(lambda d: d['resource_snapshots']['first-driving'].update(rss_kib_status='UNAVAILABLE'))

    def test_missing_raw_read_timestamps_cannot_be_archived_as_complete(self):
        for index in range(3):
            for key in ('started_utc', 'finished_utc'):
                with self.subTest(index=index,key=key):
                    self.rejects(lambda d: d['resource_snapshots']['first-driving']['reads'][index].pop(key))

    def test_nonfinite_or_boolean_capture_duration_cannot_pass(self):
        for bad in (float('nan'), float('inf'), True, -1, 20.01):
            with self.subTest(bad=bad):
                self.rejects(lambda d: d['resource_snapshots']['first-driving'].update(elapsed_seconds=bad))

    def test_actual_product_tail_calls_resource_gate_before_status_pass(self):
        calls = [node for node in self.nodes if isinstance(node, ast.Expr) and isinstance(node.value, ast.Call) and isinstance(node.value.func, ast.Name) and node.value.func.id == 'require_resource_snapshots']
        self.assertEqual(len(calls), 1)
        self.assertEqual(ast.dump(calls[0].value.args[0]), "Name(id='result', ctx=Load())")
        self.assertLess(self.nodes.index(calls[0]), len(self.nodes) - 1)


if __name__ == '__main__':
    unittest.main()
