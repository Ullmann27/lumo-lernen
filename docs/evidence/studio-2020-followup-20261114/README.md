# Eingefrorene Studio-2020-Nachträge

Momentaufnahme: 2026-11-14T06:18:37.794159+00:00. Dieses Paket sichert ausschließlich die zehn ausdrücklich ausgewählten Belegpakete. Alle 145 ursprünglichen Dateien mit zusammen 14,767,980 Bytes wurden vollständig nach Größe, SHA256 und Git-Blob-Identität geprüft. Die Originaldateien bleiben an ihren vorhandenen Orten; nur die kleinen Eingangsmanifeste werden unverändert mitgeführt.

## Quellenstand und Grenzen

Der ursprüngliche Native-Lauf [43561885899](https://github.com/Ullmann27/lumo-godot/actions/runs/43561885899) auf `8be3a95d5d948d457c4c39bc6694138d60b70027` bleibt **fehlgeschlagen**. Gameplay scheiterte an der vermischten Original-/Gesichtsableiterbindung; der Studio-Roster lehnte die ursprüngliche MovieMaker-Auflösung ab. Die übersprungenen Folgejobs werden nicht als bestanden dargestellt. Der zusätzliche Stage-2-Lauf scheiterte an einem Dirty-Check ohne konkrete CI-Pfadliste; der getrennte lokale Importvergleich belegt deshalb nicht, dass damals nur dieser eine Pfad geändert war.

Die eng geprüften Import-, Identitäts- und Aufnahmeinitialisierungskorrekturen sind inzwischen in [acf51d3bd2997c4b731e9a48e1791e05e756a132](https://github.com/Ullmann27/lumo-godot/commit/acf51d3bd2997c4b731e9a48e1791e05e756a132) veröffentlicht. Der einmalig gelesene Originalstatus des neuen Laufs [43565059832](https://github.com/Ullmann27/lumo-godot/actions/runs/43565059832), Versuch 1, ist **in_progress**, Abschluss `None`. Diese Momentaufnahme erteilt keine neue Native-Gesamtabnahme, keine Host-Pin-/Releasefreigabe und keinen Android-2020- oder Fold7-Nachweis.

Die 29 C4-Publisher- und 20 Originalarchiv-Vertragsfälle sind synthetische Prüfernachweise ihrer eigenen eingefrorenen Pakete. Sie werden weder mit anderen Testzahlen addiert noch als echte neue Androidläufe ausgegeben. Die vorhandenen echten Rendererbilder und Filme behalten ihre ursprüngliche Quellen- und Laufbindung; diese Paketbildung hat keine neuen Tests, Renderings oder Bildsichtungen ausgeführt.

## Eingangsmanifeste

| Eingefrorenes Paket | Manifestierte Dateien |
|---|---:|
| `studio-2020-facial-import-8be3` | 16 |
| `attention-landing-8be3-contract-fix-20261114` | 17 |
| `studio-2020-native-8be3-observation-20261114` | 25 |
| `studio-2020-facial-movie-8be3` | 61 |
| `studio-2020-facial-movie-independent-review-20261114` | 2 |
| `studio-2020-c4-delivery-86445` | 11 |
| `studio-2020-artifact-originals-86445` | 7 |
| `studio-2020-artifact-originals-independent-review-20261114` | 1 |
| `studio-2020-final-host-workflow-review-20261114` | 1 |
| `studio-2020-host-fixture-blobs-20261114` | 4 |

Die zehn vollständigen unveränderten Eingangsmanifeste stehen unter [input-manifests/](input-manifests/). [freeze.json](freeze.json) bindet jedes Original an seinen SHA256. Die Dateien des vierteiligen Fixture-Blob-Protokolls erhalten ausschließlich neue Dokumentationsziele unter `docs/evidence/studio-2020-host-fixture-blobs-20261114/`; die vier PNG-Produktfixtures selbst gehören nicht zu diesem Paket.

## Ziel- und Byteprüfung

Der tatsächliche veröffentlichte Host-Evidenzstand ist `e423df58117c8f49bcd03c634e438392dc79c3ef`, Tree `61d1aa197fb28072ab9405039b0d171cb4ce1aea`. Die vollständige GitHub-Tree-Antwort enthält 6461 Einträge, davon 5672 Blobs, und ist nicht abgeschnitten. [base-overlap-checks.json](base-overlap-checks.json) enthält den exakten Zielpfadabgleich mit diesem Baum und B's unverändertem 337-Dateien-Manifest. Es gibt keine Zielpfadkonflikte oder Überschreibungen. Identische Inhalte mit verschiedenen dokumentarischen Pfaden bleiben für ihre Verweise erhalten, benötigen aber nur einen Git-Blob.

Historische `.gd`, `.yml`, `.import` und kleine Replay-Skripte sind ausschließlich ausdrücklich manifestierte Diagnoseoriginale unter `docs/evidence/`. Keine operative Datei unter `scripts/`, `tools/`, `.github/`, `lib/` oder Native-Assets wird durch diese Ablage geändert. Root-eigene mutable Integrationsordner werden nicht übernommen.

[upload-manifest.json](upload-manifest.json) ist die vollständige explizite Dateiliste. Die zugehörigen Blobs werden seriell angelegt und jeweils gegen ihren erwarteten Git-SHA geprüft. Diese Arbeit erstellt keine Git-Trees, Commits, Refs oder Pull Requests; die spätere kontrollierte Belegintegration liegt bei Root.
