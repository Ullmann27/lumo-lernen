#!/usr/bin/env python3
"""Observe bounded C4 preferences/return checks on the previously built unchanged 51ec APK.

This produces diagnostic evidence only. It does not execute or impersonate the
candidate acceptance entry point, and never creates its c4-result.json output.
The app and reviewed observer remain in distinct immutable checkouts throughout.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import traceback
from types import SimpleNamespace
import zipfile

APP = '51ec0ac43f3e2aaac065e285e13cf5db5b5875d2'
APP_TREE = 'e922f8d01fe31b07ac3c5cb196451dcbedb269d0'
OBSERVER = '9deaa3f24561bc65caba898585c0c00f1c77162b'
OBSERVER_PARENT = '7c5bef2bc39024fc2c1018523cabc651820cf76b'
OBSERVER_TREE = 'c0a9e29c831113ea8e49e632bc7959a15079bc94'
NATIVE = 'bebf7bba48f09afc834469db0ea3c5541a184f55'
BUILD_RUN = 43605863655
BUILD_JOB = 132481353900
ARTIFACT = 14120856158
ARTIFACT_BYTES = 665175297
ARTIFACT_DIGEST = 'sha256:12b60eb2013536065808892c4f82e6682a495f291e9b6d71c5dc4dadcfea0071'
APK_BYTES = 334152162
APK_DIGEST = '70dcdf23005390ed5f3b8b4ffe92f987801ecf45dba1a51344a091e2ef6ffd9c'
PCK_BYTES = 75059540
PCK_DIGEST = '80d83d9baf67344f56ac235a38d3e829f112740eeb2520ece50afb6d81479787'
REPOSITORY = 'Ullmann27/lumo-lernen'
BRANCH = 'diagnostic/lumo-c4-return-51ec-20261114'
WORKFLOW = '.github/workflows/lumo-c4-return-51ec-diagnostic.yml'
DRIVER = '.github/diagnostics/lumo_c4_return_51ec.py'
QA_DIFFERENCES = frozenset((
    '.github/probes/lumo_connect_four_android_probe.py',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0392-return-final-second-000-state.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0392-return-final-second-000-state.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0392-return-final-second-000-state.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0400-return-final-second-000-preferences.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0400-return-final-second-000-preferences.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0400-return-final-second-000-preferences.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0404-return-final-touch.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0404-return-final-touch.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0404-return-final-touch.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0405-return-final-native-exit.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0405-return-final-native-exit.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0405-return-final-native-exit.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0406-return-final-return-activity.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0406-return-final-return-activity.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0406-return-final-return-activity.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0407-return-final-native-exit.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0407-return-final-native-exit.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0407-return-final-native-exit.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0408-return-final-return-activity.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0408-return-final-return-activity.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0408-return-final-return-activity.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0409-return-final-closed-mailbox.json',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0409-return-final-closed-mailbox.stderr',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/0409-return-final-closed-mailbox.stdout',
    'tools/android_qa/tests/fixtures/c4-final-return-7c5/source.json',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/0074-child-first-second-000-preferences.json',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/0074-child-first-second-000-preferences.stderr',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/0074-child-first-second-000-preferences.stdout',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/0087-child-first-confirmed-000-preferences.json',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/0087-child-first-confirmed-000-preferences.stderr',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/0087-child-first-confirmed-000-preferences.stdout',
    'tools/android_qa/tests/fixtures/c4-preferences-read-51ec/source.json',
    'tools/android_qa/tests/test_connect_four_preferences_observation.py',
    'tools/android_qa/tests/test_connect_four_return_observation.py',
))

def require(condition, message):
    if not condition:
        raise ValueError(message)


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def git(root, *arguments):
    return subprocess.check_output(['git', '-C', str(root), *arguments], text=True).strip()


def source(root, revision, tree):
    require(root.is_dir() and not root.is_symlink(), 'Expected an independent source checkout')
    require(Path(git(root, 'rev-parse', '--show-toplevel')).resolve() == root,
            'Source is not its own Git checkout root')
    require(git(root, 'rev-parse', 'HEAD') == revision
            and git(root, 'rev-parse', 'HEAD^{tree}') == tree, 'Actual source identity differs')
    require(not git(root, 'status', '--porcelain', '--untracked-files=no'), 'Tracked source changed')
    return {'commit':revision, 'tree':tree, 'tracked_source_clean':True}


def compare_sources(app, qa):
    checked = {'app':source(app, APP, APP_TREE), 'observer':source(qa, OBSERVER, OBSERVER_TREE)}
    require(app != qa, 'App and observer require distinct unchanged checkouts')
    # Verify both complete parent lists and compare the complete trees.
    # No merge parent or presumed-product-directory filter is accepted.
    require(git(qa, 'show', '-s', '--format=%P', OBSERVER).split() == [OBSERVER_PARENT],
            'Unexpected complete observer parent list')
    require(git(qa, 'show', '-s', '--format=%P', OBSERVER_PARENT).split() == [APP],
            'Unexpected complete intermediate parent list')
    checked['observer_ancestry'] = [OBSERVER, OBSERVER_PARENT, APP]
    differences = git(qa, 'diff', '--no-ext-diff', '--no-renames', '--name-only', APP, OBSERVER).splitlines()
    require(set(differences) == QA_DIFFERENCES and len(differences) == len(QA_DIFFERENCES),
            'The complete trees differ outside the 35 reviewed QA and original-fixture files')
    checked['complete_tree_differences'] = differences
    checked['product_bytes_unchanged'] = True
    return checked


def load_observer(qa):
    sys.path.insert(0, str(qa / '.github/probes'))
    sys.path.insert(0, str(qa / 'tools/android_qa'))
    spec = importlib.util.spec_from_file_location('reviewed_c4_observer',
        qa / '.github/probes/lumo_connect_four_android_probe.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    require(module.ROOT.resolve() == qa, 'Observer ROOT must remain its real reviewed source checkout')
    require(Path(module.contract.__file__).resolve() == qa / 'tools/android_qa/connect_four_android_evidence.py',
            'Observer contract was imported from a different source')
    return module


def diagnostic_identity(metadata):
    run = read(metadata / 'diagnostic-run.json')
    driver = read(metadata / 'driver-source.json')
    actual = Path(__file__).read_bytes()
    require(run.get('repository', {}).get('full_name') == REPOSITORY
            and run.get('id') == int(os.environ['GITHUB_RUN_ID'])
            and run.get('run_attempt') == int(os.environ['GITHUB_RUN_ATTEMPT'])
            and run.get('head_sha') == os.environ['GITHUB_SHA']
            and run.get('head_branch') == BRANCH
            and run.get('event') == 'push' and run.get('path') == WORKFLOW,
            'This is not the separate, explicitly diagnostic workflow/source')
    require(driver.get('type') == 'file' and driver.get('path') == DRIVER
            and driver.get('encoding') == 'base64'
            and base64.b64decode(driver['content']) == actual
            and driver.get('sha') == hashlib.sha1(b'blob ' + str(len(actual)).encode() + b'\0' + actual).hexdigest(),
            'Executing driver differs from its original GitHub source response')
    require('/blob/' + run['head_sha'] + '/' + DRIVER in driver.get('html_url', ''),
            'Driver response is not bound to this diagnostic commit')
    return {'source':run['head_sha'], 'run_id':run['id'], 'run_attempt':run['run_attempt'],
            'workflow':WORKFLOW, 'driver_blob':driver['sha'],
            'driver_sha256':hashlib.sha256(actual).hexdigest()}


def bind(args, observer):
    sources = compare_sources(args.app_source, args.qa_source)
    run, artifacts, jobs = (read(args.metadata / (name + '.json')) for name in ('run', 'artifacts', 'jobs'))
    for value, key in ((artifacts, 'artifacts'), (jobs, 'jobs')):
        require(value.get('total_count') == len(value.get(key, [])), 'Incomplete original API response')
    binding = observer.contract.artifact_binding(run, artifacts, jobs, source=APP,
        run_id=BUILD_RUN, attempt=1, artifact_id=ARTIFACT, digest=ARTIFACT_DIGEST,
        native=NATIVE, version_name='0.13.8')
    build = [job for job in jobs['jobs'] if job.get('name') == 'verify-and-build']
    require(len(build) == 1 and build[0].get('id') == BUILD_JOB, 'Original successful build job differs')
    artifact = [row for row in artifacts['artifacts'] if row.get('id') == ARTIFACT]
    require(len(artifact) == 1 and artifact[0].get('size_in_bytes') == ARTIFACT_BYTES,
            'Original candidate artifact size differs')
    require(args.apk.is_file() and not args.apk.is_symlink()
            and args.apk.stat().st_size == APK_BYTES and digest(args.apk) == APK_DIGEST,
            'Actual old APK bytes differ')
    with zipfile.ZipFile(args.apk) as archive:
        members = [info for info in archive.infolist() if info.filename == 'assets/lumo_game.pck']
        require(len(members) == 1 and members[0].file_size == PCK_BYTES, 'Embedded native package size differs')
        with archive.open(members[0]) as stream:
            require(hashlib.file_digest(stream, 'sha256').hexdigest() == PCK_DIGEST,
                    'Embedded native package hash differs')
    import modernization_android_tour as main_tour
    require(Path(main_tour.__file__).resolve() == args.qa_source / '.github/probes/modernization_android_tour.py',
            'Main-tour verifier was imported from a different checkout')
    # The existing verifier explicitly inspects cwd. Keep that cwd at the real
    # old app source; the observer module's ROOT remains the separate new source.
    require(Path.cwd() == args.app_source, 'APK identity requires the actual old app checkout as cwd')
    identity = main_tour.verify_apk_identity(args.apk, args.provenance, args.sums)
    require(identity['flutter_source_commit'] == APP and identity['godot_revision'] == NATIVE
            and identity['apk_sha256'] == APK_DIGEST and identity['godot_pck_sha256'] == PCK_DIGEST
            and identity['versionCode'] == 2020, 'Existing APK identity verifier returned a different source')
    return {'diagnostic_only':True, 'eligible_for_candidate_acceptance':False,
            'sources':sources, 'diagnostic':diagnostic_identity(args.metadata),
            'original_candidate':binding, 'apk':identity,
            'certificate_scope':'Original verified signer bound by the exact unchanged APK hash'}


def observe_return(value, result, c4):
    """Use the committed observer's real input, native and persistence methods."""
    result['root_readiness'] = value.ui.ensure_rooted_emulator(value.base.adb, value.out)
    api, api_file = value.original('sdk', 'shell', 'getprop', 'ro.build.version.sdk')
    c4.demand(api.strip() == '35', 'This diagnostic requires the same actual API35 device class')
    result['android_sdk_original'] = api_file
    value.base.launch(value.out, 'c4-start')
    value.ui.device_rotation(value.out, 'c4-responsive-portrait', 0)
    c4.demand(value.main.try_tap(value.out, ['Spielen', 'Spiele'], 'c4-games') is not None,
              'Actual games navigation is unavailable')
    before_prefs, result['preferences_before'] = value.read_preferences('before-c4')
    result['entry_touch'] = value.flutter_touch(c4.PORTAL, 'open-c4')
    initial = value.wait_observation('initial', lambda item:not item['state']['paused'] and item['state']['canDrop'])
    c4.demand(initial['state']['columns'] == [] and not initial['state']['twoPlayers'],
              'Initial actual C4 round is not the untouched single-player game')
    result['initial'] = initial['id']
    value.transition('child-first', 'drop', 'column_3')
    paused = value.transition('pause-first', 'pause', 'pause')
    time.sleep(min(1.2, value.remaining()))
    held = value.wait_observation('pause-held', lambda item:item['state']['paused'])
    c4.paused_unchanged(paused, held, held['observed_monotonic'] - paused['observed_monotonic'])
    result['pause_hold'] = {'first':paused['id'], 'second':held['id'],
                            'elapsed':held['observed_monotonic'] - paused['observed_monotonic']}
    value.transition('resume-first', 'resume', 'resume')
    value.transition('child-second', 'drop', 'column_2')
    value.transition('pause-before-return', 'pause', 'pause')
    closed = value.return_to_flutter('return-first')
    old_token = value.token
    value.mailbox, value.token = '', ''
    reopen_touch = value.flutter_touch(c4.PORTAL, 'reopen-c4')
    again = value.wait_observation('reopened', lambda item:not item['state']['paused'] and item['state']['canDrop'])
    c4.reopened(closed['state'], again['state'])
    c4.demand(again['state']['token'] != old_token and again['pid'] != closed['pid'],
              'Reopen did not create a new actual private session/process')
    result['reopen'] = {'closed':closed['id'], 'opened':again['id'], 'touch':reopen_touch}
    value.transition('pause-after-reopen', 'pause', 'pause')
    value.return_to_flutter('return-final')
    after_prefs, result['preferences_after'] = value.read_preferences('after-c4')
    c4.learning_unchanged(before_prefs, after_prefs)


def snapshot_live_xvfb(source_path, out):
    """Preserve an immutable observed prefix; the live log stays outside the inventory."""
    require(source_path.is_file() and not source_path.is_symlink(),
            'Expected the actual separate live Xvfb log')
    require(not source_path.is_relative_to(out), 'Live Xvfb output cannot remain inside the evidence inventory')
    with source_path.open('rb') as stream:
        before = os.fstat(stream.fileno())
        observed_unix_ns = time.time_ns()
        observed_monotonic = time.monotonic()
        raw = stream.read(before.st_size)
        after = os.fstat(stream.fileno())
    require(len(raw) == before.st_size and after.st_size >= before.st_size,
            'The live log was truncated during its prefix snapshot')
    path = out / 'runtime-snapshots' / 'xvfb-final-prefix.log'
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as stream:
        stream.write(raw)
    value = hashlib.sha256(raw).hexdigest()
    require(path.stat().st_size == len(raw) and digest(path) == value,
            'The written immutable Xvfb snapshot differs')
    return {'source_path':'live-logs/xvfb.log',
            'snapshot_path':str(path.relative_to(out)),
            'source_bytes_at_open':before.st_size, 'source_bytes_after_read':after.st_size,
            'snapshot_bytes':len(raw), 'snapshot_sha256':value,
            'observed_unix_ns':observed_unix_ns, 'observed_monotonic':observed_monotonic,
            'point':'After the final C4/logcat capture and before the complete evidence inventory',
            'scope':'Exact observed prefix; the separately uploaded live end log may contain later bytes'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('app-source', 'qa-source', 'apk', 'provenance', 'sums', 'metadata', 'out', 'live-xvfb-log'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    for key, value in vars(args).items():
        setattr(args, key, value.resolve())
    args.out.mkdir(parents=True, exist_ok=True)
    result = {'status':'FAIL', 'diagnostic_only':True, 'eligible_for_candidate_acceptance':False,
              'apk_source':APP, 'observer_source':OBSERVER, 'native_source':NATIVE,
              'scope':'Real API35 main-tour and C4 preferences/return/reopen diagnosis of the unchanged 51ec APK; no new candidate, release or FPS claim'}
    probe = None
    observer = None
    try:
        os.chdir(args.app_source)
        observer = load_observer(args.qa_source)
        result['binding'] = bind(args, observer)
        write(args.out / 'diagnostic-binding.json', result['binding'])
        main_out = args.out / 'main'
        started = time.monotonic()
        tour = subprocess.run([sys.executable, '-B',
            str(args.qa_source / '.github/probes/modernization_android_tour.py'),
            '--apk', str(args.apk), '--provenance', str(args.provenance),
            '--sums', str(args.sums), '--out', str(main_out)], cwd=args.app_source,
            timeout=1500, check=False)
        result['main_tour_process'] = {'returncode':tour.returncode,
                                      'elapsed_seconds':time.monotonic() - started}
        require(tour.returncode == 0, 'The actual complete main tour failed')
        prior_path = main_out / 'tour-result.json'
        prior = read(prior_path)
        import modernization_android_tour as main_tour
        require(prior.get('status') == 'PASS' and prior.get('apk_sha256') == APK_DIGEST
                and prior.get('fatal_crashes') == 0
                and all(any(step.get('step') == name and step.get('ok') is True
                            for step in prior.get('steps', [])) for name in main_tour.HARD_STEPS),
                'The complete original main-tour requirements did not pass')
        result['prior_tour'] = {'path':'main/tour-result.json', 'sha256':digest(prior_path)}
        probe = observer.Probe(SimpleNamespace(out=args.out / 'c4'))
        observe_return(probe, result, observer.contract)
        compare_sources(args.app_source, args.qa_source)
        probe.remaining()
        result['status'] = 'PASS'
    except Exception as error:
        result.update(error=f'{type(error).__name__}: {error}', traceback=traceback.format_exc())
    finally:
        if probe is not None:
            try:
                raw, original = probe.original('final-all-buffer-logcat', 'logcat', '-b', 'all', '-d', '-v',
                                               'threadtime', bound=256 * 1024 * 1024)
                errors = observer.contract.runtime_errors(raw)
                result.update(original_logcat='c4/' + original, fatal_entries=errors)
                if errors:
                    result.update(status='FAIL', error='Actual engine/Android failure in original all-buffer logcat')
            except Exception as error:
                result.update(status='FAIL', final_log_error=f'{type(error).__name__}: {error}')
            probe.base.command = probe.old_command
            result.update(observations=[item['id'] for item in probe.observations],
                          transitions=probe.transitions, returns=probe.returns)
        try:
            result['live_log_snapshot'] = snapshot_live_xvfb(args.live_xvfb_log, args.out)
        except Exception as error:
            result.update(status='FAIL', live_log_snapshot_error=f'{type(error).__name__}: {error}')
        originals = []
        for path in sorted(args.out.rglob('*')):
            if path.is_file():
                require(not path.is_symlink(), 'Diagnostic evidence cannot contain symlinks')
                originals.append({'path':str(path.relative_to(args.out)), 'bytes':path.stat().st_size,
                                  'sha256':digest(path)})
        result['originals'] = originals
        write(args.out / 'diagnostic-result.json', result)
        print('[C4ReturnDiagnostic]', json.dumps({'status':result['status'],
            'diagnostic_only':True, 'apk_source':APP, 'observer_source':OBSERVER,
            'eligible_for_candidate_acceptance':False, 'error':result.get('error')}), flush=True)
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
