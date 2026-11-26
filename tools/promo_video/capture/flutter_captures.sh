#!/usr/bin/env bash
# Echte Bildschirmfotos der Lern-App: nutzt die vorhandenen Capture-Tests der App
# (fiktive Profile wie „Mia“ bzw. Demo-Daten, keine echten Kinderdaten).
#   capture/flutter_captures.sh <zielordner>
set -euo pipefail
F=$(realpath -m "${1:?Zielordner fehlt}")
cd "$(dirname "$0")/../../.."
LUMO_TOUR_DIR=$F/tour LUMO_NACHHILFE_CAPTURES=$F/nachhilfe A5_CAPTURES=$F/a5 A6_CAPTURES=$F/a6 A3_CAPTURES=$F/a3 \
LUMO_LOGIC_CAPTURES=$F/logic LUMO_HUB_CAPTURES=$F/hub LUMO_LESSON_CAPTURES=$F/lesson \
flutter test \
  test/design/app_tour_capture_test.dart \
  test/tutoring/lumo_nachhilfe_capture_test.dart \
  test/design/a5_verstaendnis_capture_test.dart \
  test/parents/lumo_insight_kennzahlen_test.dart \
  test/design/a3_eltern_schule_capture_test.dart \
  test/games/logic_games_ui_test.dart \
  test/games/spielwelt_hub_capture_test.dart \
  test/design/lesson_premium_capture_test.dart
