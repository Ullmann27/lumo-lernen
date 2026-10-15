#!/usr/bin/env python3
"""Run current profile regressions and retain the exact historical attribution check.

The 1918/1919 comparison uses separate complete source trees. It is historical
evidence, not a claim that today's per-profile APIs existed in those versions.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


ORIGINAL_COMMIT = 'ab21b2295ca5307bae5e07c0c8a01c3017ee91a3'
REPAIRED_COMMIT = 'd07b2b48593b939a2a0446fcb83a25a2b2a59db6'
ORIGINAL_STATE_SHA256 = '26045518fded02d6b588dcbd03898312b6a2103d173873a67413102a8583d0ab'
REPAIRED_STATE_SHA256 = '49a5f51bb39da8bd1319271290a03c495facba38a76b1db84650e98b0a214eb5'
HISTORICAL_TEST_SHA256 = '7a82a25d0932e2db45717472c4016dbae8453190c7a4283db66901780ad19d6a'
STATE = 'lib/app/app_state.dart'
IDENTITY_TEST = 'test/app_state_student_identity_test.dart'
WIDGET_TEST = 'test/design/legacy_learning_assignment_test.dart'
CAPTURE_SIZES = {
    'legacy_parent_phone.png': (824, 1830),
    'legacy_parent_fold_confirm.png': (1680, 1560),
    'legacy_parent_fold_assigned.png': (1680, 1560),
    'legacy_parent_large_text.png': (640, 1480),
}
HISTORICAL_CASES = (
    'answer keeps its student when assignment changes during progress load',
    'answer keeps its student when assignment changes during progress save',
    'unassigned answers retain the existing local log attribution',
)
CURRENT_TESTS = (
    IDENTITY_TEST,
    'test/learning_profile_isolation_test.dart',
    'test/cosmos_profile_isolation_test.dart',
    'test/legacy_learning_data_test.dart',
    WIDGET_TEST,
    'test/progress_repository_storage_test.dart',
    'test/learning_modules/learning_module_progress_test.dart',
    'test/domain/school_model_test.dart',
    'test/domain/school_analysis_test.dart',
    'test/domain/learning_analysis_extended_test.dart',
    'test/reward_wallet_transaction_test.dart',
)


def require(value: bool, message: str) -> None:
    if not value:
        raise ValueError(message)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()


def write_json(path: Path, value: dict) -> None:
    path.write_text(json.dumps(value, indent=2) + '\n')


def collect_captures(root: Path, directory: Path, source_commit: str) -> dict:
    from PIL import Image

    require({path.name for path in directory.iterdir()} == set(CAPTURE_SIZES),
            'Every expected parent phone, Fold and large-text capture must be produced')
    frames = []
    for name, size in CAPTURE_SIZES.items():
        path = directory / name
        require(path.is_file() and not path.is_symlink(), f'Expected actual PNG: {name}')
        with Image.open(path) as image:
            require(image.format == 'PNG' and image.size == size,
                    f'Unexpected rendered size for {name}: {image.size}')
            image.load()
        frames.append({'file': name, 'width': size[0], 'height': size[1],
                       'bytes': path.stat().st_size, 'sha256': digest(path)})
    return {
        'schema': 'lumo.profile-widget-captures.v1', 'status': 'PASS',
        'flutter_source_commit': source_commit,
        'test_path': WIDGET_TEST, 'test_sha256': digest(root / WIDGET_TEST),
        'scope': 'Actual Flutter widget renders with local test fixtures; phone, Fold and large text',
        'physical_device_or_android_runtime': 'NOT EXECUTED BY THIS GATE',
        'captures': frames,
    }


def verify_report(root: Path, output: Path, phase: str, exit_code: int,
                  paths: tuple[str, ...], *, historical: bool = False) -> dict:
    raw = (output / f'{phase}.jsonl').read_bytes()
    events = [json.loads(line) for line in raw.decode('utf-8').splitlines() if line.strip()]
    require(bool(events) and all(type(event) is dict for event in events),
            'Missing JSON reporter events')
    done = [event for event in events if event.get('type') == 'done']
    require(len(done) == 1 and events[-1] == done[0], 'Test runner did not complete')
    starts = [event['test'] for event in events if event.get('type') == 'testStart']
    finishes = [event for event in events if event.get('type') == 'testDone']
    tests = {test['id']: test for test in starts}
    require(len(tests) == len(starts), 'Duplicate test starts')
    require(len(finishes) == len(tests) and
            {event['testID'] for event in finishes} == set(tests),
            'Incomplete or duplicate test results')
    require(all(event.get('skipped') is False and type(event.get('hidden')) is bool
                for event in finishes), 'Skipped or malformed test result')
    require(all(event['result'] == 'success' for event in finishes if event['hidden']),
            'Loading, setup or teardown failed')
    visible = [event for event in finishes if not event['hidden']]
    require(bool(visible), 'No visible tests executed')
    errors = [event for event in events if event.get('type') == 'error']
    suites = {event['suite']['id']: event['suite'] for event in events
              if event.get('type') == 'suite'}
    executed = {Path(suites[tests[event['testID']]['suiteID']]['path']).resolve()
                for event in visible}
    require(executed == {(root / name).resolve() for name in paths},
            'Every required identity, profile, storage, school and wallet suite must execute')
    cases = [{'name': tests[event['testID']]['name'], 'result': event['result']}
             for event in visible]
    if historical:
        require(len(cases) == 3 and {case['name'] for case in cases} == set(HISTORICAL_CASES),
                'Expected all three exact historical identity tests')
        require(digest(root / IDENTITY_TEST) == HISTORICAL_TEST_SHA256,
                'Historical identity test bytes changed')
    if phase == 'historical-red':
        require(exit_code == 1 and done[0].get('success') is False,
                'Original run was not completed RED')
        results = {case['name']: case['result'] for case in cases}
        require(results == {HISTORICAL_CASES[0]: 'failure', HISTORICAL_CASES[1]: 'failure',
                            HISTORICAL_CASES[2]: 'success'},
                'Original must fail only both attribution cases and pass local compatibility')
        expected_ids = {event['testID'] for event in visible
                        if tests[event['testID']]['name'] in HISTORICAL_CASES[:2]}
        require(len(errors) == 2 and {event.get('testID') for event in errors} == expected_ids,
                'Unexpected compiler, bootstrap, asynchronous or additional test error')
        for event in errors:
            require(event.get('isFailure') is True, 'Non-assertion error cannot prove RED')
            message = event.get('error', '')
            require(re.search(r"(?m)^Expected:\s*'student-a'\s*$", message) is not None and
                    re.search(r"(?m)^\s*Actual:\s*'student-b'\s*$", message) is not None,
                    'RED must be the exact student-a versus student-b attribution failure')
            require('app_state_student_identity_test.dart' in event.get('stackTrace', ''),
                    'Attribution assertion must come from the unchanged historical test')
    else:
        require(exit_code == 0 and done[0].get('success') is True and not errors and
                all(case['result'] == 'success' for case in cases),
                f'{phase}: every required test must pass without errors or skips')
    report = {
        'status': 'EXPECTED_RED' if phase == 'historical-red' else 'PASS',
        'source_commit': git(root, 'rev-parse', 'HEAD'),
        'input_sha256': {name: digest(root / name) for name in (STATE, *paths)},
        'exit_code': exit_code, 'visible_tests': len(visible), 'skipped': 0,
        'json_reporter_sha256': hashlib.sha256(raw).hexdigest(),
        'stderr_sha256': digest(output / f'{phase}-stderr.log'),
        'test_suites': list(paths), 'cases': cases,
    }
    if errors:
        report['errors'] = [{'test': tests[event['testID']]['name'],
                             'is_failure': event['isFailure'], 'error': event['error']}
                            for event in errors]
    write_json(output / f'{phase}-verification.json', report)
    print(f'[ProfileChecks] {phase}: {report["status"]}, {len(visible)} tests, no skips', flush=True)
    return report


def run_tests(root: Path, output: Path, phase: str, paths: tuple[str, ...],
              *, historical: bool = False, environment: dict | None = None) -> dict:
    before = {name: digest(root / name) for name in (STATE, *paths)}
    with (output / f'{phase}.jsonl').open('wb') as stdout, \
            (output / f'{phase}-stderr.log').open('wb') as stderr:
        result = subprocess.run(
            ['flutter', 'test', '--no-pub', '--reporter=json', '--timeout=60s',
             '--concurrency=1', *paths], cwd=root, env=environment, stdout=stdout, stderr=stderr)
    (output / f'{phase}-exit-code.txt').write_text(str(result.returncode) + '\n')
    require(before == {name: digest(root / name) for name in before},
            'Profile sources or tests changed during execution')
    git(root, 'diff', '--exit-code', 'HEAD', '--')
    return verify_report(root, output, phase, result.returncode, paths, historical=historical)


def run_history(source: Path, output: Path) -> dict:
    # Only the historical test is copied into the original complete tree. No
    # current application source is ever swapped to a former implementation.
    temporary = Path(tempfile.mkdtemp(prefix='lumo-profile-history-',
                                      dir=os.environ.get('RUNNER_TEMP')))
    roots: list[Path] = []
    reports = {}
    try:
        for phase, commit, expected_state in (
            ('historical-red', ORIGINAL_COMMIT, ORIGINAL_STATE_SHA256),
            ('historical-green', REPAIRED_COMMIT, REPAIRED_STATE_SHA256),
        ):
            if subprocess.run(['git', '-C', str(source), 'cat-file', '-e', commit],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
                subprocess.run(['git', '-C', str(source), 'fetch', '--no-tags', '--depth=1',
                                'origin', commit], check=True)
            root = temporary / phase
            git(source, 'worktree', 'add', '--detach', str(root), commit)
            roots.append(root)
            require(git(root, 'rev-parse', 'HEAD') == commit, 'Historical source mismatch')
            require(digest(root / STATE) == expected_state, 'Historical app_state bytes changed')
            if phase == 'historical-red':
                if subprocess.run(['git', '-C', str(source), 'cat-file', '-e', REPAIRED_COMMIT],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
                    subprocess.run(['git', '-C', str(source), 'fetch', '--no-tags', '--depth=1',
                                    'origin', REPAIRED_COMMIT], check=True)
                (root / IDENTITY_TEST).write_bytes(subprocess.check_output(
                    ['git', '-C', str(source), 'show', f'{REPAIRED_COMMIT}:{IDENTITY_TEST}']))
            require(digest(root / IDENTITY_TEST) == HISTORICAL_TEST_SHA256,
                    'Historical identity test must have its original exact bytes')
            shutil.copyfile(root / STATE, output / f'{phase}-app_state.dart.txt')
            shutil.copyfile(root / IDENTITY_TEST, output / f'{phase}-identity-test.dart.txt')
            with (output / f'{phase}-dependencies.log').open('wb') as log:
                subprocess.run(['flutter', 'pub', 'get', '--enforce-lockfile'], cwd=root,
                               stdout=log, stderr=subprocess.STDOUT, check=True)
            reports[phase.removeprefix('historical-')] = run_tests(
                root, output, phase, (IDENTITY_TEST,), historical=True)
    finally:
        for root in reversed(roots):
            subprocess.run(['git', '-C', str(source), 'worktree', 'remove', '--force', str(root)],
                           check=True)
        shutil.rmtree(temporary)
    return {
        'scope': 'Historical 1918 to 1919 attribution repair; separate from current profile isolation',
        'original_commit': ORIGINAL_COMMIT, 'repaired_commit': REPAIRED_COMMIT,
        'unchanged_test_sha256': HISTORICAL_TEST_SHA256,
        'original_test_added_from_repaired_commit': True,
        **reports,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=Path.cwd())
    parser.add_argument('--out', type=Path, default=Path('proof/profile-identity'))
    args = parser.parse_args()
    source, output = args.source.resolve(), args.out.resolve()
    output.mkdir(parents=True, exist_ok=True)
    git(source, 'diff', '--exit-code', 'HEAD', '--')
    git(source, 'ls-files', '--error-unmatch', STATE, *CURRENT_TESTS)
    capture_directory = Path(os.environ.get('LUMO_PROFILE_CAPTURES', output / 'captures')).resolve()
    capture_directory.mkdir(parents=True, exist_ok=True)
    require(not any(capture_directory.iterdir()), 'Use an empty directory for current widget captures')
    environment = {**os.environ, 'LUMO_PROFILE_CAPTURES': str(capture_directory)}
    # New product regressions run first, before downloading or testing history.
    current = run_tests(source, output, 'current', CURRENT_TESTS, environment=environment)
    captures = collect_captures(source, capture_directory, current['source_commit'])
    capture_report = output / 'PROFILE-CAPTURE-EVIDENCE.json'
    write_json(capture_report, captures)
    historical = run_history(source, output)
    require(current['source_commit'] == git(source, 'rev-parse', 'HEAD'),
            'Candidate commit changed during profile checks')
    require(current['input_sha256'] == {name: digest(source / name)
                                       for name in current['input_sha256']},
            'Current profile sources changed while historical checks ran')
    git(source, 'diff', '--exit-code', 'HEAD', '--')
    write_json(output / 'PROFILE-IDENTITY-EVIDENCE.json', {
        'schema': 'lumo.profile-checks.v2', 'status': 'PASS',
        'scope': 'Current profile isolation, attribution, storage, school and wallet regressions',
        'flutter_source_commit': current['source_commit'],
        'current': current, 'historical': historical,
        'widget_capture_evidence_sha256': digest(capture_report),
        'physical_device_or_android_runtime': 'NOT EXECUTED BY THIS GATE',
    })


if __name__ == '__main__':
    main()
