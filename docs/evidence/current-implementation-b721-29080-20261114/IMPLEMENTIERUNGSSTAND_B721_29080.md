# Lumo – Implementierungsnachtrag b721 / 29080

**Momentaufnahme vom 14. November 2026, 17:34:30 UTC.** Maßgeblich sind [Host b721][H], [Native 29080][N] und der dauerhaft gesicherte [Belegstand 5910][E]. Dieser Bericht beschreibt implementierte Funktionen, abgegrenzte Erfolge und offene Arbeit. Eine Gesamt-, APK- oder Leistungsfreigabe folgt daraus nicht.

Die [bisherige Modulmatrix][I] bleibt historische Quelle. Ihre 23 ausgewählten Produktquellen wurden gegen die aktuellen Gitbäume geprüft: alle identisch. Die folgende Unterscheidung „Bestand / Ausbau“ beschreibt den bisherigen Studio-Verlauf, nicht ausschließlich Änderungen des letzten Commits.

## 1. Was aktuell tatsächlich geprüft ist

| Prüfung | Ergebnis dieser Quellenstände | Aussagegrenze |
|---|---|---|
| [Native-Gesamtlauf 43611803408](https://github.com/Ullmann27/lumo-godot/actions/runs/43611803408) | Alle **9 Jobs erfolgreich**; **49 aktuelle Originalbilder** durch das Team persönlich geprüft. Der [Receipt][R] bindet Lauf, Archiv und einzelne Bildhashes. | Desktop-Godot mit Software-Renderer; keine Androidscreenshots. Bildsichtung ist keine Messung stabiler Bildrate. |
| [Host-Featurelauf 43618076296](https://github.com/Ullmann27/lumo-lernen/actions/runs/43618076296) | Alle **3 Jobs erfolgreich**; vollständige Flutter-Suite **2.608 bestanden, 0 fehlgeschlagen, 0 übersprungen**. [Originalauswertung][F] | Die 546 erzeugten Flutter-PNGs wurden nicht alle persönlich angesehen. Fluttertests prüfen nicht die neue Java-Sprachausgabe. |
| [Recovery 43618078329](https://github.com/Ullmann27/lumo-lernen/actions/runs/43618078329) | **618 Skriptfälle, 0 Fehler, 0 übersprungen**. [Gebundene Zusammenfassung][A] | Enthält Python-Orchestrierung; die gesonderten Sprachverträge sind kein darin versteckter Synthesenachweis. |
| Aktuelle Sprachintegration | Reale Android-Klassenkompilierung sowie **11 Javafälle / 103 Assertions und 8 Kotlinfälle**, alle erfolgreich, keine übersprungen. [Originalreview][S] | Inferenz-/Android-Randstubs sind deklariert; keine gehörte Ausgabe und keine tatsächliche ONNX-Inferenz. |
| [Studio 43619285124](https://github.com/Ullmann27/lumo-lernen/actions/runs/43619285124) | Englisch-, Quiz- und Memory-Authority sowie Hostkompilierung erfolgreich. **APK, Androidtouren, Update und Veröffentlichung noch offen.** | Erfolgreiche Einzeljobs ersetzen nicht den noch offenen Gesamtlauf. |

Der aktuelle [Englischjob][EN] verwendet den echten Dart-Aufgabenproduzenten: **10 Fälle / 2.955 Checks**, danach **7.691 Nativechecks und 17 gemeldete Bilder**. Diese **17 neuen Bilder sind wegen des Umgebungsausfalls ungesichtet**; für ihr Archiv wurden hier weder Download noch CRC-Prüfung behauptet. Frühere 7.633 Checks oder frühere Bildsichtungen werden nicht übertragen.

Der Flutter-Analyzer meldete 209 Informationshinweise und fünf Warnungen bei null Analysefehlern. Im erfolgreichen Native-Gesamtlauf bleiben vier Ressourcenmeldungen beim Prozessende ungeklärt. Erfolgreiche Jobstatus bedeuten deshalb nicht „warnungsfrei“. Überlappende Testsuiten werden nicht addiert.

## 2. Alle zehn Hauptportale

Die [aktuelle Portaldatei][P] enthält genau diese zehn Einträge. Ein sichtbarer Eintrag allein beweist keinen gelungenen Android-Spielstart. Die Herkunft des Bestands und die einzelnen Erweiterungen sind in der [vollständigen Inventur][I] gebunden.

| Portal | Bereits vorhanden | Im jetzigen Stand enthaltener Ausbau |
|---|---|---|
| **Memory** | Flutter-Motive, Schwierigkeitsstufen, Gegner, kindbezogene Bestwerte. | Native 3D-Karten und Drehung; gemeinsamer dauerhafter Dart-Zustand; Pause mit Restzeit, Wiederaufnahme, Schutz vor verspätetem Öffnen und doppelt gezahlter Belohnung. |
| **Cards** | Dart-Regeln, Gegner, Save, Cup und nativer Tisch. | Heartbeat, Pause/Return, gebundene Kartenfronten, echte Safe-Area, deutsche Rückmeldungen und Rücknavigation über die Showcase-Zwischenebene. |
| **Puzzle** | Fünf Motive, Teilzahlen, Drag/Snap und Speicherung. | Vierteldrehung mit gespeicherter Orientierung, bedienbare Menüs und gemeinsame Insets. |
| **Jump & Run** | Inseln/Expeditionen, Analogbewegung, variable Sprünge, Puffer und Kollisionen. | Sechs zusätzliche Original-Lumo-Bewegungsclips, neutrale Pose, Landungs-/Flugübergänge und sichere Bedienelemente. |
| **Rhythm / Rhythm Party** | Vier Songs, Tap/Hold/Slide, Combo und Tour. | Gemeinsame Insets und erneutes Layout bei Änderungen; kein neuer Rhythmusregelsatz. |
| **Schatzsuche** | Sieben Hinweise, Fundstücke, Rucksack, Tor und Save. | Garten-/Kristallfortschritt, besserer Titelkontrast, freier Blick auf Lumo, kompakte Hinweistaste und Meldungen außerhalb der Touchflächen. |
| **Bauwelt** | Bauteile, Verschieben/Drehen, Raster/Kollision, Undo/Redo und Save. | Original-Lumo-Anschluss, bedienbare Dialoge, Kamera-/Touchgrenzen und Insets. |
| **Lumo Kart** | Zwölf Strecken, Rennen/Cup/Zeitfahren/Training/Arena, Gegner und Garage. | Werkstatt-/Dichte-/Wischbedienung und Safe-Area; der QA-Vorschauschritt nutzt einen tatsächlich beobachteten Tipp. |
| **4 Gewinnt** | Flutter-Regeln auf 7×6, Gegner und lokale Runde. | Native Steine/Gewinnringe, Pause/Return/Save; gemeinsam scrollendes Flutter-Brett mit zugeordneten ≥48-dp-Spaltenknöpfen. |
| **Quizshow** | Vorhandene Fragebank, 20 Fragen, drei Joker und Meilensteine. | 3D-Studio mit Original-Lumo, Dart-Spielautorität, bestätigten Aktionen, dauerhafter Runde, nullable Erklärung, korrekten versteckten Antworten und Walletabschluss. |

Memory und Quiz sind somit keine bloßen neuen Vorschaubilder. Die aktuellen [Memory-][M] und [Quizoriginale][Q] zeigen echte Dart-/Godot-Prozesspaare mit produktiver Regellogik. Ihr Dateitransport und Belohnungsledger sind ausdrücklich QA-Adapter. Daraus folgt noch kein Nachweis der Android-Binder-Verbindung oder einer echten kindbezogenen Geräte-Wallet.

## 3. Lernen, Englisch und erhaltener Bestand

Mathematische 3D-Hilfen einschließlich **8 + 5** waren bereits vorhanden. Studio ergänzte gleichmäßiges Verteilen, passende Multiplikations-/Divisions-/Bruchdaten und korrekte Beschriftungen. Silben-/Wortzuordnung, Lesen mit Verständnisfragen, Grammatikübungen und das Pflanzenmodell sind ebenfalls Bestand; daraus werden keine vollständig neu entwickelten Lehrwelten gemacht. [Inventur][I]

Neu ist die an eine **tatsächliche aktuelle Aufgabe** gebundene Englischgalerie mit sichtbaren geometrischen Gegenständen, Auswahl, gezieltem Hinweis und Rückkehr. Ihr [geschlossener Katalog][V] enthält:

**book/Buch; pen/Kugelschreiber beziehungsweise Stift; ruler/Lineal; bag/Tasche; rubber/Radiergummi; school bag/Schultasche; desk/Schreibtisch; chair/Sessel; pencil case/Federpennal; paper/Papier; ball/Ball; car/Auto; sun/Sonne; apple/Apfel.**

Damit sind alle zehn konkreten Schulsachen-Einträge der Klassen 1/2 unterstützt. Die [Aufgabenbindung][L] prüft Fach, tatsächliche Frage, Antwort und Optionen. Die Hilfe erzeugt keine erfundene richtige Antwort, vergibt keine eigenen Fortschrittspunkte und ersetzt nicht die Aufgabenlogik. Abstrakte Inhalte höherer Klassen bleiben außerhalb dieses Objektvertrags.

**Neu in b721:** Das vertrauenswürdige Host-Aufgabenobjekt bestimmt das englische Zielwort. Derselbe vorhandene Offline-Sprachpfad erzeugt **englisches Wort → 250 ms Stille → unveränderte deutsche Erklärung**, mit derselben F2-Stimme und einem Player. Sprachkennung, PCM-Grenzen und Abbruch zwischen Inferenzschritten sind geprüft; Elternfreigabe, Offline-Lizenz, Stop/Mute und Lebenszyklus bleiben erhalten. Die allgemeine deutsche Flutter-Schnittstelle bleibt unverändert. [Adapter][SA] · [Engine][SE] · [Verträge][S]

Das ist eine implementierte Sprachanbindung, noch keine Hörabnahme. Aussprache, reale Gerätewiedergabe und das Zusammenspiel mit dem sichtbaren Kiefer müssen am tatsächlichen Modell-/Androidpfad geprüft werden.

Schreibtrainer, Wortcoach, Journal und Lesen bleiben integriert. Der neue Baumvergleich zeigt gegenüber 2e20 **sechs Schreib-, zwei Journal- und sieben Lesedateien mit identischen Gitblobs und Dateimodi**. Das belegt Quellerhalt dieser Pfade; vollständige Zwei-Kind-Wechsel, Journalmigration und alle alten nativen Saves sind dadurch nicht abgenommen. Einzelne Updatefixtures dürfen nicht auf diesen Gesamtumfang ausgedehnt werden.

## 4. Weitere bestehende Zugänge und zwölf Kartstrecken

Neben den zehn Portalen bestehen Siedlung innerhalb der Bauwelt, Würfel-Wettlauf, kooperativer Sternenpfad/Kartenabenteuer und das getrennte Flame-2D-Abenteuer unter „Zusätzliche Spielmodi“. Der Haupt-Abenteuerknopf öffnet Godot Jump. Wiederholte Cards-/C4-/Jump-Zugänge sind keine weiteren Hauptspiele. [Aufrufbindungen][G] Der Lernspiel-Levelkatalog bietet Zahlen-/Wort-/Farben-/Buchstabenaufgaben; seine Level sind keine entsprechend große Zahl neu gebauter 3D-Szenen.

Startseite, Quest/Story, Bibliothek, Zauberwelt, Meine Welt, Cosmos, Mirror, LIVE und Foto-Lektion bleiben zusätzliche Bestandszugänge. Kamera-/Online-/Sprachfreigaben sind dabei eigene Grenzen. Akademie und fünf Flutter-Lernateliers – Zehnerbrücke, Wortwerkstatt, Weg des Wassers, kleine English-Welt und Bruchatelier – sind keine fünf zusätzlichen neuen Godotwelten. Registriert bleiben auch reading_hub, alphabet, word_picture_match, sound_letter_match, word_build, learn_old, stars und parent; diese Einträge sind keine zusätzlich neu geprüften Hauptportale. Diese Einordnung stammt aus der quellengebundenen [Bestandsinventur][I].

Der aktuelle Kartbestand umfasst vier [Basisstrecken][K1] und acht [Erweiterungen][K2]:

| ID | Anzeigename | ID | Anzeigename |
|---|---|---|---|
| sonnenhafen | Sonnenhafen | zauberwald | Zauberwald |
| bergwelt | Himmelsinseln | holo_city | Holo City |
| crystal_canyon | Kristall-Canyon | jungle_temple | Dschungel-Tempel |
| candy_cloud | Candy Cloud Circuit | volcano_night | Volcano Night Run |
| winter_sprint | Winter-Sprint | galaxy_ringway | Galaxy Ringway |
| desert_drift | Desert Dune Drift | learning_lab | Funkel-Labor |

Das sind zwölf **vorhandene** Strecken, keine zwölf neuen Implementierungen oder zwölf aktuell vollständig geprüften Gerätefahrten.

## 5. Original-Lumo, Blender und Gesicht

Die [gebundene Asset-Herkunft][B] dokumentiert tatsächlich frühere Blender-Arbeit am Original-Lumo: erhaltene Körperattribute, Materialien, 65 Bones und neun Originalclips; zusätzlich sechs Studio-Bewegungsclips. Die Facial-Ableitung ergänzt skinnierte Lider, begrenzte Blickverformungen der bemalten Augenregion und eine dezente geschlossene Kiefer-/Schnauzenform.

Die Geometrie ist produktiv an Actor und Lehrer angeschlossen. Reale lokale Wiedergabezeit und Amplitude können die Kieferform steuern; das sind **keine phonembasierten Viseme**, unabhängigen Augäpfel oder offene Mundhöhle. Die bisherige Film-/Bildprüfung belegt diesen engen Geometrieumfang, keine umfassende Emotions-/Gestenbibliothek. [Herkunft][B] · [Aktueller Receipt][R]

Sichtbare Grenzen bleiben: einfache Räume/Materialien, einzelne Gesichtsfacetten, teilweise verdeckter Cards-Fuchskopf im Querformat, kein Lumo in schmalen C4-Ansichten und scrollende beziehungsweise gekürzte Texte in kleinen Formaten. Aufnahmebildrate ist keine gemessene Gerätebildrate.

## 6. Was noch fehlt und aktuell möglich ist

Für den vollständigen Masterumfang fehlen weiterhin umfassende neue Lehr-/Geschichtenwelten – etwa für Zahlenstrahl, Maße/Flächen, Uhr/Geld, Satzbau oder ganze Sachunterrichtsthemen –, reichhaltige Gestik/Emotionen und Phonemsynchronität. Offen sind außerdem die aktuelle kombinierte APK-/Android-/Update-/Publisherabnahme, vollständige Datenwechsel-/Migrationsfälle sowie physische Fold7-Messungen zu Bildrate, Temperatur, Energie und Eingabelatenz. „AAA fertig“, stabile 60 FPS oder Gleichwertigkeit mit Mario Kart sind nicht belegt.

Blender, Godot und lokale Dateibearbeitung wurden zuvor tatsächlich benutzt. **Seit dem gemeldeten Ausfall ist die lokale Umgebung derzeit nicht verfügbar.** GitHub-Zugriff, Remote-CI, Agentenkoordination und Änderungen über die Git-Daten-API funktionieren weiter; aktuelles lokales Rendering wird nicht behauptet. Dieser Nachtrag nutzt ausschließlich gelesene Gitquellen und gesicherte Originalberichte, ohne neuen Test-, Bild- oder Syntheselauf.

Die begleitende Quellenbindung enthält die exakten SHA256-/Gitblob-Zuordnungen, Baumvergleiche und Abnahmegrenzen. Spätere APK-Ergebnisse erhalten einen eigenen Nachtrag.

[H]: https://github.com/Ullmann27/lumo-lernen/commit/b7210db3f53361987fd33592de438fd7984d991a
[N]: https://github.com/Ullmann27/lumo-godot/commit/29080ef8cd1a5b385eeeec97976fbefd31280427
[E]: https://github.com/Ullmann27/lumo-lernen/tree/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence
[I]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/current-master-module-report-20261114/MODULMATRIX_2e20_29080.md
[R]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/config/studio-2020-visual-review.json
[F]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/host-b721-flutter-acceptance-20261114/review.json
[A]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/host-native29080-integration-20261114/evidence/current-script-recovery-summary.json
[S]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/studio-host-b721-speech-ci-20261114/review.json
[EN]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/studio-host-b721-english-authority-20261114/terminal-log-only/review.json
[P]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/features/games/spielwelt/spielwelt_routes.dart
[M]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/studio-b721-memory-authority-20261114/README.md
[Q]: https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/studio-host-b721-quiz-ci-20261114/review.json
[G]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/features/games/games_content.dart
[V]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/domain/tutoring/native_english_vocabulary.dart
[L]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/lib/domain/tutoring/native_learning_activity.dart
[SA]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/tools/auto_install/LumoLearningSpeech.kt
[SE]: https://github.com/Ullmann27/lumo-lernen/blob/b7210db3f53361987fd33592de438fd7984d991a/tools/auto_install/LumoOfflineSpeechEngine.java
[K1]: https://github.com/Ullmann27/lumo-godot/blob/29080ef8cd1a5b385eeeec97976fbefd31280427/scripts/games/kart_catalog.gd
[K2]: https://github.com/Ullmann27/lumo-godot/blob/29080ef8cd1a5b385eeeec97976fbefd31280427/scripts/games/kart_expansion_tracks.gd
[B]: https://github.com/Ullmann27/lumo-godot/blob/29080ef8cd1a5b385eeeec97976fbefd31280427/assets/characters/lumo_facial/ATTRIBUTION.md
