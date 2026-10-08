# APK1905 · unabhängige Wiederholung unveränderter Bauen-/Schatzsuche-Prüfungen

Status beim Quellabschluss: Diagnose vorbereitet, **NOT EXECUTED**. Dieser
Branch baut keine neue APK und repariert keinen vermuteten Produktfehler.
Der separate unfrozen1906-Zeitformatanschluss bleibt unberührt.

Original-App und tatsächlicher Harness:
`f6c4f3350db8153200594b52a9d82606279dc238`, Godot-Pin
`ad3ee9c9a1e2cfa60a6d2fe4970181b3150a1a1b`, Engine4.6.3, Version0.12.3+1905.
Die wirklich gebaute APK aus Actions37846382465 hat **201691346 Bytes** und
SHA256 `f06140353caa1f2d4c0038287b05918402324b26cc9dc5454ca1c13e9597f14c`.

Der neue Workflow startet ausschließlich durch Push auf
`codex/lumo-1905-original-android-diagnosis-2026-10-08`. Er lädt diese exakte
APK aus `lumo-visual-apk-37846382465` und dieselbe geprüfte1602-Baseline aus
Actions37674457852. Checkout ist ausdrücklich der originale App-Commitf6;
damit bleiben Harness, Config und alle Assertions byteidentisch. Workflow-
Commit, Blob-SHA und SHA256 werden separat aufgezeichnet, weil die Diagnose-
YAML aus dem neuen Branch stammt. APK-/Provenienz-/Quell-/Pin-/Versions-/
Zertifikatsprüfung erfolgt vor dem Emulator.

Die Matrix enthält ausschließlich **Bauen und Schatzsuche, API35**. Ubuntu,
Java17, Leserpakete uiautomator2==3.7.0/Pillow==12.3.0, SDK/Emulatorbuild14472402,
Pixel5, RAM/Heap, Softwaredisplay, Treiberumgebung, Inputs, Skript und alle
Timeouts werden unverändert aus dem ursprünglichen Androidjob übernommen.
Keine Orientierungseinstellung oder Gameplay-/Prüfbedingung wird verändert.

Originale Fehler bleiben erhalten: Actions37846382465, Bauenjob113557082619
und Schatzsuchejob113557082688. GitHub-Metadaten prüfen deren tatsächlichen
Originalquell-Commit und weiterhin abgeschlossene FAILURE-Zustände. Die neuen
Ergebnisse ersetzen oder löschen weder Originallogs noch Originalartefakte.
Artefakte heißen separat
`lumo-original1905-android-{game}-api35-{neue_run_id}` und werden auch bei
Fehlern hochgeladen. Der neue Workflow kann den ursprünglichen Lauf nicht
abbrechen; seine Concurrency ist getrennt, cancel-in-progress:false.

Ziel ist eine echte identische Quellen-/APK-Vergleichsmessung: reproduziert
der unveränderte neue Emulatorlauf dieselben Fehler, oder unterscheiden sich
Rohbild, Prozesszustand und echte UI-Hierarchie? Vor einer belegten Diagnose
wird kein Produktfix behauptet. Vorhandene Source-/Native-PASS-Ergebnisse,
Kart-Fehler und die offenen Referenz-/Hardwaregrenzen bleiben getrennt.

Nächster Schritt: unabhängiger Quellpeer, neuer Diagnosebranch/Run, beide
Originalartefakte mit ZIP-/SHA-/CRC-Prüfung und echte Rohdaten vergleichen.
**VISUAL_GAP / NOT FINISHED**, keine 60-FPS-/physische-Fold-Zusage; Main und
Releases bleiben unverändert.
