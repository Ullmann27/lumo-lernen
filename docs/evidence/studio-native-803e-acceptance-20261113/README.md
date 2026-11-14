# Native 803e: technische CI- und Archivabnahme

Der tatsächliche Lauf **43524051371**, Attempt **1**, ist auf **803e7a626ea6ef0aeeda9c37010e844033d3a8e3** vollständig erfolgreich. Alle acht Pflichtjobs und der zusätzliche Archivjob sind bestanden. Der Native-Branch zeigt nach Abschluss weiterhin exakt auf diesen Commit. Tree: `dc24bfa8b3fac8812c88cfc8f8eab3af1479979c`.

## Originalarchiv und Quellbindung

Artefakt **14085523056**, **199.274.727 Byte**, SHA-256 **`3b4fcac817efd007797658117f3c62185e3834cbdd624de02d6072fce688a798`**. Die CRC aller **4.447 ZIP-Mitglieder** wurde gelesen und geprüft. Fünf Source-Stempel stimmen mit dem aktuellen Commit überein, fünf Dirty-Stempel sind leer. Die vier vorhandenen Tree-Stempel sind korrekt; der bisherige Nextgen-Harness erzeugt keinen zusätzlichen Tree-Stempel.

Die ursprüngliche ZIP liegt unter `/workspace/scratch/5987865ae883/qa/studio-native-803e-original.zip`. Shadercaches wurden nicht vollständig ausgepackt. Die öffentliche Archivdatei besitzt gemäß den tatsächlichen Release-Metadaten dieselbe Bytezahl und denselben SHA-256-Digest wie das Original; der erfolgreiche Archivjob führt zusätzlich seinen strikten Original-/Public-Vergleich aus. Dieser Agent hat keine zweite öffentliche ZIP-Kopie heruntergeladen.

## Tatsächliche Ergebnisse

Die originalen Ergebnistabellen enthalten **25 erfolgreiche Nextgen-Proben**, **16 erfolgreiche Studio-Proben** sowie **je zwei erfolgreiche Touchläufe** für Werkstatt, Schatzsuche und Bauwelt. Der zuvor fehlgeschlagene Orchestrierungsvertrag besteht im neuen tatsächlichen CI-Job mit **8 Tests in 14,293 Sekunden**.

Alle **37 Studio-PNGs**, **drei Cards-Rohlayouts** und der gemeinsame Mobile-Bericht mit **15 Touchflächen** sind originalgebunden. Sämtliche **41 frühen Studio-Belegdateien** stimmen mit den entsprechenden Mitgliedern des vollständigen Gesamtarchivs überein. Die **32 geplanten Produktionsbilder** liegen für Root/B unter `selected-originals/`; `review-plan-extraction.json` bindet jedes Bild an den tatsächlichen Gesamtartefakt-Hash. Dieser technische Prüfschritt hat die Bilder nicht visuell freigegeben. Technische Bewegungsszenen werden nicht als Produktionsmodul ausgegeben.

Eine einmalige exakte Commit-Abfrage zeigt zusätzlich **13 weitere abgeschlossene erfolgreiche Workflows**, insgesamt 14 einschließlich Studio. Diese weiteren Einträge sind Statusbeobachtungen; ihre Inhalte wurden hier nicht erneut geprüft.

## Grenzen und Recorder-Eingaben

Dies ist keine Android-, Fold7- oder Geräte-FPS-Freigabe. Die neuen Safe-Area-Fälle sind ausdrücklich als Plattformrand-Fixtures gekennzeichnet. Reale Android-Integration bleibt ein eigener Nachweis.

`record-input-paths.json` nennt die tatsächlich geprüften lokalen Werte für `--archive`, `--artifact-metadata`, `--workflow-metadata` und `--jobs-metadata`. Root erstellt die visuelle Auswahl erst aus den tatsächlichen Sichtprüfungen. Dieser Agent hat weder Recorder noch Pin-/Receipt-/Branchänderungen ausgeführt.
