# APK1905 · Bauen-Wiederholung mit geprüfter Systemimage-Vorbereitung

Status dieses Folgepakets: **SOURCE FROZEN / neuer Androidlauf NOT EXECUTED**. Dieser
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
YAML aus dem neuen Branch stammt. Ein zweiter Checkout unter `workflow-source/`
verwendet ausdrücklich `${{ github.sha }}`; ausschließlich dessen selbständiger
SDK-Helper wird vor dem unveränderten Emulatorrunner ausgeführt. Der zweite
HEAD, Helperpfad und Helper-SHA256 werden separat aufgezeichnet. Der originale
Runtime-Checkout bleibt f6; APK-/Provenienz-/Quell-/Pin-/Versions-/
Zertifikatsprüfung erfolgt vor dem Emulator.

Die Folgematrix enthält ausschließlich **Bauen, API35**. Ubuntu,
Java17, Leserpakete uiautomator2==3.7.0/Pillow==12.3.0, SDK/Emulatorbuild14472402,
Pixel5, RAM/Heap, Softwaredisplay, Treiberumgebung, Inputs, Skript und alle
Timeouts des ursprünglichen Androidjobs werden unverändert übernommen:
Job45min, Emulatorboot300s, Fullrace1200s. Die neue Vorbereitung hat einen
eigenen 11min-Schritt mit einer gemeinsamen 600s-Frist und höchstens drei
Installs desselben API35-GoogleAPIs-x86_64-Pakets; Wiederholung ist ausschließlich
für den tatsächlich beobachteten ZIP-Archivfehler erlaubt. Die gültige lokale
Paketbeschreibung und nichtleere reguläre Image-Dateien werden geprüft.
Keine Orientierungseinstellung oder Gameplay-/Prüfbedingung wird verändert.

Originale Fehler bleiben erhalten: Actions37846382465, Bauenjob113557082619
und Schatzsuchejob113557082688. GitHub-Metadaten prüfen deren tatsächlichen
Originalquell-Commit und weiterhin abgeschlossene FAILURE-Zustände. Die neuen
Ergebnisse ersetzen oder löschen weder Originallogs noch Originalartefakte.
Die erste identische Diagnose Actions37852518931, Workflowquelle6b3cb7c258e185455b7874755433c7f3b6da31a2,
Bauenjob113568737178 scheiterte erneut **vor Engine-/UI-Start** am SDKManager-
Fehler `Error on ZipFile unknown archive`. Das klärt weder die ursprüngliche
schwarze Bauen-Oberfläche noch belegt es einen Produktfix. Ihr tatsächlicher
FAILURE-Zustand wird zusätzlich per Actions-Metadaten erhalten und geprüft.
Schatzsuche hat inzwischen eine separate begrenzte Wiederholungsprüfung
bestanden; dieses Folgepaket wiederholt nur den weiterhin blockierten Bauenfall.
Artefakte heißen separat
`lumo-original1905-android-{game}-api35-{neue_run_id}` und werden auch bei
Fehlern hochgeladen. Der neue Workflow kann den ursprünglichen Lauf nicht
abbrechen; seine Concurrency ist getrennt, cancel-in-progress:false.

SDK-/Lizenzkontext: Die tatsächlichen Originaljobs verwendeten Ubuntu24.04,
Image20261004.327.1 und reactivecircus-Commit
`a421e43855164a8197daf9d8d40fe71c6996bb0d`. Die offizielle exakte
[Imagebauquelle](https://github.com/actions/runner-images/blob/ubuntu24/20261004.327/images/ubuntu/scripts/build/install-android-sdk.sh)
installiert Standardkomponenten mit bestätigender Eingabe; das legt bereits
vorhandene SDK-Lizenzen nahe, beweist aber kein tatsächliches Dateiinventar vor
unserem Schritt. Die exakte
[Runnerquelle](https://github.com/ReactiveCircus/android-emulator-runner/blob/a421e43855164a8197daf9d8d40fe71c6996bb0d/src/sdk-installer.ts)
und Originaljoblogs führen `sdkmanager --licenses` erst innerhalb des späteren
Runners aus. Der neue Helper verlangt vorbestehende reguläre akzeptierte
Lizenzdateien und liefert bei fehlenden/ungültigen Voraussetzungen FAIL;
er beantwortet keine Lizenzfrage. Neue tatsächliche SDK-/Lizenzprüfung bleibt
**NOT EXECUTED**, bis der neue Runner sie ausgeführt hat.

Übernommener Helper ist byteidentisch mit dem unabhängig geprüften korrigierten
SDK-Commit `744871e420e009ac48135753b46644e5eeb4a377`, Tree
`454f0736ad818c248c4482caa9d5419e1675a656`:
SHA256 `6e5e829b84ea01dfd936d37bf153061e238b2696b9899f7d6408633162c74254`.
38 gezielte Tests,380 Android-QA- und36 Script-Tests PASS/0SKIP/FAIL;
398 kombinierte Handoff-/SDK-Tests ebenfalls PASS. Diese Zahlen sind
kontrollierte lokale Quellen-/Faultprüfungen, keine tatsächliche SDK- oder
Android-Ausführung. Die vorherige327-Helperquelle blieb wegen zweier FIFO-
Metadatendateien und eines externen Lizenz-Elternsymlinks BLOCKED; der
korrigierte Helper verwirft die tatsächlichen drei CLI-Fälle vor jedem SDK-Aufruf.
Die ursprünglichen33 Assertions bleiben plus fünf zusätzliche Negativtests.
Die Diagnose übernimmt ausschließlich den standaloneHelper; Tests und
vollständige SDK-Übergabe bleiben im separat geprüften SDK-/1906-Paket.

Ziel ist eine echte identische Quellen-/APK-Vergleichsmessung: reproduziert
der unveränderte neue Emulatorlauf dieselben Fehler, oder unterscheiden sich
Rohbild, Prozesszustand und echte UI-Hierarchie? Vor einer belegten Diagnose
wird kein Produktfix behauptet. Vorhandene Source-/Native-PASS-Ergebnisse,
Kart-Fehler und die offenen Referenz-/Hardwaregrenzen bleiben getrennt.

Nächster Schritt: unabhängiger Workflowpeer, anschließend neuer Bauen-Diagnoserun und ursprüngliche
Artefakte mit ZIP-/SHA-/CRC-Prüfung und echten Rohdaten vergleichen.
**VISUAL_GAP / NOT FINISHED**, keine 60-FPS-/physische-Fold-Zusage; Main und
Releases bleiben unverändert.
