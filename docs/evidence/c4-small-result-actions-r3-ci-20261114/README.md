# R3: tatsächliche kleine Ergebnisaktionen bestanden

## Unveränderte Produktquelle und abgeschlossener Lauf

Run [43596764202](https://github.com/Ullmann27/lumo-lernen/actions/runs/43596764202), Attempt 1, Job 132452818400 ist vollständig mit SUCCESS abgeschlossen. QA-Head 51d05896aec9bced8c789504161f2255441cd07f / Tree 1c95ba11ba980ed01bd3e76c91a66fdfcb23b8a4 ist der separat geprüfte direkte Child des eingefrorenen Hoststands. Die tatsächlichen Checkout-Zeilen im unveränderten vollständigen Joblog und die Laufzeitsnapshots binden:

- Host aab09275ec6b5808de9be539ca4e1a7e70921249 / Tree baaa84b40b09e61d144f158e5b35a1c4dc5d2ef0.
- Native e2d15dbc5f3709306decb139eeb70a1cf30c0b73 / Tree ea0f73ae6aad8792a963cadaa483c290a2f2a62e.
- Genau die vier freigegebenen QA-Dateien; keine Produktänderung.

Das offizielle Originalartefakt 14114498334 wurde genau einmal heruntergeladen. Es umfasst 1.619.461 Bytes; SHA256 415ce3b5f51d510983c0184d37e479dc00844fa50f9dcd70c4f0493454228f64. Die vollständige ZIP bleibt unverändert erhalten. CRC, eindeutige kanonische Pfade und reguläre Dateitypen wurden vor dem Lesen geprüft: 103 Dateien einschließlich vier ursprünglicher PNGs. Kein Archivcode wurde ausgeführt.

## Tatsächlicher Zwei-Aktionen-Nachweis

Native meldet 283 Checks ohne Fehler. Beide ursprünglichen Prozesse endeten mit Exit 0. Die 21 Native-Requests stimmen semantisch vollständig mit den 21 tatsächlich von Dart empfangenen Requests überein; die Aktionszustände wurden zusätzlich gegen 35 ursprüngliche Dart-Zustandsereignisse und die vier frischen Layoutbeobachtungen geprüft.

| Zielaktion | Ursprüngliche Eingaben und Bestätigung | Zustand nach der Aktion |
| --- | --- | --- |
| Neue Runde | Acht Drag-Ereignisse, Scroll 61 → 89, Press/Release bei [316,172]; Request 11, ACK 10 → 11, Revision 18 → 19 | Neue Runden-ID, leeres Brett, Zweispielermodus bleibt aktiv, playing und unpausiert |
| Gegen Lumo spielen | Sechzehn Drag-Ereignisse, Scroll 59 → 148, Press/Release bei [316,173]; Request 20, ACK 19 → 20, Revision 33 → 34 | Neue Runden-ID, leeres Brett, Solomodus, playing und unpausiert |

Beide Zielrechtecke sind nach dem Freiscrollen vollständig sichtbar und entsprechen ihrer Hitfläche: [22,146,588,52] beziehungsweise [22,147,588,52]. Bei deklarierter Testdichte 1.0 ergibt das jeweils 588×52 dp. Die unabhängige Sichtprüfung hat alle vier ursprünglichen Bilder selbst geöffnet und die jeweils getestete Schaltfläche als vollständig sichtbar und lesbar bestätigt.

Genau zwei unterschiedliche gewonnene Runden erzeugten je fünf Sterne und 40 XP, zusammen zehn Sterne und 80 XP. Der anschließende Zurück-Request wird mit ACK 21 / Revision 35 bestätigt. Der Bericht und die unveränderten Dart-Prüfungen bestätigen die Wiederöffnung derselben leeren, noch unbelohnten Solorunde im selben Prozess mit dem SharedPreferences-Testbackend.

## Originalbilder und Beweisgrenzen

Alle vier PNGs sind 640×360 Pixel groß. Ihre Datei-Hashes, die zugehörigen Layoutdateien und deren Quellen-/Zustandsbindungen sind im Originalindex, Gatebericht und unabhängigen Review enthalten. Layoutsequenzen 5, 6, 9 und 10 binden jeweils ACK/Revision 10/18, 11/19, 19/33 und 20/34.

Die beiden Nachher-PNGs sind tatsächlich bytegleich: SHA256 d950d7eb72be82cef8afdbfbf622221f37cf8d93ec75dfcddef3742d6ebf0560. Beide zeigen das leere Brett. Der Moduswechsel wird daher durch die gepaarten Layout-/ACK-/Dart-Zustände nachgewiesen, nicht durch ein sichtbares Moduslabel im Nachherbild.

Die jeweils obere Nachbaraktion ist am Scrollrand teilweise abgeschnitten; die gezielt freigescrollte und betätigte Schaltfläche ist vollständig sichtbar. Dies wird nicht als allgemeine Freigabe sämtlicher Scrollpositionen ausgegeben.

Die Abnahme betrifft den tatsächlichen Desktoplauf mit lokaler Dateiverbindung zwischen zwei Prozessen, vorgegebenen Insets und Testdichte. Sie ist keine Android-Binder-/Geräteprüfung und kein Nachweis für Persistenz nach einem Prozessneustart. Die 437 logischen Probeframes und das Startargument --fixed-fps 24 sind keine gemessene Bildrate.

## Quellenintegrität und gesicherte Originale

Die Laufzeitsnapshots vor und nach der Probe sind bytegleich: SHA256 009c0dd5b9cfde08e3a977249a4db64a0db935a48fde71f819271e5ca9a0490d. 447 Host-, 1.256 Native- und vier QA-Dateieinträge stimmen mit den exakten Remote-Trees überein. Alle 334 aufgezeichneten UID-Metadaten wurden gegen ihre getrackten Quellblobs und die aus ihren aufgezeichneten UID-Strings rekonstruierten Bytes/Hashes geprüft. Der abschließende Hashvergleich bestätigt alle 103 extrahierten Originaldateien unverändert.

Die komplette ZIP, Original-API-Antworten, der abgeschlossene Volljoblog, native und Dart-Ergebnisse, beide ursprünglichen Prozesslogs, vier Bilder mit vier Layoutdateien, identische Vorher-/Nachher-Snapshots und der reine Konsistenzreview sind einzeln gebunden. Der unabhängige Bild-/Aktionsreview steht unter ../c4-small-result-actions-qa-r3-20261114/independent-visual-review.json.

Die früheren tatsächlichen Fehlläufe und ihre engen Korrekturen bleiben als getrennte historische Belege erhalten. Nach diesem erfolgreichen Lauf wurde keine weitere Produkt-/QA-Änderung, kein weiterer Spieltest und kein Rerun angefordert.
