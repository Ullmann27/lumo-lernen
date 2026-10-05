# LUMO – Gap-Matrix und Stand

Stand: 5. Oktober 2026, Branch `claude/lumo-gesamt`. Status ehrlich: PASS / PARTIAL / FAIL / NOT EXECUTED.

## P0/P1 – Start, Datenverlust, Lernlogik
| Punkt | Status | Beleg |
|---|---|---|
| `flutter analyze` 0 Fehler, `flutter test` grün | PASS | Alle Tests grün (Stand f888b72: Gesamtlauf nach letztem Block siehe Bericht), 4 übersprungen |
| Aufgabenprotokoll geht bei Fehlern nicht verloren (kaputte Daten, Duplikate) | PASS | `test/domain/school_analysis_test.dart` |
| Fortschritt nach Neustart vorhanden | PASS (Wallet, Skills, Log) | Repos auf SharedPreferences |
| Android-APK baut | PASS (Stand 7d5c517, Debug-Signatur) | `dist/Lumo-Lernen-Neu.apk` |
| APK mit Phase 1–3 neu gebaut | NOT EXECUTED | |

## P2 – Hauptfunktionen
| Punkt | Status | Anmerkung |
|---|---|---|
| Kompetenz-Analyse (z. B. Zehnerübergang), Stärken/Schwächen, Empfehlung | PASS (Grundstufe) | `lib/domain/school/*` – Kompetenzen für Mathe aus der Aufgabe; Deutsch/Lesen nur auf Themenebene (PARTIAL) |
| Lernbericht für das Kind | PASS | Profil → „Mein Lernbericht“ |
| Lehrerbereich: Klasse, Kinder, Gruppen, Zuweisung, Einzelansicht, Empfehlung bestätigen/ändern/ignorieren | PASS lokal | `lib/features/teacher/*`, E2E-Test `teacher_flow_test.dart` |
| Kind sieht offene Lehrer-Aufgaben, Tipp startet das Thema | PASS | `StudentAssignmentsCard` auf Start |
| Anmeldung, Rollen serverseitig, Abgleich zwischen Geräten, Offline-Sync ohne Duplikate | BLOCKED_BACKEND | Kein Server vorhanden. Regeln liegen in `SchoolAccess`; Attempt-Ids sind synchronisierbar (eindeutig). |
| Schuladministrator, Eltern-Rolle | NOT EXECUTED | nur Enum |
| Tests (getrennt von Übungen) mit Themenwahl und Fehleranalyse | PARTIAL | bestehende Testbereiche nutzen noch nicht das Aufgabenprotokoll |
| Kompetenzprotokoll in Übungen, Modulen (Zeit, Aufgabe, Antwort) und Schreiben | PASS | Lesen (Leseflüssigkeit/Verständnis) noch NOT EXECUTED |
| Lumo spricht das Kind auf Start persönlich an (Hilfe/Lob aus der Analyse) | PASS | `LumoCoachCard`, Test `report_screen_test.dart` |
| Spielfreischaltung nach Lernfortschritt | PARTIAL | Domain steht (`GameUnlockService`), keine freigegebenen Schwellen |

## P3 – Visuelle Hauptabweichungen
| Screen | Status | Grund |
|---|---|---|
| Spielwelt Hub (Bild 01) | PARTIAL | Querformat-Hintergrund fehlt: **BLOCKED_ASSET** `bg_spielwelt_wide.png` |
| Memory (Bild 02) | PARTIAL / VISUAL_GAP | Lumo klein, flaches Brett, keine Welt (Wald, Wasserfälle, Schloss): **BLOCKED_ASSET** |
| Cards, Puzzle, Jump & Run, Rhythm, Schatzsuche, Bauwelt | NOT EXECUTED (Bilder 03–08 noch ohne Runtime) | |
| Lumo als echte 3D-Figur | **BLOCKED_3D_CHARACTER_ASSET** | kein GLB/Rig |
| Lumo Kart (Godot) | siehe Repo `lumo-godot`, nicht Teil dieses Stands | |

## Performance
Keine Messung auf einem Gerät (kein Fold7/Emulator in dieser Umgebung). Keine FPS-Behauptung.

## Nächste Blöcke
1. Kompetenz-Protokoll in Lesen/Schreiben/Tests/Module.
2. Spielwelt Phase 3 (Cards) nach Bild 03 – ohne Hintergrundlieferung nur teilweise abnehmbar.
3. APK neu bauen.
