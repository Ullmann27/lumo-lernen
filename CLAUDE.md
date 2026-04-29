# CLAUDE.md – Build-Schutzregeln fuer Lumo Lernen

Diese Regeln sind verbindlich, wenn Claude an diesem Repository arbeitet.

## Ziel

Der Android-Build muss zuerst wieder gruen werden. Bis dahin sind nur kleine Reparatur-Commits erlaubt.

## Aktueller Zustand

Der Build ist nach UI- und Feature-Aenderungen fehlgeschlagen. Deshalb gilt jetzt Stabilitaet vor neuen Features.

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

## Shell-Regel

Die Lumo-App bleibt immer in dieser Struktur:

- linke Navigation sichtbar
- mittlerer Inhalt wechselt
- rechte Lumo-Buehne sichtbar

Nur die mittlere Content-Zone darf sich je Bereich aendern.

## Build-Regel

Vor jedem Commit pruefen:

- Sind alle Imports vorhanden?
- Gibt es keine Imports auf entfernte Pakete?
- Stimmen alle Widget-Konstruktoren?
- Wenn ein Widget mit `key:` genutzt wird, hat es `super.key`?
- Sind alle Asset-Pfade vorhanden?
- Ist `pubspec.yaml` gueltig?

## Arbeitsreihenfolge ab jetzt

1. Erst Compile-Fehler reparieren.
2. Dann Android-Build reparieren.
3. Dann Overflow/Layout-Fehler reparieren.
4. Erst danach Design weiter verbessern.
5. Erst danach OCR wieder aktivieren.

## Commit-Regel

Ein Commit darf nur eine klare Sache reparieren. Wenn GitHub Actions rot ist, darf Claude keine neuen Features bauen, sondern muss zuerst den ersten Buildfehler reparieren.
