#!/usr/bin/env bash
# Exact existing Gradle NDK requirement; documented sdkmanager package syntax:
# https://developer.android.com/tools/sdkmanager
# No license acceptance, alternate CLI, NDK fallback or cache-wide deletion.
set -euo pipefail

if (( $# > 1 )); then
  echo 'Usage: install_ndk_for_build.sh [evidence-directory]' >&2
  exit 2
fi
readonly NDK_REVISION='28.2.13676358'
readonly NDK_PACKAGE="ndk;$NDK_REVISION"
SDK_DIRECTORY="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$SDK_DIRECTORY" || ! -d "$SDK_DIRECTORY" ]]; then
  echo '[NDKPreflight] FAIL: existing Android SDK directory is required' >&2
  exit 1
fi
SDK_DIRECTORY="$(cd "$SDK_DIRECTORY" && pwd -P)"
readonly NDK_DIRECTORY="$SDK_DIRECTORY/ndk/$NDK_REVISION"
INSTALL_TIMEOUT="${LUMO_NDK_TIMEOUT_SECONDS:-600}"
if [[ ! "$INSTALL_TIMEOUT" =~ ^[1-9][0-9]{0,2}$ ]] ||
   (( INSTALL_TIMEOUT < 1 || INSTALL_TIMEOUT > 600 )); then
  echo '[NDKPreflight] FAIL: install timeout must be between 1 and 600 seconds' >&2
  exit 1
fi
TOTAL_TIMEOUT="${LUMO_NDK_TOTAL_TIMEOUT_SECONDS:-540}"
if [[ ! "$TOTAL_TIMEOUT" =~ ^[1-9][0-9]{0,2}$ ]] ||
   (( TOTAL_TIMEOUT < 11 || TOTAL_TIMEOUT > 540 )); then
  echo '[NDKPreflight] FAIL: total timeout must be between 11 and 540 seconds' >&2
  exit 1
fi
# Share one deadline across both installations, uninstall and compiler checks.
# Reserve the kill grace inside that deadline, leaving CI's ten-minute step room.
readonly NDK_DEADLINE=$((SECONDS + TOTAL_TIMEOUT))
command -v timeout >/dev/null || { echo '[NDKPreflight] FAIL: timeout is missing' >&2; exit 1; }
EVIDENCE_ROOT="${1:-${RUNNER_TEMP:-/tmp}/lumo-ndk-preflight}"
mkdir -p "$EVIDENCE_ROOT"
EVIDENCE_DIRECTORY="$(mktemp -d "$EVIDENCE_ROOT/ndk-28.2.13676358.XXXXXX")"
echo "[NDKPreflight] Original evidence: $EVIDENCE_DIRECTORY"

run_logged() {
  local log_file="$1" limit="$2"
  shift 2
  local statuses remaining
  remaining=$((NDK_DEADLINE - SECONDS - 10))
  if (( remaining <= 0 )); then
    echo '[NDKPreflight] FAIL: shared time budget exhausted' | tee "$log_file" >&2
    return 124
  fi
  if (( limit > remaining )); then limit="$remaining"; fi
  set +e
  timeout --kill-after=10 "$limit" "$@" </dev/null 2>&1 | tee "$log_file"
  statuses=("${PIPESTATUS[@]}")
  set -e
  if (( statuses[1] != 0 )); then
    echo '[NDKPreflight] FAIL: original command log could not be retained' >&2
    return 125
  fi
  return "${statuses[0]}"
}

verify_ndk() {
  local label="$1" revision clang compiler_status=0
  if [[ -L "$NDK_DIRECTORY" ]]; then
    echo '[NDKPreflight] FAIL: refusing a symlinked NDK directory' >&2
    return 2
  fi
  if [[ ! -f "$NDK_DIRECTORY/source.properties" ]]; then
    echo '[NDKPreflight] FAIL: exact NDK is missing or incomplete' >&2
    return 1
  fi
  # Exactly one matching property; duplicate, prefix and wrong revisions fail.
  revision="$(awk '/^[[:space:]]*Pkg\.Revision[[:space:]]*=/ {
    sub(/^[^=]*=[[:space:]]*/, ""); sub(/[[:space:]]*$/, ""); print
  }' "$NDK_DIRECTORY/source.properties")"
  if [[ "$revision" != "$NDK_REVISION" ]]; then
    echo "[NDKPreflight] FAIL: expected Pkg.Revision=$NDK_REVISION, observed '$revision'" >&2
    return 2
  fi
  clang="$NDK_DIRECTORY/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
  if [[ ! -x "$clang" ]]; then
    echo '[NDKPreflight] FAIL: actual NDK clang executable is missing' >&2
    return 1
  fi
  run_logged "$EVIDENCE_DIRECTORY/clang-$label.log" 30 "$clang" --version || compiler_status=$?
  if (( compiler_status != 0 )); then
    echo '[NDKPreflight] FAIL: actual NDK clang --version failed' >&2
    # A present compiler's loader, execution, timeout or evidence failure is
    # fatal; it is not an incomplete ZIP package eligible for reinstall.
    return 126
  fi
  if ! grep -Eq 'clang version [0-9]+\.' "$EVIDENCE_DIRECTORY/clang-$label.log"; then
    echo '[NDKPreflight] FAIL: executable did not identify itself as clang' >&2
    return 2
  fi
}

# A pre-existing incomplete or differently labelled package is never silently
# treated as a fresh install. Reuse only the actually verified package.
if [[ -e "$NDK_DIRECTORY" || -L "$NDK_DIRECTORY" ]]; then
  if verify_ndk reuse; then
    echo "[NDKPreflight] PASS: verified existing $NDK_PACKAGE; no installation"
    exit 0
  fi
  exit 1
fi

SDK_MANAGER="$SDK_DIRECTORY/cmdline-tools/latest/bin/sdkmanager"
if [[ ! -x "$SDK_MANAGER" ]]; then
  SDK_MANAGER="$(command -v sdkmanager || true)"
fi
if [[ -z "$SDK_MANAGER" || ! -x "$SDK_MANAGER" ]]; then
  echo '[NDKPreflight] FAIL: existing official sdkmanager is required' >&2
  exit 1
fi

for attempt in 1 2; do
  install_log="$EVIDENCE_DIRECTORY/sdkmanager-install-$attempt.log"
  install_status=0
  run_logged "$install_log" "$INSTALL_TIMEOUT" "$SDK_MANAGER" \
    "--sdk_root=$SDK_DIRECTORY" --install "$NDK_PACKAGE" || install_status=$?
  verification_status=0
  verify_ndk "$attempt" || verification_status=$?
  if (( install_status == 0 && verification_status == 0 )); then
    echo "[NDKPreflight] PASS: installed and verified exact $NDK_PACKAGE"
    exit 0
  fi
  if (( attempt != 1 || verification_status != 1 ||
        (install_status != 0 && install_status != 1) )) ||
     [[ "${LUMO_NDK_DISPOSABLE_RUNNER:-}" != 1 ]] ||
     ! grep -Eq 'Error reading Zip content from a SeekableByteChannel|Archive is not a ZIP archive|invalid ZIP archive' "$install_log"; then
    echo "[NDKPreflight] FAIL: install/verification failed (sdkmanager exit $install_status, verification $verification_status); no further attempt" >&2
    exit 1
  fi
  echo '[NDKPreflight] Confirmed invalid ZIP on explicitly disposable runner; one bounded reinstall'
  if ! run_logged "$EVIDENCE_DIRECTORY/sdkmanager-uninstall.log" 120 \
      "$SDK_MANAGER" "--sdk_root=$SDK_DIRECTORY" --uninstall "$NDK_PACKAGE"; then
    echo '[NDKPreflight] FAIL: exact-package uninstall failed; no reinstall' >&2
    exit 1
  fi
  if [[ -L "$NDK_DIRECTORY" ]]; then
    echo '[NDKPreflight] FAIL: refusing to move a symlinked NDK directory' >&2
    exit 1
  fi
  if [[ -e "$NDK_DIRECTORY" ]]; then
    # Retain only this exact incomplete package as evidence. Other versions,
    # licenses, SDK caches and the original failed installation log stay intact.
    mv "$NDK_DIRECTORY" "$EVIDENCE_DIRECTORY/incomplete-ndk-$NDK_REVISION"
  fi
done
