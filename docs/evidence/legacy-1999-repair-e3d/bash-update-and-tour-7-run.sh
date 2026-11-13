set -euo pipefail
python3 scripts/verify_unified_apk.py candidate/dist/Lumo-Lernen-Neu.apk --abi arm64-v8a --expectations-repository historical-1999-source --expectations-revision c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf > update-proof/arm64-verification.json
python3 scripts/verify_unified_apk.py candidate/dist/x86_64/Lumo-Lernen-Neu.apk --abi x86_64 --expectations-repository historical-1999-source --expectations-revision c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf > update-proof/x86-verification.json
python3 scripts/verify_android_apk.py baseline/dist/x86_64/Lumo-Lernen-Neu.apk > update-proof/baseline-signature.txt
sha256sum candidate/dist/Lumo-Lernen-Neu.apk candidate/dist/x86_64/Lumo-Lernen-Neu.apk baseline/dist/x86_64/Lumo-Lernen-Neu.apk > update-proof/apk-sha256.txt

