"""Wire the generated Android host while preserving its application identity."""
from pathlib import Path
import argparse
import os
import re
import shutil
import xml.etree.ElementTree as ET

ANDROID = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ANDROID)

SIGNING_START = '// BEGIN LUMO STABLE SIGNING'
SIGNING_END = '// END LUMO STABLE SIGNING'
SIGNING_BLOCK = '''// BEGIN LUMO STABLE SIGNING
// Resolve from android/app, independent of HOME or ANDROID_USER_HOME.
android {
    signingConfigs {
        getByName("debug") {
            storeFile = file("../../tools/lumo-debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }
    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
// END LUMO STABLE SIGNING'''


def attr(name):
    return f'{{{ANDROID}}}{name}'


def prepare(root: Path, keystore_directory: Path, side_by_side: bool = False):
    main = root / 'android/app/src/main'
    manifest = main / 'AndroidManifest.xml'
    tree = ET.parse(manifest)
    doc = tree.getroot()
    for permission in ('INTERNET', 'CAMERA', 'RECORD_AUDIO', 'REQUEST_INSTALL_PACKAGES'):
        name = f'android.permission.{permission}'
        if not any(e.get(attr('name')) == name for e in doc.findall('uses-permission')):
            ET.SubElement(doc, 'uses-permission', {attr('name'): name})
    if not any(e.get(attr('name')) == 'android.hardware.camera' for e in doc.findall('uses-feature')):
        ET.SubElement(doc, 'uses-feature', {attr('name'): 'android.hardware.camera', attr('required'): 'false'})
    application = doc.find('application')
    if application is None:
        raise ValueError('Android application node missing')
    application.set(attr('label'), 'Lumo Lernen Neu' if side_by_side else 'Lumo Lernen')
    activity = next((e for e in application.findall('activity') if (e.get(attr('name')) or '').endswith('MainActivity')), None)
    if activity is None:
        raise ValueError('MainActivity declaration missing')
    if not any(e.get(attr('scheme')) == 'lumolernen' for e in activity.findall('intent-filter/data')):
        intent = ET.SubElement(activity, 'intent-filter')
        ET.SubElement(intent, 'action', {attr('name'): 'android.intent.action.VIEW'})
        for category in ('DEFAULT', 'BROWSABLE'):
            ET.SubElement(intent, 'category', {attr('name'): f'android.intent.category.{category}'})
        ET.SubElement(intent, 'data', {attr('scheme'): 'lumolernen'})
    queries = doc.find('queries')
    if queries is None:
        queries = ET.SubElement(doc, 'queries')
    if not any(e.get(attr('name')) == 'android.intent.action.TTS_SERVICE' for e in queries.findall('intent/action')):
        intent = ET.SubElement(queries, 'intent')
        ET.SubElement(intent, 'action', {attr('name'): 'android.intent.action.TTS_SERVICE'})
    if not any(e.get(attr('name')) == 'dev.ullmann.lumo3d' for e in queries.findall('package')):
        ET.SubElement(queries, 'package', {attr('name'): 'dev.ullmann.lumo3d'})
    if not any(e.get(attr('name')) == 'io.flutter.embedding.android.EnableImpeller' for e in application.findall('meta-data')):
        ET.SubElement(application, 'meta-data', {attr('name'): 'io.flutter.embedding.android.EnableImpeller', attr('value'): 'true'})
    if not any(e.get(attr('name')) == 'androidx.core.content.FileProvider' for e in application.findall('provider')):
        provider = ET.SubElement(application, 'provider', {
            attr('name'): 'androidx.core.content.FileProvider',
            attr('authorities'): '${applicationId}.fileprovider',
            attr('exported'): 'false', attr('grantUriPermissions'): 'true',
        })
        ET.SubElement(provider, 'meta-data', {
            attr('name'): 'android.support.FILE_PROVIDER_PATHS',
            attr('resource'): '@xml/lumo_file_paths',
        })
    ET.indent(tree)
    tree.write(manifest, encoding='utf-8', xml_declaration=True)
    xml = main / 'res/xml'
    xml.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(root / 'tools/auto_install/lumo_file_paths.xml', xml / 'lumo_file_paths.xml')

    # flutter create --org dev.ullmann.lumo erzeugt dev.ullmann.lumo.lumo_lernen.
    # Die alte CI schrieb eine zweite Activity ins falsche Elternverzeichnis.
    gradle = next(p for p in (root / 'android/app/build.gradle.kts', root / 'android/app/build.gradle') if p.exists())
    gradle_text = gradle.read_text(encoding='utf-8')
    match = re.search(r'namespace\s*(?:=\s*)?[\"\x27]([^\"\x27]+)', gradle_text)
    if not match:
        raise ValueError('Android namespace missing; application identity must be preserved')
    namespace = match.group(1)
    application_id = namespace + ('.coachpreview' if side_by_side else '')
    gradle_text, count = re.subn(
        r'(\bapplicationId\s*(?:=\s*)?)([\"\x27])[^\"\x27]+\2',
        lambda match: f'{match.group(1)}{match.group(2)}{application_id}{match.group(2)}',
        gradle_text,
    )
    if count != 1:
        raise ValueError('Expected exactly one literal applicationId in the generated Android host')
    if SIGNING_START in gradle_text or SIGNING_END in gradle_text:
        if gradle_text.count(SIGNING_START) != 1 or gradle_text.count(SIGNING_END) != 1:
            raise ValueError('Stable signing block markers are invalid')
        gradle_text, count = re.subn(
            re.escape(SIGNING_START) + r'.*?' + re.escape(SIGNING_END),
            lambda _: SIGNING_BLOCK,
            gradle_text,
            flags=re.DOTALL,
        )
        if count != 1:
            raise ValueError('Stable signing block markers are out of order')
    else:
        gradle_text = gradle_text.rstrip() + '\n\n' + SIGNING_BLOCK + '\n'
    gradle.write_text(gradle_text, encoding='utf-8')
    target = main / 'kotlin' / Path(*namespace.split('.')) / 'MainActivity.kt'
    target.parent.mkdir(parents=True, exist_ok=True)
    template = (root / 'tools/auto_install/MainActivity.kt').read_text()
    target.write_text(re.sub(r'^package [^\n]+', f'package {namespace}', template, count=1))

    # Lumo uses Latin OCR only. The plugin also references optional compileOnly
    # language APIs; suppress only those missing classes during release R8.
    proguard = root / 'android/app/proguard-rules.pro'
    existing = proguard.read_text(encoding='utf-8') if proguard.exists() else ''
    existing_rules = {line.split('#', 1)[0].strip() for line in existing.splitlines()}
    missing_rules = [
        f'-dontwarn com.google.mlkit.vision.text.{language}.**'
        for language in ('chinese', 'devanagari', 'japanese', 'korean')
        if f'-dontwarn com.google.mlkit.vision.text.{language}.**' not in existing_rules
    ]
    if missing_rules:
        with proguard.open('a', encoding='utf-8') as output:
            if existing and not existing.endswith('\n'):
                output.write('\n')
            output.write('# Optional non-Latin MLKit OCR APIs (Lumo uses Latin only).\n')
            output.write('\n'.join(missing_rules) + '\n')

    keystore_directory.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(root / 'tools/lumo-debug.keystore', keystore_directory / 'debug.keystore')
    print(f'Android host prepared: {namespace}; stable signing; installer and 3D bridge connected')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--side-by-side', action='store_true', help='Build Lumo Lernen Neu beside the existing app')
    args = parser.parse_args()
    prepare(Path(__file__).resolve().parent.parent, Path(os.environ['HOME']) / '.android', side_by_side=args.side_by_side)
