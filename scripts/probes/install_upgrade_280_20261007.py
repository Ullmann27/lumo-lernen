#!/usr/bin/env python3
"""Real 280->1400 update using shared metadata helpers, no APK rebuild.

Preserves original installation and fictional UI-created profile. Supports
Android's actual appId/userId dump fields. No data deletion or install bypass.
"""
import json
from pathlib import Path
import traceback

import install_upgrade_1321_20261007 as shared

OUT = Path('upgrade280-evidence')


def main() -> int:
    OUT.mkdir(exist_ok=True)
    shared.OUT = OUT
    base = shared.base
    base.ui_nodes = shared.ui.live_nodes
    base.tap_label = shared.ui.live_tap_label
    report = {'status':'RUNNING','baseline':280,'apk_source_sha':shared.NEW_SOURCE,
              'scope':'Real update on disposable API35 emulator; not a physical-device or complete game-save claim'}
    try:
        old = shared.only_apk('previous/280')
        new = shared.only_apk('candidate/dist')
        proof = json.loads(Path('candidate/dist/BUILD-PROVENANCE.json').read_text())
        comparison = json.loads(Path('candidate/install-evidence/package-comparison.json').read_text())
        if shared.digest(old) != shared.BROKEN_SHA:
            raise RuntimeError('Wrong baseline APK')
        if proof['flutter_source_commit'] != shared.NEW_SOURCE or proof['tracked_source_clean'] is not True:
            raise RuntimeError('Wrong candidate source')
        if shared.digest(new) != proof['sha256'] or proof['sha256'] != comparison['apks']['new']['sha256']:
            raise RuntimeError('Candidate digest mismatch')
        if proof['package'] != shared.PACKAGE or proof['versionCode'] != 1400 or proof['signingCertificateSha256'] != shared.CERT:
            raise RuntimeError('Wrong package/version/signing identity')
        report.update(apk_sha256=proof['sha256'],baseline_sha256=shared.BROKEN_SHA,
                      harness_sha=base.command('git','rev-parse','HEAD'),
                      android_sdk=base.adb('shell','getprop','ro.build.version.sdk'))
        base.adb('shell','input','keyevent','KEYCODE_WAKEUP')
        base.adb('shell','wm','dismiss-keyguard',check=False)
        base.display(1080,2400,480)
        report['initial_install'] = shared.install(old,'01-baseline280')
        before = shared.metadata('01-baseline280',280)
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
        report['update_install'] = shared.install(new,'04-update1400')
        after = shared.metadata('04-update1400',1400)
        report['after'] = after
        if any(after[field] != before[field] for field in ('uid','firstInstallTime')):
            raise RuntimeError('Original installation identity changed')
        report['updated_profile'] = shared.profile('05-profile-after-update')
        base.tap_label(OUT,'Spielen','06-games')
        if not any(label in base.accessible_text(base.ui_nodes(OUT,'06-games')) for label in ('Lumo Cards','Lumo Kart','Spielewelt')):
            raise RuntimeError('Games menu not reached')
        report['games_screenshot'] = base.capture(OUT,'06-games')
        base.adb('shell','am','force-stop',shared.PACKAGE)
        report['offline_restart_profile'] = shared.profile('07-restart')
        base.adb('shell','am','force-stop',shared.PACKAGE)
        report['same_version_install'] = shared.install(new,'08-reinstall1400')
        report['same_version_profile'] = shared.profile('09-profile-after-reinstall')
        crashes = base.adb('logcat','-d','-b','crash',check=False)
        (OUT/'crash-buffer.txt').write_text(crashes)
        if shared.PACKAGE in crashes:
            raise RuntimeError('Application crash recorded')
        report['status'] = 'PASS'
        print('[InstallUpgrade280] PASS: 280->1400, original profile, offline restart and repeat installation verified')
        return 0
    except Exception as error:
        report.update(status='FAIL',error=str(error),traceback=traceback.format_exc())
        try:
            report['failure_capture'] = base.capture(OUT,'failure')
        except Exception as capture_error:
            report['capture_error'] = str(capture_error)
        print('[InstallUpgrade280] FAIL:',error)
        return 1
    finally:
        try:
            (OUT/'logcat.txt').write_text(base.adb('logcat','-d',check=False))
        except Exception as log_error:
            report['log_error'] = str(log_error)
        (OUT/'upgrade-report.json').write_text(json.dumps(report,indent=2)+'\n')


if __name__ == '__main__':
    raise SystemExit(main())
