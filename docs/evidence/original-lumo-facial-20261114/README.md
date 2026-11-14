# Original-Lumo: Gesicht, lokale Sprache und reale Lehreraufnahme

## Ergebnis und klare Grenze

Im isolierten Kandidaten sind echte zusätzliche Lider, vier begrenzte Blickmorphs und eine geschlossene Schnauzenartikulation an den tatsächlich verwendeten Original-Lumo angeschlossen. Der Lehrer nutzt den bestehenden `apply_speech_sample`-Pfad; seine Kieferamplitude folgt den gemessenen PCM-Fenstern und der tatsächlichen lokalen Wiedergabeposition. Mute, Stopp, Pause, überholte Antworten und fehlende Freigaben erzeugen keine erfundene Mundbewegung.

**Noch keine Android-/Fold7-Freigabe:** Der neue Native-/Host-Code wurde hier isoliert geprüft. Die Wiedergabe im Film erfolgt mit Godots tatsächlichem `AudioStreamPlayer` und dem vorhandenen Originalwort `apfel.wav`; der Android-Adapter wurde mit wirklichem Kotlin-Code an ausdrücklich synthetischen Android-Grenzen geprüft. Ein echter MediaPlayer-Gerätelauf steht für diesen neuen Gesichtspfad noch aus. Die Lippen sind nicht phonembasiert; das Originalmodell besitzt keine Mundhöhle. Der sichtbare Kieferhub bleibt bewusst dezent.

- Native-Basis: `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`.
- Host-Basis: `86445f53af5d573549fc8cf03405261611f3cb7e`.
- Keine aktive Repositorydatei, Git-Referenz, Main- oder CI-Freigabe wurde durch diesen isolierten Arbeitsbereich geändert.
- `source-freeze.json` bindet die14 vorgeschlagenen Quellen; `source-against-803e-86445.patch` zeigt Textänderungen. Die neue Attribution begleitet das GLB.

## Gemessener Ausgangsstand

Das unveränderte Original-GLB hat SHA256 `3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`, 21.659 Körpervertices, 30.000 Dreiecke, eine PBR-Oberfläche, eingebettete Originaltexturen, 65 Bones und neun Clips. Die Augen sind auf der zusammenhängenden ursprünglichen Kopfoberfläche bemalt. Es gab keine separaten Augenkugeln, Gesichtsmorphs, Lid-/Kieferbones oder Mundhöhle. Diese Grenzen wurden in Blender und durch originale glTF-Daten gemessen; generische Landmarken wurden nicht als vorhandenes Rig ausgegeben.

Die neuen Lider folgen einer Projektion der tatsächlichen Originaldreiecke und ihrer UV-Textur. Die Konturauswahl ist als Autorenentscheidung ausgewiesen. `evidence/eye-surface/measurement-correction.json` korrigiert einen ursprünglichen Messbericht: Dessen Minimum -0,5 war ein Hintergrundsentinel in13 beziehungsweise3 gefüllten Maskenpixeln, keine anatomische Tiefe. Gemessene gültige Bereiche sind links0,224334–0,294509m und rechts0,224802–0,284257m. Die unveränderte Rohmessung bleibt erhalten.

## Implementierung

| Bereich | Tatsächliche Änderung |
|---|---|
| Ableitung | `Lumo-Facial-Mobile.glb`: Originalbinärdaten, Basisvertices/UVs/Materialien, 65-Bone-Skin und neun Clipdefinitionen erhalten. Die sechs separaten Studio-Bewegungsclips bleiben bytegleich. |
| Lider | Ein zusätzliches vollständig an Head gebundenes Mesh, zwei Materialoberflächen, 2.368 Vertices/4.320 Dreiecke. Vier gekrümmte Schließphasen je Auge, zusammen acht Lidmorphs. |
| Blick | Vier zurückhaltende Morphs der ursprünglichen bemalten Oberfläche, maximal8mm horizontal/6mm vertikal. Beim Blinzeln werden diese ausgeblendet, damit das Auge nicht durch das Lid schiebt. |
| Kiefer | Geschlossene Schnauzenartikulation, maximaler vollständiger Vertexdelta8,623mm. Keine geöffnete Mundhöhle, Zunge, Zähne oder Viseme. |
| Godot | `lumo_facial_pose.gd` schreibt tatsächlich gebundene Meshgewichte; Actor und produktive Lernwelt reichen Zielblick und gültige Wiedergabesamples weiter. Körperbones bleiben unberührt. |
| Import | Nur auf dem neuen dünnen Lidmesh ist automatisch erzeugtes LOD deaktiviert. Die ursprünglichen Körper-LODs bleiben erhalten. Ein echter Renderer-Gegenversuch hatte zuvor morphende LOD-Löcher gezeigt. |
| Android | `LumoSpeechEnvelope.kt` analysiert begrenzte PCM16-WAV-Daten im eigenen Worker. `LumoLearningSpeech.kt` bindet Amplitude an tatsächliche MediaPlayerposition, Streammute und Generation. Root ergänzt separat den Installer. |

Der Original-Lizenz-/Modifikationshinweis bleibt erhalten. Siehe `native/assets/characters/lumo_facial/ATTRIBUTION.md` und die unveränderte ursprüngliche Attribution. Keine neue Cloud- oder Mikrofonabhängigkeit wurde eingeführt.

## Tatsächlich ausgeführte Prüfungen

| Prüfung | Frisches lokales Ergebnis | Aussagegrenze |
|---|---|---|
| GLB-/Kurvenerhalt | Byte-/Accessor-/Skin-/Clipvergleich bestanden;101 Lidstellungen mit Vertices und Dreiecks-Schwerpunkten,0 negative Abstände, Minimum0,114mm | Stichproben an realer Geometrie; keine universelle Kollisionsbehauptung |
| FacialRegression |102 Prüfungen, Exit0, keine Enginefehler | Echte importierte Meshes und gültige produktive8+5-Lerninstanz, Headless |
| Studio-Bewegung |1047 Prüfungen, Exit0; maximaler Blender/Godot-Endeffektorfehler0,000000733m | Erhalt der sechs bestehenden Bewegungsclips |
| Lehrer / Originalrig |34 beziehungsweise21 Prüfungen, Exit0 | Vorhandene Gesten-/Rigverträge erhalten |
| Lernwelt |5340 Prüfungen, Exit0 | Bestehende Lernregeln und Schnittstellen |
| WAV-Hüllkurve |23 Kotlin-Prüfungen bestanden | Tatsächliche Originalwortbytes plus gezielte ungültige WAV-/Abbruchfälle |
| Speech-Lifecycle |17 Kotlin-Prüfungen bestanden | Synthetische Android-Grenze, kein Gerätelauf |
| Echte Aufnahme |144 Messschritte,8 PNG,148 MovieMaker-Frames, Exit0 | Desktop-Produktionslehrer mit Inspektionskamera, nicht Geräte-FPS |

Die aktualisierte102er-Facialprüfung ersetzt die frühere101er-Zählung: Ein zusätzlicher Assert verlangt eine gültige Lernpayload. Alte Originalprotokolle bleiben getrennt. Kein älteres Ergebnis wird als neuer Lauf ausgegeben.

`evidence/native-final/` enthält die Originalprotokolle. Die Aufzeichnung und alle finalen Bildbefunde stehen in `evidence/final-visual-review.json`. A hat beide Kotlinquellen unabhängig gelesen: `evidence/independent-speech-source-review.json`.

## Film und visuelle Prüfung

`evidence/Lumo-Original-Facial-Runtime.mp4` ist1.178.091B groß, SHA256 `3bbc2a491e59a4fd971d95479713cf1e9fff0c59b7cc6de63290512bfdd6b1ac`. H.264,640×640,148 decodierte Frames,6,166667s. Die24FPS sind das Aufnahmeformat. Der lokale Software-Renderer lief deutlich langsamer als Echtzeit; daraus wird kein60FPS-Ziel abgeleitet.

Alle acht ursprünglichen Godot-PNGs und alle sieben finalen Blender-PNGs wurden einzeln geöffnet. Der ganze Film wurde ohne Decodefehler gelesen und jeder seiner148 Frames auf13 vollständigen Kontaktbögen visuell geprüft; zwei kleine Unterrichtsframes wurden zusätzlich in voller Auflösung angesehen. Die letzten drei grauen Bilder zeigen den dokumentierten Szenenabbau.

Die gültige Apfel-Silbenaufgabe ist im ersten Teil sichtbar. Danach zeigt dieselbe produktive Lehrerinstanz unter einer Inspektionskamera Blinzeln, Blickwechsel, drei tatsächliche Wortstarts, Mute und Stopp. Der Film enthält die tatsächlich vom Player ausgegebene Originalaudioquelle, keine nachträgliche synthetische Tonspur. Vor Wiedergabe und nach Stopp ist die gemessene AVI-PCM-Amplitude0; in der per-80dB-Mute-Phase bleibt nur ungefähr ein16-Bit-Quantisierungsschritt. Tatsächliches Kiefergewicht ist in allen neun ausgewerteten Mute-Zeilen und32 späten Stopp-Zeilen0.

Die Lidkontur bleibt als additive Oberfläche erkennbar. Blenderbilder weisen sichtbares Samplingrauschen auf (CyclesCPU48Samples, kein Denoiser). Kieferbewegung und Blickmorphs sind zurückhaltend; die geerbte Kopf-/Körperanimation ist im Film stärker sichtbar. Das ist kein offener Mund- oder phonemgenauer Sprechbeleg.

## Reproduktion / Integration

Die genauen Nativebefehle, Pflichtnamen, Bildgrößen und Sidecarbedingungen stehen in `ci-contract.json`. Nach sauberem Godotimport sind erforderlich:

```bash
godot --headless --path . --script res://scripts/tests/lumo_facial_regression.gd
LUMO_FACE_CAPTURE_DIR=/tmp/lumo-facial-capture godot --path . --resolution 640x640 --fixed-fps 24 --write-movie /tmp/lumo-facial-runtime.avi --script res://scripts/tests/lumo_facial_capture.gd
```

Ein funktionierender X11/Mesa-Renderer ist für die zweite Zeile erforderlich. Die Captureprobe verweigert Headless und verlangt die gültige produktive Apfelaufgabe. Exitstatus, Enginefehler, Marker, acht Bilder und der vollständige tatsächliche Mesh-/Playback-Sidecar müssen zusammen geprüft werden.

Die Autorenquelle ist `evidence/sculpt-v9/Lumo-Facial-Authoring.blend`. Das aktuelle Autorenprogramm kann mit Blender4.3.2 direkt aus dem unveränderten Original, `evidence/eye-surface/sampling-surface.npz` und den beiden Konturmasken neu erzeugen:

```bash
blender --background --python tools/author_face_geometry.py -- --source /path/to/Lumo-Animated-Mobile.glb --surface evidence/eye-surface --out /tmp/lumo-face-rebuild
python3 tools/verify_face_asset.py --source /path/to/Lumo-Animated-Mobile.glb --derived /tmp/lumo-face-rebuild/Lumo-Facial-Mobile.glb --surface evidence/eye-surface/sampling-surface.npz --curves /path/to/lumo_studio_clips.gd --out /tmp/lumo-face-verification.json
```

Der Verifier benötigt NumPy. Die Blenderautorenquelle nutzt die mit Blender gelieferte Python-/NumPy-Umgebung; die ursprüngliche Oberflächenprojektion zusätzlich Pillow/SciPy. Die beiden Kotlin-Testquellen und ausdrücklich synthetischen Plattformfixtures liegen unter `host/tests/`; die vorhandenen Compile-/Ausgabelogs dokumentieren den ausgeführten Lauf. Installer-/Host-CI-Verknüpfung ist eine eigene Integrationsarbeit von Root.

## Verworfen und erhalten

Frühe UV-/Lidvarianten, ein durch flache LOD-Reduktion beschädigter Rendererstand und der erste Capture mit ungültigem Lernpayload werden ausdrücklich nicht als Endergebnis verwendet. Kleine ursprüngliche Fehlerlogs und Geometriegegenbelege sind im Uploadsatz erhalten; große Zwischenmodelle bleiben lokal. Die letzte Captureänderung blendete nur die zusätzliche Inspektionscaption während des tatsächlichen Aufgabenbilds aus. Alle produktiven GDScript-/Kotlin-/GLB-Bytes blieben dabei unverändert.

Offen bleiben die neue gemeinsame NativeCI, der echte Android-Sprachpfad, körperliche Fold7-Leistung/Temperatur/Eingabelatenz sowie ein eigenständig modellierter Mundraum mit echten Visemen. Die geschützte Main- und Versionsfreigabe bleibt bei Root und den vorhandenen Pflichtgates.
