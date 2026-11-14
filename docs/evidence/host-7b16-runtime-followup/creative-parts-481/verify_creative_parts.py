#!/usr/bin/env python3
"""Check one complete Creative parts snapshot using local verified metadata only.

Inputs must be original GitHub API objects, complete reports from the previously
checked memory collector, and its byte-identical materialized index/part files.
This fixed PR481 verifier expects a schema-2 index bound to its QA probe source;
the unchanged built APK is not the transport source. Part manifests stay schema 1.
This program neither downloads nor reopens ZIP payloads and does not authenticate
the external provenance of supplied JSON files. It grants no product acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import sys

PROBE_SOURCE = 'f89b77bbc9caacfb677a8f0b7922f27fcbbd546f'
PROBE_TREE = '5c42a92ae49e73d4739cacaaf35f2102561d841a'
RUN = 43556708653
ATTEMPT = 1
REPOSITORY = 'Ullmann27/lumo-lernen'
REPOSITORY_ID = 1222433959
WORKFLOW = '.github/workflows/lumo-creative-7b16-diagnostic.yml'
BRANCH = 'qa/lumo-creative-7b16-20261114'
NAME_PREFIX = 'lumo-creative-7b16-diagnostic-creative-part-'
MAX_PART_BYTES = 256 * 1024 * 1024
MAX_PARTS = 8
MAX_FILES = 20000
MAX_INDEX_BYTES = 4 * 1024 * 1024
MAX_PART_JSON = 16 * 1024
MAX_API_BYTES = 1024 * 1024
MAX_REPORT_BYTES = 16 * 1024 * 1024
EXPORT_BLOB = '4c113e5b73e9f6eb3c02ab48b25f0aa3331f79c9'
COLLECTOR_SHA256 = '9d7b07d27657b9c9a62c7027393419006480bc3d28848cfabe6811be21a6204e'
EXPECTED_BINDING = {'repository': REPOSITORY, 'workflow_path': WORKFLOW,
                    'probe_source_sha': PROBE_SOURCE, 'run_id': RUN, 'run_attempt': ATTEMPT}
EMPTY_SHA = hashlib.sha256(b'').hexdigest()


class Rejected(Exception):
    def __init__(self, code: str):
        self.code = code
        super().__init__(code)


def require(condition, code):
    if not condition:
        raise Rejected(code)


def integer(value, low=0, high=None):
    return type(value) is int and value >= low and (high is None or value <= high)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def sha256_value(value):
    return isinstance(value, str) and re.fullmatch(r'[a-f0-9]{64}', value) is not None


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'DUPLICATE_JSON_KEY')
        result[key] = value
    return result


def invalid_number(_):
    raise Rejected('NONFINITE_JSON_NUMBER')


def read_json(path, limit):
    path = Path(path)
    flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK
    with os.fdopen(os.open(path, flags), 'rb') as stream:
        before = os.fstat(stream.fileno())
        require(stat.S_ISREG(before.st_mode), 'INPUT_NOT_REGULAR')
        require(before.st_size <= limit, 'INPUT_SIZE_LIMIT')
        raw = stream.read(limit + 1)
        after = os.fstat(stream.fileno())
    require(len(raw) == before.st_size and len(raw) <= limit, 'INPUT_SIZE_CHANGED')
    signature = lambda info: (info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns)
    require(signature(before) == signature(after), 'INPUT_CHANGED')
    try:
        value = json.loads(raw.decode('utf-8'), object_pairs_hook=unique_object,
                           parse_constant=invalid_number)
    except (UnicodeError, ValueError):
        raise Rejected('INVALID_JSON') from None
    require(isinstance(value, dict), 'JSON_OBJECT_REQUIRED')
    return value, raw, {'path': str(path), 'bytes': len(raw), 'sha256': digest(raw)}


def safe_path(value, directory=False):
    require(isinstance(value, str) and bool(value), 'UNSAFE_PATH')
    require(len(value.encode('utf-8')) <= 4096 and not value.startswith('/') and
            '\\' not in value and ':' not in value and
            not any(ord(c) < 32 or ord(c) == 127 for c in value), 'UNSAFE_PATH')
    name = value[:-1] if directory and value.endswith('/') else value
    require(all(piece not in ('', '.', '..') for piece in name.split('/')), 'UNSAFE_PATH')
    return name


def verify_run(path):
    run, _, identity = read_json(path, MAX_API_BYTES)
    require(integer(run.get('id'), 1) and run['id'] == RUN and
            integer(run.get('run_attempt'), 1) and run['run_attempt'] == ATTEMPT,
            'RUN_OR_ATTEMPT_MISMATCH')
    require(run.get('head_sha') == PROBE_SOURCE and run.get('event') == 'pull_request' and
            run.get('path') == WORKFLOW and run.get('head_branch') == BRANCH,
            'RUN_SOURCE_OR_WORKFLOW_MISMATCH')
    for key in ('repository', 'head_repository'):
        repository = run.get(key)
        require(isinstance(repository, dict) and repository.get('full_name') == REPOSITORY and
                type(repository.get('id')) is int and repository['id'] == REPOSITORY_ID,
                'RUN_REPOSITORY_MISMATCH')
    commit = run.get('head_commit')
    require(isinstance(commit, dict) and commit.get('id') == PROBE_SOURCE and
            commit.get('tree_id') == PROBE_TREE, 'RUN_TREE_MISMATCH')
    return identity


def verify_inventory(report):
    require(type(report.get('schema')) is int and report['schema'] == 1 and
            report.get('status') == 'VERIFIED_ARCHIVE', 'COLLECTOR_REPORT_NOT_VERIFIED')
    require(report.get('archive_size_and_sha256_verified_before_zip_parsing') is True and
            report.get('all_members_crc_and_sha256_verified') is True,
            'COLLECTOR_REPORT_INCOMPLETE')
    origin = report.get('input')
    require(isinstance(origin, dict) and origin.get('mode') in ('local_original_zip', 'private_https_download') and
            origin.get('complete_zip_written_by_collector') is False and origin.get('url_recorded') is False,
            'COLLECTOR_INPUT_CONTRACT_MISMATCH')
    rows, limits = report.get('members'), report.get('limits')
    require(isinstance(rows, list) and isinstance(limits, dict), 'INVALID_INVENTORY')
    require(all(integer(limits.get(key), 1) for key in ('archive_bytes', 'expanded_bytes', 'members')) and
            integer(limits.get('materialized_bytes')), 'INVALID_COLLECTOR_LIMITS')
    require(len(rows) <= limits['members'], 'INVENTORY_COUNT_MISMATCH')
    files, directories, seen, total = {}, set(), set(), 0
    for row in rows:
        require(isinstance(row, dict) and row.get('kind') in ('file', 'directory'), 'INVALID_MEMBER')
        directory = row['kind'] == 'directory'
        name = safe_path(row.get('path'), directory)
        require(name not in seen, 'DUPLICATE_MEMBER_PATH')
        seen.add(name)
        require(integer(row.get('bytes')) and integer(row.get('compressed_bytes')) and
                sha256_value(row.get('sha256')) and isinstance(row.get('crc32'), str) and
                re.fullmatch(r'[a-f0-9]{8}', row['crc32']) is not None, 'INVALID_MEMBER_IDENTITY')
        total += row['bytes']
        if directory:
            require(row['bytes'] == 0 and row['sha256'] == EMPTY_SHA and row['crc32'] == '00000000',
                    'INVALID_DIRECTORY_MEMBER')
            directories.add(name)
        else:
            files[name] = row
    for name in seen:
        parts = name.split('/')
        require(not any('/'.join(parts[:n]) in files for n in range(1, len(parts))), 'MEMBER_PATH_COLLISION')
    require(len(files) <= MAX_FILES + 2, 'INVENTORY_COUNT_MISMATCH')
    require(integer(report.get('expanded_bytes')) and report['expanded_bytes'] == total and
            total <= limits['expanded_bytes'], 'EXPANDED_SIZE_MISMATCH')
    selected = report.get('materialized_members')
    require(isinstance(selected, list) and all(isinstance(name, str) for name in selected) and
            len(selected) == len(set(selected)) and all(name in files for name in selected),
            'INVALID_MATERIALIZED_SELECTION')
    require({'export-index.json', 'part.json'}.issubset(selected), 'MANIFESTS_NOT_MATERIALIZED')
    require(integer(report.get('materialized_bytes')) and
            report['materialized_bytes'] == sum(files[name]['bytes'] for name in selected) and
            report['materialized_bytes'] <= limits['materialized_bytes'], 'MATERIALIZED_SIZE_MISMATCH')
    return files, directories


def load_part(paths):
    metadata, metadata_raw, api_identity = read_json(paths[0], MAX_API_BYTES)
    report, _, report_identity = read_json(paths[1], MAX_REPORT_BYTES)
    index, index_raw, index_identity = read_json(paths[2], MAX_INDEX_BYTES)
    part, part_raw, part_identity = read_json(paths[3], MAX_PART_JSON)
    name = metadata.get('name')
    match = re.fullmatch(re.escape(NAME_PREFIX) + r'(0[1-8])', name) if isinstance(name, str) else None
    require(match is not None, 'ARTIFACT_NAME_MISMATCH')
    number = int(match.group(1))
    aid, size, checksum = metadata.get('id'), metadata.get('size_in_bytes'), metadata.get('digest')
    require(integer(aid, 1) and integer(size, 1) and isinstance(checksum, str) and
            checksum.startswith('sha256:') and sha256_value(checksum[7:]), 'INVALID_ARTIFACT_IDENTITY')
    api_url = f'https://api.github.com/repos/{REPOSITORY}/actions/artifacts/{aid}'
    require(metadata.get('url') == api_url and metadata.get('archive_download_url') == api_url + '/zip',
            'ARTIFACT_REPOSITORY_MISMATCH')
    workflow_run = metadata.get('workflow_run')
    require(isinstance(workflow_run, dict) and type(workflow_run.get('id')) is int and
            workflow_run['id'] == RUN and workflow_run.get('head_sha') == PROBE_SOURCE,
            'ARTIFACT_RUN_OR_SOURCE_MISMATCH')
    require(all(type(workflow_run.get(key)) is int and workflow_run[key] == REPOSITORY_ID
                for key in ('repository_id', 'head_repository_id')), 'ARTIFACT_REPOSITORY_MISMATCH')
    report_metadata, report_artifact = report.get('metadata'), report.get('artifact')
    require(isinstance(report_metadata, dict) and type(report_metadata.get('bytes')) is int and
            report_metadata == {'bytes': len(metadata_raw), 'sha256': digest(metadata_raw)},
            'API_OBJECT_NOT_BOUND_TO_REPORT')
    require(isinstance(report_artifact, dict) and
            all(type(report_artifact.get(key)) is int for key in ('id', 'bytes', 'run_id')) and
            report_artifact == {'id': aid, 'bytes': size, 'sha256': checksum[7:],
                                'run_id': RUN, 'head_sha': PROBE_SOURCE}, 'REPORT_ARTIFACT_MISMATCH')
    files, directories = verify_inventory(report)
    require(size <= report['limits']['archive_bytes'], 'COLLECTOR_ARCHIVE_LIMIT_MISMATCH')
    for member, raw in (('export-index.json', index_raw), ('part.json', part_raw)):
        require(member in files and files[member]['bytes'] == len(raw) and
                files[member]['sha256'] == digest(raw), 'MATERIALIZED_MANIFEST_DIFFERS')
    return {'number': number, 'artifact_id': aid, 'artifact_name': name, 'archive_bytes': size,
            'archive_sha256': checksum[7:], 'index': index, 'index_raw': index_raw, 'part': part,
            'part_raw': part_raw, 'files': files, 'directories': directories,
            'input_identities': {'artifact': api_identity, 'report': report_identity,
                                 'export_index': index_identity, 'part': part_identity}}


def verify_index(index, raw):
    require(set(index) == {'schema', 'binding', 'original_path_prefix', 'limits', 'file_count',
                          'total_bytes', 'part_count', 'parts', 'files'}, 'INDEX_SCHEMA_MISMATCH')
    require(type(index.get('schema')) is int and index['schema'] == 2 and
            index.get('original_path_prefix') == 'originals/', 'INDEX_SCHEMA_MISMATCH')
    binding = index.get('binding')
    require(isinstance(binding, dict) and binding == EXPECTED_BINDING and
            type(binding.get('run_id')) is int and type(binding.get('run_attempt')) is int,
            'INDEX_BINDING_MISMATCH')
    limits = index.get('limits')
    fixed = {'max_parts': MAX_PARTS, 'max_files': MAX_FILES, 'index_bytes': MAX_INDEX_BYTES,
             'part_manifest_bytes': MAX_PART_JSON}
    require(isinstance(limits, dict) and set(limits) == set(fixed) | {'part_payload_bytes'} and
            all(type(limits.get(key)) is int and limits[key] == value for key, value in fixed.items()) and
            integer(limits.get('part_payload_bytes'), 1, MAX_PART_BYTES), 'EXPORT_LIMIT_MISMATCH')
    require(len(raw) <= MAX_INDEX_BYTES and integer(index.get('part_count'), 1, MAX_PARTS) and
            integer(index.get('file_count'), 1, MAX_FILES) and integer(index.get('total_bytes')),
            'INDEX_COUNT_OR_SIZE_LIMIT')
    records, parts = index.get('files'), index.get('parts')
    require(isinstance(records, list) and len(records) == index['file_count'] and
            isinstance(parts, list) and len(parts) == index['part_count'], 'INDEX_COUNT_MISMATCH')
    by_part = {number: {} for number in range(1, index['part_count'] + 1)}
    names, used, current = [], 0, 1
    for row in records:
        require(isinstance(row, dict) and set(row) == {'path', 'bytes', 'sha256', 'part'}, 'INDEX_FILE_SCHEMA')
        name = safe_path(row['path'])
        require(integer(row['bytes'], 0, limits['part_payload_bytes']) and sha256_value(row['sha256']) and
                integer(row['part'], 1, index['part_count']), 'INDEX_FILE_IDENTITY')
        if used + row['bytes'] > limits['part_payload_bytes']:
            current += 1
            used = 0
        require(row['part'] == current, 'INDEX_PART_ASSIGNMENT_MISMATCH')
        used += row['bytes']
        names.append(name)
        require(name not in by_part[row['part']], 'DUPLICATE_ORIGINAL_PATH')
        by_part[row['part']][name] = row
    require(names == sorted(names) and len(names) == len(set(names)), 'DUPLICATE_OR_UNSORTED_ORIGINAL_PATH')
    originals = set(names)
    for name in names:
        components = name.split('/')
        require(not any('/'.join(components[:n]) in originals for n in range(1, len(components))),
                'ORIGINAL_PATH_COLLISION')
    require(sum(row['bytes'] for row in records) == index['total_bytes'], 'INDEX_TOTAL_BYTES_MISMATCH')
    require(current == index['part_count'], 'INDEX_EMPTY_OR_MISSING_PART')
    for number, part in enumerate(parts, 1):
        expected = {'part': number, 'directory': f'part-{number:02d}',
                    'file_count': len(by_part[number]),
                    'payload_bytes': sum(row['bytes'] for row in by_part[number].values())}
        require(isinstance(part, dict) and part == expected and expected['file_count'] > 0 and
                all(type(part.get(key)) is int for key in ('part', 'file_count', 'payload_bytes')),
                'INDEX_PART_COUNTS_MISMATCH')
    return by_part


def verify_parts(run_file, part_inputs):
    require(1 <= len(part_inputs) <= MAX_PARTS, 'PART_INPUT_COUNT_LIMIT')
    run_identity = verify_run(run_file)
    loaded = [load_part(paths) for paths in part_inputs]
    require(len({item['number'] for item in loaded}) == len(loaded) and
            len({item['artifact_id'] for item in loaded}) == len(loaded), 'DUPLICATE_PART_OR_ARTIFACT')
    reference = loaded[0]
    require(all(item['index_raw'] == reference['index_raw'] for item in loaded), 'INDEX_NOT_IDENTICAL')
    index, raw = reference['index'], reference['index_raw']
    by_part = verify_index(index, raw)
    require({item['number'] for item in loaded} == set(by_part), 'MISSING_OR_UNEXPECTED_PART')
    results = []
    for item in sorted(loaded, key=lambda value: value['number']):
        number, files = item['number'], item['files']
        declared = index['parts'][number - 1]
        expected_part = {'schema': 1, **declared, 'total_parts': index['part_count'],
                         'index_sha256': digest(raw), 'index_bytes': len(raw)}
        require(item['part'] == expected_part and
                all(type(item['part'].get(key)) is int for key in
                    ('schema', 'part', 'file_count', 'payload_bytes', 'total_parts', 'index_bytes')),
                'PART_MANIFEST_MISMATCH')
        expected_files = {'originals/' + name for name in by_part[number]} | {'export-index.json', 'part.json'}
        require(set(files) == expected_files, 'MISSING_OR_UNEXPECTED_MEMBER')
        ancestors = set()
        for name in expected_files:
            components = name.split('/')
            ancestors.update('/'.join(components[:n]) for n in range(1, len(components)))
        require(item['directories'].issubset(ancestors), 'UNEXPECTED_DIRECTORY_MEMBER')
        for name, row in by_part[number].items():
            actual = files['originals/' + name]
            require((actual['bytes'], actual['sha256']) == (row['bytes'], row['sha256']),
                    'ORIGINAL_MEMBER_CONTENT_MISMATCH')
        results.append({key: item[key] for key in ('number', 'artifact_id', 'artifact_name',
                                                  'archive_bytes', 'archive_sha256', 'input_identities')} |
                       {'original_file_count': declared['file_count'],
                        'original_payload_bytes': declared['payload_bytes']})
    return {'schema': 1, 'status': 'CREATIVE_PARTS_TRANSPORT_SNAPSHOT_COMPLETE',
            'binding': EXPECTED_BINDING, 'probe_source_tree': PROBE_TREE,
            'probe_branch': BRANCH, 'export_index_schema': 2, 'part_manifest_schema': 1,
            'transport_source_role': 'qa_probe_source', 'run_metadata': run_identity,
            'part_count': index['part_count'], 'original_file_count': index['file_count'],
            'original_payload_bytes': index['total_bytes'], 'identical_index_bytes': len(raw),
            'identical_index_sha256': digest(raw), 'parts': results,
            'published_export_contract_blob': EXPORT_BLOB,
            'expected_checked_memory_collector_sha256': COLLECTOR_SHA256,
            'product_acceptance': False, 'device_or_functional_or_visual_or_fps_acceptance': False,
            'earlier_full_zip_equality_claimed': False,
            'scope': 'Local consistency and complete declared parts snapshot only. Trust requires original API objects and authentic complete reports from the checked collector; no ZIP payload is reread and no external provenance is authenticated here.'}


class SafeParser(argparse.ArgumentParser):
    def error(self, message):
        raise Rejected('INVALID_ARGUMENTS')


def main(argv=None):
    try:
        parser = SafeParser(description=__doc__)
        parser.add_argument('--run', required=True, type=Path, help='Original current GitHub workflow-run JSON')
        parser.add_argument('--part', required=True, action='append', nargs=4,
                            metavar=('API_JSON', 'REPORT_JSON', 'INDEX_JSON', 'PART_JSON'))
        parser.add_argument('--output', type=Path, help='Optional new result file; never overwrites')
        args = parser.parse_args(argv)
        result = verify_parts(args.run, args.part)
        raw = (json.dumps(result, indent=2, ensure_ascii=False) + '\n').encode('utf-8')
        if args.output is not None:
            with args.output.open('xb') as stream:
                stream.write(raw)
        sys.stdout.buffer.write(raw)
        return 0
    except Rejected as error:
        result = {'schema': 1, 'status': 'CREATIVE_PARTS_REJECTED', 'code': error.code,
                  'product_acceptance': False}
    except (OSError, TypeError, KeyError, ValueError, OverflowError):
        result = {'schema': 1, 'status': 'CREATIVE_PARTS_REJECTED', 'code': 'INVALID_LOCAL_INPUT',
                  'product_acceptance': False}
    print(json.dumps(result))
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
