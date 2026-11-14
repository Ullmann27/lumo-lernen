#!/usr/bin/env python3
"""Replay the actual 803a metadata against artifact_binding; no Android rerun."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import traceback


def record(path: Path) -> dict:
    raw = path.read_bytes()
    return {
        'bytes': len(raw),
        'sha256': hashlib.sha256(raw).hexdigest(),
        'git_blob': hashlib.sha1(
            b'blob ' + str(len(raw)).encode() + b'\0' + raw
        ).hexdigest(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    parser.add_argument(
        '--originals', type=Path,
        default=Path(__file__).resolve().parent / 'originals',
    )
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    root = args.source_root.resolve()
    names = ('run.json', 'artifacts.json', 'jobs.json', 'c4-result.json')
    originals = {name: args.originals / name for name in names}
    before = {name: record(path) for name, path in originals.items()}
    sources = {
        name: root / 'tools/android_qa' / name
        for name in ('connect_four_android_evidence.py', 'native_surface_readiness.py')
    }
    source_before = {name: record(path) for name, path in sources.items()}
    source_head = subprocess.check_output(
        ['git', '--no-optional-locks', '-C', str(root), 'rev-parse', 'HEAD'],
        text=True,
    ).strip()
    data = {name: json.loads(path.read_text()) for name, path in originals.items()}
    expected = {
        'source': '803a4e960ffb804a46b6d09417731c031f00f680',
        'native': '0e26153f0e58cc05739e72923b4c563a4cf380b8',
        'run_id': 43578509499,
        'attempt': 1,
        'artifact_id': 14109755854,
        'digest': '87e668220083f6a4dbf5f6ab13827529027db12fc4957e8486f2f58cd154447b',
        'version_name': '0.13.8',
    }
    identity = data['c4-result.json']['identity']
    if not (
        identity['flutter_source_commit'] == expected['source']
        and identity['godot_revision'] == expected['native']
        and identity['versionName'] == expected['version_name']
        and identity['apk_sha256']
        == 'fc66e87274173c6c8440bc0dcdcb6e4b7f838dfa168a07e392ec305c15ee566a'
        and len(identity['checks']) == 8
        and all(value is True for value in identity['checks'].values())
    ):
        raise RuntimeError('Original identity differs before metadata replay')
    sys.path.insert(0, str(root / 'tools/android_qa'))
    import connect_four_android_evidence as contract
    result = {
        'schema': 1,
        'scope': (
            'Actual Python artifact_binding with unchanged original CI metadata; '
            'no Android, APK, engine, performance or final-delivery rerun'
        ),
        'source_checkout_head': source_head,
        'executed_working_tree_sources': source_before,
        'python_version': sys.version,
        'expected': expected,
        'originals_before': before,
        'original_failure': data['c4-result.json']['error'],
        'phase': 'artifact_binding',
    }
    try:
        result['binding'] = contract.artifact_binding(
            data['run.json'], data['artifacts.json'], data['jobs.json'], **expected
        )
        result.update(status='PASS', error=None, returncode=0)
    except Exception as error:
        result.update(
            status='FAIL', error=f'{type(error).__name__}: {error}',
            traceback=traceback.format_exc(), returncode=1,
        )
    result['originals_after'] = {
        name: record(path) for name, path in originals.items()
    }
    result['sources_after'] = {
        name: record(path) for name, path in sources.items()
    }
    result['originals_unchanged'] = result['originals_after'] == before
    result['sources_unchanged_during_call'] = (
        result['sources_after'] == source_before
    )
    if not (
        result['originals_unchanged'] and result['sources_unchanged_during_call']
    ):
        result.update(status='HARNESS_INPUT_CHANGED', returncode=2)
    text = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open('x', encoding='utf-8') as stream:
        stream.write(text)
    print(text, end='')
    return result['returncode']


if __name__ == '__main__':
    raise SystemExit(main())
