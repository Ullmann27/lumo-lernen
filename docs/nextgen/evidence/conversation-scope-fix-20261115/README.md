# Eigene Gesprächsroute und Besitzergrenzen

Die unveränderten RED-/GREEN-Logs und die maschinenlesbare Übergabe dokumentieren zwei tatsächliche Produktkorrekturen. Producer-Commits: `ddf7106cb1a3b6592f0e37dcd96d36b9108a4ec8` und `cd0906ab8f672e6c9da5659d0876ad537311eea9`. Root hat beide übernommen.

Der eigene Lab-Gesprächsdialog behält seine überprüfte aktive Aufgabe. Alte Controller/Agentansichten können keine neuere Aufgabe, Abbruchepoche, Geste oder Sprachausgabe beenden. Ausdrückliches aktives Stopp bleibt wirksam. Der abschließende gezielte Flutterlauf umfasst 56 PASS, 0 FAIL, 0 SKIP; beide Analyzerläufe melden keine Probleme. Die sieben neuen Besitzerfehler wurden vor der Korrektur tatsächlich rot reproduziert.

Das sind Widget-, Controller- und Transportauftragsprüfungen; Mikrofonkanäle in den Tests sind ausdrücklich Testdoubles. Sie ersetzen keine Android-Wiedergabe oder physische Spracherkennung. Der neue Androidlauf bleibt erforderlich. Die Originalfehler-APK 2027 wird dadurch nicht freigegeben. Hashes und genaue Testzuordnung stehen in `handoff.json`.
