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
        # The existing CLI intentionally forwards both immutable APK paths.
        original_args = sys.argv
        sys.argv = [original_args[0],'--baseline',str(args.baseline),'--candidate',str(args.candidate),'--out',str(out)]
        try:
            if education.main() != 0:raise RuntimeError('Actual update/voice/course acceptance failed')
        finally:
            sys.argv = original_args
            existing.capture = original_capture
        proof = json.loads((out/'education-android-result.json').read_text())
        if proof['status'] != 'PASS' or proof['candidate_source'] != result['flutter_commit'] or proof['candidate_apk_sha256'] != candidate['sha256']:
            raise RuntimeError('Education proof source mismatch')
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
        sys.argv = [original_args[0],'--candidate',str(args.candidate),'--out',str(race_dir),'--timeout','1800']
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
