set -euo pipefail
sudo apt-get -o Acquire::Retries=2 update -qq
sudo apt-get -o Acquire::Retries=2 install -y xvfb libgl1-mesa-dri libglx-mesa0 ffmpeg
export PATH="$GITHUB_WORKSPACE/.ci-python/bin:$PATH"
native_revision="$(python3 -c 'import json; print(json.load(open("config/godot-source.json"))["revision"])')"
native_source="$RUNNER_TEMP/lumo-native-acceptance"
native_logs="$GITHUB_WORKSPACE/acceptance-native"
mkdir -p "$native_logs/user-data/godot/app_userdata/Lumo 3D"
git init "$native_source"
git -C "$native_source" remote add origin https://github.com/Ullmann27/lumo-godot.git
git -C "$native_source" fetch --depth 1 origin "$native_revision"
git -C "$native_source" checkout --detach FETCH_HEAD
test "$(git -C "$native_source" rev-parse HEAD)" = "$native_revision"
printf '%s\n' "$native_revision" > "$native_logs/source-sha.txt"
export XDG_DATA_HOME="$native_logs/user-data"
export XDG_CONFIG_HOME="$native_logs/user-config"
export XDG_CACHE_HOME="$native_logs/user-cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
cd "$native_source"
python3 -c 'from PIL import Image; print("Pinned-native raster verification ready")'
python3 tools/validate_project.py 2>&1 | tee "$native_logs/project.log"
bash tools/validate_project.sh 2>&1 | tee "$native_logs/legacy-gameplay.log"
LUMO_2014_LOG_DIR="$native_logs/2014" bash tools/validate_2014.sh
if [ "$REQUIRE_TECHNICAL_ART" = true ]; then
  LUMO_ART_LOG_DIR="$native_logs/technical-art" bash tools/validate_technical_art.sh
fi
if [ "$REQUIRE_ACTION_STAGE" = true ]; then
  LUMO_ACTION_LOG_DIR="$native_logs/action-stage" bash tools/validate_action_stage.sh
fi
LUMO_NEXTGEN_LOG_DIR="$native_logs/nextgen" bash tools/validate_nextgen.sh 2>&1 | tee "$native_logs/nextgen-runner.log"
