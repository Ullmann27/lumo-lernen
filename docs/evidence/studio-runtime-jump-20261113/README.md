# Original-Lumo: echte Godot-Laufzeitaufnahme

`Lumo-Original-Jump-Runtime.mp4` zeigt **zehn Sekunden aus der produktiven Jump-Szene** bei 960 × 540 Pixeln. Die Aufnahme enthält 240 tatsächlich gerenderte Viewportbilder. Der Aufnahmetakt von 24 Bildern pro Sekunde ist fest vorgegeben; daraus folgt keine Aussage über die Geschwindigkeit eines Android-Geräts.

Der vorhandene Original-Lumo mit 65 Knochen bewegt sich durch echte `InputEventScreenTouch`- und `InputEventScreenDrag`-Ereignisse: langsames Gehen, Beschleunigen zum Lauf, Absprung, Überqueren der Lücke zur zweiten Insel, Landen, seitliches Gehen, erneutes Beschleunigen und Abbremsen sowie ein weiterer Sprung auf der zweiten Insel. Die Probe weist die tatsächlich durchlaufenen Zustände `idle`, `walk_loop`, `run_loop`, `jump_rise`, `jump_fall` und `land` nach. Das Protokoll enthält elf Samples mit horizontaler Verzögerung am Boden, den erreichten Kontrollpunkt 1 und keinen Sturz oder Respawn.

## Herkunft und Prüfung

Die Szene, ihre Kamera, die Physik und die Charakterdateien wurden für diese Aufnahme nicht verändert. Die externe Probe startet `res://scenes/games/jump_islands.tscn` mit Klasse 2, Mathematik und dem vorhandenen ersten Kurs. Sie verwendet isolierte lokale Speicherdaten. `source-manifest.json` enthält die vor und nach der Aufnahme verglichenen SHA-256-Werte der Szene, Steuerung, Original-GLB-Datei, Rig-Anbindung, Clipdaten und des Render-Starters. Der lokale Git-HEAD ist älter als die Arbeitskopie; deshalb enthält diese Evidenz ausdrücklich keine Behauptung eines sauberen Checkouts oder eines endgültigen Native-Commits.

Gerendert wurde mit Godot 4.6.3 unter isoliertem X11 und Mesa llvmpipe im Compatibility-Modus. Die Aufnahme dauerte rund 90,6 Sekunden reale Rechenzeit. Dieser Software-Renderer meldet die bekannten Einschränkungen für V-Sync-Umschaltung, Screen-Space-AA und volumetrischen Nebel; im Laufzeitlog stehen keine Laufzeitfehler.

FFmpeg hat alle 240 Bilder des fertigen H.264-Films vollständig decodiert. `decode-all.log` ist leer, `ffprobe.json` bestätigt Auflösung, Bildanzahl und zehn Sekunden Laufzeit. Die drei PNG-Dateien wurden aus den fertigen Videoframes 51, 60 und 75 ohne Skalierung oder Zwischenbildberechnung extrahiert und einzeln angesehen. Laufpose, Absprunghöhe, Bodenkontakt auf Insel 2 sowie getrennte und lesbare Bedienelemente waren erkennbar. `visual-review.json` bindet jeden Befund an den jeweiligen Bildhash und den passenden Laufzeitsample. Die Gameplaykamera bleibt unverändert; Lumo erscheint darin kleiner als in den separaten Studio-Nahaufnahmen.

## Reproduktion

Bei nebeneinanderliegenden Arbeitskopien `lumo-lernen` und `lumo-godot`:

```sh
python3 docs/evidence/studio-runtime-jump-20261113/record_runtime_movie.py
```

Der Starter verwendet Display 98, `lumo-godot/tools/run_local_renderer.py`, eine temporäre Folge echter PNG-Bilder und anschließend FFmpeg. Die temporären 240 Rohbilder werden nach erfolgreicher Codierung und vollständiger Decodierung gelöscht. Im Evidenzordner bleiben nur der Film, drei geprüfte Standbilder, die kurze Probe, das Reproduktionsskript, Hashmanifeste und Logs. Die erste MovieMaker-Aufnahme hatte entgegen der angeforderten Fenstergröße 720 × 1280 Pixel; sie wurde verworfen und gelöscht. Ihre begrenzte Fehlernotiz bleibt zur Nachvollziehbarkeit erhalten.

**MP4-SHA-256:** `d119c24cec8a7a1bcb37452be6f5f027cb085242e7cc9b1e977a536120de4a4b`

Diese lokale Aufnahme ergänzt die Gameplay-Evidenz. Sie ersetzt weder die noch ausstehende endgültige GitHub-Quellbindung noch eine Abnahme auf dem physischen Android-Zielgerät.
