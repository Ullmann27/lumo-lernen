# Gas-Beschriftung nach Scrollverlust · neue Wiederherstellung1906

Status: **RECONSTRUCTED_NEW_SOURCE / VISUAL_GAP / NOT FINISHED**.
Dieses Paket wurde nach dem Verlust des ursprünglichen Arbeitsbereichs neu
geschrieben und neu geprüft. Alte lokale Gas5-/436-/47-Nachweise gelten nicht
für diese neuen Dateibytes. Eine neue Android-Ausführung ist **NOT EXECUTED**.

Veröffentlichte App-Basis: `f6c4f3350db8153200594b52a9d82606279dc238`.
Die beiden Ausgangsproben wurden aus dieser Basis bytegenau wiederhergestellt.
Die unabhängige Veröffentlichung, RESULT SHA, finaler Godot-Pin und neue APK
bleiben Aufgabe der übergeordneten Integration. Dieses Paket verändert weder
Produktphysik noch Spiel-UI, Belohnungen, Ergebnis-ACK oder gespeicherte Rennen.

## Belegter Auslöser und neuer reproduzierbarer Test

Der übergeordnete Integrator hat den historischen tatsächlichen1905-
[Kart36-Job113557082644](https://github.com/Ullmann27/lumo-lernen/actions/runs/37846382465/job/113557082644)
erneut gelesen: Die äußere Fullrace-Suche beobachtet die vollständige
Gas-Beschriftung, danach verlieren die frischen Aufnahmen der eigentlichen
Tastendruckprüfung diese Beschriftung durch den Settings-Scroll. Die erhaltene
`native_tap` wartet ohne Scroll-Recovery bis zu ihrer120-Sekunden-Frist.
Dieser historische Fehler ist kein neuer Android-Lauf.

Der neue Regressionstest führt die tatsächliche verschachtelte
Fullrace-`tap_native` und die tatsächliche creative-`native_tap` aus. Eine initiale
exakte Gas-Beobachtung wird in kontrollierten Folgeaufnahmen verloren. Auf der
unveränderten f6-Basis endet der Test mit dem tatsächlichen Timeout aus
`native_tap`: **1 Test / 1 ERROR / Exit1**, erwartetes RED. Dieselbe Testmethode
besteht nach der Ergänzung unverändert: **1 PASS / Exit0**, GREEN.
Methoden-AST-SHA256:
`68c86b75a26a86429d4fcc11917ca5d88214464fc706e921a35d959dba231703`.

Die erzeugten PNGs, OCR-Zeilen, Uhr und Eingaben sind ausdrücklich synthetische
Unit-Fixtures. Sie belegen den Kontrollfluss und seine Grenzen; sie belegen
keinen Emulatorstart, keine APK und keine reale Fahr- oder Grafikqualität.

## Enge Ergänzung und erhaltene Gates

`creative.native_tap` erhält den optionalen Hook `missing_caption=None`.
Der Standardpfad bleibt erhalten. Der Hook läuft nur nach einem vollständigen
akzeptierten aktuellen Bild und nachdem OCR die angeforderte Beschriftung
nicht gefunden hat. Er erhält dieselbe absolute native Deadline und die
unmittelbar vorherige fehlende, akzeptierte Aufnahme. Partielle Bilder und
zwischenzeitlich beobachtete Zieltexte setzen diese Kette zurück.

Nur die Kombination **exakt `Gas: GAS-Taste halten` / Pause / ursprünglich
`scroll='down'`** erzeugt eine Recovery. Andere Labels, Menüs, Richtungen,
Schatzsuche und Puzzle behalten ihren ursprünglichen `native_text`-Aufruf.
Der Gas-Pfad setzt die native Frist auf `min(120, verbleibende äußere180s)`.
Es entstehen kein zusätzlicher120-Sekunden-Loop und keine neue OCR-/Capture-
Schleife innerhalb der Recovery.

Die Recovery verwendet die erhaltenen `scroll_observation` und
`stable_scroll_observation` mit Richtung `up` und Kontext `pause`. Zwei
getrennte frische vollständige Aufnahmen müssen Modalinhalt, geordnete
beobachtete Fußzeile und Geste innerhalb des Inhalts bestätigen. Gleicher
Dateiname oder nicht fortschreitender Aufnahmezeitpunkt zählt nicht als
frische Aufnahme. Die vorherigen und aktuellen gespeicherten PNG-Bytes müssen
vor Eingabe noch zu ihren Digests passen; der aktuelle Digest wird zuletzt
unmittelbar vor der begrenzten Swipe-Eingabe geprüft. Maximal **zwei** Recovery-
Swipes sind erlaubt, und nach jeder Eingabe ist ein neues Aufnahmepaar nötig.

Nach dem Scroll bleiben zwei frisch beobachtete exakte Gas-Zieltexte,
unveränderte Zielgeometrieprüfung, aktueller PNG-Digest und der bisherige
einmalige120-ms-Tastendruck erforderlich. Kein alter Treffer autorisiert einen
Tastendruck. Keine festen Touch-Koordinaten, erfundenen Captions oder
Anwendungsdaten werden eingebracht. Die vorhandene anschließende Anzeige
`Gas: automatisch` bleibt als unabhängige Konsequenzprüfung erforderlich.

## Neue Prüfzahlen und Quellen

| Prüfung | Neues tatsächliches Ergebnis |
| --- | --- |
| Identischer Regressionstest auf f6 | erwartetes RED:1 Test /1 ERROR / Exit1 |
| Identischer Regressionstest mit Änderung | GREEN:1 PASS / Exit0 |
| Neue Gas-Recovery-Guards einschließlich Regression |33 PASS /0 FAIL /0 ERROR /0 SKIP / Exit0 |
| Unveränderte NativeSurface-Guards |16 PASS /0 SKIP / Exit0 |
| Unveränderte KartComplete-Evidence-Guards |54 PASS /0 SKIP / Exit0 |
| Unveränderte NativeOCR-Tiles-Guards |10 PASS /0 SKIP / Exit0 |
| Unveränderte Capture-Integrity-Guards |2 PASS /0 SKIP / Exit0 |
| Neue Android-/APK-/Fold-/Performance-Ausführung |NOT EXECUTED |

Alle48 wiederhergestellten ursprünglichen QA-Test-/Fixture-Dateien wurden vor
und nach den82 fokussierten Originalprüfungen gegen
`BASELINE-RESTORED-INVENTORY.jsonl` auf Größe und SHA256 geprüft: unverändert.
Die neue33er-Probe prüft unter anderem verschobene/geclippte/fehlende Fußzeilen,
partielle oder alte Bilder, beide veränderten PNG-Quellen, Ablauf derselben
Frist, maximal zwei Swipes, unterbrochene Bildketten, Standardverhalten und
andere Beschriftungen. Eine Gesamtsuite wird separat auf dem vollständigen
neuen Integrationsstand ausgeführt; historische Summen werden nicht übernommen.

Quellen sind ausschließlich die byteverifizierten vorhandenen f6-Proben und
ihre vorhandenen Guards. Es wurde kein fremder Code übernommen. Die drei
Scrollfunktionen sowie creative-`image_lines`, `capture` und `native_text`
bleiben AST-identisch. Geänderte Dateien: die beiden Probe-Dateien,
`tools/android_qa/caption_scroll_recovery.py`,
`tools/android_qa/tests/test_gas_caption_scroll_recovery.py` und diese Übergabe.

Neue geschlossene Belege liegen unter
`tools-runtime/final-1906/recovery-gas-caption/`: ursprüngliche Basisbytes,
RED-Log, unveränderte GREEN-Regression,33er-Log und vier Original-Logs.
Keine Git-/Remote-Mutation, SDK-Installation, ADB- oder GL-Ausführung wurde
durch dieses Paket durchgeführt. SDK-Recovery-Dateien und ihre Belege wurden
nicht verändert.

Nächster Integrationsschritt: neue unabhängige Quellenprüfung und vollständige
lokale QA, danach exakt gepinnte APK bauen und auf Android die Gas-Umschaltung,
das gesamte Rennen, Ergebnis, ACK, einmalige Belohnung, Offline-Wiederaufnahme
und sichtbare Flutter-Rückkehr erneut nachweisen. Grafik-/Referenztreue und
Zielgeräteperformance bleiben **VISUAL_GAP / NOT FINISHED**.
