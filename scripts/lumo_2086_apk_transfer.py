#!/usr/bin/env python3
"""Package one verified original APK into bounded transport parts; never publish."""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

from lumo_2082_reviewed_publish import (
    CERT, PACKAGE, REPOSITORY, REPOSITORY_ID, OWNER_ID,
    download_archive, github_json, source_document, verify_repository,
)
from lumo_team_b_reviewed_publish import decode, digest, require, same, save

APK = 'Lumo-Lernen-Test-0.15.3-2086.apk'
SOURCE = '83e169bfedd91f050080660b21ba63cd01518259'
NATIVE = '0c36dbaa2e778dc982550989159bf70efbf1d47c'
SOURCE_RUN = 45799647600
SOURCE_ATTEMPT = 1
SOURCE_JOB = 139841363614
ARTIFACT_ID = 15109688662
ARTIFACT_BYTES = 700249330
ARTIFACT_SHA256 = 'd8a05096545f07b25bd19c95d11e0324030c5eec484422ceac00389b00147e3c'
APK_BYTES = 690483979
APK_SHA256 = '2e3316f60452fb8324c4fd3e2a1c6db7430b0ebdc3557c518c5ea44b98ab6adc'
PCK_BYTES = 431630116
PCK_SHA256 = 'ba47a3c56c2a121013ed31510d09a0f33a607ecfc476780b4ef938803dad090d'
PART_BYTES = 256 * 1024 * 1024
PART_SIZES = (PART_BYTES, PART_BYTES, APK_BYTES - 2 * PART_BYTES)
BRANCH = 'qa/lumo-2086-apk-transfer-20261126'
WORKFLOW = '.github/workflows/lumo-2086-apk-transfer.yml'
SCRIPT = 'scripts/lumo_2086_apk_transfer.py'
ROOT = Path('apk-transfer')
BUILD_STEPS = (
    'Quellstand und Godot-Pin festhalten',
    'Native Sprache, Lerndialog und Datensicherung – JVM-Verträge',
    'Flutter – Analyse und vollständige Testsuite',
    'Godot – gepinnter Spielstand startet und besteht seine Kernprüfungen',
    'World – integrierte Missionen, Kart, Figuren und Spielstand',
    'Intelligence 2.0 – neue Strecken, Spiele und Welt (gepinnter Godot-Stand)',
    'Rivalen, Tunnel und Produktionsfahrzeuge in den reparierten Spielpfaden prüfen',
    'Fold-Steuerung, Streckendetails, Kartenrunde und Grafikwahl prüfen',
    'Eine signierte Flutter-Godot-APK bauen',
    'Paketname und Signaturzertifikat gegen die installierte 2082 prüfen',
    'APK und Belege als Artefakt sichern',
)


def transfer_context():
    expected = {
        'GITHUB_ACTIONS': 'true',
        'GITHUB_REPOSITORY': REPOSITORY,
        'GITHUB_REPOSITORY_ID': str(REPOSITORY_ID),
        'GITHUB_REPOSITORY_OWNER': 'Ullmann27',
        'GITHUB_REPOSITORY_OWNER_ID': str(OWNER_ID),
        'GITHUB_REF': 'refs/heads/' + BRANCH,
        'GITHUB_EVENT_NAME': 'push',
        'GITHUB_SERVER_URL': 'https://github.com',
        'GITHUB_API_URL': 'https://api.github.com',
        'GITHUB_JOB': 'transfer',
        'GITHUB_WORKFLOW_REF': REPOSITORY + '/' + WORKFLOW + '@refs/heads/' + BRANCH,
    }
    for key, value in expected.items():
        same(os.environ.get(key), value, 'Transfer context ' + key)
    sha = os.environ.get('GITHUB_SHA', '')
    require(re.fullmatch(r'[0-9a-f]{40}', sha), 'Invalid transfer source')
    same(os.environ.get('GITHUB_WORKFLOW_SHA'), sha, 'Transfer workflow source')
    same(subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
         sha, 'Checked out transfer source')
    same(subprocess.check_output(['git', 'rev-parse', 'HEAD^'], text=True).strip(),
         SOURCE, 'Transfer must be a direct child of the tested source')
    changes = subprocess.check_output(
        ['git', 'diff', '--name-status', 'HEAD^', 'HEAD'], text=True).splitlines()
    same(sorted(changes), sorted(['A\t' + WORKFLOW, 'A\t' + SCRIPT]),
         'Transfer changes only its own new workflow and script')
    result = {'commit': sha, 'branch': BRANCH, 'workflow': WORKFLOW}
    for name in ('GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT'):
        value = os.environ.get(name, '')
        require(re.fullmatch(r'[1-9][0-9]*', value), 'Invalid transfer run identity')
        result[name.lower()] = int(value)
    return result


def original_evidence(token):
    base = 'repos/' + REPOSITORY
    run = github_json(base + '/actions/runs/' + str(SOURCE_RUN), token)
    for key, value in {
        'id': SOURCE_RUN, 'run_attempt': SOURCE_ATTEMPT, 'head_sha': SOURCE,
        'head_branch': 'integration/lumo-final-release-20261126',
        'event': 'push', 'path': '.github/workflows/lumo-intelligence-2-0.yml',
    }.items():
        same(run.get(key), value, 'Original run ' + key)
    for name in ('repository', 'head_repository'):
        verify_repository(run[name])
    jobs = github_json(
        base + '/actions/runs/' + str(SOURCE_RUN) + '/attempts/1/jobs?per_page=100', token)
    same(jobs['total_count'], len(jobs['jobs']), 'Complete original attempt jobs')
    found = [job for job in jobs['jobs'] if job.get('id') == SOURCE_JOB]
    require(len(found) == 1, 'Original APK job missing')
    job = found[0]
    for key, value in {
        'id': SOURCE_JOB, 'run_id': SOURCE_RUN, 'head_sha': SOURCE,
        'name': 'Signierte Test-APK bauen',
        'status': 'completed', 'conclusion': 'success',
    }.items():
        same(job.get(key), value, 'Original APK job ' + key)
    for name in BUILD_STEPS:
        steps = [row for row in job.get('steps', []) if row.get('name') == name]
        require(len(steps) == 1 and steps[0].get('status') == 'completed'
                and steps[0].get('conclusion') == 'success', 'Missing passed build step')
    artifact = github_json(base + '/actions/artifacts/' + str(ARTIFACT_ID), token)
    for key, value in {
        'id': ARTIFACT_ID, 'name': 'LUMO-TEST-APK-' + str(SOURCE_RUN), 'expired': False,
        'size_in_bytes': ARTIFACT_BYTES, 'digest': 'sha256:' + ARTIFACT_SHA256,
    }.items():
        same(artifact.get(key), value, 'Original artifact ' + key)
    for key, value in {
        'id': SOURCE_RUN, 'head_sha': SOURCE,
        'head_branch': 'integration/lumo-final-release-20261126',
        'repository_id': REPOSITORY_ID, 'head_repository_id': REPOSITORY_ID,
    }.items():
        same(artifact['workflow_run'].get(key), value, 'Original artifact owner ' + key)
    same(decode(source_document('config/godot-source.json', SOURCE, token)),
         {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
          'revision': NATIVE, 'engine': '4.6.3'}, 'Exact source native pin')
    return {'run': run, 'job': job, 'artifact': artifact}


def bounded_json(archive, name):
    info = archive.getinfo(name)
    require(0 < info.file_size <= 1024 * 1024, 'Invalid metadata size')
    require(not info.flag_bits & 1, 'Encrypted metadata is not supported')
    return decode(archive.read(info))


def verify_metadata(archive):
    provenance = bounded_json(archive, 'release/BUILD-PROVENANCE.json')
    verified = bounded_json(archive, 'release/APK-VERIFICATION.json')
    split = bounded_json(archive, 'release/SPLIT-APK-IDENTITY.json')
    expected = {
        'package': PACKAGE, 'versionName': '0.15.3', 'versionCode': 2086,
        'abis': ['arm64-v8a'], 'bytes': APK_BYTES, 'sha256': APK_SHA256,
        'signingCertificateSha256': CERT, 'minSdk': 24, 'targetSdk': 36,
        'godot': {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                  'revision': NATIVE, 'engine': '4.6.3',
                  'pck_sha256': PCK_SHA256, 'bytes': PCK_BYTES},
    }
    for document in (provenance, verified):
        for key, value in expected.items():
            same(document.get(key), value, 'Original APK metadata ' + key)
    same(provenance.get('flutter_source_commit'), SOURCE, 'Original APK source')
    same(provenance.get('tracked_source_clean'), True, 'Original source cleanliness')
    same(split.get('flutter_source_commit'), SOURCE, 'Original split source')
    same(split.get('same_pck'), True, 'Original split PCK equality')
    for abi in ('arm64-v8a', 'x86_64'):
        item = split['packages'][abi]
        same(item.get('godot_pck_sha256'), PCK_SHA256, 'Split PCK digest')
        same(item.get('godot_pck_bytes'), PCK_BYTES, 'Split PCK bytes')
    return expected


def write_parts(stream, destination, sizes, expected_sha256):
    require(not destination.exists(), 'Transport destination must be new')
    destination.mkdir(parents=True, exist_ok=False)
    complete = hashlib.sha256()
    entries = []
    offset = 0
    for index, size in enumerate(sizes, start=1):
        require(type(size) is int and 0 < size <= PART_BYTES, 'Invalid transport part size')
        directory = destination / ('part-' + str(index).zfill(2))
        directory.mkdir()
        path = directory / (APK + '.part' + str(index).zfill(2))
        part_hash = hashlib.sha256()
        remaining = size
        with path.open('xb') as target:
            while remaining:
                block = stream.read(min(4 * 1024 * 1024, remaining))
                require(bool(block), 'Truncated original APK')
                require(len(block) <= remaining, 'Oversized original APK block')
                target.write(block)
                complete.update(block)
                part_hash.update(block)
                remaining -= len(block)
        same(path.stat().st_size, size, 'Written part bytes')
        same(digest(path), part_hash.hexdigest(), 'Written part SHA256')
        entries.append({'index': index, 'file': path.name, 'offset': offset,
                        'bytes': size, 'sha256': part_hash.hexdigest()})
        offset += size
    require(stream.read(1) == b'', 'Original APK contains unexpected trailing bytes')
    same(complete.hexdigest(), expected_sha256, 'Complete original APK SHA256')
    joined = hashlib.sha256()
    for entry in entries:
        path = destination / ('part-' + str(entry['index']).zfill(2)) / entry['file']
        with path.open('rb') as source:
            while block := source.read(4 * 1024 * 1024):
                joined.update(block)
    same(joined.hexdigest(), expected_sha256, 'Reassembled on-disk APK SHA256')
    return entries


def copy_original_documents(archive, first_part):
    entries = []
    directory = first_part / 'release'
    directory.mkdir()
    for name in ('BUILD-PROVENANCE.json', 'APK-VERIFICATION.json',
                 'SPLIT-APK-IDENTITY.json', 'SHA256SUMS.txt'):
        member = 'release/' + name
        info = archive.getinfo(member)
        require(0 < info.file_size <= 1024 * 1024 and not info.flag_bits & 1,
                'Invalid original metadata member')
        raw = archive.read(info)
        if name == 'SHA256SUMS.txt':
            same(raw.decode('utf-8').split(), [APK_SHA256, APK], 'Original APK sums')
        path = directory / name
        with path.open('xb') as output:
            output.write(raw)
        expected = hashlib.sha256(raw).hexdigest()
        same(digest(path), expected, 'Original metadata copy SHA256')
        entries.append({'part_index': 1, 'file': member, 'source_member': member,
                        'bytes': len(raw), 'sha256': expected})
    return entries


def main():
    context = transfer_context()
    token = os.environ.get('GH_TOKEN', '')
    require(bool(token), 'Read-only Actions token unavailable')
    evidence = original_evidence(token)
    require(not ROOT.exists(), 'Refusing to reuse transfer output')
    archive_path = ROOT / 'original.zip'
    download = download_archive(ARTIFACT_ID, ARTIFACT_BYTES, ARTIFACT_SHA256,
                                archive_path, token)
    with zipfile.ZipFile(archive_path) as archive:
        names = archive.namelist()
        require(len(names) == len(set(names)), 'Duplicate original archive member')
        metadata = verify_metadata(archive)
        info = archive.getinfo('release/' + APK)
        same(info.file_size, APK_BYTES, 'Original APK ZIP member bytes')
        require(not info.is_dir() and not info.flag_bits & 1, 'Invalid original APK member')
        with archive.open(info) as stream:
            parts = write_parts(stream, ROOT / 'parts', PART_SIZES, APK_SHA256)
        documents = copy_original_documents(archive, ROOT / 'parts/part-01')
    same(len(parts), 3, 'Exactly three fixed transport parts')
    same(sum(item['bytes'] for item in parts), APK_BYTES, 'Complete transport byte count')
    manifest = {
        'schema': 1, 'status': 'TRANSPORT_VERIFIED_NOT_RELEASE_APPROVAL',
        'repository': REPOSITORY, 'repository_id': REPOSITORY_ID, 'owner_id': OWNER_ID,
        'source_commit': SOURCE, 'native_commit': NATIVE,
        'source_run': SOURCE_RUN, 'source_attempt': SOURCE_ATTEMPT, 'source_job': SOURCE_JOB,
        'original_artifact': download, 'original_job_status': 'success',
        'source_run_status_at_transfer': evidence['run'].get('status'),
        'source_run_conclusion_at_transfer': evidence['run'].get('conclusion'),
        'apk': {'file': APK, 'bytes': APK_BYTES, 'sha256': APK_SHA256},
        'pck_metadata': metadata['godot'],
        'scope': 'Original APK bytes only, no rebuild, no signing, no public release. '
                 'Android acceptance remains independent. Recipient verifies APK and PCK.',
        'transfer': context, 'parts': parts, 'original_documents': documents,
    }
    save(ROOT / 'MANIFEST.json', manifest)
    for part in parts:
        shutil.copyfile(ROOT / 'MANIFEST.json',
                        ROOT / 'parts' / ('part-' + str(part['index']).zfill(2)) / 'MANIFEST.json')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()

