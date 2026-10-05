# LUMO – Gap-Matrix und Stand

Stand: 5. Oktober 2026, Branch `claude/lumo-gesamt`. Status: PASS / PARTIAL / FAIL / NOT EXECUTED.

## P0/P1 – Start, Datenverlust, Lernlogik
| Punkt | Status | Beleg |
|---|---|---|
| `flutter analyze` 0 Fehler, `flutter test` | PASS | 86c5a33: 613 PASS, 0 FAIL, 4 SKIP |
| Aufgabenprotokoll: Speicherfehler gehen nicht verloren (Warteschlange, erneuter Versuch, Fehlerprotokoll ohne Kinderdaten) | PASS | `test/domain/learning_analysis_extended_test.dart` |
| Fortschritt nach Neustart vorhanden | PASS | Repos auf SharedPreferences, Tests mit Neuladen |
| Android-APK aus aktuellem Head | PASS (Testbuild, Debug-Signatur) | siehe unten |
| Release-Signatur | BLOCKED_RELEASE_SIGNING | Upload-Keystore + key.properties fehlen |

## P2 – Hauptfunktionen
| Punkt | Status | Anmerkung |
|---|---|---|
| Kompetenzprotokoll: Übungen, Module, Schreiben, Lesen (Sätze vorlesen, Lese-Buddy) | PASS | Lesen: Satz, Genauigkeit, Zeit, nur das schwierige Wort; undeutliche Aufnahmen zählen nicht |
| Lernbericht pro Kompetenz: Versuche, Quote, Stufe, Trend, Ø-Zeit, zuletzt, Fehlermuster, Lesetempo, Empfehlung | PASS | `lib/domain/school/*`, Profil → Mein Lernbericht |
| Fehlermuster (z. B. Zehner beim Übergang vergessen) | PASS (Mathe), PARTIAL (Deutsch) | `ErrorPatternDetector` |
| Lumo spricht das Kind auf Start an, Knopf führt ins Thema | PASS | `LumoCoachCard` |
| Lehrerbereich: Klassen, Kinder, Gruppen/Untergruppen, weitere Lehrkraft, Zuweisung, Einzelansicht, Empfehlung bestätigen/ändern/ignorieren | PASS lokal | E2E `test/features/teacher_flow_test.dart` |
| Kind sieht „Von deiner Lehrerin“, Tipp startet Thema, Lehrer sieht Ergebnis | PASS lokal | gleicher E2E-Test |
| Anmeldung, serverseitige Rechte, Mehrgeräte-Sync | BLOCKED_BACKEND | Regeln in `SchoolAccess`; Attempt-Ids eindeutig für späteren Sync |
| Domain-Repository-Trennung für spätere Remote-Sync | PARTIAL | Repos kapseln Speicher; Remote-Schnittstelle noch nicht definiert |
| Tests (Prüfungsbereich) mit Kompetenzprotokoll | PARTIAL | nutzt Übungsweg; eigene Testauswertung noch nicht |
| Spielfreischaltung nach Lernfortschritt | PARTIAL | `GameUnlockService`, keine freigegebenen Schwellen |

## P3 – Visuelle Hauptabweichungen
| Screen | Status | Grund |
|---|---|---|
| Spielwelt-Hub (Bild 01) | VISUAL_GAP | Querformat-Hintergrund: BLOCKED_ASSET `bg_spielwelt_wide.png` (#177) |
| Memory (Bild 02) | VISUAL_GAP | Komposition näher (großer Lumo, schwebende Karten, Steinplatte); Welt/Props/Tierkarten: BLOCKED_ASSET (#177) |
| Lumo Cards (Bild 03) | VISUAL_GAP | Nachtwelt, runder Steintisch, Lumo mit Karte, Tierfreunde; Kartenbilder tragen noch englische Aufschriften („WILD“), Kopfzeile alt |
| Pausenfenster aller Brettspiele | PASS | gemeinsames `LumoPausePanel` |
| Puzzle, Jump & Run, Rhythm, Schatzsuche, Bauwelt | NOT EXECUTED | |
| Lumo als echte 3D-Figur | BLOCKED_3D_CHARACTER_ASSET | kein GLB/Rig |
| Kart Zieleinlauf (Heinz-Referenzen 2026-10-05) | PARTIAL | Godot: Zielfahrt-Kamera, Ausrollen, Platz-Reaktion, Ergebnis mit Zeit/bester Runde; siehe lumo-godot |

## Performance
Keine Messung auf einem Gerät (kein Fold7/Emulator in dieser Umgebung). Keine FPS-Behauptung.
