# Memory: getrennte Bestwerte pro Kind

Vorher teilten alle Profile `lumo_memory_v2` für Bestwerte und Schwierigkeit. Die produktive Memory-Seite verwendet jetzt die bestehende `captureLearningProfile()`-Identität und einen SHA-256-Namensraum. Besitzer, JSON-Daten und Zielschlüssel werden vor asynchronem Schreiben erfasst; Schreibvorgänge laufen der Reihe nach. Ein Profilwechsel sperrt die vorherige Runde und blendet deren Ergebnisdialog aus. Beschädigte neue Kinddaten werden nicht leer überschrieben.

Der globale Altbestand bleibt bytegleich erhalten. Seine früheren Ergebnisse werden keinem Kind ohne belegte Zuordnung zugeschrieben. Spielregeln, Kartenmotive, Gegnerentscheidungen und Belohnungsregeln bleiben gleich; keine neue 3D-Szene oder Rundenwiederaufnahme wird behauptet.

Sieben bestehende/neue Memory-Testdateien bestanden mit insgesamt **25 Prüfungen**. Darunter eine tatsächlich vollständig gespielte Vier-Paare-Runde, neue App-Instanz, zwei Kinder, verzögertes Laden/Schreiben, Reihenfolge/Snapshots, ursprüngliche Altbytes sowie bestehende Layout-/Touch-/KI-Prüfungen. Drei geänderte Dart-Dateien wurden analysiert: keine Befunde. Originale Testlogs und Quellhashes liegen in `docs/evidence/nextgen-memory-20261113/`.
