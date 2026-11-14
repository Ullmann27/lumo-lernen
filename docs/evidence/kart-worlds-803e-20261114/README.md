# Kart: tatsächliche Sichtprüfung der elf weiteren Produktionsstrecken

**Stand: 14. November 2026.** Dieses neue Belegpaket untersucht die bereits vorhandenen Strecken auf dem aktuellen Native-Inhalt **`803e7a626ea6ef0aeeda9c37010e844033d3a8e3`**, Tree **`dc24bfa8b3fac8812c88cfc8f8eab3af1479979c`**. Der zugehörige Android-Kandidat bindet Host **`4ab96666f954baf258422d6ed277fc297b7ddeef`** an diesen Native-Commit. Dieses Paket verändert keine Produktdatei, keinen Pin und keine Abnahmeschwelle. Es erweitert die vorhandene Sonnenhafen-/Garage-Prüfung um die elf übrigen Strecken.

## Tatsächlich ausgeführt

Der unveränderte Produktions-Capture `scripts/tests/kart_track_theme_capture.gd` instanziierte `scenes/games/kart_island.tscn` für jede Strecke. Jede Instanz erhielt ein eigenes, geprüftes temporäres Benutzer-/Konfigurations-/Cache-Verzeichnis. Nach dem Aufbau wurde die Szene für drei stationäre Ansichten eingefroren: die produktive Fahrkamera mit stehendem Kart sowie zwei manuell gesetzte Inspektionskameras. `reduced_motion=true`, Detailstufe `full`, Grafikprofil `high`, Auflösung 1280 × 720.

**11/11 Prozesse endeten mit Exit 0; 33 originale PNGs und elf Capture-Metadatendateien liegen bei.** Der gesamte Launcher benötigte 152,618 s. Diese Wandzeit ist keine Spielbildrate. Die Logs enthalten keine `SCRIPT ERROR`, `ERROR:` oder `Parse Error`-Zeile. Je Lauf bleiben drei echte Warnungen erhalten: nicht umschaltbares V-Sync, nicht verfügbares Screen-Space-Antialiasing und nicht verfügbarer volumetrischer Nebel in diesem Renderer.

Godot 4.6.3 lief auf Linux/X11 mit Mesa-Software-GL und `gl_compatibility`. Die Bilder belegen diesen tatsächlichen Renderer, keine vollständige Mobilrenderer-Abnahme. Es wurden keine KI-generierten Bilder oder Zwischenframes benutzt.

## Quellbindung einschließlich der lokalen Grenze

[published-runtime-blobs.json](published-runtime-blobs.json) enthält die erwarteten veröffentlichten Blobwerte. [source-binding-production-before.json](source-binding-production-before.json) bindet **1175/1175 Runtime-, Asset-, Szenen- und Capture-Dateien** vor dem Lauf an diese Werte; [capture-runs.json](capture-runs.json) dokumentiert nach dem Lauf **keine Änderung** dieser Dateien.

Die Original-Capture-Metadaten bewahren ausdrücklich den älteren lokalen Git-HEAD `ada5ed81ad62339f15289da62670c0a4f9f7f2b9` und `clean_tracked_source=false`. Es wird **kein sauberer 803e-Checkout** behauptet. Die 803e-Zuordnung erfolgt durch den getrennten vollständigen Vergleich der genannten relevanten Dateien. Ein zuvor untersuchter anderer lokaler Checkout hatte insgesamt 20 Abweichungen (15 abweichende Dateien und fünf fehlende Dateien); sein unveränderter, abgelehnter Vorprüfbericht [source-binding-before.json](source-binding-before.json) liegt ebenfalls bei. Aus diesem abgelehnten Checkout wurde für dieses Paket kein Bild gerendert.

## Originalbilder und tatsächliche Sichtung

Alle **33 unterschiedlichen Bilder wurden einzeln geöffnet**. `/root` sichtete elf Fahrkameraansichten sowie das Zauberwald-Detail; `/root/character_animation` sichtete elf Kontextansichten und die zehn verbleibenden Details. Die [Root-Review](review-chase-root.json) und die [vollständige Kontext-/Detailreview](review-context-detail.json) nennen für jedes tatsächlich betrachtete Bild SHA256, Beobachtung und Grenzen. Der frühe Root-Review verweist zeitlich korrekt noch auf die anschließend abgeschlossene zweite Sichtung. Die abschließende Vereinigungsprüfung ergibt genau die 33 Originalbilder ohne Lücke oder Doppelzählung.

| Strecke | Fahrkamera, stationär | Inspektionskontext | Inspektionsdetail |
| --- | --- | --- | --- |
| Zauberwald | [Fahrkamera](captures/zauberwald/01_chase.png) | [Kontext](captures/zauberwald/02_context.png) | [Detail](captures/zauberwald/03_detail.png) |
| Bergwelt | [Fahrkamera](captures/bergwelt/01_chase.png) | [Kontext](captures/bergwelt/02_context.png) | [Detail](captures/bergwelt/03_detail.png) |
| Holo City | [Fahrkamera](captures/holo_city/01_chase.png) | [Kontext](captures/holo_city/02_context.png) | [Detail](captures/holo_city/03_detail.png) |
| Crystal Canyon | [Fahrkamera](captures/crystal_canyon/01_chase.png) | [Kontext](captures/crystal_canyon/02_context.png) | [Detail](captures/crystal_canyon/03_detail.png) |
| Jungle Temple | [Fahrkamera](captures/jungle_temple/01_chase.png) | [Kontext](captures/jungle_temple/02_context.png) | [Detail](captures/jungle_temple/03_detail.png) |
| Candy Cloud | [Fahrkamera](captures/candy_cloud/01_chase.png) | [Kontext](captures/candy_cloud/02_context.png) | [Detail](captures/candy_cloud/03_detail.png) |
| Volcano Night | [Fahrkamera](captures/volcano_night/01_chase.png) | [Kontext](captures/volcano_night/02_context.png) | [Detail](captures/volcano_night/03_detail.png) |
| Winter Sprint | [Fahrkamera](captures/winter_sprint/01_chase.png) | [Kontext](captures/winter_sprint/02_context.png) | [Detail](captures/winter_sprint/03_detail.png) |
| Galaxy Ringway | [Fahrkamera](captures/galaxy_ringway/01_chase.png) | [Kontext](captures/galaxy_ringway/02_context.png) | [Detail](captures/galaxy_ringway/03_detail.png) |
| Desert Drift | [Fahrkamera](captures/desert_drift/01_chase.png) | [Kontext](captures/desert_drift/02_context.png) | [Detail](captures/desert_drift/03_detail.png) |
| Learning Lab | [Fahrkamera](captures/learning_lab/01_chase.png) | [Kontext](captures/learning_lab/02_context.png) | [Detail](captures/learning_lab/03_detail.png) |

## Wesentliche sichtbare Befunde

Die vorhandenen Produktionsszenen besitzen echte räumliche Themenobjekte: beispielsweise Waldkonstruktionen, große Kristalle, Bonbonschloss und Tortengebäude, Observatorium, Neongebäude und Schneevegetation. Original-Lumo und Kart sind in den Fahrkameraansichten sichtbar.

Die Qualität ist unterschiedlich. Große Flächen zeigen wenig Materialvariation; einige Schatten sind hart oder rasterstufig. Schnee verliert in den sehr hellen Bereichen Konturen. Das kleine Vulkanobjekt trennt sich schwach von seinem dunklen Hintergrund. Mehrere manuelle Kontextansichten zeigen überwiegend Straße und Wandflächen; die Holo-City-Detailansicht wird größtenteils von einer Fassade verdeckt. **Diese Ausschnittsgrenzen werden nicht als Fehler der dynamischen Produktions-Fahrkamera ausgegeben.** Die betreffenden Originale bleiben erhalten.

Dieses Paket ist eine nachvollziehbare Bestandsaufnahme. Es behauptet **keine neu entwickelten elf Strecken, keine gefahrene Runde, keine geprüften Gegner-/Kollisionsereignisse, keine Android-Eingabe, keine 60 FPS und keine abgeschlossene AAA-Art-Abnahme**. Die noch benötigte Weiterentwicklung wird anhand sichtbarer Befunde konkreter. Der tatsächliche Android-Lauf und der physische Fold7-Leistungsnachweis bleiben getrennte Abnahmen.

## Wiederholbarkeit und Bestandsschutz

[capture_current_worlds.py](capture_current_worlds.py) erhält die ausgeführten Befehle und die isolierte Display-/Benutzerumgebung. [capture-runs.json](capture-runs.json) enthält Exitstatus, Laufzeiten, ursprüngliche Capture-Provenienz sowie Bildhashes. Die elf Logs und elf unveränderten `capture.json`-Dateien bleiben originale Belege. Das temporäre Xorg-Zugriffstoken wurde nach Abschluss entfernt und wird nicht veröffentlicht. Regenerierbare Cachedateien sind kein Bestandteil dieses Belegpakets; Originalbilder, Metadaten, Logs und Quellbindungen bleiben erhalten.
