#!/usr/bin/env python3
"""Bind Build 2019 publication to actual APK, Android and reviewed graphics.

Every existing Android identity, learning, speech, Cards, update and signature
invariant is retained. Historical 2018 visual receipts never approve this pin.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

from release_pipeline_gates import (EXPECTED_CERT_SHA256, PACKAGE_ID,
                                    parse_pubspec_version, sha256_file)
from verify_legacy_release_pin import verify as verify_pin
from verify_nextgen_delivery import (BASELINE_SOURCE, BASELINE_NATIVE, COMPILED_CLASSES,
                                    read_json, require, verify_cards_front_faces)
from verify_kart_graphics_review import verify_visual_review
from verify_studio_delivery import (native_review_profile, verify_android_platforms,
                                    verify_visual_review as verify_native_visual_review)


def verify_proofs(source: str, native: str, version_name: str, digest: str, size: int,
                  proof: dict, verification: dict, measured: dict, update: dict,
                  tour: dict, surfaces: dict, host: dict, surface_evidence: Path) -> dict:
    require(bool(re.fullmatch(r'[a-f0-9]{40}', source)), 'Missing immutable Flutter source')
    require(version_name == '0.13.7' and bool(re.fullmatch(r'[a-f0-9]{40}', native)),
            'Wrong 2019 version name or immutable native identity')
    require(proof.get('flutter_source_commit') == source and proof.get('tracked_source_clean') is True,
            'APK provenance belongs to different or uncommitted Flutter source')
    for info in (proof, verification, measured):
        require(info.get('versionCode') == 2019 and info.get('versionName') == version_name,
                'Wrong Android delivery version')
        require(info.get('package') == PACKAGE_ID and
                info.get('signingCertificateSha256') == EXPECTED_CERT_SHA256,
                'Wrong installed-family package or test signing certificate')
        require(info.get('abis') == ['arm64-v8a'], 'Delivery must contain the actual ARM64 APK')
        require(info.get('sha256') == digest and info.get('bytes') == size,
                'Actual APK bytes differ from provenance or repeated verification')
        require(info.get('godot', {}).get('revision') == native, 'Wrong embedded native source')
        pck = proof.get('godot', {}).get('pck_sha256')
        require(bool(re.fullmatch(r'[a-f0-9]{64}', str(pck))) and
                info.get('godot', {}).get('pck_sha256') == pck,
                'Actual ARM64 PCK differs from provenance or repeated verification')
    require(update.get('status') == 'PASS' and tour.get('status') == 'PASS' and
            surfaces.get('status') == 'PASS', 'Actual Android acceptance is incomplete')
    baseline = update.get('baseline', {})
    require(update.get('candidate_source') == source and baseline.get('versionCode') == 2017 and
            baseline.get('flutter_source_commit') == BASELINE_SOURCE and
            baseline.get('godot', {}).get('revision') == BASELINE_NATIVE,
            'In-place upgrade did not use the real 2017 baseline and this candidate')
    candidate = update.get('candidate', {})
    require(candidate.get('flutter_source_commit') == source and candidate.get('tracked_source_clean') is True and
            candidate.get('versionCode') == 2019 and candidate.get('versionName') == version_name and
            candidate.get('package') == PACKAGE_ID and
            candidate.get('signingCertificateSha256') == EXPECTED_CERT_SHA256 and
            candidate.get('abis') == ['x86_64'] and candidate.get('godot', {}).get('revision') == native,
            'Android update tested another candidate')
    identities = [step for step in tour.get('steps', []) if step.get('step') == 'apk-identity']
    require(len(identities) == 1 and identities[0].get('ok') is True, 'Missing actual tour APK identity')
    for identity in (identities[0], surfaces.get('apk_identity', {})):
        require(identity.get('flutter_source_commit') == source and identity.get('godot_revision') == native and
                identity.get('versionCode') == 2019 and identity.get('versionName') == version_name and
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
    return {'package': PACKAGE_ID, 'versionName': version_name, 'versionCode': 2019,
            'flutterSourceCommit': source, 'godotSourceCommit': native,
            'signingCertificateSha256': EXPECTED_CERT_SHA256, 'apkSha256': digest, 'apkBytes': size,
            'androidTourApkSha256': candidate['sha256'],
            'cardsFrontFacePixels': card_pixels,
            'signingScope': 'Public Lumo test key; not Google Play signing',
            'voiceScope': 'Actual local playback callbacks in a -noaudio emulator; audible quality and lip synchronization not verified',
            'deviceScope': 'x86_64 Android emulator acceptance; physical Fold7/Android17/FPS not measured'}


def verify_android_acceptance(source: str, native: str, version_name: str, digest: str, size: int,
                              proof: dict, verification: dict, measured: dict, update: dict,
                              tour: dict, surfaces: dict, host: dict, surface_evidence: Path,
                              android17_root: Path) -> dict:
    # Keep the graphics verifier's independent PCK check on all three ARM64
    # records, then reuse the complete producer checks on both emulator datasets.
    args = (source, native, version_name, digest, size, proof, verification, measured,
            update, tour, surfaces, host, surface_evidence)
    facts = verify_proofs(*args)
    platforms = verify_android_platforms(*args, android17_root)
    facts['androidEmulatorAcceptance'] = platforms['androidEmulatorAcceptance']
    facts['deviceScope'] = platforms['deviceScope']
    return facts


def verify_visual_acceptance(root: Path, native: str, proofs: Path) -> dict:
    graphics = verify_visual_review(
        root, read_json(root / 'config/kart-graphics-2019-visual-review.json'), native,
        proofs / 'native-graphics')
    profile = native_review_profile('nextgen-2019')
    native_proofs = proofs / 'native-nextgen'
    complete_native = verify_native_visual_review(
        root, read_json(root / profile.receipt), native,
        read_json(native_proofs / 'artifact.json'), read_json(native_proofs / 'run.json'),
        read_json(native_proofs / 'jobs.json'), native_proofs / 'native-evidence.zip',
        native_profile='nextgen-2019')
    return {'visualReview': graphics, 'nativeVisualReview': complete_native}


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
    require(build == version_code == 2019 and version_name == '0.13.7',
            'This publisher only accepts reviewed Build 0.13.7+2019')
    require((dist / 'APP-VERSION.txt').read_text().strip() == 'version: 0.13.7+2019',
            'Packaged application version differs from current source')
    require(read_json(dist / 'GODOT-SOURCE.json') == json.loads(source_config), 'Packaged source pin differs')
    apk = dist / 'Lumo-Lernen-Neu.apk'
    facts = verify_android_acceptance(args.source_sha, native, version_name, sha256_file(apk), apk.stat().st_size,
                          read_json(dist / 'BUILD-PROVENANCE.json'), read_json(dist / 'APK-VERIFICATION.json'),
                          read_json(dist / 'PUBLISH-VERIFICATION.json'), read_json(proofs / 'update/update-result.json'),
                          read_json(proofs / 'tour/tour-result.json'),
                          read_json(proofs / 'tour/nextgen/native-surfaces-result.json'),
                          read_json(proofs / 'host/result.json'), proofs / 'tour/nextgen',
                          proofs / 'android17')
    facts.update(verify_visual_acceptance(root, native, proofs))
    (dist / 'RELEASE-FACTS.json').write_text(json.dumps(facts, indent=2) + '\n')
    (dist / 'Lumo-Lernen-Neu.apk.sha256').write_text(f"{facts['apkSha256']}  Lumo-Lernen-Neu.apk\n")
    print(json.dumps(facts, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
