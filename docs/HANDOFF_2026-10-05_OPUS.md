# Übergabe Opus → nächster Writer (Sonnet 5.5 / Copilot oder ChatGPT Pro)

Stand: 5. Oktober 2026. Nichts hier ist nach `main` gemergt; kein Release.

## Stand der Repos
| Repo / Branch | SHA | Inhalt |
|---|---|---|
| lumo-lernen `claude/lumo-gesamt` | 7d83e5f | Lernen + Lehrer + Spielwelt + Memory + Cards (Flutter) |
| lumo-lernen Test-APK | aus 86c5a33 | `dist/Lumo-Lernen-Neu.apk` (lokal), 168 741 620 B, SHA-256 9019796…7794b, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, 0.10.5 (280), arm64-v8a + x86_64, Debug-Signatur, Godot a369da2 |
| lumo-godot `claude/kart-finish-cine` | e5eecd7 | Zieleinlauf-Kamera, Lumo-Platzreaktion, Ergebnis mit bester Runde (Basis a369da2) |
| lumo-godot PR #13 | 6803426 | Fahrzeug-Geometrie-Fix (fremder Writer) – in e5eecd7 bewusst NICHT enthalten |
| lumo-godot PR #14/#15 | – | Streckenpakete (ChatGPT/Copilot), nicht angefasst |

Tests: Flutter 86c5a33 volle Suite 613 PASS / 0 FAIL / 4 SKIP, analyze 0 Fehler.
Godot e5eecd7: KartTests, KartRaceBridge, KartModes, HostBridge PASS (gezielt, nicht die ganze validate_project.sh nach dem Zurücknehmen des Fahrzeug-Fixes).
Geräte: kein Android-Gerät/Emulator gemessen → Fold/FPS NOT EXECUTED.

## Paket 1 (Godot-Writer): Kart integrieren
1. `claude/kart-finish-cine` auf PR #13 rebasen (Konflikt nur in `scripts/games/kart_vehicle.gd`: Opus fügt `drive_arm_right`, `cheer_arm`, `celebrate()` hinzu; #13 ändert `_paint_mesh`/`_star`). Danach `tools/validate_project.sh` komplett.
2. `scripts/games/kart_island.gd`: Touch-Steuerung (`controls`-HBox als Member speichern) während `finish_cine_left > 0` und im Ergebnis ausblenden; Ergebnis-Panel im Querformat rechts statt mittig (Referenz `docs/references/kart_2026-10-05/finish_place_*.jpg`).
3. Ergebnis-Knöpfe: „Weiter“ (primär), „Nochmal“, „Strecke wählen“ wie in der Referenz.
4. Eine Strecke (Himmelsinseln) nach `track_himmelsinseln.jpg` ausbauen: Nachtlicht, Mond, Wasserfälle, Schloss-Landmarke; bestehende Rampe/Abkürzung behalten. Beweis: `scripts/tests/kart_finish_capture.gd` (xvfb) + Vergleich.
5. Danach `config/godot-source.json` in lumo-lernen auf den neuen Godot-SHA setzen und APK neu bauen (`scripts/build_unified_apk.sh`).

## Paket 2 (Flutter/Android-Writer): Aufklappen Fold
Befund (nicht auf Gerät geprüft):
- `LumoGameActivity` (Prozess `:lumo_game`) hat `screenOrientation="portrait"` – das Kart ist ein Querformat-Spiel. Auf großen Displays (≥600 dp, Android 16) ignoriert das System Orientierungssperren → Letterboxing/Resize beim Aufklappen. Vorschlag: Sperre entfernen (`unspecified`/`fullUser`), Godot-Viewport-Stretch `canvas_items` + `expand` prüfen, `_update_safe_area` bei `size_changed` (existiert) testen.
- configChanges beider Activities enthalten screenSize/smallestScreenSize/screenLayout/density → kein Neustart erwartet; trotzdem mit Emulator „Pixel Fold“/„Galaxy Z Fold“-Profil prüfen: Menü, Rennen, Pause, Hintergrund → zurück.
- Datei: `scripts/prepare_embedded_games.py` (Zeile ~66), generiertes Manifest unter `android/` (gitignored).
Abnahme: Screenshots außen/innen je Zustand, kein Neustart (Result-ID gleich), keine verdeckten Buttons.

## Paket 3 (Flutter-Design-Lane): einheitliche Menüs + App-Icon
- Screen-Inventar und Status: siehe `docs/GAP_MATRIX.md`.
- Offen: Kopfzeile Lumo Cards (alte helle Glasleiste), Kartenbilder mit englischem „WILD“ (eigene Lumo-Karten nötig), Einstellungen/Elternbereich noch heller Standard-Stil, Lernen-Fachkarten.
- App-Icon: aktuelles Launcher-Icon NICHT geprüft. Aufgabe: adaptives Icon (Vordergrund Lumo-Kopf aus `assets/lumo_design/fox/`, Hintergrund Tiefblau), alle mipmap-Dichten + monochrome Variante, im echten Build auf Homescreen prüfen.
- Asset-Anfragen offen in lumo-lernen #177 (Spielwelt-Querformat, Memory-Welt, 12 Tierkarten, kanonische Lumo-Posen, Memory-Sounds).

## Ehrliche offene Punkte
VISUAL_GAP / NOT FINISHED: Spielwelt, Memory, Cards, Kart-Strecken.
BLOCKED_ASSET (#177), BLOCKED_3D_CHARACTER_ASSET (kein GLB-Lumo), BLOCKED_BACKEND (Lehrer nur lokal), BLOCKED_RELEASE_SIGNING.
NOT EXECUTED: Fold-Gerätetest, FPS-Messung, App-Icon-Prüfung.
