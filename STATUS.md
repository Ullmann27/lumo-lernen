# LUMO Technical Art — Status, 11. November 2026

## Geprüfter App- und Spielstand

Der zusammenhängende Sonnenhafen-/Garage-/Lumo-Stand ist implementiert und als signierte **0.13.3+2015** gebaut. Die ursprüngliche Godot-/Flutter-Architektur bleibt erhalten.

| Gegenstand | Verbindlicher Stand |
|---|---|
| APK-Quellcommit Flutter | `2718f405e69c193d0121c6f6447fe53769d7c803` |
| Enthaltener Godot-Produktcommit | `b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1` |
| Godot-Nachweiscommit, gleiche Produktdateien | `a66093107fdc86fbebc94f6cf9b36250bc3a0954` |
| Engine / Flutter-CI | Godot 4.6.3 / Flutter 3.44.9 |
| ARM64-APK | 318708477 Bytes |
| ARM64 SHA-256 | `3bb833935d47fca64efeceb753a48f663d48d3d43b3f02f3e9c798ba9538a4cb` |
| x86_64-Test-APK SHA-256 | `b863bc25bc07a7ca3fb78ad4fd56a6f816d091f821c5b9af27bfb0a7aecbcb4e` |
| Gemeinsamer Godot-PCK SHA-256 | `b5a500087a21dbf42f9b0e34deaf5e22b631fbba5831e01155b8f393f6f6b6bc` |
| Paketkennung | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Bestehendes Testzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

Die APK wurde aus dem unveränderten Quellstand 2718 gebaut. Spätere reine Status-/Belegcommits ändern diese Provenienz nicht.

## Abnahme

- **Godot:** Jeweils alle zwölf Workflows auf b357 und dem Nachweiscommit f324 erfolgreich. Native Projektprüfung, 18 bestehende 2014-Prüfprogramme und sieben ergänzende Artprogramme bestanden. Spieler zwei Runden in GL Compatibility, zwei Loopings, vier Sprünge/Landungen, keine Rücksetzungen; 30 vollständige KI-Zweirundenfahrten ohne Bildausgabe. Ergänzende GL-Szenarioprüfungen für KI-Looping-Anfahrten sowie Rampenflüge/Landungen sind gesondert bestanden.
- **Flutter/Build:** [Run 43024454590](https://github.com/Ullmann27/lumo-lernen/actions/runs/43024454590) ist erfolgreich: vollständige Flutter-Suite, Vertragsprüfungen, native Gates, APK-Bau und Paketverifikation.
- **Android-Tour:** Job 130547247521 erfolgreich, 21 Schritte, API 35/x86_64. Tatsächlicher Rennstart, 26,78 m zusätzlicher Weg, Pause und Rückkehr zu Flutter. Der Test ist keine vollständige Android-Rundfahrt.
- **Update 2014 → 2015:** Job 130553327493 erfolgreich. Installation per `install -r` behält Android-userId und firstInstallTime. Sieben Lernschlüssel, Testprofil, eine richtige Antwort, ein Stern und fünf XP bleiben nach Update, Offline-Kart, Neustart und simulierten Fold-Formaten erhalten.
- **Zusätzliche native Garage auf Android:** [PR456](https://github.com/Ullmann27/lumo-lernen/pull/456) prüft am vorhandenen Paket Fahrzeugwechsel, Bestätigung, Rückwege und Weiterfahren. Aktueller Lauf [43034616066](https://github.com/Ullmann27/lumo-lernen/actions/runs/43034616066) auf Prüfcode `a1d581f0b0b392e0bc4ad7d90fd38d14f8d74095` ist noch nicht abgeschlossen. Der vorherige Lauf 43032732151 scheiterte vor dem Emulator an Ubuntu-Mirror-DNS und APT-Timeout; er ist kein UI-Nachweis. Der Folgecommit ändert nur Paketquellenbehandlung und Doku, weder UI-Probe noch Assertions oder APK.
- **Echte Hardware:** Nicht geprüft. Keine gemessenen ARM64-/Fold-FPS, Temperatur-, Energie- oder RAM-Werte. Audio-/Haptikempfinden nicht abgenommen.

## Umfang und Belege

Die Fassadenaufwertung betrifft die ersten ungefähr 150 m Sonnenhafen. Garage und Original-Lumo sind gemeinsam integriert. Original-GLB, Fahrzeuge, Freischaltungen, Fahrwege, Loopings und Rampen bleiben erhalten. Sichtbare Verbesserungen, echte Vergleichsbilder, Clips, Messbereiche und bekannte Mängel sind im [Godot-Bericht](https://github.com/Ullmann27/lumo-godot/blob/a66093107fdc86fbebc94f6cf9b36250bc3a0954/docs/TECHNICAL_ART_20261111.md) dokumentiert. Der Bericht wird nach dem ergänzenden Androidnachweis aktualisiert.

Offen: vorbestehendes Gecko-Schuhclipping, kleine Statistik-/Dekortexte, weitere Hafenabschnitte und echte Hardwareabnahme. Kein Blinzeln implementiert: Das Originalrig besitzt keine Lider-/Augenknochen oder Morph Targets.

## Lieferung

[Flutter PR455](https://github.com/Ullmann27/lumo-lernen/pull/455) und [Godot PR152](https://github.com/Ullmann27/lumo-godot/pull/152) sind Drafts. Kein main-Merge, Force-Push oder Release. Die eigenen isolierten Godot-Teil-PRs153/154 sind als vollständig in PR152 übernommen geschlossen; ihre Zweige bleiben erhalten.

Ein öffentlicher Direktdownload ist noch nicht erstellt. Die verfügbare Anbindung bietet keine Release-Erstellung/Asset-Uploads; der Browser ist abgemeldet. Der normale Actions-Token besitzt für den Workflow-verändernden Zielcommit nicht die dokumentierte zusätzliche Berechtigung. Die [inaktive Releasevorbereitung](https://github.com/Ullmann27/lumo-lernen/tree/71abdee397bd7e2381af95b77f6524b395100c54) ist konkret gesichert, aber keine Veröffentlichung. Sie darf ohne passenden Zugang und abgeschlossene zusätzliche QA nicht aktiviert werden.

Wiederaufnahme: [CONTINUE.md](CONTINUE.md).
