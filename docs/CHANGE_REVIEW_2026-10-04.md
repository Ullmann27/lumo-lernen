# Lumo: Pruefung bei Codeaenderungen

Heinz hat am 4. Oktober 2026 eine Kontrolle bei Aenderungen statt nur stuendlicher Nachschau verlangt. Der Workflow `lumo-change-review.yml` startet durch PR-Ereignisse, auch bei Drafts und bei gestapelten PRs auf dem Integrationszweig. Er hat keinen Cron-/Stundentakt. Start und Laufzeit haengen von GitHubs Runner-Verfuegbarkeit, Kontingenten und gegebenenfalls erforderlichen Workflow-Freigaben ab.

## Umfang und Grenzen

- Vor der Pruefung aktuellen Head abgleichen. Veraltete Kandidaten werden nicht als aktuell gruen gemeldet.
- Dateien anderer offener PRs mit derselben Basis vergleichen. Ueberschneidungen sind Hinweise, keine bewiesenen Mergekonflikte. Nicht gepushte Arbeit, andere PR-Basen, neue Kommentare waehrend eines Laufs und das andere Godot-Repository sind damit nicht ueberwacht.
- Exakten Head auschecken, Flutter 3.44.9 wie der vorhandene APK-Build verwenden, `flutter analyze --no-fatal-infos --no-fatal-warnings` und die gesamte Flutter-Testsuite ausfuehren. Analysefehler und Testfehler ergeben einen fehlgeschlagenen Job; auch ausgefallene/nicht gestartete Pruefschritte ergeben kein Gruen. Bestehende Analyzer-Warnungen und einzelne Test-Skips bleiben transparent im Originalprotokoll und sind kein Nachweis vollstaendiger Testabdeckung.
- Ergebnisse mit SHA, Toolchain und Protokollen als Actions-Artefakt ablegen. Fuer interne PRs genau einen Bot-Statuskommentar aktualisieren. Keine Agenten-Mentions, Selbstgespraeche, Auto-Reparaturen, Auto-Merges, Releases, neuen Schluessel oder Tarifwechsel.
- PR-Code laeuft nur mit Leserechten und ohne persistierte Checkout-Zugangsdaten. Der Kommentarjob hat keinen Checkout und fuehrt keine PR-Skripte aus. Forks erhalten keinen schreibenden Kommentarjob.
- **Mergekonflikte verhindern einen Start durch `pull_request`.** Ein ausbleibender Lauf ist keine bestandene Pruefung. Zuerst Konflikt im zustaendigen Arbeitszweig kontrolliert aufloesen und den neuen Head pruefen. Ein manueller `workflow_dispatch`-Lauf ist nur moeglich, soweit GitHub den Workflow dafuer bereitstellt; er ersetzt weder Konfliktloesung noch vorgeschriebene PR-Checks. Kein privilegierter `pull_request_target`-Job mit fremdem PR-Code wird als Abkuerzung eingefuehrt. Quelle: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#pull_request

Der Workflow ist **keine permanent laufende dritte KI**. Er kann weder Gedanken/lokale Arbeit der anderen Agenten beobachten noch echte Diskussionen oder eigene Pruefberichte von Luna, Claude und ChatGPT erfinden. Bildtreue, 3D-Bewegung, echte Geraete, TTS und die fertige APK muessen separat geprueft werden. Ein gruener technischer Check ist keine Freigabe zum Merge von PR #156 nach main.

## Zusammenarbeit

Vor jedem Schreibschritt aktuellen Head, neue Kommentare/Commits und offene PRs lesen. CLAIM mit Aufgabe, Basis-SHA und Pfaden posten. Bei Ueberschneidung den vorhandenen Bearbeiter beachten, nach dem Pull erneut pruefen und niemals Force-Push einsetzen. Lokale Tests weiterhin vor jedem Push ausfuehren; die CI ist eine zusaetzliche Gegenpruefung, kein Ersatz.

Fehler werden in drei **echten**, nachvollziehbaren Runden behandelt: (1) Reproduktion und Belege, (2) unabhaengige Gegenpruefung und alternative Loesungen, (3) begruendete Auswahl und Zuweisung einer Reparatur. Danach gezielter Regressionstest und erneute Gesamttests. Die drei Runden duerfen nicht durch drei automatisierte Kopien derselben Meldung simuliert werden. Bereits behobene Fehler nicht aufgrund alter Berichte erneut implementieren.

## Aktivierung und Endabnahme

Dieser kleine Infrastruktur-PR ist auf `codex/lumo-unified-android-2026-10-03` gestapelt und soll unabhaengig gegengeprueft werden. Er darf nach Gegenpruefung in diesen Integrationszweig uebernommen werden, ohne den gesamten App-PR nach main zu mergen. Erst ein tatsaechlich sichtbarer Actions-Lauf belegt die Aktivierung. Auf anderen offenen Zweigen muss die Workflow-Datei ebenfalls verfuegbar sein bzw. der Zweig aktualisiert werden; bereits bestehende PRs werden nicht rueckwirkend getestet.

Fuer eine APK-Freigabe bleiben drei eigene Berichte zum gleichen Kandidaten, Vergleich mit den Referenzbildern, Android-/Fold-Nutzungstests, Dateihash und Signatur erforderlich. Keine alte APK als neue Designversion ausgeben.

## Reproduzierbare lokale Pruefung dieses Workflows

`node scripts/ci/test_lumo_change_review.mjs` prueft die tatsaechlichen JavaScript-Bloecke aus der YAML-Datei mit zwoelf lokalen API-Fixtures: frischer/veralteter/geschlossener PR, manueller Lauf, Ueberschneidungen, fehlgeschlagene/uebersprungene/erfolgreiche Tests, Wiederverwendung des Botkommentars und Schutz von Nutzerkommentaren. Keine echte GitHub-API oder KI-Ausfuehrung wird dadurch simuliert als tatsaechlich geschehen ausgegeben.

In ChatGPTs urspruenglicher Sitzung: diese 12 Faelle bestanden; zusaetzlich YAML-/Berechtigungspruefung und der unveraenderte komplette Shell-Abschlussblock mit allen 27 Kombinationen aus success/failure/skipped fuer Dependencies/Analyse/Tests getestet. Nur dreimal success ergibt Exit 0. Flutter-/Android-Tests wurden lokal in dieser Sitzung nicht ausgefuehrt. Das CI-Ergebnis muss aus dem echten Actions-Lauf abgelesen werden.

## Nachweisreparatur vom 4. Oktober 2026

Der echte Lauf 37194052123 auf `36673305bab95259288758ea60e6a0d3ccf79fd0` bestand mit 503 Flutter-Tests, 4 uebersprungenen Tests und 139 nicht fatalen Analyzer-Hinweisen/Warnungen. Das Ergebnis-Artefakt fehlte trotzdem: `.ci-results/` wurde als versteckter Ordner vom Upload ausgeschlossen, und `if-no-files-found: warn` verdeckte den Fehler im Jobstatus. REST bestaetigte `total_count: 0`. Die Original-Joblogs sind davon zu unterscheiden und waren lesbar.

Lunas eigene Gegenpruefung: #156 Kommentar 5978847339. ChatGPTs Gegenpruefung: #166 Review 5405459893. Reparaturentscheidung/CLAIM: #166 Kommentar 5978884927. Gewaehlt wurde der nicht versteckte, eng begrenzte Ordner `ci-results/` und `if-no-files-found: error`, nicht ein generelles Hochladen versteckter Dateien. Quelle zum Ausschluss: https://github.com/actions/upload-artifact#uploading-hidden-files

Drei zusaetzliche Vertragspruefungen sichern konsistente Ergebnis-Pfade, einen fehlschlagenden leeren Upload und die Ausfuehrung des Testskripts in CI. ChatGPT hat die damit 15 Faelle lokal erfolgreich ausgefuehrt; drei absichtlich wieder eingefuehrte Fehler wurden jeweils erkannt. YAML-/Berechtigungspruefung und die 27 Shell-Ergebniskombinationen wurden erneut bestanden. Diese lokalen Pruefungen bestaetigen noch keinen GitHub-Upload: Ein neuer echter Lauf muss eine Artefakt-ID und die enthaltenen Quellstand-/Toolchain-/Logdateien liefern. Lunas Nachpruefung muss denselben neuen SHA benennen; Claudes fehlende Antwort darf nicht ersetzt werden.
