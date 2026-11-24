# C4 2020: geprüfter Pipelineentwurf

Dieses Paket enthält einen konkreten, noch nicht aktivierten Anschluss für den veröffentlichten C4-Code. Es ändert keinen der vorhandenen Arbeitsbäume. Root übernimmt Prüfung, Übernahme und Veröffentlichung. Es wurde kein APK gebaut, kein Android-Gerät gestartet und kein CI-Lauf ausgelöst.

## Quellen und Umfang

Die ursprüngliche Bestandsaufnahme bindet Host `06b3a1136cfe2a8a8b13e46ac9819e65b7130ea5` mit Tree `2e6ffb0a673251d4d09dfaa4c5fc916cbf898797` und Native `27ae427029a5199699c95a79a84b0027d7571752` mit Tree `c389c0de01d9a6ca9fd6e9332fafdf2dedbc8153`. Die 15 tatsächlich verwendeten C4-, Build- und Update-Referenzdateien liegen unverändert unter `before/`; ihre Herkunft und SHA-256-Werte stehen in `evidence/source-before.json`.

Root ergänzte während der Ausarbeitung einen getrennten Host-Quellencheckpoint. Die gezielten Tests liefen mit dem unveränderten lokalen Referenz-HEAD `43db2662e890b6468cf77f7044da16364a259482`. `evidence/reference-source-preservation.json` bestätigt, dass sämtliche 15 ursprünglichen Referenzdateien dabei bytegleich blieben. Der Entwurf enthält keine fest eingebaute Host- oder Native-Commitnummer: Jeder zukünftige Lauf muss seinen tatsächlichen PR-HEAD, die explizite Versionsnummer 2020 und die durch `verify_legacy_release_pin.py` freigegebene aktuelle `config/godot-source.json` nachweisen. Das ist keine Freigabe eines beliebigen Pins.

`proposed/` enthält genau sieben vorgeschlagene Dateien:

| Datei | Zweck |
| --- | --- |
| `.github/workflows/lumo-connect-four-2020.yml` | Neuer, ausschließlich auf den eigenen C4-Integrations-PR begrenzter Testkandidatenlauf |
| `.github/workflows/lumo-unified-integration-2026.yml` | Genau eine zusätzliche C4-Branchausnahme, um einen zweiten generischen APK-Build zu vermeiden |
| `.github/probes/lumo_connect_four_android_probe.py` | Echte API-35-C4-Touches, IPC-Beobachtung, Rückkehr und Wiederöffnung |
| `tools/android_qa/connect_four_android_evidence.py` | Reine Nachprüfung ursprünglicher Zustände, Geometrie, Bilder, Touches und Belegketten |
| `tools/android_qa/tests/test_connect_four_android_evidence.py` | Gezielte synthetische Gegenfälle für diesen Beobachtungsvertrag |
| `scripts/verify_connect_four_candidate.py` | Abschlussprüfung beider signierter APKs und aller verpflichtenden aktuellen Nachweise |
| `scripts/tests/test_connect_four_pipeline.py` | Tatsächliche Workflow-/Pin-/Update-Verträge; keine Geräteausführung |

Die vollständige übernehmbare Änderung steht in `proposed.patch`. Die sieben Enddateien, ihre Git-Blob- und SHA-256-Werte sind in `source-freeze.json` gebunden. Außer der einzelnen Unified-Bedingung sind alle Dateien neu. Es gibt keine Änderung an Produktcode, Spielregeln, Pins, Receipts oder Versionsdateien.

## Verpflichtende Ablaufkette

| Job | Verbindlicher Nachweis | Jobgrenze |
| --- | --- | --- |
| `connect-four-runtime` | Exakt freigegebene Native-Quelle, strenger echter Import und der vorhandene `run_connect_four_runtime.py` mit tatsächlichen Flutter-/Godot-Prozessen und Xvfb | 35 Minuten |
| `android-host-compile` | Unveränderter tatsächlicher Kotlin-/Java-Compile plus vorhandene C4-Activity-, Binder- und Bridge-Bytecodeklassen | 35 Minuten |
| `verify-and-build` | Beide vorherigen Jobs; vollständige bestehende Flutter-, Python-, native Gameplay- und Bildprüfungen; tatsächlicher signierter ARM64- und x86_64-Build mit Herkunft und Prüfsummen | 90 Minuten |
| `android-c4` | Derselbe hochgeladene Kandidat, vollständige vorhandene Haupttour und anschließend die neue tatsächliche C4-Tour auf API 35 | 65 Minuten |
| `update-2020-from-2017` | Bestehender vollständiger 2017→2020-Erhaltungsablauf mit ursprünglicher Baseline, Offline-Lernen, Kart, Neustart und drei Fold-Ständen | 55 Minuten |
| `verify-c4-candidate` | Erfolg aller fünf Jobs, erneute echte APK-/Signatur-/PCK-Prüfung beider ABIs und Wiederholung der reinen Originalbelegprüfungen | 25 Minuten |

Die bestehenden Build- und Updatebefehle bleiben erhalten. Der neue Lauf verwendet weder einen 2019-Receipt-Prüfer noch einen 2019-Publisher. Seine abschließende Datei `C4-CANDIDATE-FACTS.json` benennt ausschließlich einen geprüften **Testkandidaten** und setzt `release_approved`, `api37_approved` und `physical_arm64_tested` ausdrücklich auf `false`. Es gibt keinen Release-Schritt und keine `contents: write`-Berechtigung.

Die Upload-ID und der vollständige Digest des tatsächlichen Kandidaten werden als Buildoutputs an die Geräte- und Abschlussprüfung übergeben. Originale Run-/Job-/Artefaktmetadaten müssen Repository, Workflow, Branch, PR-Ereignis, Commit, Versuch und Artefakt eindeutig bestätigen. Die Darstellung des Digests wird lediglich zwischen dem Hexwert des Upload-Outputs und dem REST-Präfix `sha256:` vereinheitlicht; der komplette Wert muss weiterhin übereinstimmen.

## Was die neue Android-Beobachtung tatsächlich verlangt

Die Probe öffnet C4 über die reale Flutter-Spielekachel. Sie liest anschließend ausschließlich die ursprünglichen privaten Dateien der bestehenden C4-Bridge, den Originalzustand des Dart-Controllers, den gespeicherten Dart-Rundensatz, die tatsächlichen Activity-/Prozessdaten und die vom Renderer veröffentlichte Originalgeometrie. Kein Spielstand, keine Präferenz, kein Brett und kein IPC-Befehl wird direkt geschrieben.

Vor jedem nativen Touch müssen zwei frische Beobachtungen denselben autoritativen Zustand und denselben vollständig sichtbaren, eindeutigen Trefferbereich liefern. Der fortschreitende Activity-Heartbeat, die tatsächliche Android-Dichte, die Android-Fenstergeometrie, sichere Bereiche, mindestens 48 dp und der Hash der Originalaufnahme bleiben verpflichtend. Die Probe berührt den beobachteten Mittelpunkt mittels einer tatsächlichen stationären Android-Geste. Es gibt keine fest eingetragenen Geräteklickkoordinaten.

Der Ablauf verlangt zwei tatsächliche Kinderzüge und zwei anschließende Dart-Botzüge. Der zugehörige ursprüngliche Request muss genau zur vorherigen Revision, Runde, Sitzung und nächsten Sequenz gehören; der anschließende Dart-Zustand muss ihn positiv bestätigen. Die gespeicherte Rundengeschichte und die ursprünglichen sichtbaren Spielsteinpixel werden nochmals geprüft. Die reine Konsistenzprüfung implementiert keine neue Bot-, Gewinn- oder Belohnungsautorität.

Pause, gehaltene Pause und Fortsetzen müssen dieselbe Runde erhalten. Beide Zurück-Touches sind ebenfalls an ihre zwei Originalbeobachtungen gebunden. Nach der Rückkehr müssen der private native Prozess und die alte Sitzung tatsächlich verschwunden sein, Flutter wieder im Vordergrund stehen und die pausierte Runde sichtbar bleiben. Das erneute Betreten über die Flutter-Kachel muss einen anderen privaten Sitzungstoken und nativen Prozess erzeugen, zugleich aber dieselbe gespeicherte Runde mit beiden Zugpaaren erhalten. Abschließend werden beide Rückwege, die vollständige Belegkette und der unveränderte vorherige Lern-/Belohnungsbestand nachgerechnet.

Alle verwendeten Originaldateien stehen in einem lückenlosen Größen-/SHA-256-Index. Fehlende, veränderte, zusätzliche oder symbolisch verlinkte Belege führen zum Fehler. Das abschließende ursprüngliche All-buffer-Log bleibt erhalten; erkannte ANR-, Absturz- und Godot-Fehler verhindern einen erfolgreichen C4-Bericht.

## Tatsächlich ausgeführte lokale Prüfung

Die finale Prüfung unter `evidence/focused-final/` enthält vollständige Ausgaben, genaue Befehle, Exitcodes und Vorher-/Nachher-Hashes. Ergebnis: **17 Android-Belegverträge und 9 Pipeline-/Update-Verträge bestanden, 0 Fehler, 0 Skips**. Diese Fixtures sind ausdrücklich synthetisch. Sie sind keine Geräte-, APK-, Renderer- oder Freigabenachweise.

Ein konkreter Draftfehler wurde separat erhalten: Der Upload-Digest ohne REST-Präfix wurde zunächst abgelehnt. `evidence/upload-digest-draft-red/` enthält den ursprünglichen roten Einzelfall und die damalige Helperquelle. Die finale Prüfung bestätigt die Korrektur, ohne einen falschen Digest zuzulassen. Frühere grüne Teilprüfungen bleiben als eigene Zwischenstände erhalten.

`evidence/actionlint-first/` enthält den erfolgreichen tatsächlichen actionlint-Lauf über die beiden unverändert gebliebenen End-Workflowdateien. `evidence/python-syntax-final.json` bindet die erfolgreiche Syntaxanalyse aller fünf vorgeschlagenen Pythondateien. Die vollständige Suite wurde nicht erneut ausgeführt. Die lokale Pillow-Version meldete im tatsächlichen Log eine DeprecationWarning für `Image.getdata`; dies war weder ein übersprungener Test noch ein unterdrückter Fehler.

## Noch offene reale Abnahme

Der gelieferte Zweiprozessgate wurde hier nicht durch einen simulierten Lauf ersetzt. Ebenso fehlen noch ein neuer vollständiger signierter 2020-Build, dessen echte C4-Android-Tour und die neue tatsächliche Erhaltungsprüfung. Erst deren Originale dürfen den Abschlussvalidator erfüllen. Die Wahl von API 35 entspricht diesem konkreten Testumfang; sie behauptet keine API-37-, physische ARM64-, FPS-, Audioausgabe- oder allgemeine visuelle Freigabe.

Native PR167 und seine zusätzlichen Gesichts-/Schatz-Prüfungen wurden nicht automatisch übernommen. Falls Root diesen getrennten Quellumfang integriert, bleibt dessen exakte Pin- und Gateentscheidung erforderlich. Ebenso prüft Root vor Aktivierung den tatsächlichen 2020-Veröffentlichungsstand, um konkurrierende Kandidaten nicht als dieselbe Freigabe auszugeben.
