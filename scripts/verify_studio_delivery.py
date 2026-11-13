#!/usr/bin/env python3
"""Bind Studio 2019 publication to its exact APK, Android and renderer evidence.

The historical 2018 verifier and receipts remain immutable. This verifier does
not approve images: it validates an explicitly recorded review against the
downloaded original artifact, including both independent capture source stamps.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
from io import BytesIO
import json
from pathlib import Path, PurePosixPath
import re
import stat
import struct
import zipfile

from release_pipeline_gates import (EXPECTED_CERT_SHA256, PACKAGE_ID,
                                    parse_pubspec_version, sha256_file)
from verify_legacy_release_pin import verify as verify_pin
from verify_nextgen_delivery import (BASELINE_NATIVE, BASELINE_SOURCE,
                                    CARDS_FACE_STAGES, COMPILED_CLASSES,
                                    read_json, require, verify_cards_front_faces)


VERSION_CODE = 2019
VERSION_NAME = '0.13.7'
NATIVE_ARTIFACT = 'lumo-studio-2019-native-evidence'
NATIVE_WORKFLOW = '.github/workflows/lumo-studio-2019.yml'
NATIVE_JOBS = frozenset({'gameplay', 'new-worlds', 'studio', 'learning-preview'})
REVIEW_MODULES = frozenset({'learning', 'jump', 'build', 'settlement', 'garage',
                            'cards', 'rhythm', 'puzzle', 'treasure'})
REVIEW_DIRECTORY = PurePosixPath('docs/evidence/studio-2019-reviewed')
REVIEW_RECEIPT = 'config/studio-2019-visual-review.json'
CAPTURE_SOURCES = ('nextgen-evidence/nextgen', 'studio-evidence')
# Pose-studio images are useful technical evidence, but cannot stand in for an
# actual production scene. The probe directory fixes the image's module.
CAPTURE_MODULES = {
    'nextgen-evidence/nextgen/captures/learning_world_capture': 'learning',
    'studio-evidence/captures/learning_sharing_capture': 'learning',
    'nextgen-evidence/nextgen/captures/jump_nextgen_capture': 'jump',
    'nextgen-evidence/nextgen/captures/build_nextgen_play_regression': 'build',
    'nextgen-evidence/nextgen/captures/build_settlement_play_regression': 'settlement',
    'nextgen-evidence/nextgen/captures/kart_nextgen_garage_regression': 'garage',
    'nextgen-evidence/nextgen/captures/cards_table_capture': 'cards',
    'nextgen-evidence/nextgen/captures/rhythm_tour_play_regression': 'rhythm',
    'studio-evidence/captures/puzzle_rotation_regression': 'puzzle',
    'studio-evidence/captures/treasure_exploration_regression': 'treasure',
}


def verify_native_acceptance(native: str, artifact: dict, workflow: dict, jobs: dict) -> None:
    require(bool(re.fullmatch(r'[a-f0-9]{40}', str(native))), 'Invalid reviewed native SHA')
    require(artifact.get('name') == NATIVE_ARTIFACT and artifact.get('expired') is False,
            'Current Studio native visual evidence is missing or expired')
    require(type(artifact.get('id')) is int and artifact['id'] > 0, 'Invalid native artifact identity')
    run_id = workflow.get('id')
    require(type(run_id) is int and run_id > 0 and
            artifact.get('workflow_run', {}).get('id') == run_id and
            artifact['workflow_run'].get('head_sha') == native,
            'Native artifact was rendered from another source or workflow run')
    require(workflow.get('path') == NATIVE_WORKFLOW and workflow.get('head_sha') == native and
            workflow.get('status') == 'completed' and workflow.get('conclusion') == 'success',
            'Current Studio native workflow did not succeed at the exact pin')
    actual_jobs = jobs.get('jobs')
    require(isinstance(actual_jobs, list) and all(isinstance(job, dict) for job in actual_jobs),
            'Missing native acceptance job metadata')
    for name in sorted(NATIVE_JOBS):
        matching = [job for job in actual_jobs if job.get('name') == name]
        require(len(matching) == 1, 'Missing or ambiguous full native acceptance job: ' + name)
        job = matching[0]
        require(job.get('run_id') == run_id and job.get('head_sha') == native and
                job.get('status') == 'completed' and job.get('conclusion') == 'success',
                'Native acceptance job did not succeed at the exact pin: ' + name)


def archive_member(zipped: zipfile.ZipFile, name: str) -> bytes:
    matching = [entry for entry in zipped.infolist() if entry.filename == name]
    require(len(matching) == 1, 'Missing or duplicate original native archive member: ' + name)
    entry = matching[0]
    require(not entry.is_dir() and not stat.S_ISLNK(entry.external_attr >> 16),
            'Native archive evidence must be an original regular file: ' + name)
    try:
        return zipped.read(entry)
    except (OSError, RuntimeError, zipfile.BadZipFile) as error:
        raise ValueError('Cannot read original native archive member: ' + name) from error


def verify_archive_sources(zipped: zipfile.ZipFile, native: str) -> dict:
    sources = {}
    for prefix in CAPTURE_SOURCES:
        try:
            source = archive_member(zipped, prefix + '/source-sha.txt').decode('utf-8').strip()
            dirty = archive_member(zipped, prefix + '/source-dirty.txt').decode('utf-8').strip()
        except UnicodeDecodeError as error:
            raise ValueError('Invalid native capture source metadata: ' + prefix) from error
        require(source == native, 'Archive capture source differs from the current native pin: ' + prefix)
        require(not dirty, 'Native screenshots were captured from modified tracked source: ' + prefix)
        sources[prefix] = source
    return sources


def capture_module(entry: str) -> str:
    require(isinstance(entry, str) and '\\' not in entry, 'Invalid original artifact image path')
    path = PurePosixPath(entry)
    require(not path.is_absolute() and '..' not in path.parts and str(path) == entry and
            bool(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*\.png', path.name)),
            'Only original current production-scene PNGs may be reviewed')
    module = CAPTURE_MODULES.get(str(path.parent))
    require(module in REVIEW_MODULES, 'Unknown production capture; a pose studio is not a product module')
    return module


def png_dimensions(data: bytes) -> list[int]:
    require(len(data) > 32 and data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR',
            'Selected image is not an original PNG')
    width, height = struct.unpack('>II', data[16:24])
    require(width >= 320 and height >= 320, 'Reviewed PNG is too small for production review')
    # Header-shaped or truncated files must not satisfy a screenshot gate. The
    # publisher already installs Pillow for the unchanged Android Cards check.
    from PIL import Image
    try:
        with Image.open(BytesIO(data)) as image:
            require(image.format == 'PNG' and image.size == (width, height), 'Invalid PNG dimensions')
            image.verify()
        with Image.open(BytesIO(data)) as image:
            image.load()
    except (OSError, SyntaxError, ValueError, Image.DecompressionBombError) as error:
        raise ValueError('Reviewed original PNG is corrupt or incomplete') from error
    return [width, height]


def reviewed_relative_path(digest: str, module: str, entry: str) -> str:
    require(bool(re.fullmatch(r'[a-f0-9]{64}', str(digest))), 'Invalid reviewed image SHA-256')
    require(capture_module(entry) == module, 'Reviewed module differs from its actual production capture')
    return str(REVIEW_DIRECTORY / f'{digest}-{module}-{PurePosixPath(entry).name}')


def reviewed_file(root: Path, relative: str) -> Path:
    parts = PurePosixPath(relative).parts
    require(parts[:3] == REVIEW_DIRECTORY.parts and len(parts) == 4 and '\\' not in relative,
            'Reviewed image must be a content-addressed committed Studio PNG')
    path = root
    for component in parts:
        path = path / component
        require(not path.is_symlink(), 'Reviewed PNG path must not contain symlinks')
    return path


def verify_visual_review(root: Path, receipt: dict, native: str,
                         artifact: dict, workflow: dict, jobs: dict, archive: Path) -> dict:
    require(receipt.get('schema') == 1 and receipt.get('status') == 'approved',
            'The final Studio visual review is not approved')
    require(receipt.get('versionCode') == VERSION_CODE and receipt.get('native_revision') == native,
            'Visual review belongs to another native source or version')
    require(bool(str(receipt.get('reviewed_by') or '').strip()) and
            bool(str(receipt.get('notes') or '').strip()), 'Missing actual reviewer/findings')
    try:
        reviewed_at = datetime.fromisoformat(receipt.get('reviewed_at', '').replace('Z', '+00:00'))
    except (TypeError, ValueError, AttributeError) as error:
        raise ValueError('Missing dated visual review') from error
    require(reviewed_at.tzinfo is not None, 'Visual review date must include its time zone')
    verify_native_acceptance(native, artifact, workflow, jobs)
    require(artifact['id'] == receipt.get('native_artifact_id') and
            workflow['id'] == receipt.get('native_workflow_run_id'),
            'Visual artifact or workflow identity differs from the reviewed artifact')
    digest = receipt.get('native_artifact_sha256', '')
    require(bool(re.fullmatch(r'[a-f0-9]{64}', str(digest))) and
            artifact.get('digest') == 'sha256:' + digest, 'Reviewed artifact bytes differ')
    require(archive.is_file() and not archive.is_symlink() and sha256_file(archive) == digest,
            'Downloaded original native archive digest differs')
    images = receipt.get('images')
    require(isinstance(images, list) and bool(images), 'No reviewed original PNGs')
    modules, orientations, paths, hashes, entries = set(), set(), set(), set(), set()
    with zipfile.ZipFile(archive) as zipped:
        sources = verify_archive_sources(zipped, native)
        for entry in images:
            require(isinstance(entry, dict), 'Invalid reviewed image entry')
            module, original = entry.get('module'), entry.get('artifact_entry')
            image_digest = entry.get('sha256')
            relative = reviewed_relative_path(image_digest, module, original)
            require(entry.get('path') == relative, 'Reviewed PNG filename must contain its full SHA-256 and module')
            require(relative not in paths and original not in entries, 'Duplicate reviewed image path or archive entry')
            paths.add(relative)
            entries.add(original)
            path = reviewed_file(root, relative)
            require(path.is_file(), 'Reviewed PNG is not committed as a real file')
            data = path.read_bytes()
            require(hashlib.sha256(data).hexdigest() == image_digest and image_digest not in hashes,
                    'Reviewed image bytes changed or were reused across modules')
            require(data == archive_member(zipped, original), 'Reviewed PNG differs from the original current native artifact')
            dimensions = png_dimensions(data)
            require(dimensions == entry.get('dimensions'), 'Reviewed PNG dimensions differ')
            require(bool(str(entry.get('findings') or '').strip()), 'Missing actual visual findings')
            hashes.add(image_digest)
            modules.add(module)
            orientations.add('portrait' if dimensions[1] > dimensions[0] else 'landscape')
    require(modules == REVIEW_MODULES, 'Visual review must cover all nine changed production scenes')
    require(orientations == {'portrait', 'landscape'}, 'Phone and landscape visual evidence are required')
    return {'native_revision': native, 'native_workflow_run_id': workflow['id'],
            'native_artifact_id': artifact['id'], 'native_artifact_sha256': digest,
            'native_capture_sources': sources, 'native_acceptance_jobs': sorted(NATIVE_JOBS),
            'reviewed_by': receipt['reviewed_by'], 'reviewed_at': receipt['reviewed_at'],
            'images': len(images), 'modules': sorted(modules)}


def verify_proofs(source: str, native: str, version_name: str, digest: str, size: int,
                  proof: dict, verification: dict, measured: dict, update: dict,
                  tour: dict, surfaces: dict, host: dict, surface_evidence: Path) -> dict:
    require(version_name == VERSION_NAME, 'This publisher only accepts Studio 0.13.7+2019')
    require(bool(re.fullmatch(r'[a-f0-9]{40}', source)), 'Missing immutable Flutter source')
    require(proof.get('flutter_source_commit') == source and proof.get('tracked_source_clean') is True,
            'APK provenance belongs to different or uncommitted Flutter source')
    for info in (proof, verification, measured):
        require(info.get('versionCode') == VERSION_CODE and info.get('versionName') == version_name,
                'Wrong Android delivery version')
        require(info.get('package') == PACKAGE_ID and
                info.get('signingCertificateSha256') == EXPECTED_CERT_SHA256,
                'Wrong installed-family package or test signing certificate')
        require(info.get('abis') == ['arm64-v8a'], 'Delivery must contain the actual ARM64 APK')
        require(info.get('sha256') == digest and info.get('bytes') == size,
                'Actual APK bytes differ from provenance or repeated verification')
        require(info.get('godot', {}).get('revision') == native, 'Wrong embedded native source')
    require(update.get('status') == 'PASS' and tour.get('status') == 'PASS' and
            surfaces.get('status') == 'PASS', 'Actual Android acceptance is incomplete')
    baseline = update.get('baseline', {})
    require(update.get('candidate_source') == source and baseline.get('versionCode') == 2017 and
            baseline.get('flutter_source_commit') == BASELINE_SOURCE and
            baseline.get('godot', {}).get('revision') == BASELINE_NATIVE,
            'In-place upgrade did not use the real 2017 baseline and this candidate')
    candidate = update.get('candidate', {})
    require(candidate.get('flutter_source_commit') == source and candidate.get('tracked_source_clean') is True and
            candidate.get('versionCode') == VERSION_CODE and candidate.get('versionName') == version_name and
            candidate.get('package') == PACKAGE_ID and
            candidate.get('signingCertificateSha256') == EXPECTED_CERT_SHA256 and
            candidate.get('abis') == ['x86_64'] and candidate.get('godot', {}).get('revision') == native,
            'Android update tested another candidate')
    identities = [step for step in tour.get('steps', []) if step.get('step') == 'apk-identity']
    require(len(identities) == 1 and identities[0].get('ok') is True, 'Missing actual tour APK identity')
    for identity in (identities[0], surfaces.get('apk_identity', {})):
        require(identity.get('flutter_source_commit') == source and identity.get('godot_revision') == native and
                identity.get('versionCode') == VERSION_CODE and identity.get('versionName') == version_name and
                identity.get('signingCertificateSha256') == EXPECTED_CERT_SHA256,
                'Android surface or tour tested another source/version/signature')
        require(identity.get('apk_sha256') == tour.get('apk_sha256') == candidate.get('sha256'),
                'Tour, new surfaces and update tested different APK bytes')
        require(proof.get('godot', {}).get('pck_sha256') == candidate.get('godot', {}).get('pck_sha256') ==
                identity.get('godot_pck_sha256') and
                bool(re.fullmatch(r'[a-f0-9]{64}', str(identity.get('godot_pck_sha256', '')))),
                'The native PCK differs between emulator evidence and ARM64 delivery')
    require(update.get('offline') is True and all(item.get('fatal_crashes') == 0
            for item in (update, tour, surfaces)), 'Offline upgrade or crash acceptance failed')
    launches = [step for step in tour.get('steps', []) if step.get('step') == 'start-kart-race']
    require(len(launches) == 1 and launches[0].get('ok') is True, 'Actual Kart launch not proven')
    navigation = launches[0].get('spatial_menu_navigation', {})
    require(navigation.get('status') == 'PASS' and navigation.get('selected_mode') == 'cup' and
            [section.get('section') for section in navigation.get('sections', [])] == ['garage', 'driver'],
            'Actual spatial garage/driver/cup navigation not proven')
    learning, cards = surfaces.get('learning', {}), surfaces.get('cards', {})
    require(learning.get('moves', {}).get('complete') is True and
            learning['moves'].get('moved_objects') == 5 and learning.get('same_lesson_after_return') is True and
            learning.get('illustration_did_not_award_mastery') is True,
            'Actual learning object movement and unchanged learning state not proven')
    permission = surfaces.get('local_voice_permission', {})
    require(surfaces.get('offline') is True and permission.get('local_model_assent') is True and
            permission.get('voice_enabled') is True and permission.get('auto_read') is True and
            permission.get('unrelated_permissions_unchanged') is True,
            'Actual offline speech permission route was not verified')
    speech = learning.get('speech', {})
    initial_voice, result_voice = speech.get('initial', {}), speech.get('result', {})
    for observed in (initial_voice, result_voice):
        ids = observed.get('completed_utterance_ids')
        require(observed.get('profile') == 'lumo-free-supertonic-de-v1' and
                observed.get('preset') == 'F2' and isinstance(ids, list) and bool(ids) and
                all(type(value) is int and value > 0 for value in ids) and
                type(observed.get('native_process_pid')) is int and observed['native_process_pid'] > 0 and
                observed.get('audible_quality_verified') is False and observed.get('lip_sync_verified') is False,
                'Actual original local playback start/completion was not verified')
    require(initial_voice['native_process_pid'] == result_voice['native_process_pid'] and
            max(initial_voice['completed_utterance_ids']) < min(result_voice['completed_utterance_ids']) and
            speech.get('native_process_gone_on_return') is True,
            'Speech belongs to another native lesson or its process remained alive')
    for key in ('pause_saved_state_unchanged', 'reopened_same_round', 'new_mailbox_token'):
        require(cards.get(key) is True, 'Cards lifecycle/persistence gate failed: ' + key)
    for key in ('draw', 'draw_after_visible_idle'):
        move = cards.get(key, {})
        require(move.get('cards_conserved') == 112 and move.get('child_cards_added', 0) > 0,
                'Missing actual Cards draw/persistence proof: ' + key)
    require(cards['draw'].get('owner') == cards['draw_after_visible_idle'].get('owner') and
            cards['draw'].get('round_id') == cards['draw_after_visible_idle'].get('round_id') and
            cards.get('visible_idle_seconds', 0) >= 35, 'Cards authority did not survive visible idle')
    bindings = cards.get('android_authority_binding', [])
    require(len(bindings) == 2 and bindings[0] == bindings[1] and bindings[0].get('bound') is True and
            bindings[0].get('main_process_pid') != bindings[0].get('native_process_pid'),
            'Missing actual Android binding between native activity and Dart authority')
    require(host.get('status') == 'PASS' and host.get('flutter_source_commit') == source and
            COMPILED_CLASSES <= set(host.get('classes', {})), 'Current Android host bytecode not verified')
    card_pixels = verify_cards_front_faces(cards, surface_evidence)
    return {'package': PACKAGE_ID, 'versionName': version_name, 'versionCode': VERSION_CODE,
            'flutterSourceCommit': source, 'godotSourceCommit': native,
            'signingCertificateSha256': EXPECTED_CERT_SHA256, 'apkSha256': digest, 'apkBytes': size,
            'androidTourApkSha256': candidate['sha256'],
            'cardsFrontFacePixels': card_pixels,
            'signingScope': 'Public Lumo test key; not Google Play signing',
            'voiceScope': 'Actual local playback callbacks in a -noaudio emulator; audible quality and lip synchronization not verified',
            'deviceScope': 'x86_64 Android emulator acceptance; physical Fold7/Android17/FPS not measured'}


def verify_android_runtime(surfaces: dict, expected_api: int) -> dict:
    require(isinstance(surfaces, dict), 'Missing actual Android surface report')
    runtime = surfaces.get('android_runtime')
    require(isinstance(runtime, dict) and type(runtime.get('sdk')) is int and
            runtime['sdk'] == expected_api,
            f'Actual Android runtime must report API {expected_api}')
    for field in ('release', 'fingerprint', 'model'):
        require(isinstance(runtime.get(field), str) and bool(runtime[field].strip()),
                f'Missing actual Android API {expected_api} runtime {field}')
    if expected_api == 37:
        require(bool(re.fullmatch(r'17(?:\.[0-9]+)*', runtime['release'])),
                'API 37 acceptance requires actual Android release 17')
    return {field: runtime[field] for field in ('sdk', 'release', 'fingerprint', 'model')}


def verify_tour_android_runtime(tour: dict, runtime: dict) -> None:
    # The original tour writes the stripped getprop value as a JSON string.
    # Do not coerce other types or normalize evidence from a different device.
    require(isinstance(tour, dict) and isinstance(tour.get('android_sdk'), str) and
            tour['android_sdk'] == str(runtime['sdk']),
            f"Original Android tour must report API {runtime['sdk']} matching its surface runtime")


def verify_android_platforms(source: str, native: str, version_name: str, digest: str, size: int,
                             proof: dict, verification: dict, measured: dict, update: dict,
                             tour: dict, surfaces: dict, host: dict, surface_evidence: Path,
                             android17_root: Path) -> dict:
    """Require both original emulator datasets without altering any input proof.

    The same ARM64 delivery and exact x86_64 candidate/PCK must satisfy the full
    existing gates twice. The original 2017 update remains mandatory; an API 35
    tour or surface directory cannot substitute for the separate Android 17 run.
    """
    require(android17_root.is_dir() and not android17_root.is_symlink(),
            'Missing separate original Android 17 evidence directory')
    android17_evidence = android17_root / 'nextgen'
    require(android17_evidence.resolve() != surface_evidence.resolve(),
            'Android 17 evidence cannot reuse the API 35 surface directory')
    reports = []
    for relative in ('tour-result.json', 'nextgen/native-surfaces-result.json'):
        path = android17_root / relative
        require(path.is_file() and not path.is_symlink(),
                'Missing original Android 17 report: ' + relative)
        reports.append(read_json(path))
    android17_tour, android17_surfaces = reports
    runtime35 = verify_android_runtime(surfaces, 35)
    runtime37 = verify_android_runtime(android17_surfaces, 37)
    verify_tour_android_runtime(tour, runtime35)
    verify_tour_android_runtime(android17_tour, runtime37)
    facts = verify_proofs(source, native, version_name, digest, size, proof, verification, measured,
                          update, tour, surfaces, host, surface_evidence)
    android17 = verify_proofs(source, native, version_name, digest, size, proof, verification, measured,
                              update, android17_tour, android17_surfaces, host, android17_evidence)
    facts['androidEmulatorAcceptance'] = [
        {'status': 'PASS', 'android_runtime': runtime35,
         'androidTourApkSha256': facts['androidTourApkSha256'],
         'cardsFrontFacePixels': facts['cardsFrontFacePixels']},
        {'status': 'PASS', 'android_runtime': runtime37,
         'androidTourApkSha256': android17['androidTourApkSha256'],
         'cardsFrontFacePixels': android17['cardsFrontFacePixels']},
    ]
    facts['deviceScope'] = (
        'Android API 35 and API 37 (Android 17) x86_64 emulator acceptance; '
        'physical Samsung Galaxy Z Fold7 performance, FPS and temperature not measured'
    )
    return facts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--dist', type=Path, default=Path('dist'))
    parser.add_argument('--proofs', type=Path, default=Path('proofs'))
    parser.add_argument('--native-archive', type=Path,
                        help='Original downloaded ZIP, default: <proofs>/native-evidence.zip')
    args = parser.parse_args()
    root, dist, proofs = args.root, args.dist, args.proofs
    pubspec = (root / 'pubspec.yaml').read_text()
    source_config = (root / 'config/godot-source.json').read_text()
    version_name, version_code = parse_pubspec_version(pubspec)
    build, native = verify_pin(pubspec, source_config)
    require(build == version_code == VERSION_CODE and version_name == VERSION_NAME,
            'This publisher only accepts reviewed Studio 0.13.7+2019')
    require((dist / 'APP-VERSION.txt').read_text().strip() == f'version: {VERSION_NAME}+{VERSION_CODE}',
            'Packaged application version differs from current source')
    require(read_json(dist / 'GODOT-SOURCE.json') == json.loads(source_config), 'Packaged source pin differs')
    apk = dist / 'Lumo-Lernen-Neu.apk'
    facts = verify_android_platforms(args.source_sha, native, version_name, sha256_file(apk), apk.stat().st_size,
                          read_json(dist / 'BUILD-PROVENANCE.json'), read_json(dist / 'APK-VERIFICATION.json'),
                          read_json(dist / 'PUBLISH-VERIFICATION.json'), read_json(proofs / 'update/update-result.json'),
                          read_json(proofs / 'tour/tour-result.json'),
                          read_json(proofs / 'tour/nextgen/native-surfaces-result.json'),
                          read_json(proofs / 'host/result.json'), proofs / 'tour/nextgen',
                          proofs / 'android17')
    facts['visualReview'] = verify_visual_review(root, read_json(root / REVIEW_RECEIPT), native,
                                               read_json(proofs / 'native-artifact.json'),
                                               read_json(proofs / 'native-run.json'),
                                               read_json(proofs / 'native-jobs.json'),
                                               args.native_archive or proofs / 'native-evidence.zip')
    (dist / 'RELEASE-FACTS.json').write_text(json.dumps(facts, indent=2) + '\n')
    (dist / 'Lumo-Lernen-Neu.apk.sha256').write_text(f"{facts['apkSha256']}  Lumo-Lernen-Neu.apk\n")
    print(json.dumps(facts, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

