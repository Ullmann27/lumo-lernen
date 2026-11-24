# Supplemental 2031, zweiter tatsächlicher Versuch vorbereitet

Die unveränderte APK-Quelle bleibt `e05a96a52aaf57e466e79831f15aaffd144284ee`, Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Der vollständige Replay 43814971553 an `e2713c27599b6659a6ad2fd31355effeae9f88c9` läuft getrennt weiter. Der neue Zusatzfall ersetzt keinen vollständigen Replay und kann keine APK veröffentlichen.

Der Ansichtsfix ist aus dem API-Ownerstand `d3aed4a53675829bab989ed9a1496e420211623c` plus enger Provenienzkorrektur `db1180a7ee2b168b6299688c813b7a360d5776a2` übernommen. Alle 17 finalen Komponentenbytes sind gegen Handoff und Commit geprüft. Das ursprüngliche Handoff ist unverändert erhalten. Der unabhängige Read-only-Review fand nach Korrektur des tatsächlichen Bounds-Histogramms keinen konkreten verbleibenden Blocker.

Root führte die sieben im Zusatzworkflow verwendeten Prüfergruppen am dokumentierten integrierten Commit aus: **211/211 PASS**, keine übersprungenen Fälle. Die 21 fokussierten Ownerprüfungen sind darin enthalten und werden nicht nochmals addiert. Das vollständige Protokoll und genaue Befehle stehen neben dieser Datei. Es handelt sich um Hostprüfungen, nicht um einen neuen Androidnachweis.

Die 31 an den vollständigen Replay gebundenen Publisher-/Prüferquellen und alle neun zusätzlichen Banane-/Transferfixturedateien sind bytegleich zur tatsächlichen Full-QA-Quelle e2713c2. Der ganze committed Tree unterscheidet sich von der APK nur in den zugelassenen QA-/Dokumentationspfaden. Aktive Prüfung 45 s und vollständige XML-Erfassung bis zum angeforderten Tap höchstens 1 s bleiben unverändert. Die temporäre 320-dpi-Ansicht ist ausdrücklich kein Standarddichte-/Hardwarebeleg; exakte Wiederherstellung mit Aufgabe/Profil/Lernstand bleibt ein hartes Gate.

Die Konfiguration `caseAttempt=2` muss auf dem bestehenden QA-Zweig tatsächlich gestartet und das Ergebnis anschließend ergänzt werden. Beim Erstellen dieser Datei sind die neue gemeinsame Sichtbarkeit, der aktive Wechsel und die Dichte-Rückstellung **NOT_RUN**. Der erste Zusatzlauf 43812538819 bleibt FAIL; sein tatsächlich bestandener separater Zahlenfall bleibt als solcher erhalten.
