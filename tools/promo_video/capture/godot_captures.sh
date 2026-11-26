#!/usr/bin/env bash
# Echte Renderer-Aufnahmen der Spiele aus lumo-godot (Godot 4.6.3, gl_compatibility unter xvfb).
# Nutzt die dort vorhandenen Capture-Skripte unter scripts/tests/.
#   capture/godot_captures.sh <lumo-godot-checkout> <godot-binary> <zielordner>
# Hinweis: Mit Software-Renderer dauert das Paket rund eine Stunde.
set -uo pipefail
REPO=${1:?lumo-godot fehlt}; G=${2:?Godot-Binary fehlt}; O=$(realpath -m "${3:?Zielordner fehlt}")
mkdir -p "$O"; cd "$REPO"
[ -d .godot/imported ] || timeout 1800 "$G" --headless --path . --import > "$O/import.log" 2>&1
run() { name=$1; shift
  timeout 1800 xvfb-run -a -s '-screen 0 2500x2500x24' "$G" --path . --audio-driver Dummy \
    --rendering-method gl_compatibility "$@" > "$O/$name.log" 2>&1; echo "$name rc=$?"; }
LUMO_CAPTURE_DIR=$O/cards run cards --script res://scripts/tests/cards_table_capture.gd &
run chess --script res://scripts/tests/chess_visual_capture.gd -- "$O/chess" 1.0 &
wait
LUMO_MEMORY_CAPTURE_DIR=$O/memory run memory --script res://scripts/tests/memory_table_capture.gd &
LUMO_CAPTURE_DIR=$O/c4 run c4 --script res://scripts/tests/connect_four_visual_capture.gd -- --capture &
for t in vulkanexpress_3100 wolkensturm_3300 kristallflut_2800; do
  run "sig_$t" --script res://scripts/tests/kart_signature_capture.gd -- --track=$t --out="$O/sig_$t" \
    --at=120,520,980,1500 --size=1920x1080 --profile=high
done
wait
run race --script res://scripts/tests/kart_production_race_capture.gd &   # schreibt nach evidence/lumo_kart_runtime/review/
run world --script res://scripts/tests/lumo_world_capture.gd -- --out="$O/world" &
wait
LUMO_CAPTURE_DIR=$O/run LUMO_RUN_QUICK=1 LUMO_RUN_SKIP_MEASURE=1 run run --script res://scripts/tests/lumo_run_capture.gd &
mkdir -p "$O/skypost"; run skypost --script res://scripts/tests/sky_post_world_probe.gd -- out="$O/skypost" size=1280x720 &
LUMO_CAPTURE_DIR=$O/quiz run quiz --script res://scripts/tests/quiz_studio_runtime.gd -- --capture --fixture &
wait
