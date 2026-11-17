# Lumo Tutor Brain Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans; implementation in this session, fresh whole-branch reviewer at completion.

**Goal:** echte Lernereignisse, respektvolle Hilfe und selbstständige Transferprüfung verbinden.
**Architecture:** CompanionRequests + pure TutorCoordinationEngine; bestehendes profilgetrenntes LearningJourney als Persistenz.
**Tech Stack:** Flutter 3.44.9, Dart 3.12, vorhandene Offline-Dienste.
**Spec:** docs/superpowers/specs/2026-10-28-tutor-brain-design.md

## Global Constraints
Keine Änderungen an main/2000-Branch, keine neuen Pakete, Original-Lumo,
48dp, Offline, Testsperre, bestehende Lernstände/Schreibtrainer/Journal erhalten.

## Review Focus
- Verzögerte Antworten beim Profilwechsel: nur ursprüngliches Profil speichern.
- Erneute Anzeige abgelehnter Angebote: bis Aufgabenwechsel unterdrücken.
- Nach Hilfe gelöste Aufgabe: niemals selbstständig klassifizieren.
- Wiederholte identische Folgeaufgaben: keine zusätzliche Transferevidenz.
- Ungültige/neue gespeicherte Formate: erhalten und Speicherfehler sichtbar machen.

### Task 1: Ereignissteuerung und echte Aufgabenanschlüsse
Files: core/tutor_coordination_engine.dart, widgets/fox/lumo_companion_requests.dart,
features/learning/learning_content.dart, app/app_state.dart; tests under test/tutoring/.
Interfaces: scoped task/answer/help events, LearningEvidence from actual answers.
- [ ] RED: consent, sticky assistance, exam lock, generation isolation, deduplication.
- [ ] GREEN: central local state machine; existing TaskHint/TutorEngine/ErrorDetective/VisualAid paths consume explicit requests.
- [ ] Persist evidence through existing profile leases; retry failures without duplication.
- [ ] Run targeted tests, commit and push.

### Task 2: Aktive Werkstatt mit Transfer
Files: features/learning/widgets/lumo_place_value_workshop.dart and reusable visual components.
Interfaces: onTransferChecked result -> central engine -> LearningJourney, no rewards.
- [ ] RED: counting alone emits nothing; bundle ten loose cubes; different target;
  composition plus comprehension; first-attempt independence; 280/360/880dp and 2x text.
- [ ] GREEN: implement stages and original Lumo reactions; all actions >=48dp.
- [ ] Run widget/integration tests, commit and push.

### Task 3: Evidenzbasierter Tagesplan und Klassenanschlüsse
Files: core/lumo_personal_daily_tutor_planner.dart, home widgets, AppState,
features/learning_modules/learning_module_progress.dart; audit report.
Interfaces: LearningJourney records plus actual grade curriculum -> three daily steps.
- [ ] RED: unknown/review/assisted/independent/retained; one mistake not weakness;
  exact active profile; grade filter; existing exercise navigation.
- [ ] GREEN: reuse existing profile engine and curriculum; display reasons/durations.
- [ ] Inspect all grade/module routes; connect shared evidence boundary without touching writing/journal internals.
- [ ] Run targeted tests; commit and push.

### Task 4: Gesamtprüfung, visuelle Belege, Haupt-App-Kandidat
- [ ] Full Flutter tests + analysis; inspect failures and fix causes.
- [ ] Capture and inspect actual Flutter renders, phone/Fold/large text.
- [ ] Fresh whole-branch review and verify material fixes.
- [ ] Increment to 0.12.89+2001, preserve signing/package/pin policy.
- [ ] Draft PR, full Android build attempt, exact-source in-place upgrade and release gates.
- [ ] Publish only when gates pass; otherwise durable reproducible handoff with exact blockers.
