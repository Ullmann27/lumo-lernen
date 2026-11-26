#!/usr/bin/env bash
# Baut beide Videos aus Szenen, echten Aufnahmen (build/cap) und erzeugter Musik.
#   ./build.sh            beide Formate
#   ./build.sh land|port  nur eines
# Voraussetzung: build/cap ist gefüllt (capture/*.sh, dann prepare_assets.py).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/teile
DAUER=140
JOBS=${JOBS:-4}
python3 mix_audio.py "$DAUER" build/ton.m4a
for FORMAT in ${1:-land port}; do
  pids=()
  for ((i = 0; i < JOBS; i++)); do
    von=$(python3 -c "print($DAUER*$i/$JOBS)"); bis=$(python3 -c "print($DAUER*($i+1)/$JOBS)")
    node render.mjs --format="$FORMAT" --from="$von" --to="$bis" --out="build/teile/${FORMAT}_$i.mp4" &
    pids+=($!)
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
  : > "build/teile/$FORMAT.txt"
  for ((i = 0; i < JOBS; i++)); do echo "file '${FORMAT}_$i.mp4'" >> "build/teile/$FORMAT.txt"; done
  name=$([ "$FORMAT" = port ] && echo lumo_lernen_werbevideo_hochformat_1080x1920 || echo lumo_lernen_werbevideo_querformat_1920x1080)
  ffmpeg -v error -y -f concat -safe 0 -i "build/teile/$FORMAT.txt" -i build/ton.m4a -c:v copy -c:a copy -shortest -movflags +faststart "build/$name.mp4"
  echo "Fertig: build/$name.mp4"
done
