# LUMO Console Quality · Technische Bestandsaufnahme

Stand 26.11.2026. Der getrennte Android-Kandidat 0.15.3+2086 verwendet Flutter `83e169bfedd91f050080660b21ba63cd01518259` und Godot `0c36dbaa2e778dc982550989159bf70efbf1d47c`. Der Godot-Integrationszweig steht auf `a4f7454d8d8f190477f2c48f249e56be3b7ec16d`. Die beiden Schritte oberhalb des APK-Pins ergänzen Belege und einen engeren Sonnenhafen-Test. [Build 2086](https://github.com/Ullmann27/lumo-lernen/actions/runs/45799647600)

**Ausgangsbau.** 2082 wurde als signiertes ARM64-Artefakt heruntergeladen und nach Datei, Zertifikat, APK-Identität und PCK geprüft. Die Emulator-Tour bestand. 2085 stoppte vor der Paketierung mit 4.168 erfolgreichen Flutter-Prüfungen, 193 übersprungenen Prüfungen und einem Fehler. Das Widget für „Tiere“ entsteht bei einer langen Fachliste erst beim Scrollen. Der Test scrollt in 2086 bis zum Thema und öffnet das Modul über die reguläre Auswahl. 26 lokale Prüfungen bestanden. [2082-Artefakt](https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812/artifacts/15004539062)

## Prioritäten

| Priorität | Befund | Abnahme |
| --- | --- | --- |
| P0 | Die drei Android-Godot-Aktivitäten erzwingen Compatibility per Startoption. Die Projektvorgabe für einen nativen mobilen Start ist Mobile, Desktop nutzt Forward+. Flutter und Godot zeichnen auf getrennten Pfaden. | 2086 bestehend weiterprüfen. Mobile anschließend mit opt-in Start, protokolliertem Renderer und Rückfall testen. Standards in allen drei Activities vor Veröffentlichung nachweisen. |
| P0 | Ein kaputter gemeinsamer Eintrag im lokalen Aufgabenprotokoll kann durch das erste Lesen entfernt werden. | Fehlerhaftes Original bewahren, Schreibversuche kontrolliert behandeln und Trennung zweier Testprofile überprüfen. |
| P1 | Sonnenhafen besitzt fünf spielbare Abschnitte mit Sprüngen und eine vollständige Endwertung. An der ersten Rampe geht der Mittelgrund in einem gleichförmigen Horizont verloren. Die prägnanten Wahrzeichen und Architektur sind im Ausschnitt nur vereinzelt. Die kleine Fallback-Grafik unterscheidet sich von der aktuell verwendeten Groß- und Kleinkachel. | Neue Küstenstaffelung auf der Originalfahrt prüfen. Vorserienkacheln und Fallbacks für jede Strecke am aktuellen Kurs rendern. Geometrie- und Rundenprüfung getrennt vom Bildvergleich durchführen. |
| P1 | Das Leuchtschild und die warmen Hintergrundflächen der Werkstatt haben im echten Fenster viel Bildgewicht. 14 Meshy-Nahkarosserien haben je einen 2.048er-Farbatlas. Getrennte importierte Normal- und Rauheitstexturen liegen für diese Karosserien in den Quelldateien nicht vor. | Referenzfahrzeug mit warmem Hauptlicht, kühler Kontur und kontrastärmerem Schild prüfen. Das gleiche Kart und Kameraformat im Vorher-Nachher-Vergleich verwenden. |
| P1 | Die Datenbereiche für Mathematik beginnen im aktuellen Katalog später als die Aufgabenformate des österreichischen Lehrplans. Ein allgemeiner Balkenrenderer hat eine sichtbare Mindesthöhe und kann fehlende Daten aus Textziffern ergänzen. | Typisierte Daten durch Generator, Darstellung und Bewertung führen. Null, den kleinsten positiven Wert und fehlende Daten im echten Lernfluss prüfen. Danach eigene Datenwerkstatt für Klasse 2. [RIS](https://ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275) |
| P1 | Gemeinsam gespeicherte vier Grafikstufen bedienen auf allgemeiner Ebene drei Budgets. Eigene Szenen haben weitere Profile oder eine Teilmenge. Vulkan Mobile einschalten und Thermik adaptieren erfordert eine Gerätebaseline. | Aktive Wahl, internen Puffer, tatsächlichen Renderer, CPU/GPU und Dauerlast am selben APK-Hash erfassen. Die Karte und die Lernaufgabe behalten ihre Regeln bei Änderungen des Darstellungsbudgets. |
| P2 | Welt, Lauf und Tischspiele besitzen eigene Ladepfade und Ressourcen. Shader- und Textur-Caches bleiben teilweise nach Szenenabbau erhalten. | Erneutes Öffnen mit Messung der Residenz und Vorbereitung des ersten nutzbaren Bildes trennen. Geräte-Thermik und PSS zusammen mit den Renderdaten ausweisen. |

## Laufzeitpfade

- Flutter verwaltet Profile, Wallet, Lernhistorie, Fortschrittsauswertung und Sicherung. Native Events werden nach Rückkehr in dasselbe berechtigte Profil übernommen. Android lädt je nach Ziel allgemeine Spiele, Memory oder Quiz, beziehungsweise Vier gewinnt über eigene Activities. Der lokale Sprachpfad ist weiter nutzbar, wenn Gerät und Sprachmodelle tatsächlich verfügbar sind. Offline-Sprache für neue Fälle separat abnehmen.
- Die native Boot-Szene fordert das Szenenpaket asynchron über Godot an und nutzt den bestehenden SceneRouter beim Übergang. Spielregeln für Memory, Quiz und Vier gewinnt bleiben im Flutter-Host. Einzelstarts ohne diesen Host liefern Darstellungs- und Ladebeobachtungen.
- Godot enthält einen Linux-Export und einen Forward+-Standardpfad für Desktop. Der Flutter-Start der eingebetteten 3D-Welten und die Rückgabe von Fortschritt sind Android-spezifisch. Desktop benötigt neben dem Export einen Hosttransport mit lokaler Profilspeicherung, Ereignisbestätigung, Backup und Sprachanbindung. Der Cinematic-Aufruf bleibt ein eigener Capture-Prozess.
- Szenen, tatsächliche Eingänge und Belohnungsverträge stehen im [Spieleinventar](https://github.com/Ullmann27/lumo-godot/blob/a4f7454/docs/qa/spiele_inventar.md). Präsentations-, Vollrunden- und Persistenzprüfungen sind eigenständige Kriterien.

## Messgrenzen

Die Messreihe nutzt die echten Godot-Szenen bei 960 × 540 mit 24 Aufwärmframes und 60 stabilisierten Prozessintervallen. Der Durchlauf startet je Szene einen frischen Linux-Prozess mit fiktivem Profil. Lokales Mesa Software-Rendering und gleichzeitig laufende Arbeiten begrenzen die Aussage der Gesamtlaufzeiten. Textur- und Geometriezähler stammen von Godot. Ein Zähler für sichtbare Primitive enthält die Renderpässe und ist keine Summe der Dateidreiecke. Die Auflistung der in der Szene instanziierten Materialien ist eine Obergrenze. Ein Software-Fensterabzug ist kein Benchmark für ein Fold7.

Für die Geräteabnahme dasselbe Rennen am Fold7 innen und außen und auf einem 11-Zoll-Tablet mit protokollierter Puffergröße fahren. Jeweils Kaltstart, 60 Sekunden gleicher Ablauf und erneut nach 15 Minuten erfassen. P50/P95/P99, größte Bildzeitspitzen, Draw-Calls, PSS, verfügbare GPU- und Temperaturzähler getrennt ausweisen. 16,67 ms und 33,33 ms sind Budgets für 60 und 30 FPS. Die Familienkonfiguration testen, indem vorher ein lokales Backup angelegt und die signierte Variante als Update installiert wird. Fortschritt von zwei Profilen, Spielstände und erneuten Export prüfen.

## Erste Produktionsreferenzen

- [Küstenkulisse aus derselben Rennkamera](https://github.com/Ullmann27/lumo-godot/blob/96ad52c/docs/pruefung/Sonnenhafen_Kuestentiefe_Console.jpg)
- [Werkstatt im selben Kamerastand](https://github.com/Ullmann27/lumo-godot/blob/f26f56f/docs/pruefung/Werkstatt_Lichtregie_Console.webp)
- [Ein reales Diagramm im Lernfluss](Diagramm_Lernfluss_Console.webp) und [Prüfaufgabe mit Null und fehlendem Wert](Diagramm_Null_Console.webp)
- [Art Bible](https://github.com/Ullmann27/lumo-godot/blob/96ad52c/docs/design_targets/LUMO_CONSOLE_ART_BIBLE.md) und [fachlicher Kompetenzvertrag](CONSOLE-QUALITY-LERNEN.md)
