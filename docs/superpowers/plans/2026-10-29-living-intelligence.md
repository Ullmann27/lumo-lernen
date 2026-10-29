# Living Intelligence Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans, test first and one fresh whole-branch review.

**Goal:** Alternative Lernszene nach erfolgloser Erklärung und sicher gespeicherter Transfer aus echter Folgeaufgabe.
**Architecture:** additive pure Dart domain services plus existing profile leases, LearningJourney and Flutter workshop.
**Tech Stack:** existing Flutter 3.44.9/Dart, SharedPreferences namespace; no new packages or providers.
**Spec:** docs/superpowers/specs/2026-10-29-living-intelligence-design.md

## Global Constraints
Basis 9fdfc3f1 erhalten, eigener Branch, Original-Lumo, offline, keine Diagnosen,
keine Kompetenzmutation aus Animation, Exam-Sperre, 48dp und Reduce Motion.

## Review Focus
- Korrektes Ergebnis mit falscher Zerlegung darf keinen Transfer erzeugen.
- Nach Profilwechsel dürfen alte Rückmeldungen nur ihren ursprünglichen Besitzer erreichen.
- Neues/defektes Dateiformat muss erhalten bleiben; Retry darf keine Evidenz duplizieren.
- Neue Szene darf kein wiederholtes Raten als Kompetenz ausgeben.
- Fehlende Voraussetzungen bleiben Vermutungen; keine erfundene Lehrplanabdeckung.

### 1. Übernahme und bestehende Regressionen
- [x] GitHub/Release/Branch prüfen; vorhandene Test-Deadlock-/Text-Erwartung reparieren.
- [x] Fünf echte Navigations-/Darstellungstests erneut bestanden.
- [ ] Gesamte Ausgangsregression erneut ausführen und sichern.

### 2. Geprüfter Graph und Szenenvertrag
Files: lib/domain/learning_intelligence/{concept_graph,learning_scene_contract,lesson_scene_engine}.dart
- [ ] RED: Graph-Zyklen/fehlende Voraussetzungen, tatsächliche Curriculum-Zuordnungen,
  Contract-Roundtrip und unbekannte Versionen, vier verschiedene Darstellungen.
- [ ] GREEN: unveränderliche Daten und prüfbare Bedingungen implementieren.
- [ ] RED/GREEN: Ergebnis richtig/Prozess falsch, frische Folgeaufgabe, Erraten/Korrektur.
- [ ] Tests und Commit.

### 3. Lokale Entscheidungen und dauerhaftes Methodengedächtnis
Files: domain/learning_intelligence/{lumo_intelligence_engine,scene_memory}.dart,
core/{progress_repository,learning_profile_engine}.dart
- [ ] RED: gescheiterte Methode -> geeignete Alternative; Denkzeit/Schweigen;
  ursprünglicher Profilbesitzer, Restart, fehlgeschlagener Schreibvorgang, Retry, Versionsschutz.
- [ ] GREEN: vorhandenes Journal + additive Szenenbelege; keine zweite Profildatenbank.
- [ ] Synthetische Lernverläufe gegen bisherigen Tutor vergleichen; Unterschiede dokumentieren.
- [ ] Tests und Commit.

### 4. Echte Oberfläche, Plan und Elternbegründungen
Files: existing LearningContent, place-value workshop, daily planner and parent learning report.
- [ ] RED: Nichtverstehen in realer Aufgabe -> Alternative; nur neue Konstruktion UND
  Rückfrage erzeugen selbstständige Evidenz; kein Reward und keine Testhilfe.
- [ ] GREEN: originalen Fuchs und Werkstatt verwenden; persistierte nachvollziehbare Gründe.
- [ ] Abwechslung/Voraussetzungen/Pausen aus tatsächlichem Profil ableiten.
- [ ] Echte Flutter-Aufnahmen phone/Fold/2x Schrift und Widget-/Navigationstests.

### 5. Abschluss des überprüften Kern-Meilensteins
- [ ] Vollanalyse + vollständige Flutter-Suite; relevante Speichertests und Szenario-Testbank.
- [ ] Ein frischer unabhängiger Review und überprüfte Korrekturen.
- [ ] Opus-Contract-Dokumentation mit vollständiger Referenz, Grenzen und JSON-Beispiel.
- [ ] Finalen Commit ohne skip-ci pushen, Draft-PR; tatsächliche GitHub-Prüfungen auswerten.
- [ ] STATUS/CONTINUE mit SHA, Tests, Screenshots, Release-Stand und offenen Missionen sichern.
