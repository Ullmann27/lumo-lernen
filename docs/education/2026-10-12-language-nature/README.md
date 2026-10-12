# Geführte Deutsch- und Sachunterricht-Piloten

Getrennter Entwicklungsbranch sol/lumo-guided-language-nature-2026-10-12, auf d205014 (1932) aufgebaut. Diese Kurse sind noch nicht in der ausgelieferten/gebauten 1932-APK. Versionsplanung0.12.26+1933; kein neuer Android-Bau gestartet.

## Implementierter Unterricht

- Deutsch → Silben: Sprechstücke statt Buchstaben zählen, animiertes BeispielBa–na–ne, gemeinsame ÜbungenSonne/Tomate, neue WörterBlume/Rakete selbst lösen. Selbstständige Wörter werden unsegmentiert gezeigt; Annahme einer Hilfe öffnet erst die passenden Sprechstücke. Alternative Hinweise verwenden Klatschen oder Finger.
- Sachunterricht → Pflanzen: Wurzel, Stängel, Blatt und Blüte mit Funktionen. Originale editierbare Vektorgrafik im tatsächlichen Flutter-Renderer; neue Frage zeigt keine Namensbeschriftung. Ein anderes Pflanzenbild prüft den Transfer. Zugängliche Beschreibung nennt die hervorgehobene Position statt die Lösung.
- Empfehlungen starten das tatsächlich passende Fach. Die bestehende Aufgaben-/Profil-/Speicherarchitektur wird benutzt; kein zweites Fortschrittssystem. Nur zwei selbstständige Antworten pro Kurs zählen im Schulfortschritt. Beispiel- und begleitete Antworten gelten nicht als selbstständige Beherrschung.

## Tatsächliche Prüfungen

105 Unterrichtsprüfungen (2 optionale Aufnahmefälle übersprungen) bestanden; zusätzlich6 komplette echte Unterrichtsabläufe auf Smartphone390×844, schmalem320×568 mit2×Schrift sowie Fold-Ziel967×805. Falsche Antwort, zwei unterschiedliche angenommene Hinweise, korrekte Antworten, Abschluss, Neustart und separates ProfilB geprüft. Vorhandener Mathematikdatensatz und Wallet bleiben unverändert. Automatischer Inhaltsaudit40982 Aufgaben/22 geführte Antwortschritte bestanden; Analyse ohne Fehler.

Bilder sind echte Flutter-Testlaufzeitaufnahmen, keine Android-, physischen Fold- oder Konzeptbilder. Beispiel/selbstständige Aufgabe/Hilfe sind unterschiedliche tatsächliche Zustände dieser Kurse, kein behaupteter Versionsvergleich.

Offen: vollständige exakte CI, unabhängiger Review, neues Android-Update/Unterrichtsprüfung und APK-ZIP, physische Geräte, menschliche Sprachausgabe- und externe österreichische pädagogische Fachabnahme. Die zwei Piloten sind keine vollständige Lehrplanabdeckung.

Ruling: unabhängige Folgearbeit im isolierten Branch während der unveränderte 1932-Kandidat gebaut/geprüft wird. Die Auslieferung1932 behält Priorität und wird durch diesen Branch nicht verändert. Enumbezeichnung GuidedLessonConcept ist jetzt fachneutral; vorhandene mathematische Themen, IDs, Mengen und Speicherfelder bleiben erhalten.
