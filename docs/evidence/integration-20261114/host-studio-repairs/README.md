# Host-Studio-Evidenz: geteiltes Originalarchiv

Das unveränderte Archiv wurde ausschließlich für den Repository-Transport in zwei Binärteile geteilt. Ein einzelner Base64-Blob überschritt die vom Connector gemeldete 16-MiB-Anfragegrenze. Beide Teile sind in `transport-manifest.json` durch Reihenfolge, Länge, SHA256 und Git-Blob-ID an das ursprüngliche Gesamtarchiv gebunden.

## Wiederherstellen und vollständig prüfen

Aus diesem Verzeichnis, mit Python 3 und auf einem Dateisystem mit atomaren Hardlinks:

```bash
python3 -B reassemble_archive.py --output /tmp/lumo-host-studio-evidence.tar.gz
python3 -B verify_assembly.py /tmp/lumo-host-studio-evidence.tar.gz
```

Das Zielverzeichnis muss existieren. Der erste Befehl prüft beide Originalteile und den Gesamtinhalt, synchronisiert eine temporäre Datei und veröffentlicht sie atomar ohne Überschreiben. Eine bereits vorhandene identische Zieldatei wird erneut geprüft; eine abweichende Datei oder ein Symlink führt zum Fehler und bleibt unverändert. Ohne `--output` entsteht das Archiv in diesem Verzeichnis.

Erwartetes Gesamtarchiv: **16.935.599 Bytes**, SHA256:

```
df58f8725f38135f8bdc594850365474033b9fdcd8c338362a8abd807422ec60
```

`verify_assembly.py` prüft anschließend sämtliche enthaltenen Originalcontainer, SHA256-Objekte und logischen Dateipfadzuordnungen. Der unveränderte ursprüngliche Beschreibungstext steht in `ASSEMBLY_README.md`; Index, Handoff, Archivprüfbericht und Ergebnisgrenzen bleiben bytegleich. Die historischen FAILs bleiben FAIL; diese reine Transportkorrektur erteilt keine neue Host-, Native-, Visual- oder Android-Freigabe.
