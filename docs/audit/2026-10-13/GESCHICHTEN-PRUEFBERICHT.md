# Geschichten: geprüfter Reparaturblock

Produktkandidat: `086eb42ab7b834050f1f345b52cb3e811d816748`, [Draft-PR288](https://github.com/Ullmann27/lumo-lernen/pull/288), Folgebranch auf PR285/d7440be. Geschützter1938-Stand und Godot-Pin unverändert; kein Main-Merge, keine APK, kein Release.

## Tatsächliche Änderungen

- `lib/core/lumo_story_library.dart`: bool-Schreibfehler werden erkannt. Eine gescheiterte neue Story wird nur aus der aktuellen Speicherliste entfernt; vorhandene Hefte und JSON-Metadaten bleiben erhalten. Wiederholen speichert keine zurückgebliebene Fehlkopie.
- `lib/features/story/lumo_story_reader_screen.dart`: Speicherabschluss abwarten, Doppelausführung und Zurück während Speicherung sperren, Fehlermeldung oberhalb des Wiederholen-Buttons. Der unnötige PageController wurde entfernt: Die Seiten werden tatsächlich per Seitenindex/SingleChildScrollView gerendert, ein PageView existiert nicht.
- `lib/features/story/lumo_story_setup_screen.dart`: erfolgreich gespeicherter Reader meldet true. Nur die vorher erfasste Setup-Route wird entfernt, sodass die Bibliothek erreicht und ein unmittelbar geöffneter Schreibcoach erhalten wird. Reader-Abbruch meldet keinen Erfolg und behält Setup.
- Neue Tests: `story_completion_storage_test.dart` und `story_completion_navigation_test.dart`. Bestehende Profilklassen-/Lernpfad-/Filtertests unverändert.

## Prüfprovenienz

| Quell-SHA | Actions | Ergebnis |
|---|---|---|
| `d7440beaba78992ee36c8f4be1513e6b5006c1f6` | [38375803750](https://github.com/Ullmann27/lumo-lernen/actions/runs/38375803750) | Baseline1456PASS/117SKIP,24Infos |
| `c87b896f1e08918b2f798e9152c13dcf6d84ea91` | [38378429384](https://github.com/Ullmann27/lumo-lernen/actions/runs/38378429384) | RED:1456PASS/117SKIP/1FAIL; Erfolgsmeldung bei noch blockiertem Schreiben |
| `6507bbb122d45cebccb4db4d1aa20cabeb720a8a` | [38379564746](https://github.com/Ullmann27/lumo-lernen/actions/runs/38379564746) |1456PASS/117SKIP/1FAIL; neue Test-Rückkehrprüfung wartete fälschlich400ms statt tatsächlicher450ms Android-Animation |
| `ada82abc487d74e7a19f0c35974441ba3b832c67` | [38381280606](https://github.com/Ullmann27/lumo-lernen/actions/runs/38381280606) | RED:1456PASS/117SKIP/2FAIL; echte Mehrseiten-/Bibliothekskette und sichtbarer Retry geprüft; PageController-Ausnahmen, Setup bleibt offen, Snackbar verdeckt Retry |
| `086eb42ab7b834050f1f345b52cb3e811d816748` | [38384915173](https://github.com/Ullmann27/lumo-lernen/actions/runs/38384915173) | **1458PASS/117SKIP/0FAIL**,24Infos, kein Analysefehler |

Die Zwischenläufe38384501477/38384603168 auf6a66d7e wurden durch PR-/Folgetestupdates abgelöst; kein Testergebnis daraus übernommen. Fehler und Fixturekorrekturen bleiben sichtbar. Keine Assertion entfernt, keine alte Prüfung abgeschwächt. Die500ms+Disposalframe entsprechen dem SDK-Rücklauf; echte Schrift-/Icons wurden für Screenshotlesbarkeit geladen.

Toolchain im erfolgreichen letzten Originalprotokoll: Flutter3.44.9, Dart3.12.2. Befehle:

```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2
```

Alle drei Shellschritte erfolgreich (Exit0). Separat aus heruntergeladenem Artefakt geprüfte `outcomes.json`: SOURCE_SHA086eb42…, DEPENDENCIES/ANALYSIS/TESTS jeweils success. Artefakt11804794941, SHA256-Digest `3b06adc2298b57465631b1c30d163633a22c6231d1ffba932c1a84f20e0fa474`.

Die117 übersprungenen Tests und24 Informationshinweise bleiben im Originalprotokoll sichtbar. Keiner dieser Werte wird als APK-/Android-/Gerätefreigabe ausgegeben. Lokaler Flutterlauf war durch automatische Sicherheitsprüfung wegen Metadatenzugriffs blockiert; vorhandener GitHub-Reviewrunner verwendet. Offline-Dartformatierung meldete fehlende lokale Lint-Paketauflösung; die echte CI-Analyse ist davon unabhängig erfolgreich.

## Abgedeckte Fälle

- Langsames Schreiben: keine Erfolgsmeldung und kein Wegnavigieren vor bestätigter Speicherung.
- Mehrfaches Antippen: genau ein Schreibvorgang.
- Speicher-Rückgabe false und geworfene Ausnahme: kein falscher Erfolg; tatsächlich gespeicherter Plattforminhalt/Altbestand bleibt korrekt; anschließende Wiederholung speichert genau einmal.
- Echte Bibliothek → festeKlasse2/Profilklasse4 → Setup → Reader: Abbruch behält Setup; vollständiges Lesen mehrerer Seiten und Abschluss kehren zur gefilterten Bibliothek mit dem neuen Heft zurück; Profilklasse4 unverändert.
- Originaltests freieKlassenwahl1–4, manuelle/Überraschungsgeschichte, Lernpfadschulstufe/Lock und nicht destruktiver Bibliotheksfilter weiter ausgeführt.
- Getrennte KI-Quellprüfung: keine verbleibenden wichtigen Blocker im begrenzten Delta. Schreibcoach-Abschlussroute ist durch exakte Routenentfernung im Frameworkcode geprüft, aber noch kein zusätzlicher eigener vollständiger Widgetlauf dieser Variante; beim Schreibcoachblock nachholen.

## Visuelle Prüfung und Grenzen

Drei tatsächliche Flutter-Widgetlaufaufnahmen mit App-Theme/Originalschriften: `visuals/086eb42-pending-write.png`, `visuals/086eb42-persisted-success.png`, `visuals/086eb42-failed-write-retry.png`. Der lokale Bildvergleich bestätigt: Fehlerhinweis ist lesbar und der Abschluss-/Retrybutton darunter frei. Quelle/Hash/800×600-Auflösung in `visuals/story-storage-manifest.json`.

Es sind **keine Android-Screenshots**. Kein physischerFold-, Hör-, FPS- oder Gesamtgrafiknachweis. Der alte Geschichtenbereich entspricht noch nicht der Premium-Referenz: Buch-Emoji statt Illustration; heller Abschlussdialog mit teilweise heller Typografie. Diese sichtbaren Gestaltungslücken bleiben im Designblock; sie werden nicht als visuell freigegeben ausgegeben.

Nächster separater Block: [PR290 – datenbasierte Lern-DNA/Insight](https://github.com/Ullmann27/lumo-lernen/pull/290). Direkte Geschichten-Einstiege, fachliche Antwortaufzeichnung, Elternanalyse, Unterricht, Meister/Belohnungen und weitere Gesamtprüfungen sind durch diesen begrenzten Reparaturblock noch nicht abgeschlossen.
