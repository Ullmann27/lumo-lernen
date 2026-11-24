# Original-Lumo: gerenderte Studio-Animation

`Lumo-Original-Studio-Walk-Sprint.mp4` zeigt die tatsächlich gespeicherten
Blender-Actions `studio_walk` und `studio_sprint` am unveränderten Originalmodell.
Es ist ein Offline-Studiofilm mit Cycles CPU, keine Aufnahme des laufenden Spiels
und keine Messung der Android-Bildrate.

## Inhalt und Zeitachse

| Zeit im Film | Gespeicherte Action | Darstellung |
| --- | --- | --- |
| 0,00–2,00 Sekunden | `studio_walk` | Zwei Wiederholungen des einsekündigen Gehzyklus |
| 2,00–3,80 Sekunden | `studio_sprint` | Drei Wiederholungen des 0,6-sekündigen Sprintzyklus |

Die Abschnitte sind durch einen Schnitt getrennt. Das Video zeigt die Actions
auf der Stelle, entsprechend ihrer gespeicherten Ausführung ohne Root Motion.
Es behauptet keinen fertig animierten Übergang zwischen beiden Bewegungsarten.

Für den Gehzyklus wurden 25 echte Einzelbilder gerendert, für den Sprintzyklus
15. FFmpeg wiederholt diese 40 Bilder nach der angegebenen Zeitachse zu 95
Videoframes. Es werden keine zusätzlichen Zwischenbilder erzeugt, keine
Screenshots ineinander überblendet und keine generativen Bilder verwendet.

## Herkunft und Renderverfahren

- Originalmodell: `assets/characters/lumo_animated/Lumo-Animated-Mobile.glb`
- Action-Bibliothek: `docs/evidence/studio-character-20261113/Lumo-Studio-Actions.blend`
- Zugehöriges Autorenwerkzeug: `tools/lumo_animation/author_platform_clips.py`
- Blender 4.3.2, Cycles CPU, 512 × 512 Pixel, 64 Samples pro Einzelbild.
- Denoising und adaptive Sampling sind deaktiviert; AgX-Farbtransformation.
- Die Datei `.blend` enthält die gespeicherten Actions. Der Renderer importiert
  das Original-GLB, hängt diese Actions an dessen vorhandenes Skelett an und
  nutzt den vorhandenen Aufbau der Studioszene aus dem Autorenwerkzeug.
- Die Geometrie und das Gesicht werden nicht verändert. Native Quellassets
  werden nicht geschrieben; ihre SHA-256-Werte werden vorher und nachher geprüft.

Die MP4-Datei verwendet H.264, `yuv420p` und eine Medienrate von 25 fps. Diese
Medienrate sagt nichts über die Leistung des Spiels auf einem Gerät aus.

## Nachweise

`render_provenance.json` enthält die Quelldigests, Actionnamen, verwendeten
Quellframes, Renderparameter, Renderzeiten und SHA-256-Werte aller 40 PNGs.
`video_provenance.json` enthält den SHA-256-Wert der MP4, den vollständigen
FFmpeg-Aufruf, überprüfte Metadaten und die Zuordnung sämtlicher 95 Videoframes
zu den gerenderten PNGs. Beide JSON-Dateien enthalten ausdrücklich den Umfang
und die Grenzen des Nachweises.

`render.log` und `ffmpeg-encode.log` stammen aus den tatsächlichen Ausführungen.
Die MP4 wird nach dem Kodieren vollständig dekodiert; Bildgröße, Bildanzahl,
Medienrate und Dauer werden mit FFprobe überprüft.

`probe_provenance.json` und `probe_render.log` dokumentieren den vorangestellten
Budgettest mit 24 Samples. Dieses Proberenderbild wird beim endgültigen Render
durch die Fassung mit 64 Samples ersetzt und nicht für die Filmprovenienz
herangezogen.

## Reproduktion

Im Stammverzeichnis von `lumo-lernen`, bei einer benachbarten Arbeitskopie
`../lumo-godot`:

```bash
blender --background --factory-startup \
  --python docs/evidence/studio-animation-20261113/render_studio_animation.py \
  -- \
  --native-project ../lumo-godot \
  --output docs/evidence/studio-animation-20261113
python3 docs/evidence/studio-animation-20261113/encode_studio_animation.py
```

Die unabhängigen aktuellen Godot-Rendererbilder werden gesondert in
`../studio-2019-review-notes/motion-b5-review.json` geprüft. Dieser Studiofilm
ersetzt weder jene Prüfung noch die Android-Abnahme.
