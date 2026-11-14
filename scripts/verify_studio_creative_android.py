#!/usr/bin/env python3
"""Require the current build's additional real-input Android evidence.

This checks technical input/save/media contracts. It does not turn a pending
human Jump-video review into visual approval or a measured game frame rate.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PROBE = ROOT / '.github/probes/studio_creative_android_probe.py'
SPEC = importlib.util.spec_from_file_location('studio_creative_proof_parser', PROBE)
creative = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(creative)


def read(path: Path):
    creative.require(path.is_file() and not path.is_symlink(), 'Missing original evidence: ' + str(path))
    return json.loads(path.read_text())


def evidence_file(root: Path, name: str, digest: str) -> Path:
    creative.require(isinstance(name, str) and Path(name).name == name and name not in ('', '.', '..'),
                     'Evidence must name an original file inside the creative artifact')
    path = root / name
    creative.require(path.is_file() and not path.is_symlink() and path.stat().st_size > 0,
                     'Missing original creative media: ' + name)
    creative.require(isinstance(digest, str) and re.fullmatch(r'[a-f0-9]{64}', digest)
                     and creative.sha(path) == digest, 'Creative media bytes changed: ' + name)
    return path


def verify(root: Path, expected: dict, main_tour: dict, probe_sha256: str, *, studio_version: int = 2019) -> dict:
    binding = creative.verify_candidate_metadata(*[
        read(root / 'metadata' / name) for name in ('run.json', 'artifacts.json', 'jobs.json')], expected, studio_version=studio_version)
    creative.require(read(root / 'candidate-artifact-binding.json') == binding,
                     'Creative preflight metadata differs from the current upload')
    tour = root / 'tour'
    report = read(tour / 'creative-result.json')
    creative.require(report.get('status') == 'RECORDED_REVIEW_REQUIRED',
                     'Additional creative Android input/save contracts have not passed')
    creative.require(report.get('host_source') == report.get('probe_source') == expected['host_source']
                     and report.get('native_source') == expected['native_source']
                     and report.get('build_run') == expected['build_run']
                     and report.get('probe_sha256') == probe_sha256
                     and report.get('candidate_binding') == binding,
                     'Creative evidence is from another source, probe, build or artifact')
    identities = [x for x in main_tour.get('steps', []) if x.get('step') == 'apk-identity']
    creative.require(main_tour.get('status') == 'PASS' and len(identities) == 1
                     and identities[0].get('ok') is True, 'Missing current main-tour APK identity')
    identity = report.get('apk_identity', {})
    keys = ('apk_sha256', 'flutter_source_commit', 'godot_revision', 'godot_pck_sha256',
            'versionName', 'versionCode', 'signingCertificateSha256')
    creative.require(all(identity.get(key) is not None and identity[key] == identities[0].get(key)
                         for key in keys)
                     and identity.get('apk_sha256') == main_tour.get('apk_sha256')
                     and identity.get('flutter_source_commit') == expected['host_source']
                     and identity.get('godot_revision') == expected['native_source'],
                     'Creative and main tours tested different APK/PCK/source/version/signature')
    checks = identity.get('checks', {})
    required = ('sha256_matches_provenance', 'sha256_matches_build_sums',
                'flutter_source_is_this_commit', 'tracked_source_clean',
                'godot_revision_is_pinned', 'signing_certificate',
                'version_matches_pubspec', 'x86_64_native_code')
    creative.require(all(checks.get(key) is True for key in required),
                     'Original APK identity checks are incomplete')
    pack = report.get('direct_apk_pck_read', {})
    creative.require(pack.get('sha256') == identity.get('godot_pck_sha256')
                     and type(pack.get('bytes')) is int and pack['bytes'] > 0,
                     'Direct embedded PCK measurement is missing')
    runtime = report.get('runtime', {})
    creative.require(runtime.get('sdk') == '35' and runtime.get('release') == '15'
                     and all(isinstance(runtime.get(key), str) and runtime[key].strip()
                             for key in ('model', 'fingerprint')), 'Actual API35 runtime is missing')
    creative.require(report.get('offline') is True and type(report.get('fatal_crashes')) is int
                     and report['fatal_crashes'] == 0 and read(tour / 'native-engine-errors.json') == [],
                     'Offline or crash-free creative execution was not established')
    games = report.get('games', {})
    creative.require(set(games) == {'jump', 'build', 'puzzle', 'treasure'},
                     'All four additional native games must be reached')
    for name in ('build', 'puzzle', 'treasure'):
        creative.require(games[name].get('status') == 'PASS' and games[name].get('durable_resume') is True,
                         'Actual creative game/resume contract failed: ' + name)
    creative.require(games['build'].get('undo_exact_pieces') is True
                     and games['build'].get('redo_exact_pieces') is True
                     and isinstance(games['build'].get('added_piece'), dict)
                     and games['build']['added_piece'].get('part') == 'sand',
                     'Actual build addition/undo/redo is missing')
    creative.require(games['puzzle'].get('menu_count_touches') == 4
                     and games['puzzle'].get('menu_mode_touches') == 3
                     and isinstance(games['puzzle'].get('actual_rotation'), dict),
                     'Actual puzzle menu and rotation are missing')
    creative.require(games['treasure'].get('first_clue') == 'tree'
                     and games['treasure'].get('visible_inventory') == 'Blattschlüssel'
                     and len(games['treasure'].get('actual_saved_position_series', [])) >= 2,
                     'Actual treasure movement/interaction/inventory is missing')
    jump = games['jump']
    creative.require(jump.get('status') == 'INPUTS_RECORDED_SAVE_RESUMED'
                     and jump.get('fully_decoded') is True and jump.get('checkpoint_resume') is True
                     and jump.get('visual_motion_review') == 'REQUIRED',
                     'Jump input/recording/resume is incomplete or visual approval is misrepresented')
    actions = jump.get('separate_pointer_actions', [])
    creative.require([x.get('type') for x in actions] ==
                     ['separate-stick', 'separate-stick', 'short-jump', 'held-jump']
                     and [x.get('duration_ms') for x in actions] == [350, 350, 80, 650],
                     'Original separate-pointer Jump inputs are incomplete')
    video = evidence_file(tour, jump.get('video'), jump.get('sha256'))
    samples = jump.get('samples', [])
    creative.require(len(samples) == 4, 'All four original Jump action frames are required')
    for sample in samples:
        evidence_file(tour, sample.get('file'), sample.get('sha256'))
    decode = tour / 'jump-full-decode.log'
    creative.require(decode.is_file() and not decode.is_symlink() and decode.read_bytes() == b'',
                     'Successful full Jump video decoding is missing')
    return {'status': 'FUNCTIONAL_CONTRACTS_PASSED_VISUAL_REVIEW_PENDING',
            'host_source': expected['host_source'], 'native_source': expected['native_source'],
            'build_run': expected['build_run'], 'artifact_id': binding['artifact']['id'],
            'artifact_digest': binding['artifact']['digest'], 'apk_sha256': identity['apk_sha256'],
            'pck_sha256': pack['sha256'], 'runtime': runtime,
            'game_contracts': {name: value['status'] for name, value in games.items()},
            'jump_video': {'file': video.name, 'sha256': creative.sha(video)},
            'visual_motion_review': 'REQUIRED',
            'limits': ['No numeric jump physics or simultaneous multitouch acceptance',
                       'No Android17 or physical Fold7 performance/FPS/thermal claim']}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--studio-version', type=int, choices=(2019, 2020), default=2019)
    parser.add_argument('--build-run', required=True, type=int)
    parser.add_argument('--artifact-id', required=True, type=int)
    parser.add_argument('--artifact-digest', required=True)
    parser.add_argument('--creative', required=True, type=Path)
    parser.add_argument('--main-tour', required=True, type=Path)
    parser.add_argument('--out', required=True, type=Path)
    args = parser.parse_args()
    expected = {'host_source': args.source_sha,
                'native_source': read(ROOT / 'config/godot-source.json')['revision'],
                'build_run': args.build_run, 'artifact_id': args.artifact_id,
                'artifact_digest': 'sha256:' + args.artifact_digest.removeprefix('sha256:')}
    facts = verify(args.creative, expected, read(args.main_tour), creative.sha(PROBE), studio_version=args.studio_version)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(facts, indent=2) + '\n')
    print(json.dumps(facts, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
