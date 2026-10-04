# Lumo: Produkt- und Umsetzungsauftrag – Lernen schaltet Spiele frei

Stand: 04.10.2026. Auftraggeber: Heinz Ullmann. Adressaten: die tatsächlich beteiligten Luna/Copilot-, Claude/Opus- und ChatGPT-Sitzungen. Dieses Dokument ist ein Arbeitsauftrag, kein Implementierungs- oder Abnahmebericht. Es konkretisiert Heinz' neue Produktentscheidung und ergänzt die bestehenden Referenzbilder. Technische Vorschläge, Startparameter und Zeitplanung sind ausdrücklich Vorschläge von ChatGPT, keine von Nintendo übernommenen Daten und keine bereits gemessenen Ergebnisse.

## 1. Verbindliche Produktentscheidung und Vorrang

Lumo bleibt in erster Linie eine Lern-App für die 1.–4. Klasse Volksschule. Lernen, richtige Auswertung, verständliche Hilfen, stabile Speicherung und kindgerechte Bedienung haben Vorrang vor dem Ausbau des Rennspiels. Gute Lernfortschritte eröffnen zusätzliche Spiele. Die freigeschalteten Spiele sind anschließend echte Freizeitspiele und keine weiteren versteckten Unterrichtseinheiten.

Die gewünschte Reihenfolge ist Memory, danach ein eigenes UNO-ähnliches Kartenspiel, gegebenenfalls ein oder zwei später ausgewählte kleine Spiele und schließlich das größere **Lumo Kart**. „Lumo Cards“ bezeichnet ausschließlich ein Kartenspiel, nicht das Rennspiel. Weitere Minispiele sind noch nicht ausgewählt; keine erfundenen Freigaben oder aufwendigen Neuentwicklungen dafür. Bestehende Spiele zunächst prüfen und wiederverwenden.

**Im Rennspiel gibt es keine Lernfragen, keine Lern-Cups, keine Antworttimer und keine Belohnung für eine Rechenantwort während der Fahrt.** Auch ein optionales Lernportal darf nicht heimlich wieder eingeführt werden. Die alte Vorgabe „Lern-Challenge / Richtig = Turbo“ in `docs/DESIGN_ZIEL_2026-10-04.md`, insbesondere Bild 08, ist durch diesen Auftrag ersetzt. Bücher und Portale in den gelieferten Motiven dürfen Dekoration oder rein spielerische Elemente sein; niemals eine Lernunterbrechung. Die vorhandenen Lernmodule außerhalb des Spiels bleiben erhalten.

Die sonstige Gestaltung bleibt verbindlich: die vorhandenen elf Flutter-Zielbilder und die zehn Kart-Referenzen. Dunkelblaue Fantasy-Welt, Cyan-Leuchten, hochwertige Fuchsfigur, plastische Symbole, Gold für Belohnungen, Glaskarten und saubere Navigation. Keine neue Stilrichtung, keine flachen Ersatzgrafiken als fertige Gestaltung und keine komplett neue App neben der bestehenden. Dynamische Zahlen, Namen, Spielstände und Fortschrittswerte müssen echt sein; beispielhafte Zahlen in Mockups werden nicht fest einprogrammiert.

## 2. Geprüfter Ausgangsstand und Arbeitsgrenzen

Zum Erstellen dieses Auftrags wurden live gelesen: #156 auf `be1e48ae3110351de81dd6ea20e15bbb9508c3ae`, #167 auf `f1b86c052336a687bb6e7440f6570d889a3de024`, Godot #4 auf `08f3f3f60eb9712c7823faceec2350293d292ce5`, aktuelle Kommentare, CODEX_START und Design-Dokumente. Vor jedem tatsächlichen Arbeitsschritt erneut lesen, nicht diese SHAs als ewig aktuell behandeln.

Der CI-Upload-Fix liegt bereits in #167. Die dort dokumentierten Originalnachweise nennen 15 bestandene Vertragstests, 503 bestandene Fluttertests, vier übersprungene Tests, keine Testfehler sowie 20 Analyzer-Warnungen und 119 Hinweise. Luna hat denselben Kandidaten unabhängig bestätigt. Beim letzten Abruf ist der PR weiterhin offen/Draft; eine neue Claude-Abnahme fehlt. Nicht noch einmal die bereits korrigierte YAML neu entwickeln. Zuerst den vorhandenen Kandidaten entsprechend den bestehenden Prüf- und Freigaberegeln abschließen und seine tatsächliche Übernahme nachweisen. Ein fehlender unabhängiger Bericht bleibt offen, auch wenn die technische CI grün ist. Keine erforderliche Freigabe umgehen.

**Wichtige Integrationslücke:** `config/godot-source.json` im gelesenen Flutter-Head pinnt weiterhin `77269301e63b340d2ad85b23b346b4973157d17b`, nicht den neueren Godot-PR-Head `08f3f3f...`. `scripts/export_embedded_game.py` exportiert genau diese gepinnte Revision. Fortschritte im Godot-Repository erscheinen deshalb nicht automatisch in der gemeinsamen APK. Erst den vorgesehenen Godot-Kandidaten prüfen, dann den Pin in einem beanspruchten Integrationsschritt aktualisieren und das resultierende PCK nachweisen. Keinen ungeprüften Branch einfach als neue Version verpacken.

`prepare_embedded_games.py` setzt derzeit die private Game-Activity auf Portrait und deaktiviert Impeller wegen eines dokumentierten Emulator-/Rendererproblems. Für Landschaftsrennen, Aufklappen und Fensterwechsel ist ein gezielter Host-Test nötig. Nicht pauschal den Renderer umstellen oder Schutzregeln entfernen. `build_unified_apk.sh` hat noch die Standardwerte Version 0.10.5/Build 280: für einen neuen Kandidaten eine geprüfte, monoton höhere Buildnummer explizit übergeben.

Kein Merge nach main, kein öffentlicher Release, kein Force-Push, keine Datenlöschung und keine Änderungen an Secrets, Kontingenten oder Abrechnung durch diesen Auftrag. Die zwei bestehenden Agenten werden nicht umbenannt oder ersetzt. Ein Kommentar beweist nicht, dass eine bestimmte Modellinstanz gerade aktiv ist.

## 3. Zusammenarbeit und eindeutige Zuständigkeiten

Luna/Copilot bearbeitet die laufende Flutter-Gestaltung, Navigation, responsive Ansichten und Kart-Integration. Claude/Opus übernimmt eigenständige Flutter-Prüfung, Lernlogik, Fortschrittsregeln und TTS, soweit seine bestehende Sitzung verfügbar ist. ChatGPT liefert unabhängige Asset-, Quellcode-, Nachweis- und APK-Prüfungen sowie diesen Produktauftrag. Gemeinsame Dateien wie AppState, Wallet oder Shell erhalten genau einen Bearbeiter; der andere formuliert Tests und Review statt parallel zu schreiben.

Vor einer Änderung: aktuellen Head, neue Kommentare, betroffene offene PRs, tatsächlich bereits übernommene Änderungen und Claims lesen. Dann CLAIM mit Aufgabe, Basis-SHA, konkreten Dateien und Abnahmetest. Vor Push erneut abgleichen. Ein bestehender passender Beitrag hat Vorrang. Keine neuen Sitzungen oder Tasks zum Umgehen eines erreichten Limits.

Jeder echte Fehler erhält drei dokumentierte Runden: erst Reproduktion mit SHA/Log und Ausschluss einer bereits vorhandenen Reparatur; zweitens tatsächlich eingegangene unabhängige Gegenprüfung samt Alternativen; drittens Wahl der kleinsten belegten Lösung, genau ein Reparateur, anschließend Nachtests durch die anderen. Niemand formuliert eine nicht eingegangene Antwort als Zustimmung. Bei ausbleibender Rückmeldung den betroffenen Merge blockieren, aber nicht konfliktfreie Bestandsaufnahme und Dokumentation unnötig anhalten.

## 4. Bildpaket: echte Bytes, richtige Verwendung, keine Scheintransparenz

Die zuletzt im Chat erneut gelieferten Dateien `49537.png` bis `49546.png` sind intern JPEG/RGB ohne Alphakanal, trotz ihrer Dateiendung. Die dazugehörigen früheren Originale liegen in dieser Sitzung als echte PNG/RGBA-Dateien mit 1448×1086 Pixeln und Alpha-Werten 0–255 vor. Für weitere Verarbeitung diese Originale verwenden, nicht die schwarz hinterlegten JPEG-Kopien. Schwarze Reifen, Schatten und Konturen dürfen nicht durch eine globale Schwarz-zu-Transparent-Regel beschädigt werden.

Das lokale Transportpaket `Lumo_Originalbilder_und_Produktauftrag_2026-10-04.zip` enthält zehn unveränderte Originaltafeln, Herkunftsmanifest, Prüfsummen und diesen Auftrag. Es ist ausdrücklich **kein neues Einzelbildpaket**. Die bereits separat beanspruchte/erstellte Einzelbildaufbereitung aus #156 Kommentar 5979086228 hat Vorrang; deren Hash und tatsächlichen Empfang getrennt prüfen. Dieses Originalarchiv dient als belastbare Quelle und Reserve, nicht als konkurrierender Austausch aller fertigen Zuschnitte. Kein ChatGPT-Pfad `/mnt/data/...` ist automatisch im Copilot-Workspace vorhanden. Eingang erst bestätigen, wenn die ZIP dort tatsächlich heruntergeladen, entpackt und gehasht wurde.

| Originaltafel im Transportpaket | Zuordnung und Einsatz |
|---|---|
| `01_ui_icons.png` | Start, Lernen, Spielen, Profil, Einstellungen; bestehende kanonische Icons aus #165 nicht doppelt importieren |
| `02_rewards.png` | Abzeichen, Geschenk, Stern, Medaille, Truhe; Fortschritts- und Freischaltanzeigen |
| `03_gameplay.png` | Turbo-Pad, Ring, Itembox, Schild, Batterie, Reparatur; Vorschau und Vorlage für echte Spielobjekte |
| `04_track_modules.png` | Gerade, Links-/Rechts-/S-Kurven, Rampen, Brücken, Tunnel, Kreuzungen und Zielsegment |
| `05_track_props.png` | Startampel, Tore, Schilder, Leitplanken, Fahnen, Zuschauerstand und Streckendekoration |
| `06_nature.png` | Inseln, Wasserfälle, Baum, Felsen, Brücke, Wolken, Kristalle und Aussichtspunkt |
| `07_architecture.png` | Bibliothek, Stadt, Sternwarte, Glastunnel, Ruinen und Portale |
| `08_garage_parts.png` | Reifen, Felge, Spoiler, Sitz, Lenkrad, Helm, Werkzeug und Garage |
| `09_characters_karts.png` | Lumo-Posen, Kart-Ansichten und drei weitere Fahrer als Vorschau-/Gestaltungsreferenz |
| `10_master_reference.png` | Gemeinsame Material-, Farb- und Formreferenz; nicht zusätzlich zu allen Einzelmotiven ins Laufzeitpaket kopieren |

Jeden Zuschnitt mit Quellhash, Ausschnittkoordinaten, Bildgröße, Alpha-Prüfung und späterem Zielpfad dokumentieren. Keine abgeschnittenen Ohren, Reifen, Sterne oder Leuchthöfe. Auf Weiß, Dunkelblau und Schachbrett prüfen; einen vorhandenen Leuchthof nicht mit einem schmutzigen Freistellrand verwechseln. Ein Motiv pro Laufzeitdatei; transparente Innenöffnungen erhalten. PNGs nicht unnötig hochskalieren. Spritesheets nicht als riesige Ganzbilder für kleine Menüsymbole decodieren. Quelldateien und Referenztafeln nicht wahllos in die APK bündeln.

Die Tafeln liefern **2D-Bilder mit gerenderter 3D-Optik**, keine räumlichen Modelle, Rückseiten, UVs, Riggs oder Kollisionskörper. Strecken-PNGs sind für Auswahlkarten und Modellvorlagen geeignet. Für frei fahrbare Rennstrecken sind echte Geometrie und Kollision erforderlich. Kein Billboard-Straßenfoto als vermeintliche 3D-Rennwelt ausgeben. Fehlende Fachsymbole, Bewegungsphasen und spezielle Kartteile als offen erfassen; dieses Paket ist keine Behauptung, jedes Detail der gesamten App sei bereits vorhanden.

## 5. Lernkern und Freischaltmodell

Zuerst alle vorhandenen Fach- und Klassenwege prüfen: Start → Lernen → Klasse → Fach → Thema → Aufgabe → Hilfe → Antwort → Speichern → nächste Aufgabe. Besonders Plus bis 10, Bruchrechnen, Lesen, Diktat und Schreibcoach nicht durch neue Karten unsichtbar machen. Fehlerhafte Antwortprüfung vor dekorativen Animationen korrigieren. Klassenangemessene Inhalte und deutsche Texte erhalten; englische Entwicklermeldungen gehören nicht in die Kinderoberfläche.

Als technische Empfehlung drei getrennte Werte führen: dauerhafte Lern-Meilensteine, spielinterne verdienbare Währung und gegebenenfalls verifizierte Kaufberechtigungen. Spielmünzen dürfen nicht nachträglich Lernfortschritt erzeugen. Ausgegebene Sterne dürfen ein einmal freigeschaltetes Spiel nicht wieder sperren. Ein bestätigter Lernfortschritt muss vor Animation und Seitenwechsel dauerhaft gespeichert werden; Fehler bei Speicherung dürfen keinen Erfolg vortäuschen. Stabile Ereignis-IDs verhindern doppelte Belohnungen nach Wiederholung, Prozessneustart oder erneuter Brückenübertragung.

Die konkrete Freischaltkurve wird als versionierte Konfiguration umgesetzt, nicht verteilt in Widgets. Heinz hat keine numerischen Schwellen bestimmt. Für automatisierte Tests dürfen ausdrücklich markierte Beispieldaten verwendet werden; daraus keine produktive Regel „1000 Antworten bis Kart“ ableiten. Vorschlag: einzigartige abgeschlossene kurze Lektionen beziehungsweise nachvollziehbare Kompetenz-Meilensteine statt bloßer Tippzahl zählen. Wiederholtes Öffnen derselben Lektion zählt nicht beliebig weiter. Hilfen, langsames Lernen und falsche Versuche führen nicht zum Verlust bereits erreichter Freischaltungen.

Tests müssen den Zustand vor, genau auf und nach jeder Schwelle abdecken, außerdem zwei Profile, Offline-Neustart, mehrfach zugestellte Ereignisse, beschädigte Daten und Migration vorhandener Spielstände. Bereits erworbene Rechte nicht stillschweigend entziehen; eine entsprechende Bestandsschutzregel als Migrationsentscheidung dokumentieren. Für noch nicht gewählte Minispiele einen deaktivierten Konfigurationseintrag vorsehen, aber keine nie erfüllbare Voraussetzung vor Lumo Kart setzen.

Die Sperre muss fachlich am Spieleinstieg gelten, nicht nur am sichtbaren Schloss. Shell, Deep Link, Launcher und native Brücke dürfen sie nicht unbeabsichtigt umgehen. Lerninhalte selbst bleiben erreichbar. Ein optionaler, klar gekennzeichneter Entwickler-Testmodus darf Testdaten bereitstellen, jedoch nicht unbemerkt im Produktionsprofil alles freischalten. Freischaltung wird einmal freundlich angezeigt und danach dauerhaft gespeichert, ohne Countdown, Verlustdrohung oder Kaufdruck.

## 6. Oberfläche und zeitgemäße Bedienung

Die vorhandenen Design-Tokens und Komponenten erweitern statt neue Parallel-Widgets pro Bildschirm anzulegen. Kopfzeile, XP-Anzeige, Glaskarten, Cyan-Rand, Schatten, Abstände, Typografie und Zustände zentral halten. In der Spielewelt erst sichtbar machen, was freigeschaltet ist; gesperrte Spiele mit klarem nächsten Lernziel zeigen. Der große Kart-Einstieg bleibt ein attraktives langfristiges Ziel, dominiert aber nicht jede Lernseite.

Auf dem Außendisplay eine kompakte Navigation und ausreichend große Berührungsflächen; auf dem geöffneten Fold eine tatsächlich angepasste Anordnung mit mehr Übersicht, nicht lediglich auseinandergezogene Handy-Karten. Nach verfügbarem Fensterplatz entscheiden, nicht nach festem Modellnamen. MediaQuery.sizeOf und LayoutBuilder sowie gemeinsame Navigationsziele sind die dafür von Flutter beschriebenen Bausteine [Q1]. Scharnier, Aussparungen, Systemleisten, große Schrift und Mehrfensterbetrieb im Test berücksichtigen.

Für zeitgemäße Qualität wurden aktuelle Primärquellen recherchiert: Material 3 Expressive betont unter anderem Bewegung, flexible Typografie und adaptive Komponenten [Q2]. Das ist eine Bedienungsorientierung, kein Auftrag zur Abkehr von Heinz' blauem Referenzdesign oder zum Framework-Wechsel. Apples Design-Auszeichnungen 2026 würdigen bei Sago Mini Jinja’s Garden eine intuitive Wischbedienung, mit der Kinder ohne lange Anweisungen spielen können [Q3]. Daraus folgt hier als eigene Designempfehlung: eindeutige Interaktionen, wenig Erklärungstext, sofortiges Feedback und ein konsistenter Fuchs statt unverbundener Effektfülle.

Effekte müssen Information unterstützen: kleines Antippfeedback, nachvollziehbare Übergänge und Belohnungsanimation nach bestätigter Speicherung. Lernaufgaben erhalten ruhigere Hintergründe als die Garage. Keine dauerhaft wandernde Textfläche; keine Antwort wird überdeckt. Reduzierte Bewegung und ausgeschaltete Stimme respektieren. Die Bilder zeigen Zielstil, keine festen Beispielnamen oder 12-Sterne-Pflicht. Einen Screenshotvergleich mit echten Daten erstellen und erlaubte Produktabweichungen ausdrücklich markieren.

## 7. Lumo Kart: Welten, Strecken und räumliche Umsetzung

Den vorhandenen frei lenkbaren Godot-Stand zunächst prüfen; nicht erneut eine neue Engine oder einen zweiten Renncontroller beginnen. Vorhandene Runden-, Ghost-, Pause- und Host-Funktionen weiterverwenden, soweit passend. Lernfragenpfade deaktivieren und testsicher entfernen, aber die allgemeine Ergebnis-/Speicherbrücke nicht zerstören. Keine Pflicht zum Auswendiglernen oder Rechnen vor einer Itembox.

Aus den Referenzen ergeben sich vier zentrale Weltthemen: Himmelsinseln, Wasserfall-Klippen, Lichterstadt sowie Wissenswald/Bibliothek. Die Bibliothek ist hier eine Rennumgebung, keine Lernprüfung. Ziel ist mindestens eine klar unterscheidbare vollständige Runde je Welt. Die untenstehenden Abschnitte sind Umsetzungsvorgaben aus den Referenzen, keine Behauptung, diese Strecken seien bereits modelliert.

Himmelsinseln: Starttor, breite Einstiegskurve, schwebende Brücke, Inselpassage, Kristallabschnitt und Ziel. Wasserfall-Klippen: Aussicht, Hängebrücke, Serpentinen, Felsentunnel und optionale Höhlenabkürzung. Lichterstadt: Stadtgerade, Neonkurven, Glastunnel, Dachpassage mit sicherer Landung und zentrale Zielgerade. Wissenswald: Baumallee, Büchertunnel, optionale Baumwipfelroute, Sternwarte und beleuchtetes Ziel. Kristalle und Portale können spielerische Kulissen oder Abkürzungen bilden, aber keine Quizbedingungen.

Für jede Strecke eine maschinenlesbare Definition mit stabiler ID, Startpositionen, Wegverlauf, Streckenbreite, Höhen, Kurvenüberhöhung, Oberflächenprofil, Checkpoints, erlaubten Abzweigungen, Rücksetzpunkten und Objektplatzierungen erstellen. Kein einzelnes unsichtbares Oval mit vier ausgetauschten Hintergrundbildern. Abzweigungen erhalten eindeutige Wiedereintrittsstellen; Kreuzungen ohne Höhenunterschied oder klare Wegweisung vermeiden. Den Graph auf Erreichbarkeit und korrekt geschlossene Runde prüfen.

Modulare Geometrie mit passenden Anschlusspunkten, identischen Einheiten und getrennten Kollisionsformen bauen. Als Teamkonvention Meter, Y nach oben und eine einheitliche lokale Vorwärtsachse vereinbaren. Importrotationen nicht pro Objekt improvisieren. Fahrbahn, Leitplanken, Rampen und Landeflächen müssen tatsächlich kollidieren; Wasserfälle, Wolken und weit entfernte Dekoration überwiegend nicht. Vergleichsansichten aus denselben Kamerawinkeln dokumentieren. Wiederholte Bauteile instanzieren, entfernte Kulissen vereinfachen, Sichtbarkeit und Detailstufen gezielt steuern [Q4].

## 8. Fahrgefühl, Physik und Spielregeln

„Wie Mario Kart“ bedeutet hier direkte Steuerung, lesbare Strecke, kontrollierbares Driften, spürbare Beschleunigung und fairen Arcade-Spaß. Es ist keine Zusage identischer Nintendo-Berechnungen. Godot weist selbst darauf hin, dass VehicleBody3D bekannte Grenzen für anspruchsvolle Fahrzeugphysik hat; ein passender eigener Controller auf RigidBody3D oder CharacterBody3D kann notwendig sein [Q5]. Das rechtfertigt keinen ungeprüften Austausch eines bereits funktionierenden Controllers.

Physik und Darstellung trennen. Zunächst mit festem 60-Hz-Physikschritt arbeiten, sofern der vorhandene Controller dazu passt; renderabhängige Beschleunigung vermeiden. Die Unterscheidung zwischen Physiktakt und tatsächlich dargestellten Bildern ist wesentlich [Q6]. Bewegungen nach einem Rücksetzen müssen ohne lange Interpolationsspur starten. Replay- oder Ghost-Daten enthalten Ticks und Versionskennung; plattformübergreifende Bit-Deterministik nicht ungeprüft behaupten.

Als Kalibrieransatz in der lokalen Fahrbahnebene: Vorwärtsgeschwindigkeit und seitlichen Schlupf getrennt bestimmen. Längsbeschleunigung aus Motor, Bremse, Rollwiderstand und geschwindigkeitsabhängiger Dämpfung zusammensetzen. Lenkwirkung bei hohem Tempo begrenzen; die vereinfachte Kinematik `yaw_rate = v_forward / wheelbase * tan(steering_angle)` kann ein Ausgangspunkt sein, muss aber für Drift, Sprünge und Kollisionen angepasst werden. Seitengeschwindigkeit etwa exponentiell dämpfen, statt bei jedem Frame vollständig zu löschen. Alle Parameter mit Einheit, Bereich und Testfall dokumentieren; keine Zahlen als angebliche Originalphysik präsentieren.

Drift besitzt explizite Zustände, Mindestgeschwindigkeit, geregelte Schlupfänderung, Ladephase und einmalige Turboabgabe. Turbo braucht Dauer, Obergrenze und Stapelregel; kein grenzenloses Addieren. Luftsteuerung, Sprungimpuls, Landestabilisierung und Rücksetzzeit separat testen. Zurücksetzen darf keine Runde schenken. Checkpoints müssen in gültiger Reihenfolge passiert werden; reine Nähe zur Ziellinie genügt nicht. Rückwärtsüberfahrt, Abkürzung, Wandkontakt und Pause dürfen Ergebnisse nicht verdoppeln.

Die Spielerfahrt bleibt frei. Hilfen können optional und transparent sein, nicht unbemerkt auf eine Schiene setzen. KI-Fahrer dürfen Streckenpfade nutzen, sollen jedoch nicht unfair durch Wände fahren. Zunächst solides Einzelspiel gegen Bots und gegen eigene Zeiten; Online-Mehrspieler nicht durch eine leere Freunde-Kachel als fertig darstellen. Kamera weich, aber nicht schwammig; Sicht auf die nächste Kurve, Kollisionsvermeidung, reduzierte Kamerabewegung und Touch-Mehrfingereingabe prüfen.

## 9. Ziel 60 FPS auf dem Galaxy Z Fold7

60 FPS entsprechen rechnerisch ungefähr 16,67 Millisekunden pro Bild. Ein guter Mittelwert allein genügt nicht; ungleichmäßige Bildabstände können trotz hoher mittlerer Bildrate ruckeln. Android beschreibt dafür Frame-Pacing und die Probleme verspäteter beziehungsweise überfüllter Präsentationswarteschlangen [Q7]. Nicht blind eine zusätzliche native Bibliothek einbauen, wenn die Engine denselben Ablauf bereits steuert; erst vorhandenen Renderpfad messen.

Abnahmevorschlag, noch nicht gemessen: physisches Fold7, reproduzierbare 60-Hz-Zielkonfiguration, Profil-/Release-Build, beide Displays, Fensterwechsel und mindestens 15 Minuten Rennen nach kurzer Aufwärmphase. Frame-Intervalle, Jank-Anteil, CPU-/GPU-Zeit, Speicher, Temperatur-/Drosselstatus, Renderer, Auflösung und Gerätezustand protokollieren. Zielwert für Gameplay: mindestens 99 Prozent der Bildabstände im einzelnen 60-Hz-Slot innerhalb der dokumentierten Mess-Toleranz, keine wiederkehrenden Hänger und kein dauerhaftes Zurückfallen auf 30 FPS. Rohtraces und Histogramme beilegen, nicht nur eine selbst gezeichnete 60-FPS-Anzeige. Auswahlmenü, Erstladung und Fahrbetrieb getrennt ausweisen.

Qualität in dieser Reihenfolge optimieren: unnötige Arbeit und unsichtbare Objekte entfernen, gemeinsame Materialien/Instanzen, Shader vorwärmen, Größen passend decodieren, Partikel und Transparenz begrenzen, erst danach dynamische 3D-Auflösung und abgestufte Schatten/Reflexionen. Schrift und UI nicht zusammen mit der Szene unscharf skalieren. Die Referenzform und Komposition dürfen nicht durch Optimierung verloren gehen. Eine hohe Bildschirmauflösung beweist keine dauerhaft hohe Spielleistung. Emulatorläufe ersetzen keinen physischen Fold7-Leistungsnachweis.

## 10. Gratisumfang und optionale Käufe

Heinz wünscht überwiegend kostenlosen Umfang und günstige besondere Teile. Konkrete Preise, Artikel und Zahlungsanbieter sind nicht festgelegt. Empfehlung für dieses Kinderprodukt: Kernlernen, erspielbare Spielzugänge, Grundstrecken und wettbewerbsfähige Fahrzeugwerte kostenlos; optionale Sonderlackierungen, rein optische Felgen, Outfits und Effekte als klar bepreiste Extras. Leistungsverbesserungen durch Spielen beziehungsweise verdiente Währung, nicht durch einen Kaufzwang. Diese Ausgestaltung ist ein offener Produktvorschlag, keine bereits bestätigte Preisliste.

Kaufzugang vom normalen Kinderfluss trennen und nur im Erwachsenenbereich anbieten. Keine Kauf-Popups nach Fehlern, keine bezahlten Zufallskisten, keine ablaufenden Druckangebote, keine Werbung als Bedingung für Lernen. Eine Elternfreigabe für Käufe ist nicht die Wiedereinführung der früher störenden PIN bei jeder normalen Navigation. Bestehende Fortschritte oder Grundfunktionen dürfen durch abgelehnte Käufe nicht verloren gehen.

Ein echter Shop braucht verifizierte Berechtigungen, Wiederherstellung und klare Behandlung von pending, Erfolg, Abbruch und Erstattung. Google empfiehlt serverseitige Kaufprüfung und Freischaltung erst im Zustand PURCHASED [Q8]. Ein lokal gesetztes `purchased=true` ist keine Produktionsabrechnung. Zunächst Schnittstellen und Testfälle vorbereiten, echte Zahlungen deaktiviert lassen. Vor Aktivierung sind Artikelkatalog, Kontoeinrichtung, Store-/Familienrichtlinien und anwendbare rechtliche Anforderungen gesondert zu prüfen. Durch diesen Auftrag keine Konten, Geheimnisse, Abrechnung oder echten Preise ändern.

## 11. Konkreter nächster Arbeitsblock: 120 Minuten

Die Zeitfenster strukturieren eine aktive Arbeitssitzung, sie versprechen nicht die Fertigstellung des gesamten Spiels in zwei Stunden. Jede Etappe endet mit einem überprüfbaren Zwischenstand. Innerhalb des freigegebenen Bereichs nach einer bestandenen Etappe selbstständig weiterarbeiten, statt jedes Mal um eine neue Grundsatzanweisung zu bitten. Technische Blocker präzise begrenzen; nicht durch große Ersatzimplementierungen kaschieren.

**Minute 0–15:** Freshness-/CLAIM-Prüfung, #167-Freigabestand, Godot-Pin und Empfang des Assetpakets klären. Vorhandene Tests mit genauer SDK-Version erfassen. Änderungen der Produktregeln in bestehender Aufgabenliste markieren, insbesondere alte Kart-Lernfragen. Falls eine erforderliche Freigabe fehlt, diese Teilintegration blockiert lassen und parallel nur konfliktfreie Dokumentation oder Tests vorbereiten.

**Minute 15–45:** Ein Bearbeiter spezifiziert und testet die zentrale Freischaltregel samt persistierten Rechten; der UI-Bearbeiter integriert passende vorhandene Bilder in genau einen vollständigen Lern-/Spielewelt-Pfad. Keine doppelte AppState-Bearbeitung. Sichtbare Darstellung eines gesperrten und eines tatsächlich freigeschalteten Spiels demonstrieren. Erster dokumentierter Zwischenstand nach etwa 30 Minuten: SHA, bearbeitete Dateien, Testresultate, offen gebliebene Entscheidung.

**Minute 45–75:** Einen vollständigen Lauf Lernen → bestätigter Fortschritt → Memory beziehungsweise Kartenspiel → Ergebnis → Rückkehr → Neustart prüfen. Gleichzeitig nur bei klar getrennter Zuständigkeit Kart-Lernunterbrechungen am vorhandenen Controller entfernen und Regressionen testen. Der Stand nach etwa 60 Minuten enthält reale Screenshots und keine nur beschriebene UI.

**Minute 75–105:** Bestehende Godot-Strecke gegen passende Referenz prüfen und eine begrenzte grafische Verbesserung an einem tatsächlich befahrbaren Abschnitt umsetzen. Andere Welten als konkrete Folgedifferenzen dokumentieren, nicht vier ungetestete Kopien erzeugen. Falls der neue Godot-Stand noch nicht für Einbettung freigegeben ist, nicht den Pin voreilig aktualisieren. Nach etwa 90 Minuten Leistungs-/Navigationsbeobachtungen und verbleibende Abweichungen melden.

**Minute 105–120:** Alle im Block geänderten Pfade erneut prüfen, Nachweisdateien sammeln und eine Übernahmeanfrage an die anderen tatsächlichen Bearbeiter stellen. Wenn sämtliche Voraussetzungen erfüllt sind, gemeinsamen APK-Kandidaten bauen und dessen Herkunft dokumentieren. Sonst klar benannte Blockerliste mit kleinstem nächsten Schritt. Zwei zusätzliche Spiele, komplette 3D-Charakterriggs, vier fertig ausmodellierte Welten und Produktionsabrechnung sind eigenständige Folgepakete, keine in dieser Sitzung vorgetäuschten Erfolge.

Die Zwischenstände kommen von der jeweils aktiven Entwicklungssitzung. ChatGPT kann sich hier nicht automatisch alle 30 Minuten einloggen; geplante ChatGPT-Aufgaben unterstützen höchstens einen Lauf pro Stunde. Keine zwei versetzten Tasks und keine endlose Erwähnungsschleife. GitHub-CI soll bei neuen Commits prüfen, sobald der vorhandene Workflow-Fix korrekt übernommen ist.

## 12. Prüfkatalog und APK-Übergabe

Jeder Abschlusskandidat erhält denselben Flutter-SHA, Godot-SHA, PCK-Hash und Assetmanifest. Luna, Claude und ChatGPT erstellen ihre eigenen abgegrenzten Berichte. Nicht ausgeführte Gerätetests, fehlende Agentenantworten, übersprungene Tests und verbleibende Bildabweichungen werden ausdrücklich ausgewiesen. Ein Bericht aus einem älteren SHA gilt nicht automatisch für den neuen Kandidaten.

Pflichtfälle: Klassen-/Fachnavigation, korrekte und falsche Antworten, Hilfen, TTS an/aus, echte Belohnung nur einmal, Profile getrennt, Speichern bei Fehler, Offline-Neustart, Freischaltschwellen, Memory-Abschluss, eigener Karten-Spielabschluss, Kart-Start/Rennen/Pause/Fortsetzen/Ergebnis/Rückkehr, keine Lernfrage im Kart, Mehrfingereingabe, Zurück-Geste, Außendisplay und aufgeklappt, Schriftvergrößerung, reduzierte Bewegung, Hintergrundwechsel und Prozessneustart. Alle fertigen Strecken komplett fahren, nicht nur das Startmenü öffnen. Kaufzustände ausschließlich im Testmodus bis zur gesonderten Freigabe.

Die visuelle Abnahme zeigt je Bildschirm die passende Referenz und einen tatsächlichen Laufzeitscreenshot nebeneinander, mit Größenangabe und Abweichungsliste. Grafisch reichhaltige Zielbilder sind keine Simulatoraufnahmen. Kanonische Szenen und Originalfiguren prüfen, nicht nur vorhandene Dateinamen. Pflicht-Abnahmefehler bleiben Fehler; Tests nicht so umschreiben, dass verschwundene Funktionen unbemerkt als erfolgreich gelten.

Vor Auslieferung APK-Bytes wirklich herunterladen. ZIP/AndroidManifest/classes.dex/native Bibliotheken/PCK, Paket-ID, Version, Buildnummer, Signaturzertifikat, Signaturprüfung, Quellherkunft und SHA-256 prüfen. `lumo_game_source.json` und BUILD-PROVENANCE müssen die tatsächlich enthaltene Godot-Revision belegen. Benötigte neue Flutter-Assets und Godot-Modelle/PCK-Inhalte gegen Manifest kontrollieren. Originalprotokolle und sichtbare App-Versionsinformation beilegen. Arm64-Gerät und gegebenenfalls separate Emulator-ABI sinnvoll behandeln, statt Dateigröße künstlich aufzublähen.

Die alte APK 0.10.5/280 mit SHA-256 `3c01ba849139583be0b41ef2195e67f68373ebb18d720ce2d1ad1bd638523f48` ist keine fertige Umsetzung dieses Auftrags. Eine neue Datei mit geändertem Namen genügt nicht. Mehr Megabyte sind kein Qualitätsnachweis: neue Modelle, Texturen und Strecken können Größe hinzufügen, sinnvolle Komprimierung kann sie senken. Einen sachlichen Größenvergleich nach Code, Engines, Grafiken, Audio und PCK liefern; niemals Füllmaterial hinzufügen. Kein Fertig-Merge/Release bei fehlender Gesamtfreigabe.

## Quellen und Herkunft

Repository-Befunde sind Momentaufnahmen der oben angegebenen SHAs. Nutzerentscheidungen stehen in Abschnitt 1; Zahlenziele und Entwicklungspriorisierung darüber hinaus sind technische Empfehlungen. Öffentliche Quellen wurden am 04.10.2026 geprüft; bei Umsetzung zur gepinnten SDK-Version passende Dokumentation verwenden und keine ungetestete Versionsaktualisierung erzwingen.

- [R1] https://github.com/Ullmann27/lumo-lernen/pull/156
- [R2] https://github.com/Ullmann27/lumo-lernen/pull/167#issuecomment-5979135085
- [R3] https://github.com/Ullmann27/lumo-lernen/blob/be1e48ae3110351de81dd6ea20e15bbb9508c3ae/config/godot-source.json
- [R4] https://github.com/Ullmann27/lumo-lernen/blob/be1e48ae3110351de81dd6ea20e15bbb9508c3ae/scripts/prepare_embedded_games.py
- [R5] https://github.com/Ullmann27/lumo-lernen/blob/be1e48ae3110351de81dd6ea20e15bbb9508c3ae/scripts/build_unified_apk.sh
- [R6] https://github.com/Ullmann27/lumo-godot/pull/4
- [Q1] https://docs.flutter.dev/ui/adaptive-responsive/general
- [Q2] https://m3.material.io/ und https://design.google/library/design-notes-material-3-expressive-liam-spradlin
- [Q3] https://www.apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/
- [Q4] https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
- [Q5] https://docs.godotengine.org/en/stable/classes/class_vehiclebody3d.html
- [Q6] https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html
- [Q7] https://developer.android.com/games/sdk/frame-pacing
- [Q8] https://developer.android.com/google/play/billing/security
