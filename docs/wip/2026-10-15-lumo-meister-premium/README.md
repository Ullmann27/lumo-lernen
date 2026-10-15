# „Wer wird Lumo-Meister?“ – Premium-Bildschirm: Zwischenstand (15. Oktober 2026)

**Status: ZWISCHENSTAND, NICHT EINGEBAUT.** Auf Heinz' Anweisung unterbrochen (Weiterarbeit an
Astras Klassen-Navigation). Hier gesichert, damit nichts verloren geht.

## Inhalt
- `lumo_meister_premium_wip.patch` – Code (Textdateien): neuer Bildschirm
  `lib/features/quiz/quiz_show_content.dart` (Einstieg → Fragerunde → Rückmeldung → Ergebnis),
  `lib/features/quiz/meister/` (Assets-Pfade, Stil, Widgets), Test
  `test/design/lumo_meister_screen_test.dart`, Bildskript `tools/assets/build_lumo_meister_assets.py`,
  `pubspec.yaml` (Ordner `assets/lumo_meister/`). Passt auf `cc576b6e`.
  Einspielen: `git apply docs/wip/2026-10-15-lumo-meister-premium/lumo_meister_premium_wip.patch`,
  danach die Bilder erzeugen: `python3 tools/assets/build_lumo_meister_assets.py`.
- `assets_uebersicht.png` – die 21 transparenten PNGs (links Schachbrett = Transparenz).
  Lumo-Posen und Belohnungssymbole stammen aus den freigegebenen Originalen in
  `assets/lumo_design/`; Konfetti, Funken, Leuchten, Scheinwerfer, Emblem werden erzeugt.
- `zwischenstand_fold_innen_richtig.png` – echtes Flutter-Rendering (Testumgebung, Nunito geladen,
  Material-Symbolschrift noch NICHT geladen → Symbole als Quadrate).

## Offen, bevor es eingebaut werden darf
1. Lumo fehlt im Telefon-Rendering nach der ersten Antwort (Posenwechsel); Ursache klären.
2. Lumo (Arme offen) ragt auf dem Telefon über die Joker-Spalte → Breite begrenzen.
3. Telefon: Fragekarte + Antworten + Prüfen-Knopf passen nicht auf einen Bildschirm →
   Leiter neben Bühne **und** Fragekarte, Bühne niedriger.
4. Titel bricht als „Lumo-|Meister?“ → zwei Zeilen „Wer wird“ / „Lumo-Meister?“.
5. Querformat 915×412: Überlauf 47 px.
6. Joker-Beschriftung „Lumo-Tipp“ abgeschnitten.
7. Test: Material-Icons-Schrift laden; Erwartungen für doppelt gezeichneten Goldtitel
   (`findsWidgets`); Semantik-Prüfung der Antwortkarten (isButton) korrigieren.
8. Bereits behoben: verzögert erzeugter AnimationController (Absturz bei „Bewegung reduzieren“).
Spielregeln (`QuizShowEngine`) und Sternbuchung bleiben unverändert.
