# Host1453: unveränderte CI-Fehlerbelege

Dieses Paket bindet ausschließlich Host `1453c7fd09cc91ee04dcddc2631dfd6028a37d56`, Studio-Run43579548170/Attempt1 und die automatisch gestarteten Workflows desselben Heads. Der Native-Pin bleibt785413. Es enthält keine neue APK und keine Android-Abnahme.

Der neue frühe Drei-Dateien-C4-Schritt führte zwölf Fälle tatsächlich aus: acht bestanden, vier scheiterten an `getRect(...).width >= 48` mit dem Messwert47.99999999999997. Die drei vorhandenen Spielflussfälle und fünf Visualfälle bestanden; die vier späteren Fold-Wisch-/Zugfolgen wurden nach ihrer ersten Assertion nicht erreicht. FullFlutter und APK-Build des Hauptlaufs blieben anschließend übersprungen. Der echte Android-Hostcompile bestand.

Living Core führte seine vollständige Suite separat aus:2355PASS/196SKIP/4FAIL. Diese vier Fehler sind dieselben Größenassertions. Die Zahlen verschiedener Ausführungen werden nicht addiert. Der davor erfolgreiche48er-Eingangstest bleibt ein eigener Teilbeleg.

Die vollständige abschließende Head-Liste enthält16terminale Läufe:5SUCCESS,2FAILURE,3CANCELLED,6SKIPPED. Der historische1999-Upgradeworkflow endete um09:28:55UTC erfolgreich; das prüft keinen neuen2020-Kandidaten. Für die Abbrüche wurde keine unbelegte Ursache eingetragen.

`early-c4-original-failure-analysis.json` bewahrt die erste quellengebundene Diagnose. `review.json` ordnet den tatsächlichen Endstatus ein. `upload-manifest.json` ist der explizite Index der unveränderten Bytes, SHA256 und Gitblobs. Die `.dart.txt`-Datei ist nur der vollständige diagnostische Quellsnapshot von1453; sie wird nicht als Test installiert.

Die beiden Fehlerlogs und der Hostcompile-Log sind vollständige unveränderte Connector-Rohstrings in UTF-8. Es gab keine lokalen Flutter-/Cacheaufrufe, keine Reruns und keine Source-/Refmutation durch diesen Monitor. Der korrigierte Folgehead078774dd besitzt getrennte Prüfbelege; dessen Ergebnisse werden diesem fehlgeschlagenen Lauf nicht zugeschrieben. Originalarchive/PNG wurden hier nicht heruntergeladen.
