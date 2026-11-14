#!/usr/bin/env python3
"""Verify the inactive QA91 observer overlay; execute only its existing contracts."""
from __future__ import annotations

import datetime
import difflib
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

import PIL
import yaml

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'evidence'
WORKFLOW = ROOT / '.github/workflows/lumo-village-return-6b-diagnostic.yml'
ACTIONLINT = Path('/workspace/scratch/909ddb52fe7b/native-upstream-057-review/trigger-patch/bin/actionlint')
ADDED_LINE = '            tools.android_qa.tests.test_connect_four_probe_deadlines \\\n'


def blob(data):
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def save(name, value):
    with (OUT/name).open('x') as stream:
        stream.write(json.dumps(value, indent=2)+'\n')


class UniqueLoader(yaml.SafeLoader):
    pass


def unique_mapping(loader, node, deep=False):
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in result:
            raise ValueError('Duplicate YAML key: '+str(key))
        result[key] = loader.construct_object(value_node, deep=deep)
    return result


UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping)


def main():
    old = (OUT/'original-workflow.yml').read_text()
    new = WORKFLOW.read_text()
    assert new.count(ADDED_LINE) == 1 and new.replace(ADDED_LINE, '') == old
    old_yaml = yaml.load(old, Loader=UniqueLoader)
    new_yaml = yaml.load(new, Loader=UniqueLoader)
    modules = re.findall(r'^\s*((?:scripts|tools)\.[a-zA-Z0-9_.]+)\s*\\$', new, re.M)
    old_modules = re.findall(r'^\s*((?:scripts|tools)\.[a-zA-Z0-9_.]+)\s*\\$', old, re.M)
    assert len(old_modules) == 7 and modules == old_modules+[
        'tools.android_qa.tests.test_connect_four_probe_deadlines']
    assert len(modules) == len(set(modules))
    assert old_yaml['env'] == new_yaml['env']
    assert old_yaml['jobs']['android-diagnostic'] == new_yaml['jobs']['android-diagnostic']
    baseline = json.loads((OUT/'qa91-source-context.json').read_text())
    expected = {
        '.github/probes/lumo_connect_four_android_probe.py': '836cf90f170545ce6d6393d5034dc149f5f6cf8c',
        'tools/android_qa/tests/test_connect_four_probe_deadlines.py': 'da877b93d3ae61c54b1743f8aba006bac614cdea',
        '.github/workflows/lumo-village-return-6b-diagnostic.yml': blob(new.encode()),
    }

    def identity():
        rows = []
        for entry in baseline['files']:
            data = (ROOT/entry['path']).read_bytes()
            actual = blob(data)
            assert actual == expected.get(entry['path'], entry['sha']), entry['path']
            rows.append({'path': entry['path'], 'git_blob': actual, 'bytes': len(data)})
        return rows

    before = identity()
    for name in list(expected)[:2]:
        compile((ROOT/name).read_text(), name, 'exec')
    syntax = []
    for job_name, job in new_yaml['jobs'].items():
        for index, step in enumerate(job['steps']):
            if 'run' not in step:
                continue
            name = f'{job_name}-step-{index:02d}.sh'
            path = OUT/name
            with path.open('x') as stream:
                stream.write(step['run'])
            checked = subprocess.run(['bash', '-n', str(path)], capture_output=True, text=True)
            syntax.append({'job': job_name, 'step': index, 'name': step.get('name'),
                           'exit_code': checked.returncode, 'stdout': checked.stdout,
                           'stderr': checked.stderr,
                           'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
            assert checked.returncode == 0, checked.stderr
    runner = subprocess.run(['bash', '-n', str(ROOT/'scripts/run_unchanged_6b_village_diagnostic.sh')],
                            capture_output=True, text=True)
    assert runner.returncode == 0, runner.stderr
    lint = subprocess.run([str(ACTIONLINT), str(WORKFLOW)], capture_output=True, text=True)
    with (OUT/'actionlint.original.log').open('x') as stream:
        stream.write(lint.stdout+lint.stderr)
    assert lint.returncode == 0, lint.stdout+lint.stderr
    save('syntax-and-preservation.json', {
        'base_qa': baseline['source'], 'base_tree': baseline['tree'],
        'workflow_git_blob': expected['.github/workflows/lumo-village-return-6b-diagnostic.yml'],
        'workflow_only_one_additive_test_module': True,
        'old_contract_modules': old_modules, 'final_contract_modules': modules,
        'apk_source_native_bindings_and_android_job_structurally_identical': True,
        'only_three_source_changes': expected,
        'all_other_materialized_sources_and_original_fixtures_byte_identical': True,
        'verified_source_files': len(before), 'yaml_duplicate_keys': False,
        'bash_blocks': syntax, 'runner_bash_n_exit': runner.returncode,
        'actionlint_exit': lint.returncode,
        'actionlint_sha256': hashlib.sha256(ACTIONLINT.read_bytes()).hexdigest(),
        'python_compile': 'PASS', 'device_or_workflow_commands_executed': False})
    with (OUT/'workflow.diff').open('x') as stream:
        stream.write(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
            fromfile='a/.github/workflows/lumo-village-return-6b-diagnostic.yml',
            tofile='b/.github/workflows/lumo-village-return-6b-diagnostic.yml')))
    command = [sys.executable, '-B', '-m', 'unittest', '-v', *modules]
    env = {**os.environ, 'PYTHONDONTWRITEBYTECODE': '1',
           'PYTHONPATH': str(ROOT/'tools/android_qa/tests')}
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    clock = time.monotonic()
    with (OUT/'contracts.original.log').open('xb') as stream:
        tested = subprocess.run(command, cwd=ROOT, env=env, stdout=stream,
                                stderr=subprocess.STDOUT, check=False)
    elapsed = time.monotonic()-clock
    after = identity()
    assert before == after
    text = (OUT/'contracts.original.log').read_text()
    skipped = bool(re.search(r'^OK \(skipped=|^FAILED.*skipped=', text, re.M))
    save('contracts.execution.json', {
        'base_qa': baseline['source'], 'started_at': started,
        'command': command, 'elapsed_seconds': elapsed, 'exit_code': tested.returncode,
        'skipped_summary': skipped, 'before': before, 'after': after,
        'python': sys.version, 'pillow': PIL.__version__, 'pyyaml': yaml.__version__,
        'scope': 'Eight actual diagnostic contract modules; original fixtures retained; no device, SDK, renderer or workflow execution'})
    print(json.dumps({'exit_code': tested.returncode, 'skipped_summary': skipped,
                      'elapsed_seconds': elapsed, 'syntax': 'PASS', 'module_count': len(modules)}))
    return tested.returncode or int(skipped)


if __name__ == '__main__':
    raise SystemExit(main())
