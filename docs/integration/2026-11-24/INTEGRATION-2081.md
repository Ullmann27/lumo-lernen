# Lumo 0.14.8+2081: zusammengeführter Kandidat

Heinz hat am 24.11.2026 ausdrücklich angeordnet: den laufenden 2080-Lauf abbrechen, die noch fehlenden entwickelten Teile integrieren und den neuen Build liefern. Lauf 45421319160 ist `cancelled`; seine bereits gebaute APK wird nicht als 2081 ausgegeben. Der produktive Main-Branch bleibt unverändert.

## Neue integrierte Funktionen

- Adaptive Ganzzahl-Rechenhilfe mit lösungsgeprüften Hinweisen und interaktiver Zehnerwerkstatt für Plus/Minus bis 100; die ursprüngliche Aufgabe und ihr Lernfortschritt bleiben erhalten.
- Lumo World mit sieben Orten, neun lokalen Auftragsfiguren, vier Missionsketten, Dialogen und neun Figurenkarten, einschließlich strikter Daten-/Fortschrittsprüfung.
- Zusammengeführte World-Kart-Entwicklung: sichtbarer Ersteintritt, Kart-Wegweiser, sichere Parkposition, Kartkarte, Bodenkontakt und Speichern/Wiederfinden.
- Schachstart prüft die aktuelle Tagesmission/Profilgeneration nochmals und nutzt die bestehende Ereignisverwaltung. Der Wiederholungsfall vergibt Belohnungen nur einmal.
- Android-Prüfung bedient das echte sichtbare Intro-Überspringen und verlangt danach weiterhin das echte Profil und die sieben nativen Spielstarts.

## Abgleich älterer Stände

Sprachdialog, 3D-Nachhilfe, PR 530, die Schul-Demozweige, Logik/World und der World-Gang sind in der aktuellen Basis bereits funktional beziehungsweise patchgleich enthalten. Ein bloßer fehlender Merge-Commit war hier kein fehlender Inhalt. Die neueren Implementierungen werden erhalten. Der ältere Schachzweig wird nicht über die aktuelle Schach-Engine, KI und Schule geschrieben.

Die 17 zugänglichen uncommitteten Dateien des alten lokalen 2048-Workspaces sind bytegleich mit seinem gesicherten GitHub-Zweig. Er wurde vor dem Vergleich kopiert und blieb unverändert. Die früher genannten ungefähr 450 lokalen Änderungen sind in den zugänglichen Flutter-Arbeitsordnern nicht nachgewiesen. Es wird keine Wiederherstellung nicht zugänglicher Dateien behauptet.

Die älteren 2075/2077-QA-Zweige enthalten nur Test-/Prüfwerkzeugdifferenzen. Die aktuelle echte PNG-Prüfung und die strengeren vorhandenen OCR-Verträge bleiben erhalten. Android-Rohbelege und vollständiges Beleg-ZIP werden weiterhin auch bei Fehlschlag hochgeladen.

## Nachweise und Grenzen

- Exakte Quell-IDs: `INTEGRATION-2081.json`.
- Lern-/Schachvergleich: `docs/handover/BUILD_2081_FLUTTER_COVERAGE_20261124.md`, tatsächliche lokale Logs unter `docs/evidence/build-2081-flutter-20261124/`. 58 gezielte Flutter-Tests bestanden; der neue Schachtest schlägt gegen die alte Implementierung nachvollziehbar fehl.
- 47 gezielte Python-Prüfungen für Intro, Profilanlage und native Spielstarts bestanden.
- Godot: `docs/handoffs/LUMO_2081_NATIVE_INTEGRATION_20261124.md` im gepinnten Repository; 1098 Prüfpunkte und die 65-Knochen-Gangprüfung bestanden unter 4.6.3. Alle vorhandenen Charakter-/Modell-/Texturdateien gegenüber dem alten Pin bleiben bytegleich.
- Die Pipeline führt jetzt die vollständige Flutter-Suite aus, zusätzlich die fünf strikten World-Prüfungen, dann den signierten APK-Bau und die echte Android-Tour samt Datensicherung. Alle vorhandenen Paket-/Signatur-/PCK-/SHA-Prüfungen bleiben bestehen.
- APK- und Android-Abnahme dieses Kandidaten sind beim Anfordern des Builds noch offen. Keine Aussage über physische Fold7-Leistung, 60 FPS, Online-Mitspieler oder eine Play-Produktionssignatur.

Paketkennung und Zertifikat entsprechen weiterhin der installierten Familien-Test-App. Veröffentlichte alte Dateien werden nicht verändert. Ein öffentlicher Download folgt erst aus den erfolgreich geprüften Bytes dieses Kandidaten.
