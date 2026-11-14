# Native Studio 2020: verpflichtender Renderer-Harness

## Umfang und Quelle

Basis ist ausschließlich `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` aus Ullmann27/lumo-godot. Drei explizite Dateien: neuer Workflow `.github/workflows/lumo-studio-2020.yml`, bestehender `tools/validate_studio.sh` und dessen vorhandene Vertragsdatei `tools/tests/test_nextgen_runner.py`. Der alte 2019-Workflow, aktive Arbeitskopien und Gitrefs wurden nicht geändert.

Der neue Workflow hört auf `chatgpt/lumo-studio-2020-20261114`. Die acht ausgefalteten Pflichtjobs einschließlich der drei Touch-Jobs, ihre Abhängigkeiten, Rechte und Zeitbudgets bleiben erhalten. Nur der Studiojob erhält zusätzlich ffmpeg. Das vollständige Originalartefakt heißt `lumo-studio-2020-native-evidence`; sein nicht ersetzbarer technischer Prerelease-Tag lautet `studio-2020-evidence-$SOURCE_SHA-$artifact_id`. Die bestehenden Source-/ZIP-/Digest-/öffentliches-cmp-Prüfungen und `--prerelease --latest=false` bleiben bestehen.

## Additive Prüfungen

Alle 16 bisherigen Aufrufe mit denselben Budgets bleiben die ersten 16. Alle 37 bisherigen PNGs einschließlich Cards-/Mobile-Sidecars bleiben Pflicht. Neu sind:

| Script | Modus / Budget | Pflichtmarker | Medien |
| --- | --- | --- | --- |
| lumo_facial_regression | headless / 180 s | LUMO_FACIAL_PASS checks=102 | Geometrie-/Neutralpose-/Sprechzustandsregression |
| lumo_facial_capture | Renderer / 420 s | LUMO_FACIAL_CAPTURE_PASS frames=144 | 8 PNGs 640×640, runtime-frames.json, echtes MovieMaker-AVI und vollständig dekodiertes MP4 samt movie.json/ffprobe |
| connect_four_visual_capture | Renderer / 600 s, -- --capture | CONNECT_FOUR_VISUAL_PASS | 4 PNGs mit festen Formaten, visual-state.json |
| treasure_title_contrast_regression | Renderer / 600 s, -- --capture | [TreasureTitleContrast] PASS | 4 PNGs mit festen Formaten, treasure-title-report.json |

Gesamt: **20 Studio-Gates / 53 PNGs**. `LUMO_CAPTURE_DIR` bleibt gesetzt; Facial erhält zusätzlich `LUMO_FACE_CAPTURE_DIR`. Face-Aufnahme: `--resolution 640x640 --fixed-fps 24 --write-movie <capture>/facial-runtime.avi`. Das MP4 entsteht ausschließlich aus diesen echten Frames und dem aufgenommenen Ton, ohne Bildgenerierung oder Zwischenbildberechnung. 24 Bilder/s sind das Aufnahmeformat, kein Geräte-FPS-Nachweis.

Der Fehlerstatus des ursprünglichen strikten Probe-Runners wird explizit vor der Medienverarbeitung zurückgegeben. Marker allein reichen weiterhin nicht: Enginefehler, fehlende Quellen, Timeout und nichtzero Exit bleiben Fehler. Encode, vollständiger Decode und ffprobe müssen ebenfalls mit Exit 0 enden.

## Belegverträge und Grenzen

Der Facial-Sidecar muss eine gültige produktive Silbenlektion Apfel mit dem tatsächlichen lokalen Wortclip, 144 geordnete Zustandsmessungen, fortschreitende gezeichnete Frames und tatsächliche Kiefer-/Lidmeshgewichte enthalten. Hörbare Wiedergabepositionen und Amplitude müssen sich ändern; Stumm-/Stoppabschnitte müssen geschlossen bleiben. Video- und Metadatenbytes werden über SHA256 gebunden. Dies belegt amplitudenabhängige geschlossene Schnauzenartikulation, keine phonembasierte Lippenanimation und keine Androidwiedergabe.

C4 bleibt ausdrücklich eine schreibgeschützte native Bildfixture: vier echte Produktionsszenen mit legalen, original gebundenen v7-Zuständen, tatsächlichen Mesh-/Layout-/48-dp-Bounds und echten Menüwischereignissen. Auf 960 px ist Lumo sichtbar; bei 412 und 640 px blendet das unveränderte Produktlayout ihn bewusst aus. Dieser formatspezifische Vertrag ist exakt `[true,false,true,false]`. Kein Dart-Regel-/Bot-/Save-/Androidnachweis wird daraus abgeleitet; diese Gates liegen separat beim Host.

Treasure bindet die vier vorhandenen Formate 1920×1080, 640×320, 1080×2400 und 2176×1812 samt Dichte/Inset-Fixtures, mindestens 137 Prüfungen, leerer Fehlerliste, ursprünglicher deklarierter Save-Fixture, sicherem Titelrechteck und endlichem Weißhintergrundkontrast ≥7. Die vier PNG-Hashes müssen zum Report passen. **Nur diese neue Gruppe** darf das ausdrücklich verlangte Format 640×320 verwenden; die vorherigen 49 PNGs behalten ihre Mindesthöhe 360. Die bestehende Ellipse des Titels im Porträt wird nicht als vollständig dargestellter Titel ausgegeben. Der C-Test führt echte Rucksack-/Pause-Touches aus und bewahrt die Questidentität; die lokale Save-/Androidgrenzen-Fixture ist kein Gerätelauf.

Neue Felder in renderer-images.json: `facial_runtime`, `facial_movie` (mit `proof`), `connect_four_visual_state`, `treasure_title_report`, jeweils mit Pfad, Bytezahl und SHA256. Frühere Rosterfelder bleiben erhalten.

## Tatsächlich ausgeführt

- Gezielte vollständige Datei `test_nextgen_runner.py`: **13/13 Tests, 28,341 s, 0 Skip, Exit 0**. Enthält alle vorhandenen Tests sowie manipulierte/fehlende neue Bilder und Sidecars, falsche Audio-/Blink-/Mutezustände, falsche C4-Fixtures/Layout-/48-dp-Ziele und 21 gezielte Treasure-Gegenfälle. Ein zusätzlicher Altbild-Gegenfall sichert, dass 640×320 außerhalb der neuen Gruppe weiter abgewiesen wird.
- `bash -n` und actionlint 1.7.12: Exit 0. YAML-/Strukturvergleich bindet dieselben Job-Abhängigkeiten/Rechte/Budgets und alle 16 bisherigen Probeaufrufe.
- Echte vorhandene Face-/C4-Sidecars wurden durch die reinen neuen Reader gelesen; der aktuelle Treasure-Report und alle vier Original-PNG-Hashes wurden ebenfalls tatsächlich geprüft. Es erfolgte hierfür keine erneute Szeneaufnahme.
- Der neue Film-Encoder/-Decoder wurde einmal am erhaltenen tatsächlichen Original-AVI ausgeführt. Das Ergebnis ist bytegleich zum eingefrorenen echten Facial-MP4; FFmpeg vollständiger Decode und ffprobe: Exit 0.
- Der erste Original-C4-Sidecar-Gegenlauf deckte eine falsche pauschale Sichtbarkeitsannahme im neuen Harness auf. Rotlog und vorherige Quelle sind erhalten; die Korrektur prüft nun die tatsächlich vorhandene formatabhängige Sichtbarkeit, einschließlich beider Gegenfälle. Die 19/49-Zwischenstände und ihre Logs bleiben separat erhalten.

Die synthetischen Raster-/Video-Testfixtures dieser Python-Verträge sind ausschließlich Orchestrierungsgegenfälle und werden nicht als Rendererbilder ausgegeben. Ein vollständiger neuer Native-2020-CI-Lauf und die tatsächlichen neuen Artefakte stehen zum Zeitpunkt dieses Pakets noch aus. APK-, Android-, Publisher- und physische Fold7-/60-FPS-Abnahme folgen nicht aus diesem Harnessfreeze.

## Reproduktion

```sh
python3 -m unittest discover -s tools/tests -p test_nextgen_runner.py -v
bash -n tools/validate_studio.sh
actionlint .github/workflows/lumo-studio-2020.yml
```

Nach Integration aller separat eingefrorenen Produkt-/Probequellen führt der neue Workflow den unveränderten echten Enginepfad aus. Die drei Quelldateien und expliziten Belege sind in `native-harness-upload-manifest.json` byte-/modus-/Gitblob-gebunden; Root übernimmt GitHub-Publikation und die neue externe CI.
