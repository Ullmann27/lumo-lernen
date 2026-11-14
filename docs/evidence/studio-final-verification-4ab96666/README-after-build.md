# Aktueller 4ab-Kandidat: Build und Paketbytes geprüft, Android-Abnahme läuft

**Stand: 14. November 2026, nach Abschluss des Buildjobs um 00:57:01 UTC.** Diese Ergänzung gehört ausschließlich zu Host `4ab96666f954baf258422d6ed277fc297b7ddeef`, Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`, [Run 43530667812](https://github.com/Ullmann27/lumo-lernen/actions/runs/43530667812), Versuch 1. Sie ändert keine Produktdatei und ist keine vorgezogene Android- oder Auslieferungsfreigabe.

## Tatsächlich neue Ergebnisse

| Bereich | Ergebnis aus diesem Kandidaten | Originalbeleg |
| --- | --- | --- |
| Vollständige Flutter-Regression | 2.514 PASS, 0 FAIL, 0 SKIP | Bereits gesicherter [Flutter-Review](flutter/review.json) und unveränderter Maschinenlog. |
| Build-/Bestandsschutzverträge | 430 Tests, 0 Fehler, 0 Skip, 131,128 s | [Build-Review](build/review.json), [vollständiger dekodierter Joblog](build/original-job.log). |
| Android-Probe-Verträge | 807 Tests, 0 Fehler, 0 Skip, 46,372 s | Dieselben Originale. Diese Suite enthält synthetische Verträge und ersetzt keinen Live-Emulatorlauf. |
| Native-Gesamtschritt im Hostjob | SUCCESS; 25 Nextgen- und 16 Studio-Gatezeilen PASS | [Native-Host-Review](native-host/review.json) mit Original-TSVs, Logs und Quellenstempeln. |
| APK-Bau | SUCCESS, 00:50:03–00:56:35 UTC | [Originale Jobmetadaten](build/original-job-metadata.json). |
| APK-Verifikation | Beide ABIs erfolgreich geprüft, 00:56:35–00:56:44 UTC | [Unveränderte CI-Paketberichte aus dem Originaljob](build/apk-verification-reports-from-original-job.json). |
| ARM64-Download und lokale Inhaltsprüfung | Originalartefakt-Hash, alle APK-CRC-Einträge, eingebettetes PCK, ELF 16 KiB, Ressourcenausrichtung und Sprachmodellhashes stimmen | [Lokaler Paketreview](arm64/local-package-review.json), [originaler CI-Bericht](arm64/original/APK-VERIFICATION.json), [Buildprovenienz](arm64/original/BUILD-PROVENANCE.json). |

Die Testzahlen verschiedener Suites, Varianten und Commits werden nicht addiert. Die vorherigen 426/788- oder 402/764-Angaben sind historische Ergebnisse und werden nicht als neue Prüfungen ausgegeben.

## Paketidentität

| Eigenschaft | Tatsächlicher Wert |
| --- | --- |
| Version | 0.13.7+2019 |
| Paket |`dev.ullmann.lumo.lumo_lernen.coachpreview` |
| ARM64-APK | 322.140.841 Bytes; SHA256 `639d9d4f94fc1b1ce4447995eb673643ec4f2ade2717d701d73e0562ccf5e2aa` |
| x86_64-APK | 325.295.610 Bytes; SHA256 `7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6` |
| Gemeinsames PCK | 66.234.596 Bytes; SHA256 `28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e` |
| Godot-Paketformat | 3; Engine 4.6.3 |
| Android | minSdk 24, targetSdk 36; die zusätzliche Laufzeitprüfung auf Android 17/API 37 ist davon getrennt. |
| Zertifikat laut tatsächlich erfolgreichem CI-apksigner |`a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

Das separate ARM64-Artefakt 14089503005 besitzt 322.151.254 Bytes und SHA256 `a05231c727d3f7872c9d3bff40ccf2fc5c50ed25655a648b874cac94ddcfd043`. Der lokale Download wurde komplett CRC-geprüft. Die APK wurde direkt aus dem Original-ZIP im Speicher geprüft; es wurde keine zweite große APK-Datei erzeugt. Die lokale Prüfung wiederholt `apksigner` nicht: Signatur und Manifest sind durch den tatsächlichen CI-Lauf belegt, dessen exakte APK-Bytes hier unabhängig übereinstimmen.

## Native-Originale und verbleibende Warnungen

Das neue Host-Native-Artefakt 14090026570 besitzt 157.198.504 Bytes, SHA256 `452061825ace93484d7699c27e858c66ca225c3f893b329e35cb1d92f9d4804c`, und 5.329 CRC-geprüfte Einträge. Alle fünf vorhandenen Quellenstempel zeigen 803e; die beiden Dirty-Dateien sind leer, der Studio-Tree entspricht `dc24bfa8b3fac8812c88cfc8f8eab3af1479979c`. 84 kleine Original-Logs/TSVs/Quellstempel sind unverändert ausgewählt und in diesem Repository gesichert. Die vollständige Original-ZIP und ihre Inhaltsliste wurden geprüft; die PNGs dieses zusätzlichen Host-Artefakts werden nicht pauschal als manuell gesichtet ausgegeben.

Der Projektvalidator meldet 117 PASS / 7 WARN / 0 FAIL. Sechs Warnungen betreffen fehlende alte AssetLoader-Pfade mit vorhandenen Fallbacks; die siebte betrifft das Ausführungsbit eines Web-Helfers. Das tatsächlich verwendete Original-Lumo-Animations-GLB liegt unter einem anderen, vorhandenen Pfad. Außerdem bleiben vier `resources still in use at exit`-Zeilen aus drei Testlogs erhalten. Ein grüner Gate-Ausgang wird deshalb weder als warnungsfrei noch als Nachweis für Geräte-Speicherstabilität dargestellt. Die separate Primitive-Character-Testsuite beweist keine neue Gesichtsanimation des 65-Knochen-Originalfuchses.

## Laufende getrennte Android-Abnahmen

Die folgenden echten Jobs haben nach dem Build begonnen:

- API 35: 132269951320.
- Android 17/API 37: 132269951372.
- Update 2017→2019: 132269951387.
- Creative-Android mit Jump, Bauwelt, Puzzle und Schatzsuche: 132269951369.

Für diese Jobs liegt zum Zeitpunkt dieses Berichts noch keine vollständige Laufzeit-/Bild-/Speicherstandsfreigabe vor. Publisher und tatsächlicher öffentlicher Download bleiben ebenfalls zu prüfen. Kein physisches Fold7 ist angeschlossen; stabile 60 FPS, GPU-Framezeiten, Wärme und Touchlatenz sind nicht gemessen. Der vollständige Masterauftrag bleibt wegen der im [Umfangsbericht](../../STUDIO_NEXTGEN_SCOPE.md) benannten Produktlücken teilweise offen.
