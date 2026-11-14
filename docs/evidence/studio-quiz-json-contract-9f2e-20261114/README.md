# Quiz: tatsächlichen Dart-JSON-Vertrag korrekt darstellen

## Ausgangsfehler und Quellen

Der echte Paarlauf `43603969762`, Job `132474493736`, verband Native `9f2e865614262c7176f9fdd987766ff5e45f2551` mit Host `c0ca5265eb4159e6848317da5f49edabaa75bfa0`. Er scheiterte bei der ersten Antwortaufdeckung. Das Originalartefakt `14117811208` ist 296.547 Bytes groß; SHA256 `b1d4bb894083344f4a862fe2412df260759018b030378e06646c5247b68933cb`. Alle 26 ZIP-Mitglieder wurden auf CRC geprüft. Originale liegen separat unter `qa/studio-quiz-native-9f2e-ci-20261114/`; dieses Paket verändert sie nicht.

Die gespeicherte Originalfrage `e_sk_body_3` lautet „Womit riechen wir?“ und besitzt keine Erklärung. Dart hatte die echte Auswahl und Aufdeckung gespeichert: `recordRevision=6`, `ack=5`, `rejected=0`, `revealed=true`, `correctIndex=1`, `explanation=null`. Der native Presenter verlangte nach Aufdeckung dagegen zwingend einen String und nahm diesen gültigen Zustand nicht an. Der konkrete Fehler war damit keine fehlende Dart-Speicherung oder zusätzliche 300-Sekunden-Zeitüberschreitung.

Die beiden tatsächlichen früheren Layoutzustände enthalten `hidden=[2.0,3.0]`. Godots JSON-Zahlen trafen den bisherigen Vergleich mit ganzzahligen Schleifenindizes nicht. Dadurch blieben C/D sichtbar und im Presenter auswählbar, obwohl Dart sie bereits ausgeblendet hatte. Die drei Original-PNGs wurden bei der Diagnose einzeln geöffnet. Die unveränderten vier Original-JSON-Dateien sind die neuen Regressionfixtures; ihre Herkunft und Hashes stehen in `evidence/original-fixture-binding.json`.

## Enger Produktumfang

`scripts/games/quiz/quiz_studio.gd` akzeptiert für die weiterhin zwingend vorhandene Erklärung ausschließlich `null` oder den bereits begrenzten gültigen String. Bei `null` zeigt der tatsächliche Feedback-Control nur das Ergebnis, ohne erfundene Erklärung oder ausgegebenen Nullwert.

Die vorhandene Prüfung verlangt weiterhin eindeutige ganze Hiddenindizes 0 bis 3. Erst nach dieser Validierung vergleicht `_option_hidden` deren ganzzahligen Wert. Darstellung und Intentguard verwenden dieselbe Prüfung; die empfangenen JSON-Daten werden nicht umgeschrieben. Andere Erklärungsdatentypen, Nachkommastellen, Strings, doppelte oder außerhalb des Bereichs liegende Hiddenindizes bleiben ungültig.

Die übrigen Produktfunktionen einschließlich Token-/Owner-/Revisionsbindung, Ablauf des ACK, Speichern, Rückkehr, Lifecycle und Layoutpublikation bleiben bytegleich. Der exakte Funktionsvergleich und der vollständige Diff liegen in `evidence/source-function-boundary.json` und `evidence/final-implementation-against-exact-9f2e.patch`.

## Tatsächlich ausgeführte Gegenprüfung

| Endlauf | Produkt | Ergebnis |
|---|---|---|
| `red-original-render-final-v2` | unverändertes 9f2e-Produkt | Exit 1; 208 Prüfungen, 17 konkrete Fehler, neun Aufnahmen |
| `green-corrected-render-final-v2` | korrigiertes Produkt | Exit 0; 215 Prüfungen, kein Fehler, zehn Aufnahmen; 46,860 Sekunden Rendererzeit |

Beide Läufe verwenden denselben finalen Test. Er erhält sämtliche bisherigen Fixtureverträge und ergänzt die vier bytegleichen CI-JSONs, tatsächliche Touchversuche auf die ausgeblendeten Buttons, falsche Datentypen sowie den bestätigten Nullable-Zustand. Der tatsächliche spätere Dart-Paarpfad bekommt zusätzliche Hidden- und Nullable-Assertions; seine 20 Fragen, 15-Sekunden-Einzelgates, ACK-, Save-, Pause-/Resume- und Rewardbedingungen bleiben bestehen. Er wurde nach dieser Korrektur lokal nicht ausgeführt.

Alle neun gebundenen Laufzeitdateien sind im finalen grünen Runtimebericht vor und nach dem Lauf hashgleich. Die isolierte Umgebung basiert auf der wiederhergestellten Native344-Laufzeit mit den exakten Quiz- und Modellquellen; sie wird nicht als vollständiger sauberer 9f2e-Checkout ausgegeben. Verwendet wurden Godot 4.6.3, X11, Compatibility-Renderer und llvmpipe, mit ausdrücklich lokalem Fixture-Transport. Es gibt daraus keinen Android-, echten Dart-Paar-, Audio- oder Geräteleistungsnachweis.

## Bildsichtung und erhaltene Fehlversuche

Alle zehn PNGs des finalen grünen Laufs wurden einzeln geöffnet. `evidence/final-image-review.json` bindet jede tatsächliche Datei mit SHA256, Gitblob, Maßen und konkreten Grenzen. C/D zeigen in den originalen JSON-Zuständen ausschließlich „Ausgeblendet“. Der kompakte Nullable-Frame zeigt die grüne richtige Antwort und „Nächste Frage“; der Feedbacktext liegt dort unter dem Scrollclip und ist separat als tatsächlicher Controltext geprüft. Cutout- und kompakte Ansichten benötigen weiterhin reales Scrollen. Der angezeigte 5000-Sterne-Abschluss des ursprünglichen lokalen Fixtures ist kein Auszahlungsnachweis.

Der erste lokale QA-Entwurf hatte einen GDScript-Typinferenzfehler vor Testbeginn. Zwei spätere Orchestrierungsversuche brachen vor Godot ab, weil das Ausgabeverzeichnis vorzeitig angelegt worden war. Diese Protokolle bleiben unverändert erhalten und zählen nicht als Produktgegenläufe. Der erste ausgeführte 207/17- bzw. 214/0-Durchgang bleibt historisch erhalten. Bei dessen Bildprüfung fiel die noch sichtbare alte CanvasLayer-UI auf; ausschließlich die neue Replay-Fixture versteckt sie nun ausdrücklich und prüft dies. Erst die oben genannten finalen Läufe und Bilder bilden den Abschlussstand.

## Übergabe

`source-upload-manifest.json` enthält genau sechs Nativequellen: den engen Produktfix, den additiven Runtime-Test und vier Original-JSON-Fixtures. Alle sechs wurden als unveränderliche Gitblobs in `Ullmann27/lumo-godot` angelegt und vollständig bytegleich zurückgelesen; `confirmed-source-tree-inputs.json` und `source-blob-upload-proof.json` enthalten die bestätigten Angaben. Keine Trees, Commits, Refs oder PRs wurden durch diesen Auftrag geändert. Die unabhängige Leseprüfung durch Agent A liegt separat unter `qa/studio-quiz-json-independent-review-9f2e-20261114/`.
