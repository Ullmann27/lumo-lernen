# Aktuelle C4-Hubnavigation: exakter Titel und frische Eingabebindung

Dieses Paket korrigiert ausschließlich die Android-QA-Probe auf Host
`8e64f27c86e1704fa65dfe9ef9c8b2217f9f0a11`. Der ausgeführte alte Androidlauf
`43626348519`, Job `132563694518`, verwendete Host
`28462a7547048b75fa114e6f5832248e54c94faa` und Native
`29080ef8cd1a5b385eeeec97976fbefd31280427`. Die betreffende Probe ist zwischen
diesen beiden Hostständen bytegleich. Der alte Androidlauf bleibt FAILURE.

## Konkreter Originalbefund

Die Probe suchte mit dem exakten Titel `Vier gewinnt`. Der produktive Hub
verwendet dagegen `Lumo 4 Gewinnt` als Semantiktitel. Der vorhandene gemeinsame
Selektor verlangt den Titel am Anfang der vollständigen Semantikzeile. Die
Originaldatei `connect-four/0006-actual-c4-hub.xml` enthält genau
`Lumo 4 Gewinnt. Vier in einer Reihe · gegen Lumo oder zu zweit Spielen` an
`[42,1072][524,1536]`. Das zugehörige aktuelle PNG wurde persönlich geöffnet:
Die ganze Kachel „4 Gewinnt“ und ihre Brettgrafik sind sichtbar und lesbar.

Scrollen hat im ursprünglichen Lauf nachweislich funktioniert: Der obere
Viewport enthält die Kachel noch nicht, die Originalzwischenbilder und XMLs
ab 0005/0006 enthalten sie. Das alte Eingabejournal enthielt keine Scrollzeilen,
weil der alte Code die ausgeführten Swipe-Aufrufe dort nicht protokollierte.
Aus dieser fehlenden Protokollierung folgt ausdrücklich kein Ausbleiben der
ADB-Geste. Die bisherige Gestengeometrie stammt bereits aus dem aktuellen
Screenshot und den tatsächlichen ScrollView-Grenzen; sie bleibt erhalten.

Die beiden neuen XML-Fixtures sind byteidentische ausgewählte Originalmitglieder
aus dem Root-seitig per geprüften HTTP-206-Ranges gelesenen Artefakt
`14130101135`. Dessen API meldet 196404454 Bytes und SHA256
`bfddd9c10504e2271a8b785bd3a46aef4ec76c3fab80bdd2dadea6162ea58e0b`.
Es wird kein vollständiger lokaler ZIP-Hash-/CRC-Check behauptet. Die vollständigen
ausgewählten Mitglieder haben eigene CRC-/SHA-Bindungen in der Fixtureprovenienz.
Root archiviert Originaljob, Bilder und Transfernachweise; dieses Paket lädt sie
nicht nochmals als Evidenz hoch.

## Enger Patch

Der C4-Selektor erhält den tatsächlichen Titel. Vor einem Hub-Tap werden die
Semantikzeile und Bounds nach dem Screenshot nochmals aus einem frischen UI-Baum
bestätigt, außerdem muss weiterhin MainActivity im Vordergrund stehen. Vor einer
Scrollgeste müssen die frisch gelesenen Viewportgrenzen übereinstimmen. Das neue
Scrolljournal hält Ausgangsbild, bestätigtes XML, Viewport, Start/Ziel und die
unveränderten 450 ms fest. `adb_completed` wird erst nach erfolgreicher Rückkehr
des tatsächlichen ADB-Aufrufs wahr; bei einer Ausnahme bleibt der Versuch falsch
und der Fehler wird weitergereicht.

Alle anderen 37 Funktions-/Methodendefinitionen sind textgleich. Der ursprüngliche
30-Sekunden-Vorlauf zur tatsächlichen Hubroute bleibt bytegleich. Die anschließende
bereits vorhandene Hubsuche behält beide Richtungen, je elf Beobachtungen, maximal
zehn Gesten pro Richtung, 450 ms und 0,6 s Pause. Dieser bisherige Abschnitt ist
versuchsbeschränkt; eine globale 30-Sekunden-Grenze für die gesamte Hubsuche wird
nicht neu behauptet. Die 48-dp-Anforderung sowie APK-/PCK-/Quell-, Spiel-, Pause-,
Lease-, Speicher-, Wiederöffnungs- und Rückkehrprüfungen sind unverändert.

## Tatsächlich ausgeführte gezielte Prüfung

Der neue Original-XML-Replay wurde mit der unveränderten alten Probe ausgeführt:
ein Fall, Exit 1, `Actual C4 hub tile never appeared`. Mit der neuen Probe bestehen
alle elf Fälle, Exit 0, kein Skip; dazu gehören die fünf vollständig unveränderten
bisherigen Navigationsfälle. Der positive Replay durchläuft den oberen Original-
Viewport, eine Geste innerhalb `[0,136][1080,1993]` und danach die tatsächliche
sichtbare C4-Kachel. Negative Fälle verwerfen geänderte Bounds, Activity-Wechsel,
geänderte Viewports und fehlgeschlagene Gesten.

Die Tests benutzen echte unveränderte XML-Daten und den tatsächlichen gemeinsamen
Produktionsselektor. ADB, Capturetransport und die aus dem Original bekannte
Bildgröße sind bewusst Testdoubles. Dies ist kein neuer Androidlauf, kein OCR-
Erfolg und kein Renderer-/FPS-Nachweis. Es wurde kein Dart/Flutter ausgeführt.
Die erste neue Activity-Testfixture wechselte den Vordergrund eine Beobachtung
zu früh und traf korrekt den früheren Schutz; dieser ursprüngliche fehlgeschlagene
Testlauf bleibt in `evidence/execution.json` samt Rohlog erhalten. Nur das Double
wurde korrigiert; die Probe blieb dabei unverändert. Der finale gebundene Lauf
steht in `evidence/execution-final.json` mit exakten Kommandos und Quellen vor/nach.

## Übergabe

`source-upload-manifest.json` nennt genau fünf zu integrierende Quellen:
Probe, vorhandene Testdatei, zwei Original-XML-Fixtures und deren Provenienz.
Die lokale Kopie des gemeinsamen Creative-Helfers sowie die sieben alten
Fixtures sind lediglich unveränderte Prüfabhängigkeiten. Keine Produktdatei,
kein gemeinsamer Helper und keine Gitreferenz wird durch dieses Paket geändert.
Die bestätigten Source-Blob-IDs stehen in `source-confirmed-tree-inputs.json`,
der vollständige Readback-/Nachhashnachweis in `source-blob-upload-proof.json`.
Die separate unabhängige Peernote steht am kanonischen Ziel
`docs/evidence/studio-c4-hub-caption-peer-review-8e64-20261114/review.json`,
SHA256 `fb86f60c90585fb2650abbbe6a359096c72253bb9292b72e0fe72c238c95a71f`.
Sie meldet keinen zusätzlichen konkreten Blocker, keine eigene Testwiederholung
und keinen neuen Androidnachweis.
