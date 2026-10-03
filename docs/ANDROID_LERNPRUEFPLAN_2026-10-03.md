# Android-Lernprüfung: Klasse 1 bis 4

Ausführungsplan für die tatsächlich ausgelieferte APK, noch kein Testnachweis.
APK-Version/SHA-256, Emulator-Gerät/API/ABI, Bildschirmgröße und Zeitpunkt
vor dem ersten Schritt notieren. Nur ein fiktives Testprofil verwenden;
vorhandene Nutzerdaten weder zurücksetzen noch löschen. Für jede Klasse ein
passend gespeichertes Testprofil verwenden und den aktiven Grad auf der
Lernfachauswahl kontrollieren. Ein früheres Thema ist als Wiederholung erlaubt.

| Klasse | Mathematik | Deutsch | Sachunterricht | Logik |
| --- | --- | --- | --- | --- |
| 1 | Plus bis 10 | Silben | Wetter | Muster |
| 2 | Einmaleins Vorbereitung | Einzahl und Mehrzahl | Wetter | Zahlenmuster |
| 3 | Schriftliche Addition | Wortarten | Bundesländer Österreichs | Schlussfolgern |
| 4 | Bruchrechnen einfach | Die 4 Fälle | Stromkreise | Regeln kombinieren |

Unter `Start → Lernen → Unterthemen` das konkrete Thema öffnen. Die Inhalte
sind zufällig: den tatsächlich gezeigten Prompt und die selbst überprüfte
richtige Antwort festhalten, keine feste Antwortposition voraussetzen.

1. Je Klasse zuerst Mathematik öffnen. Sterne/XP vorher notieren. Eine bewusst
   falsche Antwort wählen: Aufgabe bleibt zum Wiederholen erhalten, Rückmeldung
   passt zum Fehler, Sterne/XP bleiben unverändert. Keine Erfolgsmeldung.
2. Auf derselben Aufgabe Lumos Aufgabenhilfe dreimal anfordern. Die drei
   Hinweise entwickeln sich weiter und passen zum aktuellen Prompt. Aufgabe
   und Optionen wechseln dadurch nicht. Klasse 2: Gruppen passen zu Malrechnen;
   Klasse 4: Brüche werden nicht als Plusaufgabe mit Äpfeln erklärt.
3. Richtig antworten. Erfolg, angezeigte Sterne-/XP-Differenz und nächste
   Aufgabe kontrollieren. Gesamtstand muss exakt vorheriger Stand plus
   angezeigter Differenz sein; Belohnungshöhe kann vom Lernstand abhängen.
   Ein schnelles zweites Antippen darf dieselbe Lösung nicht doppelt vergüten.
4. Je Klasse zusätzlich die drei anderen Tabellen-Themen öffnen, je einen
   passenden Hilfehinweis ansehen und eine unabhängig geprüfte richtige
   Antwort eingeben. Silbenhilfe verwendet das erfragte Wort; Sachhilfe erklärt
   den Inhalt; Logikoptionen haben genau eine regelgerechte richtige Antwort.
   Die nächste Aufgabe darf keinen alten Hilfehinweis behalten. Damit sind
   mindestens 16 echte Aufgaben in allen vier Fächern abgeschlossen.
5. Nach einer erfolgreichen Aufgabe nach `Start` wechseln, App in Hintergrund
   und zurück holen, dann normal beenden/neustarten. Klasse, bearbeitetes
   Fach/Thema, Lernfortschritt und Sterne/XP müssen erhalten bleiben.
   Bei abgeschaltetem Netz eine neue Aufgabe inklusive Hilfe lösen.
6. Eine ungelöste Aufgabe im schmalen Außenbildschirmformat öffnen, Hilfe zeigen,
   in ein breites Innenbildschirmformat wechseln und beantworten. Prompt,
   Antworten und Hilfe bleiben erreichbar; Lumo verdeckt keine Antwortfläche.
   Diese Prüfung dokumentiert Emulatorgrößen, keine echte Galaxy-Z-Fold-Prüfung.

Optional zusätzlich eine Mathematikaufgabe in `Schularbeit` absichtlich falsch
beantworten: keine Aufgabenhilfe, kein XP-Bonus; den angezeigten Sternabzug
gegen den gespeicherten Stand prüfen. Das ist ein anderer Modus als Schritt 1.

Onlineprüfung: Den bereits belegten Livefehler aus PR #155 nicht als aktive KI
werten. Falls im Androidtest die Onlinefreigabe ausdrücklich eingeschaltet wird,
muss der Elternbereich fehlendes Providerkontingent verständlich anzeigen;
lokale Aufgabenhilfe bleibt benutzbar. Bekannter Livezustand: Tutor HTTP 503
`openai_quota_exceeded`, Provider HTTP 429 `type=insufficient_quota`, ausgerollte
SHA `fcca1f372ea24ea5a5057d79688cc8e0f2ad7c06`. Keine Schlüssel-/Tarifänderung.

Für jeden Fall festhalten: Klasse/Fach/Thema, Prompt, Antwort, erwartetes und
tatsächliches Ergebnis, Sterne/XP vorher/nachher, Screenshot und bestandene
oder offene Schritte. Fehlende Tests ausdrücklich als nicht ausgeführt führen.
