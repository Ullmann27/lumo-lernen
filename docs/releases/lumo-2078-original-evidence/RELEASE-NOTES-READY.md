# Lumo 0.14.6+2078 — signierte Android-Testversion

Diese vollständige Testversion integriert die neun originalen Meshy-Tierfiguren mit je 26 Knochen, zwölf Animationen und drei Detailstufen. Alle 27 Varianten werden im tatsächlichen APK-Paket geladen und geprüft. Enthalten sind außerdem die Kart-/Garagenkorrekturen, die angepasste World-Kamera bei Wandnähe und die getrennten Play-/Streckenpfeilflächen in den geprüften Fold-Ansichten.

## Nachgewiesene Prüfungen

- 15.246 native Prüfaussagen, einschließlich 2.243 Menüprüfungen; 73 quellgebundene Rendererbilddateien mit geprüften Hashes.
- Android-Rundgang: 23 von 23 Schritten bestanden, einschließlich Kartfahrt, Rückkehr zur Lern-App und Erhalt des Lernstands nach Neustart.
- Verbindliche native Starts: Run, Quiz, Memory, Chess, Kart, Cards und World bestanden.
- Android-Sicherung/Wiederherstellung: 8 von 8 Schritten bestanden. Zusätzlich wurden 17 Einstellungen und zehn native Spielstandsdateien unabhängig abgeglichen.
- Vollständige Original-APK bytegenau übertragen; Paketkennung, Version und Signatur unabhängig geprüft.

Original-Prüflauf: https://github.com/Ullmann27/lumo-lernen/actions/runs/45365478105

## Bekannte Grenzen dieser Testversion

Im flachen Querformat überdeckt der linke Streckenpfeil einen Teil des Namens „Sonnenhafen“. Im Sternenpost-Abschnitt traten drei nichtfatale Godot-can_process-Meldungen auf; Flug, Belohnung und Rückkehr bestanden. Die zusätzliche Routendiagnose erreichte 13 von 16 Versuchen; die drei alten Routen settlement, build und treasure wurden in diesem Diagnoseablauf nicht gefunden. Das verpflichtende Sieben-Szenen-Gate ist vollständig bestanden.

Die Abnahme erfolgte mit Desktop-Renderer und Android-Emulator. Physische Fold7-Bildrate/60 FPS, hörbare Audioausgabe und ein vollständiges Kartrennen über zwei Runden samt Belohnung sind damit nicht nachgewiesen. Testsignatur; kein Play-Store-Release.

## Datei und Herkunft

- Datei: `Lumo-Lernen-0.14.6-2078.apk`
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`
- Version: `0.14.6`, versionCode `2078`
- Größe: `701640419` Bytes
- ABIs: `arm64-v8a`, `x86_64`
- Flutter-Quelle: `94cabcff7f6c568eddfe6805801f49a00ad58312`
- Godot-Quelle: `c3f459eca88f659da1a9e4af1c990c804e715528` (Engine 4.6.3)
- APK SHA256: `3e49c99c22d05f7003e4477911d0f72e20fd3447cf6f9d55f6ab805c5fbc8198`
- Zertifikat SHA256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`

Manuelle Installation über die APK-Datei. Die vorhandene Familien-App zum Aktualisieren nicht vorher deinstallieren. Der interne Updateknopf verwendet weiterhin seinen bisherigen coachpreview-Kanal.
