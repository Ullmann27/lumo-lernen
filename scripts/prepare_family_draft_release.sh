#!/usr/bin/env bash
# Prepare a family-channel GitHub DRAFT for the next Lumo APK.
# Default is a dry run. Pass --create-draft to upload a DRAFT release.
# This script never publishes a non-draft release.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APK=""
VERIFICATION=""
LAST_PUBLISHED=""
RELEASES_JSON=""
CREATE_DRAFT=0
REPO="${GITHUB_REPOSITORY:-Ullmann27/lumo-lernen}"
SOURCE_SHA=""

usage() {
  cat <<'EOF'
Usage: scripts/prepare_family_draft_release.sh [options]

  --apk PATH              Signed family APK (default: dist/Lumo-Lernen-Neu.apk)
  --verification PATH     Output of verify_unified_apk.py
                          (default: dist/APK-VERIFICATION.json)
  --last-published N      Override the last published family versionCode
  --releases-json PATH    Offline GitHub /releases catalog for tests
  --source-sha SHA        Flutter source commit recorded in the notes
  --repo OWNER/NAME       GitHub repository (default Ullmann27/lumo-lernen)
  --create-draft          Create a DRAFT GitHub release (not published)
  -h, --help              Show this help

Without --create-draft the script only prints the intended tag, notes and
files. It never turns a draft into a published prerelease.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apk) APK="$2"; shift 2 ;;
    --verification) VERIFICATION="$2"; shift 2 ;;
    --last-published) LAST_PUBLISHED="$2"; shift 2 ;;
    --releases-json) RELEASES_JSON="$2"; shift 2 ;;
    --source-sha) SOURCE_SHA="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --create-draft) CREATE_DRAFT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

APK="${APK:-$ROOT/dist/Lumo-Lernen-Neu.apk}"
VERIFICATION="${VERIFICATION:-$ROOT/dist/APK-VERIFICATION.json}"
SOURCE_SHA="${SOURCE_SHA:-$(git rev-parse HEAD)}"

if [ ! -s "$APK" ]; then
  echo "APK missing: $APK" >&2
  exit 1
fi
if [ ! -s "$VERIFICATION" ]; then
  echo "Verification JSON missing: $VERIFICATION" >&2
  echo "Run: python3 scripts/verify_unified_apk.py \"$APK\" | tee dist/APK-VERIFICATION.json" >&2
  exit 1
fi

SIDECAR="$(dirname "$APK")/Lumo-Lernen-Neu.apk.sha256"
gate_args=(
  --pubspec "$ROOT/pubspec.yaml"
  --apk "$APK"
  --verification "$VERIFICATION"
  --source-sha "$SOURCE_SHA"
  --write-sha256 "$SIDECAR"
)
if [ -n "$LAST_PUBLISHED" ]; then
  gate_args+=(--last-published "$LAST_PUBLISHED")
fi
if [ -n "$RELEASES_JSON" ]; then
  gate_args+=(--releases-json "$RELEASES_JSON")
fi

REPORT="$(mktemp "${TMPDIR:-/tmp}/lumo-family-gate.XXXXXX.json")"
STAGED="$(mktemp -d "${TMPDIR:-/tmp}/lumo-family-draft.XXXXXX")"
cleanup() {
  rm -f "$REPORT"
  rm -rf "$STAGED"
}
trap cleanup EXIT

python3 "$ROOT/scripts/release_pipeline_gates.py" "${gate_args[@]}" | tee "$REPORT"

TAG="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tag"])' "$REPORT")"
TITLE="$(python3 -c 'import json,sys; info=json.load(open(sys.argv[1])); print("Lumo Lernen + Lumo Kart %s – Familienupdate (Draft)" % info["versionCode"])' "$REPORT")"
NOTES="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["releaseNotes"])' "$REPORT")"

# The installed updater accepts only this exact asset name on the tag.
cp "$APK" "$STAGED/Lumo-Lernen-Neu.apk"
(
  cd "$STAGED"
  sha256sum Lumo-Lernen-Neu.apk > Lumo-Lernen-Neu.apk.sha256
)
cp "$VERIFICATION" "$STAGED/APK-VERIFICATION.json"
if [ -s "$ROOT/dist/BUILD-PROVENANCE.json" ]; then
  cp "$ROOT/dist/BUILD-PROVENANCE.json" "$STAGED/BUILD-PROVENANCE.json"
fi
if [ -s "$ROOT/dist/GODOT-SOURCE.json" ]; then
  cp "$ROOT/dist/GODOT-SOURCE.json" "$STAGED/GODOT-SOURCE.json"
fi

echo
echo "Prepared DRAFT family release $TAG"
echo "Title: $TITLE"
echo "Repository: $REPO"
echo "Source: $SOURCE_SHA"
echo "Files:"
ls -l "$STAGED"
echo
printf '%s\n' "$NOTES"

if [ "$CREATE_DRAFT" -ne 1 ]; then
  echo "Dry run only. Re-run with --create-draft to upload a DRAFT (not a published update)."
  exit 0
fi

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  echo "Refusing to overwrite an existing tag or release: $TAG" >&2
  exit 1
fi

assets=("$STAGED/Lumo-Lernen-Neu.apk" "$STAGED/Lumo-Lernen-Neu.apk.sha256" "$STAGED/APK-VERIFICATION.json")
if [ -f "$STAGED/BUILD-PROVENANCE.json" ]; then
  assets+=("$STAGED/BUILD-PROVENANCE.json")
fi
if [ -f "$STAGED/GODOT-SOURCE.json" ]; then
  assets+=("$STAGED/GODOT-SOURCE.json")
fi

gh release create "$TAG" \
  "${assets[@]}" \
  --repo "$REPO" \
  --target "$SOURCE_SHA" \
  --title "$TITLE" \
  --notes "$NOTES" \
  --draft \
  --prerelease

gh api "repos/$REPO/releases/tags/$TAG" > "$STAGED/created.json"
python3 - "$STAGED/created.json" "$TAG" <<'PY'
import json
import sys

record = json.load(open(sys.argv[1], encoding="utf-8"))
tag = sys.argv[2]
if record.get("draft") is not True:
    raise SystemExit("Created release is not a draft; refusing to treat it as published")
if record.get("tag_name") != tag:
    raise SystemExit(f"Unexpected tag {record.get('tag_name')}")
matching = [
    asset
    for asset in record.get("assets") or []
    if asset.get("name") == "Lumo-Lernen-Neu.apk"
]
if len(matching) != 1:
    raise SystemExit("Draft is missing the exact Lumo-Lernen-Neu.apk asset")
print("DRAFT_FAMILY_RELEASE_READY", tag, record.get("html_url"))
print("Publish later as a prerelease (not Latest) after Heinz approves.")
PY
