#!/usr/bin/env python3
"""Reproduce the reviewed observer regression, then require all 54 QA tests.

The old and proposed checkouts stay separate and unchanged. This runs Python
regression tests only; it grants no Android, APK, or candidate acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import traceback
import unittest

REPOSITORY = 'Ullmann27/lumo-lernen'
BRANCH = 'qa/lumo-kart-observer-20261114'
BASE = '9deaa3f24561bc65caba898585c0c00f1c77162b'
BASE_TREE = 'c0a9e29c831113ea8e49e632bc7959a15079bc94'
NATIVE = 'bebf7bba48f09afc834469db0ea3c5541a184f55'
RUNNER = '.github/qa/lumo_kart_observer_regression.py'
WORKFLOW = '.github/workflows/lumo-kart-observer-qa.yml'
TOUR = '.github/probes/modernization_android_tour.py'
RECOVERY_TEST = 'tools/android_qa/tests/test_kart_garage_scroll_recovery.py'
EVIDENCE_TEST = 'tools/android_qa/tests/test_kart_garage_evidence.py'
LOADER = 'tools/android_qa/tests/test_modernization_tour_identity.py'
HELPER = 'tools/android_qa/kart_garage_evidence.py'
PATCH = {
    TOUR: 'f8c266c672632aa086b11e695fb1883a063e2123',
    RECOVERY_TEST: '3da90d30a2c602e800fda9b6165e335eb039afb7',
    EVIDENCE_TEST: '20f856522493f5fdfc41d147de70bb096a2938fa',
}
BASELINE_METHOD = (
    'test_only_real_inputs_settle_and_each_fresh_frame_has_one_full_list_analysis'
)


def require(ok, message):
    if not ok:
        raise ValueError(message)


def record(path):
    data = path.read_bytes()
    return {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_sha1': hashlib.sha1(
                b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()}


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args],
                                   stderr=subprocess.STDOUT, text=True).strip()


def original_file(root, relative):
    path = root / relative
    require(path.is_file() and not path.is_symlink(),
            'Missing regular source: ' + relative)
    require(path.read_bytes() == subprocess.check_output(
        ['git', '-C', str(root), 'show', 'HEAD:' + relative]),
        'Working bytes differ from the exact committed source: ' + relative)
    return record(path)


def source_state(root, expected, tree=None):
    require(root.is_dir() and not root.is_symlink()
            and Path(git(root, 'rev-parse', '--show-toplevel')).resolve() == root,
            'A separate actual checkout is required')
    require(git(root, 'rev-parse', 'HEAD') == expected, 'Unexpected checkout head')
    actual_tree = git(root, 'rev-parse', 'HEAD^{tree}')
    require(tree is None or actual_tree == tree, 'Unexpected checkout tree')
    require(not git(root, 'status', '--porcelain', '--untracked-files=all'),
            'Source checkout changed or acquired an untracked file')
    paths = [TOUR, RECOVERY_TEST, EVIDENCE_TEST, LOADER, HELPER,
             'pubspec.yaml', 'pubspec.lock', 'config/godot-source.json']
    fixture = root / 'tools/android_qa/tests/fixtures/kart-scroll-6f42'
    paths.extend(p.relative_to(root).as_posix() for p in sorted(fixture.rglob('*'))
                 if p.is_file())
    require(len(paths) == 17, 'The nine frozen original garage fixtures are required')
    files = {name: original_file(root, name) for name in paths}
    require(json.loads((root/'config/godot-source.json').read_text())['revision'] == NATIVE,
            'The unchanged native pin differs')
    return {'commit': expected, 'tree': actual_tree, 'tracked_and_untracked_clean': True,
            'files': files}


def bind_sources(baseline, proposed):
    require(baseline != proposed and not baseline.is_relative_to(proposed)
            and not proposed.is_relative_to(baseline), 'Source checkouts must be separate')
    require(os.environ.get('GITHUB_REPOSITORY') == REPOSITORY
            and os.environ.get('GITHUB_REF') == 'refs/heads/' + BRANCH
            and os.environ.get('GITHUB_EVENT_NAME') == 'push',
            'Unexpected repository, trigger branch, or event')
    head = os.environ['GITHUB_SHA']
    require(git(proposed, 'rev-parse', 'HEAD') == head
            and git(proposed, 'show', '-s', '--format=%P', 'HEAD').split() == [BASE],
            'The proposed QA source must be the reviewed direct child of 9de')
    changed = set(git(proposed, 'diff', '--name-only', BASE, head, '--').splitlines())
    require(changed == {*PATCH, RUNNER, WORKFLOW}, 'Unexpected proposed source change')
    for path, expected in PATCH.items():
        require(original_file(proposed, path)['git_sha1'] == expected,
                'Reviewed v2 patch differs: ' + path)
    execution = {name: original_file(proposed, name) for name in (RUNNER, WORKFLOW)}
    return {'baseline': source_state(baseline, BASE, BASE_TREE),
            'proposed': source_state(proposed, head),
            'execution_files': execution}


def write_new(path, value):
    with path.open('x', encoding='utf-8') as stream:
        json.dump(value, stream, indent=2, ensure_ascii=False)
        stream.write('\n')


class RecordedResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.subtest_errors = []

    def addSubTest(self, test, subtest, error):
        if error is not None:
            self.subtest_errors.append({
                'test': test.id(), 'subtest': subtest.id(),
                'exception_type': error[0].__name__,
                'message': str(error[1]),
                'traceback': ''.join(traceback.format_exception(*error)),
            })
        super().addSubTest(test, subtest, error)


def test_record(result):
    return {
        'tests_run': result.testsRun, 'was_successful': result.wasSuccessful(),
        'failures': [{'test': test.id(), 'traceback': detail}
                     for test, detail in result.failures],
        'errors': [{'test': test.id(), 'traceback': detail}
                   for test, detail in result.errors],
        'skipped': [{'test': test.id(), 'reason': reason}
                    for test, reason in result.skipped],
        'expected_failures': [test.id() for test, _ in result.expectedFailures],
        'unexpected_successes': [test.id() for test in result.unexpectedSuccesses],
        'subtest_errors': result.subtest_errors,
    }


def baseline_suite(baseline, proposed):
    # Import the unchanged old loader first. Its real __file__/ROOT resolves to
    # the old checkout; the new positive method then imports that same loader.
    # No copied production file, ROOT override, or replacement callback is used.
    sys.path.insert(0, str(baseline/'tools/android_qa/tests'))
    loader = importlib.import_module('test_modernization_tour_identity')
    require(Path(loader.__file__).resolve() == baseline/LOADER,
            'Baseline loader came from a different checkout')
    tour = loader.TOUR_MODULE
    require(Path(tour.__file__).resolve() == baseline/TOUR
            and Path(tour.garage_evidence.__file__).resolve() == baseline/HELPER,
            'Baseline did not load the actual unchanged tour and image analyser')
    path = proposed / RECOVERY_TEST
    spec = importlib.util.spec_from_file_location('lumo_proposed_kart_regression', path)
    require(spec is not None and spec.loader is not None, 'Cannot load reviewed positive test')
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    require(module.tour is tour and Path(module.__file__).resolve() == path,
            'Positive regression is not bound to the original tour')
    test = module.GarageSelectionObservationTests(BASELINE_METHOD)
    return unittest.TestSuite([test]), {
        'test_file': str(path), 'test_method': BASELINE_METHOD,
        'tour_file': str(Path(tour.__file__).resolve()),
        'analyser_file': str(Path(tour.garage_evidence.__file__).resolve()),
        'loader_file': str(Path(loader.__file__).resolve()),
        'source_override_performed': False,
    }


def expected_baseline_failure(result, baseline):
    items = result.subtest_errors
    return (
        result.testsRun == 1 and not result.wasSuccessful()
        and len(result.failures) == 1 and len(result.errors) == 1
        and not result.skipped and not result.expectedFailures
        and not result.unexpectedSuccesses and len(items) == 2
        and items[0]['subtest'].endswith('(timeout=150)')
        and items[0]['exception_type'] == 'AssertionError'
        and items[0]['message'] == '6 != 4'
        and 'self.assertEqual(analyses.call_count, 4)' in items[0]['traceback']
        and items[1]['subtest'].endswith('(timeout=5)')
        and items[1]['exception_type'] == 'TimeoutError'
        and items[1]['message'] ==
            'Current complete kart caption was not observed twice inside the list: Comet'
        and str(baseline/TOUR) in items[1]['traceback']
    )


def run_phase(args):
    report = {'phase': args.phase, 'status': 'UNEXPECTED_FAILURE',
              'android_acceptance': False, 'candidate_acceptance': False}
    code = 2
    try:
        before = bind_sources(args.baseline, args.proposed)
        report['sources_before'] = before
        if args.phase == 'baseline':
            suite, binding = baseline_suite(args.baseline, args.proposed)
            report['test_binding'] = binding
        else:
            loader = unittest.TestLoader()
            suite = loader.discover(
                str(args.proposed/'tools/android_qa/tests'),
                pattern='test_kart_garage*.py')
            require(not loader.errors and suite.countTestCases() == 54,
                    'The complete current two-module inventory must contain exactly 54 tests')
            report['discovered_tests'] = suite.countTestCases()
        result = unittest.TextTestRunner(
            stream=sys.stderr, verbosity=2, resultclass=RecordedResult).run(suite)
        report['unittest'] = test_record(result)
        after = bind_sources(args.baseline, args.proposed)
        require(after == before, 'Regression execution changed either source checkout')
        report['sources_after'] = after
        if args.phase == 'baseline':
            require(expected_baseline_failure(result, args.baseline),
                    'The baseline did not reproduce the exact analysis/deadline regression')
            report['status'] = 'EXPECTED_BASELINE_REGRESSION_REPRODUCED'
            # Preserve the actual failing test-process exit. The parent checks
            # this exact result and its two original failure kinds separately.
            code = 1
        else:
            require(result.testsRun == 54 and result.wasSuccessful()
                    and not result.skipped and not result.expectedFailures
                    and not result.unexpectedSuccesses,
                    'All 54 regression tests must pass without skips or allowed failures')
            tour = sys.modules['test_modernization_tour_identity'].TOUR_MODULE
            require(Path(tour.__file__).resolve() == args.proposed/TOUR
                    and Path(tour.garage_evidence.__file__).resolve() == args.proposed/HELPER,
                    'Green tests used a foreign source checkout')
            report['status'] = 'ALL_54_QA_TESTS_PASS'
            code = 0
    except Exception as error:
        report['error'] = type(error).__name__ + ': ' + str(error)
        report['traceback'] = traceback.format_exc()
        traceback.print_exc()
    finally:
        report['exit_code'] = code
        write_new(args.out/(args.phase+'-result.json'), report)
        print('[LumoKartObserverPhase] '+json.dumps(report, ensure_ascii=True), flush=True)
    return code


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--proposed', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--phase', choices=('baseline', 'green'))
    args = parser.parse_args()
    args.baseline, args.proposed, args.out = (
        args.baseline.resolve(), args.proposed.resolve(), args.out.resolve())
    sys.dont_write_bytecode = True
    require(not any(args.out.is_relative_to(root) or root.is_relative_to(args.out)
                    for root in (args.baseline, args.proposed)),
            'Evidence must be outside both source checkouts')
    if args.phase:
        require(args.out.is_dir(), 'Phase evidence directory is missing')
        return run_phase(args)
    require(not args.out.exists(), 'Refusing to overwrite a previous evidence directory')
    args.out.mkdir(parents=True)
    receipt = {'kind': 'reviewed_kart_observer_python_regression', 'status': 'FAIL',
               'baseline_source': BASE, 'native_source': NATIVE,
               'candidate_acceptance': False, 'android_acceptance': False,
               'APK_or_emulator_executed': False, 'product_files_changed': False,
               'phases': {}, 'errors': []}
    try:
        import PIL
        require(PIL.__version__ == '12.3.0', 'Unexpected reviewed Pillow version')
        receipt['python'] = sys.version
        receipt['pillow'] = PIL.__version__
        receipt['run_id'] = int(os.environ['GITHUB_RUN_ID'])
        receipt['run_attempt'] = int(os.environ['GITHUB_RUN_ATTEMPT'])
        receipt['sources_before'] = bind_sources(args.baseline, args.proposed)
        for phase, expected_exit, expected_status in (
            ('baseline', 1, 'EXPECTED_BASELINE_REGRESSION_REPRODUCED'),
            ('green', 0, 'ALL_54_QA_TESTS_PASS'),
        ):
            log = args.out/(phase+'.log')
            command = [sys.executable, '-B', str(args.proposed/RUNNER),
                       '--baseline', str(args.baseline), '--proposed', str(args.proposed),
                       '--out', str(args.out), '--phase', phase]
            with log.open('xb') as stream:
                process = subprocess.run(
                    command, cwd=args.baseline if phase == 'baseline' else args.proposed,
                    stdout=stream, stderr=subprocess.STDOUT, timeout=300, check=False)
            phase_path = args.out/(phase+'-result.json')
            require(phase_path.is_file(), 'Original phase report was not written')
            actual = json.loads(phase_path.read_text(encoding='utf-8'))
            receipt['phases'][phase] = {
                'command': command, 'returncode': process.returncode,
                'status': actual.get('status'), 'log': record(log),
                'original_phase_report': record(phase_path),
                'unittest': actual.get('unittest'),
            }
            # Print the exact complete original child log. Never replace a red
            # assertion with an import/API error or suppress a green failure.
            sys.stdout.flush()
            sys.stdout.buffer.write(log.read_bytes())
            sys.stdout.buffer.flush()
            require(process.returncode == expected_exit
                    and actual.get('exit_code') == expected_exit
                    and actual.get('status') == expected_status,
                    'Unexpected original phase result: '+phase)
        receipt['sources_after'] = bind_sources(args.baseline, args.proposed)
        require(receipt['sources_after'] == receipt['sources_before'],
                'Regression execution changed either original checkout')
        receipt['status'] = 'EXPECTED_BASELINE_RED_AND_ALL_54_GREEN'
    except Exception as error:
        receipt['errors'].append(type(error).__name__ + ': ' + str(error))
        receipt['traceback'] = traceback.format_exc()
        traceback.print_exc()
    finally:
        write_new(args.out/'regression-receipt.json', receipt)
        print('[LumoKartObserverReceipt] '+json.dumps(receipt, ensure_ascii=True), flush=True)
    return 0 if receipt['status'] == 'EXPECTED_BASELINE_RED_AND_ALL_54_GREEN' else 1


if __name__ == '__main__':
    raise SystemExit(main())
