# Arbeitsauftrag für Claude Opus 5.5: Lumo Lernen und Lumo Kart

Du übernimmst die technische und gestalterische Verantwortung für die Weiterentwicklung meines bestehenden Projekts **Lumo Lernen** einschließlich **Lumo Kart**. Arbeite direkt am vorhandenen Projekt und liefere eine tatsächlich laufende Android-App mit nachvollziehbaren visuellen Verbesserungen.

## 1. Deine Rolle und dein Qualitätsanspruch

Handle als erfahrener leitender Entwickler mit den Fähigkeiten eines Mobile-App-Architekten, Flutter-/Android-Entwicklers, Godot-Spieleentwicklers, Art Directors, 3D-Character-Artists, Motion-Designers, Voice- und Sound-Designers sowie Testers für mobile Spiele.

Nutze deine Fähigkeiten für umfangreiche Codeanalysen, das Erkennen von Ursachen, visuelle Vergleiche, die Koordination von Werkzeugen und die eigenständige Umsetzung. Verbinde Gestaltung, Programmierung und tatsächliche Spielerfahrung in jedem Arbeitsschritt.

**Mario Kart ist mein Qualitätsmaßstab für Lesbarkeit, Fahrgefühl, lebendige Welten, Kamera, Musik, Inszenierung und den vollständigen Ablauf eines Rennens.** Entwickle dafür eine eigenständige Lumo-Welt mit eigenen Figuren, Strecken, Musikstücken und Effekten. Das Ziel ist ein überzeugendes, hochwertiges mobiles Kartspiel. Entscheidend ist das Ergebnis in der laufenden App.

Beurteile die Arbeit streng: Ein hübsches Vorschaubild beweist keine hochwertige Spielgrafik. Eine vorhandene Audiodatei beweist keine hörbare Musik. Ein grüner Build beweist kein gutes Fahrgefühl. Prüfe diese Eigenschaften jeweils im Betrieb.

## 2. Ausgangsbasis zuerst verifizieren

Die bekannten Repository-Adressen sind:

- App: https://github.com/Ullmann27/lumo-lernen
- Spiele: https://github.com/Ullmann27/lumo-godot
- Aktuelle Reparatur-Übergabe: App-PR 213 und Kart-PR 26, jeweils auf dem Branch `chatgpt/repair-opus-handoff-2026-10-07`. Lies zuerst `OPUS_NEXT.md` und den dort verlinkten Prüfbericht. Frühere PRs 211/212 und 24/25 sind historische Vorstufen.

Die vorhandene Architektur besteht aus einer Flutter-Lern-App und eingebetteten Godot-Spielen. Baue darauf auf. Prüfe die aktuell gepinnten Engine-Versionen, die Android-Integration und den gemeinsamen APK-Build, bevor du etwas änderst.

Lies die geltenden Projektanweisungen und insbesondere, soweit vorhanden:

- `docs/DESIGN_ZIEL_2026-10-04.md`
- `docs/DESIGN_ZIEL_KART_2026-10-04.md`
- `docs/design_targets/2026-10-04/`
- `docs/design_targets/2026-10-04/kart/`
- die aktuellen Übergabe- und Build-Dokumente.

Sichte außerdem die hochgeladenen App-Dateien, Bildvorlagen und beiden Referenzvideos, sofern sie in deiner Umgebung zugänglich sind. Verwende ältere HTML-/Flutter-Prototypen als Kontext; ermittele die neueste funktionsfähige Ausgangsbasis anhand von Code und Build-Nachweisen.

Erfasse zuerst Branch, Commit, lokale Änderungen, offene Arbeiten und vorhandene Assets. Sichere fremde oder noch nicht veröffentlichte Änderungen. Dokumentiere knapp, welcher Stand deine Basis ist.

Die aktuelle Reparatur zielt auf **0.10.10+1602**. Sie führt die zwischenzeitlich getrennten App- und Kart-Verbesserungen zusammen und verhindert einen Versionsrückschritt gegenüber den Kandidaten 1504 und 1601. Der zugehörige APK-Quellstand und die tatsächlich abgeschlossenen Prüfungen stehen in `OPUS_NEXT.md`; verwende sie statt einer älteren APK als Ausgangspunkt.

Der frühere Abbruch bei der Item-Erkennung wurde untersucht: Die Beschriftung deaktivierter Kart-Aktionen ist jetzt kontrastreicher, und der Test prüft zusätzlich das Verhalten eines leeren und eines tatsächlich eingesetzten Items. Ein fehlendes Texterkennungsergebnis beweist noch keinen fehlenden Button. Ein sichtbarer Button beweist wiederum noch keine funktionierende Aktion. Erhalte diese Verhaltensprüfungen bei der weiteren grafischen Überarbeitung.

Der Online-KI-Dienst meldete bei der Reparaturprüfung am 7. Oktober 2026 `openai_quota_exceeded`. Bezeichne die Online-KI erst nach einer erfolgreichen tatsächlichen Anfrage als verfügbar. Offline-Lernen muss unabhängig davon funktionieren. Die neue Stimme, Musik und Renninszenierung gehören zu deinem nachfolgenden Entwicklungsauftrag; ihre Fertigstellung ist durch die Reparatur-APK noch nicht nachgewiesen.

## 3. Verbindliche Reihenfolge

Arbeite in dieser Reihenfolge und führe jede Etappe bis zu einem sichtbaren, nutzbaren Ergebnis:

1. Den aktuellen Stand sichern und Start-/Bedienfehler beheben.
2. Grafik, Layout, Buttons, Übergänge und Animationen der Lern-App verbessern und ihre Lumo-Stimme überarbeiten.
3. Spielewelt, Kart-Menü, Streckenauswahl und Garage gestalterisch verbinden.
4. Lumo als Fahrer anhand der bestehenden Lumo-Vorlagen korrigieren.
5. Ein vollständiges Kart-Rennerlebnis mit Intro, Einfahrt, Musik, Gameplay und Zieleinlauf fertigstellen.
6. Weitere vorhandene Strecken und Spielmodi auf diese Qualität bringen.
7. Android-/Fold-Prüfungen abschließen und eine installierbare APK liefern.

**Die große Neuentwicklung des frei agierenden Lumo-Lernassistenten, seiner KI und seines vollständigen App-Animationssystems ist eine spätere Etappe. Die Verbesserung seiner Stimme gehört ausdrücklich zum jetzigen Auftrag.** Bereite sinnvolle Schnittstellen für die späteren Arbeiten vor. Lumo muss im Kart bereits eindeutig als dieselbe Figur erkennbar sein.

## 4. Lern-App: eine hochwertige, zusammenhängende Gestaltung

Setze die vorhandenen verbindlichen Bildvorlagen in der echten Oberfläche um. Mein bevorzugter Gesamteindruck ist dunkelblau/schwarz mit Weiß, Cyan, Lichtakzenten und hochwertigen Glasflächen. Orange darf als Fellfarbe und gezielter Akzent vorkommen; es soll die App nicht als Grundfarbe dominieren.

Verbessere besonders Startseite, Lernübersicht, Aufgabenansicht, Spielewelt, Profil, Belohnungen und die entsprechenden Fold-Layouts.

- Gib jedem Bereich eine erkennbare Bildwelt und klare visuelle Hierarchie.
- Verwende passende Bild-Assets, Materialien und Symbole statt beliebig zusammengestellter Piktogramme.
- Gestalte Karten mit sauberer Tiefe, verständlichen Zuständen und gut lesbaren Beschriftungen.
- Vereinheitliche Rundungen, Abstände, Schriftgrößen, Schatten, Leuchtfarben und Button-Reaktionen über gemeinsame Komponenten.
- Halte Aufgaben, Antworten und Hilfen ruhig und gut erfassbar. Dekoration unterstützt die Orientierung.
- Zeige tatsächliche Profil-, Lern- und Belohnungsdaten. Beispielzahlen aus Vorlagen bleiben keine fest eingebauten Nutzerwerte.
- Sorge dafür, dass alle vorhandenen Funktionen weiterhin erreichbar sind.

Auf dem Fold soll die Fläche sinnvoll genutzt werden: größere Inhalte, deutliche Hauptaktionen, angepasste Spalten und passende Abstände. Das Außen- und Innendisplay brauchen jeweils bewusst gestaltete Ansichten. Ein Layoutwechsel muss den aktuellen Zustand erhalten.

## 5. Animation: die App soll sichtbar leben

Implementiere ein abgestimmtes Bewegungssystem:

- Buttons reagieren sofort auf Druck und Loslassen, mit kurzer Federbewegung und einem passenden Lichtimpuls.
- Navigation und Seitenwechsel erhalten weiche, zügige Übergänge.
- Karten erscheinen geordnet und führen den Blick zur nächsten sinnvollen Aktion.
- Fortschrittsbalken, Sterne, XP und Ringe bewegen sich vom alten zum neuen tatsächlichen Wert.
- Erfolge bekommen kurze, angenehme Effekte und gegebenenfalls dezente Klangsignale.
- Hintergründe können durch sparsame Wolkenbewegung, Partikel, Licht oder Parallax Tiefe erhalten.
- Ladezustände zeigen echten Fortschritt, soweit messbar, und erklären verständlich, was gerade vorbereitet wird.

Lege kurze Reaktionen in der Regel auf etwa 100–250 ms und größere Übergänge auf etwa 250–500 ms aus. Passe diese Richtwerte an Bediengefühl und vorhandene Gestaltung an. Eingaben müssen sofort verarbeitet werden; dekorative Animationen dürfen sie nicht verzögern.

Beachte die Einstellung für reduzierte Animationen, die Sichtbarkeit eines Bildschirms und den App-Lebenszyklus. Stoppe unsichtbare Daueranimationen und räume ihre Ressourcen auf. Kontrolliere auch Textvergrößerung und Lesbarkeit auf den beiden Fold-Flächen.

## 6. Lumo im Kart: dieselbe Figur wie in der App

Der bisherige Fahrer wirkt für mich noch nicht wie Lumo. Behebe diesen Unterschied anhand der Originalvorlagen.

Nutze insbesondere die vorhandenen Fuchs-Assets unter `assets/lumo_design/fox/`, die App-Designvorgabe und die Kart-Gesamtansicht `k10_kart_uebersicht.png`, sofern vorhanden. Die dokumentierte Figur hat oranges Fell, weiße Gesichts-/Bauchpartien und Schweifspitze, eine Fliegerbrille auf der Stirn sowie eine dunkelblaue Rennjacke mit leuchtendem L. Gleiche die tatsächlichen Referenzbilder ab und halte Gesicht, Proportionen, Farben und Ausstattung konsistent.

Erstelle einen visuellen Vergleich von App-Lumo, Referenz-Lumo und dem aktuellen Kartfahrer. Korrigiere die wesentlichen Unterschiede an Kopf, Augen, Schnauze, Ohren, Körper und Outfit. Erfinde keine neue Hauptfigur als Ersatz.

Für den Fahrer benötige ich:

- ein in den relevanten Kameraansichten überzeugendes 3D-Modell;
- passende Materialien und eine gut erkennbare Silhouette;
- eine natürliche Sitzhaltung mit Pfoten am Lenkrad;
- Lenk-, Drift-, Brems- und Boost-Reaktionen;
- dezente Körper-, Kopf- und Schweifbewegungen;
- kurze Start-, Freude- und Siegesanimationen.

Nutze ein vorhandenes gutes Modell oder verbessere es mit den verfügbaren 3D-Werkzeugen. Prüfe das Ergebnis in Bewegung aus Vorder-, Seiten- und Rückansicht. Bilder und Billboards eignen sich für einzelne Oberflächenelemente; der Fahrer in der Rennszene braucht glaubwürdige räumliche Form und Bewegung.

## 7. Ein vollständiger Einstieg ins Kartspiel

Gestalte den Ablauf vom Antippen der Spielkarte bis zum Rennen als zusammenhängendes Erlebnis:

**Kart-Einstieg:** Ein kurzes, überspringbares Lumo-Kart-Intro mit eigenem Logo, Musik und einer kleinen Bewegungsszene. Lumo fährt sichtbar ins Bild, bremst oder driftet kontrolliert ein und reagiert freundlich. Danach ist das Menü direkt bedienbar.

**Menü:** Animierte Strecken-/Kart-Vorschau, klare Auswahlmöglichkeiten, passende Musik, erkennbare Schaltflächen und aktuelle Freischaltzustände.

**Streckenvorschau:** Vor einem Rennen zeigt eine Kamerafahrt für ungefähr 4–6 Sekunden einige markante Orte der ausgewählten Strecke. Titel, Cup und Streckendetails erscheinen im passenden Moment. Überspringen ist jederzeit möglich.

**Startaufstellung:** Fahrer und Karts fahren oder rollen nachvollziehbar auf ihre Startplätze. Die Kamera geht weich in die Rennansicht über. Startampel, Countdown, Motorgeräusche und Musik stimmen zeitlich überein. Die Fahrzeugsteuerung wird exakt zum Rennstart freigegeben.

**Zieleinlauf:** Eine kurze Kamerasequenz, passende Figurreaktion, musikalischer Abschluss und ein verständlicher Ergebnisbildschirm führen zurück zu Wiederholen, nächster Strecke oder Menü.

Nutze bevorzugt Sequenzen aus der tatsächlichen Spielwelt. Wenn ein Video sinnvoll ist, erstelle und integriere es mit passendem Dateiformat und zuverlässiger Wiedergabe. Vorgefertigte Filme dürfen das eigentliche Rennspiel nicht ersetzen. Vorladen, Überspringen, Pause, App-Wechsel und erneuter Einstieg müssen funktionieren.

## 8. Strecke und Umgebung: glaubwürdige Rennwelten

Bring zunächst eine repräsentative vorhandene Strecke über den gesamten Rennablauf auf ein überzeugendes Niveau. Nutze diese fertige Strecke als Grundlage für die übrigen Welten.

Orientiere dich bei Strecken, Kartgröße, Kamera, Tempo und Umgebungsdichte an den vorhandenen Bild- und Videoreferenzen. Wenn du die Videos erreichen kannst, untersuche mehrere aussagekräftige Stellen statt nur das erste Bild.

Jede überarbeitete Strecke benötigt:

- nachvollziehbaren Verlauf, gut lesbare Kurven, unterschiedliche Abschnitte und erkennbare Orientierungspunkte;
- passende Fahrbahnmaterialien, Randbereiche, Leitplanken und Beschilderung;
- gestaltete Umgebung im Vorder-, Mittel- und Hintergrund;
- Höhenwechsel, Brücken, Tunnel, Rampen oder Abkürzungen, soweit sie zum Streckenkonzept passen;
- echte räumliche Geometrie, passende Kollisionen und sichere Rücksetzpunkte;
- bewegte Umgebungsdetails wie Wasser, Wolken, Lichter oder kleine Figuren;
- Startbereich, Checkpoints, Ziel und sichtbare Identität der jeweiligen Welt.

Die vorhandenen Welten sollen sich durch Form, Farbklima, Material, Musik und Streckenverlauf unterscheiden. Prüfe Wissenswald, Lichterstadt, Wasserfall-Klippen und Himmelsinseln anhand der dokumentierten Vorlagen, soweit sie zum aktuellen Stand gehören.

Baue eine konsistente Asset-Pipeline für Modelle, Texturen, Materialien, Effekte und Vorschaugrafiken auf. Sorge dafür, dass die Dateien im Projekt und in der APK enthalten sind. Fehlende Dateien müssen konkret benannt werden; behebe reproduzierbare Pipeline-Probleme selbstständig.

## 9. Fahrgefühl, Kamera und kindgerechte Steuerung

Das Kart soll sich direkt, flüssig und verständlich fahren lassen. Prüfe Beschleunigung, Bremsen, Lenkung, Drift, Haftung, Rampen, Sprünge, Landung, Kollisionen und Rücksetzen als zusammenhängendes System.

Die Verfolgerkamera soll Strecke und bevorstehende Kurven zeigen, Fahrzeugbewegungen weich begleiten und Geschwindigkeit spürbar machen. Setze Veränderungen von Blickwinkel, Abstand, Licht und Effekten gezielt ein. Kamerawackeln bleibt sparsam und abschaltbar.

Die Steuerung ist verbindlich:

- Links ein moderner analoger Joystick mit gut erkennbarem Griff und unmittelbarer Rückmeldung.
- Rechts eigene Buttons für Gas, Boost, Drift, Bremse und Item.
- Kindgerechte, ausdrucksstarke Motive: beispielsweise Gas-Pfeile, Rakete, Drift-Reifen, Bremssymbol und Überraschungsbox, passend zur Lumo-Gestaltung.
- Auf dem Fold deutlich größere Bedienflächen und sinnvolle Abstände; auf dem Außendisplay bleibt die Rennansicht nutzbar.
- Größen nach logischer Bildschirmfläche und tatsächlicher Bedienbarkeit abstimmen. Berücksichtige Pixeldichte, Seitenverhältnis, Safe Areas und Daumenreichweite.
- Mehrfache gleichzeitige Berührungen müssen zuverlässig funktionieren, insbesondere Lenken plus Gas plus Boost.
- Bei Pause, App-Wechsel, Fingerverlust und Auf-/Zuklappen dürfen keine gedrückten Eingaben hängen bleiben.

Prüfe Item-, Drift- und Boost-Rückmeldungen im tatsächlichen Rennen. Die Wirkung muss optisch, akustisch und im Fahrverhalten verständlich sein. Gegner sollen glaubwürdig fahren, Kurven bewältigen und mit dem Renngeschehen umgehen. Schwierigkeitsgrade und Fahrhilfen müssen Kindern einen fairen Einstieg ermöglichen.

**Lumo Kart ist ein Freizeitspiel. Im laufenden Rennen gibt es keine Lernfragen, Antworttimer oder Turbo-Belohnungen für richtige Lernantworten.** Die Freischaltung durch Lernfortschritt bleibt außerhalb des Rennens gemäß den bestehenden Projektregeln.

## 10. Die neue Lumo-Stimme in der Lern-App

Die aktuelle Stimme erfüllt meinen Anspruch nicht. Lumo soll wie eine lebendige Cartoon-Figur mit einer menschlich klingenden Stimme sprechen. Er braucht eine eigene, wiedererkennbare Persönlichkeit, die zur Fuchsfigur passt.

Die gewünschte Stimme ist:

- warm, freundlich, hell und verspielt;
- ausdrucksstark und natürlich in Betonung, Satzmelodie, Rhythmus und Pausen;
- kindgerecht und leicht verständlich, mit ruhigem Tempo beim Erklären;
- fröhlicher und energischer bei Begrüßung, Spielen und Erfolg;
- geduldig und ermutigend bei Fehlern und Unsicherheit;
- konsistent über Begrüßung, Aufgabenhilfe, Rückmeldungen und Belohnungen hinweg.

Gestalte sie als freundlichen sprechenden Cartoon-Fuchs mit menschlicher Ausdruckskraft. Eine bloß hochgestellte Tonhöhe reicht dafür nicht. Beurteile auch, ob die Stimme auf Dauer angenehm ist und längere Erklärungen verständlich bleiben.

Prüfe die bisherige TTS-/Audio-Pipeline, die tatsächliche Stimmenauswahl auf Android, Sprechtempo, Aussprache, Unterbrechungen und Wiederholungen. Nutze eine hochwertige verfügbare Sprachsynthese oder geeignete professionelle Sprachaufnahmen. Entscheide anhand hörbarer Ergebnisse. Häufige kurze Begrüßungs- und Reaktionssätze können als sauber produzierte Audiodateien vorliegen; variable Aufgaben und Erklärungen brauchen eine passende Sprachsynthese.

Erstelle drei kurze, hörbare Stimmvarianten mit denselben deutschen Beispieltexten: eine Begrüßung, eine kleine Mathe-Erklärung und eine ermutigende Rückmeldung nach einem Fehler. Je Variante reichen etwa 15–25 Sekunden. Beschreibe knapp ihre Unterschiede und integriere eigenständig die am besten passende Variante als Standard. Zeige mir die Proben zur späteren Feinabstimmung; halte die unabhängigen Entwicklungsarbeiten dafür nicht an.

Die ausgewählte Stimme muss in der tatsächlichen Lern-App verwendet werden. Prüfe die Aussprache von Zahlen, Rechenzeichen, Buchstaben, Namen und Aufgabenanweisungen. Eine Demo außerhalb der App ist nur ein Zwischenschritt.

Behalte verständliche Textanzeigen und einen funktionierenden Offline-Fallback. Nutze vorhandene freigegebene Dienste und Konfigurationen; Zugangsdaten gehören in die dafür vorgesehene sichere Infrastruktur. Wenn eine gewünschte Stimme mangels Zugang nicht verfügbar ist, integriere die beste nutzbare Alternative und benenne die noch offene Qualitätsstufe konkret.

Sorge für verlässliches Stummschalten, Abbrechen und erneutes Sprechen. Beim Wechsel der Aufgabe darf alter Text nicht weiterlaufen. Musik wird während einer Erklärung sanft abgesenkt und danach wieder angehoben. Falls die vorhandene Lumo-Figur bereits Sprechzustände oder Mundanimation unterstützt, synchronisiere sie mit dem tatsächlichen Audio. Ein vollständiges neues Figuren-Rig bleibt die spätere Etappe.

## 11. Moderne Musik und Sound als Teil des Spielerlebnisses

Musik, Motoren und Effekte müssen in der laufenden App hörbar und gut abgestimmt sein. Die Musik soll insgesamt moderner, klanglich hochwertiger und musikalisch überzeugender werden. Im bekannten Stand liegen unter `lumo-godot/assets/audio/kart/` bereits Musikstücke und Effekte. Prüfe zuerst deren tatsächliche Einbindung, Wiedergabe und Qualität.

Entwickle eine eigene Lumo-Klangwelt aus klaren Melodien, modernen elektronischen und instrumentalen Klangfarben, einem gut abgestimmten Bassfundament und abwechslungsreicher Rhythmik. Die Stücke sollen Neugier, Abenteuer und Freude vermitteln. Passe die Energie an die Situation an: ruhiger beim Lernen, einladend im Menü, dynamisch beim Rennen und feierlich beim Zieleinlauf.

Verbessere neben den Kompositionen auch Arrangement, Klangqualität, Mischung, Dynamik und Übergänge. Eine überall wiederholte kurze Melodie oder zusätzliche Lautstärke erfüllt diesen Auftrag nicht. Wähle eine stimmige Richtung selbstständig und liefere hörbare Vorher-/Nachher-Ausschnitte.

Sorge für:

- eine eigene musikalische Identität von Lumo Kart;
- eine dezente, abschaltbare musikalische Gestaltung der Lern-App, soweit sie die jeweilige Aufgabe unterstützt;
- geeignete Musik für Intro, Menü, Garage, einzelne Welten, Rennen und Ergebnis;
- saubere Schleifen und weiche Übergänge;
- passende Motor-, Drift-, Boost-, Sprung-, Kollisions-, Item- und Zielgeräusche;
- klar getrennte Einstellungen für Musik und Effekte;
- verständliche Countdown-Signale und angenehm abgestimmte Lautstärken;
- eine funktionierende Stummschaltung sowie korrektes Verhalten bei Pause, App-Wechsel und Audio-Unterbrechungen.

Prüfe die Musik auch über eine tatsächliche Tonaufnahme aus dem laufenden Spiel. Wenn vorhandene Stücke den gestalterischen Anspruch nicht erfüllen, verbessere Arrangement, Klang und Variation oder erstelle geeignete eigene Stücke mit verfügbaren Werkzeugen. Dokumentiere die Herkunft verwendeter Audio-Assets.

Eine andere letzte Runde kann musikalisch intensiver wirken; Abstimmung und Übergang sollen bewusst komponiert sein. Verhindere überlagerte Musik beim wiederholten Öffnen oder Neustarten.

## 12. Spielmenüs und weitere Inhalte

Verbinde Spielewelt, Moduswahl, Cups, Strecken, Garage, Freischaltungen und Ergebnisse zu einem klaren Ablauf. Nutze tatsächliche Fortschrittsdaten und verständliche Zustände.

Erhalte die übrigen vorhandenen Spiele und behebe gemeinsame Darstellungs- oder Navigationsfehler. Konzentriere die aufwendige neue Renninszenierung zunächst auf Lumo Kart.

Ein angebotener spielbarer Modus braucht die entsprechende Spiellogik und einen vollständigen Ablauf. Noch nicht implementierte Inhalte werden korrekt gekennzeichnet. Für gesperrte vorhandene Inhalte muss die tatsächliche Freischaltbedingung sichtbar sein.

## 13. Leistung auf Android und Fold

**60 FPS sind das Entwicklungsziel.** Messe Leistung in einer Release-Version und unterscheide Desktop, Emulator und physisches Gerät eindeutig.

Prüfe Framezeiten, längere Aussetzer, Speicherbedarf, Ladezeiten und Verhalten über mehrere Rennen. Als Referenz für 60 FPS dient eine Framezeit von rund 16,7 ms; beurteile zusätzlich die langsameren Frames und wiederkehrendes Ruckeln.

Verwende geeignete mobile Materialien, kontrollierte Partikelmengen, Texturgrößen, Sichtweiten, Schatten und Detailstufen. Entscheide anhand von Messungen, welche Effekte teuer sind. Bewahre die visuelle Identität auch bei reduzierter Qualität.

Prüfe mindestens Außen- und Innendisplay, Hoch- und Querformat, Auf-/Zuklappen während eines Rennens, Pause/Fortsetzen und Hintergrund/Vordergrund. Die Prüfung des Screenwechsels muss Spielzustand und Eingaben einschließen.

Wenn kein physisches Fold verfügbar ist, liefere belastbare Emulator-/Layoutprüfungen und einen konkreten Gerätetest. Kennzeichne die physische FPS-Messung als offen. Behaupte keine geprüften 60 FPS auf meinem Gerät ohne Messung.

## 14. Sichtbarer Fortschritt während der Arbeit

Ich muss erkennen können, was du tatsächlich gemacht hast. Gib während der aktiven Bearbeitung regelmäßig kurze, konkrete Rückmeldungen. Melde bei längeren Werkzeugläufen oder Builds nach Möglichkeit spätestens nach etwa einer Minute den realen Zustand.

Nach jeder wesentlichen visuellen Etappe liefere:

1. einen echten Screenshot aus der laufenden App oder Spielszene;
2. einen Vergleich mit Ausgangsstand und passender Vorlage;
3. eine kurze Erklärung der sichtbaren Verbesserung und verbleibender Abweichungen.

Für Animation, Einfahrt, Kamerafahrt, Drift, Boost und Zieleinlauf liefere kurze Aufnahmen aus dem laufenden Spiel. Für Musik und die neue Lumo-Stimme muss die Aufnahme Ton enthalten. Kennzeichne gerenderte Konzepte und echte Laufzeitaufnahmen eindeutig.

Bewerte Lesbarkeit, Figurentreue, räumliche Qualität, Bewegung, Sound und Fahrgefühl getrennt. Überarbeite erkennbare Schwächen, bevor du die betreffende Etappe als fertig bezeichnest. Eine reine Änderung des Quellcodes reicht für die visuelle Abnahme nicht aus.

## 15. Autonom arbeiten und Unterbrechungen vermeiden

Dieser Auftrag erlaubt dir, die beschriebenen Verbesserungen selbstständig umzusetzen, reversible Änderungen vorzunehmen, zu prüfen und in passenden Arbeitsbranches zu sichern. Entscheide übliche Gestaltungs- und Implementierungsdetails selbst.

Halte einen kurzen Arbeitsplan mit dem nächsten konkreten Schritt aktuell. Arbeite nach Analyse und Planung unmittelbar an der Umsetzung weiter. Stelle Rückfragen nur, wenn eine unverzichtbare Information fehlt oder eine Entscheidung den vereinbarten Umfang wesentlich verändert.

Nutze verfügbare Fachwerkzeuge für Grafiken, Modelle, Audio und Animation. Falls deine Umgebung mehrere Arbeitsagenten unterstützt und die Aufteilung sinnvoll ist, kannst du klar getrennte Aufgaben verteilen. Koordiniere Dateiverantwortung und Integration; prüfe die Ergebnisse selbst.

Verändere nur die für den Auftrag notwendigen Teile der Architektur. Sichere Arbeit in nachvollziehbaren Commits. Beachte vorhandene Rechte und Freigaben für Merge, Release und Veröffentlichung; erledige alle vorbereitenden Arbeiten, bevor dafür eine noch fehlende Freigabe benötigt wird.

Bei einem Fehler: Ermittle die Ursache anhand der tatsächlichen Ausgabe, korrigiere sie und wiederhole die passende Prüfung. Bewahre sinnvolle Tests und behebe fehlerhafte Erwartungen anhand des gewünschten Verhaltens. Bei fehlendem Werkzeug oder Zugang benenne den konkreten Blocker und arbeite an unabhängigen Teilen weiter.

Vor einem Kontext- oder Sitzungslimit sichere Code und dokumentiere Branch, Commits, Buildstand, erledigte Arbeiten, verbleibende Fehler, Screenshots und den nächsten Schritt. Ein Folgechat muss an diesem Stand weiterarbeiten können.

## 16. Prüfung und auslieferbare APK

Führe die bestehenden relevanten Flutter-, Godot- und Android-Prüfungen aus. Ergänze gezielte Tests dort, wo neue Logik oder ein konkreter Fehler sie rechtfertigen.

Prüfe insbesondere Start, Navigation, Lernaufgabe, Lumo-Stimme, Musik, Stummschaltung, Speicherung, Spieleinstieg, Rennstart, gleichzeitige Touch-Eingaben, Pause, Rückkehr zur App, Bildschirmwechsel, Zieleinlauf und Wiederholung. Erhalte die reparierte Item-Lesbarkeit und prüfe die Aktion selbst. Bei Android 16 unterscheide eine Änderung der Displaygröße von einer tatsächlichen Gerätedrehung; beides muss mit echten Aufnahmen und Zustandsprüfungen belegt werden.

Baue die gemeinsame APK aus einem dokumentierten, abgestimmten Quellstand. Prüfe Paketkennung, Versionsnummer, Signatur, eingebetteten Godot-Stand und die enthaltenen Assets. Erhalte, soweit die vorhandene App-Konfiguration es ermöglicht, den Updatepfad und die gespeicherten Profile.

Liefere eine Datei mit der tatsächlichen Endung `.apk`, einem eindeutigen Dateinamen und einem überprüften Download. Prüfe Installation und Start dieser exakten Datei. Berichte klar, welche Installation ein Update der bestehenden Variante ist und ob eine andere Paketkennung eine separate App erzeugt.

Die Abschlusslieferung umfasst:

- die installierbare APK;
- Links zu den Arbeitsbranches oder Pull Requests;
- echte Screenshots für Handy und Fold;
- hörbare Stimmvarianten und eine Aufnahme der integrierten neuen Lumo-Stimme;
- eine Aufnahme des vollständigen Rennablaufs mit hörbarem Ton;
- eine kurze Beschreibung der Änderungen und der tatsächlich ausgeführten Prüfungen;
- die wenigen noch offenen Punkte mit genauer Ursache und nächstem Schritt.

## 17. Wann der Auftrag als erfüllt gilt

Die fertige Etappe muss als Ganzes überzeugen:

- Die Lern-App entspricht den verbindlichen Vorlagen und wirkt durch abgestimmte Bewegung lebendig.
- Buttons, Texte und Layouts sind auf beiden Fold-Flächen gut bedienbar.
- Lumo im Kart ist anhand der bestehenden Figurenvorlagen wiedererkennbar.
- Lumo in der Lern-App spricht mit der ausgewählten menschlich klingenden Cartoon-Stimme; Erklärung, Aussprache und Audiosteuerung sind geprüft.
- Intro, Einfahrt, Streckenvorschau, Start, Rennen, Zieleinlauf und Ergebnis bilden einen funktionierenden Ablauf.
- Musik und Effekte sind hörbar, musikalisch und klanglich verbessert, sinnvoll abgestimmt und korrekt steuerbar.
- Eine vollständig überarbeitete Strecke zeigt die angestrebte visuelle und spielerische Qualität im Betrieb.
- Fahrgefühl, Kamera, Touch-Steuerung und Bildschirmwechsel sind geprüft.
- Die APK ist gebaut, herunterladbar und mit nachvollziehbarem Ergebnis installiert worden.

**Beginne jetzt mit der Bestandsprüfung und gehe anschließend unmittelbar in die Umsetzung. Arbeite innerhalb dieses Auftrags eigenständig bis zu einem konkret überprüfbaren Ergebnis.**
