# Direkte Übergabe an Opus 5.5 – 7. Oktober 2026

Heinz hat ausdrücklich beauftragt, zuerst konkrete Fehler zu beheben und eine
geprüfte APK bereitzustellen. Anschließend soll Opus 5.5 die grafische, spielerische
und akustische Weiterentwicklung autonom übernehmen.

**Lies jetzt `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` vollständig.** Dieser vollständige
Nutzerauftrag enthält die neue menschlich klingende Cartoon-Lumo-Stimme,
modernere Musik, App-Animationen, korrekte Lumo-Figur im Kart und ein vollständiges
Rennerlebnis mit Intro, Einfahrt, Kamerafahrt und Zieleinlauf.

**Abschließende Nachweise:** [Reparaturbericht](docs/REPARATURBERICHT_2026-10-07.md)
und [Originalergebnisse der sechs Android-Prüffälle](docs/REPAIR_RESULTS_2026-10-07.json).

## Aktueller Reparaturstand

- Arbeitsbranch in beiden Repositories: `chatgpt/repair-opus-handoff-2026-10-07`.
- Ausgangsbasis App: `99b2afc3362add6b69db6956a692cfcda9de4cc1` (PR 212).
- Ausgangsbasis Godot: `b79ec387da593f97d078bd02c7629b1316f3ebd0` (PR 25).
- Erstellte APK: `0.10.10+1602`, gleiche Preview-Paketkennung und bestehende Signatur.
- App-Quellstand der APK: `1f9ab5a8fc0d7b5a8fbf2d0b8a35a92d7f8cdf9b`.
- Eingebetteter Godot-Stand: `9ade252e67309d18b17d3226e33b0034b91f3495`.
- APK-SHA-256: `82865962c7c00413c75bfc2e427a201bb957ab564d8c8eb944f2b798dfbf1511`.
- Die abschließende Übergabe ergänzt Dokumentation, Prüfwerkzeug und begrenzte
  Wartezeiten für die CI-Vorbereitung. App, Assets und nativer Quellstand der
  ausgelieferten APK bleiben unverändert; maßgeblich ist der obige Commit.
- Version 1602 liegt über den vorherigen parallelen Kandidaten 1504 und 1601.
- Die zwischenzeitlich auseinander gelaufenen App-/Kart-Zweige sind inhaltlich
  zusammengeführt: Startseitenbilder, vollständige Begrüßung, blaue Lernkacheln
  und separate Hilfsleiste aus App 1601 bleiben neben der neuen Kart-Vorschau
  und den neueren nativen Welten erhalten. Die Hilfsleiste überdeckt keine
  Lernantworten oder Spielbuttons mehr.
- Schmale Fold-Navigation stellt Symbol und vollständige Beschriftung
  untereinander dar, statt „Belohnungen“ in die Nachbarseite zu zeichnen.
- Die Beschriftung deaktivierter Kart-Aktionen bleibt lesbar; leere und tatsächlich
  eingesetzte Items sowie zusätzliche Cover-/Kompaktgrößen werden geprüft.
- Der Android-Test wird mit exakter Quell-/Versions-/Hashprüfung durch alle
  Größenwechsel, Rückkehr und vollständigen Neustart geführt.
- CI: 707 Flutter-Tests bestanden (4 zuvor deaktivierte Tests übersprungen),
  9 Python-Tests und 22 Backend-Tests bestanden. 40.960 erzeugte Lernaufgaben
  geprüft. Android-Prüfwerkzeuge: 177 bestanden, 8 übersprungen.
- Godot: echte Renderings sowie Fold-, Menü- und Fahrphysikregression bestanden.
  Zehn Bildschirmgrößen, leeres/aktiviertes Item, gleichzeitige Drei-Finger-Steuerung,
  Loslassen außerhalb und Pause geprüft. Signierte APK und eingebettetes Paket
  geprüft; heruntergeladene Datei zusätzlich per Hash und ZIP-Integrität abgeglichen.
- Die statische App-Analyse enthält keine Fehler, aber weiterhin 20 Warnungen und
  130 Hinweise. Diese sind durch die Reparatur nicht als erledigt ausgewiesen.
- Online-KI am 7. Oktober geprüft: `/health` erreichbar; echte synthetische
  Mathe-Anfrage erhält HTTP 503 mit `openai_quota_exceeded`. Kein Quellcode-Fix
  kann das Provider-Kontingent auffüllen. Offline-Lernhilfe weiterhin prüfen.
- Android 15: Update von Version 1400 mit Profilerhalt sowie Bauwelt, Puzzle,
  Rhythm Party, Schatzsuche und Kart bestanden. Kart umfasst die innere/äußere
  Fold-Fläche, 640 × 320 Pixel, Rückkehr und vollständigen Neustart.
- Android 16: Update von 1601 und Kart-Start bestanden. Der erste Größenwechsel-
  Test erwartete fälschlich, dass die Bildschirmvergrößerung das Gerät dreht.
  Der korrigierte Test dreht den Emulator ausdrücklich und behält die strikten
  Größen-/Tastenprüfungen bei. Die vollständige Wiederholung ist **bestanden**:
  Update/Profilerhalt, Offline-Start, fünf Einrichtungsschritte, 1920 × 1080,
  2176 × 1812, Cover, 640 × 320, Rückkehr, Neustart und leerer Crash-Puffer.
- Ursprünglicher [Workflow 37674457852](https://github.com/Ullmann27/lumo-lernen/actions/runs/37674457852)
  und ergänzender [Workflow 37678448599](https://github.com/Ullmann27/lumo-lernen/actions/runs/37678448599).
  Die Ergänzung prüft die unveränderte APK; ihre Prüfwerkzeug-Revision lautet
  `4e46b95db1090f061dec308db7cf0ae6e4d2cb7e`.
- Der abschließende [Android-16-Lauf 37681087799](https://github.com/Ullmann27/lumo-lernen/actions/runs/37681087799)
  verwendet die Prüfwerkzeug-Revision `9bcd223e2ddab8d60e79972f49e323c4b0fa9023`.
  Nach zwei aufgezeichneten doppelten Hardware-Texteingaben in der alten Version
  1601 werden sichtbare Bildschirmtastatur-Tasten anhand frischer UI-Daten
  angetippt. Der exakte Profilname wird weiterhin Buchstabe für Buchstabe geprüft.
  Auch die ursprünglichen Fehlversuche sind im Prüfbericht dokumentiert.

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
