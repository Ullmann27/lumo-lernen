# TEST_RESULTS · LUMO 2040 Memory (`lumo-2040/memory-20261117`)

Stand: 17.11.2026, ca. 13:20 Europe/Vienna. Flutter 3.44.9 (`/home/box/sdk/env.sh`).

## Grün
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: exit 0, 278 Hinweise. Das ist dieselbe Zahl wie auf der Basis `e823a5c9`, also keine neuen Hinweise.
- `flutter test test/games/ test/academy_grade_3_4_visible_navigation_test.dart test/home_3d_workshop_entry_test.dart`: **275 Tests, alle grün.** Stand `5a79c14c`.
- Darin enthalten:
  - der neue `memory_menu_entry_regression_test`,
  - die vorher roten `memory_result_frame_test` und `academy_grade_3_4_visible_navigation_test`,
  - der neue `memory_visual_capture_test`.

## Ursache belegt
`memory_menu_entry_regression_test` ist **rot**, sobald `lumo_memory_game.dart` aus 2036 (`4af64ec5`) eingesetzt ist („Entry must not open the native table session“). Mit diesem Branch ist er **grün**.

## Nicht gelaufen
- Volle `flutter test`-Suite: NOT RUN lokal, weil zu teuer. Das übernimmt die CI.
- APK-Bau: NOT RUN lokal (CI-Workflow `lumo-einfach-apk`).
- DEVICE TEST NOT RUN · FOLD7 NOT RUN. Das tatsächliche Absturzbild auf dem Gerät (Logcat) ist nicht belegt.

## Bilder (Widget-Test-Rendering, kein Gerät)
- Vorher: `/workspace/lumo/artifacts/2040/memory/before/flutter/`.
- Nachher: `/workspace/lumo/artifacts/2040/memory/after/flutter/`.
