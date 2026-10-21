# SOL – Kristallkorrektur abgeschlossen und remote gesichert

Stand: 21.10.2026. Branch:
`sol/fix-answer-crystal-depth-20261021`.
Geprüfter Code-/Nachweis-Checkpoint, erfolgreich gepusht:
`f7e359cc4df29c4b113ab8206def03c95feb08aa`.
Die danach folgende reine Übergabe-Aktualisierung enthält keine UI-Änderung;
ihren SHA liefert `git rev-parse HEAD` auf diesem Remote-Branch.
Basis: `0eef84aa54f1ee4b180718e917bf8f1d529fe81c`, inklusive #399 und
sämtlicher gesicherter SOL-Änderungen. Main, SOL-Originalzweig, Version/Pins,
Godot und laufende Buildkonfigurationen wurden nicht verändert.

## Nachgewiesene Ursache

1. #399 / Quellstand der APK 0.12.82+1994 enthält bei Minus bis 10 noch
   `LumoLessonAnswerTap` + `AnimatedContainer`, keinen `LumoAnswerCrystal`.
   Die Kristall-Anbindung entstand erst in den neueren gesicherten SOL-Commits.
   Daher kann die unverändert installierte APK 1994 diese Änderungen nicht zeigen.
2. Im neuesten SOL-Stand lädt der echte Akademiepfad bereits vier Kristalle.
   Es liegt keine Überdeckung durch Button/Material vor: transparente native
   Buttons liegen über dem Painter, Facetten sind im zusammengesetzten Bild da.
3. `LumoLessonAnswerGrid` begrenzt hier die Kacheln auf 68–84 dp; der rote
   reale Akademie-Routentest maß 72 dp. Der Painter verwendet davon nur 79 %
   für den Körper. Gestreckte Geometrie und Facetten mit nur 5,5–13 %
   Deckkraft ergeben schmale, dunkle, fast flache blaue Formen.

## Korrektur – exakte Dateien

- `lib/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart`:
  vorhandenes `LumoCrystalAnswerGrid` statt kompakter Lesson-Kacheln, 108 dp
  je Antwort, mit vorhandenem Textskalierungs-/Einspaltenverhalten.
- `lib/widgets/design/lumo_answer_crystal.dart`: sichtbare untere Seitenfläche,
  kontrastreiche triangulierte Lichtfacetten, beleuchtete innere/äußere Kanten,
  lokaler Cyan-Schein und dezente Zahlenschatten. Keine neue Dauerschleife,
  kein Shader/Asset und keine Änderung der Bewertung/Touch-Handler.
- `test/design/minus_crystal_depth_regression_test.dart`: echter Pfad
  Akademie → erweiterte Lernübersicht → Klasse 1 → Mathe → Minus bis 10;
  vier neutrale Kristalle, Mindesthöhe, Hit-Tests, native Zahlensemantik und
  sichtbare Facettenpixel im zusammengesetzten Flutter-Render. Die unteren
  Antworten werden über den echten Scrollpfad vollständig sichtbar gemacht.

## Tatsächlich bestandene Prüfungen und Nachweise

Verzeichnis: `docs/handoffs/evidence/crystal-depth-2026-10-21/`.

- `regression-red.txt`: Test reproduziert vor dem Patch 72 statt mindestens
  100 dp Kristallhöhe. Kein absichtlich abgeschwächter Testvertrag.
- `regression-green.txt`: 12 bestandene Tests: neuer Routen-/Rastertest plus
  elf bestehende Modul-Fortschrittstests. Einschließlich erst falsch, dann
  richtig bei Minus, zweiter Versuch ohne Lösungshinweis, gespeicherte
  Sterne/XP, verzögerte/fehlerhafte Wallet-/Profilzugriffe, Navigation und
  Hintergrund-/Wiederaufnahmeverhalten. Keine Lernlogik geändert.
- `route-final.txt`: finaler Akademie-Routen-/Rastertest nochmals bestanden,
  inklusive finalem Screenshot ohne Debugbanner.
- `analyze.txt`: gezieltes `dart analyze` für die beiden Produktdateien und
  den neuen Test: `No issues found!`.
- Vorher: `before/minus-bis-10-phone-360x800.png`.
- Nachher: `after/minus-phone.png` (360 × 800, vollständige vier Körper und
  Podeste). Echter unretuschierter Flutter-Test-Runtime-/Skia-Render der
  Produktionswidgets nach echter Navigation; kein Mockup, kein Android-
  Gerätescreenshot. Vorher/Nachher können verschiedene echte Aufgaben zeigen.

Vergleich intern mit dem Kristall-Zielbild aus dem Chat: vier facettierte,
leuchtende Antwortkörper auf Podesten, gleiche neutrale Behandlung aller
Antworten. Die lokale ältere Referenz
`docs/design/2026-10-10-lumo-games/references/50608.png` zeigt dagegen noch
runde Glaskarten; sie darf nicht mit dem neueren Kristallbild verwechselt werden.
Keine vollständige Referenztreue oder gemessene Android-Performance behauptet.

## Übernahme / nächste konkrete Aufgabe

1. Diesen Branch bzw. seine zwei Produktdateien und den Regressionstest in
   die fortlaufende geprüfte SOL-Entwicklung übernehmen, ohne nach main zu mergen.
   Kein APK-Build/Release wurde in diesem gezielten Auftrag gestartet.
2. Für weitere interne Nachweise ohne Android-Build:
   `LUMO_CRYSTAL_CAPTURE_DIR=<Ausgabeordner> /workspace/flutter/bin/flutter test --no-pub test/design/minus_crystal_depth_regression_test.dart`.
   Der neue Test reproduziert den echten Navigationspfad.
3. Nächste sinnvolle Erweiterung: derselbe gezielte Geometrie-/Semantikcheck
   auf schmalem Fold-Cover mit großer Schrift; Android-Einbindung erst in
   einem später ausdrücklich wieder aufgenommenen Build-Arbeitsblock.
4. Die alte installierte APK 1994 bleibt unverändert. Für ihr sichtbares
   Update ist später ein aus diesem Code gebautes, geprüftes APK erforderlich.

Cloud-Checkpoint-Wächter lief während dieses Auftrags alle 120 Sekunden;
zusätzliche erfolgreiche `tools/lumo_autosave.py once`-Pushes vor Tests und
zum Abschluss. Der Remote-Branch ist die dauerhafte Übergabe; ein Cloud-
Prozess kann bei Sitzungsunterbrechung stoppen.

---

## Archiv: vorheriger breiter SOL-Arbeitsauftrag (nicht aktueller Abschluss)

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
