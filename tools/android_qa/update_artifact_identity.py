"""Read-only artifact identity validation without emulator/UI dependencies."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path


def require_update_artifact(apk: Path, *, source: str, version: int,
                            package: str, certificate: str, native_source: str) -> dict:
    info = json.loads((apk.parent / 'BUILD-PROVENANCE.json').read_text())
    expected = {
        'flutter_source_commit': source, 'versionCode': version, 'package': package,
        'signingCertificateSha256': certificate,
        'sha256': hashlib.sha256(apk.read_bytes()).hexdigest(),
    }
    if info.get('tracked_source_clean') is not True or any(
            info.get(key) != value for key, value in expected.items()):
        raise RuntimeError('Artifact provenance does not identify the expected APK')
    if info.get('abis') != ['x86_64']:
        raise RuntimeError('Update gate requires the actual x86_64 native APK')
    if info.get('godot', {}).get('revision') != native_source:
        raise RuntimeError('Native source is not the reviewed pin')
    return info
