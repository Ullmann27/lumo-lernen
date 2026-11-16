# Originaler Video-Transferfehler · Run 43811505799

Die drei Dateien in `manifest.json` sind unveränderte Originalmember des
Artefakts 14201128406. Root hält das vollständig geprüfte Archiv und den
Joblog unter `docs/nextgen/evidence/ci-2031-replay-video-transfer-failure/`.
Die SHA-/CRC-/Größenwerte beziehen sich auf die Originalbytes.

Die vorherige Originaltour hat ihren eigenen `PASS_WITH_LIMITATIONS`-Befund.
Die Referenztour bleibt **FAIL**: Nach der sichtbaren geführten Ba–na–ne-Seite
brach `adb pull` der Aufnahme 0091 mit Exit 1 und einer 7-%-Fortschrittszeile ab.
`primary_error` ist null, die Recorderausgabe ist leer. Daraus folgt weder ein
fehlgeschlagener Recorderstart noch eine fehlende Remote-Datei. Der tiefere
Grund des Transferabbruchs ist mit diesen Originalen nicht bestimmt.

Die Testtransportdaten, ADB-/Zeitabläufe und positive Decoderantwort sind
ausdrücklich konstruiert. Sie sind keine neue Androidaufnahme und werden nicht
als Originalvideo abgelegt. Die bestehenden Resize-/Foreground-Tests prüfen
weiter die echten historischen Nullzeit-MP4s mit dem tatsächlichen `ffprobe`.
