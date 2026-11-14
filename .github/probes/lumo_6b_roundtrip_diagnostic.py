#!/usr/bin/env python3
"""Exercise the unchanged 6b APK using an explicitly distinct diagnostic observer.

The production probes remain strict about one source identity. This separate
diagnostic reuses their complete journeys, with explicit APK and QA identities.
Its reports cannot replace the seven-job exact-source release acceptance.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys
import time
import traceback

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools/android_qa"))
sys.path.insert(0, str(ROOT / "scripts"))
from lumo_village_android_probe import VillageProbe
from lumo_connect_four_android_probe import Probe, write
import connect_four_android_evidence as c4
import village_android_evidence as village
import verify_unchanged_6b_village_diagnostic as diagnostic
contract = c4


def require_bound_diagnostic(args) -> dict:
    binding = diagnostic.read_json(args.diagnostic_binding)
    expected = {
        "expected_source": diagnostic.HOST,
        "expected_native": diagnostic.NATIVE,
        "build_run": diagnostic.BUILD_RUN,
        "run_attempt": diagnostic.BUILD_ATTEMPT,
        "artifact_id": diagnostic.ARTIFACT_ID,
        "artifact_digest": diagnostic.ARTIFACT_DIGEST,
    }
    for key, value in expected.items():
        actual = getattr(args, key)
        diagnostic.require(type(actual) is type(value) and actual == value,
                           "Diagnostic argument differs from the actual original APK: " + key)
    diagnostic.require(binding.get("status") == "BOUND"
                       and binding.get("diagnostic_qa", {}).get("source") == args.expected_qa_source
                       and args.expected_qa_source != diagnostic.HOST
                       and binding.get("candidate_build", {}).get("host_source") == diagnostic.HOST
                       and binding.get("candidate_build", {}).get("run_id") == diagnostic.BUILD_RUN
                       and binding.get("candidate_build", {}).get("artifact_id") == diagnostic.ARTIFACT_ID,
                       "Missing explicit separate QA and original APK binding")
    sources = binding["git_sources"]
    diagnostic.require(sources["qa"]["commit"] == args.expected_qa_source
                       and sources["candidate"]["commit"] == diagnostic.HOST,
                       "Diagnostic source receipts differ")
    diagnostic.source_identity(ROOT, args.expected_qa_source, sources["qa"]["tree"])
    candidate = Path(sources["candidate"]["path"])
    diagnostic.source_identity(candidate, diagnostic.HOST, diagnostic.HOST_TREE)
    diagnostic.require(Path.cwd().resolve() == candidate.resolve(),
                       "Run APK checks from the unchanged original candidate checkout")
    for entry in binding["source_files"]["qa"]:
        diagnostic.require(diagnostic.committed_file(ROOT, entry["path"]) == entry,
                           "Diagnostic observer changed since its original preflight")
    apk = diagnostic.regular(args.apk)
    diagnostic.require(apk.stat().st_size == diagnostic.APK_BYTES
                       and diagnostic.file_digest(apk) == diagnostic.APK_SHA256,
                       "Original APK changed before diagnostic journey")
    return {
        "qa_source": args.expected_qa_source,
        "apk_source": diagnostic.HOST,
        "apk_sha256": diagnostic.APK_SHA256,
        "binding_sha256": diagnostic.file_digest(args.diagnostic_binding),
        "seven_job_acceptance": False,
        "scope": "Actual unchanged-APK diagnostic, separate QA source; no publication approval",
    }


def _village_run(self):
    result = {'schema': 1, 'status': 'FAIL',
              'scope': 'Diagnostic actual 6b APK Village roundtrip with separately bound QA; no seven-job acceptance'}
    try:
        result['diagnostic_binding'] = require_bound_diagnostic(self.args)
        source = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
        sys.path.insert(0, str(ROOT/'scripts'))
        from verify_legacy_release_pin import verify as verify_pin
        build, native = verify_pin((ROOT/'pubspec.yaml').read_text(), (ROOT/'config/godot-source.json').read_text())
        c4.demand(build == 2020 and source == self.args.expected_qa_source
                  and native == self.args.expected_native, 'Actual Village QA source/native pin differs')
        subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=ROOT, check=True)
        identity = self.main.verify_apk_identity(self.args.apk, self.args.provenance, self.args.sums)
        c4.demand(identity['versionCode'] == 2020 and identity['godot_revision'] == native
                  and identity['flutter_source_commit'] == self.args.expected_source,
                  'Wrong actual Village candidate identity')
        result['identity'] = identity
        metadata = [json.loads((self.args.metadata_dir/(name+'.json')).read_text())
                    for name in ('run', 'artifacts', 'jobs')]
        result['binding'] = c4.artifact_binding(*metadata, source=self.args.expected_source,
            run_id=self.args.build_run, attempt=self.args.run_attempt,
            artifact_id=self.args.artifact_id, digest=self.args.artifact_digest,
            native=native, version_name=identity['versionName'])
        prior = json.loads(self.args.prior_tour.read_text())
        c4.demand(prior.get('status') == 'PASS' and prior.get('apk_sha256') == identity['apk_sha256']
                  and prior.get('fatal_crashes') == 0
                  and all(any(s.get('step') == name and s.get('ok') is True
                              for s in prior.get('steps', [])) for name in self.main.HARD_STEPS),
                  'The unchanged complete main Android tour must pass before Village')
        result['prior_tour'] = {'path': str(self.args.prior_tour), 'sha256': c4.sha256(self.args.prior_tour)}
        result['root_readiness'] = self.ui.ensure_rooted_emulator(self.base.adb, self.out)
        api, result['android_sdk_original'] = self.original('village-sdk', 'shell', 'getprop', 'ro.build.version.sdk')
        c4.demand(api.strip() == '35', 'Village Android proof requires the actual API35 device')
        self.await_processes('initial-flutter', native=False)
        self.ui.device_rotation(self.out, 'village-responsive-portrait', 0)
        c4.demand(self.main.try_tap(self.out, ['Spielen', 'Spiele'], 'village-games') is not None,
                  'Actual Flutter Spielewelt navigation is unavailable')
        result['before'] = self.await_processes('before-village', native=False)
        _, result['before']['preferences'] = self.read_preferences('before-village')
        result['entry_touch'] = self.flutter_touch(village.PORTAL, 'open-village')
        result['native'] = self.observe_village()
        _, pid = village.process(self.out, result['native'], native=True)
        result['returned'] = self.visible_return(pid)
        subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=ROOT, check=True)
        result['status'] = 'PASS'
    except Exception as error:
        result.update(error=f'{type(error).__name__}: {error}', traceback=traceback.format_exc())
    finally:
        try:
            raw, result['original_logcat'] = self.original('village-final-all-buffer-logcat',
                'logcat', '-b', 'all', '-d', '-v', 'threadtime', bound=256*1024*1024)
            result['fatal_entries'] = c4.runtime_errors(raw)
            if result['fatal_entries']:
                result.update(status='FAIL', error='Actual Android/engine failure in original Village logcat')
        except Exception as error:
            result.update(status='FAIL', final_log_error=f'{type(error).__name__}: {error}')
        self.base.command = self.old_command
        result['originals'] = []
        for path in sorted(self.out.rglob('*')):
            c4.demand(not path.is_symlink(), 'Village original evidence cannot contain symlinks')
            if path.is_file():
                result['originals'].append({'path': path.relative_to(self.out).as_posix(),
                    'bytes': path.stat().st_size, 'sha256': c4.sha256(path)})
        write(self.out/village.REPORT, result)
    if result['status'] == 'PASS':
        village.verify_report(self.out, result['binding'], result['identity'])
    print('[DiagnosticVillageAndroid]', json.dumps({'status': result['status'], 'error': result.get('error')}), flush=True)
    return 0 if result['status'] == 'PASS' else 1

def _c4_run(self) -> int:
    result = {'schema':1, 'status':'FAIL', 'scope':'Diagnostic actual 6b APK C4 test with separately bound QA; no seven-job acceptance',
              'observations':[], 'transitions':[], 'returns':[]}
    try:
        result['diagnostic_binding'] = require_bound_diagnostic(self.args)
        source = subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT, text=True).strip()
        pin = json.loads((ROOT / 'config/godot-source.json').read_text())
        sys.path.insert(0, str(ROOT / 'scripts'))
        from verify_legacy_release_pin import verify as verify_pin
        build, native = verify_pin((ROOT / 'pubspec.yaml').read_text(), (ROOT / 'config/godot-source.json').read_text())
        contract.demand(build == 2020 and source == self.args.expected_qa_source
                        and self.args.expected_native == native == pin['revision'],
                        'Actual checked-out QA/APK/native identity differs')
        subprocess.run(['git','diff','--exit-code','HEAD','--'], cwd=ROOT, check=True)
        identity = self.main.verify_apk_identity(self.args.apk, self.args.provenance, self.args.sums)
        contract.demand(identity['versionCode'] == 2020 and identity['godot_revision'] == native
                        and identity['flutter_source_commit'] == self.args.expected_source, 'Wrong 2020 candidate identity')
        result['identity'] = identity
        meta = [json.loads((self.args.metadata_dir / (name+'.json')).read_text())
                for name in ('run','artifacts','jobs')]
        result['binding'] = contract.artifact_binding(*meta, source=self.args.expected_source,
            run_id=self.args.build_run, attempt=self.args.run_attempt,
            artifact_id=self.args.artifact_id, digest=self.args.artifact_digest,
            native=native, version_name=identity['versionName'])
        prior = json.loads(self.args.prior_tour.read_text())
        contract.demand(prior.get('status') == 'PASS' and prior.get('apk_sha256') == identity['apk_sha256']
                        and prior.get('fatal_crashes') == 0
                        and all(any(s.get('step') == name and s.get('ok') is True for s in prior.get('steps',[]))
                                for name in self.main.HARD_STEPS), 'The complete existing main tour must pass first')
        result['prior_tour'] = {'path':str(self.args.prior_tour), 'sha256':contract.sha256(self.args.prior_tour)}
        result['root_readiness'] = self.ui.ensure_rooted_emulator(self.base.adb, self.out)
        api, api_file = self.original('sdk', 'shell','getprop','ro.build.version.sdk')
        contract.demand(api.strip() == '35', 'This C4 device proof is explicitly API35')
        result['android_sdk_original'] = api_file
        self.base.launch(self.out, 'c4-start')
        self.ui.device_rotation(self.out, 'c4-responsive-portrait', 0)
        contract.demand(self.main.try_tap(self.out, ['Spielen','Spiele'], 'c4-games') is not None,
                        'Actual games navigation is unavailable')
        before_prefs, before_file = self.read_preferences('before-c4')
        result['preferences_before'] = before_file
        result['entry_touch'] = self.flutter_touch(contract.PORTAL, 'open-c4')
        initial = self.wait_observation('initial', lambda o:not o['state']['paused'] and o['state']['canDrop'])
        contract.demand(initial['state']['columns'] == [] and not initial['state']['twoPlayers'],
                        'Initial actual C4 round is not the untouched single-player game')
        result['initial'] = initial['id']
        first = self.transition('child-first', 'drop', 'column_3')
        paused = self.transition('pause-first', 'pause', 'pause')
        time.sleep(min(1.2, self.remaining()))
        held = self.wait_observation('pause-held', lambda o:o['state']['paused'])
        contract.paused_unchanged(paused, held, held['observed_monotonic']-paused['observed_monotonic'])
        result['pause_hold'] = {'first':paused['id'], 'second':held['id'],
                               'elapsed':held['observed_monotonic']-paused['observed_monotonic']}
        self.transition('resume-first', 'resume', 'resume')
        second = self.transition('child-second', 'drop', 'column_2')
        self.transition('pause-before-return', 'pause', 'pause')
        closed = self.return_to_flutter('return-first')
        old_token = self.token
        self.mailbox, self.token = '', ''
        reopen_touch = self.flutter_touch(contract.PORTAL, 'reopen-c4')
        again = self.wait_observation('reopened', lambda o:not o['state']['paused'] and o['state']['canDrop'])
        contract.reopened(closed['state'], again['state'])
        contract.demand(again['state']['token'] != old_token and again['pid'] != closed['pid'],
                        'Reopen did not create a new real private native session/process')
        result['reopen'] = {'closed':closed['id'], 'opened':again['id'], 'touch':reopen_touch}
        self.transition('pause-after-reopen', 'pause', 'pause')
        self.return_to_flutter('return-final')
        after_prefs, after_file = self.read_preferences('after-c4')
        contract.learning_unchanged(before_prefs, after_prefs)
        result['preferences_after'] = after_file
        subprocess.run(['git','diff','--exit-code','HEAD','--'], cwd=ROOT, check=True)
        self.remaining()
        result['status'] = 'PASS'
    except Exception as error:
        result.update(error=f'{type(error).__name__}: {error}', traceback=traceback.format_exc())
    finally:
        try:
            raw, log_file = self.original('final-all-buffer-logcat', 'logcat','-b','all','-d','-v','threadtime',
                                          bound=256*1024*1024)
            errors = contract.runtime_errors(raw)
            result['original_logcat'] = log_file
            result['fatal_entries'] = errors
            if errors:
                result.update(status='FAIL', error='Actual engine/Android failure in original all-buffer logcat')
        except Exception as error:
            result.update(status='FAIL', final_log_error=f'{type(error).__name__}: {error}')
        self.base.command = self.old_command
        result.update(observations=[o['id'] for o in self.observations],
                      transitions=self.transitions, returns=self.returns)
        files = []
        for path in sorted(self.out.rglob('*')):
            if path.is_file():
                contract.demand(not path.is_symlink(), 'Original evidence cannot contain symlinks')
                files.append({'path':str(path.relative_to(self.out)), 'bytes':path.stat().st_size,
                              'sha256':contract.sha256(path)})
        result['originals'] = files
        write(self.out / 'c4-result.json', result)
        print('[DiagnosticConnectFourAndroid]', json.dumps({'status':result['status'], 'error':result.get('error'),
              'observations':len(self.observations), 'transitions':len(self.transitions)}), flush=True)
    return 0 if result['status'] == 'PASS' else 1

class DiagnosticVillageProbe(VillageProbe):
    run = _village_run


class DiagnosticConnectFourProbe(Probe):
    run = _c4_run


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("village", "c4"))
    for name in ("apk", "provenance", "sums", "metadata-dir", "prior-tour", "out", "diagnostic-binding"):
        parser.add_argument("--" + name, type=Path, required=True)
    for name in ("expected-source", "expected-qa-source", "expected-native", "artifact-digest"):
        parser.add_argument("--" + name, required=True)
    for name in ("build-run", "run-attempt", "artifact-id"):
        parser.add_argument("--" + name, type=int, required=True)
    args = parser.parse_args(argv)
    require_bound_diagnostic(args)
    probe = DiagnosticVillageProbe if args.mode == "village" else DiagnosticConnectFourProbe
    status = probe(args).run()
    if status == 0 and args.mode == "c4":
        report = diagnostic.read_json(args.out / "c4-result.json")
        replay = c4.verify_report(args.out, report["binding"], report["identity"])
        diagnostic.require(replay.get("status") == "PASS", "Original C4 diagnostic replay failed")
        write(args.out.parent / "c4-diagnostic-replay.json", replay)
    return status


if __name__ == "__main__":
    sys.dont_write_bytecode = True
    raise SystemExit(main())
