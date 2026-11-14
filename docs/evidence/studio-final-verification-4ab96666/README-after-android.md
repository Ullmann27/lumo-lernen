# Android-Ergebnisse des Kandidaten 4ab

Stand: 14. November 2026, 01:31 UTC. Diese Belege gehören zu Run **43530667812**, Versuch 1, Host **4ab96666f954baf258422d6ed277fc297b7ddeef** und Native **803e7a626ea6ef0aeeda9c37010e844033d3a8e3**.

## Tatsächlicher Status

| Pflichtjob | GitHub-Job | Ergebnis zum angegebenen Zeitpunkt |
| --- | --- | --- |
| Android-Hostkompilierung | 132247239767 | SUCCESS |
| Vollständige Prüfung und APK-Build | 132247240154 | SUCCESS |
| API35 Anwendungstour und Studio-Oberflächen | 132269951320 | FAILURE: Lern-OCR vor erster Objektberührung |
| API37 Anwendungstour und Studio-Oberflächen | 132269951372 | FAILURE: Lern-OCR vor erster Objektberührung |
| Update von 2017 auf 2019 | 132269951387 | SUCCESS innerhalb der unten beschriebenen Ein-Kind-Fixture |
| Zusätzliche echte Jump-/Bau-/Puzzle-/Schatz-Eingaben | 132269951369 | IN_PROGRESS; noch kein Ergebnis beansprucht |

**Keine Android-Gesamtabnahme und keine freigegebene APK.** Ein erfolgreicher Build ersetzt die fehlgeschlagenen Oberflächenprüfungen nicht. Die historische Meldung laufender Android-Jobs in README-after-build.md beschreibt ihren damaligen Zeitpunkt; dieses Dokument enthält den späteren Befund.

## Beide fehlgeschlagenen Oberflächentests

[API35-Originalbericht](api35/README.md) und [API37-Originalbericht](api37/README.md) trennen normale App-Tour und die zusätzliche Studio-Abnahme. Die normale Tour besteht auf beiden APIs 21/21 Schritte. Anschließend erscheint die echte räumliche 8+5-Lernszene. Die goldene Schaltfläche „Ein Objekt zeigen“ ist in den tatsächlich gesichteten Originalbildern vollständig lesbar, aber die ursprüngliche OCR erkennt ihre Beschriftung nicht exakt. Alle betreffenden Frames bestehen die Prüfung auf eine vollständige renderbare Oberfläche.

Die unveränderte Frist von 120 Sekunden läuft ab. API35 endet beim letzten Tesseract-Unterprozess mit rund 0,637 Sekunden Restbudget; API37 endet im übergeordneten Ziel-/Oberflächen-Guard. Daraus wird kein generell hängendes OCR-Programm abgeleitet. Es wurde kein akzeptierter erster Lern-Touch gesendet, die Szene bleibt bei **0/5 bewegt**, und **Cards wurde auf beiden APIs nicht erreicht**. Es gibt deshalb weder einen neuen Lernabschluss-/Rückkehr-PASS noch einen neuen Cards-PASS.

## Tatsächliches Update und Datenerhalt

[Update-Bericht](update/README.md) und [unabhängiger Wertevergleich](update/independent-data-comparison.json) belegen die Installation derselben neuen x86-APK mit install -r: Version 2017 → 2019, UID und erste Installationszeit bleiben erhalten. Das eine tatsächlich angelegte Testkind behält seine fünf verglichenen Identitätsfelder, sieben geschützte Lernschlüssel, eine richtige Antwort, einen Stern und fünf XP. Alle zehn bisherigen Kompetenzfelder bleiben einschließlich ihrer Typen erhalten; hinzu kommt ausschließlich die zugelassene independentEvidence-Ergänzung.

Die geschützten Werte bleiben auch nach Offline-Kart, erneutem Appstart und drei simulierten Displaygrößen gleich. Die optionale alte 2017-Navigation nach Deutsch und Englisch scheitert; das alte Rückkehrbild zeigt einen leeren Hauptbereich. Diese Teilbefunde bleiben ausdrücklich erhalten. Die Fixture prüft keine zwei Kinder, gefüllten Journale oder alten nativen Spielstände.

## Binärbindung und Sichtung

Alle drei Jobs verwenden die neue x86-APK mit **325.295.610 Bytes**, SHA256 **7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6**, und das native PCK mit **66.234.596 Bytes**, SHA256 **28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e**. Die Originalarchive wurden vollständig auf CRC und Mitgliederhashes geprüft. Ausgewählte unveränderte Bilder, XML-/JSON-Daten, Logs und die Prüferquellen sind über explizite Dateilisten gebunden; große ZIPs und APK-Duplikate werden hier nicht hinzugefügt.

Agent A hat neun Updatebilder und zwei API37-Lernbilder tatsächlich einzeln gesehen; Agent C zwei API35-Lernbilder. Roots ergänzende, begrenzte Sichtung ist separat dokumentiert. Mehrere Reviewer desselben Bildes machen daraus keine zusätzlichen App-Tests. In einem tatsächlich angesehenen Update-Kart-Bild zeigt der HUD 169 km/h; dies ist eine Spielanzeige und kein gemessener Geräte-Durchsatz.

## Weiteres Vorgehen und Grenzen

Ein separater OCR-Replay und ein Nachtest derselben APK werden vorbereitet. Die Prüferquelle wird dabei von der unveränderten APK-Quelle getrennt gebunden. Erst tatsächlich ausgeführte Ergebnisse können daraus neue Aussagen begründen; der ursprüngliche fehlgeschlagene Run wird nicht umetikettiert. Normale Veröffentlichungsgates bleiben unverändert.

Kein physischer Galaxy-Z-Fold7-, 60-FPS-, Temperatur-, Touchlatenz-, hörbarer Sprach- oder Original-Lumo-Lippensynchronitätsnachweis. Main und Produktquellen werden durch diesen Belegcommit nicht geändert.

