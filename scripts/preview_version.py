"""Reject known preview downgrades and mismatched APK update identities.

Evidence must originate from verify_unified_apk.py, not a filename/versionName.
This static gate complements, but does not replace, a real update/install test.
https://developer.android.com/studio/publish/versioning
https://developer.android.com/studio/publish/app-signing
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
POLICY = ROOT / 'config/android-preview-version.json'
MAX_CODE = 2_100_000_000


def version_code(value: object) -> int:
    if isinstance(value, bool) or not re.fullmatch(r'[1-9][0-9]*', str(value)):
        raise ValueError('versionCode must be a positive decimal integer')
    number = int(str(value))
    if number > MAX_CODE:
        raise ValueError('versionCode exceeds the Android distribution limit')
    return number


def resolve(policy: dict, environ: dict) -> tuple[int, str]:
    minimum = version_code(policy['minimumVersionCode'])
    previous = version_code(policy['observedPreviousVersionCode'])
    default = version_code(policy['versionCode'])
    if minimum <= previous or default < minimum:
        raise ValueError('Preview policy does not advance the known previous version')
    code = version_code(environ.get('LUMO_BUILD_NUMBER', default))
    name = str(environ.get('LUMO_VERSION_NAME', policy['versionName']))
    if code < minimum:
        raise ValueError(f'Preview versionCode {code} is below reserved minimum {minimum}; '
                         f'previous delivery already used {previous}. Do not uninstall user data.')
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+(?:[-+][A-Za-z0-9.-]+)?', name):
        raise ValueError('versionName must be a simple semantic version, without whitespace')
    return code, name


def verify_candidate(policy: dict, proof: dict, environ: dict) -> None:
    code, name = resolve(policy, environ)
    for key in ('package', 'signingCertificateSha256'):
        if proof.get(key) != policy[key]:
            raise ValueError('Candidate update identity mismatch: ' + key)
    if version_code(proof.get('versionCode')) != code or proof.get('versionName') != name:
        raise ValueError('Compiled APK version differs from the requested build')


def compare_updates(previous: dict, candidate: dict) -> dict:
    for key in ('package', 'signingCertificateSha256'):
        if not previous.get(key) or previous[key] != candidate.get(key):
            raise ValueError('Update would change ' + key)
    before = version_code(previous.get('versionCode'))
    after = version_code(candidate.get('versionCode'))
    if after <= before:
        raise ValueError(f'Update must advance versionCode: {before} -> {after}')
    return {'package': candidate['package'], 'fromVersionCode': before,
            'toVersionCode': after, 'sameSigningCertificate': True,
            'scope': 'Static APK metadata gate, not an installed-device claim'}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--shell', action='store_true')
    parser.add_argument('--verify', type=Path)
    parser.add_argument('--previous', type=Path)
    args = parser.parse_args()
    try:
        policy = json.loads(POLICY.read_text())
        code, name = resolve(policy, dict(os.environ))
        if args.verify:
            proof = json.loads(args.verify.read_text())
            verify_candidate(policy, proof, dict(os.environ))
            if args.previous:
                print(json.dumps(compare_updates(json.loads(args.previous.read_text()), proof), indent=2))
            else:
                print(f'[PreviewVersion] PASS: {code} / {name}')
        elif args.shell:
            print(f'{code}\n{name}')
        else:
            print(json.dumps({'versionCode': code, 'versionName': name}, indent=2))
        return 0
    except (OSError, KeyError, TypeError, ValueError) as error:
        parser.exit(1, f'[PreviewVersion] FAIL: {error}\n')


if __name__ == '__main__':
    raise SystemExit(main())
