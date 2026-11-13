# LUMO Studio: geprüfte Native-Quelle 803e und neue Android-Integration

Dieser Integrationsstand bindet die App an **Godot `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`**, Tree `dc24bfa8b3fac8812c88cfc8f8eab3af1479979c`. Die native Prüfung und die ausgewählte Bildsichtung sind abgeschlossen. **Der neue Host-/Android-Build wird erst aus dem Commit dieses Integrationsstands ausgeführt. Dieses Dokument behauptet noch keinen erfolgreichen neuen Android-Lauf oder freigegebenen APK-Download.**

Die vollständige [Modul- und Fähigkeitsübersicht](STUDIO_NEXTGEN_SCOPE.md) bleibt als zeitgebundene Inventur vom 13. November 2026, 23:10 UTC erhalten. Der nachstehende spätere Nachweis ersetzt dort ausschließlich den damals noch offenen Native-Abnahmestand. Offene Produktbereiche, insbesondere Gesicht/Lippenbewegungen, weitere 3D-Spielräume und die physische Fold7-Abnahme, werden dadurch nicht abgeschlossen.

## Warum eine neue Integration nötig ist

Der vorherige Host-Kandidat `31883868` mit Native `796b2818` baute erfolgreich, bestand aber seine API-35- und API-37-Cards-Prüfungen nicht. Zurück/Pause lagen teilweise unter Android-Systemleisten. Bei API 35 waren drei tatsächlich gesichtete Kartenbilder kein automatischer Pixel-/Gameplay-PASS: Der Ablauf stoppte bereits am OCR-Nachweis vor dem ersten Ziehen. API 37 führte zwei Ziehaktionen aus und scheiterte anschließend am Pause-Tap. Ein weiterer Androidlauf erreichte die Kreativspiele nicht, weil die sichtbaren Flutter-Portale keine anklickbare Semantikaktion anboten. Die Originale bleiben in [PR #475](https://github.com/Ullmann27/lumo-lernen/pull/475) erhalten.

Die gemeinsame native Randkorrektur liest die tatsächliche RenderView und Android-WindowInsets, verwirft überholte Antworten nach Größen-/Lebenszykluswechsel und aktualisiert die vorhandenen Szenenlayouts. Cards schreibt ausschließlich beruhigte, atomare Layoutbeobachtungen. Die Hostprüfung bindet Zustand, Layoutgeneration und echte Screenshots und berechnet die Kartenprojektion unabhängig. Die beiden zusätzlichen Semantikzeilen verbinden offene Portale mit ihrer vorhandenen Aktion. Schreibtrainer, Journal, Lernprofile, Regeln, Originalassets und Speicherformate werden dafür nicht neu aufgebaut.

Die kontrollierte Vorbereitung einschließlich Sammler und Dokumentation liegt im Vorgänger **`39ddc673577e31e76fb992a1b49ef67d1deee908`**. Der unabhängige [Abgleich aller 1.271 veröffentlichten Dateien der angefragten Quellverzeichnisse](evidence/studio-source-binding-1dfd-20261113/local-vs-published-source-summary.json) bestätigte den lokalen Source-Stand gegen `1dfd6e32`; die nachfolgenden fünf Dateien in 39dd sind ausschließlich Dokumentation. Das alte lokale Git-HEAD wurde nicht als aktuelle Quelle ausgegeben.

## Vollständiger neuer Native-Nachweis

Der [Lauf 43524051371](https://github.com/Ullmann27/lumo-godot/actions/runs/43524051371) bestand im **ersten Versuch** auf genau 803e. Erfolgreich sind die acht Pflichtjobs `learning-preview`, `gameplay`, `studio`, `new-worlds`, `touch-workshop`, `touch-treasure`, `touch-build`, `bundle-evidence` sowie die anschließende Archivierung. Alle 13 weiteren am gleichen Head sichtbaren Workflow-Läufe meldeten ebenfalls Erfolg; das ist ein Statusbefund, keine erneute manuelle Sichtung ihrer sämtlichen Einzelartefakte.

Der zuvor fehlgeschlagene 20fd-Lauf bleibt fehlgeschlagen. Seine zwei veralteten Python-Fixtures erwarteten elf Studio-Aufrufe und 30 Bilder. Der enge Testfix übernimmt die tatsächlichen 16 Aufrufe und 37 Bilder, behält die bisherigen Fälle und ergänzt negative Prüfungen. Produktionscode, Harness, Zeitbudgets und Schwellen wurden für diesen Fix nicht verändert. Erst der neue vollständige 803e-Lauf begründet die aktuelle Native-Abnahme.

| Originalbindung | Wert |
| --- | --- |
| Artefakt | `14085523056`, `lumo-studio-2019-native-evidence` |
| Original-ZIP | 199.274.727 Bytes |
| SHA256 | `3b4fcac817efd007797658117f3c62185e3834cbdd624de02d6072fce688a798` |
| Integrität | CRC aller 4.447 ZIP-Mitglieder bestanden |
| Capture-Quellen | Fünf Source-/Dirty-Gruppen: exakt 803e, keine getrackten Quelländerungen |
| Tree-Stempel | Alle vier vorhandenen Stempel entsprechen `dc24bfa8…`; die Nextgen-Gruppe besitzt keinen eigenen Tree-Stempel |
| Studio-Teil | 16 bestandene Gates, 37 PNGs und vier Layout-/Messsidecars |
| Vergleich frühes Studio / Gesamtarchiv | Alle 37 Bilder und vier Sidecars bytegleich |

Das [veröffentlichte Originalarchiv](https://github.com/Ullmann27/lumo-godot/releases/download/studio-evidence-803e7a626ea6ef0aeeda9c37010e844033d3a8e3-14085523056/native-evidence.zip) weist in den tatsächlichen Release-Metadaten dieselbe Bytezahl und denselben Digest auf. Die für den Review heruntergeladenen Originalbytes stammen aus dem Actions-Artefakt; eine zusätzliche zweite Downloadprüfung des öffentlichen Release-ZIPs wird nicht behauptet. [Originalmetadaten, Inventar und Quellenprüfung](evidence/studio-native-803e-acceptance-20261113/README.md) sind getrennt von der Bildsichtung dokumentiert.

## Tatsächlich gesichtete Produktionsbilder

**32 aktuelle Originalbilder** wurden einzeln geöffnet: 19 durch den Integrator und 13 durch den zweiten prüfenden Agenten. Jeder ausgewählte Bildinhalt stimmt mit dem neuen Gesamtarchiv überein. Der [neue Receipt](../config/studio-2019-visual-review.json) enthält die einzelnen Befunde, Abmessungen und SHA256-Werte sowie Workflow-/Artefaktbindung. Der Recorder validierte ihn gegen alle acht Pflichtjobs und die sauberen Capture-Quellen, bevor der Pin aktualisiert wurde.

| Produktionsbereich | Gesichtete Bilder |
| --- | ---: |
| Lernen: Division und Hunderterübergang | 4 |
| Jump | 3 |
| Bauwelt | 4 |
| Siedlung | 1 |
| Garage/Werkstatt | 2 |
| Cards | 5 |
| Rhythm Party | 1 |
| Puzzle einschließlich sechs Menü-/Modusbildern | 9 |
| Schatzsuche | 3 |
| **Gesamt** | **32** |

Die Aufnahmen zeigen die echten Produktionsszenen. Die Division stellt in einer schmalen Ansicht zunächst drei gleich große Einsergruppen und neun verbleibende Würfel dar; die Abschlussansicht zeigt drei Vierergruppen. Die beiden Hunderteransichten zeigen 180 + 50 = 230 mit lesbarer extrudierter Beschriftung. Cards besitzt vollständig sichtbare Randaktionen in den neuen Insets-Fixtures. Die sechs Menübilder unterscheiden Dreh- und klassischen Puzzlemodus nach dem tatsächlichen Menüstarter.

Sichtbare Grenzen werden ausdrücklich erhalten: Einige untere oder seitliche Menüeinträge benötigen Scrollen; Nachbarzeilen sind an Scrollkanten angeschnitten. Treasure-Zähler umbrechen, das große Hinweisfeld verdeckt in einer Fixture einen Teil der Figur, und ein Bauwelt-Hintergrundtitel ist im Portrait verkürzt. Diese Punkte werden nicht als gleichzeitig vollständig sichtbare Inhalte dargestellt. Die ausgewählten maßgeblichen Aktionen bleiben lesbar. Standbilder belegen keine vollständige manuelle Spielsitzung, Eingabelatenz oder Bildrate.

## Erforderliche Prüfungen für das neue APK-Paar

Der neue Host-Commit muss seine eigenen vollständigen Build-/Quellen-/Signatur-/PCK-Prüfungen sowie API 35, Android 17/API 37, die 2017→2019-Updateprobe und das zusätzliche verpflichtende Creative-Android-Gate bestehen. Alte grüne Teilprüfungen des 318-Kandidaten ersetzen diese Läufe nicht. Die aktuellen Android-Gates verlangen unter anderem echte Cards-Layoutdaten, Kartenfront-/Zustandsprüfungen, Pause/Fortsetzen und frische Flutter-Rückkehrbilder. Die Creative-Sequenz muss die vier tatsächlichen Native-Einstiege und deren vorgeschriebene Aktionen erreichen; der neue Jump-Mitschnitt benötigt anschließend eine ausdrückliche Sichtprüfung.

Die bisherige Updatefixture enthält ein Kind. Sie ist kein Nachweis sämtlicher Zwei-Kind-/Journal-/Altspielstand-Migrationen. Bestehende lokale Gegenfälle bleiben dokumentiert, ersetzen aber keine nicht ausgeführten Geräteszenarien.

Der [lesende Gerätesammler](../tools/android_qa/FOLD_DEVICE_CAPTURE.md) ist implementiert und mit 19 synthetischen Tests geprüft. Er wurde nicht auf einem Fold7 ausgeführt. **Native FPS, GPU-Framezeit und Touchlatenz bleiben `NOT_MEASURED`; stabile 60 FPS, Temperaturverhalten und das Steuergefühl auf dem Samsung Galaxy Z Fold7 sind noch nicht belegt.** Die Linux-Rendererbilder und die Medienbildraten früherer Filme werden nicht dafür verwendet.

Main wird durch diese Integration nicht verändert. Die neue Quellenkombination wird auf dem Studio-Arbeitszweig geprüft; dieses Dokument bewirkt keine Zusammenführung oder pauschale Fertigmeldung des gesamten Masterauftrags.
