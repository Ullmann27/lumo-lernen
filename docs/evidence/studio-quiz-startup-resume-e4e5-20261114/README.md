# Quiz-Start: beobachtete Pause tatsächlich fortsetzen

## Belegte Ursache und Grenze

Native `e4e5ce03e644a2f23b01a96f1d340a882a1798c4`, Host `bdd86f289a165ea5140a01607d78fcf4c31c98c6`, Run `43598637301`, Job `132458415469` scheiterten beim ersten Startgate. Das unveränderte Original `public-state.json` enthält Frage 1, eine gültige Runde, `paused=true`, `canSelect=false`, ACK 0 und keinen Fehler. Der Native-Bericht enthält keine Eingaben und keine Requests. Das letzte Lifecycle-Sample ist aktiv und frisch. Eine frühere Lücke während der Szeneninitialisierung ist damit vereinbar, aber ohne ursprüngliche Zeitreihe nicht als gemessene Ursache belegt.

## Enger Quellumfang

Geändert wird ausschließlich `_run()` in `scripts/tests/quiz_studio_runtime.gd`. Der Prüfer wartet zuerst auf einen gültigen aktuellen Zustand. Nur wenn dieser tatsächlich pausiert ist, erreicht er den sichtbaren Fortsetzen-Knopf mit dem bestehenden Wisch-/Touch-Helfer, sendet einen echten Resume-Intent und wartet auf eine höhere bestätigte Sequenz derselben Runde bei leerem Pending-Slot und aufgehobener Pause. Anschließend gilt unverändert `authority_ready && canSelect`.

Alle drei Startphasen teilen weiterhin ein einziges 15-Sekunden-Zeitfenster. Die externe 2500-ms-Lifecycle-Grenze, 300-Sekunden-Dartgrenze, 330-Sekunden-Paargrenze, 20 Fragen, Joker, Pause/Wiederaufnahme, Belohnung und Rückkehr bleiben unangetastet. Keine Produktionsszene, Spielregel, Save- oder Hostquelle wurde geändert. Alle anderen Top-Level-Funktionen der QA-Datei sind bytegleich zur veröffentlichten Basis.

## Tatsächlich ausgeführte enge Gegenprüfung

Der Replay liest die unveränderten 754 Originalbytes (SHA256 `3b8d23928226847217ea944e9544f2030c5d1f583fc76e2d4309780576b7dae2`). Ausschließlich der Testtoken wird auf den bereits vorhandenen Fixture-Launchtoken abgebildet. Nur der ausdrücklich deklarierte Fixture-Transport erzeugt nach einem tatsächlich eingegangenen Resume-Touch eine synthetische Bestätigung. Das ist kein Produktions-Dart-Ergebnis.

| Lauf | Tatsächliches Ergebnis |
|---|---|
| Unveränderter e4e5-Prüfer + Original-Pausenzustand | Exit 1 nach 16,440 s; ursprüngliches Active-Gate scheitert; null Eingaben |
| Gepatchter Prüfer + derselbe Zustand mit Fixture-ACK | Exit 0; 57 Prüfungen; genau ein Resume-Request, echte Wischfolge und Touch-Down/Up; Runde/Frage/Rewards erhalten |
| Bereits aktiver Kontrollzustand | Exit 0; 52 Prüfungen; null Eingaben/Requests |
| Pausenzustand ohne Bestätigung | Erwarteter Exit 1 nach 15,846 s; ACK bleibt 0, Pause bleibt bestehen |
| Vollständige bestehende Headless-UI-Fixture | Exit 0; 138 Prüfungen; alle ursprünglichen Bedingungen erhalten, eine zusätzliche Gültigkeitsprüfung |

Die gemessenen Prozessdauern enthalten Modell-/Engineinitialisierung und sind keine Darstellung des internen 15-Sekunden-Wartefensters und keine Geräteleistungswerte. Vorher-/Nachherhashes stimmen bei allen Läufen überein. Ein anfänglicher Replay-Assertionsfehler zählte die notwendigen Wischereignisse fälschlich als zusätzliche Resume-Tipps; dessen unveränderte Rohdateien und v1-Replay bleiben erhalten. Die abschließende identische Replayfassung wurde danach gegen Original und Patch ausgeführt.

## Weiter offen

Der korrigierte echte Dart↔Godot-Paarlauf muss erst in CI bestehen. Hier wurden keine neuen PNGs aufgenommen, keine Android-Eingaben ausgeführt und keine Wallet-/Releasefreigabe erteilt. Der ursprüngliche fehlgeschlagene Run bleibt unverändert dokumentiert.

## Wiederholbare lokale Eingrenzung

`evidence/tests/run_startup_replay.py` benötigt nur das bereits vorhandene Godot und eine isolierte, exakt gebundene Quiz-Runtime. Es schreibt ausschließlich in einen neuen Outputordner. `--source` wählt Original oder Patch, `--case` ist `paused_ack`, `active_no_touch` oder `paused_no_ack`; `--runtime` und `--output` sind ausdrücklich erforderlich. Die vollständigen tatsächlichen Befehle, Zeiten und Exitcodes stehen in jedem `execution.json`.
