# Intelligence 2.0 – Fachanalyse und Hilfenutzung

Basis: 6574b19f92abb4f6421fd3074cec09738dc0974a (erfolgreich gebauter 2082-Stand). Dieses begrenzte Folgepaket erweitert die gemeinsame echte Lernanalyse von Eltern- und Lehrerberichten, nicht die Demo. Es bewahrt HoloPanel und das originale globale Design.

- Fachwahl mit Umschalten von Radar, 28-Tage-Verlauf und Aktivitätskarten. Die globale Summenzeile bleibt unverändert; die Fachwahl gilt für die darunterliegenden Analysen.
- Pro Fach: selbstständige Trefferquote, Anzahl und Anteil mit Hilfe, Median der tatsächlich vorhandenen positiven Zeitmessungen selbstständiger Antworten einschließlich Messanzahl. Fehlende Messwerte werden nicht erfunden.
- Dieselbe bestehende Profil-, Assessment-, Duplikat- und Zeitgrenze wie die 2082-Auswertung. Fachwahl wird beim Profilwechsel oder fehlendem Fach zurückgesetzt. Keine neuen gespeicherten oder übertragenen Daten, keine Noten, keine Geschwindigkeitspunkte, keine Änderung von Förderplänen.
- Regressionen für Filter, kleine und große Bildschirme, Profilwechsel, Median, fehlende Zeitwerte, Hilfen und Datentrennung. Separate CI-Prüfung; kein neuer APK-Bau und kein Merge nach main. PR #554 bleibt separat und wird nicht überschrieben.
- Noch keine physische Geräteprüfung. Die tatsächliche CI-Ausführung muss dem neuen Commit zugeordnet werden.
