set -euo pipefail
test "$(git -C qa-source rev-parse HEAD)" = "$QA_SHA"
python3 qa-source/scripts/run_connect_four_small_result_actions_qa.py \
  --qa "$GITHUB_WORKSPACE/qa-source" \
  --host "$GITHUB_WORKSPACE/frozen-host" \
  --native "$GITHUB_WORKSPACE/frozen-native" \
  --output "$GITHUB_WORKSPACE/qa-evidence/preflight" --preflight
