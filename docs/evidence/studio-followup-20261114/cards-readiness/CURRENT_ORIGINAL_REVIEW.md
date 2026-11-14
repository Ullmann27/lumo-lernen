# API35/API37: originale OCR-Nachprüfung und Cards-Readiness

Der echte Diagnose-Run **43542310963, Versuch 1**, endet auf beiden Android-Versionen mit **FAILURE**. QA-Quelle ist `a446f3c1a320ad5297e17606727d801c5e993ce1`; geprüft wurde weiterhin das unveränderte APK von Host `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`.

## Tatsächlich erreicht

| Originaljob | Laufzeit | Lernbewegungen | Rückkehr | Cards vor Ziehen | Nach Ziehen |
|---|---|---|---|---|---|
| 132285770589 | SDK 35, Android 15, x86_64-Emulator | Fünf wirkliche Touchaktionen; Zielplätze 8, 9, 10, 11, 12; `placed=5 complete=true` | Dieselbe Flutter-Lektion; zwei Lernschlüssel unverändert | Zwei vollständige Fronten-/Layout-/Pixelbeobachtungen, Revision 3 | Fehlende Layoutdatei, JSONDecodeError nach 0,104349s |
| 132285770547 | SDK 37, Android 17, x86_64-Emulator | Fünf wirkliche Touchaktionen; Zielplätze 8, 9, 10, 11, 12; `placed=5 complete=true` | Dieselbe Flutter-Lektion; zwei Lernschlüssel unverändert | Zwei vollständige Fronten-/Layout-/Pixelbeobachtungen, Revision 3 | Fehlende Layoutdatei, JSONDecodeError nach 0,123735s |

Die fünf Eingaben sind einzeln in den unveränderten `learning-move-*-surface-readiness.json` mit aktuellen Bounds und Touchpunkten dokumentiert. Der originale `learning-movement-logcat.txt` bestätigt jede zugehörige Objektbewegung. Jeweils zwei neue Objekte füllen den Zehner; drei weitere ergeben 13. Die Erklärung vergibt keine zusätzliche Beherrschung oder Belohnung. Der Sprachpfad meldet abgeschlossene Äußerungen, ersetzt aber keine Hörprüfung oder Lippenanimation.

Die API37-Bilder `04_learning_native_thirteen.png`, `05_learning_same_flutter_lesson.png` und `11_cards_real_table_before_draw.png` wurden von Agent B tatsächlich einzeln geöffnet. Sie zeigen 13 Würfel, die wiederhergestellte Flutter-Aufgabe mit 13 Äpfeln sowie drei vollständige Handkartenfronten vor dem Ziehen. Roots eigener API35-Bildbericht bleibt getrennt zugeordnet. Bildhashes und Befunde stehen in `api37-image-review.json` und `root-api35-image-review.json`.

## Erste harte Fehlerursache

In beiden Originalarchiven steht bytegleich diese 113-B-Rohantwort:

```text
cat: /data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview/files/cards_layout_v1.json: No such file or directory
```

SHA256: `0054bf61f03f13e08b83292429123c21f2b3470100987ad033e67ed1dbb1e679`.

Die Antwort ist kein JSON. Der Reader speichert sie bereits unverändert, lässt aber anschließend `JSONDecodeError` aus dem vorhandenen `RuntimeError`-/`TimeoutError`-Wartepfad entkommen. Damit scheitert der Nachhervergleich beim ersten Lesen. Die öffentliche Spielzustandsantwort hatte die Ziehaktion bereits bestätigt (`ack=1`, acht Handkarten); die nachfolgenden Prüfungen des dauerhaft gespeicherten Zustands, der 35-Sekunden-Ruhezeit und der Cards-Wiederaufnahme wurden noch nicht erreicht.

Der exakt an Native 803 gebundene Writer veröffentlicht Layouts über `.tmp`, Flush, Schließen und Umbenennen. Bei einem Übergang löscht er bewusst das vorige abgeglichene Layout und wartet auf zwei Settle-Frames sowie abgeschlossene Kartenbewegungen. Es gibt keinen Beleg für einen nichtatomaren oder abgeschnittenen JSON-Schreibvorgang. Der nachgewiesene Fehler liegt hier in der Behandlung einer nicht verfügbaren Diagnoseaufnahme durch den Leser.

## Enger lokaler Fix

Der isolierte Patch ändert ausschließlich `read_cards_layout`: Nach Sicherung der Rohantwort wird `JSONDecodeError` als dokumentierter `RuntimeError` weitergegeben. Der bestehende 60-Sekunden-Loop wartet dadurch weiter und verlangt weiterhin zwei vollständige, unveränderte Frames mit aktueller Session, Revision, gemessenem Layout und echten Kartenpixeln. Es gibt keine Ersatzwerte oder Wiederverwendung eines alten Layouts.

Der abschließende identische Gegenfall scheitert mit der Originalquelle zweimal an `JSONDecodeError`. Mit dem Patch bestehen alle **sechs gezielten Tests**: Rohdaten bleiben erhalten; eine Lücke wird erneut beobachtet; eine Lücke zwischen zwei Bildern setzt die Zweibildprüfung zurück; dauerhaft fehlende, veraltete, fremde und übergroße Layouts werden weiter abgewiesen. Die echten Geometrie-/Pixelvalidatoren laufen mit historischen Vorheraufnahmen; Transport und Uhr sind ausdrücklich Testdoubles. Ein anfänglich unvollständiger Test-Importpfad ist als eigener fehlgeschlagener Entwicklungslauf erhalten.

**Dies ist noch kein neuer Android-Cards-PASS.** Kein vollständiger Cards-Rundlauf, keine Creative-Spielsequenz, keine physische Fold7-Messung und keine Geräte-FPS werden daraus abgeleitet. Die beiden vollständigen Original-ZIPs und Joblogs sind erhalten; selektiv extrahierte Dateien bleiben unverändert und SHA-/CRC-gebunden.
