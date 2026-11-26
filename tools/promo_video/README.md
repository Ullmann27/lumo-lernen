# Lumo Lernen – Werbevideo (Quellen)

Erzeugt das Eltern-Werbevideo für Lumo Lernen samt Spielwelt in zwei Formaten:

- `build/lumo_lernen_werbevideo_querformat_1920x1080.mp4`
- `build/lumo_lernen_werbevideo_hochformat_1080x1920.mp4`

Dauer 2:20 (140 s), 30 Bilder/s, H.264 + AAC. Die MP4-Dateien und alle Zwischenstände
liegen unter `build/` und werden **nicht** eingecheckt.

## Preis und Abo: eine Stelle

`config.json` → `angebot`. Dort stehen Preis (`14,99 €`), Zeitraum (`pro Monat`),
Steuerhinweis (`inkl. USt.`), Modell (`Monatliches Abo`), der Zusatz zu neuen Spielen und
der Schlussaufruf. Lesart des Auftrags: **14,99 € im Monatsabo**. Die Szenen 13 und 14
lesen ausschließlich diese Werte (`data-cfg`). Danach `./build.sh` neu ausführen.

`"stimme": false` schaltet Lumos gesprochene Sätze ab (dann nur Musik und Texte).

## Aufbau

| Datei | Zweck |
|---|---|
| `scenes/index.html` | 14 Szenen mit Zeiten (`data-in`/`data-out` in Sekunden) |
| `scenes/style.css` | App-Design: Farben aus `lib/app/app_theme.dart`, Schrift Nunito aus `assets/fonts/` |
| `scenes/engine.js` | stellt jede CSS-Animation exakt auf den Zeitpunkt eines Bildes (deterministisch) |
| `scenes/more.js` | Spiele-Montage und Sternenflug |
| `render.mjs` | Chromium (Playwright) rendert Bild für Bild, ffmpeg kodiert |
| `music.py` | Musik, vollständig rechnerisch erzeugt (numpy, keine Samples) |
| `audio.json`, `mix_audio.py` | Musikabschnitte, Lumo-Stimmclips, Mischung auf −16 LUFS |
| `capture/*.sh` | echte Aufnahmen aus App (Flutter-Tests) und Spielen (Godot-Renderer) |
| `capture/godot_auswahl.json`, `prepare_assets.py` | Auswahl und Zuschnitt der Aufnahmen nach `build/cap/` |

## Neu bauen

```bash
# 1) echte Aufnahmen (Flutter 3.44.9, Godot 4.6.3, xvfb)
tools/promo_video/capture/flutter_captures.sh /tmp/lumo-cap/flutter
tools/promo_video/capture/godot_captures.sh <lumo-godot> <godot-binary> /tmp/lumo-cap/godot
# 2) Auswahl zuschneiden
python3 tools/promo_video/prepare_assets.py /tmp/lumo-cap/flutter /tmp/lumo-cap/godot
# 3) Videos
tools/promo_video/build.sh
```

Einzelbilder zur Kontrolle: `node render.mjs --format=port --still=12,33,128 --dir=build/stills`.

## Was echt ist

- Alle Bildschirme in den Handyrahmen und Spielrahmen sind unveränderte Aufnahmen
  (nur zugeschnitten und verkleinert): Lern-App aus den Capture-Tests der App,
  Spiele aus dem Godot-Renderer von `lumo-godot`.
- Fuchs Lumo, LUMO-Logo und Hintergründe stammen unverändert aus `assets/lumo_design/`.
- Profile in den Aufnahmen sind fiktiv („Mia“, „Demo-Kind“, Demo-Klasse).
- Lumos Stimme: zwei vorhandene App-Clips aus `assets/audio/voice/lumo/` (siehe `audio.json`).
- Musik: selbst erzeugt durch `music.py` – keine fremden Aufnahmen, Samples oder Melodien.

## Grenzen der Werbung

Das Video richtet sich an Eltern (Anrede „Sie“, „Für Eltern“), enthält keine
Kaufaufforderung an Kinder, keine Bewertungen, Auszeichnungen, Store-Abzeichen oder
Notenversprechen. Der Preis steht mit „inkl. USt.“.
