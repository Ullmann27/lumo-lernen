# Lumo 2027 – Übersicht aller Arbeitszweige (Stand 29.10.2026)

Auftrag von Heinz: Lumo Lernen und Lumo Kart sollen 2027-Premium wirken. Die ganze
Spielwelt soll auf Lumo-Kart-Niveau kommen, mit lebendigem Lumo, Elternbereich,
KI-Nachhilfe und Schularbeits-Planung.

Alle Zweige sind offen, gepusht und für jede KI weiterführbar. Nichts ist gesperrt.
`main` und Releases bleiben unverändert. Gemeinsame Regeln für alle Agenten stehen in
[BRIEFING.md](BRIEFING.md). Jede KI soll sie vor dem Weiterarbeiten lesen.

## Basis

- App: `origin/release/lumo-2003-family-button-20261029` @ `5457b2ee` (0.12.91+2003).
  Enthält Sols Tutor-Kern, den lebenden Original-Lumo und die Zehner-Werkstatt.
- Godot: `origin/qa/sonnenhafen-2003-aerial-flight-captures-20261029` @ `54ed315`.
  Release 2003 pinnt `adcce30` (Vorfahr).
- Kart-Referenzbilder von Heinz liegen in den Godot-Zweigen unter
  `docs/design_targets/2026-10-29-kart-reference/`.

## Zweige und Aufgaben

| Bereich | Repo | Zweig | Auftrag |
|---|---|---|---|
| Kart-Menüfluss | lumo-godot (+ App, falls nötig) | `claude/kart-2027-menu-flow-20261029` (+ `claude/lumo-2027-kart-entry-20261029`) | Ablauf: Vorspann → Hauptmenü mit drehendem Lumo → Grand Prix, Strecke, Zeitrennen, Garage, Werkstatt, Pause. Das alte Doppelmenü kommt weg. |
| Kart-Strecken + HUD | lumo-godot | `claude/kart-2027-track-kit-20261029` | Strecken-Bausatz für alle 12 Strecken nach den Referenzbildern. Plastische, actionreiche Tasten und Joystick. Effekte. |
| Kart-Physik + Steuerung | lumo-godot | `claude/kart-2027-physics-feel-20261029` | Fahrphysik, Flug- und Sprungphysik, Landung, Drift, Mini-Turbo, Joystick-Kurve, Kamera. Gegner-KI prüfen (`claude/kart-rival-race-craft-20261022`). |
| Elternbereich | lumo-lernen | `claude/lumo-2027-parents-20261029` | Oberen Bereich entwirren, klare Abschnitte, ruhig und edel. |
| Start + lebender Begleiter | lumo-lernen | `claude/lumo-2027-home-companion-20261029` | Lebender Lumo begrüßt auf dem Start, begleitet den Lern-Hub und als Mini-Begleiter die Aufgaben. |
| Abenteuer 2.5D | lumo-lernen | `claude/lumo-2027-adventure-20261029` | Tiefe, Licht, Kamera und Partikel statt flachem 2D. |
| KI-Nachhilfe | lumo-lernen | `claude/lumo-2027-tutor-presence-20261029` | Lumos Präsenz zu den Signalen der Tutor-Logik. Nur Darstellung. |
| Spielwelt | lumo-lernen | `claude/lumo-2027-spielwelt-20261029` | Konsolen-Launcher, Premium-Spiele-Baukasten, Vier gewinnt, Würfelrennen, Minispiele. |
| Lumo Cards | lumo-lernen | `claude/lumo-2027-cards-20261029` | 2.5D-Tisch, Premium-Karten, Animationen; Lumo spielt sichtbar mit. |
| Koordination | lumo-lernen | `claude/lumo-2027-coordination-20261029` | Diese Übersicht, gemeinsame Regeln und die Forschungsberichte. |

**Noch nicht gestartet** (für die nächste KI frei, jeweils eigener Zweig ab `5457b2ee`):
- Memory (`claude/lumo-2027-memory-20261029`);
- Bauwelt (`claude/lumo-2027-bauwelt-20261029`);
- Schularbeits-Planer (`claude/lumo-2027-exam-planner-20261029`). Der Bauplan folgt aus der
  Lernforschung unter `docs/research/2027/`.

## Status (gesichert am 29.10.2026, nach Abbruch aller Agenten am Nutzungslimit)

Alle elf Agenten wurden am Nutzungslimit abgebrochen, bevor sie Produktcode
geschrieben hatten. Nichts davon ist fertig. Gesichert ist genau das, was in der
Tabelle steht. Remote-Stand geprüft per `git ls-remote`: Jeder Zweig enthält
den lokalen Stand, kein Arbeitsverzeichnis hat ungesicherte Änderungen.

| Agent | Zweig | Remote-HEAD | Gesichert | Fertig |
|---|---|---|---|---|
| Kart-Strecken + HUD | `claude/kart-2027-track-kit-20261029` (Godot) | `58e064f` | Referenzbilder; Aufnahme-Skript `scripts/tests/kart_track_kit_capture.gd` für alle 12 Strecken (noch nicht ausgeführt; gdlint: eine Zeile > 100 Zeichen, Z. 201) | nein |
| Kart-Menüfluss | `claude/kart-2027-menu-flow-20261029` (Godot) | `db3bf17` | Referenzbilder | nein |
| Kart-Physik + Steuerung | `claude/kart-2027-physics-feel-20261029` (Godot) | `929fa3a` | Referenzbilder | nein |
| Elternbereich | `claude/lumo-2027-parents-20261029` | `baa6d04f` | Claim `docs/audit/2026-10-29/PARENTS-2027-CLAIM.md` | nein |
| Start + Begleiter | `claude/lumo-2027-home-companion-20261029` | `5457b2ee` | nichts (gleich Basis) | nein |
| Abenteuer 2.5D | `claude/lumo-2027-adventure-20261029` | `5457b2ee` | nichts (gleich Basis) | nein |
| KI-Nachhilfe | `claude/lumo-2027-tutor-presence-20261029` | `5457b2ee` | nichts (gleich Basis) | nein |
| Spielwelt | `claude/lumo-2027-spielwelt-20261029` | `5457b2ee` | nichts (gleich Basis) | nein |
| Lumo Cards | `claude/lumo-2027-cards-20261029` | `5457b2ee` | nichts (gleich Basis) | nein |
| Recherche Technik | – | – | kein Bericht geschrieben | nein |
| Recherche Lernen / Schularbeit | – | – | kein Bericht geschrieben | nein |

Nicht gestartet, Zweig gleich Basis:
- `claude/lumo-2027-kart-entry-20261029`
- `claude/lumo-2027-memory-20261029`
- `claude/lumo-2027-bauwelt-20261029`
- `claude/lumo-2027-exam-planner-20261029`

Die Godot-Arbeitsbäume enthalten zusätzlich etwa 195 von Godot erzeugte `.uid`-Dateien. Sie
sind auch upstream nicht versioniert und wurden bewusst nicht committet.

Fertige, geprüfte Arbeit aus dieser Sitzung liegt vor dieser 2027-Runde:
- `claude/lumo-living-world-visual-20261029` @ `f249fd78`: lebender Original-Lumo, Szenenvertrag
  und Zehner-Werkstatt; Tests grün. Andere KIs haben das bereits in Release 2003 übernommen.
- `claude/lumo-android-integration-m0-aloove` @ `c116408a` (PR #331): Hilfe-Hinweise
  für fehlende Zahlen, Bildvergleich-Fix aus PR #403; CI komplett grün.

## Weiterarbeiten (für jede KI)

1. `git fetch origin` und den gewünschten Zweig auschecken.
2. Zuerst `BRIEFING.md`, dann `HANDOFF.md` und den Claim des Moduls lesen.
3. Sols Lern-Logik nicht anfassen; nur Darstellung (siehe BRIEFING Abschnitt 4).
4. Kleine Commits, früh und oft pushen, kein Force-Push, kein Merge nach `main`.
5. Zusammenführen: einen Integrationszweig ab `5457b2ee` anlegen, Modulzweige einzeln
   mergen, danach die komplette Testsuite laufen lassen. Godot-Zweige zuerst
   zusammenführen, dann den Pin `config/godot-source.json` in einem eigenen, geprüften
   Schritt erneuern.

Es wurden keine Gerätetests behauptet. Alle Bilder sind Flutter-Test- bzw.
Godot-xvfb-Renderings.
