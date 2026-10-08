#!/usr/bin/env python3
"""Verify preserved runtime evidence before rebuilding the exact clean source.

This does not turn the original failed build into a successful build. The
workflow separately checks the original GitHub run, step and artifact identity.
Here every downloaded evidence file is hashed and its substantive logs checked.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct

APP_SOURCE = '22b221b2ebe5c85562f359e471c8ca2d44ee8354'
GODOT_SOURCE = '9f17cd2f7af652917a0c1290e506e1211a08fb3f'
ORIGINAL_RUN = 37797365941
DIRTY_CAPTURE = '.ci-results/onboarding-visual/age-360x800.png'
BUILD_REJECTION = 'Build rejected: tracked source differs from the candidate commit.'
ENGINE_ERRORS = re.compile(r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed')
ANSI = re.compile(r'\x1b\[[0-?]*[ -/]*[@-~]')
NATIVE_MARKERS = {
    'kart_pause_layout_regression.log': ('[KartPauseLayoutTests] PASS:',),
    'kart_fold_controls_regression.log': ('[KartFoldControls] PASS:',),
    'kart_menu_flow_regression.log': ('[KartMenuFlow] PASS:',),
    'kart_physics_regression.log': ('[KartPhysics] PASS:',),
    'kart_fleet_regression.log': ('[KartFleet] PASS:',),
    'kart_video_visual_regression.log': (
        '[KartVideoGrade] PASS: complete rendered kart bounds',
        '[KartVideoGrade] PASS: close chase framing',
    ),
    'kart_reference_capture.log': ('[ReferenceCapture] PASS:',),
    'kart_driven_capture.log': ('[DrivenCapture] PASS:',),
    'kart_steering_grip_regression.log': ('[KartSteeringGrip] PASS:',),
    'kart_arm_contact_regression.log': ('[KartArmContact] PASS:',),
    'kart_steering_grip_capture.log': ('[KartSteeringGripCapture] PASS:',),
    'kart_race_continuity_regression.log': ('[KartContinuity] PASS:',),
    'kart_complete_flow_regression.log': ('[KartCompleteFlow] PASS:',),
    'kart_harbor_regression.log': ('[KartHarbor] PASS:',),
    'kart_vehicle_regression.log': (
        '[KartVehicle] Geometry/colours, shadows, animations, effects, LOD and hysteresis passed',
    ),
    'kart_vehicle_detail_regression.log': ('[KartDetails] PASS:',),
    'fleet-capture.log': ('[FleetCapture] PASS:',),
    'harbor-capture.log': ('[KartHarbor] PASS:',),
    'visual.log': ('[KartVisualQuality] PASS:',),
}
NATIVE_PNG_COUNTS = {
    'fleet-proof': 52, 'reference-design': 19, 'fold-controls': 11,
    'holographic-proof': 9, 'video-reference-grade': 9, 'steering-grip': 5,
    'complete-flow': 5, 'harbor-proof': 3,
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read(directory, name):
    path = directory / name
    require(path.is_file() and not path.is_symlink(), f'Missing regular evidence file: {path}')
    return ANSI.sub('', path.read_text())


def flutter_summary(text, name, expected, skipped=0):
    require('Some tests failed.' not in text, f'Failed Flutter suite: {name}')
    matches = re.findall(r'\+(\d+)(?:\s+~(\d+))?: All tests passed!', text)
    require(len(matches) == 1, f'Missing or ambiguous Flutter success summary: {name}')
    count, ignored = (int(matches[0][0]), int(matches[0][1] or 0))
    require((count, ignored) == (expected, skipped), f'Unexpected Flutter test counts: {name}')
    return {'passed': count, 'skipped': ignored}


def python_summary(text, name, expected, skipped=0):
    require(not re.search(r'^FAILED\b', text, re.MULTILINE), f'Failed Python suite: {name}')
    counts = re.findall(r'^Ran (\d+) tests? in ', text, re.MULTILINE)
    summaries = re.findall(r'^OK(?: \(skipped=(\d+)\))?$', text, re.MULTILINE)
    require(len(counts) == len(summaries) == 1, f'Missing or ambiguous Python summary: {name}')
    count, ignored = int(counts[0]), int(summaries[0] or 0)
    require((count, ignored) == (expected, skipped), f'Unexpected Python test counts: {name}')
    return {'ran': count, 'passed': count - ignored, 'skipped': ignored}


def inventory(directory):
    files = []
    for path in sorted(directory.rglob('*')):
        require(not path.is_symlink(), f'Symlink is not preserved evidence: {path}')
        if not path.is_file():
            continue
        with path.open('rb') as stream:
            sha = hashlib.file_digest(stream, 'sha256').hexdigest()
        row = {'path': path.relative_to(directory).as_posix(), 'bytes': path.stat().st_size, 'sha256': sha}
        if path.suffix == '.png':
            with path.open('rb') as stream:
                header = stream.read(24)
            require(header[:8] == b'\x89PNG\r\n\x1a\n' and header[12:16] == b'IHDR', f'Invalid PNG header: {path}')
            width, height = struct.unpack('>II', header[16:24])
            require(width > 0 and height > 0, f'Empty PNG dimensions: {path}')
            row['dimensions'] = [width, height]
        files.append(row)
    require(files, f'Empty evidence directory: {directory}')
    return files


def verify_preserved_source(app, native, failed_build):
    app, native, failed_build = map(Path, (app, native, failed_build))
    require(read(app, 'source-sha.txt').strip() == APP_SOURCE, 'Stale Flutter source evidence')
    require(read(native, 'fold-controls/source-sha.txt').strip() == GODOT_SOURCE, 'Stale Godot source evidence')
    require(read(failed_build, 'source-sha.txt').strip() == APP_SOURCE, 'Stale failed-build source evidence')
    rejection = read(failed_build, 'build.log').strip().splitlines()
    require(rejection == [BUILD_REJECTION, 'M\t' + DIRTY_CAPTURE],
            'Original build failed for an unapproved reason or additional dirty path')
    results = read(app, 'TEST-RESULTS.txt')
    for marker in ('Flutter source: ' + APP_SOURCE, 'PASS Flutter source analysis (no errors)',
                   'PASS full Flutter regression suite', 'PASS native preparation Python tests'):
        require(marker in results, f'Missing preserved app result: {marker}')
    analysis = read(app, 'analysis.log')
    require(not re.search(r'^\s*error\s+[•-]', analysis, re.MULTILINE), 'Flutter analysis contains source errors')
    require(re.search(r'(?:\d+ issues found\.|No issues found!)', analysis), 'Missing Flutter analysis completion')
    read(app, 'dependencies.log')
    counts = {
        'flutter': flutter_summary(read(app, 'flutter-tests.log'), 'flutter', 750, 4),
        'launcher_green': flutter_summary(read(app, 'launcher-candidate-green.log'), 'launcher', 15),
        'photo_lesson_green': flutter_summary(read(app, 'photo-lesson-candidate-green.log'), 'photo lesson', 12),
        'native_preparation': python_summary(read(app, 'native-preparation.log'), 'native preparation', 9),
        'android_harness': python_summary(read(app, 'android-harness-tests.log'), 'Android harness', 204, 8),
    }
    launcher_red = read(app, 'launcher-base-red.log')
    for marker in ('A profile changed while lifetime-wallet storage was pending.',
                   'Expected: false', 'Some tests failed.'):
        require(marker in launcher_red, f'Missing expected launcher base RED: {marker}')
    require(re.search(r'Actual:.*true', launcher_red), 'Launcher base RED lacks the stale launch')
    photo_red = read(app, 'photo-lesson-base-red.log')
    for subject in ('Deutsch', 'Englisch', 'Sachunterricht'):
        require(f'Photo lesson must keep recognized subject {subject} and topic.' in photo_red,
                f'Missing expected photo lesson base RED: {subject}')
    require('Some tests failed.' in photo_red, 'Photo lesson base did not fail')
    backend = read(app, 'backend.log')
    for marker in ('# tests 22', '# pass 22', '# fail 0'):
        require(re.search(r'^' + re.escape(marker) + '$', backend, re.MULTILINE), f'Missing backend summary: {marker}')
    counts['backend'] = {'passed': 22, 'failed': 0}
    content = read(app, 'content.log')
    require('Checked 40960 generated tasks' in content and 'PASS: exact answers' in content,
            'Missing complete learning-content audit')
    counts['learning_content'] = {'generated_tasks': 40960}
    guard = read(app, 'repair-guard.log')
    require('Zero-Defect Repair Guard finished.' in guard, 'Repair guard did not finish')
    require(not re.search(r'^\s*error\s+[•-]', guard, re.MULTILINE), 'Repair guard reports source errors')
    for name, markers in NATIVE_MARKERS.items():
        text = read(native, 'fold-controls/' + name)
        require(not ENGINE_ERRORS.search(text), f'Strict engine failure in {name}')
        require('[ProbeRunner] FAIL' not in text, f'Probe wrapper failed in {name}')
        for marker in markers:
            require(marker in text, f'Missing final runtime marker in {name}: {marker}')
        require('Godot Engine v4.6.3.stable.official.' in text, f'Wrong engine in {name}')
    imported = read(native, 'fold-controls/import.log')
    require(not re.search(r'SCRIPT ERROR|Parse Error|Failed to load|ERROR:', imported), 'Strict native import failed')
    require('Godot Engine v4.6.3.stable.official.' in imported, 'Wrong native import engine')
    evidence = json.loads(read(native, 'complete-flow/evidence.json'))
    require(evidence['save_reopen_resume'] is True, 'Saved runtime did not resume')
    require([row['gate'] for row in evidence['ordered_gates']] == list(range(1, 17)), 'Incomplete ordered race gates')
    require(evidence['result']['status'] == 'completed' and evidence['result']['checkpoints'] == 16,
            'Missing complete race result')
    inventories = {'app': inventory(app), 'native': inventory(native), 'failed_build': inventory(failed_build)}
    app_pngs = [row for row in inventories['app'] if row['path'].endswith('.png')]
    require(len(app_pngs) == 26, 'Incomplete preserved app screenshot set')
    for folder, expected in NATIVE_PNG_COUNTS.items():
        actual = sum(row['path'].startswith(folder + '/') and row['path'].endswith('.png')
                     for row in inventories['native'])
        require(actual == expected, f'Incomplete native screenshot set: {folder}')
    glbs = [row for row in inventories['native'] if row['path'].startswith('fleet-models/') and row['path'].endswith('.glb')]
    require(len(glbs) == 9, 'Incomplete authored Kart GLB set')
    return {
        'status': 'PASS', 'scope': 'Preserved pre-build runtime verification; original APK build remains FAIL',
        'original_run_id': ORIGINAL_RUN, 'flutter_source_commit': APP_SOURCE, 'godot_source_commit': GODOT_SOURCE,
        'version': '0.12.1+1902', 'test_counts': counts, 'strict_native_probes': len(NATIVE_MARKERS),
        'strict_import_checked': True, 'expected_base_regressions_retained': True,
        'known_failed_build': {'status': 'FAIL', 'reason': BUILD_REJECTION, 'dirty_paths': [DIRTY_CAPTURE]},
        'app_png_count': len(app_pngs), 'native_png_count': sum(NATIVE_PNG_COUNTS.values()),
        'kart_glb_count': len(glbs), 'files': inventories,
        'original_run_identity': 'Checked separately by workflow through GitHub run/job/step/artifact metadata',
        'new_apk_build': 'NOT EXECUTED by this evidence helper', 'physical_device_performance': 'NOT EXECUTED',
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, required=True)
    parser.add_argument('--native', type=Path, required=True)
    parser.add_argument('--failed-build', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    for directory in (args.app, args.native, args.failed_build):
        require(not output.is_relative_to(directory.resolve()), 'Output must remain outside original evidence')
    result = verify_preserved_source(args.app, args.native, args.failed_build)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2) + '\n')
    print(f"PASS preserved exact source: {APP_SOURCE}; native {GODOT_SOURCE}; {len(NATIVE_MARKERS)} strict probes")


if __name__ == '__main__':
    main()
