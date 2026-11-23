# Lumo Kart: Strecken, Fahrzeuge und gemeinsames Online-Rennen

Stand: 23. November 2026. Entwicklungszweig: `integration/kart-action-20261123`.

Dieses Paket erweitert den integrierten Stand 0.13.55+2067. Der endgültige
Flutter-Commit, die eingebettete Godot-Revision, APK-Signatur und SHA-256 stehen
in den beim tatsächlichen Bau erzeugten Dateien `BUILD-PROVENANCE.json`,
`APK-VERIFICATION.json` und `SHA256SUMS.txt`. Eine Quellcodeänderung allein
ist kein Nachweis einer installierten oder öffentlich betriebenen Version.

## Strecken

Die gemeinsame Erweiterung ist an alle 15 Produktionsstrecken angeschlossen:
Sonnenhafen, Zauberwald, Himmelsinseln, Holo City, Kristall-Canyon,
Dschungel-Tempel, Candy Cloud Circuit, Volcano Night Run, Winter-Sprint,
Galaxy Ringway, Desert Dune Drift, Funkel-Labor, Dschungelherz, Riesengarten
und Lumos Windwerk.

Zusätzliche Abschnitte verwenden den tatsächlichen Straßen- und Kontaktaufbau:
Panorama-Rampen, verengte Fahrpassagen und alternative Turbospuren werden nur
in geeignete freie Abschnitte eingefügt. Vorhandene Erfahrungen und deren
Schutzkorridore bleiben für die Platzierung maßgeblich. Die sichtbare
Rampenoberfläche verwendet dasselbe Profil wie die berechnete Kontakthöhe.

Themenbezogene Landschaftsgruppen und bewegte Leuchteffekte ergänzen alle
Strecken. Ihre Instanzen werden gebündelt; Entfernungsstufen und die vorhandene
Einstellung für reduzierte Bewegung sind angeschlossen.

Loopings sind befahrbare Abzweigungen mit Zufahrt, vollständiger Loopbahn und
Rückführung. Renderdeck, Kartposition und Kartorientierung beziehen sich auf
dieselbe räumliche Bahn. Die Hauptstraße bleibt als durchgängige Alternative
erhalten. Spieler und Rivalen nutzen ihre tatsächlichen Fahrzeugfaktoren auch
für Gas, Bremswirkung und seitliche Reaktion in der Loopbahn.

Die Sonnenhafen-Sequenz berücksichtigt zusätzlich den Präzisionssprung,
den Tunnel und die tatsächlich erreichbare Fahrzeuggeschwindigkeit.
Eine sichtbar markierte Bremshilfe verwendet die normalen Bremswerte des
montierten Karts. Die Geometrie hält den Landebereich vor dem Tunnel frei;
der Flug selbst erhält keine verdeckte Positionskorrektur. Diese anspruchsvollere Fahrprüfung benötigt einen echten
GL-Renderer; ein Aufruf mit `--headless` erfüllt ihre Voraussetzungen nicht.

## Fahrzeuge und Bauteile

Die bestehenden neun Bauteilplätze bleiben erhalten. Neun zusätzliche
Alternativen erweitern den Katalog von 56 auf 65 auswählbare Einträge:

| Platz | Neues Teil |
| --- | --- |
| Motor | Axial-Antrieb |
| Reifen | Performance-Reifen |
| Flügel | Venturi-Flügel |
| Booster | Superkondensator |
| Federung | Adaptive Dämpfer |
| Lenkung | Vector-Lenkung |
| Bremsen | Keramikbremse |
| Getriebe | Doppelkupplung |
| Ballast/Chassis | Carbon-Chassis |

Das Teilemodell berechnet die kombinierten Faktoren für die Fahrphysik.
Die Werkstatt verwendet dieselbe Berechnung und zeigt zwölf Fahrwerte sowie
die Veränderung gegenüber der vorherigen Zusammenstellung. Begrenzungen für
kombinierte Faktoren werden kenntlich gemacht. Ein günstiger Einzelwert
bedeutet nicht, dass ein Teil in allen Disziplinen überlegen ist.

Die 14 vorhandenen Kartmodelle erhalten zusätzliche Front-, Seiten- und
Heckdetails. Neue Teile besitzen eigene sichtbare Geometrie; Aufhängung,
Bremsscheiben und Chassis sitzen an ihren tatsächlichen Montagepunkten.
Die Geometrien werden zwischengespeichert und berücksichtigen die vorhandenen
Entfernungsstufen.

Die vollständige katalogbezogene Wirkung und die Grenzen der Messungen stehen
im Godot-Repository in `docs/kart-action-20261123/VEHICLES.md`. Die Zahl
52.706.752 bezeichnet mögliche vollständige Teileauswahlen. Sie bezeichnet
keine ebenso große Zahl tatsächlich gefahrener Testläufe.

## Gemeinsames Spielen: der konkrete Ablauf

1. Beide Kinder öffnen **Spielen → Lumo Kart → Online**.
2. Jedes Kind wählt beim ersten Mal einen eigenen festen Spielernamen,
   beispielsweise `Alina_04` oder `Zoe_07`. Der Name des Lernprofils wird
   nicht automatisch als Online-Name verwendet.
3. **Freund einladen** öffnet die Eingabe des anderen Spielernamens.
4. Die andere Person erhält eine Freundschaftsanfrage und kann sie ausdrücklich
   annehmen oder ablehnen.
5. Angenommene Freunde bleiben in der Liste. Ihre Online-Präsenz ist sichtbar.
6. Eine eigene **Renneinladung** startet die gemeinsame Rennvorbereitung.
7. Beim Bereitmelden werden die aktuellen Fahrzeuge, Teile und Lackfarben
   erneut abgeglichen. Beide laden dieselbe Strecke und starten nach der
   gemeinsamen Startfreigabe.
8. Im Rennen sind beide Karts und ihre Namensschilder vorhanden. Der Rennstand
   zeigt Platz 1/2 oder 2/2 sowie den relativen Abstand.
9. Das Ergebnis bietet einen eigenen Rückweg zur Online-Lobby.

Die erste Online-Ausbaustufe synchronisiert Start, aktuelle Fahrzeuge, laufende
Positionen, Orientierung, Platzierung, Checkpoints und das gemeinsame
Zielergebnis. Offensive Itemtreffer und physische Zusammenstöße zwischen den
beiden Karts sind noch nicht Bestandteil der Netzwerksynchronisierung.

Nach der erstmaligen Registrierung verbindet sich ein freigegebenes Profil
beim erneuten Eintritt in Lumo Kart automatisch. Eingehende Anfragen werden
auch bei geschlossenem Onlinebereich im Kart-Hauptmenü angezeigt.

Spielernamen, Freundschaften und noch offene Anfragen werden auf dem Server
in SQLite gespeichert. Ein Serverneustart löscht diese Beziehungen nicht.
Der individuelle Zugangsschlüssel bleibt im lokalen Spielprofil; persönliche
Lerninhalte werden für das Rennen nicht übertragen. Die portable lokale
Datensicherung exportiert weder diesen Schlüssel noch eine eingeschaltete
Online-Freigabe.

## Serverbetrieb und Elternfreigabe

Der Internetmodus benötigt einen gemeinsam erreichbaren WebSocket-Server.
Ein lokal erfolgreicher Test und eine gebaute APK ersetzen dessen öffentliche
Bereitstellung nicht.

Die App prüft eine verschlüsselte `wss://`-Adresse und eine ausdrückliche
Online-Freigabe in den Elterneinstellungen. Ohne eingerichteten Server wird
kein erfundener Endpunkt angenommen.

Die vorbereitete Konfiguration befindet sich im Godot-Repository unter
`server/kart_online/render.yaml`: eine Python-Webinstanz in Frankfurt,
ein dauerhaftes 1-GB-Laufwerk und keine automatischen Folge-Deployments.
Der Python-Stand 3.12.16 und die Serverabhängigkeit aiohttp 3.14.5 wurden im
tatsächlichen Serverprüflauf verwendet.

Die Auswahl des Render-Arbeitsbereichs und die Freigabe laufender Kosten
sind ein gesonderter notwendiger Bereitstellungsschritt. Bis zu dieser
Freigabe ist der öffentliche Dienst nicht eingerichtet. Es wurde kein
kostenpflichtiger Server allein durch die Vorbereitung dieser Dateien
angelegt.

## Tatsächlich ausgeführte Prüfungen und reproduzierbare Nachweise

Der native Prüfworkflow ist
`.github/workflows/kart-action-20261123.yml` im Godot-Repository.
Seine Artefakte enthalten den exakten Quellcommit, vollständige Protokolle,
numerische Messdaten und unveränderte PNG-Aufnahmen.

Die Serverprüfung auf Commit
`447ff8956a2942bafae775a9be62edb339f64cca` hat 23 Tests bestanden, darunter
Freundschaftsanfragen, Annahme, Präsenz, aktuelle Teile/Lackfarben beim
Bereitmelden, gemeinsame Ergebnisse und dauerhafte Daten nach Neustart.

Auf demselben Commit sind auch die beiden Workflow-Stufen mit zwei getrennten
Godot-Spielprozessen sowie der echten Kart-Spielszene erfolgreich:
automatischer Wiedereintritt, Anfrage im Hauptmenü, Annahme, gemeinsamer
Rennraum, sichtbares Gegenkart, Namen, Platzanzeige und Verbindungsende.

Diese Nachweise sind in
https://github.com/Ullmann27/lumo-godot/actions/runs/45133703768
verankert. Der Gesamtlauf kann unabhängig davon andere noch fehlgeschlagene
Prüfungen enthalten; einzelne erfolgreiche Stufen werden nicht als grüner
Gesamtlauf ausgegeben.

Reproduzierbare Server- und Clientprüfungen:

```sh
python -m pip install -r server/kart_online/requirements.txt
python -m unittest discover -s server/kart_online -p test_relay.py -v
python scripts/tests/kart_online_two_process.py --godot godot --output proof/online-processes
python scripts/tests/kart_online_scene_probe.py --godot godot --output proof/online-scene
xvfb-run -a python scripts/tests/kart_online_scene_probe.py --godot godot --output proof/online-images --shots
```

Der APK-Workflow wartet vor dem Paketbau auf einen vollständig erfolgreichen
nativen Prüflauf des exakt eingebetteten Godot-Commits. Die tatsächliche
Run-ID und dessen Schlussstatus werden in
`build-proof/NATIVE-KART-SOURCE-QA.json` festgehalten; ein roter oder noch
unbelegter Quellstand wird damit nicht als geprüfte APK veröffentlicht.

Der APK-Workflow verwendet zusätzlich die bestehenden Lern-, Profil-,
Datensicherungs- und Wallet-Prüfungen, überprüft den tatsächlich gepackten
Godot-Inhalt und führt die installierte x86_64-Geschwister-APK durch den
Android-Emulator. Die ausgelieferte Handydatei ist die getrennte ARM64-APK.

Die Entwicklungstests sind keine Messung stabiler 60 FPS auf einem
physischen Android-Gerät. Der Online-Nachweis mit zwei Spielprozessen ist
auch kein unbeobachteter Test auf zwei echten Familienhandys über Mobilfunk.
Solche Aussagen werden erst nach entsprechenden realen Messungen ergänzt.
