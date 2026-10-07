#!/usr/bin/env python3
"""Verify real existing-install updates on disposable emulators only.

No uninstall, clear-data, signature change, version downgrade override, root or
private-data extraction. UI-created fictional profile must survive install -r,
restart and repeat install. This is not proof of a specific user's phone error.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time
import traceback
import zipfile

ROOT = Path(__file__).resolve().parents[2]
POLICY = ROOT / 'config/install-upgrade-2026-10-07.json'


def digest(path: Path) -> str:
    with path.open('rb') as file:
        return hashlib.file_digest(file, 'sha256').hexdigest()


def apk_path(folder: Path) -> Path:
    result = list(folder.glob('*.apk'))
    if len(result) != 1:
        raise ValueError(f'Expected exactly one APK in {folder}, got {len(result)}')
    return result[0]


def verify_packages(old_dir: Path, broken_dir: Path, new_dir: Path,
                    out: Path) -> dict:
    sys.path.insert(0, str(ROOT / 'scripts'))
    from verify_android_apk import find_apksigner, verify_apk
    policy = json.loads(POLICY.read_text())
    tool = Path(find_apksigner()).parent / 'aapt'
    result = {'status': 'PASS', 'policy': policy, 'apks': {}}
    for label, folder in [('1291', old_dir), ('280', broken_dir), ('new', new_dir)]:
        path = apk_path(folder)
        signing = verify_apk(path)
        badging = subprocess.check_output([str(tool), 'dump', 'badging', str(path)], text=True)
        match = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
        if not match:
            raise ValueError('Missing package metadata: ' + str(path))
        package, code, version = match.groups()
        code = int(code)
        expected = policy['version_code'] if label == 'new' else int(label)
        if code != expected or package != policy['package']:
            raise ValueError('Wrong package or version for ' + label)
        if signing != policy['signing_certificate_sha256']:
            raise ValueError('Signature mismatch for ' + label)
        sha = digest(path)
        if label != 'new' and sha != policy['previous_builds'][label]['sha256']:
            raise ValueError('Previous artifact digest mismatch: ' + label)
        if label == 'new':
            proof = json.loads((folder/'BUILD-PROVENANCE.json').read_text())
            if proof['tracked_source_clean'] is not True or proof['sha256'] != sha:
                raise ValueError('New APK source/digest proof failed')
            if version != policy['version_name']:
                raise ValueError('Wrong visible version')
            if code <= max(map(int, policy['previous_builds'])):
                raise ValueError('New candidate is not a forward update')
        with zipfile.ZipFile(path) as archive:
            if archive.testzip() is not None:
                raise ValueError('ZIP integrity failed')
        result['apks'][label] = {'sha256': sha, 'versionCode': code,
                                'versionName': version, 'package': package,
                                'certificate_sha256': signing, 'bytes': path.stat().st_size}
        (out / (label+'-badging.txt')).write_text(badging)
    (out/'package-comparison.json').write_text(json.dumps(result, indent=2)+'\n')
    return result


def smoke(args) -> int:
    import pr207_android_smoke as base
    import pr207_android_ui_probe as ui
    base.ui_nodes = ui.live_nodes
    base.tap_label = ui.live_tap_label
    policy = json.loads(POLICY.read_text())
    package = policy['package']
    comparison = json.loads(args.comparison.read_text())
    paths = {'1291': apk_path(args.old), '280': apk_path(args.broken),
             'new': apk_path(args.new)}
    for label, path in paths.items():
        if digest(path) != comparison['apks'][label]['sha256']:
            raise ValueError('APK differs from signature-checked build evidence')
    out = args.out
    report = {'status': 'RUNNING', 'baseline': args.baseline,
              'package_comparison': comparison, 'captures': [],
              'scope': 'Disposable emulator update and fictional profile retention; not physical Fold or complete saved game verification'}

    def adb(*words):
        return base.adb(*words)

    def installed(tag, expected_code):
        text = adb('shell', 'dumpsys', 'package', package)
        (out/(tag+'-package.txt')).write_text(text)
        version = re.search(r'\bversionCode=(\d+)', text)
        uid = re.search(r'\buserId=(\d+)', text)
        first = re.search(r'\bfirstInstallTime=([^\n]+)', text)
        if not version or int(version[1]) != expected_code or not uid or not first:
            raise RuntimeError('Installed metadata missing or wrong: ' + tag)
        return {'versionCode': int(version[1]), 'uid': uid[1], 'firstInstallTime': first[1].strip()}

    def install(path, tag, expect_downgrade=False):
        proc = subprocess.run(['adb','install','-r','--no-streaming',str(path)],
                              stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                              text=True,timeout=180)
        (out/(tag+'-installer.txt')).write_text(proc.stdout)
        if expect_downgrade:
            if proc.returncode == 0 or 'INSTALL_FAILED_VERSION_DOWNGRADE' not in proc.stdout:
                raise RuntimeError('Expected a real Android version downgrade rejection')
        elif proc.returncode or 'Success' not in proc.stdout:
            raise RuntimeError('Installation failed: ' + proc.stdout)
        return {'exit_code':proc.returncode, 'output':proc.stdout.strip()}

    def profile(tag):
        base.launch(out, tag)
        nodes = base.ui_nodes(out, tag)
        if 'LumoTest' not in base.accessible_text(nodes):
            raise RuntimeError('Existing profile not restored: '+tag)
        shot = base.capture(out, tag)
        report['captures'].append(shot)
        return {'profile_name_visible': 'LumoTest', 'screenshot': shot}

    try:
        report['harness_sha'] = base.command('git','rev-parse','HEAD')
        report['android_release'] = adb('shell','getprop','ro.build.version.release')
        report['android_sdk'] = adb('shell','getprop','ro.build.version.sdk')
        adb('shell','input','keyevent','KEYCODE_WAKEUP')
        base.adb('shell','wm','dismiss-keyguard',check=False)
        base.display(1080,2400,480)
        report['baseline_install'] = install(paths[args.baseline], '01-baseline')
        before = installed('01-baseline',int(args.baseline))
        report['before'] = before
        adb('shell','svc','wifi','disable')
        adb('shell','svc','data','disable')
        adb('shell','cmd','connectivity','airplane-mode','enable')
        if adb('shell','settings','get','global','airplane_mode_on') != '1':
            raise RuntimeError('Offline mode not confirmed')
        adb('logcat','-c')
        base.launch(out,'02-create-profile')
        report['onboarding'] = base.onboard(out)
        adb('shell','am','force-stop',package)
        report['baseline_profile'] = profile('03-before-update')
        adb('shell','am','force-stop',package)
        if args.baseline == '1291':
            report['downgrade_reproduction'] = install(paths['280'],'04-blocked-280',True)
            if installed('04-after-blocked-install',1291) != before:
                raise RuntimeError('Rejected downgrade unexpectedly changed installation')
        report['update_install'] = install(paths['new'],'05-update-1400')
        after = installed('05-update',policy['version_code'])
        for field in ('uid','firstInstallTime'):
            if after[field] != before[field]:
                raise RuntimeError('Update did not preserve original installation '+field)
        report['after'] = after
        report['updated_profile'] = profile('06-after-update')
        base.tap_label(out,'Spielen','07-open-games')
        nodes = base.ui_nodes(out,'07-games')
        if not any(text in base.accessible_text(nodes) for text in ('Lumo Cards','Lumo Kart','Spielewelt')):
            raise RuntimeError('Games page not verified')
        report['captures'].append(base.capture(out,'07-games'))
        adb('shell','am','force-stop',package)
        report['restart_profile'] = profile('08-offline-restart')
        adb('shell','am','force-stop',package)
        report['same_version_reinstall'] = install(paths['new'],'09-repeat-update')
        report['repeat_profile'] = profile('10-profile-after-repeat')
        crash = base.adb('logcat','-d','-b','crash',check=False)
        (out/'crash-buffer.txt').write_text(crash)
        if package in crash:
            raise RuntimeError('App appears in crash buffer')
        report['status'] = 'PASS'
        print('[InstallUpgrade] PASS baseline='+args.baseline+' -> '+str(policy['version_code'])+'; profile retained without uninstall/clear-data')
        return 0
    except Exception as error:
        report['status'] = 'FAIL'
        report['error'] = str(error)
        report['traceback'] = traceback.format_exc()
        try:
            report['failure_capture'] = base.capture(out,'failure')
        except Exception as capture_error:
            report['capture_error'] = str(capture_error)
        print('[InstallUpgrade] FAIL:',error)
        return 1
    finally:
        try:
            (out/'logcat.txt').write_text(base.adb('logcat','-d',check=False))
        except Exception as error:
            report['log_error'] = str(error)
        (out/'upgrade-report.json').write_text(json.dumps(report,indent=2)+'\n')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode',choices=('verify','smoke'))
    parser.add_argument('--old',type=Path,default=Path('previous/1291'))
    parser.add_argument('--broken',type=Path,default=Path('previous/280'))
    parser.add_argument('--new',type=Path,default=Path('dist'))
    parser.add_argument('--out',type=Path,default=Path('install-evidence'))
    parser.add_argument('--comparison',type=Path,default=Path('install-evidence/package-comparison.json'))
    parser.add_argument('--baseline',choices=('280','1291'),default='1291')
    args = parser.parse_args()
    args.out.mkdir(parents=True,exist_ok=True)
    if args.mode == 'verify':
        verify_packages(args.old,args.broken,args.new,args.out)
        print('[InstallUpgrade] package identity, signature and forward version PASS')
        return 0
    return smoke(args)


if __name__ == '__main__':
    raise SystemExit(main())
