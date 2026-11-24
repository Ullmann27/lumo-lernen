# Gezielte Prüfung der ersten c5-Integration

Quellen und verbleibende Grenzen: `../../C5_INTEGRATION_REVIEW.md`.
SDK: Flutter 3.44.9 / Dart 3.12.2. Die hier gespeicherten Abschlussläufe
verwendeten den gemeinsamen Lock mit `flock --close`.

## Befehle

```sh
flutter test --no-pub test/learning/sentence_prompt_privacy_test.dart test/learning/interactive_task_workspace_test.dart test/tutoring/native_pattern_activity_test.dart --reporter expanded
flutter test --no-pub test/learning/nextgen_task_quality_test.dart test/learning/nextgen_answer_payload_test.dart test/learning/nextgen_task_hint_precision_test.dart test/safe_fallback_pool_test.dart test/learning/cross_grade_contract_test.dart test/cross_grade_second_chance_test.dart test/cross_grade_practice_storage_hardening_test.dart test/learning_modules/learning_module_progress_test.dart test/design/learning_registered_routes_test.dart test/design/learning_adventure_layout_test.dart --reporter expanded
flutter test --no-pub test/learning/nextgen_pattern_pipeline_test.dart test/design/learning_registered_routes_test.dart --reporter expanded
LUMO_WORKSPACE_CAPTURES=docs/nextgen/evidence/c5_integration_20261115 flutter test --no-pub test/learning/interactive_task_workspace_test.dart --name 'real .* view fits' --reporter expanded
```

`analyze.log` enthält den aktuellen gezielten Analyzer-Lauf über alle
27 geänderten/neuen Dart-Dateien. `integration_tests.log` protokolliert
den dritten Befehl. Der vierte Befehl ist die reproduzierbare Anweisung für
den separat gestarteten Aufnahmelauf; sein Ergebnis und PNGs sind noch
nicht Bestandteil des Kern-Commits. Die ersten beiden
Befehle wurden zuvor tatsächlich mit 35 beziehungsweise 141 bestandenen
Tests ausgeführt; ihre Konsolenausgabe liegt im Sitzungsverlauf, nicht als
nachträglich erfundenes Log in diesem Ordner.

Der Aufnahmelauf verwendet `AdaptiveTaskRenderer` im Flutter-Widgettest
nach realen Testeingaben. Dateinamen bezeichnen Viewport und Modell.
Es entstehen keine Android-Emulator- oder Hardwareaufnahmen. Der
Faltzustand ist eine Layoutgröße; Audio, native 3D-Activity und physischer
Gerätewechsel werden dadurch nicht belegt.
