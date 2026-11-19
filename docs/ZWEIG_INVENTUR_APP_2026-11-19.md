# Zweig-Inventur Lern-App (Flutter) – 19.11.2026

Gemeinsame Linie: `origin/repair/lumo-quiz-run-kart-20261119` (`fde9a4c4`). Arbeitszweig:
`agent/inventur-app`. Nichts gepusht, nichts auf GitHub geändert, `main` unberührt, keine
Bauschalter (`config/test-apk-request.json`, `config/godot-source.json`, `pubspec.yaml`,
`.github/workflows/lumo-test-apk.yml`) geändert.

## Vorgehen

1. Ausgangsliste: 794 Zweige; 315 Vorfahren und 7 inhaltlich enthaltene Zweige brauchen nichts.
   486 Zweige haben einen Rest (83 REST_SAUBER, 403 REST_KONFLIKT).
2. Ein Merge-Tree-Rest zeigt bei REST_KONFLIKT vor allem Konfliktmarken (die Linie hat die
   Datei später weiterentwickelt). Deshalb wurde je Zweig gemessen, **welche vom Zweig
   hinzugefügten Zeilen in der Linien-Datei nirgends vorkommen** (Werkzeug `fehlt.py` in der
   Ablage; Belege unter `docs/`, `config/`, `*.md` nur gezählt; gleiche Dateiinhalte an
   anderer Stelle gelten als vorhanden).
3. Zweige mit gleichem fehlenden App-/Test-Inhalt bilden eine Familie: **287 Familien
   (384 Zweige)**. Dazu **102 Zweige ohne fehlenden App-/Testinhalt** (68 nur
   Werkzeug/CI/Probes, 34 nur Doku/Belege).
4. Urteil je Familie, neueste zuerst. November-Familien mit App-Inhalt einzeln angesehen
   (Zeilenvergleich mit `zeig.sh`); Oktober-/Mai-Familien über die Regeln „Dateien auf der
   Linie neu aufgebaut/entfernt“, Stichproben und einen Probelauf von 23 Oktober-Testdateien
   gegen die Linie (17 kompilieren, davon 14 rot wegen umgebauter Oberfläche/„Sachkunde“ →
   „Sachunterricht“, 3 grün; 6 kompilieren nicht mehr). Genau neue Dateien der Oktober-/Mai-Zweige
   (nicht im Merge-Base, nicht auf der Linie) sind unten einzeln beurteilt.

## Übernommen (Commits auf `agent/inventur-app`)

| Commit | Inhalt | Quelle | Test |
|---|---|---|---|
| `b7095155` | Memory: Flutter-Brett, Karten, Ergebnis im Look des 3D-Tisches + Bildtest | `lumo-2040/memory-20261117` (PR #529, 5a79c14c) | PASS LOKAL: 34 Memory-Tests; 4 Widget-Bilder angesehen (kein Gerät) |
| `4cfb30ec` | Vier gewinnt: nativer Tisch sicher gegen Öffnen/Schließen-Wettlauf + 8 Regressionstests | `delivery/lumo-2032-complete-source-to-apk-20261116` (a60470ad, c5dfcec0) | PASS LOKAL: 63 C4-Tests |
| `34feeac9` | Memory- und Sternen-Speicherung bestätigen; C4-Lumozug nach Speicherfehler fortsetzbar | `integration/lumo-c4-connections-20261114` u. a. (e2db0d60/37414d0c, a5ac4cbe, c874abe3) | PASS LOKAL: 89 neue/geänderte Tests; 212 Spiel-/Wallet-Tests |
| `41c8007c` | Tests: Lernmodul-Registry, Geschichten-Speicherung | `sol/lumo-app-audit-2026-10-13` | PASS LOKAL: 3 Tests |
| `d413b27e` | Nachhilfe „Schritt für Schritt mit Lumo“ (Plus bis 20, Stufen, Wege, Fehlermuster), Einstieg freigeschaltet, 2D-Weg; neuer Einstiegstest | `lumo-2040/tutor-20261117` (PR #530) | PASS LOKAL: 13 Logik- + 2 Einstiegstests; 593 Tests `test/tutoring`+`test/learning` |

Gesamtlauf und `flutter analyze` siehe Abschnitt „Prüfung“.

## Ausdrücklich angefragte Zweige

| Zweig / PR | Befund |
|---|---|
| #529 Memory (`lumo-2040/memory-20261117`) | 5a79c14c fehlte → `b7095155`; b93aef5b liegt als a9a8ad60 auf der Linie |
| #530 Nachhilfe (`lumo-2040/tutor-20261117`) | fehlte → `d413b27e` (fertiggestellt; 3D-Weg wartet auf Godot-Szene „tutor“, MainActivity nicht geändert) |
| #532 Schach (`qa/lumo-2049-android-rundgang` = `delivery/lumo-schach-2048-20261118`) | überholt: Schach-Route, Portal, Overlay, MainActivity-Freigabe auf der Linie |
| `delivery/lumo-2037-memory-werkstatt-20261117` | überholt (Memory nativ nur auf Wunsch; Werkstatt-Knöpfe in Lektion und Akademie) |
| `fix/lumo-learning-conversation-scope-20261115` | überholt: einzige Abweichung `useSafeArea` im Begleiter-Menü, Linie hat das Menü später neu gefasst |
| `fix/lumo-core-menu-presenter-20261116` | überholt: `_presentCompanionMenu` und Bindung auf der Linie |
| `fix/lumo-lab-route-scope-20261116` | überholt: `lab_conversation_return_test.dart` auf der Linie ist umfangreicher |
| `delivery/lumo-2032-complete-source-to-apk-20261116` | C4-Wettlauf fehlte → `4cfb30ec`; Memory-Teil überholt; Workflows nicht übernommen |
| `delivery/lumo-2031-workshop-test-apk-20261116` | überholt (eine Kommentarzeile; Werkzeug/Workflow nur Beleg) |
| `agent/verbinden` | fehlt der Linie (Geister-Duell/WLAN) – **nicht übernommen**, macht der Koordinator mit dem Godot-Teil |
| `agent/holo-lernen` | bestätigt: inhaltlich auf der Linie (dort weiterentwickelt) |

## Familien (App-/Testinhalt), neueste zuerst

| Familie | Datum | Zweige | Inhalt | Befund | Aktion | Test |
|---|---|---|---|---|---|---|
| F002 | 2026-11-19 | `agent/holo-lernen` | Holo-Lektionskatalog, Satz-/Textaufgaben in 3D | überholt: auf der Linie als Squash, dort weiterentwickelt (Namenwort im Satz, Bilder); einzige Abweichung ist eine später erweiterte Bedingung in native_learning_activity.dart | keine | – |
| F001 | 2026-11-19 | `agent/verbinden` | Geister-Duell / WLAN-Rennen (kart_friends, KartFriendsBridge.kt) | fehlt der Linie – Übernahme macht der Koordinator zusammen mit dem Godot-Teil | nicht übernommen (Auftrag) | NICHT GETESTET |
| F003 | 2026-11-18 | `delivery/lumo-schach-2048-20261118`, `qa/lumo-2049-android-rundgang` | PR #532 Schach in Spielewelt, Lernrunde, Fold-Menü | überholt: Linie hat Schach-Route (spielwelt_routes identity chess, cover_chess.jpg, MainActivity erlaubt chess, Overlay „Lumo Schach“) | keine | – |
| F006 | 2026-11-17 | `delivery/lumo-2037-memory-werkstatt-20261117` | 2037 Memory-Einstieg + 3D-Werkstatt in Akademie/Lektion | überholt: Memory nativ nur auf Wunsch (lumo_memory_game.dart, memory_native_entry_test), 3D-Werkstatt-Knopf in Lektion (learning-3d-workshop) und Akademie (academy-3d-workshop) | keine | – |
| F005 | 2026-11-17 | `lumo-2040/memory-20261117` | PR #529 Memory: Flutter-Brett/Karten/Ergebnis im Look des 3D-Tisches | teilweise fehlte: b93aef5b liegt als a9a8ad60 auf der Linie, 5a79c14c fehlte | übernommen: b7095155 | PASS LOKAL 34 Memory-Tests, Bilder angesehen |
| F004 | 2026-11-17 | `lumo-2040/tutor-20261117` | PR #530 Lumo-Nachhilfe Plus bis 20 (Hilfestufen, 5 Wege, Fehlermuster, 2D-Fallback) | fehlte (WIP, Einstieg verborgen) | übernommen und fertiggestellt: d413b27e (Einstieg freigeschaltet, 3D bleibt aus bis Godot-Szene „tutor“ da ist) | PASS LOKAL 13+2 Tests; tutoring+learning 593 |
| F009 | 2026-11-16 | `delivery/lumo-2031-workshop-test-apk-20261116`, `integration/lumo-2031-learning-workshop-repair-20261116` | lib/features/learning | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F008 | 2026-11-16 | `delivery/lumo-2034-gesamt-20261116`, `delivery/lumo-2035-complete-20261116` | pubspec.yaml | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F007 | 2026-11-16 | `fix/lumo-memory-child-safe-start-20261116`, `integration/lumo-learning-nextgen-20261115` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F012 | 2026-11-16 | `delivery/lumo-2032-complete-source-to-apk-20261116` | 2032: Vier-gewinnt Öffnen/Schließen-Wettlauf + Memory sicherer Start | C4-Wettlauf-Fix fehlte; Memory-Teil überholt (Linie: nativ nur auf Wunsch) | übernommen: 4cfb30ec (C4-Teil) | PASS LOKAL 63 C4-Tests (darin 8 neue) |
| F015 | 2026-11-16 | `fix/lumo-core-menu-presenter-20261116` | lib/features/learning, test/learning/core_conversation_route_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F014 | 2026-11-16 | `fix/lumo-lab-route-scope-20261116` | test/learning/lab_conversation_return_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F019 | 2026-11-16 | `fix/lumo-learning-conversation-scope-20261115` | lib/app/lumo_companion_host.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F018 | 2026-11-16 | `qa/lumo-2031-lab-runtime-cases-20261116` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F013 | 2026-11-16 | `qa/lumo-nextgen-2029-native-diagnostic-20261116` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F011 | 2026-11-16 | `qa/lumo-nextgen-2032-runtime-cases-20261116` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F016 | 2026-11-16 | `qa/lumo-nextgen-pattern-reader-20261116` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F017 | 2026-11-16 | `qa/lumo-recording-start-20261116` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F010 | 2026-11-16 | `repair/lumo-learning-workshop-relevance-20261116` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F026 | 2026-11-15 | `chatgpt/lumo-chat4-dialogue-20261115` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F020 | 2026-11-15 | `chatgpt/lumo-nextgen-blender-flutter-apk-20261115` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F023 | 2026-11-15 | `feature/lumo-nextgen-conversation-20261115-403a` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F024 | 2026-11-15 | `feature/lumo-nextgen-learning-20261115` | Checkpoint Lernfragen-Qualität, Fragen-Coach für Karten/Minispiele | überholt: Fachkorrekturen 16c44e12/e9496a6f/23b40c11 (18.11.), Karten-Overlay mit Flutter-Kartenspiel entfernt (97e4f6fd) | keine | – |
| F025 | 2026-11-15 | `feature/lumo-nextgen-voice-20261115` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F027 | 2026-11-15 | `integration/lumo-learning-generation-20261115-ea41` | Universelle 3D-Aufgabenkarte für jede Aufgabe | bewusst verworfen: Linie blockiert universelle 3D-Karten (89688626, Vorgabe „keine universelle Tafel“) | keine | – |
| F022 | 2026-11-15 | `integration/lumo-reviewed-delta-20261115-58e0` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F028 | 2026-11-15 | `qa/lumo-nextgen-native-reference-diagnostic-20261115` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F021 | 2026-11-15 | `support/lumo-c4-open-close-20261115` | NextGen-Lernintegration mit Chat4-Aufgabendialog (lumo_task_dialogue*, Spracheingabe) | parallele Fassung: Linie hat eigenen Dialog (lumo_learning_dialogue_intent.dart, lumo_conversation_controller.dart, LumoLearningSpeech.kt; a31080c9). Nicht blind übernommen | keine – offener Punkt: fachlicher Vergleich der Absichten (warum/alternativ/zeigen/Schritt) | – |
| F029 | 2026-11-15 | `work/lumo-nextgen-voice-20261115-ea41` | lib/widgets/fox | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F030 | 2026-11-14 | `audit/lumo-originals-9de-20261114`, `checkpoint/lumo-9de-android-evidence-20261114`, `checkpoint/lumo-9de-early-evidence-20261114`, `checkpoint/lumo-9de-native-build-evidence-20261114` (+5) | lib/features/games, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F031 | 2026-11-14 | `checkpoint/lumo-198dd3-build-evidence-20261114`, `checkpoint/lumo-198dd3-early-evidence-20261114`, `checkpoint/lumo-198dd3-native-evidence-20261114`, `checkpoint/lumo-agent-publication-198dd3-20261114` (+3) | lib/features/games, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F032 | 2026-11-14 | `checkpoint/lumo-c4-return-observer-04-20261114`, `checkpoint/lumo-live-publisher-ec936873-20261114`, `checkpoint/lumo-original-replay-ec-20261114`, `evidence/lumo-final-flutter-ec936873-20261114` (+3) | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F033 | 2026-11-14 | `checkpoint/lumo-agent-publication-7c5-20261114`, `checkpoint/lumo-c4-preferences-20261114`, `checkpoint/lumo-c4-preferences-diagnostic-20261114`, `checkpoint/lumo-c4-return-fixtures-recovery-20261114` (+2) | lib/features/games, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F034 | 2026-11-14 | `checkpoint/lumo-c4-diagnostic-20261114`, `checkpoint/lumo-c4-navigation-20261114`, `diagnostic/lumo-c4-return-74a-20261114`, `validation/lumo-native-bebf7bba-20261114` | lib/features/games, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F038 | 2026-11-14 | `chatgpt/lumo-learning-curriculum-audit-20261114`, `chatgpt/lumo-playstore-agent-network-20261114`, `chatgpt/lumo-three-qa-workers-20261114` | lib/core/school_exercise_generator.dart, test/learning/learning_exact_selection_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F036 | 2026-11-14 | `checkpoint/lumo-unchanged-2020-diagnostic-20261114`, `checkpoint/lumo-unchanged-2020-diagnostic-union-20261114`, `qa/lumo-android-runtime-1e22-20261114` | scripts/tests/test_verify_unchanged_2020_apk_diagnostic.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F035 | 2026-11-14 | `integration/lumo-next-authorities-lint-20261114`, `integration/lumo-next-table-authorities-20261114`, `validation/root-recovery-1750-20261114` | Quiz nativ, Englisch-Aussprache in der 3D-Lernszene (LumoOfflineSpeechEngine.synthesizeEnglishLesson) | Quiz überholt; Englisch-Aussprache (nur Kotlin/Java, 3a5b2241) fehlt | nicht übernommen – offener Punkt (Kotlin hier nicht baubar) | NICHT GETESTET |
| F037 | 2026-11-14 | `qa/lumo-c4-small-result-actions-20261114-2708`, `qa/lumo-c4-small-result-actions-20261114-2708-r2`, `qa/lumo-c4-small-result-actions-20261114-2708-r3` | test/games/connect_four_small_result_actions_qa.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F040 | 2026-11-14 | `chatgpt/lumo-nextgen-feature-20261114`, `chatgpt/lumo-studio-2020-20261114` | lib/app/app_state.dart, lib/core/reward_wallet_repository.dart, lib/domain/analysis | Haltbarkeits-Korrekturen 14.11. fehlten; Rest überholt. Englisch-Aussprache (LumoOfflineSpeechEngine) siehe offener Punkt. | übernommen über 34feeac9 | PASS LOKAL (siehe 34feeac9) |
| F045 | 2026-11-14 | `chatgpt/lumo-studio-4ab96666-evidence-20261114`, `chatgpt/lumo-studio-evidence-archive-20261114` | scripts/tests/test_android_framework_ready.py, scripts/tests/test_android_voice_scroll.py, scripts/tests/test_candidate_2011_pin.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F042 | 2026-11-14 | `checkpoint/lumo-agent-publication-review-20261114`, `checkpoint/lumo-kart-scroll-recovery-20261114` | lib/features/games, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F043 | 2026-11-14 | `checkpoint/lumo-c4-cleanup-diagnostic-6b-20261114`, `qa/lumo-village-return-6b-20261114` | scripts/tests/test_6b_roundtrip_diagnostic.py, scripts/tests/test_verify_unchanged_6b_village_diagnostic.py, tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F041 | 2026-11-14 | `checkpoint/lumo-kart-diagnostic-20261114`, `diagnostic/lumo-kart-scroll-6f42-20261114` | lib/features/games, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F047 | 2026-11-14 | `checkpoint/lumo-live-combined-aab-20261114`, `evidence/lumo-union-preflight-f365-20261114` | scripts/tests/test_candidate_2011_pin.py, test/games/games_screen_flow_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F044 | 2026-11-14 | `checkpoint/lumo-village-return-diagnostic-20261114`, `evidence/lumo-village-6b-diagnostic-originals-20261114` | scripts/tests/test_6b_roundtrip_diagnostic.py, scripts/tests/test_verify_unchanged_6b_village_diagnostic.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F039 | 2026-11-14 | `integration/lumo-c4-connections-20261114`, `integration/lumo-next-repair-1952-20261114` | Haltbarkeit 14.11.: Memory-/Wallet-Speicherbestätigung, C4-Lumozug nach Speicherfehler | fehlte (PR507/PR494-Korrekturen) | übernommen: 34feeac9 (ohne ASR-Teil der Tagesempfehlung) | PASS LOKAL 89 neue/geänderte, 212 Spiel/Wallet-Tests |
| F048 | 2026-11-14 | `integration/lumo-next-hub-20261114`, `repair/lumo-native-3d-games-hub-entry-20261114` | tools/auto_install/MainActivity.kt | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F046 | 2026-11-14 | `release/lumo-2020-arm64-one-apk-20261114`, `repair/lumo-2020-exact-learning-20261114` | lib/features/learning, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_pipeline.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F062 | 2026-11-14 | `chatgpt/lumo-direct-village-flutter-20261114` | lib/features/learning, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_connect_four_delivery.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F050 | 2026-11-14 | `chatgpt/lumo-studio-078-kart-recheck-20261114` | lib/features/games, lib/features/lumo3d, scripts/tests/fixtures | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F052 | 2026-11-14 | `chatgpt/lumo-studio-20261113` | lib/features/games, scripts/tests/fixtures, scripts/tests/test_android_framework_ready.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F054 | 2026-11-14 | `chatgpt/lumo-studio-4ab-ocr-recheck-20261114` | scripts/tests/test_android_framework_ready.py, scripts/tests/test_android_voice_scroll.py, scripts/tests/test_candidate_2011_pin.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F059 | 2026-11-14 | `chatgpt/lumo-studio-runtime-integration-20261113` | scripts/tests/test_android_framework_ready.py, scripts/tests/test_android_voice_scroll.py, scripts/tests/test_candidate_2011_pin.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F061 | 2026-11-14 | `checkpoint/lumo-c4-flutter-repairs-20261114` | lib/features/games, lib/features/learning, scripts/tests/test_candidate_2011_pin.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F073 | 2026-11-14 | `checkpoint/lumo-final-integration-20261114` | scripts/tests/test_candidate_2011_pin.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F056 | 2026-11-14 | `integration/lumo-c4-publisher-20261114` | scripts/tests/test_publish_connect_four_delivery.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F051 | 2026-11-14 | `integration/lumo-discovery-host-7136-20261114` | scripts/tests/test_candidate_2011_pin.py, tools/android_qa/tests, tools/auto_install/MainActivity.kt | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F049 | 2026-11-14 | `integration/lumo-next-candidate-1913-20261114` | lib/app/app_state.dart, lib/domain/analysis, lib/domain/tutoring | Haltbarkeits-Korrekturen 14.11. fehlten; Rest überholt. Englisch-Aussprache (LumoOfflineSpeechEngine) siehe offener Punkt. | übernommen über 34feeac9 | PASS LOKAL (siehe 34feeac9) |
| F058 | 2026-11-14 | `qa/lumo-console-joystick-7b16-20261114` | scripts/tests/test_console_joystick_workflow.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F057 | 2026-11-14 | `qa/lumo-console-start-7b16-20261114` | scripts/tests/test_console_joystick_workflow.py, scripts/tests/test_console_start_workflow.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F067 | 2026-11-14 | `repair/lumo-2020-one-apk-20261114` | scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_studio_jump_decode.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F065 | 2026-11-14 | `repair/lumo-2020-village-hook-20261114` | scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_studio_jump_decode.py, test/design/dorfwirtschaft_spielewelt_capture_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F068 | 2026-11-14 | `repair/lumo-c4-safe-entry-20261114` | lib/features/games, test/games/connect_four_native_route_test.dart, test/games/games_screen_flow_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F063 | 2026-11-14 | `repair/lumo-exact-learning-20261114` | lib/features/learning, scripts/tests/test_connect_four_delivery.py, scripts/tests/test_connect_four_pipeline.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F060 | 2026-11-14 | `repair/lumo-historical-diagnostic-fixture-20261114` | lib/features/games, lib/features/learning, scripts/tests/test_candidate_2011_pin.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F064 | 2026-11-14 | `repair/lumo-live-diagnostic-20261114` | scripts/tests/test_connect_four_delivery.py, test/games/spielwelt_semantics_action_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F070 | 2026-11-14 | `repair/lumo-live-drawing-20261114` | test/learning_modules/deutsch_sach_module_progress_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F069 | 2026-11-14 | `repair/lumo-live-village-android-20261114` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F066 | 2026-11-14 | `repair/lumo-live-village-host-20261114` | scripts/tests/test_connect_four_pipeline.py, test/design/dorfwirtschaft_spielewelt_capture_test.dart, test/design/home_1989_premium_cards_capture_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F072 | 2026-11-14 | `repair/lumo-producer-flutter-union-20261114` | test/games/games_screen_flow_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F053 | 2026-11-14 | `repair/lumo-single-apk-20261114` | lib/features/games, lib/features/live, lib/widgets/profile_screen.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F071 | 2026-11-14 | `work/lumo-dream-ui-recovery-20261114` | test/games/connect_four_navigation_test.dart, test/lumo_scene_atmosphere_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F055 | 2026-11-14 | `work/lumo-spielwelt-studio-20261114` | assets/lumo_design/spielwelt, lib/features/games, pubspec.yaml | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F074 | 2026-11-13 | `chatgpt/lumo-2020-android-qa-recovery-20261113`, `chatgpt/lumo-2020-direct-apk-delivery-20261113`, `chatgpt/lumo-complete-app-20261113` | lib/features/lumo3d, scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_embedded_android.py | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F075 | 2026-11-13 | `chatgpt/lumo-android17-cli22-recheck-20261113`, `chatgpt/lumo-android17-framework-recheck-20261113` | scripts/tests/test_android_framework_ready.py, scripts/tests/test_android_recheck_identity.py, scripts/tests/test_candidate_2011_pin.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F076 | 2026-11-13 | `chatgpt/lumo-android17-sdk-diagnostic-20261113`, `chatgpt/lumo-historical-1999-verifier-20261113` | scripts/tests/test_candidate_2011_pin.py, tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F078 | 2026-11-13 | `chatgpt/lumo-2018-android-acceptance-20261113` | scripts/tests/test_nextgen_retest.py, tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F085 | 2026-11-13 | `chatgpt/lumo-2018-review-recovery-20261113` | scripts/tests/test_nextgen_review_recovery.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F084 | 2026-11-13 | `chatgpt/lumo-2019-release-candidate-20261113` | lib/domain/tutoring, lib/features/learning, lib/features/lumo3d | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F079 | 2026-11-13 | `chatgpt/lumo-android-recheck-2019-20261113` | scripts/tests/test_android_recheck_identity.py, scripts/tests/test_candidate_2011_pin.py, tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F082 | 2026-11-13 | `chatgpt/lumo-cards-heartbeat-20261113` | scripts/tests/test_candidate_2011_pin.py, scripts/tests/test_cards_lifecycle_heartbeat.py, tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F080 | 2026-11-13 | `chatgpt/lumo-creative-android-31883868-20261113` | scripts/tests/test_android_framework_ready.py, scripts/tests/test_android_voice_scroll.py, scripts/tests/test_candidate_2011_pin.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F081 | 2026-11-13 | `chatgpt/lumo-studio-31883868-evidence-20261113` | scripts/tests/test_android_framework_ready.py, scripts/tests/test_android_voice_scroll.py, scripts/tests/test_candidate_2011_pin.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F083 | 2026-11-13 | `claude/lumo-nextgen-app-20261113` | lib/domain/tutoring, lib/features/learning, lib/features/lumo3d | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F077 | 2026-11-13 | `qa/lumo-creative-51e-20261113` | scripts/tests/fixtures, scripts/tests/test_studio_creative_android_probe.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F087 | 2026-11-11 | `chatgpt/lumo-2015-android-garage-qa-20261111` | scripts/tests/test_lumo_2015_garage_android_probe.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F086 | 2026-11-11 | `chatgpt/lumo-2015-verified-apk-delivery-20261111` | scripts/tests/test_lumo_2015_garage_delivery.py | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F089 | 2026-11-10 | `lumo-2014/cards-games-20261110` | lib/features/games, test/design/cards_opponent_capture_test.dart, test/games/lumo_cards_strategy_test.dart | überholt: Flutter-Kartenspiel entfernt (97e4f6fd) | keine | – |
| F088 | 2026-11-10 | `lumo-2014/cards-resume-20261110` | Flutter-Kartenspiel (Bot, Fortsetzen) | überholt: Flutter-Kartenspiel bewusst entfernt, 3D-Kartentisch (97e4f6fd) | keine | – |
| F090 | 2026-11-10 | `lumo-2014/learning-tutor-20261110` | lib/core/progress_repository.dart, lib/features/tutoring | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F091 | 2026-11-10 | `lumo-2014/quiz-lock-final-20261110` | lib/features/quiz | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F092 | 2026-11-10 | `lumo-2014/quiz-lock-lifetime-20261110` | test/quiz_category_lock_lifetime_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F094 | 2026-11-03 | `chatgpt/lumo-2005-star-trail-scroll-regression-fix-20261103` | test/design/parent_games_polish_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F093 | 2026-11-03 | `chatgpt/lumo-games-3d-launch-20261103` | test/design/parent_games_polish_test.dart, test/games/star_trail_visual_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F095 | 2026-11-03 | `ux/lumo-scroll-all-sections-20261103` | test/lumo_child_navigation_cluster_test.dart | überholt: dieselben Dateien auf der Linie später weiterentwickelt; Abweichung nur alte Zwischenstände (Stichproben geprüft) | keine | – |
| F096 | 2026-10-31 | `qa/lumo-all-registers-grade-1-4-visual-20261031` | test/design/app_full_register_tour_capture_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F099 | 2026-10-29 | `claude/lumo-android-integration-m0-aloove` | lib/core/lumo_child_speech_normalizer.dart, lib/core/math_task_templates.dart, lib/core/task_hint_service.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F097 | 2026-10-29 | `claude/lumo-living-world-visual-20261029` | lib/features/learning | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F098 | 2026-10-29 | `repair/lumo-living-workshop-polish-20261029` | lib/features/learning | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F100 | 2026-10-26 | `sol/lumo-learning-repair-20261026` | lib/core/math_task_templates.dart, lib/core/task_hint_service.dart, test/adaptive_task_help_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F101 | 2026-10-23 | `repair/lumo-405-real-adventure-visibility-20261023` | lib/features/home, test/games/flame_adventure_flow_test.dart, test/games/flame_adventure_round_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F102 | 2026-10-21 | `sol/fix-answer-crystal-depth-20261021` | lib/features/learning_modules, test/design/minus_crystal_depth_regression_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F103 | 2026-10-20 | `ops/lumo-codex-checkpoint-protection-20261020`, `repair/lumo-nextgen-apk-qa-20261020` | lib/widgets/design, test/curriculum_cross_grade_navigation_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F105 | 2026-10-19 | `chatgpt/lumo-1987-denkprofil-knobel-unified-2026-10-19` | test/cognitive_profile_visual_prompt_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F104 | 2026-10-19 | `chatgpt/lumo-play-aab-secure-staging-2026-10-19` | lib/features/games, pubspec.yaml, scripts/tests/test_legacy_release_pin.py | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F107 | 2026-10-18 | `chatgpt/lumo-1978-connect-four-fold-controls-2026-10-18` | lib/features/games, test/games/connect_four_fold_controls_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F106 | 2026-10-18 | `chatgpt/lumo-meister-live-stage-2026-10-18` | lib/features/games, lib/features/quiz | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F108 | 2026-10-18 | `chatgpt/lumo-story-scene-art-transparent-2026-10-18` | lib/features/learning_modules, lib/features/story, lib/widgets/design | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F109 | 2026-10-16 | `claude/integration-stories-2026-10-16`, `chatgpt/gemini-story-compatibility-2026-10-15` | lib/features/story | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F110 | 2026-10-16 | `chatgpt/apk1948-resume-qa-2026-10-16` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F111 | 2026-10-16 | `chatgpt/lumo-cross-grade-hologlas-progress-safe-2026-10-16` | lib/features/learning, test/cross_grade_practice_storage_hardening_test.dart, test/cross_grade_visual_capture_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F113 | 2026-10-15 | `chatgpt/lumo-meister-host-safe-area-2026-10-15` | lib/features/quiz, test/lumo_meister_host_layout_regression_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F112 | 2026-10-15 | `perplexity/lumo-nvidia-tutor-pilot-2026-10-15` | Online-KI-Pilot (NVIDIA-Proxy) | nicht übernommen: Online-KI standardmäßig aus, bezahlte API nur mit Heinz | keine – Entscheidung Heinz | – |
| F114 | 2026-10-14 | `chatgpt/lumo-pr295-grade-semantic-tests-2026-10-14`, `chatgpt/lumo-story-reader-visual-fix-2026-10-14` | lib/features/story, test/design/lumo_story_actual_reader_visual_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F119 | 2026-10-14 | `chatgpt/lumo-1940-combined-test-apk-2026-10-14` | lib/features/agent, lib/features/story, pubspec.yaml | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F118 | 2026-10-14 | `chatgpt/lumo-1941-tutor-voice-hologlass-2026-10-14` | lib/features/agent, lib/features/learning, lib/features/story | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F117 | 2026-10-14 | `chatgpt/lumo-1942-family-preview-updates-2026-10-14` | lib/core/app_update_service.dart, lib/features/agent, lib/features/learning | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F116 | 2026-10-14 | `chatgpt/lumo-1943-grade-menu-content-audit-2026-10-14` | lib/core/app_update_service.dart, lib/features/agent, lib/features/home | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F115 | 2026-10-14 | `chatgpt/lumo-1944-mobile-learning-qa-2026-10-14` | lib/core/app_update_service.dart, lib/features/agent, lib/features/home | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F120 | 2026-10-14 | `sol/lumo-1939-local-qa-backup-2026-10-14` | test/story_setup_learning_path_grade_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F122 | 2026-10-13 | `fix/grade-learning-structure-2026-10-12` | lib/core/german_task_templates.dart, lib/core/lumo_brain.dart, lib/core/math_task_templates.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F121 | 2026-10-13 | `sol/lumo-app-audit-2026-10-13` | Oktober-Prüftests (Akademie-Navigation, Geschichten, Registry) | 2 Tests laufen unverändert grün und fehlten; übrige prüfen alte Oberfläche/„Sachkunde“ | übernommen: 41c8007c (2 Testdateien) | PASS LOKAL 3 Tests; 17 Okt-Testdateien gegen Linie: 14 rot (alte UI), 3 grün |
| F123 | 2026-10-13 | `sol/lumo-meister-20-stars-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F124 | 2026-10-12 | `chatgpt/lumo-1938-android-smoke-2026-10-12`, `chatgpt/lumo-1938-android-smoke-direct-2026-10-12`, `chatgpt/lumo-1938-complete-integration-2026-10-12`, `chatgpt/lumo-1938-evidence-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F125 | 2026-10-12 | `chatgpt/lumo-1938-emergency-fallback-2026-10-12`, `sol/lumo-1937-android-acceptance-2026-10-12`, `sol/lumo-1937-content-kart-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F126 | 2026-10-12 | `sol/lumo-1936-android-delivery-v3-2026-10-12`, `sol/lumo-1936-runtime-screenshots-2026-10-12`, `sol/lumo-1936-unified-integration-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F128 | 2026-10-12 | `sol/lumo-1932-download-2026-10-12`, `sol/lumo-1932-verified-bundle-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F127 | 2026-10-12 | `sol/lumo-1934-android-delivery-2026-10-12`, `sol/lumo-games-fold-1934-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F140 | 2026-10-12 | `sol/lumo-1933-android-delivery-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F136 | 2026-10-12 | `sol/lumo-1935-fold-return-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F134 | 2026-10-12 | `sol/lumo-1936-android-delivery-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F135 | 2026-10-12 | `sol/lumo-1936-android-delivery-v2-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F137 | 2026-10-12 | `sol/lumo-active-companion-2026-10-11` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F133 | 2026-10-12 | `sol/lumo-curriculum-depth-1938-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F139 | 2026-10-12 | `sol/lumo-guided-language-nature-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F130 | 2026-10-12 | `sol/lumo-learning-repair-check-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F131 | 2026-10-12 | `sol/lumo-learning-repair-check2-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F129 | 2026-10-12 | `sol/lumo-learning-repair-check3-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F132 | 2026-10-12 | `sol/lumo-meister-apk-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/english_vocabulary_extensions.dart, lib/core/german_curriculum_extensions.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F138 | 2026-10-12 | `sol/lumo-parent-report-privacy-2026-10-12` | lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart, lib/core/lumo_ai_proxy_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F141 | 2026-10-11 | `sol/lumo-adaptive-local-help-2026-10-11`, `sol/lumo-direct-download-2026-10-11` | lib/app/lumo_companion_host.dart, lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F145 | 2026-10-11 | `astra/lumo-learning-quality-2026-10-11` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F146 | 2026-10-11 | `computer/lumo-android-1929-runtime-repair-2026-10-11` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F142 | 2026-10-11 | `computer/lumo-android-1930-verified-bundle-2026-10-11` | lib/app/lumo_companion_host.dart, lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F147 | 2026-10-11 | `computer/lumo-education-excellence-2026-10-11` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F148 | 2026-10-11 | `computer/lumo-kart-android-1928-2026-10-11` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F144 | 2026-10-11 | `computer/lumo-learning-adventures-2026-10-11` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F143 | 2026-10-11 | `computer/lumo-learning-companion-discovery-2026-10-11` | lib/app/lumo_companion_host.dart, lib/core/embedded_game_service.dart, lib/core/learning_profile_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F149 | 2026-10-10 | `computer/lumo-1927-apk-handoff-2026-10-10`, `computer/lumo-1927-runtime-qa-same-apk-2026-10-10`, `computer/lumo-context-sulafat-2026-10-10`, `computer/lumo-rival-roster-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F155 | 2026-10-10 | `chatgpt/lumo-1925-apk-build-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_voice.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F153 | 2026-10-10 | `chatgpt/lumo-1926-sulafat-apk-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_sulafat_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F159 | 2026-10-10 | `chatgpt/lumo-aaa-kart-integration-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_voice.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F156 | 2026-10-10 | `chatgpt/lumo-onboarding-voice-1924-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_voice.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F152 | 2026-10-10 | `chatgpt/lumo-sulafat-everywhere-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_sulafat_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F154 | 2026-10-10 | `chatgpt/lumo-writing-stability-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_voice.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F163 | 2026-10-10 | `codex/lumo-kart-premium-apk-1921-2026-10-10` | pubspec.yaml | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F157 | 2026-10-10 | `codex/lumo-profile-android-1920-2026-10-10` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F160 | 2026-10-10 | `codex/lumo-profile-diagnostics-2026-10-10` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F158 | 2026-10-10 | `computer/lumo-aaa-integration-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_voice.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F161 | 2026-10-10 | `computer/lumo-cards-connect-four-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_voice.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F151 | 2026-10-10 | `computer/lumo-visual-foundation-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_story_generator.dart, lib/core/lumo_sulafat_client.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F150 | 2026-10-10 | `computer/lumo-voice-next-runtime-fixes-2026-10-10` | lib/core/embedded_game_service.dart, lib/core/lumo_ai_proxy_client.dart, lib/core/lumo_companion_engine.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F162 | 2026-10-10 | `perplexity/lumo-cards-approved-design-2026-10-10` | lib/features/games | überholt: Flutter-Kartenspiel entfernt (97e4f6fd) | keine | – |
| F164 | 2026-10-09 | `codex/lumo-app-recovery-2026-10-09`, `codex/lumo-integrated-runtime-2026-10-08` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F168 | 2026-10-09 | `chatgpt/learning-visual-fold-tree-2026-10-09` | lib/features/learning, lib/features/teacher_mode, test/design/lumo_learning_tree_fold_visual_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F171 | 2026-10-09 | `chatgpt/lumo-1917-apk-artifact-2026-10-09` | pubspec.yaml | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F165 | 2026-10-09 | `chatgpt/lumo-cards-landscape-hud-2026-10-09` | lib/features/games, lib/features/shared, lib/widgets/design | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F166 | 2026-10-09 | `chatgpt/lumo-learning-glass-cards-2026-10-09` | lib/features/games, lib/features/shared, lib/widgets/design | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F170 | 2026-10-09 | `chatgpt/lumo-learning-visual-apk-1915-2026-10-09` | pubspec.yaml | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F169 | 2026-10-09 | `codex/lumo-host-time-precision-2026-10-09` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F167 | 2026-10-09 | `codex/lumo-return-frame-recovery-2026-10-09` | tools/android_qa/tests | nur QA-Werkzeug/Belege zu alten Kandidaten (scripts/tests, tools/android_qa) | keine | – |
| F172 | 2026-10-08 | `codex/lumo-visual-fidelity-2026-10-08` | pubspec.yaml, tools/android_qa/tests | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F173 | 2026-10-07 | `chatgpt/lumo-complete-delivery-2026-10-07`, `chatgpt/lumo-complete-verified-2026-10-07`, `chatgpt/lumo-visual-polish-2026-10-07` | lib/app/app_shell.dart, lib/features/games, lib/features/home | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F174 | 2026-10-07 | `chatgpt/fix-akademie-practical-scroll-2026-10-06` | lib/app/app_theme.dart, lib/core/cognitive_profile_generator.dart, lib/core/cognitive_profile_repository.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F175 | 2026-10-07 | `chatgpt/lumo-complete-games-2026-10-07` | lib/app/app_shell.dart, lib/features/games, lib/features/home | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F178 | 2026-10-07 | `chatgpt/lumo-floating-animated-fox-2026-10-07` | lib/widgets/fox, test/lumo_free_companion_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F177 | 2026-10-07 | `chatgpt/parent-games-polish-2026-10-07` | lib/features/games, test/design/parent_games_polish_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F176 | 2026-10-07 | `copilot/ullmann27-lumo-lernen` | lib/features/games, test/lumo_cards_save_test.dart | überholt: Flutter-Kartenspiel entfernt (97e4f6fd) | keine | – |
| F179 | 2026-10-06 | `chatgpt/cards-resume-safety-2026-10-06` | lib/features/games, test/lumo_cards_controller_lifecycle_test.dart, test/lumo_cards_session_ui_test.dart | überholt: Flutter-Kartenspiel entfernt (97e4f6fd) | keine | – |
| F181 | 2026-10-06 | `chatgpt/hologlass-consistency-stage2-2026-10-06` | lib/features/games, lib/features/learning | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F182 | 2026-10-06 | `chatgpt/hologlass-quiz-stage3-2026-10-06` | lib/features/quiz | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F180 | 2026-10-06 | `chatgpt/lumo-learning-curriculum-cognitive-2026-10-06` | lib/app/app_theme.dart, lib/core/cognitive_profile_generator.dart, lib/core/cognitive_profile_repository.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F183 | 2026-10-05 | `chatgpt/fold-reference-recovery-2026-10-05` | lib/app/app_shell.dart, lib/features/home, lib/widgets/fox | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F184 | 2026-10-05 | `chatgpt/visual-fidelity-recovery-2026-10-05` | lib/app/app_shell.dart, lib/features/home, lib/widgets/design | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F185 | 2026-10-05 | `claude/design-lernen` | lib/app/app_shell.dart, lib/features/home | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F186 | 2026-10-05 | `copilot/review-first-172-170` | lib/core/game_progress_repository.dart, test/games/game_progress_persistence_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F188 | 2026-10-04 | `chatgpt/lumo-home-readability-2026-10-04` | test/home_readability_acceptance_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F189 | 2026-10-04 | `claude/design-tafeln` | test/lumo_design_tafeln_test.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F190 | 2026-10-04 | `claude/fix-learning-modules` | lib/features/learning_modules | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F187 | 2026-10-04 | `codex/lumo-holographic-2026-10-03` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/lumo_companion_host.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F191 | 2026-10-03 | `claude/voice-on-codex-followup` | Stimmenauswahl (System-TTS), Eltern-PIN mit Wiederherstellung | Stimme überholt (lokale Lumo-Stimme); Eltern-PIN fehlt der Linie (dort Erwachsenen-Bestätigung je Freigabe) | keine – offener Punkt Eltern-PIN (Entscheidung Heinz) | Tests kompilieren nicht gegen Linie |
| F193 | 2026-10-02 | `codex/lumo-school-readiness-followup-2026-10-02` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/lumo_companion_host.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F192 | 2026-10-02 | `codex/lumo-stage1-audit-44095eb` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/lumo_companion_host.dart | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F194 | 2026-06-17 | `claude/voice-improvement-fwjkX` | lib/core/app_settings.dart, lib/core/lumo_voice.dart, lib/features/settings | überholt: Oktober-Stand, betroffene Dateien auf der Linie neu aufgebaut (Stichproben: Oktober-Tests rot gegen neue Oberfläche, Sachkunde→Sachunterricht) | keine | – |
| F195 | 2026-05-28 | `copilot/hol-dir-den-neuesten-stand-von-lumo` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F201 | 2026-05-25 | `feat/pr-h1-star-burst` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F200 | 2026-05-25 | `feat/pr-h2-result-lottie` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F199 | 2026-05-25 | `feat/pr-h3-music` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F197 | 2026-05-25 | `feat/pr-i-audio-settings` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F198 | 2026-05-25 | `fix/ci-nuclear-remove-native-plugins` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F196 | 2026-05-25 | `fix/ci-rescue-l10n-yaml` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F202 | 2026-05-24 | `claude/asset-ai-briefing`, `claude/chatgpt-megaprompt`, `claude/i18n-foundation`, `claude/tier6-card-polish` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F210 | 2026-05-24 | `assets/lumo-pack-import` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F211 | 2026-05-24 | `claude/tier4-3d-optics` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F209 | 2026-05-24 | `feat/asset-registry-pr-a` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F206 | 2026-05-24 | `feat/pr-b-companion-pose` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F207 | 2026-05-24 | `feat/pr-c-lumo-sound-registry` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F204 | 2026-05-24 | `feat/pr-d-lottie` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F203 | 2026-05-24 | `feat/pr-e-svg-icons` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F208 | 2026-05-24 | `feat/pr-f-learning-questions` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F205 | 2026-05-24 | `feat/pr-g-error-sfx` | assets/icons/back.svg, assets/icons/bell.svg, assets/icons/bell_off.svg | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F215 | 2026-05-23 | `claude/lumo-cards-4-players` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F219 | 2026-05-23 | `claude/lumo-cards-animations` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F216 | 2026-05-23 | `claude/lumo-cards-more-anims` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F214 | 2026-05-23 | `claude/lumo-cards-multiplayer-rules` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F217 | 2026-05-23 | `claude/lumo-cards-smarter` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F213 | 2026-05-23 | `claude/tier1-foundation` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F212 | 2026-05-23 | `claude/tier3-audio` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F218 | 2026-05-23 | `claude/writing-canvas-touch-fix` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F231 | 2026-05-22 | `claude/feat-lumo-cards-avatar-picker` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F232 | 2026-05-22 | `claude/feat-lumo-cards-avatars` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F229 | 2026-05-22 | `claude/feat-lumo-cards-from-sheet` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F230 | 2026-05-22 | `claude/feat-lumo-cards-layout-polish` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F233 | 2026-05-22 | `claude/feat-lumo-cards-layout-spec` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F235 | 2026-05-22 | `claude/feat-lumo-cards-solo-bot` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F228 | 2026-05-22 | `claude/feat-lumo-cards-specials` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F234 | 2026-05-22 | `claude/feat-lumo-cards-uno-style` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F226 | 2026-05-22 | `claude/fix-lumo-cards-crash-overflow` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F221 | 2026-05-22 | `claude/fix-lumo-cards-debugneeds` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F227 | 2026-05-22 | `claude/fix-lumo-cards-still-crashes` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F222 | 2026-05-22 | `claude/lumo-cards-big-refactor` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F223 | 2026-05-22 | `claude/lumo-cards-dependents-fix` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F224 | 2026-05-22 | `claude/lumo-cards-hand-crash-fix` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F220 | 2026-05-22 | `claude/lumo-cards-hud-polish` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F225 | 2026-05-22 | `claude/lumo-cards-new-cards` | assets/lumo_cards/cards, assets/lumo_jump/fox, assets/lumo_kart/collectibles | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F240 | 2026-05-21 | `claude/design-polish-subject-tiles` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F237 | 2026-05-21 | `claude/feat-lumo-cards-mvp` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F243 | 2026-05-21 | `claude/fix-farben-wuerfel-kaputt` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F236 | 2026-05-21 | `claude/fix-lumo-cards-layout` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F242 | 2026-05-21 | `claude/fix-tutorial-jumps-writing` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F241 | 2026-05-21 | `claude/fix-update-detection-profile-reset` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F239 | 2026-05-21 | `claude/fix-wordcoach-crash-tutorial` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F244 | 2026-05-21 | `claude/in-app-update-keystore` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F238 | 2026-05-21 | `claude/phase56-on-main` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F245 | 2026-05-21 | `claude/polish-2-tiere` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F246 | 2026-05-20 | `claude/lumo-kart-premium-A9oBr` | assets/lumo_jump/fox, assets/lumo_kart/collectibles, assets/lumo_kart/effects | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F247 | 2026-05-18 | `codex/hybrid-lumo-voice`, `copilot/add-animated-lumo-fox`, `copilot/add-premium-voice-api`, `copilot/implement-hybrid-voice-patch` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F249 | 2026-05-18 | `codex/check-.github/workflows/release-apk.yml`, `copilot/quality-product-sprint-lumo-lernen`, `copilot/stabilize-existing-feature` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F248 | 2026-05-18 | `copilot/explore-codebase-implementation-plan`, `copilot/fix-android-debug-apk-build`, `copilot/fix-current-frame-index` | assets/lumo_jump/fox, lib/app/app_shell.dart, lib/app/app_state.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F250 | 2026-05-18 | `copilot/transfer-codex-clause-4-6` | assets/lumo_jump/fox, lib/app/app_shell.dart, lib/app/app_state.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F260 | 2026-05-17 | `codex/sprint-8-number-house` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F259 | 2026-05-17 | `copilot/analyze-and-refactor-code` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F261 | 2026-05-17 | `copilot/check-current-status` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F251 | 2026-05-17 | `copilot/create-lumo-lernen-app` | lib/app.dart, lib/main.dart, lib/navigation/adaptive_nav.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F252 | 2026-05-17 | `copilot/feat-engine-overhaul-timer-replacement` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F253 | 2026-05-17 | `copilot/finalize-lumo-jump-adventure` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F254 | 2026-05-17 | `copilot/fix-lumo-jump-game` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F258 | 2026-05-17 | `copilot/optimiere-spiel-performance-und-code-struktur` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F257 | 2026-05-17 | `copilot/optimize-game-code-performance` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F256 | 2026-05-17 | `copilot/stabilization-pr-39` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F255 | 2026-05-17 | `feat-lumo-jump-adventure-prototype` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/app_theme.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F262 | 2026-05-09 | `codex/find-current-app-status` | lib/app/app_state.dart, lib/app/app_theme.dart, lib/core/german_task_templates.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F263 | 2026-05-05 | `fix-v0.3.1-core-stabilization` | lib/app/app_shell.dart, lib/app/app_state.dart, lib/app/lumo_hint_request.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F264 | 2026-05-04 | `chore-chat-guard-patcher`, `chore-learn-guard-patcher`, `chore-reading-guard-patcher`, `chore-release-candidate-patcher` (+3) | lib/core/lumo_ai_policy_guard.dart, lib/features/reading, test/lumo_ai_policy_guard_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F265 | 2026-05-04 | `chore-problem-word-trainer`, `chore-syllable-ui-patcher`, `feat-reading-active-sentence-view`, `feat-reading-analyzer-integration` | lib/features/reading, test/lumo_learning_feedback_engine_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F266 | 2026-05-04 | `chore-smart-ears-patcher`, `feat-learning-rescue-feedback`, `feat-reading-unclear-feedback` | test/lumo_learning_feedback_engine_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F269 | 2026-05-04 | `feat-chat-enforce-ai-policy` | lib/core/lumo_ai_policy_guard.dart, lib/features/agent, lib/features/reading | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F267 | 2026-05-04 | `feat-integrated-ai-tutor` | lib/core/lumo_ai_policy_guard.dart, lib/core/lumo_ai_proxy_client.dart, lib/features/learning | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F270 | 2026-05-04 | `feat-learn-enforce-ai-policy` | lib/core/lumo_ai_policy_guard.dart, lib/features/learning, lib/features/reading | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F271 | 2026-05-04 | `feat-parents-ai-selector-ui` | lib/features/parents | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F268 | 2026-05-04 | `feat-reading-problem-word-trainer` | lib/features/reading, test/lumo_learning_feedback_engine_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F272 | 2026-05-04 | `p5-ai-mode-settings` | lib/core/app_settings.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F274 | 2026-05-03 | `audit-voice-barrel-20260503`, `audit-voice-widgets-20260503` | lib/features/shared, test/lumo_widgets_barrel_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F273 | 2026-05-03 | `chore-audit-tests-20260503b`, `chore-core-audit-tests-20260503` | lib/features/shared, test/lumo_widgets_barrel_test.dart, test/primary_school_word_data_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F278 | 2026-05-03 | `active-sentence-syllables-20260503` | lib/core/lumo_learning_help_orchestrator.dart, test/lumo_learning_help_orchestrator_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F283 | 2026-05-03 | `connect-reading-v2-20260503` | test/reading_syllable_chip_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F276 | 2026-05-03 | `feat-didactic-task-styles-20260503` | lib/core/lumo_didactic_task_style.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F275 | 2026-05-03 | `feat-modern-lumo-ui-components-20260503` | lib/features/shared, test/lumo_modern_widgets_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F280 | 2026-05-03 | `feature-wire-session-variety-20260502` | lib/core/primary_school_word_data.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F281 | 2026-05-03 | `fix-red-main-word-bank-variety-20260503` | lib/core/primary_school_word_data.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F279 | 2026-05-03 | `test-didactic-styles-20260503` | test/lumo_didactic_task_style_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F282 | 2026-05-03 | `test-recent-repository-20260503` | test/recent_task_repository_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F277 | 2026-05-03 | `voice-bubble-20260503` | lib/features/shared, test/lumo_voice_bubble_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F284 | 2026-05-02 | `feat/primary-word-bank-german-generator`, `task-word-bank-generator` | lib/core/school_exercise_generator.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F286 | 2026-05-02 | `feature-local-tutor-hints-20260502` | lib/features/learning | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F285 | 2026-05-02 | `feature-task-generator-20260502` | lib/core/school_exercise_generator.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |
| F287 | 2026-05-02 | `test-local-tutor-engine-20260502` | test/lumo_tutor_engine_test.dart | überholt: Mai-Stand vor dem Neuaufbau der App (alte Struktur, Dateien später ersetzt/entfernt) | keine | – |

### Neue Dateien aus Oktober-/Mai-Zweigen (einzeln beurteilt)

- `lumo_nvidia_pilot_client.dart` (perplexity, 15.10.): Online-KI-Pilot – nicht übernommen (Online-KI aus, bezahlte API nur mit Heinz).
- `parent_pin_setup_dialog.dart`, `parent_pin_recovery.dart`, `parental_gate.dart`, `parent_pin_service.dart` (claude/voice-on-codex-followup, codex/*-2026-10-02, fix-v0.3.1): Eltern-PIN – fehlt der Linie, die Linie fragt je Freigabe „als erwachsene Person“ und vermerkt den PIN als eigene Freigabestufe (`local_voice_license_dialog.dart`). **Offener Punkt / Entscheidung Heinz.**
- `lumo_voice_picker.dart`: überholt durch lokale Lumo-Stimme.
- `primary_curriculum_support.dart`: überholt durch neuen Lehrplan (Sachunterricht, österreichische Einheiten).
- `lumo_jump_adventure_game.dart`, `game_task_factory.dart`, `game_level_playability.dart`, `games_screen.dart`, `lumo_level_map.dart`, `weekly_challenge.dart`, `image_quiz_question.dart`: Mai-Spielprototypen – überholt durch Lumo Lauf (Godot), Flame-Sprungspiel und Spielewelt.
- `lib/screens/*`, `lib/services/*`, `lib/app.dart`, `adaptive_nav.dart` (copilot/create-lumo-lernen-app): eigenständiger früher Prototyp – überholt.
- `scanned_task_*`, `scanned_task_practice_content.dart`, `local_data_wipe_service.dart`, `lumo_hint_request.dart` (fix-v0.3.1): überholt durch Foto-Lektion, Profil-Zurücksetzen und Hilfe-Anfrage der Linie.
- `reading_problem_word_trainer.dart`, `lumo_learning_help_orchestrator.dart`, `lumo_voice_bubble.dart`, `lumo_primary_cta.dart`, `lumo_stat_pill.dart`, `lumo_didactic_task_style.dart`, `lumo_ai_policy_guard.dart`, `pixar_colors.dart`: überholt (Problemwörter im Lesen, `lumo_ai_learning_policy_bridge.dart`, neues Design-System).

## Prüfung

Siehe Bericht des Abschlusslaufs unten (wird mit dem letzten Commit eingetragen).

## Nur Belege / Werkzeug (102 Zweige)

Ohne fehlenden App- oder Testinhalt; der Rest sind `docs/evidence`, Doku, Probes, Workflows,
`config/test-apk-request.json`. Nicht einzeln aufgearbeitet, alle archivierbar.

## Offene Punkte

1. **Aufgabendialog (Chat4/NextGen, 8 Familien)**: zweite, parallele Fassung von Spracheingabe
   und Aufgabengespräch. Linie hat eine eigene; fachlicher Vergleich der Absichten
   (warum/alternativ/zeigen/Schritt/langsamer) steht aus – nicht blind übernommen.
2. **Englisch-Aussprache in der 3D-Lernszene** (`3a5b2241`, nur Kotlin/Java): fehlt; Kotlin
   ist hier nicht baubar → braucht Android-Kompilierlauf.
3. **Eltern-PIN**: Entscheidung Heinz.
4. **Online-KI-Pilot (NVIDIA)**: Entscheidung Heinz.
5. **WLAN/Geister-Duell** (`agent/verbinden`): Koordinator.
6. **Nachhilfe in 3D**: Godot-Szene „tutor“ (`lumo-2040/tutor-godot-20261117`) und
   MainActivity-Freigabe „tutor“ fehlen; danach `open3D` in `learning_content.dart` setzen.
7. ASR-Neutralität der Tagesempfehlung (`reading_asr_evidence_boundary_test`, 14.11.) nicht
   übernommen, weil die Linie die Empfehlung inzwischen anders aufbaut; fachlich prüfen.

## Zweige, die gefahrlos archiviert werden können

Alle 315 Vorfahren und 7 inhaltlich enthaltenen Zweige (Liste: `app.tsv` der Inventur),
die 102 Beleg-/Werkzeug-Zweige und – sobald `agent/inventur-app` zusammengeführt ist – die
folgenden 364 Zweige mit App-/Testrest (überholt oder hier übernommen).
**Nicht** archivieren, solange die offenen Punkte bestehen: `agent/verbinden`, `origin/fix/lumo-memory-child-safe-start-20261116`, `origin/integration/lumo-learning-nextgen-20261115`, `origin/repair/lumo-learning-workshop-relevance-20261116`, `origin/chatgpt/lumo-chat4-dialogue-20261115`, `origin/chatgpt/lumo-nextgen-blender-flutter-apk-20261115`, `origin/feature/lumo-nextgen-conversation-20261115-403a`, `origin/feature/lumo-nextgen-voice-20261115`, `origin/integration/lumo-reviewed-delta-20261115-58e0`, `origin/support/lumo-c4-open-close-20261115`, `origin/integration/lumo-next-authorities-lint-20261114`, `origin/integration/lumo-next-table-authorities-20261114`, `origin/validation/root-recovery-1750-20261114`, `origin/chatgpt/lumo-nextgen-feature-20261114`, `origin/chatgpt/lumo-studio-2020-20261114`, `origin/integration/lumo-next-candidate-1913-20261114`, `origin/perplexity/lumo-nvidia-tutor-pilot-2026-10-15`, `origin/claude/voice-on-codex-followup`, `origin/codex/lumo-school-readiness-followup-2026-10-02`, `origin/codex/lumo-stage1-audit-44095eb`.

<details><summary>364 Zweige mit App-/Testrest (archivierbar)</summary>

- `agent/holo-lernen`
- `origin/active-sentence-syllables-20260503`
- `origin/assets/lumo-pack-import`
- `origin/astra/lumo-learning-quality-2026-10-11`
- `origin/audit-voice-barrel-20260503`
- `origin/audit-voice-widgets-20260503`
- `origin/audit/lumo-originals-9de-20261114`
- `origin/chatgpt/apk1948-resume-qa-2026-10-16`
- `origin/chatgpt/cards-resume-safety-2026-10-06`
- `origin/chatgpt/fix-akademie-practical-scroll-2026-10-06`
- `origin/chatgpt/fold-reference-recovery-2026-10-05`
- `origin/chatgpt/gemini-story-compatibility-2026-10-15`
- `origin/chatgpt/hologlass-consistency-stage2-2026-10-06`
- `origin/chatgpt/hologlass-quiz-stage3-2026-10-06`
- `origin/chatgpt/learning-visual-fold-tree-2026-10-09`
- `origin/chatgpt/lumo-1917-apk-artifact-2026-10-09`
- `origin/chatgpt/lumo-1925-apk-build-2026-10-10`
- `origin/chatgpt/lumo-1926-sulafat-apk-2026-10-10`
- `origin/chatgpt/lumo-1938-android-smoke-2026-10-12`
- `origin/chatgpt/lumo-1938-android-smoke-direct-2026-10-12`
- `origin/chatgpt/lumo-1938-complete-integration-2026-10-12`
- `origin/chatgpt/lumo-1938-emergency-fallback-2026-10-12`
- `origin/chatgpt/lumo-1938-evidence-2026-10-12`
- `origin/chatgpt/lumo-1940-combined-test-apk-2026-10-14`
- `origin/chatgpt/lumo-1941-tutor-voice-hologlass-2026-10-14`
- `origin/chatgpt/lumo-1942-family-preview-updates-2026-10-14`
- `origin/chatgpt/lumo-1943-grade-menu-content-audit-2026-10-14`
- `origin/chatgpt/lumo-1944-mobile-learning-qa-2026-10-14`
- `origin/chatgpt/lumo-1978-connect-four-fold-controls-2026-10-18`
- `origin/chatgpt/lumo-1987-denkprofil-knobel-unified-2026-10-19`
- `origin/chatgpt/lumo-2005-star-trail-scroll-regression-fix-20261103`
- `origin/chatgpt/lumo-2015-android-garage-qa-20261111`
- `origin/chatgpt/lumo-2015-verified-apk-delivery-20261111`
- `origin/chatgpt/lumo-2018-android-acceptance-20261113`
- `origin/chatgpt/lumo-2018-review-recovery-20261113`
- `origin/chatgpt/lumo-2019-release-candidate-20261113`
- `origin/chatgpt/lumo-2020-android-qa-recovery-20261113`
- `origin/chatgpt/lumo-2020-direct-apk-delivery-20261113`
- `origin/chatgpt/lumo-aaa-kart-integration-2026-10-10`
- `origin/chatgpt/lumo-android-recheck-2019-20261113`
- `origin/chatgpt/lumo-android17-cli22-recheck-20261113`
- `origin/chatgpt/lumo-android17-framework-recheck-20261113`
- `origin/chatgpt/lumo-android17-sdk-diagnostic-20261113`
- `origin/chatgpt/lumo-cards-heartbeat-20261113`
- `origin/chatgpt/lumo-cards-landscape-hud-2026-10-09`
- `origin/chatgpt/lumo-complete-app-20261113`
- `origin/chatgpt/lumo-complete-delivery-2026-10-07`
- `origin/chatgpt/lumo-complete-games-2026-10-07`
- `origin/chatgpt/lumo-complete-verified-2026-10-07`
- `origin/chatgpt/lumo-creative-android-31883868-20261113`
- `origin/chatgpt/lumo-cross-grade-hologlas-progress-safe-2026-10-16`
- `origin/chatgpt/lumo-direct-village-flutter-20261114`
- `origin/chatgpt/lumo-floating-animated-fox-2026-10-07`
- `origin/chatgpt/lumo-games-3d-launch-20261103`
- `origin/chatgpt/lumo-historical-1999-verifier-20261113`
- `origin/chatgpt/lumo-home-readability-2026-10-04`
- `origin/chatgpt/lumo-learning-curriculum-audit-20261114`
- `origin/chatgpt/lumo-learning-curriculum-cognitive-2026-10-06`
- `origin/chatgpt/lumo-learning-glass-cards-2026-10-09`
- `origin/chatgpt/lumo-learning-visual-apk-1915-2026-10-09`
- `origin/chatgpt/lumo-meister-host-safe-area-2026-10-15`
- `origin/chatgpt/lumo-meister-live-stage-2026-10-18`
- `origin/chatgpt/lumo-onboarding-voice-1924-2026-10-10`
- `origin/chatgpt/lumo-play-aab-secure-staging-2026-10-19`
- `origin/chatgpt/lumo-playstore-agent-network-20261114`
- `origin/chatgpt/lumo-pr295-grade-semantic-tests-2026-10-14`
- `origin/chatgpt/lumo-story-reader-visual-fix-2026-10-14`
- `origin/chatgpt/lumo-story-scene-art-transparent-2026-10-18`
- `origin/chatgpt/lumo-studio-078-kart-recheck-20261114`
- `origin/chatgpt/lumo-studio-20261113`
- `origin/chatgpt/lumo-studio-31883868-evidence-20261113`
- `origin/chatgpt/lumo-studio-4ab-ocr-recheck-20261114`
- `origin/chatgpt/lumo-studio-4ab96666-evidence-20261114`
- `origin/chatgpt/lumo-studio-evidence-archive-20261114`
- `origin/chatgpt/lumo-studio-runtime-integration-20261113`
- `origin/chatgpt/lumo-sulafat-everywhere-2026-10-10`
- `origin/chatgpt/lumo-three-qa-workers-20261114`
- `origin/chatgpt/lumo-visual-polish-2026-10-07`
- `origin/chatgpt/lumo-writing-stability-2026-10-10`
- `origin/chatgpt/parent-games-polish-2026-10-07`
- `origin/chatgpt/visual-fidelity-recovery-2026-10-05`
- `origin/checkpoint/lumo-198dd3-build-evidence-20261114`
- `origin/checkpoint/lumo-198dd3-early-evidence-20261114`
- `origin/checkpoint/lumo-198dd3-native-evidence-20261114`
- `origin/checkpoint/lumo-9de-android-evidence-20261114`
- `origin/checkpoint/lumo-9de-early-evidence-20261114`
- `origin/checkpoint/lumo-9de-native-build-evidence-20261114`
- `origin/checkpoint/lumo-agent-publication-198dd3-20261114`
- `origin/checkpoint/lumo-agent-publication-7c5-20261114`
- `origin/checkpoint/lumo-agent-publication-9de-20261114`
- `origin/checkpoint/lumo-agent-publication-review-20261114`
- `origin/checkpoint/lumo-c4-cleanup-diagnostic-6b-20261114`
- `origin/checkpoint/lumo-c4-diagnostic-20261114`
- `origin/checkpoint/lumo-c4-flutter-repairs-20261114`
- `origin/checkpoint/lumo-c4-navigation-20261114`
- `origin/checkpoint/lumo-c4-preferences-20261114`
- `origin/checkpoint/lumo-c4-preferences-diagnostic-20261114`
- `origin/checkpoint/lumo-c4-return-51ec-diagnostic-20261114`
- `origin/checkpoint/lumo-c4-return-evidence-20261114`
- `origin/checkpoint/lumo-c4-return-fixtures-recovery-20261114`
- `origin/checkpoint/lumo-c4-return-observer-04-20261114`
- `origin/checkpoint/lumo-final-integration-20261114`
- `origin/checkpoint/lumo-kart-diagnostic-20261114`
- `origin/checkpoint/lumo-kart-observer-evidence-20261114`
- `origin/checkpoint/lumo-kart-scroll-recovery-20261114`
- `origin/checkpoint/lumo-live-combined-aab-20261114`
- `origin/checkpoint/lumo-live-publisher-ec936873-20261114`
- `origin/checkpoint/lumo-original-replay-ec-20261114`
- `origin/checkpoint/lumo-originals-9de-diagnostic-audit-20261114`
- `origin/checkpoint/lumo-unchanged-2020-diagnostic-20261114`
- `origin/checkpoint/lumo-unchanged-2020-diagnostic-union-20261114`
- `origin/checkpoint/lumo-village-return-diagnostic-20261114`
- `origin/chore-audit-tests-20260503b`
- `origin/chore-chat-guard-patcher`
- `origin/chore-core-audit-tests-20260503`
- `origin/chore-learn-guard-patcher`
- `origin/chore-problem-word-trainer`
- `origin/chore-reading-guard-patcher`
- `origin/chore-release-candidate-patcher`
- `origin/chore-smart-ears-patcher`
- `origin/chore-syllable-ui-patcher`
- `origin/claude/asset-ai-briefing`
- `origin/claude/chatgpt-megaprompt`
- `origin/claude/design-lernen`
- `origin/claude/design-polish-subject-tiles`
- `origin/claude/design-tafeln`
- `origin/claude/feat-lumo-cards-avatar-picker`
- `origin/claude/feat-lumo-cards-avatars`
- `origin/claude/feat-lumo-cards-from-sheet`
- `origin/claude/feat-lumo-cards-layout-polish`
- `origin/claude/feat-lumo-cards-layout-spec`
- `origin/claude/feat-lumo-cards-mvp`
- `origin/claude/feat-lumo-cards-solo-bot`
- `origin/claude/feat-lumo-cards-specials`
- `origin/claude/feat-lumo-cards-uno-style`
- `origin/claude/fix-farben-wuerfel-kaputt`
- `origin/claude/fix-learning-modules`
- `origin/claude/fix-lumo-cards-crash-overflow`
- `origin/claude/fix-lumo-cards-debugneeds`
- `origin/claude/fix-lumo-cards-layout`
- `origin/claude/fix-lumo-cards-still-crashes`
- `origin/claude/fix-tutorial-jumps-writing`
- `origin/claude/fix-update-detection-profile-reset`
- `origin/claude/fix-wordcoach-crash-tutorial`
- `origin/claude/i18n-foundation`
- `origin/claude/in-app-update-keystore`
- `origin/claude/integration-stories-2026-10-16`
- `origin/claude/lumo-android-integration-m0-aloove`
- `origin/claude/lumo-cards-4-players`
- `origin/claude/lumo-cards-animations`
- `origin/claude/lumo-cards-big-refactor`
- `origin/claude/lumo-cards-dependents-fix`
- `origin/claude/lumo-cards-hand-crash-fix`
- `origin/claude/lumo-cards-hud-polish`
- `origin/claude/lumo-cards-more-anims`
- `origin/claude/lumo-cards-multiplayer-rules`
- `origin/claude/lumo-cards-new-cards`
- `origin/claude/lumo-cards-smarter`
- `origin/claude/lumo-kart-premium-A9oBr`
- `origin/claude/lumo-living-world-visual-20261029`
- `origin/claude/lumo-nextgen-app-20261113`
- `origin/claude/phase56-on-main`
- `origin/claude/polish-2-tiere`
- `origin/claude/tier1-foundation`
- `origin/claude/tier3-audio`
- `origin/claude/tier4-3d-optics`
- `origin/claude/tier6-card-polish`
- `origin/claude/voice-improvement-fwjkX`
- `origin/claude/writing-canvas-touch-fix`
- `origin/codex/check-.github/workflows/release-apk.yml`
- `origin/codex/find-current-app-status`
- `origin/codex/hybrid-lumo-voice`
- `origin/codex/lumo-app-recovery-2026-10-09`
- `origin/codex/lumo-holographic-2026-10-03`
- `origin/codex/lumo-host-time-precision-2026-10-09`
- `origin/codex/lumo-integrated-runtime-2026-10-08`
- `origin/codex/lumo-kart-premium-apk-1921-2026-10-10`
- `origin/codex/lumo-profile-android-1920-2026-10-10`
- `origin/codex/lumo-profile-diagnostics-2026-10-10`
- `origin/codex/lumo-return-frame-recovery-2026-10-09`
- `origin/codex/lumo-visual-fidelity-2026-10-08`
- `origin/codex/sprint-8-number-house`
- `origin/computer/lumo-1927-apk-handoff-2026-10-10`
- `origin/computer/lumo-1927-runtime-qa-same-apk-2026-10-10`
- `origin/computer/lumo-aaa-integration-2026-10-10`
- `origin/computer/lumo-android-1929-runtime-repair-2026-10-11`
- `origin/computer/lumo-android-1930-verified-bundle-2026-10-11`
- `origin/computer/lumo-cards-connect-four-2026-10-10`
- `origin/computer/lumo-context-sulafat-2026-10-10`
- `origin/computer/lumo-education-excellence-2026-10-11`
- `origin/computer/lumo-kart-android-1928-2026-10-11`
- `origin/computer/lumo-learning-adventures-2026-10-11`
- `origin/computer/lumo-learning-companion-discovery-2026-10-11`
- `origin/computer/lumo-rival-roster-2026-10-10`
- `origin/computer/lumo-visual-foundation-2026-10-10`
- `origin/computer/lumo-voice-next-runtime-fixes-2026-10-10`
- `origin/connect-reading-v2-20260503`
- `origin/copilot/add-animated-lumo-fox`
- `origin/copilot/add-premium-voice-api`
- `origin/copilot/analyze-and-refactor-code`
- `origin/copilot/check-current-status`
- `origin/copilot/create-lumo-lernen-app`
- `origin/copilot/explore-codebase-implementation-plan`
- `origin/copilot/feat-engine-overhaul-timer-replacement`
- `origin/copilot/finalize-lumo-jump-adventure`
- `origin/copilot/fix-android-debug-apk-build`
- `origin/copilot/fix-current-frame-index`
- `origin/copilot/fix-lumo-jump-game`
- `origin/copilot/hol-dir-den-neuesten-stand-von-lumo`
- `origin/copilot/implement-hybrid-voice-patch`
- `origin/copilot/optimiere-spiel-performance-und-code-struktur`
- `origin/copilot/optimize-game-code-performance`
- `origin/copilot/quality-product-sprint-lumo-lernen`
- `origin/copilot/review-first-172-170`
- `origin/copilot/stabilization-pr-39`
- `origin/copilot/stabilize-existing-feature`
- `origin/copilot/transfer-codex-clause-4-6`
- `origin/copilot/ullmann27-lumo-lernen`
- `origin/delivery/lumo-2031-workshop-test-apk-20261116`
- `origin/delivery/lumo-2032-complete-source-to-apk-20261116`
- `origin/delivery/lumo-2034-gesamt-20261116`
- `origin/delivery/lumo-2035-complete-20261116`
- `origin/delivery/lumo-2037-memory-werkstatt-20261117`
- `origin/delivery/lumo-schach-2048-20261118`
- `origin/diagnostic/lumo-c4-preferences-51ec-20261114`
- `origin/diagnostic/lumo-c4-return-51ec-20261114`
- `origin/diagnostic/lumo-c4-return-74a-20261114`
- `origin/diagnostic/lumo-kart-scroll-6f42-20261114`
- `origin/evidence/lumo-final-flutter-ec936873-20261114`
- `origin/evidence/lumo-root-ec-review-20261114`
- `origin/evidence/lumo-union-preflight-f365-20261114`
- `origin/evidence/lumo-village-6b-diagnostic-originals-20261114`
- `origin/feat-chat-enforce-ai-policy`
- `origin/feat-core-add-ai-policy-guard`
- `origin/feat-didactic-task-styles-20260503`
- `origin/feat-integrated-ai-tutor`
- `origin/feat-learn-enforce-ai-policy`
- `origin/feat-learning-rescue-feedback`
- `origin/feat-lumo-jump-adventure-prototype`
- `origin/feat-modern-lumo-ui-components-20260503`
- `origin/feat-parents-ai-selector-ui`
- `origin/feat-reading-active-sentence-view`
- `origin/feat-reading-analyzer-integration`
- `origin/feat-reading-problem-word-trainer`
- `origin/feat-reading-unclear-feedback`
- `origin/feat-release-candidate`
- `origin/feat/asset-registry-pr-a`
- `origin/feat/pr-b-companion-pose`
- `origin/feat/pr-c-lumo-sound-registry`
- `origin/feat/pr-d-lottie`
- `origin/feat/pr-e-svg-icons`
- `origin/feat/pr-f-learning-questions`
- `origin/feat/pr-g-error-sfx`
- `origin/feat/pr-h1-star-burst`
- `origin/feat/pr-h2-result-lottie`
- `origin/feat/pr-h3-music`
- `origin/feat/pr-i-audio-settings`
- `origin/feat/primary-word-bank-german-generator`
- `origin/feature-local-tutor-hints-20260502`
- `origin/feature-task-generator-20260502`
- `origin/feature-wire-session-variety-20260502`
- `origin/feature/lumo-nextgen-learning-20261115`
- `origin/fix-learning-ui-and-tutor`
- `origin/fix-red-main-word-bank-variety-20260503`
- `origin/fix-v0.3.1-core-stabilization`
- `origin/fix/ci-nuclear-remove-native-plugins`
- `origin/fix/ci-rescue-l10n-yaml`
- `origin/fix/grade-learning-structure-2026-10-12`
- `origin/fix/lumo-core-menu-presenter-20261116`
- `origin/fix/lumo-lab-route-scope-20261116`
- `origin/fix/lumo-learning-conversation-scope-20261115`
- `origin/integration/lumo-2031-learning-workshop-repair-20261116`
- `origin/integration/lumo-agent-execution-20261114`
- `origin/integration/lumo-c4-connections-20261114`
- `origin/integration/lumo-c4-publisher-20261114`
- `origin/integration/lumo-discovery-host-7136-20261114`
- `origin/integration/lumo-learning-generation-20261115-ea41`
- `origin/integration/lumo-live-connections-20261114`
- `origin/integration/lumo-next-hub-20261114`
- `origin/integration/lumo-next-repair-1952-20261114`
- `origin/lumo-2014/cards-games-20261110`
- `origin/lumo-2014/cards-resume-20261110`
- `origin/lumo-2014/learning-tutor-20261110`
- `origin/lumo-2014/quiz-lock-final-20261110`
- `origin/lumo-2014/quiz-lock-lifetime-20261110`
- `origin/lumo-2040/memory-20261117`
- `origin/lumo-2040/tutor-20261117`
- `origin/ops/lumo-codex-checkpoint-protection-20261020`
- `origin/p5-ai-mode-settings`
- `origin/perplexity/lumo-cards-approved-design-2026-10-10`
- `origin/qa/lumo-2031-lab-runtime-cases-20261116`
- `origin/qa/lumo-2049-android-rundgang`
- `origin/qa/lumo-all-registers-grade-1-4-visual-20261031`
- `origin/qa/lumo-android-runtime-1e22-20261114`
- `origin/qa/lumo-c4-small-result-actions-20261114-2708`
- `origin/qa/lumo-c4-small-result-actions-20261114-2708-r2`
- `origin/qa/lumo-c4-small-result-actions-20261114-2708-r3`
- `origin/qa/lumo-console-joystick-7b16-20261114`
- `origin/qa/lumo-console-start-7b16-20261114`
- `origin/qa/lumo-creative-51e-20261113`
- `origin/qa/lumo-kart-observer-20261114`
- `origin/qa/lumo-nextgen-2029-native-diagnostic-20261116`
- `origin/qa/lumo-nextgen-2032-runtime-cases-20261116`
- `origin/qa/lumo-nextgen-native-reference-diagnostic-20261115`
- `origin/qa/lumo-nextgen-pattern-reader-20261116`
- `origin/qa/lumo-original-replay-selftest-ec-20261114`
- `origin/qa/lumo-recording-start-20261116`
- `origin/qa/lumo-village-return-6b-20261114`
- `origin/recovery/lumo-c4-return-fixtures-20261114`
- `origin/release/lumo-2020-arm64-one-apk-20261114`
- `origin/repair/lumo-2020-exact-learning-20261114`
- `origin/repair/lumo-2020-one-apk-20261114`
- `origin/repair/lumo-2020-village-hook-20261114`
- `origin/repair/lumo-405-real-adventure-visibility-20261023`
- `origin/repair/lumo-c4-safe-entry-20261114`
- `origin/repair/lumo-exact-learning-20261114`
- `origin/repair/lumo-historical-diagnostic-fixture-20261114`
- `origin/repair/lumo-live-diagnostic-20261114`
- `origin/repair/lumo-live-drawing-20261114`
- `origin/repair/lumo-live-village-android-20261114`
- `origin/repair/lumo-live-village-host-20261114`
- `origin/repair/lumo-living-workshop-polish-20261029`
- `origin/repair/lumo-native-3d-games-hub-entry-20261114`
- `origin/repair/lumo-nextgen-apk-qa-20261020`
- `origin/repair/lumo-producer-flutter-union-20261114`
- `origin/repair/lumo-single-apk-20261114`
- `origin/sol/fix-answer-crystal-depth-20261021`
- `origin/sol/lumo-1932-download-2026-10-12`
- `origin/sol/lumo-1932-verified-bundle-2026-10-12`
- `origin/sol/lumo-1933-android-delivery-2026-10-12`
- `origin/sol/lumo-1934-android-delivery-2026-10-12`
- `origin/sol/lumo-1935-fold-return-2026-10-12`
- `origin/sol/lumo-1936-android-delivery-2026-10-12`
- `origin/sol/lumo-1936-android-delivery-v2-2026-10-12`
- `origin/sol/lumo-1936-android-delivery-v3-2026-10-12`
- `origin/sol/lumo-1936-runtime-screenshots-2026-10-12`
- `origin/sol/lumo-1936-unified-integration-2026-10-12`
- `origin/sol/lumo-1937-android-acceptance-2026-10-12`
- `origin/sol/lumo-1937-content-kart-2026-10-12`
- `origin/sol/lumo-1939-local-qa-backup-2026-10-14`
- `origin/sol/lumo-active-companion-2026-10-11`
- `origin/sol/lumo-adaptive-local-help-2026-10-11`
- `origin/sol/lumo-app-audit-2026-10-13`
- `origin/sol/lumo-curriculum-depth-1938-2026-10-12`
- `origin/sol/lumo-direct-download-2026-10-11`
- `origin/sol/lumo-games-fold-1934-2026-10-12`
- `origin/sol/lumo-guided-language-nature-2026-10-12`
- `origin/sol/lumo-learning-repair-20261026`
- `origin/sol/lumo-learning-repair-check-2026-10-12`
- `origin/sol/lumo-learning-repair-check2-2026-10-12`
- `origin/sol/lumo-learning-repair-check3-2026-10-12`
- `origin/sol/lumo-meister-20-stars-2026-10-12`
- `origin/sol/lumo-meister-apk-2026-10-12`
- `origin/sol/lumo-parent-report-privacy-2026-10-12`
- `origin/task-word-bank-generator`
- `origin/test-didactic-styles-20260503`
- `origin/test-local-tutor-engine-20260502`
- `origin/test-recent-repository-20260503`
- `origin/ux/lumo-scroll-all-sections-20261103`
- `origin/validation/lumo-native-bebf7bba-20261114`
- `origin/voice-bubble-20260503`
- `origin/work/lumo-dream-ui-recovery-20261114`
- `origin/work/lumo-nextgen-voice-20261115-ea41`
- `origin/work/lumo-spielwelt-studio-20261114`

</details>

<details><summary>102 Beleg-/Werkzeug-Zweige (archivierbar)</summary>

- `origin/audit/lumo-1919-diagnostics-2026-10-09`
- `origin/audit/lumo-1919-gas-recovery-2026-10-09`
- `origin/audit/lumo-1919-verified-package-2026-10-09`
- `origin/chatgpt/android-install-upgrade-2026-10-07`
- `origin/chatgpt/fold-apk-android-2026-10-07`
- `origin/chatgpt/fold-apk-build-2026-10-07`
- `origin/chatgpt/fold-native-check-2026-10-07`
- `origin/chatgpt/gemini-source-export-2026-10-15`
- `origin/chatgpt/install-upgrade-2026-10-07`
- `origin/chatgpt/lumo-1916-apk-artifact-2026-10-09`
- `origin/chatgpt/lumo-1963-direct-arm64-apk-2026-10-16`
- `origin/chatgpt/lumo-1977-verified-arm64-download-2026-10-18`
- `origin/chatgpt/lumo-1991-full-race-qa-2026-10-20`
- `origin/chatgpt/lumo-1992-direct-release-20261020`
- `origin/chatgpt/lumo-2016-direct-apk-candidate-20261111`
- `origin/chatgpt/lumo-2017-publication-recovery-20261112`
- `origin/chatgpt/lumo-asset-delivery-2026-10-04`
- `origin/chatgpt/lumo-asset-production-100plus-2026-10-05`
- `origin/chatgpt/lumo-ci-evidence-followup-2026-10-04`
- `origin/chatgpt/lumo-inventory-2026-10-13`
- `origin/chatgpt/lumo-kart-assets-handoff-2026-10-10`
- `origin/chatgpt/lumo-kart-graphics-apk-20261113`
- `origin/chatgpt/lumo-next-integration-2026-10-07`
- `origin/chatgpt/lumo-product-brief-2026-10-04`
- `origin/chatgpt/lumo-sonnenhafen-godot-pin-2026-10-15`
- `origin/chatgpt/lumo-sonnenhafen-unified-apk-2026-10-15`
- `origin/chatgpt/lumo-technical-art-host-20261111`
- `origin/chatgpt/lumo-visual-prep-2026-10-05`
- `origin/checkpoint/lumo-2018-card-recovery-20261113`
- `origin/checkpoint/lumo-live-publisher-04a8-20261114`
- `origin/checkpoint/lumo-live-publisher-1e22-20261114`
- `origin/checkpoint/lumo-live-publisher-20261114`
- `origin/checkpoint/lumo-live-publisher-6b-20261114`
- `origin/checkpoint/lumo-live-qa-aab09275-20261114`
- `origin/checkpoint/lumo-original-replay-04-20261114`
- `origin/checkpoint/lumo-original-replay-6b-20261114`
- `origin/claude/design-targets-heinz`
- `origin/claude/design-test-apk`
- `origin/claude/kart-test-apk`
- `origin/claude/lumo-2027-coordination-20261029`
- `origin/claude/lumo-2027-parents-20261029`
- `origin/claude/lumo-aaa-spielwelt-20261113`
- `origin/claude/qa-empty-semantics-retry`
- `origin/codex/lumo-1905-original-android-diagnosis-2026-10-08`
- `origin/codex/lumo-1985-spatial-reading-2026-10-19`
- `origin/codex/lumo-kart-event-forensics-2026-10-09`
- `origin/codex/lumo-kart-menu-1921-2026-10-10`
- `origin/codex/lumo-main-proof-read-2026-10-10`
- `origin/codex/lumo-tutor-quota-diagnostics-2026-10-03`
- `origin/codex/lumo-unified-android-2026-10-03`
- `origin/codex/opus-86c5a33-test-apk`
- `origin/delivery/lumo-nextgen-2031-replay-20261116`
- `origin/design/lumo-cards-build-connect-four-2026-10-10`
- `origin/design/lumo-nextgen-visual-brief-20261020`
- `origin/docs/lumo-2031-delivery-status-20261116`
- `origin/docs/lumo-living-intelligence-verification-20261029`
- `origin/docs/lumo-nextgen-2032-delivery-draft-20261116`
- `origin/docs/lumo-nextgen-host-source-coverage-20261116`
- `origin/evidence/lumo-home-village-captures-20261114`
- `origin/evidence/lumo-publisher-syntax-20261114`
- `origin/feat-settings-ai-selector-visible`
- `origin/feature-session-variety-guard-20260502`
- `origin/feature/lumo-jungle-emerald-3600-20261115-a298`
- `origin/fix-actions-artifact-quota-20260503`
- `origin/fix/lumo-source-public-download-20261116`
- `origin/integration/lumo-2022-complete-20261115`
- `origin/integration/lumo-learning-dschungelherz-2032-20261116`
- `origin/integration/lumo-magic-family-apk-20261114`
- `origin/integration/lumo-nextgen-learning-20261115`
- `origin/qa/lumo-2004-real-upgrade-20261031`
- `origin/qa/lumo-2020-legible-3d-entry-20261114`
- `origin/qa/lumo-2020-visible-flutter-20261114`
- `origin/qa/lumo-2031-active-syllable-observation-20261116`
- `origin/qa/lumo-2031-immutable-replay-20261116`
- `origin/qa/lumo-2031-native-runtime-cases-20261116`
- `origin/qa/lumo-foreground-transition-20261116`
- `origin/qa/lumo-mic-postgrant-reader-20261116`
- `origin/qa/lumo-native-panel-readiness-20261116`
- `origin/qa/lumo-nextgen-2028-replay-implementation-20261116`
- `origin/qa/lumo-nextgen-2031-android-20261116`
- `origin/qa/lumo-nextgen-reference-android-20261115`
- `origin/qa/lumo-original-replay-selftest-04-20261114`
- `origin/qa/lumo-original-replay-selftest-6b-20261114`
- `origin/qa/lumo-permission-reader-20261116`
- `origin/qa/lumo-prompt-label-contrast-20261114-2708`
- `origin/qa/lumo-resize-capture-20261116`
- `origin/qa/lumo-supplemental-academy-navigation-20261116`
- `origin/qa/lumo-supplemental-numeric-capture-20261116`
- `origin/recovery/lumo-public-bases-20261106`
- `origin/release/lumo-1993-direct-chrome-20261021`
- `origin/release/lumo-2002-family-button-20261029`
- `origin/release/lumo-2004-family-update-20261102`
- `origin/release/lumo-2020-wiring-apk-20261114`
- `origin/repair/lumo-capture-state-20261114`
- `origin/repair/lumo-console-and-joystick-7b16-20261114`
- `origin/repo-tests-20260503`
- `origin/sol/lumo-release-repair-20261026`
- `origin/sol/lumo-update-repair-20261026`
- `origin/sol/lumo-writing-repair-20261026`
- `origin/speech-tools-20260503`
- `origin/test-german-generator-20260503`
- `origin/work/lumo-learning-audit-20261114`

</details>
