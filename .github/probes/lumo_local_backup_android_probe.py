#!/usr/bin/env python3
"""Real SAF export/restore of fictional data on the tour's disposable API35 emulator.

All mutations use current UI controls. Preferences and game files are observed
read-only; no state, test receipt, document URI or touch coordinate is injected.
Helper unit tests validate failure handling, never constitute Android evidence.
"""
from __future__ import annotations

import argparse
import base64
from datetime import datetime, timedelta, timezone
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creative_android_probe as probe
from modernization_android_tour import verify_apk_identity

base, live, PACKAGE = probe.base, probe.live, probe.PACKAGE
DOCUMENTS = {'com.android.documentsui', 'com.google.android.documentsui'}
SETTINGS = 'lumo_app_settings_v1'
PROFILE = 'lumo_active_profile'
WALLET = 'lumo_reward_wallet_v1'
CONSENT = 'Als erwachsene Person möchte ich diesen Stand wiederherstellen.'
RESTORED = 'Die Sicherung wurde beim App-Start wiederhergestellt.'
REQUIRED = ('apk-identity', 'fictional-profile', 'saf-export', 'export-archive',
            'changed-setting', 'saf-review', 'process-closed', 'restore-and-preservation')


def strict_json(raw):
    def pairs(items):
        result = {}
        for key, value in items:
            if key in result:
                raise ValueError('Duplicate JSON field: ' + key)
            result[key] = value
        return result
    return json.loads(raw, object_pairs_hook=pairs,
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def owned_native_path(path):
    if (not isinstance(path, str) or len(path) > 220 or '..' in path or
            '\\' in path or re.search(r'[\x00-\x1f]', path)):
        return False
    if path.startswith('kart_geister/'):
        leaf = path[len('kart_geister/'):]
        return bool(leaf and '/' not in leaf and leaf.endswith(('.json', '.lumogeist')))
    return path in {'settings.cfg', 'progress.cfg', 'lumo_game_events.json',
                    'lumo_host_pending_rewards.cfg', 'lumo_soundscape.cfg',
                    'lumo_sternenjagd.cfg'} or bool(re.fullmatch(
        r'(?:kart|run|skypost|jump)_[A-Za-z0-9_-]{1,180}\.cfg|'
        r'lumo_(?:build|settlement|puzzle|rhythm|treasure|cards|chess|first_run)_'
        r'[A-Za-z0-9_-]{1,160}\.(?:json|cfg)', path))


def validate_archive(raw):
    if not raw or len(raw) > 64 * 1024 * 1024:
        raise ValueError('Invalid archive byte size')
    envelope = strict_json(raw)
    if (not isinstance(envelope, dict) or set(envelope) !=
            {'format', 'version', 'createdAt', 'payload', 'sha256'} or
            envelope['format'] != 'lumo-local-backup' or
            type(envelope['version']) is not int or envelope['version'] != 1 or
            not isinstance(envelope['payload'], str)):
        raise ValueError('Unsupported backup envelope')
    date = datetime.fromisoformat(envelope['createdAt'].replace('Z', '+00:00'))
    if date.utcoffset() != timedelta(0) or not 2000 <= date.year <= 2200:
        raise ValueError('Invalid UTC backup date')
    payload = envelope['payload'].encode('utf-8')
    if hashlib.sha256(payload).hexdigest() != envelope['sha256']:
        raise ValueError('Backup payload checksum differs')
    body = strict_json(payload)
    if (not isinstance(body, dict) or set(body) != {'preferences', 'nativeFiles'} or
            not isinstance(body['preferences'], dict) or not isinstance(body['nativeFiles'], list)):
        raise ValueError('Invalid backup payload')
    preferences = {}
    for key, row in body['preferences'].items():
        if not isinstance(row, dict) or set(row) != {'type', 'value'}:
            raise ValueError('Invalid typed preference')
        value, kind = row['value'], row['type']
        valid = ((kind == 'string' and isinstance(value, str)) or
                 (kind == 'bool' and type(value) is bool) or
                 (kind == 'int' and type(value) is int) or
                 (kind == 'double' and type(value) in (int, float)) or
                 (kind == 'strings' and isinstance(value, list) and
                  all(isinstance(v, str) for v in value)))
        if not valid:
            raise ValueError('Wrong preference type: ' + key)
        preferences[key] = value
    files = {}
    for row in body['nativeFiles']:
        if (not isinstance(row, dict) or set(row) != {'path', 'bytes', 'sha256', 'data'} or
                not owned_native_path(row['path']) or row['path'] in files or
                type(row['bytes']) is not int or not 0 <= row['bytes'] <= 8 * 1024 * 1024):
            raise ValueError('Invalid or duplicate native file')
        data = base64.b64decode(row['data'], validate=True)
        if len(data) != row['bytes'] or hashlib.sha256(data).hexdigest() != row['sha256']:
            raise ValueError('Native file checksum differs: ' + row['path'])
        files[row['path']] = data
    if len(files) > 1024 or sum(map(len, files.values())) > 32 * 1024 * 1024:
        raise ValueError('Native snapshot exceeds limits')
    if not any(name.startswith('kart_') and name.endswith('.cfg') for name in files):
        raise ValueError('The preceding real Kart tour has no exported Kart save')
    return {'createdAt': envelope['createdAt'], 'payload_sha256': envelope['sha256'],
            'preferences': preferences, 'nativeFiles': files}


def stored_json(preferences, key, *, physical=False):
    value = preferences.get(('flutter.' if physical else '') + key)
    if not isinstance(value, str):
        raise ValueError('Missing persisted JSON: ' + key)
    decoded = strict_json(value)
    if not isinstance(decoded, dict):
        raise ValueError('Persisted JSON is not an object: ' + key)
    return decoded


def verify_preferences(archive, observed):
    for key in (PROFILE, WALLET):
        if stored_json(archive['preferences'], key) != stored_json(observed, key, physical=True):
            raise ValueError('Stored data differs from archive: ' + key)
    expected = stored_json(archive['preferences'], SETTINGS)['reduceAnimations']
    actual = stored_json(observed, SETTINGS, physical=True).get('reduceAnimations')
    if type(expected) is not bool or actual is not expected:
        raise ValueError('Persisted reduceAnimations differs from archive')
    for key in ('lumo_learning_local_student_id_v1', 'lumo_school_active_student_v1',
                'lumo_school_v1', 'lumo_native_profile_keys_v1'):
        if key in archive['preferences'] and observed.get('flutter.' + key) != archive['preferences'][key]:
            raise ValueError('Profile ownership differs from archive: ' + key)
    return {'profile': stored_json(observed, PROFILE, physical=True),
            'wallet': stored_json(observed, WALLET, physical=True), 'reduceAnimations': actual}


def event_ack_only(before, after, wallet):
    """Only proven durable reward ACKs/navigation removal may change this file."""
    old, new = strict_json(before), strict_json(after)
    if not isinstance(old, dict) or not isinstance(new, dict):
        return False
    allowed = {'results', 'destination', 'callerReturnSession'}
    if {k: v for k, v in old.items() if k not in allowed} != {
            k: v for k, v in new.items() if k not in allowed}:
        return False
    for key in ('destination', 'callerReturnSession'):
        if key in new and (key not in old or new[key] != old[key]):
            return False
    if 'destination' in new and 'callerReturnSession' in old and 'callerReturnSession' not in new:
        return False
    rows, retained = old.get('results', []), new.get('results', [])
    if not isinstance(rows, list) or not isinstance(retained, list):
        return False
    paid = wallet.get('gameResultIds', [])
    if not isinstance(paid, list):
        return False
    rest = list(retained)
    for row in rows:
        if rest and row == rest[0]:
            rest.pop(0)
        elif not isinstance(row, dict) or row.get('resultId') not in paid:
            return False
    return not rest


def remote_bytes(path):
    # exec-out preserves every byte, including trailing newlines in CFG files.
    return subprocess.run(['adb', 'exec-out', 'cat', '--', shlex.quote(path)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=90, check=True).stdout


def native_snapshot(out, archive, tag, wallet):
    result = []
    folder = out / tag
    folder.mkdir(exist_ok=True)
    for path, expected in archive['nativeFiles'].items():
        actual = remote_bytes(f'/data/user/0/{PACKAGE}/files/{path}')
        target = folder / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(actual)
        same = actual == expected
        ack = path == 'lumo_game_events.json' and event_ack_only(expected, actual, wallet)
        if not same and not ack:
            raise ValueError('Native save differs: ' + path)
        result.append({'path': path, 'bytes': len(actual),
            'sha256': hashlib.sha256(actual).hexdigest(),
            'archive_sha256': hashlib.sha256(expected).hexdigest(),
            'comparison': 'identical-bytes' if same else 'proven-event-ack-only'})
    return result


def bounds(node):
    match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
    if not match:
        return None
    x0, y0, x1, y1 = map(int, match.groups())
    return (x0, y0, x1, y1) if x1 > x0 and y1 > y0 else None


def caption(node, labels):
    wanted = {' '.join(value.split()).casefold() for value in labels}
    return any(' '.join(value.split()).casefold() in wanted
        for key in ('text', 'content-desc')
        for value in [node.get(key, ''), *node.get(key, '').splitlines()] if value)


def native_target(nodes, package, labels):
    targets = {}
    for node in nodes:
        if (node.get('package') != package or node.get('enabled') != 'true' or
                node.get('visible-to-user') == 'false' or not caption(node, labels)):
            continue
        choices = [parent for parent in nodes if parent.get('package') == package and
            parent.get('clickable') == 'true' and parent.get('enabled') == 'true' and
            parent.get('visible-to-user') != 'false' and bounds(parent) and
            (parent is node or (hasattr(parent, 'iter') and node in parent.iter()))]
        if choices:
            parent = min(choices, key=lambda value: (bounds(value)[2] - bounds(value)[0]) *
                         (bounds(value)[3] - bounds(value)[1]))
            targets[bounds(parent)] = parent
    if len(targets) > 1:
        raise RuntimeError('Ambiguous current DocumentsUI target: ' + repr(labels))
    return next(iter(targets.values()), None)


def tap_native(out, package, labels, tag):
    for attempt in range(20):
        node = native_target(live.live_nodes(out, f'{tag}-{attempt}'), package, labels)
        if node is None:
            time.sleep(.4)
            continue
        shot = probe.capture(out, tag + '-before-touch')
        fresh = native_target(live.live_nodes(out, tag + '-touch'), package, labels)
        if fresh is None or bounds(fresh) != bounds(node):
            time.sleep(.3)
            continue
        x0, y0, x1, y1 = bounds(fresh)
        event = {'package': package, 'labels': labels, 'bounds': bounds(fresh),
                 'screenshot': shot, 'hierarchy': tag + '-touch.xml'}
        (out / (tag + '-touch.json')).write_text(json.dumps(event, ensure_ascii=False, indent=2))
        base.adb('shell', 'input', 'tap', str((x0 + x1) // 2), str((y0 + y1) // 2))
        time.sleep(.7)
        return event
    raise RuntimeError('Current DocumentsUI target missing: ' + repr(labels))


def picker_identity(activities, action):
    resumed = re.findall(r'(?:topResumedActivity[=:]|mResumedActivity[:=])\s*'
        r'ActivityRecord\{([a-f0-9]+)\s+u\d+\s+([^/\s]+)/[^\s}]+', activities)
    candidates = {(token, package) for token, package in resumed if package in DOCUMENTS}
    if len(candidates) != 1:
        raise RuntimeError('One actual foreground DocumentsUI activity is required')
    token, package = next(iter(candidates))
    sections = re.split(r'(?=\n\s*\* Hist\s+#\d+:)', activities)
    sections = [section for section in sections if re.match(
        r'\s*\* Hist\s+#\d+:\s*ActivityRecord\{' + re.escape(token) + r'\s', section)]
    for section in sections:
        for line in section.splitlines():
            if ('Intent {' in line and f'act=android.intent.action.{action}' in line and
                    'typ=application/json' in line and f'cmp={package}/' in line):
                return {'package': package, 'activity_token': token, 'intent': line.strip()}
    raise RuntimeError('Current DocumentsUI activity lacks the expected JSON SAF intent')


def wait_picker(out, action, tag):
    for attempt in range(25):
        activities = base.adb('shell', 'dumpsys', 'activity', 'activities')
        (out / (tag + '-activities.txt')).write_text(activities)
        try:
            return picker_identity(activities, action)
        except RuntimeError:
            time.sleep(.5)
    raise RuntimeError('Expected JSON SAF picker did not become foreground: ' + action)


def suggested_filename(nodes, package):
    values = [node.get('text', '') for node in nodes if node.get('package') == package and
        node.get('class') == 'android.widget.EditText' and node.get('enabled') == 'true' and bounds(node)]
    if len(values) != 1 or not re.fullmatch(r'Lumo-Sicherung-\d{4}-\d{2}-\d{2}-\d{4}\.json', values[0]):
        raise RuntimeError('Exactly one current suggested backup filename is required')
    return values[0]


def downloads(out, package, tag):
    # Android 15 DocumentsUI res/values{,-de}/strings.xml, drawer_open.
    tap_native(out, package, ['Show roots', 'Root-Verzeichnis anzeigen'], tag + '-roots')
    tap_native(out, package, ['Downloads'], tag + '-downloads')
    nodes = live.live_nodes(out, tag + '-download-folder')
    if not any(node.get('package') == package and caption(node, ['Downloads']) for node in nodes):
        raise RuntimeError('Downloads folder is not currently visible')
    probe.capture(out, tag + '-download-folder')


def scroll_current(nodes, direction):
    areas = [bounds(node) for node in nodes if node.get('package') == PACKAGE and
             node.get('scrollable') == 'true' and bounds(node)]
    if not areas:
        return False
    x0, y0, x1, y1 = max(areas, key=lambda area: (area[2] - area[0]) * (area[3] - area[1]))
    lo, hi = round(y0 + (y1 - y0) * .2), round(y0 + (y1 - y0) * .8)
    start, end = (lo, hi) if direction < 0 else (hi, lo)
    base.adb('shell', 'input', 'swipe', str((x0 + x1) // 2), str(start),
             str((x0 + x1) // 2), str(end), '350')
    time.sleep(.5)
    return True


def see_flutter(out, wanted, tag, *, scroll=False):
    seen = set()
    for direction in ((-1, 1) if scroll else (1,)):
        for attempt in range(20 if scroll else 30):
            nodes = live.live_nodes(out, f'{tag}-{direction}-{attempt}')
            text = '\n'.join(node.get('text', '') + '\n' + node.get('content-desc', '')
                for node in nodes if node.get('package') == PACKAGE)
            seen.update(value for value in wanted if value in text)
            if seen == set(wanted):
                return {'observed': sorted(seen), 'hierarchy': f'{tag}-{direction}-{attempt}.xml'}
            if not scroll or not scroll_current(nodes, direction):
                time.sleep(.4)
    raise RuntimeError('Required real Flutter text missing: ' + repr(set(wanted) - seen))


def parents(out, tag):
    visited = set()
    for attempt in range(8):
        nodes = live.live_nodes(out, f'{tag}-{attempt}')
        if any(node.get('package') == PACKAGE and node.get('clickable') != 'true' and
               caption(node, ['Elternbereich']) for node in nodes):
            return
        for label in ('Einstellungen', 'Eltern', 'Elternbereich öffnen', 'Dein Profil', 'Profil'):
            if label in visited:
                continue
            if any(node.get('package') == PACKAGE and node.get('clickable') == 'true' and
                   node.get('enabled') != 'false' and caption(node, [label]) for node in nodes):
                probe.flutter_tap(out, label, f'{tag}-{attempt}-navigate', min_visible_height_px=48)
                visited.add(label)
                break
        else:
            # This real profile action card remains reachable when its small
            # upper edit button is merged into an untappable semantics region.
            if 'Profil' in visited:
                probe.flutter_tap(out, 'Klasse und Einstellungen ansehen',
                    tag + '-profile-settings', scroll_attempts=22, min_visible_height_px=48)
            else:
                time.sleep(.5)
    raise RuntimeError('Actual parent settings route was not reached')


def wait_setting(out, expected, tag):
    for attempt in range(30):
        current = probe.prefs(out, f'{tag}-{attempt}')
        try:
            value = stored_json(current, SETTINGS, physical=True).get('reduceAnimations')
        except ValueError:
            value = None
        if type(value) is bool and (expected is None or value is expected):
            return current
        time.sleep(.3)
    raise RuntimeError('The visible animation switch did not persist the expected change')


def installed_identity(out, expected, tag):
    paths = base.adb('shell', 'pm', 'path', PACKAGE).splitlines()
    if len(paths) != 1 or not paths[0].startswith('package:/data/app/'):
        raise RuntimeError('Expected one installed candidate APK')
    path = paths[0][len('package:'):]
    actual = base.adb('shell', 'sha256sum', shlex.quote(path)).split()[0]
    package = probe.package_identity(out, tag)
    if actual != expected['apk_sha256'] or int(package['versionCode'].split()[0]) != expected['versionCode']:
        raise RuntimeError('Installed APK differs from source/provenance-bound candidate')
    return {'path': path, 'sha256': actual, 'package': package}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('apk', 'provenance', 'sums', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'steps': [], 'scope': 'Real API35 Android SAF round trip',
        'not_tested': ['restoration of a running native game process', 'physical user devices']}
    phase = 'apk-identity'

    def passed(name, **details):
        result['steps'].append({'step': name, 'ok': True, **details})
        (out / 'backup-result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        print('[LocalBackupEvidence]', name, 'PASS', flush=True)

    try:
        result['identity'] = verify_apk_identity(args.apk, args.provenance, args.sums)
        if base.adb('shell', 'getprop', 'ro.kernel.qemu') != '1' or base.adb(
                'shell', 'getprop', 'ro.build.version.sdk') != '35':
            raise RuntimeError('This probe is authorized only on the disposable API35 emulator')
        result['emulator_root_readiness'] = probe.ensure_rooted_emulator(base.adb, out)
        result['installed'] = installed_identity(out, result['identity'], 'before')
        if base.adb('shell', 'pidof', PACKAGE + ':lumo_game', check=False):
            raise RuntimeError('The preceding tour left a native game process active')
        passed(phase, installed_sha256=result['installed']['sha256'])

        phase = 'fictional-profile'
        initial = probe.prefs(out, 'initial')
        if stored_json(initial, PROFILE, physical=True).get('name') != 'LumoTest':
            raise RuntimeError('Only the preceding tour fictional LumoTest profile is authorized')
        base.adb('shell', 'am', 'force-stop', PACKAGE)
        base.launch(out, 'backup-cold-start')
        parents(out, 'parents-before')
        current = probe.prefs(out, 'parents-before')
        if 'flutter.' + SETTINGS not in current:
            for index in range(2):
                probe.flutter_tap(out, 'Animationen reduzieren', f'initialize-setting-{index}',
                    scroll_attempts=40, min_visible_height_px=48)
                current = wait_setting(out, None if index == 0 else not first_value,
                                       f'initialized-setting-{index}')
                if index == 0:
                    first_value = stored_json(current, SETTINGS, physical=True)['reduceAnimations']
            result['default_settings_initialized_by_two_real_taps'] = True
        baseline = probe.prefs(out, 'before-export')
        original = stored_json(baseline, SETTINGS, physical=True)['reduceAnimations']
        if type(original) is not bool:
            raise RuntimeError('Persisted original animation setting is missing')
        passed(phase, profile_name='LumoTest', original_reduceAnimations=original)

        phase = 'saf-export'
        probe.flutter_tap(out, 'Sicherungsdatei speichern', 'export',
            scroll_attempts=40, min_visible_height_px=48)
        picker = wait_picker(out, 'CREATE_DOCUMENT', 'export-picker')
        filename = suggested_filename(live.live_nodes(out, 'export-suggested-name'), picker['package'])
        downloads(out, picker['package'], 'export')
        if suggested_filename(live.live_nodes(out, 'export-final-name'), picker['package']) != filename:
            raise RuntimeError('Current save filename changed unexpectedly')
        remote = '/sdcard/Download/' + filename
        if base.adb('shell', 'test', '-e', shlex.quote(remote), '&&', 'echo', 'exists', check=False):
            raise RuntimeError('Refusing to replace an existing document in the test emulator')
        tap_native(out, picker['package'], ['Save', 'Speichern'], 'export-save')
        see_flutter(out, ['Die Sicherungsdatei wurde am gewählten Speicherort gespeichert.'], 'export-confirmed')
        probe.capture(out, 'export-completed')
        raw = remote_bytes(remote)
        (out / filename).write_bytes(raw)
        passed(phase, picker=picker, observed_filename=filename, remote_path=remote,
               bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())

        phase = 'export-archive'
        archive = validate_archive(raw)
        preserved = verify_preferences(archive, baseline)
        files = native_snapshot(out, archive, 'native-export', preserved['wallet'])
        passed(phase, format='lumo-local-backup', version=1, createdAt=archive['createdAt'],
            payload_sha256=archive['payload_sha256'], profile=preserved['profile'],
            wallet=preserved['wallet'], preference_count=len(archive['preferences']), native_files=files)

        phase = 'changed-setting'
        probe.flutter_tap(out, 'Animationen reduzieren', 'change-animation',
            scroll_attempts=40, min_visible_height_px=48)
        changed = wait_setting(out, not original, 'changed-setting')
        probe.capture(out, 'setting-changed')
        if stored_json(changed, PROFILE, physical=True) != preserved['profile']:
            raise RuntimeError('Profile changed before restore')
        passed(phase, before=original, persisted_after=not original)

        phase = 'saf-review'
        probe.flutter_tap(out, 'Sicherung auswählen und prüfen', 'import',
            scroll_attempts=40, min_visible_height_px=48)
        picker = wait_picker(out, 'OPEN_DOCUMENT', 'import-picker')
        downloads(out, picker['package'], 'import')
        tap_native(out, picker['package'], [filename], 'import-file')
        nodes = live.live_nodes(out, 'import-after-file')
        if native_target(nodes, picker['package'], ['Open', 'Öffnen']) is not None:
            tap_native(out, picker['package'], ['Open', 'Öffnen'], 'import-open')
        offset = base.adb('shell', 'date', '+%z')
        if not re.fullmatch(r'[+-]\d{4}', offset):
            raise RuntimeError('Actual Android timezone offset unavailable')
        minutes = (int(offset[1:3]) * 60 + int(offset[3:])) * (-1 if offset[0] == '-' else 1)
        date = datetime.fromisoformat(archive['createdAt'].replace('Z', '+00:00')).astimezone(
            timezone(timedelta(minutes=minutes)))
        date_label = f'Sicherung vom {date.day}.{date.month}.{date.year} {date:%H:%M}'
        review = see_flutter(out, ['Geprüfte Sicherung wiederherstellen?', date_label,
            'Profile: LumoTest', f'{len(archive["preferences"])} Lerndaten-Einträge und '
            f'{len(archive["nativeFiles"])} native Spielstandsdateien.'], 'restore-review', scroll=True)
        probe.capture(out, 'restore-review')
        probe.flutter_tap(out, CONSENT, 'adult-restore-consent', scroll_attempts=16,
                          min_visible_height_px=48)
        consent_nodes = live.live_nodes(out, 'adult-consent-checked')
        if not any(node.get('package') == PACKAGE and caption(node, [CONSENT]) and
                   node.get('checked') == 'true' for node in consent_nodes):
            raise RuntimeError('Adult restore checkbox is not confirmed checked')
        probe.capture(out, 'adult-consent-checked')
        passed(phase, picker=picker, observed_filename=filename, review=review,
               adult_checkbox_checked=True)

        phase = 'process-closed'
        prior_pid = base.adb('shell', 'pidof', PACKAGE, check=False)
        if not prior_pid:
            raise RuntimeError('No running host process before restore confirmation')
        probe.flutter_tap(out, 'Wiederherstellen und schließen', 'confirm-restore',
            scroll_attempts=16, min_visible_height_px=48)
        observations = []
        result['process_close_observations'] = observations
        for attempt in range(60):
            pid = base.adb('shell', 'pidof', PACKAGE, check=False)
            native = base.adb('shell', 'pidof', PACKAGE + ':lumo_game', check=False)
            observations.append({'attempt': attempt, 'host_pid': pid, 'native_pid': native})
            if not pid and not native:
                break
            time.sleep(.5)
        else:
            raise RuntimeError('Restore confirmation did not close the app processes')
        probe.capture(out, 'restore-app-closed')
        passed(phase, prior_pid=prior_pid, observations=observations)

        phase = 'restore-and-preservation'
        new_pid = base.launch(out, 'restore-cold-start')
        parents(out, 'parents-after')
        status = see_flutter(out, [RESTORED], 'restore-status', scroll=True)
        probe.capture(out, 'restore-status')
        restored = verify_preferences(archive, probe.prefs(out, 'after-restore'))
        files = native_snapshot(out, archive, 'native-restored', restored['wallet'])
        result['installed_after'] = installed_identity(out, result['identity'], 'after')
        passed(phase, new_host_pid=new_pid, status_message=status,
            profile=restored['profile'], wallet=restored['wallet'],
            restored_reduceAnimations=restored['reduceAnimations'], native_files=files)
        if [step['step'] for step in result['steps']] != list(REQUIRED):
            raise RuntimeError('Required backup proof is incomplete')
        result['status'] = 'PASS'
        return 0
    except Exception as error:
        result.update(status='FAIL', error=f'{type(error).__name__}: {error}')
        result['steps'].append({'step': phase, 'ok': False, 'error': str(error)})
        (out / 'failure-trace.txt').write_text(traceback.format_exc())
        try:
            probe.capture(out, 'backup-failure')
            live.live_nodes(out, 'backup-failure')
        except Exception as capture_error:
            result['failure_capture_error'] = str(capture_error)
        return 1
    finally:
        (out / 'backup-result.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        print('[LocalBackupResult]', json.dumps(result, ensure_ascii=False), flush=True)


if __name__ == '__main__':
    raise SystemExit(main())
