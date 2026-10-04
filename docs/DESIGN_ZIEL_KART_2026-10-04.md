# Lumo Kart: verbindliche Vorgabe nach Heinz' Kart-Bildern (4. Oktober 2026)

Heinz: „Das sind genau die Vorlagebilder, wie die App auszusehen und zu funktionieren hat. Es darf nicht abweichen.“
Die Bilder liegen in `docs/design_targets/2026-10-04/kart/`. Sie ergänzen `DESIGN_ZIEL_2026-10-04.md` (gleiches Design-System, gleiche Animationen aus Abschnitt 2b).

## Bilder und wo sie umgesetzt werden

| Datei | Inhalt | Umsetzung |
|---|---|---|
| `k09_modus_waehlen.png` | Kart-Startseite: Logo, Lumo im Kart, „Modus wählen“ mit 6 Bildkarten (Grand Prix, Freies Rennen, Zeitrennen, Sammelrennen, Teamrennen, Abenteuer), Banner „Lern-Boost (Optional)“ | Flutter, Einstieg aus Spielen → Lumo Kart (ersetzt `09_kart_menue.png` als Kart-Hauptmenü) |
| `k08_cup_streckenauswahl.png` | 4 Cups (Himmelsinsel, Wasserfall, Lichterstadt, Wissenswald) mit Sternen, 4 Strecken pro Cup mit 1–3 Sternen, Detailkarte mit Beschreibung, Schwierigkeit, Lern-Boost, Sammelzielen und gelbem „Starten“ | Flutter, nach Moduswahl; „Starten“ übergibt Cup/Strecke an Godot |
| `k01_garage.png` | Garage: Lumo mit Schraubenschlüssel, Kart auf Drehteller, „Testfahren“, Reiter Karts/Farben/Räder/Sticker/Boost/Bald verfügbar, „Meine Karts“ (freigeschaltet/gesperrt mit Bedingung), „Lern-Boost belohnt dich!“, „Fair und kindgerecht“ | Flutter-Menü; Kart-Vorschau als Bild bzw. Godot-Render, „Testfahren“ startet Godot |
| `k04`–`k07` Strecken | Wissenswald & Bibliothekpfad, Lichterstadt Circuit, Wasserfall-Klippen Run, Himmelsinseln Sprint. Jede Strecke hat 6 Abschnitte, eine Abkürzung, ein optionales Lern-/Rätsel-Tor und eine Streckenübersicht. | Godot (`Ullmann27/lumo-godot`); die Vorschaubilder für `k08` daraus |
| `k02_welt_bausteine.png` | Strecken-Bausteine (gerade, Kurven, Brücke, Tunnel, Kreuzung, Rampe), Natur, Deko, Spezial-Orte, Materialien | Godot-Baukasten |
| `k03_gameplay_elemente.png` | Turbo-Pad, Speed-Ring, Item-Box, Stern-Token, Checkpoint, Zieltor, Leitplanke, Pfeilschilder, Abkürzungs-Rampe, Start-Ampel, Lern-Boost-Portal, Buch-Token, Schild-Power-up, Turbo-Batterie, Reparatur-Pad | Godot |
| `k10_kart_uebersicht.png` | Gesamtbild: Strecken-Welten, Lumo & Kart von vorne/seitlich/hinten, Farbwelt | Referenz für Godot-Figur, Kart und Licht; zusammen mit `08_kart_rennen_hud.png` für das HUD |

## Regeln

1. **Lernen ist im Kart optional** („Lernen ist ein Extra – nicht Pflicht!“): Lern-Boost-Tore und Rätsel geben Extras (Turbo, XP), blockieren aber nie das Rennen.
2. **Echte Daten:** Sterne pro Strecke/Cup, freigeschaltete Karts („3/8“) und Sammelziele kommen aus gespeichertem Fortschritt, keine Beispielzahlen.
3. **Gesperrte Inhalte** zeigen die echte Freischalt-Bedingung (z. B. „Sammle 50 Sterne“). Nichts ist kaufbar.
4. **Fair und kindgerecht:** Upgrades nur kosmetisch bzw. Spaß, kein Vorteil, der Rennen entscheidet.
5. **Figuren:** Lumo (Fuchs), Häsin, Schildkröte, Wolf/Katze wie in den Bildern.

## Offene Widersprüche in den Bildern (bis Heinz entscheidet)

- **Untere Leiste:** `k09` zeigt Start · Lernen · Spielen · Tests · Profil (= App-Navigation, gilt). `k08` zeigt „Rennen/Erfolge“, `k01` zusätzlich „Garage“. Umsetzung vorerst: App-Navigation bleibt; Garage, Cups und Erfolge werden innerhalb von Lumo Kart über die Bildkarten/Buttons erreicht.
- **Schreibfehler:** `k08` zeigt „LIMO KART“. Richtig ist **LUMO KART** (`assets/lumo_design/logo/logo_lumo_kart.png`).
