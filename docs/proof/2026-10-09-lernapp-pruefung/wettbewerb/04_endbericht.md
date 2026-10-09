# Endbericht Prüfer 6 – Wettbewerb, Forschung, USP (9.10.2026, Commit b04bee5)

**Ist-Stand Lumo (am Code verifiziert, nur gelesen).** Vorhanden und von `main.dart` erreichbar: ErrorPatternDetector (~14 Regeln, nur Rechnen und Lesen), Kompetenzprotokoll und Lernbericht (Trend, wiederkehrende Fehlermuster, 10-Minuten-Empfehlung), Lehrerbereich, Foto-Lektion (ML-Kit-OCR, dann 5 lokale Aufgaben), Denkprofil, Schreib-Engine, Lese-Analyse, 228 Sprachclips. Fehlt: Teachable Agent, kindersichtbare Wiederholungsplanung (nur interner Decay-Wert „Tage/14“), mehrere Kinderprofile (ein `lumo_active_profile`), Geschwistermodus. Schwächer als beschrieben: Schreiben ist eine Strich-Heuristik (ML-Kit-Ink „deferred“, keine Schulschrift); die Aussprache-Analyse gleicht Wörter eines Transkripts ab, `speech_to_text` läuft ohne `onDevice` (Offline nicht garantiert). **Widerspruch:** PRIVACY.md (28.4.2026) sagt „INTERNET nicht benötigt, kein Datentransfer an Dritte“. Im Code: Manifest-Rechte INTERNET und REQUEST_INSTALL_PACKAGES, Bilder per URL von image.pollinations.ai (Lumo-Lehrer, Jahreszeiten, Live-Pro; kein Eltern-Gate gefunden), optionaler OpenAI-Proxy (Standard aus), GitHub-Update-Prüfung. Ohne Bereinigung taugt „offline/kein Tracking“ nicht als USP. Drei `lib/`-Dateien sind von `main.dart` nicht erreichbar (Regel 8).

## 1. Marktüberblick

| Anbieter | Plattform / Preis | Kernmechanik | Datenschutz | AT-Lehrplan |
|---|---|---|---|---|
| ANTON | Web+App; Grundfunktionen gratis, werbefrei; Offline/Schulverwaltung kostenpflichtig (Preise 2019/20: 3,99–249,99 €, veraltet?) | Sofort-Feedback mit Erklärung, Sterne, Lehrer-Dashboard; ISTE-Seal 8/2026 | Login per Code/E-Mail; 2019 Sicherheitslücke (behoben); Erklärung nicht inhaltlich geprüft | kein AT-Bezug belegt; Parlamentsanfrage 12/2025 fragt nach Einsatz |
| scoyo | Browser, Kl. 1–7, ca. 15 €/Monat (Vergleichsportal) | Lernwelt, Elternbericht | – | DE-Lehrpläne; **wird eingestellt** (Hinweis scoyo.de, kein Datum) |
| Schlaukopf | iOS; gratis mit Werbung, Premium 3,99 €/Mon. | Quiz, 100.000+ Fragen | Store-Label: „Daten zur Nachverfolgung: Kennungen“ | DE-Lehrplan |
| Khan Academy Kids | iOS/Android, gratis, werbefrei, Alter 2–8 | Lernpfad, Geschichten | Konto mit Name+Alter; Label: Analytics | im DE-Store nur Englisch |
| Duolingo ABC | iOS, nur Englisch | Lesen/Schreiben Vorschule–2. Kl. | – | kein DACH-Wettbewerber |
| Antolin | Web, Schul-/Klassenlizenz (DE: 44 €/Klasse, Stand unklar) | Buch, Quiz, Punkte (160.600 Quiz) | – | AT-Verfügbarkeit nicht belegt |
| bettermarks | Web, Mathe Kl. 3–13, Länder-/Schullizenz | adaptiv, „Feedback zu typischen Fehlermustern“ | Seite ohne Angaben | kein AT-Bezug |
| sofatutor.at | Videos+Übungen, Abo (Drittquellen 15–20 €/Mon.), 30-Tage-Test | Video, Übung | SRF warnt vor Abo-Falle | AT-Lehrplan nicht geprüft |
| eSquirrel / digi4school / Eduthek | Verlagskurse (Klassenlizenz); E-Books via Schulbuchaktion (familienkostenlos; Sek. belegt, Volksschule NICHT belegt); Eduthek = BMB-Materialplattform | Schulbuch digital, Übungen | Gütesiegel-KO: DSGVO + werbefrei | AT-Lehrplan über Verlage/BMB |
| Nischen | Dybuster Calcularis/Orthograph (ETH, ML-Schülermodell); Dynamilis (EPFL, Schreib-App, Abo geplant) | Förderung Dyskalkulie/LRS; Handschrift | – | – |

„Lernando“: nichts gefunden. Blitzrechnen/Einmaleins-Apps: nicht einzeln geprüft.

## 2. Marktlücken
- **Kaum geboten** (Negativbefund Websuche, nicht systematisch, VERMUTET): kindersichtbare Wiederholungsplanung; Teachable Agent (nur Forschung: Betty's Brain, Lunds „Magical Garden“ für Vorschule); Handschrift in DE/AT-Schulschrift (keine gefundene App bestätigt sie; Tracing-Apps nutzen angelsächsische Stile); Vorlese-Feedback für die deutsche Primarstufe; lokale Foto-zu-Übung-Funktion; Eltern-Handlungsempfehlung.
- **Kein Alleinstellungsmerkmal:** Fehlerdiagnose (bettermarks, Eedi UK, Calcularis), Lehrerzuweisung (ANTON), Elternbericht (scoyo), Profilverwaltung (scoyo Geschwisterrabatt). Hier hat Lumo bei Profilen sogar eine Lücke.
- **Marktchance:** scoyo steigt aus; eine werbefreie, DSGVO-saubere Alternative ist gefragt. AT-Lehrplanbezug unterscheidet von ANTON, scoyo, Schlaukopf (alle DE), Lumo belegt ihn bisher nur per Doku.
- **„Lernen finanziert Tuning“** ist ein verbreitetes Belohnungsmuster und evidenzseitig riskant (Abschnitt 3).

## 3. Evidenz

| Methode | Beleg | Stärke (6–10 J.) |
|---|---|---|
| Retrieval Practice | Yang 2021: 222 Studien, N=48.478, g=0,50 (Grundschulanteil im Abstract nicht ausgewiesen); Karpicke 2016: 88 Kinder (~10 J.), robust | mittel–stark |
| Verteiltes Wiederholen | Latimier 2021: g=0,74 (29 Studien, Alter ungeprüft); Klassenzimmer d=0,54 (Mawson/Kang 2025); expandierend ≈ gleichmäßig (g=0,03). Sichtbare Vergessenskurve für Kinder: keine Studie gefunden | mittel–stark; Anzeige offen |
| Elaboriertes/Fehler-Feedback | van der Kleij 2015: elaboriert g=0,49 gegen richtig/falsch 0,05; Wisniewski 2020: d=0,48; Eedi (UK, Sek., Herstellerangabe 0,17–0,34); ASSISTments g=0,18 | mittel–stark; Misconception-Distraktoren: mittel, Grundschule dünn |
| Worked Examples | Barbieri 2023: g=0,48 (55 Studien, v. a. Mittelstufe); fehlerhafte Beispiele im Mittel schwächer; Durkin: 4./5. Kl. gemischt | stark (Novizen); Fehlerbeispiele schwach–gemischt |
| Interleaving | Brunmair/Richter 2019: g=0,42, Mathe kleiner; Rohrer 2020: d=0,83 (54 Klassen, 7. Kl.) | mittel; Grundschule schwach |
| Selbsterklärung | Bisra 2018: g=0,55 (69 Effekte); Mathe-Metaanalyse kleiner (~0,39, Sekundärquelle) | mittel |
| Teachable Agent / Protégé | Chase 2009: mehr Lernzeit und Gewinn, v. a. Schwächere (8. Kl.); Pareto 2012: n=38, 7 Wochen, Verständnis p<0,05; Kobayashi 2019: g=0,35/0,56 (28 Studien, v. a. Ältere, VERMUTET); Ribosa/Duran 2022: g=0,17, methodisch kritisiert | mittel–schwach |
| Wachstums-Mindset | Sisk 2018: d≈0,08; Macnamara/Burgoyne 2023: Bias-Verdacht; EEF 2019: 101 Schulen, 5.018 Kinder, kein Zusatzfortschritt | schwach, umstritten: nur Haltung, kein Wirkversprechen |
| Belohnung | Deci 1999 (128 Exp.): erwartete greifbare Belohnungen mindern intrinsische Motivation (d −0,28 bis −0,40); Habgood/Ainsworth 2011 (n=58, 7–11 J.): in die Mechanik eingebettetes Lernen schlägt aufgesetztes | mittel; Warnsignal für Sterne-Tuning |

## 4. USP-Kandidaten

| # | Idee | Neuheit / Evidenz | Aufwand, vorhandene Module | Risiko | Demo in einem Satz |
|---|---|---|---|---|---|
| A | **„Lumo macht einen Fehler“**: Lumo rechnet absichtlich typisch falsch, das Kind findet und erklärt den Fehler | DACH-Volksschule nicht gefunden; Protégé + Selbsterklärung + Fehlermuster | M; ErrorPatternDetector (umgekehrt), MathTaskTemplates, LearningAnalysis, Clips/TTS | Fehlerbeispiele schwächer als korrekte: erst Beispiel, dann Fehler | „Lumo sagt 8+5=3, das Kind zeigt am Zehnerfeld den vergessenen Zehner, Lumo ruft: Jetzt versteh ich's!“ |
| B | **Gedächtnis-Himmel**: Sterne „schlafen“ bei Pause, 3 Fragen wecken sie | keine Kinder-App gefunden; Spaced Retrieval stark, kindgerechte Anzeige ungeprüft | M; cosmos, AdaptiveTaskSelector, Attempt-Log; braucht Profile | Verlustangst, Druck | „Drei Sterne flimmern leise, nach drei Fragen strahlen sie wieder.“ |
| C | **Fehler-Reparatur-Pfad**: Beispiel, Finde-den-Fehler, Aufgaben mit Fehlertyp-Distraktoren | bettermarks ab Kl. 3, Eedi (Sek.); Feedback g≈0,49 | S–M; LearningAnalysis-Muster, Generator | Regex deckt nur Rechnen/Lesen | „Dreimal derselbe Trick entwischt: Lumo fängt ihn mit dir, ein Stern leuchtet.“ |
| D | **Schulschrift-Lumo**: Kind bringt Lumo die Schrift bei (ML-Kit-Ink) | Dynamilis (CH), keine AT-Schrift gefunden; CoWriter n klein | L; writing_engine | Vorlagenwahl, Fehlerkennung frustriert | „Lumos wackliges a wird mit jeder Korrektur schöner.“ |
| E | **Vorlese-Coach offline** (on-device-ASR, Wort-Tipps) | nur Englisch bei Duolingo ABC/Khan; Evidenz hier nicht geprüft | M–L; Analyzer, Lese-Screens | Kinderstimmen-Fehler | „Lumo markiert nur das eine Wort, das nochmal dran ist.“ |
| F | **Ehrliche Sterne**: Sterne für Reparatur/Wiederholung, Tagesdeckel, Eltern sehen das „Warum“ | gering (Vertrauensmerkmal); Deci, Habgood | S; RewardWallet/Reward-Engine | Spieler wollen mehr | „Sterne gibt's fürs Verstehen, nicht fürs Klicken.“ |

Kein USP, aber Voraussetzung: Datenschutz-Bereinigung (PRIVACY.md angleichen, Pollinations hinter Eltern-Gate oder streichen, `onDevice`), Mehrprofil/Geschwistermodus, AT-Lehrplan-Kompetenzraster.

**Favorit: A**, mit dem Kern von C. Es nutzt Lumos Figur, verwendet die vorhandene Fehlerdiagnose in Umkehrrichtung, braucht weder Netz noch Mikrofon (Antippen) und hat zwei getrennte Evidenzstränge (Protégé, Selbsterklärung). **Reihenfolge:** Voraussetzungen, A, F, B, C-Ausbau, E, D. Die Werkstatt-Mathe-Idee (Lernen in die Tuning-Mechanik) widerspricht DESIGN_ZIEL_KART („kein Lernen im Kart“) und braucht Heinz' Entscheidung.

**MVP (1–2 Tage):** nur „Addition mit Zehnerübergang“, Kl. 1–2. (1) Fehlergenerator als Umkehrtabelle des Detectors (`expected−10`, vertauschte Ziffern, ±1) liefert Lumos Falschantwort und Musterlabel. (2) Screen: Aufgabe plus Zehnerfeld, drei Karten „Was ist passiert?“, Kind legt den Zehner selbst, Lumo reagiert; 3 Runden, dann 2 Transferaufgaben. (3) Start nur bei needsHelp oder Muster ≥2× und nach einer korrekt gelösten Aufgabe. (4) Logging als Attempt „Fehler erklären“, Sterne fürs Erklären, keine Abzüge, kein Timer. (5) Generator- und Widget-Tests. Messung: Muster-Häufigkeit im Lernbericht (nicht kausal).

## 5. Elternsicht (Österreich)
Eine belastbare österreichische Elternumfrage speziell zu Lern-Apps (Lehrplan, Werbefreiheit, Kontrolle) habe ich nicht gefunden. Indizien: UNICEF Österreich/Marketagent (8/2025, n=1.005, 14–75 J.): nur 12,3 % halten Kinder online für sicher, 47,7 % fordern ein Verbot kommerzieller Nutzung von Kinderdaten, 46,4 % Grenzen für personalisierte Werbung, 83,1 % der Eltern sehen sich als Begleiter. Saferinternet.at (2018, qualitativ, 12 Kinder): Eltern verunsichert, nutzen Zeitlimits; unklickbare Werbung nervt Kinder. Das Gütesiegel Lern-Apps (BMB/OeAD) verlangt als KO-Kriterien DSGVO-Konformität und Werbefreiheit. öbv/JKU-Lehrkräftebefragung (n=949, 2024): Lern-Apps in Volksschulen >80 % genutzt, 39 % vermissen stabiles Internet, also zählt Offline. Rechtlich gilt Einwilligung erst ab 14 (§ 4 Abs. 4 DSG): bei Volksschulkindern entscheiden stets Eltern, „ohne Konto“ senkt die Hürde.

## 6. Unsicherheiten
Preise aus Dritt- und teils alten Quellen; scoyo-Enddatum unbekannt; „fehlt am Markt“ beruht auf Websuche, nicht auf App-Audit; ANTON-Datenschutzerklärung nur als Gliederung gelesen; Digi4School-Seite nicht abrufbar; LernMax/Kimaro nicht gefunden; Effektgrößen meist von älteren Lernenden, einige nur sekundär (Rittle-Johnson, Latimier, Eedi herstellerseitig); Kart-Fakten nur aus Doku (Godot-Code nicht im Repo); Code nur statisch geprüft.

## Quellen
(siehe Endbericht)
