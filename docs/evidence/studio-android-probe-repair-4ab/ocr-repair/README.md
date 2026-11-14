# Enger OCR-Folgefix für die unveränderten Android-Originale 4ab/803

## Befund und tatsächlich ausgeführter Vergleich

Run **43530667812** scheitert auf API35 und API37 vor der ersten Lernobjektbewegung: „Ein Objekt zeigen“ ist auf den Originalbildern sichtbar, wird aber vom bisherigen Screenshotleser nicht exakt erkannt. Es erfolgt kein Blindtap. Cards bleibt unerreicht. Die roten Originalberichte bleiben unverändert in den getrennten Android-Evidenzpaketen.

Der neue, unveränderte Vierer-Fixturetest wurde zuerst auf dem exakten bisherigen Reader ausgeführt: **4 Tests, 4 Fehlerbefunde (Assertion-Failures), 23,834s**. Auf der isolierten Reparatur bestehen **12/12 Fälle in15,795s**, einschließlich derselben vier bytegleichen Originalbilder und acht strenger Fehler-/Geometrie-/Fristfälle. Die drei unmittelbar betroffenen vorhandenen OCR-/Surface-Testmodule bestehen zusätzlich mit **34/34 Fällen in5,906s**.

Vier gesondert protokollierte echte Gesamtleser-Replays erkennen jeweils den unveränderten Text mit tatsächlichen Wortbounds `[104,2029,467,2071]` und minimaler Konfidenz95,722694. Die vollständigen Leseraufrufe dauern lokal3,660–4,185s. Diese Koordinaten sind **Ergebnis des aktuellen OCR-TSV**, keine feste Zielvorgabe im Reader. Die Originalhashes stimmen vor/nach jedem Lauf überein.

## Änderung und Grenzen

Der zusätzliche Fallback ermittelt zusammenhängende Goldflächen über das gesamte aktuelle Bild. Erst deren unveränderte RGB-Pixel werden mit Textblock-Segmentierung PSM6 gelesen. Die Fläche allein darf keine Eingabe autorisieren. Exakter Text, Konfidenz, Wortkoordinaten, Cropkantenprüfung, vollständiger aktueller Frame und die zweite stabile Aufnahme bleiben zwingend. Die20 anderen bestehenden Funktionen, einschließlich `native_tap` und `native_text`, sind AST-gleich. Die120-Sekunden-Gesamtfrist bleibt unverändert; der neue Reader nutzt höchstens15Sekunden daraus.

Die einfacheren Ganzbildvarianten raw1x/contrast1x wurden mit beiden Sprachmodellen auf allen vier Originalen tatsächlich erfolglos überprüft und nicht eingebaut. Frühere lokale Untersuchungen verwendeten wegen eines fehlenden deutschen Systemmodells nur das vorhandene Englisch; sie sind ausdrücklich kein sprachgleicher CI-Nachweis. Die endgültigen Rot-/Grünbelege verwenden die bereits vorhandenen, in `ocr-environment.json` gehashten deutschen und englischen Modelle. Der lokale Tesseract ist5.5.0, das CI-Paket5.3.4-1build5. Der echte Android-Gegenlauf bleibt erforderlich.

Es wurde kein App-, Native-, Branch-, Pin-, Receipt- oder CI-Stand verändert. Alle sechs neuen Quell-/Fixturedateien liegen isoliert; Root integriert sie ausdrücklich. Die vier vollständigen Fixture-PNGs sind bytegleich zu den benannten Originalarchiven. Die kleinen PNGs unter `replays/` sind klar gekennzeichnete abgeleitete OCR-Crops, keine zusätzlichen Rendererbilder.

## Reproduktion

Im integrierten Checkout mit Pillow und tatsächlich installierten Tesseract-Modellen `deu` und `eng`:

```sh
python3 -m unittest discover -s tools/android_qa/tests -p test_native_caption_ocr.py -v
```

Die lokalen exakt verwendeten Daten-/Quellpfade und Aufrufe stehen in `final-replay-results.json`, Modellversionen und Hashes in `ocr-environment.json`; Rohprotokolle bleiben unter `logs/`.
