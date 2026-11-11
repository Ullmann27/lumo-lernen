"""Read-only, fail-closed delivery binding for the original supplemental QA proof.

This validates an existing Actions artifact. It never runs the app, creates a
runtime result, modifies the downloaded proof, builds an APK or publishes it.
"""
from __future__ import annotations

import argparse
from datetime import datetime
import hashlib
import json
import math
from pathlib import Path
import re
import struct

REPOSITORY = 'Ullmann27/lumo-lernen'
REPOSITORY_ID = 1222433959
APP_SOURCE = '2718f405e69c193d0121c6f6447fe53769d7c803'
NATIVE_SOURCE = 'b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1'
APP_RUN = 43024454590
QA_RUN = 43034616066
QA_SOURCE = 'a1d581f0b0b392e0bc4ad7d90fd38d14f8d74095'
QA_ATTEMPT = 2
QA_WORKFLOW_ID = 414716713
QA_WORKFLOW = '.github/workflows/lumo-2015-android-garage-qa.yml'
QA_BRANCH = 'chatgpt/lumo-2015-android-garage-qa-20261111'
ARTIFACT_NAME = 'lumo-2015-existing-apk-garage-android-proof'
APK_SHA256 = 'b863bc25bc07a7ca3fb78ad4fd56a6f816d091f821c5b9af27bfb0a7aecbcb4e'
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
KARTS = {'comet': 'Comet', 'gecko_velo': 'Gecko Velo'}
LAYOUTS = {'fold-cover': (904, 2316, 420), 'fold-open': (1812, 2176, 420)}
IDENTITY_CHECKS = (
    'sha256_matches_provenance', 'sha256_matches_build_sums', 'flutter_source_is_this_commit',
    'tracked_source_clean', 'godot_revision_is_pinned', 'signing_certificate',
    'version_matches_pubspec', 'x86_64_native_code',
)
REQUIRED_STEPS = (
    'apk-identity', 'onboarding', 'phone-garage-cancel-back',
    'phone-comet-selection-confirm-start', 'phone-comet-drive',
    'phone-comet-pause-freeze', 'phone-comet-continue-and-drive',
    'phone-comet-pause-android-back', 'phone-gecko-selection-confirm-start',
    'phone-gecko-drive', 'phone-gecko-abandon',
    'fold-cover-garage-confirm-back', 'fold-open-garage-confirm-back',
    'profile-learning-preserved', 'no-native-crash',
)


def demand(ok: bool, message: str) -> None:
    if not ok:
        raise RuntimeError(message)


def number(value, name: str, minimum: float = 0) -> float:
    demand(type(value) in (int, float) and math.isfinite(value) and value >= minimum,
           'Missing, nonfinite or out-of-range number: ' + name)
    return value


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        demand(key not in value, 'Duplicate JSON key: ' + key)
        value[key] = item
    return value


def load_json(path: Path):
    def invalid(value):
        raise RuntimeError('Nonfinite JSON constant: ' + value)
    return json.loads(path.read_bytes(), object_pairs_hook=unique_object,
                      parse_constant=invalid)


def timestamp(value: str) -> datetime:
    parsed = datetime.fromisoformat(value.replace('Z', '+00:00'))
    demand(parsed.tzinfo is not None, 'Actions timestamp lacks a timezone')
    return parsed


def validate_metadata(run: dict, jobs: list[dict], artifacts: list[dict]) -> dict:
    expected = {'id': QA_RUN, 'head_sha': QA_SOURCE, 'run_attempt': QA_ATTEMPT,
                'workflow_id': QA_WORKFLOW_ID, 'path': QA_WORKFLOW,
                'name': 'Lumo 2015 existing APK Garage Android QA',
                'event': 'pull_request', 'head_branch': QA_BRANCH,
                'status': 'completed', 'conclusion': 'success'}
    for key, value in expected.items():
        demand(type(run.get(key)) is type(value) and run[key] == value,
               'Supplemental Garage run is not the fixed successful run: ' + key)
    for key in ('repository', 'head_repository'):
        demand(run[key]['full_name'] == REPOSITORY and run[key]['id'] == REPOSITORY_ID,
               'Supplemental Garage run belongs to another repository')
    selected_jobs = [job for job in jobs if job.get('name') == 'existing-apk-garage']
    demand(len(selected_jobs) == 1, 'Missing or ambiguous actual Garage QA job')
    job = selected_jobs[0]
    for key, value in {'run_id': QA_RUN, 'head_sha': QA_SOURCE, 'run_attempt': QA_ATTEMPT,
                       'status': 'completed', 'conclusion': 'success'}.items():
        demand(type(job.get(key)) is type(value) and job[key] == value,
               'Supplemental Garage job is not the fixed successful attempt: ' + key)
    # Earlier failed attempts retain their own proof artifacts. Only an upload
    # created during this exact successful job can supply the current proof.
    selected = [item for item in artifacts if item.get('name') == ARTIFACT_NAME and
                timestamp(item['created_at']) >= timestamp(job['started_at'])]
    demand(len(selected) == 1, 'Missing or ambiguous original Garage artifact')
    artifact = selected[0]
    demand(type(artifact.get('id')) is int and artifact['id'] > 0 and
           type(artifact.get('size_in_bytes')) is int and artifact['size_in_bytes'] > 0 and
           artifact.get('expired') is False, 'Original Garage artifact unavailable')
    demand(re.fullmatch(r'sha256:[0-9a-f]{64}', artifact.get('digest', '')) is not None,
           'Original Garage artifact lacks an archive digest')
    identity = artifact['workflow_run']
    demand(identity['id'] == QA_RUN and identity['head_sha'] == QA_SOURCE and
           identity['head_branch'] == QA_BRANCH and
           identity['repository_id'] == identity['head_repository_id'] == REPOSITORY_ID,
           'Original Garage artifact belongs to another run/source/repository')
    demand(timestamp(run['run_started_at']) <= timestamp(job['started_at']) <=
           timestamp(artifact['created_at']) <= timestamp(job['completed_at']) and
           timestamp(artifact['created_at']) <= timestamp(artifact['updated_at']) <=
           timestamp(job['completed_at']), 'Artifact is outside the fixed successful job attempt')
    return {'qa_run': QA_RUN, 'qa_source': QA_SOURCE, 'qa_attempt': QA_ATTEMPT,
            'job_id': job['id'], 'artifact_id': artifact['id'],
            'artifact_name': ARTIFACT_NAME, 'artifact_digest': artifact['digest'],
            'artifact_bytes': artifact['size_in_bytes'],
            'artifact_created_at': artifact['created_at'],
            'artifact_updated_at': artifact['updated_at']}


def metadata_directory(directory: Path, prefix: str = 'garage') -> dict:
    return validate_metadata(load_json(directory / (prefix + '-run.json')),
                             load_json(directory / (prefix + '-jobs.json')),
                             load_json(directory / (prefix + '-artifacts.json')))


def original_file(root: Path, relative: str) -> Path:
    path = Path(relative)
    demand(not path.is_absolute() and '..' not in path.parts and bool(path.parts),
           'Evidence path escapes the original artifact')
    result = root / path
    demand(result.is_file() and not result.is_symlink(), 'Missing original evidence: ' + relative)
    demand(result.resolve().is_relative_to(root.resolve()), 'Evidence resolves outside the artifact')
    demand(result.stat().st_size > 0, 'Empty original evidence: ' + relative)
    return result


def state_identity(state: dict, kart: str, race_id: str | None = None, *, full: bool = True) -> str:
    demand(state['selected_kart'] == kart and state['selected_driver'] == 'fox' and
           state['track_id'] == 'sonnenhafen' and state['mode'] == 'cup',
           'Wrong actual car, original driver, track or mode')
    identity = state['result_id']
    demand(type(identity) is str and bool(identity) and (race_id is None or identity == race_id),
           'Actual race identity changed or is missing')
    number(state['distance'], 'race distance')
    number(state['elapsed'], 'race elapsed', 1)
    demand(number(state['countdown'], 'race countdown', -1e9) <= 0,
           'Garage has not started a running race')
    if full:
        demand(state['finished'] is False and state['completed_race'] is False,
               'Finished race cannot prove current selection or continuation')
    return identity


def require_frame(frame: dict) -> None:
    width, height = frame['size']
    demand(width > height >= 160 and width >= 320, 'Missing rendered landscape race')
    demand(len(frame['visible_fractions']) == len(frame['detail']) == 3,
           'Missing full-width rendered scene evidence')
    for fraction, detail in zip(frame['visible_fractions'], frame['detail']):
        number(fraction, 'visible scene fraction', .65)
        number(detail['colour_bins'], 'scene colour bins', 8)
        number(detail['bright_fraction'], 'bright scene fraction', .2)


def require_capture(runtime: Path, folder: str, capture: dict) -> None:
    name = capture['file']
    demand(Path(name).name == name and name.endswith('.png'), 'Invalid original screenshot name')
    raw = original_file(runtime, folder + '/' + name).read_bytes()
    demand(hashlib.sha256(raw).hexdigest() == capture['sha256'], 'Original screenshot digest differs')
    demand(raw.startswith(b'\x89PNG\r\n\x1a\n') and len(raw) >= 24,
           'Original screenshot is not PNG')
    demand(list(struct.unpack('>II', raw[16:24])) == [capture['width'], capture['height']],
           'Original screenshot dimensions differ from the observation')


def require_touch(runtime: Path, touch: dict, label: str) -> None:
    demand(touch['label'] == label, 'Wrong actual native action caption')
    readiness = load_json(original_file(runtime, touch['readiness']))
    demand(readiness['status'] == 'TOUCH_SENT' and readiness['label'] == label and
           readiness['exact_caption_required'] is True and readiness['touch'] == touch['touch'],
           'Original stable native touch evidence is missing or inconsistent')
    demand(len(readiness['frames']) >= 2 and
           readiness['frames'][-1]['target']['stable_observed_target'] is True,
           'Native touch lacks two current stable observations')


def require_drive(detail: dict, kart: str, race_id: str) -> None:
    before, after = detail['start'], detail['after']
    state_identity(before, kart, race_id)
    state_identity(after, kart, race_id)
    number(after['distance'] - before['distance'], 'actual driving distance gain', 8)
    number(after['elapsed'] - before['elapsed'], 'actual driving time gain', 2.5)
    movement = detail['movement']
    require_frame(movement['rendered_frame'])
    number(movement['world_moved']['changed_fraction'], 'changed rendered world', .08)
    number(movement['world_moved']['mean_channel_delta'], 'rendered world difference', 6)
    progress = movement['native_progress']
    demand(progress['result_id'] == race_id, 'Movement proof belongs to another race')
    number(progress['distance_gain'], 'saved driving distance gain', 8)
    number(progress['elapsed_gain'], 'saved driving time gain', 2.5)
    number(movement['gas_pulses'], 'actual GAS pulses', 1)
    number(movement['hold_ms'], 'actual GAS hold duration', 1)
    demand(len(movement['gas_touch']) == 2, 'Missing actual GAS touch')


def saved_scalars(path: Path, fields: tuple[str, ...]) -> dict:
    sections = re.split(r'^\[race\]\s*$', path.read_text(), flags=re.M)
    demand(len(sections) == 2, 'Original native save needs exactly one race section')
    race = re.split(r'^\[', sections[1], maxsplit=1, flags=re.M)[0]
    result = {}
    for field in fields:
        matches = re.findall(r'^' + re.escape(field) + r'=(.*)$', race, re.M)
        demand(len(matches) == 1, 'Missing or ambiguous original native scalar: ' + field)
        result[field] = json.loads(matches[0])
    return result


def require_pause(runtime: Path, folder: str, detail: dict, kart: str, race_id: str) -> None:
    state_identity(detail['state'], kart, race_id)
    fields = ('result_id', 'distance', 'elapsed', 'checkpoint_index', 'finished')
    first = saved_scalars(original_file(runtime, folder + '/paused-first-session.cfg'), fields)
    second = saved_scalars(original_file(runtime, folder + '/paused-second-session.cfg'), fields)
    demand(first == second == detail['frozen'] == {key: detail['state'][key] for key in fields},
           'Original paused samples are missing, changed or inconsistent')
    require_capture(runtime, folder, detail['title']['capture'])
    demand(detail['title']['caption'] == 'Eine kleine Pause' and detail['title']['observed'],
           'Actual pause caption missing')


def require_return(runtime: Path, folder: str, detail: dict) -> None:
    demand(PACKAGE in detail['foreground'] and 'LumoGameActivity' not in detail['foreground'],
           'Native navigation did not return to Flutter')
    require_capture(runtime, folder, detail['capture'])


def require_navigation(runtime: Path, folder: str, detail: dict) -> None:
    demand(detail['race_not_started'] is True, 'Cancel/back unexpectedly started a race')
    captions = {'world': ('Wohin geht die Reise?',), 'kart': ('Dein Kart. Dein Stil.',),
                'driver': ('Wer fährt mit?',), 'mode': ('Dein Abenteuer', 'Dein nächstes Abenteuer'),
                'landing': ('Garage',)}
    for name, expected in captions.items():
        demand(detail[name]['caption'] in expected and detail[name]['observed'],
               'Original Garage confirmation/back caption missing: ' + name)
        require_capture(runtime, folder, detail[name]['capture'])


def validate_proof(artifact_root: Path, binding: dict, expected_pck: str,
                   tour_apk_sha256: str, update_apk_sha256: str) -> dict:
    demand(re.fullmatch(r'[0-9a-f]{64}', expected_pck) is not None, 'Actual ARM64 PCK hash is missing')
    demand(tour_apk_sha256 == update_apk_sha256 == APK_SHA256,
           'Garage, original Android tour and update must test the exact same x86 APK')
    demand(binding['qa_run'] == QA_RUN and binding['qa_source'] == QA_SOURCE and
           binding['qa_attempt'] == QA_ATTEMPT, 'Wrong successful Garage metadata binding')
    demand(original_file(artifact_root, 'apk-source-sha.txt').read_text().strip() == APP_SOURCE and
           original_file(artifact_root, 'qa-source-sha.txt').read_text().strip() == QA_SOURCE,
           'QA commit and actual APK source are missing or confused')
    path = original_file(artifact_root, 'runtime/garage-result.json')
    demand(list(artifact_root.rglob('garage-result.json')) == [path],
           'Original Garage result is missing or ambiguous')
    original_digest = hashlib.sha256(path.read_bytes()).hexdigest()
    report = load_json(path)
    demand(report['status'] == 'PASS' and not any(key in report for key in
           ('error', 'failure_capture_error', 'logcat_error')), 'Original Garage result failed or is incomplete')
    demand(report['source'] == APP_SOURCE and report['godot_source'] == NATIVE_SOURCE and
           report['source_run'] == APP_RUN and report['apk_sha256'] == APK_SHA256,
           'Original Garage result tested another APK/source/native pack')
    steps = report['steps']
    names = [item['step'] for item in steps]
    demand(len(names) == len(set(names)) and set(names) == set(REQUIRED_STEPS),
           'Original Garage result has missing, duplicate or unexpected steps')
    demand(all(item['status'] == 'PASS' and 'error' not in item for item in steps),
           'A mandatory original Garage step did not pass')
    evidence = {item['step']: item['evidence'] for item in steps}
    runtime = artifact_root / 'runtime'
    apk = evidence['apk-identity']['actual_apk']
    demand(apk == load_json(original_file(runtime, 'verified-actual-apk.json')),
           'Original actual APK verifier result differs from the Garage result')
    demand(apk['package'] == PACKAGE and apk['versionCode'] == 2015 and
           apk['versionName'] == '0.13.3' and apk['abis'] == ['x86_64'] and
           apk['sha256'] == APK_SHA256 and apk['signingCertificateSha256'] == CERTIFICATE and
           apk['godot']['revision'] == NATIVE_SOURCE and apk['godot']['pck_sha256'] == expected_pck,
           'Original Garage APK package/version/ABI/signature/native PCK mismatch')
    identity = evidence['apk-identity']['provenance']
    demand(identity['apk_sha256'] == APK_SHA256 and identity['flutter_source_commit'] == APP_SOURCE and
           identity['godot_revision'] == NATIVE_SOURCE and identity['godot_pck_sha256'] == expected_pck and
           identity['versionCode'] == 2015 and identity['versionName'] == '0.13.3' and
           identity['signingCertificateSha256'] == CERTIFICATE and set(identity['checks']) == set(IDENTITY_CHECKS) and
           all(value is True for value in identity['checks'].values()), 'Original Garage provenance mismatch')
    races = report['races']
    demand(len(races) == 2 and {race['selected_kart'] for race in races} == set(KARTS),
           'Both original vehicles must start actual separate races')
    by_kart = {race['selected_kart']: race for race in races}
    ids = {kart: state_identity(race, kart, full=False) for kart, race in by_kart.items()}
    demand(len(set(ids.values())) == 2, 'Garage reused one saved race for two selections')
    for kart, short in (('comet', 'comet'), ('gecko_velo', 'gecko')):
        folder = 'phone-' + short
        selected = evidence[folder + '-selection-confirm-start']
        demand(selected['actual_race'] == by_kart[kart], 'Started race differs from recorded selection')
        require_touch(runtime, selected['selection_touch'], KARTS[kart])
        require_capture(runtime, folder, selected['selection_capture'])
        require_frame(selected['hud']['rendered_frame'])
        original_file(runtime, folder + '/' + selected['hud']['capture'] + '.png')
        number(selected['garage_replaced']['changed_fraction'], 'replaced Garage pixels', .22)
        number(selected['garage_replaced']['mean_channel_delta'], 'replaced Garage image delta', 18)
        require_drive(evidence[folder + '-drive'], kart, ids[kart])
    paused = evidence['phone-comet-pause-freeze']
    require_pause(runtime, 'phone-comet/first-pause', paused, 'comet', ids['comet'])
    resumed = evidence['phone-comet-continue-and-drive']
    require_touch(runtime, resumed['touch'], 'Weiterfahren')
    demand(resumed['drive']['start'] == paused['state'], 'Continuation did not start from the observed pause')
    require_drive(resumed['drive'], 'comet', ids['comet'])
    progress, after = resumed['progress'], resumed['drive']['after']
    demand(progress['result_id'] == ids['comet'] and progress['kart'] == 'comet',
           'Continuation belongs to another car or race')
    for metric, field, minimum in (('distance_gain_after_continue', 'distance', 8),
                                    ('elapsed_gain_after_continue', 'elapsed', 2.5)):
        number(progress[metric], metric, minimum)
        demand(math.isclose(progress[metric], after[field] - paused['state'][field], abs_tol=1e-8),
               'Continuation progress does not match the original states')
    returned = evidence['phone-comet-pause-android-back']
    require_pause(runtime, 'phone-comet/second-pause', returned['pause'], 'comet', ids['comet'])
    require_return(runtime, 'phone-comet', returned['return'])
    abandoned = evidence['phone-gecko-abandon']
    require_pause(runtime, 'phone-gecko/abandon-pause', abandoned['pause'], 'gecko_velo', ids['gecko_velo'])
    require_touch(runtime, abandoned['touch'], 'Rennen abbrechen')
    require_return(runtime, 'phone-gecko', abandoned['return'])
    require_navigation(runtime, 'phone-cancel', evidence['phone-garage-cancel-back'])
    for name, (width, height, density) in LAYOUTS.items():
        detail = evidence[name + '-garage-confirm-back']
        screen = detail['screen']
        demand(screen == load_json(original_file(runtime, name + '/actual-native-garage-display.json')),
               'Original Fold display observation differs')
        demand(screen['layout'] == name and screen['requested_portrait_pixels'] == [width, height] and
               screen['requested_density_dpi'] == density and screen['actual_screenshot_pixels'] == [height, width] and
               PACKAGE in screen['foreground'] and 'LumoGameActivity' in screen['foreground'],
               'Actual native Fold Garage or dimensions missing')
        require_capture(runtime, name, screen['screenshot'])
        require_touch(runtime, detail['garage']['touch'], 'Garage')
        demand(detail['garage']['title']['caption'] == 'Dein Kart. Dein Stil.' and
               detail['garage']['title']['observed'], 'Original Fold Garage title missing')
        require_capture(runtime, name, detail['garage']['title']['capture'])
        for kart, key in (('comet', 'comet'), ('gecko_velo', 'gecko')):
            demand(detail[key]['caption'] == KARTS[kart] and detail[key]['observed'],
                   'Original Fold car caption missing')
            require_capture(runtime, name, detail[key]['capture'])
        require_touch(runtime, detail['gecko_touch'], 'Gecko Velo')
        require_navigation(runtime, name, detail['navigation'])
        require_return(runtime, name, detail['returned'])
    preserved = evidence['profile-learning-preserved']
    number(preserved['learning_keys_compared'], 'preserved learning keys', 1)
    demand(preserved['profile']['id'] and preserved['profile']['name'], 'Preserved child profile missing')
    demand(evidence['no-native-crash']['fatal_events'] == [], 'Original Garage detected a fatal crash')
    logs = list(runtime.glob('required-fatal-observation-*.log'))
    demand(len(logs) == 1 and bool(logs[0].read_text().strip()), 'Original required crash observation missing')
    lines = logs[0].read_text().splitlines()
    for index, line in enumerate(lines):
        window = '\n'.join(lines[index:index+6])
        demand(not (('FATAL EXCEPTION' in line or 'Fatal signal' in line) and
                    (PACKAGE in window or 'lumo' in window.lower())), 'Original Garage log contains a fatal crash')
    demand(hashlib.sha256(path.read_bytes()).hexdigest() == original_digest,
           'Original Garage JSON changed during validation')
    return {**binding, 'status': 'PASS', 'apk_source': APP_SOURCE, 'godot_source': NATIVE_SOURCE,
            'apk_sha256': APK_SHA256, 'godot_pck_sha256': expected_pck,
            'original_result_path': 'runtime/garage-result.json',
            'original_result_sha256': original_digest, 'mandatory_steps': list(REQUIRED_STEPS),
            'selected_race_ids': ids, 'fold_layouts': list(LAYOUTS),
            'scope': 'Original existing-APK Garage artifact; no physical-hardware or continuous-physics claim'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--metadata', type=Path, required=True)
    parser.add_argument('--prefix', default='garage')
    parser.add_argument('--compare', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    binding = metadata_directory(args.metadata, args.prefix)
    if args.compare is not None:
        demand(binding == load_json(args.compare), 'Garage run/job/artifact changed before publication')
    args.output.write_text(json.dumps(binding, indent=2) + '\n')
    print(json.dumps(binding))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
