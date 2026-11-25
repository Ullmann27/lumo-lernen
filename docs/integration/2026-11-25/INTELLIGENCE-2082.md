# LUMO Intelligence 2.0 – Kandidat 0.14.9+2082

Stand: 25. November 2026. Reale Lernanalysen, Hausaufgaben und Coach sind integriert und gezielt ausgeführt geprüft. Die neuen Karten-/Schachabläufe und bisherigen Regeln bestehen auf dem unten genannten Native-Pin. Der gemeinsame APK-/Android-Lauf wird mit diesem Commit neu angefordert; eine fertige 2082-APK oder abgeschlossene Bildprüfung wird hier noch nicht behauptet.

## Nachvollziehbare Quellen

- Flutter 2081: `7ece88343c005920be850b3413a3bb342c42746c`.
- Bereits vorhandener Intelligence-Zweig: `b978499b848d46ada45693a7bffc79d88be0ec26`; dessen Lernplan und Profilwechselkorrektur wurden erhalten.
- Echte Diagramme: `48368f6e18bb6c7a0ae1485946ab43171bfac881`.
- Individuelle Lernhilfe: `6d709bc2e004a2da5569039e4bed61eaa803bcb5`.
- Hausaufgaben-Auswertung: `046457c503f1808c4f04e2fc5f2034be646f9164`, anschließend präzisierter Hinweis zur begrenzten Protokollaufbewahrung.
- Native 2081-Basis: `c814e35249e4038f903d1fca3e19bb4751040a43`.
- Neuer Godot-Pin: `62108c0355f860ab9a0a020ecb5f3f941f1032e9` (World plus ruhige, geordnete Karten-/Schachzüge).
- Integrierter Flutter-Vorprüfstand: `f346db8e21bbc7ee7202a444b866bb1f862d85cb`.
- Unabhängige Kompetenzanalyse: `a933456b85edf3ddf205d46d44402b438c8fed05`; profilgebundener Coach: `a4aa0c26afd365e92f404e27738eebba85691627`.

## Sichtbare Änderungen

1. Elternzentrum und Einzelberichte zeigen ein echtes Kompetenz-Radar und vier datierte Siebentagesabschnitte der letzten 28 Kalendertage. Zahlen stammen ausschließlich aus dem vorhandenen Aufgabenprotokoll des ausgewählten Kindes. Leerdaten bleiben leer, fehlende Wochen bleiben Lücken.
2. Selbstständige Antworten und Bearbeitungen mit Hilfe sind getrennt. Radar, Trefferquote und Verlauf sowie die bisherigen Lehrer-/Einzelberichte verwenden Antworten ohne Hilfe für Kompetenzquote, Stufe und Trend. Kleine Stichproben bleiben ausdrücklich gekennzeichnet; eine Kompetenzstufe erfordert mindestens fünf unabhängige Antworten. Gleichnamige Kompetenzen verschiedener Fächer bleiben getrennt. Bearbeitungszeit allein bewertet keine Kompetenz.
3. Der bestehende adaptive Plan und die neuen Diagramme verwenden denselben profilgebundenen Snapshot. Verzögerte Daten eines zuvor ausgewählten Kindes werden verworfen. Das gilt auch für Coach-Texte und Aufgabenrouten bei Profil-/App-Wechsel, verspäteter Antwort oder Ladefehler; alte Hinweise werden unmittelbar entfernt.
4. Der Tagesplan beachtet fällige Wiederholungen und den Themenfilter auch beim Ergänzen neuer Einheiten. Ein einzelner Erfolg ohne Übertragungsnachweis wird nicht als bestätigte Stärke ausgegeben.
5. Deutsch, Silben, Bild-/Wortlesen und Mathematik erhalten passende bestehende Hilfen. Ein erster Silbenhinweis verrät nicht durch ein vollständiges Silbenbild die Lösung. Mathe-Erklärungen zu Fehlern benötigen eine überprüfte Aufgabe und eine tatsächliche abweichende Antwort.
6. Reale Lehrkraftaufgaben zeigen bearbeitete, richtige, selbstständige und unterstützte Antworten getrennt. Nach Abschluss bleiben bis zu drei Ergebnisse beim Kind sichtbar; konkrete Aufgaben, Antworten und vorhandene Lösungen sind aufklappbar.
7. Hausaufgaben zählen pro Kind nur eindeutige Antworten zum zugewiesenen Thema ab Zuweisung, ohne Zukunftsdaten. Die Auswertung verwendet die ersten Zielantworten im aktuell vorhandenen Protokoll. Das vorhandene Protokoll ist begrenzt; es wird keine unbegrenzte oder dauerhaft eingefrorene Ergebnisspeicherung behauptet. Mehrere Aufträge desselben Themas können dieselben Antworten abdecken.
8. Neun World-Bewohner haben eigene Interessen, 36 beschriebene Tagesaktivitäten, erreichbare Alltagsdialoge und eine Verbindung zu ihren vorhandenen Lernaufträgen. Pausen stoppen den Tageslauf; Gespräche erzeugen keine erfundenen Lernleistungen oder Belohnungen.
9. Karten werden weich beschleunigt und abgebremst. Die normale Kartenbewegung dauert 0,82 Spielsekunden; eine KI-Aktion beginnt mit 0,90–1,38 Sekunden Denkpause. Mehrere Karten werden nacheinander übergeben. Eingabe und sichtbares aktives Namensschild wechseln erst nach Ende der Aktion.
10. Schach zeigt den Zug in 2D und 3D. Zuerst endet der Kinderzug, dann folgt mindestens 0,95 Sekunden aktive Denkzeit und anschließend die 0,95 Sekunden lange KI-Bewegung; die tatsächliche Suche darf länger dauern. Rochade bewegt König und Turm nacheinander. Pause hält Bewegungen und Denkzeit an; Neustart, Menü und Zurück verwerfen veraltete Aktionen. Reduzierte Animationen beschleunigen Denk-/Lesepausen nicht.

## Erhaltene Grundlage und Grenzen

Das dunkelblaue Originaldesign, originale Figuren, Lernmodule, Schreibtrainer, Journal und Speicherformate werden beibehalten. Der Demo-Modus bleibt getrennt verfügbar. Keine neue Datenbank, Cloudübertragung oder Kontoverbindung wird eingeführt. Die Schulverwaltung bleibt lokal; eine geräteübergreifende Schulverwaltung wird hier nicht als fertig bezeichnet.

Die neun World-Figuren verwenden weiterhin sitzende Kart-Rigs ohne Gehclip. Sie erhalten Gesten und Dialoge, bleiben aber am Standort. Kurze kollisionsgeprüfte Wege sind im Code nur für einen tatsächlich vorhandenen passenden Gehclip freigegeben. Beschriebene Tätigkeiten bedeuten kein animiertes Umräumen von Requisiten. Neue Fahrer-/Laufmodelle, vollständige Fotohandschrift-Nachhilfe, komplette Kart-Politur und physische Fold7-Performance sind nicht durch diesen Patch erledigt.

Der Native-Vergleich zur 2081-Basis enthält zwölf geänderte Dateien unter scripts/, docs/ und .github/workflows/. Alle Produktionsmodelle, Texturen und ihr Manifest sind bytegleich zur 2081-Basis. Der Exporter ergänzt nur den exakt überprüften neuen Pin; Inhalts-, Pfad-, Hash- und Ablehnungsprüfungen bleiben erhalten. Historische 2081-Exporttests bleiben als solche bestehen, aktuelle 2082-Gegenproben kommen hinzu.

## Prüfpfad

Die Änderungen liegen in eigenen Git-Zweigen und wurden unabhängig gelesen sowie in der passenden Flutter-/Godot-Umgebung ausgeführt geprüft. [Flutter-Originalbelege](../../evidence/intelligence-2082-focused-20261125/README.md) und [native Originalbelege](../../evidence/intelligence-2082-native-tables-20261125/RESULT.json) halten Quellstand, Lauf und Artefakthashes fest.

| Ausgeführter Vorlauf | Quelle | Ergebnis |
| --- | --- | --- |
| Vollständige Flutter-Analyse und 16 gezielte Dateien | f346db8e | 114 Tests bestanden, 0 Analysefehler; 5 Warnungen und 299 Hinweise bleiben sichtbar |
| Neue Karten-/Schachabläufe | 62108c03 | 133 Prüfungen, 0 Fehler |
| Kartenregeln und Massenspiele | 62108c03 | 212.968 Prüfungen, 148.154 Züge, 0 Fehler |
| Schachregeln | 62108c03 | 238 Prüfungen, 0 Fehler |
| Vollständiger Kartentisch | 62108c03 | 634 Prüfungen, 0 Fehler |
| Vollständiger Schachtisch | 62108c03 | 919 Prüfungen, 0 Fehler |
| World-Routinen | b6562a76; diese World-Dateien bleiben unverändert | 124 Modell- und 57 Szenenprüfungen, 0 Fehler |

Der frühere gemeinsame Lauf 45545648754 bestand auf 250ad2c die vollständige Flutter-Suite mit 3.640 bestandenen und 193 übersprungenen Tests. Danach scheiterte er am neuen World-Testaufbau des alten Pins b22f3bb; er erzeugte keine APK. Dieser Testaufbau ist im aktuellen Native-Pin korrigiert. Frühere Fehlbelege werden nicht zu Erfolgen umgedeutet.

Der erste Renderer-Lauf [45567127413](https://github.com/Ullmann27/lumo-godot/actions/runs/45567127413) erreichte bei der Quartett-Endprüfung nach 12,161 Sekunden Rechnerzeit erst 4,658 Sekunden Spielzeit. Der gültige, nicht pausierte Kartentween bewegte sich im Folgedump weiter. Dieser fehlgeschlagene Beleg bleibt erhalten. Der finale Pin ändert gegenüber bfc1eda0 ausschließlich die Prüfzeitmessung: weiterhin höchstens zwölf Spielsekunden für die Übergabe, zusätzlich ein fester Wächter von 60 Sekunden Rechnerzeit. Der neue Headless-Lauf [45568517233](https://github.com/Ullmann27/lumo-godot/actions/runs/45568517233) besteht auf exakt 62108c03; die Quartettfolge benötigte dort 6,050 Spiel- und Rechnersekunden. Produktdateien bleiben bytegleich.

Die neue strenge Rendereraufnahme [45569486039](https://github.com/Ullmann27/lumo-godot/actions/runs/45569486039) prüft exakt denselben finalen Native-Pin. Sie ist beim Anfordern des gemeinsamen APK-Laufs noch offen. Öffentliche Auslieferung setzt ihren Abschluss und die Sichtkontrolle voraus. Software-Rendererbilder belegen keine Fold7-Bildrate.

Der eigene Workflow `.github/workflows/lumo-intelligence-2082.yml` startet zuerst gezielte Flutter-Analyse/Regressionen. Danach folgt die erhaltene vollständige 2081-Pipeline: Flutter-Gesamtsuite, JVM-Verträge, Godot-Kernprüfungen, World-Prüfungen einschließlich der zwei neuen Routine-Skripte, fünf strenge Karten-/Schachproben mit denselben Aufrufen wie im nativen Vorlauf, frisch signierte ARM64/x86_64-Pakete, Herkunfts-/PCK-/Signaturkontrolle und Android-Tour mit sieben Pflichtspielstarts und lokaler Sicherung/Wiederherstellung.

Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`. Erwartete Familien-Testzertifikat-SHA256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Die Signatur ist keine Play-Produktionssignatur.

Erst tatsächliche Ergebnisse dieses neuen Quellstands erlauben eine Auslieferungsaussage. Hauptzweige und bisherige Releases bleiben unverändert.
