# Direkte Übergabe an Claude Opus 5.5: Lumo Lernen und Lumo Kart

Stand der Übergabe: 8. Oktober 2026, ca. 16:40 Uhr Europe/Vienna. Statusangaben zu laufenden Actions sind Momentaufnahmen. Vor jedem weiteren Eingriff die aktuellen Branch-Heads, offenen PRs, Claims und Actions neu lesen.

Heinz übergibt dir wieder die Weiterentwicklung der vorhandenen vollständigen Flutter-Lernapp und des eingebetteten Godot-Kartspiels. Setze auf dem tatsächlichen aktuellen Projekt auf. Der Auftrag bleibt: höchste erreichbare Qualität in der echten Android-Runtime, dieselbe Lumo-Figur wie auf seinen Bildern, detailreiche Strecken, präzise Touchsteuerung und nachvollziehbare Screenshots. Diese Datei startet keine Claude-Sitzung automatisch.

## 1. Zuerst die parallelen Arbeitsstände zusammenführen

**Nicht mit einer alten OPUS_NEXT-Anweisung oder einem alten HTML-Prototyp neu beginnen.** Die alte Übergabe vom 7. Oktober wird archiviert. App, Godot-Quellstand, Godot-Pin und tatsächlich gebautes APK sind getrennt zu prüfen.

| Bereich | Aktiver Branch und PR | Zuletzt gelesener Produktcode-Commit |
| --- | --- | --- |
| Meine App-/Referenzarbeit einschließlich neuer Kamerakorrektur | `Ullmann27/lumo-lernen`, `codex/lumo-reference-app-2026-10-08`, [PR 214](https://github.com/Ullmann27/lumo-lernen/pull/214) | `84ce0e3cee37e3c525c28a6e83e9be75043632f9` |
| Mein Godot-/Referenzstand einschließlich vollständiger Heckansicht | `Ullmann27/lumo-godot`, `codex/lumo-reference-design-2026-10-08`, [PR 27](https://github.com/Ullmann27/lumo-godot/pull/27) | `30dc99b405c423cd5f01d42113b60172ad9565d3` |
| Zusätzliche aktive App-/Runtimearbeit | `codex/lumo-runtime-apk-2026-10-08`, [PR 215](https://github.com/Ullmann27/lumo-lernen/pull/215) | `9f56cb8df00925988c84fccab5fbb8eaf2821d3c` |
| Zusätzliche aktive Godot-/Kontakt-/Speicherarbeit | `codex/lumo-race-continuity-2026-10-08`, [PR 28](https://github.com/Ullmann27/lumo-godot/pull/28) | `649e7dc7e90ad3affe94721012d39140522e717e` |

Die zusätzliche Runtimearbeit ist nicht von dieser Referenzsitzung erstellt worden. Ich habe ihre PRs, Branch-Heads, Differenzen und Übergaben zur Koordination gelesen; ihre eigenen Prüfergebnisse sind von meinen unabhängig ausgeführten Prüfungen zu unterscheiden.

Die Branches sind noch nicht vollständig integriert. App 215 ist gegenüber `84ce0e3` acht Commits voraus und einen zurück; gemeinsame Basis ist `f5763658b477258deda2f62465c84daf162a818e`. Godot 28 ist gegenüber `30dc99b` zwei Commits voraus und einen zurück; gemeinsame Basis ist `d2ebb85d0dcfeec690c18b7d35135a66f472b170`. Die fehlenden jeweils einzelnen Commits enthalten meine letzte Kamerakorrektur und deren App-Pin-/Aufnahmeänderung.

Wichtig: Der frisch gelesene tatsächliche Pin von App 215 ist **`649e7dc7e90ad3affe94721012d39140522e717e`**. Der PR-Beschreibungstext nennt teilweise noch `4d4bd2b`; die Datei `config/godot-source.json` ist für den Bau maßgeblich. Mein App 214 pinnt **`30dc99b405c423cd5f01d42113b60172ad9565d3`**. Keinen Pin beim Konfliktlösen blind auf den älteren Wert setzen.

Starte einen eigenen Integrationsbranch von den frisch gelesenen Runtime-Heads, übernimm meine Kamerakorrektur und die Übergabe, erhalte sämtliche Continuity-/Kontakt-/Launcher-/Foto-Lektionsänderungen und baue den kombinierten Stand erneut. Dateien mit direkter Überschneidung: Godot `scripts/games/kart_island.gd`; App `config/godot-source.json` und `pubspec.yaml`. Meine Änderung am bestehenden Android-Prüfer muss neben dem zusätzlichen vollständigen Rennprüfer erhalten bleiben.

Beide Kandidaten verwenden bereits versionCode 1901, aber unterschiedliche versionName-Werte. Für eine neue zusammengeführte APK einen höheren Build verwenden, mindestens **1902**, und denselben Paketnamen und Signierschlüssel beibehalten. Eine erfolgreiche Installation einer anderen APK mit demselben Buildcode ist kein Nachweis dieses kombinierten Stands.

Die abschließenden Commits dieser Übergabe ändern ausschließlich Dokumentation. Deshalb kann der Branch-Head nach den oben genannten Produktcode-Commits neuer sein. Das ist kein zusätzlicher APK-Bau. Alle PRs bleiben Entwürfe; keine Main-Übernahme oder Release-Veröffentlichung wurde ausgeführt.

Lies außerdem:

- App `docs/OPUS_ENTWICKLUNGSAUFTRAG.md` vollständig; die historischen SHA-/Versionsangaben darin werden durch diese frische Bestandsaufnahme ergänzt.
- App `docs/HANDOFF_REFERENCE_APP_2026-10-08.md` und `docs/HANDOFF_2026-10-08_STAGE2_ANDROID.md`.
- Runtime-App `docs/handoffs/LUMO_RUNTIME_APK_2026-10-08.md` auf dem Branch von PR 215.
- Godot `docs/HANDOFF_REFERENCE_DESIGN_2026-10-08.md`, `docs/HANDOFF_2026-10-08_CODEX_KART_FLEET.md` und `docs/RACE_CONTINUITY_2026-10-08.md` auf PR 28.
- `CLAUDE.md`, `CODEX_START.md`, geltende AGENTS-Dateien sowie neue Claims. Fremde Arbeitsstände nicht überschreiben; keine Force-Pushes.

## 2. Was ich an der App umgesetzt habe

Die aktuelle Claude-Appbasis `1f280b90ae0cab2c799da2426b8de185e595f120` wurde vollständig erhalten, einschließlich überarbeiteter Startseite, Belohnungen, Denkprofil-/IQ-Grundlagen, Lifetime-Sternen und Profil-Reset-Bereinigung. Der frühere Main-Checkout ist nicht meine aktive Arbeitsbasis.

Der Spieleinstieg zeigt jetzt die freigestellte Referenz-Rückansicht von Lumo im Kart und einen tatsächlich gerenderten Sonnenhafen-Hintergrund. Das Hintergrundbild enthält keine zweite eingebrannte Spieloberfläche. Die gemeinsam verwendete Lernbegleitung zeigt den vorhandenen Lumo-Fuchs statt eines Plattform-Fuchs-Emojis. Bestehende Einstellungen für reduzierte Animationen stoppen dessen dekorative Dauerschleife.

Geänderte Produktdateien:

- `lib/features/games/widgets/lumo_game_spotlights.dart`
- `lib/features/shared/widgets/lumo_companion_avatar.dart`
- `lib/widgets/design/lumo_design_system.dart`
- `assets/lumo_design/fox/fox_kart_rear.png`
- `assets/lumo_design/gameplay/kart_sonnenhafen_preview.webp`
- `pubspec.yaml` und `config/godot-source.json`

Die vollständige App bleibt vorhanden: Start, Lernen, Tests, Spiele, Profil und Belohnungen sowie die vorhandenen Lern-/Fortschrittsfunktionen. Echte Seitenaufnahmen wurden für Telefon und Fold sowie Lernansichten, Elternansichten und vergrößerten Text erzeugt. Diese Arbeit behauptet keine vollständige Neuerstellung der KI, keine neue menschliche Stimme und keine vollständige App-Animationsabnahme.

Die gemeinsame Buildroute enthält Flutter und Godot in **einer signierten APK**. Build 1900 wurde tatsächlich gebaut und geprüft. Mein letzter Referenzkandidat ist `0.12.0+1901`; dessen neue Buildprüfung läuft bei der Übergabe noch.

## 3. Was ich am echten Godot-Spiel umgesetzt habe

### Fahrzeuge und Modellierungsgrundlagen

Die frühere Flottenarbeit wurde erhalten: neun auswählbare echte Kartformen, eigene Karosserieprofile und Lackierungen, bewegliche Räder/Lenkrad/Gelenke, LOD, Drift-/Boost-Reaktionen sowie Vorder-, Rück-, Seiten- und Draufsicht in der Garage. Die vorhandenen Fahrzeug-IDs sind Comet, Glider, Turbo, Gecko Velo, Boru Rally, Nala Comet, Noa Tide, Iva Aurora und Zuri Volt. Rivalen verwenden unterschiedliche Fahrzeuge.

Es gibt Exporte für neun statische Fahrzeug-GLBs und sechs getrennte Streckenmodule. Die GLBs sind editierbare Geometrie-Schnappschüsse, **keine fertigen geriggten Produktionsmodelle und keine gebackenen Animationspakete**. Generierte Figuren Piko/Boru/Nala/Noa/Iva/Zuri sind zusätzliche Konzepte; damit sind keine sechs neuen fertigen spielbaren Fahrer behauptet. Frühere Konzeptnamen Mira/Tavi ersetzen die vorhandenen Fahrer nicht.

Die umfangreicheren früheren Entwicklerpakete enthalten 104 Konzept-PNGs, 61 echte Godot-Aufnahmen, 15 statische GLBs und einen kurzen Modellfilm mit gesonderter Provenienz. Deren ältere Quellstände sind in ihren Manifesten ausgewiesen. Diese historischen Aufnahmen nicht als Bilder des jetzigen APK-Pins ausgeben.

### Lumo, Sitzhaltung und Comet

Lumo wurde am bestehenden prozeduralen 3D-Modell überarbeitet: runder orangefarbener Kopf, große braune Augen, weiße Schnauze und flauschige Wangen, große Ohren, blaue Fliegerbrille mit Band, navyfarbener Anzug mit geschlossenem cyanfarbenem L sowie buschiger Schweif mit weißer Spitze. Das kurze Fell besteht aus eigener opaker Geometrie. Vorhandene Kopf-, Ohr-, Augen-, Mund-, Lenk- und Schweifgelenke bleiben erhalten.

Der Sitz wurde abgesenkt, sodass der Rücken mit dem L sichtbar bleibt. Der Schweif tritt außerhalb der rechten Sitzkante aus. Die Haube endet vor einem tatsächlichen Fußraum. Beine und Schuhe sind plausibel angeordnet; beide Sohlen liegen an eigenen Pedalen. Gemessene Boot-/Hauben-/Pedal-/Lenkradkontakte und vier tatsächliche Modellansichten ergänzen den visuellen Vergleich.

Der Starter-Comet erhält dunkelblau/anthrazitfarbene Flächen, cyanfarbene Lichtleisten und dezente goldene Kanten. Ein originales achtflächiges violettes Mystery-Prisma mit goldenen Kanten ersetzt die einfache Item-Box; Geometrie und Materialien werden gemeinsam genutzt.

**Offen:** Die Figur und das Kart sind noch sichtbar einfacher als Heinz' verbindliche gerenderte Referenz. Fell, Gesichtsskulptur, Materialien und einige Proportionen sind nicht exakt abgenommen. Einzelne geprüfte Kontakte sind kein Beweis sämtlicher verdeckter Flächen oder jeder Animation. Die neuere Arbeit auf Godot PR 28 korrigiert zusätzlich Hand-/Lenkrad- und Ärmel-/Handkontakt in Bewegung; sie muss unbedingt integriert werden.

Wichtige Dateien: `scripts/games/kart_vehicle.gd`, `kart_fur_geometry.gd`, `kart_fleet.gd`, `kart_mystery_prism.gd`.

### Touch und Analogstick

GAS, BREMSE, SPEED, ITEM und das zusätzliche DRIFT verwenden zusammenhängende navy/cyanfarbene Glasgrafiken mit getrennten normalen, gedrückten und deaktivierten Texturen. Die vier ursprünglich verlangten Namen bleiben exakt GAS, BREMSE, SPEED und ITEM. Nunito Black zeichnet Beschriftungen scharf zur Laufzeit. Die Item-Beschriftung darf im Spiel den tatsächlich erhaltenen Gegenstand anzeigen.

Die bewegliche Analogknopf-Textur bleibt von der Basis getrennt. Basis 1024×1024, Mittelpunkt (512,512), physischer Durchmesser 820; Knopf 512×512, Mittelpunkt (256,256), physischer Durchmesser 328. Verhältnis 0,40; maximaler dargestellter Weg 128 Basispixel. Die tatsächliche Eingabe-Totzone bleibt 0,08. Finger-Versatz wird mit 0,31×Basisbreite normiert; Achsenglättung verwendet min(1,delta×18). Die 0,12 im Originalpaket ist eine Empfehlung für neue Integrationen, nicht die aktuelle Laufzeit-Totzone.

Fold- und kompakte Ansichten haben größere beziehungsweise passend begrenzte Touchziele. Geprüft werden getrennte Fingerbesitzer, gleichzeitiges Gas/Lenken/Speed, Freigabe außerhalb der Buttons, Pause und leere/tatsächlich verbrauchte Items. Innere Flächen lassen den Fahrerzentrumspunkt frei. Mindest-Touchziele und Beschriftungsbreite bleiben geprüft.

Dateien: `scripts/games/kart_touch_action.gd`, `kart_joystick.gd`, `kart_island.gd`, `assets/kart/controls/reference/`.

### Kamera: letzte Änderung vor der Übergabe

Die Abschluss-Sichtprüfung der tatsächlich installierten APK 1900 zeigte einen echten Fehler: Im Stillstand wurde das Heck unten angeschnitten, auf dem breiten Cover besonders stark. Die vorherige Prüfung kontrollierte nur die erkennbare Figur und einen mittleren Radpunkt.

Die neue Kamera schaut etwas weiter nach unten: Abstand 4,35–4,8, Höhe 2,6, Blick-Vorlauf 4,0, Zielhöhe 0,75. Basis-/Fahrt-/Boost-FOV bleiben 55/60/68 Grad. Breite Displays behalten mindestens das vertikale Basis-FOV und gewinnen seitliche Straßenansicht, statt das Kart durch einen kleineren vertikalen Winkel abzuschneiden.

`kart_video_visual_regression.gd` projiziert jetzt die tatsächlichen Mesh-Bounds einschließlich Heck/Rädern/Ohren/Schweif in drei Displayformen und drei Bewegungszuständen. Alle neun Fälle benötigen drei Prozent Bildrand; echte Stillstandaufnahmen und `full-kart-framing.json` werden gespeichert. Das alte Pause-Resize-Verhalten wurde an die beabsichtigte vollständige Fahrzeugansicht angepasst. Mein bestehender Android-Prüfer wartet jetzt auf die sichtbare RUNDE-Anzeige, bevor er die Telefon-Rennansicht erfasst; vorher konnte er noch den Streckenüberflug aufnehmen.

Lokal bestanden nach dem Fix: vollständige visuelle Kamera-/Materialprüfung, Pause-/Displaymatrix und Fold-Mehrfingerprüfung. Diese neuen lokalen Aufnahmen sind Engine-Bilder, **noch keine Android-Aufnahmen des Builds 1901**.

### Strecken und bestehende Abläufe

Sonnenhafen erhielt weiter ausgearbeitete Ufer-, Hafen-, Boots-/Steg- und Werkstattdetails. Zwölf vorhandene Rennwelten bekommen zusätzliche Boxen-/Serviceflächen, Streckenposten, Zuschauer, Flaggen, Beleuchtung und bepflanzte Gruppen. Die Platzierung berücksichtigt Höhe, Nachbarfahrbahnen, Sprunglücken und Brücken. High/Low-Dichte wird in räumlichen MultiMesh-Batches organisiert; alte Gruppen werden beim Neubau entfernt.

Alle zwölf Welten wurden lokal in beiden Detailprofilen geprüft und an jeweils zwei Positionen tatsächlich gerendert: sonnenhafen, zauberwald, bergwelt, holo_city, crystal_canyon, jungle_temple, candy_cloud, volcano_night, winter_sprint, galaxy_ringway, desert_drift und learning_lab. Die zusätzliche Dekoration umfasst je Welt/Profil 131–630 Details. Das sind räumliche Bauteile, keine entsprechende Zahl individuell animierter NPCs.

Dateien: `scripts/games/kart_harbor_dressing.gd`, `kart_track_detail.gd`, `kart_world.gd`, `kart_garage_menu.gd`.

Claude-Fix `640855fc91f9b603609883c0ed84f550f6dea49e` für Vorschau/Physik wurde übernommen. Intro, Einfahrt/Drift, überspringbarer Streckenflug, einrollende Startaufstellung, Startampel, Zielfahrt, bestehende Musik-/Lautstärkeneinstellungen und HostBridge bleiben erhalten. Im Rennen gibt es keine Lernfragen oder Antwort-Turbos. Ich habe hier keine neue Musikproduktion und keinen neuen Sprachdienst als fertig gemeldet.

## 4. Tatsächlich geprüfte APK 1900 – abgeschlossen

Der [Actions-Lauf 37784807913](https://github.com/Ullmann27/lumo-lernen/actions/runs/37784807913) ist vollständig erfolgreich: ein Buildjob und sechs Android-Jobs. Seine Belege gelten ausschließlich für folgende Quellstände:

| Feld | Geprüfter Wert |
| --- | --- |
| App-Commit | `f5763658b477258deda2f62465c84daf162a818e` |
| Godot-Pin | `d2ebb85d0dcfeec690c18b7d35135a66f472b170` |
| Version | `0.12.0+1900` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| APK-Bytes | 201675962 |
| APK SHA-256 | `c884af1a96e63ba955fab1de7f5ce2a80c5163ab04a583fe2e3cc6afac35c2e7` |
| Signierzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Engine | Godot 4.6.3 |
| PCK SHA-256 | `13de938fdbff0d75e56fcb8a1b79659b657cc4020af22e3153b7026ef60889e5` |
| Architektur / API | arm64-v8a und x86_64; minSDK 24, targetSDK 36; native 16-KiB-Ausrichtung geprüft |

Alle heruntergeladenen Artefakt-ZIPs wurden per SHA-256 und CRC kontrolliert; APK-Dateihash, eingebetteter nativer Commit und PCK-Hash wurden zusätzlich lokal abgeglichen. Signaturprüfung erfolgte im CI-Verifier; ein eigener lokaler apksigner-Lauf wird nicht behauptet.

Bestanden:

- 739 Flutter-Tests; vier übersprungen. Quellanalyse ohne Fehler, vorhandene Hinweise/Warnungen bleiben sichtbar.
- Neun Python-Vorbereitungstests, 22 Backend-Tests, Lerninhaltskontrolle über 40.960 generierte Aufgaben; Android-Prüfharness im CI mit sichtbaren Skips.
- Exakter Godot-Import, echte Welt-/Modell-/Menüaufnahmen, Physik-, Fahrzeug-, Hafen-, Kamera-, LOD-, Kontakt- und Touchprüfungen.
- Drei echte Touch-/Drag-Testfahrten mit 480 Physikschritten plus Bremsphase: Sonnenhafen 152,45 m, Candy Cloud 155,33 m, Vulkan 153,63 m. Keine Teleport-Abkürzung der Fahrt; das initiale Test-Setup ist gesondert dokumentiert. Acht Sekunden Simulationsfahrt beweisen kein vollständiges Rennen und keine 60 FPS.
- Kart unter API 35 und 36: Update ab 1602 mit Profilerhalt, Start/Einrichtung, Telefon 1920×1080, Fold innen 2176×1812, Cover, 640×320, Pause/Rückkehr und Neustart.
- Bauwelt, Puzzle, Rhythmus und Schatzsuche unter API 35: echte Einstiege und jeweilige Speicher-/Rückkehr-/Belohnungsgrenzen. Bauziel/Belohnung wurde abgeschlossen; Puzzle/Rhythmus/Schatzsuche sind damit nicht vollständig durchgespielt.

Android-Prüfungen verwenden Emulatoren. Die API-36-Größenwechsel drehen das virtuelle Gerät ausdrücklich; ein Resize allein ist kein Scharnier-/Dreh-Nachweis. Kein physischer Samsung-/Fold- oder dauerhafter 60-FPS-Nachweis wurde erbracht.

Artefakte im Lauf 37784807913:

| Inhalt | Artefakt-ID |
| --- | --- |
| APK mit Provenienz/Verifier | `11556070364` |
| Echte Flutter-Seitenbilder | `11553637329` |
| Native Welt-/Menübilder | `11553602994` |
| Native Regressionen, Modell-/Fahrbilder, statische GLBs | `11554259275` |
| Kart API 35 / API 36 | `11556341594` / `11556112837` |
| Bauwelt / Schatzsuche | `11556385750` / `11555916740` |
| Rhythmus / Puzzle | `11555846734` / `11555652668` |

Der spätere Kamera-Fix ist in dieser APK 1900 nicht enthalten. Die Ausgabe darf daher nicht als abschließend referenzgleiche oder vollständig korrigierte neue APK bezeichnet werden.

## 5. Neue Prüfungen und noch offene Lieferung

Mein neuer [Build-/Android-Lauf 37793427981](https://github.com/Ullmann27/lumo-lernen/actions/runs/37793427981) baut App `84ce0e3` mit Godot `30dc99b` als `0.12.0+1901`. Bei Vorbereitung dieser Übergabe läuft er noch. Den Erfolg der 1900-Matrix nicht auf diese APK übertragen. Originalergebnisse, tatsächliche neue APK-Provenienz und alle sechs Android-Jobs nach Abschluss lesen.

Der [App-Reviewlauf 37793436316](https://github.com/Ullmann27/lumo-lernen/actions/runs/37793436316) war ebenfalls aktiv. Neue reine Dokumentationscommits können einen weiteren PR-Reviewlauf erzeugen; das ist kein neuer APK-Prüflauf.

Godot-Prüfungen für `30dc99b`: [Stage 2](https://github.com/Ullmann27/lumo-godot/actions/runs/37793377138), [Fahrzeuggeometrie](https://github.com/Ullmann27/lumo-godot/actions/runs/37793377169), [Kameragrade](https://github.com/Ullmann27/lumo-godot/actions/runs/37793377150), [Rivalen](https://github.com/Ullmann27/lumo-godot/actions/runs/37793377316). Geometrie und Rivalen waren bereits erfolgreich; die übrigen Status neu abfragen. Die lokalen neuen Kamera-/Pause-/Fold-Läufe sind erfolgreich abgeschlossen.

Für die zusätzliche Runtimearbeit auf PR 215/28 ihre gesonderten Actions lesen. Deren Handoff berichtet zuletzt 750 Flutter-PASS/4 SKIP und neue erfolgreiche Launcher-/Foto-Lektionstests, aber der damalige kombinierte Lauf brach korrekt vor dem APK-Bau wegen Texture-Fehlern im Prüfer-Cleanup ab. Der Prüfer wurde korrigiert; keine Android-/APK-Freigabe daraus erfinden. Die Runtime-Reparaturen haben einen eigenen vollständigen Zwei-Runden-Prüfpfad mit Ergebnis/ACK/Replay, den meine bisherige Android-Matrix noch nicht abdeckte.

Das neue vollständige Android-Entwickler-ZIP wurde **noch nicht zusammengestellt oder ausgeliefert**. Ein Assemblerskript ist vorbereitet. Die Benutzeränderung zur Claude-Übergabe kam vor dessen Ausführung. Es muss erst nach abgeschlossenen, exakt zugeordneten Prüfungen ausgeführt und für den integrierten Stand angepasst werden.

## 6. Bilder, Assets und reproduzierbare Werkzeuge

Das beigefügte Übergabe-ZIP enthält die Originalreferenzen, das vollständige separate PNG-Asset-Paket, die aktuellen Laufzeit-Bedienelemente, ausgewählte echte App-/Android-/Godot-Bilder, statische Fahrzeug-GLBs, Originalprüfergebnisse und vorbereitete Lieferwerkzeuge. Jede Bildgruppe besitzt Herkunftshinweise; alte APK-Bilder und neue Engine-Kamerabilder bleiben getrennt.

Das aktuelle ursprüngliche Assetverzeichnis besitzt 46 Dateien; dazu kommt seine ZIP-Datei. Nutzbare transparente Einzelmotive: eine Kart-Rückansicht, 24 Buttondateien und drei Analogteile, also 28. Die Buttons enthalten je Normal/Gedrückt/Deaktiviert eine exakt beschriftete und eine textfreie Variante. Der separate Runtimeordner hat 18 Alpha-PNGs: fünf Aktionen × drei Zustände plus drei Analogteile.

Transparenz wurde tatsächlich geprüft: Alpha ist vorhanden, vollständig transparente Außenkanten und genügend Platz für den Glow. Helle/dunkle Vorschauen und Manifest JSON/CSV sind vorhanden. Ein gezeichnetes Schachbrett gilt nicht als Transparenz. Die 2048×2048-Rückansicht wurde aus einer nativen 1254px-Quelle hochskaliert; sie enthält damit keine echten nativen 2048px-Details. Keine Behauptung eines fertigen 3D-Modells aus diesem PNG.

Die zusätzlichen Konzeptbilder aus dem früheren großen Entwicklerpaket sind als Konzepte gekennzeichnet, nicht als aktuelle Runtime-Screenshots. Mehrwinkel-KI-Bilder sind keine automatisch kalibrierten CAD-Ansichten.

Lokaler Arbeitsraum dieser Sitzung: `/workspace/scratch/b7039705c23f/`.

- Aktive Git-Checkouts: `lumo-android-stage2/` und `lumo-godot/`. Tracked-Dateien waren vor der Übergabedokumentation sauber. Ungetrackte `.gd.uid` sind Engine-Nebenprodukte; sie wurden nicht pauschal gestaged.
- Vollständig heruntergeladene 1900-Belege: `ci-proof/final-delivery/`, darin `apk/`, `app/`, `native/`, `native-verification/` und sechs `android/`-Unterordner.
- Originalgrafiken: `upload/01-50138.png` bis `upload/10-49776.png`; neues Assetpaket `Lumo_Kart_Asset_Paket/` und `Lumo_Kart_Asset_Paket.zip`.
- Neues Kameramaterial: `lumo-godot/exports/video-reference-grade/stopped-kart-*.png`, `full-kart-framing.json`; Logs unter `exports/reference-design/camera-*.log`.
- Alle-Welten-Prüfer: `lumo-godot/exports/reference-design/kart_all_world_review.gd`, Ausgabe `all-worlds/`, 24 PNGs und Bericht. Der bisherige Bericht ist für `d2ebb85`; vor Nutzung als neuer-Pin-Beleg erneut ausführen. Das lokale Skript wurde bereits auf `30dc99b` vorbereitet, aber die alte Ausgabe dadurch nicht rückwirkend neu geprüft.
- Vorbereiteter Lieferassembler: `asset_work/assemble_android_delivery.py`. Hartkodierte ROOT/OUT-Pfade und erwartete Version/Native-SHA für ein anderes Workspace beziehungsweise den integrierten 1902-Stand anpassen. Er verlangt sieben erfolgreiche Jobs, sechs Android-PASS-Ergebnisse, exakte APK-/PCK-/Quellhashes, Alpha-/Randprüfungen, Manifest/Prüfsummen und ZIP-CRC. Er wurde noch nicht ausgeführt.
- Vorbereiteter 3D-Rekonstruktionsauftrag: `asset_work/Lumo_3D_Rekonstruktionsauftrag.json`; Fähigkeitsgrenze `asset_work/3d_capability_limit.json`.
- Die zusätzlich von Heinz hochgeladenen 19 alten HTML/ZIP/Markdown-Unterlagen liegen unter `project_sources/`. Der Implementierungsbericht beschreibt einen früheren MVP mit damals nicht ausgeführten Flutter-Tests. Das ist kein Ersatz für die heutige App. Diese Referenzsitzung hat nicht alle 19 Dateien erneut vollständig auditiert; die zusätzliche Runtimeübergabe berichtet ihre eigene Prüfung.

Die verfügbaren Bildwerkzeuge haben PNGs erzeugt. Ein Image-to-3D-Katalog zeigte Meshy/Tripo/Hunyuan, aber die benötigte Aufruffunktion `generate_3d` war in diesem Toolset nicht verfügbar. Keine 3D-Generierung, Zahlung oder Credits-Bestellung wurde ausgelöst. Das ist keine Aussage, dass andere Umgebungen kein Modellierungswerkzeug besitzen. Nutze deine tatsächlichen verfügbaren Werkzeuge und prüfe ihre Möglichkeiten vor einer Produktzusage.

## 7. Dein konkreter Fortsetzungsauftrag

1. **Koordination und Integration:** aktuelle Heads von PR 214/215 und 27/28 neu lesen, Claims beachten und beide Entwicklungsstränge erhalten. Kamerafix, Rennspeicherung, dynamischer Hand-/Ärmelkontakt, Launcher-Guard und fachrichtige Foto-Lektionen zusammenführen. Den neuen exportierten Godot-Commit exakt pinnen. Keine parallel laufende fremde Arbeit überschreiben.
2. **Neue APK belastbar abschließen:** neuen höheren Build, stabile Signatur und Paketkennung. Volle Flutter-/Nativeprüfung, API35/36-Update/Profilerhalt und den neuen vollständigen Zwei-Runden-/Ergebnis-/ACK-Test aus PR 215 durchführen. Fehler zuerst beheben, keine Assertions oder Error-Gates zur Erzeugung grüner Läufe lockern. Artefakte herunterladen, Hash und eingebetteten PCK unabhängig kontrollieren.
3. **Lumo und Kart wirklich referenzgleich gestalten:** verbindliche Bilder nebeneinander mit aktuellen Front-/Seiten-/Rück-/Dreiviertelansichten unter identischen Kamerabedingungen vergleichen. Kopf, Augen, Wangen, Schnauze, Ohren, Brille, Stoff, Fell und Schwanz korrigieren. Den niedrigen breiten navy/anthrazitfarbenen Racer mit cyanfarbenen Felgen/Leisten und zurückhaltenden Goldkanten modellieren. Keine fremden Markenfiguren/Fahrzeugdesigns kopieren. Bei einem GLB-Import vollständige UVs/PBR, Gelenke, Handkontakt, Schweifabstand, Rad-/Lenkbewegung und LOD prüfen. Kein Bild oder Billboard ersetzt den Fahrer im Rennen.
4. **Rennablauf in Bewegung abnehmen:** Intro → Garage/Auswahl → Vorschau → Einrollen → Startampel → zwei Runden → Ziel → Ergebnis → Belohnung → nächstes Rennen. Lenken, Gas, Bremse/Rückwärts, Driftstufen, Speed, Item, Gegnerkontakt, Sprung/Landung, Reset, Pause, Profilwechsel, Grafikwechsel und Offline-Neustart prüfen. Verbleibende Gegnerflug-/Flugpersistenz-/Tunnel-/Landekamera-Lücken aus PR 28 beachten. Gesperrte Loopings erst nach vollständiger Kontakt-, Steuerungs-, Gegner- und Respawn-Abnahme aktivieren.
5. **Streckenqualität weiter erhöhen:** zuerst Sonnenhafen als komplette Referenzstrecke, anschließend alle zwölf Welten mit eigener lesbarer Identität. Art Direction, Fahrbahn-/Umgebungsmaterialien, Terrain, Vorder-/Mittel-/Hintergrund, Animation, Licht und Kollision als zusammenhängende Szene verbessern. Zusätzliche zufällige Props allein sind keine Grafikabnahme. Sichtbarkeit und mobile Draw-/Vertex-/Texturbudgets kontrollieren.
6. **App, Stimme und Ton weiterführen:** bestehende vollständige Seiten und echte Nutzerdaten erhalten; hochwertige blaue Glasgestaltung, sinnvoll dosierte Animation und Fold-Flächennutzung ausbauen. Menschlich klingende kindgerechte Cartoon-Lumo-Stimme sowie moderne eigene Musik tatsächlich anhören/aufnehmen und erst danach abnehmen. Der große frei agierende KI-Lernassistent bleibt ein eigener weiterer Arbeitsblock; Online-KI nur nach tatsächlicher erfolgreicher Anfrage als aktiv bezeichnen.
7. **Physische Android-Leistung prüfen:** Heinz' Fold außen→innen→außen im Menü/Rennen/Pause/Ergebnis, ARM, Framezeiten, Speicher, Wärme und längerer Betrieb. Gemessene CPU-/GPU-Zeiten und Bildrate angeben; 1/60-Physikschritt oder Emulatorrender beweist keine 60 FPS. Bis zur Messung offen kennzeichnen.
8. **Sichtbar liefern:** nach jeder wesentlichen visuellen Änderung echte aktuelle Screenshots zeigen; Bewegung und Ton mit tatsächlichen Clips belegen. Abschließend direkte installierbare APK, vollständiges Asset-/Screenshot-/Prüfpaket, Manifest, helle/dunkle Assetvorschau und ZIP liefern. Keine unbelegte Abschluss-, Release- oder Modellbehauptung.

## 8. Abnahmeregel

Technische PASS-Ergebnisse und vorhandene PNGs ersetzen nicht Heinz' verlangte visuelle Referenztreue. Aktueller Gesamtstatus: **spielbare überarbeitete Entwicklungsstufe; Referenzgleichheit und physische Leistung offen**. Arbeite autonom an den vorhandenen Funktionen weiter, führe sinnvolle Prüfungen aus und kommuniziere konkrete Fortschritte statt nur Pläne. Markiere jede noch nicht ausgeführte Prüfung eindeutig.
