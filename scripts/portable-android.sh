#!/usr/bin/env bash
# Android candidate build on Linux or a cloud shell, without GitHub Actions.
# Does not upload to Google Play, alter signing credentials, or install apps.
set -Eeuo pipefail
umask 077
export PYTHONDONTWRITEBYTECODE=1

# Toolchain pinned by the existing GitHub build (lumo-runtime-apk.yml) and
# scripts/install_ndk_for_build.sh. A portable host must match it.
readonly FLUTTER_VERSION='3.44.9'
readonly JDK_MAJOR=17
readonly ANDROID_PLATFORM='android-36'
readonly NDK_REVISION='28.2.13676358'

usage() {
  printf 'Usage: bash scripts/portable-android.sh doctor|tests|godot-tests|preview-apk\n' >&2
  exit 2
}
[[ "$#" -eq 1 ]] || usage
mode="$1"
case "$mode" in doctor|tests|godot-tests|preview-apk) ;; *) usage ;; esac
command -v git >/dev/null || { echo 'Git is missing' >&2; exit 3; }
root="$(git rev-parse --show-toplevel)" || { echo 'Trusted Git checkout required' >&2; exit 3; }
cd "$root"
for file in pubspec.yaml pubspec.lock config/godot-source.json scripts/build_unified_apk.sh scripts/verify_unified_apk.py scripts/install_godot_for_build.sh scripts/install_ndk_for_build.sh; do
  [[ -f "$file" ]] || { echo "Unexpected Lumo source; missing $file" >&2; exit 3; }
done
original_head="$(git rev-parse HEAD)"
[[ "$original_head" =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid Git HEAD' >&2; exit 3; }
# Logs and evidence stay in the ignored build/ folder of this checkout.
evidence_dir="${LUMO_EVIDENCE_DIR:-$root/build/portable-evidence/$(date -u +%Y%m%dT%H%M%SZ)-${original_head:0:12}-$mode}"
if [[ "$mode" != doctor ]]; then
  mkdir -p "$evidence_dir"
  evidence_dir="$(cd "$evidence_dir" && pwd -P)"
fi

failures=0
pass() { printf '[doctor] PASS  %s\n' "$*"; }
warn() { printf '[doctor] WARN  %s\n' "$*"; }
fail() { printf '[doctor] FAIL  %s\n' "$*"; failures=$((failures + 1)); }

android_sdk() { printf '%s' "${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"; }

godot_pin() {
  python3 - <<'PY'
import json
from pathlib import Path
config = json.loads(Path('config/godot-source.json').read_text(encoding='utf8'))
assert config.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git', 'Unexpected game source'
assert config.get('engine') == '4.6.3', 'Unexpected engine version'
rev = config.get('revision')
assert isinstance(rev, str) and len(rev) == 40 and all(c in '0123456789abcdef' for c in rev), 'Unpinned Godot source'
print(config['repository'], rev)
PY
}

java_major() {
  java -version 2>&1 | sed -nE 's/.* version "([0-9]+)[."].*/\1/p' | head -n 1
}

# Every check runs, so one doctor call lists all missing pieces at once.
# Scope "godot" needs only what the game regressions use, "tests" adds the
# Flutter/JDK test toolchain, "android" (doctor, preview-apk) adds the SDK.
doctor() {
  local scope="$1" tool tools=(git python3 sha256sum curl unzip timeout)
  [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] &&
    pass "Linux x86_64 host" || fail 'A Linux x86_64 build host is required (Flutter and Godot binaries)'
  [[ "$scope" == godot ]] || tools+=(flutter dart java node rg)
  for tool in "${tools[@]}"; do
    command -v "$tool" >/dev/null && pass "tool $tool" || fail "missing required tool: $tool"
  done
  doctor_toolchain "$scope"
  if (( failures )); then
    echo "Lumo doctor: $failures blocking problem(s); nothing was built." >&2
    return 3
  fi
  echo "Lumo $scope preflight passed (no Android build executed)."
}

doctor_toolchain() {
  local scope="$1" sdk version apksigner mem_kb disk_kb pin
  if pin="$(godot_pin 2>&1)"; then pass "pinned Godot source ${pin##* }"; else fail "Godot source pin: $pin"; fi
  if command -v godot >/dev/null; then
    version="$(godot --version 2>/dev/null || true)"
    [[ "$version" == 4.6.3* ]] && pass "Godot $version" || fail "godot on PATH is $version, not 4.6.3"
  else
    warn 'godot not on PATH; godot-tests/preview-apk download the SHA-256-pinned 4.6.3 build'
  fi
  [[ "$scope" == godot ]] && return 0
  if command -v flutter >/dev/null; then
    version="$(flutter --version 2>/dev/null || true)"
    [[ "$version" == *"Flutter $FLUTTER_VERSION "* ]] && pass "Flutter $FLUTTER_VERSION" ||
      fail "expected Flutter $FLUTTER_VERSION; got: $(grep -m1 '^Flutter' <<< "$version" || echo unknown)"
  fi
  if command -v java >/dev/null; then
    version="$(java_major)"
    if [[ ! "$version" =~ ^[0-9]+$ ]] || (( version < JDK_MAJOR )); then
      fail "JDK $JDK_MAJOR or newer is required; got ${version:-unknown}"
    elif (( version != JDK_MAJOR )); then
      warn "JDK $version works with Gradle, but the reviewed CI build uses JDK $JDK_MAJOR"
    else
      pass "JDK $JDK_MAJOR"
    fi
  fi
  if command -v tesseract >/dev/null && python3 -c 'import PIL' 2>/dev/null; then
    pass 'tesseract + Pillow (Android QA unit tests)'
  else
    warn 'tesseract or Pillow missing; tests mode skips tools/android_qa unit tests'
  fi
  [[ "$scope" == tests ]] && return 0
  sdk="$(android_sdk)"
  if [[ -n "$sdk" && -d "$sdk" ]]; then
    pass "Android SDK $sdk"
    [[ -x "$sdk/cmdline-tools/latest/bin/sdkmanager" ]] || command -v sdkmanager >/dev/null &&
      pass 'sdkmanager' || fail "sdkmanager missing; install cmdline-tools into $sdk/cmdline-tools/latest"
    [[ -f "$sdk/platforms/$ANDROID_PLATFORM/android.jar" ]] && pass "platform $ANDROID_PLATFORM" ||
      fail "platform $ANDROID_PLATFORM missing (sdkmanager \"platforms;$ANDROID_PLATFORM\")"
    [[ -f "$sdk/licenses/android-sdk-license" ]] && pass 'Android SDK license accepted' ||
      fail 'Android SDK license not accepted on this host (run sdkmanager --licenses yourself)'
    [[ -f "$sdk/ndk/$NDK_REVISION/source.properties" ]] && pass "NDK $NDK_REVISION" ||
      warn "NDK $NDK_REVISION missing; preview-apk installs it via scripts/install_ndk_for_build.sh"
  else
    fail 'ANDROID_SDK_ROOT or ANDROID_HOME must name an existing Android SDK'
  fi
  if apksigner="$(python3 -c 'import sys; sys.path.insert(0, "scripts"); from verify_android_apk import find_apksigner; print(find_apksigner())' 2>/dev/null)" &&
     [[ -x "$apksigner" && -x "$(dirname "$apksigner")/aapt" ]]; then
    pass "build-tools $(dirname "$apksigner")"
  else
    fail 'Android build-tools with apksigner and aapt are required for APK verification'
  fi
  [[ -f tools/lumo-debug.keystore ]] && pass 'public Lumo test keystore (never a Play upload key)' ||
    fail 'tools/lumo-debug.keystore missing'
  mem_kb="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)"
  (( mem_kb >= 8000000 )) && pass "memory $((mem_kb / 1024 / 1024)) GiB" ||
    warn "memory $((mem_kb / 1024 / 1024)) GiB; Gradle release builds need about 8 GiB"
  disk_kb="$(df -Pk "$root" | awk 'NR == 2 {print $4}')"
  (( disk_kb >= 20000000 )) && pass "free disk $((disk_kb / 1024 / 1024)) GiB" ||
    warn "free disk $((disk_kb / 1024 / 1024)) GiB; SDK, NDK, Gradle and Godot need about 20 GiB"
  command -v xvfb-run >/dev/null && pass 'xvfb-run (Godot renderer regressions)' ||
    warn 'xvfb-run missing; Godot validate_project.sh skips its renderer regressions'
}

# Logs every command's output to the evidence folder and keeps its exit code.
logged() {
  local name="$1"
  shift
  printf '\n== %s: %s\n' "$name" "$*"
  "$@" 2>&1 | tee "$evidence_dir/$name.log"
  return "${PIPESTATUS[0]}"
}

clean_source() {
  [[ -z "$(git status --porcelain=v1 --untracked-files=normal)" ]] || {
    echo 'STOP: checkout contains changes/untracked files. Preserve owner work and use a clean build checkout.' >&2
    exit 3
  }
}

source_unchanged() {
  [[ "$(git rev-parse HEAD)" == "$original_head" ]] || { echo "STOP: Git HEAD changed during $1" >&2; exit 3; }
  git diff --quiet HEAD -- || { echo "STOP: Tracked source changed during $1" >&2; exit 3; }
}

ensure_godot() {
  bash scripts/install_godot_for_build.sh
  export PATH="${RUNNER_TEMP:-/tmp}/lumo-godot-engine-4.6.3:$PATH"
  command -v godot >/dev/null || { echo 'Godot binary missing after setup' >&2; exit 3; }
  [[ "$(godot --version)" == 4.6.3* ]] || { echo 'STOP: Wrong Godot engine for pinned Lumo source' >&2; exit 3; }
}

run_tests() {
  # Resolve packages first: the Dart content audit imports package:lumo_lernen.
  logged pub-get flutter pub get --enforce-lockfile
  logged proxy-tests node --test server/lumo-ai-proxy/test/*.test.js
  logged script-tests python3 -m unittest discover -s scripts/tests -p 'test_*.py'
  if command -v tesseract >/dev/null && python3 -c 'import PIL' 2>/dev/null; then
    logged android-qa-tests python3 -m unittest discover -s tools/android_qa/tests -p 'test_*.py'
  else
    echo 'SKIPPED: tools/android_qa unit tests need tesseract and Pillow' | tee "$evidence_dir/android-qa-tests.log"
  fi
  logged content-audit dart scripts/audit_content.dart
  logged repair-guard bash scripts/lumo_repair_guard.sh
  logged analyze flutter analyze --no-fatal-infos --no-fatal-warnings
  logged flutter-tests flutter test --no-pub --reporter=expanded --timeout=60s --concurrency=2
  source_unchanged tests
}

# The game's own suite (lumo-godot tools/validate_project.sh) at the exact pin.
run_godot_tests() {
  local repository revision checkout
  read -r repository revision < <(godot_pin)
  ensure_godot
  checkout="$(mktemp -d "${TMPDIR:-/tmp}/lumo-godot-tests.XXXXXXXX")"
  git -C "$checkout" init -q
  git -C "$checkout" fetch -q --depth 1 "$repository" "$revision"
  git -C "$checkout" checkout -q --detach FETCH_HEAD
  [[ "$(git -C "$checkout" rev-parse HEAD)" == "$revision" ]] || { echo 'STOP: Godot checkout is not the pin' >&2; exit 3; }
  [[ -f "$checkout/tools/validate_project.sh" ]] || { echo 'STOP: pinned Godot source has no validate_project.sh' >&2; exit 3; }
  command -v xvfb-run >/dev/null ||
    echo 'WARN: xvfb-run missing; validate_project.sh skips its renderer regressions' | tee "$evidence_dir/godot-renderer-skipped.txt"
  (cd "$checkout" && logged godot-validate env GODOT_BIN="$(command -v godot)" bash tools/validate_project.sh)
  [[ -z "$(git -C "$checkout" status --porcelain --untracked-files=no)" ]] || {
    echo 'STOP: Godot regressions changed tracked game source' >&2
    exit 3
  }
  printf '%s\n' "$revision" > "$evidence_dir/godot-tested-revision.txt"
  printf 'Godot regressions passed for %s (checkout %s)\n' "$revision" "$checkout"
}

write_evidence() {
  python3 - "$evidence_dir" "$original_head" "$started_at" <<'PY'
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

evidence, head, started = Path(sys.argv[1]), sys.argv[2], sys.argv[3]


def output(*command):
    result = subprocess.run(command, capture_output=True, text=True, check=True)
    return result.stdout + result.stderr


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1 << 20), b''):
            digest.update(block)
    return digest.hexdigest()


flutter = json.loads(subprocess.check_output(['flutter', '--version', '--machine'], text=True,
                                             stderr=subprocess.DEVNULL))
candidates = Path('dist/candidates')
candidates.mkdir(parents=True, exist_ok=True)
apks = []
for folder in (Path('dist'), Path('dist/x86_64')):
    apk, provenance_path = folder / 'Lumo-Lernen-Neu.apk', folder / 'BUILD-PROVENANCE.json'
    if not apk.is_file():
        continue
    provenance = json.loads(provenance_path.read_text())
    digest = sha256(apk)
    if provenance.get('sha256', digest) != digest:
        raise SystemExit(f'{apk} does not match its BUILD-PROVENANCE.json')
    abi = '-'.join(provenance['abis'])
    # Immutable name: a later build never overwrites an earlier candidate.
    name = f"Lumo-Lernen-{provenance['versionName']}+{provenance['versionCode']}-{head[:12]}-{abi}.apk"
    target = candidates / name
    if target.exists() and sha256(target) != digest:
        raise SystemExit(f'Refusing to replace a different candidate {target}')
    shutil.copyfile(apk, target)
    apks.append({'file': str(target), 'sha256': digest, 'bytes': apk.stat().st_size,
                 'package': provenance['package'], 'versionName': provenance['versionName'],
                 'versionCode': provenance['versionCode'], 'abis': provenance['abis'],
                 'targetSdk': provenance['targetSdk'],
                 'signingCertificateSha256': provenance['signingCertificateSha256'],
                 'godot': provenance['godot'], 'provenance': str(provenance_path)})
if not apks:
    raise SystemExit('No APK candidate to document')
(candidates / 'SHA256SUMS.txt').write_text(
    ''.join(f"{item['sha256']}  {Path(item['file']).name}\n" for item in apks))
report = {
    'kind': 'Lumo portable Android preview build (not a Play Store release)',
    'flutter_source_commit': head,
    'started_utc': started,
    'finished_utc': datetime.now(timezone.utc).isoformat(timespec='seconds'),
    'toolchain': {
        'flutter': flutter.get('frameworkVersion'),
        'flutter_framework_revision': flutter.get('frameworkRevision'),
        'dart': flutter.get('dartSdkVersion'),
        'java': output('java', '-version').strip().splitlines()[-3:],
        'godot': output('godot', '--version').strip(),
        'gradle_central_mirror': os.environ.get('LUMO_GRADLE_CENTRAL_MIRROR', '0'),
    },
    'host': {'platform': platform.platform(), 'cpus': os.cpu_count()},
    'apks': apks,
    'tests': 'scripts/portable-android.sh tests passed in this run (logs beside this file)',
    'device_test': 'NOT EXECUTED - install and play-test on an emulator or phone separately',
    'signing': 'public Lumo test key tools/lumo-debug.keystore; side-by-side package, no Play upload',
}
(evidence / 'PORTABLE-BUILD-EVIDENCE.json').write_text(json.dumps(report, indent=2) + '\n')
shutil.copyfile(evidence / 'PORTABLE-BUILD-EVIDENCE.json', candidates / 'PORTABLE-BUILD-EVIDENCE.json')
print(json.dumps(report, indent=2))
PY
}

case "$mode" in
  doctor)
    doctor android
    ;;
  tests)
    doctor tests
    clean_source
    run_tests
    printf 'Lumo tests passed for %s (logs: %s)\n' "$original_head" "$evidence_dir"
    ;;
  godot-tests)
    doctor godot
    run_godot_tests
    ;;
  preview-apk)
    started_at="$(date -u +%Y-%m-%dT%H:%M:%S+00:00)"
    # Fail on missing SDK pieces before spending time on the test suite.
    doctor android
    clean_source
    run_tests
    run_godot_tests
    logged ndk-preflight bash scripts/install_ndk_for_build.sh "$evidence_dir/ndk-preflight"
    # The existing build creates the native host, integrates Godot, and validates
    # the test APK certificate. This is NOT a Play-Store AAB signing pipeline.
    logged build bash scripts/build_unified_apk.sh
    [[ -s dist/Lumo-Lernen-Neu.apk ]] || { echo 'No APK candidate produced' >&2; exit 3; }
    if [[ "${LUMO_SPLIT_PER_ABI:-0}" == 1 ]]; then
      python3 scripts/verify_unified_apk.py dist/Lumo-Lernen-Neu.apk --abi arm64-v8a > "$evidence_dir/verification.json"
      python3 scripts/verify_unified_apk.py dist/x86_64/Lumo-Lernen-Neu.apk --abi x86_64 > "$evidence_dir/verification-x86_64.json"
    else
      python3 scripts/verify_unified_apk.py dist/Lumo-Lernen-Neu.apk > "$evidence_dir/verification.json"
    fi
    source_unchanged build
    sha256sum dist/Lumo-Lernen-Neu.apk | tee dist/APK-SHA256.txt
    write_evidence
    echo "Verified Lumo preview candidate in dist/candidates (evidence: $evidence_dir)."
    echo 'Google Play signing and device QA remain separate.'
    ;;
esac
