from pathlib import Path
import argparse
import datetime
import hashlib
import json
import platform
import shutil
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', required=True)
parser.add_argument('--source-commit', required=True)
parser.add_argument('--expected-workflow-blob', required=True)
args = parser.parse_args()
output = Path(args.output)
output.mkdir(parents=True, exist_ok=False)

def sources():
    values = {}
    for relative in (
        '.github/workflows/lumo-connect-four-2020.yml',
        'config/godot-source.json',
        'scripts/tests/test_connect_four_return_gate.py',
    ):
        data = (ROOT / relative).read_bytes()
        values[relative] = {
            'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': hashlib.sha1(
                b'blob ' + str(len(data)).encode() + b'\0' + data
            ).hexdigest(),
        }
    return values

before = sources()
assert before['.github/workflows/lumo-connect-four-2020.yml']['git_blob'] == args.expected_workflow_blob
observed = []

class RecordingResult(unittest.TextTestResult):
    def stopTest(self, test):
        observed.append({
            'test': test.id(),
            'executions': getattr(test, 'gate_executions', []),
        })
        super().stopTest(test)

started = datetime.datetime.now(datetime.timezone.utc).isoformat()
suite = unittest.defaultTestLoader.discover(
    str(ROOT / 'scripts/tests'), pattern='test_connect_four_return_gate.py',
)
with (output / 'unittest.log').open('w') as log:
    result = unittest.TextTestRunner(
        stream=log, verbosity=2, resultclass=RecordingResult
    ).run(suite)
after = sources()
assert before == after, 'Sources changed during actual targeted execution'
exit_code = 0 if result.wasSuccessful() else 1
report = {
    'scope': 'Actual execution of the unmodified workflow shell step with real Bash/Git/timeout/tee/grep/Python and explicit fake Godot. Synthetic tracked Git fixtures; no Native engine, Android, or game acceptance.',
    'host_workflow_source_commit': args.source_commit,
    'started_utc': started,
    'completed_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'python_version': platform.python_version(),
    'actual_command': sys.argv,
    'tools': {name: shutil.which(name) for name in
              ('python3', 'bash', 'git', 'timeout', 'tee', 'grep')},
    'unittest_methods': result.testsRun,
    'failure_cases': len(result.failures),
    'errors': len(result.errors),
    'skipped': len(result.skipped),
    'exit_code': exit_code,
    'shell_execution_count': sum(len(row['executions']) for row in observed),
    'sources_before': before,
    'sources_after': after,
    'source_bytes_unchanged': True,
    'execution_records': observed,
}
(output / 'execution.json').write_text(json.dumps(report, indent=2) + '\n')
print((output / 'unittest.log').read_text(), end='')
print('Actual shell invocations:', report['shell_execution_count'])
print('Source bytes unchanged:', before == after)
print('Scope: explicit fake Godot only; no Native/Android execution')
raise SystemExit(exit_code)
