# CLAUDE.md – Build-Schutzregeln fuer Lumo Lernen

Diese Regeln sind verbindlich, wenn Claude an diesem Repository arbeitet.

## Wichtigste Übergabe-Datei

Claude Code muss zuerst diese Projektübergabe lesen:

```text
docs/CLAUDE_CODE_HANDOVER_AND_NEXT_STEPS.md
```

Dort steht konkret:

- was zuletzt gemacht wurde,
- welche Dateien relevant sind,
- welche Fehler Heinz in der App gesehen hat,
- welche Aufgaben als nächstes abzuarbeiten sind,
- welche Designrichtung gewünscht ist,
- welche Build- und Sicherheitsregeln gelten.

## Ziel

Der Android-Build muss zuerst gruen sein. Wenn GitHub Actions oder `flutter build apk --debug` rot ist, sind nur kleine Reparatur-Commits erlaubt.

## Aktueller Zustand

Die App ist eine Flutter-/Android-first Kinderlern-App mit stabiler Lumo-Shell, Lernmodus, Übungen, Tests, aktivem Lesen, Writing-Canvas, Elternbereich, Rewards, Tagesplan, ParentReport und Update-Service. Mehrere Features wurden zuletzt eingebaut. Deshalb gilt: erst Stabilität, dann Aufgabenqualität, dann Designausbau.

## Claude darf NICHT mehr

1. Keine grossen Komplettumbauten auf `main`.
2. Keine neuen Pakete in `pubspec.yaml`, solange der APK-Build rot ist.
3. ML Kit nicht wieder aktivieren, bis der Build gruen ist.
4. Keine Imports auf Pakete lassen, die in `pubspec.yaml` nicht aktiv sind.
5. Keine Bilder als Base64 in Dart-Dateien einbauen.
6. Keine Pflicht-Fonts in `pubspec.yaml` eintragen, wenn die Font-Dateien nicht im Repo liegen.
7. Keine Shell-Struktur zerstoeren.
8. Keine neuen Hauptseiten, die linke Navigation oder rechte Lumo-Buehne ersetzen.
9. Keine Standard-Flutter-Optik als Ersatz fuer das Lumo-Design.
10. Keine halb kopierten oder syntaktisch unvollstaendigen Dart-Dateien committen.
11. Keine geschuetzten Schulbuchseiten oder Verlaglayouts 1:1 kopieren.
12. Keine Designarbeit fortsetzen, wenn der Build rot ist.

## Shell-Regel

Die Lumo-App bleibt immer in dieser Struktur:

- linke Navigation sichtbar,
- mittlerer Inhalt wechselt,
- rechte Lumo-Buehne sichtbar,
- auf normalen Handys responsive mobile Shell.

Nur die mittlere Content-Zone darf sich je Bereich aendern.

## Build-Regel

Vor jedem Commit pruefen:

- Sind alle Imports vorhanden?
- Gibt es keine Imports auf entfernte Pakete?
- Stimmen alle Widget-Konstruktoren?
- Wenn ein Widget mit `key:` genutzt wird, hat es `super.key`?
- Sind alle Asset-Pfade vorhanden?
- Ist `pubspec.yaml` gueltig?
- Gibt es keine falschen Enum-Werte oder Theme-Tokens?

## Arbeitsreihenfolge ab jetzt

1. Erst Compile-Fehler reparieren.
2. Dann Android-Build reparieren.
3. Dann Aufgabenqualität Deutsch/Rechtschreibung prüfen.
4. Dann Writing-Canvas und Schreibziel synchronisieren.
5. Dann Wiederholungslogik verbessern.
6. Dann Overflow/Layout-Fehler reparieren.
7. Erst danach Design weiter verbessern.
8. Erst danach OCR/ML Kit wieder aktivieren.

## Aktuelle Schwerpunktdateien

```text
lib/core/school_exercise_generator.dart
lib/features/learning/adapters/legacy_lumo_task_adapter.dart
lib/features/learning/learning_content.dart
lib/features/learning/renderers/adaptive_task_renderer.dart
lib/features/learning/renderers/writing_task_renderer.dart
lib/features/learning/widgets/lumo_writing_canvas.dart
lib/domain/writing/expanded_writing_template_repository.dart
lib/app/app_shell.dart
lib/app/app_state.dart
lib/app/app_theme.dart
```

## Commit-Regel

Ein Commit darf nur eine klare Sache reparieren oder verbessern. Wenn GitHub Actions rot ist, darf Claude keine neuen Features bauen, sondern muss zuerst den ersten Buildfehler reparieren.

## Antwort-Regel

Wenn Claude Heinz vor eine Entscheidung stellt, immer das `AskUserQuestion`-Tool nutzen und 2-4 klar formulierte, anklickbare Optionen vorbereiten. Keine offenen Fragen mehr ohne Auswahl ("Was möchtest du?", "Welcher Hebel?"). Heinz tippt nicht gerne lange Antworten - er klickt.
