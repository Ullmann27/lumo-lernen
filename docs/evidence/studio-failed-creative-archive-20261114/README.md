# Einmaliges Archiv des fehlgeschlagenen Creative-Originalbelegs

Stand: 14. November 2026. Dieser isolierte Entwurf wurde noch nicht auf GitHub ausgeführt. Er ändert keine Produktquelle und ersetzt keine Abnahme.

## Exakt gebundener Originalbeleg

| Merkmal | Unveränderte Identität |
| --- | --- |
| Repository | `Ullmann27/lumo-lernen` |
| Originalrun / Versuch | `43530667812` / `1` |
| Originaljob | `132269951369`, `Android API 35 additional creative gameplay`, **failure** |
| Hostquelle | `4ab96666f954baf258422d6ed277fc297b7ddeef` |
| Nativequelle | `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` |
| Originalartefakt | `14092241868`, `lumo-studio-2019-creative-android` |
| Originalgröße | 526.570.745 Byte |
| Original-SHA256 | `bd1660a6032c9adba051f209ab3979ea1888d03ffeb902bd0403d3f813a61d40` |

Die echte abgeschlossene REST-Antwort ist unter `validation/original-metadata/` gesichert. Der Jobdatensatz enthält `run_attempt: 1` und den vollständigen Host-SHA; frühere reduzierte Connectoransichten ließen diese Felder weg.

## Ausführung und Erhaltung

Die einzige neue Workflowdatei ist `.github/workflows/lumo-studio-failed-creative-archive.yml`. Sie startet nur auf `chatgpt/lumo-studio-evidence-archive-20261114`; ein manueller Start ist auf dieselbe Branchgrenze beschränkt. Nur der Archivjob erhält `contents: write` und `actions: read`. Er lädt das feste Original über die GitHub-API, prüft Quelle, ursprünglichen Fehlerstatus, Größe, SHA256, alle ZIP-CRCs, enthaltene Quellenstempel und das unveränderte `FAIL`-Ergebnis. APK/AAB/APKS-Mitglieder sind ausgeschlossen. Das Archiv wird nicht neu gepackt.

Geplanter eindeutiger Tag: `studio-failed-creative-evidence-4ab96666f954baf258422d6ed277fc297b7ddeef-14092241868`. Der Tag zeigt ausdrücklich auf die ursprüngliche Produktquelle 4ab, während der tatsächliche neue Workflow-SHA separat in `archive-binding.json` steht. Der Prerelease trägt `FAILED TEST EVIDENCE`, `NOT AN APK`, `NOT A RELEASE APPROVAL` und wird mit `--latest=false` erstellt.

Ein vorhandenes vollständiges passendes Archiv wird nur überprüft. Ein fehlender Gegenpart, fremder Tag, anderes Asset oder unvollständiger Upload führt zum Abbruch; der Workflow enthält keinen Ersetzungs-, Ergänzungs-, Lösch- oder Clobberpfad. Die vier Releaseassets sind ausschließlich Original-ZIP, Prüfsummendatei, ursprüngliche Artefaktmetadaten und Quellenbindung.

Der anschließende öffentliche Download benutzt keinen Token und keine curl-Konfiguration. `cmp` vergleicht die vollständigen ZIP-Bytes; Größe und SHA256 werden zusätzlich geprüft. Die drei öffentlichen Begleitdateien werden ebenfalls gelesen und geprüft. Das von GitHub gemeldete Feld `immutable` wird protokolliert. Die garantierte Regel dieses Workflows ist Nichtüberschreiben; eine technische GitHub-Schreibsperre wird nicht vorweg behauptet.

## Tatsächlich ausgeführte lokale Prüfung

- Actionlint 1.7.12: Exit 0. Externer ShellCheck wurde nicht ausgeführt.
- `bash -n`: alle vier tatsächlichen Run-Blöcke bestanden; alle vier eingebetteten Pythonblöcke kompilieren.
- Acht ausführbare Vertragsfälle: 8 PASS, 0 Skip, 0,006 s. Die tatsächlichen abgeschlossenen Originalmetadaten werden akzeptiert. Synthetische Gegenfälle verändern gezielt Quelle, Versuch, Fehlerstatus, Artefakt-ID, Größe, Digest, Ablaufstatus oder bestehende Release-/Assetidentität und werden zurückgewiesen.
- Unabhängiger lesender Review: kein zusätzlicher konkreter Blocker, an den endgültigen Workflowhash gebunden.

Reproduktion der begrenzten lokalen Prüfung (PyYAML vorhanden):

```bash
python3 -B validation/contract_checks.py --workflow .github/workflows/lumo-studio-failed-creative-archive.yml --metadata validation/original-metadata -v
```

Es wurden weder ein Release erstellt noch öffentliche ZIP-Bytes zurückgeladen. Der neue Workflow muss diese Schritte erst tatsächlich bestehen. Kein lokales Originalarchiv wurde gelöscht, verändert oder dupliziert. Keine APK wurde geladen und kein Android-/Godot-Test neu gestartet.

## Vorbild und offizielle Schnittstellen

Das bestehende [Native803-Archivierungsverfahren](https://github.com/Ullmann27/lumo-godot/blob/803e7a626ea6ef0aeeda9c37010e844033d3a8e3/.github/workflows/lumo-studio-2019.yml) wurde anhand des veröffentlichten Git-Blobs `a004e56f149d2496962b65fbb5daf638421f41e1` bytegleich gelesen. Das neue Hostarchiv erhält zusätzlich die feste Original-FAIL-Bindung. Die verwendeten Schnittstellen sind in der [Workflow-Run-REST-Dokumentation](https://docs.github.com/en/rest/actions/workflow-runs#get-a-workflow-run-attempt) und im [GitHub-CLI-Handbuch zu release create](https://cli.github.com/manual/gh_release_create) beschrieben. Letzteres unterscheidet die Repositoryeinstellung für unveränderliche Releases von den Optionen `--prerelease` und `--latest=false`.
