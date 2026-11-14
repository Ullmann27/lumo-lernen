#!/usr/bin/env python3
"""Recheck current Studio2020 C4 originals before publication.

No emulator, rule engine, APK installation or test process is started here.
Current GitHub metadata binds the uploaded originals to the current jobs;
recorded states, readbacks, pixels, touches, saves and leases are re-evaluated.
The separate real Dart/Godot gate remains mandatory and is never replaced by
the renderer-only Visualfixture or by a successful older Android candidate.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import importlib.util
import json
from pathlib import Path
import re
import subprocess
import unicodedata
import xml.etree.ElementTree as ET

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
WORKFLOW = '.github/workflows/lumo-studio-2020.yml'
JOBS = {'build': 'verify-and-build', 'compile': 'android-host-compile',
        '35': 'Android API 35 live application tour',
        '37': 'Android API 37 live application tour'}
ARTIFACTS = {'candidate': 'lumo-studio-2020-candidate',
             '35': 'lumo-studio-2020-android-tour',
             '37': 'lumo-studio-2020-android-17-tour',
             'runtime': 'lumo-candidate-pinned-native-gameplay'}
IDENTITY_CHECKS = ('sha256_matches_provenance', 'sha256_matches_build_sums',
                   'flutter_source_is_this_commit', 'tracked_source_clean',
                   'godot_revision_is_pinned', 'signing_certificate',
                   'version_matches_pubspec', 'x86_64_native_code')
TOUR_STEPS = {'apk-identity', 'launch', 'onboarding', 'navigate-start',
              'navigate-lernen', 'atelier-roundtrip', 'navigate-spiele',
              'open-kart', 'start-kart-race', 'race-running', 'race-hud',
              'race-drive', 'pause-menu', 'return-from-kart',
              'learning-state-after-kart', 'lernen-usable-after-kart',
              'profile-after-kart', 'restart-keeps-learning-state',
              'display-fold_offen', 'display-fold_aussen', 'display-quer'}
STAGES = ('initial-board', 'child-and-bot', 'child-and-bot', 'native-pause',
          'resumed-board', 'after-home', 'before-exit', 'reopened-board')


def module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    value = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(value)
    return value


probe = module('c4_android_delivery_contract', ROOT / '.github/probes/lumo_connect_four_android_probe.py')
creative = module('c4_hub_delivery_contract', ROOT / '.github/probes/studio_creative_android_probe.py')
readiness = module('c4_return_pixel_contract', ROOT / '.github/probes/flutter_surface_readiness.py')
learning = module('c4_learning_preservation_contract', ROOT / 'tools/android_qa/kart_tour_evidence.py')
runner = module('c4_real_two_process_contract', ROOT / 'scripts/run_connect_four_runtime.py')
require = probe.require


def read(path: Path):
    require(path.is_file() and not path.is_symlink(), 'Missing original file: ' + str(path))
    require(path.stat().st_size <= 32 * 1024 * 1024, 'Oversized JSON original: ' + str(path))
    return probe.parse_json(path.read_text())


def member(folder: Path, name: str) -> Path:
    require(type(name) is str and Path(name).name == name and name not in ('', '.', '..'),
            'Evidence path must be one original artifact filename')
    path = folder / name
    require(path.is_file() and not path.is_symlink() and path.stat().st_size > 0,
            'Missing/nonregular original evidence: ' + name)
    return path


def digest(value, length=64):
    require(type(value) is str and re.fullmatch('[a-f0-9]{' + str(length) + '}', value),
            'Full immutable hash required')
    return value


def utc(value):
    require(type(value) is str and value.endswith('Z'), 'Original UTC timestamp required')
    return datetime.fromisoformat(value.removesuffix('Z') + '+00:00')


def verify_metadata(folder: Path, expected: dict) -> dict:
    run = read(folder / 'run.json')
    jobs = read(folder / 'jobs.json')['jobs']
    artifacts = read(folder / 'artifacts.json')['artifacts']
    require(run.get('id') == expected['build_run'] and run.get('head_sha') == expected['host']
            and run.get('path') == WORKFLOW
            and run.get('repository', {}).get('full_name') == 'Ullmann27/lumo-lernen',
            'Wrong current GitHub run/source/workflow/repository')
    attempt = probe.integer(run.get('run_attempt'), 'current run attempt', 1)
    selected_jobs = {}
    for key, name in JOBS.items():
        found = [j for j in jobs if j.get('name') == name]
        require(len(found) == 1, 'Missing/ambiguous current job: ' + name)
        job = found[0]
        require(job.get('run_id') == run['id'] and job.get('head_sha') == expected['host']
                and job.get('run_attempt') == attempt and job.get('status') == 'completed'
                and job.get('conclusion') == 'success', 'Current required job has not succeeded: ' + name)
        require(utc(job['started_at']) <= utc(job['completed_at']), 'Invalid actual job chronology')
        selected_jobs[key] = job
    selected = {}
    for key, name in ARTIFACTS.items():
        found = [a for a in artifacts if a.get('name') == name]
        require(len(found) == 1, 'Missing/ambiguous current artifact: ' + name)
        artifact = found[0]
        require(artifact.get('expired') is False and type(artifact.get('id')) is int
                and artifact['id'] > 0 and type(artifact.get('size_in_bytes')) is int
                and artifact['size_in_bytes'] > 0, 'Missing/expired/empty artifact: ' + name)
        require(re.fullmatch(r'sha256:[a-f0-9]{64}', artifact.get('digest', '')) is not None,
                'Original GitHub artifact digest absent')
        origin = artifact.get('workflow_run', {})
        require(origin.get('id') == run['id'] and origin.get('head_sha') == expected['host'],
                'Artifact is from another actual run/source')
        job = selected_jobs[key if key in ('35', '37') else 'build']
        require(utc(job['started_at']) <= utc(artifact['created_at']) <= utc(job['completed_at']),
                'Artifact was not created by the current successful attempt')
        selected[key] = artifact
    require(selected['candidate']['id'] == expected['artifact_id']
            and selected['candidate']['digest'] == 'sha256:' + expected['artifact_digest'],
            'Candidate artifact is not the original build selection')
    return {'run': run['id'], 'attempt': attempt,
            'jobs': {key: value['id'] for key, value in selected_jobs.items()},
            'artifacts': {key: {field: value[field] for field in ('id', 'name', 'digest', 'size_in_bytes')}
                          for key, value in selected.items()}}


def git(root: Path, *arguments: str) -> bytes:
    return subprocess.check_output(['git', '--no-replace-objects', '-C', str(root), *arguments])


def current_sources(host: Path, native: Path, expected: dict) -> dict:
    hashes = {}
    for root, head in ((host, expected['host']), (native, expected['native'])):
        require(git(root, 'rev-parse', 'HEAD').decode().strip() == head, 'Publisher checkout source differs')
        require(not git(root, 'status', '--porcelain', '--untracked-files=no').strip(), 'Publisher tracked source is dirty')
    require(read(host / 'config/godot-source.json').get('revision') == expected['native'], 'Wrong actual Native pin')
    require(re.search(r'^version:\s*0\.13\.8\+2020\s*$', (host / 'pubspec.yaml').read_text(), re.M),
            'This publisher contract requires exact Studio2020')
    paths = [(host, name, name) for name in probe.SOURCE_FILES]
    paths += [(native, name, 'native/' + name) for name in
              ('scripts/games/connect_four/connect_four_table.gd', 'scenes/games/connect_four_table.tscn')]
    for root, name, key in paths:
        path = root / name
        require(path.is_file() and not path.is_symlink(), 'Missing executed source: ' + key)
        require(path.read_bytes() == git(root, 'show', 'HEAD:' + name), 'Executed source differs from commit: ' + key)
        hashes[key] = probe.sha(path)
    return hashes


def check_identity(identity: dict, expected: dict):
    required = {'apk_sha256': expected['apk'], 'godot_pck_sha256': expected['pck'],
                'flutter_source_commit': expected['host'], 'godot_revision': expected['native'],
                'versionName': '0.13.8', 'versionCode': 2020, 'signingCertificateSha256': CERT}
    require(all(identity.get(k) == v and type(identity.get(k)) is type(v) for k, v in required.items()),
            'C4 APK/PCK/source/version/certificate differs')
    require(set(identity.get('checks', {})) == set(IDENTITY_CHECKS)
            and all(identity['checks'][key] is True for key in IDENTITY_CHECKS),
            'Original APK/signature/ABI/source guards are incomplete')


def check_header(report: dict, before: dict, after: dict, main_tour: dict,
                 expected: dict, source_hashes: dict, api: int):
    require(report.get('status') == 'PASS' and report.get('source_binding') == before == after,
            'Current C4 report/before/after bindings failed')
    require(before.get('host') == expected['host'] and before.get('native') == expected['native']
            and before.get('actual_installed_apk_sha256') == expected['apk']
            and before.get('source_hashes') == source_hashes, 'Current installed APK or executed probe sources differ')
    check_identity(before.get('apk', {}), expected)
    steps = main_tour.get('steps', [])
    require(main_tour.get('status') == 'PASS' and main_tour.get('apk_sha256') == expected['apk']
            and main_tour.get('android_sdk') in (api, str(api))
            and len(steps) == 21 and {s.get('step') for s in steps} == TOUR_STEPS
            and all(s.get('ok') is True for s in steps), 'Current main tour is incomplete or from another APK/API')
    check_identity(next(s for s in steps if s['step'] == 'apk-identity'), expected)
    runtime = report.get('android_runtime', {})
    require(type(runtime.get('sdk')) is int and runtime['sdk'] == api
            and runtime.get('release') == {35: '15', 37: '17'}[api]
            and all(type(runtime.get(k)) is str and runtime[k].strip() for k in ('fingerprint', 'model')),
            'Actual requested Android runtime absent')
    require(type(report.get('fatal_crashes')) is int and report['fatal_crashes'] == 0
            and report.get('physical_fold7_performance_measured') is False
            and report.get('new_mailbox_token') is True
            and report.get('saved_round_unchanged_after_pause_home_exit_reopen') is True,
            'Crash-free lifecycle/save scope is missing or overstated')


def readbacks(folder: Path) -> dict:
    result = {}
    serials = set()
    for path in sorted(folder.glob('*-read.json')):
        match = re.fullmatch(r'(\d{4})-([a-z-]+)-read\.json', path.name)
        if not match:
            continue
        meta = read(path)
        name = path.name.removesuffix('-read.json')
        raw = folder / (name + '.raw')
        stderr = folder / (name + '.stderr')
        require(raw.is_file() and not raw.is_symlink() and stderr.is_file() and not stderr.is_symlink(),
                'Original bounded ADB read bytes missing')
        require(probe.allowed_read(meta.get('path', '')) and re.fullmatch(r'emulator-\d+', meta.get('serial', '')),
                'Readback is not from the explicit C4 emulator/path')
        require(meta.get('sha256') == probe.sha(raw) and meta.get('bytes') == raw.stat().st_size,
                'Original ADB read bytes differ from measurement')
        require(probe.number(meta['finished_unix_seconds'], 'read finish') >=
                probe.number(meta['started_unix_seconds'], 'read start'), 'Invalid ADB read chronology')
        serials.add(meta['serial'])
        value = None
        if meta.get('returncode') == 0 and 0 < raw.stat().st_size <= 131072:
            try:
                value = probe.parse_json(raw.read_text())
            except (RuntimeError, ValueError, UnicodeError):
                pass  # A transient rejected partial read is retained, never accepted as a state.
        result[name] = {'number': int(match[1]), 'label': match[2], 'metadata': meta,
                        'value': value, 'sha256': probe.sha(raw)}
    require(result and len(serials) == 1, 'Missing or mixed-device original readbacks')
    return result


def raw_value(raws: dict, name: str, path: str):
    require(name in raws and raws[name]['value'] is not None
            and raws[name]['metadata']['returncode'] == 0
            and raws[name]['metadata']['path'] == path, 'Missing successful original read: ' + name)
    return raws[name]['value']


def png(folder: Path, record: dict):
    path = member(folder, record['file'])
    require(probe.sha(path) == digest(record['sha256']), 'Original PNG hash changed: ' + path.name)
    with Image.open(path) as image:
        require(image.format == 'PNG' and min(image.size) >= 360, 'Complete Android PNG required')
        image.load()
        require(list(image.size) == [record['width'], record['height']], 'Original PNG dimensions changed')
        return image.convert('RGB')


def observations(folder: Path, raws: dict, owner: str, density: float) -> list:
    accepted = []
    for path in sorted(folder.glob('*-observation.json')):
        match = re.fullmatch(r'(\d{4})-([a-z-]+)-observation\.json', path.name)
        require(match is not None and match[2] in STAGES, 'Unknown accepted C4 observation')
        item = read(path); stage = match[2]; shot = item['capture']
        shot_match = re.fullmatch(r'(\d{4})-' + stage + r'\.png', shot['file'])
        require(shot_match and int(match[1]) == int(shot_match[1]) + 3, 'Original capture/readback ordering changed')
        n = int(shot_match[1]); token = item['state']['token']
        prior = raw_value(raws, f'{n-2:04d}-layout-before', probe.LAYOUT)
        later = raw_value(raws, f'{n+2:04d}-layout-after', probe.LAYOUT)
        state_before = raw_value(raws, f'{n-1:04d}-state', probe.SESSION + token + '/state.json')
        state_after = raw_value(raws, f'{n+1:04d}-state', probe.SESSION + token + '/state.json')
        require(item['layout'] == prior == later and item['state'] == state_before == state_after,
                'Original state/layout changed during accepted PNG')
        require(item['layout_sha256'] == raws[f'{n-2:04d}-layout-before']['sha256']
                == raws[f'{n+2:04d}-layout-after']['sha256'], 'Layout raw byte hashes differ')
        probe.check_state(item['state'], owner)
        with png(folder, shot) as image:
            actual = probe.check_layout(prior, state_before, image.size, density, prior['pid'])
            require(actual == item['geometry'], 'Fresh independent geometry disagrees with recorded result')
            visible = stage != 'native-pause' and not (stage == 'after-home' and state_before['paused'])
            pixels = probe.check_pixels(image, prior, actual) if visible else []
            require(pixels == item['disc_pixels'], 'Fresh original disc pixels disagree')
        accepted.append(dict(item, stage=stage, number=int(match[1])))
    require(tuple(x['stage'] for x in accepted) == STAGES, 'All eight original C4 observations are required')
    return accepted


def check_moves_and_states(items: list, raws: dict, report: dict):
    states = [item['state'] for item in items]
    first = states[0]
    require(first['columns'] == [] and first['twoPlayers'] is False and first['canDrop'] is True,
            'Actual initial solo round must be empty and playable')
    require(report.get('same_round_id') == first['roundId'], 'Reported saved round differs')
    require(all(s['roundId'] == first['roundId'] and s['owner'] == first['owner']
                and s['twoPlayers'] is False for s in states), 'Round/child/mode changed')
    require(all(s['token'] == first['token'] for s in states[:-1])
            and states[-1]['token'] != first['token'], 'Reopen did not use a new mailbox')
    require(len({x['layout']['pid'] for x in items[:-1]}) == 1, 'Native process changed before actual reopen')
    moves = []
    for index, column in ((1, 3), (2, 2)):
        candidates = [r['value'] for r in raws.values() if r['label'] == 'drop-request'
                      and items[index-1]['number'] < r['number'] < items[index]['number']
                      and r['value'] is not None and r['metadata']['path'] == probe.SESSION + first['token'] + '/request.json']
        validated = []
        for request in candidates:
            try:
                validated.append(probe.check_drop(states[index-1], request, states[index], column))
            except RuntimeError:
                pass
        require(validated and all(value == validated[0] for value in validated), 'Actual positively acknowledged child/bot request missing')
        moves.append(validated[0])
    require(moves == report.get('actual_moves'), 'Summary differs from actual original moves')
    require(states[3]['paused'] is True and states[3]['canDrop'] is False,
            'Native pause was not observed')
    require(all(not states[i]['paused'] and states[i]['canDrop'] for i in (4, 6, 7)),
            'Actual resume/before-exit/reopen is not playable')
    require(all(s['columns'] == states[2]['columns'] and s['recordRevision'] == states[2]['recordRevision']
                for s in states[3:]), 'Pause/Home/exit/reopen altered the persisted history')
    return moves


def check_inputs(folder: Path, items: list, raws: dict, density: float):
    events = read(folder / 'input-events.json')
    require(type(events) is list and events and events[0].get('kind') == 'actual_hub_touch', 'Actual C4 hub input absent')
    hub = events[0]
    with png(folder, hub['capture']) as image:
        xml = member(folder, Path(hub['capture']['file']).with_suffix('.xml').name)
        nodes = list(ET.fromstring(xml.read_text()).iter('node'))
        selected = creative.hub_choice(nodes, 'Vier gewinnt', image.size, 48 * density)
    require(selected is not None and selected == hub['target'], 'Actual C4 hub target differs from original live XML')
    bounds = selected['bounds']
    require(hub['point'] == [round((bounds[0]+bounds[2])/2), round((bounds[1]+bounds[3])/2)], 'Hub tap was not at the observed target')
    ids = [e.get('target', {}).get('id') for e in events[1:]]
    required_ids = ['column_3', 'column_2', 'pause', 'resume']
    if items[5]['state']['paused']:
        required_ids.append('resume')
    required_ids += ['back', 'back']
    require(ids == required_ids, 'Actual C4 input sequence is incomplete')
    previous = -1.0
    for event in events[1:]:
        require(event.get('kind') == 'actual_adb_touch', 'Non-ADB/native input in C4 evidence')
        found = [x for x in items if x['capture'] == event.get('capture') and x['layout_sha256'] == event.get('layout_sha256')]
        require(len(found) == 1, 'Input is not bound to one stable original PNG/layout')
        item = found[0]
        target = probe.button_target(item['layout'], event['target']['id'], density)
        require(target == event['target'] and event['point'] == [round(v) for v in target['point']], 'Input target/bounds/48dp changed')
        clock = probe.number(event.get('time_monotonic'), 'input clock')
        require(clock > previous, 'Input events are not chronologically distinct')
        previous = clock
        require(any(r['label'] == 'touch-layout' and r['sha256'] == event['layout_sha256']
                    and r['number'] > item['number'] and r['value'] == item['layout'] for r in raws.values()),
                'Fresh layout read immediately before actual touch absent')
    return len(events)


def prefs(path: Path):
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 4 * 1024 * 1024,
            'Missing/bounded original SharedPreferences')
    root = ET.fromstring(path.read_text())
    require(root.tag == 'map', 'Original SharedPreferences map required')
    values = {}
    for node in root:
        require(node.get('name') not in values, 'Ambiguous saved preference key')
        values[node.get('name')] = node.text
    return values


def check_saves(folder: Path, items: list, report: dict, before: dict):
    student = before.get('flutter.lumo_learning_local_student_id_v1')
    require(type(student) is str and re.fullmatch(r'local-[a-f0-9]{32}', student), 'Actual existing local child missing')
    owner = hashlib.sha256(student.encode()).hexdigest()
    require(items[0]['state']['owner'] == owner, 'C4 belongs to another local child')
    key = 'flutter.lumo.connect_four.round.v1.' + owner
    saved = []
    for path in sorted(folder.glob('*-saved-preferences.xml')):
        require(re.fullmatch(r'\d{4}-saved-preferences\.xml', path.name), 'Unbound saved-round observation')
        original = prefs(path)
        require(key in original, 'Profile-bound C4 save missing')
        value = probe.parse_json(original[key])
        matching = []
        for item in items:
            try:
                probe.check_saved(value, item['state']); matching.append(item)
            except RuntimeError:
                pass
        require(matching, 'Saved round differs from all actually observed states')
        saved.append(value)
    require(saved, 'No original native save observations')
    for index in (0, 1, 2, 7):
        require(any(value['columns'] == items[index]['state']['columns'] and
                    value['revision'] == items[index]['state']['recordRevision'] for value in saved),
                'Initial/moved/reopened saved round missing')
    terminal = [v for v in saved if len(v['columns']) == 4]
    require(len(terminal) >= 7 and all(v == terminal[0] for v in terminal), 'Pause/Home/reopen exact saved round observations incomplete')
    after = prefs(folder / 'after-c4-preferences.xml')
    require(after.get(key) is not None and probe.parse_json(after[key]) == terminal[0], 'Final durable C4 round changed')
    preserved = learning.learning_preserved(before, after)
    require(preserved == report.get('learning_preservation'), 'Original learning preservation differs from report')
    closed = read(folder / 'closed-session-read.json')
    require(closed.get('path') == probe.SESSION + items[0]['state']['token']
            and type(closed.get('returncode')) is int and closed['returncode'] == 1
            and closed.get('stdout') == '' and closed.get('stderr') == '', 'Old native mailbox was not actually removed')
    return {'owner': owner, 'original_preference_reads': len(saved), 'learning': preserved,
            'saved_round_sha256': hashlib.sha256(json.dumps(terminal[0], sort_keys=True).encode()).hexdigest()}


def check_leases(report: dict, raws: dict, token: str):
    leases = report.get('leases')
    require(type(leases) is list and len(leases) == 3, 'Three actual active Activity leases required')
    inactive = report.get('home_inactive_lease', {})
    samples = [(x, True) for x in leases] + [(inactive, False)]
    for sample, active in samples:
        value = sample.get('lifecycle', {})
        before = probe.integer(sample.get('device_before_ms'), 'device lease before', 1, 2**63-1)
        after = probe.integer(sample.get('device_after_ms'), 'device lease after', 1, 2**63-1)
        stamp = probe.integer(value.get('stamp'), 'actual lease stamp', 1, 2**63-1)
        probe.integer(value.get('pauseEpoch'), 'pause epoch')
        require(before <= after and value.get('active') is active and stamp <= after+500
                and (not active or before-stamp < 2500), 'Stale/wrong real Activity lease')
        require(any(r['value'] == value and r['label'] == 'lifecycle'
                    and r['metadata']['path'] == probe.SESSION+token+'/lifecycle.json' for r in raws.values()),
                'Lease has no original readback for the current session')
    require(leases[-1]['lifecycle']['pauseEpoch'] >= inactive['lifecycle']['pauseEpoch'] > leases[0]['lifecycle']['pauseEpoch'],
            'Home did not advance the actual pause epoch')
    require(leases[-1]['device_before_ms'] >= inactive['device_after_ms'] + 3000,
            'Actual Home interval is shorter than the original three-second gate')
    return {'active_samples': 3, 'home_inactive': True, 'pause_epoch': inactive['lifecycle']['pauseEpoch']}


def check_return(folder: Path, tag: str) -> dict:
    report = read(folder / (tag + '-return-pixels.json'))
    frames = report.get('frames', [])
    require(report.get('status') == 'PASS' and report.get('expected_captions') == ['Spiel pausiert']
            and report.get('consecutive_confirmed_frames') == 2 and 2 <= len(frames) <= 12
            and 0 < probe.number(report.get('elapsed_seconds'), 'return seconds') <= 30,
            'Original Flutter return deadline/consecutive-frame gate not passed')
    require([v.get('status') for v in frames[-2:]] == ['CONFIRMED_FLUTTER_PIXELS']*2,
            'Return did not end in two consecutive visible Flutter frames')
    positive = []
    for index, frame in enumerate(frames, 1):
        if 'source' not in frame:
            require(frame.get('status') == 'REJECTED', 'Missing original return frame')
            continue
        require(frame['source'] == f'{tag}-return-candidate-{index}.png', 'Return capture is not original chronological frame')
        path = member(folder, frame['source'])
        require(probe.sha(path) == digest(frame['source_sha256']), 'Return frame bytes changed')
        if frame.get('status') != 'CONFIRMED_FLUTTER_PIXELS':
            continue
        measured = readiness.inspect_flutter_frame(path)
        require(measured == frame.get('render_readiness') and measured['visually_ready'] is True,
                'Original positive Flutter pixels are not ready')
        captions = frame.get('captions', [])
        require(len(captions) == 1 and captions[0].get('expected') == 'Spiel pausiert', 'Required actual pause caption absent')
        line = captions[0].get('ocr', {})
        text = line.get('text')
        require(type(text) is str, 'Actual OCR caption text absent')
        plain = unicodedata.normalize('NFKD', text).encode('ascii', 'ignore').decode()
        require(re.sub('[^a-z0-9]', '', plain.lower()) == 'spielpausiert',
                'Different OCR caption cannot prove return')
        bounds = probe.vector(line.get('bounds'), 4, 'OCR bounds')
        require(0 <= bounds[0] < bounds[2] <= measured['width'] and 0 <= bounds[1] < bounds[3] <= measured['height'],
                'OCR caption not inside the actual frame')
        raw_ocr = read(folder / (path.stem + '-caption-0-ocr.json'))
        require(type(raw_ocr) is list and line in raw_ocr, 'Caption not present in original OCR lines')
        positive.append(frame['source_sha256'])
    require(len(positive) >= 2 and report.get('source') == tag+'.png'
            and report.get('source_sha256') == frames[-1]['source_sha256']
            and probe.sha(member(folder, tag+'.png')) == frames[-1]['source_sha256'],
            'Final Flutter original is not the last accepted frame')
    return {'consecutive_frames': 2, 'elapsed_seconds': report['elapsed_seconds'],
            'accepted_image_sha256': report['source_sha256']}


def verify_android(folder: Path, main_tour: dict, expected: dict, hashes: dict, api: int):
    report = read(folder/'result.json')
    check_header(report, read(folder/'binding-before.json'), read(folder/'binding-after.json'), main_tour, expected, hashes, api)
    density_raw = member(folder, 'actual-density.txt').read_text()
    matches = re.findall(r'(?:Override|Physical) density:\s*(\d+)', density_raw)
    require(matches, 'Actual Android density missing')
    density = int(matches[-1])/160
    before = prefs(folder/'before-c4-preferences.xml')
    student = before.get('flutter.lumo_learning_local_student_id_v1')
    require(type(student) is str, 'Actual child identity absent')
    owner = hashlib.sha256(student.encode()).hexdigest()
    raws = readbacks(folder)
    items = observations(folder, raws, owner, density)
    moves = check_moves_and_states(items, raws, report)
    touches = check_inputs(folder, items, raws, density)
    saves = check_saves(folder, items, report, before)
    leases = check_leases(report, raws, items[0]['state']['token'])
    returns = [check_return(folder, tag) for tag in ('c4-return-flutter', 'c4-final-flutter')]
    return {'status':'PASS','android_runtime':report['android_runtime'],'actual_moves':moves,
            'native_png_observations':len(items),'actual_touch_events':touches,
            'save':saves,'leases':leases,'returns':returns,'source_binding':report['source_binding'],
            'raw_readbacks':len(raws),'physical_fold7_performance_measured':False}


def check_snapshot_tree(snapshot: dict, root: Path, head: str, paths: tuple):
    require(snapshot.get('head') == head, 'Runtime source head differs')
    entries = git(root, 'ls-tree', '-rz', head, '--', *paths).split(b'\0')
    expected = {}
    for entry in entries:
        if entry:
            meta, path = entry.split(b'\t', 1)
            mode, kind, blob = meta.decode().split()
            require(kind == 'blob' and mode in ('100644','100755'), 'Unexpected runtime source tree entry')
            expected[path.decode()] = (mode, blob)
    files = snapshot.get('files', [])
    require(expected and len(files) == len(expected) and {f.get('path') for f in files} == set(expected),
            'Runtime source inventory is incomplete')
    for item in files:
        require((item.get('mode'),item.get('git_blob')) == expected[item['path']], 'Runtime source tree/blob/mode changed')
        digest(item.get('sha256')); require(type(item.get('bytes')) is int and item['bytes'] >= 0, 'Runtime source size missing')


def verify_runtime(folder: Path, host: Path, native: Path, expected: dict):
    report = read(folder/'runtime-gate.json')
    require(report.get('passed') is True and not report.get('error')
            and report.get('exit_codes') == {'dart':0,'godot':0}
            and all(type(v) is int for v in report['exit_codes'].values()), 'Real Dart/Godot processes did not both succeed')
    before = read(folder/'source-before.json')
    require(before == read(folder/'source-after.json'), 'Runtime source changed during execution')
    check_snapshot_tree(before['host'],host,expected['host'],runner.HOST_PATHS)
    check_snapshot_tree(before['native'],native,expected['native'],runner.NATIVE_PATHS)
    for group, root, names in (('host',host,('scripts/run_connect_four_runtime.py','test/games/connect_four_runtime_bridge.dart')),
                               ('native',native,('scripts/games/connect_four/connect_four_table.gd','scenes/games/connect_four_table.tscn','scripts/tests/connect_four_runtime_regression.gd'))):
        indexed={f['path']:f for f in before[group]['files']}
        for name in names:
            require(name in indexed and probe.sha(root/name)==indexed[name]['sha256'], 'Actual runtime runner/source hash differs: '+name)
    require(str(report.get('godot_version','')).startswith('4.6.3.'), 'Wrong actual runtime engine')
    require(read(folder/'session.json') == report.get('session'), 'Original runtime handshake differs')
    log=runner.validate_native_log(member(folder,'original-godot.log'))
    require(log == report.get('original_godot_log'), 'Original runtime engine log changed')
    member(folder,'original-dart.log')
    # Unchanged real gate re-decodes every actual PNG and rechecks all170+
    # assertions, fall trajectories, touch bounds, legal history and reward.
    results=runner.validate_results(folder,report['session'])
    require(results == report.get('results'), 'Actual runtime observations/media differ from original result')
    return {'status':'PASS','scope':'Real production Dart/Godot, local file transport/test preferences; not Android',
            'native_checks':results['native_checks'],'frames':results['frames'],
            'observed_moving_frames':results['observed_moving_frames'],
            'runtime_report_sha256':probe.sha(folder/'runtime-gate.json'),'device_fps_claim':False}


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('source-sha','native-sha','artifact-digest','apk-sha256','pck-sha256'):
        parser.add_argument('--'+name,required=True)
    for name in ('build-run','artifact-id'):
        parser.add_argument('--'+name,type=int,required=True)
    for name in ('native-source','metadata-dir','api35','api37','main-tour35','main-tour37','runtime','out'):
        parser.add_argument('--'+name,type=Path,required=True)
    args=parser.parse_args(argv)
    expected={'host':digest(args.source_sha,40),'native':digest(args.native_sha,40),
              'build_run':args.build_run,'artifact_id':args.artifact_id,
              'artifact_digest':digest(args.artifact_digest.removeprefix('sha256:')),
              'apk':digest(args.apk_sha256),'pck':digest(args.pck_sha256)}
    require(args.build_run>0 and args.artifact_id>0,'Actual positive GitHub IDs required')
    hashes=current_sources(ROOT,args.native_source,expected)
    metadata=verify_metadata(args.metadata_dir,expected)
    results={str(api):verify_android(folder,read(main_tour),expected,hashes,api)
             for api,folder,main_tour in ((35,args.api35,args.main_tour35),(37,args.api37,args.main_tour37))}
    runtime=verify_runtime(args.runtime,ROOT,args.native_source,expected)
    facts={'status':'PASS','schema':1,'source':expected,'original_github_metadata':metadata,
           'api35':results['35'],'api37':results['37'],'dart_godot_runtime':runtime,
           'limits':['No physical Fold7/FPS/thermal/touch-latency measurement',
                     'No two-child switch or all-opponent/tournament acceptance',
                     'Visualfixture does not satisfy this Android or Dart/Godot gate'],
           'verifier_sha256':probe.sha(Path(__file__))}
    require(not args.out.exists(),'Refusing to replace previous publication evidence')
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(facts,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps(facts,indent=2,ensure_ascii=False))
    return 0


if __name__=='__main__':
    raise SystemExit(main())
