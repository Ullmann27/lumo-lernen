"""Exact 2019/2020 contexts; synthetic metadata and a blocked Android boundary."""
import argparse
import ast
import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
from types import SimpleNamespace
import sys
import tempfile
import traceback
import unittest
from unittest.mock import Mock, patch

ROOT = Path(__file__).resolve().parents[2]
CREATIVE = ROOT / '.github/probes/studio_creative_android_probe.py'
SURFACES = ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py'
SPEC = importlib.util.spec_from_file_location('studio_2020_creative_contract', CREATIVE)
creative = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(creative)


def metadata(version):
    host, native = 'a' * 40, 'b' * 40
    expected = dict(host_source=host, native_source=native, build_run=100,
                    artifact_id=200, artifact_digest='sha256:' + 'c' * 64)
    run = dict(id=100, head_sha=host, path=f'.github/workflows/lumo-studio-{version}.yml',
               repository={'full_name': 'Ullmann27/lumo-lernen'})
    artifacts = {'artifacts': [dict(id=200, name=f'lumo-studio-{version}-candidate',
        size_in_bytes=1234, digest=expected['artifact_digest'], expired=False,
        workflow_run=dict(id=100, head_sha=host))]}
    jobs = {'jobs': [dict(id=300, name='verify-and-build', conclusion='success',
                         status='completed', run_id=100, head_sha=host)]}
    return run, artifacts, jobs, expected


def surface_namespace():
    # Compile the actual definitions, avoiding hardware/helper imports. No
    # function body is rewritten and no device success is manufactured.
    tree = ast.parse(SURFACES.read_text())
    definitions = [n for n in tree.body if isinstance(n, ast.FunctionDef)
                   and n.name in ('require_studio_version', 'main')]
    namespace = dict(argparse=argparse, Path=Path, json=json, traceback=traceback)
    exec(compile(ast.Module(body=definitions, type_ignores=[]), str(SURFACES), 'exec'), namespace)
    return namespace


class Studio2020AndroidContracts(unittest.TestCase):
    def test_default_2019_and_explicit_2020_metadata_are_separate(self):
        old = creative.verify_candidate_metadata(*metadata(2019))
        new = creative.verify_candidate_metadata(*metadata(2020), studio_version=2020)
        self.assertEqual(old['artifact']['name'], 'lumo-studio-2019-candidate')
        self.assertEqual(new['artifact']['name'], 'lumo-studio-2020-candidate')
        self.assertEqual(creative.ARTIFACT, 'lumo-studio-2019-candidate')

    def test_old_artifact_or_workflow_cannot_supply_new_acceptance(self):
        for version, other in ((2019, 2020), (2020, 2019)):
            for location in ('workflow', 'artifact'):
                values = metadata(version)
                if location == 'workflow':
                    values[0]['path'] = f'.github/workflows/lumo-studio-{other}.yml'
                else:
                    values[1]['artifacts'][0]['name'] = f'lumo-studio-{other}-candidate'
                with self.subTest(version=version, location=location), self.assertRaises(RuntimeError):
                    creative.verify_candidate_metadata(*values, studio_version=version)
        with self.assertRaises(RuntimeError):
            creative.verify_candidate_metadata(*metadata(2020))

    def test_fresh_artifact_source_digest_and_builder_remain_required(self):
        changes = (
            lambda v: v[0].update(head_sha='d' * 40),
            lambda v: v[1]['artifacts'][0].update(id=201),
            lambda v: v[1]['artifacts'][0].update(digest='sha256:' + 'd' * 64),
            lambda v: v[1]['artifacts'][0]['workflow_run'].update(head_sha='d' * 40),
            lambda v: v[2]['jobs'][0].update(conclusion='failure'),
        )
        for version in (2019, 2020):
            for change in changes:
                values = metadata(version); change(values)
                with self.subTest(version=version, change=change), self.assertRaises(RuntimeError):
                    creative.verify_candidate_metadata(*values, studio_version=version)

    def test_unlisted_versions_and_wrong_types_never_select_a_contract(self):
        check_surface = surface_namespace()['require_studio_version']
        for version in (2018, 2021, '2020', 2020.0, True, None):
            with self.subTest(version=version):
                with self.assertRaises(RuntimeError):
                    creative.verify_candidate_metadata(*metadata(2020), studio_version=version)
                with self.assertRaises(RuntimeError):
                    check_surface({'versionCode': 2020, 'versionName': '0.13.8'}, version)

    def test_surface_version_name_code_and_default_are_exact(self):
        check = surface_namespace()['require_studio_version']
        check({'versionCode': 2019, 'versionName': '0.13.7'})
        check({'versionCode': 2020, 'versionName': '0.13.8'}, 2020)
        for selected, identity in (
            (2019, {'versionCode': 2020, 'versionName': '0.13.8'}),
            (2020, {'versionCode': 2019, 'versionName': '0.13.7'}),
            (2020, {'versionCode': 2020, 'versionName': '0.13.7'}),
            (2020, {'versionCode': 2020.0, 'versionName': '0.13.8'}),
        ):
            with self.subTest(selected=selected, identity=identity), self.assertRaises(RuntimeError):
                check(identity, selected)

    def run_surface_main(self, selected, identity_version, *, prior_pass=True):
        namespace = surface_namespace()
        boundary = 'TEST BOUNDARY: no Android runtime contacted'
        def adb(*args, **kwargs):
            if args[:2] == ('shell', 'getprop'):
                raise RuntimeError(boundary)
            self.assertEqual(args[:2], ('logcat', '-d'))
            return ''
        base = SimpleNamespace(adb=Mock(side_effect=adb))
        identity = {'apk_sha256': 'd' * 64, 'versionCode': identity_version,
                    'versionName': {2019: '0.13.7', 2020: '0.13.8'}[identity_version]}
        namespace.update(base=base, probe=SimpleNamespace(capture=Mock()),
                         tour=SimpleNamespace(verify_apk_identity=Mock(return_value=identity)))
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); prior = root / 'prior.json'
            prior.write_text(json.dumps({'status': 'PASS' if prior_pass else 'FAIL',
                                         'apk_sha256': identity['apk_sha256']}))
            argv = ['probe', '--apk', str(root / 'synthetic.apk'), '--provenance', str(root / 'provenance.json'),
                    '--sums', str(root / 'sums.txt'), '--prior-tour', str(prior),
                    '--expected-api', '37', '--out', str(root / 'out')]
            if selected is not None:
                argv.extend(['--studio-version', str(selected)])
            with patch.object(sys, 'argv', argv), contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(namespace['main'](), 1)
            result = json.loads((root / 'out/native-surfaces-result.json').read_text())
        self.assertEqual(result['status'], 'FAIL')
        calls = [call for call in base.adb.call_args_list if call.args[:2] == ('shell', 'getprop')]
        return result, calls, boundary

    def test_actual_main_reaches_only_blocked_device_boundary_for_selected_version(self):
        for selected, version in ((None, 2019), (2020, 2020)):
            with self.subTest(selected=selected):
                result, calls, boundary = self.run_surface_main(selected, version)
                self.assertIn(boundary, result['error'])
                self.assertEqual(len(calls), 1)

    def test_actual_main_rejects_wrong_generation_and_failed_prior_before_device(self):
        for selected, version, prior_pass in ((None, 2020, True), (2020, 2019, True), (2020, 2020, False)):
            result, calls, boundary = self.run_surface_main(selected, version, prior_pass=prior_pass)
            self.assertEqual(calls, [])
            self.assertNotIn(boundary, result['error'])

    def test_candidate_binding_forwards_selected_version_and_retains_old_default(self):
        for selected in (None, 2020):
            version = 2019 if selected is None else selected
            run, artifacts, jobs, expected = metadata(version)
            with tempfile.TemporaryDirectory() as temp:
                root = Path(temp); (root / 'config').mkdir()
                (root / 'config/godot-source.json').write_text(json.dumps({
                    'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                    'revision': expected['native_source']}))
                for name, value in (('run.json', run), ('artifacts.json', artifacts), ('jobs.json', jobs)):
                    (root / name).write_text(json.dumps(value))
                args = SimpleNamespace(candidate_source=root, metadata_dir=root,
                    expected_source=expected['host_source'], build_run=100, artifact_id=200,
                    artifact_digest=expected['artifact_digest'])
                if selected is not None:
                    args.studio_version = selected
                self.assertEqual(creative.candidate_binding(args)['artifact']['name'],
                                 f'lumo-studio-{version}-candidate')


if __name__ == '__main__':
    unittest.main()
