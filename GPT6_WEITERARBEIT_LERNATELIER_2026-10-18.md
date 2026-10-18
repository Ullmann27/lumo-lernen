# Übergabe an GPT‑6: Lumo Lernen, Lernatelier

**Der Nutzer hat die laufende Umsetzung am 18.10.2026 ausdrücklich zum Abschluss und zur Übergabe angehalten. Hier fortsetzen, nicht neu beginnen. Lumo Kart bleibt vollständig außerhalb dieses Auftrags.**

## Stand und GitHub-Basis

- Repository: `Ullmann27/lumo-lernen`.
- Neuer isolierter Branch: `codex/lumo-learning-lab-2026-10-18`.
- Worktree dieser Sitzung: `/workspace/lumo-learning-work`; unveränderte Basis separat unter `/workspace/lumo-lernen`.
- Basis-SHA: `0e6373e3f2e7b5abd2322280d996c0392d993b0e`, PR #368, auf PR #367 aufgebaut. Nicht auf Main oder dem älteren 1977-Branch neu starten.
- PR #367 ist der 1978-Kandidat mit echten Schriften, Fold-Korrekturen und separater ARM64-Auslieferung. PR #368 ergänzt nur die Android-OCR-Prüfung. Dessen vollständiger Androidlauf [#39104800278](https://github.com/Ullmann27/lumo-lernen/actions/runs/39104800278) wurde frisch als `completed / success` auf der Basis-SHA gelesen. Das ist ein **Basisnachweis**, kein Androidnachweis der neuen Lernatelier-Grundlagen.
- App-Version weiterhin `0.12.66+1978`. `config/godot-source.json`, sämtliche nativen Quellen, Kart-Dateien und alte APKs unverändert.

## Ursprünglicher Plan

Eine integrierte, lokale Lernreise mit fünf Welten bauen: Zehnerbrücke, Wortwerkstatt, englischer Alltagssatz, Wasserweg/Pflanzenfunktionen und Bruchatelier. Ein Kind sieht ein korrekt erklärtes Beispiel, baut danach einen neuen Lösungsweg, ruft eine weitere Antwort frei ab und bearbeitet einen neuen Transfercheck. Hilfe steigt von kurzem Hinweis über Prinzip/Modell/Beispiel bis zur kleinen Teilfrage. Ein Rückblick zeigt konkret, was mit Hilfe und was selbstständig gelang.

Die gemeinsame Grundlage erweitert die vorhandenen sicheren Komponenten. Keine zweite Profildatenbank, kein Cloud-KI-Zwang, keine Umrechnung alter Lernstände. Original-Lumo, seine Stimme/Posen und vorhandene Belohnungen nutzen. Große neue Effekte dürfen die Arbeitsobjekte nicht verdecken. Alle alten Lernmodule, Schreiben, Journal und Profile bleiben erreichbar.

Entwurf: [Design](docs/superpowers/specs/2026-10-18-learning-lab-design.md).
Arbeitsplan: [Plan](docs/superpowers/plans/2026-10-18-learning-lab.md).

## Fertig implementierte Grundlagen

1. `lib/core/learning_journey.dart`: lokale Lernbelege, getrennte unterstützte/selbstständige Erfolge, Fehlertags, unterschiedliche Problemidentitäten, Transfer und späterer Abruf. Status `In Übung`, `Selbstständig geprüft`, `Später erinnert`. Intervalle 1/3/7/14 Tage ausdrücklich als Produktheuristik, keine validierte Diagnose. FIFO-Deduplizierung der letzten 128 Versuche, begrenzte Datenmengen, keine freien Antworten/Namen/Audiodaten im neuen Modell.
2. `ProgressRepository` und `LearningProfileEngine`: zusätzliche versionierte Struktur im vorhandenen Kinder-Namensraum; unbekannte oder beschädigte Formate bleiben erhalten; fehlgeschlagene Writes bleiben wiederholbar. `flush`, Reset und `hasUnsavedChanges` berücksichtigen die neue Struktur.
3. `lib/core/lumo_learning_narration.dart`: sitzungsgebundenes Vorlesen, Wiederholen, Pause und Ende über die vorhandene zentrale Stimme. Automatisches Feedback wird bei belegter Ausgabe verworfen, statt eine Erklärung zu unterbrechen. Keine neue Stimme oder neue Audioassets hergestellt. Native Wiedergabetests simulieren den Plattformkanal.
4. `lib/features/learning/lab/learning_lab_catalog.dart`: fünf lokale Themen mit insgesamt 30 unterschiedlichen Problemen. Berechnete/überprüfte Antworten, stabile Problem-IDs, fünf Hilfstexte, Worked Examples, Reflexionssätze und vorsichtige aufgabenbezogene Fehlermuster. Klasse 1: Brücke/Wörter/Natur; Englisch ab Klasse 2; Brüche ab Klasse 4.
5. `lib/features/learning/lab/learning_manipulatives.dart`: echte kontrollierte Widgets für bewegliche Plättchen im Zehnerfeld, gleich große Bruchsektoren sowie Wort-/Prozessbausteine mit Reihenfolge und Undo. Räumliche Materialien, Schatten/Lichtkanten; 48dp-Bedienflächen, Semantik, Tastatur, 280dp Breite/2× Schrift, reduzierte Bewegung geprüft.
6. `LearningModuleProgress`: optional `learningEvidence` bei `saveAnswer` und `saveObservation(evidence)` für begleitete Konstruktionen ohne Schulantwort/Daily/Belohnung. Dieselbe eingefangene Profilidentität und Retry-Grenze. Journal-Retry sendet **dieselbe Versuch-ID** erneut; die Engine dedupliziert. Keine fragile „schon gespeichert“-Markierung vor einer möglicherweise fehlgeschlagenen Validierung.

Die unabhängige Abschlussprüfung fand eine wichtige Grenze: Begleitete Beobachtungen durften anfänglich `helpLevel:0` verwenden. Die Regression wurde rot ausgeführt und korrigiert: `saveObservation` erfordert Hilfe >0; `saveAnswer(hintUsed:true, evidence.helpLevel:0)` wird abgelehnt; eine Hilfe im Beleg setzt auch das bestehende Schul-`hintUsed`. Keine unberechtigte Selbstständigkeit aus Hilfen.

## Exakte APIs

```dart
LearningEvidence(taskId: ..., problemId: ..., correct: ...,
  helpLevel: 0, transferCheck: false, errorTag: ...);
// taskId: neuer Versuch, beim Speicher-Retry identisch.
// problemId: feste Katalogaufgabe, bei erneutem Versuch unverändert.

await owner.profile.loadJourney();
owner.profile.journey.records[SkillRecord.makeId(subject, unit)];
await owner.profile.recordJourneyEvidence(
  subject: subject, unit: unit, evidence: evidence);
await owner.profile.flushJourney();
// JourneySkill: status/statusLabel/explanation/recommendationReason(now),
// attempts, independentCorrect, assistedCorrect, transferCorrect,
// errorCounts, dueAt, lastSeen.

QuantityBridgeBoard(start: ..., addend: ..., moved: ...,
  onChanged: ..., enabled: true, reveal: false, reduceMotion: ...);
FractionBuildBoard(denominator: ..., selected: <int>{},
  onChanged: ..., enabled: true, reduceMotion: ...);
LearningTokenWorkbench(tokens: ..., selected: <int>[],
  onChanged: ..., enabled: true, reduceMotion: ...);

// Narration ist ein ChangeNotifier:
LumoLearningNarration(); // read, feedback, repeat, pause, stop -> Future<void>
// currentText, isPaused, isActive; dispose beim Verlassen.
```

## Genau hier wurde aufgehört

**Die neue Laufzeit-Sitzung und ihr Einstieg wurden noch nicht geschrieben.** `LearningLabScreen`, `learning_lab_hub.dart` und eine neue räumliche Gesamtbühne existieren noch nicht. Die neuen Manipulativ-Widgets, der Katalog und Narrationscontroller sind daher noch nicht vom produktiven App-Start erreichbar. Die Grundlagen sind kein fertiger sichtbarer Grafikumbau. Bestehende Bildkurse wurden nicht verändert.

Der nächste testgetriebene Schritt wurde bereits vorbereitet: [Laufzeittest-Entwurf](docs/superpowers/drafts/learning_lab_runtime_test.dart.txt). Er liegt absichtlich als `.dart.txt` außerhalb `test/`, weil er auf die noch fehlende `LearningLabScreen` verweist. Nicht als bestehenden oder bestandenen Test ausgeben. Bei Fortsetzung nach `test/learning_lab_runtime_test.dart` kopieren, API/Schlüssel mit den echten Boards abgleichen und zunächst rot ausführen. Der echte Plus-Knopf heißt `quantity-add`.

## Nächster Entwicklungsblock für GPT‑6

1. Frischen Branch/PR-/CI-Stand abrufen; eigene letzte Commits und dieses Handoff lesen. Nicht bereits fertige Grundlagen nochmals implementieren.
2. `LearningLabScreen(appState:, topic:, seed:)` mit den Phasen Beispiel → Bauen → freier Abruf → neuer Transfer → Rückblick implementieren. Für seed 0 nimmt der Entwurf aufeinanderfolgende Katalogprobleme 0/1/2/3; Mathe dann Beispiel 8+5, Bauen 7+5 bis zur Zehn, freier Abruf 9+7=16, Transfer 6+5=11. Keine Antwortauswahl im unabhängigen Check.
3. Daten über `captureLearningProfile`/`prepareLearningLease` laden und auf Profilgeneration, Reset, Route und Klassenfreigabe prüfen. Begleitete Modellaktionen nur über `saveObservation(helpLevel>=1)`, unabhängige Antworten über `saveAnswer(learningEvidence:...)`. Nach einer erklärenden Fehlerrückmeldung zählt eine Wiederholungsantwort konservativ als unterstützt. Wiederholte identische Aufgaben sind kein neuer Transferbeleg.
4. Hilfen stufenweise einblenden. Das Modell im freien Abruf zunächst verbergen; erst bei ausdrücklicher Hilfe zeigen. Worked Example mit anderen Zahlen verwenden. Bei mehrfachen Fehlern eine Teilfrage anbieten statt zehn identische Endfragen. Automatisches Feedback nur bei aktivierter Sprache/AutoRead und freier Narration. Vorhandenen `lastError` und lokale Sprachlizenz respektieren.
5. `LearningLabHub` mit echten Journey-Status/Gründen und frei wählbaren freigegebenen Themen bauen. Nach Rückkehr neu laden. In Home/Akademie und normalem GuidedLearningHub anbinden. Entdeckungsfreigaben nicht umgehen; Schul- und Entdeckungsdaten getrennt halten.
6. Optional „Selbst bauen“ in `guided_lesson_screen.dart` für gültige Zehnerbrücken-/Bruch-/Silbenschritte ergänzen. Hilfe auf mindestens 3 setzen, Board beim `_startStep` zurücksetzen, bestehende Auswahlantworten/Speicher-/Sprach-/Entdeckungsflüsse erhalten. Diese Integration wurde nur gelesen, **nicht begonnen**.
7. Original-Fuchsposen über `LumoCharacterController` für Erklären/Denken/Ermutigen/Erfolg verwenden. Reduzierte Animationen, App-Hintergrund und unsichtbare Routen beachten. Keine neue Figur erfinden.
8. Ganze Flutter-Suite, Integrations-/Speicher-/Profil-/Sprachtests und Layoutmatrix (320dp, Fold innen, Querformat, 2× Schrift) ausführen. Echte PNGs und Animationssequenz erst mit `loadLumoCaptureFonts()` und bei Bedarf `loadLumoCaptureEmojiFont()` aufnehmen, tatsächlich ansehen und `tools/qa/verify_capture_fonts.py` ausführen. Komponentenrender sind keine Android-Screenshots.
9. Erst nach integrierter, geprüfter Sitzung einen eigenen Androidkandidaten mit **neuer** freier Versionsnummer bauen. Den bisherigen Godot-Pin unangetastet übernehmen; die bestehende fail-closed Versionszuordnung verlangt eine explizite neue Packaging-Zulassung, keine Änderung der alten Pins. Eigenen APK-Dateinamen/Artefakt und Hash liefern. Kein Main-Merge/Release.

## Tests und echte Grenzen dieses Zwischenstands

SDK in dieser Cloud: `/workspace/flutter/bin/flutter`, 3.44.9 / Dart 3.12.2. `flutter pub get --enforce-lockfile` erfolgreich. Keine neuen Pakete.

Finale gezielte Prüfung: **104 Tests bestanden, Exit 0**, einschließlich der Reviewkorrektur. Kommando: `flutter test --no-pub --reporter=expanded test/learning_lab_catalog_test.dart test/learning_lab_manipulatives_test.dart test/learning_lab_progress_test.dart test/learning_journey_test.dart test/learning_speech_narration_test.dart test/learning_speech_playback_test.dart test/progress_repository_storage_test.dart test/progress_repository_corruption_test.dart test/learning_profile_isolation_test.dart test/discovery_progress_test.dart`. Neue Sprachdateien zusätzlich mit 164 Sprach-/Datenschutz-/Sitzungsfällen geprüft. Nur die finalen Ergebnisse übernehmen, nicht die absichtlich roten Entwicklungsdurchläufe.

Vollanalyse hat dieselben 44 bestehenden **Info**-Meldungen wie die Basis, keine neuen Warnungen/Fehler; daher vorhandenen CI-Aufruf `flutter analyze --no-fatal-infos --no-fatal-warnings` verwenden und Infos transparent berichten.

Der separate vollständige Basislauf unter `/workspace/lumo-lernen` war bei Übergabevorbereitung noch aktiv; nicht dessen Zwischenzähler als Gesamterfolg ausgeben. Vollständige neue Branch-Suite/Android-Integration sind noch offen.

**Keine neuen App-Screenshots, keine neue App-Animationsaufnahme, keine neue hörbare Cartoon-Stimme, keine neue APK und keine physische Fold-/FPS-Prüfung in diesem Zwischenstand.** Originalclips wurden dekodiert/vermessen, siehe [Sprachnachweis](docs/evidence/learning-lab/speech.md). Kein Nutzer-Lernstand oder vorhandenes APK überschrieben.

## Commits vor dem Abschluss

- `b73d505`: überprüfte Basis, Design und Arbeitsplan.
- `65e92c6`: lokaler Aufgabenkatalog und Feedback.
- `53d4d5e`: Narrationscontroller mit Tests und ehrlichem Audiobefund.
- `98d250d`: lokale Lernbelege und Speicher-/Wiederholungsmodell.
- `218aafa`: interaktive Arbeitsobjekte mit Zugänglichkeitsprüfungen.
- Anschließender Abschlusscommit: sicherer Speicheranschluss, Reviewkorrektur und diese Übergabe. Die endgültige SHA über `git log` feststellen.

Keine eigenständige neue GPT‑6-Sitzung wird automatisch gestartet. Dieses Dokument ist der konkrete Fortsetzungsauftrag.
