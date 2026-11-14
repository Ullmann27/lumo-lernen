set -euo pipefail
gh api --paginate --slurp "repos/$GITHUB_REPOSITORY/releases?per_page=100" > publication/metadata/releases.json
gh api "repos/$GITHUB_REPOSITORY/git/matching-refs/tags/$VERSION_TAG" > publication/metadata/tags.json
python3 scripts/verify_connect_four_delivery.py check-vacant \
  --delivery publication/delivery --metadata publication/metadata
gh api --method POST "repos/$GITHUB_REPOSITORY/git/refs" \
  --input publication/delivery/audit/create-tag.json > publication/created-tag.json
python3 scripts/verify_connect_four_delivery.py check-tag \
  --delivery publication/delivery --tag publication/created-tag.json
gh api --method POST "repos/$GITHUB_REPOSITORY/releases" \
  --input publication/delivery/audit/create-release.json > publication/created-release.json
release_id="$(python3 -c 'import json; print(json.load(open("publication/created-release.json"))["id"])')"
gh api "repos/$GITHUB_REPOSITORY/releases/$release_id" > publication/empty-draft.json
python3 scripts/verify_connect_four_delivery.py check-release \
  --delivery publication/delivery --tag publication/created-tag.json \
  --created publication/created-release.json --release publication/empty-draft.json --stage empty-draft
