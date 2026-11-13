#!/usr/bin/env python3
"""Bind 2018 publication to actual APK, Android, update and visual evidence.

This verifier cannot approve a visual review. A reviewer must first inspect
the original rendered images and commit an explicit source-bound receipt.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import struct

from release_pipeline_gates import (EXPECTED_CERT_SHA256, PACKAGE_ID,
                                    parse_pubspec_version, sha256_file)
from verify_legacy_release_pin import verify as verify_pin


BASELINE_SOURCE = '47889f74a651b073965def70743417cf320b1eb9'
BASELINE_NATIVE = '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57'
REVIEW_MODULES = {'learning', 'jump', 'build', 'settlement', 'garage', 'cards', 'rhythm'}
COMPILED_CLASSES = {'MainActivity', 'LumoGameActivity', 'LumoHostPlugin', 'CardsTableBridge',
                    'CardsAuthorityService', 'LumoLearningSpeech', 'LumoOfflineSpeechBridge',
                    'LumoOfflineSpeechEngine'}


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise ValueError(reason)


def read_json(path: Path) -> dict:
    value = json.loads(path.read_text())
    require(isinstance(value, dict), f'Expected JSON object: {path}')
    return value


def verify_visual_review(root: Path, receipt: dict, native: str,
                         artifact: dict, workflow: dict, jobs: dict) -> dict:
    require(receipt.get('schema') == 1 and receipt.get('status') == 'approved',
            'The final visual review is not approved')
    require(receipt.get('versionCode') == 2018 and receipt.get('native_revision') == native,
            'Visual review belongs to another native source or version')
    require(bool(re.fullmatch(r'[a-f0-9]{40}', native)), 'Invalid reviewed native SHA')
    require(bool(str(receipt.get('reviewed_by') or '').strip()) and
            bool(str(receipt.get('notes') or '').strip()), 'Missing actual reviewer/findings')
    try:
        reviewed_at = datetime.fromisoformat(receipt.get('reviewed_at', '').replace('Z', '+00:00'))
    except (TypeError, ValueError, AttributeError) as error:
        raise ValueError('Missing dated visual review') from error
    require(reviewed_at.tzinfo is not None, 'Visual review date must include its time zone')
    require(artifact.get('id') == receipt.get('native_artifact_id') and
            type(artifact.get('id')) is int and artifact['id'] > 0,
            'Visual artifact identity differs from the reviewed artifact')
    require(artifact.get('name') == 'lumo-nextgen-2018-native-evidence' and
            artifact.get('expired') is False, 'Native visual evidence is missing or expired')
    digest = receipt.get('native_artifact_sha256', '')
    require(bool(re.fullmatch(r'[a-f0-9]{64}', str(digest))) and
            artifact.get('digest') == 'sha256:' + digest, 'Reviewed artifact bytes differ')
    run_id = receipt.get('native_workflow_run_id')
    require(type(run_id) is int and run_id > 0 and artifact.get('workflow_run', {}).get('id') == run_id and
            artifact['workflow_run'].get('head_sha') == native,
            'Native artifact was rendered from another source')
    require(workflow.get('id') == run_id and workflow.get('head_sha') == native and
            workflow.get('status') == 'completed' and workflow.get('conclusion') == 'success',
            'Reviewed native workflow did not finish successfully at the exact pin')
    actual_jobs = {job.get('name'): job for job in jobs.get('jobs', [])}
    for name in ('gameplay', 'new-worlds'):
        job = actual_jobs.get(name, {})
        require(job.get('run_id') == run_id and job.get('status') == 'completed' and
                job.get('conclusion') == 'success', 'Missing full native acceptance job: ' + name)
    images = receipt.get('images')
    require(isinstance(images, list) and bool(images), 'No reviewed original PNGs')
    modules, orientations, paths, hashes = set(), set(), set(), set()
    for entry in images:
        require(isinstance(entry, dict), 'Invalid reviewed image entry')
        relative = PurePosixPath(str(entry.get('path', '')))
        require(not relative.is_absolute() and '..' not in relative.parts and
                relative.parts[:3] == ('docs', 'evidence', 'nextgen-2018-reviewed') and
                relative.suffix == '.png', 'Reviewed image must be an original committed proof PNG')
        require(str(relative) not in paths, 'Duplicate reviewed image path')
        paths.add(str(relative))
        path = root.joinpath(*relative.parts)
        require(path.is_file() and not path.is_symlink(), 'Reviewed PNG is not committed as a real file')
        data = path.read_bytes()
        require(data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR' and len(data) > 32,
                'Reviewed image is not a PNG')
        width, height = struct.unpack('>II', data[16:24])
        require(width >= 320 and height >= 320 and [width, height] == entry.get('dimensions'),
                'Reviewed PNG dimensions differ')
        image_digest = hashlib.sha256(data).hexdigest()
        require(image_digest == entry.get('sha256') and image_digest not in hashes,
                'Reviewed image bytes changed or were reused across modules')
        hashes.add(image_digest)
        require(entry.get('module') in REVIEW_MODULES, 'Unknown reviewed production scene')
        require(bool(str(entry.get('artifact_entry') or '').endswith('.png')) and
                bool(str(entry.get('findings') or '').strip()), 'Missing original artifact path or visual findings')
        modules.add(entry['module'])
        orientations.add('portrait' if height > width else 'landscape')
    require(modules == REVIEW_MODULES, 'Visual review must cover every changed production scene')
    require(orientations == {'portrait', 'landscape'}, 'Phone and landscape visual evidence are required')
    return {'native_revision': native, 'native_workflow_run_id': run_id,
            'native_artifact_id': artifact['id'], 'native_artifact_sha256': digest,
            'reviewed_by': receipt['reviewed_by'], 'reviewed_at': receipt['reviewed_at'],
            'images': len(images), 'modules': sorted(modules)}


def verify_proofs(source: str, native: str, version_name: str, digest: str, size: int,
                  proof: dict, verification: dict, measured: dict, update: dict,
                  tour: dict, surfaces: dict, host: dict) -> dict:
    require(bool(re.fullmatch(r'[a-f0-9]{40}', source)), 'Missing immutable Flutter source')
    require(proof.get('flutter_source_commit') == source and proof.get('tracked_source_clean') is True,
            'APK provenance belongs to different or uncommitted Flutter source')
    for info in (proof, verification, measured):
        require(info.get('versionCode') == 2018 and info.get('versionName') == version_name,
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
            candidate.get('versionCode') == 2018 and candidate.get('versionName') == version_name and
            candidate.get('package') == PACKAGE_ID and
            candidate.get('signingCertificateSha256') == EXPECTED_CERT_SHA256 and
            candidate.get('abis') == ['x86_64'] and candidate.get('godot', {}).get('revision') == native,
            'Android update tested another candidate')
    identities = [step for step in tour.get('steps', []) if step.get('step') == 'apk-identity']
    require(len(identities) == 1 and identities[0].get('ok') is True, 'Missing actual tour APK identity')
    for identity in (identities[0], surfaces.get('apk_identity', {})):
        require(identity.get('flutter_source_commit') == source and identity.get('godot_revision') == native and
                identity.get('versionCode') == 2018 and identity.get('versionName') == version_name and
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
    return {'package': PACKAGE_ID, 'versionName': version_name, 'versionCode': 2018,
            'flutterSourceCommit': source, 'godotSourceCommit': native,
            'signingCertificateSha256': EXPECTED_CERT_SHA256, 'apkSha256': digest, 'apkBytes': size,
            'androidTourApkSha256': candidate['sha256'],
            'signingScope': 'Public Lumo test key; not Google Play signing',
            'deviceScope': 'x86_64 Android emulator acceptance; physical Fold7/Android17/FPS not measured'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--dist', type=Path, default=Path('dist'))
    parser.add_argument('--proofs', type=Path, default=Path('proofs'))
    args = parser.parse_args()
    root, dist, proofs = args.root, args.dist, args.proofs
    pubspec = (root / 'pubspec.yaml').read_text()
    source_config = (root / 'config/godot-source.json').read_text()
    version_name, version_code = parse_pubspec_version(pubspec)
    build, native = verify_pin(pubspec, source_config)
    require(build == version_code == 2018, 'This publisher only accepts reviewed Build 2018')
    require((dist / 'APP-VERSION.txt').read_text().strip() == f'version: {version_name}+2018',
            'Packaged application version differs from current source')
    require(read_json(dist / 'GODOT-SOURCE.json') == json.loads(source_config), 'Packaged source pin differs')
    apk = dist / 'Lumo-Lernen-Neu.apk'
    facts = verify_proofs(args.source_sha, native, version_name, sha256_file(apk), apk.stat().st_size,
                          read_json(dist / 'BUILD-PROVENANCE.json'), read_json(dist / 'APK-VERIFICATION.json'),
                          read_json(dist / 'PUBLISH-VERIFICATION.json'), read_json(proofs / 'update/update-result.json'),
                          read_json(proofs / 'tour/tour-result.json'),
                          read_json(proofs / 'tour/nextgen/native-surfaces-result.json'),
                          read_json(proofs / 'host/result.json'))
    facts['visualReview'] = verify_visual_review(root, read_json(root / 'config/nextgen-2018-visual-review.json'),
                                               native, read_json(proofs / 'native-artifact.json'),
                                               read_json(proofs / 'native-run.json'),
                                               read_json(proofs / 'native-jobs.json'))
    (dist / 'RELEASE-FACTS.json').write_text(json.dumps(facts, indent=2) + '\n')
    (dist / 'Lumo-Lernen-Neu.apk.sha256').write_text(f"{facts['apkSha256']}  Lumo-Lernen-Neu.apk\n")
    print(json.dumps(facts, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
