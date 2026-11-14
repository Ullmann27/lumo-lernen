# LUMO Studio 2019 – implementierter Stand und Abnahme

## Ergebnis und aktueller Lieferstatus

Die Studio-Entwicklung enthält echte, produktiv angeschlossene Godot-Geometrie, eine neue interaktive Verteilmechanik, zusätzliche Blender-Bewegungsclips für das Originalrig, spielbare Puzzle-/Schatzsuche-Erweiterungen sowie bestätigte Korrekturen an Touchbedienung und nativen Kinderprofilen. Drei reale Entwicklungsagenten und der Integrator haben getrennte Bereiche bearbeitet und konkrete Änderungen unabhängig gegengelesen.

**Der vollständige Masterauftrag ist noch nicht abgeschlossen.** Insbesondere ein flächendeckender neuer 3D-Umbau aller Fächer und Spiele, Gesichtsmorphs mit echter Sprachsynchronisation, ein einheitlicher Ausbau sämtlicher Kartstrecken sowie die physische Fold7-Leistungsmessung bleiben offen. Dieser Bericht trennt neue Studio-Arbeit, übernommene Nextgen-Funktionen und tatsächliche Testgrenzen.

Der produktive Main-Branch wurde nicht zusammengeführt. Beide Studio-PRs bleiben zur Prüfung getrennt von Main:

| Bereich | Gesicherte Quelle | Tatsächlicher Prüfstand |
| --- | --- | --- |
| Godot | [PR #158](https://github.com/Ullmann27/lumo-godot/pull/158), Branch `chatgpt/lumo-studio-20261113`, Commit `796b2818ff729dc5389a92f8bf1f7fd7e6b6d93e` | Vollständiger [Native-Lauf 43479909943](https://github.com/Ullmann27/lumo-godot/actions/runs/43479909943) im ersten Versuch **SUCCESS**: acht Pflichtjobs und Archivierung. 29 aktuelle Originalbilder einzeln geprüft; 25 davon im neuen quellengebundenen Receipt ausgewählt, einschließlich aller sechs Puzzle-Menübilder. |
| Flutter/Android | [PR #466](https://github.com/Ullmann27/lumo-lernen/pull/466), derselbe Branchname; Dokumentationscheckpoint `3022777fba84618a1915f98fdcf6a6ccda9f4db1` | Die tatsächlich gebauten APKs stammen aus `e3d161cb2f79b732ac2dbafc2764b151247f018b` und enthalten Native `76980a94`. Der Dokumentationscheckpoint verändert diese App nicht. |
| Android-Gegenprüfung | Commit `21df16b1278e5294a225f796e599d8bb0155e9f5`, Branch `chatgpt/lumo-android-recheck-2019-20261113` | Prüft unveränderte e3d-APK-Bytes mit getrennt protokolliertem Prüferstand. Dies ist keine neue APK und ersetzt den späteren vollständigen Kandidatenlauf nicht. |

**Noch kein freigegebener öffentlicher Studio-APK-Download.** Eine erfolgreiche Kompilierung allein reicht dafür nicht aus. Das physische Galaxy Z Fold7 ist nicht angeschlossen; 60 FPS, GPU-Zeit, Temperatur und Touchlatenz auf dem Zielgerät wurden nicht gemessen.

## Aktueller Integrationsfreeze vor dem neuen vollständigen APK-Lauf

Stand: 13. November 2026, 19:43 UTC. Die nachfolgenden historischen e3d-APK-Ergebnisse werden dadurch nicht zu Ergebnissen des neuen Kandidaten.

- **Cards:** Der getrennte, datei- und modusgeprüfte Commit `651d4d967f6d7c918a3e5cd666c5364283abbaa5` ist in [PR #471](https://github.com/Ullmann27/lumo-lernen/pull/471) gesichert. Die unabhängige Aktivitäts-Lebensdauersteuerung aktualisiert die vorhandene Autoritäts-Lease alle 500 ms nur bei aktivem und gültig gebundenem Cards-Host. Pausieren, Stoppen, Rückkehr, Zerstörung, geschlossener Briefkasten und Autoritätsverlust stoppen die Erneuerung. Alte Renderaufrufe können sie nicht wiederbeleben. Die bestehende Dart-Frist und ausdrückliche Wiederaufnahme bleiben erhalten. 13 lokale JVM-Verhaltensfälle bestanden; die reale neue Android-Ausführung ist noch offen.
- **Android 17:** Der vorherige Framework-Lauf `43489065730` mit Prüfer `e4ed59e2` scheiterte vor Installation der App nach einem tatsächlich beobachteten `system_server`-Wechsel. Original-Logcat und Archiv belegen wiederholte SurfaceFlinger-Abbrüche und frühere ENOSPC-Schreibfehler. Die bisherige CLI-Version und AVD-Zielkennung wurden dort nicht erfasst; eine konkrete Ursache daraus zu behaupten wäre unzulässig.
- **Neue eigene Gegenprüfung:** [PR #472](https://github.com/Ullmann27/lumo-lernen/pull/472), Quelle `fbb9a28e76a08455fc796ed1915a7c5a2ef8226f`, [Run 43494312623](https://github.com/Ullmann27/lumo-lernen/actions/runs/43494312623), erzeugt zuerst ein echtes unverändertes Vergleichs-AVD mit den ursprünglichen Werkzeugen. Danach verwendet die Action die SHA256-geprüfte offizielle CLI 22.0. Der strenge Guard prüft das tatsächlich neu erzeugte AVD vor dem ursprünglichen Keyevent und der App-Tour. GPU, Emulator, Image, RAM und Partitionsvorgaben werden nicht zusätzlich verändert. Die Ausführung läuft; ein Android-PASS ist noch nicht festgestellt.
- **Quellenaktualität:** Die fünf inzwischen neu hinzugekommenen funktionalen/supportenden Dateien des Flutter-Basiszweigs sind bereits in e3d, dem Dokumentationscheckpoint und Cards651d bytegleich enthalten. Die Godot-Basis hat sich nicht weiterbewegt. [Exakter Vergleich](evidence/studio-final-integration-796b/current-base-source-comparison.json).
- **Neue lokale Integrationstests:** 764 Android-Probe-Vertragsfälle bestanden ohne Skip. Der vollständige Scriptlauf hatte 390 Fälle und einen Fehler in einer alten erwarteten Anzahl von UI-Beobachtungen. Die tatsächliche Gestengrenze bleibt 24; beide Richtungen benötigen einschließlich ihres letzten erreichten Bildes 26 Beobachtungen. Die korrigierte vorhandene Vertragsdatei bestand anschließend alle sieben Fälle. Ein nachträglicher vollständiger 390-PASS wird nicht behauptet. Die neue gesamte CI wird den zusammengeführten Stand erneut prüfen.

Der finale Anschluss verwendet Native `796b2818ff729dc5389a92f8bf1f7fd7e6b6d93e` mit dem neuen 25-Bilder-Receipt. Die neue CLI-/AVD-Erweiterung bestand lokal acht zusätzliche Gegenfälle sowie acht vorhandene Framework-/Action-Verträge ohne Skip, Actionlint und die Shell-Syntaxprüfung. Eine unabhängige Quellenprüfung bestätigte den unveränderten API35-Aufruf und die vier anderen Workflowjobs. [Unabhängige Review](evidence/studio-2019-review-notes/android37-cli22-independent-review.json).

Die endgültige Host-Commit-ID entsteht erst beim anschließenden Commit. Ein erfolgreicher Abschluss des vollständigen Builds, der API35-/API37-App-Touren, des Updates und des Publishers wird in diesem Vorabfreeze nicht vorweggenommen.



### Folgekorrektur vor dem tatsächlichen neuen Kandidatenlauf

Der erste CLI22-Diagnoselauf [43494312623](https://github.com/Ullmann27/lumo-lernen/actions/runs/43494312623) mit Quelle `fbb9a28e` ist inzwischen **FAIL**. Der erfolgreiche SDK-Installer lud `x86_64-37.0_r08.zip`. Dessen eingebettete `source.properties` enthalten Revision 7, während der installierte lokale Paketdescriptor Revision 8 ausweist. Unsere Vorprüfung hatte diese unterschiedlichen Felder gleichgesetzt; sie stoppte deshalb vor AVD-Erzeugung, CLI22-Installation und Androidstart. Dies ist kein beobachteter neuer Androidabsturz. [Originalbericht und Originalartefakt](evidence/studio-2019-verification-e3d161cb/android37/cli22-recheck-fbb9a28e/failure-review.json).

Die enge Korrektur liest den eindeutigen lokalen Paketdescriptor, behält beide Originalangaben und weist spätere Änderungen an Properties oder Descriptor weiterhin ab. Der echte ursprüngliche Fall scheitert unter dem alten Helper; nach Korrektur bestehen zwölf gezielte Fälle ohne Skip. Workflow, Framework-Guard und App-Gates sind unverändert. Quelle `f63618670359af93a25f84a69cbfab4c583b6c53` ist in PR #472 gesichert; der neue [Diagnoselauf 43496485216](https://github.com/Ullmann27/lumo-lernen/actions/runs/43496485216) prüft weiterhin ausschließlich die unveränderte e3d-APK. Ein neuer Startup- oder Android-PASS wird noch nicht behauptet. [Unabhängige Review](evidence/studio-final-integration-796b/android37-package-descriptor-independent-review.json).

Der neue [abschließende Quellfreeze](evidence/studio-final-integration-796b/final-source-freeze-after-descriptor-fix.json) umfasst 34 neue beziehungsweise geänderte Dateien außerhalb von `docs/` gegenüber e3d; alle anderen 1.854 Quelldateien bleiben erhalten. Zusammenführung und vollständige Kandidatenprüfung folgen auf genau diesen Dateien. Die endgültige Host-Commit-ID wird durch die tatsächliche CI-Provenienz festgehalten.

## 1. Tatsächlich neue Studio-Funktionen

### Mathematik und Aufgabenverbindung

Die neue Anschauung für **12 : 3** verteilt echte dreidimensionale Würfel gleichmäßig im Rundlauf. Nach einer vollständigen Runde besitzen die drei Gruppen jeweils einen Würfel, anschließend zwei, drei und vier. Das Kind kann die Objekte ziehen oder antippen; ein großer Aktionsknopf nutzt denselben Ablauf. Sichtbare Gruppenzähler, Vorrat und bewegte Objekte bleiben konsistent. Pause sperrt Eingaben, Neustart stellt dieselbe Aufgabe wieder her und ein Formatwechsel behält den Zustand.

Der produktive Weg startet die aktuelle Flutter-Aufgabe über „Mit Lumo in 3D ausprobieren“ in Godots Lernroute. Die Rückkehr verändert weder die Aufgabe noch deren Bewertung. Der Besuch zählt als Hilfe; es werden dadurch keine richtigen Antworten, Sterne oder Kompetenzen erzeugt. Aktuelle Multiplikationen und gleichnamige Bruchadditionen werden ebenfalls an das passende vorhandene Modell übergeben. Rationale Antworten wie `3/4` bleiben erhalten.

Die native neue Verteilung unterstützt 2–6 Gruppen mit je 1–6 Würfeln, höchstens 36 Objekte. Größere oder nicht passende Aufgaben bleiben in ihrer vorhandenen Darstellung. Die Flutter-Divisionsdarstellung unterstützt alle vorgesehenen 1–12 Gruppen und exakte Mengenbündel. Diese Grenzen werden nicht still durch vereinfachte Aufgaben ersetzt.

Wesentliche Dateien sind `scripts/learning/learning_activity.gd` und `learning_world.gd` im Godot-Repository sowie `native_learning_activity.dart`, `legacy_lumo_task_adapter.dart`, `lumo_premium_visuals.dart` und der vorhandene Android-Host im Flutter-Repository. [Detailbericht und Hostbelege](STUDIO_LEARNING_HOST_20261113.md).

### Tatsächlich eingebautes Blender-Lernatelier

Das neue Atelier besitzt reale Architektur, Boden- und Gartenobjekte, Requisiten und Materialien. Die editierbare Blender-Quelle und das Autorenwerkzeug sind im Godot-Repository gesichert. Das exportierte GLB enthält elf Meshes, elf Materialien und 29.424 Dreiecke; es wird von `learning_atelier.gd` in der tatsächlich benutzten Lernwelt geladen. Wiederholte Geometrie verwendet gemeinsame Meshes beziehungsweise MultiMesh. Ein Blattshader respektiert reduzierte Bewegung.

Eine echte Sichtprüfung fand zunächst unzureichend hinterlegte und durch Perspektive beziehungsweise Tiefentest beeinträchtigte Hunderterbeschriftungen. Diese Befunde wurden im Produkt und mit geometrischen Gegenproben korrigiert. Die aktuellen ausgewählten Bilder zeigen die untere Beschriftung vollständig auf ihrer Platte und beide Balken des oberen Gleichheitszeichens. Meshzahlen sind Assetwerte; sie sind kein Nachweis des gesamten GPU- oder Framebudgets.

### Original-Lumo und Bewegung

Sechs zusätzliche Bewegungsclips wurden in Blender auf dem vorhandenen Originalrig mit **65 Knochen** erstellt: Gehen, Sprint, Sprungaufstieg, Sprungabstieg, Landung und Bremsen. Jede Action enthält 25 Quaternion-Keyframes. Die Laufzeit berechnet die Pose in den jeweiligen Ruheachsen der Knochen und steuert sie aus tatsächlicher Geschwindigkeit, Flugphase, Bodenkontakt und Verzögerung.

Die produktiven Jump-&-Run- und Bauwelt-Aufrufer benutzen diesen Pfad. Die neuen Clips sind damit keine isolierte Präsentation. Das ursprüngliche Modell bleibt bytegleich, und die neun bisherigen Clips bleiben erhalten. Eine gefundene Fußtranslation, welche die Segmentlänge veränderte, und ein Idle-Zeitversatz wurden korrigiert. Der mathematische Blender-/Godot-Vergleich umfasst 300 Fußendpunkte; die maximale gemessene Abweichung beträgt rund 0,000000733 Meter.

**Gesicht und Sprache:** Kontrollierbare Lider, Augen, Kiefer und entsprechende Morphs sind noch nicht implementiert. Körpergesten und Kopfbewegung sind vorhanden, ersetzen aber weder Blinzeln noch echte Lippensynchronisation. Die dafür nötige Modellierungs-/Rigarbeit ist grundsätzlich mit Blender möglich und bleibt Entwicklungsarbeit.

### Drehpuzzle und Menübedienung

Das vorhandene Puzzle besitzt nun zusätzlich einen Drehmodus. Vierteldrehungen verändern echte Teilgeometrie und die Einrastregel. Auswahl, Drehen, Ziehen, Loslassen, passendes Einrasten und Autosave sind über tatsächliche Eingabeereignisse geprüft. Der bisherige Bildermodus und alte Version-1-Spielstände bleiben kompatibel; neue optionale Rotationsfelder ergänzen die Daten.

Die erste kompakte Rendererprüfung zeigte Teile unter dem HUD. Kamera und Inhaltsbereich wurden deshalb anhand der tatsächlichen Bildschirmprojektion korrigiert. Eine spätere kontinuierliche Aufnahme deckte einen eigenständigen Menüfehler auf: Ein Button wurde während seiner Release-Verarbeitung aus dem SceneTree entfernt. Die enge Reparatur blendet den alten Control sofort aus und lässt ihn mit `queue_free()` geordnet freigeben. Der neue gemeinsame Native-Stand enthält diese Reparatur sowie einen verbindlichen Headless- und Rendererpfad mit sechs exakt benannten Bildern in zwei Formaten.

### Schatzsuche und Bauwelt-Touchkorrekturen

Nach dem Brückenhinweis kann das Kind Garten und Kristallgebiet in beliebiger Reihenfolge erkunden; beide Funde werden für den nächsten gemeinsamen Abschnitt benötigt. Die neuen optionalen Speicherfelder erhalten ältere lineare Stände. Vorhandene Belohnungen bleiben erhalten. Ein vollständiger Austausch der bisherigen Begleiter oder ein neuer Ausbau aller Umgebungen ist damit nicht behauptet.

Bei der Bauwelt wurden konkrete Eingabeprobleme mit Auftragsdialogen und Werkzeugleisten behoben: UI-Eingaben werden nicht gleichzeitig als Kameradrehung verarbeitet. Werkstatt, Schatzsuche und Bauwelt besitzen zusätzliche echte Dichte-/Touchprüfungen. Die Bauwelt selbst war bereits ein begehbares Bauspiel mit Teilen, Raster, Kollisionen, Undo/Redo und Projektspeicherung; diese vorhandenen Mechaniken werden nicht als neue Studio-Erfindung ausgegeben.

### Cards: Lebensnachweis unabhängig von Renderstillstand

Ein zusätzlicher Android-Befund führte zu einer konkreten Hostkorrektur. Der Kartentisch erneuert seinen Lebensnachweis jetzt alle 500 ms auf dem Android-Main-Looper, solange die Aktivität wiederaufgenommen und ihre Cards-Autorität tatsächlich gebunden ist. Der Renderlesepfad schreibt keine Lebenszyklusdaten mehr. Pause, Stop, Destroy, Rückkehr, verlorene Autorität und eine geschlossene Mailbox stoppen die Erneuerung; bereits geplante alte Aufrufe werden entwertet. Die bestehende 2.500-ms-Frist, echte Hintergrundpause, ausdrückliche Fortsetzung und alle Profil-/Speicherregeln bleiben bestehen.

Die vollständige unveränderte und geänderte Kotlin-Activity wurde tatsächlich kompiliert und mit einem kontrollierten JVM-Looper ausgeführt. Derselbe finale Vertrag ergibt vorher neun Fehler und vier bestandene Fälle, nachher **13/13 PASS ohne Skip**. Dazu kommen acht bestehende Dart-Sessiontests und die zusätzliche reine Beobachtung der tatsächlichen Gerätezeit/`lifecycle.json` im kommenden Emulatorlauf. Die ursprüngliche API35-Aufnahme belegt die erneute Pause, aber noch nicht eindeutig deren Auslöser; die Architekturkorrektur ist separat durch den Renderstillstand-Gegenfall belegt. Gesichert in [Draft-PR #471](https://github.com/Ullmann27/lumo-lernen/pull/471), Commit `651d4d967f6d7c918a3e5cd666c5364283abbaa5`. Ein neuer echter Android-PASS steht noch aus. [Quellen und unveränderte Rohbelege](evidence/studio-cards-heartbeat-20261113/source-and-tests.json).

### Getrennte native Kinderprofile

Ein bestätigter Kollisionspfad bei nativen Speicherkennungen wurde korrigiert. Die neue Bindung verwendet die stabile Kinder-ID statt einer allein aus Namen beziehungsweise Klasse abgeleiteten Zuordnung. Gleichnamige Kinder bleiben getrennt; Umbenennen, Klassenwechsel und Neustart behalten die Zuordnung. Mehrdeutige alte Daten werden nicht automatisch dem falschen Kind zugeschrieben. Die dafür vorgesehene ausdrückliche Elternzuordnung und asynchrone Sessiongrenzen sind getestet.

Schreibtrainer, Journal, vorhandene Lese-/Sprachmodule und Offlinefreigaben wurden nicht durch neue Parallelsysteme ersetzt. [Profil- und Speicherbelege](evidence/studio-native-profiles-20261113/RESULT.json).

## 2. Echte Animationen und spielbare Evidenz

Die folgenden vier Videos stammen aus Blender beziehungsweise dem tatsächlichen Godot-Viewport. Es handelt sich nicht um generierte Konzeptbilder. Die kontinuierlichen Godot-Aufnahmen verwenden den unveränderten produktiven Stand `76980a94`; die spätere Änderung auf 796b betrifft den Puzzle-Menülebenszyklus und dessen Prüferanschluss.

| Aufnahme | Tatsächlich gezeigt | Grenze |
| --- | --- | --- |
| [Lumo geht und sprintet – Blender](evidence/studio-animation-20261113/Lumo-Original-Studio-Walk-Sprint.mp4) | 40 echte Cycles-CPU-Frames aus den gespeicherten Actions, zu 3,8 Sekunden Video verarbeitet | Gehen/Sprint auf der Stelle; bewusst wiederholte Frames und Schnitt; kein Gameplay-/FPS-Beleg |
| [Jump & Run – tatsächlicher Godot-Lauf](evidence/studio-runtime-jump-20261113/Lumo-Original-Jump-Runtime.mp4) | 240 aufeinanderfolgende Viewportbilder; echte Touch-/Drag-Eingaben, sechs Bewegungszustände, Absprung und Landung auf der zweiten Insel | Zehn Sekunden bei festem Aufnahmeformat; Software-Renderer, keine gemessenen Android-FPS |
| [12 : 3 – tatsächliche Verteilung](evidence/studio-runtime-learning-20261113/Lumo-Lernen-12-durch-3-Runtime.mp4) | Zwölf echte Aktivierungen, vier vollständige Runden bis `[4,4,4]`, reale Würfelbewegungen und Lumo-Gesten | Keine Tonspur, keine Lernerfolgsbewertung durch die Probe |
| [Drehpuzzle – tatsächliche Teilsequenz](evidence/studio-runtime-puzzle-20261113/Lumo-Drehpuzzle-Runtime.mp4) | Auswahl, zwei Vierteldrehungen, Drag/Drop, Einrasten und produktives Autosave | 1/6 Teile, vier Züge, null Hilfen; ausdrücklich dokumentiertes Anfangspreset wegen des erst später reparierten Menüfehlers |

Alle vier MP4-Dateien wurden vollständig decodiert. Einzelne dekodierte Bewegungs-/Spielzustände wurden tatsächlich geöffnet. Das Aufnahmeformat von 24 beziehungsweise 25 Medien-fps ist kein Leistungsnachweis auf dem Zielgerät.

## 3. Was aus Nextgen übernommen wurde

Bereits vorhanden waren unter anderem die 8+5-Zehnerbrücke, Subtraktion über den Zehner, Gruppen-/Bruchmodelle, Silben und Pflanzen, die Leseverständnisbewertung ohne automatische ASR-Fehlerbenotung sowie 24 Geschichten. Jump & Run besaß bereits Beschleunigung, variable Sprunghöhe, Sprungpuffer und Absprungtoleranz. In der Bauwelt waren unter anderem 41 Bauteile, sechs Projekte, Raster und Undo/Redo vorhanden.

Lumo Kart besitzt zwölf Strecken und die geforderten bestehenden Tempo-, Extrem-Gegner-, Schanzen- und Lassoerweiterungen. Diese wurden erhalten und erneut in den verpflichtenden Regressionen berücksichtigt. Studio hat nicht alle zwölf Strecken neu auf einen einheitlichen Produktionsstandard gebracht. Cards besitzt bereits seinen nativen Tisch, Kartenmaterialien und Spiel-/Turniermechaniken; die neue Integration prüft den tatsächlichen Kartenraum und seine Laufzeit, beansprucht aber keine vollständige Neuentwicklung des Spiels.

Die Inventur umfasst zehn kanonische Spieleportale und die zusätzlichen alten beziehungsweise eingebetteten Routen. Memory, Vier gewinnt, Quizshow, Würfel-Wettlauf, Kartenabenteuer und Lernminispiele sind erfasst; sie besitzen noch keinen flächendeckenden neuen Studio-3D-Umbau. [Vollständige Inventur und Grenzen](STUDIO_EXECUTION_20261113.md), [Nextgen-Bestandsprüfung](NEXTGEN_AUDIT_20261113.md).

## 4. Tatsächlich ausgeführte Tests und Android-Ergebnis

Der erste vollständig gebaute Studio-Kandidat ist **0.13.7+2019**, Host e3d, Native 76980. Sein tatsächlicher Verify-/Buildjob hat bestanden: 2.510 Flutter-Tests ohne Fehler oder Skip, 353 Build-/Skriptverträge, 746 Android-Probeverträge und 84 native Pflichtaufrufe. Diese Prüfgruppen überlappen teilweise und werden nicht zu einer künstlichen Gesamtsumme addiert. Der Android-Host wurde tatsächlich kompiliert; beide APK-Architekturen wurden erzeugt und auf Paket, Quellen, eingebettetes PCK, feste Signatur und Ressourcen geprüft.

Die ARM64-APK hat SHA256 `c8f3f15a2e9eb77a1f03152f849f0e73211de91cd6f4299fb6555e557735a3d1`. Ihre tatsächlichen Originalbytes und das eingebettete PCK wurden zusätzlich lokal gelesen. Der erste Kandidat ist trotzdem nicht vollständig abgenommen:

- Die normale API35-Tour bestand **21/21 Schritte**. Die anschließende Studio-Tour scheiterte am fehlenden letzten Suchdurchlauf nach einer erlaubten Scrollbewegung. Ein identischer neuer Vertrag reproduzierte den Fehler; der enge Fix behält das Gestenlimit und ergänzt die abschließende Beobachtung.
- Die API35-Gegenprüfung bestand die normale Tour erneut mit 21/21 Schritten sowie die Studio-Lern-/Sprachsequenz: tatsächliche Elternfreigabe, fünf reale Lernaktionen, bestätigte Sprachabschlussmarker und Rückkehr zur selben Aufgabe mit erhaltenen Lernschlüsseln. Cards scheiterte vor dem ersten Ziehen: Nach bestätigtem Weiterspielen wechselte der öffentliche Zustand von Revision 5, `paused=false` auf Revision 6, `paused=true`. Die beiden tatsächlich geöffneten Fehlerbilder zeigen Kartenmotive und eine Pausefläche. Der erste Capture wurde daher bereits wegen des Pausenzustands abgewiesen; kein abgeschlossener Pixelvergleich, keine gezogene Karte und kein kompletter Cards-PASS. Das Originalartefakt enthält keine Heartbeat-/Pause-Epoch-Zeitreihe, sodass die genaue Ursache nicht abschließend belegt ist. Die im Code gefundene Kopplung des Heartbeats an den Renderpoll wird als konkrete Schwachstelle separat repariert und mit zusätzlicher Diagnose geprüft.
- API37 scheiterte zunächst vor Emulatorstart am SDK-Paketnamen. Ein echter separater SDK-Kataloglauf belegte `android-37.0`. Mit dem korrigierten Namen kam die Gegenprüfung bis zur Bootmeldung, scheiterte anschließend aber vor der App-Tour an Androids noch nicht erreichbarem Eingabedienst. Dafür wurde ein zusätzlicher strikt begrenzter Framework-Guard mit echten Dienst-/Provider-/Systemserver-Beobachtungen entwickelt. Der tatsächliche [API37-Diagnoselauf 43489065730](https://github.com/Ullmann27/lumo-lernen/actions/runs/43489065730) auf Commit `e4ed59e226ab76c4d7accf174f1f05fc05089d87` ist vor der App-Tour fehlgeschlagen: Der Guard beobachtete einen Systemserverwechsel. Die Original-Startprotokolle zeigen acht SurfaceFlinger-Abbrüche mit derselben Mapper-DMA-Assertion und neun Systemserverstarts sowie gesonderte ENOSPC-Schreibfehler. Ein gezielter Vergleich der tatsächlichen CLI-/AVD-Erzeugung wird vorbereitet; die aktuelle AVD-INI und CLI-Version wurden in diesem Lauf nicht aufgezeichnet. Original-Keyevent, vollständige App-Tour und alle Binär-/SDK-Guards bleiben bestehen.
- Der reale **2017→2019-Updatepfad bestand**. Beim getesteten einen Kind bleiben UID, erste Installationszeit, zehn bestehende SkillRecord-Felder und sieben geschützte Lernschlüssel erhalten. Ein Stern und 5 XP bleiben nach Update, Kartbesuch, Neustart und drei Anzeigeformaten sichtbar. Dies ersetzt keine vollständige Migration mit zwei alten Kinderprofilen, gefülltem Journal oder alten nativen Spielständen.
- Ein separater historischer 1999-Workflowfehler wurde ebenfalls behoben und tatsächlich erneut erfolgreich ausgeführt. Er wird nicht als Erfolg des aktuellen Studio-Kandidaten gezählt.

Der neue Native-Stand 796b besitzt zusätzlich die erfolgreiche aktuelle Menüregression und echte neue Bilder. Sein vollständiger Workflow hat inzwischen alle acht Pflichtjobs und die Archivierung im ersten Versuch bestanden. Der neue Bildreceipt ist inzwischen erstellt: SHA256 `4091bc1c79a0efa75c368b35ea77472a5bb2cf2ea8fd2f0e1b096ebdb43eebae`, 25 ausgewählte Originalbilder aus 29 einzeln betrachteten aktuellen Aufnahmen. Der neue vollständige APK-Kandidatenlauf bleibt ein gesonderter Pflichtschritt. Originalfehler und Zwischenstände bleiben in GitHub erhalten; ein späterer Erfolg löscht ihre Beweisgrenzen nicht.

## 5. Technische Fähigkeiten und verbleibende Abnahme

| Fähigkeit | Einstufung | Tatsächlicher Nachweis / Grenze |
| --- | --- | --- |
| Godot-Szenen, GDScript, Shader und Originalmodelle bearbeiten | direkt umsetzbar | Produktcode geändert und mit Godot 4.6.3 ausgeführt |
| Echte Geometrie und Animationen erstellen | mit vorhandenen Werkzeugen umsetzbar | Blender 4.3.2, gespeicherte Quellen, GLB-Export und tatsächliche Cycles-Frames |
| Flutter-/Android-/Godot-Verbindung entwickeln | direkt umsetzbar | Bestehender Launcher, Kotlin-Host, Aufgaben-/Profilverträge und echte APK-Builds |
| Echte Rendererbilder und Interaktionen prüfen | mit vorhandenen Werkzeugen umsetzbar | Lokaler X11-Software-Renderer und GitHub-Rasterläufe; tatsächliche Eingaben und Originalbildreviews |
| GitHub, getrennte Branches und drei Agenten verwenden | direkt umsetzbar | Tatsächliche Commits, PRs, Workflows und voneinander abgegrenzte Verantwortung |
| Vollständige Android17-Abnahme | noch offen | Konkreter Emulator-Frameworkstartfehler; kein vorgetäuschter App-/SDK-PASS |
| Physische Fold7-Leistung und Bedienung messen | derzeit blockiert | Kein verbundenes Zielgerät; keine gemessenen 60 FPS, CPU/GPU-Framezeiten, Temperatur oder Touchlatenz |
| Vollständige Gesichtsanimation und alle Welten auf Zielqualität | grundsätzlich bearbeitbar, noch nicht umgesetzt | Weitere reale Modellierungs-, Gameplay- und Integrationsarbeit erforderlich |

Die begrenzte CPU-Poseprobe zeigt für acht Plattformfiguren ungefähr 0,379 ms P95 im Linux-Headless-Lauf. Sie schließt Rendering, GPU-Skinning, Physik, Sprache und Flutter aus. Der neue Posensampler ist relativ zum alten vereinfachten Pfad teurer. Daraus lässt sich weder das gesamte 16,7-ms-Budget noch eine stabile Zielgerätebildrate ableiten.

**Vollständige Originalprotokolle, Dateihashes, Bildreviews und die chronologische Zuordnung verworfener Kandidaten:** [STUDIO_EXECUTION_20261113.md](STUDIO_EXECUTION_20261113.md).
