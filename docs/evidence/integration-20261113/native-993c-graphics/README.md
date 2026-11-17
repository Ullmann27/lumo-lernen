# Graphics-993c: vollständiger Originalcheckpoint

Dieser Pack bindet ausschließlich Native
993c145304c3e5f8aa947e1c7a949a8ef8685415 / Tree
f13dd5fc5540ecb7705c5f18bf3cf8ba6e79d7a6 an Grafiklauf 43489950655,
PR 160, Versuch 1. Home, Worlds und Feedback endeten mit SUCCESS;
der gesamte Grafiklauf war am 13.11.2026 um 19:23:28 UTC abgeschlossen.

## Tatsächlich enthaltene Originalbytes

- original/ bewahrt die unveränderten finalen und früheren API-Antworten,
  alle drei vollständigen Joblogs, den eingefrorenen Handoff und seine Hashliste,
  Quellenbindungen, Auswertungen, unveränderliche Capture-/Produktquellen,
  beide Root-Sichtungsbelege und die vorbereitete finale Bildauswahl.
- artifact-logs/ enthält sämtliche 40 vollständigen Artefaktlogs einschließlich
  aktueller und historischer Imports, Engine- und Captureprotokolle. Die
  gespeicherten Namen sind abgeflacht; das Manifest nennt jeweils den exakten
  Original-ZIP-Pfad.
- original-artifacts/ enthält die originalen Head-/Tree-/Dirty-/Engine-Stempel,
  Bildmanifeste, Baseline-Harness-Hashes und Captureberichte.
- original/archive-indexes/ bewahrt die drei vollständigen unveränderten
  Mitgliederindizes. Alle 2.487 regulären ZIP-Einträge sind mit Größe, CRC und
  SHA-256 gebunden, einschließlich der nicht kopierten Laufzeit-Caches.

API-JSON und Logtexte wurden nicht gekürzt oder neu serialisiert. Die Joblogs
sind die vollständigen vom GitHub-Connector dekodierten UTF-8-Ausgaben mit BOM;
eine unbekannte ursprüngliche HTTP-Transportkodierung wird nicht behauptet.

## Nicht duplizierte Originalpayloads

Die großen ZIP-Dateien und alle PNG-Payloads bleiben unverändert unter:
 /workspace/scratch/b3485b7bb989/pipeline-evidence/pr160-993c1453-graphics/

archive-index.json nennt Artefakt-ID, originale API-/Downloadquelle, Bytezahl,
REST-Digest, Originalpfad und vollständigen Mitgliederindex jeder ZIP.
raster-index.json.gz bindet alle 62 PNG mit ihrer tatsächlichen Quelle, ihrem
ZIP-Mitglied, ihren Maßen, Bytezahlen und Hashes: 36 aktuelle und 26 frisch
ausgeführte historische Baselinebilder. Kein Bild aus 90d oder einem älteren
Run wird als aktueller 993c-Nachweis übernommen.

| Bereich | Originalartefakt | Aktuelle PNG | Baseline-PNG | Vollständige Logs |
|---|---:|---:|---:|---:|
| Home | 14068903423 | 24 | 20 | 19 |
| Worlds | 14069811657 | 6 | 6 | 15 |
| Feedback | 14068797425 | 6 | 0 | 6 |

Die historische Vergleichsquelle bleibt ada5ed81ad62339f15289da62670c0a4f9f7f2b9,
Tree 2e93cc5587b477ceee2d159c8aa981ff5188171b. Ihre Bilder sind getrennt
gekennzeichnet; der Capture-Harness ist jeweils an die aktuelle unveränderliche
Quelldatei gebunden.

## Originalprüfung und spätere Root-Sichtung

Die ursprüngliche Prüfung dekodierte alle PNG vollständig mit Image.verify()
und Image.load(). Alle 40 Artefaktlogs bestanden den strengen Fehlercheck;
Projektvalidator-Warnungen bleiben vollständig erhalten. Der direkte aktuelle
Feedback-Nachweis ist gerendert PASS 75 mit drei tatsächlich freigegebenen
Audio-Playbacks nach 10 ms vor PASS. Ein früherer Headless-PASS 56 wird nicht
übernommen. Der gesonderte Collector-Timingvermerk bleibt unverändert erhalten:
Ein vorzeitig gestarteter lokaler Leseaufruf öffnete noch keine ZIP und erzeugte
keinen akzeptierten Befund; die vollständige ZIP wurde anschließend regulär
gegen Digest, Inhalt und Gates geprüft.

Beim Packen wurden alle 191 eingefrorenen Hashbindungen, ZIP-Digests und Größen,
sämtliche 2.487 ZIP-Mitglieder, die PNG-Identitäten und alle kopierten Rohbytes
erneut verglichen. Keine Engine-, Renderer- oder Regressionstests wurden gestartet.

Root öffnete die fünf neuen Originalbilder tatsächlich: Home 1280×720,
Home 412×915, Winter-Landmark, Crystal-Landmark und Drift-Release. Der vollständige
Review liegt unverändert in original/root-current-five-viewed.json,
SHA-256 2c383d58a58fed9b97c857ff88bf6f97c32ceda55baa6f9606b5a62fe503f293.
Der frühere Dreierreview bleibt als historische Teilsichtung erhalten.

original/root-final-graphics-selection.json enthält die von Root vorbereiteten
fünf Einträge und seine Befunde, SHA-256
8d2ab7a70941b1567a4f946e4c7395fffd69d4e4b73a34daf1368737544f9e90.
Die Auswahl ist kein Receipt. Ihre Einträge und Befunde stimmen mit dem
tatsächlichen aktuellen Fünferreview überein.

Der eingefrorene Originalhandoff und seine Hashliste entstanden vor Fünferreview
und Auswahl. Sie wurden nicht umgeschrieben. Dieses Manifest bindet beide
späteren Dateien zusätzlich, mit ihren eigenen unveränderten Originalhashes.

## Speicherformat und Grenzen

Logs und größere Dateien sind deterministisch komprimiert: gzip, leerer
Originaldateiname, mtime=0, Kompressionsstufe 9. Das Manifest nennt Original- und
Speichergrößen, beide Hashes, Herkunft und den bytegleichen Roundtrip.
SHA256SUMS bindet alle gespeicherten Dateien einschließlich Manifest.

Dies ist ausschließlich der 993c-Grafikcheckpoint. Er ersetzt keine separate
Nextgen-, Android-, APK/AAR- oder Native-Gesamtfreigabe und belegt keine
physische Geräteprüfung oder gemessene Bildrate. Der Pack schreibt weder
Hostquelle, Pin, Receipt, Index noch Commit/Ref. Die dauerhafte Übernahme erfolgt
gesondert durch Root.
