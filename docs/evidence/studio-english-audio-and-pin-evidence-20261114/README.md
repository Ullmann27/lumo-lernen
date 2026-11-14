# Englisch-Wortaudio und Native29080: unveränderte Implementierungsbelege

Dieses Paket bewahrt die tatsächliche lokale Implementierungsprüfung sowie den unabhängigen Pin-/Workflowreview. Es ist ein ausschließlich dokumentarischer Nachtrag auf Evidencecommit `0dcfd51761480886c94e5b36b9f27f620e28b703` (Tree `984fc38cdf2d270f4f697e179736c4cd10a68eef`, 7.993 vorhandene Dateien). Keine vorhandene Evidenzdatei wird überschrieben.

## Maßgeblicher Stand

- Die drei Produktdateien bleiben am ursprünglichen Freeze `465eb8e570ef8ca79ef862a635ac526188ccc4eef875573e59deef998198efab` gebunden. Der PCM-Join liegt innerhalb der vorhandenen Java-Engine; keine neue Produktionsdatei oder Installationskopie ist nötig.
- Für die Erstintegration gilt das abgeleitete Manifest `f0f0e43979fb3c99c280bf1cffb39ea3f62388f84aa3521f8adee92bee01d791`. Nur die beiden unveröffentlichten Driver-Zielpfade wechseln nach `scripts/speech_contracts/`. Alle zehn Inhaltsblobs bleiben exakt identisch.
- Die originale Implementierungs-README wird unverändert als historischer Stand aufbewahrt. Ihre alten Direktaufrufe unter `scripts/tests` sind durch die dokumentierte Pfadtrennung und den strikten CI-Runner ersetzt. Maßgeblicher Aufruf: `python3 -B scripts/run_speech_jvm_contracts.py --output host-compile-evidence/speech`.
- Sämtliche zehn Produkt-/Test-/Fixtureblobs sind bereits separat gesichert. Dieses Dokumentpaket enthält deren Manifeste und Readbacknachweise, keine erneuten Produktdateien oder vollständigen Arbeitsbäume.

## Tatsächliche Ausführungen und Grenzen

Der erste Java-Versuch endet im Setup: `--release 17` wird von der installierten abgespeckten JDK-Umgebung nicht unterstützt. Originalprotokoll, Exitcode 5 und null ausgeführte Fälle bleiben erhalten.

Der zweite tatsächliche Java-Lauf kompiliert die vollständige Produktionsengine mit Source/Target 17 gegen die installierten JDK21-APIs. Er besteht mit 11 Fällen und 103 Java-Assertions. Die originale Compilerwarnung bleibt im Log. Die ONNX-Sessions, Tensoren und erzeugten PCM-Samples sind ausdrücklich synthetische Vertragsgrenzen; daraus folgt keine echte Modellsynthese, gehörte Aussprache oder Androidwiedergabe.

Die acht Kotlinfälle sind vorbereitet und lokal nicht ausgeführt. Ihre alten 23 Envelope- und 17 Lifecycle-Assertions sind keine zusätzlichen Testfälle. Der neue strikte Runner verlangt diese acht Kotlinfälle und die elf Javafälle vollständig, ohne Skips. Die unabhängige Runnerprüfung dokumentiert 19 eigene Python-Orchestrierungsfälle; diese Zahl wird nicht mit den noch ausstehenden 19 Sprachfällen vermischt.

Bs unveränderte Produktreview `48182d9beb47f09ae65c494a8960b8534df8b2df17ad2fe31e27e5e120828db2` fand im gelesenen Umfang keinen weiteren konkreten Blocker. Sie ist eine Quellenprüfung ohne erneute Testausführung.

Der zusätzliche Pin-/Workflowreview bestätigt unveränderte 50 historische Pins, die einzige neue 2020-Identität Native29080 und den verpflichtenden Runner nach tatsächlicher Android-Kompilierung. Die vier bereits von Root ausgeführten Pinverträge werden als solche erhalten. Kein neuer Android-, APK-, CI-Gesamt-, Audio- oder Veröffentlichungs-PASS wird vorweggenommen.

## Paketstruktur

- `../studio-english-word-audio-2e20-20261114/`: Original-README, ursprünglicher und abgeleiteter Quellfreeze, bestätigte Sourceblobs, tatsächliche Java-Originale, Quellen- und Installationsgrenzen sowie genauer Produktdiff.
- `../studio-english-word-audio-peer-review-20261114/`: Bs unveränderte Produktreview samt eigenem Manifest.
- `../host-native29080-pin-workflow-independent-review-20261114/`: die sechs ausdrücklich gelisteten Reviewbelege und ihr ursprüngliches Manifest.
- Dieser Ordner: Gesamtmanifest und Vergleich gegen den vollständig gelesenen Evidence-Baum.

Alle Uploadziele liegen ausschließlich unter `docs/evidence/`. Es werden keine Klassen-Caches, Modellgewichte, vollständigen Baseline-/Prepared-Verzeichnisse oder Git-Refs verändert. Jeder Text wird nach dem Blobupload vollständig als UTF-8 zurückgelesen und mit seinen unveränderten lokalen Bytes verglichen.
