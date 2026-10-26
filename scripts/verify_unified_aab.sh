#!/usr/bin/env bash
# A staging AAB from the SAME build host and app inputs as the verified APKs.
set -euo pipefail
readonly BUNDLETOOL_VERSION='1.18.3'
readonly BUNDLETOOL_SHA256='a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29'
directory=build/lumo-aab-verification
mkdir -p "$directory" dist/aab
jar="$directory/bundletool-all-$BUNDLETOOL_VERSION.jar"
if [ ! -f "$jar" ]; then
  curl --fail --location --silent --show-error --retry 3 \
    "https://github.com/google/bundletool/releases/download/$BUNDLETOOL_VERSION/bundletool-all-$BUNDLETOOL_VERSION.jar" \
    --output "$jar"
fi
printf '%s  %s\n' "$BUNDLETOOL_SHA256" "$jar" | sha256sum -c -
bundle=build/app/outputs/bundle/release/app-release.aab
test -s "$bundle"
java -jar "$jar" validate --bundle="$bundle"
# No keys are generated. This is the same public TEST key as the APKs.
java -jar "$jar" build-apks --bundle="$bundle" --output="$directory/candidate.apks" \
  --mode=universal --overwrite --ks=tools/lumo-debug.keystore \
  --ks-key-alias=androiddebugkey --ks-pass=pass:android --key-pass=pass:android
unzip -p "$directory/candidate.apks" universal.apk > "$directory/universal.apk"
python3 scripts/verify_unified_apk.py "$directory/universal.apk" > "$directory/APK-VERIFICATION.json"
python3 scripts/verify_unified_aab.py "$bundle" "$directory/APK-VERIFICATION.json" \
  | tee dist/aab/AAB-PROVENANCE.json
cp "$bundle" dist/aab/Lumo-Lernen-Test-Candidate.aab
(cd dist/aab && sha256sum Lumo-Lernen-Test-Candidate.aab > SHA256SUMS.txt)
