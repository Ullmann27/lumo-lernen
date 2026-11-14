# Vier gewinnt: eigenständige visuelle Rendererprüfung

## Ergebnis und Geltungsbereich

Der tatsächliche lokale Godot-4.6.3-Lauf `render-v2` endete mit **Exit 0 und 303 bestandenen Prüfungen**. Er erzeugte vier unveränderte Framebuffer-PNGs und `visual-state.json`; alle vier finalen Bilder wurden einzeln geöffnet. Der negative Aufruf mit `--headless` endete wie vorgesehen mit Exit 2 und `CONNECT_FOUR_VISUAL_REQUIRES_REAL_RENDERER`.

Dies ist ausdrücklich eine **Visualfixture**. Die echte Produktionsszene `scenes/games/connect_four_table.tscn` wird über `PackedScene.instantiate()` geladen. Ihr Host liefert ausschließlich vier unveränderliche, bekannte Zustände aus dem früheren tatsächlichen C4-Dart/Godot-Lauf `runtime-final-v7`. Der Testhost quittiert keine Spielaktion, erzeugt keinen Botzug, berechnet keine Gewinnregel und schreibt keinen Spielstand oder Reward. Die sichtbare Produktbeschriftung „Gespeichert“ ist deshalb keine neue Speicherabnahme. Der echte Zweiprozesslauf bleibt eine separate Pflichtprüfung.

| Bild | Tatsächliches Raster | Tatsächliche Szenengeometrie | Sichtprüfung |
|---|---:|---|---|
| `c4-empty-landscape.png` | 960 × 540 | 0 Steine, 0 Winringe | Vollständiges Lochbrett und sieben Spaltenziele |
| `c4-playing-phone.png` | 412 × 915 | 2 Steine, 0 Winringe | Cyan/Gold in Spalte 4, vollständige Bedienelemente |
| `c4-win-landscape.png` | 960 × 540 | 7 Steine, 4 Winringe | Sichtbare Viererreihe und Gewinnbeschriftung |
| `c4-paused-small.png` | 640 × 360 | 3 Steine, 0 Winringe | Erklärung und Fortsetzen vollständig im Scrollausschnitt |

Die Pauseüberlagerung verdeckt erwartungsgemäß einen Teil des Bretts. Ihre drei Steine sind tatsächlich vorhandene Meshes; das Bild wird nicht als pixelweise Sicht auf alle drei Steine ausgegeben. Resume, Restart und Modus wurden mit echten `InputEventScreenTouch`-/`InputEventScreenDrag`-Ereignissen nacheinander vollständig exponiert. Danach führt ein echter weiterer Wischer zum Menüanfang zurück. Insgesamt sind 30 Eingabeereignisse protokolliert; es gab keine angenommene Hostaktion und keine Zustandsfortschreibung.

Die kleinste geprüfte, tatsächlich vollständig exponierte Zielseite beträgt **50 dp** bei der ausdrücklich festgelegten Desktop-Testdichte 1. Die Prüfung nutzt hier die volle Desktopfläche; sie ist keine neue Android-WindowInsets-, Fold7-, Temperatur-, Touchlatenz- oder 60-FPS-Messung. `--fixed-fps 24` ist lediglich der deterministische Aufnahme-/Testtakt. Der Renderer ist Mesa-Software-OpenGL.

## Quellen und ehrliche Fixturebindung

`fixture-source-binding.json` bindet die vier ursprünglichen JSON-Beobachtungen mit vollständigen SHA256-Werten. Die öffentlichen Zustandsfelder, Zughistorien, Boards, Eigentümer/Rundenkennungen und bekannten tatsächlichen Steinpositionen wurden daraus übernommen. Die vier dort nicht vorhandenen Transportfelder sind ausdrücklich als Visualfixture-Vorgaben dokumentiert: `exit=false`, `reduceMotion=false`, `error=null`, alle sieben freien `validColumns`. Keine gewählte Beispielspalte ist voll. Diese Transportergänzung wird nicht als byteidentischer vollständiger Originalzustand bezeichnet.

Die neue Capturedatei ist der einzige für die Native-Integration vorgesehene Quellpfad. Die echte C4-Produktdatei bleibt auf SHA256 `76ab128b835bffd41b87274566408b8baab4073fe6733b2f5e3e990e0e027a72`. Dreißig ausdrücklich gemessene Szenen-, Script-, Asset- und Metadatendateien sind vor/nach dem Lauf bytegleich. Der kleine isolierte Projektbaum kopiert nur Textquellen und referenziert bestehende große Assets/importierte Ressourcen; es wurde keine große Projekt- oder Importcachekopie erzeugt.

Drei UID-Warnungen des minimalen lokalen Projekts fallen auf die vorhandenen exakten Texturpfade zurück. Die Originaltexturbytes sind vor/nach gebunden und die Figur wurde tatsächlich angesehen. Diese Warnungen bleiben im unveränderten Rohlog. Harte Schatten und einfache Raummaterialien bleiben sichtbar; dieser Beleg verspricht weder Konsolengrafikniveau noch Gesichtssynchronität.

## Native-CI-Schnittstelle

```bash
LUMO_CAPTURE_DIR="$PWD/captures/connect_four_visual_capture" \
godot --path . --rendering-method gl_compatibility --fixed-fps 24 \
  --resolution 960x540 \
  --script res://scripts/tests/connect_four_visual_capture.gd -- --capture
```

Ein tatsächlicher Displayserver ist erforderlich. `LUMO_CAPTURE_DIR` muss explizit sein; vorhandene Belegdateien werden nicht ersetzt. Der zwingende Erfolgsmarker lautet `CONNECT_FOUR_VISUAL_PASS`. Der aktuelle Lauf nennt `checks=303 captures=4 fixture=true`. Alle bisherigen Native-Gates, die separate echte Host/Dart-Regel-/Speicherprüfung und die Android-Gates bleiben erforderlich.

`visual-state.json` hat `schema:1`, `kind:"connect_four_visual_fixture"` und `read_only_fixture_host:true`. Es enthält vier `captures` mit PNG-Hash und tatsächlichen Abmessungen, Fixturequellenhash, exakt verwendetem Zustand, tatsächlich gemessener Board-/Cylinder-/Torus-Geometrie, Beschriftungen, vollständig exponierten Zielbounds sowie dem unveränderten Produktionslayout-Snapshot. Dazu kommen Inputprotokoll, Prüfzahl/Fehler, Renderer und Quellhashes vor/nach. `source_revision` übernimmt in CI den tatsächlichen `GITHUB_SHA`; lokal bleibt er leer. Das ist kein angenommener künftiger Native-Commit.

## Lokale Reproduktion

Der ausgeführte Befehl steht unverändert in `render-v2/run.json`; er verwendet `tools/run_local_renderer.py`, den isolierten Display 108, ein 600-s-Abbruchbudget und den kleinen Projektbaum `qa/connect-four-visual-fixture-20261114/runtime`. Die tatsächliche Laufzeit betrug 9,336774 Sekunden. Die vorangehende 302er-Fassung ist separat erhalten; nur die Captureprobe wurde für die abschließende obere Menüposition ergänzt.

`source-upload-manifest.json` nennt genau einen neuen Native-Quellpfad. `evidence-upload-manifest.json` listet ausschließlich die ausdrücklich vorgesehenen Belege, PNGs und Manifeste; der lokale Runtimebaum und seine großen Referenzen gehören nicht zum Upload.
