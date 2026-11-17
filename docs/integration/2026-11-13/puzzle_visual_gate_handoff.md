# Puzzle-Abnahme und Versionsübergabe — 2026-11-13

## Abnahmevertrag

Host-Ausgangsstand: `143cf7864efa5a1479d78771d582099a05d996d8`.
`scripts/verify_nextgen_delivery.py` verlangt jetzt acht Bildmodule:
`learning`, `jump`, `build`, `settlement`, `garage`, `cards`, `rhythm`, `puzzle`.
Die Änderung betrifft diese Pflichtmenge und die beiden vorhandenen Testdateien
`scripts/tests/test_nextgen_delivery.py` und
`scripts/tests/test_nextgen_review_recovery.py`. Der Recorder selbst benötigt
keine Produktänderung: Er akzeptiert bereits die echten Puzzle-Capture-Pfade
und prüft die vollständige Auswahl vor jedem Schreiben ins Zielverzeichnis.

## Tatsächlicher Native-Artefaktpfad

Die folgenden Dateien wurden lokal gelesen und anschließend direkt gegen
[Native-Commit 2eb6c9ae388b1d79e4ac970088f9235a6aab59f7](https://github.com/Ullmann27/lumo-godot/commit/2eb6c9ae388b1d79e4ac970088f9235a6aab59f7)
abgeglichen. Die Git-Blobs sind identisch:

| Native-Datei | Git-Blob |
| --- | --- |
| `scripts/tests/puzzle_rotation_regression.gd` | `54b5aa74b2e3a9be1479bcdc6eff2bd8ceef705d` |
| `tools/validate_nextgen.sh` | `1ed6e29ae81fa5049e898a97570e830b3fbe4cf2` |
| `.github/workflows/lumo-nextgen-2018.yml` | `5ab4378c251b684999ccd5c5cca90bbbd21df4be` |

Die Probe schreibt über `PUZZLE_ROTATION_CAPTURE_DIR` echte Renderer-PNGs;
im Headless-Modus entstehen diese Bilder nicht. Der Runner setzt die Variable
auf `$LUMO_NEXTGEN_LOG_DIR/captures/puzzle_rotation_regression` und führt
zusätzlich zum Headless-Vertrag einen eigenen Rendererdurchlauf aus.
Der Workflow-Job `new-worlds` verwendet `nextgen-evidence/nextgen` als Logordner
und lädt `lumo-nextgen-2018-native-evidence` hoch. Darin liegen:

```text
nextgen-evidence/nextgen/captures/puzzle_rotation_regression/
  puzzle_rotation_table.png
  puzzle_rotation_hint.png
  puzzle_rotation_placed.png
  puzzle_rotation_640x360.png
  puzzle_rotation_412x915.png
  puzzle_rotation_840x760.png
  puzzle_rotation_compact_menu.png
```

Die Runner-Metadaten heißen `nextgen-evidence/nextgen/source-sha.txt`,
`source-dirty.txt` und `results.tsv`. Die Probe erzeugt keinen eigenen
Puzzle-JSON-Datensatz. Die tatsächlich geprüfte Bildauswahl des Host-Recorders
ordnet einen Originalpfad ausdrücklich `module: "puzzle"` zu; die Tests verwenden
dafür den echten Pfad bis `puzzle_rotation_table.png` mit synthetischen PNG-Bytes.
Eine reale Bildsichtung wird dadurch nicht ersetzt.

## Bestehende Freigabe bleibt historisch gebunden

`config/nextgen-2018-visual-review.json` bleibt unverändert: 18 Originalbilder,
sieben Module, Native `ada5ed81ad62339f15289da62670c0a4f9f7f2b9`,
Workflow-Run `43399721309`, Artefakt `14026025798`, Version 2018.
Es gibt darin keinen Puzzle-Bildnachweis. Dieser Receipt ist keine Freigabe
des neuen Studio-/Puzzle-Pakets und erfüllt die erweiterte Pflichtmenge nicht.
Für den neuen Stand müssen erfolgreiche, exakt quellgebundene Native-Jobs und
tatsächlich gesichtete Originalbilder einschließlich Puzzle vorliegen.

Native-Pin, `APPROVED`-Zuordnungen, `pubspec.yaml` und sämtliche bestehenden
Bildfreigaben wurden nicht verändert. Receipt-SHA256 vor/nach:
`70a93dc1e8ac9a33652946fd5314ac5d14d8220fb088bba574e14f74e50163c3`.

## Gezielte Prüfung

```sh
python3 -m unittest -v scripts.tests.test_nextgen_delivery scripts.tests.test_nextgen_review_recovery
```

Ergebnis: **16 Tests bestanden, keine ausgelassen**. Vor der Verifier-Korrektur
scheiterten genau die zwei ergänzten Negativfälle: Eine Auswahl ohne Puzzle
wurde noch akzeptiert. Danach wird sie sowohl bei der direkten Abnahme als auch
beim Recorder abgewiesen; vorhandene Dateien bleiben unverändert. Bestehende
Verträge für unveränderliche PNGs, Quellenbindung, Artefakt-Digests,
fehlgeschlagene Jobs und echte erneute PNG-Messung bestehen weiter.

Unveränderte Rohlogs sind verlustfrei als `.log.gz` gesichert; die nachstehenden Hashes beziehen sich auf die entpackten Originalbytes. Archivhashes stehen im Manifest. Verzeichnis:
`docs/evidence/integration-20261113/puzzle-visual-gate/`:

| Log | SHA256 |
| --- | --- |
| `before-puzzle-gate.log` | `ac87e5450658c4bd1e50030e94c53a46a24479a3aff82bc8041746c5eda57b16` |
| `recorder-delivery-contracts.log` | `88d1f89561c3d7294ae9ec68deb1b8e725118f49db4370ede2ae15643ff9a6c3` |

## Reale Grenze zwischen 2018 und Producer-2019

Der Integrationsbaum bleibt bei `0.13.6+2018`. Der bestehende Nextgen-Workflow,
Delivery-Verifier, Visual-Receipt, Android-Surface-Einstieg und der
2017→2018-Updatevertrag sind ausdrücklich an 2018 gebunden.

Der getrennte lokale Producer-Baum
`/workspace/scratch/777ac99b0ad0/flutter-delivery` steht beim gelesenen
Commit `a4f1aa9f9d244e365656f293ea13a5153e9c9853` auf
`chatgpt/lumo-kart-graphics-apk-20261113`. Seine acht committed Änderungen
ergänzen eigene `lumo_2019_surfaces_android_probe.py`- und
`lumo_2019_update_android_probe.py`-Einstiegspunkte, einen ausdrücklichen
2017→2019-Migrationsschalter und den Ausschluss von 2019 aus dem allgemeinen
Workflow. Auch dort lautet `pubspec.yaml` weiterhin `0.13.6+2018`;
`verify_legacy_release_pin.py` enthält an diesem Commit keinen
`APPROVED[2019]`-Eintrag.

Bei der Leseprüfung waren der neue `lumo-kart-graphics-2019.yml`-Workflow,
zwei Kart-Graphics-Verifier, ihre zwei Testdateien und
`docs/KART_GRAPHICS_2019_DELIVERY.md` noch ungetrackt. Das ist laufende
Producer-Arbeit, keine übernommene 2019-Lieferung. Dieser Patch übernimmt
keine dieser Dateien und erzeugt weder eine neue Version noch einen Release.
Die endgültige Übergabe benötigt einen vollständigen veröffentlichten
Producer-Stand mit eigener geprüfter Quellenzuordnung und den zu 2019
gehörenden Nachweisen; die vorhandenen 2018-Belege werden nicht umetikettiert.
