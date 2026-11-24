# V2: absolute Publisher-Scriptbindung

Diese getrennte Korrektur beseitigt genau den im unabhängigen Quellenreview gefundenen relativen Scriptpfad. Bei externem `RUNNER_TEMP`-Arbeitsverzeichnis muss das ausführbare Script aus demselben absoluten Checkoutpfad gebildet werden, der als `--publisher-source` übergeben wird: `python3 -B "$LUMO_PUBLISHER_SOURCE/scripts/publish_connect_four_delivery.py"`. `LUMO_PUBLISHER_SOURCE` ist einmalig der absolut aufgelöste feste `GITHUB_WORKSPACE/publisher-source`-Checkout, kein Pfad relativ zum Logverzeichnis.

Die 13 Argumentbindungen, externes CWD, getrennte Quellen, Permissions, Fristen und fehlenden tatsächlichen Bundlewerte bleiben unverändert. Keine neue Ausführung, kein Test oder Workflowstart. Der ursprüngliche V1-Pack samt ursprünglichem falschem Vertrag ist vollständig bytegleich in `original-v1/complete-original-plan.tar.gz` erhalten. Die folgende ursprüngliche Plandarstellung wird vollständig erhalten; maßgebliche korrigierte Argumentdatei ist `final/cli-argument-contract.json`.

---

# C4 2020: Plan für den einmaligen Publisher-Workflow

**Stand: reiner Implementierungsplan, nicht aktiviert.** Es wurde kein Publisher ausgeführt, kein Bundle/APK heruntergeladen und kein Tag, Draft, Asset oder Release geschrieben. Die bereits vorhandenen 32 isolierten Publisher-Verträge werden als historischer Originalnachweis beigefügt; es gab hier keinen neuen Testlauf.

## Gebundene Ausgangslage

| Gegenstand | Tatsächliche Identität / Grenze |
|---|---|
| Veröffentlichte Publisherquelle | `72143d3586109967773d6442072d486c11dc1449`, Tree `f77e67ad2e1ceb702dd4fe9d6a3279e55ea9b131` |
| CLI-Blob | `982f8cf3c85a6bf85f49bed842b3c7e08a20730e` |
| CLI-SHA256 | `cc06aaf7472e675171344e6321078749101d21ea112795bf1d6ed8dd15228a7d` |
| Tatsächlicher 32er-Teststand | Parent `9799d1d637eb870dbb366d95d6593ed7ca876849`; 32 PASS, 0 Fehler, 0 Skips, ein Lauf, Python 3.12.14. Proof ist in 72143 veröffentlicht. Nur isolierte Fakes. |
| Beobachteter Kandidat | Host `0b7bacadd3cdc45d22a8e038c5df50ba8b739d62`, Tree `f3a7df4c3112ac63577db00a9637facfea5c0175` |
| Gebundener Native-Pin | `baf148b03a7a32c6ad9f737d731f900eb9113ea1` |
| Zugehöriger tatsächlicher Lauf | `43604903064`, Versuch 1, PR 485, `.github/workflows/lumo-connect-four-2020.yml` |
| Noch nicht beobachtete Eingaben | Delivery-Bundle-Artefakt-ID, exakter API-Digest und API-Bytezahl; endgültiger erfolgreicher Abschluss aller sieben Jobs; späterer Publisher-Workflowcommit |

`source-binding.json` bindet Originalbytes, Größen, SHA256 und Git-Blobs. Die Verifier- und Helperbytes in Publisher72143 und Kandidat0b7 sind exakt identisch. Die beigefügten Kandidaten-API-Antworten stammen aus bereits erhaltenen Pipeline-Snapshots um 14:27/14:48/14:49 UTC. Sie sind Hintergrundbelege, keine frische Freigabe. Es gab keinen parallelen C4-Poll.

## Ein neuer, gesonderter Workflow

Vorgesehen ist ausschließlich `.github/workflows/lumo-connect-four-2020-publish.yml`, ausgelöst durch einen Push auf `integration/lumo-c4-publisher-20261114` im Repository `Ullmann27/lumo-lernen`. Kein PR-, Main-, Dispatch- oder Workflow-run-Trigger, keine Matrix. Die vorhandene C4-Pipeline, ihre sieben Fachjobs, Produktquellen, Pins und Verifier werden nicht geändert.

Der einzelne Publisherjob erhält `contents: write`, `actions: read` und `pull-requests: read`; der Workflowstandard bleibt `contents: read`. Nur der Publisheraufruf erhält `GITHUB_TOKEN` im Step-Environment. Keine Shellausgabe der Umgebung oder Zugangsdaten. Die feste Concurrency-Gruppe `lumo-c4-publisher-2020` verwendet `cancel-in-progress: false`. Ein früher Preflight verlangt Versuch 1. Das verhindert einen Wiederanlauf desselben Actions-Laufs; vorhandene Release-/Tagzustände werden zusätzlich von der unveränderten CLI abgewiesen.

Die Actions wurden für diesen Plan anhand ihrer offiziellen v4-Refs und der vollständigen unveränderlichen `action.yml` gelesen:

- Checkout: `actions/checkout@11d5960a326750d5838078e36cf38b85af677262`.
- Evidence-Upload: `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02`.

Die Originalantworten und Definitionen liegen im Pack; Checkout-CRLF sind unverändert erhalten. Dies ist eine Quellenprüfung, keine neue Action-Ausführung.

## Zwei getrennte Checkouts und vollständige CLI-Eingaben

`publisher-source` und `candidate-source` liegen als Geschwister unter `GITHUB_WORKSPACE`. Beide verwenden `persist-credentials: false`, Fetch-Tiefe 1 und keine LFS-/Submodule-/Tagübernahme. Ein begrenzter Sparse-Checkout materialisiert alle vom SourceGuard tatsächlich verlangten Dateien. Es wird kein Checkout in den anderen geschachtelt.

Der Publisher wird aus der exakten SHA des späteren Aktivierungspushes gestartet. Sein CLI-Blob muss weiterhin exakt dem geprüften72143 entsprechen. Seine `--publisher-sha` ist deshalb die neue tatsächliche `github.sha`, seine Tree-ID die hierzu gebundene Git-Tree-ID; die spätere Workflowdatei darf ihren neuen HEAD nicht als72143 ausgeben.

Der Candidate-Checkout verwendet die akzeptierte Host-SHA. Physisch erforderlich sind `scripts/verify_connect_four_delivery.py`, `scripts/release_pipeline_gates.py`, `config/godot-source.json`, `pubspec.yaml` und der originale C4-Workflow. SourceGuard prüft sauberen Status, HEAD/Tree, Rohindex, Stage-Inventar und die exakten committed Bytes. Verifier-Kinder erhalten keine Veröffentlichungscredentials.

`cli-argument-contract.json` bildet alle 13 Pflichtargumente auf tatsächliche Originalwerte oder klar benannte Laufzeitquellen ab. Nur die drei noch fehlenden Bundlewerte sowie der spätere Publishercommit bleiben dort ausdrücklich unbekannt. Diese Plan-Nullwerte sind keine ausführbaren Workflowwerte. Erst nach dem vollständigen Originalhandoff schreibt Root die konkreten Literale in den neuen Workflow.

`--bundle-archive` wird nicht gesetzt: Die vorhandene CLI lädt genau das gebundene Original-ZIP über seine Artefakt-ID, prüft volle API-Größe/SHA256, inventarisiert jedes Mitglied mit CRC/SHA256 und erhält das Original-ZIP. Ein von `download-artifact` bereits entpacktes Verzeichnis ersetzt diese Originalprüfung nicht. Alle Ausgaben liegen unter einem neuen `RUNNER_TEMP/lumo-c4-publication-evidence` außerhalb beider Checkouts; der CLI-Unterordner darf vor Aufruf noch nicht existieren.

## Bereits implementierte unveränderte Veröffentlichungsfolge

Die vorhandene CLI bindet Run und Versuch, erfolgreichen Abschluss aller sieben erwarteten Jobs und erforderlichen Schritte, unverrückten offenen PR485-Head, exaktes Bundle und die vorbereiteten Delivery-Fakten. Sie ruft unverändert `check-current`, `check-vacant`, `check-tag`, `check-release` für die drei Phasen sowie `verify-public` auf.

Nach vollständiger Prüfung sämtlicher Release-/Tagseiten entsteht ausschließlich ein neuer Tag am akzeptierten Host, anschließend ein neuer leerer Prerelease-Draft. Genau elf vorbereitete Dateien werden jeweils einmal hochgeladen. Vor jedem Schreibaufruf werden Run, PR und Quellen erneut gelesen. Vor Veröffentlichung folgen vollständige frische Prüfungen von Kandidat, Katalogen, Tag, Draft und allen Asset-Identitäten. Erst danach wird `draft=false` gesetzt; `make_latest` bleibt false.

Zu den elf Dateien gehören die ARM64-Test-APK, ihr SHA256-Sidecar, Build-/Native-/Candidate-/Delivery-Provenienz, C4-Android-/Desktop-, Update- und Dorfresultat sowie der vorbereitete Veröffentlichungsnachweis. Die vollständige Liste steht in `plan.json`. Es werden keine neuen Produkt-/Laufzeitergebnisse erzeugt.

Nach Veröffentlichung lädt die CLI die vollständige öffentliche APK über HTTPS ohne Authentifizierung auf irgendeinem Redirect-Hop und vergleicht die Bytes. Erst ein echter Exit0, `completed.json` mit `PUBLIC_BYTES_VERIFIED` und der passende öffentliche Bytebeleg erlauben einen Erfolg. Der vorbereitete kanonische Releasepfad ist bis dahin kein verifizierter Downloadlink.

## Laufzeit und Beweiserhaltung

Vorschlag: Jobgrenze100 Minuten, Publisher-Step80 Minuten, Always-Evidence10 Minuten. Das ist eine äußere Begrenzung mit Reserve für Setup und Sicherung. Die bestehende CLI begrenzt ihre Entscheidungen auf3600 Sekunden; ein bereits laufender Verifier hat bis zu900 Sekunden, eine HTTP-Operation ein eigenes600-Sekunden-Annahmebudget. Die3600 Sekunden sind keine behauptete harte Gesamtprozessdauer. Keine interne Frist wird erhöht.

Vor dem einen Aufruf wird ein STARTED-Beleg geschrieben. Originalstdout und stderr werden getrennt erhalten, anschließend der tatsächlich beobachtete Child-Exit. Bei fehlendem Wait-Ergebnis bleibt der Exit unbekannt; ein abgebrochener Lauf wird nicht als erfolgreich ausgegeben. Ein `always()`-Upload erhält alle Originalantworten und Operationen, ZIP, unveränderte Delivery-Mitglieder, Source-/Indexstempel, öffentliche APK, Receipt oder Failuredatei sowie äußere Streams. Der Upload verwendet keinen Overwrite, keine versteckten Ausschlüsse, Kompression0 und30 Tage Aufbewahrung. Runnerverlust oder eine harte Jobabbruchgrenze können auch einen Always-Schritt verhindern; der Plan behauptet keine Garantie für solche Fälle.

Ein Fehler nach einem Schreibversuch kann einen Tag, Teil-Draft oder sogar ein bereits veröffentlichtes Release hinterlassen. Es gibt weder automatische Mutation-Retries noch Resume, Clobber oder Cleanup. Root beurteilt den tatsächlichen Originalzustand. Concurrency schützt nur diesen Workflow und ersetzt keine Prüfung anderer Repositoryschreiber.

## Übergabe und Aktivierungsschwelle

Vor der späteren Aktivierung fehlen die drei tatsächlichen Bundlefelder und die endgültige Kandidatenfreigabe. Root bindet danach die konkrete neue Workflowquelle, ihren Commit/Tree und alle Argumente. Bei geändertem Kandidaten muss die gesamte Host/Tree/Run/Attempt/Artefaktbindung neu geprüft werden. Es wird kein neuer Kandidat aus einzelnen ausgetauschten Zahlen konstruiert.

Dieser Pack enthält keine ausführbare Platzhalter-Workflowdatei. Er verändert weder den aktiven Kandidaten noch den Publisher72143, führt keine Tests erneut aus und besitzt keine Releasefreigabe allein aufgrund der historischen32 Verträge. Der spätere öffentliche Downloadnachweis bleibt eine echte noch ausstehende Ausführung.
