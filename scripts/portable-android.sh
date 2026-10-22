#!/usr/bin/env bash
# Android candidate build on Linux or a cloud shell, without GitHub Actions.
# Does not upload to Google Play, alter signing credentials, or install apps.
set -Eeuo pipefail
umask 077

usage() {
  printf 'Usage: bash scripts/portable-android.sh doctor|tests|preview-apk\n' >&2
  exit 2
}
[[ "$#" -eq 1 ]] || usage
mode="$1"
case "$mode" in doctor|tests|preview-apk) ;; *) usage ;; esac
command -v git >/dev/null || { echo 'Git is missing' >&2; exit 3; }
root="$(git rev-parse --show-toplevel)" || { echo 'Trusted Git checkout required' >&2; exit 3; }
cd "$root"
for file in pubspec.yaml pubspec.lock config/godot-source.json scripts/build_unified_apk.sh scripts/verify_unified_apk.py scripts/install_godot_for_build.sh; do
  [[ -f "$file" ]] || { echo "Unexpected Lumo source; missing $file" >&2; exit 3; }
done

check_tools() {
  [[ "$(uname -s)" == Linux ]] || { echo 'A configured Linux build host is required' >&2; exit 3; }
  for tool in flutter dart java python3 node sha256sum; do
    command -v "$tool" >/dev/null || { echo "Missing required tool: $tool" >&2; exit 3; }
  done
  local flutter_version
  flutter_version="$(flutter --version)"
  [[ "$flutter_version" == *"Flutter 3.44.9"* ]] || {
    echo 'STOP: Expected Flutter 3.44.9; install pinned toolchain before running' >&2
    exit 3
  }
  python3 - <<'PY'
import json
from pathlib import Path
config = json.loads(Path('config/godot-source.json').read_text(encoding='utf8'))
assert config.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git', 'Unexpected game source'
assert config.get('engine') == '4.6.3', 'Unexpected engine version'
rev = config.get('revision')
assert isinstance(rev, str) and len(rev) == 40 and all(c in '0123456789abcdef' for c in rev), 'Unpinned Godot source'
print('Pinned Godot source:', rev)
PY
}

clean_source() {
  [[ -z "$(git status --porcelain=v1 --untracked-files=normal)" ]] || {
    echo 'STOP: checkout contains changes/untracked files. Preserve owner work and use a clean build checkout.' >&2
    exit 3
  }
}

case "$mode" in
  doctor)
    check_tools
    echo 'Lumo toolchain preflight passed (no Android build executed).'
    ;;
  tests|preview-apk)
    check_tools
    clean_source
    original_head="$(git rev-parse HEAD)"
    [[ "$original_head" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid Git HEAD' >&2; exit 3; }
    node --test server/lumo-ai-proxy/test/*.test.js
    python3 -m unittest discover -s scripts/tests -p 'test_*.py'
    dart scripts/audit_content.dart
    bash scripts/lumo_repair_guard.sh
    flutter pub get --enforce-lockfile
    flutter analyze --no-fatal-infos --no-fatal-warnings
    flutter test --no-pub --reporter=expanded --timeout=60s --concurrency=2
    [[ "$(git rev-parse HEAD)" == "$original_head" ]] || { echo 'STOP: Git HEAD changed during tests' >&2; exit 3; }
    git diff --quiet HEAD -- || { echo 'STOP: Tracked source changed during tests' >&2; exit 3; }
    if [[ "$mode" == tests ]]; then
      printf 'Lumo tests passed for %s\n' "$original_head"
      exit 0
    fi
    # A portable Linux host has no GitHub Actions GITHUB_PATH. Use the helper's
    # verified output location instead, preserving the project's Godot pin.
    bash scripts/install_godot_for_build.sh
    export PATH="${RUNNER_TEMP:-/tmp}/lumo-godot-engine-4.6.3:$PATH"
    command -v godot >/dev/null || { echo 'Godot binary missing after setup' >&2; exit 3; }
    godot_version="$(godot --version)"
    [[ "$godot_version" == 4.6.3* ]] || {
      echo 'STOP: Wrong Godot engine for pinned Lumo source' >&2
      exit 3
    }
    # Existing build creates the native host, integrates Godot, and validates
    # the test APK certificate. This is NOT a Play-Store AAB signing pipeline.
    bash scripts/build_unified_apk.sh
    [[ -s dist/Lumo-Lernen-Neu.apk ]] || { echo 'No APK candidate produced' >&2; exit 3; }
    if [[ "${LUMO_SPLIT_PER_ABI:-0}" == 1 ]]; then
      python3 scripts/verify_unified_apk.py dist/Lumo-Lernen-Neu.apk --abi arm64-v8a
    else
      python3 scripts/verify_unified_apk.py dist/Lumo-Lernen-Neu.apk
    fi
    [[ "$(git rev-parse HEAD)" == "$original_head" ]] || { echo 'STOP: Source HEAD changed during build' >&2; exit 3; }
    git diff --quiet HEAD -- || { echo 'STOP: Tracked source changed during build' >&2; exit 3; }
    sha256sum dist/Lumo-Lernen-Neu.apk | tee dist/APK-SHA256.txt
    echo 'Verified Lumo preview candidate. Google Play signing and device QA remain separate.'
    ;;
esac
