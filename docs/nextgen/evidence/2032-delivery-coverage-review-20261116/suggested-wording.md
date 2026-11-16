# Lesereview des Lieferberichts 2032

**Prüfstand:** Bericht/Belege `8649ac8d4bc86deadbe5a64b9dc925dd95cc007a`; APK-Quelle `9b38360ca5f21919dce4a2b99e605ee39bbbf454`, Native `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`. Keine neuen Tests, Geräteaktionen oder Repositoryänderungen. Die neue Vierfall-Tour an QA `ce8458e8…` hat in dieser Prüfung noch kein ausgewertetes Originalresultat.

## Konkrete Korrekturen der sechs Abschnitte

| Abschnitt | Befund und erforderliche Präzisierung |
|---|---|
| 1 – Lernbereiche | Alle benötigten Inventare sind vorhanden. Die Überschrift „vollständig modernisiert“ ist zu stark; ersetzen durch „Erreichbare modernisierte Lernwege und verbleibende Abdeckung“. Zusätzlich je Bereich tatsächliche Flutter-Lernoberfläche, bestehende Fachbewertung und speziellen Nativeanschluss oder generische Karte unterscheiden. |
| 2 – Figur / Gespräch | Kein konkreter überzogener Funktionsclaim gefunden. Lokaler Aufgabenbezug, optionaler generativer Proxy, Sprachkandidat mit bewusster Bestätigung und separate native Activity sind bereits zutreffend begrenzt. Gültiger Scope bedeutet nicht Verständnis jeder beliebigen Frage. Prüfungsbeschränkungen sind beabsichtigt. |
| 3 – Prüfungen / Gerät | Harte Zahlen stimmen mit den gesicherten Auswertungen überein. Home-/Resize-Zeile genauer auf die unten genannten Lab-Checkpoints begrenzen. Erreichbarkeit, Quelltests und Androidabnahme nicht vermischen. |
| 4 – Quellen / Integration | Keine konkrete falsche Identität gefunden. Katalogquelle `a5ea7422…`, APKquelle `9b38360…`, Nativepin und Nachlauf-QA getrennt lassen. Der katalogrelevante Diff `lib/assets/android/Exporter/Lock` von a5ea zu 9b ist leer; die ursprüngliche Exportidentität bleibt erhalten. |
| 5 – APK / Medien | Keine konkrete Übertreibung gefunden. Anonym geprüfter ARM64-Download und x86-Emulatortour bleiben unterschiedliche Belege. Fotos/Videos aus der abgeschlossenen Tour belegen keinen Erfolg des neuen Nachlaufs. |
| 6 – Restgrenzen | Weitgehend korrekt. „Dafür wird ein getrennter QA-Zweig erstellt“ ist nach Aktivierung veraltet. Strukturelle Grenzen, noch ungetestete Varianten und absichtlich geschützte/manuelle/inaktive Bereiche ausdrücklich trennen. |

## Vorschlag für die fachliche Anschlussmatrix

Die Zählbasis umfasst **61 geprüfte Inventareinträge**, darunter Navigation, Verträge, geschützte und inaktive Wege; **55 Quelldateien mit Screens** und **236 Curriculumfamilien** sind keine 61 bewerteten Aufgaben oder 236 auf Android geprüften Screens. Erreichbar sind **19 Spezialmoduleinstiege auf 18 Oberflächen**, **6 Lernatelier-Modi mit 35 festen Problem-IDs** sowie **7 geführte Lektionen**. Die vorhandene Fachlogik bleibt zuständig; die Oberfläche, Hilfe, Sprache und Nativeübergabe geben keine eigenständigen Belohnungen aus.

| Lernweg / tatsächlicher Einstieg | Was angeschlossen ist | Native-Darstellung und Grenze |
|---|---|---|
| Akademie → Fach / Einheit → Core oder klassenübergreifende Übung | Aufgabenrenderer, vorhandene lokale Auswertung, aufgabengebundener Coach, bestätigungspflichtige Sprach-/Coachvorschläge, gesicherte eigene Dialogwege | `forTask` wählt ein geprüftes Spezialmodell, sonst eine begrenzte aktuelle `task_card`. Kein individuelles 3D-Modell jeder der 236 Familien. |
| Akademie → registriertes Fachthema | 19 Einstiege: Plus/Minus/Zahlen bis 10, Formen, Tiere, Farben, Uhr, Geld, Zahlen bis 100, Artikel, Mehrzahl, Jahreszeiten, Wetter, Verkehr, Wortarten, Zeitformen, zwei Einmaleins-Stufen und Brüche. Vorhandene interaktive Fachübungen im gemeinsamen Rahmen; aktuelle Aufgabenbindung, Hilfe und kontrollierte Bestätigung | `ModuleTaskScope` beziehungsweise Plus-Adapter nutzen `fromCompanionContext`: generische Karte. Zwei Einmaleins-Einstiege teilen einen Screen; der registrierte Wortdiktatweg wird durch den geschützten Wort-Schreibcoach verdrängt. |
| Akademie-Werkzeuge → „Lumos interaktives Lernatelier“ | Sechs interaktive Flutter-Modelle: Zehnerübergang, Silben/Wörter, Englisch, Pflanzen, Brüche, Muster; 35 Problem-IDs, gestufte Hilfe, lokale Auswertung und Checkpoints | Alle sechs Native-Einstiege sind `task_card`. Die spezialisierten nativen Pflichtszenen Banane und Muster werden über andere Wege erreicht. |
| „Lumo erklärt es mir“ / „Mit Lumo Neues entdecken“ | Sieben geführte Lektionen: Über den Zehner; Einmaleins; Minus über den Zehner; Wörter in Silben hören; Blütenpflanze; nächster Hunderter; gleiche Teile/Brüche. Beispiel, gemeinsamer Schritt und eigenständige Aufgabe sind getrennt | `fromLesson` liefert passende begrenzte Spezialmodelle; andernfalls aktueller Kontext als Karte. Nicht jede Schrittvariante wurde auf Android durchgespielt. |
| Lesen / Reading Buddy / Geschichten; Live, Quiz, Lernkarten und 2D-Flame-Fragen | Bestehende Text-/Frageabläufe und lokale Fachregeln mit aktuellem Coach, Hilfe und Sprache | Überwiegend gemeinsame Nativekarte. Teilnahme ist nicht automatisch fachliche Beherrschung. Freie deutsche Erkennung und sämtliche dynamischen Texte sind nicht vollständig gerätegeprüft. |
| Foto-Lektion → Üben; Minispiel → Lernrunde | Tatsächliche Antwortaufgaben, lokale Prüfung und Fortschritts-/Wiederaufnahmewege. OCR und eine gezeigte Lösung sind keine richtige Antwort | `forTask` wählt validierte Spezialmodelle oder Karte. 49 Minigamelevel plus Abschlussquiz sind Katalogbestand, keine 50 vollständig durchgespielten Androidlevel. |
| Tests / IQ / kognitives Profil | Vorhandene lokale Prüfungsabläufe, Aufgabenidentität und begrenzte zulässige Begleitung | Fehlende Lösungshilfe oder 3D-Abkürzung ist hier Prüfungsregel. Kein klinischer Normierungs- oder vollständiger Testvariantenclaim. |
| Praxisaufgaben / Schreiben / Journal / Altwege | 60 praktische Aktivitäten haben einen Journal-Beobachtungsweg. 18 geschützte Dateien bleiben bytegleich; äußere Adapter sind getrennt | Manuelle Beobachtung bleibt absichtlich manuell. Die alte mehrdeutige Deutsch-Lückenbank ist inaktiv; der alte Teacher-Themenchat ist keine aktuell erreichbare bewertete Aufgabe. Kart und natives Dschungel sind ausgeschlossen. |

Die native Adapterfamilie kennt **12 Deskriptortypen: elf spezialisierte Modelle und `task_card`**. Diese Typzahl beweist weder eigene räumliche Modelle für jede Katalogfamilie noch zwölf überall erreichbare Android-Prüffälle. Lumo erscheint in einer eigenen nativen Activity und steht nicht dauerhaft in jeder Flutter-Aufgabe.

## Genaue Pause- und Größenwechselgrenze

Die abgeschlossene Originaltour hat drei echte Home→Launcher→App-Rückwege geprüft: `bridge-8-5` mit `moved=1`, `word-banane` mit `tokens=[2,3,0]` und `pattern-kreis-dreieck-5` mit `patternChoice=1`; jeweils Beispielphase und identischer gespeicherter Checkpoint. Zusätzlich sind Rückwege aus der jeweiligen Labroute protokolliert. Die vier WM-Konfigurationen und anschließende Rückstellung betreffen ausschließlich denselben `bridge-8-5`-Zwischenstand: 720×1600/320 dpi, 1768×2208/360 dpi, 1080×2520/420 dpi und 1968×2184/420 dpi. Das sind emulierte Layoutklassen, kein realer Fold7-/Scharnier-, Prozessneustart- oder Native-Resize-Nachweis. Restliche Bedienelemente können weiterhin Scrollen benötigen.

Belegt sind die tatsächlich vorhandenen synthetischen Profile, zwei vorhandene kanonische Lern-/Belohnungswerte und die genannten Checkpoints. Eine Migration einer gefüllten echten Kinderhistorie oder sämtliche Aufgaben-/Gerätekombinationen folgen daraus nicht. Die neue Zusatzrunde bleibt ergebnisoffen; bisher sind die fachliche Musterabgabe, 15→16-Abgabe, aktiver Flutter-Wortwechsel und native Langsamer-Wiedergabe nicht aus dieser abgeschlossenen 2032-Tour abzuleiten.

## Maßgebliche Quellstellen

- `docs/nextgen/COVERAGE.json`: `counts`, `countSemantics`, `scope`, `routes[*].entry/reachable/authorityRef`, `capabilityMatrix[*].nativeLearningEntry`, `gaps[*].classification`, `sourceSnapshot`.
- `lib/domain/tutoring/native_learning_activity.dart`: `forTask` (17), `fromCompanionContext` (30–46), `_taskCard` (66), `fromLesson` (329–410).
- `lib/features/learning/lab/learning_lab_screen.dart`: `_openNativeLearning` (895–915), sichtbarer `lab-open-3d` (1195); `lib/features/learning/nextgen/module_task_scope.dart`: Nativeübergabe (369–379), sichtbarer `module-open-3d` (542).
- `lib/features/learning_modules/learning_module_registry.dart`: `builderFor` (46–90), registrierte IDs (93–114); `lib/domain/tutoring/guided_lesson_catalog.dart` und `lib/features/learning/lab/learning_lab_catalog.dart` fixieren Lektionen und Problem-IDs.
- `docs/nextgen/INTEGRATION_V1.md` sowie `evidence/2032-original-team-integration-review-20261116/root-byte-review.json` sichern Integrationsgrenzen; kein vermeintlicher neuer Scope-Fehler wird aus alten Inventarbegriffen abgeleitet.
- `evidence/ci-2032-android-complete-verified/independent-review/lifecycle-persistence-review.json`: 0172→0182, 0281→0291, 0334→0344 (Home); 0193→0202/0212/0222/0232/0236 (Resize/Rückstellung). Rohbelege bleiben unverändert.

**Vollständigkeit bleibt offen:** Spezifische räumliche Modelle für alle Familien, dauerhaft eingebettete 3D-Figur, flächendeckende Varianten-/48-dp-/Hardwareprüfung, reale deutsche Spracherkennung und akustisch vermessene Wiedergabe fehlen als vollständiger Nachweis. Die gemessenen rund 1,215 nativen Prozessframes/s auf dem Softwareemulator erfüllen kein 60-FPS-Ziel. Flame-Auswahl für höhere Klassen ist zusätzlich eine offene Inhaltsprüfung; daraus allein wird kein bestätigter Laufzeitfehler behauptet.
