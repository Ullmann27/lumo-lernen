# 2031: begrenzte Beobachtung eines Offlinezustands beim Videotransfer

## Unveränderter tatsächlicher Fehler

Vollreplay **43814971553**, Androidjob **133124836818**, QA-Quelle
`e2713c27599b6659a6ad2fd31355effeae9f88c9`, unveränderte APK-Quelle
`e05a96a52aaf57e466e79831f15aaffd144284ee`: Die Originaltour meldete
`PASS_WITH_LIMITATIONS`; die Referenztour blieb **FAIL** vor nativer Banane.
Dieser Patch erklärt keinen früheren Lauf nachträglich für bestanden.

Die vollständigen Originale liegen unter
`docs/nextgen/evidence/ci-2031-replay-transfer-state-failure/`.
Artefakt **14203175225**, **75.040.815 Bytes**, SHA256
`3575c784355901d6d0f35cbce3de05bfd93186222047d2c1a62d29afcc565f76`.
Die drei kleinen Dateien der neuen Fixture sind bytegleiche Archivmitglieder;
das Fixturemanifest enthält ihre individuellen Größen, Hashes und Herkunft.

`0090-banana-guided-navigation-video-transfer.json` zeigt:

- Vor der ersten Kopie war die PID-Antwort leer. Die bereits beendete Remoteaufnahme
  war mit **830.450 Bytes** und SHA256
  `36f05562925beab6528816bdf26776e4c4e338781108620c9bdb15196c08f931` lesbar.
- `adb pull` endete mit Exit 1 und leerem zusammengeführten Output.
- Die anschließende PID-Abfrage lieferte wörtlich **`adb: device offline`**.
  Es wurde keine weiterlaufende Recorder-PID beobachtet.
- Der gesamte Transferblock endete nach **0,192 Sekunden**. Die zweite erlaubte
  Kopie wurde nicht begonnen; `primary_error` war `null`.

Der volle Joblog protokolliert danach um `06:24:46.8573677Z` einen erfolgreichen
frischen ADB-Screenshot `0109-failure-current-screen.png`. Sein SHA256
`52aca64ed4d8b5da1000d3417424350cb3ad7ca327b04a835d3e662b977ec57c`
entspricht der vorherigen Ansicht `0108`. Das belegt wieder mögliche
Screenshot-Kommunikation, keine erfolgreiche nachgeholte Videokopie.
Der reguläre Emulator-Kill folgt erst um `06:24:46.9120886Z` nach dem Probeabbruch.
Ursache und genaue Dauer der Unterbrechung sowie ein möglicher Ressourcenengpass
sind aus diesen Belegen nicht bestimmt. Insbesondere wird kein Recorderstart-,
App-, Speicherplatz- oder 90-Sekunden-Timeoutfehler behauptet.

## Enger Fix

Geändert wird ausschließlich `LearningProbe._pull_recording()` in der
gemeinsamen Probe sowie ihr vorhandenes Hosttestmodul. Kein Workflow, Produkt,
Publisher, Originaltourablauf oder nativer Referenzfall wird geändert.

Nach einer fehlgeschlagenen Kopie darf ausschließlich die exakte PID-Rohantwort
`adb: device offline` passiv erneut gelesen werden. Jede Antwort wird mit ihrer
verstrichenen Zeit sofort im vorhandenen Transferjournal gesichert. Zwischen
den Beobachtungen liegen höchstens 0,25 Sekunden Pause; alle Abfragen und Pausen
verbrauchen die **unveränderte gesamte 90-Sekunden-Frist**. Die erlaubte Zahl
bleibt **höchstens zwei Kopien derselben Aufnahme**.

Vor einer Kopie werden die tatsächlich abgefragte ADB-Seriennummer und
`/proc/sys/kernel/random/boot_id` gebunden. Jede verwertbare erneute Remoteprüfung
muss dieselben Werte liefern. Danach gelten weiterhin die Prüfung des beendeten
eigenen Recorders, positive Remotegröße, identischer Remote-SHA256, vollständige
lokale Byte-/Hashgleichheit und die unveränderte positive `ffprobe`-Videodauer.
Unbekannte PID-Texte, eine echte eigene Recorder-PID, unlesbare Identitäten,
Seriennummern-/Bootwechsel oder veränderte Aufnahmebytes bleiben harte Fehler.
Offline vor dem ersten Transfer oder nach einer vollständig gemeldeten Kopie
wird durch diesen Fix nicht in eine zusätzliche Wiederholung umgedeutet.

Es gibt keinen ADB-Reset, Reconnect, Serverneustart, Appstart, neuen Recorder,
neue UI-Aktion oder zusätzliche Aufnahmerunde. Frühere Teilkopien und der erste
Transferfehler bleiben erhalten. Das bestehende `recording()` einschließlich
seines Primärfehlerschutzes und der Decoderprüfung ist bytegleich zur Basis.

## Tatsächliche lokale Prüfung

Basis: `daa69bf4d639ee1a35a4938bfb469311f85eec4c`.
`red-source.json` und `red-test.patch` binden den RED-Lauf an die unveränderte
Probe: **2 Tests, 1 erwarteter Fehler** am bisherigen Guard. Der Originalrohwert
ist real; die anschließende Gerätewiederkehr ist eine ausdrücklich konstruierte
Hostsequenz. Die tatsächlichen fehlenden MP4-Bytes werden nicht erfunden.

`transfer-green-first.log`: **10/10 PASS**. `joined-green.log`: **19/19 PASS**
aus Recordertransfer-, Resize- und Foreground-Prüfungen. Dazu gehören dauerhaft
offline, Wiederkehr desselben Geräts, Serial-/Bootwechsel, ungültiger Status,
eigene Recorder-PID, veränderte Datei und keine dritte Kopie. Die bestehenden
echten Nullzeit-MP4s werden weiterhin durch tatsächliches `ffprobe` abgelehnt;
ein sekundärer Videofehler verdrängt den ursprünglichen Homefehler nicht.

ADB-Wiederkehr, Gerätewerte und positive Videoausgabe der Transporttests sind
synthetische Testgrenzen. Kein Androidlauf, APK-Build oder Remotevorgang wurde
für diesen Patch ausgeführt. Ein neuer tatsächlicher Replay muss erst belegen,
dass die Verbindung innerhalb des vorhandenen Budgets stabil zurückkehrt und
dieselben Videobytes vollständig übertragen werden können.
