# C4 2020: verifiziertes Delivery-Bundle, keine aktive Veröffentlichung

## Eingefrorener Anschluss

Dieser getrennte Patch basiert auf den sieben unveränderten C4-v1-Dateien, die Root im Host `8dd2ad1fc2f04a8a116c15147436da3c15102b87` / Tree `37ac9221832bc4ec8d0b2faf98bcd1360f2d103c` veröffentlicht hat. Er ändert ausschließlich die vier unter `proposed/` abgelegten Repositorypfade. Der alte v1-Pack bleibt unverändert. Keine Worktree-, Index-, Commit-, Ref-, Release- oder Workflowdispatch-Aktion wurde ausgeführt.

Die sechs fachlichen C4-Jobs bleiben mit ihren bisherigen Bedingungen und Prüfungen erhalten. Der tatsächliche Native-Build erhält `ffmpeg` für den veröffentlichten Facial-Movie-Gate sowie einen verlustfreien vollständigen `nextgen-runner.log` mit bestehendem `pipefail`. Die komplette Ausgabe der bestehenden Script-Discovery wird zusätzlich als kleines unverändertes Artefakt bewahrt, damit die tatsächlich ausgeführten 23/17/30 PCM-Verträge erneut nachweisbar sind.

Der neue siebte Job `prepare-c4-delivery` benötigt alle sechs erfolgreichen Jobs, denselben internen C4-PR-Branch und denselben Host-HEAD. Er hat nur Actions-/Contents-Leserechte. Er liest Originalmetadaten, prüft beide signierten APKs und ihr identisches PCK mit dem bestehenden Verifier erneut, wiederholt die reine Belegprüfung für echten C4-Zweiprozesslauf, API35-Touch/IPC/Return und 2017→2020-Erhaltung und vergleicht die finalen Originalfacts. Die 70 PCM-Assertions bleiben ausdrücklich eine synthetische JVM-Plattformgrenze.

Der Nativeanschluss verwendet den tatsächlichen `config/godot-source.json`-Pin und den von Root separat veröffentlichten 52er-Vertrag (`gate-contract.json`, SHA256 `bacf00a979217d3d4394e74e221886d9839cd400c42c55bf32b8fb0ec7ce0018`). Weder der frühere 27ae-Stand noch der vorläufige 7e03-Stand ist als akzeptierter Pin fest eingebrannt. Alle 52 tatsächlichen Logpaare, die unveränderten Rastergruppen 24/4/6/7 sowie die zusätzlichen 16 PNGs, drei Sidecars und der gebundene Facial-Movie-/ffprobe-Nachweis sind Pflicht. PNGs werden vollständig dekodiert; die vorhandenen älteren schreibenden Helper laufen nur in einer wegwerfbaren Kopie. Der neue Helper wird mit `write=False` aufgerufen. Originalmanifeste werden nicht umgeschrieben.

## Inhalt und Grenzen des neuen CI-Artefakts

`lumo-connect-four-2020-delivery-bundle` enthält die signierte ARM64-Test-APK, deren SHA256-Datei, ursprüngliche Build-/PCK-Provenienz, ursprüngliche C4-/Runtime-/Update-Berichte, die vollständig berechneten Deliveryfacts, den Signaturprüfbericht, die reinen Publikationsplan-Dateien und die ursprünglichen API-Antworten. Es sind zehn exakt indizierte Release-Assets plus Audit/Plan. Die vollständigen Raster-/Movie-Payloads und umfassenden ursprünglichen Spielprotokolle bleiben in ihren gesonderten Originalartefakten desselben Actions-Laufs; sie werden hier erneut gelesen/geprüft und mit Original-Artifact-ID/Digest sowie Datei-/Raster-/Loghashes gebunden, nicht als im Bundle enthalten ausgegeben. Die x86-APK bleibt ebenfalls im unveränderten Candidate-Artefakt; ihre frische Signatur-/PCK-Prüfung ist Bestandteil der Facts.

Das Ergebnis heißt `VERIFIED_TEST_BUNDLE_NOT_PUBLISHED`; `published` und `release_approved` bleiben false. Es ist weder eine 2019-Receipt-Umdeutung noch eine API37-, physische ARM64-, Android-Audio-, FPS- oder menschliche Bildfreigabe. Der vorbereitete URL-String ist kein bestätigter öffentlicher Download.

## Publikationsgrenze

Die offizielle GitHub-Dokumentation verlangt für diesen Workflow-ändernden Zielcommit eine zusätzliche Workflows-Schreibberechtigung, die der Actions-GITHUB_TOKEN nicht erhalten kann. Eine Ausnahme durch einen bereits bestehenden Tag ist nicht dokumentiert. Root hat keinen geeigneten vorhandenen Release-Schreibconnector oder Credential nachgewiesen. Deshalb wurde kein nicht ausführbarer Publisher aktiviert.

`publication/` enthält getrennt eine konkrete, nicht im Repositorypatch enthaltene Referenzprozedur samt Voraussetzungen. Sie erfordert einen ausdrücklich bereitgestellten geeigneten externen Zugang, prüft vor einem neuen Tag und nochmals vor Publish den kompletten erfolgreichen Sieben-Job-Lauf, die aktuelle PR und das vollständig CRC-/SHA-geprüfte ursprüngliche Bundle. Existierende Tags/Releases/Assets werden nie ersetzt. Erst ein tatsächlicher unauthentifizierter öffentlicher APK-Download mit gleichen Bytes kann einen externen Receipt erzeugen. Server-Immutability wird nur anhand des tatsächlichen GitHub-Felds berichtet. Diese Prozedur wurde nicht ausgeführt; nur ihre Shellsyntax wurde geprüft.

## Tatsächliche lokale Prüfung

- 30 neue gezielte Delivery-/Archiv-/Gate-Gegenfälle: PASS, 0 Fehler, 0 Skips. Die dabei geprüften Verifier-, Workflow- und Testbytes sind im finalen Freeze unverändert.
- 9 bestehende C4-Workflow-/Erhaltungsverträge nach der exakten tee-Erwartungsanpassung: PASS, 0 Fehler, 0 Skips.
- Actionlint für den finalen Workflow: Exit 0.
- `bash -n` für die getrennte inaktive Publikationsprozedur: Exit 0.

Die teuren tatsächlichen APK-/Geräte-/Enginegrenzen sind in den neuen Offline-Tests ausdrücklich gestubbt, wo nur der anschließende Beleg-/Dateitransport geprüft wird. Kein solcher Fixture ist eine echte APK- oder Androidabnahme.

Die ursprünglichen roten Ergebnisse bleiben unverändert erhalten: Der erste Parser las einen tatsächlich mehrzeiligen Facial-Befehl fälschlich als getrennte Zeilen; der gezielte Red ist in `evidence/multiline-native-red/`. Ein späterer bestehender Workflowtest erwartete beim extrahierten letzten Befehl noch ein bereits weggefallenes Zeilenende; `focused-readonly-v1/suite-2.log` bewahrt den echten Fehler. Seine neue Erwartung bindet exakt denselben einzelnen Befehl mit dem zusätzlich autorisierten tee. Frühere erfolgreiche, aber inzwischen abgelöste Publisher-Entwürfe sind unter `pre-auth-draft` und `focused-first` als historische Vorbereitung erhalten und wurden nie aktiviert.

`source-freeze.json`, `delivery.patch`, `evidence/final-test-bindings.json` und `handoff.json` sind die maßgeblichen Übergaben. Der gesondert beauftragte C4-Deadline-Nachtrag wird in einem anderen Pack erstellt und ändert diesen Freeze nicht.
