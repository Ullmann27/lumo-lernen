# Lernapp-Prüfbericht (9. Oktober 2026)

Prüfstand: Branch `claude/continue-previous-chat-KtY7p`, Basis `b04bee5` (APK 1913). Sechs Prüfer waren
beauftragt. **Zwei lieferten** (Denk-/Knobel-Test, Wettbewerb/Alleinstellungsmerkmal). **Vier brachen durch das
Nutzungslimit ab, bevor sie berichteten** (Lerninhalt/Lehrplan, Aufgaben-Fuzzing, Grafik per Rendering,
Fehler/Erreichbarkeit/Datenschutz). Deren Themen sind unten als **nicht geprüft** geführt; Erreichbarkeit und
Datenschutz habe ich danach selbst am Code geprüft. Alles hier ist entweder im Code belegt oder ausdrücklich
als Annahme/Simulation markiert.

## 1. Antworten auf die Fragen

| Frage | Antwort |
|---|---|
| Ist ein IQ-Test enthalten? | **Ja, aber nicht als normierter IQ-Test.** „Lumo Knobel-Test“: 24 Rätsel in 6 Bereichen (Muster-Matrix, Figurenfolge, Was passt nicht, Drehen im Kopf, Zahlenrätsel, Merk-Blitz), adaptiv, ohne Zeitdruck, ohne IQ-Zahl, mit Sternen/XP. Erreichbar: Navigation → Tests → Karte „Lumo Knobel-Test“ (`app_shell.dart` → `lumo_tests_screen.dart` → `IqTestsCard` → `IqTestScreen`). Dazu der ältere „Denkprofil · 50“ (50 feste Fragen). Ein echter IQ-Wert ist ohne Normstichprobe nicht möglich (`docs/DENKTEST_KONZEPT.md`). |
| Ist alles grafisch super? | **Nicht belegt.** Der Rendering-Prüfer brach ab. Für den Knobel-Test gilt (Prüfer 3, Widget-Test-Renderings): Optik passt zum Design-Ziel (Nachtszene, Glaskarten, Cyan, Fuchs), Kontraste ≥ 6,2:1, Tippflächen ≥ 48 dp; Nebentexte mit 12–13,5 sp klein, Anleitung lang, auf dem Handy bleibt unten rund ein Drittel leer. Für den Rest der App steht der Vergleich gegen `docs/design_targets/2026-10-04/` aus. |
| Lernstoff ausreichend, altersgerecht? | **Nicht geprüft** (Prüfer abgebrochen). Bekannt aus `docs/AUSTRIA_VOLKSSCHULE_CURRICULUM_2026.md`: automatisch prüfbare Aufgaben in Mathematik, Deutsch, Lesen, Rechtschreibung, Schreiben, Sachunterricht, Englisch, Logik; Musik, Kunst, Technik, Bewegung und Verkehr nur als Aktivitätenkatalog. Der Vertragstest `curriculum_coverage_contract_test.dart` (17 Prüfungen) besteht. Menge, Zahlenräume je Klasse und Textschwierigkeit sind offen. |
| Gibt es Fehler? | **Ja, vier echte, alle behoben** (Abschnitt 2), dazu ein Datenschutz-Widerspruch (behoben) und tote Dateien (beseitigt). Offen bleiben Messqualität des Knobel-Tests und Punkte aus Abschnitt 3. |
| Eigene Ideen, Alleinstellungsmerkmal? | Abschnitt 5. |

## 2. Behoben (jeweils ein Commit, jeweils mit Test, der am alten Stand fehlschlägt)

1. **Denkprofil · 50: Platzhalter-Antwortkarten.** Der Generator füllte fehlende Karten mit „—4—“ auf
   (Klasse 2: `g2_quant_4/5`, Klasse 4: `g4_quant_4/6/8`); der alte Test auf vier *verschiedene* Karten blieb grün.
   Jetzt echte Nachbarwerte. Dazu: „Bei Hunger essen wir. Bei Durst …“ hatte die Lösung „Durst“ schon in der Frage;
   „wachsen“, „Konsequenz/Folge“ und „Blickwinkel/Standpunkt“ waren Synonym-Paare mit zwei Lösungen; „Masse“ → „Gewicht“;
   Klasse 4 „Wechselgeld“ war immer 10 Euro. (`6721b50`)
2. **Knobel-Test zählte als Lernschwäche.** Der adaptive Test landet bauartbedingt bei ~50 % richtig; seine 24
   Protokolleinträge liefen in die Kompetenzanalyse. Simulation des Prüfers: nach dem 2. Test standen 85–87 % der
   typischen Kinder bei „braucht Hilfe“, Lumo sagte „Bei „Logisches Schließen“ passieren dir noch Fehler“, der
   Start-Knopf öffnete Mathe. Jetzt zählen `IQ-Rätsel`-Einträge in der Analyse nicht mehr (Einträge bleiben im Protokoll).
   (`e38054b`)
3. **Merk-Blitz maß Abschreiben.** „Nochmal zeigen“ war unbegrenzt. Jetzt genau eine Wiederholung je Rätsel. (`c340a73`)
4. **Beschriftung widersprach sich.** „Der IQ-Test für Kinder“ stand im selben Bild wie „kein klinisch normierter
   Intelligenztest“. Jetzt „Rätsel wie im IQ-Test“; Elternhinweis um Wiederholungsabstand und Schulpsychologie ergänzt. (`4cb7092`)
5. **Datenschutz.** Der Bildgenerator rief ohne Schalter `image.pollinations.ai` auf (Lumo-Lehrer, Jahreszeiten),
   obwohl `docs/PIN_FREI_2026-10-03.md` Online-KI in frischen Einstellungen auslässt. Jetzt nur mit „Lumo-KI-Server
   erlauben“; gesendet wird auch dann nur ein übersetztes Themenwort der Positivliste (Test). `PRIVACY.md` (Stand
   28.04.: „INTERNET nicht benötigt“, „kein Datentransfer an Dritte“) ist neu und nennt alle Netzwerkziele. (`9020d83`)
6. **Tote Dateien (Regel 8).** Importgraph ab `main.dart`: 315 von 315 Dateien erreichbar (vorher 315 von 318). Altes
   Onboarding entfernt; die Lehrplan-Abdeckungstabelle liegt als Test-Fixture in `test/support/`. (`cbb5b9d`)
7. **Analyzer:** 131 Hinweise → 0 (`flutter analyze`: „No issues found!“). Darunter vier `BuildContext` nach `await`.
8. **Android-Prüfer:** Das Abholen der Video-Segmente übersteht kurzes „device offline“ (drei Versuche mit
   `adb reconnect`/`wait-for-device`); alle anderen Fehler scheitern wie zuvor. Anlass: Run 37937263563, Android 15 war
   komplett durchgelaufen, nur der letzte `adb pull` scheiterte. (`78adcad`)

## 3. Offen im Knobel-Test (Prüfer 3, im Code verifiziert; Simulationen unter Annahme eines Antwortmodells)

| # | Befund | Schwere | Aufwand |
|---|---|---|---|
| F1 | **Lösung ohne Regel erratbar:** Der Ablenker-Bau (`iq_puzzle_generator.dart:538-562`) macht die richtige Karte zur „Mitte“. Strategie „ähnlichste Option“ trifft in der Matrix 63–100 % (Zufall 17–25 %). | hoch | M |
| F2 | Ehrentitel und „Hier hilft Üben“ nicht belastbar (Retest-Korrelation ≈ 0,45 simuliert; Gleichstand begünstigt den ersten Bereich). 4 Rätsel je Bereich sind zu wenig. | hoch | M |
| F4 | Aufgabenvielfalt: gleicher Aufgabenstamm kommt in 20–82 % der Sitzungen doppelt vor. | mittel | S |
| F5 | Farbe als einziges Merkmal („Was passt nicht?“ Stufe 2/4; viele Matrix-/Serien-Ablenker). Rot-/Grün-Schwäche betrifft Mädchen selten (~0,5 %). | mittel | S |
| F6 | Messbereich hängt an der Klasse (Perfekt = 84 Punkte in Klasse 1, 156 in Klasse 4); Hochbegabung in Klasse 1 nicht sichtbar. | mittel | M |
| – | Keine Sprachausgabe: 6-Jährige brauchen die Eltern zum Lesen. Nur ein festes Beispiel je Bereich statt Übungsaufgaben mit Rückmeldung. | mittel | M |
| – | Kein Tempo-Bereich, keine Pause/Fortsetzen, keine getrennte Eltern-Ansicht, ~10 statt ~30 Minuten (Konzept). Sterne/XP hängen am Ergebnis (Anreiz zu schummeln: besser Fixbonus). | mittel | L |
| F10 | Es gibt nur ein aktives Profil (`profile_repository.dart`): zwei Kinder am selben Gerät mischen Ergebnisse. | mittel | L |
| F9 | `Denkprofil · 50`: dieselben 50 Fragen bei jeder Wiederholung; Sprachteil misst Wortschatz (Klasse 4: „Hypothese“, „Konsequenz“). | niedrig | S |

Auf der Tests-Seite stehen drei Denk-Einträge (Kategorie „Kreatives Denken“, Knobel-Test, Denkprofil · 50): verwirrend.

## 4. Datenschutz-Stand (am Code geprüft)

- Keine Werbe-, Analyse- oder Absturz-SDKs, kein Recorder-Paket (`pubspec.yaml`); Lernstände lokal.
- Netzwerkziele im Code: `lumo-ai-proxy.onrender.com` (nur mit „Lumo-KI-Server erlauben“, Standard aus),
  `image.pollinations.ai` (jetzt ebenfalls nur mit diesem Schalter), `api.github.com` (nur nach Tippen auf „Update“).
- Berechtigungen laut `scripts/prepare_android.py`: INTERNET, CAMERA, RECORD_AUDIO, REQUEST_INSTALL_PACKAGES.
- **Offen, braucht Heinz' Entscheidung:** (a) Spracherkennung (`speech_to_text`, kein `onDevice`): je nach Gerät geht
  Audio an den Erkenner-Anbieter; Mikrofon ist ohne Freigabe aus. (b) Der Elternbereich ist bewusst PIN-frei.
  (c) `PRIVACY.md` ist eine technische Beschreibung und vor einem Store-Eintrag rechtlich zu prüfen.

## 5. Markt, Forschungslage, Alleinstellungsmerkmal (Prüfer 6)

**Markt (Websuche, kein App-Audit; Quellenliste in `docs/proof/2026-10-09-lernapp-pruefung/wettbewerb/04_endbericht.md`):** ANTON (gratis, werbefrei, DE-Lehrplan, Lehrer-Dashboard), scoyo (**wird eingestellt**,
Datum unbekannt), Schlaukopf (iOS, Werbung/Premium), Khan Academy Kids (Englisch), Antolin (Lesen, Schullizenz),
bettermarks (Mathe ab Klasse 3, **Feedback zu typischen Fehlermustern**), sofatutor, Digi4School/eSquirrel (Schulbuchverlage).
Kein DACH-Anbieter belegt Österreichs Volksschullehrplan.

**Was am Markt kaum geboten wird (VERMUTET, aus Websuche):** kindersichtbare Wiederholungsplanung, Lernen durch Lehren,
Handschrift in österreichischer Schulschrift, deutsches Vorlese-Feedback für die Primarstufe, lokale Foto-zu-Übung-Funktion,
Eltern-Handlungsempfehlung. **Kein Alleinstellungsmerkmal:** reine Fehlerdiagnose (bettermarks), Lehrerzuweisung (ANTON),
Elternbericht (scoyo).

**Evidenz (Auszug, Stärke ehrlich):** Retrieval Practice und verteiltes Wiederholen mittel–stark; elaboriertes Fehler-Feedback
g≈0,49 gegen richtig/falsch; Selbsterklärung mittel; Teachable Agent mittel–schwach (v. a. ältere Lernende); Wachstums-Mindset
schwach und umstritten (nur als Haltung im Feedback, kein Wirkversprechen); erwartete greifbare Belohnungen können intrinsische
Motivation senken (Deci 1999), **ein Warnsignal für „Lernen finanziert Tuning“** – Sterne sollten Verstehen belohnen, nicht Klicken.

**Favorit (Prüfer 6, ich teile ihn): „Lumo macht einen Fehler“.** Lumo rechnet absichtlich typisch falsch (z. B. 8+5=3, Zehner
vergessen), das Kind findet und erklärt den Fehler am Zehnerfeld, Lumo ruft „Jetzt versteh ich’s!“. Nutzt die vorhandene
Fehlererkennung (`lib/domain/school/error_patterns.dart`, 14 Regeln, Rechnen und Lesen) in Gegenrichtung, braucht weder Netz noch
Mikrofon, stützt sich auf Protégé-Effekt und Selbsterklärung. Erst ein korrektes Beispiel, dann der Fehler (Fehlerbeispiele sind
allein schwächer).
**MVP (1–2 Tage):** nur „Addition mit Zehnerübergang“, Klasse 1–2: Fehlergenerator als Umkehrtabelle des Detectors
(`erwartet−10`, vertauschte Ziffern, ±1), Screen mit Aufgabe, Zehnerfeld und drei Karten „Was ist passiert?“, Start nur bei
`needsHelp` oder Muster ≥ 2× nach einer richtig gelösten Aufgabe, Sterne fürs Erklären, kein Timer, Generator- und Widget-Tests.
**Danach:** „Ehrliche Sterne“ (Reparatur/Wiederholung zählt, Tagesdeckel, Eltern sehen das Warum), dann „Gedächtnis-Himmel“
(Sterne „schlafen“, drei Fragen wecken sie; braucht Mehrprofil), dann Fehlerreparatur-Pfad ausbauen.
**Voraussetzungen (kein Merkmal, aber nötig):** Datenschutz sauber (teilweise erledigt), Mehrprofil/Geschwister, AT-Lehrplan-Raster.

Nicht umgesetzt: Die Idee „Werkstatt-Mathe“ (Aufgaben aus den eigenen Kart-Werten) widerspricht `docs/DESIGN_ZIEL_KART_2026-10-04.md`
(kein Lernen im Kart) und braucht Heinz' Entscheidung.

## 6. Nicht geprüft – für den nächsten Schritt

1. **Lerninhalt und Lehrplan:** Inventar Fach × Schulstufe × Themenblock (Zahlen per Befehl), Zahlenräume je Klasse
   (1: bis 20, 2: bis 100, 3: bis 1000, 4: bis 1 Mio), Textschwierigkeit in Klasse 1, Sprachausgabe der Aufgaben, österreichisches
   Deutsch, adaptive Logik (`progress_recommendation_service.dart`, `weakness_detection_engine.dart`, `session_variety_guard.dart`).
2. **Aufgaben-Fuzzing:** Generatoren je Klasse tausendfach aufrufen; genau eine richtige Antwort, unabhängige Neuberechnung,
   keine negativen Ergebnisse in Klasse 1/2, Platzhalter, Einzahl/Mehrzahl, Duplikate in einer Lektion. Ein wiederholbarer
   Fuzz-Test gehört danach ins Repo (das Denkprofil hat ihn jetzt in kleiner Form).
3. **Grafik:** echte Flutter-Renderings der Hauptscreens (Start, Lernen, Aufgabe, Ergebnis, Tests, Spiele, Profil, Eltern) bei
   360×800, 412×915, 768×1024, 1280×800, 840×720 gegen `docs/design_targets/2026-10-04/`, Überläufe bei Textskalierung 1,3/2,0.
4. **Fehler:** nicht abgewartete Futures, nicht entsorgte Timer/Controller, Listenzugriffe, Zeitzonen bei Tageszielen,
   SharedPreferences-Migration, Test-Lücken (21 übersprungene Tests), große ungenutzte Assets (APK ≈ 200 MB).
