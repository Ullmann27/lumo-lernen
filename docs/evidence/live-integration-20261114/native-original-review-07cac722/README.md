# Native-Originalprüfung des Host-Laufs 43586101225

Der Originalrun auf Host `07cac7225e2f7b6451665dfda9c38841f51c758b` und Native `71a4c1e2304b52005950b12490d070c286c45438` hat den vollständigen Native-Hauptblock und anschließend Live9 bestanden. Discovery wurde während einer laufenden Lernweltaufnahme unterbrochen. Der Gesamtjob endete als `cancelled`; APK-Build und Android-Abnahmen wurden nicht gestartet.

Dieser eigene Belegcheckpoint enthält ausschließlich Originalprotokolle, unveränderte API-Antworten und diese daraus abgeleitete Auswertung. Er verändert keine Produktionsdatei, keinen Native-Pin und kein Prüfbudget.

## Quellen

- [Vollständiger Originaljoblog](verify-and-build-original.log): Gitblob `c246b7ddce9d1b66db659a93b0af8abec539ee0d`, **1.370.502 UTF-8-Bytes**, SHA256 `fc687b374ca27e28632b11786ff26fb4eed916e4e9b0fe70d3bb72a064acbef1`.
- [Originaler C4-Runtimelog](connect-four-runtime-original.log): Gitblob `3cf536f314913709ed2f5f542bd3629fba9c291e`, **287.986 Bytes**, SHA256 `a5203d649dab1729a06de65e01a7e5cf886051c03bed757cbea0064821617d65`.
- [Run-Metadaten](original-run.json), [Job-Metadaten](original-jobs.json) und [Artefaktmetadaten](original-artifacts.json).
- [Strukturierte vollständige Auswertung](native-review.json) mit Originalzeilen, Zeitstempeln, Quellenblobs und der genauen Prüfgrenze.

Im Hauptlog belegen Zeilen 99–171 den tatsächlichen Host-Checkout. Zeilen 4293/4294 belegen Fetch und Checkout von Native 71a4. Die Auswertung verwendet ausschließlich diesen Lauf und dessen ersten Versuch.

## Bestätigte Ergebnisse

| Bestandteil | Tatsächlicher Originalnachweis |
| --- | --- |
| C4-Runtime | Return-Probe mit 21 Checks; Dart-/Godot-Zweiprozessgate erfolgreich, beide Exitcodes 0 |
| Native-Schritt 31 | SUCCESS, 11:03:00 bis 12:01:51 UTC, **58 Minuten 51 Sekunden** |
| Nextgen | Abschlussmarker für alle **52 Proben** in Zeile 10229 |
| Studio2020 | **17 echte PNGs, 3 Originalsidecars und 1 geprüfter Facialfilm**, Zeile 10228 |
| Bestehende Rastergruppen | Studio 24, Village 4, Puzzle-Menü 6 und Safe-Area 7; alle PASS, Zeilen 10224–10227 |
| Live | **9 Proben und 7 verifizierte Renderer-PNGs**, PASS um 12:03:02.8314009 UTC, Zeile 10398 |
| Live-Unterverträge | C4-Return 21, Wisp 14 headless und 18 gerendert |
| Discovery | **8 von 10 Proben abgeschlossen**; der vollständige 10/38-Abschluss wurde nicht erreicht |

Die einzelnen Rastergruppen sind Pflichten innerhalb des Runners; ihre Zahlen werden hier nicht zu einer ungeprüften Gesamtbildzahl zusammengezählt. Die wiederholten Marker durch die anschließende `grep`-Bestätigung zählen nicht als zusätzliche Probeläufe.

## Erstmals belegbare Dauer des vollständigen Nextgen52-Blocks

Der vorherige Action-Stage-Block meldete PASS um **11:20:25.6371834 UTC** (Zeile 8775). Die erste Godot-Ausgabe des anschließenden Nextgen-Runners folgte um **11:20:26.5019711 UTC** (Zeile 8776). Sein vollständiger PASS-Marker erschien um **12:01:51.6153084 UTC** (Zeile 10229).

Damit beträgt das beobachtete Fenster vom ersten Engineoutput bis zum Abschluss **41 Minuten 25,113 Sekunden**. Da der Runneraufruf zwischen dem vorherigen PASS und seiner ersten Engineausgabe beginnt, liegt die gesamte Aufrufdauer innerhalb **41:25,113 bis 41:25,978**. Das sind aus Originalzeitstempeln berechnete Grenzen, keine geschätzte Restlaufzeit.

Die vorherigen bestehenden Blöcke benötigten bis zu ihrem letzten PASS 17:25,637. Die erste vollständige Lernweltaufnahme innerhalb von Nextgen meldete alle 25 Bilder nach **10:18,970** zwischen ihrer ersten Engineausgabe (Zeile 9541) und ihrem PASS (Zeile 9635). Die lange Gesamtdauer des Native-Schritts ist damit durch erfolgreich ausgeführte zusätzliche Prüfungen nachvollziehbar.

## Discovery: genaue Grenze beim Abbruch

Vor dem Abbruch bestanden:

1. LearningWorld: 5.347 Checks.
2. LearningSharing: 1.811 Checks.
3. LearningStudio: 183 Checks.
4. GameHub: acht vorhandene native Routen und erhaltene Einstellungen.
5. VillageHost: tatsächlicher Host- und interner Einstieg samt unterschiedlichem Rückweg.
6. LearningWonder headless: 100 Checks.
7. LearningWonder mit X11-Renderer: 108 Checks.
8. GameHub-Capture: beide aktuellen Original-PNGs; PASS um 12:07:01.0716057 UTC.

Die neunte Probe, `learning_world_capture`, begann mit ihrer Engineausgabe um **12:07:01.3001490 UTC**. Bis zur Unterbrechung enthält der Originaljoblog **10 von 25 Screenshotmeldungen**. Zuletzt wurden `syllables-start` um 12:10:55.1307973 UTC und danach eine tatsächliche Spielaktion um 12:10:55.7407137 UTC protokolliert.

Die einzige GitHub-Abbruchmeldung steht in Zeile 10804 um **12:11:03.5742356 UTC**: `The operation was canceled.` Die Probe lief zu diesem Zeitpunkt erst rund **242,274 Sekunden** ihres unverändert 900 Sekunden langen Einzelbudgets. Ein Ablauf dieses Einzelbudgets ist nicht belegt. Die anschließende Wonder-Aufnahme mit elf PNGs und der vollständige Discovery-Replay mit 38 Bildern wurden nicht erreicht.

Die in dieser Desktop-Regression protokollierten VillageHostReady-Marker stammen aus ihrem eigenen Testkontext mit Slot 3. Sie werden ausdrücklich nicht als bereits durchgeführter Android-Dorf-Roundtrip ausgegeben.

## Fehler- und Ursachenprüfung

Im gesamten ursprünglichen Native-Zeitfenster vor der GitHub-Abbruchmeldung gibt es **null Treffer** auf die im JSON vollständig aufgeführten Engine-, Parser-, Assert-, Leak- und Probe-Timeout-Muster. Die üblichen Meldungen zu Compatibility-Renderer, VSync und nicht verfügbaren Forward+-Effekten bleiben unverändert im Original erhalten.

Das Workflowobjekt auf Host 07cac7 setzt für diesen Gesamtjob 90 Minuten. Der Job startete um 10:40:50 UTC; die Unterbrechung erfolgte kurz nach dieser Grenze bei weiterhin protokolliertem Fortschritt. Das stützt einen zu kurzen Gesamtjobrahmen. Der inspizierte Log benennt jedoch nur die Abbruchmeldung; er enthält keine eigenständige ausdrückliche Plattformannotation zur Timeoutursache. Diese Auswertung behauptet deshalb keine darüber hinausgehende gesicherte Ursache und leitet keinen Enginefehlerfix ab.

## Originalartefakt und verbleibende Abnahme

Der trotz Abbruch ausgeführte Upload war erfolgreich. Das originale Artefakt **14113137811**, `lumo-candidate-pinned-native-gameplay`, umfasst **201.481.571 Bytes** und hat SHA256 `84e8e465e16bc49c302b500f5b12dd81cf2dc03729f009f623576fc9833f4c05`. Die API bindet es an denselben Run und Host-Commit. Für diese Gegenprüfung wurde es nicht erneut heruntergeladen oder visuell nachgeprüft.

Offen bleiben im abgebrochenen Run der vollständige Discovery-Abschluss, APK-Build, reale Android-Dorf-/C4-/Update-Prüfungen und Delivery. Dieser Quellen- und Lognachweis erzeugt weder eine Gesamtfreigabe noch eine Messung physischer Android-FPS.
