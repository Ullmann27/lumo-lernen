set -euo pipefail
export PATH="$GITHUB_WORKSPACE/.ci-python/bin:$PATH"
native_revision="$(python3 -c 'import json; print(json.load(open("config/godot-source.json"))["revision"])')"
native_source="$RUNNER_TEMP/lumo-native-acceptance"
native_logs="$GITHUB_WORKSPACE/acceptance-native"
dream_logs="$native_logs/dream"
test "$(git -C "$native_source" rev-parse HEAD)" = "$native_revision"
test "$(git -C "$native_source" rev-parse HEAD:tools/verify_dream_rasters.py)" = da8eed7d6383fcbc82a03596518a5fcc3b9a00c5
printf '%s  %s\n' f7296a802d15c382dbcc77640373a0f53e30306fcaab3de869549ff1656de89d "$native_source/tools/verify_dream_rasters.py" | sha256sum -c -
test ! -e "$dream_logs" && test ! -L "$dream_logs"
test ! -e "$native_logs/dream-verifier-original.py" && test ! -L "$native_logs/dream-verifier-original.py"
cp "$native_source/tools/verify_dream_rasters.py" "$native_logs/dream-verifier-original.py"
cmp "$native_source/tools/verify_dream_rasters.py" "$native_logs/dream-verifier-original.py"
cd "$native_source"
python3 -c 'from PIL import Image; print("Pinned-native Dream raster verification ready")'
LUMO_DREAM_LOG_DIR="$dream_logs" LUMO_EXPECTED_NATIVE_SHA="$native_revision" \
  bash tools/validate_dream_connections.sh 2>&1 | tee "$native_logs/dream-runner.log"
