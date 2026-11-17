# TEST_RESULTS – lumo-nullpunkt/integration-20261117 (lumo-lernen) – Stand 17.11.2026 13:30 (Europe/Vienna)

Abbruch wegen Nutzungslimit (90 %). **Nicht nach main gemergt.**

- Basis: `integration/lumo-original-assets-readiness-20261117` @ 7e71dd07 (enthält #527 LUMO 2037 Memory und integration/lumo-playready). Dazu nur Doku-/Beleg-Branches (B) und No-op-Merges (A), siehe `docs/handover/BRANCH-INVENTUR-20261117.md`.
- Godot-Pin `config/godot-source.json` unverändert bb478880 (ohne die Godot-Reparaturen aus lumo-godot PR #197).
- Lokal: `flutter analyze` rc=0 (278 Hinweise, keine Fehler); `flutter test` gezielt (smoke_main_screens, test/games, embedded_game_service): 282 PASS, 1 FAIL `test/games/memory_result_frame_test.dart` („Memory result waits for durable reward…“). Memory-Absturzfix liegt auf lumo-2040/memory-20261117 (#529), nicht integriert.
- Volle Testsuite: NOT RUN (Kosten). APK: CI-Workflow „Build Android Debug APK“ auf diesem Zweig manuell gestartet (kein Release).
- Offen: Integration-2 (lumo-2040/*, lumo-kart/*), Pin-Update auf reparierten Godot-Stand, Memory-Fix, main-Merge. DEVICE/FOLD7 NOT RUN.
