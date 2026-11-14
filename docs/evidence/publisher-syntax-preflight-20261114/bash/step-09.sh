set -euo pipefail
gh api "repos/$GITHUB_REPOSITORY/actions/runs/$ACCEPTANCE_RUN" > publication/metadata/run.json
gh api "repos/$GITHUB_REPOSITORY/actions/runs/$ACCEPTANCE_RUN/jobs?per_page=100" > publication/metadata/jobs.json
gh api "repos/$GITHUB_REPOSITORY/actions/runs/$ACCEPTANCE_RUN/artifacts?per_page=100" > publication/metadata/artifacts.json
gh api "repos/$GITHUB_REPOSITORY/pulls/$ACCEPTANCE_PR" > publication/metadata/pull.json
python3 scripts/verify_connect_four_delivery.py check-current \
  --delivery publication/delivery --metadata publication/metadata \
  --pull-request "$ACCEPTANCE_PR" --bundle-archive publication/original-bundle.zip \
  --bundle-artifact-id "$BUNDLE_ARTIFACT_ID"
release_id="$(python3 -c 'import json; print(json.load(open("publication/created-release.json"))["id"])')"
gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$VERSION_TAG" > publication/prepublish-tag.json
gh api "repos/$GITHUB_REPOSITORY/releases/$release_id" > publication/prepublish-draft.json
python3 scripts/verify_connect_four_delivery.py check-release \
  --delivery publication/delivery --tag publication/prepublish-tag.json \
  --created publication/created-release.json --release publication/prepublish-draft.json --stage uploaded-draft
gh api --method PATCH "repos/$GITHUB_REPOSITORY/releases/$release_id" \
  --input publication/delivery/audit/publish-release.json > publication/published-release.json
gh api "repos/$GITHUB_REPOSITORY/git/ref/tags/$VERSION_TAG" > publication/published-tag.json
python3 scripts/verify_connect_four_delivery.py check-release \
  --delivery publication/delivery --tag publication/published-tag.json \
  --created publication/created-release.json --release publication/published-release.json --stage published
