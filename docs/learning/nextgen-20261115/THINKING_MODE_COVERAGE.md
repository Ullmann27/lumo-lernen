# Denkprofil und Knobel-Test: Abdeckung und Ausführungsnachweis

Stand: 15.11.2026. Chat 2, Arbeitszweig `feature/lumo-nextgen-learning-20261115`.
Dieser Nachtrag betrifft die beiden bereits vorhandenen Testmodi. Er ist keine
psychometrische Normierung und keine externe didaktische Abnahme.

## Erhaltener Bestand und Ablauf

| Modus | Bestand und Einstieg | Eingabe und Auswertung | Hilfe während des Tests | Abschluss und Speicherung |
| --- | --- | --- | --- | --- |
| Denkprofil | Bestehende Tests-Seite; 5 Denkbereiche mit je 10 Fragen; 50 Fragen je Klasse 1–4. Nummern-, Formen-, Rechen-, Wort-, Richtungs- und Merkaufgaben bleiben erhalten. | Eine der vier sichtbaren Antworten auswählen und Weiter. Generation prüft alle Fragen vor Ausgabe; der Scorer verlangt 50 bestätigte gültige Antworten und eindeutige Fragekennungen. Alte Weiter-Callbacks werden nach dem Wechsel verworfen. | Auftrag wiederholen, langsamer vorlesen, Stopp und ruhiger Modus. Keine Lösungen, Antwortlisten oder inhaltlichen Erklärungsschritte im Exam-Kontext. Merkstimuli werden durch die Wiederholung des Auftrags nicht erneut gezeigt. | Tatsächliche Bereichsergebnisse und Rückblick mit gegebener Antwort, Lösung und Erklärung. Ergebnis-ID bleibt bei Speicherwiederholung identisch. Ergebnis- und Versuchsspeicherung müssen erfolgreich sein, bevor der Abschluss gezeigt wird. |
| Knobel-Test / bisheriger IQ-Modus | Bestehende Tests-Seite; 6 Bereiche: Matrizen, Figurenreihen, Andersling, Drehen, Zahlenreihen und Merk-Blitz. Normalrunde 24, Entdeckerrunde 36 Aufgaben. | Auswahlkarten oder Reihenfolge im Merkfeld. Jede Variante wird vor Anzeige mit ihrer bestehenden Regel geprüft. Schwierigkeit 1–8 ändert sich nur anhand bestätigter richtiger/falscher Eingaben. Unvollständige und veraltete Eingaben verändern weder Ergebnis noch Schwierigkeit. | Derselbe eingeschränkte Exam-Anschluss. Das bestehende einmalige „Nochmal zeigen“ beim Merk-Blitz bleibt als explizite Spielregel erhalten; allgemeines „Auftrag wiederholen“ spielt den Stimulus nicht ab. | Bestehende Denkpunkte, Bereichsübersicht, Erklärungen und Vergleich nur kompatibler Ergebnisse. Kein normierter IQ, keine Diagnose. Speicherung lässt sich mit derselben Ergebnis-ID wiederholen; tägliche Stern-/XP-Regel und 24/36-Formate bleiben erhalten. |

## Geprüfte Regeln und Zustandsgrenzen

- `CognitiveProfileGenerator.problems` prüft alle 200 vorhandenen Fragen aus
  vier Klassen. Zahlen und Mengen werden aus der Aufgabenbeschreibung
  nachgerechnet; Richtungen und Merkantworten aus sichtbaren bzw. zuvor
  gezeigten Daten abgeleitet. Wortanalogien sind an den bestehenden endlichen
  Wortkatalog gebunden. Ein Gegenversuch ersetzt bei jeder Frage die als richtig
  gespeicherte Antwort; keine dieser Mutationen darf die Prüfung passieren.
- `IqPuzzleQuality.problems` prüft die jeweils deklarierte Regelfamilie:
  Matrixzeilen/-spalten, Figurenmerkmale, genau einen Andersling, direkte
  Rotation zusammenhängender Teile, die vorhandenen Zahlenfolgenregeln sowie
  gültige, eindeutige Merkfelder. Der bestehende Generator-Sweep umfasst
  120 Seeds × 6 Bereiche × 8 Schwierigkeitsstufen = **5.760 Varianten**. Dies ist
  eine reproduzierbare Stichprobe des Generators, keine Behauptung einer
  vollständigen Prüfung aller zufälligen Seeds oder aller denkbaren Folgenregeln.
- `ExamSessionOwner` bindet einen Versuch vor asynchronen Aufrufen an das
  vorhandene Kind, seine Klasse und die Profilgeneration. Profilwechsel beendet
  die Eingabe und verhindert, dass ein altes Ergebnis oder eine alte Belohnung
  dem neuen Profil zugeordnet wird.
- Beide Repositories serialisieren Lese-/Änderungs-/Schreibvorgänge je
  bestehendem Speicherschlüssel. Gleichzeitiges Speichern verliert keine
  Ergebnisse; dieselbe ID ersetzt denselben Eintrag. Die bestehende Grenze von
  zwölf historischen Ergebnissen bleibt erhalten. Ungültige vorhandene JSON-
  Historien werden beim Schreiben nicht still überschrieben.
- Hintergrundwechsel pausiert die verbleibende Sichtzeit des Denkprofil-
  Stimulus und die noch ausstehenden Merk-Blitz-Ereignisse. Bei Rückkehr geht es
  an genau dieser Stelle weiter. Frühere Felder werden dabei nicht erneut
  abgespielt. Eine neue dauerhafte Speicherung **angefangener** Tests über einen
  Prozessabbruch hinweg wurde nicht eingeführt; das vorhandene bestätigte
  Beenden verwirft den unvollständigen Versuch weiterhin. Abgeschlossene
  Ergebnisse bleiben im bisherigen Format gespeichert.

## Bedienung und LUMO

- `ExamCompanionScope` veröffentlicht ausschließlich den sichtbaren Auftrag,
  eine neutrale Bedienanweisung und das Ziel `thinking-question` am kanonischen
  Bus. Explizit erlaubte Aktionen: `repeat`, `slower`, `stop`. Inhaltliche
  Hinweise und Antwortvorschläge bleiben im Exam-Modus gesperrt.
- Der dafür benötigte gemeinsame Busstand stammt unverändert aus Main-Commit
  `3eff952bd3aa4184b5e3508d790de37882c27937`; Provenienz steht in
  `evidence/shared_api_source.json`. Dieser Teilauftrag hat den Bus nicht geändert.
- Auftrags-, Langsamer-, Stopp- und Ruhig-Tasten sind mindestens 48 dp hoch.
  Das Merkfeld behält auch in einem 180 × 180-Testcontainer mindestens
  48 × 48 dp je Feld; zu kleiner Platz wird scrollbar. Ein Doppeltipp auf
  dasselbe Feld erzeugt keine zweite Eingabe.
- IQ-Farben tragen zusätzlich sichtbare Farbnamen. Die Links-Drehung im
  Denkprofil zeigt einen tatsächlichen Links-Pfeil. Die bestehende Gestaltung
  wurde beibehalten; keine Figur- oder Sprachimplementierung wurde ersetzt.

## Tatsächlich ausgeführte Prüfungen

**112 Tests bestanden, Exit 0.** Vollständiges Protokoll:
`evidence/thinking_complete_tests.log`. Darin enthalten sind Bestandstests,
Lehrkraftanzeige, Generator-Sweeps, bestehende vollständige 24-Aufgaben-UI-Runde,
Geräte-/Schriftgrößenprüfungen sowie die neuen Qualitäts- und Ablaufregressionen.

```sh
FLUTTER_SUPPRESS_ANALYTICS=true flock --close \
  /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock \
  /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test \
  --no-pub --reporter expanded \
  test/cognitive_profile_test.dart \
  test/cognitive_profile_premium_ui_test.dart \
  test/features/teacher_cognitive_profile_test.dart \
  test/iq/iq_puzzle_generator_test.dart \
  test/iq/iq_extended_adventure_test.dart \
  test/iq/iq_test_screen_test.dart \
  test/iq/nextgen_thinking_quality_test.dart \
  test/iq/nextgen_thinking_flow_test.dart
```

Die neue Flow-Datei enthält acht tatsächlich ausgeführte Widgettests: alle
50 Denkprofilfragen mit echtem Antippen und Scrollen; fehlgeschlagenes Speichern
mit Wiederholung; alte IQ-Callbacks und Profilwechsel; Ende einer 36er-Runde mit
einmaliger Belohnung; echter Exam-Bus; Links-Drehung; beide Hintergrund-
Fortsetzungen; kleine Merkfelder mit Mehrfachtipps. Beim 36er-Abschlusstest werden
die ersten 35 Antworten auf Sessionebene vorbereitet und die letzte Merkaufgabe
über die Oberfläche gelöst. Er belegt den Abschluss-/Speicherpfad, nicht
36 einzeln manuell oder per UI gelöste Fragen.

Gezielte statische Analyse aller veränderten Denkmodusdateien und beiden neuen
Testdateien: **No issues found**, `evidence/thinking_analysis.log`.

## Geänderte Quelldateien dieses Nachtrags

- `lib/core/cognitive_profile_generator.dart`
- `lib/core/cognitive_profile_scorer.dart`
- `lib/core/cognitive_profile_repository.dart`
- `lib/core/iq/iq_puzzle_generator.dart`
- `lib/core/iq/iq_puzzle_quality.dart` (neu)
- `lib/core/iq/iq_test_session.dart`
- `lib/core/iq/iq_test_repository.dart`
- `lib/core/iq/test_history_queue.dart` (neu)
- `lib/core/iq/exam_session_owner.dart` (neu)
- `lib/features/tests/cognitive_profile_screen.dart`
- `lib/features/tests/cognitive_profile_visual_prompt.dart`
- `lib/features/tests/iq_test_screen.dart`
- `lib/features/tests/iq/exam_companion_scope.dart` (neu)
- `lib/features/tests/iq/iq_result_view.dart`
- `lib/features/tests/iq/iq_figure_painter.dart`
- `lib/features/tests/iq/iq_memory.dart`
- `test/iq/nextgen_thinking_quality_test.dart` (neu)
- `test/iq/nextgen_thinking_flow_test.dart` (neu)

Dieser Nachtrag enthält keine Behauptung eigener Geräteaufnahmen oder eines
neuen APK-Builds. Integration, echte Laufzeitaufnahmen und Release-Nachweis liegen
beim koordinierenden Hauptchat.
