#!/usr/bin/env python3
"""Repeat only the 1291/API36 update with Android's actual appId field.

Reuse the reviewed 1321 harness helpers (metadata supports appId/userId), not
its scenario or result. The APK is exactly the existing 1400 build. No source
rebuild, uninstall, clearing data, downgrade override or fake success.
"""
import json
from pathlib import Path
import traceback

import install_upgrade_1321_20261007 as shared

OUT = Path('upgrade1291-evidence')
OLD_SHA = '42b8656fdff6a503aae2a21c72aa60f053aebd4435608b63592ce8d2eac6f10f'


def main() -> int:
    OUT.mkdir(exist_ok=True)
    shared.OUT = OUT
    base = shared.base
    base.ui_nodes = shared.ui.live_nodes
    base.tap_label = shared.ui.live_tap_label
    report = {'status':'RUNNING','baseline':1291,'apk_source_sha':shared.NEW_SOURCE,
              'scope':'Real 1291 update on disposable API36 emulator; not user-phone or full game-save acceptance'}
    try:
        old = shared.only_apk('previous/1291')
        broken = shared.only_apk('previous/280')
        new = shared.only_apk('candidate/dist')
        proof = json.loads(Path('candidate/dist/BUILD-PROVENANCE.json').read_text())
        comparison = json.loads(Path('candidate/install-evidence/package-comparison.json').read_text())
        if shared.digest(old) != OLD_SHA or shared.digest(broken) != shared.BROKEN_SHA:
            raise RuntimeError('Baseline APK identity changed')
        if proof['flutter_source_commit'] != shared.NEW_SOURCE or proof['tracked_source_clean'] is not True:
            raise RuntimeError('Wrong candidate source')
        if shared.digest(new) != proof['sha256'] or proof['sha256'] != comparison['apks']['new']['sha256']:
            raise RuntimeError('APK differs from verified build')
        if proof['package'] != shared.PACKAGE or proof['versionCode'] != 1400 or proof['signingCertificateSha256'] != shared.CERT:
            raise RuntimeError('Wrong candidate package/version/signature')
        report.update(apk_sha256=proof['sha256'],baseline_sha256=OLD_SHA,
                      harness_sha=base.command('git','rev-parse','HEAD'),
                      android_sdk=base.adb('shell','getprop','ro.build.version.sdk'))
        base.adb('shell','input','keyevent','KEYCODE_WAKEUP')
        base.adb('shell','wm','dismiss-keyguard',check=False)
        base.display(1080,2400,480)
        report['initial_install'] = shared.install(old,'01-baseline1291')
        before = shared.metadata('01-baseline1291',1291)
        report['before'] = before
        base.adb('shell','svc','wifi','disable')
        base.adb('shell','svc','data','disable')
        base.adb('shell','cmd','connectivity','airplane-mode','enable')
        if base.adb('shell','settings','get','global','airplane_mode_on') != '1':
            raise RuntimeError('Offline mode not confirmed')
        base.adb('logcat','-c')
        base.launch(OUT,'02-create-profile')
        report['onboarding'] = base.onboard(OUT)
        base.adb('shell','am','force-stop',shared.PACKAGE)
        report['baseline_profile'] = shared.profile('03-before-update')
        base.adb('shell','am','force-stop',shared.PACKAGE)
        report['downgrade_reproduction'] = shared.install(broken,'04-rejected-280',True)
        if shared.metadata('04-still1291',1291) != before:
            raise RuntimeError('Rejected downgrade changed installation')
        report['update_install'] = shared.install(new,'05-update1400')
        after = shared.metadata('05-update1400',1400)
        report['after'] = after
        if any(after[field] != before[field] for field in ('uid','firstInstallTime')):
            raise RuntimeError('Update did not preserve original installation')
        report['updated_profile'] = shared.profile('06-profile-after-update')
        base.tap_label(OUT,'Spielen','07-games')
        if not any(label in base.accessible_text(base.ui_nodes(OUT,'07-games')) for label in ('Lumo Cards','Lumo Kart','Spielewelt')):
            raise RuntimeError('Games menu not reached')
        report['games_screenshot'] = base.capture(OUT,'07-games')
        base.adb('shell','am','force-stop',shared.PACKAGE)
        report['offline_restart_profile'] = shared.profile('08-restart')
        base.adb('shell','am','force-stop',shared.PACKAGE)
        report['same_version_install'] = shared.install(new,'09-reinstall1400')
        report['same_version_profile'] = shared.profile('10-profile-after-reinstall')
        crashes = base.adb('logcat','-d','-b','crash',check=False)
        (OUT/'crash-buffer.txt').write_text(crashes)
        if shared.PACKAGE in crashes:
            raise RuntimeError('Application crash recorded')
        report['status'] = 'PASS'
        print('[InstallUpgrade1291] PASS: real downgrade rejected; 1400 update, original profile, restart and repeat install verified')
        return 0
    except Exception as error:
        report.update(status='FAIL',error=str(error),traceback=traceback.format_exc())
        try:
            report['failure_capture'] = base.capture(OUT,'failure')
        except Exception as capture_error:
            report['capture_error'] = str(capture_error)
        print('[InstallUpgrade1291] FAIL:',error)
        return 1
    finally:
        try:
            (OUT/'logcat.txt').write_text(base.adb('logcat','-d',check=False))
        except Exception as log_error:
            report['log_error'] = str(log_error)
        (OUT/'upgrade-report.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    raise SystemExit(main())
