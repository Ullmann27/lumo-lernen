"""Small synthetic compatibility/counterexamples; no downloads or device tests."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parent
EVIDENCE = ROOT / 'evidence'
EVIDENCE.mkdir(exist_ok=True)


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


CHECK = load('creative_parts_check', ROOT / 'verify_creative_parts.py')
EXPORT = load('published_creative_export', ROOT / 'source-contract/export_creative_evidence_parts.py')
MEMORY = load('checked_memory_collector', ROOT / 'source-contract/checked_memory_collector.py')
assert hashlib.sha256((ROOT / 'source-contract/checked_memory_collector.py').read_bytes()).hexdigest() == CHECK.COLLECTOR_SHA256
EXPORTER_BYTES = (ROOT / 'source-contract/export_creative_evidence_parts.py').read_bytes()
assert hashlib.sha1(b'blob ' + str(len(EXPORTER_BYTES)).encode() + b'\0' + EXPORTER_BYTES).hexdigest() == CHECK.EXPORT_BLOB


def raw_json(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n').encode()


def change_index(members, change):
    index = json.loads(members['export-index.json'])
    change(index)
    index_raw = raw_json(index)
    members['export-index.json'] = index_raw
    part = json.loads(members['part.json'])
    part['index_sha256'] = hashlib.sha256(index_raw).hexdigest()
    part['index_bytes'] = len(index_raw)
    members['part.json'] = raw_json(part)


def fixture(root, mutate=None, mutate_api=None, mutate_run=None):
    root.mkdir()
    source = root / 'source'
    source.mkdir()
    for name, payload in {'a.txt': b'first-doc\n', 'nested/b.json': b'{"x":1}\n',
                          'z.log': b'third-data\n'}.items():
        path = source / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(payload)
    parts = root / 'published-parts'
    summary = EXPORT.export_parts(source, parts, repository=CHECK.REPOSITORY,
                                  workflow_path=CHECK.WORKFLOW, source_sha=CHECK.PROBE_SOURCE,
                                  run_id=CHECK.RUN, run_attempt=CHECK.ATTEMPT, max_part_bytes=20)
    assert summary['part_count'] == 2
    run = {'id': CHECK.RUN, 'run_attempt': CHECK.ATTEMPT, 'head_sha': CHECK.PROBE_SOURCE,
           'event': 'pull_request', 'path': CHECK.WORKFLOW, 'head_branch': CHECK.BRANCH,
           'repository': {'id': CHECK.REPOSITORY_ID, 'full_name': CHECK.REPOSITORY},
           'head_repository': {'id': CHECK.REPOSITORY_ID, 'full_name': CHECK.REPOSITORY},
           'head_commit': {'id': CHECK.PROBE_SOURCE, 'tree_id': CHECK.PROBE_TREE},
           'status': 'completed', 'conclusion': 'failure', 'synthetic_test_fixture': True}
    if mutate_run:
        mutate_run(run)
    run_file = root / 'run.json'
    run_file.write_bytes(raw_json(run))
    inputs = []
    for number in range(1, 3):
        part_root = parts / f'part-{number:02d}'
        members = {str(path.relative_to(part_root)): path.read_bytes()
                   for path in part_root.rglob('*') if path.is_file()}
        if mutate:
            mutate(number, members)
        archive_path = root / f'synthetic-part-{number:02d}.zip'
        with zipfile.ZipFile(archive_path, 'w', compression=zipfile.ZIP_DEFLATED) as zipped:
            for name, payload in sorted(members.items()):
                zipped.writestr(name, payload)
        raw = archive_path.read_bytes()
        aid = 9400000000 + number
        url = f'https://api.github.com/repos/{CHECK.REPOSITORY}/actions/artifacts/{aid}'
        metadata = {'id': aid, 'name': CHECK.NAME_PREFIX + f'{number:02d}',
                    'size_in_bytes': len(raw), 'digest': 'sha256:' + hashlib.sha256(raw).hexdigest(),
                    'url': url, 'archive_download_url': url + '/zip',
                    'workflow_run': {'id': CHECK.RUN, 'head_sha': CHECK.PROBE_SOURCE,
                                     'repository_id': CHECK.REPOSITORY_ID,
                                     'head_repository_id': CHECK.REPOSITORY_ID},
                    'synthetic_test_fixture': True}
        if mutate_api:
            mutate_api(number, metadata)
        metadata_path = root / f'api-part-{number:02d}.json'
        metadata_path.write_bytes(raw_json(metadata))
        collected = root / f'collected-part-{number:02d}'
        MEMORY.collect(metadata_file=metadata_path, local_zip=archive_path, url_file=None,
                       output=collected, selected=['export-index.json', 'part.json'],
                       limits=MEMORY.Limits(archive_bytes=len(raw),
                                            materialized_bytes=CHECK.MAX_INDEX_BYTES + CHECK.MAX_PART_JSON,
                                            members=CHECK.MAX_FILES + 2))
        inputs.append([metadata_path, collected / 'report.json',
                       collected / 'originals/export-index.json', collected / 'originals/part.json'])
    return run_file, inputs


class CreativePartsCases(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='tiny-case-', dir=EVIDENCE)
        self.addCleanup(self.temporary.cleanup)
        self.parent = Path(self.temporary.name)

    def build(self, **kwargs):
        return fixture(self.parent / 'fixture', **kwargs)

    def rejected(self, code, run, inputs):
        with self.assertRaises(CHECK.Rejected) as found:
            CHECK.verify_parts(run, inputs)
        self.assertEqual(found.exception.code, code)

    def test_real_exporter_collector_and_cli_complete_transport_only(self):
        run, inputs = self.build()
        paths = [run, *(path for part in inputs for path in part)]
        before = {path: path.read_bytes() for path in paths}
        output = self.parent / 'result.json'
        command = [sys.executable, '-B', str(ROOT / 'verify_creative_parts.py'), '--run', str(run)]
        for part in inputs:
            command += ['--part', *(str(path) for path in part)]
        command += ['--output', str(output)]
        result = subprocess.run(command, capture_output=True, check=False,
                                env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'})
        self.assertEqual(result.returncode, 0, result.stdout.decode())
        doc = json.loads(output.read_bytes())
        self.assertEqual(doc['status'], 'CREATIVE_PARTS_TRANSPORT_SNAPSHOT_COMPLETE')
        self.assertEqual((doc['part_count'], doc['original_file_count'], doc['original_payload_bytes']), (2, 3, 29))
        self.assertFalse(doc['product_acceptance'])
        self.assertEqual(doc['export_index_schema'], 2)
        self.assertEqual(doc['part_manifest_schema'], 1)
        self.assertEqual(doc['binding']['probe_source_sha'], CHECK.PROBE_SOURCE)
        self.assertNotIn('host_source_sha', doc['binding'])
        self.assertNotIn('host_tree', doc)
        self.assertEqual(doc['probe_source_tree'], CHECK.PROBE_TREE)
        for part in inputs:
            self.assertEqual(json.loads(part[2].read_bytes())['schema'], 2)
            self.assertEqual(json.loads(part[3].read_bytes())['schema'], 1)
        self.assertFalse(doc['earlier_full_zip_equality_claimed'])
        self.assertEqual({path: path.read_bytes() for path in paths}, before)
        # A failing workflow conclusion deliberately does not become product PASS.
        self.assertEqual(json.loads(run.read_bytes())['conclusion'], 'failure')

    def test_missing_and_duplicate_part_rejected(self):
        run, inputs = self.build()
        self.rejected('MISSING_OR_UNEXPECTED_PART', run, inputs[:1])
        self.rejected('DUPLICATE_PART_OR_ARTIFACT', run, [inputs[0], inputs[0]])

    def test_foreign_api_source_rejected(self):
        run, inputs = self.build(mutate_api=lambda n, api: api['workflow_run'].update(head_sha='0' * 40))
        self.rejected('ARTIFACT_RUN_OR_SOURCE_MISMATCH', run, inputs)

    def test_foreign_run_attempt_and_index_workflow_rejected(self):
        run, inputs = self.build(mutate_run=lambda value: value.update(run_attempt=2))
        self.rejected('RUN_OR_ATTEMPT_MISMATCH', run, inputs)
        second = self.parent / 'wrong-workflow'
        def change(number, members):
            change_index(members, lambda value: value['binding'].update(workflow_path='.github/workflows/lumo-studio-2019.yml'))
        other_run, other_inputs = fixture(second, mutate=change)
        self.rejected('INDEX_BINDING_MISMATCH', other_run, other_inputs)

    def test_self_consistent_but_different_index_rejected(self):
        def change(number, members):
            if number == 2:
                change_index(members, lambda value: value['files'][0].update(sha256='f' * 64))
        run, inputs = self.build(mutate=change)
        self.rejected('INDEX_NOT_IDENTICAL', run, inputs)

    def test_changed_member_with_valid_new_zip_crc_and_digest_rejected(self):
        def change(number, members):
            if number == 1:
                payload = members['originals/a.txt']
                members['originals/a.txt'] = b'X' + payload[1:]
        run, inputs = self.build(mutate=change)
        self.rejected('ORIGINAL_MEMBER_CONTENT_MISMATCH', run, inputs)

    def test_missing_or_unexpected_original_rejected(self):
        def remove(number, members):
            if number == 1:
                del members['originals/a.txt']
        run, inputs = self.build(mutate=remove)
        self.rejected('MISSING_OR_UNEXPECTED_MEMBER', run, inputs)
        def add(number, members):
            if number == 1:
                members['originals/unlisted.txt'] = b'unexpected'
        other_run, other_inputs = fixture(self.parent / 'unexpected-member', mutate=add)
        self.rejected('MISSING_OR_UNEXPECTED_MEMBER', other_run, other_inputs)

    def test_unsafe_original_path_and_published_limit_rejected(self):
        def unsafe(number, members):
            change_index(members, lambda value: value['files'][0].update(path='../escape.txt'))
        run, inputs = self.build(mutate=unsafe)
        self.rejected('UNSAFE_PATH', run, inputs)
        def excess(number, members):
            change_index(members, lambda value: value['limits'].update(part_payload_bytes=CHECK.MAX_PART_BYTES + 1))
        other_run, other_inputs = fixture(self.parent / 'excess-limit', mutate=excess)
        self.rejected('EXPORT_LIMIT_MISMATCH', other_run, other_inputs)

    def test_materialized_manifest_or_complete_report_changed_rejected(self):
        run, inputs = self.build()
        inputs[0][2].write_bytes(inputs[0][2].read_bytes() + b' ')
        self.rejected('MATERIALIZED_MANIFEST_DIFFERS', run, inputs)
        other_run, other_inputs = fixture(self.parent / 'incomplete-report')
        report = json.loads(other_inputs[0][1].read_bytes())
        report['all_members_crc_and_sha256_verified'] = False
        other_inputs[0][1].write_bytes(raw_json(report))
        self.rejected('COLLECTOR_REPORT_INCOMPLETE', other_run, other_inputs)

    def test_schema1_and_host_source_binding_never_alias_schema2_probe_source(self):
        def replace_with_host(value):
            value['binding']['host_source_sha'] = value['binding'].pop('probe_source_sha')

        changes = (
            ('legacy-schema', lambda value: value.update(schema=1), 'INDEX_SCHEMA_MISMATCH'),
            ('boolean-schema', lambda value: value.update(schema=True), 'INDEX_SCHEMA_MISMATCH'),
            ('host-key', replace_with_host, 'INDEX_BINDING_MISMATCH'),
            ('both-source-keys', lambda value: value['binding'].update(
                host_source_sha='7b16f2f5ab16f3d913ee170aefd9807c87216260'), 'INDEX_BINDING_MISMATCH'),
        )
        for name, change, code in changes:
            with self.subTest(case=name):
                run, inputs = fixture(self.parent / name,
                    mutate=lambda _number, members: change_index(members, change))
                self.rejected(code, run, inputs)

    def test_part_manifest_remains_exact_integer_schema1(self):
        for wrong in (2, True):
            def change(_number, members):
                value = json.loads(members['part.json'])
                value['schema'] = wrong
                members['part.json'] = raw_json(value)
            with self.subTest(schema=wrong):
                run, inputs = fixture(self.parent / ('part-schema-' + str(wrong)), mutate=change)
                self.rejected('PART_MANIFEST_MISMATCH', run, inputs)

    def test_apk7b16_and_prior_qa61c_cannot_identify_current_transport(self):
        previous = ('7b16f2f5ab16f3d913ee170aefd9807c87216260',
                    '61c94cfb78bda8dfbe191331eca0fd0382deb151')
        for index, source in enumerate(previous):
            with self.subTest(source=source, layer='index'):
                run, inputs = fixture(self.parent / ('index-source-' + str(index)),
                    mutate=lambda _number, members: change_index(
                        members, lambda value: value['binding'].update(probe_source_sha=source)))
                self.rejected('INDEX_BINDING_MISMATCH', run, inputs)
            with self.subTest(source=source, layer='artifact'):
                run, inputs = fixture(self.parent / ('api-source-' + str(index)),
                    mutate_api=lambda _number, value: value['workflow_run'].update(head_sha=source))
                self.rejected('ARTIFACT_RUN_OR_SOURCE_MISMATCH', run, inputs)
            with self.subTest(source=source, layer='run'):
                run, inputs = fixture(self.parent / ('run-source-' + str(index)),
                    mutate_run=lambda value: value.update(head_sha=source))
                self.rejected('RUN_SOURCE_OR_WORKFLOW_MISMATCH', run, inputs)

    def test_exact_current_run_branch_tree_and_event_are_required(self):
        changes = (
            ('old-build-run', lambda value: value.update(id=43540111465), 'RUN_OR_ATTEMPT_MISMATCH'),
            ('old-qa-run', lambda value: value.update(id=43551424080), 'RUN_OR_ATTEMPT_MISMATCH'),
            ('old-branch', lambda value: value.update(
                head_branch='qa/lumo-android-runtime-7b16-20261114'), 'RUN_SOURCE_OR_WORKFLOW_MISMATCH'),
            ('old-apk-tree', lambda value: value['head_commit'].update(
                tree_id='fe430b86449e4f4e221cadfc802f42db639f3133'), 'RUN_TREE_MISMATCH'),
            ('wrong-event', lambda value: value.update(event='push'), 'RUN_SOURCE_OR_WORKFLOW_MISMATCH'),
        )
        for name, change, code in changes:
            with self.subTest(case=name):
                run, inputs = fixture(self.parent / name, mutate_run=change)
                self.rejected(code, run, inputs)

    def test_cli_never_overwrites_an_existing_result(self):
        run, inputs = self.build()
        output = self.parent / 'preserved-result.json'
        previous = b'Original result bytes must remain unchanged.\n'
        output.write_bytes(previous)
        command = [sys.executable, '-B', str(ROOT / 'verify_creative_parts.py'), '--run', str(run)]
        for part in inputs:
            command += ['--part', *(str(path) for path in part)]
        command += ['--output', str(output)]
        result = subprocess.run(command, capture_output=True, check=False,
                                env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'})
        self.assertEqual(result.returncode, 1)
        self.assertEqual(json.loads(result.stdout)['status'], 'CREATIVE_PARTS_REJECTED')
        self.assertEqual(output.read_bytes(), previous)


if __name__ == '__main__':
    unittest.main(verbosity=2)
