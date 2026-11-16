# Supplemental 2031: sichtbare Silbenleiste vor dem Aufgabenwechsel

## Tatsächlicher Ausgangsbefund

Der ursprüngliche Supplemental-Lauf **43812538819**, QA-Quelle
`e4c9b16751b4db2b1486fd58361000954f89fa11`, bleibt **FAIL**. Verwendet wurde die
unveränderte APK-Quelle `e05a96a52aaf57e466e79831f15aaffd144284ee` / Native
`678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Die gespeicherten Zahlenabgaben
15 und 16 waren bereits geprüft; der anschließende Wort-Aufgabenwechsel und
die beiden späteren nativen Zusatzfälle waren nicht erfolgreich abgeschlossen.

Originalartefakt: **14201531176**, **15.469.393 Bytes**, SHA256
`8290ce1dfcd5779df8e2de1c3900fb8eada31ed6f48cf7236c23ad666da1dac8`.
Die beiden ZIP-Teile und die vollständige Prüfung aller 539 Mitglieder liegen
unverändert unter `docs/nextgen/evidence/ci-2031-runtime-cases-active-observation-failure/`.
Für diesen Fix wurden nur fünf kleine Originaldateien bytegleich unter
`tools/android_qa/tests/fixtures/nextgen_active_syllable_43812538819/` übernommen.
Ihr Manifest enthält die Originalpfade, Größen, Einzelhashes und Herkunft.

### Was die tatsächlichen Beobachtungen zeigen

Alle **270 XMLs** `0213` bis `0482-switch-live-active-and-next.xml` enthalten
den sichtbaren, aktivierten Knopf **„Jetzt selbstständig antworten“**: **246**
Beobachtungen bei `[83,858][998,1001]`, **24** bei `[83,918][998,1061]`
(beispielsweise `0226-switch-live-active-and-next.xml`). Sie enthalten
**keinen einzigen individuellen Silbenknoten**,
weder aktiv noch inaktiv. Das selbst betrachtete Originalbild
`0483-runtime-failure-current-screen.png` zeigt ebenfalls den unteren Teil der
Werkbank, den Weiter-Knopf und die Gesprächsaktionen; die Silbenleiste liegt
oberhalb dieses Ausschnitts. Sein SHA256 lautet
`c4f60e3e2c41b1d6077c185a9f9c56fffc628fd47aae15c89f3eaad406b80658`.

`original-observation-manifest.json` enthält alle 270 Originalnamen, Größen,
SHA256-Werte und die beobachteten Next-Bounds. Es gibt drei XML-Hashes mit den
Häufigkeiten **101, 24 und 145**. Die vollständigen XMLs bleiben im Original-ZIP.

Der alte Beobachter scrollte nur, wenn Next fehlte. Weil Next sichtbar blieb,
wartete er bis zum unveränderten 45-Sekunden-Ende am falschen Seitenausschnitt.
Die fehlenden Silbenknoten belegen diese Beobachtungslücke. Sie belegen **nicht**,
dass die Stimme ausgefallen wäre; der Ausschnitt erlaubt keine solche Aussage.

### Warum bloßes Scrollen vor Replay nicht ausreicht

Die Originalgeometrie lässt sich an identischen tatsächlichen Ankern vergleichen:

| Original-XML | Silbe Ba | Ba auf Platz 1 | ri im Vorrat | Modell prüfen | Next | Replay |
|---|---|---|---|---|---|---|
| 0199 | y945–1127 | y1737–1876 | y2054–2193 | außerhalb | noch nicht vorhanden | außerhalb |
| 0200 | außerhalb | y545–684 | y862–1001 | y1226–1369 | noch nicht vorhanden | y1713–1856 |
| 0204 | außerhalb | y545–684 | y862–1001 | y1226–1369 | y1402–1545 | y2258–2274, geclippt |
| 0213 | außerhalb | außerhalb | y318–456 | y682–825 | y858–1001 | y1713–1856 |

Der ScrollView misst in diesen Originalen `[0,290][1080,2274]`, also 1984 Pixel
Höhe. Zwischen 0199 und 0200 verschieben sich beide Werkbankanker exakt um
1192 Pixel. Zwischen 0200 und 0204 bleiben diese Anker und der Modellknopf
gleich; Next und Feedback kommen hinzu. Daraus ergibt sich für dieselbe
Layoutposition eine Silbenunterkante bei y−65 und eine Replayoberkante bei
y2258: Bereits der Zwischenraum ist größer als der Viewport. Diese abgeleitete
Relation beschreibt die aufgezeichnete Ansicht; sie wird nicht als neue
Androidbeobachtung ausgegeben und liefert keine zukünftigen Tappkoordinaten.

## Eng begrenzte QA-Korrektur

Nur die neue Supplemental-Probe und ihr bestehendes Testmodul ändern sich.
Die gemeinsame Originalprobe, ihr Recorder, native Helper, Appquellen,
Publisher und die vollständigen Replay-Gates bleiben unverändert.

Für genau den Wort-Aufgabenwechsel wird die echte Emulatordichte vorübergehend
auf **320 dpi** gesetzt, bei unveränderten **1080×2340 Pixeln**. Der ursprüngliche
WM-Wert muss eine größere Dichte aufweisen. Das ist eine größere **logische
Emulatoransicht**, keine physische PPI-Angabe, keine Fold7-Hardwareprüfung und
kein Nachweis dieses Falls in der ursprünglichen Dichte.

Die Probe sichert originale und geänderte WM-Rohwerte, tatsächliche PNGs sowie
identische fertige Banane-Checkpoints und Profil-/Lerndaten. Vor der einzigen
neuen Wiederholung müssen alle drei Silben, Next und Replay gemeinsam in einem
aktuellen sichtbaren ScrollView liegen. Kleine Vorbereitungsgesten werden nur
aus dessen jeweils beobachteten Bounds berechnet; es gibt keine aus Quellcode
oder historischen Bildern übernommenen Tappunkte. Die Vorbereitung ist auf
45 Sekunden und 30 Gesten begrenzt.

Nach einem Screenshot liest die Probe die gemeinsame Ansicht noch einmal
frisch und bedient Replay direkt an dessen beobachteten Bounds. Ein erneuter
suchender `tap()` kann sie daher nicht wieder vom Silbenbereich wegscrollen.
Die vollständige Erfassung bis zum angeforderten Replay-Tap darf höchstens
eine Sekunde dauern. Die anschließende ursprüngliche Aktivprüfung bleibt
unverändert: aktive Silbe und aktivierter Next-Knopf müssen im selben frischen
XML stehen, die gesamte Erfassung bis zum angeforderten Next-Tap darf höchstens
eine Sekunde dauern, und nach 45 Sekunden ohne Beleg ist der Fall FAIL.

Die ursprüngliche Dichte wird vor Verlassen der Wortaufgabe exakt auf ihren
beobachteten Override beziehungsweise mit `reset` zurückgestellt. Die Probe
verlangt die tatsächliche WM-Rückkehr, einen echten Screenshot und den weiterhin
unbeantworteten, unveränderten Rakete-Checkpoint samt Profil-/Lerndaten. Auch
bei Fehlern wird die Rückstellung versucht. Ein sekundärer Restore-Fehler wird
gesichert und verdrängt keinen bereits vorhandenen primären Fehler; bei sonst
erfolgreichem Ablauf bleibt ein Restore-Fehler ein harter Fehler.

Zusätzliche Ergebnisfelder unter `flutter_switch_during_syllable_playback`:

- `viewport`: originale, vorbereitete und wiederhergestellte WM-/PNG-/Datenbelege,
  `standard_density_case=false`, `physical_device_evidence=false`.
- `replay_preparation`: tatsächliche gemeinsame Kontroll-Bounds, Silbenlabels,
  XML-Datei/-Hash, Vorbereitungsbewegungen, Erfassungszeiten und genau ein Replay-Tap.
- Bei Rückstellfehlern: `viewport.restoration_error`; der ursprüngliche Fehler
  bleibt der Fehler des gesamten Laufs.

`verify_switch_viewport()` prüft diese Belege am Ende erneut. Die bestehenden
Numerik-, Lernstand-, Aktivitäts-, Video- und nativen Ergebnisgates werden
weiterhin angewendet. `verify_word_switch()`, `verify_numeric_submission()`,
`numeric_wrong_then_correct()` und `switch_on_active_syllable()` bleiben identisch.

## Tatsächlich ausgeführte Hostprüfungen und Grenzen

`viewport-red.log`: 16 registrierte Tests, genau **eine** erwartete Verletzung
des neu geforderten Ergebnisgates auf unveränderter Probe. Der konstruierten
Ergebnisfixture fehlte die gemeinsame Viewport-/Restore-Bindung; die bisherige
Prüfung akzeptierte sie. Das ist ein Host-RED, kein vorgetäuschter Android-RED.
Der separate Android-Ursachenbeleg sind die oben bezeichneten Originale.

`viewport-green-first.log`: erster enger Lauf **21/21**. Beim anschließenden
strengeren Besitzer-/Aufgabencheck erkannte die echte XML-Fixture eine
zusammengefasste mehrzeilige Flutter-`content-desc`; der betreffende Zwischenlauf
bleibt als `viewport-fixture-followup-failure.log` erhalten. Die Prüfung verwendet
nun exakte Textzeilen dieser echten Darstellung, entsprechend dem vorhandenen
`see(exact=True)`-Verhalten, ohne unscharfen Teilstringvergleich.

`viewport-green-final.log`: **21/21 PASS**. Geprüft wurden Originalfixture-Hashes,
fehlende/verdeckte/fremde/mehrdeutige Ziele, einmaliger direkter Replay-Tap,
verspätete Erfassung, unveränderte Fristen, echte Parserdarstellung als
`ET.Element`, positive und negative Ergebnisgates, Override-/Reset-Rückstellung
sowie primärer Bodyfehler zusammen mit sekundärem Restore-Fehler.
Transport- und vergrößerte Layoutfixtures sind ausdrücklich konstruiert.

Keine Androidausführung, kein neuer APK-Build und keine Remoteaktion wurden
für diesen Patch vorgenommen. Eine tatsächlich gemeinsame Ansicht bei 320 dpi,
aktive Wiedergabe während Next und die erfolgreiche Rückkehr der Dichte müssen
erst der neue echte Supplemental-Lauf belegen. Das ursprüngliche FAIL bleibt FAIL.
