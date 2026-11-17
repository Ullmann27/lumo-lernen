# Alle 18 Fachmodule: konkrete Aufgabenanschlüsse

## Ausgeliefertes Verhalten

Alle **18 vorhandenen Fachmodul-Screens über 19 tatsächliche Akademie-Einstiege**
haben jetzt eine kanonische Bindung pro Aufgabe, gestufte Hilfe, Wiederholen,
Langsamer und Stopp. Sprachvorschläge bleiben sichtbar und bearbeitbar. Erst
die ausdrückliche Bestätigung erreicht den bisherigen Fachcallback; ein
unklarer Text, ein alter Task oder eine alte Bestätigung bucht keine Antwort.

Jedes Modul besitzt einen erreichbaren `Mit Lumo in 3D ausprobieren`-Einstieg
über Roots `NativeLearningActivity.fromCompanionContext` und `launchLumo3D`.
Der passende Hilfeschritt wird lokal sichtbar und vor jedem Await als Hilfe
vermerkt. Die Aufgabenbindung bleibt beim nativen Activity-Wechsel erhalten,
auch wenn Android bereits zurückmeldet, bevor Flutter wieder resumed ist.
Die Bestätigung erfolgt anschließend über dieselbe fachliche Autorität.

17 Screens verwenden `ModuleTaskScope`. Die öffentliche Ergänzung ist
`ValueChanged<int>? onConfirmChoice`. Sie übergibt nach eindeutiger Zuordnung
nur den Index der angebotenen Antwort. Der bestehende Modulcode entscheidet
über richtig/falsch, Belohnung und Speichern. Plus behält seinen bisherigen
`_handleAnswer`-/Lease-/Wallet-Weg und verwendet `LearningCoachBinding`.
Die gemeinsame `LearningAnswerCandidateCard` wertet selbst nichts.

Ein stabiler GlobalKey pro Modul erhält ModuleTaskScope beim Wechsel
zwischen Telefon- und Fold-Layout. Gewöhnlicher Hintergrund und überdeckte
Routen geben die Busbindung frei; Aufgabe und Hilfestufe bleiben erhalten.
Die zuvor benutzte Hilfe bleibt auch nach „Selbst versuchen“ Teil der Wertung.

## Nachweis

- **134/134 Tests bestanden**, finale Ausgabe in
  `evidence/chat2_completion_20261115/module_tests.log`.
- **21 Dart-Dateien ohne Analyze-Befund**, `module_analyze.log`.
- Jeder der 19 Akademie-Einstiege wird tatsächlich bedient. Jeder Screen
  zeigt einen mindestens 48dp hohen berührbaren 3D-Einstieg, nimmt einen
  sichtbaren Sprachvorschlag an, verwirft einen nicht zuordenbaren Text und
  prüft erst die bestätigte angebotene Antwort. Doppelte Bestätigung ist
  ausgeschlossen. Die zweifache Einmaleins-Route teilt einen Screen.
- Gemeinsamer Modulrahmen und Plus: Pause/Resume, Overlay, Resize, gestufte
  Hilfe, alte Identitäten/Bestätigungen und native Rückkehr vor Resume.
- Vorhandene Layout-, richtige/falsche Antworten-, Speicher-, Belohnungs-
  und Abschlussprüfungen der Mathe-/Deutsch-/Sachmodule bleiben grün. Die
  geschützten Diktat-Regressionsprüfungen laufen mit unveränderten Internals.

## Umfang und Grenzen

Die Liste samt Dateihashes und expliziten Lücken ist `MODULE_CONNECTIONS.json`.
Die fünf Naturmodule stammen aus dem ausdrücklich genehmigten Freeze der
Owner-WIP-Dateien; Owner-HEAD war weiterhin `573eb1a`. Die eigenen engen
Resolver liefern die tatsächlichen Bestätigungs-, Native- und Resize-Anschlüsse.
Keine fremde Arbeitskopie wurde geändert. Der bestehende C5-Renderer, dessen
NumberCompare, AppState-Wallet, C5-Spiele/Foto/Story, ReadingBuddy, Host und
Kotlin sind nicht Teil dieser Änderung.

**Der gemeinsame native Weg ist eine begrenzte Aufgabenkarte mit dem bestehenden
3D-Lumo.** Er liefert keine eigene räumliche Münz-, Uhren-, Wetter-, Farben-
oder Grammatik-Manipulation für jedes Fachmodul. Ein erreichbarer Einstieg
und eine geprüfte Plattformgrenze sind kein Nachweis einer vollständigen
spezialisierten 3D-Lernwelt. Die Tests nutzen Flutter und kontrollierte
Android-Kanalantworten; Godot-Rendering, reales Mikrofon und tatsächliches
Geräteverhalten gehören weiterhin zur End-to-End-Prüfung des Hauptchats.

| Tatsächlicher Einstieg | Screen | Aufgabenanschluss |
|---|---|---|
| d2_artikel | ArtikelLernenScreen | ModuleTaskScope |
| m4_bruch | BruchrechnenScreen | ModuleTaskScope |
| m2_einmaleins, m3_einmaleins_voll | EinmaleinsScreen | ModuleTaskScope |
| s1_farben | FarbenScreen | ModuleTaskScope |
| m1_formen | FormenScreen | ModuleTaskScope |
| m2_geld | GeldScreen | ModuleTaskScope |
| s2_jahreszeiten | JahreszeitenScreen | ModuleTaskScope |
| d2_mehrzahl | MehrzahlScreen | ModuleTaskScope |
| m1_minus10 | MinusBis10Screen | ModuleTaskScope |
| m1_plus10 | PlusBis10Screen | bestehender Plus-Writer + CoachBinding |
| s1_tiere | TiereScreen | ModuleTaskScope |
| m2_uhr | UhrLernenScreen | ModuleTaskScope |
| s2_verkehr | VerkehrScreen | ModuleTaskScope |
| s2_wetter | WetterScreen | ModuleTaskScope |
| d3_wortarten | WortartenScreen | ModuleTaskScope |
| m2_zahlen100 | ZahlenBis100Screen | ModuleTaskScope |
| m1_zahlen10 | ZahlenBis10Screen | ModuleTaskScope |
| d3_zeitformen | ZeitformenScreen | ModuleTaskScope |
