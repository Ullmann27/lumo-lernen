# Auftrag: Aufräumen und Anschließen (Sonnet 5.5)

Stand: 5. Oktober 2026. Auftraggeber: Heinz. Danach übernimmt Claude Opus 5.5 (maximale Stufe) für die schwierigen Teile.

## Rolle
Sonnet 5.5 räumt auf, sortiert, schlichtet, repariert und schließt unfertige Anschlüsse. Keine neuen großen Features, kein Redesign (das macht Opus danach).

## Vorher lesen
`CODEX_START.md`, `CLAUDE.md`, `docs/CHANGE_REVIEW_2026-10-04.md`, `docs/AGENT_LANES_2026-10-04.md`.

## Aufgaben
1. **Bestandsaufnahme zuerst:** offene PRs und Zweige (u. a. #156, #170, #172) sowie `lumo-godot` PR #4 vergleichen. Liste in `docs/` ablegen: was ist fertig, was halb, was doppelt.
2. **Godot-Pin angleichen:** Flutter-Stand gegen den aktuellen Kart-Kopf in `lumo-godot` prüfen (neu: Lernfragen im Rennen entfernt, Spielstand v4, `solved` bleibt 0, Himmelsinseln, Leitplanken, Drift). `embedded_game_service.dart` und Build-Skript abgleichen.
3. **Freischaltung:** Kart-Freischaltung durch App-Lernfortschritt dauerhaft und idempotent machen; Spiele-Freischaltung nicht nur aus Sternen ableiten. Offen aus der Prüfung: Schreibkonflikt bei `recordResult` (ohne die Mini-Game-Tests zu brechen), Fehlerrückmeldung bei Stimme in `lib/core/lumo_voice.dart`.
4. **Migration:** alte Speicherstände (Sterne, Wallet, Lernfortschritt, Kart v1–v4) laden ohne Verlust; Tests ergänzen.
5. **Aufräumen:** tote Dateien in `lib/` (jede Datei muss von `lib/main.dart` erreichbar sein), veraltete Docs zusammenführen, Analyzer-Hinweise (`flutter analyze`) abbauen.
6. **Lose Enden:** TODOs, halb verdrahtete Bildschirme, fehlende `pubspec.yaml`-Asset-Einträge, QA-Texte in `tools/android_qa/` bei Textänderungen.

## Regeln
- `flutter analyze` ohne Fehler, `flutter test` grün (zuletzt 507 bestanden, 4 übersprungen).
- Kleine Commits, eine Sache pro Commit. Kein Force-Push, kein Merge nach `main`, kein Release.
- Nur geprüfte Erfolge melden; Bericht auf Deutsch.

## Übergabe an Opus 5.5
Am Ende eine Liste in `docs/`: erledigt, bewusst offen, Risiken. Für Opus bleiben: Design nach den Zielbildern, Kart-Grafik, Denktest-Konzept, schwierige Fehlersuche.
