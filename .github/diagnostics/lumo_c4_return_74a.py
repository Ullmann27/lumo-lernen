#!/usr/bin/env python3
"""Observe the repaired C4 return against the unchanged, previously built 74a APK.

This produces diagnostic evidence only. It does not execute or impersonate the
candidate acceptance entry point, and never creates its c4-result.json output.
The app checkout remains 74a; the observer checkout remains 6f42 throughout.
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

APP = '74a0f421a0650308eb7f73ae1c60b6d8ecd2fe0a'
APP_TREE = 'e713855dcfcee73661fb306a22e69b292bd75e75'
OBSERVER = '6f42fa8c0f18ea27dac90d7799ca06a1f9f0614a'
OBSERVER_TREE = '7732acb45cd26887608b001c2ae19040774a7b83'
NATIVE = 'bebf7bba48f09afc834469db0ea3c5541a184f55'
BUILD_RUN = 43582902189
BUILD_JOB = 132412380224
ARTIFACT = 14112410201
ARTIFACT_BYTES = 665175297
ARTIFACT_DIGEST = 'sha256:99d94c2fecb609fa4bf80905ad5b7adf24e7740d664e48ba456836fe73d5532a'
APK_BYTES = 334152162
APK_DIGEST = 'd5d000c5361298e7d05447672459bd0ac515430a8850fc4146cabd628f8e036d'
PCK_BYTES = 75059540
PCK_DIGEST = '2c5b61d932eb93561c5a31ca8bcdb9e01eda8fda432c31fa4633d961a6b8a0a0'
REPOSITORY = 'Ullmann27/lumo-lernen'
BRANCH = 'diagnostic/lumo-c4-return-74a-20261114'
WORKFLOW = '.github/workflows/lumo-c4-return-74a-diagnostic.yml'
DRIVER = '.github/diagnostics/lumo_c4_return_74a.py'
QA_DIFFERENCES = frozenset((
    '.github/probes/lumo_connect_four_android_probe.py',
    '.github/workflows/lumo-connect-four-2020.yml',
    'tools/android_qa/tests/test_connect_four_probe_deadlines.py',
    'tools/android_qa/tests/test_connect_four_flutter_navigation.py',
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
    # The observer commit is a direct child of APP. Compare the complete trees,
    # without narrowing the diff to presumed product directories.
    require(git(qa, 'rev-parse', OBSERVER + '^') == APP, 'Unexpected observer parent')
    differences = git(qa, 'diff', '--no-ext-diff', '--no-renames', '--name-only', APP, OBSERVER).splitlines()
    require(set(differences) == QA_DIFFERENCES and len(differences) == 4,
            'The complete trees differ outside the four reviewed QA files')
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
    require(module.ROOT.resolve() == qa, 'Observer ROOT must remain its real 6f42 checkout')
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


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('app-source', 'qa-source', 'apk', 'provenance', 'sums', 'metadata', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    for key, value in vars(args).items():
        setattr(args, key, value.resolve())
    args.out.mkdir(parents=True, exist_ok=True)
    result = {'status':'FAIL', 'diagnostic_only':True, 'eligible_for_candidate_acceptance':False,
              'apk_source':APP, 'observer_source':OBSERVER, 'native_source':NATIVE,
              'scope':'Real API35 return/reopen diagnosis of the old 74a APK; no new candidate, release or FPS claim'}
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
