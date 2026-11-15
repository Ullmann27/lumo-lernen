# Lernabdeckung – tatsächlicher Quellstand

**Diese Matrix ist ein Inventar und eine offene Prüfliste, keine Erklärung einer fertigen Gesamtmodernisierung.** Grundlage ist Flutter `6f4a8c4753f4d06d0b392da0789b8162b2faa71b` mit den lokalen Navigationskorrekturen `6923a89` und `dde93af`. Die konkreten Quellenhashes stehen in [COVERAGE.json](COVERAGE.json). Parallele Änderungen werden erst nach ausdrücklicher Integration und erneutem Export berücksichtigt.

## Umfang

Der Export lädt die echten Dart-Kataloge. Die Matrix verknüpft **59 Routen und 53 Lernscreen-Dateien** mit Einstieg, Bedingungen, Fachautorität, Hilfen, Abschluss, vorhandenen Adaptern, Tests und Lücken.

| Bestand | Enumerierter Umfang |
|---|---:|
| Aktuelle Klassen-/Fach-/Einheitskombinationen | 236 (Klassen 1–4: 69 / 58 / 56 / 53) |
| Mathe- / Deutsch-Templates | 60 / 32, mit unveränderten IDs |
| Akademie-Themen | 79 |
| Fachmodul-Registry | 20 IDs, 19 verschiedene Screens |
| Praktische Aufträge | 60 IDs |
| Lernlabor | 5 Modi, 30 Problem-IDs |
| Geführte Lektionen | 7 Lektionen, 16 Antwortarten |
| Lernspiel-Level | 50 Level, 7 MiniGame-Typen auf 5 Screens |
| Reading Buddy / vorgefertigte Quests | 24 Text-IDs / 4 Quest-IDs |
| Kognitiver Aufgabenpool | 200 Frage-IDs, 5 Bereiche |
| Quizshow / Karten-Denkpausen | 108 deklarierte Quiz-IDs / 4 Bundles mit zusammen 200 Einträgen |
| Alte Deutsch-Lückensätze | 20 Bankeinträge, aktuell ohne App-Einstieg |

Die 10 `TaskType`- und 28 `VisualType`-Enumwerte sind getrennt erfasst. Ein Enumwert bedeutet keine eigene erreichbare Aufgabe. Der bestehende Legacy-Adapter erzeugt sechs der zehn TaskTypes; `imageWord`, `readingComprehension`, `dragDrop` und `trueFalse` sind darüber nicht eigenständig angebunden. Generierte Varianten und gespeicherte Geschichten haben dynamische Kennungen; diese Matrix erfindet dafür keine vollständige endliche ID-Liste. `routeRef` und `sourceIndex` sind ausschließlich Dokumentationsschlüssel.

## Bereits konkret geschlossen

- **Farben:** `s1_farben` war registriert, hatte aber keinen erreichbaren Akademie-Einstieg. Es öffnet jetzt über „Lernwerkzeuge & Geschichten“ für eingeschriebene und gewählte Klasse 1. Die Modul-ID und Fachlogik bleiben gleich.
- **Praktische Sprach-/Sachaufträge:** Der Hub öffnete nur 40 der 60 vorhandenen Katalogeinträge. Drei Werkzeuge erschließen nun die übrigen 20 Deutsch-, Englisch- und Sachunterricht-Aufträge. Sie verwenden die angesehene Klassenstufe ohne Profilwechsel und ohne künstliche Punktevergabe.
- **Gezielte Navigation:** Drei Widgettests sind auf 412 × 915 mit ruhigem Modus gelaufen und bestanden. Sie prüfen Öffnen/Zurück, mindestens 48 dp hohe Einstiege, unveränderte Klasse/Sterne/XP und die Trennung von angesehener und eingeschriebener Klasse.

## Fehlende echte räumliche Anschlüsse

Jede Route besitzt ein eigenes `spatial3D`-Objekt. **Flutter-Karten mit Schatten, interaktive 2D-Materialien und ein optionaler nativer Aufruf erfüllen die vollständige aufgabengebundene 3D-Anforderung noch nicht.** Der vorhandene native Pfad öffnet eine getrennte Activity; eine eingebettete Godot-Ansicht im Flutter-Aufgabenbaum ist in diesem Stand nicht vorhanden.

| Oberfläche | Tatsächlich vorhanden | Noch offen |
|---|---|---|
| Reguläre Aufgaben | 2D-Renderer, geprüfter Legacy-Adapter, optionale native Erklärung für passende Nutzdaten | Durchgängige Verbindung jeder Aufgabenfamilie mit sichtbaren benannten Objekten, Figur und fachlich geprüfter Eingabe |
| Fachmodule | Eigene lokale Aufgabenlogik, gemeinsamer Rahmen; Plus10 mit eigenem Kontext | Die übrigen 18 Screens veröffentlichen in der Basis keinen aktuellen Companion-Aufgabenkontext; 16 Screens haben keine eigene gestufte Hilfe |
| Lernlabor | Mengenbrücke, Bruchbau und Wort-/Begriffskarten zum Manipulieren | Vollständiger räumlicher Objekt-/Figuranschluss; eigener interaktiver Referenzfall „Muster fortsetzen“ |
| Geführte Lektionen | Fachlich geprüfte Schritte, Illustrationen, kompatible native Erklärungen | Gleiche aktuelle Aufgabe, Objekte, Sprache und Rückmeldung über den gesamten Ablauf verbindlich koppeln |
| Lesen, Geschichten, Foto, Praxis | Getrennte vorhandene Oberflächen und Bewertungsregeln | Eigene räumliche Anschlüsse; Foto-Karten prüfen derzeit keine Antwort, Praxisaufträge haben keinen Abgabe-/Beobachtungsabschluss |
| Tests, kognitive Aufgaben, Lernspiele | Eigene Controller, ID-/Speicher-/Belohnungsregeln | Jede Oberfläche separat anschließen und prüfen; Änderungen am Standardrenderer erreichen sie nicht automatisch |

Die zehn nativen Adapter-Kinds und ihre Grenzen stehen unter `nativeCompatibility`. Beispielsweise sind kleine Addition, kleine Multiplikationsgruppen, passende Brüche und geprüfte Silbenzahlen möglich; daraus folgt keine native Abdeckung sämtlicher Mathe-, Sprach- oder Sachthemen. Der Flutter-Szenenvertrag erklärt derzeit nur `placeValue` als Szenenart.

## Inhaltliche und technische Restlücken

**Satz-bauen-Lösungsleck:** `_SchoolbookFallbackVisual` baut die ständig sichtbare Satzkarte aus `correctAnswer`. Die neue Regression hat dies für Übung, Prüfung und Änderung ausschließlich des verborgenen Lösungsschlüssels reproduziert: **0 von 3 bestanden auf diesem Rendererstand.** Die Rendererdatei gehört dem parallelen c5-Zweig und wurde in diesem Branch nicht geändert. Der Test wird erst zusammen mit dessen Korrektur grün erwartet.

**Alte Lückensätze:** `LumoDeutschScreen` ist im Importgraph ab `main.dart` nicht erreichbar. Manche Aufgaben erlauben mehrere sinnvolle Antworten, etwa „im Haus/Garten“ und „auf dem Tisch/Ast“. Außerdem verwendet dieser alte Screen eine direkte Punkte-/Antwortbuchung. Er wurde deshalb nicht blind angeschlossen. Reguläre Satz-bauen- und Satzbaustelle-Aufgaben bleiben über den vorhandenen Generator erreichbar.

**Weitere offene Grenzen:** `d1_woerter` wird in der Akademie durch den aktivierten geschützten Wort-Schreibcoach überlagert. Lesen führt im Hub direkt zum aktiven Vorlesen, Rechtschreibung hat keine eigene Fachkachel; die exakte Auswahl jeder Generatorfamilie ist nicht durch einen UI-Durchlauf belegt. Live-Wort-/Foto-Teilnahmebelohnungen und heuristische Safari-Spracherkennung sind von überprüfter Fachleistung zu unterscheiden. Der 2D-Flame-Lernspielzweig hat eigene Aufgabenblöcke und eine feste Liste früher Einheiten; seine Klassenbindung benötigt gesonderte Prüfung.

Schreibtrainer und Journal sind intern geschützt. Die Matrix enthält überprüfte Hashes ihrer Dateien sowie der angrenzenden Schreibspeicherung/-darstellung. Kart und nativer Dschungel sind ausgeschlossen. Der eigenständige 2D-Flame-Lernspielpfad ist im Inventar enthalten.

## Reproduktion und Lesen der Prüfstände

```bash
flutter pub get --offline
flutter test --no-pub tools/nextgen/export_learning_catalog_test.dart \
  --dart-define=LUMO_CATALOG_OUTPUT=/tmp/lumo-learning-catalog.json
python3 tools/nextgen/build_coverage.py /tmp/lumo-learning-catalog.json
flutter test --no-pub test/design/learning_registered_routes_test.dart
flutter test --no-pub test/learning/sentence_prompt_privacy_test.dart
```

Der letzte Befehl reproduziert auf der dokumentierten Basis den offenen Fehler. Export und Quellenprüfung sind von fachlicher Prüfung und Gerätetest getrennt. Bei allen anderen verlinkten Tests bedeutet `present_not_run_in_this_review` nur: Die Testdatei ist vorhanden. Es werden keine früheren PASS-Berichte als aktueller Beleg übernommen. Android/Fold-Hardware, Rotation, große Schrift, tatsächliche Audio-/Mikrofonabläufe und 60 FPS bleiben offen.
