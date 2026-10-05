# Opus-Fortsetzung: Test-APK 0.10.6 / 1279

Stand: 5. Oktober 2026. Auftrag von Heinz: exakt beim Screenshot-Stand von Opus fortsetzen und eine APK zum Ausprobieren bereitstellen.

## Gelieferter Build

- APK: `Lumo-Lernen-0.10.6-1279.apk` (unveränderte APK aus dem CI-Artefakt, nur aussagekräftiger Dateiname).
- Größe: 168741940 Bytes, ungefähr 169 MB.
- SHA-256: `edc30a9f368da119a75839c93d712a3f0afda7226840106678ac10e1c833886b`.
- Android: `dev.ullmann.lumo.lumo_lernen.coachpreview`, Anzeigename **Lumo Lernen Neu**, Version 0.10.6, Build 1279.
- ABIs: arm64-v8a und x86_64. minSdk 24, targetSdk 36.
- Stabile Testsignatur; kein Produktionsrelease. Separate Paketkennung gegenüber der normalen Lumo-App.
- Originaler Opus-Flutter-Stand: `86c5a332244728d34074fb27423fbdf728390546`.
- Tatsächlicher Flutter-Build-Quellcommit: `48ec0064b3c9d34c3b6764962a839968f3c0e8d0`. Dieses nachträgliche Dokument ist nicht Teil des APK-Quellcommits.
- Eingebauter Godot-Quellcommit: `dee0da4c582813ad3f4ffa7c6da320a6f6eb89ac`, Engine 4.6.3.
- PCK-SHA-256: `f24bbbd06fee546ff1f635a7687fa8c461bf357dc30b4b2189e0ebec8458bedf`.

APK-Build erfolgreich: https://github.com/Ullmann27/lumo-lernen/actions/runs/37312358964
Artefakt: `lumo-probe-apk-37312358964-1`, ID 11345864334. Die Aufbewahrung im CI ist auf 14 Tage begrenzt. Die eigentliche APK wurde aus dem Artefakt entpackt und im Chat als APK-Datei bereitgestellt, nicht nur als ZIP-Link.

## Tatsächlich erledigt

Opus' Cards- und Querformat-Änderungen bleiben erhalten. Der offene Fahrzeugtest wurde am alten Godot-Pin a369da2dc208fcd9d5451c7007d8b1f9e7bf52a1 reproduziert. Beim Zusammenfassen von indizierter und nicht indizierter Geometrie gingen 20 Dreiecke der Stern-Embleme verloren. Bereits die alte Testreferenz verlor 10 Dreiecke.

Die Produktionskorrektur ergänzt vor dem Zusammenfassen explizite Indizes für bislang nicht indizierte Dreiecke. Nah- und Fernmodell behalten sämtliche Dreiecke. Die verstärkte Regression vergleicht zusätzlich mit tatsächlich ungebündelter Geometrie, prüft beide Detailstufen und hält das Materialbudget ein. Veraltete Blink-Zeitpunkt- und LOD-Schwellen-Erwartungen wurden an verhaltensbasierte Prüfungen angepasst, ohne das Animationsdesign zu ändern.

Negativkontrolle: Der ursprüngliche Produktionscode scheitert auch mit dem neuen Test; der korrigierte Code besteht für alle fünf Figuren.

## Gemessene Testergebnisse

| Prüfung | Ergebnis |
| --- | --- |
| Flutter-Tests | 613 bestanden, 0 fehlgeschlagen, 4 übersprungen |
| Flutter-Codeanalyse | 0 Fehler, 18 Warnungen, 119 Hinweise; Warnungen/Hinweise nicht vollständig bereinigt |
| Servercode-Tests | 22 bestanden; kein Nachweis einer laufenden externen KI-Bereitstellung |
| Android-Vorbereitung | 5 bestanden |
| Inhaltsprüfung | 40960 generierte Aufgaben geprüft |
| Kart-Regressionsskripte | 8 von 8 bestanden am exakt eingebauten Godot-Pin |
| Gerendertes Kart-Menü | Pixel-Touch-Ablauf bei 1280x720 und 800x480 bestanden |
| APK-Prüfung im CI | Signatur, Paket, ABIs, PCK-Provenienz und Ressourcen-/16-KiB-ELF-Ausrichtung bestanden |
| Prüfung nach Download | APK-SHA-256, ZIP-Integrität, eingebetteter PCK-Hash, ABIs und resources.arsc-Ausrichtung erneut bestätigt |

Kart-Suite: https://github.com/Ullmann27/lumo-lernen/actions/runs/37312359031
Artefakt: `opus-kart-proof-37312359031-1`, ID 11346502383. Enthält alle acht Logs, Ergebnis-JSON, exakten Pin und tatsächlich gerenderte Screenshots.

Flutter-Protokolle: `lumo-probe-test-logs-37312358964-1`, ID 11345759588.

## Übergabe und Grenzen

- Flutter-Draft-PR: https://github.com/Ullmann27/lumo-lernen/pull/195
- Godot-Korrektur-Draft-PR: https://github.com/Ullmann27/lumo-godot/pull/13
- Keine automatischen Merges; main und Claudes Arbeitszweige wurden nicht verändert.
- Kein physischer Fold-7-Test, keine FPS-Messung und keine Garantie für 60 FPS.
- Vorabversion, nicht als fertiges Grafikniveau oder vollständig integrierte Produktions-App bezeichnen.
- Die vier übersprungenen Flutter-Tests und bestehenden Warnungen/Hinweise bleiben ausdrücklich offen.
- Bestehende externe Integrations- und Grafikaufgaben aus der Gap-Matrix bleiben offen. Keine Nutzungsgrenze bei Claude umgangen und keine fremde Agentensitzung als gesteuert ausgegeben.
