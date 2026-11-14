# Strikter Speech-JVM-Anschluss

Stand: 2026-11-14, Hostbasis `2e20f5f24cee7a696296e6bea5618cc130a40ce2`. Dieses Paket ergänzt zwei neue Pythondateien. Es ändert keine Produktdatei, keinen Workflow und keinen Native-Stand.

## Tatsächlicher Anschluss

Root fügt unmittelbar nach dem erfolgreichen `bash scripts/compile_android_host.sh` in den bestehenden Host-Compile-Job genau diesen Aufruf ein:

```bash
python3 -B scripts/run_speech_jvm_contracts.py --output host-compile-evidence/speech
```

Der vorhandene Artefaktpfad `host-compile-evidence/` enthält danach Toolchainprotokoll, getrennte originale Java-/Kotlinlogs, Einzelergebnisse und den abschließenden Quellenvergleich. Der Runner überschreibt keinen bereits gefüllten Belegordner.

Er verlangt zuerst die erfolgreiche tatsächliche Android-Kompilation desselben ausgecheckten Commits und überprüft deren vier Speech-Klassendateien mit Größe, SHA256 und JVM-Magic. Bei einem Same-repo-Pull-Request entspricht die Quelle dem originalen `pull_request.head.sha` aus `GITHUB_EVENT_PATH`, passend zum vorhandenen Studio-Checkout. Bei Push und manueller Ausführung gilt `GITHUB_SHA`.

Die Gradle-Version und der bestehende Cachepfad werden aus der tatsächlich vorhandenen `gradle-wrapper.properties` ermittelt. Der Runner startet ausschließlich die bereits installierte passende Distribution, direkt mit `--offline`, ohne Wrapper-Bootstrap, Installation oder globalen Gradle-Ersatz. Fehlende oder mehrdeutige Distributionen beziehungsweise Compiler brechen ab. Eine temporäre reine Gradle-Abfrage bestätigt die wirklich gestartete Distribution, deren Kotlinbibliotheken und das verwendete JDK. Die Compiler-JARs werden vor und nach dem Lauf gehasht.

## Ein einziger Sprachvertragslauf

Die beiden unveränderten Driver gehören zu As abgeleitetem Manifest `path-separated-v2/source-upload-manifest.json`, SHA256 `f0f0e43979fb3c99c280bf1cffb39ea3f62388f84aa3521f8adee92bee01d791`. Ihre Ziele sind ausschließlich `scripts/speech_contracts/test_english_lesson_speech.py` und `scripts/speech_contracts/test_learning_english_speech_lifecycle.py`. Die alten unveröffentlichten Top-Level-Ziele unter `scripts/tests/` werden nicht integriert. Der Runner lehnt eine solche zusätzliche Kopie ausdrücklich ab.

Die Java-Gruppe umfasst genau elf Fälle. Die Kotlin-Gruppe umfasst genau acht Fälle: die unveränderten ursprünglichen 23 Envelope- und 17 Lifecycle-Assertions in zwei getrennten Mainklassen sowie sechs neue EN/DE-Szenarien. Beide Gruppen müssen ohne Fehler, Skip oder erwarteten Fehler enden; vollständige eindeutige Testlisten und originale Abschlussmarker sind erforderlich. `REQUIRE_ALL_TESTS=true` wird zwingend gesetzt. Die neue allgemeine Python-Testdatei dieses Pakets führt nur Orchestrierungsgrenzen aus, keine der 19 Sprachprüfungen.

Die einzige Original-WAV-Fixture bleibt in As Manifest unter `scripts/tests/fixtures/learning_english_speech/apfel-original.wav`, SHA256 `39aba71e80a9230d832f038630eaff8fa0fc0c5eae104581ce487bce9ebbd586`. Hier wird keine zweite Datei hinzugefügt. Die historischen Kotlinquellen und die WAV werden zusätzlich fest auf ihre ursprünglichen SHA256-Werte gebunden.

## Tatsächlich ausgeführte lokale Prüfung

`evidence/runner-boundaries-final.log` dokumentiert 19/19 neue reine Python-Orchestrierungsfälle, 0 Skip, 0,486 s, Exit 0. Die Quellenhashes waren vor und nach dem Prozess identisch. Die Fälle prüfen unter anderem fehlende und mehrdeutige Compiler, fremde Klassen-/Quellbindungen, den PR-Head statt des Merge-Commits, abgeschnittene oder doppelte Testlisten/Marker, Skip-Ablehnung, Prozessfrist samt erhaltenem Originalstdout und den Discovery-Ausschluss der dedizierten Sprachmodule. Die kleinen JAR-/Klassen-Fixtures dieser Tests sind ausdrücklich synthetische Formatgrenzen und keine ausführbare Kotlininstallation.

Der vorherige 17er-Orchestrierungslauf bleibt unverändert erhalten. Danach wurde der konkrete PR-Checkout-Unterschied erkannt, mit zwei Gegenfällen ergänzt und der dokumentierte abschließende 19er-Lauf ausgeführt. Es gab keinen lokalen Gradle-/Kotlin-Lauf, keine neue Spracherzeugung und keine Androidwiedergabe. As tatsächliche Java-11/103-Prüfung und deren ursprünglicher JDK-Abbruch bleiben in As eigenem Paket. Die erste vollständige Ausführung der unveränderten 23/17-Kotlinverträge und der sechs neuen Szenarien ist Aufgabe der vorhandenen CI-Toolchain.
