# Übergabe an ChatGPT – Lumo Lernen und Lumo Kart (9. Oktober 2026)

Zum Einfügen als Startnachricht. Heinz' Regeln stehen vorn, danach Stand, Reihenfolge und Abnahmekriterien.
Alles hier ist am Quelltext oder in Actions-Läufen geprüft; Unsicheres ist markiert.

---

**Auftrag:** Arbeite am bestehenden Projekt weiter. Kein neuer Prototyp. Mario Kart ist nur Qualitätsmaßstab, nichts wird kopiert.

## 0. Regeln (verbindlich)

- Kein Force-Push, kein Merge nach `main`, kein Release ohne ausdrückliche Freigabe von Heinz. Keine fremden Änderungen löschen.
  Kleine Commits, eine Sache pro Commit. Erst lesen, dann schreiben.
- Bestehende Tests nie löschen, abschwächen oder durch Blind-Assertions ersetzen. Neue Tests müssen am alten Stand fehlschlagen
  (Rot/Grün zeigen).
- Nur Geprüftes melden. Kein „identisch zur Vorlage“, kein „AAA erreicht“, kein „60 FPS“ ohne physisches Gerät.
  „APK technisch fertig“ und „visuell abgenommen“ getrennt berichten. Kein Übermalen, keine KI-Verschönerung von Runtime-Bildern,
  keine Konzeptbilder statt Renderings.
- Im Rennen selbst keine Lernfragen, Lern-Cups, Antworttimer oder „richtige Antwort = Turbo“ (`docs/DESIGN_ZIEL_KART_2026-10-04.md`).
- Keine Nintendo-Assets oder fremder geschützter Code. Freie Assets nur mit dokumentierter Lizenz.
- `flutter analyze` ohne Fehler (aktuell 0 Hinweise), `flutter test` grün, jede Datei in `lib/` von `lib/main.dart` aus erreichbar,
  Bilder als Dateien unter `assets/` (nie Base64), echte Daten statt Beispielzahlen.
- APK 1909 bleibt der unveränderte, geprüfte Rückfallstand. Paketname und Signatur behalten.

## 1. Repos, Zweige, Stände

- App: `Ullmann27/lumo-lernen`, Zweig `claude/continue-previous-chat-KtY7p`. Godot-Spiel: `Ullmann27/lumo-godot`, gleicher Zweig.
- Die App pinnt Godot per `config/godot-source.json` auf `de91cc966f7a8b5d43b04e0dd9d67b0e28dbe09b`. Ändere den Pin nur auf einen
  **gepushten** Godot-Commit und binde danach die Quell-Hashes in `tools/android_qa/native_lap_evidence_recovery.py` und
  `native_handoff_evidence_recovery.py` (`kart_island.gd`, Proben) neu, geprüft gegen echte lokale Exporte.
- Lies zuerst: `OPUS_NEXT.md`, `docs/LUMO_VISUAL_EXECUTION_2026-10-09.md` (Matrix, Prüfungen, APK), `docs/LERNAPP_PRUEFBERICHT_2026-10-09.md`,
  im Godot-Repo `docs/wip/2026-10-09-lumo-gesicht/README.md`.
- APK 1913: Run 37937263563 (Artefakt `lumo-visual-apk-37937263563`), SHA-256 `bc6dfc93fd20e39fa01e088f35215066884bf59e649d4bde76428318e59b9fb1`.
  APK 1914 entsteht aus dem Push `c23c70a`; Ergebnis in den Actions.
- Concurrency: ein Push auf den Zweig bricht den laufenden APK-Lauf ab. Deshalb Änderungen sammeln und einmal pushen.
  Reine Doku-Pushs (Pfade `docs/**`, Wurzel-`*.md`) lösen keinen Lauf aus.
- Offene PRs anderer Instanzen (nicht mein Stand, nicht löschen): App #223, #224, #225, #226, #229; Godot #32, #33, #34, #35, #36.
  #227/#228 und Godot #37 sind eingearbeitet.

## 2. Arbeitsweise

Beobachten → Diagnose → Plan → Umsetzen → Bauen → Rendern → Testen → Vergleichen → Verfeinern. Eigene Arbeitsbäume für lange Läufe
(`git worktree`). Lokale Godot-Läufe strikt wie die CI: jede Zeile `SCRIPT ERROR`, `Assertion failed`, `Parse Error`, `Failed to load`
oder `ERROR:` ist ein Fehlschlag (`tools/run_godot_probe.py`). Proben mit `LUMO_QA_DIR` brauchen die Umgebungsvariable.
Nie Skripte oder Assets ändern, während eine Suite läuft. Nach neuen Assets `godot --headless --path . --editor --import --quit`.

## 3. Aufgaben in dieser Reihenfolge

### A. Lumo (Figur) nach den Referenzblättern – größte sichtbare Lücke
Referenzen: `docs/design_targets/2026-10-08-kart-fahrzeuge/` (7 PNG + README), besonders `03_…`, `06_…`, `07_…`.
Stand: Der Patch `docs/wip/2026-10-09-lumo-gesicht/lumo_gesicht_wip.patch` (Godot-Repo) liegt auf `de91cc9` (`git apply --check` bestanden):
neuer Kopf, Augen mit Iris-Kappe, Schnauze, Ohren mit dunklen Spitzen, Brille, Anzugteile, Garagenlicht von vorn, Aufnahmeskript für acht
Ansichten mit Messwerten. Eine Messung VORHER/NACHHER steht in der README; **die Referenzmaße sind noch nicht ausgemessen**.
1. Referenzmaße (Augenbreite/Kopfbreite, Iris/Auge, Pupille/Iris, Augenabstand, Nasenbreite, Ohrposition, Fahrerposition) aus den Blättern
   messen und in die Tabelle eintragen.
2. Patch einbauen, dann: Augen in der Dreiviertelansicht (wirken flach), Lider, Blickrichtung, Fell- und Stoffmaterial (Detailaufnahme),
   Handschuhe, Schulterpolster, leuchtendes Brust-L, Rückseite, Schwanzansatz. Keine Geometriefehler an Gelenken.
3. Acht Ansichten aus der Engine: Gesicht vorn, Gesicht seitlich, Kopf dreiviertel, Ganzkörper, im Kart vorn, Kart mit Fahrer seitlich,
   Kart hinten, Verfolgerkamera während der Fahrt. Immer REFERENZ | VORHER | NACHHER. Status bleibt „VISUAL_GAP – NOT ACCEPTED“, bis die
   Bilder nah sind und Heinz es sagt.
4. Schnittstellen für Animation, Fahren, Steuerung und `set_look`/`configure` bleiben. Alle Fahrzeug-/Fahrer-Regressionen laufen lassen:
   `kart_vehicle_regression` (Endmarker: „…hysteresis passed“), `kart_vehicle_detail_regression`, `kart_arm_contact_regression`,
   `kart_steering_grip_regression`, `kart_fleet_regression`, `kart_workshop_regression`, `kart_menu_flow_regression`,
   `creative_adventure_capture` (Begleiter-Fuchs in der Schatzsuche; Ordner `exports/creative-build` anlegen), `holographic_companion_export`.

### B. COMET-Premiumkart
Glänzender dunkelblauer Lack, präzise Lichtkanten statt Bloom-Flecken, türkise Scheinwerferbalken, leuchtendes L auf der Haube, orange
Akzente, modellierte Reifenprofile, Felgen mit türkisen Ringen, sichtbares Fahrwerk, Bremsscheiben, Achsen, Sitz und Überrollbügel,
detailreiches Heck mit Leuchtbalken (die Rückansicht ist entscheidend). Eigene PBR-Materialien für Lack, Gummi, Kunststoff, Metall,
Stoff, Fell, Glas, Emission. Alle 14 Karts mit ihren Werten und dem Tuning bleiben erhalten (`kart_fleet.gd`, `kart_tuning.gd`).
Wichtig: Lumo und COMET müssen aus Front, Seite und Heck zusammenpassen.

### C. Grafikpipeline (Messen vor und nach jeder Optimierung)
Godot 4.6.3. Mobile-Renderer auf Android, Forward+ für Desktop-QA, GL-Kompatibilität als Rückfall. Prüfe schrittweise PBR, Kantenglättung,
Filterung, Mipmaps, Schatten, Reflexionssonden, Tonemapping, selektives Glühen, Nebel, MultiMesh, LOD, Culling, VRAM, Overdraw, Partikel.
Keine Funktionen vortäuschen, die der Mobile-Renderer nicht kann (kein TAA/FSR2/SSAO/Volumennebel). Schärfe vor Nachbearbeitung; HUD wird
nicht mit der 3D-Auflösung herunterskaliert. Profile HOCH/MITTEL/NIEDRIG. 60 FPS nur mit physischem Gerät behaupten (bisher nirgends gemessen).

### D. Spielstart und Menü (PR #226/#227/#36/#37 sind drin, nicht neu bauen)
Prüfen und verfeinern: Spielkarte mit echtem Bild, gebrandeter Splash (Lumo im Kart, Logo, Marineblau/Cyan/Gold, kein Schwarzbild),
ehrliches Laden (**keine** erfundenen Prozente, keine künstlichen Wartezeiten), Hauptmenü (animierter Lumo, echtes 3D-Kart, Modi,
Strecken-/Cup-Wahl, Garage/Tuning, echter Fortschritt), Vorschau → Laden → Kamerafahrt → Startaufstellung → Ampel → Rennen → Ziel →
Rückkehr. Referenzen: `docs/design_targets/2026-10-04/` und die neuen Bilder von Heinz (Splash, Menü, Streckenwahl, Ergebnis).

### E. Welten und Fahrgefühl
Himmelsinseln, Holo-City, Sonnenhafen (mit Aquarium), Zauberwald: je eigene Identität, drei Tiefenschichten. Kurze Strecken verlängern
nur mit Tests (Zauberwald 377 m, Holo-City 443 m, Himmelsinseln 473 m; Ziel 35–45 s Rundenzeit, 650–950 m). Sonnenhafen bleibt die
stabile Android-Referenz. Kamerawerte in `kart_visual_grade.gd` nur mit A/B-Laufzeitbildern ändern. Touch: Mehrfachtouch (lenken + Gas +
Turbo gleichzeitig), Fold innen/außen, Querformat, Safe Areas; kein Overlay darf Berührungen schlucken. Audio: Musik je Welt mit
Überblendung, Einstellungen für Ton und Bewegung respektieren, keine vorgetäuschte natürliche KI-Stimme.

### F. Lernapp (siehe `docs/LERNAPP_PRUEFBERICHT_2026-10-09.md`)
Vier Themen sind **nicht geprüft** (Abschnitt 6): Lerninhalt je Klasse gegen den österreichischen Lehrplan, Aufgaben-Fuzzing, echte
Renderings der Hauptscreens gegen `docs/design_targets/2026-10-04/`, statische Fehlersuche. Danach: Knobel-Test-Messqualität (Ablenker so
bauen, dass keine Ratestrategie über Zufall liegt; mehr Rätsel je Bereich; Sprachausgabe; Eltern-Ansicht; Mehrprofil). Neue Funktionen wie
„Lumo macht einen Fehler“ erst nach Freigabe von Heinz.

### G. Android und APK
Gates: `flutter pub get --enforce-lockfile`, `flutter analyze`, `flutter test`; Godot: `python3 tools/validate_project.py`,
`godot --headless --path . --import`, Regressionen. Android-Ende-zu-Ende auf API 35 und 36 (`.github/workflows/lumo-runtime-apk.yml`),
Responsive-Matrix (dp): 320×720, 360×800, 412×915, 600×960, 768×1024, 840×720, 1024×768, 1280×800, dazu Ausrichtung, Safe Areas, Fold-Scharnier.
Der Ergebnis-Abgleich im Host-Beleg erlaubt nur Rundung der zwei Zeitfelder (< 1e-9 s); alle anderen Felder bleiben exakt. APK bauen mit
`scripts/build_unified_apk.sh` und `config/godot-source.json`, Version erhöhen, Beleg: Flutter-SHA, Godot-SHA, Version, Paket, Signatur,
APK-SHA-256, PCK, Testergebnisse, Actions-Lauf, Artefakt-Link.

## 4. Offene Entscheidungen (Heinz fragen, nicht selbst entscheiden)

- Spracherkennung (`speech_to_text`) ohne `onDevice`: je nach Gerät geht Audio an den Erkenner-Anbieter.
- Elternbereich bleibt PIN-frei (bewusste Vorgabe seit 3. Oktober)? Online-KI und Online-Bilder sind jetzt nur mit dem Elternschalter
  „Lumo-KI-Server erlauben“ möglich.
- „Werkstatt-Mathe“ (Aufgaben aus den eigenen Kart-Werten) widerspricht dem Kartdesignziel „kein Lernen im Kart“.
- Name „Knobel-Test“ („Rätsel wie im IQ-Test“) statt „IQ-Test“; kein normierter IQ-Wert ohne Normstichprobe.
- Alleinstellungsmerkmal: Favorit „Lumo macht einen Fehler“ (Bericht Abschnitt 5).

## 5. Bekannte Fallen

- Eine Probe mit `LUMO_QA_DIR` (z. B. `kart_modal_backdrop_regression`) scheitert ohne diese Variable an ihrer ersten Assertion.
- `kart_vehicle_regression` druckt kein „PASS“, sondern „[KartVehicle] Geometry/colours, … passed“.
- Das Nutzungslimit kann parallele Unter-Agenten abbrechen (am 9. Oktober vier von sechs). Große Parallel-Läufe vermeiden, Zwischenstände sichern.
- Kein Neustart eines Android-Jobs über die API mit den Rechten dieser Sitzung (HTTP 403); ein Neulauf entsteht nur durch Push.
- Die Ablenker des Knobel-Tests sind bauartbedingt erratbar (Bericht F1): Eine hohe Trefferquote beweist dort noch keine Fähigkeit.

## 6. Berichtsformat nach jedem Meilenstein

IMPLEMENTIERT / BEWIESEN / VERBESSERT / NOCH OFFEN / GITHUB (Zweige, SHAs, PRs) / APK (Version, SHA-256, Link). Tests mit Ergebnis,
auch die roten. Nichts als erledigt melden, was nicht geprüft ist.
