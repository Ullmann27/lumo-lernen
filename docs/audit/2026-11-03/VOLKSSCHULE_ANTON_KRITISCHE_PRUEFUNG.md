# Lumo Lernen: Volksschule 1–4, ANTON-Referenz und kritische Lernprüfung

Datum: 03.11.2026. Prüfgrundlage: veröffentlichte Lumo-2004-Quellen `1f99665c6b2b44f0e88a94264621652c0a9c34e8`, die bereits erstellten internen Lumo-Audits, der Bundes-Lehrplan im RIS und das Bundesministerium (Links unten), ANTON-Produktangaben und Schule.at (Links unten).

**Methodische Grenze:** Diese Aktennotiz ist ein aktueller technischer Befund und eine verbindliche fachliche Abnahmeplanung. Sie ersetzt weder eine manuelle pädagogische Beurteilung aller Aufgaben durch österreichische Volksschullehrkräfte noch einen Nutzertest mit Kindern und ist keine amtliche Lehrplanzertifizierung.

## A. Fächermatrix und verbindliche Regeln

| Bereich | Schulstufen 1–2 | Schulstufen 3–4 | Lumo-2004-Befund | Abnahmehandlung |
|---|---|---|---|---|
| Deutsch, Lesen, Schreiben, Rechtschreibung | Aufbau von Laut/Buchstaben, einfachen Texten, Handschrift, Hörverstehen | längere Texte, Sprachbetrachtung, Rechtschreibung und selbstständiges Schreiben | `Curriculum` führt Deutsch und zusätzliche Kompetenzbereiche als Generatorfächer; eigene Schreib-/Diktat-Module | realen Text-/Schreibbezug, sprachliche Eindeutigkeit, Aufgabenvielfalt, altersgerechte Vorleseführung stichprobenartig und fachlich abnehmen |
| Mathematik | Mengen/Zahlen, konkrete Materialien, Operationen im jeweils vorgeschriebenen Zahlenraum, Maße und Formen | größere Zahlenräume, multiplikatives Denken, Längen/Flächen/Größen, Mathematikargumente | Generator mit grade-spezifischen `MathTaskTemplates`; geometrische Zeichenansicht vorhanden | jede Aufgabe gegen genau die Schulstufe und die vier offiziellen Kompetenzbereiche Zahlen/Daten, Operationen, Größen, Ebene/Raum prüfen |
| Sachunterricht | unmittelbare Lebenswelt, soziale Regeln, Natur, Umgebung | weiter gefasste historische/geografische/technische und naturwissenschaftliche Zusammenhänge | `Science`-Fragen pro Klasse; 3./4. Grade mit Österreich/Europa-Themen | Bild-/Sachfehler, Regionalbezüge, Erfahrungsorientierung, Erklärung und Varianz durch Fachreview abnehmen |
| Lebende Fremdsprache | als verbindliche Übung, vorwiegend Hören/Sprechen und einfache Alltagssituationen | als Pflichtgegenstand, zunehmend selbstständige Anwendung | App bietet Englisch für alle Klassen | nicht Englisch mit rechtlich einzig zulässiger lebender Fremdsprache gleichsetzen; 1./2. Klasse nicht wie eine schriftliche Fremdsprachen-Schularbeit behandeln |
| Musik, Kunst und Gestaltung, Technik und Design, Sport | praktische Aktivität, Gestaltung, Bewegung | praktischer Lernfortschritt mit steigender Eigenständigkeit | `PrimaryActivityCatalog` und UI-Zugänge, keine vollwertige motorische KI-Bewertung | pro Klasse echte Aktivitätsdurchführung und kindliche Rückmeldung; keine künstlichen Multiple-Choice-Noten |
| Verkehrs- und Mobilitätsbildung | altersgerechte Schulweg-/Verkehrssicherheit | zunehmende selbstständige Anwendung | eigener Aktivitätszugang, nicht als klassischer Prüfungsgenerator modelliert | amtlichen Status als verbindliche Übung wahrheitsgemäß beschriften, Alltagssituationen realistisch erläutern |
| Religion | vom schulischen Kontext abhängig | vom schulischen Kontext abhängig | im `officialSubjectsForGrade` verzeichnet, aber nicht wie die anderen Aktivitätsfächer als vollwertige Übung in `PrimaryActivityCatalog` | kein konfessioneller oder verpflichtender Content ohne ausdrückliche inhaltliche Vereinbarung |

Die konkrete Reihenfolge der Kompetenzen ist dem amtlichen Text je Schulstufe zu entnehmen; bloß eine Aufgabe mit `task.grade=3` zu kennzeichnen, reicht pädagogisch nicht.

## B. Drei belegbare technische Schwachstellen in Build 2004

1. **Inhaltsdichte:** Das ältere vollständige Lumo-Tutor-Audit `docs/audit/2026-10-28/TUTOR-CURRICULUM-AUDIT.md` meldet 79.200 *synthetisch generierte* Aufgaben in 268 Kombinationen, aber 55 Themenzeilen mit weniger als zwölf unterschiedlichen Problem-Antwort-Paaren. Dies sind **nicht** 79.200 unterschiedliche Aufgaben. Für ANTON-ähnliche Variation zuerst gerade die dünnen Zeilen durch eigenständige Aufgabenmethoden und neue Situationsbeispiele ergänzen.
2. **Klassenfilter nur teilweise in zentraler Auswahl:** `Curriculum.unitsForGrade()` respektiert `grade` für Mathe, Deutsch, Englisch und Sachunterricht. Bei `Lesen`, `Schreiben` und `Rechtschreibung` wird dagegen derzeit eine gemeinsame Fächerliste aus `subjects[subject]` ohne Klassenunterscheidung zurückgegeben. Ob die danach tatsächlich generierte Schwierigkeit korrekt mitwächst, muss unabhängig von `task.grade` fachlich überprüft werden. Keine automatische Behauptung eines Lehrplanfehlers allein aus dieser Listenstruktur.
3. **Evidenz:** Nicht jede Lesebeobachtung ist bereits Kompetenznachweis; Selbstbeurteilung freier Handschrift darf nicht als automatisch richtiges Schreiben gespeichert werden. `LearningNavigation` trennt nur die Ansicht der höheren Klasse vom Profil; das ist korrekt und muss so bleiben.

## C. Benchmark gegen ANTON – keine Kopie, sondern sinnvolle Wettbewerbskriterien

ANTON beschreibt über **200.000 Aufgaben** und über **200 Übungstypen**, sofortiges Feedback, Erklärungen, eigene Lerngeschwindigkeit, Vorlesen, Lehrkraft-Zuweisungen sowie Belohnungen/Spiele (Stand öffentlich erreichbare Produktseite). Schule.at beschreibt kleine Lernsequenzen aus **Erklären → einfachen Aufgaben → Vertiefen → Mini-Test**. Ein Teil von ANTONs Offline-/Schulverwaltungsoptionen ist kostenpflichtig. ANTON ist ein nützlicher Vergleich, aber keine Gewähr, dass die Inhalte genau dem österreichischen VS-Lehrplan entsprechen.

Für Lumo:
- **Kindpfad mit nur einer Aufgabe im Fokus:** Ziel erklären, Lumo spricht eine knappe Hilfestellung, Kind probiert, Fehlversuch erklärt Denkweg, unabhängiger Transfer, kleine Reflexion. Kein unnötiger Lernchat oder verwirrende verschachtelte Menüs.
- **Vielfalt statt Masse:** Texteingabe, Hörverstehen, Vorlesen, interaktive Stellenwertblöcke, Zeichnen, Experimentieren/Bewegen und Geschichten systematisch mischen; identische Aufgaben nicht nur anders nummerieren.
- **Schulstufentreue und Fortschritt:** aktuelles Profil behält Klasse und Daten; die freiwillige höhere Klasse wird klar als Entdecken markiert; nachprüfbare Kompetenzbelege statt erfundene Sterne.
- **Eltern/Lehrer:** Prüfbericht mit gelösten Aufgaben, Hilfebedarf und Zeitpunkten; keine vage Prozentzahl oder falsche Note. Lehrkraftzuweisung und Organisation auf Datenschutz/Schulkontext prüfen.
- **Lumo-Markenunterschied:** originale Figur, warme Stimme, spielerische 3D-Welt, keine ANTON-Logos, Screens oder urheberrechtlich geschützten Aufgaben übernehmen.

## D. Abnahmematrix für vier Stufen – technische Abnahme allein reicht nicht

- **Klasse 1:** keine vorzeitige überfordernde Textlast; Zahlenraum, Laut-Buchstaben-Zuordnung und praktische Aktivität. Großzügige Buttons, jederzeit vorlesbare Hilfen, direkte Wiederholung.
- **Klasse 2:** reale Erweiterung gegenüber Klasse 1 statt bloß höherer Zahl; längere Sätze, sichereres Stellenwert-/Rechenverständnis und Alltagsprobleme.
- **Klasse 3:** nachweisbar eigenständige Themen und Erklärungen (z.B. im Bestand: Plus bis 1000, Einmaleins, Österreich), textbasierte Sachaufgaben und geeignete Ergebnisprüfung.
- **Klasse 4:** tatsächlich anspruchsvollere Aufgaben (z.B. Bestand: Zahlenraum bis 1 Million, Bruchrechnen einfach, mehrere Rechenschritte, längere Texte) und nachvollziehbare Rechenwege. Die konkrete Kompetenzzuordnung im RIS pro Thema klären.

Jede Kombination erhält später einen **separaten Beleg**: RIS-Kompetenzanker / eingebundene Unit / reale Aufgabe / Lehrkraftreview / Widget-/Phone-/Fold-Screenshot / Fehlerlog. Ungeprüfte Kombinationen bleiben explizit **ungeprüft**, statt als abgenommen zu erscheinen.

## E. Produkt-/Release-Auflagen

- Original-Lumo und Schreibtrainer/Journal erhalten; ihre Inhalte nicht bei Layoutänderungen überschreiben.
- Die durchgehend scrollbare 14-Register-Seitenleiste in PR #429 ist ein bewusst isolierter UX-Kandidat; vorhandene Smartphone-Bottom-Navigation bleibt funktionell getrennt.
- Keine neuen API-Abhängigkeiten, Kinderdatenübertragung oder ungeprüfte Modellbewertungen als Ersatz für reale Lernergebnisse.
- Vor neuem APK: vollständige Flutter-Tests inkl. Grad-/Fachrouting, tatsächliche Renderbilder, App-Kart-Android-Emulatortour, identisches Zertifikat und echte Datenmigration nachweisen.

## Quellen

- [BMB – Volksschul-Lehrplan](https://www.bmb.gv.at/Themen/schule/schulpraxis/lp/lp_vs.html)
- [RIS – Lehrplan der Volksschule](https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275)
- [ANTON – offizielle Funktionsübersicht](https://anton.app/)
- [Schule.at – ANTON Lern-App-Review](https://www.schule.at/tools-apps/details/anton)
- Reproduzierbares Lumo-Code-Evidenzmaterial: `docs/audit/2026-10-28/TUTOR-CURRICULUM-AUDIT.md`, `test/grade_1_to_4_subject_menu_integrity_test.dart`, `test/learning/volksschule_exhaustive_generator_contract_test.dart`, `lib/core/school_exercise_generator.dart`.
