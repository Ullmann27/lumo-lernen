# Echte Laufzeitaufnahme: 12 Würfel gerecht auf 3 Gruppen verteilen

[Film ansehen oder herunterladen: Lumo-Lernen-12-durch-3-Runtime.mp4](Lumo-Lernen-12-durch-3-Runtime.mp4)

Die unveränderte produktive Godot-Lernszene verteilt zwölf echte Würfel auf drei Gruppen. Zwölf synthetische Touch-Eingaben auf **„Einen Würfel verteilen“** ergeben **vier gleichmäßige Verteilrunden**: `[1, 1, 1]`, `[2, 2, 2]`, `[3, 3, 3]`, schließlich `[4, 4, 4]`. Der fertige Film enthält 240 tatsächlich aufeinanderfolgende Viewportframes in 960 × 540 Pixeln und dauert bei einem festgelegten Aufnahmeformat von 24 Bildern pro Sekunde genau 10 Sekunden.

Es wurden weder Produktdateien noch vorhandene Tests, Kameras oder Spielregeln verändert. Dieser Film ist ein zusätzlicher lokaler Laufzeitnachweis; er ersetzt keine Android-Abnahme.

## Tatsächlicher Ablauf und Eingaben

Die externe [Captureprobe](record_learning_runtime.gd) lädt `res://scenes/learning/learning_world.tscn` und übergibt `equal_sharing`, `a = 12`, `b = 3` über die normale `SceneRouter.launch_options`-Schnittstelle. QA-Kinderkennung und Benutzerdatenverzeichnisse sind isoliert. Die produktive `capture_options`-Abkürzung wird nicht benutzt. Nach 24 Aufwärmframes beginnt die Aufnahme.

Zwischen den Videoframes 24 und 157 werden zwölf echte `InputEventScreenTouch`-Drück-/Loslasspaare am Mittelpunkt des vorhandenen Verteilknopfs eingespeist. „Echt“ bezeichnet hier den Godot-Eingabepfad: Es sind automatisierte QA-Ereignisse, keine menschlichen Fingerbewegungen. Die Probe ruft weder den Aktionshandler noch die Mengenänderung direkt auf. Ein passiver Beobachter zählt zwölf tatsächliche `pressed`-Signale des Produktionsbuttons. Alle 24 Touch-Ereignisse und zwölf Signale stehen in [input-events.json](input-events.json).

Für jeden der 240 aufgenommenen Frames protokolliert [runtime-frames.json](runtime-frames.json) die drei Gruppenzahlen, alle zwölf realen 3D-Würfelpositionen, laufende Bewegungen, den Zustand des Buttons, Erklärung und Status sowie Lumos Animationszustand. Die Probe prüft, dass keine Menge verschwindet oder hinzukommt und der Größenunterschied zwischen den Gruppen nie größer als eins ist. Alle räumlichen Gruppenzähler stimmen mit dem Laufzeitzustand überein.

Der logische Abschluss erfolgt in Videoframe 157. In Frame 167 sind auch alle Bewegungen abgeschlossen; alle zwölf Würfel erreichen ihre produktiven Zielpositionen mit weniger als 0,001 Metern Abweichung. Der Endzustand bleibt bis Frame 239 sichtbar. Die erfassten Engine-Prozessframes reichen lückenlos von 24 bis 263. Das Originalmodell wird als importierte Szene mit 65 Knochen geladen. Die Laufzeitdaten enthalten die Zustände `greeting_wave` (25 Frames), `agree_nod` (116), `celebrate` (49) und `idle` (50); diese Zahlen bezeichnen protokollierte Zustandsnamen, keine Einzelbildprüfung jeder Animation.

## Quellbindung und unveränderte Dateien

Die Aufnahme bindet die 31 in [source-manifest.json](source-manifest.json) einzeln aufgeführten Produkt-, Asset- und Renderpfade an:

- Native Commit: `76980a941fa05d047574d8cc386d3249d93ffca3`
- Native Tree: `8df22766bd0dbae31aacaa26c0228811c027686e`
- Film-SHA256: `921e41ef7a8d3002c72c9ea089851cd4f2e445ace25b89fc9e3a795b48d30a5e`
- Filmgröße: 555.987 Bytes

Vor der Aufnahme wurde jeder aufgeführte Pfad bytegenau mit `git show <Native-Commit>:<Pfad>` verglichen. Der Git-Blob und SHA256 sind gespeichert. Nach der Aufnahme wurden dieselben Dateien nochmals gehasht: Alle 31 stimmen unverändert mit den gebundenen Commitbytes überein. Die Quellen des Recorders und der Probe sowie die Hashes aller 240 ursprünglichen Renderer-PNGs sind ebenfalls dokumentiert.

Der lokale Checkout-HEAD lautet weiterhin `ada5ed81ad62339f15289da62670c0a4f9f7f2b9`. Deshalb beruht der Nachweis ausdrücklich auf den einzeln verglichenen Pfaden; er behauptet weder einen insgesamt sauberen Checkout noch eine Prüfung aller Importcache-Dateien. Die temporäre vollständige PNG-Sequenz wurde nach erfolgreicher Codierung und vollständiger Videodecodierung gelöscht; ihre Hashes bleiben im Manifest, der Film und die sechs dekodierten Stichproben bleiben erhalten.

Das automatisch erzeugte Quellenmanifest trägt weiterhin den Zustand `recorded_encoded_and_fully_decoded_awaiting_visual_review`, den es am Ende des Aufnahmeprogramms geschrieben hat. Die anschließende tatsächliche Sichtprüfung ist getrennt und ohne Umschreibung des Aufnahmeprotokolls in [visual-review.json](visual-review.json) dokumentiert.

## Render- und Videoprüfung

Die Aufnahme lief über den vorhandenen `tools/run_local_renderer.py` auf einem isolierten X11-Display `:105` mit Godot 4.6.3, OpenGL Compatibility und Mesa llvmpipe. Der Renderer beendete die Probe mit Exit 0 und:

```text
[LearningRuntimeMovie] PASS frames=240 taps=12 rounds={"1":[1,1,1],"2":[2,2,2],"3":[3,3,3],"4":[4,4,4]}
```

FFmpeg codierte ausschließlich die 240 ursprünglichen Viewport-PNGs zu H.264, CRF 18, YUV420p. Es wurden keine Zwischenbilder erzeugt, Frames interpoliert oder Szenen aus Standbildern montiert. Anschließend wurde das **gesamte** MP4 mit FFmpeg ohne Fehler decodiert. [ffprobe.json](ffprobe.json) bestätigt H.264, 960 × 540, `24/1`, 240 decodierbare Frames und 10,000 Sekunden. [decode-all.log](decode-all.log) ist leer, der Decodeprozess endete mit Exit 0.

Die folgenden sechs Bilder wurden aus dem fertigen MP4 ohne Größenänderung dekodiert und jedes einzeln tatsächlich geöffnet:

| Dekodierter Frame | Bild | Geprüfter Inhalt |
| --- | --- | --- |
| 12 | [Start](runtime-learning-start.png) | Drei Gruppen mit 0; Aufgabe, Originalfuchs, Ablage und Bedienleiste sichtbar. |
| 29 | [Würfel in Bewegung](runtime-learning-moving.png) | Ein realer Würfel auf dem Weg zum Tablett; Verteilknopf während der Bewegung deaktiviert. |
| 59 | [Runde 1](runtime-learning-round-1.png) | Je ein Würfel, drei Zähler mit 1, neun Würfel verbleiben. |
| 95 | [Runde 2](runtime-learning-round-2.png) | Je zwei Würfel, drei Zähler mit 2, sechs Würfel verbleiben. |
| 131 | [Runde 3](runtime-learning-round-3.png) | Je drei Würfel, drei Zähler mit 3, drei Würfel verbleiben. |
| 239 | [Abschluss](runtime-learning-complete.png) | Je vier Würfel, drei Zähler mit 4, leere Ablage und vollständiger Erklärungssatz. |

In diesen sechs tatsächlich angesehenen Bildern wurde kein blockierendes Darstellungsproblem festgestellt. Gruppenzahlen, Erklärung und Bedienelemente sind lesbar; die drei Gruppentabletts werden nicht vom HUD verdeckt. Im Bewegungsbild ist die logische Zuordnung bereits aktualisiert, während der Würfel noch sichtbar unterwegs ist. Das entspricht dem protokollierten Animationszustand. Es wird keine visuelle Einzelprüfung aller 240 Frames behauptet.

## Grenzen dieses Nachweises

Die gesamte Aufnahme beanspruchte 73,134 Sekunden reale Rechenzeit. **24 fps sind das feste Simulations- und Videoformat, keine gemessenen 24 oder 60 fps eines Geräts.** Es handelt sich um einen lokalen Linux-Software-Renderer, nicht um Android, das Galaxy Z Fold7 oder einen Test von Wärmeentwicklung und Touch-Latenz.

Das originale [godot.log](godot.log) enthält drei konkrete Rendererwarnungen: Der X11-Softwaretreiber kann den V-Sync-Modus nicht ändern; Screen-space AA und volumetrischer Nebel werden vom Compatibility-Renderer nicht unterstützt. Diese Aufnahme weist diese Effekte daher nicht nach. Sprache und Ton sind für die Aufnahme ausgeschaltet, das MP4 hat keine Audiospur; es ist kein Nachweis von Aussprache oder Lippensynchronität.

Die vorhandene produktive Lernszene und der Verteilknopf werden benutzt. Der Flutter-/Android-Eintritt, die Rückkehr zur Aufgabe, Speicherstand- und Profiltests sowie die Funktionen der beiden anderen unteren Buttons gehören nicht zum getesteten Eingabepfad dieses Films. Die gesonderten CI- und Android-Gates bleiben erforderlich.

## Reproduktion

Voraussetzungen sind der gebundene Native-Commit im lokalen Git-Objektspeicher, die passenden unveränderten Produktdateien, importierte Assets sowie Godot, Xorg, FFmpeg und FFprobe. Das vorhandene Renderwerkzeug isoliert Display und QA-Benutzerdaten. Der Display muss frei sein; ein vorhandenes Xorg-Lock führt zum Abbruch. Der Aufruf schreibt die Filmbelege in diesen Ordner und sollte für eine neue Aufnahme in einer separaten Kopie des Evidenzordners erfolgen, um die jetzigen Belege zu erhalten.

```sh
python3 docs/evidence/studio-runtime-learning-20261113/record_runtime_movie.py --display 105
```

Arbeitsverzeichnis: Hostrepository `lumo-lernen`. Die genaue tatsächlich ausgeführte Godot-Kommandozeile und deren temporäre Pfade stehen im Quellenmanifest. [run.json](run.json), [renderer-launcher.log](renderer-launcher.log), [encode.log](encode.log), die Decodeprotokolle und [decoded-samples.json](decoded-samples.json) ergänzen den Nachweis.
