# Lumo Lernatelier Implementation Plan

> **For agentic workers:** Execute the integration inline; isolated, nonoverlapping storage, narration and board tasks may run in parallel as permitted by the repository's development instructions. Use test-driven-development and verification-before-completion.

**Goal:** Spielbare, nachvollziehbar adaptive Lernaufgaben mit hochwertiger räumlicher Darstellung in die vorhandene App integrieren.
**Architecture:** Lokaler geprüfter Katalog, kontrollierte Manipulativ-Widgets, gemeinsame sitzungsgebundene Aufgabe mit bestehender Speichergrenze; additive Lernbelege im vorhandenen Profilrepository.
**Tech Stack:** Flutter 3.44.9, Dart, CustomPainter, vorhandene SharedPreferences/Voice/Originalgrafiken; keine neuen Pakete.
**Spec:** `docs/superpowers/specs/2026-10-18-learning-lab-design.md`

## Global Constraints

- Keine Änderungen an Lumo Kart oder dessen Quellpin; kein Main-Merge oder Release.
- Bestehende Profile, Schul-/Entdeckungsfortschritte, Journal, Schreiben und Belohnungen bleiben erhalten.
- Unterstützte Antworten sind kein selbstständiger Beherrschungsnachweis.
- Mindestens 48dp große neue Touchflächen; System-/App-Animationseinstellung beachten.
- Nur tatsächlich ausgeführte Tests, Aufnahmen und APK-Ergebnisse berichten.

## Review Focus

- Profilwechsel während ausstehender Speicherung: ursprünglicher Besitzer bleibt gebunden.
- Speicherfehler vor/nach Mutation: Retry darf weder Antwort verdoppeln noch Beleg verlieren.
- Wiederholung derselben Zahlen: neue Versuch-ID erzeugt keine neue Problemidentität.
- Große Schrift und schmales Display: Eingabe und Hilfe bleiben scrollbar erreichbar.
- Laufende Erklärung plus Antwortfeedback: keine Unterbrechung oder spätere Wiederaufnahme alter Sprache.

### Task 1: Lokale Kompetenzbelege

Files: `lib/core/learning_journey.dart`, `progress_repository.dart`, `learning_profile_engine.dart`, zugehörige Tests.
Interface: `LearningEvidence(taskId,problemId,correct,helpLevel,transferCheck,errorTag)`; Engine `loadJourney`, `journey`, `recordJourneyEvidence`, `flushJourney`.
- [ ] Speicherung/Retry/Profilisolierung und selbstständige vs. begleitete Belege zuerst als fehlschlagende Tests schreiben.
- [ ] Strikte additive Speicherung und transparente Wiederholung implementieren; Tests ausführen; gezielt committen.

### Task 2: Überprüfter Aufgabenkatalog

Files: `lib/features/learning/lab/learning_lab_catalog.dart`, `test/learning_lab_catalog_test.dart`.
Interface: `LabTopic`, `LabProblem`, `LabMode`; eindeutige Problemidentitäten, geprüfte erwartete Antworten, Fehlertags, fünf Hilfestufen, Klassenfreigabe.
- [ ] Tests für Mathe/Brüche/Wörter/Englisch/Natur, neue Transferprobleme und unsichere Fehler schreiben und rot ausführen.
- [ ] Lokale Inhalte und deterministische Bewertung implementieren; grün ausführen.

### Task 3: Manipulative Arbeitsflächen

Files: `learning_manipulatives.dart`, neue `lab_`-Helfer, `test/learning_lab_manipulatives_test.dart`.
Interface: `QuantityBridgeBoard(start,addend,moved,onChanged,enabled,reveal,reduceMotion)`, `FractionBuildBoard(denominator,selected,onChanged,enabled,reduceMotion)`, `LearningTokenWorkbench(tokens,selected,onChanged,enabled,reduceMotion)`.
- [ ] Echte Interaktion, Auswahlreihenfolge, Undo, schmale/große Layouts rot prüfen.
- [ ] Plastische interaktive Objekte umsetzen und grün prüfen.

### Task 4: Narration

Files: `lib/core/lumo_learning_narration.dart`, `test/learning_speech*.dart`, Sprachnachweis.
Interface: `read`, `feedback`, `repeat`, `pause`, `stop`, `dispose`; Zustand `currentText`, `isPaused`, `isActive`.
- [ ] Rennen zwischen expliziter Erklärung, automatischem Feedback, Pause und Dispose rot prüfen.
- [ ] Bestehende zentrale Stimme sitzungsgebunden anbinden und grün prüfen.

### Task 5: Tutor-Sitzung und Speicheranschluss

Files: `learning_lab_screen.dart`, `learning_lab_stage.dart`, `learning_module_progress.dart`, Laufzeittests.
Consumes Tasks 1–4. New observation path stores accompanied evidence without school counters; independent answers use existing answer path plus evidence, both retry safe.
- [ ] Tatsächliche Runde Beispiel→Bauen→freier Abruf→Transfer, Fehlerhilfe, Retry und Profilwechsel rot prüfen.
- [ ] Adaptiven Hilfefluss, Original-Lumo, Sprachknöpfe und konkreten Rückblick implementieren.
- [ ] Layoutmatrix und echte Eingaben grün prüfen; fokussiert committen.

### Task 6: Lernkarte und Erreichbarkeit

Files: `learning_lab_hub.dart`, bestehende Home-/Akademie-/Nachhilfe-Einstiege, Tests.
- [ ] Freie Auswahl nur zulässiger Klasse, Gründe aus echten lokalen Belegen und Rückkehr prüfen.
- [ ] Gemeinsamen Einstieg integrieren und Status mit tatsächlichen Belegen anzeigen.

### Task 7: Nachweise und Androidkandidat

Files: eigene Capturetests, Belegverzeichnis, CI für Lernnachweise, Versions-/Paketidentität.
- [ ] Ganze Flutter-Suite, Analyse, Speicher-/Sprach-/Layoutregressionen ausführen.
- [ ] Echte Schriften laden; Original-Renders und Animationsframes aufnehmen, ansehen und Pixelgate ausführen.
- [ ] Unabhängige Gesamtprüfung; notwendige Fehler testgestützt beheben.
- [ ] Kleine Commits und eigenen PR sichern; Androidpipeline ausführen, tatsächliches Ergebnis dokumentieren und separate APK nur bei erfolgreichem Bau ausgeben.
