# Android 17: begrenzte Frameworkprüfung vor dem originalen Keyevent

Dieser isolierte Folgecheck baut keine APK. Er verwendet weiterhin genau die ursprüngliche e3d-APK und ihren nativen Stand 76980. Die tatsächlichen Android-Ergebnisse dieses Folgechecks stehen noch aus.

## Konkreter Ausgangsbefund

Der originale API37-Job [132073879662 / Run 43480051009](https://github.com/Ullmann27/lumo-lernen/actions/runs/43480051009/job/132073879662) des Prüfercommits `21df16b1278e5294a225f796e599d8bb0155e9f5` installierte die verfügbaren Pakete `android-37.0` erfolgreich und startete Emulator 37.2.13.0. Um 18:14:08 UTC meldete `sys.boot_completed` den Wert `1`. Unmittelbar danach scheiterte der originale `input keyevent 82` mit fehlendem Inputdienst und Exit 20; auch der Settingsdienst war in einem parallel ausgeführten Emulatorbefehl nicht verfügbar. Die Action beendete daraufhin den Emulator. Der Tourrunner und die Appinstallation wurden nicht erreicht.

Das Originalartefakt `14063879036` enthält zehn Vorabdateien, 8.109 Bytes, SHA256 `edace3ce229d45b04119d5f9f57dca3692103b9cdb7b2e01de499b47e2d9b4db`. Das vollständige gespeicherte Joblog umfasst 221.394 Bytes, SHA256 `385aedab2befb39d6d5e6e759894390d697f25355ca3261a7ed90a4cd2ec92df`. Diese Originale bleiben unverändert. Ohne Android-Logcat, PID-Serie und Startzähler lässt sich aus ihnen ein Start-Rennen nicht sicher von einem Systemserverausfall unterscheiden. Die detaillierte Quellenbindung steht in [original-failure-analysis.json](original-failure-analysis.json).

## Eng begrenzte Änderung

Die originale [Action am Commit a421e438](https://github.com/ReactiveCircus/android-emulator-runner/tree/a421e43855164a8197daf9d8d40fe71c6996bb0d) hat keinen Hook zwischen ihrer Bootprüfung und dem ersten Keyevent. Der neue Workflow checkt deshalb genau diese Action separat aus. Abhängigkeiten, Lizenz und übrige Quellen bleiben erhalten; es gibt keine neue Dependencyinstallation und keinen TypeScript-Neubau.

Der Preparator prüft den echten Git-Commit, einen sauberen Action-Checkout und sechs exakte Dateihashes. Er fügt genau einen wartenden Aufruf zwischen `waitForDevice` und `input keyevent 82` ein, übereinstimmend im TypeScript und im tatsächlich ausgeführten, bereits versionierten JavaScript. Die Änderungen tragen einen sichtbaren Herkunftshinweis. Das ursprüngliche `LICENSE` bleibt bytegleich erhalten; es enthält Apache License 2.0, während das ebenfalls unveränderte upstream `package.json` die abweichende Angabe MIT enthält.

Die Zusatzprüfung verwendet unverändert das echte SDK-adb und dieselbe Emulator-ID. Es gibt keinen adb-Wrapper, keine gefälschte Bootproperty, keine übersprungenen Einstellungen und keinen verschluckten Keyeventfehler. Sie verlangt:

- tatsächliches SDK 37, Release 17 und einen nichtleeren Fingerprint;
- Bootproperty `1`, eine konsistente Systemserver-PID und einen konsistenten Startzähler;
- registrierte Input-, Settings-, Activity-, Package- und Window-Dienste;
- erfolgreiche echte Leseaufrufe des Settingsproviders, Android-Paketpfads und Window-Managers;
- mindestens drei vollständige erfolgreiche Beobachtungen über mindestens zehn Sekunden. Ein während dieser Prüfung beobachteter Wechsel der Systemserver-Identität führt zum Fehler.

Das zusätzliche Budget beträgt maximal 120 Sekunden. Der originale Boottimeout von 300 Sekunden bleibt erhalten. Ein weiterhin fehlender Dienst führt zum Fehler und zum originalen Action-Cleanup. Die vorhandene Vorab-Hook startet einen separaten, auf 450 Sekunden begrenzten Roh-Logcat-Mitschnitt einschließlich Crashbuffer vor dem Emulatorstart. Jeder Guardaufruf speichert vollständige stdout-/stderr-Bytes, Exitcode, Timeout und Zeitpunkte; PID-, Dienst- und Startzählerbeobachtungen bleiben im Ergebnis erhalten. Der Mitschnitt wird vor der Tour oder im verpflichtenden `always()`-Schritt beendet. Das finale Manifest bindet die Original-/Patchhashes, den tatsächlichen Prüfercommit, den ausführenden Workflow und die separat deklarierte APK-/Nativequelle.

Der Startpfad ist ohne hart codierte e3d-Identität im Preparator auch für den späteren Studio-API37-Matrixjob nutzbar. Nur dieser Diagnoseworkflow deklariert e3d/76980 als unveränderte APK-Quelle. Die eigenständige ursprüngliche APK-Prüfung verifiziert weiterhin die realen Binärbytes; das Patchmanifest ersetzt sie nicht.

## Tatsächlich ausgeführte lokale Prüfungen

[readiness-contracts-no-env.log](readiness-contracts-no-env.log) enthält den aktuellen Lauf mit acht bestandenen Tests, null übersprungenen Tests, Exit 0 und 0,468 Sekunden. Die Umgebungsvariable `LUMO_ACTION_TEST_SOURCE` war ausdrücklich entfernt. Standardmäßig verwendet die Testsuite sechs bytegenau gepinnte upstream Dateien inklusive unveränderter Original-Lizenz unter `scripts/tests/fixtures/android_emulator_runner_a421/`; sie benötigt weder Netzwerk noch einen zusätzlichen Checkout. Eine ausdrücklich gesetzte alternative Quelle wird weiterhin gegen alle sechs exakten Hashes geprüft. Dadurch funktionieren auch die bestehenden vollständigen Testsuite-Aufrufe und `scripts/portable-android.sh` ohne neue Vorbedingung. Herkunft und Hashes stehen in der Fixture-README. Der frühere Lauf mit externem Fixture-Checkout bleibt unverändert als [readiness-contracts.log](readiness-contracts.log) erhalten. Sie prüfen fehlende Dienste trotz Bootwert `1`, einen nicht lesbaren Settingsprovider, einen Systemserverwechsel, falsches Android-SDK, den vollen Stabilitätszeitraum und einen echten Subprozess-Timeout mit unverändert gespeicherten stdout-/stderr-Bytes.

Der Integrationsvertrag führt das exakte originale `lib/main.js` und den exakt gepatchten Manager unter Node aus. Nur SDK-/adb-Ausführung wird durch einen ausdrücklich synthetischen Aufrufrekorder ersetzt. Er bestätigt die Reihenfolge Guard → originaler Keyevent → drei ursprüngliche Einstellungen sowie das originale Emulator-Cleanup bei Erfolg, Guardfehler und Keyeventfehler. Derselbe Vertrag schlug mit dem unmodifizierten upstream Manager fehl: [original-action-control-red.log](original-action-control-red.log). Dieser Kontrolllauf fand vor der anschließenden Änderung des Fixture-Standardpfads statt; seine Assertions blieben unverändert. Das ist kein tatsächlicher Android-Lauf.

Actionlint 1.7.12 endet mit Exit 0; alle elf tatsächlichen Shellblöcke bestehen `bash -n`; drei Pythondateien lassen sich parsen. Zehn ursprüngliche Prüf-, Workflow- und Identitätsdateien sind unverändert gegenüber 21df. Die Einzelbelege stehen in [local-validation.json](local-validation.json).

## Noch erforderlicher echter Lauf

Der neue Branch `chatgpt/lumo-android17-framework-recheck-20261113` startet nur API37. Der separate API35-Lauf wird weder wiederholt noch verändert. Nach erfolgreicher Frameworkprüfung bleiben die vollständige originale Tour, die Studio-Lern-/Cardsflächen und alle bisherigen Identitäts-, SDK-/Release- und Oberflächengates zwingend. Das Diagnoseartefakt heißt `lumo-2019-android37-framework-recheck-<run>-<attempt>`. Es gibt keinen Publisher, keine neue APK und keine Produktänderung.

Ein lokaler Vertrags-PASS ist keine Android-Freigabe. Erst die kommenden Originalmessungen können zeigen, ob der Frameworkzustand stabil wird und ob die unveränderte App unter Android 17 alle bisherigen Gates besteht. Physische Fold7-Leistung, Wärme und 60 FPS sind damit nicht gemessen.
