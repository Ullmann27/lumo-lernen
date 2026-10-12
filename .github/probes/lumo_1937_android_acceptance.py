#!/usr/bin/env python3
"""1937 exact APK acceptance and mandatory real Android screenshots.

No app-side injection or content/state edits. Existing course and complete-race
assertions remain intact. Only disposable emulator UI/size/orientation changes.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import sys
import traceback

import lumo_education_android_probe as education
import kart_complete_android_probe as kart


def digest(path):
    return hashlib.file_digest(path.open('rb'), 'sha256').hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--arm64', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--reuse-education-proof', action='store_true')
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    candidate = json.loads((args.candidate.parent/'BUILD-PROVENANCE.json').read_text())
    arm = json.loads((args.arm64.parent/'BUILD-PROVENANCE.json').read_text())
    for data, apk, abi in [(candidate,args.candidate,'x86_64'),(arm,args.arm64,'arm64-v8a')]:
        if (data['versionCode'] != 1937 or data['versionName'] != '0.12.30'
            or data['flutter_source_commit'] != os.environ['LUMO_EXPECT_SOURCE']
            or data['godot']['revision'] != os.environ['LUMO_EXPECT_GODOT']
            or data['sha256'] != digest(apk) or data['abis'] != [abi]
            or data['signingCertificateSha256'] != education.existing.CERT
            or data['tracked_source_clean'] is not True):
            raise RuntimeError('Exact 1937 APK provenance mismatch')
    result = {'status':'RUNNING','flutter_commit':candidate['flutter_source_commit'],
              'godot_commit':candidate['godot']['revision'],'build_run':int(os.environ['LUMO_BUILD_RUN']),
              'emulator_apk_sha256':candidate['sha256'],'arm64_apk_sha256':arm['sha256'],
              'qa_commit':os.environ['LUMO_QA_SOURCE'],'physical_fold':False,
              'paid_api_calls':0, 'screenshots':[]}
    existing = education.existing
    original_capture = existing.capture

    def capture_current(folder, name, role):
        if any(s['role'] == role for s in result['screenshots']):
            return None
        capture = original_capture(folder, name)
        file = folder/capture['file']
        result['screenshots'].append({'role':role,'file':str(file.relative_to(out)),
                                      'sha256':digest(file),'width':capture['width'],'height':capture['height'],
                                      'flutter_commit':result['flutter_commit'],'godot_commit':result['godot_commit'],
                                      'installed_apk_sha256':candidate['sha256'],
                                      'build_run':result['build_run'],'runtime':'actual Android16 x86_64 emulator APK'})
        return capture

    def course_capture(folder, name, *extra, **kw):
        shot = original_capture(folder,name,*extra,**kw)
        if name == '08_actual_android_school_introduction':
            existing.base.display(1080,2400,420)
            capture_current(folder,'pflicht01-lernen-smartphone','learning_phone')
            existing.base.display(1200,896,160)
        elif name == '10_actual_android_fold_target_seven_plus_five':
            capture_current(folder,'pflicht02-lernen-fold-offen','learning_fold')
        elif name == '24_actual_android_plant_example':
            capture_current(folder,'pflicht06-pflanzenteile','additional_learning')
        return shot

    existing.capture = course_capture
    try:
        original_args = sys.argv
        if args.reuse_education_proof:
            prior = json.loads((out/'APK-AND-SCREENSHOT-PROOF.json').read_text())
            proof = json.loads((out/'education-android-result.json').read_text())
            if (prior['status'] != 'FAIL' or proof['status'] != 'PASS'
                or proof['candidate_source'] != result['flutter_commit']
                or proof['candidate_apk_sha256'] != candidate['sha256']
                or proof['voice_update_kart']['candidate']['godot']['revision'] != result['godot_commit']):
                raise RuntimeError('Only the actual passed education proof for the identical APK may be reused')
            for shot in prior['screenshots']:
                if shot['role'] not in {'learning_phone','learning_fold','additional_learning'}:
                    continue
                if digest(out/shot['file']) != shot['sha256'] or shot['installed_apk_sha256'] != candidate['sha256']:
                    raise RuntimeError('Original actual education capture changed')
                result['screenshots'].append(shot)
            (out/'APK-AND-SCREENSHOT-PROOF.json').rename(out/'FIRST-FAILED-APK-AND-SCREENSHOT-PROOF.json')
            (out/'complete-race/result.json').rename(out/'complete-race/FIRST-FAILED-result.json')
            (out/'rooted-emulator.json').rename(out/'FIRST-rooted-emulator.json')
            seed=out/'fresh-actual-race-preparation'
            seed.mkdir(exist_ok=True)
            root=existing.ensure_rooted_emulator(existing.base.adb,out)
            if int(existing.base.adb('shell','getprop','ro.build.version.sdk')) != 36:
                raise RuntimeError('Fresh actual Android16 expected')
            installed=existing.base.adb('install','-r','--no-streaming',str(args.candidate),timeout=240)
            if 'Success' not in installed:raise RuntimeError('Actual candidate install failed')
            existing.base.adb('shell','svc','wifi','disable')
            existing.base.adb('shell','svc','data','disable')
            existing.base.adb('shell','cmd','connectivity','airplane-mode','enable')
            existing.base.display(1080,2400,480)
            existing.base.launch(seed,'fresh-exact1937')
            existing.onboard(seed)
            existing.base.display(1200,896,160)
            # Nonempty learning records come from real answer taps, never prefs injection.
            course=education.language_nature_course(seed,plant=True)
            if course['status']!='PASS' or course['actual_attempts_added']!=3:
                raise RuntimeError('Actual fresh saved-learning course did not pass')
            existing.flutter_tap(seed,'Spielen','fresh-race-games')
            existing.enter(seed,'Lumo Kart','Einzelrennen','fresh-race-menu',launch_label='Losfahren')
            for step in range(4):existing.native_tap(seed,'Weiter',f'fresh-race-next-{step}')
            existing.native_tap(seed,'Rennen starten','fresh-race-start')
            existing.native_text(seed,'RUNDE','fresh-race-real-hud')
            existing.capture(seed,'actual-prior-race')
            existing.leave(seed,'fresh-partial-race',return_label='Zum Lernen')
            result['education_reuse']={'prior_run':38240584021,'education_proof_sha256':digest(out/'education-android-result.json'),
                'same_apk_sha256':candidate['sha256'],'rebuilt':False,'fresh_actual_saved_learning_course':course,
                'scope':'Immutable actual full education PASS reused; fresh real UI profile/course and partial race prepare complete-race checks'}
        else:
            sys.argv=[original_args[0],'--baseline',str(args.baseline),'--candidate',str(args.candidate),'--out',str(out)]
            try:
                if education.main()!=0:raise RuntimeError('Actual update/voice/course acceptance failed')
            finally:
                sys.argv=original_args
                existing.capture=original_capture
            proof=json.loads((out/'education-android-result.json').read_text())
            root=proof['voice_update_kart']['root']
        if proof['status']!='PASS' or proof['candidate_source']!=result['flutter_commit'] or proof['candidate_apk_sha256']!=candidate['sha256']:
            raise RuntimeError('Education proof source mismatch')
        existing.capture=original_capture
        # Root identity adapter links actual preceding education (not fictional Creative
        # results) to the same strict serial/UID/boot/source/digest/API checks.
        predecessor=out/'actual-education-root-predecessor.json'
        predecessor.write_text(json.dumps({'status':'PASS','scope':'Actual education/fresh-UI root identity, not a completed race',
            'education_proof_sha256':digest(out/'education-android-result.json'),
            'source':result['flutter_commit'],'godot':result['godot_commit'],'apk_sha256':candidate['sha256'],
            'android_sdk':int(existing.base.adb('shell','getprop','ro.build.version.sdk')),
            'emulator_root_readiness':root},indent=2)+'\n')
        result['education'] = proof
        old_loader = kart.load_creative
        def loader():
            creative = old_loader()
            old_enter = creative.enter
            def enter(folder,title,header,tag,launch_label=''):
                if title == 'Lumo Kart':capture_current(folder,'pflicht03-spieleuebersicht','games_overview')
                old_enter(folder,title,header,tag,launch_label=launch_label)
                if title == 'Lumo Kart':capture_current(folder,'pflicht04-kart-menue','kart_menu')
            creative.enter = enter
            old_capture = creative.capture
            def race_capture(folder,name,*extra,**kw):
                shot = old_capture(folder,name,*extra,**kw)
                if name == '02-fresh-race-phone':capture_current(folder,'pflicht05-kart-rennen-hud','kart_race')
                return shot
            creative.capture = race_capture
            return creative
        kart.load_creative = loader
        race_dir = out/'complete-race'
        sys.argv = [original_args[0],'--candidate',str(args.candidate),'--out',str(race_dir),'--timeout','1800','--predecessor',str(predecessor)]
        try:
            if kart.main() != 0:raise RuntimeError('Actual complete Android Kart race failed')
        finally:
            sys.argv = original_args
            kart.load_creative = old_loader
        race = json.loads((race_dir/'result.json').read_text())
        if race['status'] != 'PASS' or race['source'] != result['flutter_commit'] or race['godot'] != result['godot_commit'] or race['apk_sha256'] != candidate['sha256']:
            raise RuntimeError('Race proof source mismatch')
        result['race'] = race
        roles={s['role'] for s in result['screenshots']}
        if roles != {'learning_phone','learning_fold','games_overview','kart_menu','kart_race','additional_learning'}:
            raise RuntimeError('Mandatory actual current APK screenshots are incomplete')
        for s in result['screenshots']:
            if not (out/s['file']).is_file() or digest(out/s['file']) != s['sha256']:raise RuntimeError('Screenshot missing or changed')
        result['status']='PASS'
        return 0
    except Exception:
        result.update(status='FAIL',error=traceback.format_exc())
        return 1
    finally:
        (out/'APK-AND-SCREENSHOT-PROOF.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')

if __name__ == '__main__':raise SystemExit(main())
