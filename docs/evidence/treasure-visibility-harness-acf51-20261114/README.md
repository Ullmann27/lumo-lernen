# Schatzsuche: verbindlicher Sichtbarkeitsvertrag im Native-Harness

## Quelle und Zuständigkeit

Ausgang ist der tatsächlich aus GitHub gelesene Native-Commit
`acf51d3bd2997c4b731e9a48e1791e05e756a132`. Die beiden ursprünglichen Dateien
und ihre Git-Blob-/SHA256-Bindungen liegen unter `baseline/` und in
`baseline-binding.json`. Die drei unveränderten Abhängigkeiten der vorhandenen
Pythonprüfungen stammen ebenfalls genau aus diesem Commit.

Agent B ändert ausschließlich `tools/validate_studio.sh` und
`tools/tests/test_nextgen_runner.py` in diesem isolierten Paket. Agent C besitzt
die separat eingefrorene Schatzsuche-Szene und ihre echte Godot-Regression.
Root übernimmt Integration und eine neue vollständige CI. Dieses Paket
ändert keine aktive Arbeitskopie, Hostdatei, Pin-, Receipt- oder Gitreferenz.

## Verbindliche Ergänzung

Die 20 bestehenden Engine-Aufrufe einschließlich Argumenten, Capture-Umgebung
und Zeitbudgets bleiben bytegleich. Der Roster verlangt nun 54 statt 53 PNGs:
Die bisherigen 37 Bilder, acht Gesichtsaufnahmen, vier C4-Aufnahmen und vier
Schatzsuche-Titelaufnahmen bleiben erhalten; hinzu kommt ausschließlich
`treasure-title-landscape-cutout.png` mit 2400 × 1080 Pixeln.

Der Schatzsuche-Bericht muss zehn eindeutige Kombinationen enthalten: fünf
Profile jeweils beim tatsächlichen Produktions-Frischstart und mit der
ausdrücklich bezeichneten ursprünglichen Wiederaufnahme-Fixture. Die vier
bisherigen Bilder gehören weiter zum Wiederaufnahmezustand. Das neue
Cutout-Bild gehört ausschließlich zum Frischstart. Nicht fotografierte
Zeilen dürfen keine zusätzlichen oder teilweisen Bildnachweise behaupten.

Für jede der zehn Zeilen werden geprüft:

- Exakte Fenstergröße, Dichte, Insets und Titelrechteck im sicheren Bereich.
- Titel- und Hinweistextkontrast von mindestens 7:1 gegen weißen Hintergrund.
- Ein endliches, positives und vollständig im Fenster liegendes Rechteck der
  tatsächlich projizierten Figur.
- Vollständige semantische HUD-Rollen mit endlichen positiven Rechtecken.
  Kleine Querformate benötigen den bedienbaren `hint`, die hohen Formate
  das sichtbare `clue`-Feld.
- Aus den Rechtecken selbst berechnete Überschneidungsfreiheit zwischen
  Figur und HUD sowie zwischen Toast und Stick-/Aktions-/Sprung-/Hinweisfläche.
- Vollständige sichere HUD-Flächen und mindestens 47,99 dp pro Seite der
  gemessenen Eingabeflächen; die Toleranz entspricht dem vorhandenen 48-dp-Vertrag.
- Mindestens 3.341 Prüfungen, entsprechend Cs abgeschlossenem finalen
  Headless-Pfad; der echte Rendererbericht enthält 3.351 erfolgreiche Prüfungen.

Die tatsächlichen Hinweis-Taps, vollständiger Hinweistext, Scrollcontainer,
gesperrte Hintergrundbedienung, Schließen und unveränderte Quest-/Rewardidentität
werden in Cs streng ausgeführter Engine-Regression geprüft. Der unveränderte
Pflichtaufruf erzwingt weiterhin ihren PASS-Marker, Exitcode, Fehlerfreiheit
und das 600-Sekunden-Budget. Der Roster erfindet dazu keine eigenen PASS-Felder.

## Tatsächlich ausgeführte Prüfungen

| Nachweis | Tatsächliches Ergebnis |
|---|---|
| Einschlägige vollständige Pythondatei | 16/16 PASS, 38,623 s, Exit 0 |
| Umfang | 13 vorhandene Fälle, drei zusätzliche Methoden mit 32 neuen Negativvarianten |
| Bash-Syntax | `bash -n` erfolgreich |
| Originaler acf51-Roster mit Cs finalen fünf PNGs | Exit 1: erwartete alte Anzahl 4, tatsächlich 5 |
| Erweiterter Roster mit denselben Originalbytes | Exit 0; alle fünf Bilder und der Bericht hashgebunden |
| Quellvergleich | Alle übrigen Rosterfunktionen, Face-/C4-/Movie-Fixtures und der komplette PNG-Verarbeitungsloop unverändert |

Die vollständige Pythonprüfung verwendet ausdrücklich synthetische
Orchestrierungsfixtures. Beim gesonderten Replay sind die fünf Treasure-PNGs
und der 30.295-Byte-Bericht echte Originale aus Cs finalem Renderer; die anderen
49 Bilder und ihre Sidecars bleiben synthetische Vertragsfixtures. Der
eingebettete Originalroster gibt dabei seine unveränderte generische
PASS-Zeile aus. Daraus folgt kein zusätzlicher vollständiger Renderer-,
Gameplay-, Android- oder Leistungsnachweis.

Der aktuelle Bericht hat SHA256
`2eacc62e102f3b835fa938bab7966ac507b9be210c604120ab42d61c559d7f02`.
Die Einzelhashes der fünf Originalbilder, ihre Maße und die beiden Rosterläufe
stehen in `evidence/final-replay/result.json`. Die PNGs werden nicht dupliziert;
sie bleiben im separat gesicherten Originalpaket von Agent C.

Die erste lokale 16er-Prüfung mit dem damaligen Mindestwert 3.273 ist unter
`contracts-before-final-check-bound.*` erhalten. Nach Cs endgültigem
3.341er-Nachweis wurde die Mindestgrenze angehoben und der vorherige
3.273er-Umfang als zusätzlicher Gegenfall aufgenommen. Maßgeblich ist
`contracts-final.*`. Die früheren Replaydateien bleiben als lokale
Zwischennachweise erhalten; der abschließende Stand liegt unter `final-replay/`.

## Wiederholung der engen Prüfung

```sh
cd native
python3 -m unittest discover -s tools/tests -p test_nextgen_runner.py -v
bash -n tools/validate_studio.sh
```

Der separate Replay ist aus der Paketwurzel ausführbar:

```sh
python3 replay_actual_treasure.py \
  --captures ../treasure-gameplay-visibility-acf51/final-render \
  --output /tmp/treasure-final-roster-replay
```

Der Ausgabeordner muss neu sein. Ein neuer Gesamt-CI-Lauf und dessen echte
Bildsichtung nach Integration stehen für diesen Folgepatch noch aus.
