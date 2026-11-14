# Wiederaufnahme – kombinierter Hoststand

Dieser Commit sichert die exakt gegengeprüften äußeren Jobbudgets 120/80 Minuten. Einzelne Probe-Fristen, Fehlerbehandlung und alle Pflichtprüfungen bleiben unverändert.

Der lokale Executor fiel nach dem Quellenfreeze aus. Die beiden finalen Quellen wurden aus dem veröffentlichten Elternstand wiederhergestellt und vollständig gegen die ursprünglichen Bytezahlen, Git-Blobs und SHA256 abgeglichen. Die vollständigen unabhängigen Reviewtexte sind mitgesichert.

## Nächste konkrete Schritte

1. Die 88 Pipeline-/Deliveryfälle und einmal Actionlint auf diesem neuen Quellenstand tatsächlich ausführen; diese Kombination ist noch nicht bestanden.
2. Den neuen Native-PR181-Delta mit vier Quellen gegen c300 einbinden und prüfen. Den endgültigen Hostpin erst danach festlegen.
3. Den bereits laufenden alten C4-Run 43589206933 auf Host3d/Nativebd bis zum belegten Abschluss beobachten. Sein Build ist erfolgreich; Androidtour und Update sind eigene noch laufende Prüfungen.
4. Den vollständigen neuen kombinierten C4-Lauf erst auf seinem tatsächlichen finalen Host-/Nativepaar starten. Kein alter Beleg darf dafür umbenannt werden.

## Bereits gesichert

Die 16 Dorfdateien liegen in f44ec248fc73be1fc0032f35bf41199400e7a5b5; die drei reparierten Android-QA-Dateien in ad623b8a149caf5e4339fd544cef4c4736c0d218; der fünfteilige Workflow-/Candidate-/Deliveryanschluss in e168f6ae96c4a1a50fb7c4313963425d0b15a1eb. Die tatsächlichen 80 Vertragsfälle auf4f5 und34 Dorffälle aufad623 sind dort mit vollständigen Originalbelegen erhalten.

Der Nativec300-Lauf43592406370 war erfolgreich und sein Originalartefakt14113881738 wurde vor dem Ausfall vollständig gelesen und rein nachgerechnet (45 PNGs, Dream5/7/2, Discovery10/38/2). Der genaue lokale Artefaktpack kann nach Recovery fehlen; die vollständigen Originale bleiben im Actions-Artefakt. Keine vollständige52/17-, neueAndroid- oderFPS-Freigabe wird daraus abgeleitet.

Main, veröffentlichte historische Releases und der aktive C4-Branch werden durch diesen Checkpoint nicht verändert. Die Automation bleibt deaktiviert. Es gibt keine Zusage eines unbeaufsichtigten Dauerbetriebs nach Ende der aktiven Sitzung.
