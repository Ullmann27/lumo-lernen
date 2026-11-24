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
- [x] Gesamte Ausgangsregression erneut ausführen und sichern.

### 2. Geprüfter Graph und Szenenvertrag
Files: lib/domain/learning_intelligence/{concept_graph,learning_scene_contract,lesson_scene_engine}.dart
- [x] RED: Graph-Zyklen/fehlende Voraussetzungen, tatsächliche Curriculum-Zuordnungen,
  Contract-Roundtrip und unbekannte Versionen, vier verschiedene Darstellungen.
- [x] GREEN: unveränderliche Daten und prüfbare Bedingungen implementieren.
- [x] RED/GREEN: Ergebnis richtig/Prozess falsch, frische Folgeaufgabe, Erraten/Korrektur.
- [x] Tests und Commit.

### 3. Lokale Entscheidungen und dauerhaftes Methodengedächtnis
Files: domain/learning_intelligence/{lumo_intelligence_engine,scene_memory}.dart,
core/{progress_repository,learning_profile_engine}.dart
- [x] RED: gescheiterte Methode -> geeignete Alternative; Denkzeit/Schweigen;
  ursprünglicher Profilbesitzer, Restart, fehlgeschlagener Schreibvorgang, Retry, Versionsschutz.
- [x] GREEN: vorhandenes Journal + additive Szenenbelege; keine zweite Profildatenbank.
- [x] Synthetische Lernverläufe gegen bisherigen Tutor vergleichen; Unterschiede dokumentieren.
- [x] Tests und Commit.

### 4. Echte Oberfläche, Plan und Elternbegründungen
Files: existing LearningContent, place-value workshop, daily planner and parent learning report.
- [x] RED: Nichtverstehen in realer Aufgabe -> Alternative; nur neue Konstruktion UND
  Rückfrage erzeugen selbstständige Evidenz; kein Reward und keine Testhilfe.
- [x] GREEN: originalen Fuchs und Werkstatt verwenden; persistierte nachvollziehbare Gründe.
- [x] Abwechslung/Voraussetzungen/Pausen aus tatsächlichem Profil ableiten.
- [x] Echte Flutter-Aufnahmen phone/Fold/2x Schrift und Widget-/Navigationstests.

### 5. Abschluss des überprüften Kern-Meilensteins
- [x] Vollanalyse + vollständige Flutter-Suite; relevante Speichertests und Szenario-Testbank.
- [x] Ein frischer unabhängiger Review und überprüfte Korrekturen.
- [x] Opus-Contract-Dokumentation mit vollständiger Referenz, Grenzen und JSON-Beispiel.
- [ ] Finalen Commit ohne skip-ci pushen, Draft-PR; tatsächliche GitHub-Prüfungen auswerten.
- [ ] STATUS/CONTINUE mit SHA, Tests, Screenshots, Release-Stand und offenen Missionen sichern.
