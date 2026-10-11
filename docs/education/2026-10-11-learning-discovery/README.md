# Lumo: getrenntes freiwilliges Vorlernen und geführter Unterricht

## Tatsächlich implementierter Unterrichts-Meilenstein

Die bestehende Akademie hat zwei reale neue Einstiege: „Lumo erklärt es mir“
und „Mit Lumo Neues entdecken“. Es gibt keine Ersatz-App, zweite KI-Plattform,
neue Fortschrittsdatenbank oder Veränderung der eingestellten Schulklasse.
Die ursprünglichen Lernmodule, Lumo Frei, Sulafat-Originalaufnahmen und die
geprüfte Kart-Integration bleiben erhalten.

- **Über den Zehner:** Zählvoraussetzung, tatsächliches bewegtes Beispiel
  `7 + 5`, Zwischenschritte bei `9 + 4`, selbstständige Rechnung `8 + 6`,
  neue Überprüfungsaufgabe `6 + 5`, echte Zusammenfassung. Acht bedienbare Schritte.
- **Das Einmaleins entdecken:** Zählvoraussetzung, drei Gruppen mit je zwei
  Original-Äpfeln, wiederholte Addition und Multiplikation, gemeinsam zwei
  Gruppen mit je drei, selbstständig vier Gruppen mit je zwei und die passende
  Plusdarstellung für drei Gruppen mit je drei. Sieben bedienbare Schritte.
- **Echte Lernbegleitung:** tatsächlicher aktueller Aufgabenkontext und
  Antwort-/Hilfe-/Wiederholungs-/Abschlussereignisse im bestehenden Companion-Bus.
  Keine zufälligen Erfolgsmeldungen, automatischen Lösungen beim ersten Fehler
  oder erfundenen Diagnosen. Alternative Tipps und eine leichtere Zählaufgabe
  führen zur ursprünglichen Aufgabe zurück.
- **Echte Mengen:** Alle animierten Äpfel bleiben einzelne originale PNG-Widgets.
  Ein Apfel wird verschoben, nicht für einen Effekt verdoppelt. Der Rest-Schritt
  zeigt einen gefüllten Zehner und die tatsächlich verbleibende Menge.
- **Einheitliche Stimme und Figur:** bestehender `LumoVoice`, vorhandene
  Vorlesen-/Pause-/Fortsetzen-/Stoppbedienung, originaler Lumo und sein
  vorhandener 2D-Gestencontroller. Keine neue Stimme, keine behauptete
  Lippensynchronisation und keine neue Android-Hörabnahme dieses Unterrichts.
- **Bedienung:** Smartphone, Fold-Zielviewport, Tablet, kurzes Querformat und
  vergrößerte Schrift. Auf dem Smartphone ist genau eine Weiter-Schaltfläche
  fest erreichbar. Schrittwechsel setzen die Unterrichts-Scrollposition zurück.
  Verschachtelte Akademie-/Hub-/Unterrichtsrouten verdecken nach dem Wechsel
  zu Spielen nicht mehr den eigentlichen Hauptbereich.

## Elternfreigabe und getrennte Speicherung

Im vorhandenen Elternbereich ist Vorlernen pro ausgewähltem Kinderprofil
standardmäßig ausgeschaltet. Eine explizite Erwachsenenbestätigung erlaubt
eine Höchstschulstufe zwischen eins und vier. Diese Bestätigung ist keine
verifizierte Erwachsenenidentität; eine geeignete endgültige Erwachsenenprüfung
bleibt ausdrücklich eine Release-Bedingung.

Die neue lokale Freigabe aktiviert weder Online-KI noch Sprachserver, Mikrofon,
Kamera, Käufe oder Premium. Bei einem Profilwechsel während der Bestätigung
wird für das andere Profil keine Freigabe übernommen. Ein von der nativen
Speicherung zurückgewiesener Schreibvorgang erlaubt Vorlernen noch nicht.
Erst der tatsächlich erfolgreiche Wiederholungsversuch macht die Freigabe wirksam.

Voraussetzungen, begleitetes Üben, selbstständige Antworten, Überprüfung und
verwendete Hilfen bleiben im bereits angelegten Entdeckungsfeld getrennt.
Reguläre Kompetenzzähler, Tagesziel, Aufgabenprotokoll, Cosmos und Wallet bleiben
bei Vorlernantworten unverändert. Bei regulärem Unterricht zählen nur die
wirklichen selbstständigen Antworten, nicht das bloße Anschauen eines Beispiels.

## Ausgeführte Prüfungen des Unterrichts-Meilensteins

- **66 gezielte Tests bestanden:** 14 echte Flutter-Bedienabläufe, 34 Mengen-/
  Animations-/Layoutfälle, vier deterministische Katalogtests und 14
  Speicher-/Freigabeprüfungen.
- **151 arithmetische Strategievarianten geprüft:** als vollständiger
  deterministischer Sweep innerhalb eines Katalogtests, nicht als 151
  separat ausgeführte Flutter-Tests.
- **18 geänderte Quell-/Testdateien analysiert:** keine Probleme.
- **Vier abschließende echte Unterrichts-Capture-Fälle bestanden:** jeweils
  Plus-Unterricht und Einmaleins-Einführung auf Smartphone und Fold-Zielviewport.
  Originalgrafiken, geladenes Nunito, tatsächliche Eltern-Taps, tatsächliche
  Antworten, Beispiel-Wiederholung und Rückkehr.
- **Zwei echte Plus-Hilfe-Capture-Fälle bestanden:** Smartphone und Fold mit
  tatsächlich falscher Antwort, angenommener Hilfe und anderem Tipp. Die
  Smartphone-Hilfe hat lesbare größere Mengengrafiken statt winziger Sprechblasen.
- **118 bestehende Modul-/Speicher-/Profilregressionen bestanden:** zusätzlich
  vor den letzten optionalen Unterrichts-Scroll-/Footerergänzungen. Danach besteht
  die vollständige Suite am exakten Produktkopf `9b8b7c86b4b4137c625d2e4fa727a9669a4962f5`:
  **1.232 bestanden, 113 optionale Capture-Fälle übersprungen, null Fehler**
  im tatsächlichen [CI-Lauf 38143393481](https://github.com/Ullmann27/lumo-lernen/actions/runs/38143393481).
  Analyse: null Errors, null Warnings, 16 bestehende Info-Lints.
- **40.969 erzeugte und geführte Aufgabenproben bestanden:** der bestehende
  `scripts/audit_content.dart` prüft jetzt auch die neun konkreten neuen
  Antwortschritte. Keine Behauptung vollständiger fachlicher Begutachtung.

## Nachgewiesene und gezielt behobene Ursachen

Die erste neue Bedienprobe blieb vor dem ersten Aufgabenbild hängen. Ursache
war die Initialisierung realer nativer Speicher-Warteschlangen in `FakeAsync`,
während `runAsync` auf deren Abschluss wartete. Die realen App- und Wallet-
Fixtures werden jetzt in ihrer tatsächlichen asynchronen Zone initialisiert.
Keine künstliche Verlängerung des Testbudgets.

Eine anschließend tatsächlich gemeldete `SwitchListTile`-Materialüberdeckung
wurde durch einen eigenen `Material`-Vorfahr behoben. Ein direkter Schulstoff-
Aufruf einer zu hohen Klasse blieb durch eine vorzeitige Gültigkeitsprüfung beim
Ladehinweis stehen; er zeigt jetzt vor jedem Speicherzugriff eine verständliche
gesperrte Route. Dieselben ursprünglichen Assertions bestehen, nichts wurde
ignoriert oder zur Grünmeldung übersprungen.

Die ersten echten Grafikaufnahmen zeigten unnötigen Leerraum und weggescrollte
Unterrichtsüberschriften. Danach wurden das Mengenfeld, die kurze sichtbare
Erklärung, die weiterhin abrufbare vollständige Erklärung, die Scroll-Rücksetzung
und die feste Smartphone-Weiterbedienung im laufenden Produkt verbessert.

## Grenzen und sofort ausführbare Fortsetzung

Es sind zwei tatsächliche kleine Mathematik-Einführungen, nicht der vollständige
Unterricht der ersten bis vierten Klasse. Weitere mathematische Einführungen,
geführtes Deutsch/Lesen/Schreiben/Sachunterricht, alle direkten Modulereignisse,
der vollständige Lehrplan-/Inhaltsstatus und eine externe österreichische
pädagogische Freigabe bleiben offen.

Die neue Unterrichts-/Vorlernoberfläche ist noch nicht in einer neuen APK
enthalten. Die APK 1929 bleibt unverändert; ihr tatsächlicher Android-PASS
prüft die vorherige App-Quelle, nicht diese neu hinzugefügten Lernwege.
Neue Aufnahmen sind Flutter-Testlaufzeit, nicht Android oder physisches Fold.
Das Animationsvideo verwendet echte Flutter-Frames ohne Audio, nicht
gemessene Geräte-FPS oder eine menschliche Hörabnahme.

Die vollständige Suite für den exakten Produktkopf ist jetzt tatsächlich geprüft.
Als Nächstes die vorhandene ältere Nachhilfe-Karte an tatsächlich verfügbare Lernwege
und reale `learningSkills()`-Daten anschließen. Keine erfundenen Versuchszahlen,
keine pauschale Fremdfach-Zuordnung und keine fiktiven Kurs-/Belohnungsversprechen.
Danach systematisch weitere Inhalte und Eltern-/Release-Gates bearbeiten.
Keine großen Cards-/Kart-Erweiterungen vor Abschluss der vorrangigen Lernarbeit.

## Historischer gesicherter Speicher-Meilenstein

Der vorhandene `ProgressRepository` und `LearningProfileEngine` wurden um ein
pro Kind getrenntes, versionsgeprüftes Entdeckungsfeld erweitert. Es gibt keine
zweite Datenbank. Die bestehende `LearningModuleProgress`-Schreibgrenze übernimmt
Besitzerbindung, Wiederholung fehlgeschlagener Schreibvorgänge und Lebenszyklus.

Vorlernen ist bei neuen Profilen ausgeschaltet. Eine Höchstschulstufe von 1 bis 4
ist explizit vorgesehen. Ein Widerruf bewahrt bereits entdeckte Themen.
Unbekannte, neuere oder beschädigte Speicherformate bleiben unverändert und
werden nicht stillschweigend durch leere Daten ersetzt.

Vorlernantworten verändern weder Schulklasse noch reguläre Kompetenzzähler,
Tagesziel, Aufgabenprotokoll, Cosmos oder Wallet. Voraussetzung, begleitetes
Üben, selbstständiges Üben und Überprüfung haben getrennte lokale Zähler.
Diese Beobachtungen sind keine Diagnose und keine nachgewiesene Beherrschung.

## Tatsächlich ausgeführte Prüfungen des Speicher-Meilensteins

- 46 Flutter-Tests bestanden: 13 neue Vorlernprüfungen sowie vorhandene
  Speicher-, Profilwechsel-, Mathematikmodul- und Plus-bis-10-Regressionen.
- Analyse der fünf geänderten Quell-/Testdateien: keine Probleme.
- Ein nativer `SharedPreferences.setValue`-Rückgabewert `false` bleibt ein Fehler.
  Erneut speichern zählt dieselbe akzeptierte Antwort nicht doppelt.
- Getrennte fiktive Profile A/B; reguläre gespeicherte Daten bleiben bytegleich.
- Nur der explizite bestehende Reset-Pfad wurde um das neue Feld ergänzt.
  Kein Kinderprofil und kein realer Lernstand wurde zurückgesetzt.

## Grenzen des historischen Speicher-Meilensteins

Die Speicherprüfungen sind keine Android- oder Hörabnahme des Vorlernens.
Der historische Speicher-Meilenstein umfasste noch keine vollständige
Unterrichtsoberfläche. Der tatsächliche neue Elternanschluss und die
interaktiven Unterrichtsprüfungen sind oben gesondert dokumentiert.
Eine explizite lokale Elternbestätigung ist keine verifizierte Erwachsenenidentität.
Eine geeignete endgültige Elternprüfung bleibt eine Release-Freigabebedingung.

APK 1929 bleibt unverändert und enthält diese neuen Funktionen noch nicht.
Ihr tatsächlich bestandener Android-16-x86_64-Prüflauf ist
[38138064509](https://github.com/Ullmann27/lumo-lernen/actions/runs/38138064509).
Physisches Samsung/ARM64, menschliche Hörabnahme, vollständiger Inhaltsaudit
und Google-Play-Abnahme bleiben getrennte offene Prüfungen.

## Pädagogische Grundlage der ersten Unterrichtsabläufe

Der [geltende österreichische Volksschullehrplan im RIS](https://www.ris.bka.gv.at/GeltendeFassung.wxe?Abfrage=Bundesnormen&Gesetzesnummer=10009275)
verlangt in der ersten Schulstufe additive Rechenoperationen bis mindestens 20
und in der zweiten Schulstufe additive und multiplikative Rechenoperationen im
Zahlenraum 100. Das kleine Einmaleins wird laut Lehrplan in der zweiten Schulstufe
erarbeitet und weitgehend gefestigt, in der dritten automatisiert.
Die ersten kleinen Unterrichtsabläufe sind nur ein Ausschnitt davon.
Vollständige Lehrplanabdeckung und externe österreichische Fachprüfung werden
nicht behauptet.
