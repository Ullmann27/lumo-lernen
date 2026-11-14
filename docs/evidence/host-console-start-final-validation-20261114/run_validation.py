#!/usr/bin/env python3
"""Run only the authorized Console followup local contracts, once."""
from __future__ import annotations

from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path('/workspace/scratch/b3485b7bb989/lumo-host-jump-joystick-repair-7b16')
OUT = Path('/tmp/host-console-5676495b-targeted-validation-20261114')
PYTHON = '/opt/codex/runtimes/codex-primary-runtime/dependencies/python/bin/python'
ACTIONLINT = '/workspace/scratch/e0abce7d2838/toolchain/actionlint/actionlint'
HEAD = '5676495b331bc5a41d5ff78259f7165cf25d100a'
TREE = 'f6f7d30eeb8ace2eb546fd2d952834d2bbd68a1f'
BRANCH = 'validation/lumo-console-start-source-20261114'
FREEZES = (
    Path('/tmp/host-pr483-console-start-repair-20261114/source-freeze-parser-v1.json'),
    Path('/tmp/host-pr483-console-launch-diagnostics-20261114/source-freeze-v1.json'),
    Path('/tmp/host-console-start-qa-20261114/source-freeze.json'),
)
WORKFLOWS = (
    '.github/workflows/lumo-1966-cards-route-kart-qa.yml',
    '.github/workflows/lumo-astra-script-recovery.yml',
    '.github/workflows/lumo-console-start-7b16.yml',
    '.github/workflows/lumo-unified-integration-2026.yml',
)
ENV = {**os.environ, 'PYTHONDONTWRITEBYTECODE': '1', 'GIT_OPTIONAL_LOCKS': '0', 'TMPDIR': '/tmp'}


def utc():
    return datetime.now(timezone.utc).isoformat()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def write(name, value):
    with (OUT / name).open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def git(*args):
    result = subprocess.run(['git', '-C', str(ROOT), *args], env=ENV,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
    if result.stderr:
        raise RuntimeError('Read-only Git command produced unexpected stderr')
    return result.stdout


def snapshot(label, expected):
    state = {
        'observed_at_utc': utc(),
        'head': git('rev-parse', 'HEAD').decode().strip(),
        'tree': git('rev-parse', 'HEAD^{tree}').decode().strip(),
        'branch': git('branch', '--show-current').decode().strip(),
        'status_porcelain': git('status', '--porcelain=v1', '--untracked-files=all').decode(),
        'index_entries': git('ls-files', '--stage', '--', *sorted(expected)).decode(),
        'files': {},
    }
    for name in sorted(expected):
        path = ROOT / name
        if not path.is_file() or path.is_symlink():
            raise RuntimeError('Missing regular source: ' + name)
        raw = path.read_bytes()
        state['files'][name] = {
            'bytes': len(raw), 'sha256': digest(raw),
            'git_blob': hashlib.sha1(b'blob ' + str(len(raw)).encode() + b'\0' + raw).hexdigest(),
        }
    write(label + '.json', state)
    return state


def run(name, command, timeout):
    started = utc()
    clock = time.monotonic()
    with (OUT / (name + '.log')).open('xb') as stream:
        try:
            result = subprocess.run(command, cwd=ROOT, env=ENV, stdin=subprocess.DEVNULL,
                                    stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
            rc, error = result.returncode, None
        except subprocess.TimeoutExpired:
            rc, error = None, 'TIMEOUT'
    raw = (OUT / (name + '.log')).read_bytes()
    record = {
        'command': command, 'cwd': str(ROOT),
        'environment_overrides': {key: ENV[key] for key in ('PYTHONDONTWRITEBYTECODE', 'GIT_OPTIONAL_LOCKS', 'TMPDIR')},
        'started_at_utc': started, 'finished_at_utc': utc(),
        'elapsed_seconds': time.monotonic() - clock,
        'returncode': rc, 'error': error,
        'raw_log': {'path': name + '.log', 'bytes': len(raw), 'sha256': digest(raw)},
    }
    write(name + '-execution.json', record)
    return record, raw.decode('utf-8', errors='replace')


def main():
    OUT.mkdir(exist_ok=False)
    (OUT / 'run_validation.py').write_bytes(Path(__file__).read_bytes())
    expected = {}
    provenance = []
    for path in FREEZES:
        raw = path.read_bytes()
        provenance.append({'path': str(path), 'bytes': len(raw), 'sha256': digest(raw)})
        for entry in json.loads(raw)['files']:
            if entry['path'] in expected:
                raise RuntimeError('Duplicate source in frozen inputs')
            expected[entry['path']] = entry
    expected['.github/workflows/lumo-console-joystick-7b16.yml'] = {
        'bytes': 24911, 'sha256': 'ce286833614ab5c460e37b1b386532ea139f27ec374413bd95ccb14d7bd884b9',
    }
    if len(expected) != 27:
        raise RuntimeError('The authorized source scope must contain exactly 27 files')
    write('input-freezes.json', provenance)
    before = snapshot('source-before', expected)
    if (before['head'], before['tree'], before['branch'], before['status_porcelain']) != (HEAD, TREE, BRANCH, ''):
        raise RuntimeError('Actual checkout does not match the authorized clean source')
    for name, entry in expected.items():
        if any(before['files'][name][key] != entry[key] for key in ('bytes', 'sha256')):
            raise RuntimeError('Actual source differs from freeze: ' + name)
    tests, raw = run('combined-contracts', [PYTHON, '-B', '-m', 'unittest', '-v',
        'scripts.tests.test_console_start_workflow',
        'scripts.tests.test_console_launch_originals',
        'scripts.tests.test_console_launch_failure_diagnostics'], 180)
    lint, _ = run('actionlint', [ACTIONLINT, '-color', *WORKFLOWS], 120)
    after = snapshot('source-after', expected)
    unchanged = all(before[key] == after[key] for key in ('head', 'tree', 'branch', 'status_porcelain', 'index_entries', 'files'))
    counts = re.findall(r'^Ran (\d+) tests in ', raw, re.M)
    successful_methods = len(re.findall(r'^test_[^\n]+ \.\.\. ok$', raw, re.M))
    plain_ok = re.findall(r'^OK$', raw, re.M) == ['OK']
    skip_markers = re.findall(r'^.*(?:\.\.\. skipped |^OK \(skipped=|^FAILED.*skipped=).*$', raw, re.M)
    green = tests['returncode'] == 0 and counts == ['25'] and successful_methods == 25 and plain_ok and not skip_markers
    overall = green and lint['returncode'] == 0 and unchanged
    result = {
        'schema': 1, 'status': 'PASS' if overall else 'FAIL', 'head': HEAD, 'tree': TREE,
        'worktree': str(ROOT), 'branch': BRANCH, 'source_files': 27, 'sources_and_git_state_unchanged': unchanged,
        'tests': {'methods': int(counts[0]) if len(counts) == 1 else None,
                  'successful_methods': successful_methods, 'plain_ok': plain_ok,
                  'skips': 0 if not skip_markers else None, 'skip_markers': skip_markers,
                  'failures': 0 if green else None, 'errors': 0 if green else None,
                  'execution': tests},
        'actionlint': {'workflow_count': 4, 'execution': lint},
        'boundaries': ['Exactly one authorized 9+7+9 contract run and one four-workflow actionlint invocation.',
                       'No 86-method AF_UNIX run; it remains mandatory in actual CI.',
                       'Diagnostic child processes simulate adb output. No SDK, APK, emulator, renderer, Android or console-survival acceptance.',
                       'No source edits or Git/index/ref mutation; original transcript bytes are unchanged.'],
    }
    write('result.json', result)
    write('handoff.json', {'schema': 1, 'status': result['status'], 'pack': str(OUT),
          'head': HEAD, 'tree': TREE, 'tests': {'methods': result['tests']['methods'],
          'passed': successful_methods, 'failures': result['tests']['failures'], 'errors': result['tests']['errors'],
          'skips': result['tests']['skips']}, 'actionlint': {'workflows': 4, 'returncode': lint['returncode']},
          'source_count': 27, 'source_and_git_state_unchanged': unchanged,
          'result': {'path': 'result.json', 'sha256': digest((OUT / 'result.json').read_bytes())},
          'scope': 'Only the authorized combined local contracts. Real API37/AF_UNIX CI remains required.'})
    (OUT / 'README.md').write_text(
        '# Console followup targeted validation\n\n'
        f'Actual committed source: {HEAD}; tree {TREE}.\n\n'
        'One combined unittest invocation contains Workflow 9, original-parser 7 and failure-diagnostic 9 methods. '
        'One actionlint invocation checks exactly the four requested workflows. All original stdout/stderr is retained '
        'losslessly in the raw logs, with commands, timestamps and exit codes. Source-before/source-after bind all 27 '
        'relevant files, exact Git HEAD/tree/branch, index entries and full porcelain status. No source or Git state is changed.\n\n'
        'The 86 Console/AF_UNIX cases are not repeated here. This does not establish Android launch, init-console survival '
        'or ANR absence. The three historical original END:1 transcripts remain failures in the parser regressions.\n', encoding='utf-8')
    entries = []
    for path in sorted(OUT.rglob('*')):
        if path.is_file():
            data = path.read_bytes()
            entries.append({'path': str(path.relative_to(OUT)), 'bytes': len(data), 'sha256': digest(data)})
    write('manifest.json', {'schema': 1, 'files': entries})
    (OUT / 'SHA256SUMS').write_text(''.join(row['sha256'] + '  ' + row['path'] + '\n' for row in entries)
        + digest((OUT / 'manifest.json').read_bytes()) + '  manifest.json\n')
    print(json.dumps({'status': result['status'], 'tests': result['tests']['methods'], 'passed': successful_methods,
                      'actionlint_exit': lint['returncode'], 'source_unchanged': unchanged,
                      'handoff': str(OUT / 'handoff.json'), 'handoff_sha256': digest((OUT / 'handoff.json').read_bytes()),
                      'manifest_sha256': digest((OUT / 'manifest.json').read_bytes())}, indent=2))
    return 0 if overall else 1


if __name__ == '__main__':
    sys.exit(main())
