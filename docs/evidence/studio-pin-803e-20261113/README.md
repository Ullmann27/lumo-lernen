# Studio 2019: geprüfte Native-Identität 803e

Diese Änderung aktualisiert ausschließlich die explizit erlaubte Native-Identität für Build 2019 auf `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` und den zugehörigen Regressionstest. Sie erteilt keine APK-, Android-, Update-, Performance- oder Veröffentlichungsfreigabe.

## Quellenbindung

Die beiden ursprünglichen Dateien wurden vor der Bearbeitung direkt aus dem veröffentlichten Host-Commit `39ddc673577e31e76fb992a1b49ef67d1deee908` gelesen. Ihre zurückgegebenen Git-Blob-IDs wurden aus den Originalbytes nachgerechnet und mit den lokalen Dateien verglichen. Das absichtlich alte lokale Git-HEAD wurde nicht als Basis verwendet. Die vollständigen gelesenen Inhalte stehen in `baseline-fetch-original.json`; der Vergleich steht in `before-binding.json`.

Der neue Native-Commit gehört zum tatsächlich erfolgreichen Run `43524051371`, Versuch 1. Das geprüfte Gesamtartefakt `14085523056` hat SHA256 `3b4fcac817efd007797658117f3c62185e3834cbdd624de02d6072fce688a798`. Der aktuelle lokale Pin und der neue visuelle Receipt waren vor diesem Auftrag bereits gesetzt; beide wurden hier nicht geändert.

## Tatsächlicher Gegenbeleg und Reparatur

1. Der unveränderte CLI-Prüfer wurde gegen die aktuelle Konfiguration ausgeführt. Er endete mit Exit 1: für Build 2019 wurde noch `796b2818ff729dc5389a92f8bf1f7fd7e6b6d93e` erwartet, während die Konfiguration bereits den geprüften Stand `803e7a62…` enthielt. Originale stdout/stderr und Ausführungsmetadaten sind als `red-cli.*` erhalten.
2. Der neue, ausdrücklich benannte Test gegen die überholte 796b-Identität wurde vor der Policyänderung ausgeführt. Er scheiterte mit `ValueError not raised`, weil die alte Policy diesen Pin noch akzeptierte. Originalprotokoll und Metadaten stehen unter `red-superseded-pin-test*`.
3. In `scripts/verify_legacy_release_pin.py` wurde genau ein 40-stelliger Wert geändert: `APPROVED[2019]`. Sämtliche anderen Bytes der Prüferdatei sind unverändert.
4. In `scripts/tests/test_candidate_2011_pin.py` wurde die positive 2019-Testidentität aktualisiert und die ausdrückliche Ablehnung des alten 796b-Pins ergänzt. Die bestehende Prüfung unbekannter Versionen wird zusätzlich mit dem neu erlaubten 803e-Pin ausgeführt. Vorhandene Herkunfts-, Engine-, Konfigurations- und historische Pinprüfungen bleiben erhalten.

## Ausgeführte Prüfung

```text
python3 -m unittest scripts.tests.test_candidate_2011_pin scripts.tests.test_legacy_release_pin -v
Ran 64 tests in 0.020s
OK

python3 scripts/verify_legacy_release_pin.py
PASS reviewed Lumo build 2019; exact Godot 4.6.3 source 803e7a626ea6ef0aeeda9c37010e844033d3a8e3
```

Die 64 Testmethoden bestehen aus 24 Kandidaten-Pintests und allen 40 bestehenden Legacy-Pintests. Der neue 796b-Gegenfall ist darunter. Die vollständigen Originalprotokolle und jeweiligen Prozesslaufzeiten liegen als `green-pin-tests*` und `green-cli*` bei. `git diff --check` für die beiden bearbeiteten Dateien endete mit Exit 0; sein leeres Originalprotokoll ist ebenfalls erhalten. Keine weitere Testmatrix wurde ausgeführt.

## Bestandsschutz

Der AST-Vergleich bestätigt: Alle 49 früheren Versionspins und sämtliche erlaubten Versionsschlüssel bleiben unverändert. Ein zusätzlicher Bytevergleich bestätigt, dass außerhalb des einen SHA-Werts kein Byte des produktiven Prüfers geändert wurde.

Diese fünf Dateien sind gegenüber dem vor der Bearbeitung gesicherten Zustand bytegleich geblieben:

- `config/godot-source.json`
- `config/studio-2019-visual-review.json`
- `.github/workflows/lumo-studio-2019.yml`
- `pubspec.yaml`
- `tools/android_qa/tests/fixtures/cards_safe_area_2019/manifest.json`

Insbesondere wurde die historische Cards-Fixture nicht auf den neuen Native-Stand umetikettiert. Die vollständigen Einzelhashes, früheren Pinwerte und finalen Sourcehashes stehen in `preservation-and-source-freeze.json`. Der genaue Diff gegen den veröffentlichten Host-Stand steht in `pin-against-39dd.patch`.

Root übernimmt die GitHub-Integration. Dieser Auftrag hat keine Branch-, Workflow-, Receipt- oder GitHub-Mutation ausgeführt; die beiden gezielt bearbeiteten lokalen Source-/Testdateien werden über das explizite Uploadmanifest übergeben.
