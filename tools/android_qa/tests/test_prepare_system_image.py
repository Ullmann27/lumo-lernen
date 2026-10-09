"""New recovery guards for the published system-image helper.

These fixtures never download an SDK, accept licenses, create an AVD, or run
Android. The CLI cases execute a local, controlled sdkmanager fixture only.
Historical source/test proofs are deliberately not reused.
"""
from __future__ import annotations

import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from unittest.mock import patch

sys.dont_write_bytecode = True
HELPER_PATH = Path(__file__).resolve().parents[1] / 'prepare_system_image.py'
SPEC = importlib.util.spec_from_file_location('recovered_system_image_helper', HELPER_PATH)
assert SPEC is not None and SPEC.loader is not None
helper = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(helper)


class ManualClock:
    def __init__(self):
        self.value = 0.0

    def __call__(self):
        return self.value


class ControlledManager:
    """A synchronous runner; its clocks, files and outputs are controlled."""
    def __init__(self, case, *, actions=None, list_output=None, list_rc=0,
                 list_error='', list_seconds=0, list_hook=None, clock=None):
        self.case = case
        self.actions = list(actions if actions is not None else [{'rc': 0}])
        self.list_output = list_output
        self.list_rc = list_rc
        self.list_error = list_error
        self.list_seconds = list_seconds
        self.list_hook = list_hook
        self.clock = clock
        self.calls = []

    def __call__(self, arguments, *, stdin, stdout, stderr, timeout):
        self.case.assertEqual(stdin, subprocess.DEVNULL)
        self.case.assertGreater(timeout, 0)
        self.calls.append({'arguments': list(arguments), 'timeout': timeout})
        if '--list' in arguments:
            if self.list_hook:
                self.list_hook()
            output = self.list_output
            if output is None:
                output = self.case.installed_listing()
            error, rc, seconds = self.list_error, self.list_rc, self.list_seconds
        else:
            self.case.assertIn('--install', arguments)
            self.case.assertTrue(self.actions, 'Unexpected extra install attempt')
            action = self.actions.pop(0)
            if 'raise' in action:
                raise action['raise']
            rc = action.get('rc', 0)
            output, error = action.get('stdout', ''), action.get('stderr', '')
            seconds = action.get('seconds', 0)
            if action.get('partial'):
                self.case.seed_image(complete=False)
            if action.get('mutate'):
                action['mutate']()
            if rc == 0 and action.get('create', True):
                self.case.seed_image()
        stdout.write(output)
        stderr.write(error)
        if self.clock:
            self.clock.value += seconds
        return subprocess.CompletedProcess(arguments, rc)


class SystemImageRecoveryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='lumo-sdk-recovery-guard-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.sdk = self.root / 'sdk'
        self.sdk.mkdir()
        self.manager = self.sdk / 'cmdline-tools/latest/bin/sdkmanager'
        self.manager.parent.mkdir(parents=True)
        self.manager.write_text('#!/bin/sh\nexit 0\n')
        self.manager.chmod(0o755)
        self.license = self.sdk / 'licenses/android-sdk-license'
        self.license.parent.mkdir()
        self.license.write_bytes(b'already-accepted-fixture-license\n')
        self.api = 35
        self.out_number = 0

    @property
    def target(self):
        return self.sdk / f'system-images/android-{self.api}/google_apis/x86_64'

    def properties(self, **changes):
        values = {'AndroidVersion.ApiLevel': str(self.api), 'SystemImage.Abi': 'x86_64',
                  'SystemImage.TagId': 'google_apis', 'Pkg.Path': helper.package_name(self.api),
                  'AndroidVersion.CodeName': 'REL', 'Pkg.Revision': '9'}
        values.update(changes)
        return ''.join(f'{key}={value}\n' for key, value in values.items())

    def package_xml(self):
        return ('<repository><localPackage path="' + helper.package_name(self.api) + '">'
                '<type-details><api-level>' + str(self.api) + '</api-level>'
                '<abi>x86_64</abi><tag><id>google_apis</id></tag></type-details>'
                '<revision><major>9</major><minor>0</minor><micro>0</micro></revision>'
                '<uses-license ref="android-sdk-license"/></localPackage></repository>')

    def seed_image(self, *, mode='initial-image', complete=True):
        self.target.mkdir(parents=True, exist_ok=True)
        (self.target / 'source.properties').write_text(self.properties())
        (self.target / 'package.xml').write_text(self.package_xml())
        if complete:
            for name in helper.MANDATORY_IMAGE_FILES:
                (self.target / name).write_bytes(('controlled-' + name).encode())
            if mode in ('initial-image', 'both'):
                (self.target / 'userdata.img').write_bytes(b'controlled-initial-userdata')
            if mode in ('data-directory', 'both'):
                data = self.target / 'data'
                data.mkdir(exist_ok=True)
                (data / 'empty_data_disk').write_bytes(b'')
                (data / 'local.prop').write_bytes(b'ro.kernel.qemu=1\n')

    def reset_image(self, **kwargs):
        if self.target.exists():
            shutil.rmtree(self.target)
        self.seed_image(**kwargs)

    def invalid_path(self, path, kind):
        if path.is_symlink() or path.is_file():
            path.unlink()
        elif path.exists():
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
        if kind == 'missing':
            return
        if kind == 'empty':
            path.write_bytes(b'')
        elif kind == 'directory':
            path.mkdir()
        elif kind == 'symlink':
            external = self.root / 'external-file'
            external.write_bytes(b'controlled-external-content')
            path.symlink_to(external)
        elif kind == 'dangling-symlink':
            path.symlink_to(self.root / 'does-not-exist')
        elif kind == 'fifo':
            os.mkfifo(path)
        else:
            raise AssertionError(kind)

    def installed_listing(self):
        package = helper.package_name(self.api)
        location = f'system-images/android-{self.api}/google_apis/x86_64'
        return ('Installed packages:\n  Path | Version | Description | Location\n'
                f'  {package} | 9 | Controlled Google APIs image | {location}\n'
                'Available Packages:\n')

    def new_out(self):
        self.out_number += 1
        return self.root / f'evidence-{self.out_number}'

    def prepare(self, runner=None, **kwargs):
        return helper.prepare_system_image(self.api, self.new_out(), sdk=self.sdk,
                                           runner=runner or ControlledManager(self), **kwargs)

    def last_result(self):
        results = sorted(self.root.glob('evidence-*/system-image-*/result.json'))
        self.assertTrue(results)
        return json.loads(results[-1].read_text())

    def write_cli_manager(self, *, actions=None, list_output=None):
        config_path = self.sdk / 'controlled-manager.json'
        files = {'source.properties': self.properties(), 'package.xml': self.package_xml()}
        files.update({name: 'controlled-' + name for name in helper.MANDATORY_IMAGE_FILES})
        files['userdata.img'] = 'controlled-userdata'
        config = {'package': helper.package_name(self.api), 'api': self.api,
                  'actions': actions if actions is not None else [{'rc': 0}],
                  'listing': list_output if list_output is not None else self.installed_listing(),
                  'files': files}
        config_path.write_text(json.dumps(config))
        source = '''#!INTERPRETER
import json
from pathlib import Path
import sys
config_path = Path(CONFIG_PATH)
config = json.loads(config_path.read_text())
sdk = config_path.parent
records = sdk / 'controlled-manager-calls.jsonl'
previous = records.read_text().splitlines() if records.exists() else []
record = {'arguments': sys.argv[1:], 'stdin': sys.stdin.read()}
with records.open('a') as output:
    output.write(json.dumps(record) + '\\n')
if '--list' in sys.argv:
    print(config['listing'], end='')
    raise SystemExit(0)
if '--install' not in sys.argv or config['package'] not in sys.argv:
    print('Unexpected controlled invocation', file=sys.stderr)
    raise SystemExit(7)
index = sum('--install' in json.loads(line)['arguments'] for line in previous)
action = config['actions'][index]
target = sdk / ('system-images/android-' + str(config['api']) + '/google_apis/x86_64')
if action.get('partial') or action.get('rc', 0) == 0:
    target.mkdir(parents=True, exist_ok=True)
    for name, contents in config['files'].items():
        if action.get('partial') and name not in ('source.properties', 'package.xml'):
            continue
        (target / name).write_text(contents)
print(action.get('stdout', ''), end='')
print(action.get('stderr', ''), end='', file=sys.stderr)
raise SystemExit(action.get('rc', 0))
'''.replace('INTERPRETER', sys.executable).replace('CONFIG_PATH', repr(str(config_path)))
        self.manager.write_text(source)
        self.manager.chmod(0o755)

    def run_cli(self, *arguments):
        env = dict(os.environ, ANDROID_HOME=str(self.sdk), ANDROID_SDK_ROOT=str(self.sdk),
                   PYTHONDONTWRITEBYTECODE='1')
        return subprocess.run([sys.executable, str(HELPER_PATH), *arguments], env=env,
                              capture_output=True, text=True, timeout=15)

    def test_package_api35_exact(self):
        self.assertEqual(helper.package_name(35), 'system-images;android-35;google_apis;x86_64')

    def test_package_api36_exact(self):
        self.assertEqual(helper.package_name(36), 'system-images;android-36;google_apis;x86_64')

    def test_package_rejects_other_versions_and_types(self):
        for value in (34, 37, 0, '35', 35.0, True, False, None):
            with self.subTest(value=value), self.assertRaises(ValueError):
                helper.package_name(value)

    def test_revision_normalizes_release_trailing_zeros(self):
        for value, expected in (('9', (9,)), ('9.0', (9,)), ('9.0.0', (9,)),
                                ('9.1.0', (9, 1)), ('9.1.2', (9, 1, 2))):
            with self.subTest(value=value):
                self.assertEqual(helper.revision(value), expected)

    def test_revision_rejects_preview_and_malformed_values(self):
        for value in ('', '0', '09', '9-preview', '9.0.0.1', ' 9', '9 ', '9.-1', '9..0'):
            with self.subTest(value=value), self.assertRaises(RuntimeError):
                helper.revision(value)

    def test_metadata_legacy_initial_image(self):
        self.seed_image()
        observed = helper.metadata(self.target, self.api)
        self.assertEqual([x['file'] for x in observed['files']], list(helper.IMAGE_FILES))
        self.assertEqual(observed['userdata_bootstrap']['mode'], 'initial-image')
        self.assertFalse(observed['userdata_bootstrap']['generation_executed'])

    def test_metadata_modern_data_directory_allows_empty_marker(self):
        self.seed_image(mode='data-directory')
        observed = helper.metadata(self.target, self.api)
        self.assertEqual(len(observed['files']), 4)
        self.assertEqual(observed['userdata_bootstrap']['inputs'], [
            {'file': 'data/empty_data_disk', 'bytes': 0},
            {'file': 'data/local.prop', 'bytes': len(b'ro.kernel.qemu=1\n')}])
        self.assertIsNone(observed['userdata_bootstrap']['initial_image'])
        self.assertFalse(observed['userdata_bootstrap']['generation_executed'])

    def test_metadata_valid_both_layouts_records_both(self):
        self.seed_image(mode='both')
        observed = helper.metadata(self.target, self.api)['userdata_bootstrap']
        self.assertEqual(observed['mode'], 'data-directory')
        self.assertEqual(observed['initial_image']['file'], 'userdata.img')
        self.assertEqual(len(observed['inputs']), 2)

    def test_metadata_rejects_missing_all_userdata_bootstrap(self):
        self.seed_image(mode='none')
        with self.assertRaisesRegex(RuntimeError, 'No packaged userdata'):
            helper.metadata(self.target, self.api)

    def test_invalid_present_initial_image_cannot_use_valid_data_fallback(self):
        self.seed_image(mode='both')
        (self.target / 'userdata.img').write_bytes(b'')
        with self.assertRaisesRegex(RuntimeError, 'userdata.img'):
            helper.metadata(self.target, self.api)

    def test_invalid_present_data_cannot_use_valid_initial_fallback(self):
        self.seed_image(mode='both')
        (self.target / 'data/local.prop').unlink()
        with self.assertRaisesRegex(RuntimeError, 'local.prop'):
            helper.metadata(self.target, self.api)

    def test_initial_image_rejects_empty_nonregular_and_symlink(self):
        for kind in ('empty', 'directory', 'symlink', 'dangling-symlink', 'fifo'):
            with self.subTest(kind=kind):
                self.reset_image()
                self.invalid_path(self.target / 'userdata.img', kind)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_data_path_requires_actual_directory(self):
        for kind in ('empty', 'symlink', 'dangling-symlink', 'fifo'):
            with self.subTest(kind=kind):
                self.reset_image(mode='both')
                self.invalid_path(self.target / 'data', kind)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_empty_data_disk_requires_regular_marker(self):
        for kind in ('missing', 'directory', 'symlink', 'dangling-symlink', 'fifo'):
            with self.subTest(kind=kind):
                self.reset_image(mode='data-directory')
                self.invalid_path(self.target / 'data/empty_data_disk', kind)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_local_prop_requires_nonempty_regular_companion(self):
        for kind in ('missing', 'empty', 'directory', 'symlink', 'dangling-symlink', 'fifo'):
            with self.subTest(kind=kind):
                self.reset_image(mode='data-directory')
                self.invalid_path(self.target / 'data/local.prop', kind)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_every_mandatory_image_is_required(self):
        for name in helper.MANDATORY_IMAGE_FILES:
            with self.subTest(name=name):
                self.reset_image()
                (self.target / name).unlink()
                with self.assertRaisesRegex(RuntimeError, name):
                    helper.metadata(self.target, self.api)

    def test_mandatory_images_reject_empty_nonregular_and_symlinks(self):
        for name in helper.MANDATORY_IMAGE_FILES:
            for kind in ('empty', 'directory', 'symlink', 'fifo'):
                with self.subTest(name=name, kind=kind):
                    self.reset_image()
                    self.invalid_path(self.target / name, kind)
                    with self.assertRaises(RuntimeError):
                        helper.metadata(self.target, self.api)

    def test_properties_require_exact_stable_package_identity(self):
        for key, bad in (('AndroidVersion.ApiLevel', '36'), ('SystemImage.Abi', 'arm64-v8a'),
                         ('SystemImage.TagId', 'google_apis_playstore'), ('Pkg.Path', 'foreign'),
                         ('AndroidVersion.CodeName', 'Preview')):
            with self.subTest(key=key):
                self.reset_image()
                (self.target / 'source.properties').write_text(self.properties(**{key: bad}))
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_properties_reject_duplicate_and_malformed_lines(self):
        for tail in ('Pkg.Revision=9\n', 'missing-equals\n'):
            with self.subTest(tail=tail):
                self.reset_image()
                with (self.target / 'source.properties').open('a') as stream:
                    stream.write(tail)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_properties_require_regular_nonsymlink_metadata(self):
        for kind in ('missing', 'directory', 'symlink', 'dangling-symlink', 'fifo'):
            with self.subTest(kind=kind):
                self.reset_image()
                self.invalid_path(self.target / 'source.properties', kind)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_xml_rejects_wrong_or_duplicate_local_package(self):
        self.seed_image()
        good = self.package_xml()
        variants = [good.replace(helper.package_name(35), helper.package_name(36)),
                    good.replace('</repository>', good.split('<repository>')[1])]
        for value in variants:
            with self.subTest(value=value):
                (self.target / 'package.xml').write_text(value)
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_xml_requires_matching_platform_abi_tag_and_license(self):
        self.seed_image()
        for old, new in (('<api-level>35', '<api-level>36'), ('<abi>x86_64', '<abi>arm64-v8a'),
                         ('<id>google_apis', '<id>google_apis_playstore'),
                         ('ref="android-sdk-license"', 'ref="foreign-license"')):
            with self.subTest(new=new):
                (self.target / 'package.xml').write_text(self.package_xml().replace(old, new))
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_xml_required_fields_are_unique_and_present(self):
        self.seed_image()
        for name in ('type-details', 'revision', 'uses-license'):
            for action in ('missing', 'duplicate'):
                with self.subTest(name=name, action=action):
                    root = ET.fromstring(self.package_xml())
                    local = root.find('localPackage')
                    node = local.find(name)
                    if action == 'missing':
                        local.remove(node)
                    else:
                        local.append(ET.fromstring(ET.tostring(node)))
                    (self.target / 'package.xml').write_bytes(ET.tostring(root))
                    with self.assertRaises(RuntimeError):
                        helper.metadata(self.target, self.api)

    def test_xml_revision_rejects_preview_duplicate_and_invalid_number(self):
        self.seed_image()
        for replacement in ('<major>9</major><preview>1</preview>',
                            '<major>9</major><major>9</major>', '<major>0</major>',
                            '<major>9</major><minor>0</minor><minor>0</minor>'):
            with self.subTest(replacement=replacement):
                (self.target / 'package.xml').write_text(
                    self.package_xml().replace('<major>9</major>', replacement))
                with self.assertRaises(RuntimeError):
                    helper.metadata(self.target, self.api)

    def test_xml_missing_nonregular_symlink_and_parse_failure(self):
        for kind in ('missing', 'directory', 'symlink', 'fifo', 'malformed'):
            with self.subTest(kind=kind):
                self.reset_image()
                if kind == 'malformed':
                    (self.target / 'package.xml').write_text('<broken')
                else:
                    self.invalid_path(self.target / 'package.xml', kind)
                with self.assertRaises((RuntimeError, ET.ParseError)):
                    helper.metadata(self.target, self.api)

    def test_metadata_revisions_must_match(self):
        self.seed_image()
        (self.target / 'package.xml').write_text(self.package_xml().replace('<major>9', '<major>10'))
        with self.assertRaisesRegex(RuntimeError, 'revision differs'):
            helper.metadata(self.target, self.api)

    def test_metadata_hashes_bind_actual_raw_properties_and_xml(self):
        self.seed_image()
        observed = helper.metadata(self.target, self.api)
        for item in observed['metadata']:
            raw = (self.target / item['file']).read_bytes()
            self.assertEqual(item['bytes'], len(raw))
            self.assertEqual(item['sha256'], hashlib.sha256(raw).hexdigest())

    def test_partial_identity_does_not_require_finished_images(self):
        self.seed_image(complete=False)
        self.assertEqual(helper.metadata(self.target, self.api, complete=False),
                         {'partial_identity_checked': True})
        shutil.rmtree(self.target)
        self.target.mkdir()
        self.assertEqual(helper.metadata(self.target, self.api, complete=False),
                         {'partial_identity_checked': True})

    def test_partial_identity_rejects_present_wrong_metadata(self):
        self.seed_image(complete=False)
        (self.target / 'source.properties').write_text(self.properties(**{'SystemImage.Abi': 'arm64-v8a'}))
        with self.assertRaises(RuntimeError):
            helper.metadata(self.target, self.api, complete=False)

    def test_safe_target_rejects_symlinked_ancestor_and_sdk(self):
        external = self.root / 'external-images'
        external.mkdir()
        (self.sdk / 'system-images').symlink_to(external, target_is_directory=True)
        with self.assertRaises(RuntimeError):
            helper.safe_target(self.sdk, self.target)
        alias = self.root / 'sdk-alias'
        alias.symlink_to(self.sdk, target_is_directory=True)
        with self.assertRaises(RuntimeError):
            helper.safe_target(alias, alias / 'system-images/android-35/google_apis/x86_64')

    def test_safe_target_rejects_target_and_descendant_symlinks(self):
        self.seed_image()
        (self.target / 'unexpected-component').symlink_to(self.root / 'missing')
        with self.assertRaises(RuntimeError):
            helper.safe_target(self.sdk, self.target)
        (self.target / 'unexpected-component').unlink()
        shutil.rmtree(self.target)
        self.target.symlink_to(self.root / 'missing')
        with self.assertRaises(RuntimeError):
            helper.safe_target(self.sdk, self.target)

    def test_prepare_requires_existing_absolute_nonroot_sdk(self):
        for sdk in (Path('relative-sdk'), self.root / 'missing-sdk', Path('/')):
            with self.subTest(sdk=str(sdk)), self.assertRaises(RuntimeError):
                helper.prepare_system_image(35, self.new_out(), sdk=sdk)

    def test_environment_requires_home_and_matching_alternate(self):
        variants = ({}, {'ANDROID_HOME': str(self.sdk), 'ANDROID_SDK_ROOT': str(self.root / 'other')})
        for env in variants:
            with self.subTest(env=env), patch.dict(os.environ, env, clear=True), self.assertRaises(RuntimeError):
                helper.prepare_system_image(35, self.new_out())

    def test_matching_environment_reuses_exact_package(self):
        self.seed_image()
        runner = ControlledManager(self)
        with patch.dict(os.environ, {'ANDROID_HOME': str(self.sdk), 'ANDROID_SDK_ROOT': str(self.sdk)}, clear=True):
            state = helper.prepare_system_image(35, self.new_out(), runner=runner)
        self.assertEqual(state['status'], 'PASS')
        self.assertEqual(len(runner.calls), 1)

    def test_manager_must_be_executable_inside_sdk(self):
        for kind in ('missing', 'nonexecutable', 'outside'):
            with self.subTest(kind=kind):
                if self.manager.exists() or self.manager.is_symlink():
                    self.manager.unlink()
                if kind == 'nonexecutable':
                    self.manager.write_text('controlled')
                    self.manager.chmod(0o644)
                elif kind == 'outside':
                    external = self.root / 'outside-manager'
                    external.write_text('#!/bin/sh\nexit 0\n')
                    external.chmod(0o755)
                    self.manager.symlink_to(external)
                with self.assertRaises(RuntimeError):
                    self.prepare()

    def test_existing_license_must_be_nonempty_regular_and_nonsymlink(self):
        for kind in ('missing', 'empty', 'directory', 'symlink', 'fifo'):
            with self.subTest(kind=kind):
                self.invalid_path(self.license, kind)
                with self.assertRaises(RuntimeError):
                    self.prepare()
                self.invalid_path(self.license, 'missing')
                self.license.write_bytes(b'already-accepted-fixture-license\n')

    def test_license_directory_must_not_be_symlink(self):
        self.license.unlink()
        self.license.parent.rmdir()
        external = self.root / 'outside-licenses'
        external.mkdir()
        (external / 'android-sdk-license').write_bytes(b'controlled-license')
        self.license.parent.symlink_to(external, target_is_directory=True)
        with self.assertRaises(RuntimeError):
            self.prepare()

    def test_evidence_directory_must_be_outside_sdk(self):
        self.seed_image()
        with self.assertRaises(RuntimeError):
            helper.prepare_system_image(35, self.sdk / 'evidence', sdk=self.sdk)
        alias = self.root / 'evidence-alias'
        alias.symlink_to(self.sdk, target_is_directory=True)
        with self.assertRaises(RuntimeError):
            helper.prepare_system_image(35, alias / 'evidence', sdk=self.sdk)

    def test_timeout_bounds_and_types_fail_before_invocation(self):
        for value in (True, False, '600', 9, 601, -1, math.nan, math.inf):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.prepare(timeout=value)

    def test_reuse_issues_only_stable_installed_listing(self):
        self.seed_image(mode='data-directory')
        runner = ControlledManager(self)
        before = self.license.read_bytes()
        state = self.prepare(runner)
        self.assertTrue(state['reused'])
        self.assertEqual(state['shared_timeout_seconds'], 600)
        self.assertEqual(runner.calls[0]['arguments'], [str(self.manager), f'--sdk_root={self.sdk}', '--list', '--channel=0'])
        self.assertEqual(self.license.read_bytes(), before)
        self.assertIn('no emulator/APK/gameplay success', state['scope'])

    def test_first_install_uses_exact_api35_and_api36_packages(self):
        for api in (35, 36):
            with self.subTest(api=api):
                self.api = api
                runner = ControlledManager(self)
                state = self.prepare(runner)
                self.assertFalse(state['reused'])
                self.assertEqual(runner.calls[0]['arguments'][2:], ['--install', helper.package_name(api), '--channel=0'])
                self.assertEqual(len(runner.calls), 2)
                self.assertEqual(state['status'], 'PASS')

    def test_exact_zip_fault_retries_and_retains_matching_partial_package(self):
        runner = ControlledManager(self, actions=[{'rc': 1, 'stderr': helper.ZIP_WARNING, 'partial': True}, {'rc': 0}])
        state = self.prepare(runner)
        self.assertEqual(len(runner.calls), 3)
        self.assertEqual(state['retained_partial_packages'], ['partial-image-after-1'])
        retained = Path(state['evidence_directory']) / 'partial-image-after-1'
        self.assertEqual((retained / 'source.properties').read_text(), self.properties())
        self.assertFalse((retained / 'system.img').exists())
        self.assertEqual(state['status'], 'PASS')

    def test_exact_zip_fault_is_limited_to_three_install_attempts(self):
        runner = ControlledManager(self, actions=[{'rc': 1, 'stderr': helper.ZIP_WARNING}] * 3)
        with self.assertRaisesRegex(RuntimeError, 'max3'):
            self.prepare(runner)
        self.assertEqual(len(runner.calls), 3)
        self.assertEqual(self.last_result()['status'], 'FAIL')

    def test_other_installer_failures_are_not_retryable(self):
        variants = [dict(rc=2, stderr=helper.ZIP_WARNING), dict(rc=1, stderr='Network denied'),
                    dict(rc=1, stderr=helper.ZIP_WARNING + '\nUnexpected failure'),
                    dict(rc=1, stderr=helper.ZIP_WARNING, stdout='Warning: another fault')]
        for action in variants:
            with self.subTest(action=action):
                runner = ControlledManager(self, actions=[action])
                with self.assertRaises(RuntimeError):
                    self.prepare(runner)
                self.assertEqual(len(runner.calls), 1)

    def test_return_code_zero_does_not_hide_warning_or_stderr(self):
        for action in ({'rc': 0, 'stdout': 'Warning: incomplete image'}, {'rc': 0, 'stderr': 'unexpected stderr'}):
            with self.subTest(action=action):
                if self.target.exists():
                    shutil.rmtree(self.target)
                runner = ControlledManager(self, actions=[action])
                with self.assertRaises(RuntimeError):
                    self.prepare(runner)
                self.assertEqual(len(runner.calls), 1)

    def test_zip_retry_rejects_partial_package_of_wrong_identity(self):
        def wrong_partial():
            (self.target / 'source.properties').write_text(self.properties(**{'SystemImage.Abi': 'arm64-v8a'}))
        runner = ControlledManager(self, actions=[{'rc': 1, 'stderr': helper.ZIP_WARNING,
                                                 'partial': True, 'mutate': wrong_partial}])
        with self.assertRaises(RuntimeError):
            self.prepare(runner)
        self.assertEqual(len(runner.calls), 1)
        self.assertTrue(self.target.exists())

    def test_preexisting_incomplete_image_is_not_reinstalled(self):
        self.seed_image(complete=False)
        runner = ControlledManager(self)
        with self.assertRaises(RuntimeError):
            self.prepare(runner)
        self.assertEqual(runner.calls, [])
        self.assertEqual(self.last_result()['status'], 'FAIL')

    def test_installed_listing_requires_one_matching_installed_row(self):
        self.seed_image()
        good = self.installed_listing()
        row = good.splitlines()[2]
        variants = [good.replace('Installed packages:', 'Available Packages:'),
                    good + 'Installed packages:\n', good.replace(row, row + '\n' + row),
                    good.replace(' | 9 | ', ' | 8 | '), good.replace('google_apis/x86_64\n', 'google_apis/arm64\n'),
                    good.replace(row, row.rsplit('|', 1)[0]),
                    'Installed packages:\nAvailable Packages:\n' + row + '\n']
        for output in variants:
            with self.subTest(output=output):
                runner = ControlledManager(self, list_output=output)
                with self.assertRaises(RuntimeError):
                    self.prepare(runner)
                self.assertEqual(len(runner.calls), 1)

    def test_installed_listing_rejects_failed_command_and_error_output(self):
        self.seed_image()
        for kwargs in ({'list_rc': 1}, {'list_error': 'unexpected stderr'},
                       {'list_output': self.installed_listing() + 'Warning: unavailable\n'}):
            with self.subTest(kwargs=kwargs):
                runner = ControlledManager(self, **kwargs)
                with self.assertRaises(RuntimeError):
                    self.prepare(runner)
                self.assertEqual(len(runner.calls), 1)

    def test_three_attempts_and_listing_share_one_600_second_budget(self):
        clock = ManualClock()
        runner = ControlledManager(self, clock=clock, actions=[
            {'rc': 1, 'stderr': helper.ZIP_WARNING, 'seconds': 180},
            {'rc': 1, 'stderr': helper.ZIP_WARNING, 'seconds': 180},
            {'rc': 0, 'seconds': 180}], list_seconds=40)
        state = self.prepare(runner, clock=clock)
        self.assertEqual([x['timeout'] for x in runner.calls], [180, 180, 180, 60])
        self.assertEqual(state['elapsed_seconds'], 580)
        self.assertEqual(state['shared_timeout_seconds'], 600)

    def test_exhausted_shared_deadline_prevents_a_fresh_attempt(self):
        clock = ManualClock()
        runner = ControlledManager(self, clock=clock,
                                   actions=[{'rc': 1, 'stderr': helper.ZIP_WARNING, 'seconds': 10}])
        with self.assertRaises(TimeoutError):
            self.prepare(runner, clock=clock, timeout=10)
        self.assertEqual(len(runner.calls), 1)
        self.assertEqual(self.last_result()['status'], 'FAIL')

    def test_subprocess_timeout_is_not_retried_and_keeps_command_logs(self):
        runner = ControlledManager(self, actions=[{'raise': subprocess.TimeoutExpired('controlled-sdkmanager', 180)}])
        with self.assertRaises(subprocess.TimeoutExpired):
            self.prepare(runner)
        state = self.last_result()
        self.assertEqual(state['status'], 'FAIL')
        self.assertEqual(len(state['attempts']), 1)
        self.assertIn('error', state['attempts'][0])
        self.assertEqual(len(state['attempts'][0]['logs']), 2)

    def test_raw_metadata_and_bootstrap_evidence_exist_before_listing(self):
        self.seed_image(mode='data-directory')
        def assert_raw_evidence():
            state = self.last_result()
            evidence = Path(state['evidence_directory'])
            self.assertEqual(state['status'], 'RUNNING')
            for name in ('source.properties', 'package.xml'):
                self.assertEqual((evidence / ('installed-' + name)).read_bytes(), (self.target / name).read_bytes())
            bootstrap = json.loads((evidence / 'installed-userdata-bootstrap.json').read_text())
            self.assertEqual(bootstrap['mode'], 'data-directory')
            self.assertFalse(bootstrap['generation_executed'])
        state = self.prepare(ControlledManager(self, list_hook=assert_raw_evidence))
        evidence = Path(state['evidence_directory'])
        for attempt in state['attempts']:
            for item in attempt['logs']:
                raw = (evidence / item['file']).read_bytes()
                self.assertEqual(item['bytes'], len(raw))
                self.assertEqual(item['sha256'], hashlib.sha256(raw).hexdigest())

    def test_cli_reuses_api35_without_license_answers(self):
        self.seed_image(mode='data-directory')
        self.write_cli_manager()
        before = self.license.read_bytes()
        out = self.new_out()
        result = self.run_cli('--api', '35', '--out', str(out))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('[SystemImage] PASS: ' + helper.package_name(35), result.stdout)
        records = [json.loads(x) for x in (self.sdk / 'controlled-manager-calls.jsonl').read_text().splitlines()]
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]['arguments'], [f'--sdk_root={self.sdk}', '--list', '--channel=0'])
        self.assertEqual(records[0]['stdin'], '')
        self.assertEqual(self.license.read_bytes(), before)
        self.assertEqual(self.last_result()['verified_package']['userdata_bootstrap']['mode'], 'data-directory')

    def test_cli_reuses_api36_and_archives_raw_metadata(self):
        self.api = 36
        self.seed_image()
        self.write_cli_manager()
        result = self.run_cli('--api', '36', '--out', str(self.new_out()))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        state = self.last_result()
        self.assertEqual(state['package'], helper.package_name(36))
        for item in state['verified_package']['metadata']:
            path = Path(state['evidence_directory']) / item['evidence_file']
            self.assertEqual(path.read_bytes(), (self.target / item['file']).read_bytes())

    def test_cli_exact_zip_retry_uses_local_fixture_and_keeps_partial(self):
        self.write_cli_manager(actions=[{'rc': 1, 'stderr': helper.ZIP_WARNING, 'partial': True}, {'rc': 0}])
        result = self.run_cli('--api', '35', '--out', str(self.new_out()))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        state = self.last_result()
        self.assertEqual(state['retained_partial_packages'], ['partial-image-after-1'])
        self.assertEqual(len(state['attempts']), 3)
        records = [json.loads(x) for x in (self.sdk / 'controlled-manager-calls.jsonl').read_text().splitlines()]
        self.assertEqual(sum('--install' in x['arguments'] for x in records), 2)
        self.assertTrue(all(x['stdin'] == '' for x in records))
        self.assertTrue(all('--licenses' not in x['arguments'] for x in records))

    def test_cli_rejects_unsupported_api_before_manager_invocation(self):
        self.write_cli_manager()
        result = self.run_cli('--api', '34', '--out', str(self.new_out()))
        self.assertEqual(result.returncode, 2)
        self.assertIn('invalid choice', result.stderr)
        self.assertFalse((self.sdk / 'controlled-manager-calls.jsonl').exists())

    def test_cli_fails_missing_license_without_acceptance_attempt(self):
        self.write_cli_manager()
        self.license.unlink()
        result = self.run_cli('--api', '35', '--out', str(self.new_out()))
        self.assertEqual(result.returncode, 1)
        self.assertIn('[SystemImage] FAIL:', result.stdout)
        self.assertIn('no license answers supplied', result.stdout)
        self.assertFalse((self.sdk / 'controlled-manager-calls.jsonl').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
