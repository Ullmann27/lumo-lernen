# LUMO Studio 2019 – Abnahme des tatsächlich gebauten Kandidaten

Stand dieses Berichts: 13. November 2026, 21:44 UTC. Der Lauf318/796b ist abgeschlossen; seine Fehler bleiben dem tatsächlich getesteten Stand zugeordnet.

## Aktueller Stand

Der zusammengeführte Kandidat **0.13.7+2019** wurde tatsächlich als ARM64- und x86_64-APK gebaut. Verify/Build, die getrennte Android-Hostkompilierung und das echte Update2017→2019 sind erfolgreich. **Beide anschließenden Android-Touren scheitern an Cards-Bedienung unter der Systemleiste. Der automatische Publisher wurde übersprungen; diese APK ist nicht abgenommen und wird nicht als fertiger Kandidat veröffentlicht.** Ein enger neuer Native-Layoutfix und eine tatsächliche Flutter-Bedienaktion für die Spielkacheln werden entwickelt; sie gehören noch nicht zu den hier getesteten Quellen.

| Bestandteil | Exakte Quelle |
| --- | --- |
| Flutter/Android | `31883868bac56699dbf3b3d60a7cdb7afc496a8b`, Baum `5ca2eeee9ea3af3f67acbee83f19934942c1c5d5` |
| Godot | `796b2818ff729dc5389a92f8bf1f7fd7e6b6d93e`, Baum `ffd943c83079c5957514934ad7077f32e743fe68` |
| Entwicklungszweig beider Repositories | `chatgpt/lumo-studio-20261113` |
| Flutter-PR | [Ullmann27/lumo-lernen#466](https://github.com/Ullmann27/lumo-lernen/pull/466) |
| Godot-PR | [Ullmann27/lumo-godot#158](https://github.com/Ullmann27/lumo-godot/pull/158) |
| Vollständiger Kandidatenlauf | [43496928833, Versuch 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43496928833) |
| Vollständiger Native-Lauf | [43479909943, Versuch 1](https://github.com/Ullmann27/lumo-godot/actions/runs/43479909943) |

Main wurde nicht zusammengeführt. Die PRs sind weiterhin Entwürfe. Vor dem Host-Commit wurden alle 1.888 Dateien außerhalb von `docs/` auf Git-Blob und Dateimodus geprüft; außerdem alle 271 ausdrücklich integrierten Dateien und die 27 Dateien der historischen Verifier-Korrektur. Der endgültige Quellfreeze enthält 34 geänderte oder neue Nicht-Dokumentationsdateien gegenüber dem ersten e3d-Kandidaten. [Prüfbarer Quellfreeze](evidence/studio-final-integration-796b/final-source-freeze-after-descriptor-fix.json).

**Der gesamte Masterauftrag ist noch nicht vollständig umgesetzt.** Ein neuer flächendeckender 3D-Umbau aller Fächer und Spiele, vollständig animierte Lider/Augen/Kiefer mit Sprachsynchronisation, der einheitliche neue Ausbau aller Kartstrecken sowie die physische Fold7-Abnahme bleiben offen. Die folgenden Nachweise beziehen sich auf die konkret implementierte Studio-Ausbaustufe.

## Tatsächlich neue Funktionen und Bestandsschutz

| Modul | Vorher und konkrete neue Arbeit | Produktiver Anschluss und Grenze |
| --- | --- | --- |
| Mathematik | Bestehende Anschauungsmodelle wurden um echte gleichmäßige Verteilung ergänzt. Zwölf Würfel werden bei 12 : 3 in vier Runden auf drei Gruppen verteilt; Ziehen, Antippen und großer Aktionsknopf nutzen denselben Zustand. | Die vorhandene Flutter-Aufgabe startet die native Lernwelt. Rückkehr erhält die Aufgabe; der Besuch zählt als Hilfe und erzeugt keine fiktive richtige Antwort oder Belohnung. Die neue native Verteilung unterstützt 2–6 Gruppen mit je 1–6 Objekten. |
| 3D-Lernatelier | Reale Blender-Geometrie, Requisiten und Materialien wurden erstellt und eingebaut. Eine Sichtprüfung führte zu korrigierten Hunderterbeschriftungen und Trägerflächen. | `learning_atelier.gd` lädt das tatsächliche GLB in der verwendeten Lernwelt. Elf Meshes, elf Materialien, 29.424 Dreiecke sind Assetwerte, keine gesamte Szenen- oder GPU-Messung. |
| Original-Lumo | Sechs zusätzliche Blender-Clips auf dem vorhandenen 65-Knochen-Rig: Gehen, Sprint, Sprungaufstieg, Sprungabstieg, Landung und Bremsen. Quaternionen und Ruheachsen verhindern verfälschte Knochenbewegungen. | Jump & Run und Bauwelt steuern die Pose aus Bewegung und Bodenzustand. Originalmodell und neun bestehende Clips bleiben erhalten. Neue Gesichts-Morphs und echte Lippenbewegungen sind noch nicht enthalten. |
| Drehpuzzle | Echte Vierteldrehungen, passende Einrastprüfung, Speicherung und kompatible Wiederaufnahme. Ein Menü-Lebenszyklusfehler mit stehenbleibenden beziehungsweise freigegebenen Controls wurde korrigiert. | Der tatsächlich benutzte Puzzle-Raum ist geändert. Die aktuelle native Menüprüfung und sechs neue Menübilder gehören zu 796b. Der ältere Puzzlefilm zeigt den davor aufgezeichneten Lauf und wird nicht umetikettiert. |
| Schatzsuche | Garten und Kristallpfad können in unterschiedlicher Reihenfolge erkundet werden; beide Funde werden für den Abschluss benötigt. Touchflächen und Modalverhalten wurden geprüft beziehungsweise korrigiert. | Bestehender produktiver Abenteuerpfad, Version-1-Spielstände und Belohnungsregeln bleiben erhalten. Die alte einfachere Begleitfigur und Teile der alten Umgebung sind noch vorhanden. |
| Bauwelt | Original-Lumo-Bewegung und Touch-/Dialogkorrekturen sind angeschlossen. | Bauen, Drehen, Platzieren, 41 Teile, Rückgängig/Wiederholen und Projekte bestanden bereits zuvor. Sie werden nicht als neu erfundene Studio-Funktionen gezählt. Der zusätzliche Android-Test soll eine echte Objektänderung und deren Rücknahme nachweisen. |
| Cards | Der bisher vom Renderpoll abhängige Host-Lebensnachweis wurde an den tatsächlich aktiven Android-Activity-Lebenszyklus gebunden. | Erneuerung alle500 ms nur bei gültiger aktiver Autorität; Pause/Stop/Zerstörung/Rückkehr/Autoritätsverlust beenden sie. Die bestehende2500 ms-Lease und ausdrückliche Wiederaufnahme bleiben erhalten. Der Heartbeat bleibt in den beobachteten Android-Zeitfenstern aktiv; die gesamte Rundenprüfung scheitert anschließend am durch die Systemleiste verdeckten Pause-Bereich. Der nötige Layoutfix ist noch nicht Bestandteil318/796b. |
| Kinderprofile | Der native Scope verwendet stabile Kinderidentitäten und verhindert Kollisionen bei gleichnamigen beziehungsweise umbenannten Profilen. | Namen-/Klassenänderungen und Wiederaufnahme sind geprüft. Bestehende Lernbewertungen werden durch neue Visualisierungen nicht als gemeistert markiert. |
| Kart, Rhythmus und weitere Spiele | Bestehende Regeln, Geschwindigkeiten, Extrem-Gegner, Lasso, Karten, Fahrzeuge, Spielstände und Belohnungen wurden übernommen und regressionsgeprüft. | Es wird kein neuer vollständiger Streckenumbau oder neuer 3D-Umbau von Memory, Vier Gewinnt und Quizshow behauptet. Diese offenen Ziele bleiben eigenständige Entwicklungsarbeit. |

Die Inventur und die ausführlichen Vorher-/Nachher- und Quelldateiangaben stehen in [STUDIO_SUMMARY_2019.md](STUDIO_SUMMARY_2019.md), [STUDIO_LEARNING_HOST_20261113.md](STUDIO_LEARNING_HOST_20261113.md) und der chronologischen [Ausführungsdokumentation](STUDIO_EXECUTION_20261113.md). Schreibtrainer, Journal, Lesen, Offline-Lernen, vorhandene Elternfreigaben und bestehende Lernprofile werden über vorhandene Schnittstellen erhalten.

## Frische, tatsächlich ausgeführte Prüfungen

| Prüfung dieses Kandidaten | Ergebnis und genaue Bedeutung |
| --- | --- |
| Vollständige Flutter-Suite | 2.510 sichtbare Tests bestanden, 0 fehlgeschlagen, 0 übersprungen; Laufzeit526,524 s. 546 PNG-Einträge sind inventarisiert; dieser Logreview hat sie nicht pauschal visuell abgenommen. |
| Build-/Skriptverträge | 402 bestanden, 0 fehlgeschlagen, 0 übersprungen;72,848 s. Darin enthalten: 13 Cards-Lebenszyklusfälle und 12 Paketdescriptorfälle. |
| Android-Prüfhelfer | 764 bestanden, 0 fehlgeschlagen, 0 übersprungen;40,770 s. Dies sind Codeverträge der Prüfprogramme, keine764 installierten App-Touren. |
| Tatsächliche Android-Hostkompilierung | Gradle erfolgreich;107 Tasks, 102 ausgeführt, 5 aktuell; 202 s. Die geänderte `LumoGameActivity` gehört zu den tatsächlich kompilierten Klassen. |
| Frischer eingebundener Godot-Lauf | Erfolgreich mit fünf exakten Quellstempeln796b und leeren vorhandenen Dirty-Stempeln. 25 Nextgen- und11 Studio-Protokolle sowie die weiteren vorhandenen Pflichtgruppen sind dokumentiert. |
| Zusätzliche gezielte Gates | Fonts3, Pin/Export23 und Launcher8 erfolgreich. Diese Gruppen werden mit den obigen teilweise überlappenden Prüfungen nicht zu einer künstlichen Gesamtsumme addiert. |
| Statische Flutter-Analyse | 0 Errors, 5 Warnings, 103 Infos; der bestehende Workflow behandelt Infos/Warnungen nicht als fatal. Erfolg bedeutet hier nicht Warnungsfreiheit. |
| API35 / Android15 | **Fehlgeschlagen**, Job132161617695: normale21-Schritte-Tour bestanden; Cards-Kopfzeile durch Systemleiste überlagert. Der erste strenge Karten-/Pause-Textnachweis wird vor dem ersten Zug nicht erreicht. |
| API37 / Android17 | **Fehlgeschlagen**, Job132161617997: Framework-Guard und normale21-Schritte-Tour bestanden. Vier Kartenbildprüfungen und zwei echte Ziehaktionen bestanden; Pause-Tipp(949,87) liegt im sichtbar überlagerten Header, danach weiterhin paused=false. |
| Update2017→2019 | **Bestanden**, Job132161617636. Gleiche Testprofil-ID/Android-UID/Erstinstallation;1Stern/5XP und zehn alte Skillfelder erhalten, abgeleitetes Evidenzfeld ergänzt. Sieben geschützte Lernschlüssel bleiben über Kart, Neustart und drei Anzeigeformate exakt gleich. Die Ein-Kind-Fixture ist keine umfassende Mehrkind-/Journalmigration. |
| Zusätzliche Spiele auf Android | Separater Lauf43508752443, QA-Quelle2fdd038d, **fehlgeschlagen vor allen vier nativen Einstiegen**. Die sichtbaren Hubkacheln melden clickable=false;88 echte XMLs belegen den fehlenden Accessibility-Aktionsvertrag. Kein Android-Jumpfilm und keine neue Gameplay-Abnahme aus diesem Lauf. |

Originalnachweise: [Flutter](evidence/studio-final-verification-31883868/flutter/review.json), [Build](evidence/studio-final-verification-31883868/build/review.json), [Android-Host](evidence/studio-final-verification-31883868/host-compile/review.json), [Native](evidence/studio-final-verification-31883868/native/review.json).

Die Native-Logs enthalten weiterhin fünf Ressourcen-beim-Beenden-Fehlerzeilen und zugehörige ObjectDB-Warnungen aus älteren Kartprüfungen. Der Linux-Compatibility-Renderer meldet nicht unterstützte VSync-Umschaltung, Screen-space-AA und volumetrischen Nebel. Diese Meldungen sind erhalten; ihr Fehlen oder ihre Harmlosigkeit auf Android wird nicht behauptet. Es gab in den primären frischen Native-Logs keine `SCRIPT ERROR`-Zeile.


## Konkrete Android-Fehler und nächste Korrekturen

Die tatsächlichen Originalbilder beider Androidversionen zeigen die Systemuhr und Batterie-/Flugmodussymbole über „Zurück“ und „Pause“ von Cards. Unter API37 erreicht der Test zwei echte Ziehaktionen: Die Hand wächst von7 auf8 und9 Karten, während die Gegenhand von7 auf6 und5 sinkt; Revision und Bestätigung steigen bis7/2. Über89 Stichproben in259,600 Sekunden bleibt der neue Activity-Lebensnachweis aktiv, mit beobachtetem Alter zwischen1 und546 ms. Die alten2500-ms-Leaseregeln sind unverändert. Diese Stichproben sind keine kontinuierliche Scheduling- oder Leistungsmessung.

Beim wirklichen Pause-Tipp bleibt die Runde unpausiert. Der Tipp liegt im sichtbar überlagerten Bereich; dass die Systemleiste das Ereignis abgefangen hat, ist eine nachvollziehbare Schlussfolgerung aus Bild, Koordinaten und Zustand, aber kein separat aufgezeichneter Android-Inputdispatch. Die Produktkorrektur liest echte `WindowInsets` und tatsächliche RenderView-Abstände, berücksichtigt schon vorhandene Viewränder und verschiebt Bedienung in den sicheren Inhalt. Pixel-/OCR-Grenzen und Spielregeln werden nicht abgesenkt. Die sichere Fläche muss auch die unabhängige Kartenprojektion des Prüfers bestimmen.

Beim getrennten Zusatztest sind die realen Spielkacheln sichtbar und enabled, jedoch ohne Android-Bedienaktion gemeldet. Die318-Flutterquelle enthält einen äußeren Semantics-Button ohne `onTap`, obwohl der innere InkWell den Touch verarbeitet. Der neue Produktfix ergänzt die semantische Bedienaktion und erhält den Touchpfad; der Testfilter wird nicht aufgeweicht. Alle vier bisher nicht erreichten Spielwelten müssen mit dem neuen Kandidaten tatsächlich betreten und geprüft werden.

Originale und Auswertung: [API35](evidence/studio-final-verification-31883868/api35/api35-cards-failure-review.json), [API37](evidence/studio-final-verification-31883868/api37/review.json), [erfolgreiches Update](evidence/studio-final-verification-31883868/update/review.json). Das API37-Archiv enthält304 einzeln gehashte Original-/Protokolldateien; seine beiden ausdrücklich geöffneten Schlüsselbilder zeigen den Cards-Überlappungsfehler und den noch nativen Rückkehrframe. Die späteren Korrekturen werden durch neue Quellen und neue Läufe nachgewiesen.

## Originalbilder und echte Aufnahmen

Der Native-Lauf 796b wurde anhand von **29 einzeln geöffneten Originalbildern** geprüft; 25 davon stehen im aktuellen quellengebundenen Receipt. Vier ausgewählte Bilder wurden zusätzlich vom Integrator erneut aus den archivierten Originalbytes verglichen und geöffnet. Das erhöht nicht die Anzahl einzigartiger Bilder.

- [12 : 3, tatsächlich abgeschlossene Verteilung](evidence/studio-2019-reviewed/cb24691851bed6f1f80d725a969f30bca87097510dcf7c4a5d06a0696116051a-learning-sharing-complete-1280x720.png).
- [Original-Lumo während des echten Sprungaufstiegs](evidence/studio-2019-reviewed/0d9e5031e6b59e437202eb379693d49df9b252806fadb85b4de21be41ebc22eb-jump-jump_690x829_touch_ascent.png).
- [Drehpuzzle mit einem gesetzten Teil](evidence/studio-2019-reviewed/7a8a740af7040e19619b271fb766072dfe7be454368a1beff626f0a1f4727ab9-puzzle-puzzle_rotation_placed.png).
- [Schatzsuche am Abzweig zu zwei benötigten Funden](evidence/studio-2019-reviewed/d751095dec4aed5503d7d8f3821adae6730258efcd26611a43d6fc0d6cd6c7a7-treasure-treasure_choose_route.png).

Die editierbaren Blender-Dateien und echten Videos sind im jeweiligen Quellrepository gesichert. [Blender-Lauf/Sprint](evidence/studio-animation-20261113/Lumo-Original-Studio-Walk-Sprint.mp4), [Godot-Jump-Aufnahme](evidence/studio-runtime-jump-20261113/Lumo-Original-Jump-Runtime.mp4), [interaktive 12:3-Aufnahme](evidence/studio-runtime-learning-20261113/Lumo-Lernen-12-durch-3-Runtime.mp4), [Drehpuzzle-Aufnahme](evidence/studio-runtime-puzzle-20261113/Lumo-Drehpuzzle-Runtime.mp4).

Diese bisherigen Filme wurden vor dem letzten Menüfix auf dem dokumentierten Native-Vorgänger 76980 aufgezeichnet. Ihre Originalprotokolle bleiben dabei. Die Blender-Aufnahme enthält deklarierte Loop-Wiederholungen; die Godot-Aufnahmen stammen aus kontinuierlichen Laufzeitframes. Medienbildraten von 24/25 FPS sind keine gemessenen Spielbildraten. Es handelt sich um Desktop- beziehungsweise Blender-Evidenz, nicht um eine physische Android-Aufnahme.

## Tatsächliche ARM64-Dateiprüfung

| Eigenschaft | Ergebnis |
| --- | --- |
| APK-Größe | 322.123.605 Bytes |
| APK-SHA256 | `2288a64ccd84cc6c39d2a0502d8a225d603649f15aafc4e1499d82d1b3717b42` |
| Archivartefakt | 14075184774, 322.134.018 Bytes; SHA256 `ff5e391df4d647fd2ec30da91ddad5e4497398516d9d675965055b17460ed9d4` |
| Eingebettetes Godot-Paket | 66.217.496 Bytes; SHA256 `13f87bd1b72526d187584a35f50c67961dc88ca67af6d703472b439bc07a523b` |
| Paketkennung laut tatsächlichem CI-Verifier | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Version laut tatsächlichem CI-Verifier | 0.13.7+2019, Minimum SDK 24, Target SDK 36 |
| Gemeinsames Signaturzertifikat laut tatsächlichem CI-Verifier | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

Der Integrator hat die Original-ARM64-Datei heruntergeladen, Archiv- und APK-Prüfsummen und alle ZIP-CRCs geprüft, die eingebettete Quellprovenienz gelesen und die 16-KiB-Load-Ausrichtung aller neun nativen ELF-Bibliotheken sowie die Ausrichtung von `resources.arsc` kontrolliert. Der lokale Review ist kein zweiter apksigner-Lauf; die Signaturprüfung stammt aus dem tatsächlich erfolgreichen CI-Verifier und wurde über exakt identische APK-Bytes zugeordnet. [Unabhängige Dateiprüfung](evidence/studio-final-verification-31883868/arm64/local-package-review.json).

## Historische Fehler bleiben eindeutig zugeordnet

Die erste tatsächlich gebaute APK e3d/76980 ist eine andere Datei. Ihre früheren Android- oder Update-Ergebnisse werden nicht zum Erfolg von 318/796b erklärt.

Die korrigierte separate CLI22-Gegenprüfung f6361867 hat mit dieser alten APK Android 17 tatsächlich gestartet, den strengen Framework-Guard sowie die normale 21-Schritte-Tour bestanden und anschließend beim alten Cards-Fortsetzen versagt. Der Lauf ist insgesamt fehlgeschlagen. Die 59 geprüften Evidenzdateien sind in Dokumentationscommit `02376fb60bc1c56733cd9356968a7b9576713afd` auf [PR472](https://github.com/Ullmann27/lumo-lernen/pull/472) erhalten.

Original CLI 12 erzeugte in diesem Vergleich ein ungestartetes AVD mit Ziel android-0 und 800M; offizielle CLI 22 erzeugte android-37.0 und 10G. Weitere erzeugte Defaults veränderten sich ebenfalls; daraus wird kein isolierter Kausalbeweis für eine einzelne Einstellung konstruiert. Die vorherigen Vorbereitungs- und Frameworkfehler bleiben dokumentiert.

Eine alte Aufnahme namens `05_learning_same_flutter_lesson.png` zeigt noch die native Szene, während die später gelesene XML bereits die Flutter-Aufgabe belegt. Dieses Bild gilt ausdrücklich nicht als visuelle Rückkehrbestätigung. Die aktuelle API35-Aufnahme zeigt tatsächlich wieder Flutter. Die aktuelle API37-Aufnahme desselben Namens zeigt dagegen erneut die noch native Szene; die spätere XML bestätigt dort die Rückkehr. Auch diese neue API37-PNG gilt ausdrücklich nicht als visueller Flutter-Rückkehrbeleg. Die Capture-Synchronisation wird vor dem nächsten Kandidaten präzisiert.

## Fähigkeitsmatrix und offene Zielgeräteabnahme

| Fähigkeit | Einstufung | Tatsächlicher Einsatz oder Grenze |
| --- | --- | --- |
| Szenen, GDScript, Shader, GLB und Hostcode bearbeiten | direkt umsetzbar | Änderungen in den vorhandenen Projekten, tatsächliche Godot- und Kotlin-Ausführung. |
| Geometrie und Originalrig-Clips erzeugen | mit vorhandenen Werkzeugen umsetzbar | Blender 4.3.2, echte bearbeitbare Quellen, GLB-Export, Quaternion-Keyframes und Cycles-Aufnahmen. |
| Flutter und Godot auf Android verbinden | direkt umsetzbar | Bestehende Schnittstellen erweitert, beide echten APK-Architekturen gebaut. |
| Rendererbilder und reale Eingaben prüfen | mit vorhandenen Werkzeugen umsetzbar | Lokaler Linux-Renderer sowie echte GitHub-Emulatorläufe; kein Ersatz für Zielgeräteprüfung. |
| GitHub, getrennte Branches und drei Entwicklungsagenten | direkt umsetzbar | Tatsächliche Commits, PRs und getrennte Aufgabenbereiche mit kontrollierter Integration. |
| Physische Fold7-60-FPS-, Temperatur- und Latenzmessung | derzeit blockiert | Kein verbundenes Samsung Galaxy Z Fold7. Dafür liegen keine gemessenen Werte vor. |
| Vollständige Gesichtsanimation und übriger Weltenausbau | mit vorhandenen Werkzeugen umsetzbar | Grundsätzlich reale weitere Entwicklungsarbeit; in dieser Ausbaustufe noch nicht vollständig umgesetzt. |

Die isolierte CPU-Poseprobe mit acht Figuren lag bei etwa 0,379 ms P95 unter Linux. Sie umfasst weder Grafik noch Physik, Sprache oder Flutter; der neue Posensampler ist teurer als der alte vereinfachte Pfad. Eine stabile 16,7-ms-Gesamtframetime oder 60 FPS auf dem Zielgerät lässt sich daraus nicht ableiten.

