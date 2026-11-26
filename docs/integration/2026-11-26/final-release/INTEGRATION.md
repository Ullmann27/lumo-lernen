# LUMO Intelligence 2.0 · Integrationsmatrix und Abnahme

## Quellen

| Quelle | Befund und Entscheidung |
| --- | --- |
| Flutter `6d7e7aa19831012264c37ea8d20324531e95c39b` | Ausgangspunkt. Enthält die Zusammenführung von 2082, fachliche Korrekturen, Lernstufen, neue Vergleichsaufgaben, Elternansicht und Lernspielrouten. [2083-Bau](https://github.com/Ullmann27/lumo-lernen/actions/runs/45786210491) hatte 4.161 erfolgreiche und 193 übersprungene Tests sowie einen Fehler im Sachunterricht. |
| Godot `dedc588cd0862069fe22863f671877042aa7c53c` | Ausgangspunkt. Enthält die Kart-Flotte, Werkstatt, drei Signaturstrecken, die Welt mit Sonnenhafen sowie die laufenden NPC- und Tischspiel-Entwicklungen. |
| Parallele 2083-Integration Flutter `d5b50c331b2235544daa9c4aba61c9dee3eb9b25` | Probe der gepackten Laufzeitdaten übernommen. Der gewählte Flutter-Ausgangspunkt enthält zusätzlich die drei Sachunterrichtsdiagramme sowie die Prüfung ähnlicher Aufgaben anhand der Kompetenz. |
| Parallele 2083-Integration Godot `94477ade6339133bb15125d719b50af80d615ea0` | Exportfilter für Stadt-, Figuren-, Strecken- und Musikdaten übernommen. Die dortige abweichende Windschatten-Änderung und die bereits im Ausgangspunkt ersetzten Importprodukte gehören nicht zum Integrationsstand. |
| 2081, 2082 und frühere Kart-, World- und Lernzweige | Die übernommenen Branches und Patches sind in den früheren [2081-Daten](../../2026-11-24/INTEGRATION-2081.json), der [2082-Matrix](../../2026-11-25/INTELLIGENCE-2082.md) und der [2083-Übergabe](../INTELLIGENCE-2-0.md) verzeichnet. Der Ausgangspunkt baut auf 2082 auf. |
| 2082 APK | Das [ARM64-Artefakt](https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812/artifacts/15004539062) ist der jüngste gelungene Ausgangsbau. Seine drei Workflow-Jobs einschließlich Android-Tour meldeten Erfolg. Ein späterer, getrennter Versuch, die unveränderte Datei öffentlich zu veröffentlichen, scheiterte beim Erstellen des Tags mit HTTP 403. |
| 2079 APK | Jüngstes öffentlich gefundenes Test-Release. Zeitpunkt und Verfügbarkeit sind getrennt vom Ergebnis des jeweiligen Emulatorlaufs zu bewerten. |

## Freigabematrix

| Umfang | Stand | Nachweis oder offene Abnahme |
| --- | --- | --- |
| Diagramme im Sachunterricht | INTEGRIERT, GERÄTEPRÜFUNG OFFEN | Beobachtete Null im Igel-Beispiel explizit mit Null und ohne Kästchen. |
| Laufzeitdaten im Export | INTEGRIERT, GERÄTEPRÜFUNG OFFEN | Vertrag für alle Exportprofile. Der Android-Workflow prüft die tatsächlich eingebetteten JSON-Daten und Tiermodelle. |
| Adaptive Lernhilfe, Eltern und Schule, Profile | INTEGRIERT, GERÄTEPRÜFUNG OFFEN | Fachtests, Kennzahlen, Lernen mit lokalem Profil und Sicherung im Kandidaten wiederholen. Keine gemessene Lernverbesserung ableiten. |
| Kart-Rivalen auf Dschungelherz, Tunnel und Turbo | FEHLERHAFT | Bekannte Ausfälle in der 2083-Basis. Reparatur und ganze Rennläufe sind Freigabepunkte. |
| Fahrzeuglack, Garage und Rückkehr aus dem Rennen | FEHLERHAFT | 2083 als Ausgangspunkt. Vollständige Fahrzeugmodelle und Werkstatt in der echten Oberfläche sowie Rückkehr prüfen. |
| World-Kart, Missionen und Sonnenhafen | FEHLERHAFT | Bodenkontakt und Wiederherstellung aus älteren Spielständen prüfen. Das Quellinventar hat 15 Missionen und drei separate Botengänge. |
| Waldheim und Ausbau auf 30 Missionen | NICHT IMPLEMENTIERT | Waldheim ist als Ziel vorgesehen. Das Soll von 30 vollständig geprüften Missionen ist offen. |
| Fahrzeug-, Teile- und Effektausbau | NICHT IMPLEMENTIERT | Zielgrößen 24 Fahrzeuge und neue Teilekategorien erst nach Laufzeit- und Modellprüfung ausweisen. Die 14 vorhandenen Meshy-Karts bleiben im Bestand. |
| Übrige Spiele | INTEGRIERT, GERÄTEPRÜFUNG OFFEN | Starts, volle Spielrunden, Rückwege und Fortschritt je Route getrennt erfassen. Ein Start zählt als Startbeleg. |
| Galaxy Z Fold7, Tablet und thermischer Dauertest | INTEGRIERT, GERÄTEPRÜFUNG OFFEN | Bildschirmformate in Software prüfen. Für FPS, Speicher und Thermik sind Messungen am physischen Gerät erforderlich. |
| Signiertes Android-Update | FEHLERHAFT | 2083 erreichte die Android-Stufe nicht. 2084 erhält einen neuen, exakten Flutter-/Godot-Pin und prüft `dev.ullmann.lumo.lumo_lernen.coachpreview`, ARM64 und das vorhandene Familienzertifikat. |

Die Einträge beschreiben den Stand vor dem Zwischenbuild. Testergebnisse für den neuen Stand müssen mit genau seinem APK-Quellpin verknüpft werden.
