#!/usr/bin/env python3
"""Reverify the complete 2020 test candidate without granting a release receipt."""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools/android_qa'))
import connect_four_android_evidence as c4
from update_preservation import (require_learning_preserved,
                                require_post_update_learning_preserved,
                                require_in_place_update)
from verify_unified_apk import verify as verify_apk
from verify_legacy_release_pin import verify as verify_pin


def read(path: Path) -> dict:
    value = json.loads(path.read_text())
    c4.demand(isinstance(value, dict), 'Missing original evidence object: ' + str(path))
    return value


def module(path: Path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


def update_proof(root: Path, candidate: dict, source: str) -> dict:
    report = read(root / 'update-result.json')
    c4.demand(report.get('status') == 'PASS' and report.get('offline') is True
              and report.get('fatal_crashes') == 0 and report.get('candidate_source') == source,
              'The complete original 2017 to 2020 update has not passed')
    old, new = report.get('baseline', {}), report.get('candidate', {})
    c4.demand(old.get('versionCode') == 2017
              and old.get('flutter_source_commit') == '47889f74a651b073965def70743417cf320b1eb9'
              and old.get('godot', {}).get('revision') == '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57',
              'The actual baseline differs from the reviewed 2017 source')
    c4.demand(new.get('sha256') == candidate['sha256'] and new.get('versionCode') == 2020
              and new.get('flutter_source_commit') == source
              and new.get('godot') == candidate['godot']
              and new.get('signingCertificateSha256') == c4.CERT,
              'Update tested another current APK/native source')
    def prefs(name):
        return c4.preferences((root / (name+'-preferences.xml')).read_text())
    before, after = prefs('before-update'), prefs('after-update')
    c4.demand(require_learning_preserved(before, after, migration_versions=(2017,2020)) == report.get('after_update'),
              'Original first update preservation replay differs')
    for name, field in (('after-kart','after_kart'),('after-restart','after_restart')):
        c4.demand(require_post_update_learning_preserved(before, after, prefs(name), migration_versions=(2017,2020))
                  == report.get(field), 'Original post-update preservation replay differs: ' + name)
    c4.demand(set(report.get('fold', {})) == {'cover','open','landscape'}, 'Complete Fold preservation is missing')
    for name in ('cover','open','landscape'):
        c4.demand(require_post_update_learning_preserved(before, after, prefs('fold-'+name), migration_versions=(2017,2020))
                  == report['fold'][name], 'Original Fold preservation replay differs: ' + name)
    def package(name):
        import re
        raw = (root / (name+'-package.txt')).read_text()
        uid_raw = (root / (name+'-package-uid.txt')).read_text()
        ids = re.findall(r'^package:'+re.escape(c4.PACKAGE)+r'\s+uid:(\d+)', uid_raw, re.M)
        c4.demand(len(ids) == 1, 'Original PackageManager UID is missing or ambiguous')
        result = {'userId':ids[0]}
        for field in ('firstInstallTime','versionCode'):
            matches = re.findall(r'(?m)^\s*'+field+r'=([^\n]+)', raw)
            c4.demand(len(set(matches)) == 1, 'Ambiguous original installed package field: ' + field)
            result[field] = matches[0].strip()
        return result
    c4.demand(require_in_place_update(package('baseline'), package('updated'), 2020) == report.get('installation'),
              'Actual in-place installation identity differs')
    c4.demand(set(report.get('native_tour', {})) == {'race','hud','drive','pause','return'}
              and report.get('learning_journey',{}).get('status') == 'PASS'
              and report.get('onboarding',{}).get('status') == 'PASS',
              'Actual baseline learning or post-update Kart sequence is incomplete')
    c4.demand(not (root / 'fatal-logcat.txt').read_text().strip(), 'The update left a fatal Android trace')
    return {'status':'PASS','from_version':2017,'to_version':2020,
            'candidate_apk_sha256':candidate['sha256'], 'raw_report_sha256':c4.sha256(root/'update-result.json')}


def verify(args) -> dict:
    source = subprocess.check_output(['git','rev-parse','HEAD'], cwd=ROOT,text=True).strip()
    c4.demand(source == args.source, 'Final verifier is not on the exact candidate head')
    subprocess.run(['git','diff','--exit-code','HEAD','--'], cwd=ROOT,check=True)
    build,native = verify_pin((ROOT/'pubspec.yaml').read_text(), (ROOT/'config/godot-source.json').read_text())
    from release_pipeline_gates import parse_pubspec_version
    version_name,version_code = parse_pubspec_version((ROOT/'pubspec.yaml').read_text())
    c4.demand(build == version_code == 2020, 'Final version is not the dedicated 2020 candidate')
    meta = [read(args.metadata/(name+'.json')) for name in ('run','artifacts','jobs')]
    binding = c4.artifact_binding(*meta,source=source,run_id=args.build_run,attempt=args.run_attempt,
                                 artifact_id=args.artifact_id,digest=args.artifact_digest,
                                 native=native,version_name=version_name)
    for name in ('android-c4','update-2020-from-2017'):
        jobs = [j for j in meta[2].get('jobs',[]) if j.get('name') == name]
        c4.demand(len(jobs) == 1 and jobs[0].get('head_sha') == source
                  and jobs[0].get('run_attempt') == args.run_attempt
                  and jobs[0].get('conclusion') == 'success', 'Required actual Android job failed: ' + name)
    apks = {}
    for abi, directory in (('arm64-v8a',args.candidate),('x86_64',args.candidate/'x86_64')):
        apk = directory/'Lumo-Lernen-Neu.apk'
        fresh = verify_apk(apk,{abi})
        original = read(directory/'BUILD-PROVENANCE.json')
        c4.demand(all(original.get(k) == v for k,v in fresh.items())
                  and original.get('flutter_source_commit') == source
                  and original.get('tracked_source_clean') is True,
                  'Current signed APK differs from its original build provenance: ' + abi)
        c4.demand(fresh['versionCode'] == 2020 and fresh['versionName'] == version_name
                  and fresh['godot']['revision'] == native, 'Wrong candidate version/native revision')
        apks[abi] = fresh
    c4.demand(apks['arm64-v8a']['godot'] == apks['x86_64']['godot'], 'The two ABIs embed different native PCK bytes')
    compile = read(args.host_compile/'result.json')
    classes = read(args.host_compile/'connect-four-classes.json')
    c4.demand(compile.get('status') == classes.get('status') == 'PASS'
              and compile.get('flutter_source_commit') == classes.get('source') == source
              and set(classes.get('classes',{})) == {'ConnectFourGameActivity','ConnectFourAuthorityService','ConnectFourBridge'}
              and all(classes['classes'][k] for k in classes['classes']), 'Actual current C4 host bytecode is missing')
    runtime = read(args.runtime/'runtime-gate.json')
    before, after = read(args.runtime/'source-before.json'),read(args.runtime/'source-after.json')
    c4.demand(runtime.get('passed') is True and runtime.get('exit_codes') == {'dart':0,'godot':0}
              and before == after and before.get('host',{}).get('head') == source
              and before.get('native',{}).get('head') == native,
              'The real current Dart/Godot runtime pair is incomplete or failed')
    runner = module(ROOT/'scripts/run_connect_four_runtime.py')
    c4.demand(runner.validate_native_log(args.runtime/'original-godot.log') == runtime.get('original_godot_log')
              and runner.validate_results(args.runtime,runtime['session']) == runtime.get('results'),
              'Original runtime logs/state/PNG replay differs')
    android = read(args.android/'c4/c4-result.json')
    identity = android.get('identity',{})
    x86 = apks['x86_64']
    c4.demand(identity.get('apk_sha256') == x86['sha256']
              and identity.get('flutter_source_commit') == source
              and identity.get('godot_revision') == native
              and identity.get('godot_pck_sha256') == x86['godot']['pck_sha256']
              and identity.get('versionCode') == 2020 and identity.get('versionName') == version_name
              and identity.get('signingCertificateSha256') == c4.CERT
              and identity.get('checks') and all(v is True for v in identity['checks'].values()),
              'Actual C4 device observation belongs to another signed APK')
    main = read(args.android/'main/tour-result.json')
    c4.demand(main.get('status') == 'PASS' and main.get('apk_sha256') == x86['sha256']
              and main.get('fatal_crashes') == 0
              and c4.sha256(args.android/'main/tour-result.json') == android['prior_tour']['sha256'],
              'The original complete existing main tour differs')
    device = c4.verify_report(args.android/'c4',binding,identity)
    update = update_proof(args.update,x86,source)
    return {'schema':1,'status':'PASS','versionName':version_name,'versionCode':2020,
            'binding':binding,'apks':apks,'c4_android':device,'update':update,
            'runtime_gate_sha256':c4.sha256(args.runtime/'runtime-gate.json'),
            'scope':'Signed 2020 test candidate with real desktop/API35 C4 and 2017 update evidence',
            'release_approved':False,'api37_approved':False,'physical_arm64_tested':False}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('candidate','runtime','host-compile','android','update','metadata','out'):
        parser.add_argument('--'+name,type=Path,required=True)
    for name in ('source','artifact-digest'):
        parser.add_argument('--'+name,required=True)
    for name in ('build-run','run-attempt','artifact-id'):
        parser.add_argument('--'+name,type=int,required=True)
    args=parser.parse_args()
    c4.demand(not args.out.exists(),'Refusing to overwrite previous candidate facts')
    result=verify(args)
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2)+'\n')
    print('[ConnectFourCandidate] PASS: exact signed 2020 test artifacts and current real C4 evidence')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
