# Übergabe „LUMO NEXT GENERATION“ – 13.11.2026

Kurzfassung:
- Es gibt jetzt **eine** gemeinsame Godot-Linie und **eine** gemeinsame Flutter-Linie, die auf
  genau diese Godot-Linie zeigt.
- Heinz' 20 Referenzbilder liegen im Repo. Sie sind ab jetzt die verbindliche Grafikvorgabe
  für alle Spiele.
- Es wurde **keine** APK gebaut, nichts installiert und nichts veröffentlicht.

## 1. Gemeinsame Godot-Linie

Zweig `claude/lumo-nextgen-combined-20261113` @ `76d498662314da8cc9a2e1f1b8f0a6b45ef6fedd`
(Repo lumo-godot).

Sie baut auf `integration/lumo-connections-20261113` @ `cf039ad` (PR #160) auf, der bereits Studio
`24fb858` enthält. Zusätzlich gemergt:

| Kopf | Inhalt | Ergebnis |
|---|---|---|
| `25e3a11` | Native-Editor-Import-Isolation | echt neu (1 Datei) |
| `a1e083a` | Winter-Stationen | schon in weiterentwickelter Form in #160 enthalten (`72a1330`, `ea72b24`). Konflikte zugunsten dieser Form gelöst, der Merge bringt nur Herkunft. |
| `8d4a4e1` | Kart-Menü-Pixelgröße | ebenfalls schon enthalten, keine Netto-Änderung |
| `bb889bc` | Cards-Safe-Area, Feedback-Anker | ebenfalls schon enthalten (`db4cd7c`, `ea72b24`). Konflikt zugunsten des Audio-Release-Tests aus #160 gelöst. |
| `7c088c5` | Bauwelt-Dorf: Wirtschaft, Bewohner, Nelli/Bruno/Tilda-GLBs, 12 Kapitel | echt neu (17 Dateien) |

Dazu der Commit `76d4986`: Die sieben Dorf-Skripte waren als `[skip ci]`-Checkpoint mit
140 Lint-Fehlern hochgeladen worden. Sie sind jetzt mit gdformat formatiert und lintfrei
(gdlint: 0 Probleme). `validate_project.py` meldet PASS (117 PASS, 7 WARN, 0 FAIL).

### Bauwelt-Tests auf dieser Linie (headless, lokal ausgeführt)

PASS:

| Test | Prüfungen |
|---|---|
| build_village_art | 2259 |
| build_settlement | 194 |
| build_settlement_play | 127 |
| build_dialog_density | 1637 |
| build_transform | 38 |
| build_frontier | 14 |
| build_sandbox_tools | ohne Zählerangabe |
| build_sandbox_ui | ohne Zählerangabe |
| build_premium_props | ohne Zählerangabe |

**FAIL**, beide schon im Original-Checkpoint, nicht durch die Zusammenführung verursacht:
- `build_village_economy_regression` (3 von 1221 Prüfungen). Ursache gefunden: **Soft-Lock**.
  - Münzen verdient man nur über den Marktplatz (`build_settlement_economy.gd`, produce:
    `gross = market*2`). Der Marktplatz kostet selbst 2 Münzen (`build_settlement_state.gd`,
    BUILDINGS).
  - Wer vorher Häuser oder Wege kauft, bleibt bei 0 Münzen hängen.
  - Nachgestellt: Kampagne steckt in Kapitel 4 fest, mit coins=0, Holz 1328, Stein 986.
  - Empfohlene Lösung: Im Dorfmodus kostet der Marktplatz nur Holz und Stein. Eine einzige
    Kostenfunktion für Kauf, Abriss-Rückgabe und UI-Anzeige.
- `build_nextgen_play_regression` (4 Fehler: Rotations-Vorschau, Touch-Snap, Wand-Kollision,
  Wand-Inspektion). Noch nicht geprüft, ob die Touch-Reparatur `24fb858` die Ursache ist oder
  ein veralteter Test.

**Wichtiger Befund:** Das neue Dorf (Wirtschaft, Kampagne, Nelli/Bruno/Tilda) ist **im Spiel
noch nicht erreichbar**.
- `scripts/creative/build_settlement_world.gd:86` erzeugt `STATE.new(mode)` ohne Dorfmodus.
- Die Bauleiste bietet nur die klassischen 6 Gebäude.
- Das Dorf existiert bisher nur im Modell und in den Tests.

## 2. Gemeinsame Flutter-Linie

Zweig `claude/lumo-nextgen-app-20261113` @ `1ae8ee71` (Repo lumo-lernen), Version
0.13.7+2019. Er führt drei Linien zusammen:
- Kart-Grafik `chatgpt/lumo-kart-graphics-apk-20261113` @ `bc58a16f`;
- Integration `integration/lumo-connections-20261113` @ `e5c8d6f9` (inkl. Bauwelt-Host
  `fe66edf9`);
- Studio `chatgpt/lumo-studio-20261113` @ `5e07d7d6`.

Pin:
- `config/godot-source.json` zeigt auf die gemeinsame Godot-Linie `76d49866`.
- `scripts/verify_legacy_release_pin.py` hat 2019 = `76d49866`.
- Die beiden Teil-Pins `25e3a11` und `24fb858` werden für 2019 jetzt ausdrücklich abgelehnt.
- Damit baut kein 2019-Host mehr gegen einen älteren oder unvollständigen Godot-Stand.

Ausgeführt:
- `python3 -m unittest scripts.tests.test_candidate_2011_pin`: 24 Tests OK.
- Alle 44 Python-Testmodule unter `scripts/tests/` einzeln laufen gelassen: 42 OK.
- 2 Module mit Importfehler: `test_kart_graphics_delivery` und `test_kart_graphics_review`.
  Sie importieren `test_nextgen_delivery` und müssen vermutlich aus `scripts/tests/`
  gestartet werden. **Nicht abschließend geprüft.**

**Nicht ausgeführt:**
- `flutter analyze` und `flutter test` auf dem zusammengeführten Stand;
- der native/APK-Workflow;
- API-35/37-Läufe und das Update 2017→2019;
- jede Geräteprüfung.

## 3. Referenzbilder und Agentenaufträge

`docs/design_targets/2026-11-13-aaa/` enthält 20 Bilder:
- Spielwelt-Hub und Spielwelt-Board;
- Lumo-Master-Sheet;
- 7 Spiel-Poster;
- 5 Spiel-Boards;
- Kart-Hauptmenü, Garage und Zielbildschirme Platz 1–3.

`docs/integration/2026-11-13/BRIEFING_NEXTGEN.md` ist die gemeinsame, verbindliche
Agentenanweisung: Bildbedeutung, Bild-Nutzungsregeln, Basen, Push-Pflicht, Ehrlichkeit.

Fünf Agenten wurden gestartet und durch die Unterbrechung gestoppt, bevor sie Produktcode
geschrieben hatten. Gesichert ist nur:
- `claude/lumo-aaa-spielwelt-20261113` @ `8f269d3b`: Referenzbilder plus Vorher-Aufnahmen
  (Phone, Fold-Cover, Fold-Open) des alten Spiele-Hubs.

Die anderen vier Zweige existieren nur lokal und enthalten keine Änderungen:
- `claude/lumo-aaa-character-20261113`
- `claude/lumo-aaa-tutor-20261113`
- `claude/lumo-aaa-kart-menus-20261113`
- `claude/lumo-aaa-bauwelt-20261113`

Die Aufträge zum Neustart, je ein Agent, Basis wie oben:
1. **Spielwelt-Hub und Spiel-Titelbildschirme** (Flutter) nach `spielwelt-hub.jpg` und den
   Postern. Glasportale mit Key-Art-Ausschnitten ohne Text, Logo als echtes Widget,
   „Auf ins Abenteuer!“, Elternbereich bleibt geschützt.
2. **Lumo-Animation** (Flutter `lib/widgets/fox/living/`) nach dem Master-Sheet:
   Blinzeln, Blick, Atmen, Ohren/Schwanz/Halstuch, Gesten, weiche Übergänge, Reduce-Motion.
3. **KI-Nachhilfe „Frag Lumo“** (Flutter) wie ein Prompt:
   - Tippen oder Sprechen;
   - Offline-Intent-Parser für Rechnen, „erklär mir …“, „Übung zu …“ und Rechtschreibung;
   - Hinweise vor der Lösung;
   - Vorschläge aus echtem Fortschritt;
   - kein Cloud-LLM, keine bezahlte API.
4. **Kart-Hauptmenü, Garage und Zielbildschirm** (Godot) nach den Kart-Bildern. Deutsche
   Texte, nur echte Werte.
5. **Bauwelt**:
   - Soft-Lock beheben;
   - `build_nextgen_play` reparieren;
   - Dorfmodus ins echte Spiel einbauen: alle Gebäude, Tilda-Handel, Kapitel-Panel,
     Nelli/Bruno/Tilda als 3D-Figuren.

## 4. Nächste Schritte in dieser Reihenfolge

1. Bauwelt-Soft-Lock und `build_nextgen_play` auf der Godot-Linie beheben.
2. Danach den Flutter-Pin auf den neuen Godot-Kopf setzen. Dafür `config/godot-source.json`,
   die 2019-Zeile in `verify_legacy_release_pin.py` und `COMBINED_2019_REVISION` im Pin-Test
   ändern.
3. Auf `claude/lumo-nextgen-app-20261113` Folgendes laufen lassen:
   - `flutter analyze`;
   - die Flutter-Tests;
   - die beiden Kart-Grafik-Python-Tests aus `scripts/tests/` heraus.
4. Den nativen APK-Workflow per `workflow_dispatch` auf diesem Zweig starten. Danach prüfen:
   - API 35 und 37;
   - Update 2017→2019 mit gleichem Paketnamen und gleicher Signatur;
   - Kinderprofile und Fortschritt.
5. Erst dann die Grafik-Agenten 1–4 neu starten und ihre Ergebnisse einzeln in beide
   Linien mergen. Danach den Pin erneut setzen.

`main` blieb unberührt. Es gab keinen Force-Push. Es wird keine FPS-, Geräte-, Installations-
oder Veröffentlichungsbehauptung aufgestellt.
