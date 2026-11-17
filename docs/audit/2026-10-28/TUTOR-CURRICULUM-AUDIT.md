# Tutor- und Klassenprüfung, Meilenstein 2001

Basis PR413 `a79ff08c`, neuer isolierter Branch. Original-Lumo, Godot-Pin,
Paket und Signaturanforderungen bleiben; Schreibtrainer-/Journalquellen unverändert.

## Systematisch ausgeführter Aufgaben-Audit

`dart run tools/audit_learning_sessions.dart docs/evidence/tutor-2001/curriculum-audit.json`
prüfte 79.200 synthetische Aufgaben in 268 Kombinationen. Keine ungültigen
Antwortoptionen, fehlenden Lösungen oder leeren Erklärungen. Das ist ein
Generator-Audit, keine fachliche Abnahme durch eine Lehrperson.

| Klasse | geprüfte Fach-/Themenzeilen einschließlich Alle | Zeilen mit weniger als 12 verschiedenen Aufgaben |
|---|---:|---:|
| 1 | 77 | 22 |
| 2 | 66 | 11 |
| 3 | 64 | 13 |
| 4 | 61 | 9 |

In jeder Klasse: Mathematik, Deutsch, Lesen, Rechtschreibung, Schreiben,
Englisch, Sachunterricht und Logik. Originaldaten pro Thema im JSON.
55 kleine Aufgabenbestände sind erfasst; sie werden nicht als vergrößert ausgegeben.

## Anschlüsse und Grenzen

| Oberfläche | Anschluss in 2001 | noch offen |
|---|---|---|
| reguläre Aufgaben, alle acht Unterrichtsbereiche und Klassen 1–4 | reale Task-/Answer-/Help-Ereignisse über zentrale Engine; Hilfe klebt an Aufgabe; Exam-Sperre | fachlich neue Werkstätten jenseits Stellenwert |
| Zehner-Werkstatt | zählen, echte 10er-Bündelung, Zerlegung, andere Zahl konstruieren, Rückfrage; nur neuer unabhängiger Transfer zählt | Drag-and-drop als zusätzliche Eingabeform |
| Plus bis 10, eigene Akademie | bestehende Ereignisse gehen auch in zentrale Steuerung und Journal | eigene Angebotsdarstellung weiter vereinheitlichen |
| übrige bewertete Akademiemodule | bestehender gemeinsamer Speicherpfad erhält echte, stabile Aufgabenidentität und Hilfe-Metadaten | vollständig sichtbarer Tutor-/Hilfeanschluss auf allen tiefen Unterseiten |
| Wort-Diktat | komplexes Canvas/Selbstbewertung vollständig erhalten | Selbstbewertung wird ausdrücklich NICHT zu unabhängig geprüfter Transferevidenz |
| Schreibtrainer und Journal | Implementierungen unverändert; bestehende Regressionen bleiben | keine automatische Bewertung freier Handschrift erfinden |
| Lesen/Geführte Lektionen | vorhandener Companion-Kontext wird von der zentralen Bussteuerung übernommen | nicht jede Lesebeobachtung ist bereits als Kompetenznachweis gespeichert |
| Heute mit Lumo | aktuelles Profil + aktueller Klassenfilter + vorhandenes Journey; drei Schritte, 5/4/3 Minuten, direkter Aufgabenstart | Dauer ist eine transparente Schätzung, keine Zeitmessung |
| Sprache | bestehende lokale Stimme/Einwilligung und expliziter Mikrofonstart erhalten | lokale Erkennung auf physischem Zielgerät nicht nachgewiesen |

Bewertete Akademie: Plus, Minus, Zahlen bis 10/100, Formen, Uhr, Geld,
kleines/großes Einmaleins, Brüche, Artikel, Mehrzahl, Wortarten, Zeitformen,
Tiere, Farben, Jahreszeiten, Wetter und Verkehr. Stabile Identitäten beruhen
auf dem tatsächlich gezeigten Material, nicht auf zufälliger Antwortreihenfolge.

## Visuelle Prüfung

Neue Screenshots stammen aus tatsächlich gerenderten HomeContent- und
LearningContent-Routen im Flutter-Testprozess, mit produktiven Widgets,
Originalgrafiken und Nunito-Schrift. Sie sind keine Mockups und keine
Android-/Fold7-Geräteaufnahmen. 280dp/2x, 360dp und 880dp werden tatsächlich
bedient; der Tagesplan startet die vorhandene Aufgabe. Zählen erzeugt keine
Transferevidenz, Konstruktion plus Rückfrage schon. Kein zusätzlicher Reward.

Bei 280dp/2x wurde ein echter 12px-Überlauf im bestehenden Hilfe-Button
reproduziert und durch umbrechende Beschriftung behoben. Doppelte Bildhilfe
wird für die interaktive Stellenwert-Werkstatt nicht zusätzlich eingeblendet.

## Release-Schutz

Build 2000 a6558161 wird nicht verändert. Neue Quellversion 0.12.89+2001,
eigenes 2000→2001-Gate und eigenes unveränderliches Chrome-Release.
Keine APK-Freigabe allein durch diese Dokumentation oder Flutter-Tests.
