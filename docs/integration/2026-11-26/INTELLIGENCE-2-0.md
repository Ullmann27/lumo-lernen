# LUMO Intelligence 2.0 – Kandidat 2083 · Übergabe an Fable 5.2 (26.11.2026)

Auftrag: „LUMO INTELLIGENCE 2.0 – OPERATION NEXT GENERATION“ (Heinz, 25.11.2026) und
„Ergänzende Entwicklungsfreigabe“ (26.11.2026). Koordination: Claude Opus 5.5 mit Teams
A1–A6, B1–B3, C12. Dieses Dokument beschreibt nur, was tatsächlich gebaut und geprüft wurde.
Kennzeichnung: PASS LOKAL / PASS CI / PASS EMULATOR / PASS GERÄT / FEHLER / NICHT GETESTET.

## 1. Identität des Kandidaten

| | Wert |
|---|---|
| App (Flutter) | `Ullmann27/lumo-lernen`, Zweig `opus/lumo-intelligence-2-0-20261126`, Stand dieses Dokuments |
| Spiele (Godot 4.6.3) | `Ullmann27/lumo-godot`, Zweig `opus/lumo-intelligence-2-0-20261126`, Pin in `config/godot-source.json` |
| Version | `0.15.0+2083` (versionCode 2083) |
| Paket / Signatur | `dev.ullmann.lumo.lumo_lernen.coachpreview`, Zertifikat SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` (unverändert, `tools/lumo-debug.keystore`) |
| Bau | `.github/workflows/lumo-intelligence-2-0.yml`, ausgelöst nur durch `config/intelligence-2-0-apk-request.json` |
| Basis | 0.14.9+2082 (Flutter `6574b19f`, Godot `62108c03` = Godot-PR #230), dazu PR #554 und #555 |
| main | unverändert; kein Merge, kein Release, frühere APKs unberührt |

Kinderprofile, Lernfortschritte, Spielstände, Belohnungen, Gutscheine, Schreibtrainer und
Journal: kein Speicherformat entfernt oder umbenannt. Neue Felder sind rückwärtskompatibel;
Migrationstests mit 2082-Spielständen siehe Abschnitt 4.

## 2. Was neu ist

### Team A – Lernen, Eltern, Schule (App)
- **PR #555-Konflikt** semantisch gelöst (`3bdfeeb9`): Hilfenutzung erscheint als Anzahl
  („Hilfe genutzt bei 2 von 5 Antworten“), nie als Prozent, der wie Leistung gelesen würde.
- **A1 Lehrplanprüfung Kl. 1–4:** Prüfmatrix aller Lernkacheln aus der echten Oberfläche
  (`docs/qa/lernmodul_pruefmatrix.*`, `test/qa/lernmodul_pruefmatrix_test.dart`),
  Prüfbericht `docs/qa/LERNMODUL_PRUEFBERICHT_2026-11-26.md`, Korrekturen: Lösungen nicht
  mehr an Kartenlänge/-lage erkennbar (Deutsch, Logik, Abenteuer-Mathe, Sachunterricht),
  Mathematik-Lösungen unabhängig nachgerechnet, Kalenderfragen in den Sachunterricht,
  Fachreinheit gemischter Übungen, kein unbewertetes Schreibtraining in Tests.
- **A2 Nachhilfe mit fünf Stufen** (Hinweis, andere Erklärung, visuell, gemeinsam,
  Verständnisprüfung) für Plus/Minus, Kopfrechnen bis 100, Einmaleins; bewegtes Material,
  Zahlenstrahl mit echtem Fuchs, Ziffernblock fest sichtbar (Fold innen ohne Scrollen).
- **A3 Eltern/Schule:** „Auf einen Blick“ (Stärken, Förderbedarf, Lernplan, Entwicklung),
  LUMO-Stil (dunkelblau, goldene Hauptknöpfe, Cyan, lebendiger Lumo), Hausaufgaben
  Mathematik/Deutsch Kl. 1–4, Schreibtrainer ohne Überlauf bei 360/412 dp und Fold innen.
- **A4 Lehrplanentscheidungen:** drei Ebenen „Schulwissen“, „Vertiefung“, „Lumo
  Expertenwelt“ (nichts gelöscht; Expertenwelt nie in Tests/Schularbeiten ohne ausdrückliche
  Auswahl, durch Prüfmatrix-Spalte „Ebene“ abgesichert); Lernhub Mathematik zeigt die Ebenen
  getrennt; Rechendiagramme in Mathematik Kl. 4, Sachunterricht behält Wetter/Natur/Verkehr/
  Umwelt; Deutsch-Schularbeit prüft Sprache, Lesen und Rechtschreibung wie beschrieben;
  Logik „Welche dieser Zahlen erfüllt alle drei Regeln …“; Schreibthemen einer anderen Klasse
  starten eine Schreibübung; Sachunterricht-Fragenbanken: richtige Karte nicht mehr
  überdurchschnittlich oft die längste (`test/qa/sachunterricht_ablenker_test.dart`).
- **A5 „Lumo erkennt Verständnis“:** nach Hilfe folgt eine vergleichbare selbstständige
  Aufgabe; selbstständig richtig = neues Verständnis-Indiz; bei wiederholter Schwierigkeit
  wechselt die Erklärungsmethode; Eltern sehen „Später bestätigt“. Fach-Nachhilfe mit fünf
  Stufen auch für Englisch, Lesen und Sachunterricht; Hausaufgaben für Englisch, Lesen und
  Sachunterricht.
- **A6 Elternkennzahlen:** Die vier Kacheln in „Lumo Insight“ zeigten 0, obwohl 36 Antworten
  vorlagen. Ursache: zwei Datenquellen, „nicht geladen“ als 0, unterschiedliche Grenzwerte,
  Antworten nur in einer Quelle. Jetzt gleiche Grundlage wie „Auf einen Blick“, eigene
  Zustände „wird geladen“ / „nicht geladen“ (mit Erneut-Knopf) / „noch offen“ / echte 0,
  alte Zähler ohne Doppelzählung einbezogen, ein Ladevorgang je Profil. Neue Android-Probe
  `.github/probes/lumo_parent_insight_android_probe.py` (im Workflow nach der Tour).

### Team B – Spiele und Kart (Godot, Lernspiele in der App)
- **B1 drei Signatur-Strecken:** Vulkanexpress – Feuerinsel (`vulkanexpress_3100`, 3151 m),
  Wolkensturm – Himmelsmetropole (`wolkensturm_3300`, 3323 m, 360°-Wendel), Kristallflut –
  versunkene Abenteuerwelt (`kristallflut_2800`, 2823 m, Unterwassertunnel). Abzweige,
  angekündigte Tore, Heldensprünge, je eine 36°-Steilkurve; Baukasten
  `scripts/games/kart_signature/`, Blender-Skripte `tools/lumo_signature_art/`.
- **B2 Figuren und Fahrzeuge:** stehende, gehende Tierfiguren (9 Arten, 30 Knochen,
  Clip-Bibliothek mit Gehen, Laufen, Drehen, Hinsetzen/Aufstehen, Gesten, Ein-/Aussteigen;
  nahtlose Übergänge < 3 cm), Anschluss in der offenen Welt (Modellpfad, Schrittrate ohne
  Fußgleiten), Kart-Federung (Nicken/Rollen/Landung), Garage-Werkzeugleiste im
  Fold-Querformat zweizeilig. Inventar `docs/qa/figuren_fahrzeuge_inventar.md`,
  `docs/qa/figuren_clipbibliothek.md`.
- **B3a Fahrgefühl und Gegner-KI:** Untergrund, Kamera-Körpersprache, Gangwechsel,
  Rempler, vier Grafikstufen; Gegner bremsen vorausschauend, haben eine Antriebsgrenze,
  nutzen Windschatten (Schleuder zündet erst seitlich neben dem Vordermann), machen kleine
  Fehler und machen Platz. Computergegner bleiben als solche erkennbar.
- **B3b Spiele:** Karten – Mitspieler nehmen ihre Karte sichtbar auf, bevor sie sie legen;
  Schach – Figuren heben an, gleiten, setzen weich ab; Sternenjagd – Pause (Knopf,
  Zurück-Geste, Hintergrund). Lernspiel-Einstufung laut Lehrplan (Plus/Minus bis 100 und
  Einmaleins inkl. 3er/10er → Kl. 2, schriftlich Plus/Minus → Kl. 3; Level-IDs, Freischaltungen,
  Erfolge und Spielstände unverändert), adaptive Freischaltung nach nachgewiesenem Lernstand,
  „Minus bis 10“ nur noch Karten im Zahlenraum. Inventar `docs/qa/spiele_inventar.md`.

### Team C – Offene Welt (Godot)
- **C12 Sonnenhafen:** modularer Stadtbaukasten (71 GLB aus Blender-Skript
  `tools/lumo_world_art/build_sonnenhafen_kit.py`), Hafenstadt mit Fischhalle, Markt, Piers,
  Kart-Parkplatz, Schildern; 14 Bewohner mit Persönlichkeit, Beruf, Beziehungen,
  Tagesplan (Utility-KI, Navigation nah / Polylinie fern), fünf Aufträge mit Lernquittung;
  Spielstand-Kompatibilität mit 2082 getestet. Doku `docs/SONNENHAFEN_2026-11-26.md`.

## 3. Bau und Kontrolle
Der Workflow prüft vor dem Bau: Fokus-Flutter-Tests (inkl. `test/parents`, `test/qa`,
`test/tutoring`), Analyse, vollständige Flutter-Suite, gepinnte Godot-Kernprüfungen (wie 2082)
und neu: Streckenvertrag, Signatur-Welt, je ein ganzes Rennen auf den drei neuen Strecken.
Danach APK, Paket/Zertifikat/versionCode-Kontrolle, Emulator-Tour, Sicherungsprobe,
Spielstarts und die Elternkennzahlen-Probe (erste Ausführung, Ergebnis wird ausgewiesen).

## 4. Prüfstand

Alle Angaben PASS LOKAL im Container (Linux, Godot 4.6.3 headless, Flutter 3.44.9),
26.11.2026. Gerät/Emulator: NICHT GETESTET (folgt im CI-Lauf dieses Workflows).

**App (Flutter)**
- Vollständige Suite auf `27f7d380`: 4158 bestanden, 193 übersprungen, **3 Fehler** – alle
  behoben und gezielt nachgeprüft:
  - `unit_variety_audit` (Sachunterricht Kl. 4 „Diagramme lesen“ 13 < 15 Varianten) →
    drei neue Deutungsfragen (`fce1b4e0`), jetzt 16.
  - `verstaendnis_flow_test` Methodenwechsel (zufallsabhängig rot, etwa jeder 5. Lauf) →
    Vergleichsaufgabe prüft dieselbe Kompetenz (`1690ce79`), danach 6/6 grün.
  - `math_task_templates_test` (Diagramm-Sammlung ohne Zahlenbereich) → eigene
    Vielfaltsprüfung der Sammlung (`4f23eab6`).
- Nach den Korrekturen: `test/tutoring` + `test/learning` 920 grün; `test/qa` + Vielfalt +
  Sachunterricht 172 grün; Mathe-Vorlagen 9 grün; `flutter analyze` 304 Hinweise
  (= Ausgangszahl, keine neuen).
- Zusammenführungsstand vorher: `test/qa`, `test/parents`, `test/tutoring`, `test/games`,
  Hausaufgaben, Lehrkraft, Bericht: 1068 grün. Elternkennzahlen-Probe (Python): 21 grün.
- Vollständige Suite auf dem allerletzten Stand: NICHT lokal wiederholt (läuft im CI).

**Spiele (Godot, Endstand `dedc588c`)**
- Godot-Prüfungen des 2082-Workflows: 29 von 31 im Parallellauf grün, die übrigen zwei
  (`kart_extra_drivers`, `lumo_world_kart_ground`) einzeln grün (siehe unten), u. a. Karten-, Schach- und
  Tischfluss, Kart-Garage/-Heim/-Ergebnis, Lernwerkstatt, Lauf (1278 s), Parcours, Welt
  (Aufträge, Erstbetritt, Routinen, Spielstand).
- Neu grün: Karten-, Schach-, Sternenjagd-Durchspiel; Kart-Federung, Fahrgefühl (104),
  Streckenvertrag, Signatur-Welt, **Signatur-Rennen auf allen drei neuen Strecken**,
  Figuren-Animation (1854 Prüfungen), Sonnenhafen Aufträge/Bewohner/Spielstände,
  Kart-Physik, Fahrbarkeit aller Strecken, Items, Raketen-Fairness.
- Unter Volllast (drei Reihen parallel) rot, einzeln grün: `kart_extra_drivers`
  (333/333 einzeln), `kart_fahrgefuehl` (gemeinsame Einstellungsdatei paralleler Läufe).

## 5. Offene Punkte und bekannte Fehler (für Fable 5.2)

1. **Gegner-KI hängt auf Dschungelherz (`jungle_emerald_3600`, Stufe pro):** ein Rival bleibt
   bei ≈ 2372 m stehen (4/5 im Ziel). Repro: `kart_rival_ai_regression.gd -- --tracks=jungle_emerald_3600`.
   Stammt aus `53f89a2f` (B3a); die angefangene Windschatten-Schleuder verschlimmerte es und
   wurde zurückgenommen (`dedc588c`). Außerdem dort: Stufe „flott“ auf `jungle_temple`
   nicht klar langsamer als „pro“. Der Test steht deshalb nicht im Bau-Workflow.
2. **Vorbestehend rot (schon auf 2082 `62108c03`):** `kart_detail_layer_regression`
   (zu wenig Bühne/Leben auf Zauberwald u. a., Mast bei crystal_canyon, Höhenfeld-Index in
   `kart_world._ground_height`), `kart_workshop_regression` (2 UI-Prüfungen, hängt danach),
   `kart_production_vehicle_regression`/`kart_fleet_regression` (erwarten 3 statt 4 Quellen),
   `lumo_world_hud_regression`, `lumo_world_support_integration` (die letzten vier laut
   Teamberichten, von mir nicht nachgeprüft).
3. **`kart_adventure_regression`:** veraltete Gesamtzahl korrigiert (`959305c3`); dahinter
   jetzt sichtbar: 10× „Reserved tunnel contains a pad“ (Tunnel-/Pad-Code seit 2082 unverändert).
4. **`lumo_world_kart_ground_regression` ist instabil**, schon auf 2082 (dort 3 von 4 Läufen
   rot, Kart in der Torsäule); auf dem Endstand 4/4 grün. Steht im Bau-Workflow – ein
   zufälliger Fehlschlag dort ist dieser bekannte Fall.
5. **Nicht begonnen:** C3 (≥ 30 Missionen, Wirtschaft, Langzeitmotivation, Geschichte);
   Städte Sternenstadt und Waldheim (nur Sonnenhafen gebaut); echte Bob-Wandpassagen
   (je Strecke nur eine 36°-Steilkurve, Streckenvertrag begrenzt); Lumo-Clips Drehen,
   Hinsetzen/Aufstehen, Überraschung, Enttäuschung, Ein-/Aussteigen (Tierfiguren haben sie).
6. **Bewusst offen:** Schwächen werden ohne Fach gespeichert (Prüfbericht Punkt 9) – eine
   echte Lösung ändert das Profilformat; der Generator verhindert Fachwechsel bereits.
7. **Entscheidungen für Heinz:** „Lerntage in Folge“ zeigen morgens vor dem Üben 0 („zuletzt
   gestern“); „Denkprofil“ zählt als Lernantwort.
8. **Elternbericht, Themenübersicht, KI-Prompt** nutzen weiter die alten Themenzähler
   (KI standardmäßig aus); Fehlerarten-Karte erscheint nie.
9. **Elternkennzahlen-Probe** läuft im CI zum ersten Mal und blockiert noch nicht.
10. Bilder 1080×2340 / 2176×1812 für Hausaufgaben Englisch/Lesen/Sachunterricht fehlen;
    Gerät (Fold7), Ton und Bildrate (keine FPS-Messung) NICHT GETESTET.

## 6. Zweige (alle gepusht)
App: `opus/agent-a1-curriculum`, `opus/agent-a2-nachhilfe`, `opus/agent-a3-eltern`,
`opus/agent-a4-lehrplan(-wip)`, `opus/agent-a5-verstaendnis(-wip)`, `opus/agent-a6-kennzahlen`,
`opus/agent-a6-probe`, `opus/agent-b3-spiele`.
Godot: `opus/agent-b1-strecken`, `opus/agent-b1-fix`, `opus/agent-b2-figuren(-wip)`,
`opus/agent-b3-fahrspass(-wip)`, `opus/agent-b3-spiele`, `opus/agent-c12-welt`.
`-wip` = beim Abbruch der Agenten gesicherter Stand; vom Koordinator geprüft und
zusammengeführt (Abschnitt 4).

## 7. Reproduktion
```bash
# App
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings   # 304 Hinweise = Ausgangszahl
flutter test --no-pub test/qa test/parents test/tutoring test/games
LUMO_UPDATE_PRUEFMATRIX=1 flutter test --no-pub test/qa/lernmodul_pruefmatrix_test.dart  # nur nach gewollter Kachel-Änderung
python3 -m unittest discover -s tools/android_qa/tests -p "*insight*"
# Godot (im Godot-Repo, nach einmaligem Import mit --single-threaded-scene)
godot --headless --path . --script res://scripts/tests/kart_track_contract.gd
godot --headless --path . --script res://scripts/tests/kart_signature_race_regression.gd -- --track=kristallflut_2800
godot --headless --path . --script res://scripts/tests/lumo_world_sonnenhafen_mission_regression.gd
godot --headless --path . --script res://scripts/tests/lumo_figure_animation_regression.gd
```
