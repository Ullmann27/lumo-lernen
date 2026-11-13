# LUMO Drehpuzzle: echter Runtimefilm

Der Film **Lumo-Drehpuzzle-Runtime.mp4** zeigt zehn Sekunden der unveränderten produktiven Godot-Szene `res://scenes/creative/puzzle_world.tscn`. Ein Teil wird durch echte, automatisiert zugestellte Touch-Ereignisse ausgewählt, über den vorhandenen Knopf zweimal um 90° gedreht, über das Brett gezogen und am passenden Ziel losgelassen. Die Spielmechanik rastet es selbst ein und speichert den Fortschritt.

## Identität und überprüfter Umfang

- Native Quelle: `76980a941fa05d047574d8cc386d3249d93ffca3`.
- MP4: **308,729 Bytes**, SHA256 `1208b51fce515a5d3422f755a7524a77647b235b49519b610875b7a286b1128b`.
- Format: **960 × 540 Pixel, 240 Bilder, 24 fps, 10,000 Sekunden**, H.264, ohne Tonspur.
- Renderer: Godot 4.6.3, X11 auf isoliertem Display 95, OpenGL Compatibility, Mesa llvmpipe. Gemessene Dauer des lokalen Aufnahmelaufs: **46.112 Sekunden**.
- Der fertige Film wurde vollständig dekodiert; Exit 0, leeres Fehlerlog. FFprobe zählt genau 240 Bilder. Acht daraus dekodierte PNGs wurden einzeln geöffnet und visuell geprüft.
- 24 relevante Quellen/Assets wurden als Git-Blobs gegen den exakten GitHub-Commit geprüft und vor/nach dem Lauf per SHA256 verglichen. Alle sind unverändert. Es wird kein vollständig sauberer lokaler Checkout behauptet.

**24 fps bezeichnet das feste Aufnahmeformat und den Aufnahmetakt. Es ist kein Nachweis für Android, Fold7, Eingabelatenz oder gemessene Gerätebildrate.**

## Ablauf und Anfangszustand

Für die Aufnahme werden vor dem Eintritt der unveränderten Szene in den Baum ausschließlich die Auswahlwerte `selected_count=6` und `selected_rotation=true` gesetzt. Das vorhandene Motiv bleibt 3 (Leuchtturm-Bucht). RNG-Seed: `20191113`; die anfängliche Orientierung selbst folgt der vorhandenen Formel `posmod(id * 3 + motif + 1, 4)`.

Das eigene XDG-Verzeichnis beginnt ohne Spielstand. Der echte Startknopf erzeugt alle Teile mit der Produktionslogik. Der Recorder weist weder Teilpositionen noch Kamerapositionen, Züge, Erfolge oder gespeicherten Fortschritt zu. Im Film beginnt Teil 2 mit `turn=2` und 0/6 gelegten Teilen.

| Zeitpunkt | Echte Interaktion und sichtbares Ergebnis |
| --- | --- |
| 1,000 s | ScreenTouch wählt das linke untere Teil; es hebt sich an. |
| 1,167 s | Loslassen erhält die Auswahl für den Rotationsknopf. |
| 1,792 s | Loslassen des bestehenden Drehen-Knopfs: erste Vierteldrehung, `2 → 3`. |
| 3,125 s | Zweiter Knopf-Release: zweite Vierteldrehung, `3 → 0`. |
| 4,333 s | Teil erneut durch echten Ray-Pick berührt. |
| 4,583–7,083 s | 61 ScreenDrag-Ereignisse ziehen es auf einer durchgehenden Eingabebahn zum Ziel. |
| 7,417 s | Touch-Release; die Produktionslogik erkennt Form und Orientierung und rastet das Teil ein. |
| Danach | 1/6 Teile, 4 Produktionszüge, 0 Hilfen; produktiver Autosave enthält das tatsächlich gelegte Teil. |

Die vier Züge bestehen aus dem ersten noch unpassenden Ablageversuch zur Auswahl, zwei Drehungen und der erfolgreichen Ablage. Es wird weder eine vollständige Lösung noch ein Erfolg ohne diese Eingaben behauptet.

## Bildherkunft und Sichtprüfung

`record_puzzle_runtime.gd` liest nach jedem `RenderingServer.frame_post_draw` genau das aktuelle Viewportbild aus. Die gezählten Rendererframes 38 bis 277 sind ohne Lücke aufeinanderfolgend. FFmpeg kodiert diese 240 Original-PNGs, ohne zusätzliche Zwischenbilder, visuelle Komposition, Skalierung oder Frameverdoppelung. Die stetige Bahn ist eine Folge echter Touch-Drag-Eingabepunkte; sie ist keine nachträgliche Bildanimation.

Die acht Dateien `runtime-*.png` wurden **aus der fertigen MP4** dekodiert. Sie zeigen Anfangszustand, Auswahl, beide laufenden Drehungen, erste abgeschlossene Vierteldrehung, freies Ziehen, Schwebeposition über dem Ziel und eingerastetes Teil. Brett, obere Statusanzeige und untere Bedienelemente bleiben in diesen Bildern getrennt und lesbar. `visual-review.json` bindet jede Beobachtung an Dateihash und Framezustand.

## Offen erhaltener Menübefund

Im ersten unveränderten Lauf wurden auch vier echte Stückzahlwechsel und der Wechsel zum Drehmodus im Auswahlmenü durchgeführt. Jeder dieser fünf Releases erzeugte einen nichtfatalen Godot-Fehler `can_process: !is_inside_tree()`. Der bestehende Pfad `_next_count()` beziehungsweise `_toggle_rotation_mode()` ruft `_show_selection()` und `_clear_menu()` synchron auf; dabei wird der gerade seinen Release verarbeitende Button aus dem Baum entfernt. Es wurde kein Absturz oder falscher Spielzustand beobachtet. Der strenge Recorder verwarf diesen Lauf wegen seiner Fehlerzeilen trotzdem als lieferbare Aufnahme.

Die unveränderte Erstprobe, ihre Logs, Quellhashes und Eingabedaten sind vollständig unter `menu-setup-diagnostic/` erhalten. Der hier beschriebene Film umgeht ausschließlich diese vorbereitenden Auswahl-Callbacks durch die offen genannten Anfangswerte. **Der Menüfehler ist damit nicht repariert und keine fehlerfreie Menüabnahme behauptet.** Keine Produktquelle wurde dafür geändert. Ein Nachweis der Auswirkungen auf Android steht aus.

## Dateien und Reproduktion

- `record_puzzle_runtime.gd`: eigentliche externe Godot-Aufnahmeprobe.
- `record_runtime_movie.py`: Source-Bindung, isolierter Renderer, Kodierung, vollständiger Decode, FFprobe und PNG-Auszüge.
- `source-manifest.json`: tatsächliche Quellen, SHA256 vorher/nachher, Git-Blobs, Aufruf und Videohash.
- `input-manifest.json`: alle 10 ScreenTouch- und 61 ScreenDrag-Ereignisse mit Frame und tatsächlichen Koordinaten.
- `runtime-frames.json`: Anfangs-/Endzustand und beobachtete Teilposition, Quaternion, Orientierung und Fortschritt pro Frame.
- `frame-hashes.json`: SHA256 jedes ursprünglichen Renderer-PNGs sowie der acht dekodierten Videobilder. Original- und Decode-Hashes bleiben getrennt, da H.264 verlustbehaftet ist.
- `godot.log`, `run.json`, `renderer-launcher.log`, `encode.log`, `decode-all.log`, `ffprobe.json`: Originalausführungsbelege.
- `visual-review.json`: tatsächliche Einzelbildprüfung und begrenzte Abnahme.
- `SHA256SUMS`: vollständige Dateiliste dieses Evidenzordners, ausgenommen die Prüfsummendatei selbst.

Reproduktion in einer neuen, gleich aufgebauten Evidenzkopie, wenn Display 95 frei ist:

```bash
python3 -B docs/evidence/studio-runtime-puzzle-20261113/record_runtime_movie.py
```

Der Wrapper schützt eine vorhandene MP4 vor Überschreiben. Er benötigt Godot, Xorg, FFmpeg und den bereits vorhandenen nativen `tools/run_local_renderer.py`. Das separate temporäre XDG-Verzeichnis und die X11-Authentifizierung verwaltet der Runner. Keine tatsächlichen Kinderprofile, Produktionsspielstände oder Originalassets werden verändert. Es erfolgt keine Git-/CI-Mutation.

Diese Evidenz ist eine Teilabnahme der aufgezeichneten Puzzleinteraktion. Sie ersetzt weder die vorgeschriebenen CI-Gates noch die noch getrennt zu prüfenden Android-/Update-/Fold7-Nachweise oder die Gesamtanforderungen des Masterauftrags.
