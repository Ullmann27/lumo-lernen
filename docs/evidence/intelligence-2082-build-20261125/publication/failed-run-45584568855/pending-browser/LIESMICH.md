# LUMO 0.14.9+2082 – ruhige Spielzüge und Intelligence 2.0

Diese ARM64-Testversion enthält weich animierte Kartenbewegungen, geordnete Kartenübergaben, sichtbare Schachzüge in 2D und 3D und Denkpausen für Lumo. Pause, Abbruch und Neustart beenden oder halten laufende Abläufe kontrolliert an.

Hinzu kommen profilgebundene Lernanalysen, individuelle Lernhilfe und adaptive Lernpläne, nachvollziehbare Hausaufgabenergebnisse aus aktuell gespeicherten Antworten sowie World-Tagesaktivitäten und Dialoge.

## Originaldatei und Quellstand

- Datei: Lumo-Lernen-Test-0.14.9-2082.apk
- Größe: 653.020.163 Bytes
- APK SHA256: 0ab02c4f1d3b3a625be42f5f974d1592ec993af27e5ed56135245dfee4996243
- Paket: dev.ullmann.lumo.lumo_lernen.coachpreview
- Version: 0.14.9, versionCode 2082
- Zertifikat SHA256: a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702
- Flutter/Android: 6574b19f92abb4f6421fd3074cec09738dc0974a
- Godot: 62108c0355f860ab9a0a020ecb5f3f941f1032e9

Die APK stammt unverändert aus dem Originalbuild. Sie wurde für die Übertragung nicht neu gebaut oder signiert. Paket und Familien-Testsignatur bleiben erhalten; kein Play-Store-Produktionsrelease.

## Ausgeführte Prüfung

Originaler Gesamtbuild: https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812

Alle drei Jobs sind erfolgreich: 3.669 Flutter-Tests bestanden, 193 übersprungen; native Regel-, Szenen- und Ablaufprüfungen bestanden; signierter APK-Bau samt Manifest- und Zertifikatsprüfung bestanden. Android: 23 Tour-Schritte, acht Schritte des realen SAF-Backup-/Restore-Rundlaufs und sieben verbindliche native UI-Starts bestanden, keine fatalen Abstürze. Root hat tatsächliche vollständige APK-, eingebettete PCK- und Androidartefaktbytes unabhängig geprüft. ARM64 und x86_64 enthalten denselben PCK.

Echter Godot-Rendererlauf für die Spielbewegungen: https://github.com/Ullmann27/lumo-godot/actions/runs/45569486039 – 148 Checks ohne Fehler, 14 Originalbilder.

Die zusätzliche schreibfreie Veröffentlichungsprüfung und erneute Übergabeprüfung bestanden. Der automatische Publisher wurde beim Anlegen des neuen Tags mit HTTP 403/permission abgewiesen: https://github.com/Ullmann27/lumo-lernen/actions/runs/45584568855

Die kleine Datei LUMO-2082-PRUEFNACHWEISE.zip bündelt die unveränderten Originalberichte und die unabhängigen Prüfprotokolle; sie ersetzt nicht die umfangreichen Original-Bild-/Videoartefakte der verlinkten Läufe.

## Grenzen dieses Teststands

Die Androidprüfungen liefen im Emulator. Kein physischer Fold7-/ARM64- oder 60-FPS-Nachweis, keine vollständige Spielpartie für jedes gestartete Spiel. Zusätzliche UI-Suchversuche für settlement, build und treasure fanden ihre aktivierten Bedienelemente nicht und gelten nicht als bestandene Starts. Schulverwaltung bleibt lokal. Das begrenzte Aufgabenprotokoll ist kein dauerhaft eingefrorenes Hausaufgabenarchiv. World-Figuren haben weiterhin keine eigenen Gehclips; vollständige Kart-Politur und neue Foto-/Handschriftnachhilfe bleiben offen.

Kein Merge nach main.
