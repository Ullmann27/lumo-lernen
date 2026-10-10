# Lumo Kart: Android-Testintegration 1928

Stand: 11. Oktober 2026. Eigener Branch `computer/lumo-kart-android-1928-2026-10-11`, Ausgangscommit `d2d25c35f7a78ec0a4b09fb263f0cfddfedf357a` aus dem [gemeinsamen Gegnerkatalog PR #257](https://github.com/Ullmann27/lumo-lernen/pull/257). Diese Quelle enthält den bestehenden Sprach-/Kontextstand, den Schreibcoach und das Grafik-Grundgerüst. Fremde uncommittete Rivalenbilder und Spieländerungen bleiben unangetastet.

## Tatsächlich geänderter Umfang

- **Version:** `0.12.21+1928`, eindeutig von der [technischen Testversion 1927](https://github.com/Ullmann27/lumo-lernen/releases/tag/lumo-0.12.20-1927-context-voice-technical-test) unterscheidbar.
- **Godot-Pin:** `a981e8b08f89b3d995cb1e0f8d2edc9027ef75f4` aus [PR #54](https://github.com/Ullmann27/lumo-godot/pull/54). Enthält die echte Kart-Rennanimation aus [PR #52](https://github.com/Ullmann27/lumo-godot/pull/52), das geprüfte Originalreferenz-/Fold-Menü aus [PR #53](https://github.com/Ullmann27/lumo-godot/pull/53), den neuen tatsächlichen Ladepfad und ausdrücklich versionierte verlustfrei eingebettete native Texturen.
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

Der [erste Buildlauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/38092390305) bestand 29 Backend-Tests, 45 Vorbereitungstests, Content-Audit, Repair-Guard, Analyse und die vollständige Flutter-Suite mit 921 erfolgreichen und 27 übersprungenen Tests. Die Analyse enthält 20 bestehende Hinweise/Warnungen; sie wird nicht als fehlerfreie Lint-Abnahme bezeichnet. Der Build stoppte vor dem APK-Bau am strikten Godot-Source-Guard, weil die bislang nicht versionierte Standard-Importregel Texturen in drei neue PNG-Dateien extrahierte.

Die Importregel ist im korrigierten Godot-Pin ausdrücklich versioniert. Eine experimentelle nachträgliche PNG-Bereinigung wurde durch einen tatsächlichen PCK-Lauf als ungeeignet erkannt, vollständig verworfen und nie veröffentlicht. Im veröffentlichten Flutter-Exporter bleibt nur eine genauere Fehlerdiagnose; seine Schutzprüfung ist unverändert streng. Der erste Basis-Universal-Versuch blieb im tatsächlichen GL-Weiterwechsel hängen und ist kein akzeptierter APK-Kandidat. Die endgültige verlustfreie Einbettung (`3`) bestand den gleichen GL-Menütest mit 46/0 einschließlich realem Weiterwechsel und Ressourcenfreigabe. GLB, Rig, Clips und Provider bleiben unverändert. Frischer und wiederholter PCK-Export werden vor dem nächsten APK-Lauf geprüft.

Beide tatsächlichen Exporte sind inzwischen erfolgreich: erster PCK-Lauf 87/0, wiederholter Lauf 86/0; jeweils Original-Materialtexturen, tatsächlicher Router, Retry und Orphan-Baseline geprüft. Der native Checkout bleibt nach beiden Exporten vollständig sauber. Das zuletzt geprüfte PCK enthält den oben angegebenen Godot-Commit, 47.305.348 Bytes und SHA-256 `a1486f2fa929fc0f02b07ea0930d84c2405ec2aed75e7cd7d4686dba9f436ca8`. Die PCK-Prüfung ist noch kein APK- oder physischer Android-Nachweis.

## Fortsetzung

Der [zweite Buildlauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/38094050301) bestand erneut die komplette Flutter-Suite, aber Gradle lehnte die gleichzeitigen bisherigen `ndk.abiFilters` und die neuen ABI-Splits ab. Der native Hostblock setzt die bisherigen Universal-Filter deshalb nur, wenn Flutter nicht `-Psplit-per-abi=true` übergibt. Paketkennung und Signatur bleiben unangetastet.

Für diese isolierte Verpackungsreparatur dürfen die bereits erfolgreichen Flutter-Tests nur mit ausdrücklichem Workflow-Input wiederverwendet werden. Die CI prüft dazu den konkreten vorherigen Run, dessen Quellcommit und erfolgreiche Suite sowie einen strikt begrenzten Dateivergleich ohne Änderungen an App, Assets, Backend, Version, Pin oder Flutter-Tests. Der ursprüngliche fehlgeschlagene Build bleibt dokumentiert. Backend-/Vorbereitungstests, Analyse, tatsächlicher neuer Build, Variantenprüfung und Android-Runtime laufen erneut. Der Nachweis liegt in `VALIDATED-FLUTTER-TESTS.json`; bei anderer Quelle oder größerem Diff bricht die Wiederverwendung ab.

Zuerst aktuellen Commit, Godot-/Flutter-PR-Köpfe und laufende CI prüfen. Den bestehenden Workflow `release-apk.yml` einmal auf diesem Branch starten; keine zusätzlichen vollständigen Builds nach reinen Dokumentänderungen. Nach Erfolg ARM64-Artefakt und genaue Provenienz herunterladen, unabhängig prüfen und möglichst direkt im Chat bereitstellen. Den x86_64-Emulatornachweis klar vom ARM64-Gerätetest trennen.
