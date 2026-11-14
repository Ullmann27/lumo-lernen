# Originalarchive für den C4-Publisher

Isolierte Ergänzung vom 14. November 2026 auf Host-Basis
`86445f53af5d573549fc8cf03405261611f3cb7e`. Genau zwei neue Quellen;
bestehende Release-/C4-Prüfer, Workflows, Pins und Originalverzeichnisse
wurden nicht geändert.

## Pflichtaufruf vor C4-Prüfung und Veröffentlichung

```bash
python3 scripts/verify_studio_artifact_originals.py \
  --source-sha "$SOURCE_SHA" \
  --build-run "$BUILD_RUN_ID" \
  --metadata-dir proofs/c4-metadata \
  --api35 proofs/tour \
  --api37 proofs/android17 \
  --runtime proofs/native-runtime \
  --out dist/C4-ARTIFACT-ORIGINALS.json
```

`SOURCE_SHA` und `BUILD_RUN_ID` sind die tatsächlichen aktuellen
Kandidatenwerte. `run.json` und `artifacts.json` müssen die originalen aktuellen
GitHub-Antworten sein. Die Artefaktliste muss vollständig sein
(`total_count == len(artifacts)`). Andere Artefakte desselben Runs dürfen in
dieser Liste stehen; ausgewählt werden genau diese drei eindeutigen Namen:

- `lumo-studio-2020-android-tour`
- `lumo-studio-2020-android-17-tour`
- `lumo-candidate-pinned-native-gameplay`

Die bereits mit `actions/download-artifact` bereitgestellten Verzeichnisse
müssen vollständig sein. Ausgelassene Shadercaches, zusätzliche lokale
Prüfdateien oder bereits hineingeschriebene Ergebnisdateien werden als
abweichender Bestand abgelehnt. Der neue Ergebnisbericht liegt deshalb
außerhalb dieser drei Verzeichnisse.

Der Linux-Publisher benötigt Python 3.11 oder neuer, `gh` und die bereits
vorgesehene Berechtigung zum Lesen seiner Actions-Artefakte. Der Prüfer hat
keine zusätzlichen Python-Abhängigkeiten. Er verwendet keine Ausgabe von
Tokens oder Weiterleitungs-URLs; auch GitHub-CLI-Fehlerantworten werden nicht
in den Bericht übernommen.

## Tatsächlicher Prüfpfad

Jedes Original wird nacheinander mit dem festen Repository und der geprüften
Artefakt-ID über `gh api .../actions/artifacts/<id>/zip` in ein eigenes
temporäres Verzeichnis geladen. Nach exakter Größen- und SHA-256-Prüfung
gegen GitHub-Metadaten werden alle ZIP-Einträge vollständig gelesen und
dadurch ihre CRCs geprüft. Jede reguläre Datei wird blockweise mit der bereits
vorhandenen Originaldatei verglichen. Es wird nichts entpackt.

Fehlende oder zusätzliche Dateien, doppelte ZIP-Pfade, Traversal,
absolute/mehrdeutige Pfade, Symlinks, Spezialdateien, verschlüsselte Einträge
und Datei-/Verzeichnis-Kollisionen führen zum Fehler. Verzeichnisse und
Dateien werden ohne Folgen von Symlinks geöffnet. Der Dateibestand wird vor
und nach dem Vergleich erfasst; Änderungen während des Lesens werden
abgewiesen. Das temporäre Originalarchiv wird auch nach einem Fehler vom
zugehörigen `TemporaryDirectory` entfernt.

Erst nach allen drei vollständigen Erfolgen wird ein neuer Bericht erstellt.
Er bindet Quelle, Run/Versuch, Original-Metadatendateien, drei
Artefakt-IDs/-Namen/-Digests/-Größen, geprüfte Dateizahlen und den Hash der
sortierten vollständigen Datei-/Größen-/SHA-Liste. Eine vorhandene
Ergebnisdatei wird nicht überschrieben.

Dieser Prüfer belegt Archiv-/Dateiidentität. Spielzüge, Androidversionen,
Signatur-/APK-/PCK-Verträge und der Zweiprozesslauf bleiben die zusätzlichen
Pflichtprüfungen des bestehenden C4-Publishers.

## Lokal ausgeführter Nachweis

```bash
python3 -W error::ResourceWarning -B -m unittest discover \
  -s scripts/tests -p test_studio_artifact_originals.py -v
```

Tatsächlich **20/20 Tests PASS, 0 Skip**, unittest 0,023 Sekunden. Die Tests
verwenden nur kleine synthetische ZIPs und gemockte Downloads. Sie prüfen
unter anderem CRC-Schäden trotz passendem Archivhash, gleich große geänderte
Dateien, fehlende/zusätzliche Dateien, Pfad-/Symlink-Angriffe, falsche
Quellenmetadaten, Downloadfehler und die Bereinigung ausschließlich eigener
temporärer Dateien. Es wurde kein echtes großes Artefakt heruntergeladen,
keine APK geöffnet und keine Android- oder Publisher-Freigabe behauptet.

Die unveränderten Rohprotokolle, Ausführungsparameter und Quellenhashes liegen
unter `evidence/`. Das Quellenmanifest listet ausschließlich den neuen Prüfer
und seinen Test; das separate Belegmanifest enthält diese Anleitung und die
kleinen Prüfberichte.
