#!/usr/bin/env python3
"""Bind a diagnostic rerun to the unchanged Studio e3d APK, not to new app code."""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile


ROOT = Path(__file__).resolve().parents[1]


@dataclass(frozen=True)
class Candidate:
    repository: str = 'Ullmann27/lumo-lernen'
    run: int = 43461547945
    build_job: int = 132009667976
    artifact: int = 14061222588
    artifact_name: str = 'lumo-studio-2019-candidate'
    artifact_bytes: int = 647427173
    artifact_sha256: str = '1f7290285cc20c2739005de2221b9bdd3573989c73aa6520f79a89551e1256e5'
    source: str = 'e3d161cb2f79b732ac2dbafc2764b151247f018b'
    native: str = '76980a941fa05d047574d8cc386d3249d93ffca3'
    apk_bytes: int = 325277610
    apk_sha256: str = 'd2ffac6c1749284ae3c7e6439a6775f086bdcaec308595ae58b988dddf99bf93'
    pck_bytes: int = 66217416
    pck_sha256: str = 'a5bd0c24692b97acad1ce48522f5f34aa56643009af341a70c5aaaa01b71dfe3'
    package: str = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
    certificate: str = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'


EXPECTED = Candidate()


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def read_json(path: Path) -> dict:
    value = json.loads(path.read_text(encoding='utf-8'))
    require(isinstance(value, dict), f'Expected an object in {path}')
    return value


def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify_original_metadata(artifact: dict, run: dict, job: dict,
                             expected: Candidate = EXPECTED) -> None:
    require(artifact.get('id') == expected.artifact and
            artifact.get('name') == expected.artifact_name and
            artifact.get('size_in_bytes') == expected.artifact_bytes and
            artifact.get('digest') == 'sha256:' + expected.artifact_sha256 and
            artifact.get('expired') is False,
            'Original candidate artifact identity differs')
    origin = artifact.get('workflow_run', {})
    require(origin.get('id') == expected.run and origin.get('head_sha') == expected.source,
            'Artifact belongs to a different original source or run')
    require(run.get('id') == expected.run and run.get('head_sha') == expected.source and
            run.get('repository', {}).get('full_name') == expected.repository and
            run.get('path') == '.github/workflows/lumo-studio-2019.yml',
            'Original Studio workflow source differs')
    # The complete old run may fail its later Android gates. Only its real build
    # must be successful; this diagnostic exists to investigate those later gates.
    require(job.get('id') == expected.build_job and job.get('run_id') == expected.run and
            job.get('head_sha') == expected.source and job.get('name') == 'verify-and-build' and
            job.get('status') == 'completed' and job.get('conclusion') == 'success',
            'Original build job did not succeed on the exact APK source')
    for name in ('Build unified real Android APK',
                 'Verify APK archive and collect reproducible source hashes',
                 'Upload exact candidate (no release or synthetic screenshots)'):
        matches = [step for step in job.get('steps', []) if step.get('name') == name]
        require(len(matches) == 1 and matches[0].get('conclusion') == 'success' and
                matches[0].get('status') == 'completed',
                f'Original build lacks successful step: {name}')


def verify_candidate(dist: Path, expected: Candidate = EXPECTED) -> dict:
    apk = dist / 'x86_64/Lumo-Lernen-Neu.apk'
    proof = read_json(dist / 'x86_64/BUILD-PROVENANCE.json')
    measured = digest(apk)
    require(apk.stat().st_size == expected.apk_bytes and measured == expected.apk_sha256,
            'Actual x86 APK bytes differ from the original e3d build')
    fields = {
        'flutter_source_commit': expected.source, 'tracked_source_clean': True,
        'package': expected.package, 'versionCode': 2019, 'versionName': '0.13.7',
        'abis': ['x86_64'], 'bytes': expected.apk_bytes, 'sha256': measured,
        'signingCertificateSha256': expected.certificate,
    }
    require(all(type(proof.get(key)) is type(value) and proof.get(key) == value
                for key, value in fields.items()), 'Original APK provenance differs')
    native = proof.get('godot', {})
    require(native.get('revision') == expected.native and native.get('engine') == '4.6.3' and
            native.get('pck_sha256') == expected.pck_sha256 and
            native.get('bytes') == expected.pck_bytes,
            'Original APK PCK provenance differs')
    sums = []
    for line in (dist / 'ANDROID-TOUR-SHA256SUMS.txt').read_text().splitlines():
        if line.strip():
            checksum, name = line.split(maxsplit=1)
            sums.append((checksum, name.strip().lstrip('*')))
    require(sums == [(measured, 'dist/x86_64/Lumo-Lernen-Neu.apk')],
            'Original tour checksum file differs')
    with zipfile.ZipFile(apk) as archive:
        for name in ('assets/lumo_game.pck', 'assets/lumo_game_source.json'):
            require(archive.namelist().count(name) == 1, f'Missing or duplicated {name}')
        pack = archive.read('assets/lumo_game.pck')
        embedded = json.loads(archive.read('assets/lumo_game_source.json'))
    require(len(pack) == expected.pck_bytes and
            hashlib.sha256(pack).hexdigest() == expected.pck_sha256,
            'Actual embedded PCK bytes differ')
    require(len(pack) >= 20 and struct.unpack('<4s4I', pack[:20])[:1] == (b'GDPC',),
            'Actual embedded pack is not a Godot PCK')
    require(embedded == native, 'Embedded source JSON differs from original provenance')
    return {'apk_source_commit': expected.source, 'native_source_commit': expected.native,
            'apk_bytes': expected.apk_bytes, 'apk_sha256': measured,
            'pck_bytes': len(pack), 'pck_sha256': expected.pck_sha256,
            'versionCode': 2019, 'versionName': '0.13.7', 'package': expected.package,
            'signature_from_original_verified_provenance': expected.certificate,
            'scope': 'Exact original APK/PCK byte identity; no new APK build or new signing claim.'}


def source_checkout(path: Path, revision: str) -> dict:
    require(bool(re.fullmatch(r'[0-9a-f]{40}', revision)), 'Expected a full source commit')
    git = ['git', '--no-replace-objects', '-C', str(path)]
    head = subprocess.check_output(git + ['rev-parse', 'HEAD'], text=True).strip()
    require(head == revision, 'Source checkout differs from its declared commit')
    dirty = subprocess.check_output(git + ['status', '--porcelain', '--untracked-files=no'], text=True)
    require(not dirty, 'Tracked source changed in the diagnostic checkout')
    return {'revision': head, 'tree': subprocess.check_output(
        git + ['rev-parse', 'HEAD^{tree}'], text=True).strip(), 'tracked_source_clean': True}


def verify_runtime_reports(tour: dict, surfaces: dict, api: int,
                           expected: Candidate = EXPECTED) -> dict:
    from verify_studio_delivery import verify_android_runtime, verify_tour_android_runtime

    require(tour.get('status') == 'PASS' and tour.get('apk_sha256') == expected.apk_sha256,
            'The complete original tour did not pass on the unchanged APK')
    require(surfaces.get('status') == 'PASS', 'Studio learning/Cards surface probe did not pass')
    identities = [step for step in tour.get('steps', []) if step.get('step') == 'apk-identity']
    require(len(identities) == 1 and identities[0].get('ok') is True,
            'Original tour has no successful exact APK identity')
    for identity in (identities[0], surfaces.get('apk_identity', {})):
        require(identity.get('apk_sha256') == expected.apk_sha256 and
                identity.get('flutter_source_commit') == expected.source and
                identity.get('godot_revision') == expected.native and
                identity.get('godot_pck_sha256') == expected.pck_sha256 and
                identity.get('versionCode') == 2019 and identity.get('versionName') == '0.13.7' and
                identity.get('signingCertificateSha256') == expected.certificate and
                identity.get('checks') and all(value is True for value in identity['checks'].values()),
                'Runtime identity differs from the exact original APK/PCK')
    runtime = verify_android_runtime(surfaces, api)
    verify_tour_android_runtime(tour, runtime)
    return runtime


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--phase', choices=('before', 'after'), required=True)
    parser.add_argument('--dist', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--apk-source-checkout', required=True, type=Path)
    parser.add_argument('--probe-source', required=True)
    parser.add_argument('--expected-api', required=True, type=int, choices=(35, 37))
    args = parser.parse_args()
    out = args.out.resolve()
    metadata = out / 'recheck'
    metadata.mkdir(parents=True, exist_ok=True)
    report = {'status': 'RUNNING', 'phase': args.phase, 'diagnostic_only': True,
              'build_or_publish_performed': False, 'physical_fold7_performance_measured': False}
    try:
        verify_original_metadata(read_json(metadata / 'original-artifact.json'),
                                 read_json(metadata / 'original-run.json'),
                                 read_json(metadata / 'original-build-job.json'))
        report['probe_source'] = source_checkout(ROOT, args.probe_source)
        report['apk_source'] = source_checkout(args.apk_source_checkout, EXPECTED.source)
        report['original_apk'] = verify_candidate(args.dist)
        report['requested_api'] = args.expected_api
        report['emulator_action_package_suffix'] = '37.0' if args.expected_api == 37 else '35'
        report['execution_boundary'] = (
            'Absolute probe paths from probe_source execute with the immutable APK source checkout '
            'as cwd. Original tour identity guards remain unchanged and read its real git HEAD/config.')
        paths = ('.github/probes/creative_android_probe.py',
                 '.github/probes/modernization_android_tour.py',
                 '.github/probes/lumo_studio_surfaces_android_probe.py',
                 'scripts/verify_studio_delivery.py', 'scripts/verify_android_recheck_identity.py',
                 'scripts/run_android_recheck_tour.sh', '.github/workflows/lumo-android-recheck-2019.yml')
        report['probe_file_sha256'] = {name: digest(ROOT / name) for name in paths}
        for name in ('pubspec.yaml', 'config/godot-source.json'):
            require((ROOT / name).read_bytes() == (args.apk_source_checkout / name).read_bytes(),
                    'Probe metadata changed the frozen APK version/native pin')
        if args.phase == 'after':
            before = read_json(metadata / 'before.json')
            for key in ('probe_source', 'apk_source', 'original_apk', 'requested_api', 'probe_file_sha256'):
                require(before.get(key) == report[key], 'Identity changed during Android execution: ' + key)
            require(before.get('status') == 'PASS', 'Pre-emulator byte/source gate did not pass')
            report['android_runtime'] = verify_runtime_reports(
                read_json(out / 'tour-result.json'), read_json(out / 'nextgen/native-surfaces-result.json'),
                args.expected_api)
        report['status'] = 'PASS'
    except Exception as error:
        report.update(status='FAIL', error=f'{type(error).__name__}: {error}')
    (metadata / (args.phase + '.json')).write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2), flush=True)
    return 0 if report['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
