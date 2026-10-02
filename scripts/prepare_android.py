"""Wire the generated Android host while preserving its application identity."""
from pathlib import Path
import os
import re
import shutil
import xml.etree.ElementTree as ET

ANDROID = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', ANDROID)


def attr(name):
    return f'{{{ANDROID}}}{name}'


def prepare(root: Path, keystore_directory: Path):
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
    match = re.search(r'namespace\s*(?:=\s*)?[\"\x27]([^\"\x27]+)', gradle.read_text())
    if not match:
        raise ValueError('Android namespace missing; application identity must be preserved')
    namespace = match.group(1)
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
    prepare(Path(__file__).resolve().parent.parent, Path(os.environ['HOME']) / '.android')
