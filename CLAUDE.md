# CLAUDE.md – Regeln für Lumo Lernen

Zuerst `OPUS_NEXT.md` lesen: aktuelle Übergabe und Heinz' direkter Auftrag an Opus 5.5.
Danach `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` vollständig lesen und an diesem Auftrag
weiterarbeiten. `CODEX_START.md` enthält die Code-Landkarte und ältere Grundlagen.

## Ziel
Die App sieht genau aus wie Heinz' Bilder in `docs/design_targets/2026-10-04/`
(Vorgabe: `docs/DESIGN_ZIEL_2026-10-04.md`) und lebt: animierte Leisten, atmender Fuchs,
Begrüßung beim Start. Alle Lern- und Spielfunktionen bleiben erhalten.

## Regeln
1. Build muss grün sein: `flutter analyze` ohne Fehler, `flutter test` ohne Fehlschläge.
   Ist er rot, zuerst den ersten Fehler beheben, keine neuen Features.
2. Kleine Commits, eine Sache pro Commit.
3. Keine neuen Pakete in `pubspec.yaml` ohne Grund; keine Imports auf nicht aktive Pakete.
4. Bilder als Dateien unter `assets/`, nie als Base64 im Code. Neue Asset-Ordner in `pubspec.yaml` eintragen.
5. Echte Daten anzeigen (Sterne, XP, Level, Fortschritt), keine Beispielzahlen aus den Bildern.
6. Kein Force-Push, kein Merge nach `main`, kein Release ohne Heinz.
7. Nur Erfolge melden, die tatsächlich geprüft sind.
8. Toten Code nicht wieder einführen: Jede Datei in `lib/` muss von `lib/main.dart` aus erreichbar sein.
