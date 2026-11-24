# TEST_RESULTS – lumo-abschluss/integration-20261124 (lumo-lernen) – Abschluss 24.11.2026 (Europe/Vienna)

Freigabe: Heinz direkt 24.11. 15:52 (testen, integrieren, nach grüner CI nach main, APK). Korrektur Heinz 15:55: keine Parallel-App; APK muss die installierte App (vc 2078) aktualisieren, nur auf GitHub bauen.

## Basis und Merges (nur Merge-Commits, kein Force-Push)
- Basis: `grok/schule-demo-20261124` @ 2eac99a6 (Branch selbst unverändert).
- B gemergt: `delivery/lumo-schule-demo-20261124` @4e656629 (Demo-Lieferung 2079, Kart-PCK-Probe 10 Fahrer), `grok/schule-mathe-audit-20261124` @132daf61 (#548), `grok/schule-nachdemo-design-20261124` @55520d54 (#549, vorheriges Design zurück + Icon im Debug-Build; Heinz: „finde unsere vorherigen besser“), `lumo-hauptbot/lernen-phase-b-20261124` @fae7b368 (enthält d0f0cadc), `lumo-hauptbot/schule-ci-fix-20261124` @c400ec67, `feature/unified-lumo-open-world-20261123` @8b375c13 (#540, nur noch 3 Test-/Toolchain-Commits offen).
- A enthalten: #529 `lumo-2040/memory-20261117` – Code-Commits b93aef5b und 5a79c14c sind patch-identisch enthalten (`git cherry`: „-“), Memory-Look über 95c7fa71 und danach weiterentwickelt; nur der Doku-Commit e5dbe5ca fehlt (Konflikt nur in TEST_RESULTS.md/lumo_memory_game.dart, daher nicht gemergt). #545, #546 enthalten.
- C nicht gemergt: #530 `lumo-2040/tutor-20261117` @58549eae (WIP M1, Einstieg verborgen; Konflikte in 5 Dateien), `agent/sprache` @42bbb2fa (Konflikt lumo_learning_dialogue_intent.dart + Test), `agent/tutor3d` (WIP), `fix/lumo-2077-android-qa-20261124`, `integration/lumo-kart-final-2077`, `integration/lumo-world-cards-20261123` (Konflikte in tools/android_qa/tests; dieselben Tests wurden in a7626c17 auf der 2078-Linie überarbeitet).
- D überholt/nicht Integrationsgegenstand: `delivery/lumo-2037-memory-werkstatt-20261117` (2037, überholt), `support/lumo-2078-*`, `checkpoint/lumo-2078-verified-20261124` (Publisher/Belege; Release nur mit Heinz), `transport/team-b-apk-2071-*`.
- W: Chef-Agentenzweige `grok/schule-*` sind über die Demo enthalten; Demo-Branch nicht verändert.

## Godot-Pin
- `config/godot-source.json` bleibt `c3f459ec`. Diese Revision enthält bereits lumo-godot main, #197 (ebd3401c), #195, #196, #198–#202, alle lumo-2040/* und lumo-kart/* (geprüft mit `git merge-base --is-ancestor`). Godot-Integration `lumo-abschluss/integration-20261124` = c3f459ec + CI-Fix 5de8f57e (nur Workflow, PCK-Inhalt identisch), siehe lumo-godot PR #228.

## APK
- Version 0.14.7+2080 (> 2078 installiert, > 2079 Demo). Workflow `.github/workflows/lumo-abschluss-apk.yml` = lumo-test-apk.yml ohne Release/Tag, Ergebnis nur als Workflow-Artefakt.
- Paket: `scripts/build_unified_apk.sh` ruft `prepare_android.py --side-by-side` auf; diese Option erzeugt genau die installierte App-ID `dev.ullmann.lumo.lumo_lernen.coachpreview` (ohne sie entstünde `dev.ullmann.lumo.lumo_lernen`, also eine andere App). Signatur: tools/lumo-debug.keystore, erwartetes Zertifikat SHA-256 a6b1ef61…0702 (wie 2078). Beides prüft der Workflow mit aapt/apksigner.

## CI / Ergebnisse
- (wird nach den Läufen ergänzt)

## Offen
- DEVICE/FOLD7 NOT RUN (kein Gerät auf dem Box-Rechner).
# TEST_RESULTS – lumo-nullpunkt/integration-20261117 (lumo-lernen) – Stand 17.11.2026 13:30 (Europe/Vienna)

Abbruch wegen Nutzungslimit (90 %). **Nicht nach main gemergt.**

- Basis: `integration/lumo-original-assets-readiness-20261117` @ 7e71dd07 (enthält #527 LUMO 2037 Memory und integration/lumo-playready). Dazu nur Doku-/Beleg-Branches (B) und No-op-Merges (A), siehe `docs/handover/BRANCH-INVENTUR-20261117.md`.
- Godot-Pin `config/godot-source.json` unverändert bb478880 (ohne die Godot-Reparaturen aus lumo-godot PR #197).
- Lokal: `flutter analyze` rc=0 (278 Hinweise, keine Fehler); `flutter test` gezielt (smoke_main_screens, test/games, embedded_game_service): 282 PASS, 1 FAIL `test/games/memory_result_frame_test.dart` („Memory result waits for durable reward…“). Memory-Absturzfix liegt auf lumo-2040/memory-20261117 (#529), nicht integriert.
- Volle Testsuite: NOT RUN (Kosten). APK: CI-Workflow „Build Android Debug APK“ auf diesem Zweig manuell gestartet (kein Release).
- Offen: Integration-2 (lumo-2040/*, lumo-kart/*), Pin-Update auf reparierten Godot-Stand, Memory-Fix, main-Merge. DEVICE/FOLD7 NOT RUN.
