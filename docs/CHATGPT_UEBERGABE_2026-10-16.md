# Übergabe Claude → ChatGPT (16. Oktober 2026)

Diese Übergabe gilt für den Master-Übernahmeauftrag vom 16.10. (Astra sichern, Version 1001↔1947,
Kart-Garage-Test, Zusammenführung, Grafik, APK). Alles unten ist geprüft. Ungeprüftes ist ausdrücklich
als offen markiert.

> **Nachtrag (Ende der Claude-Sitzung):** Schritte 1–3 aus Abschnitt 4 sind begonnen. Commit `f8732a56` setzt den Godot-Pin auf `74eeb466bfaad77a57280b2dcabdb5923b80d827` (Android-Garage grün in Lauf 38841952066) und baut auf ChatGPTs Reservierung 0.12.40+1948 (`89d13ba1`) auf. Der volle APK-Lauf **38843372425** wurde gestartet; Claude hat sein Ergebnis **nicht** mehr gesehen. ChatGPT: Lauf auswerten. Bei Fehlern den ersten Fehler beheben. Bei Grün das Artefakt `LUMO-Lernen-0.12.40-1948-Android-APK` mit SHA-256, Zertifikat, Provenienz und dem Ergebnis des Jobs `sonnenhafen-update` melden. Ein lokaler `flutter test` des vollen Stands ist nach dem Pin nicht gelaufen.

## 1. Stand der Zweige

| Repo | Zweig | Kopf | Zustand |
|---|---|---|---|
| lumo-lernen | `claude/continue-previous-chat-KtY7p` | siehe `git log`; enthält alle Punkte aus Abschnitt 2 | gepusht, Arbeitsbaum sauber |
| lumo-godot | `claude/kart-integration-2026-10-16` | `28c0dae` | gepusht, Android-Garage-Test grün auf `74eeb46` |

- App-Version im Repo: noch **0.12.39+1947**. Die Umstellung auf **0.12.40+1948** ist noch nicht gemacht (Abschnitt 4, Schritt 2).
- Godot-Pin in `config/godot-source.json`: noch `ad6bd8856a9d…`. Er ist noch nicht umgestellt (Abschnitt 4, Schritt 1).
- Lokaler Stash `stash@{0}` (nur in Claudes Container): der unfertige Lumo-Meister-WIP. Er ist überholt, weil die
  Premium-Bühne von ChatGPT gewinnt. Sicherung liegt in `docs/wip/2026-10-15-lumo-meister-premium/` (Patch, README, Bogen).

## 2. Was Claude erledigt hat

### Erstens: Astra und die Klassen-/Lernfunktionen gesichert

- PRs #313 (Version 1947), #314, #315, #316 und #317 sind zusammengeführt. Das umfasst:
  - Klassenwechsel 1–4 als echtes freies Üben, ohne dass sich die Profilklasse ändert;
  - eigener Fortschritt pro Klasse unter `cross_grade_practice_v1:*`;
  - geschütztes Speichern mit erneutem Versuch;
  - die Bibliotheksszene.
- Konflikt in `lib/features/learning/cross_grade_practice_screen.dart` von Hand gelöst: #315 (Glas-Panel) plus #317 (Speicherfehler, Retry).
- Test `test/cross_grade_practice_storage_hardening_test.dart`: Er scrollt jetzt wie ein Kind zu „Nächste Aufgabe“. Die strenge Prüfung ist unverändert.
- Astras gemeldete Prüfungen sind mit vorhandenen Tests bestätigt. Lokal grün sind 28 Tests in diesen Dateien:
  - `reading_writing_content_test`
  - `writing_coach_recognition_test`
  - `academy_grade_3_4_visible_navigation_test`
  - `curriculum_cross_grade_navigation_test`
  - `academy_exact_topic_units_test`
  - `parents/parent_school_grade_progression_test`
  - `cross_grade_practice_storage_hardening_test`
  - `cross_grade_scene_design_test`
  - `academy_subject_art_test`
- Die CI hat den Stand `1a16366a` geprüft (Lauf 38841388349): Flutter-Regressionssuite, Screenshots, Lerninhalt-Guards,
  Godot-Import und native Renderings sind **grün**. Beim Schreiben liefen die Android-Jobs noch; das Ergebnis bitte nachsehen.

### Zweitens: Versionskonflikt 1001 ↔ 1947 analysiert

- Die Sonnenhafen-APK `lumo-lernen-sonnenhafen-unified-test-20261015` hat:
  - versionCode 1001 / 0.10.6;
  - Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`;
  - Zertifikat SHA-256 `a6b1ef61…0702`;
  - APK-SHA-256 `dd9ad0c7…7944`.
  
  Paket und Signatur sind gleich wie bei den 19xx-Builds. Ein In-place-Update auf einen höheren Code ist also möglich.
- Neuer Build-Code **1948**: Er ist geprüft frei und noch nirgends verwendet.
- Neuer CI-Job `sonnenhafen-update` in `.github/workflows/lumo-runtime-apk.yml` mit dem Prüfskript `.github/probes/sonnenhafen_update_probe.py`. Ablauf:
  1. 1001 per SHA-256 gepinnt herunterladen und installieren.
  2. Ein echtes Profil „LumoTest“ anlegen.
  3. `adb install -r` mit dem Kandidaten.
  4. Prüfen: höherer versionCode, gleiche userId, gleiche firstInstallTime, gleiches aktives Profil offline und auf dem Startbildschirm.
  
  Der Job blockiert die APK nicht; das Ergebnis muss im Bericht stehen. **Er ist noch nie gelaufen**, weil er erst mit dem nächsten CI-Lauf ohne `[skip ci]` startet.

### Drittens: Kart-Auswahltest repariert (lumo-godot)

- Ursache von Lauf 38803602256 („Visible footer control missing at step 1: Weiter“): `tools/tap_android_garage.py` las nur
  helle Schrift auf dunklem Grund. Der neue goldene „Weiter →“-Knopf hat dunkle Schrift. Außerdem wurde vor dem Vergrößern
  geschwellt, was die 10-px-Glyphen auf dem 320×640-Emulator zerstörte.
- Fix (`481d98c`):
  - zweite Lesart: erst LANCZOS-Vergrößerung, dann Schwelle für dunkle Schrift;
  - die bisherige Lesart, die exakte Beschriftung und die Fußzeilen-Regel sind unverändert;
  - TSV wird mit `QUOTE_NONE` gelesen;
  - neuer Test `tools/tests/test_android_garage_ocr.py` mit dem echten CI-Bild als Fixture; in der CI läuft er streng (`LUMO_REQUIRE_ANDROID_OCR=1`).
- `74eeb46`: `build.yml` läuft auch auf dem Integrationszweig. **Release und Pages sind für `claude/*` gesperrt.**
- **Beleg:** Lauf 38841952066 auf `74eeb46` ist **grün**. Im Log stehen:
  - `[AndroidGarage] actual screenshot touch: 1 Weiter … 4 Weiter, 5 Rennen starten`
  - `PASS: five real screenshot-directed touches`
  - `PASS: direct kart route, five actual selection steps and rendered race after orientation change`
  
  Artefakte: `lumo-android-startup-diagnostics`, `lumo-sonnenhafen-android-and-images`.
- `28c0dae`: `kart_aaa_visual_regression` gibt seine Prüfobjekte frei. Mit echtem Renderer gab es vorher Lecks beim Beenden. Die Prüfungen selbst sind unverändert. Lokal grün. CI-Lauf 38842736798 lief beim Schreiben noch.

### Viertens: Zusammenführung (kontrolliert, je Branch geprüft)

Godot-Kandidat `claude/kart-integration-2026-10-16`:
- Basis #72 Sonnenhafen-Wasser `9d80dff`.
- Dazu #71 Gemini-Visuals `c850e8d`, mit Wasser-Shader-Konflikt: Farben aus #71, Küstenschaum aus #72.
- Dazu größere Weltvorschau `ad6bd88` (der aktuelle App-Pin), Review-PDF `e430f1a` und Puzzle-Referenzen `daa775f` (nur Doku).
- Alle neueren lumo-godot-Zweige sind enthalten.
- Alle 8 hash-gebundenen Godot-Dateien sind gegenüber `ad6bd88` **unverändert**: `kart_island.gd`, `progress_store.gd` und 6 Testdateien. Ein Pin-Wechsel bricht die Beweisbindungen also nicht.
- Lokale Regressionen auf dem Kandidaten:
  - `validate_project.sh`: 12 Testsuiten grün; nur `kart_pause_layout` brach lokal unter CPU-Last nach 120 s ab. In der CI ist „Project import“ grün.
  - Danach 16 von 66 Regressionen: 14 grün. AAA ist behoben. Bei `kart_brake_reverse_feedback` meldete der strenge Ende-Log-Check unter Last einmal „4 resources still in use at exit“; in Ruhe ist er grün.
  - **Die übrigen 50 Regressionen sind lokal nicht gelaufen.**

lumo-lernen:
- Übernommen: #304 `native-source-preflight`. Die CI bricht früh ab, wenn native Beweisbindungen veraltet sind.
- Nur Historie, Inhalt bereits in `e76552b7`:
  - #311 kart-qa-real-caption
  - premium-quiz-stage
  - #309 3D-Lerninseln
  - hologlass-1940 (dessen neuere Testdatei ohne ungenutzten Import behalten)
- Nicht übernommen, mit Begründung:
  - `lumo-meister-host-safe-area`: ersetzt durch die Premium-Bühne; sein Test kompiliert gegen den aktuellen Stand nicht.
  - `gemini-source-export`: einmaliger Export des ganzen Quellcodes an einen externen KI-Dienst; braucht Heinz' Freigabe.
- Aufgeräumt: `_PrizeColumn`/`_Milestone` (ungenutzt) und `_positive`. `flutter analyze`: **0 Fehler, 0 Warnungen** (38 Info-Hinweise). Quiz-, Meister-, Generator- und Klassen-Tests: 32 grün.

## 3. Offen (ehrlich, nicht erledigt)

1. **Noch nicht geprüft, mit Empfehlung:**
   - `chatgpt/gemini-story-compatibility-2026-10-15` (7 Commits: Plots, Begleiter, Zaubergegenstände, Geschichten pro Kind, Fold-Kopf). Vor dem Merge prüfen:
     - Rückwärtskompatibilität gespeicherter Geschichten und Profile;
     - kindgerechte Texte;
     - Erreichbarkeit;
     - die eigenen Tests des Branches.
   - `perplexity/lumo-nvidia-tutor-pilot-2026-10-15` (9 Commits, NVIDIA Nemotron). **Nur** übernehmen, wenn:
     - er standardmäßig aus ist und nur Eltern ihn einschalten;
     - kein Schlüssel im Repo oder in der APK liegt;
     - der Aufruf nur über den Server läuft;
     - `PRIVACY.md` angepasst ist.
     
     NVIDIA-API-Credits können kostenpflichtig sein: **Ohne Heinz' Freigabe nicht aktivieren.**
   - Alte Linie `chatgpt/lumo-sonnenhafen-unified-apk-2026-10-15` (`1978642c`) und `…-sonnenhafen-godot-pin-…`: Sie liegen 785 Commits zurück. Nur einzelne Commits portieren (CI-Publish/Beleg), niemals pauschal mergen.
   - `sol/lumo-1939-local-qa-backup-2026-10-14` (1 Commit) und `chatgpt/lumo-inventory-2026-10-13` (3 Commits): kurz sichten.
2. **Alte Android-Fehler** aus den Läufen 38695767539 und 38705170622 (Lernreise auf API 35, Kart auf API 35 und 36):
   - Die Fixes aus #311 („1 Modus“, Tab „Lernen“) sind enthalten. Ob sie greifen, zeigt erst der nächste volle Lauf.
   - Risiko: `LEARN_TILE='Lernen'` könnte auf dem Fold-Innendisplay auch die Seitenleisten-Überschrift treffen. Dann wäre nur die Tour-Aufnahme betroffen.
3. **Grafik (Auftrag „beeindruckende 3D-Sachen“): noch nicht begonnen.** Ist-Zustand aus echten Renderings (Lauf 38705170622, `lumo-visual-native-renders`):
   - flacher Verlaufshimmel;
   - glatter Asphalt ohne Struktur;
   - wenig Tiefenstaffelung;
   - keine Rad-/Driftpartikel.
   
   Vorhanden sind bereits: `kart_speed_fx.gd`, `visual/kart_environment_polish.gd`, `visual/kart_neon_gates.gd`, `kart_visual_grade.gd`, `ProceduralSkyMaterial` und Nebel in `kart_world.gd`, ein `CPUParticles3D` in `kart_island.gd`.
   
   Vorschlag in dieser Reihenfolge, je mit Regressionstest und Vorher/Nachher-Rendering aus der Engine:
   1. Wolkenschicht und Sonnenscheibe im Himmel;
   2. Asphalt-Detail im Shader;
   3. Drift-Funken und Boost-Flammen (CPUParticles3D, aus bei reduzierter Bewegung und niedriger Grafik);
   4. Kontaktschatten unter den Karts;
   5. Konfetti im Ziel.
   
   Alles muss im Renderer `gl_compatibility` laufen. Keine 60-FPS-Behauptung ohne echtes Gerät.
4. **Lumo-Gesicht-WIP** (`docs/wip/2026-10-09-lumo-gesicht/` im Godot-Kandidaten) passt nicht mehr: Das Gesicht wurde inzwischen von anderen neu modelliert. Nicht anwenden, nur als Ideensammlung nutzen.
5. **Sicherheit:** `tools/lumo-debug.keystore` (Passwort „android“) liegt im öffentlichen Repo und signiert die Test-APKs. Ein Schlüsselwechsel bricht Updates. Das entscheidet Heinz.

## 4. Nächste Schritte für die APK (in dieser Reihenfolge)

1. Ergebnis von Godot-Lauf 38842736798 (`28c0dae`) abwarten. Ist er grün, in lumo-lernen `config/godot-source.json` →
   `"revision": "28c0dae…"` setzen (vollständige SHA mit `git ls-remote` holen). Ist er rot, auf `74eeb46` pinnen (Android-Garage grün belegt).
2. `pubspec.yaml` → `version: 0.12.40+1948`.
3. Lokal `flutter analyze` und `flutter test` ausführen. Dann **ohne** `[skip ci]` pushen. Das startet `lumo-runtime-apk.yml` vollständig:
   native Regressionen, Android-Spiele API 35 und 36, Lernreise, 1001-Update-Job und das Paketieren der verifizierten APK.
4. APK-Artefakt `LUMO-Lernen-0.12.40-1948-Android-APK` aus dem Lauf nehmen. Im Bericht nennen:
   - SHA-256, Zertifikat (`a6b1ef61…`), Godot-Commit und Flutter-Commit aus `BUILD-PROVENANCE.json`;
   - Ergebnis des 1001-Update-Jobs;
   - Link zum Lauf.
   
   **Kein Release und kein Merge nach `main` ohne Heinz.**
5. Danach: die offenen Branches aus Abschnitt 3 und die Grafik-Arbeit.

## 5. Regeln, die weiter gelten

- `flutter analyze` ohne Fehler und `flutter test` grün; Tests nie abschwächen.
- Kleine Commits, kein Force-Push, kein Merge nach `main`, kein Release ohne Heinz.
- Bilder als Dateien unter `assets/`, kein Base64; jede `lib/`-Datei muss von `main.dart` aus erreichbar sein.
- Echte Daten anzeigen; keine bezahlten APIs oder Cloud-Dienste ohne Freigabe; keine Schlüssel im Repo.
- Im Kart-Rennen keine Lernfragen; keine Nintendo- oder Mario-Kart-Inhalte.
- Nur Geprüftes als erledigt melden; Screenshots nie nachträglich bearbeiten.
- Commits, die einen laufenden erfolgreichen CI-Lauf abbrechen würden, mit `[skip ci]` im Kopf-Commit pushen (Concurrency mit cancel-in-progress).

## 6. Letzte Claude-Schritte (Fehlersuche und Anschlüsse)

- Godot-Lauf 38842736798 auf `28c0dae` ist rot, aber nur wegen der Emulator-Infrastruktur: „adb: device offline“ und
  „Could not capture logcat“ vor dem Garage-Schritt. Kein Spielfehler.
- Angeschlossen: `chatgpt/kart-android-adb-resilience-2026-10-16` → Godot-Kandidat `ea69d12`. Die eigenen Tests sind lokal
  grün (8 Tests inkl. Garage-OCR). Der neue CI-Lauf **38844004716** ist gestartet; Ergebnis offen. Ist er grün, kann der
  App-Pin von `74eeb46` auf `ea69d12` wechseln. Die Wiederholungen betreffen nur die CI, die Spiel-Inhalte sind gleich.
- Angestoßen: `chatgpt/gemini-story-compatibility-2026-10-15` liegt konfliktfrei zusammengeführt auf dem **eigenen** Zweig
  `claude/integration-stories-2026-10-16`. Er löst keine CI aus und bricht deshalb den APK-Lauf nicht ab.
  `flutter analyze` meldet 0 Fehler und 0 Warnungen; 29 Story-Tests sind grün. Nach grünem APK-Lauf 38843372425 in den
  Hauptzweig mergen.
- Weiter offen: NVIDIA-Pilot (Freigabe, Kosten, Datenschutz) und die alte Sonnenhafen-Linie (nur einzelne Commits portieren).
- Hinweis: Die Testausgaben in `.ci-results/onboarding-visual/` sind versioniert, nicht löschen.
