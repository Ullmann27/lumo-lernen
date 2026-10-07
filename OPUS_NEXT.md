# Direkte Übergabe an Opus 5.5 – 7. Oktober 2026

Heinz hat ausdrücklich beauftragt, zuerst konkrete Fehler zu beheben und eine
geprüfte APK bereitzustellen. Anschließend soll Opus 5.5 die grafische, spielerische
und akustische Weiterentwicklung autonom übernehmen.

**Lies jetzt `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` vollständig.** Dieser vollständige
Nutzerauftrag enthält die neue menschlich klingende Cartoon-Lumo-Stimme,
modernere Musik, App-Animationen, korrekte Lumo-Figur im Kart und ein vollständiges
Rennerlebnis mit Intro, Einfahrt, Kamerafahrt und Zieleinlauf.

## Aktueller Reparaturstand

- Arbeitsbranch in beiden Repositories: `chatgpt/repair-opus-handoff-2026-10-07`.
- Ausgangsbasis App: `99b2afc3362add6b69db6956a692cfcda9de4cc1` (PR 212).
- Ausgangsbasis Godot: `b79ec387da593f97d078bd02c7629b1316f3ebd0` (PR 25).
- APK-Ziel: `0.10.10+1602`, gleiche Preview-Paketkennung und bestehende Signatur.
- Version 1602 liegt über den vorherigen parallelen Kandidaten 1504 und 1601.
- Die zwischenzeitlich auseinander gelaufenen App-/Kart-Zweige sind inhaltlich
  zusammengeführt: Startseitenbilder, vollständige Begrüßung, blaue Lernkacheln
  und separate Hilfsleiste aus App 1601 bleiben neben der neuen Kart-Vorschau
  und den neueren nativen Welten erhalten. Die Hilfsleiste überdeckt keine
  Lernantworten oder Spielbuttons mehr.
- Die Beschriftung deaktivierter Kart-Aktionen bleibt lesbar; leere und tatsächlich
  eingesetzte Items sowie zusätzliche Cover-/Kompaktgrößen werden geprüft.
- Der Android-Test wird mit exakter Quell-/Versions-/Hashprüfung durch alle
  Größenwechsel, Rückkehr und vollständigen Neustart geführt.
- Lokaler Godot-Test: zehn Bildschirmgrößen, leeres/aktiviertes Item, gleichzeitige
  Drei-Finger-Steuerung, Loslassen außerhalb und Pause bestanden. Python-Prüfungen
  zur Android-Vorbereitung: 5 bestanden. Backend-Tests: 22 bestanden.
- Online-KI am 7. Oktober geprüft: `/health` erreichbar; echte synthetische
  Mathe-Anfrage erhält HTTP 503 mit `openai_quota_exceeded`. Kein Quellcode-Fix
  kann das Provider-Kontingent auffüllen. Offline-Lernhilfe weiterhin prüfen.
- Weitere Prüfergebnisse sind bis zum Abschluss des Workflows **offen**. Vor einer
  Erfolgsaussage den aktuellen Workflow und seine Ergebnisdateien lesen.

## Für die nächste Etappe

1. Den finalen Prüfbericht dieser Reparatur und den eingetragenen Godot-Pin lesen.
2. Arbeit auf diesen Quellständen fortsetzen; ältere HTML-Prototypen nicht als
   aktuelle App behandeln. Keine fremden lokalen Änderungen überschreiben.
3. App-Gestaltung und Stimme verbessern, anschließend Kart-Figur und komplette
   Renninszenierung gemäß dem vollständigen Auftrag umsetzen.
4. Nach wesentlichen visuellen Änderungen echte Screenshots zeigen. Stimme,
   Musik und Animation mit tatsächlichen Ton-/Videoaufnahmen belegen.
5. Verfügbare Geräte-/Emulatornachweise klar unterscheiden. Physische Fold-
   Messung und 60 FPS sind bisher nicht bestätigt.

Die große Neuentwicklung des eigenständig agierenden KI-Assistenten folgt später.
Die menschlich klingende Lumo-Stimme ist bereits Teil des jetzigen Folgeauftrags.
Im Kart-Rennen gibt es keine Lernfragen oder Lernantworten für Turbo.

Diese Übergabe liegt absichtlich im Repository und ist über `CLAUDE.md` und
`CODEX_START.md` sichtbar. Sie startet keine andere Sitzung automatisch.
