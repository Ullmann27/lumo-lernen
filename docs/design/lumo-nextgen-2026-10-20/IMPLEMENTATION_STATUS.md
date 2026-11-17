# Lumo Lernen Next Gen – tatsächlicher Code-Stand (20.10.2026)

Draft-PR: https://github.com/Ullmann27/lumo-lernen/pull/392
Quelle: PR #390 (HEAD cdb58c7128c2ec1bb15789f938449b2afb5628b8), bereits gestapelt auf der Premium-UX aus PR #389. Diese neue Designrunde schreibt main nicht um.

Erste echte Flutter-Änderung: lib/widgets/design/lumo_design_system.dart. LumoColorTile zeigt nun tiefblaue Glasverläufe statt weißpastellfarbener Kachelflächen, cyanfarbene Symbolkanten und hellen Text. InkWell-Tap, bestehende onTap-Funktion, Layout/semantische Labels und die Lumo-Fuchsfigur bleiben unverändert.

Neue Regressionstests: test/nextgen_premium_tiles_test.dart für echte Kartenaktionen und kompakte Smartphone-Breite.

Bisher keine automatische Bestätigung für APK, Screenshot oder Widgettest. CI wurde bei der Bearbeitung gestartet; Status nach Prüfungen aktualisieren.

Nächste Schritte für Astra/Codex:
1. Erst CI-Ergebnisse von PR #392 lesen und fehlerhafte Tests beheben.
2. Flutter Home (Lernen/Spielen) auf echtem 360–430dp Android und Fold rendern und mit neuen Lumo-Originalbildern vergleichen.
3. Mathe-Aufgabenkarten und Jahreszeitenkarten auf die gemeinsam aktualisierten Tokens setzen; Lernlogik und zweiter Versuch aus PR #390 bleiben unverändert.
4. Story-/Quizshow-/Voice-Ansichten nach denselben Glas-/Cyan-/Gold-Regeln veredeln.
5. Nur versionierte Commits, Screenshots und Testbefunde verwenden. main bleibt unverändert.