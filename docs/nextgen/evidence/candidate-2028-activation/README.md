# Aktivierung des korrigierten 2028-Kandidaten

Der saubere, bereits veröffentlichte Produktstand `daf6ca5e9f7df7b32a32ef987d067035ddb5328c` mit Native `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef` ist die Quelle des echten Dart-Katalogexports. Alle 245 in der Abdeckungsliste bezeichneten Quellhashes wurden erneut geprüft; alle 18 geschützten Dateien sind bytegleich zum vorgegebenen Basisstand. Der abschließende Aktivierungscommit ergänzt nur Konfiguration und Belege, nicht den exportierten Produktcode.

Die Originaldateien und ihre Hashes liegen bei. 88 Python-Prüfungen der Androidbeobachter bestehen, aber dies ist keine Androidtour. Diese Aktivierung startet die vollständige CI mit neuen Buildartefakten. Ein erfolgreicher Build, aktuelle Androidbilder/-messungen und der direkte neue Download werden erst anhand der tatsächlichen späteren Ergebnisse berichtet. Die fehlerhafte alte 2027-APK wird nicht veröffentlicht.

Die Abdeckungsliste enthält 61 geprüfte Inventareinträge, darunter Navigation, Verträge, geschützte und inaktive Pfade; diese Zahl bedeutet nicht 61 bewertete aktive Aufgaben. 18 Fachoberflächen haben 19 nachgewiesene Akademieeinstiege. Weitere Aufgaben nutzen gemeinsame Oberflächen und die vorhandenen nativen Adapter. `fullModernizationComplete` bleibt ausdrücklich false.
