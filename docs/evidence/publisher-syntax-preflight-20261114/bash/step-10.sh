set -euo pipefail
url="$(python3 -c 'import json; print(json.load(open("publication/delivery/publication-plan.json"))["download_url"])')"
curl --fail --location --retry 4 --retry-all-errors --retry-delay 5 --max-time 300 \
  "$url" -o publication/public-Lumo-Lernen-Neu.apk
python3 scripts/verify_connect_four_delivery.py verify-public \
  --delivery publication/delivery --tag publication/published-tag.json \
  --created publication/created-release.json --release publication/published-release.json \
  --apk publication/public-Lumo-Lernen-Neu.apk --receipt publication/PUBLIC-APK-RECEIPT.json
cat publication/PUBLIC-APK-RECEIPT.json
