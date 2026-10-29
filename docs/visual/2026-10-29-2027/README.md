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

## Status

Die Ergebnisse der einzelnen Zweige stehen jeweils in
`docs/visual/2026-10-29-2027/<modul>/HANDOFF.md` und im Claim
`docs/audit/2026-10-29/<MODUL>-2027-CLAIM.md` des jeweiligen Zweigs. Diese Übersicht wird
ergänzt, sobald die Berichte vorliegen. Bis dahin gilt für einen Zweig nur, was dort
gepusht und belegt ist.

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
