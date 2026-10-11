# Lumo: getrenntes freiwilliges Vorlernen und geführter Unterricht

## Gesicherter Speicher-Meilenstein

Der vorhandene `ProgressRepository` und `LearningProfileEngine` wurden um ein
pro Kind getrenntes, versionsgeprüftes Entdeckungsfeld erweitert. Es gibt keine
zweite Datenbank. Die bestehende `LearningModuleProgress`-Schreibgrenze übernimmt
Besitzerbindung, Wiederholung fehlgeschlagener Schreibvorgänge und Lebenszyklus.

Vorlernen ist bei neuen Profilen ausgeschaltet. Eine Höchstschulstufe von 1 bis 4
ist explizit vorgesehen. Ein Widerruf bewahrt bereits entdeckte Themen.
Unbekannte, neuere oder beschädigte Speicherformate bleiben unverändert und
werden nicht stillschweigend durch leere Daten ersetzt.

Vorlernantworten verändern weder Schulklasse noch reguläre Kompetenzzähler,
Tagesziel, Aufgabenprotokoll, Cosmos oder Wallet. Voraussetzung, begleitetes
Üben, selbstständiges Üben und Überprüfung haben getrennte lokale Zähler.
Diese Beobachtungen sind keine Diagnose und keine nachgewiesene Beherrschung.

## Tatsächlich ausgeführte Prüfungen des Speicher-Meilensteins

- 46 Flutter-Tests bestanden: 13 neue Vorlernprüfungen sowie vorhandene
  Speicher-, Profilwechsel-, Mathematikmodul- und Plus-bis-10-Regressionen.
- Analyse der fünf geänderten Quell-/Testdateien: keine Probleme.
- Ein nativer `SharedPreferences.setValue`-Rückgabewert `false` bleibt ein Fehler.
  Erneut speichern zählt dieselbe akzeptierte Antwort nicht doppelt.
- Getrennte fiktive Profile A/B; reguläre gespeicherte Daten bleiben bytegleich.
- Nur der explizite bestehende Reset-Pfad wurde um das neue Feld ergänzt.
  Kein Kinderprofil und kein realer Lernstand wurde zurückgesetzt.

## Noch nicht durch diesen Meilenstein nachgewiesen

Die Speicherprüfungen sind keine Android- oder Hörabnahme des Vorlernens.
Die vollständige Unterrichtsoberfläche, der Elternanschluss und ihre
interaktiven Prüfungen werden im nächsten Meilenstein ergänzt.
Eine explizite lokale Elternbestätigung ist keine verifizierte Erwachsenenidentität.
Eine geeignete endgültige Elternprüfung bleibt eine Release-Freigabebedingung.

APK 1929 bleibt unverändert und enthält diese neuen Funktionen noch nicht.
Ihr tatsächlich bestandener Android-16-x86_64-Prüflauf ist
[38138064509](https://github.com/Ullmann27/lumo-lernen/actions/runs/38138064509).
Physisches Samsung/ARM64, menschliche Hörabnahme, vollständiger Inhaltsaudit
und Google-Play-Abnahme bleiben getrennte offene Prüfungen.

## Pädagogische Grundlage der ersten Unterrichtsabläufe

Der [geltende österreichische Volksschullehrplan im RIS](https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275)
verlangt in der ersten Schulstufe additive Rechenoperationen bis mindestens 20
und in der zweiten Schulstufe additive und multiplikative Rechenoperationen im
Zahlenraum 100. Das kleine Einmaleins wird laut Lehrplan in der zweiten Schulstufe
erarbeitet und weitgehend gefestigt, in der dritten automatisiert.
Die ersten kleinen Unterrichtsabläufe sind nur ein Ausschnitt davon.
Vollständige Lehrplanabdeckung und externe österreichische Fachprüfung werden
nicht behauptet.
