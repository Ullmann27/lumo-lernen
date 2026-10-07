# Lumo – Einstieg (für jede KI zuerst lesen)

**Aktueller Auftrag vom 7. Oktober 2026:** Zuerst `OPUS_NEXT.md` und den vollständigen
`docs/OPUS_ENTWICKLUNGSAUFTRAG.md` lesen. Die unten genannten alten Rollen, Branches
und Testzahlen sind historisch; für die Fortsetzung gilt die neue Übergabe.

Stand: 4. Oktober 2026. Aufgeräumt: toter Code, ungenutzte Assets, alte Berichte und
Einmal-Workflows sind entfernt (alles bleibt in der Git-Historie).

## Aktueller Auftrag

Die App bekommt das neue Design aus Heinz' Bildern.
1. `docs/DESIGN_ZIEL_2026-10-04.md`: verbindliche Vorgabe, Abnahmepunkte, Etappen, Animationen
2. `docs/DESIGN_ASSETS_2026-10-04.md`: alle Einzelbilder mit festen Dateinamen
3. `docs/design_targets/2026-10-04/`: die elf Zielbilder
4. `docs/LERNSTRUKTUR_LEBENDIG.md`: Lernpfad nach Anton-Prinzip und lebendige App
5. `docs/RESPONSIVE_DEVICE_MATRIX.md`: Handy, Fold, Tablet nach logischer Breite
6. `docs/DESIGN_ZIEL_KART_2026-10-04.md` + `docs/design_targets/2026-10-04/kart/`: Lumo Kart (Modus, Cups, Garage, Strecken)
7. Später: `docs/DENKTEST_KONZEPT.md` (Denk-/IQ-Abenteuer, noch nicht bauen)

Rollen: Copilot (GPT-6 Luna) baut die Bildschirme. Claude koordiniert, führt `flutter analyze`
und `flutter test` aus und prüft gegen die Bilder. Arbeitszweig `codex/lumo-unified-android-2026-10-03`,
Haupt-PR #156. Kein Merge nach `main` und kein Release ohne Heinz.

## Code-Landkarte

| Bereich | Datei |
|---|---|
| App-Start, Theme | `lib/main.dart`, `lib/app/app_theme.dart`, `lib/theme/` |
| Shell, Navigation, Bereichswahl | `lib/app/app_shell.dart` (`_buildContent`, `_MobileBottomNavigation`) |
| Zustand, Sterne, XP, Level | `lib/app/app_state.dart`, `lib/core/reward_wallet_repository.dart` |
| Neue Design-Bausteine | `lib/widgets/design/lumo_design_system.dart`, `lib/theme/lumo_visual_tokens.dart` |
| Fuchs-Bilder | `assets/lumo_design/fox/` |
| Start | `lib/features/home/home_content.dart` |
| Lernen (Klasse, Fächer) | `lib/features/teacher_mode/lumo_akademie_screen.dart` |
| Lernmodule (Plus, Minus, Farben …) | `lib/features/learning_modules/<modul>/` |
| Übungen / Aufgaben-Renderer | `lib/features/learning/learning_content.dart`, `lib/features/learning/renderers/` |
| Aufgaben-Erzeugung | `lib/core/school_exercise_generator.dart`, `math_task_templates.dart`, `german_task_templates.dart` |
| Lesen / Deutsch | `lib/features/reading/` |
| Spiele | `lib/features/games/games_content.dart`, Unterordner pro Spiel |
| Kart (3D, Godot) | Start über `lib/features/lumo3d/`, Spiel in `Ullmann27/lumo-godot` |
| Profil, Belohnungen | `lib/features/rewards/` (`ProfileScreen`) |
| Einstellungen | `lib/features/settings/settings_content.dart` |
| Stimme | `lib/core/lumo_voice.dart` |
| KI-Proxy | `lib/core/lumo_ai_proxy_client.dart`, Server `server/lumo-ai-proxy/` |

## Bauen und prüfen

- `flutter analyze` und `flutter test` (ca. 510 Tests) müssen grün sein.
- Gemeinsame APK: `bash scripts/build_unified_apk.sh` (Flutter + Godot), CI `.github/workflows/release-apk.yml`.
- Android-UI-Test im Emulator: `.github/workflows/android-integration-qa.yml`, Werkzeuge in `tools/android_qa/`
  (`python3 -m unittest discover -s tools/android_qa/tests`). Er sucht sichtbare Texte wie „Lernen“,
  „LUMO AKADEMIE“, „Plus bis 10“, „Aufgabe 1 / 30“. Bei Textänderungen dort mit anpassen.

## Weitere Berichte (nur bei Bedarf)

`docs/UNIFIED_ANDROID_2026-10-03.md` (Flutter+Godot-Paket), `docs/ANDROID_LIVE_UI_2026-10-04.md` und
`docs/ANDROID_APK_ABSCHLUSS_2026-10-04.md` (APK/QA-Stand), `docs/COPILOT_GRAFIK_2026-10-04.md`
(Kart-Grafik in Godot), `docs/PIN_FREI_2026-10-03.md`, `docs/WALLET_TRANSACTIONS_2026-10-03.md`,
`docs/GAMES_QA_2026-10-03.md`, `docs/LERNEN_KI_PRUEFUNG_2026-10-03.md`, `docs/ANDROID_LERNPRUEFPLAN_2026-10-03.md`.
