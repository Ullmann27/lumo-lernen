#!/usr/bin/env python3
"""Check draft preconditions, then freeze and describe the exact runner-built APK."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from release_lookup import resolve_draft


def main(args):
    if not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', args.repository):
        raise ValueError('Invalid GitHub repository')
    release = resolve_draft(args.repository, args.release_tag)
    if any(asset['name'].lower().endswith('.apk') for asset in release.get('assets', [])):
        raise ValueError('Build mode refuses to replace an existing draft APK; use download mode to check it')
    args.out.mkdir(parents=True, exist_ok=True)
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    if head != os.environ.get('GITHUB_SHA', head):
        raise ValueError('Checkout differs from the saved commit selected by workflow dispatch')
    dirty = subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no'], text=True).strip()
    if dirty:
        raise ValueError('Tracked source differs from the saved checkout; refusing a misleading build proof')
    pin = json.loads(Path('config/godot-source.json').read_text())
    if not re.fullmatch(r'[0-9a-f]{40}', pin['revision']):
        raise ValueError('Godot source must be pinned to a full saved commit SHA')
    proof = {'repository': args.repository, 'draft_release': args.release_tag,
             'flutter_source_commit': head, 'tracked_source_clean': True,
             'godot_source_pin': pin, 'mode': 'runner-build', 'release_published': False}
    if not args.preflight:
        from importlib.util import spec_from_file_location, module_from_spec
        import sys
        # Reuse the application's release verifier, including the persisted
        # signing certificate, ABI/page alignment and embedded PCK source hash.
        scripts = Path('scripts').resolve()
        sys.path.insert(0, str(scripts))
        spec = spec_from_file_location('lumo_release_verifier', scripts/'verify_unified_apk.py')
        verifier = module_from_spec(spec); spec.loader.exec_module(verifier)
        proof['apk'] = verifier.verify(args.apk)
        path = args.out/'tested.apk'
        shutil.copyfile(args.apk, path)
        with path.open('rb') as stream:
            actual = hashlib.file_digest(stream, 'sha256').hexdigest()
        if actual != proof['apk']['sha256']:
            raise ValueError('Copied APK differs from the exact verified build')
        proof['flutter_toolchain'] = json.loads(subprocess.check_output(
            ['flutter', '--version', '--machine'], text=True))
        if os.environ.get('GITHUB_OUTPUT'):
            with Path(os.environ['GITHUB_OUTPUT']).open('a') as stream:
                stream.write(f'sha256={actual}\n')
    filename = 'build-request.json' if args.preflight else 'runner-build-proof.json'
    (args.out/filename).write_text(json.dumps(proof, indent=2)+'\n')
    print(json.dumps(proof, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repository', required=True)
    parser.add_argument('--release-tag', required=True)
    parser.add_argument('--apk', type=Path, default=Path('dist/Lumo-Lernen-Neu.apk'))
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--preflight', action='store_true')
    main(parser.parse_args())
