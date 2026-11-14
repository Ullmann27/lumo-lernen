set -euo pipefail
while IFS= read -r name; do
  test -n "$name"
  gh release upload "$VERSION_TAG" "publication/delivery/assets/$name" --repo "$GITHUB_REPOSITORY"
done < publication/delivery/audit/asset-names.txt
release_id="$(python3 -c 'import json; print(json.load(open("publication/created-release.json"))["id"])')"
gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$VERSION_TAG" > publication/current-tag.json
gh api "repos/$GITHUB_REPOSITORY/releases/$release_id" > publication/uploaded-draft.json
python3 scripts/verify_connect_four_delivery.py check-release \
  --delivery publication/delivery --tag publication/current-tag.json \
  --created publication/created-release.json --release publication/uploaded-draft.json --stage uploaded-draft
