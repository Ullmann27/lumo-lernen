# Host workflow guard repair — 2026-11-13

Dieser Pack bindet die gezielte Reparatur eines bestehenden Workflow-Vertragstests an die unveränderten Originalprotokolle. Basis ist Host `f80fe6b3d6a3c58c89f8507853dcbfc15a84525e`, Tree `bc925bfebb77fa58ae4b82b93204906ae9265172`, mit genau einem Testpatch.

## Ergebnis und Änderung

Der ursprüngliche Gesamt-Gate führte 409 Tests aus und scheiterte an sieben Subfällen desselben Tests. Dieser las aus der tatsächlich gefalteten YAML-Bedingung nur `>-` und erzeugte damit einen Python-Syntaxfehler. Die gezielte Red-Reproduktion enthält dieselben sieben Fehler.

Der Patch liest die vollständige echte Bedingung bis `runs-on` und glättet ihre Zeilenumbrüche, entsprechend den vorhandenen Lesemustern im Repository. Alle sieben ursprünglichen Branch-Fälle bleiben bestehen. Vier weitere Fälle decken die tatsächlich vorhandenen 2019-Zweige Graphics-Producer und Integration jeweils als PR und manuelle Ausführung ab. Workflow und Branchschutz wurden nicht geändert.

Die gezielte Grünprüfung besteht mit elf Branch-Fällen. Anschließend besteht der vollständige bestehende Gate mit **409 Tests, null Fehlern und null übersprungenen Prüfungen in 97,705 Sekunden**. Die 1.184 erfassten Quellfingerprints sind während dieses Laufs unverändert. Gradle 9.1.0, Flutter 3.44.9 und Java 21 waren bereits installiert; Toolchain-Binaries sind nicht Bestandteil dieses Packs.

## Inhalt und Integrität

- `red/`: ursprünglicher vollständiger 409er-Fehllauf, originales Laufmanifest sowie Quellen vor und nach dem Lauf.
- `targeted/`: gezielte Red-/Green-Originalprotokolle samt ursprünglichen Laufmetadaten.
- `green/`: vollständiger 409er-Erfolgslauf, originales Laufmanifest sowie Quellen vor und nach dem Lauf.
- `source/` und `workflow-guard.patch.gz`: exakte Testquellen vor/nach der Reparatur und der vollständige Patch.
- `flutter-source-reuse.json`: alle zwölf zuvor geprüften Produkt-/Testdateien, die identischen `lib`-/`test`-/`assets`-Git-Bäume und beide Pubspec-Blobs zwischen `732056af52826920e4228fc9e68e188cc8f27a82` und der f80-Basis. Beide Digests des früheren Flutter-Originalprotokolls wurden ebenfalls geprüft. Die damaligen 55 bestandenen Flutter-Tests wurden nicht erneut ausgeführt.
- `toolchain.json` und `original-handoff.json`: unveränderte ursprüngliche Werkzeug- und Übergabemetadaten.

`manifest.json` bildet jeden archivierten Eintrag auf seinen ursprünglichen relativen Pfad ab und nennt Originalgröße, Original-SHA-256 sowie Größe und SHA-256 der gespeicherten Datei. Alle gzip-Dateien sind verlustfrei und wurden nach dem Schreiben vollständig dekomprimiert und byteweise mit dem Original verglichen. Die Original-Laufmanifeste behalten ihre damaligen Dateinamen und Scratch-Pfade; die Paketzuordnung erfolgt über dieses Manifest. Die aufgeführten Pack-Dateien ohne gzip sind unveränderte Originalbytes, ausgenommen diese README und der neue Paketindex.

Der Nachweis betrifft Host-Verträge und Quellidentität. Er erzeugt keine Native-/Bildfreigabe, keinen neuen Receipt und keine APK-Abnahme. Die drei Identitätsdateien behalten den vorläufigen b5bc-Pin; Root übernimmt den Commit.
