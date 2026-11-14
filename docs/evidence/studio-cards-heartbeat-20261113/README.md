# Cards: sichtbarkeitsgebundener Android-Lebensnachweis

Der Host erneuert den vorhandenen Cards-Lebensnachweis alle 500 ms auf dem Android-Main-Looper, solange die Aktivität wiederaufgenommen und die Autorität tatsächlich gebunden ist. Renderabrufe schreiben keinen Lebensnachweis mehr. Pause, Stop, Destroy, Rückkehr, Autoritätsverlust und geschlossene Mailbox beenden die Erneuerung. Alte Rückrufe werden über eine Generation entwertet.

## Was tatsächlich nachgewiesen ist

Die vollständige originale und geänderte `LumoGameActivity.kt` wurde mit dem bereits vorhandenen Kotlin-Compiler kompiliert und auf der JVM ausgeführt. Android/Godot sowie der Main-Looper sind ausdrücklich kontrollierte Randstubs. Dieselben elf Fälle ergeben vor der Änderung 2 PASS/9 FAIL und danach 11 PASS/0 FAIL. Der konkrete Gegenfall lässt sechs Sekunden ohne Rendererabruf verstreichen: Der alte Host überschreitet die unveränderte 2500-ms-Frist, der neue sichtbare und gebundene Host hält den Zeitstempel aktuell. Nach dem eng ergänzten Abhängigkeitsvertrag wurde derselbe Vergleich unter `REQUIRE_ALL_TESTS=true` erneut ausgeführt: elf unveränderte Lifecyclefälle plus zwei Dependency-Fälle, alt 4 PASS/9 FAIL, neu 13 PASS/0 FAIL/0 Skip in 6,456 Sekunden. Fehlender Compiler darf nur in optionalen Altumgebungen als Skip erscheinen; im Pflichtlauf bleibt er ein Fehler. Dies ist kein Emulator- oder Hardwareleistungsnachweis.

Zusätzlich bestanden neun bestehende Registry-/Hostanschlussprüfungen, acht unveränderte Dart-Sessiontests und 52 Probeverträge (zwölf neu, vierzig bestehend). Die Dart-Sessiontests enthalten den Abbruch bei abgelaufenem Lebensnachweis, echte Hintergrundpause, verpasste Pause-Epoch, Profilentzug, Speichern vor Quittierung und zwölf vollständige Kartenspielrunden.

## Beobachtbarkeit und Originalbefund

Der neue Prüfer liest nach dem vorhandenen State-Read optional die echte `lifecycle.json` und Gerätezeit. Ein einzelner zusätzlicher adb-Aufruf ist auf 0,75 Sekunden begrenzt. Rohtext und Beobachtungsfehler werden gespeichert. Die zeitlich aufeinanderfolgenden Daten werden ausdrücklich nicht als atomarer Snapshot ausgegeben. Keine zusätzliche Berührung, Wiederaufnahme oder Zustandsänderung erfolgt. Die bestehende Kartenfreigabe mit zwei aktuellen ungepausten Frames, Pixel-/Seitenprüfung, Quittierung und gespeichertem Kartenwachstum bleibt unverändert.

Der fehlgeschlagene Original-API35-Lauf zeigte einen erneut pausierten Tisch nach quittiertem Resume und sichtbare Kartenfronten. Er enthielt keine Lifecycle-Zeitreihe; sein exakter Pauseauslöser bleibt deshalb offen. Der lokale Gegenfall belegt die Architekturkopplung separat. Die Originalfehler werden weder zu einem PASS noch zu einem sicher bewiesenen Blankkartenfehler umgedeutet.

## Erhaltene Grenzen

2500-ms-Dart-Frist, monotone Pause-Epoch, ausdrückliches Resume, Binder-Autorität, Profil- und Speicherlogik sind unverändert. Eine neue echte APK und die vollständigen Android-Tour-/Cards-Prüfungen bleiben erforderlich. Keine Veröffentlichung oder Gesamtfreigabe wurde ausgeführt.

`source-and-tests.json` bindet Quellhashes, die unveränderten Guards, alle tatsächlichen Rohlogs und die Grenzen der Tests. Der anfängliche, vor Rot/Grün korrigierte Teststub-Kompilierfehler ist ebenfalls vollständig erhalten.
