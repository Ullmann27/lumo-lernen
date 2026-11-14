from __future__ import annotations

import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path('/workspace/scratch/5987865ae883')
REPO = ROOT / 'lumo-studio-final-e3d'
OUT = Path(__file__).resolve().parent
GRADLE = Path('/workspace/scratch/e0abce7d2838/toolchain/gradle-9.1.0')
GROUPS = {'scripts': 'scripts/tests', 'android-qa': 'tools/android_qa/tests'}


def source_hashes():
    raw = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others',
                                   '--exclude-standard'], cwd=REPO)
    names = sorted(set(raw.decode().strip('\0').split('\0')))
    prefixes = {'.github', 'scripts', 'tools', 'lib', 'test', 'config', 'android',
                'integration_test'}
    suffixes = {'.py', '.sh', '.dart', '.kt', '.kts', '.java', '.gradle', '.properties',
                '.json', '.yaml', '.yml', '.xml', '.js', '.ts', '.toml', '.cfg'}
    records = []
    for name in names:
        path = REPO / name
        parts = Path(name).parts
        if not parts or '__pycache__' in parts:
            continue
        if not ((parts[0] in prefixes and
                 (path.suffix in suffixes or 'fixtures' in parts)) or
                name in {'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'AGENTS.md'}):
            continue
        if not path.is_file():
            continue
        content = path.read_bytes()
        records.append({'path': name, 'bytes': len(content),
                        'sha256': hashlib.sha256(content).hexdigest(),
                        'is_symlink': path.is_symlink()})
    return records


def frozen_c_hashes():
    manifest = json.loads((OUT.parent / 'upload-manifest.json').read_text())
    result = []
    for item in manifest['files']:
        path = Path(item['absolute_path'])
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if digest != item['sha256']:
            raise RuntimeError('Frozen C file changed: ' + str(path))
        result.append({'path': str(path), 'sha256': digest})
    return result


def main():
    name = sys.argv[1]
    tests = GROUPS[name]
    folder = OUT / name
    folder.mkdir(parents=True, exist_ok=True)
    before = {'sources': source_hashes(), 'C_frozen_files': frozen_c_hashes()}
    (folder / 'source-before.json').write_text(json.dumps(before, indent=2) + '\n')
    environment = dict(os.environ)
    environment.update(REQUIRE_ALL_TESTS='true', GRADLE_HOME=str(GRADLE),
        LUMO_KOTLIN_LIB_DIR=str(GRADLE / 'lib'),
        PATH=str(GRADLE / 'bin') + os.pathsep + environment.get('PATH', ''))
    if not (GRADLE / 'bin/gradle').is_file() or not (
            GRADLE / 'lib/kotlin-compiler-embeddable-2.2.0.jar').is_file():
        raise RuntimeError('The previously validated Gradle/Kotlin toolchain is missing')
    command = [sys.executable, '-m', 'unittest', 'discover', '-s', tests, '-v']
    started_utc = datetime.datetime.now(datetime.timezone.utc).isoformat()
    started = time.monotonic()
    log = folder / 'original.log'
    with log.open('wb') as stream:
        process = subprocess.run(command, cwd=REPO, env=environment,
                                 stdout=stream, stderr=subprocess.STDOUT, timeout=900)
    elapsed = time.monotonic() - started
    after = {'sources': source_hashes(), 'C_frozen_files': frozen_c_hashes()}
    (folder / 'source-after.json').write_text(json.dumps(after, indent=2) + '\n')
    text = log.read_text(errors='replace')
    summaries = list(re.finditer(r'^Ran (\d+) tests? in ([\d.]+)s\s*\n\s*\n'
                                 r'(OK(?: \([^\n]*\))?|FAILED[^\n]*)', text, re.MULTILINE))
    summary = summaries[-1] if summaries else None
    skipped = re.search(r'\bskipped=(\d+)', summary.group(3)) if summary else None
    skip_count = int(skipped.group(1)) if skipped else 0
    result = {'group': name, 'command': command, 'cwd': str(REPO),
        'started_utc': started_utc, 'process_exit_code': process.returncode,
        'elapsed_seconds': elapsed, 'tests': int(summary.group(1)) if summary else None,
        'unittest_seconds': float(summary.group(2)) if summary else None,
        'unittest_summary': summary.group(3) if summary else None, 'skipped': skip_count,
        'source_files': len(before['sources']), 'C_frozen_files': len(before['C_frozen_files']),
        'source_unchanged': before == after,
        'environment': {key: environment[key] for key in
                        ('REQUIRE_ALL_TESTS', 'GRADLE_HOME', 'LUMO_KOTLIN_LIB_DIR')},
        'toolchain_downloaded': False, 'log_bytes': log.stat().st_size,
        'log_sha256': hashlib.sha256(log.read_bytes()).hexdigest()}
    accepted = bool(process.returncode == 0 and summary and skip_count == 0 and before == after)
    result['status'] = 'PASS' if accepted else 'FAIL'
    (folder / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result), flush=True)
    return 0 if accepted else 1


if __name__ == '__main__':
    raise SystemExit(main())
