from pathlib import Path
import datetime
import hashlib
import importlib.metadata
import json
import os
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / 'source'
OUTPUT = ROOT / 'actual-validation'
OUTPUT.mkdir(exist_ok=False)
BINDING = json.loads((ROOT / 'actual-source-checkpoint.json').read_text())

def utc():
    return datetime.datetime.now(datetime.timezone.utc).isoformat()

def source_state():
    records = []
    for item in BINDING['entries']:
        data = (SOURCE / item['path']).read_bytes()
        actual = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()
        if actual != item['sha']:
            raise RuntimeError('Source identity mismatch: ' + item['path'])
        records.append({'path': item['path'], 'blob': actual,
                        'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    return records

before = source_state()
argv = [sys.executable, '-B', '-m', 'unittest', '-v',
        'tools.android_qa.tests.test_connect_four_probe_deadlines',
        'tools.android_qa.tests.test_connect_four_return_observation']
environment = os.environ.copy()
environment.pop('LUMO_C4_PROBE_SOURCE', None)
environment.pop('PYTHONPATH', None)
environment['PYTHONDONTWRITEBYTECODE'] = '1'
invocation = {'status': 'STARTED', 'started_utc': utc(), 'argv': argv,
              'cwd': str(SOURCE), 'deadline_seconds': 120,
              'checkpoint': BINDING['host'], 'tree': BINDING['tree'],
              'python': sys.version, 'pillow': importlib.metadata.version('Pillow'),
              'materialized_source_files': before,
              'scope': 'Two explicit Python test modules; source view, not a complete Git checkout.'}
(OUTPUT / 'invocation.json').write_text(json.dumps(invocation, indent=2) + '\n')
started = time.monotonic()
actual_returncode = None
interruption = None
with (OUTPUT / 'stdout.original').open('xb') as stdout, (OUTPUT / 'stderr.original').open('xb') as stderr:
    try:
        completed = subprocess.run(argv, cwd=SOURCE, env=environment,
                                   stdout=stdout, stderr=stderr, timeout=120, check=False)
        actual_returncode = completed.returncode
    except subprocess.TimeoutExpired:
        interruption = 'Actual subprocess timeout after 120 seconds; no return code assigned.'
after = source_state()
raw = (OUTPUT / 'stderr.original').read_bytes()
matches = re.findall(rb'(?m)^Ran (\d+) tests? in ([0-9.]+)s$', raw)
test_count = int(matches[-1][0]) if matches else None
final_ok = bool(re.search(rb'(?m)^OK\s*$', raw))
result = {'status': 'PASS' if actual_returncode == 0 and test_count == 21 and final_ok and before == after else 'FAIL',
          'started_utc': invocation['started_utc'], 'finished_utc': utc(),
          'wall_seconds': time.monotonic() - started,
          'actual_returncode': actual_returncode, 'interruption': interruption,
          'original_reported_tests': test_count, 'original_final_ok': final_ok,
          'source_before_after_identical': before == after,
          'checkpoint': BINDING['host'], 'tree': BINDING['tree'],
          'streams': {name: {'bytes': (OUTPUT / name).stat().st_size,
                             'sha256': hashlib.sha256((OUTPUT / name).read_bytes()).hexdigest()}
                      for name in ('stdout.original', 'stderr.original')}}
(OUTPUT / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
(OUTPUT / 'source-after.json').write_text(json.dumps(after, indent=2) + '\n')
print(json.dumps(result))
raise SystemExit(0 if result['status'] == 'PASS' else 1)
