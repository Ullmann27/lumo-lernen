"""Execute the workflow's real metadata/collision guards without network writes."""
import argparse
import ast
import copy
import json
from pathlib import Path
import re
import subprocess
import sys
import unittest

import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--workflow', type=Path, required=True)
parser.add_argument('--metadata', type=Path, required=True)
args, remaining = parser.parse_known_args()
workflow = yaml.safe_load(args.workflow.read_text())
steps = workflow['jobs']['archive-failed-evidence']['steps']
run_blocks = [step['run'] for step in steps if 'run' in step]
python_blocks = [block for script in run_blocks
                 for block in re.findall(r"python3 - <<'PY'\n(.*?)\nPY(?:\n|$)", script, re.S)]
assert len(run_blocks) == len(python_blocks) == 4
namespace = {}
for index, block in enumerate(python_blocks):
    parsed = ast.parse(block)
    compile(parsed, f'{args.workflow}:python-{index}', 'exec')
    definitions = [node for node in parsed.body if isinstance(node, ast.FunctionDef)]
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(args.workflow), 'exec'), namespace)

HOST = '4ab96666f954baf258422d6ed277fc297b7ddeef'
TAG = 'studio-failed-creative-evidence-' + HOST + '-14092241868'


class ArchiveContracts(unittest.TestCase):
    def metadata(self):
        values = [json.loads((args.metadata / f'{name}.json').read_text())
                  for name in ('repository', 'run', 'jobs', 'artifact')]
        values[2] = [values[2]]
        return values

    def validate(self, values):
        return namespace['validate_metadata'](*values)

    def existing(self):
        refs = [{'ref': 'refs/tags/' + TAG, 'object': {'type': 'commit', 'sha': HOST}}]
        release = {
            'tag_name': TAG, 'draft': False, 'prerelease': True,
            'assets': [{'name': name, 'state': 'uploaded', 'size': size}
                       for name, size in [('creative-failed-evidence.zip', 526570745),
                                          ('creative-failed-evidence.zip.sha256', 96),
                                          ('source-artifact.json', 1000),
                                          ('archive-binding.json', 1000)]],
        }
        return refs, [[release]]

    def test_actual_completed_original_metadata_passes(self):
        job = self.validate(self.metadata())
        self.assertEqual(job['id'], 132269951369)
        self.assertEqual(job['conclusion'], 'failure')

    def test_foreign_source_in_run_job_or_artifact_is_rejected(self):
        for boundary in ('run', 'job', 'artifact'):
            with self.subTest(boundary=boundary):
                values = self.metadata()
                row = values[1] if boundary == 'run' else values[3]['workflow_run']
                if boundary == 'job':
                    row = next(j for j in values[2][0]['jobs'] if j['id'] == 132269951369)
                row['head_sha'] = 'b' * 40
                with self.assertRaises(RuntimeError):
                    self.validate(values)

    def test_wrong_original_artifact_identity_size_digest_or_expiry_is_rejected(self):
        for key, value in [('id', 14089507933), ('size_in_bytes', 526570744),
                           ('digest', 'sha256:' + '0' * 64), ('expired', True),
                           ('name', 'lumo-studio-2019-candidate')]:
            with self.subTest(field=key):
                values = self.metadata()
                values[3][key] = value
                with self.assertRaises(RuntimeError):
                    self.validate(values)

    def test_wrong_attempt_repository_or_relabelled_success_is_rejected(self):
        for field, value in [('run_attempt', 2), ('conclusion', 'success'), ('status', 'in_progress')]:
            with self.subTest(field=field):
                values = self.metadata()
                values[1][field] = value
                with self.assertRaises(RuntimeError):
                    self.validate(values)
        values = self.metadata()
        values[0]['private'] = True
        with self.assertRaises(RuntimeError):
            self.validate(values)

    def test_missing_or_relabelled_creative_job_is_rejected(self):
        for mode in ('missing', 'duplicate', 'success'):
            with self.subTest(mode=mode):
                values = self.metadata()
                jobs = values[2][0]['jobs']
                job = next(j for j in jobs if j['id'] == 132269951369)
                if mode == 'missing':
                    jobs.remove(job)
                elif mode == 'duplicate':
                    jobs.append(copy.deepcopy(job))
                else:
                    job['conclusion'] = 'success'
                with self.assertRaises(RuntimeError):
                    self.validate(values)

    def test_absent_archive_creates_and_complete_archive_only_verifies(self):
        self.assertEqual(namespace['archive_mode']([], [[]]), 'create')
        self.assertEqual(namespace['archive_mode'](*self.existing()), 'verify-existing')

    def test_partial_or_foreign_tag_never_permits_replacement(self):
        refs, pages = self.existing()
        for pair in [(refs, [[]]), ([], pages)]:
            with self.subTest(pair=pair):
                with self.assertRaises(AssertionError):
                    namespace['archive_mode'](*pair)
        refs[0]['object']['sha'] = 'b' * 40
        with self.assertRaises(AssertionError):
            namespace['archive_mode'](refs, pages)

    def test_foreign_incomplete_or_non_prerelease_asset_set_is_rejected(self):
        for mode in ('apk', 'incomplete', 'size', 'digest', 'draft', 'normal_release'):
            with self.subTest(mode=mode):
                refs, pages = self.existing()
                release = pages[0][0]
                if mode == 'apk':
                    release['assets'].append({'name': 'app.apk', 'state': 'uploaded', 'size': 1})
                elif mode == 'incomplete':
                    release['assets'][0]['state'] = 'new'
                elif mode == 'size':
                    release['assets'][0]['size'] -= 1
                elif mode == 'digest':
                    release['assets'][0]['digest'] = 'sha256:' + '0' * 64
                elif mode == 'draft':
                    release['draft'] = True
                else:
                    release['prerelease'] = False
                with self.assertRaises(AssertionError):
                    namespace['archive_mode'](refs, pages)


if __name__ == '__main__':
    for index, script in enumerate(run_blocks):
        checked = subprocess.run(['bash', '-n'], input=script, text=True, capture_output=True)
        if checked.returncode:
            raise RuntimeError(f'Run block {index}: {checked.stderr}')
    print('Four actual workflow Bash blocks and four embedded Python blocks compile.', flush=True)
    unittest.main(argv=[sys.argv[0], *remaining])
