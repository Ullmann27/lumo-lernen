# Lumo Lernatelier – ausführbarer Entwicklungsblock

Auftrag: autonome Verbesserung der bestehenden Lernabteilung; Original-Lumo, Profile, Schreibtrainer, Journal, Speicherstände und Android-Qualität bewahren. Lumo Kart bleibt unberührt. Architekturarbeit, ausdrücklich zur unmittelbaren Umsetzung beauftragt; keine zusätzlichen Designfreigaben.

## Geprüfte Basis und Inventar

Basis: `0e6373e3f2e7b5abd2322280d996c0392d993b0e`, PR #368, Nachfolger von PR #367 (`4124bda9`). Der vollständige Androidlauf #39104800278 auf dieser Basis meldet SUCCESS. Main ist nicht der aktuelle Entwicklungsstand. Isolierter Worktree `/workspace/lumo-learning-work`, Branch `codex/lumo-learning-lab-2026-10-18`.

Vorhanden: 19 direkte Akademie-Module (u.a. Mengen, Plus/Minus, Multiplikation, Brüche, Uhr/Geld, Wortarten, Zeitformen, Natur); klassenübergreifende Übungen und Schreibansichten; AdaptiveTaskRenderer; geführte Mathe-/Sprach-/Natur-Nachhilfe mit lokalen überprüften Aufgaben; Lesebegleiter, Schreibtrainer und Journal. `LearningModuleProgress` reserviert den ursprünglichen Profilbesitzer und wiederholt fehlgeschlagene Speicherungen. `LearningProfileEngine`/`ProgressRepository` speichern lokal pro Kind, Entdeckungsfortschritt bleibt von Schulfortschritt getrennt. LumoVoice und die vorhandenen Originalposen sind zentral angebunden. Nunito, MaterialIcons und Linux-Noto-Emoji müssen vor Testaufnahmen geladen sein.

## Architekturentscheidung

Erweiterung der vorhandenen Komponenten um ein optionales Lernatelier, statt einer Ablösung der vielen bestehenden Aufgabenrenderer. Das liefert prüfbare interaktive Aufgaben mit geringem Integrationsrisiko. Ein rein visueller Gesamtumbau wäre breit, würde aber weder aktiven Abruf noch fachlich passende Hilfe sicherstellen. Ein neuer Cloud-KI-Tutor würde zusätzliche Abhängigkeiten und Datenschutzrisiken einführen. Das Atelier läuft mit überprüften lokalen Inhalten vollständig offline.

## Spielbare Mechaniken

1. **Zehnerbrücke:** plastische Plättchen zwischen Vorrat und Zehnerfeld bewegen, Ergänzung erkennen; anschließend andere Zahlen ohne Modell rechnen. Lernziel: Zerlegen und Ergänzen statt wiederholten Ratens.
2. **Wortwerkstatt:** Silben in richtiger Reihenfolge zusammensetzen; neues Wort aus Sprechstücken selbst schreiben. Keine erfundene Lerntyp-Diagnose.
3. **Szenensatz:** englische Wörter zu einem Alltagssatz zusammensetzen, anschließend neues Wort aus dem Kontext abrufen. Keine Behauptung eines neuen Aussprachetrainings.
4. **Wasserweg:** Prozessabschnitte ordnen, anschließend den passenden Pflanzenteil aus seiner Funktion benennen. Die Darstellung ist ein vereinfachtes Modell.
5. **Bruchatelier:** gleich große Sektoren markieren; neue Brüche selbst angeben. Verfügbar ab Klasse 4 gemäß bestehendem Katalog.

Ruhige räumliche Bühne, gerichtetes Licht, gemeinsame Materialgestaltung, reaktive Original-Lumo-Posen und kurze Übergänge. Keine Dauerpartikel über Arbeitsobjekten. Interaktive Objekte bleiben über echte mindestens 48dp große Buttons erreichbar, System-/App-Reduktionsmodus und Lebenszyklus werden beachtet.

## Tutor und Lernreise

Jede Runde hat Beispiel, gemeinsames Bauen, selbstständigen Abruf, neue Transferaufgabe und einen konkreten Rückblick. Die Hilfe wächst von Hinweis über Prinzip, Modell und durchgerechnetes Beispiel bis zur kleinen geführten Teilfrage. Feedback benennt beobachtbare Fehlermuster (z.B. Zählen ab Start statt Ergänzen, vertauschte Bruchzahlen); unklare Antworten erhalten keine erfundene Diagnose. Erklärungstext ist der Klasse und dem lokalen Aufgabentyp angepasst. Die freie Wahl zulässiger Übungen und Pause bleiben sichtbar.

Eine zusätzliche versionierte Struktur im vorhandenen lokalen ProgressRepository hält begrenzte Lernbelege ohne freie Antworten, Namen oder Ton fest. Unterstützte Erfolge zählen getrennt von selbstständigen Antworten. Unterschiedliche Aufgaben und ein Transfercheck sind für den selbstständig geprüften Zustand erforderlich; späterer Abruf für Behalten. Wiederholungsabstände 1/3/7/14 Tage sind transparente Produkheuristiken, keine normierte Diagnose. Alte Lernstände werden nicht umgerechnet. Keine neuen Anwesenheitszwänge oder verlorenen Punkte.

## Sprache und Speicherung

Eine kleine sitzungsgebundene Narrationssteuerung verwendet ausschließlich LumoVoice. Explizites Vorlesen/Wiederholen darf aktuelle eigene Sprache ersetzen; automatisches Feedback unterbricht keine laufende Erklärung. Pause und Ende invalidieren verspätete Fortsetzungen. Keine Behauptung neuer Stimmqualität ohne Hörnachweis.

Neue Lernbelege laufen durch denselben eingefangenen Profilbesitzer und dieselbe Retry-Grenze wie vorhandene Antworten. Geführte Beispiele erzeugen keine Schulantworten. Unbekannte/neue oder beschädigte Speicherformate bleiben erhalten und werden nicht überschrieben. Profilwechsel und Reset sperren alte Bedienaktionen.

## Verifikation und Grenzen

Tests: Katalogarithmetik und Normalisierung; tatsächliche Manipulation/Undo; Fehlermuster und Hilfen; neue Aufgaben nach Hilfen; selbstständige vs. begleitete Belege; Persistenz/Retry/Profilwechsel; 320dp Cover, Fold innen, Querformat, Schrift bis 2x, Semantik und ruhiger Modus. Ganze bestehende Flutter-Suite und Analyse (bestehende Infos separat), Font-Pixelgate, lesbare echte Flutter-Renders samt Animationssequenz. Androidbau und tatsächlicher Emulatortest müssen separat grün sein; kein physisches Samsung-Gerät oder FPS-Wert wird behauptet. Kandidat bekommt eigene Versionsnummer bei unverändertem nativen Quellstand; alte APKs bleiben erhalten.

Dies ist ein integrierter Lernentwicklungsblock, keine belegte vollständige AAA+-Neugestaltung aller vorhandenen Module und keine klinisch validierte Lernstandsdiagnostik.
