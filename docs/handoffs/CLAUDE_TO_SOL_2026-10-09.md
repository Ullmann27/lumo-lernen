# Übergabe von Claude an ChatGPT Sol 6.1 · 9. Oktober 2026

Heinz hat die Weiterarbeit wieder an ChatGPT Sol 6.1 übergeben. Diese Datei beschreibt den
Stand des Claude-Strangs (Branch `claude/continue-previous-chat-KtY7p` in beiden Repositories),
was tatsächlich geprüft ist, was nicht, und womit es weitergeht. Statuswörter: **PASS** nur nach
echter Ausführung, **FAIL**, **NOT EXECUTED**, **VISUAL_GAP**. Nichts hier ist ein Release.

Vor jedem Schreiben die frischen Branch-Heads, offenen PRs und Claims lesen; fremde Stände
(Codex-PRs 214/215/216/221 in der App, 27/28/29/31 in Godot) nicht überschreiben, kein Force-Push,
kein Merge nach `main`, keine Veröffentlichung ohne Heinz.

## 1. Stände

Die aktuellen SHAs und der Build stehen im Abschnitt „Endstand“ unten (wird mit dem letzten
CI-Lauf gefüllt). Aufbau des Claude-Strangs:

- **Godot** (`Ullmann27/lumo-godot`, `claude/continue-previous-chat-KtY7p`): Codex-Recovery
  `4b63ec2` (enthält PR 29/31 mit Rundenspeicherung und Teardown-Schutz) plus
  14 Karts mit fünf Werten, Tuning-Werkstatt mit Prüfstand, Kart-Karten in der Garage,
  Baukasten-Karts mit gemeinsamem Cockpit, Item-Abzeichen, Himmels-Leckschutz, Action-Parcours.
  Eigene Dokumente: `docs/KART_FAHRZEUGE_2026-10-08.md`, `docs/KART_ACTION_PARCOURS_2026-10-09.md`;
  Bilder: `docs/proof/2026-10-09-action/`, Referenzen `docs/design_targets/2026-10-08-kart-fahrzeuge/`.
- **App** (`Ullmann27/lumo-lernen`, gleicher Branchname): Codex-Recovery `8abb01a` (PR 221, enthält
  PR 216) plus Merge PR 214 und 215, Lumo Knobel-Test (IQ-Test für Kinder, Oberfläche, Tests,
  Aufnahmen unter `docs/proof/2026-10-08-iq/`), Aufräumen der Analyzer-Warnungen (0 Fehler, 0 Warnungen,
  131 Stilhinweise bleiben), Pin auf den Godot-Stand, neue Versionsnummer, CI-Anpassungen.

## 2. Was in diesem Strang entstanden ist

1. **Zusammenführung.** Beide Codex-Stränge (Referenz/Kamera und Runtime/Kontinuität) sind
   mit dem Claude-Strang vereinigt; Konflikte in `kart_fleet.gd`, `kart_vehicle.gd`,
   `kart_touch_action.gd`, `kart_joystick.gd`, `kart_garage_menu.gd`, `kart_island.gd` und den
   Tests wurden so gelöst, dass beide Seiten erhalten blieben (Merge-Commits beschreiben das).
2. **Flotte.** 14 Karts (Comet, Gecko Velo, Boru Rally, Glider, Nala Comet, Noa Tide, Iva Aurora,
   Aurora GT, Zuri Volt, Blitz, Terra, Koloss, Phantom, Stella) mit fünf Werten (Tempo,
   Beschleunigung, Bremsen, Handling, Turbo), die in der Fahrphysik wirken. Neun Karts nutzen die
   geloftete Codex-Karosserie, fünf den Plattenbaukasten.
3. **Werkstatt mit Prüfstand.** Motor, Bremsen, Reifen, Turbo je Stufe 0–5, Lack/Felgen/Neon,
   Budget = alle je verdienten Fortschrittssterne (Belohnungssterne der App bleiben unberührt),
   Rückgabe aller Sterne, Speicherung je Kind. Neu: Prüfstand (Höchsttempo km/h, 0–54 km/h,
   Bremsweg aus 72 km/h) mit Vorher/Nachher, geprüft gegen echte Fahrten.
4. **Action-Parcours** auf 11 Strecken (Turbo-Felder, Slalom mit Hütchen, Sprungschanze,
   Unterwasser-Tunnel, offene Kanten mit fairer Rettung). **Sonnenhafen ist bewusst unverändert**
   (Prüfstrecke des Android-Rennablaufs).
5. **Leck-Behebung.** Seit dem strengen Probe-Runner (`tools/run_godot_probe.py`: jede `ERROR:`-Zeile
   zählt) leakten Einstellungen, Rennbrücke und Rundenspeicherung Godot-Texturen beim Beenden.
   Auf dem unveränderten Recovery-Stand reproduziert (2 / 10 / 14 Meldungen); Ursache: Ein im
   Kompatibilitäts-Renderer schon gezeichneter Himmel lässt beim Freigeben zwei 256er-Texturen
   liegen. Behebung: Himmel je Strecke einmal anlegen und wiederverwenden. Das erste Festhalten für
   1 s war nur ein Zufallstreffer und wurde ersetzt.
6. **Android-QA-Bindung.** `tools/android_qa/native_lap_evidence_recovery.py` bindet jetzt die
   gepinnten Dateien des integrierten Godot-Stands; die Fixture-Tests prüfen weiter gegen die
   historischen Quellen, aus denen die Fixtures stammen.
7. **CI.** `lumo-runtime-apk.yml` läuft auch auf dem Claude-Branch; neue Proben
   `kart_fleet_stats_regression`, `kart_workshop_regression`, `kart_action_course_regression`
   (Markerliste 22 → 25). Der alte `lumo-1700-android.yml` startet nur noch manuell.
   **Bewusste Änderung der Recovery-Vorgabe „45-Minuten-Job“:** Der Android-Job darf 75 Minuten
   dauern und der Rennprüfer 2100 s warten, weil API 36 auf dem Software-Emulator rund 1,8-mal
   langsamer fährt als API 35 (siehe 3.). Es sind nur Wartezeiten; kein Rennkriterium wurde
   geändert.

## 3. Nachweise (alles tatsächlich ausgeführt)

- **Flutter:** 791 bestanden, 21 übersprungen, 0 Fehlschläge (lokal und im CI-Lauf 37880993479).
- **Python-QA:** 534 Harness-Tests (8 übersprungen), 36 Skripttests; `summarize_native_lap_evidence`
  besteht mit echten Belegen des integrierten Stands (104 Prüfungen, Gesamtablauf 01:22.983 / 00:41.183).
- **Godot lokal, strenger Runner** (Godot 4.6.3, Xvfb, Mesa llvmpipe): alle Regressionsproben außer
  `kart_vehicle_regression` melden ihre PASS-Zeile; `kart_vehicle_regression` hat keine Zeile mit
  „PASS“, sondern `[KartVehicle] Geometry/colours, shadows, animations, effects, LOD and hysteresis
  passed` (die CI nutzt diesen Marker). Aufnahme-Proben Flotte, Grafik, Referenz, Lenkrad, Fahrt: grün.
  Genauer Endlauf im Abschnitt „Endstand“.
- **CI-Lauf 37880993479** (APK 0.12.5+1907 aus App `36391b2`, Godot `99cdb77`): Build, Flutter,
  24 strenge native Proben PASS; Android API 35: Kart-Vollrennen, Bauwelt, Puzzle, Rhythmus,
  Schatzsuche PASS. **Android API 36 Kart: FAIL** – Wartefrist erreicht (597 s nach Wiederaufnahme erst
  45 s Spielzeit; API 35 brauchte 491 s für das ganze Rennen). Ob das allein am Emulator liegt, ist
  nicht bewiesen; die Frist wurde angehoben (siehe 2.7), das Ergebnis des neuen Laufs steht unten.
- **Nicht ausgeführt:** physisches Fold/Samsung, Bildrate auf echter Hardware, Dauerbetrieb/Wärme,
  Tonabnahme am Gerät, Kamera-/Bewegungsvideo des Action-Parcours auf Android.

## 4. Offen, in dieser Reihenfolge

1. **Referenzgleichheit (VISUAL_GAP).** Lumo, Anzug, Fell, Gesicht und Kart sind sichtbar einfacher
   als Heinz' Referenzbilder (`docs/design_targets/2026-10-08-kart-fahrzeuge/`). Kein Bild oder
   Billboard darf den Fahrer ersetzen. Einzelne Kontaktprüfungen beweisen nicht jede Fläche.
2. **Längere Strecken.** Gemessene Rundenlängen: Zauberwald 377 m, Holo-City 443 m, Himmelsinseln
   473 m, Sonnenhafen 545 m; die acht Erweiterungswelten 690–803 m. Eine Mario-Kart-Runde
   (Recherche: 34–48 s bei guten Spielern, ca. 700–1000 m) braucht für die vier Grundwelten neue
   Streckenführungen. Sonnenhafen mit Parcours erst nach neuer Abnahme des Android-Rennablaufs.
3. **Sporadischer ACK-Save-Fehler** der Voll-Ablauf-Probe (Recovery-Übergabe): in diesem Strang nicht
   reproduziert (Gesamtablauf lokal mehrfach grün); der Scene-Teardown-Schutz von Codex (`4b63ec2`) ist
   enthalten. **Nicht als behoben beansprucht.** Weiter beobachten: Quelle des Schreibaufrufs.
4. **Werkstatt-Werte** (Teile je Stufe nur +0,2 bis +0,5 Punkte, höchstens +2): Wirkung ist messbar
   (Prüfstand), aber moderat. Eine kräftigere Abstimmung wäre eine Spielbalance-Entscheidung von Heinz.
5. **Gerät:** Fold außen → innen → außen, Framezeiten, Speicher, Wärme messen; erst dann Aussagen zu
   Leistung. Grafikprofil auf Android ist „medium“.
6. **App:** großer frei agierender KI-Lernassistent, Stimme/Musik am Gerät abnehmen, Lern-Inhalte
   Klasse 1–4 erweitern (Aufgabe #9 offen).
7. **Aufräumen:** `.uid`-Dateien vieler Skripte sind in Godot-Repositories untracked; sie wurden nicht
   pauschal committet.

## 5. Arbeitsweise, die sich bewährt hat

- Kleine Commits, ein Thema je Commit; Commit-Nachrichten nennen Messwerte statt Behauptungen.
- Godot-Proben immer mit dem strengen Runner lokal prüfen:
  `xvfb-run -a -s '-screen 0 2400x2400x24' godot --audio-driver Dummy --rendering-method gl_compatibility --script res://scripts/tests/<probe>.gd`
  und jede Zeile mit `ERROR:`, `SCRIPT ERROR`, `Assertion failed` als Fehler werten; vor Läufen
  `~/.local/share/godot/app_userdata/Lumo 3D` löschen; nach neuen Assets `godot --headless --path . --editor --import --quit`.
- Nie Skripte ändern, während eine lokale Testreihe läuft (Tests laden die Dateien live).
- Die Zusammenführung der Android-Hashes: bei jeder Änderung an `kart_island.gd` oder den gebundenen
  Proben die Konstanten in `tools/android_qa/native_lap_evidence_recovery.py` neu aus den echten
  Dateien setzen und `summarize_native_lap_evidence` mit lokal erzeugten Belegen prüfen.
- APK-Auslieferung: Artefakt `lumo-visual-apk-<Lauf>` des Laufs `lumo-runtime-apk.yml` (APK,
  `SHA256SUMS.txt`, `BUILD-PROVENANCE.json`). Hash, Paket, Version, Zertifikat, ABIs und PCK-Hash
  gegen die Herkunftsdatei prüfen; die APK ist größer als das Upload-Limit der Chat-Oberfläche (30 MiB).

## Endstand (Stand beim Abschluss, 9. Oktober 2026)

| | |
|---|---|
| App-Head (Quelle der APK) | `68ab2064276bfdf408d899083f06d8d4b2f354af` |
| Godot-Pin / Godot-Head | `9a3dcbd62e78fbb59ef2c3521bf534c4e76dfb5c` |
| Version | 0.12.6, Build 1908 |
| Paket / Zertifikat | `dev.ullmann.lumo.lumo_lernen.coachpreview` / `a6b1ef61…db80702` (unverändert) |
| APK | 203.808.386 Bytes, SHA-256 `070bcb40d58387a312fcaa37fd9e7ad9dff18eadcf71c8eea3f339a0b7fb7378`, arm64-v8a und x86_64, PCK-SHA-256 `65ca0522…a034` |
| CI-Lauf | 37913484330, Artefakt `lumo-visual-apk-37913484330` (ID 11608789766) |

Der Hash der heruntergeladenen APK wurde gegen `SHA256SUMS.txt` und `APK-VERIFICATION.json` nachgerechnet.
Dieser Lauf bestätigt:

- **PASS:** Build-Job (Flutter-Analyse, volle Flutter-Suite, Python-Vorbereitungstests, 25 strenge
  native Proben auf Godot 9a3dcbd, Aufnahmen Flotte und Hafen) sowie auf Android API 35 Bauwelt, Puzzle,
  Rhythmus und Schatzsuche.
- **OFFEN beim Abschluss:** Android Kart API 35 und API 36 (Vollrennen, Pause, Ergebnis, ACK, Belohnung,
  Neustart) liefen noch. Ihr Ergebnis steht im Lauf 37913484330 und ist hier nicht eingetragen; bis es
  gelesen ist, gilt die Kart-Android-Abnahme dieses Builds als **NOT CONFIRMED**. Beim Vorgängerbuild
  1907 bestand API 35, API 36 scheiterte an der Wartefrist (Frist inzwischen von 1200 auf 2100 s).
- **Nicht in der APK getestet:** Action-Parcours auf Android (Sonnenhafen, die Strecke der Android-Probe,
  hat ihn bewusst nicht), physisches Fold, Bildrate.

Der Ablauf zum Abholen: Artefakt `lumo-visual-apk-37913484330` herunterladen (GitHub-Login nötig, bis
07.01.2027 abrufbar), Hash prüfen, installieren (gleiche Paketkennung und gleicher Schlüssel, Update
über Build 1907 oder älter).

## Erste Schritte für Sol 6.1

1. Ergebnis der Jobs „android (kart, 35)“ und „android (kart, 36)“ im Lauf 37913484330 lesen. Bei
   Rot zuerst die Ursache aus `native-proof/full-race/result.json` und `race-trace.json` ablesen;
   Wartefristen und Rennbedingungen getrennt bewerten.
2. Die vier Grundstrecken verlängern (siehe 4.2) und Sonnenhafen mit Parcours neu abnehmen.
3. Referenzgleichheit von Lumo und Kart gegen die Bilder in
   `docs/design_targets/2026-10-08-kart-fahrzeuge/` angehen (4.1).
