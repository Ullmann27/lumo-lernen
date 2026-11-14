# Creative-Teileprüfer für PR481 / QA f89b77

`verify_creative_parts.py` ist eine getrennte neue Fassung des vorhandenen
Transportprüfers. Der ursprüngliche Ordner `host-creative-parts-collector` wurde
nicht verändert. Diese Fassung prüft ausschließlich den vollständigen,
deklarierten Teileexport des folgenden tatsächlichen QA-Laufs:

| Merkmal | Feste Bindung |
|---|---|
| Repository | `Ullmann27/lumo-lernen`, ID `1222433959` |
| QA-Quelle | `f89b77bbc9caacfb677a8f0b7922f27fcbbd546f` |
| QA-Tree | `5c42a92ae49e73d4739cacaaf35f2102561d841a` |
| Run / Versuch | `43556708653` / `1` |
| Ereignis | `pull_request` |
| Zweig | `qa/lumo-creative-7b16-20261114` |
| Workflow | `.github/workflows/lumo-creative-7b16-diagnostic.yml` |
| Artefaktnamen | `lumo-creative-7b16-diagnostic-creative-part-01` bis `-08` |
| Exporter-Gitblob | `4c113e5b73e9f6eb3c02ab48b25f0aa3331f79c9` |

Die bereits vorliegende originale Runliste bindet diese Identitäten zusätzlich.
Ihre unveränderten Bytes liegen unter
`source-contract/original-initial-run-list.json`; Herkunft und Hash stehen in
`source-contract/manifest.json`. Sie ist ein früher Metadatenstand, kein Nachweis
fertiger Artefakte oder eines erfolgreichen Android-Laufs.

## Schema und Quellenrolle

Der gemeinsame `export-index.json` muss exakt **Schema 2** und in seiner
`binding` ausschließlich das Quellenfeld **`probe_source_sha`** besitzen. Dieses
Feld bezeichnet die neue QA-Quelle f89b77. Die unveränderte gebaute APK stammt
weiterhin aus einem anderen Quellstand; dieser Prüfer nimmt keine APK-Abnahme vor.

Alte Schema-1-Indizes, `host_source_sha` anstelle von `probe_source_sha`, beide
Quellenfelder gemeinsam sowie die früheren Quellen 7b16 oder 61c werden verworfen.
Die einzelnen `part.json`-Manifeste bleiben dagegen ausdrücklich **Schema 1**.
Der Ergebnisbericht dieses lokalen Prüfers verwendet sein eigenes Schema 1 und
nennt beide Eingabeschemata sowie `probe_source_tree` und `transport_source_role`
ausdrücklich. Es wird kein altes Host- oder APK-Quellenfeld umgedeutet.

## CLI und unveränderte Eingaben

```text
python3 -B verify_creative_parts.py --run RUN_JSON \
  --part API_JSON REPORT_JSON EXPORT_INDEX_JSON PART_JSON \
  [--part API_JSON REPORT_JSON EXPORT_INDEX_JSON PART_JSON ...] \
  [--output NEUE_ERGEBNISDATEI]
```

| Argument | Erforderliche Eingabe |
|---|---|
| `RUN_JSON` | Vollständige originale REST-Antwort für genau Run `43556708653`; kein Listenwrapper |
| `API_JSON` | Unverändertes vollständiges API-Objekt eines Teil-Artefakts |
| `REPORT_JSON` | Vollständiger Bericht des eingefrorenen RAM-Collectors nach erfolgreicher ZIP-, CRC- und SHA-Prüfung |
| `EXPORT_INDEX_JSON` | Daraus bytegleich materialisierter ZIP-Eintrag `export-index.json` |
| `PART_JSON` | Daraus bytegleich materialisierter ZIP-Eintrag `part.json` |

`--part` wird für jeden deklarierten Teil einmal angegeben. Die vier lokalen
Dateien müssen demselben Originalartefakt entsprechen. Im Materialisierungsordner
des RAM-Collectors liegen die beiden JSONs typischerweise unter
`originals/export-index.json` und `originals/part.json`; ihre ursprünglichen
ZIP-Einträge liegen dennoch auf oberster Ebene. Die eigentlichen Exportdateien
tragen im ZIP dagegen den Präfix `originals/`.

Ohne `--output` erscheint nur JSON auf stdout. Ein angegebener Ausgabepfad wird
ausschließlich neu angelegt. Vorhandene Ergebnisdateien werden nicht überschrieben.
Exit 0 und `CREATIVE_PARTS_TRANSPORT_SNAPSHOT_COMPLETE` belegen ausschließlich
einen vollständigen, konsistenten Teile-Snapshot. Fehler ergeben Exit 1 und
`CREATIVE_PARTS_REJECTED` mit einem festen Fehlercode.

## Erhaltene vollständige Integritätsprüfungen

Alle deklarierten Teile müssen genau einmal vorhanden sein; Teilnummern und
Artefakt-IDs dürfen sich nicht wiederholen. Jeder Teil muss denselben vollständigen
Index mit identischen Bytes enthalten. Die unveränderten API-Objekte binden
Repository, tatsächlichen QA-Run und Head, Artefaktnamen, IDs, ZIP-Größen und
SHA-256-Digests. Ihre Rohhashes müssen exakt zu den Collectorberichten passen.

Der vorausgesetzte Collector prüft das vollständige Archiv vor Parsing gegen
API-Größe und SHA-256, danach sämtliche Mitglieder per CRC und SHA-256. Dieser
Teileprüfer verlangt diese vollständigen Berichte, sichere eindeutige Pfade,
kollisionsfreie Mitglieder und die exakte Manifest-Materialisierung. Er prüft die
sortierte Teilplanung sowie jede Datei, Größe und SHA-256 gegen den Gesamtindex.
Zusätzliche oder fehlende Dateien, widersprüchliche Indizes und unzulässige
Verzeichnisse bleiben Fehler.

Die bestehenden Grenzen bleiben unverändert: höchstens 8 Teile, 20.000
Originaldateien, 256 MiB Originalpayload pro Teil, 4 MiB gemeinsamer Index und
16 KiB pro Teilmanifest. Die kleineren synthetischen Fälle verwenden 20 Bytes
Payloadbudget. Der reale Workflow verwendet die vorhandenen Standardgrenzen.

## Gezielte lokale Nachweise

**14 Tests bestanden, keine Fehler oder Skips.** Der positive Fall erzeugt drei
ausdrücklich synthetische Dateien mit insgesamt 29 Bytes. Der exakte veröffentlichte
Exporter erstellt daraus zwei Teile mit Schema-2-Index und Schema-1-Teilmanifesten.
Der unveränderte geprüfte RAM-Collector inventarisiert die kleinen echten Test-ZIPs;
anschließend läuft die tatsächliche neue CLI. Die Eingaben bleiben dabei bytegleich.

Die neun vorhandenen Guardfälle wurden übernommen. Hinzu kommen die enge
Schema-/Quellenabgrenzung, die unveränderte Teilmanifest-Version, die Ablehnung
früherer APK-/QA-Identitäten auf Index-, Artefakt- und Runebene, genaue Branch-/Tree-
und Ereignisbindung sowie der nachgewiesene Schutz einer vorhandenen Ausgabedatei.
Der positive Test verwendet absichtlich einen fehlgeschlagenen Gesamt-Workflowstatus:
vollständiger Transport darf niemals zu einer Produktfreigabe werden.

Vollständiges Log: `evidence/focused-tests.log`. Vorher-/Nachher-Quellhashes,
unveränderte Legacy-Inventare und der kleine Verifier-Diff liegen daneben.
Exporter und RAM-Collector sind als genaue Quellsnapshots mit Hash-/Blobbindung
enthalten. Es gab keine Downloads, Git-Aktionen oder Geräteaufrufe.

## Grenzen

Es wurden noch keine tatsächlichen neuen Artefakte von PR481 geprüft. Die kleinen
Test-ZIPs sind synthetisch und wurden nach den Tests entfernt. Dieser Prüfer
lädt keine ZIPs herunter und liest ihre Payloads nicht nochmals: Er kontrolliert
authentisch bereitzustellende Originalmetadaten und vollständige Berichte des
geprüften RAM-Collectors. Er authentifiziert deren externen Ursprung nicht und
kann konsistent gefälschte Berichte ohne Originalpayload nicht eigenständig erkennen.

Vollständigkeit gilt gegenüber dem identischen Gesamtindex. Eine Gleichheit mit
einem zuvor separat hochgeladenen Voll-ZIP wird nicht behauptet. Produktfunktion,
APK-Identität, Bildfreigabe, Sprache, Geräteerfolg und FPS bleiben gesonderte
Abnahmen. Die Ergebnisfelder kennzeichnen diese Grenzen ausdrücklich.
