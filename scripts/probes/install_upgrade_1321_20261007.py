#!/usr/bin/env python3
"""Supplement the 280/1291 matrix with the actual PR202 build 1321.

Same immutable 1400 APK, no rebuild. Fresh disposable emulator only; no
uninstall, clear-data, downgrade flags, signature changes or gate bypasses.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import traceback

import pr207_android_smoke as base
import pr207_android_ui_probe as ui

PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CERT = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
NEW_SOURCE = '2beabe722dd40bfe110236a305e66e9122e944b6'
OLD_SHA = 'c946a008509fc1c1cd322552ed353d39d945192f85fb32ad4429b2a237e63f40'
BROKEN_SHA = 'dbd445466a49ed4e23a899f4a166c19d7f11cc4200a3835efc53f1937befd970'
OUT = Path('upgrade1321-evidence')


def digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def only_apk(folder: str) -> Path:
    matches = list(Path(folder).glob('*.apk'))
    if len(matches) != 1:
        raise RuntimeError('Expected exactly one APK: '+folder)
    return matches[0]


def metadata(tag: str, expected: int) -> dict:
    raw = base.adb('shell','dumpsys','package',PACKAGE)
    (OUT/(tag+'-package.txt')).write_text(raw)
    version = re.search(r'\bversionCode=(\d+)',raw)
    uid = re.search(r'\b(?:userId|appId)=(\d+)',raw)
    first = re.search(r'\bfirstInstallTime=([^\n]+)',raw)
    if not version or int(version[1]) != expected or not uid or not first:
        raise RuntimeError('Installed package identity unavailable or wrong: '+tag)
    return {'versionCode':int(version[1]),'uid':uid[1],'firstInstallTime':first[1].strip()}


def install(path: Path, tag: str, rejection: bool = False) -> dict:
    result = subprocess.run(['adb','install','-r','--no-streaming',str(path)],
                            text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                            timeout=180)
    (OUT/(tag+'-installer.txt')).write_text(result.stdout)
    if rejection:
        if result.returncode == 0 or 'INSTALL_FAILED_VERSION_DOWNGRADE' not in result.stdout:
            raise RuntimeError('Actual downgrade rejection not observed')
    elif result.returncode != 0 or 'Success' not in result.stdout:
        raise RuntimeError('Installation rejected: '+result.stdout)
    return {'exit_code':result.returncode,'output':result.stdout.strip()}


def profile(tag: str) -> dict:
    base.launch(OUT,tag)
    text = base.accessible_text(base.ui_nodes(OUT,tag))
    if 'LumoTest' not in text:
        raise RuntimeError('Original fictional profile missing: '+tag)
    return {'visible_name':'LumoTest','screenshot':base.capture(OUT,tag)}


def main() -> int:
    OUT.mkdir(exist_ok=True)
    report = {'status':'RUNNING','apk_source_sha':NEW_SOURCE,'baseline':1321,
              'scope':'Real update on disposable emulator; not specific phone diagnosis or complete game-save acceptance'}
    base.ui_nodes = ui.live_nodes
    base.tap_label = ui.live_tap_label
    try:
        old = only_apk('previous/1321')
        broken = only_apk('previous/280')
        new = only_apk('candidate/dist')
        proof = json.loads(Path('candidate/dist/BUILD-PROVENANCE.json').read_text())
        comparison = json.loads(Path('candidate/install-evidence/package-comparison.json').read_text())
        if digest(old) != OLD_SHA or digest(broken) != BROKEN_SHA:
            raise RuntimeError('Original baseline APK digest changed')
        if proof['flutter_source_commit'] != NEW_SOURCE or proof['tracked_source_clean'] is not True:
            raise RuntimeError('Wrong or dirty 1400 source')
        if digest(new) != proof['sha256'] or proof['sha256'] != comparison['apks']['new']['sha256']:
            raise RuntimeError('1400 APK differs from verified build')
        if proof['package'] != PACKAGE or proof['versionCode'] != 1400 or proof['signingCertificateSha256'] != CERT:
            raise RuntimeError('Wrong new package/version/certificate')
        report.update(apk_sha256=proof['sha256'],baseline_sha256=OLD_SHA,
                      harness_sha=base.command('git','rev-parse','HEAD'),
                      android_sdk=base.adb('shell','getprop','ro.build.version.sdk'))
        base.adb('shell','input','keyevent','KEYCODE_WAKEUP')
        base.adb('shell','wm','dismiss-keyguard',check=False)
        base.display(1080,2400,480)
        report['initial_install'] = install(old,'01-baseline1321')
        before = metadata('01-baseline1321',1321)
        report['before'] = before
        base.adb('shell','svc','wifi','disable')
        base.adb('shell','svc','data','disable')
        base.adb('shell','cmd','connectivity','airplane-mode','enable')
        if base.adb('shell','settings','get','global','airplane_mode_on') != '1':
            raise RuntimeError('Offline state not confirmed')
        base.adb('logcat','-c')
        base.launch(OUT,'02-create-profile')
        report['onboarding'] = base.onboard(OUT)
        base.adb('shell','am','force-stop',PACKAGE)
        report['baseline_profile'] = profile('03-before-update')
        base.adb('shell','am','force-stop',PACKAGE)
        report['downgrade_reproduction'] = install(broken,'04-rejected-280',True)
        if metadata('04-still1321',1321) != before:
            raise RuntimeError('Rejected downgrade changed original installation')
        report['update_install'] = install(new,'05-update1400')
        after = metadata('05-update1400',1400)
        report['after'] = after
        if any(after[field] != before[field] for field in ('uid','firstInstallTime')):
            raise RuntimeError('Update did not preserve original installation')
        report['updated_profile'] = profile('06-profile-after-update')
        base.tap_label(OUT,'Spielen','07-games')
        text = base.accessible_text(base.ui_nodes(OUT,'07-games'))
        if not any(label in text for label in ('Lumo Cards','Lumo Kart','Spielewelt')):
            raise RuntimeError('Games menu not reached')
        report['games_screenshot'] = base.capture(OUT,'07-games')
        base.adb('shell','am','force-stop',PACKAGE)
        report['offline_restart_profile'] = profile('08-restart')
        base.adb('shell','am','force-stop',PACKAGE)
        report['same_version_install'] = install(new,'09-reinstall1400')
        report['same_version_profile'] = profile('10-profile-after-reinstall')
        crashes = base.adb('logcat','-d','-b','crash',check=False)
        (OUT/'crash-buffer.txt').write_text(crashes)
        if PACKAGE in crashes:
            raise RuntimeError('Application crash recorded')
        report['status'] = 'PASS'
        print('[InstallUpgrade1321] PASS: 1321->280 rejected;1321->1400 update, original profile, restart and repeat install verified')
        return 0
    except Exception as error:
        report.update(status='FAIL',error=str(error),traceback=traceback.format_exc())
        try:
            report['failure_capture'] = base.capture(OUT,'failure')
        except Exception as capture_error:
            report['capture_error'] = str(capture_error)
        print('[InstallUpgrade1321] FAIL:',error)
        return 1
    finally:
        try:
            (OUT/'logcat.txt').write_text(base.adb('logcat','-d',check=False))
        except Exception as log_error:
            report['log_error'] = str(log_error)
        (OUT/'upgrade-report.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    raise SystemExit(main())
