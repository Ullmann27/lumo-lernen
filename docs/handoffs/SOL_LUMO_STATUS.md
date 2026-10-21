# Aktueller gezielter Auftrag: Kristalltiefe – 21.10.2026

Branch: `sol/fix-answer-crystal-depth-20261021`.
Basis: remote bestätigter SOL-Checkpoint
`0eef84aa54f1ee4b180718e917bf8f1d529fe81c` (inklusive #399).
Originalzweige und Godot werden für diesen Auftrag nicht verändert.

Diagnose gesichert: #399 / APK 1994 baut in
`lib/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart`
noch `LumoLessonAnswerTap` + `AnimatedContainer`, keinen Kristall.
Der neuere SOL-Branch enthält die Anbindung bereits. Dessen echter Flutter-
Render zeigt die Facetten unverdeckt; Grid-Kacheln nur ca. 68 dp hoch,
Kristallkörper zusätzlich auf 79 % reduziert, dunkle Facetten mit 5,5–13 %
Deckkraft: sehr flach und wenig Materialkontrast. Keine opaque Überdeckung
im OutlinedButton; dessen Hintergrund ist explizit transparent.

Vorher: `docs/handoffs/evidence/crystal-depth-2026-10-21/before/minus-bis-10-phone-360x800.png`.
Test: `test/design/minus_crystal_depth_regression_test.dart` nutzt den echten
Akademiepfad → Klasse 1 → Mathe → Minus bis 10 und prüft Geometrie,
Hit-Test, Semantik und tatsächlich zusammengesetzte Facettenpixel.
Korrektur und grüner Test stehen beim Diagnose-Checkpoint noch aus.
Nächster Schritt: Kachelraum für Körper/Podest und sichtbare Facetten korrigieren;
gezielte Minus-Speicher-/Zwei-Versuche-Tests, echter Flutter-Render, Remote-Push.
Keine vollständigen Builds und keine neue APK für diesen gezielten Auftrag.

---

# SOL Lumo – laufender, remote gesicherter Stand

Stand: 21.10.2026. Entwicklungsbranch in beiden Repositories:
`sol/lumo-runtime-crystals-kart-20261021`.

## Ausgangspunkt und Sicherung

Flutter #399: `1d5633c1c160a0b1a3cc7d259fea86de93b1b243`.
Godot #113 / Flutter-Pin: `928fed3c7f0b39357e0f06463ce13c8d5677d6e1`.
Version der Basis: 0.12.82+1994. Beide neuen Remote-Branches sind angelegt.
Der gesamte ursprüngliche Home-/Kristall-/Werkstatt-Stand ist Vorfahr von #399;
keine manuelle Rückübertragung erforderlich. Letzter vorhandener Checkpoint
beim Schreiben dieses Berichts: `db8e5eff3ae687d72b7461847958a065f342dd2e`.
120-Sekunden-Watcher je Repo in verwalteten laufenden Exec-Sessions.

## Erreicht: Ursache des Android-Abbruchs behoben, lokale Regression grün

Der 1994-Tourlauf startete den echten Grand Prix (`cup`), danach verlangte
`race_running` weiterhin den alten Standard `race`. Godots Laufzeit und der
bestehende Produktions-Hosttest erwarten beim Premium-START korrekt `cup`.
Quellnachweis: Actions-Lauf `39581898675`, Job `119169270251`, Schritt
`race-running`: `Saved race belongs to cup/sonnenhafen, not race/sonnenhafen`.

Die Tour bindet jetzt Marker, Save-Lesen, laufende Uhr, GAS-Bewegung und Pause
an Modus/Strecke des gestarteten UI-Pfads (Premium Grand Prix oder Legacy-Einzelrennen).
Ein anderer Modus, andere Strecke oder andere Renn-ID schlägt weiterhin fehl.
Grenzen 8 m / 2,5 s und der unabhängige Bildvergleich bleiben unverändert.

Neu bestanden: 15 Renn-/Bild-/Speicher-Nachweistests und 6 Tour-/APK-Identitätstests.
Negativtests zeigen vor der Korrektur den fehlenden Modusvertrag. Ein neuer
vollständiger Android-Emulatorlauf steht noch aus; bisher keine neue APK freigegeben.

Geändert: `.github/probes/modernization_android_tour.py`,
`tools/android_qa/kart_tour_evidence.py` und die beiden zugehörigen Testdateien.
Protokolle: `docs/handoffs/evidence/sol-2026-10-21/`.

## Nächste konkrete Arbeit

1. Kristalle in echten normalen Akademie-/Mathe-Routen prüfen und weitere
   vorhandene Zahlenantworten gezielt anbinden, ohne Bewertung/Schreibschutz zu ändern.
2. Alle fünf Godot-Garagenschritte durch echte Control-Eingaben testen und
   vereinheitlichen, insbesondere Rückweg zum Premium-Menü und Einstellungen.
3. Godot-Regression, Runtime-Render auf Smartphone/Fold/Querformat, Flutter-
   Regression und Python-Suite; geprüften Godot-SHA pinnen, Version erhöhen.
4. Ein vollständiger Android-Build plus verpflichtende Tour. Release erst
   nach tatsächlichem Erfolg; alte Releases behalten. Keine 60-FPS-Behauptung.

Referenzen: `docs/design/2026-10-10-lumo-games/references/` und vorhandene
Original-Lumo-Assets. Keine neuen kostenpflichtigen Grafikdienste.
