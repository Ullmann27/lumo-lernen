#!/usr/bin/env bash
set -euo pipefail

MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ ! -f "$MANIFEST" ]; then
  echo "AndroidManifest.xml not found"
  exit 1
fi

if ! grep -q 'xmlns:tools=' "$MANIFEST"; then
  sed -i 's|<manifest |<manifest xmlns:tools="http://schemas.android.com/tools" |' "$MANIFEST" || true
fi

if ! grep -q 'android.permission.RECORD_AUDIO' "$MANIFEST"; then
  sed -i '/<manifest /a\    <uses-permission android:name="android.permission.RECORD_AUDIO"/>' "$MANIFEST"
fi

if ! grep -q 'android.permission.CAMERA' "$MANIFEST"; then
  sed -i '/<manifest /a\    <uses-permission android:name="android.permission.CAMERA"/>\n    <uses-feature android:name="android.hardware.camera" android:required="false"/>' "$MANIFEST"
fi

if ! grep -q 'android.speech.RecognitionService' "$MANIFEST"; then
  sed -i 's|</manifest>|    <queries>\n        <intent>\n            <action android:name="android.speech.RecognitionService"/>\n        </intent>\n        <intent>\n            <action android:name="android.intent.action.TTS_SERVICE"/>\n        </intent>\n    </queries>\n</manifest>|' "$MANIFEST"
fi

cat "$MANIFEST"
