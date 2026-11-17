# Neue Flutter-Abnahme auf 1e22d245

Dieser Nachweis gehört ausschließlich zu Host `1e22d2455937e2640d1e44e153d290746f3afe49`, Tree `7fcc3748f8178bff91176ff27f11f7e86ca165ca`.

## Neuer Home-Lauf

Run `43596913225`, Attempt 1, Job `132453271395` ist erfolgreich abgeschlossen. Das unveränderte Joblog enthält 13 erfolgreiche Home-Prüfungen und 8 erfolgreiche Welten-Prüfungen. Der tatsächliche Checkout war der PR-Mergecommit `67ab955d0844b9021090bf019a798611d1f0f56f`; dessen GitData-Tree stimmt exakt mit dem Host-Tree überein.

Das neue Originalarchiv `14115111878` wurde einmalig heruntergeladen. Seine 17.097.348 Bytes und SHA256 `4681a6b646cfa2f643a75ff78f4e77a52090c125f4cdbfdab8b70596745742e3` stimmen mit der GitHub-Metadatenantwort überein. Alle ZIP-Mitglieds-CRCs und die acht PNG-Hashes/Abmessungen wurden geprüft. Es wurden keine Bilder bearbeitet.

Alle vier Auswahlbilder wurden vom unabhängigen Android-QA-Agenten tatsächlich geöffnet, ebenso der Cover-Start. Sein Befund: Mathe ist in allen vier Auswahlbildern vollständig lesbar; das aufgeklappte Fold zeigt das Fachraster ohne Überdeckung, große Schrift keine Titel-/Textkollision. „Belohnungen“ ist auf dem Cover-Start vollständig sichtbar. Nachfolgende Karten können an den dokumentierten Scrollrändern abgeschnitten sein; es wird keine Vollsicht aller Karten auf jedem Ausschnitt behauptet.

## Vollständige neue Flutter-Abnahme

Der C4-Gesamtlauf `43596913210`, Attempt 1, Job `132454178537` hat den vollständigen Flutter-/Capture-Abschnitt erfolgreich abgeschlossen: **2.627 PASS, 0 FAIL, 0 SKIP, 566 erzeugte PNGs**. Die unveränderte Runner-Summary, das vollständige originale `flutter-machine.jsonl`, die unabhängige Neuzählung, die tatsächlich ausgeführte Archivprüfung und ihre Rohlogs liegen unter `full/`. Die drei zuvor fehlerhaften Diktatfälle sind in den tatsächlichen `testDone`-Ereignissen erfolgreich; ebenso die exakte kumulative Mathematikauswahl und der verzögert abgelehnte native C4-Einstieg.

Das einmalig geladene Originalartefakt `14115282912` enthält 363.833.462 Bytes. Sein eigener SHA256 `81132f79c596df4a70f87f4a39b3cebe8fb3405384d34a471cb40c8416d4b6ab` stimmt mit den GitHub-Metadaten überein. Alle ZIP-Mitglieds-CRCs wurden geprüft. Die 566 PNGs wurden anhand der Originaldateien nachgezählt und gehasht; dies ist keine Behauptung, dass sämtliche 566 Bilder visuell geprüft wurden oder ihren Dateinamen entsprechend den beabsichtigten Spielzustand zeigen.

### Dorf: sechs tatsächlich betrachtete Originale

Alle sechs neuen Dorf-PNGs wurden direkt und unbearbeitet geöffnet. „Dorfwirtschaft“ ist jeweils vollständig in einer Zeile sichtbar. Bei 640 dp sowie 690 dp mit größerer Schrift werden zwei Hauptspalten verwendet; 690 dp mit normaler Schrift und die Queransicht bleiben dreispaltig. In diesen sechs Ausschnitten wurde keine blockierende Titel-, Avatar- oder Schaltflächenüberdeckung festgestellt. Untere Karten dürfen außerhalb des dokumentierten Scrollausschnitts fortgesetzt sein. Die Originalbytes sind unter `full/village-original-pngs/` gesichert.

### Vier gewinnt: alte Beleglücke und getrennte aktuelle Brettbelege

Die vier älteren `games/connect_*`-Aufnahmen aus der Vollsuite sind **alle ungeeignet als Zug- oder Siegbeleg**: Die Phone-Übersicht zeigt ein leeres Brett, die drei weiteren Aufnahmen einen Pausedialog. Die beiden Fold-Bilder sind sogar bytegleich. Die ursprüngliche Testfixture wartet nur eine feste kurze Zeit und prüft die tatsächlich gespielten Felder oder eine Gewinnlinie nicht; 30 echte Missed-hit-Warnungen wurden im Original-JSONL aufgezeichnet. Originalereignisse, Zeilennummern, Quellblobs und die vier unveränderten Bilder sind gesichert. Der genaue asynchrone Auslöser des Pausezustands wurde im Ursprungslauf nicht instrumentiert; daraus wird kein unbewiesener Laufzeitfehler abgeleitet.

Die anschließende dedizierte C4-Stufe 27 lief von 13:19:39 bis 13:19:47 UTC erfolgreich. Ihr eigenes Artefakt `14116190611` (`lumo-1981-real-flutter-captures`) wurde einmalig geladen: 38.336.679 Bytes, SHA256 `94d641676e8eb11e6c7b40598960013efccc3c134fcc06fdc83381e696ad999f`, sämtliche ZIP-Mitglieds-CRCs geprüft. Alle fünf daraus stammenden C4-PNGs wurden tatsächlich geöffnet. 360×800, 640×360, 1280×720, 740×840 und 1200×896 zeigen jeweils ein unpausiertes Brett mit sieben alternierenden Steinen in der unteren Reihe (vier Cyan, drei Gold), sieben Pfeilsteuerungen und „Gold ist dran!“. Diese Bilder belegen den gespielten Brettzustand, **keinen Sieg**. Der aktuelle dedizierte Test prüft die tatsächlichen sieben Züge, die Bereitschaft und die mindestens 48 dp großen Ziele. Seine Originale und separate Herkunft stehen unter `dedicated-c4/`.

Der Evidenzcheckpoint verändert keine Produkt-, Test- oder Workflowdatei und führt keinen neuen Flutter-Test aus. Der übergeordnete Buildjob war beim hier gespeicherten API-Snapshot noch in Arbeit; eine APK-/Android- oder vollständige Pipeline-Abnahme wird damit nicht vorweggenommen. Das komplette terminale Joblog wird vereinbarungsgemäß ausschließlich vom Android-QA-Agenten einmalig abgerufen.

## Neuer Living-Lauf: eigenständiger Nachweis mit ausgewiesenen Skips

Run `43596913164`, Attempt 1, Job `132453271203` ist am 14.11.2026 um 13:03:03 UTC erfolgreich abgeschlossen. Das Originaljoblog bestätigt den direkten Checkout von `1e22d2455937e2640d1e44e153d290746f3afe49`. Die Core-/Routenstufe meldet in Zeile 596 **48 PASS**. Die anschließende Regression meldet in Zeile 3637 **2.425 PASS und 202 SKIP**, ohne Fehler. Die Skips werden nicht als ausgeführte Erfolge gezählt.

Das Originaljoblog und die unveränderte Artefaktmetadatenantwort sind gesichert. Das Living-ZIP wurde nicht zusätzlich heruntergeladen; dessen gemeldeter Digest ist deshalb eine GitHub-Metadatenangabe und kein eigener lokaler Archivhashnachweis. Der maßgebliche C4-Lauf mit eingeschalteten Captures bleibt für die vollständige Abnahme erforderlich.
