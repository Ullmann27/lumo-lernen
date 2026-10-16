#!/usr/bin/env python3
"""Update the published Sonnenhafen test APK (versionCode 1001) in place.

Families installed the prerelease "lumo-lernen-sonnenhafen-unified-test-20261015"
(0.10.6, versionCode 1001). Its learning state is older than the 19xx line, so
the combined candidate must update it in place: same package, same signer,
higher versionCode, unchanged installation identity, and the child's profile
kept. Only fictional data in a disposable emulator is used; Flutter controls
are read from live accessibility, nothing is injected into the app.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import time
import traceback

sys.path.insert(0, str(Path(__file__).resolve().parent))
import creative_android_probe as probe  # noqa: E402  (shares the pinned helpers)

base = probe.base
live = probe.live
SONNENHAFEN_DIGEST = 'dd9ad0c73c691488f09e45cea2dcbe820af07c6140f506d9461b9cf2905c7944'
SONNENHAFEN_VERSION = '1001'


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out
    out.mkdir(parents=True, exist_ok=True)
    result = {'status': 'RUNNING', 'baseline': 'sonnenhafen-unified-test-20261015',
              'source': probe.SOURCE, 'godot': probe.GODOT,
              'scope': 'In-place update 1001 -> candidate with a real onboarded profile',
              'not_tested': ['physical device', 'Play Store delivery', 'native game saves of 1001']}
    try:
        if probe.digest(args.baseline) != SONNENHAFEN_DIGEST:
            raise RuntimeError('Sonnenhafen 1001 APK digest mismatch')
        provenance = json.loads((args.candidate.parent / 'BUILD-PROVENANCE.json').read_text())
        if (provenance['flutter_source_commit'] != probe.SOURCE or
                provenance['tracked_source_clean'] is not True or
                provenance['signingCertificateSha256'] != probe.CERT or
                provenance['versionCode'] != probe.EXPECTED_VERSION or
                provenance['sha256'] != probe.digest(args.candidate)):
            raise RuntimeError('Candidate provenance mismatch')
        if probe.EXPECTED_VERSION <= int(SONNENHAFEN_VERSION):
            raise RuntimeError('Candidate versionCode must be higher than 1001')
        result['candidate_sha256'] = provenance['sha256']
        result['emulator_root_readiness'] = probe.ensure_rooted_emulator(base.adb, out)
        result['android_sdk'] = int(base.adb('shell', 'getprop', 'ro.build.version.sdk'))
        base.display(1080, 2400, 480)
        install = base.adb('install', '-r', '--no-streaming', str(args.baseline), timeout=240)
        (out / 'sonnenhafen-install.txt').write_text(install)
        if 'Success' not in install:
            raise RuntimeError('Sonnenhafen 1001 installation failed')
        before = probe.package_identity(out, 'sonnenhafen')
        if not before['versionCode'].startswith(SONNENHAFEN_VERSION):
            raise RuntimeError('Installed baseline is not versionCode 1001')
        base.launch(out, 'sonnenhafen')
        result['onboarding'] = probe.onboard(out)
        before_prefs = probe.prefs(out, 'sonnenhafen')
        before_profile = before_prefs.get('flutter.lumo_active_profile')
        if not before_profile or 'LumoTest' not in before_profile:
            raise RuntimeError('Sonnenhafen profile was not actually persisted')
        probe.capture(out, '01_sonnenhafen_profile')
        base.adb('shell', 'am', 'force-stop', probe.PACKAGE)
        update = base.adb('install', '-r', '--no-streaming', str(args.candidate), timeout=240)
        (out / 'candidate-update.txt').write_text(update)
        after = probe.package_identity(out, 'updated')
        if ('Success' not in update or
                not after['versionCode'].startswith(str(probe.EXPECTED_VERSION)) or
                after['userId'] != before['userId'] or
                after['firstInstallTime'] != before['firstInstallTime']):
            raise RuntimeError('In-place update from 1001 with unchanged identity failed')
        base.adb('shell', 'svc', 'wifi', 'disable')
        base.adb('shell', 'svc', 'data', 'disable')
        base.adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        base.launch(out, 'updated-offline')
        after_prefs = probe.prefs(out, 'updated')
        if after_prefs.get('flutter.lumo_active_profile') != before_profile:
            raise RuntimeError('Sonnenhafen profile changed during the update')
        for attempt in range(20):
            if 'LumoTest' in base.accessible_text(live.live_nodes(out, f'updated-home-{attempt}')):
                break
            time.sleep(1)
        else:
            raise RuntimeError('Sonnenhafen profile missing from the updated home UI')
        probe.capture(out, '02_updated_profile')
        result.update(status='PASS', before=before, after=after, profile_retained=True,
                      offline=True)
    except Exception as error:  # Keep every observation for the report.
        result.update(status='FAIL', error=f'{type(error).__name__}: {error}',
                      traceback=traceback.format_exc())
        try:
            probe.capture(out, 'failure')
        except Exception:
            pass
    (out / 'sonnenhafen-update-result.json').write_text(json.dumps(result, indent=2) + '\n')
    print('[SonnenhafenUpdate]', result['status'], result.get('error', ''), flush=True)
    return 0 if result['status'] == 'PASS' else 1


if __name__ == '__main__':
    raise SystemExit(main())
