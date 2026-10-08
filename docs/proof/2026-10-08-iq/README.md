# Lumo Knobel-Test (IQ-Test für Kinder) – Aufnahmen vom 8. Oktober 2026

Alle Bilder sind **echte Flutter-Renderings des Teststands** (Widget-Test-Renderer mit
Software-Rendering, geladene Schrift Nunito und echte Bild-Assets). Es sind **keine
Konzeptbilder** und nichts ist nachbearbeitet; die PNG-Dateien wurden nur verlustfrei
verkleinert. Kein Android-Gerät, kein Emulator, keine FPS-Messung.

Erzeugt mit `test/design/iq_capture_test.dart`:

```
LUMO_TOUR_DIR=<ordner> flutter test test/design/iq_capture_test.dart
```

Der Test spielt den echten Bildschirm `IqTestScreen` durch Antippen durch (Seed 41, 2. Klasse,
Kind „Mia“). Einige Rätsel (3, 6, 10, 13, 17, 20) werden absichtlich falsch beantwortet, damit
der Rückblick Lösungen zeigt. Vorher ist ein früheres Ergebnis (72 Denkpunkte, 1. Oktober)
gespeichert, damit „Letztes Mal“ und die Vergleichspfeile sichtbar sind. Diese Zahlen sind
Testdaten, keine Daten eines echten Kindes. Alle anderen Zahlen (Denkpunkte, Stufen, Sterne, XP)
werden aus dem Testlauf berechnet.

## Dateien

`phone_*` = Telefon 412 × 915, `fold_*` = Fold innen 690 × 829, `quer_*` = Telefon quer 915 × 412.

| Datei | Inhalt |
|---|---|
| `*_01_start.png` | Startseite: Lumo, Titel, sechs Bereiche, „24 Rätsel · ca. 10 Minuten · ohne Zeitdruck“, Elternhinweis, „Letztes Mal“ |
| `*_02_anleitung_matrix.png` | Anleitung vor dem ersten Bereich mit gezeichnetem Beispiel |
| `*_03_raetsel_matrix.png` | Muster-Matrix mit markierter Antwort (Vorschau im gesuchten Feld) |
| `*_03_raetsel_series.png` | Figurenfolge |
| `*_03_raetsel_oddone.png` | Was passt nicht? |
| `*_03_raetsel_rotation.png` | Drehen im Kopf (Bauteile mit Facetten) |
| `*_03_raetsel_numbers.png` | Zahlenrätsel (leuchtende Blasen) |
| `*_03_raetsel_memory.png` | Merk-Blitz: zwei Felder schon angetippt (nummeriert) |
| `*_04_ergebnis.png` | „Dein Denk-Profil“ auf Gerätegröße (Sechseck, Ehrentitel, Denkpunkte) |
| `*_04_ergebnis_komplett.png` | Dieselbe Seite in voller Länge (Stufen je Bereich, Pfeile, „Hier hilft Üben“, Belohnung, Elternhinweis) |
| `*_05_rueckblick_loesung.png` | Rückblick: gelöste Rätsel kurz, nicht gelöste mit gezeichneter Lösung und Regel |
| `*_06_tests_seite.png` | Tests-Seite in der echten App-Hülle mit der neuen Karte „Lumo Knobel-Test“ |
| `quer_*` | Querformat: Start, Rätsel, Ergebnis |

## Was die Aufnahmen belegen und was nicht

- Belegt: Aussehen und Layout auf diesen drei Größen, keine Überläufe (die Widget-Tests prüfen
  zusätzlich Fold quer, ein kleines Telefon und Schrift 1,3).
- Nicht belegt: Bewegung (die Aufnahmen laufen mit „Animationen reduzieren“), Ton, Geschwindigkeit
  auf einem echten Gerät.
