# Lumo Kart: Android-Testintegration 1928

Stand: 11. Oktober 2026. Eigener Branch `computer/lumo-kart-android-1928-2026-10-11`, Ausgangscommit `d2d25c35f7a78ec0a4b09fb263f0cfddfedf357a` aus dem [gemeinsamen Gegnerkatalog PR #257](https://github.com/Ullmann27/lumo-lernen/pull/257). Diese Quelle enthält den bestehenden Sprach-/Kontextstand, den Schreibcoach und das Grafik-Grundgerüst. Fremde uncommittete Rivalenbilder und Spieländerungen bleiben unangetastet.

## Tatsächlich geänderter Umfang

- **Version:** `0.12.21+1928`, eindeutig von der [technischen Testversion 1927](https://github.com/Ullmann27/lumo-lernen/releases/tag/lumo-0.12.20-1927-context-voice-technical-test) unterscheidbar.
- **Godot-Pin:** `b7c41149cc78f9884b52a62f06a6e30421057f87` aus [PR #54](https://github.com/Ullmann27/lumo-godot/pull/54). Enthält die echte Kart-Rennanimation aus [PR #52](https://github.com/Ullmann27/lumo-godot/pull/52), das geprüfte Originalreferenz-/Fold-Menü aus [PR #53](https://github.com/Ullmann27/lumo-godot/pull/53) und den neuen tatsächlichen Ladepfad.
- **Build:** Optionaler `LUMO_SPLIT_PER_ABI=1` erzeugt ARM64 und x86_64 in einer Flutter-Buildinvokation. ARM64 bleibt die Samsung-Datei im normalen `dist/`-Pfad; die Emulator-Datei liegt unter `dist/x86_64/`. Kein manuelles Entfernen von APK-Bibliotheken und kein nachträgliches Umpacken.
- **Verifikation:** Jede Variante erhält ihre eigene exakte ABI-, Paket-, Versions-, Signatur-, 16-KiB-ELF-, PCK-, Quellen- und SHA-Prüfung sowie eigene Build-Provenienz. Ohne Split-Option bleibt der bisherige Universal-Build unverändert und benötigt beide ABIs.
- **Android-16-Abnahme:** Die bestehende unabhängige Runtime-Probe wird verwendet. Sie installiert zunächst die SHA-geprüfte APK 1927, erstellt nur ein fiktives Testprofil und aktualisiert ohne Deinstallation. Kandidat, Signatur, Installationsidentität, Profil, Kart-Einstieg, tatsächliche Bedienelemente, Pause/Rückkehr und Fold-Resize werden geprüft. Das ist keine physische Samsung-Abnahme.

Keine Änderungen an Sprachprovider, Sulafat-Dateien, Online-Freigaben, Profilformat, Lernmodulen, Aufgabenbewertung, Belohnungen, Originalbildern oder Rennphysik. Kein Merge nach `main` und kein öffentlicher Produktiv-Release.

## Navigation und visuelle Nachweise

Start → Spielen → Lumo Kart. Die tatsächliche Moduswahl bleibt Godot; es gibt kein konkurrierendes neues Flutter-Menü. Das vorhandene Profil und die vorhandenen Freischaltungen bleiben maßgeblich.

Die echten Desktop-/GL-Menübilder, der echte Winke-Mitschnitt, vier Ladeansichten und der normale Ladeübergang sind im Projekt gesichert. Diese Belege werden nicht als Screenshots des APK-Kandidaten ausgegeben. Der alte Ladevergleich ist als angehaltene historische Godot-Fixture markiert; die neuen normalen Startframes besitzen echte Zeitstempel.

## Prüfstatus bei Erstellung

Shellsyntax, Workflow-YAML und Android-Vorbereitungs-/Packaging-Unit-Tests wurden lokal geprüft. Die vier neuen ABI-Tests lehnen fehlende, zusätzliche, leere oder unbekannte Architekturen ab. Der Buildworkflow führt zusätzlich vollständige Flutter-Analyse/Tests, Backend-/Vorbereitungstests, Content-Audit, Repair-Guard, native PCK-Integration und APK-Verifikation aus.

Ein vorbereiteter Buildweg ist keine gebaute APK. Erfolgreiche Analyse, tatsächliche APK-Datei und tatsächliche Android-Runtime-Ergebnisse sind erst nach dem konkreten Workflowlauf zu dokumentieren. Es gibt hier kein physisch angeschlossenes Galaxy Z Fold und kein akustisch geprüftes Sulafat-Hörerlebnis.

## Fortsetzung

Zuerst aktuellen Commit, Godot-/Flutter-PR-Köpfe und laufende CI prüfen. Den bestehenden Workflow `release-apk.yml` einmal auf diesem Branch starten; keine zusätzlichen vollständigen Builds nach reinen Dokumentänderungen. Nach Erfolg ARM64-Artefakt und genaue Provenienz herunterladen, unabhängig prüfen und möglichst direkt im Chat bereitstellen. Den x86_64-Emulatornachweis klar vom ARM64-Gerätetest trennen.
