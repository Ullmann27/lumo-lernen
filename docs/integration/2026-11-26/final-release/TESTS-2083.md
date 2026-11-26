# 193 übersprungene Flutter-Tests in 2083

Der [GitHub-Lauf 45786210491](https://github.com/Ullmann27/lumo-lernen/actions/runs/45786210491) meldete 4.161 bestandene, einen fehlgeschlagenen und 193 übersprungene Tests. Die erweiterte Textausgabe gibt bei gleichzeitigen Tests den gerade sichtbaren Namen aus. Der lokale Wiederholungslauf unter derselben Belegung der Capture-Variablen ordnete alle 193 übersprungenen Fälle über den JSON-Reporter ihren tatsächlichen Testdateien und Namen zu.

Alle 193 Tests sind durch fehlende Zielvariablen für Bildschirmaufnahmen deaktiviert. Sie ersetzen keine Tests der installierten App. Ausstehende Sichtprüfungen bleiben insbesondere für überarbeitete Oberflächen, die Klassen 1–4 und Fold-/Tablet-Formate relevant.

| Testdatei | Fälle | Capture-Variable | Abnahme |
| --- | ---: | --- | --- |
| `test/design/app_tour_capture_test.dart` | 18 | `LUMO_TOUR_DIR` | Gesamte App-Oberfläche in Telefon, Fold und Tablet prüfen. Installierte Android-Oberfläche zusätzlich auf dem Gerät öffnen. |
| `test/design/denkprofil_knobel_before_after_capture_test.dart` | 6 | `LUMO_VISUAL_CAPTURE_DIR` | Knobelansicht und Aufgabentext bei geänderter Darstellung vergleichen. |
| `test/design/dorfwirtschaft_spielewelt_capture_test.dart` | 6 | `LUMO_VILLAGE_CAPTURES` | Einstieg zu Lumo World und Dorfkachel im Bildschirm prüfen. Native Missionen und Rückkehr separat ausführen. |
| `test/design/flutter_games_2013_capture_test.dart` | 10 | `LUMO_FLUTTER_GAMES_CAPTURE` | Spielekacheln und Flutter-Spiele prüfen. Vollständige Runden und Belohnung zusätzlich in der installierten App testen. |
| `test/design/guided_learning_runtime_capture_test.dart` | 6 | `LUMO_GUIDED_CAPTURE_DIR` | Hilfestufen und echte Aufgaben auf den vorgesehenen Displaygrößen prüfen. |
| `test/design/iq_capture_test.dart` | 5 | `LUMO_TOUR_DIR` | IQ-/Knobeloberflächen und erreichbare Optionen prüfen. |
| `test/design/learning_adventure_capture_test.dart` | 80 | `LUMO_LEARNING_CAPTURE_DIR` | Aufgaben der Klassen 1–4 an den verwendeten Formaten mit vollständigen Antwortflächen prüfen. |
| `test/design/lumo_companion_runtime_capture_test.dart` | 2 | `LUMO_COMPANION_CAPTURE_DIR` | Aktive Hilfe, alternative Erklärung und Übergang zurück zur Aufgabe dokumentieren. |
| `test/design/lumo_modernization_capture_test.dart` | 36 | `LUMO_CAPTURE_DIR` | Flutter-Ansichten je Format und Schreibtrainer im vorhandenen Stil prüfen. |
| `test/design/lumo_spatial_reading_capture_test.dart` | 3 | `LUMO_SPATIAL_CAPTURES` | Leseaufgabe und Navigation mit geöffnetem und geschlossenem Fold prüfen. |
| `test/design/memory_optik_capture_test.dart` | 5 | `LUMO_STREAM_E_CAPTURE` | Motive und Layout in Flutter prüfen. Native Eingabe und vollständige Runde separat belegen. |
| `test/design/nextgen_navigation_capture_test.dart` | 10 | `LUMO_NAVIGATION_CAPTURES` | Tabwechsel, Schnellzugriffe und Navigation optisch prüfen. |
| `test/design/teacher_demo_shots_test.dart` | 3 | `LUMO_SHOTS` | Lehrer- und Unterrichtsansichten mit lokalen Beispielen dokumentieren. |
| `test/fox_living/lumo_rig_stress_capture_test.dart` | 1 | `LUMO_RIG_STRESS` | Gesicht und Bewegung des Original-Lumo bei hoher Animationslast prüfen. |
| `test/tutoring/tutoring_flow_connection_test.dart` | 2 | `LUMO_TUTORING_CAPTURE_DIR` | Echte gespeicherte Antworten bis zur geöffneten Nachhilfehilfe verfolgen. |

## Konkrete Fälle

### app_tour_capture_test.dart

- Tour phone home
- Tour phone learn
- Tour phone games
- Tour phone tests
- Tour phone rewards
- Tour phone profile
- Tour fold home
- Tour fold learn
- Tour fold games
- Tour fold tests
- Tour fold rewards
- Tour fold profile
- Tour reference-phone home
- Tour reference-phone learn
- Tour reference-phone games
- Tour reference-phone tests
- Tour reference-phone rewards
- Tour reference-phone profile

### denkprofil_knobel_before_after_capture_test.dart

- Real Denkprofil before/after UI on phone-412x915
- Real Knobeltest before/after UI on phone-412x915
- Real Denkprofil before/after UI on fold-cover-344x882
- Real Knobeltest before/after UI on fold-cover-344x882
- Real Denkprofil before/after UI on fold-open-690x829
- Real Knobeltest before/after UI on fold-open-690x829

### dorfwirtschaft_spielewelt_capture_test.dart

- Actual games hub includes a direct village fold-cover (variant: TargetPlatform.android)
- Actual games hub includes a direct village phone (variant: TargetPlatform.android)
- Actual games hub includes a direct village fold-open (variant: TargetPlatform.android)
- Actual games hub includes a direct village fold-landscape (variant: TargetPlatform.android)
- Actual games hub includes a direct village fold-wide-min (variant: TargetPlatform.android)
- Actual games hub includes a direct village fold-open-large-text (variant: TargetPlatform.android)

### flutter_games_2013_capture_test.dart

- Memory overview phone
- Connect Four overview phone
- Quizshow overview phone
- Memory combo phone
- Connect Four win-glow phone
- Memory overview fold
- Connect Four overview fold
- Quizshow overview fold
- Memory combo fold
- Connect Four win-glow fold

### guided_learning_runtime_capture_test.dart

- actual bridge_ten example and controls: phone-360x800
- actual equal_groups example and controls: phone-360x800
- actual subtract_ten example and controls: phone-360x800
- actual bridge_ten example and controls: fold-target
- actual equal_groups example and controls: fold-target
- actual subtract_ten example and controls: fold-target

### iq_capture_test.dart

- Knobel-Test Aufnahmen Querformat
- Knobel-Test Aufnahmen phone
- Tests-Seite mit Knobel-Karte phone
- Knobel-Test Aufnahmen fold
- Tests-Seite mit Knobel-Karte fold

### learning_adventure_capture_test.dart

- Real module capture minus-bis-10 phone-360x800
- Real module capture minus-bis-10 landscape-640x360
- Real module capture minus-bis-10 wide-1280x720
- Real module capture minus-bis-10 fold-2176x1812-density-225
- Real module capture zahlen-bis-10 phone-360x800
- Real module capture zahlen-bis-10 landscape-640x360
- Real module capture zahlen-bis-10 wide-1280x720
- Real module capture zahlen-bis-10 fold-2176x1812-density-225
- Real module capture formen phone-360x800
- Real module capture formen landscape-640x360
- Real module capture formen wide-1280x720
- Real module capture formen fold-2176x1812-density-225
- Real module capture plus-bis-10-reference phone-360x800
- Real module capture plus-bis-10-reference landscape-640x360
- Real module capture plus-bis-10-reference wide-1280x720
- Real module capture plus-bis-10-reference fold-2176x1812-density-225
- Real module capture uhr phone-360x800
- Real module capture uhr landscape-640x360
- Real module capture uhr wide-1280x720
- Real module capture uhr fold-2176x1812-density-225
- Real module capture geld phone-360x800
- Real module capture geld landscape-640x360
- Real module capture geld wide-1280x720
- Real module capture geld fold-2176x1812-density-225
- Real module capture zahlen-bis-100 phone-360x800
- Real module capture zahlen-bis-100 landscape-640x360
- Real module capture zahlen-bis-100 wide-1280x720
- Real module capture zahlen-bis-100 fold-2176x1812-density-225
- Real module capture einmaleins phone-360x800
- Real module capture einmaleins landscape-640x360
- Real module capture einmaleins wide-1280x720
- Real module capture einmaleins fold-2176x1812-density-225
- Real module capture grosses-einmaleins phone-360x800
- Real module capture grosses-einmaleins landscape-640x360
- Real module capture grosses-einmaleins wide-1280x720
- Real module capture grosses-einmaleins fold-2176x1812-density-225
- Real module capture brueche phone-360x800
- Real module capture brueche landscape-640x360
- Real module capture brueche wide-1280x720
- Real module capture brueche fold-2176x1812-density-225
- Real module capture artikel phone-360x800
- Real module capture artikel landscape-640x360
- Real module capture artikel wide-1280x720
- Real module capture artikel fold-2176x1812-density-225
- Real module capture mehrzahl phone-360x800
- Real module capture mehrzahl landscape-640x360
- Real module capture mehrzahl wide-1280x720
- Real module capture mehrzahl fold-2176x1812-density-225
- Real module capture wortarten phone-360x800
- Real module capture wortarten landscape-640x360
- Real module capture wortarten wide-1280x720
- Real module capture wortarten fold-2176x1812-density-225
- Real module capture zeitformen phone-360x800
- Real module capture zeitformen landscape-640x360
- Real module capture zeitformen wide-1280x720
- Real module capture zeitformen fold-2176x1812-density-225
- Real module capture tiere phone-360x800
- Real module capture tiere landscape-640x360
- Real module capture tiere wide-1280x720
- Real module capture tiere fold-2176x1812-density-225
- Real module capture farben phone-360x800
- Real module capture farben landscape-640x360
- Real module capture farben wide-1280x720
- Real module capture farben fold-2176x1812-density-225
- Real module capture jahreszeiten phone-360x800
- Real module capture jahreszeiten landscape-640x360
- Real module capture jahreszeiten wide-1280x720
- Real module capture jahreszeiten fold-2176x1812-density-225
- Real module capture wetter phone-360x800
- Real module capture wetter landscape-640x360
- Real module capture wetter wide-1280x720
- Real module capture wetter fold-2176x1812-density-225
- Real module capture verkehr phone-360x800
- Real module capture verkehr landscape-640x360
- Real module capture verkehr wide-1280x720
- Real module capture verkehr fold-2176x1812-density-225
- Real module capture wort-diktat phone-360x800
- Real module capture wort-diktat landscape-640x360
- Real module capture wort-diktat wide-1280x720
- Real module capture wort-diktat fold-2176x1812-density-225

### lumo_companion_runtime_capture_test.dart

- real task, wrong answer and accepted alternative help: phone-360x800
- real task, wrong answer and accepted alternative help: fold-target

### lumo_modernization_capture_test.dart

- capture rechentricks fold-cover
- capture achievements fold-cover
- capture journal fold-cover
- capture lumo_welt fold-cover
- capture foto_lektion fold-cover
- capture reading_buddy fold-cover
- capture lumo_quest fold-cover
- capture lumo_magic fold-cover
- capture schreibcoach fold-cover
- capture schreibaufgabe fold-cover
- capture rechentricks phone
- capture achievements phone
- capture journal phone
- capture lumo_welt phone
- capture foto_lektion phone
- capture reading_buddy phone
- capture lumo_quest phone
- capture lumo_magic phone
- capture schreibcoach phone
- capture schreibaufgabe phone
- capture rechentricks fold-open
- capture achievements fold-open
- capture journal fold-open
- capture lumo_welt fold-open
- capture foto_lektion fold-open
- capture reading_buddy fold-open
- capture lumo_quest fold-open
- capture lumo_magic fold-open
- capture schreibcoach fold-open
- capture schreibaufgabe fold-open
- capture trainer B fold-cover
- capture trainer a fold-cover
- capture trainer B phone
- capture trainer a phone
- capture trainer B fold-open
- capture trainer a fold-open

### lumo_spatial_reading_capture_test.dart

- spatial reading and home fold-cover
- spatial reading and home phone
- spatial reading and home fold-open

### memory_optik_capture_test.dart

- Memory overview 4x4 on phone
- Memory overview leicht on phone (Lumo and table)
- Memory one card flipped on phone
- Memory matched pair on phone
- Memory overview 4x4 on fold-open

### nextgen_navigation_capture_test.dart

- navigation render home grade tools games phone
- navigation render math topics task phone
- navigation render german topics task phone
- navigation render english topics task phone
- navigation render science topics task phone
- navigation render home grade tools games fold
- navigation render math topics task fold
- navigation render german topics task fold
- navigation render english topics task fold
- navigation render science topics task fold

### teacher_demo_shots_test.dart

- Klassenübersicht
- Auswertung Demo-Kind 1
- Hausaufgaben mit Auswertung

### lumo_rig_stress_capture_test.dart

- exaggerated head, ears and tail stay connected

### tutoring_flow_connection_test.dart

- actual tutoring card capture: phone-360x800
- actual tutoring card capture: fold-target
