# Lumo 1985 — räumliches Lesen und bedienbare Karten

Basis: Flutter `f3277e57911f4641a3099af67ce4427bfdc382a3` (offener Stack #374–#376), Godot `85f392bfbc9f9a5e9267a935788340cb62ca0b29` (#106). Neuer Kart-Pin: `ffd2955ca9222daf02e6b602b3f213fd9383204a` (#107). Version `0.12.73+1985`. Der historische Pin von 1984 bleibt im Versionsprüfer unverändert.

## Umsetzung

- Fachinseln: Glasfacetten, räumliches Akzentlicht, sichtbarer Navigationspfeil und gemeinsame, abschaltbare Druckreaktion. Anordnung, Fächer und gespeicherte Leistungen bleiben erhalten.
- Premium-Karten: gemeinsame Materialkante, native Tastatur-/Screenreader-Bedienung, mindestens 48 dp und reduzierte Bewegung. Native Ripple-Rückmeldung ohne zusätzlichen Sparkle-Shader.
- Leseabenteuer: vorhandene transparente Lumo-PNGs auf der vorhandenen Bibliothekskulisse, getrennte Vorder-/Hintergrundebenen und einmalige Einblendung. Kein Zugriff mehr auf die fehlenden vorbereiteten Story-Cutouts. Die achtseitigen frei gewählten Geschichten erhalten keine fremden Bibliotheks-/Gartenszenen.
- Mini-Aufgaben: native Antwortbuttons, Symbol- und Textfeedback, korrigierbare Rechenantworten, kein Weitergehen nach falscher Antwort, nur eine Belohnung pro gelöster Aufgabe.
- Kart: kreisrunde Startlichter mit Lichtkante und kurzem Impuls; Materialwechsel nur bei neuem Countdown-Schritt oder Größenwechsel. Ruhemodus bleibt statisch. PR #106 ist im neuen Pin enthalten.

## Bildnachweise

Die Flutter-Bilder sind unveränderte Rasterisierungen der echten Produktionswidgets mit Originalschriften und lokalen Testprofilen, keine Android-Screenshots. Alle zwölf Aufnahmen (Home, Fachkarten, Lesen, erneutes Versuchen × 344/412/690 dp) erzeugt:

```sh
LUMO_SPATIAL_CAPTURES=/tmp/lumo-captures flutter test --no-pub test/design/lumo_spatial_reading_capture_test.dart
```

[Lesen auf dem Handy](reading-phone.png) · [Fachkarten auf Fold außen](subjects-fold-cover.png) · [Antwortkorrektur](retry-phone.png) · [Startseite auf Fold innen](home-fold-open.png)

[Kart-Countdown](countdown.png) · [Kart-Start](go.png) stammen aus dem laufenden Godot-4.6.3-Rennen, Compatibility/Mesa llvmpipe, 1280×720, mit angehaltenem Rennzustand für reproduzierbare Aufnahmen (`kart_start_lights_capture.gd`). Keine FPS-Messung.

## Prüfung und Grenzen

- Lokale Analyse: keine Fehler; 56 Meldungen, darunter zwei bereits vorhandene Warnungen (Quiz-Import, unbenutztes Story-Painter-Feld).
- Neue Verhaltensproben reproduzierten zunächst fehlende Tastaturaktivierung, nicht korrigierbare Rechenantworten und neue Lampenressourcen pro Bild; die gezielten Nachprüfungen bestehen.
- Zwölf Flutter-Bildaufnahmen: 3 Matrixprüfungen bestanden, ohne Layout-/Assetfehler.
- Versions-/Pin-Schutz: 21 Tests bestanden; 1984 lehnt den neuen Pin weiterhin ab.
- Godot: statischer Validator 117 PASS / 7 WARN / 0 FAIL; Countdown- und Profilpersistenzproben bestanden. Die ältere Kart-Grundprobe meldete funktional PASS, aber Ressourcenwarnungen beim Beenden; die lokale Brückenprobe erreichte ihr Zeitlimit. Die vollständige Stage-2-Prüfung läuft auf GitHub.
- Ein erster vollständiger lokaler Flutter-Lauf traf beim neuen InkWell auf einen fehlenden Sparkle-Shader. Die Karten verwenden jetzt den günstigeren nativen Ripple; beide Kartentests und beide betroffenen Auswahltests bestehen im Nachlauf. Maßgeblich für den Kandidaten ist der vollständige GitHub-Lauf des finalen Commits.
- APK, Emulator und Veröffentlichung gelten erst bei erfolgreichem gesamten Integrationsworkflow als abgeschlossen. Keine physische Fold-/ARM64-/60-FPS-Abnahme.

GitHub ergänzt die abschließenden Testergebnisse und APK-Provenienz im verlinkten PR/Workflow. Offene Grafikarbeit: zusätzliche geschichtsspezifische Illustrationen für die mittleren Kapitel; die vorhandenen Canvas-Szenen bleiben dort erhalten.
