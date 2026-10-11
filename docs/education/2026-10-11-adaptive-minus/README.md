# Lokale adaptive Hilfe und Minus über den Zehner

Fortsetzung auf dem abgenommenen Android-1930-Stand von PR #266; keine Änderung
am ausgelieferten APK. Neue Produktversion: 0.12.24+1931. Paketkennung,
Testsignatur, Godot-Revision, Kinderprofile, Speicherformate und Originalstimmen
bleiben erhalten. Kein kostenpflichtiger Provider und kein Mikrofonaufruf.

## Tatsächlicher Produktfortschritt

- Der lokale Begleiter kündigte bei wiederholten Fehlern einen anderen Schritt
  an, wiederholte aber einen unveränderten Modulhinweis. Jetzt verwendet er die
  vorhandene Aufgabenhilfe: Zählstrategie nach zwei Fehlversuchen, passende
  Zerlegung nach drei. Bewusst wechselnde Modulhinweise haben weiterhin Vorrang.
- Die dritte Rechenhilfe erklärt 7+5 als 3 zum Zehner und 2 weitere Schritte;
  12−5 als 2 bis zehn und 3 weitere Schritte zurück. Sie nennt keinen Endwert.
  Sichtbare Aufgaben ohne Gleichheitszeichen werden ebenfalls erkannt.
- Ein neuer achtteiliger Unterricht für „Minus bis 20“ erklärt 12−5, begleitet
  13−6 und lässt 14−8 sowie 11−4 selbstständig lösen. Eigenständige Versuche
  nutzen ausschließlich die bestehende, profilspezifische Speicherwarteschlange.
- Alle zwölf Originaläpfel bleiben im Beispiel einzeln vorhanden. Zuerst wandern
  zwei, dann drei in die Wegnahmefläche. Bei eigenständigen Fragen wird die
  Endmenge nicht vorweggenommen. Null ist eine eindeutige Antwortoption.

## Prüfung und Grenzen

Reproduzierte Fehler vor der Änderung: wiederholter Hinweis und fehlende
Minus-Einführung. Danach bestanden 67 gezielte Hilfs-/Mengen-/Rechentests und
21 Unterrichts-/Aufnahmeprüfungen. Neue Subtraktionswege wurden zusätzlich in
270 Zahlen-/Antwortfällen geprüft. Der vorhandene vollständige Inhaltsaudit
wird weiterhin ausgeführt; das ist keine externe pädagogische Fachabnahme.

Die beigefügten Bilder sind echte **Flutter-Widget-Laufzeitaufnahmen** bei
360×800 und einer simulierten Fold-Zielgröße. Sie sind keine Android- oder
physische Fold-Abnahme. Der neue Workflow `lumo-education-1931.yml` baut den
sauberen Kandidaten einmal und prüft anschließend Android 16/API 36, das Update
von 1930, lokale Stimme, Plus, Minus, getrenntes Vorlernen und Neustart. Eine
fertige 1931-Auslieferung wird erst nach tatsächlichem erfolgreichen Lauf und
Integritätsprüfung beansprucht. Vollständige Flutter-CI läuft auf dem exakten
PR-Commit; die ZIP-Abnahme verlangt deren erfolgreiches Ergebnis.

Geführte Einführungen bestehen nun für Plus bis 20, Minus bis 20 und gleiche
Gruppen/Einmaleins. Geführte Einführungen für übrige Mathematikthemen sowie
Deutsch und Sachunterricht bleiben Inhaltslücken. Die vorhandenen regulären
Aufgabengeneratoren werden dadurch nicht ersetzt. Menschliche Sprachqualität,
physisches ARM64/Fold und externe Lehrplanprüfung bleiben offen.
