# Aktueller Studio-Quiznachweis – Host b721 / Native 29080

Beobachtungsstand: **2026-11-14T17:15:27Z**. Der Quiz-Autoritätsjob **132521067495** im Studio-Run **43619285124** ist **SUCCESS**. Dies ist eine begrenzte Abnahme dieses Desktop-Paarlaufs, keine vollständige Studio- oder Android-Freigabe.

## Quellen und Originale

Host `b7210db3f53361987fd33592de438fd7984d991a`, Tree `c65558a13e4dd2950eda7a685583e5484d9b9959`; Native `29080ef8cd1a5b385eeeec97976fbefd31280427`, Tree `5ddbea2b1d5e76ed592a27c36079632d7f26cada`. Diese Inhalte wurden aus den aktuellen Originalstempeln und dem Paarbericht gelesen. Beide Quellbäume sind vor/nach dem Paarlauf identisch.

Das einmal geladene Artefakt **14124000432** enthält **35 vollständig CRC-geprüfte ZIP-Einträge**. Archiv: **501.399 B**, SHA256 `ac00a40ffb8215e6e50b6f17a5aaedf346f1ed3c40f7a05224549f195c332a8d`. Der einmal nach Jobabschluss geladene Originaljoblog umfasst **302.585 B**, SHA256 `16258f88f6f7bd9f56f1cfeaa163755ff9ba3891d98f7927b9c36e04faf55c41`.

## Tatsächliche Ergebnisse

- Reine produktive Dartverträge: **28 Fälle / 1.786 Checks / 0 Fehler / 0 Skip**.
- Echter Dart↔Godot-Paarlauf: **386 Checks / 0 Fehler**, **366 tatsächliche Godot-Eingabeereignisse** (182 ScreenTouch, 184 ScreenDrag), **68 Requests**, sechs PNGs; beide Prozesse **Exit 0**.
- Die gespeicherte Runde enthält **20 Fragen**, 20 Auswahl-, 20 Aufdeck-, 19 Weiter- und drei Jokeraktionen. Das ausdrücklich deklarierte QA-Ledger enthält genau eine bezahlte Runden-ID und **5.000 Sterne**.
- Im aktuellen Start wurde eine beobachtete Pause mit echter Eingabe fortgesetzt. Weitere Pause/Wiederaufnahme nach Frage fünf und nach dem Abschluss sowie die bestätigte Rückkehr sind im aktuellen Journal dokumentiert. Die erste Wiederaufnahme erklärt die aktuelle Requestzahl68; ältere Zähler wurden nicht übernommen.
- Godot **4.6.3**, Dart **3.12.2**, X11/GL-Compatibility/llvmpipe. VSync-, SSAA- und Volumetric-Fog-Warnungen sind vorhanden; es wird kein warnungsfreier Lauf behauptet.

## Sechs tatsächlich einzeln geöffnete aktuelle Bilder

| Originaldatei | Größe | Tatsächlicher Befund und Grenze |
|---|---:|---|
| quiz-dart-question.png | 960×540 | Frage 1 von 20, Sachunterricht/Stufe 1 und „Womit riechen wir?“ sind vollständig lesbar. Vier beschriftete Antworten bilden ein geordnetes Zweispaltenraster. Original-Lumo steht vollständig sichtbar links auf dem Podest vor dem Leuchtbogen. Kopf, Hände und Füße werden nicht vom Fragefeld verdeckt. Zurück, Pause, Antwort aufdecken und alle drei Joker sind sichtbar. „Gesichert: 0 Sterne“ ist lesbar. Statische Ansicht ohne eigenen Nachweis der Eingabefunktion. Die Kulisse ist ein schlichtes Podest mit Leuchtbogen; daraus folgt keine umfassende visuelle Qualitätsfreigabe. |
| quiz-dart-selected-phone.png | 412×915 | Im schmalen Hochformat steht der sichtbare Lumo oberhalb der Frage. Header, Figurenbereich und Antwortkarte überlagern sich nicht. B „Mit der Nase · Publikum: 77 %“ ist deutlich goldfarben als Auswahl markiert; A zeigt 5 %, C und D heißen sichtbar „Ausgeblendet“. Antwort aufdecken, die drei Joker, der zweizeilige Lumo-Tipp und „Gesichert: 0 Sterne“ sind in diesem aktuellen Bild vollständig lesbar. Die Figur ist im Hochformat kleiner als in der Landschaftsansicht. Das Bild belegt weder eine Android-Dichte noch eine Geräteleistung. |
| quiz-dart-jokers.png | 960×540 | Publikumswerte sind an A/B lesbar, C/D werden als „Ausgeblendet“ dargestellt. Die mehrzeiligen Antwortbeschriftungen bleiben in ihren Feldern. Die drei genutzten Joker erscheinen gedimmt; der Lumo-Tipp ist als zweizeiliger Text sichtbar. Lumo und Bogen bleiben links frei; der vertikale Scrollbalken rechts zeigt zusätzlichen Inhalt. Die Zeile mit gesicherten Sternen ist in diesem Scrollausschnitt nicht sichtbar. Aus diesem Einzelbild wird keine gleichzeitige Sichtbarkeit sämtlicher Inhalte behauptet. |
| quiz-dart-revealed-small.png | 640×360 | Der kleine Querformat-Ausschnitt zeigt die ausgeblendeten C/D-Zeilen, eine vollständig beschriftete „Nächste Frage“-Taste und die Rückmeldung „Richtig!“. Lumo ist links vollständig sichtbar und hat beide Arme angehoben. Header mit Zurück und Pause bleibt frei. Es erscheint weder ein fehlerhafter Null-Text noch eine erfundene Erklärung; der gelesene aktuelle Zustand enthält explanation=null. Frage und obere Antworten liegen oberhalb des sichtbaren Scrollausschnitts. Das Standbild belegt keine Animationssequenz oder zeitliche Reaktion. |
| quiz-dart-paused.png | 640×360 | Die Pause-Taste im Header ist gedimmt; Lumo steht links vollständig sichtbar. Der aktuelle Scrollausschnitt zeigt „Fach für eine neue Runde“, „Alle Fächer“, „Deutsch“ und „Mathe“. „Sachunterricht“ ist am unteren Cliprand nur teilweise sichtbar. Der Original-Sidecar bestätigt paused=true bei Frage 5. Die Fortsetzen-Taste ist in genau diesem Bild außerhalb des Ausschnitts; ihre hit_rect ist hier leer. Das wird ausdrücklich nicht als sichtbarer Fortsetzen-Nachweis ausgegeben. Die spätere tatsächlich protokollierte Wiederaufnahme wird durch den Eingabe-/Zustandsbericht belegt, nicht durch diesen Screenshot. Nicht alle bedienbaren Inhalte sind gleichzeitig sichtbar; der bestehende Scrollmechanismus ist erforderlich. |
| quiz-dart-complete.png | 1200×896 | Die zwanzigste Frage des Logik-Finales und alle vier Antworten sind vollständig lesbar; C „Lea“ ist grün markiert. „Richtig!“, „5000 Sterne gutgeschrieben“ und „Alle 20 Fragen geschafft!“ sind deutlich sichtbar. „Neue Runde“ und alle vier Fachwahlen sind sichtbar. Lumo steht vollständig sichtbar auf dem Podest mit erhobenen Armen; die zwanzig Lichter des Bogens erscheinen gelb. Die sichtbare Gutschrift stammt hier aus dem ausdrücklich deklarierten QA-Ledger. Sie belegt keine Android-AppState-/SharedPreferences-Auszahlung. Das Bild belegt keinen Klang, keine neue Sprachsynthese und keine Geräte-FPS. |

Alle sechs Bilder wurden neu mit `view_image` geöffnet. Es wurde **kein neuer visueller Blocker** festgestellt. Die vollständigen SHA256-Werte, Sidecarbindungen und Befunde stehen in `image-review.json`.

Die sichtbare Grenze des Pausenbildes wird ausdrücklich erhalten: Die Fortsetzen-Taste liegt in genau diesem gescrollten Standbild oberhalb des Clipbereichs. Der Sidecar weist deshalb eine leere Trefffläche aus. Erst der spätere reale Scroll-/Tapverlauf erreicht die Taste mit dem tatsächlichen Rechteck **376×52** und demselben Rundentoken. Der Screenshot wird nicht als Beleg eines darin sichtbaren Fortsetzen-Buttons dargestellt.

## Abnahmegrenze und Speicherung

Der Paarlauf verwendet produktive Dart-Regeln, Fragebank, Controller/Session und Godot-Szene, aber einen deklarierten QA-Dateitransport und eine QA-Belohnungsablage. Er belegt weder Android-Binder/APK-Verhalten noch eine Auszahlung im AppState/SharedPreferences-Pfad, Geräteleistung oder physische FPS. Es wurde kein Ton gehört und keine EN/DE-Modellinferenz beurteilt. Die Kulisse bleibt ein schlichtes Podest mit Bogen; eine umfassende visuelle Fertigstellung wird nicht behauptet.

Originale, Metadaten und ZIP-Bindung waren vor dem Umgebungsausfall lokal gesichert. Diese drei neuen Reviewtexte wurden danach ausschließlich aus bereits gelesenen Befunden als vollständige UTF8-Strings im Sitzungsspeicher erstellt; ein lokaler Schreibabschluss wird nicht behauptet. Keine Produkt-, Workflow-, Test-, Ref-, Tree- oder Commitmutation; keine zusätzliche Aufnahme und kein Testwiederholungslauf.

## Dauerhafte Textübergabe

Quellen: [aktueller Job](https://github.com/Ullmann27/lumo-lernen/actions/runs/43619285124/job/132521067495), [Host b721](https://github.com/Ullmann27/lumo-lernen/commit/b7210db3f53361987fd33592de438fd7984d991a), [Native 29080](https://github.com/Ullmann27/lumo-godot/commit/29080ef8cd1a5b385eeeec97976fbefd31280427), [Artefaktmetadaten](https://api.github.com/repos/Ullmann27/lumo-lernen/actions/artifacts/14124000432).

Der neue Git-Blobhandoff umfasst ausschließlich diese drei Reviewtexte, die drei vollständig im Sitzungsspeicher erhaltenen Originaltexte (terminaler Job-Metadatenabruf, damaliger Artefakt-Metadatenabruf und vollständiger Joblog) sowie das neue Manifest. Die 35 entpackten Originaldateien, die sechs PNGs und das ZIP werden damit **nicht als in Git gesichert** ausgegeben. Der Metadatenabruf ist ein endlicher Snapshot; sein erfolgreicher Quizjob bedeutet keinen Gesamterfolg der übrigen Jobs.
