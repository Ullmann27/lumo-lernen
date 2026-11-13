# Android Cards: verdeckter Header im Lauf 43428626135

## Herkunft und Geltungsbereich

Dieses Paket sichert den **fehlgeschlagenen Original-Lauf**, ausschließlich für
Host `8eab228433f124c1e2332e3d3c2ecf462ec8b136` und Native
`ada5ed81ad62339f15289da62670c0a4f9f7f2b9`. Es nimmt keine spätere Reparatur oder ein späteres APK ab.

- [Lauf 43428626135](https://github.com/Ullmann27/lumo-lernen/actions/runs/43428626135):
  `pull_request`, Versuch 1, abgeschlossen mit `failure`.
- [Android-tour-Job 131917895312](https://github.com/Ullmann27/lumo-lernen/actions/runs/43428626135/job/131917895312):
  Schritt `Install and tour the exact APK` fehlgeschlagen.
- Originalartefakt `14043514997`, `lumo-nextgen-2018-android-tour`,
  109.693.887 Bytes und 873 ZIP-Einträge.
- ZIP-SHA256: `60b1397d3fb5ef9a35c83fdd5adca26bd81ab3c10a5daba19aa91ebbbf5a646b`.
  Der Download stimmt mit dem GitHub-Artefaktdigest überein.
- Originalframe `11_cards_real_table_before_draw-face-check-03.png`,
  1080 × 2400 Pixel, Density 2,625, SHA256:
  `c90d4d7a30bba7a0384d73508f75b1fc4a908dc2d4513c92feb42b4cb8696163`.

`manifest.json` bindet zusätzlich APK, PCK, Signatur, Run, Job und Artefakt
aneinander. Die ausgewählten Originaldateien wurden direkt mit ihren
ZIP-Einträgen verglichen. Das 109-MB-ZIP wird nicht nochmals im Repository
abgelegt. Das Manifest enthält alle Herkunftspfade und die SHA256-Werte
der komprimierten und unkomprimierten Dateien.

## Tatsächlicher Fehler

Der unveränderte Frame zeigt Kartenfronten und **Seite 1/3**. Die Android-Uhr
und Statussymbole überlagern den Header mit Zurück und Pause. Die archivierte
OCR liest den rechten Bereich beispielsweise als `pay D.`. Ein exakter
Pause-Treffer fehlt.

Die initiale Bereitschaft war bereits `READY`, `native_resume_acknowledged`,
nach 11,680944 Sekunden. Alle vier anschließend verworfenen Frames besitzen
denselben überprüften PNG-Hash und öffentlichen Stand: Revision 5,
`paused=false`, `canDraw=true`, `phase=playing`, `current=0`.
Es liegt somit kein belegter pausierter IPC-Stand vor.

`capture_cards_faces` in `.github/probes/lumo_nextgen_surfaces_android_probe.py`
verwirft diese Frames wegen des fehlenden sichtbaren Pause-Nachweises.
Der alte Meldungstext `Current Cards frame still has a paused/modal transition`
beschreibt diese Ursache unzutreffend. Die Kartenfront-Pixelklassifikation
wird noch nicht erreicht. Karten-Ziehen und dessen anschließender Roundtrip
sind mit diesem Lauf nicht bewiesen.

Die erfolglosen Prüfungen verbrauchen das bestehende 60-Sekunden-Budget.
Der nächste `adb exec-out screencap -p` erhält nur noch rund 1,478 Sekunden
und endet mit `TimeoutExpired`. Der Bericht misst insgesamt 60,003826
Sekunden. Dieser Transport-Timeout ersetzt den vorher belegten
Sichtbarkeitsfehler nicht.

## Bereits vorhandene Ergebnisse und Grenzen

Die frühere allgemeine Tourdatei `tour-result.json` ist für ihren eigenen
Ablauf `PASS`; der spätere `native-surfaces-result.json` ist `FAIL`.
Beides bleibt unverändert erhalten. Host-Compile, APK-Build und Update
2017 auf 2018 waren erfolgreich. Der Veröffentlichungsjob wurde übersprungen.
Der gesamte Lauf bleibt fehlgeschlagen.

Der native Layoutfix stammt separat vom Producer-Commit
`3c26573d070a131ed5215fbdbff2517e719b3bbd`: Der Header berücksichtigt die
Display-Safe-Area. Dieses historische Paket beweist dessen neue
Android-Ausführung ausdrücklich nicht. Der tatsächliche Host-/Engine-Pfad
zur Erfassung der Systemleisten-Abstände und ein neuer APK-Lauf werden
separat geprüft.

Die lokale Host-Probe ändert ausschließlich den Text zu
`Current Cards frame does not expose the visible Pause control`.
Diese Textänderung ist **keine Layoutreparatur**. Bedingung, Wiederholungen,
60-Sekunden-Frist, OCR-Pflicht und Pixelprüfungen bleiben bytegenau gleich.
`diagnosis-only-verification.json` und die beiden lokalen Prüflogs
belegen den Ein-Zeilen-Vergleich und acht erfolgreiche bestehende
Karten-Probetests. Diese Tests verwenden deklarierte Transport- und
OCR-Doubles; sie liefern keine neue Gerätefreigabe.

## Unveränderte Rohdaten

Unter `raw/` liegen das vollständige originale Nextgen-Logcat, der vollständige
abgerufene GitHub-Joblog, Karten-/OCR-/Bereitschaftsberichte und
Run-/Artefakt-/Job-Metadaten. Die Jobliste ist die normalisierte
Connector-Antwort und entsprechend im Manifest bezeichnet.
Alle gzip-Dateien wurden nach dem Komprimieren bytegenau zurückdekomprimiert
und mit ihrer Quelle verglichen. Keine frühere Fehlermeldung im
Originalbericht wurde nachträglich geändert.

`SHA256SUMS` prüft alle Paketdateien außer sich selbst:

```sh
sha256sum -c SHA256SUMS
```
