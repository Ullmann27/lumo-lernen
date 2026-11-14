#!/usr/bin/env bash
set -euo pipefail

# Compile the real Kotlin/Java host independently of the final native PCK pin.
# No APK is built or published; final release/R8/device acceptance stays separate.
if ! git diff --quiet HEAD --; then
  echo 'Host compilation requires the exact checked-out source.' >&2
  exit 1
fi
proof="$PWD/host-compile-evidence"
mkdir -p "$proof"
git rev-parse HEAD > "$proof/source-sha.txt"
python3 -m unittest scripts.tests.test_cards_authority_registry scripts.tests.test_embedded_android -v \
  2>&1 | tee "$proof/cards-authority-registry.log"
flutter --version > "$proof/flutter-version.txt"
flutter pub get --enforce-lockfile
if [[ ! -d android ]]; then
  scaffold_root="$(mktemp -d "${TMPDIR:-/tmp}/lumo-compile-host.XXXXXXXX")"
  trap 'rm -rf "$scaffold_root"' EXIT
  flutter create --no-pub --project-name lumo_lernen --platforms=android \
    --org dev.ullmann.lumo "$scaffold_root/scaffold"
  cp -a "$scaffold_root/scaffold/android" android
fi
python3 scripts/prepare_android.py --side-by-side
python3 scripts/prepare_embedded_games.py
python3 scripts/prepare_offline_voice.py
flutter pub get --enforce-lockfile
gradle_init_dir="${GRADLE_USER_HOME:-$HOME/.gradle}/init.d"
mkdir -p "$gradle_init_dir"
cp scripts/gradle/lumo-maven-central-mirror.init.gradle "$gradle_init_dir/"
(
  cd android
  # Native compilation needs the genuine Flutter embedding and plugin classes,
  # but no assembled Dart bundle or native game PCK. No placeholder is supplied.
  ./gradlew :app:compileDebugKotlin :app:compileDebugJavaWithJavac \
    -x :app:compileFlutterBuildDebug -Ptarget-platform=android-arm64,android-x64 \
    --stacktrace 2>&1 | tee "$proof/compile.log"
)
git diff --exit-code HEAD --
python3 - <<'PY'
import hashlib
import json
from pathlib import Path
import subprocess

required = ('MainActivity', 'LumoGameActivity', 'LumoHostPlugin', 'CardsTableBridge', 'CardsAuthorityService',
            'CardsAuthorityRegistry',
            'LumoLearningSpeech', 'LumoOfflineSpeechBridge', 'LumoOfflineSpeechEngine')
classes = {}
for name in required:
    paths = list(Path('build/app').rglob(name + '.class'))
    if not paths:
        raise RuntimeError('Actual Android bytecode was not produced for ' + name)
    classes[name] = []
    for path in paths:
        data = path.read_bytes()
        if not data.startswith(bytes.fromhex('cafebabe')):
            raise RuntimeError('Invalid compiled JVM class ' + str(path))
        classes[name].append({'path': str(path), 'bytes': len(data),
                              'sha256': hashlib.sha256(data).hexdigest()})
report = {'status': 'PASS', 'scope': 'Actual Android Kotlin/Java compilation only; no APK or runtime claim',
          'flutter_source_commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(),
          'godot_aar': 'org.godotengine:godot:4.6.3.stable',
          'onnxruntime_android': json.loads(Path('config/lumo-offline-voice.json').read_text())['onnxruntime_version'],
          'classes': classes}
Path('host-compile-evidence/result.json').write_text(json.dumps(report, indent=2) + '\n')
print('[AndroidHostCompile] PASS: actual Kotlin/Java bytecode for native lifecycle, Cards IPC and offline speech')
PY
