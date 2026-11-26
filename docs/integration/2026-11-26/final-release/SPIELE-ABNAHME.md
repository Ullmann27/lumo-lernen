# Spieleabnahme für den LUMO-Zwischenstand

Quellen der Inventur sind die echte Flutter-Spielewelt, ihre Zusatzmodi, die Godot-Szenenregistrierung und ihre native 3D-Spielewelt. Die Startregression drückt die 12 Flutter-Portale und prüft ihren Zielbildschirm beziehungsweise den konkreten Aufruf der Android-Schnittstelle. Dazu kommen 11 Kacheln im separat erreichbaren nativen Hub. Derselbe Spielweg zählt einmal, auch wenn mehrere Kacheln ihn öffnen.

| Einstieg | Ziel | Lokaler Nachweis | Offene Abnahme |
| --- | --- | --- | --- |
| Lumo World | Godot world | Flutter-Portal übergibt den richtigen Spielschlüssel | Vollständige World-Missionen und Persistenz je Profil mit aktueller APK in der World-Matrix |
| Logikspiele | Flutter-Sudoku-Insel, Wörterwerkstatt und Zahlenbrücken | Portal und sichtbarer Zielbildschirm geprüft | Runden jeder Variante auf der installierten APK |
| Memory | Flutter-Spiel, auf Wunsch eigener Godot-Tisch memory | App-Einstieg, echtes Paar, Pause, Speichern und Wiederaufnahme mit Profilwechsel. Nativer Boot lädt Tabelle und Sitzungsdaten. | Komplette Partie auf der installierten APK in beiden Darstellungen |
| Cards | Godot cards, vier Spiele Sternenstich, Sternenleiter, Quartett und Punktlandung | App-Portal und nativer Boot. Gespielte Sternenstich-Runden mit Sieg und Niederlage sowie Punktlandung mit Sieg und Sternereignis. | Sämtliche Kartenrunden und deren Übergänge auf der installierten APK |
| Puzzle-Atelier | Godot puzzle | Flutter-Portal übergibt puzzle | Vollständige Puzzle-Runde, Speicherstand und Rückkehr auf der installierten APK |
| Jump & Run | Godot run | Flutter-Portal übergibt run | Hauptstrecken, Checkpoints, Ziel und Belohnung auf der installierten APK |
| Rhythm Party | Godot rhythm | Flutter-Portal übergibt rhythm | Runde mit Ton und sichtbarem Timing auf der installierten APK |
| Schach | Godot chess | Flutter-Portal und Tagesmissionssperre. Lokal eine vollständige Gewinnpartie mit 67 Halbzügen und Sternereignis beobachtet. | Geführter Lernweg, alle Stufen und vollständige Partie auf der installierten APK |
| Sternenpost | Godot skypost | Flutter-Portal übergibt skypost | Abflug, vollständiger Lieferauftrag, Rückkehr und einmal verbuchte Sterne auf der installierten APK |
| Lumo Kart | Godot kart | Flutter-Portal übergibt kart. Fahr- und Grafiknachweise in der Kart-Matrix. | Spielstarts, Rennen und Garage auf der installierten APK |
| Vier gewinnt | Flutter-Spiel, auf Wunsch Godot-Tisch connect_four | Vollständige lokal getippte Partie und Neu starten. Optionaler Nativeinstieg kehrt zum pausierten Flutter-Spiel zurück. Godot-Boot lädt Tisch und Autorität. | Vollständige Runde und Android-Activity-Rückkehr auf der installierten APK |
| Quizshow und Lernstufe 50 | Flutter Lumo-Meister, auf Wunsch Godot-Studio quiz | App-Portal. Lokaler Bühnenstart, Antwort, Rückkehr und Wiederaufnahme. Nativer Boot lädt Bühnenressourcen und Sitzungsdaten. | Vollständige 20-Fragen-Runde, Joker, Belohnung und Wiederaufnahme auf der installierten APK |
| Zusätzliche Spielmodi | Flutter-Würfelrennen, Sternenpfad, Flame-Abenteuer, Lernspielkarte sowie Godot jump | Würfelrennen im Flutter-Widget vom Start bis Ergebnis mit Speicherung, Pause und Neu starten | Sternenpfad, Flame, Wolkeninseln und jede Lernspielart über dieselbe echte Oberfläche |
| Native 3D-Spielewelt | Kart, Dorf, Wolkeninseln, Lumo Lauf, Sternenpost, Puzzle, Schatzsuche, World, Rhythm, Bauwelt, Sternenjagd | Sternenjagd über drei Wellen mit Pause, Zurück-Geste, Neustart und persistenter Bestzeit. Sternenjagd führt absichtlich keine Lernsternbuchung aus. | Hub-Kacheln und Rückkehr aller 11 Ziele auf der installierten APK |

Die Flutter-Routen-/Spieletests ergaben **22/22**, die Launcher- und Rückkehrtests **25/25**. Der native Table-Boot ergab **26/26** und die vollständige lokale Sternenjagd **22/22**. Die Kartensieg-, Kartenniederlage- und Schachrunden oben sind beobachtete Endzustände aus den längeren Native-Suites. Das Gesamtresultat dieser beiden Suites bleibt offen, bis sie vollständig durchgelaufen sind.

Eine abgebrochene Android-Activity darf keinen normalen Zielwechsel melden. Die Android-Schnittstelle liefert bei fehlendem, ungültigem oder abgebrochenem Rückgabeziel keinen Erfolg an Flutter. Bei einem bestätigten Ziel bleiben Quittung, Sternbuchung und Prozessfreigabe in der bisherigen Reihenfolge. Flutter prüft die expliziten Ziele. Sechs Python-Vertragsprüfungen und die Flutter-Rückkehrprüfung sind lokal grün. Der Betrieb auf Android bleibt in diesem Bericht offen.

Im 2084-Quellpfad fehlen die Bildkacheln von Sternenpost, Sternenjagd und Dorf & Wirtschaft im **nativen** Hub. Alle drei Ziele sind registriert. Echte Godot-Aufnahmen sind für die Runde nach 2084 vorbereitet. Die gleichnamigen Spieleinträge der Flutter-Spielwelt folgen ihrem eigenen Coverkatalog.
