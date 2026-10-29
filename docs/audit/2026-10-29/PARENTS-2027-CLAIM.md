# Arbeitsclaim · Elternbereich 2027

- Agentenprofil: Claude Opus 5.5 – Lumo 2027 Elternbereich
- Repository: Ullmann27/lumo-lernen
- Branch: `claude/lumo-2027-parents-20261029`
- Basis: `origin/release/lumo-2003-family-button-20261029` @ `5457b2ee1615c693009cf17e7b3dc2d1e5e88ac0` (0.12.91+2003)
- Auftrag (Heinz, 29.10.2026): „Der Elternbereich muss schöner und klarer werden.
  Besonders der obere Bereich wirkt aktuell zu verwurschtelt.“

## Beanspruchte Pfade (nur Darstellung)

- `lib/features/settings/settings_content.dart` – Reihenfolge, Gruppierung, Kopfbereich,
  Abschnitte, Karten, Abstände, Icons, zweispaltiges Layout am offenen Fold.
- neu: `lib/features/settings/parent_area/` – Darstellungsbausteine des Elternbereichs
  (Kopf mit Kindprofil und echtem Lernstand, Abschnittskopf, Karten-Rahmen).
- nur bei Bedarf, ausschließlich Optik/Abstände ohne Logikänderung:
  `lib/features/settings/parent_report_card.dart`,
  `lib/features/settings/legacy_learning_data_card.dart`,
  `lib/features/settings/writing_report_card.dart`,
  `lib/features/settings/discovery_settings_card.dart`,
  `lib/features/settings/lumo_voice_diagnostics_card.dart`.
- neu: `test/features/settings/parent_area_layout_test.dart` (Struktur, Ziele ≥ 48 dp,
  kein Überlauf bei Schriftgröße 2.0 auf 344 dp, alle Aktionen erreichbar).
- neu: `test/design/parents_2027_capture_test.dart` (Vorher-/Nachher-Aufnahmen,
  PNG-Schreiben nur mit `LUMO_PARENTS_2027_CAPTURES`).
- `docs/visual/2026-10-29-2027/parents/` (Aufnahmen und `HANDOFF.md`).
- dieser Claim.

## Grund und Abnahmetests

Der Kopf des Elternbereichs mischt Update-Hinweise, Paketnamen-Erklärung,
Klassenwahl, Lehrerbereich, Altdatenzuordnung und Profil-Löschen ohne klare
Hierarchie. Ziel: ruhiger Kopf mit Kindprofil, Klasse und echter Lernstand-
Zusammenfassung, klar getrennte Abschnitte („Lernstand“, „Heute & Plan“,
„Sicherheit & Konto“, „Updates & App“, „Einstellungen“), einheitliche Karten,
Lumo-DNA, zwei Spalten am offenen Fold, 2.0-Schrift sicher.

Abnahme:
- `flutter analyze` ohne Fehler; keine neuen Hinweise in geänderten Dateien.
- Bestehende Tests grün: `test/daily_mission_parent_settings_test.dart`,
  `test/design/parent_games_polish_test.dart`, `test/lumo_voice_settings_capture_test.dart`,
  `test/design/lumo_sulafat_controls_capture_test.dart`,
  `test/design/legacy_learning_assignment_test.dart`,
  `test/design/guided_learning_runtime_capture_test.dart`,
  `test/state_persistence_regression_test.dart` sowie Navigationstests in den Elternbereich.
- Neue Strukturtests grün.
- Alle Texte/Schlüssel, die Tests und die Android-Tour lesen, bleiben erhalten
  („Elternbereich“ als nicht tippbare Überschrift, „Sichere Einstellungen“,
  „Auf Update prüfen“, `open-teacher-area`, `parent-school-grade-*`,
  `legacy-learning-*`, `discovery-parent-switch`, kein Text mit „PIN“).

## Ausdrücklich ausgeschlossen

- Lernlogik und Sols Dateien: `lib/core/tutor_coordination_engine.dart`,
  `lib/core/lumo_companion_requests.dart`, `lib/app/app_state.dart` (Logik),
  `lib/features/learning/**`, `lib/domain/**`, Tagesplaner, Journal, Schreibtrainer.
- Update- und Release-Logik: `lib/core/app_update_service.dart`, `.github/workflows/**`,
  `pubspec.yaml` (Version/Pakete), `config/godot-source.json`.
- Erzeugung der Eltern-Erklärungen: `lib/features/parents/**`,
  `ParentReportEngine`, `LumoTutorEvidenceCard`-Inhalte.
- Routing/Eintritt: `lib/app/app_shell.dart` (unverändert).
- Die Karte „Schularbeit eintragen“ (Schularbeits-Planer eines anderen Agenten) wird
  weder gebaut noch als leerer Platzhalter angelegt.
