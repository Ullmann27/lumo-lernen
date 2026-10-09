# Lumo Kart – Arbeitsbericht zum AAA-Produktionsauftrag (9. Oktober 2026)

Integrationsinstanz: Claude (Branch `claude/continue-previous-chat-KtY7p` in App und Godot).
Status: **VISUAL_GAP – NOT ACCEPTED**. Kein Merge nach `main`, kein Release.

## 1. Bestandsaufnahme (Stand 9. Oktober 2026, 12:15 UTC)

`main` ist unverändert: App `90c239898c2f`, Godot `ee4d932e59cf`.

### App (`Ullmann27/lumo-lernen`)

| PR | Zweig → Basis | Kopf | Inhalt | Prüfstand |
|---|---|---|---|---|
| #223 | `codex/lumo-action-android-qa` → main | `0a4f988` | APK 1909 (Quelle `aa65192`, Godot `a377b9e`), Android-Bildleser, screencap-Wiederholung | APK 1909 gebaut, SHA-256 `b58e0553…`; Kart API 36 PASS (Run 37893374564), API 35 PASS (Run 37896765244) |
| #225 | `codex/lumo-apk-1910` → #223 | `f38bb1a` | Pin Godot `75e563e` (#35), Version 1910 | Build-Run 37914387612 FAIL (Quellhash-Abweichung in der nativen Phase) |
| #226 | `codex/lumo-game-entry-polish` → #225 | `c9a8231` | Spielstart-Overlay mit Spielbildern, ehrliche Ladeanzeige | nur Flutter-Prüfung |
| #227 | `codex/lumo-claude-game-entry` → Claude | `bc63170` | dasselbe Overlay auf Claudes 1908, Pin `f9d2b90`, Version 1911 (gemergt `5a97a5d`) | Run 37921146749: Build PASS, Kart API 36 PASS, **Kart API 35 FAIL** (`Host did not durably retain …` = Float-Vergleich) |
| #228 | `codex/lumo-host-finish-numeric` → #227 | `fc33aa4` | Zeitrundung in `require_event` (elapsed + bestLap), Version 1912 | gewählt und gemergt (`54f467e`), um ganzzahlige org.json-Zeiten erweitert (`6d2d1f0`); Unit-Tests grün |
| #229 | `codex/lumo-host-time-precision` → #227 | `280b242` | Alternative: nur `elapsedSeconds` | nur Unit-Tests |
| #224 | `codex/lumo-return-frame-recovery` → integrated-runtime | `2fea2da` | Rückkehr-Frames der Kreativspiele | nicht im Kart-Pfad |

Claude-Strang vorher: `b570866` (APK 1908 aus `68ab206`, Pin `9a3dcbd`; Kart API 36 PASS, API 35 FAIL durch denselben Float-Vergleich).

### Godot (`Ullmann27/lumo-godot`)

| PR | Zweig → Basis | Kopf | Inhalt |
|---|---|---|---|
| #32 | `codex/lumo-action-workshop` → main | `8542c0b` | Sonnenhafen-Aquarium mit 6 Hütchen, gemeinsamer Antrieb `kart_powertrain.gd`, Werkstatt-Prüfstand mit Prüflauf, Profilbudget; Grundlage APK 1909 (`a377b9e`) |
| #33 | `codex/lumo-modal-viewport-repair` → integrated-runtime | `9eb0979` | erste aktive Rennspeicherung, Pausenhintergrund (eng gefasste Fassung von #35) |
| #34 | `codex/lumo-cup-finish-regression` → #33 | `f5647f4` | Cup-Test erlaubt Ausrollen nach Ziel (in #35 enthalten) |
| #35 | `codex/lumo-1909-snapshot-backdrop` → #32 | `75e563e` | erste aktive Sekunde speichern, Fold-Pausenhintergrund über den ganzen Bildschirm |
| #36 | `codex/lumo-game-entry-brand` → #35 | `e9ac48b` | Boot-Bild je Spiel, blaue Nunito-Kopfzeile, unbestimmte Ladeanzeige |
| #37 | `codex/lumo-claude-game-entry` → Claude | `f9d2b90` | dieselben Boot-Dateien wie #36 auf Claudes `240bf6a` |

Claude-Strang vorher: `240bf6a` (Action-Parcours auf 11 Strecken `3f953e1/a2dc352/11f8248`, Prüfstand-Formeln `5e1aae8`, Himmel-Wiederverwendung gegen Texturlecks `9a3dcbd`).
Der Codex-Strang #32–#36 zweigt bei `99cdb77` ab, also **vor** diesen sieben Claude-Commits.

## 2. Integrationsmatrix

| Funktion | Neueste funktionierende Fassung | Geprüft | Nur lokal/CI, nicht Android | Überschneidung / Alternative | Verlust bei älterem Zweig |
|---|---|---|---|---|---|
| 14 Karts, Werte, Tuning | beide Stränge (gemeinsam ab `99cdb77`) | Flotten-/Werkstatt-Tests, APK 1909 Android | Fahrgefühl je Kart | – | – |
| Action-Parcours (Turbo-Feld, Slalom, Schanze, Tauchtunnel, offene Kante) auf 11 Strecken | Claude `3f953e1…11f8248` | `kart_action_course_regression` lokal und in CI (1908) | Android-Fahrt über die Elemente | Codex legte eine **andere** Datei gleichen Namens an (Aquarium) | Codex-Strang: alles weg |
| Sonnenhafen-Aquarium + 6 Hütchen | Codex `a377b9e` | `kart_action_workshop_regression`, Android 1909 | – | gleicher Dateiname wie Claudes Parcours | Claude-Strang: alles weg |
| Prüfstand | Codex (Panel + Prüflauf) und Claude (Zeile + Formeln) | beide Tests | – | **doppelt** in der Werkstatt | – |
| Himmel-Wiederverwendung (keine Texturlecks) | Claude `9a3dcbd` | strenger Lauf 0 Lecks | – | – | Codex-Strang: Lecks zurück |
| Erste aktive Rennspeicherung, Fold-Pausenhintergrund | Codex `75e563e` | 41/11/8 Prüfungen + 40 GL-Prüfungen (CI) | Android | #33/#34 eng gefasste Vorläufer | Claude-Strang: fehlt |
| Spielstart-Branding Godot (Boot-Bild, Kopfzeile) | #36 = #37 (inhaltsgleich) | `kart_entry_artwork_regression` | Android-Bildschirmfolge | #36/#37 Alternativen | – |
| Spielstart-Overlay Flutter | #226 = #227 (inhaltsgleich) | Flutter-Test, Build 1911 | Android-Sichtprüfung | Alternativen | – |
| Android-Bildleser, screencap-Wiederholung | Codex #223 | 590 Werkzeugtests, Android 1909 | – | – | Claude-Strang: fehlt |
| Zeitrundung in der Host-ACK-Prüfung | #228 (beide Zeitfelder) | Unit-Tests; Fehler bewiesen in 1908 und 1911 | Android-Lauf mit Fix | #228/#229 Alternativen | ohne Fix: API 35 fälschlich rot |

### Entscheidungen

1. **Godot**: `f9d2b90` (#37) vorgespult, dann `e9ac48b` (#32/#35/#36) zusammengeführt. Codex' Aquarium heißt jetzt
   `kart_harbor_aquarium.gd` (eigene UID), Claudes Parcours bleibt `kart_action_course.gd`; beide laufen.
   Fahrformel aus `kart_powertrain.gd`, Tauch-Faktor des Parcours bleibt. Der Prüfstand ist einer: Codex' Panel mit
   Prüflauf; Claudes Kennwerte (`KartTuning.performance_for`) rechnen über denselben Antrieb und bleiben für Toast und
   den Fahrtest (`kart_fleet_stats_regression`) erhalten.
2. **App**: #227 und #228 zusammengeführt, dann #223/#225/#226. #228 statt #229, weil es beide Zeitfelder abdeckt;
   ergänzt um ganzzahlige Zeiten (Android-`org.json` schreibt `76.0` als `76`), die #228 sonst in etwa 2 % der Rennen
   fälschlich abgelehnt hätte. Die strengen Fälle aus #229 laufen als Regression mit.
3. **Version** `0.12.7+1913`: 1909 gebaut, 1910–1912 vergeben. APK 1909 bleibt der unveränderte Rückfallstand.

## 3. Prüfungen dieses Integrationsstands

Alle Läufe lokal mit dem strengen Läufer (jede Zeile `SCRIPT ERROR`, `Assertion failed`, `Parse Error`,
`Failed to load` oder `ERROR:` ist ein Fehlschlag, wie `tools/run_godot_probe.py` in der CI), Mesa llvmpipe,
Xvfb, `gl_compatibility`, Godot 4.6.3.

**Godot `de91cc9` (Merge-Stand): 29 Proben bestanden.**
Action-Parcours, Aquarium/Werkstatt, Werkstatt, Flottenwerte, Spielmodi, Rundenfortsetzung (104), Boot-Artwork,
Physik, Hafen, Menüfluss, vollständiger Rennablauf, erste aktive Rennspeicherung (41/11/8),
Profilbudget (24), Zeitformat (29), Pausenhintergrund Fold (40), Countdown-Pause, Modal-Touch, Pausenlayout,
Fold-Steuerung, Flotte (14 Designs), Lenkgriff, Armkontakt, Fahrzeug, Fahrzeugdetails, Video-Bildausschnitt,
Referenzaufnahme, Lenkgriff-Aufnahme.
Nicht lokal gelaufen (laufen in der CI): `kart_driven_capture` (über 600 s), die Showcase-Aufnahmen der Welten.
Beim ersten Lauf war `kart_modal_backdrop_regression` rot, weil mein Läufer `LUMO_QA_DIR` nicht setzte
(die Probe verlangt es). Mit der CI-Umgebung besteht sie; kein Produktfehler.

**Quellbindung der Android-Belege.** `native_lap_evidence_recovery.py` und `native_handoff_evidence_recovery.py`
binden `kart_island.gd` (jetzt `d71ee4d9…`) und die Proben. Beide wurden gegen echte Exporte des Merge-Stands
geprüft: 104 Rundenprüfungen, 29 Zeitformatfälle, 6 Bilder des vollständigen Ablaufs, 10 Handoff-Fälle.

**App (Stand 1914).** `flutter pub get --enforce-lockfile` ok; `flutter analyze`: **No issues found** (vorher 131 Hinweise);
`flutter test`: **816 bestanden, 21 übersprungen, 0 fehlgeschlagen**; Python `tools/android_qa/tests`: 594 Tests (9 übersprungen),
`scripts/tests`: 36 Tests. Importgraph ab `main.dart`: 315 von 315 Dateien erreichbar. Reparaturen und Belege:
`docs/LERNAPP_PRUEFBERICHT_2026-10-09.md`.

**Nicht geprüft:** physisches Gerät, Bildrate, Fahrgefühl, Musik, Android-Lauf dieses Stands (folgt aus der CI).

## 4. Lumo und COMET gegen die Referenz

Status: **in Arbeit, nicht abgenommen** (VISUAL_GAP). Die Änderungen liegen noch nicht im Integrationszweig,
sondern uncommittet in einem eigenen Arbeitsbaum. Stand der Messung am gerenderten Kopf (Frontansicht, lange
Brennweite, Engine-Bild ohne Nachbearbeitung):

| Maß | Vorher | Nachher (Zwischenstand) |
|---|---|---|
| Augenbreite / Kopfbreite | 0,319 | 0,239 |
| Iris / Auge | 0,884 | 0,663 |
| Pupille / Iris | 0,667 | 0,556 |
| Augenabstand (Mitte–Mitte) / Kopfbreite | 0,464 | 0,444 |
| Nasenbreite / Kopfbreite | 0,223 | 0,156 |

Die Referenzwerte aus den Blättern 03 und 06 sind noch nicht belastbar ausgemessen; deshalb steht hier kein
Vergleich zur Vorlage. Die vorherigen Augen standen kugelig vor dem Kopf; die neue Iris liegt als Kappe auf dem
Augapfel.

## 5. Offene visuelle Abweichungen

Lumo: Gesichtsmaße gegen Referenz ausmessen, Fell und Anzugstoff (Materialien), Handschuhe, Schulterpolster,
Stiefel, Seitenansicht des Kopfes, Rückseite; Ansicht 8 (Verfolgerkamera) ist noch die alte Aufnahme.
COMET: Lack, Lichtkanten, Reifenprofil, Felgen, Fahrwerk, Heck – noch nicht begonnen.
Welten: Identität, Tiefenschichten, kurze Strecken (Zauberwald 377 m, Holo-City 443 m, Himmelsinseln 473 m).
Spielstart: Overlay und Boot-Bild sind integriert, Splash-Animation und Menü Phase D/E nicht abgenommen.

## 6. APK-Status

**APK 1913** (App `b04bee5`, Godot `de91cc9`; Run 37937263563, Artefakt `lumo-visual-apk-37937263563`, 11621664190):
- Datei `Lumo-Lernen-Neu.apk`, 203.837.110 Bytes, SHA-256 `bc6dfc93fd20e39fa01e088f35215066884bf59e649d4bde76428318e59b9fb1`.
- Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, Version 0.12.7 (1913), minSdk 24, targetSdk 36, ABIs arm64-v8a und x86_64,
  16-KiB-ausgerichtet. Signatur-SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` (gleich wie 1908).
- Eingebettetes PCK `c517a9ed5e38ad04a076830375c50cdec606a5f96fd744fdea85519ed668980e` (41.248.792 Bytes), Godot-Pin `de91cc9`.
- Im Bau grün: Flutter-Analyse, komplette Flutter-Suite, Python-Vorbereitungstests, 26 strenge native Spiel-/Render-Proben auf dem
  exakten Pin; Android 15: Bauwelt, Puzzle, Rhythmus, Schatzsuche; Android 16: komplettes Kart-Rennen.
- **Android 15 Kart: rot.** Das Rennen lief komplett durch (16 Checkpoints, Ergebnis, Größenwechsel, Offline-Neustart); beim Abholen des
  letzten Aufnahme-Segments meldete der Emulator `adb: error: failed to get feature set: device offline`. Das ist ein
  Testumgebungs-Aussetzer. Ein Neulauf ist mit den Rechten dieser Sitzung nicht möglich (HTTP 403). Abgesichert in `78adcad`.

**APK 1914** (App Version 0.12.7+1914, gleicher Godot-Pin): enthält die Reparaturen des Lernapp-Berichts und das abgesicherte Abholen.
Der Lauf entsteht aus dem nächsten Push; sein Ergebnis steht in den Actions und wird hier ergänzt.

APK 1909 bleibt unverändert der geprüfte Rückfallstand. **Technisch fertig** und **visuell abgenommen** sind getrennt: Letzteres ist
ausdrücklich nicht der Fall (VISUAL_GAP, siehe Abschnitt 5 und `docs/wip/2026-10-09-lumo-gesicht/` im Godot-Repo).
