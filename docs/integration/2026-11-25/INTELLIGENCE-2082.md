# LUMO Intelligence 2.0 – Kandidat 0.14.9+2082

Stand: 25. November 2026. Quellcode integriert; neue Ausführungsprüfungen stehen beim Anlegen dieses Dokuments noch aus. Kein bestandener 2082-Build wird aus dem erfolgreichen 2081-Lauf abgeleitet.

## Nachvollziehbare Quellen

- Flutter 2081: `7ece88343c005920be850b3413a3bb342c42746c`.
- Bereits vorhandener Intelligence-Zweig: `b978499b848d46ada45693a7bffc79d88be0ec26`; dessen Lernplan und Profilwechselkorrektur wurden erhalten.
- Echte Diagramme: `48368f6e18bb6c7a0ae1485946ab43171bfac881`.
- Individuelle Lernhilfe: `6d709bc2e004a2da5569039e4bed61eaa803bcb5`.
- Hausaufgaben-Auswertung: `046457c503f1808c4f04e2fc5f2034be646f9164`, anschließend präzisierter Hinweis zur begrenzten Protokollaufbewahrung.
- Native 2081-Basis: `c814e35249e4038f903d1fca3e19bb4751040a43`.
- Neuer Godot-Pin: `b22f3bb424c6488f107ed6a772e19c878a837154`.

## Sichtbare Änderungen

1. Elternzentrum und Einzelberichte zeigen ein echtes Kompetenz-Radar und vier datierte Siebentagesabschnitte der letzten 28 Kalendertage. Zahlen stammen ausschließlich aus dem vorhandenen Aufgabenprotokoll des ausgewählten Kindes. Leerdaten bleiben leer, fehlende Wochen bleiben Lücken.
2. Selbstständige Antworten und Bearbeitungen mit Hilfe sind getrennt. Radar, Trefferquote und Verlauf verwenden Antworten ohne Hilfe; das Tempo wird nicht als Kompetenz bewertet. Kleine Stichproben bleiben ausdrücklich gekennzeichnet.
3. Der bestehende adaptive Plan und die neuen Diagramme verwenden denselben profilgebundenen Snapshot. Verzögerte Daten eines zuvor ausgewählten Kindes werden verworfen.
4. Der Tagesplan beachtet fällige Wiederholungen und den Themenfilter auch beim Ergänzen neuer Einheiten. Ein einzelner Erfolg ohne Übertragungsnachweis wird nicht als bestätigte Stärke ausgegeben.
5. Deutsch, Silben, Bild-/Wortlesen und Mathematik erhalten passende bestehende Hilfen. Ein erster Silbenhinweis verrät nicht durch ein vollständiges Silbenbild die Lösung. Mathe-Erklärungen zu Fehlern benötigen eine überprüfte Aufgabe und eine tatsächliche abweichende Antwort.
6. Reale Lehrkraftaufgaben zeigen bearbeitete, richtige, selbstständige und unterstützte Antworten getrennt. Nach Abschluss bleiben bis zu drei Ergebnisse beim Kind sichtbar; konkrete Aufgaben, Antworten und vorhandene Lösungen sind aufklappbar.
7. Hausaufgaben zählen pro Kind nur eindeutige Antworten zum zugewiesenen Thema ab Zuweisung, ohne Zukunftsdaten. Die Auswertung verwendet die ersten Zielantworten im aktuell vorhandenen Protokoll. Das vorhandene Protokoll ist begrenzt; es wird keine unbegrenzte oder dauerhaft eingefrorene Ergebnisspeicherung behauptet. Mehrere Aufträge desselben Themas können dieselben Antworten abdecken.
8. Neun World-Bewohner haben eigene Interessen, 36 beschriebene Tagesaktivitäten, erreichbare Alltagsdialoge und eine Verbindung zu ihren vorhandenen Lernaufträgen. Pausen stoppen den Tageslauf; Gespräche erzeugen keine erfundenen Lernleistungen oder Belohnungen.

## Erhaltene Grundlage und Grenzen

Das dunkelblaue Originaldesign, originale Figuren, Lernmodule, Schreibtrainer, Journal und Speicherformate werden beibehalten. Der Demo-Modus bleibt getrennt verfügbar. Keine neue Datenbank, Cloudübertragung oder Kontoverbindung wird eingeführt. Die Schulverwaltung bleibt lokal; eine geräteübergreifende Schulverwaltung wird hier nicht als fertig bezeichnet.

Die neun World-Figuren verwenden weiterhin sitzende Kart-Rigs ohne Gehclip. Sie erhalten Gesten und Dialoge, bleiben aber am Standort. Kurze kollisionsgeprüfte Wege sind im Code nur für einen tatsächlich vorhandenen passenden Gehclip freigegeben. Beschriebene Tätigkeiten bedeuten kein animiertes Umräumen von Requisiten. Neue Fahrer-/Laufmodelle, vollständige Fotohandschrift-Nachhilfe, komplette Kart-Politur und physische Fold7-Performance sind nicht durch diesen Patch erledigt.

Der Native-Vergleich enthält fünf Änderungen ausschließlich unter scripts/ und docs/. Alle Produktionsmodelle und ihr Manifest sind bytegleich zur 2081-Basis. Der Exporter ergänzt nur den exakt überprüften neuen Pin; Inhalts-, Pfad-, Hash- und Ablehnungsprüfungen bleiben erhalten. Historische 2081-Exporttests bleiben als solche bestehen, aktuelle 2082-Gegenproben kommen hinzu.

## Prüfpfad

Die lokale Ausführungsumgebung war nicht verfügbar. Änderungen wurden über den GitHub-Connector in eigenen Zweigen gesichert und gegenseitig statisch geprüft. Das ersetzt keine Kompilierung.

Der eigene Workflow `.github/workflows/lumo-intelligence-2082.yml` startet zuerst gezielte Flutter-Analyse/Regressionen. Danach folgt die erhaltene vollständige 2081-Pipeline: Flutter-Gesamtsuite, JVM-Verträge, Godot-Kernprüfungen, World-Prüfungen einschließlich der zwei neuen Routine-Skripte, frisch signierte ARM64/x86_64-Pakete, Herkunfts-/PCK-/Signaturkontrolle und Android-Tour mit sieben Pflichtspielstarts und lokaler Sicherung/Wiederherstellung.

Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`. Erwartete Familien-Testzertifikat-SHA256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Die Signatur ist keine Play-Produktionssignatur.

Erst tatsächliche Ergebnisse dieses neuen Quellstands erlauben eine Auslieferungsaussage. Hauptzweige und bisherige Releases bleiben unverändert.
