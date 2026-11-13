# LUMO Studio 318: unveränderte Build- und Updatebelege

Dieses Paket bündelt ausschließlich die fünf abgeschlossenen Reviewbereiche von Agent A aus dem echten CI-Run **43496928833**. Hostquelle: **31883868bac56699dbf3b3d60a7cdb7afc496a8b**. Nativequelle: **796b2818ff729dc5389a92f8bf1f7fd7e6b6d93e**.

## Archiv und nachgewiesene Integrität

[studio-31883868-build-and-update-evidence.zip](studio-31883868-build-and-update-evidence.zip) enthält **180 Dateien**: genau die **121** bereits eingefrorenen Dateien der vier Build-Reviewbereiche sowie **58 Update-Dateien und deren unverändertes Manifest**. Alle Pfade sind relativ zum Repository-Wurzelverzeichnis. Der vollständige Inhalt jeder Datei wurde nach dem Packen erneut aus der ZIP gelesen, mit dem eingefrorenen SHA256 und anschließend byteweise mit der ursprünglichen lokalen Datei verglichen. Keine Originaldatei wurde gelöscht oder umgeschrieben.

| Eigenschaft | Tatsächlicher Wert |
| --- | --- |
| ZIP-Größe | 29.936.080 Bytes |
| ZIP-SHA256 | `097c0180cf6ed0f478d996bace00002cc69e076b4d70fe1ce5b3645fb946674b` |
| Unkomprimierte Originale | 35.115.190 Bytes |
| Ersparnis | 5.179.110 Bytes / 14,749 % |
| Original-PNG-Daten | 29.004.310 Bytes, unverändert |
| Zurückgelesene und verglichene Mitglieder | 180 von 180 |

Die geringe zusätzliche Kompression der PNG-Dateien ist erwartbar: Ihre vorhandenen Bildbytes wurden nicht verändert. ZIP verwendet ausschließlich Deflate auf den unveränderten Dateien. Die festen ZIP-Metadatenzeiten sind Packmetadaten und keine behaupteten ursprünglichen Aufnahmezeiten.

Direkte Prüfdokumente: [Archivindex](archive-index.json), [Byte-/CRC-Prüfung](archive-verification.json), [Größenvergleich](size-comparison.json), [unverändertes 121-Datei-Ausgangsmanifest](build-evidence-upload-manifest.json) und [unverändertes Update-Ausgangsmanifest](../update/evidence-manifest.json).

## Direkt lesbare Ergebnisse

| Bereich | Ergebnis und Grenzen | Direkte Dokumente |
| --- | --- | --- |
| Android-Hostkompilierung | Echter Job erfolgreich; sechs Verträge und tatsächliche Kotlin-/Gradle-Kompilierung. Kein Emulator-/APK-Nachweis allein durch dieses Teilpaket. | [Review](../host-compile/review.json), [Originalergebnis](../host-compile/result.json) |
| Flutter | 2.510 sichtbare bestandene Tests, keine fehlgeschlagenen oder übersprungenen Tests. Hit-Test-Hinweis und absichtlich erzeugte Fehler-/Audiomeldungen sind abgegrenzt; keine pauschale Sichtprüfung von 546 PNGs. | [Review](../flutter/review.json), [Originalzusammenfassung](../flutter/acceptance-summary.json), [Ereignisanalyse](../flutter/event-analysis.json) |
| Native Prüfungen | Frisch ausgeführte Prüfungen der gepinnten Quelle. Einzelne Testzahlen bleiben getrennt; Ressourcen-Leak- und Rendererwarnungen werden ausdrücklich erhalten. Keine Geräte-FPS-Aussage. | [Review](../native/review.json), [Ergebnisse der Hauptlogs](../native/primary-log-results.json), [Dateimanifest](../native/files-manifest.json) |
| Vollständiger Build | 402 Scriptverträge und 764 Android-Probeverträge, jeweils ohne Skip; beide echten APKs wurden im CI erzeugt und geprüft. Analysewarnungen bleiben sichtbar. | [Review](../build/review.json), [Diagnosen](../build/diagnostic-summary.json), [ARM64-CI-Prüfung](../build/ci-apk-verification-arm64-v8a.json), [x86-CI-Prüfung](../build/ci-apk-verification-x86_64.json), [Logabschnittsherkunft](../build/section-provenance.json) |
| Tatsächliches Update | Erfolgreiche Installation 2017 → 2019 mit gleichem UID/appId und erster Installationszeit. Ein Testprofil, sieben geschützte Lernschlüssel, zehn alte Skillfelder, ein Stern und fünf XP bleiben erhalten. Nur independentEvidence kommt hinzu. | [Review](../update/review.json), [unabhängiger Datenvergleich](../update/independent-data-comparison.json), [13 tatsächlich geöffnete Bilder](../update/selected-visual-review.json), [Quellenbindung](../update/source-binding.json), [Logbefunde](../update/log-review.json), [Job-/Artefaktmetadaten](../update/completion-and-artifact-metadata.json) |

Die 35 im Updatejob erneut ausgeführten Vertragsfälle überlappen die bereits enthaltenen vollständigen Probeverträge; Testzahlen werden nicht zu einer künstlichen Gesamtsumme addiert. Im alten 2017-Lernreisebericht bleiben zwei optionale Navigationsfehler bei Deutsch/Englisch aufgezeichnet. Der erfolgreiche Kern-Updatepfad ersetzt keine allgemeine Abnahme dieser Fächer.

## Umfang und Herkunft

Alle Rohlogs, ausgewählten Originalberichte, Zustandsdateien, Provenienzdateien und tatsächlich geprüften Bilder aus den zwei eingefrorenen Manifestlisten sind im Archiv enthalten. Die direkt bereitgestellten ursprünglichen Review-, Vergleichs- und Manifestdateien behalten ihre unveränderten Bytes. Die neu erzeugten Archiv-/Prüfindizes stehen separat daneben; keines dieser Dokumente ersetzt die archivierten Rohdaten.

Die große ursprüngliche Update-Artefakt-ZIP selbst wird nicht erneut in dieses Archiv gepackt. Ihre lokal vollständig geprüfte Größe, GitHub-Identität, SHA256 und die Hashes sämtlicher 442 Mitglieder bleiben im archivierten `update/original-archive-byte-verification.json` erhalten. Ebenso bleiben die vorhandenen Herkunftsangaben für nur teilweise heruntergeladene Flutter-/Native-Artefakte unverändert: Aus diesen Teilzugriffen wird keine lokale Voll-ZIP-Prüfung behauptet.

Nicht enthalten sind APK-/PCK-Dateien, fremde Reviewbereiche, neue Produktänderungen oder eine neue Releasefreigabe. Root betreut ARM64, die gesonderten API35/API37-Touren und die Veröffentlichung separat. Dieses Paket beweist weder Mehrkind-/Journal-/native Altspielstandmigration noch physische Fold7-FPS, Temperatur, Eingabelatenz oder hörbare Sprachausgabe.

## Archiv erneut prüfen

Im Verzeichnis mit ZIP und `archive-index.json` kann die folgende reine Leseprüfung ausgeführt werden. Sie benötigt kein Netzwerk und extrahiert keine Dateien:

```python
from pathlib import Path
import hashlib
import json
import zipfile

index = json.loads(Path("archive-index.json").read_text())
archive = Path(index["archive"]["file"])
assert archive.stat().st_size == index["archive"]["bytes"]
with archive.open("rb") as stream:
    assert hashlib.file_digest(stream, "sha256").hexdigest() == index["archive"]["sha256"]
expected = {entry["path"]: entry for entry in index["members"]}
with zipfile.ZipFile(archive) as zipped:
    assert len(zipped.infolist()) == len(expected) == 180
    assert set(zipped.namelist()) == set(expected)
    assert zipped.testzip() is None
    for name, record in expected.items():
        raw = zipped.read(name)
        assert len(raw) == record["bytes"]
        assert hashlib.sha256(raw).hexdigest() == record["sha256"]
print("180 Originaldateien: CRC, Größe und SHA256 stimmen.")
```

Der aktuelle Upload ist durch eine separate explizite Dateiliste unter `qa/studio-final-31883868/compact-evidence-upload-manifest.json` begrenzt. Es wird keine ganze Verzeichnisstruktur automatisch ausgewählt.
