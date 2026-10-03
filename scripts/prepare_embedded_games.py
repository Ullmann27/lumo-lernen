"""Install the private Godot host inside the generated Flutter Android application."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ANDROID = 'http://schemas.android.com/apk/res/android'
TOOLS = 'http://schemas.android.com/tools'
ET.register_namespace('android', ANDROID)
ET.register_namespace('tools', TOOLS)
START = '// BEGIN LUMO EMBEDDED GODOT'
END = '// END LUMO EMBEDDED GODOT'
BLOCK = '''// BEGIN LUMO EMBEDDED GODOT
android {
    defaultConfig {
        minSdk = 24
        ndk { abiFilters.clear(); abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }
    }
    androidResources { noCompress += "pck" }
    packaging {
        jniLibs {
            useLegacyPackaging = true
            excludes.addAll(listOf("lib/armeabi-v7a/**", "lib/x86/**"))
        }
    }
}
dependencies {
    implementation("org.godotengine:godot:4.6.3.stable")
}
// END LUMO EMBEDDED GODOT'''


def prepare(root: Path):
    main = root / 'android/app/src/main'
    manifest = main / 'AndroidManifest.xml'
    tree = ET.parse(manifest)
    doc = tree.getroot()
    attr = lambda name: f'{{{ANDROID}}}{name}'
    app = doc.find('application')
    if app is None:
        raise ValueError('Missing Android application')
    for entry in app.findall('provider/meta-data'):
        if entry.get(attr('name')) == 'android.support.FILE_PROVIDER_PATHS':
            entry.set(f'{{{TOOLS}}}replace', 'android:resource')
    gradle = root / 'android/app/build.gradle.kts'
    text = gradle.read_text()
    namespace = re.search(r'namespace\s*=\s*"([^"]+)"', text)
    if namespace is None:
        raise ValueError('Expected the generated Kotlin Android host')
    namespace = namespace.group(1)
    name = namespace + '.LumoGameActivity'
    activity = next((a for a in app.findall('activity') if a.get(attr('name')) == name), None)
    if activity is None:
        activity = ET.SubElement(app, 'activity')
    for key, value in {
        'name': name, 'exported': 'false', 'process': ':lumo_game',
        'screenOrientation': 'portrait', 'resizeableActivity': 'true',
        'configChanges': 'orientation|screenSize|smallestScreenSize|keyboardHidden|keyboard|navigation|screenLayout|uiMode|colorMode|density|assetsPaths',
        'theme': '@style/LumoGameTheme', 'enableOnBackInvokedCallback': 'false',
    }.items():
        activity.set(attr(key), value)
    main_activity = next((a for a in app.findall('activity') if (a.get(attr('name')) or '').endswith('MainActivity')), None)
    if main_activity is not None:
        main_activity.set(attr('resizeableActivity'), 'true')
    queries = doc.find('queries')
    if queries is not None:
        for package in queries.findall('package'):
            if package.get(attr('name')) == 'dev.ullmann.lumo3d':
                queries.remove(package)
    ET.indent(tree)
    tree.write(manifest, encoding='utf-8', xml_declaration=True)
    if START in text:
        if text.count(START) != 1 or text.count(END) != 1:
            raise ValueError('Invalid embedded host markers')
        text = re.sub(re.escape(START) + '.*?' + re.escape(END), lambda _: BLOCK, text, flags=re.S)
    else:
        text = text.rstrip() + '\n\n' + BLOCK + '\n'
    gradle.write_text(text)
    target = main / 'kotlin' / Path(*namespace.split('.'))
    target.mkdir(parents=True, exist_ok=True)
    for filename in ('LumoGameActivity.kt', 'GameEventStore.kt'):
        source = (root / 'tools/auto_install' / filename).read_text()
        (target / filename).write_text(re.sub(r'^package [^\n]+', f'package {namespace}', source, count=1))
    resources = main / 'res/values'
    resources.mkdir(parents=True, exist_ok=True)
    (resources / 'lumo_game_styles.xml').write_text('''<resources>
    <style name="LumoGameTheme" parent="Theme.AppCompat.DayNight.NoActionBar">
        <item name="android:windowActionModeOverlay">true</item>
        <item name="android:windowNoTitle">true</item>
        <item name="android:windowBackground">#142D42</item>
    </style>
</resources>
''')
    rules = root / 'android/app/proguard-rules.pro'
    existing = rules.read_text() if rules.exists() else ''
    keep = '-keep class ' + namespace + '.LumoHostPlugin { *; }'
    if keep not in existing:
        rules.write_text(existing.rstrip() + '\n# Godot registers the host methods through reflection.\n' + keep + '\n')
    print('Embedded Godot host prepared; same APK, private activity, durable reward events.')


if __name__ == '__main__':
    prepare(Path(__file__).resolve().parents[1])
