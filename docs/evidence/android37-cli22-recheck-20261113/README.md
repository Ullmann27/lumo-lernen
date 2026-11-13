# Android17: gezielter CLI22-/AVD-Vergleich

Dieser Diagnosezweig basiert unverändert auf `e4ed59e226ab76c4d7accf174f1f05fc05089d87`. Er prüft eine konkrete offene Hypothese des tatsächlichen Emulatorabbruchs. Die vorher beobachteten SurfaceFlinger-/Systemserver-Abstürze und ENOSPC-Meldungen belegen weder die ursprüngliche AVD-Zielzeile noch eine alleinige CLI-Ursache.

## Tatsächlicher Ablauf des nächsten CI-Laufs

1. Originale SDK-Werkzeugversion, `source.properties` und Werkzeugdateihashes erfassen.
2. Dieselben API37.0-/google_apis-x86_64-Pakete verwenden; tatsächliche Image-Revision8 und Emulator37.2.13 binden. Mit den ursprünglichen Tools und der echten a421-`createAvd`-Funktion ein separates ungestartetes AVD erzeugen. Originalkonfiguration unverändert kopieren; Originalwerkzeuge und AVD bleiben erhalten.
3. Das feste offizielle Archiv `commandlinetools-linux-15859902_latest.zip` mit SHA256 `4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583` prüfen, installieren und die tatsächlich ausgeführte CLI22-Version verifizieren. Nur `cmdline-tools/latest` wird auf diese geprüften Werkzeuge umgestellt.
4. Dieselbe Original-Action erzeugt ihr eigenes neues AVD. Ziel, Image, CPU/RAM/Heap, gesamte Rohkonfiguration und spätere Hardware-/Diskdateien werden erfasst; keine Zielzeile oder Partitionsgröße wird umgeschrieben.
5. Der verbindliche Guard prüft CLI-/AVD-/Quellidentität nochmals vor dem originalen Keyevent und der App-Tour. Ein fehlgeschlagener Action-Prehook allein wäre keine Abbruchgrenze; deshalb liegt die verbindliche Prüfung im strikten Guard. Dessen bisherige Dienst-, PID-, Startzähler- und SDK-/Releaseprüfungen bleiben erhalten. Ressourcenaufnahme und Zusatzprüfung liegen innerhalb seines bisherigen120-Sekunden-Budgets.
6. Erst danach laufen dieselbe vollständige normale Tour und die ursprünglichen Learning-/Cards-Gates am unveränderten e3d-APK. Keine neue APK und keine Veröffentlichung in diesem Diagnosezweig.

## Lokale Prüfung

Acht neue Datei-/Identitätsgegenfälle und alle acht bisherigen Framework-/Actionfälle bestanden. Actionlint ist für Diagnose und finalen Studio-Workflow grün; 14 beziehungsweise45 Shellblöcke bestehen `bash -n`. Der finale API35-Aufruf sowie Compile-, Build-, Update- und Publisherjobs bleiben unverändert. Die neuen gemeinsamen Hilfsdateien sind in beiden Checkouts bytegleich.

`framework-contracts.tool-output.log` enthält den exakten Text der tatsächlichen Toolausgabe des ausgeführten Vertragslaufs, keinen wiederholten Testlauf; `local-validation.json` nennt diese Erfassungsgrenze. Alle lokalen SDK-/ADB-Gegenfälle sind ausdrücklich synthetische Parser- oder Prozessgrenzentests. Sie bestätigen noch keinen erfolgreichen Androidstart und keine APK-Freigabe.

Die offizielle CLI22-Datei wurde bereits im früheren echten SDK-Inventarlauf43476259207 geladen und gestartet. Die hier neue Installation, beide AVD-Konfigurationen und die tatsächliche Gerätebelegung müssen trotzdem erst im neuen Lauf beobachtet werden.
