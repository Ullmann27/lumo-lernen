"""Prepare a distinct, privately signed Google Play Android App Bundle host.

Runs on the generated (untracked) Flutter Android host after normal native
integration. Never prints credentials or replaces the sideload APK channel.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET

import prepare_android

PLAY_SIGNING = '''// BEGIN LUMO PLAY UPLOAD SIGNING
android {
    signingConfigs {
        create("lumoPlayUpload") {
            storeFile = file(System.getenv("LUMO_PLAY_UPLOAD_KEYSTORE") ?: error("Missing Play upload key file"))
            storePassword = System.getenv("LUMO_PLAY_UPLOAD_STORE_PASSWORD") ?: error("Missing Play upload store password")
            keyAlias = System.getenv("LUMO_PLAY_UPLOAD_KEY_ALIAS") ?: error("Missing Play upload key alias")
            keyPassword = System.getenv("LUMO_PLAY_UPLOAD_KEY_PASSWORD") ?: error("Missing Play upload key password")
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("lumoPlayUpload")
        }
    }
}
// END LUMO PLAY UPLOAD SIGNING'''

PACKAGE_PATTERN = re.compile(r'^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*){2,}$')


def prepare(root: Path, application_id: str) -> None:
    if not PACKAGE_PATTERN.fullmatch(application_id) or application_id.endswith('.coachpreview'):
        raise ValueError('Final, non-preview applicationId is required')
    gradle = root / 'android/app/build.gradle.kts'
    manifest = root / 'android/app/src/main/AndroidManifest.xml'
    text = gradle.read_text(encoding='utf-8')
    if text.count(prepare_android.SIGNING_BLOCK) != 1:
        raise ValueError('Expected unchanged, generated Lumo sideload signing block')
    if 'create("lumoPlayUpload")' in text:
        raise ValueError('Play signing already applied')
    text = text.replace(prepare_android.SIGNING_BLOCK, PLAY_SIGNING)
    text, ids = re.subn(
        r'(\bapplicationId\s*=\s*)"[^"]+"',
        lambda m: m.group(1) + '"' + application_id + '"', text,
    )
    if ids != 1:
        raise ValueError('Expected exactly one Android applicationId')
    for name in ('targetSdk', 'compileSdk'):
        text, count = re.subn(
            rf'(?m)^(\s*{name}\s*=\s*)(?:flutter\.\w+|\d+)\s*$',
            lambda match: match.group(1) + '36', text,
        )
        if count != 1:
            raise ValueError(f'Expected exactly one {name} in Flutter host')
    if 'storePassword = "android"' in text or 'androiddebugkey' in text:
        raise ValueError('Development signing is forbidden in Play package')
    tree = ET.parse(manifest)
    doc = tree.getroot()
    for element in list(doc):
        if element.tag in ('uses-permission', 'uses-permission-sdk-23') and (
                element.get(prepare_android.attr('name')) ==
                'android.permission.REQUEST_INSTALL_PACKAGES'):
            doc.remove(element)
    for element in doc.iter():
        if element.get(prepare_android.attr('name')) == 'android.permission.REQUEST_INSTALL_PACKAGES':
            raise ValueError('Install-packages permission survives Play sanitization')
    ET.indent(tree)
    gradle.write_text(text, encoding='utf-8')
    tree.write(manifest, encoding='utf-8', xml_declaration=True)
    print('Play Android host ready: API 36, private upload signing, no install permission')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--application-id', required=True)
    args = parser.parse_args()
    prepare(Path(__file__).resolve().parent.parent, args.application_id)
