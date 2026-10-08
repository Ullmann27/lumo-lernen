# Lumo – Runtime-, Grafik- und Android-Paket vom 8. Oktober 2026

**Status: VISUAL_GAP / NOT FINISHED.** Dieses Paket repariert belegte Kontakt- und
Speicherfehler und erweitert die Abnahme auf eine vollständig gefahrene Runde.
Es ersetzt weder die bestehende App noch die Godot-Architektur. Ein bestandener
Engine-Test ist keine bestätigte APK-Installation, Referenzgleichheit oder
60-FPS-Freigabe. Die mit **PENDING** bezeichneten Commit-/Buildfelder müssen nach
dem tatsächlichen Abschluss durch die jeweiligen Originalergebnisse ersetzt werden.

## 1. Aktueller Quellstand und Koordination

| Ebene | Verifizierter Ausgangspunkt / Status |
| --- | --- |
| App-Repository | `Ullmann27/lumo-lernen` |
| App `main` bei der Bestandsprüfung | `90c239898c2f5fe7230dda05cb9e499069162208` |
| Aktiver Vorgänger | [App PR #214](https://github.com/Ullmann27/lumo-lernen/pull/214), `codex/lumo-reference-app-2026-10-08` |
| Zunächst gelesener App-Head | `9f2dafd51332cc54f02e7ce309b02e0a78d39c51` |
| Tatsächliche App-BASE nach frischem Fast-forward | `d35f8793b4de65902ba29c592d5f7a3fbd9b628d` |
| Änderung zwischen diesen App-Basen | Vorhandener Kreativspiel-Prüfer erkennt die aktuelle Kart-Beschriftung `SPEED` statt `BOOST`; eigene Änderungen bleiben erhalten |
| App-Arbeitsbranch | `codex/lumo-runtime-apk-2026-10-08` |
| App RESULT SHA / PR | **PENDING – erst nach Commit / PR-Erstellung eintragen** |
| Godot-Repository / BASE | `Ullmann27/lumo-godot`, `d2ebb85d0dcfeec690c18b7d35135a66f472b170` |
| Godot-Arbeitsbranch | `codex/lumo-race-continuity-2026-10-08` |
| Godot RESULT SHA / PR | `4d4bd2ba3ac2b956d35ec74dacbad766199e9f9c`, [Godot PR #28](https://github.com/Ullmann27/lumo-godot/pull/28); veröffentlichter Kandidat mit dem lokal geprüften Baum |
| Vorgesehener finaler Godot-Pin | `config/godot-source.json`: `4d4bd2ba3ac2b956d35ec74dacbad766199e9f9c`; Root setzt diesen veröffentlichten Kandidaten vor dem gemeinsamen Bau, tatsächlichen PCK-Inhalt danach prüfen |
| Engine / CI-Flutter | Godot `4.6.3.stable.official.7d41c59c4`; Workflow verwendet Flutter `3.44.9` |
| Geplanter APK-Kandidat | `0.12.1+1901`; Version im Arbeitsstand, noch kein Buildnachweis |
| Merge / Release | Nicht Bestandteil dieses Pakets |

Vor Änderungen wurden aktuelle Branches, offene PRs, Projektanweisungen,
Übergaben und Claims gelesen. Der Paket-Claim wurde auf App PR #214 und Godot
PR #27 abgestimmt. Bestehende fremde Arbeitsbereiche bleiben getrennt.
`CODEX_START.md` bezeichnet `OPUS_NEXT.md` ausdrücklich als historisch; zusätzlich
wurden die Übergaben vom 8. Oktober und der neuere Referenz-App-Handoff gelesen.
Ältere SHAs aus Berichten wurden nicht als aktive Heads übernommen.

App-Quellstand, Godot-Head, App-Pin und tatsächlich im APK eingebetteter PCK sind
vier getrennte Nachweise. Ein neuer Godot-Commit erscheint erst nach Pin-Änderung,
Export und geprüftem gemeinsamen Bau in der APK. Die hochgeladenen älteren
HTML-/ZIP-Prototypen wurden nicht zum Ersatz für die aktive Runtime gemacht.

## 2. Kurze Bestandsmatrix

| Bereich | Bestand / belegter Befund | Status dieses Pakets |
| --- | --- | --- |
| Flutter-App, Profil, Lernmodule, Spielezugang | Vorhanden im aktiven App-Zweig | Bestehende Architektur erhalten; volle Kandidatenprüfung **PENDING** |
| Godot-Auswahl, Garage, zwölf Welten, fünf Modi | Vorhanden; Menü-, Fahrzeug- und Streckenregressionen vorhanden | Keine neue Parallel-Demo |
| Lumo / Kart / Arme | Echte Runtime-Meshes; Hände verließen bei Lenken den bewegten Lenkradkontakt, Ärmel-/Handanschluss war unzureichend | Bestätigter Kontaktfehler korrigiert; lokale Geometrie- und Bildnachweise **PASS** |
| Referenzidentität / Materialien / Licht | Orangefarbener Fuchs, navy/cyan Markenwelt und bestehende Bilder vorhanden | **VISUAL_GAP**; keine identische Referenzrekonstruktion bestätigt |
| Fahrmodell | Freie Lenkung, Gas/Bremse/Rückwärtsfahrt, Drift, Speed, Rails, Sprünge, sichere Rücksetzung und geordnete Tore vorhanden | Bestehende Physik erhalten; Flugzustand bei manueller Rücksetzung korrigiert |
| Items bei Grafik-Rebuild / Neustart | Verbrauchte Prismen erschienen erneut; Gegner-Items und Effektzeiten gingen beim Wiederöffnen verloren | Auf Basis reproduziert; lokale Reparaturregression **PASS** |
| Gegner / Sprünge / Looping | Vorhandene Gegner fahren Strecke; eigene Arc-Darstellung vorhanden | Vollständige ballistische Gegner-Sprünge und unterbrochene Flugpersistenz offen; Loopings bleiben gesperrt |
| Touch / Pause / Resize | Mehrfinger-Controls, Release außerhalb, Pause und Layoutprüfungen vorhanden | Desktop-Engine-Nachweise vorhanden; neue Android-Matrix **PENDING** |
| Flutter → Godot | Startschutz bereits vorhanden; fehlende erneute Prüfung nach spätem Wallet-Await | Enger Guard ergänzt; gezielter CI-Negativ-/Positivbeweis **PENDING** |
| Ergebnis / ACK / Belohnung | Native durable Queue, Ergebnis-ID und Belohnung im selben Wallet-Snapshot | Erhalten; vollständiger nativer Ablauf lokal **PASS**; echter Android-Replay **PENDING** |
| Vollständige Rennrunde | Alter Android-Prüfer startete und verließ nur ein unvollendetes Rennen | Neuer vollständiger Android-Prüfer vorbereitet; noch kein Android-Erfolg gemeldet |
| CPU/GPU / Speicher / Wärme / physisches Fold | Keine aktuelle Produktionsgerätemessung | **NOT EXECUTED**; keine 60-FPS-Zusage |
| Gemeinsame APK | Buildroute, stabile Signatur, Paket- und PCK-Verifier vorhanden | Neue APK **PENDING**; keine Datei/Hash vor tatsächlichem Bau |

## 3. Kleines zusammenhängendes Reparaturpaket

### Kontakt und lebendige Figur

`scripts/games/kart_vehicle.gd` erhält den vorhandenen Lumo, seine Farben,
Fahrzeuge und Animationen. Die vorhandenen Handschuh-Meshes folgen den tatsächlichen
Kontaktpunkten des bewegten Lenkrads, einschließlich Lenkung, Drift und Boost.
Beim vorhandenen Jubel darf die rechte Hand sichtbar loslassen; danach kehren
beide Hände zum Lenkrad zurück. Der Ärmel wird als geeignetes Mesh mit realem
Manschettenring bis zur Hand geführt. Die reduzierte Geometrie behält den Anschluss.

Der Kontakt wird an den echten neutralen Weltkontakten und tatsächlichen
Mesh-Vertices gemessen, nicht allein an Solver-Zielwerten. Bestehende Material-
Bündelung, LOD und Bewegungsreduktion werden weiterverwendet. Das ist eine
belegte Kontaktverbesserung, noch keine vollständige Anatomie-/Rig-Abnahme.

### Unveränderte Rennidentität über Grafikwechsel und Rückkehr

`scripts/games/kart_island.gd` bewahrt den Verbrauchsstatus der Item-Prismen über
den bestehenden Grafik-Rebuild und schreibt ihn in den vorhandenen ConfigFile-
Spielstand. Beim Wiederöffnen stimmt die sichtbare Verfügbarkeit sofort wieder.
Die nächste legitime Runde stellt den Gegenstand weiterhin regulär bereit.

Gegner-Items sowie Stun-, Cooldown-, Boost-, Schild- und Warnzeiten werden mit
gespeichert und sichtbar wiederhergestellt. Nur bekannte Item-IDs und endliche
Zeiten innerhalb der bestehenden Spielgrenzen werden akzeptiert. Fehlende oder
ungültige optionale Werte älterer Versionen werden neutral behandelt. Während
Pause bleiben die gespeicherten Warnzeiten angehalten. Die additive Änderung
erhält die Lesbarkeit der bestehenden Spielstandversionen 1–4; früher nie
gespeicherte Informationen lassen sich nachträglich nicht rekonstruieren.

Ein echter manueller Reset während eines Rampenflugs beendet jetzt auch
`airborne`, `vertical_speed` und `air_time`. Die vorhandene sichere Straßen- und
Checkpoint-Platzierung bleibt erhalten. Ein unterbrochener Flug darf damit
keine Landung und keinen Landungsturbo vortäuschen. Details und Baselinefehler:
`lumo-godot/docs/RACE_CONTINUITY_2026-10-08.md`.

### Letzter Startschutz vor dem Android-Aufruf

`lib/features/lumo3d/lumo3d_launcher.dart` prüft Seite, Route, Reset und
Profilgeneration erneut, nachdem Lifetime-Sterne geladen wurden. Dieses zweite
Storage-Await lag bislang hinter dem vorhandenen Lebenszyklus-Guard. Ein später
aufgelöster alter Start darf kein Spiel mit inzwischen gewechseltem Profil öffnen.

Der neue Test verzögert den tatsächlichen Preferences-Plattformschreibvorgang
der ersten Wallet-Ladung, wechselt die Profilgeneration und prüft sowohl die
Absage als auch einen danach erlaubten neuen Start. Keine produktive
Test-Injection und keine Lockerung vorhandener Tests. Da lokal Flutter fehlt,
reproduziert CI den spezifischen neuen Fehler zunächst mit dem unveränderten
Launcher aus App-BASE und stellt danach den Kandidaten wieder her. Ein beliebiger
Testfehler zählt nicht als Negativbeweis: der Workflow verlangt die konkrete
`Expected: false` / `Actual: true`-Assertion samt zugehörigem Grund.

## 4. Ausgeführte Prüfungen und tatsächliche Grenzen

| Prüfung | Ergebnis / Umfang |
| --- | --- |
| Python Android-Prüfwerkzeuge | 204 Tests bestanden (`Ran 204 tests in 7.008s`, `OK`; keine Skip-Annotation) |
| Python Build-/Vorbereitung | 9 Tests bestanden |
| Backend | 22 Tests bestanden, 0 übersprungen |
| Lenkradkontakt | 11.700 Messungen, 0 Fehler, größte Abweichung 0,2777 mm |
| Ärmel-/Handkontakt | 6.240 Prüfungen; mindestens 9 von 20 Manschetten-Vertices innerhalb der Hand, reduzierte Geometrie mindestens 3 von 8 |
| Kontaktmatrix | Neun Lumo-Karts, fünf Fahrer, zwei Detailstufen, reduzierte Bewegung, Lenken/Drift/Boost und Jubel-Loslassen/-Rückkehr |
| Race-Continuity Negativbeweis | Unveränderte Basis scheitert getrennt an Rebuild, Verbrauchsspeicherung, Gegnerzuständen und Flug-Reset |
| Race-Continuity Reparatur | Fünf Szenariogruppen bestanden: Rebuild/nächste Runde, Save/Reopen, Gegner/Pause, Legacy/ungültige Felder, Flug-Reset |
| Bestehende Physik-/Sprung-/Race-Bridge-/Kartregression | Lokal mit unveränderten Prüfanforderungen bestanden |
| Neuer vollständiger Engine-Ablauf | Echter Menü-Touch, Gas/Joystick-Drag, Pause, gespeicherte Rückkehr, neue Szeneninstanz, Weiterfahren, 16 geordnete Tore / 2 Runden, Ziel, Ergebnis, ACK, erneuter Start bestanden |
| Ergebnis dieses Engine-Ablaufs | Sonnenhafen / Lumo / Comet, 82,8 **simulierte** Sekunden, 0 Resets, 3 Sterne, genau 1 raw Host-Reward-Aufruf |
| Flutteranalyse / neue Launcher-Regression / volle Suite | **PENDING in CI; lokal NOT EXECUTED** |
| APK-Bau / Provenienz / Installation / komplette Android-Runde | **PENDING in CI; lokal NOT EXECUTED** |
| Physisches Fold / Geräte-CPU/GPU / Input-Latenz / Speicher-Soak | **NOT EXECUTED** |

Die Engine verwendet unter Linux Godot 4.6.3 und Mesa/llvmpipe. Für den vollständigen
Engine-Test werden echte Touch-/Drag-Ereignisse verarbeitet und Physikschritte
mit 1/60 Sekunde ausgeführt. Distanz, Checkpoints und Finish werden nicht gesetzt
oder teleportiert. Die Beobachtungssteuerung liest die vorhandene Straßenkurve.
Der Host ist hier ein kontrollierter Test-Host; der Lauf beweist nicht bereits
Androids AtomicFile-Queue oder Flutter-Import im gebauten APK.

Die 82,8 Sekunden sind Rennsimulationszeit. Der 1/60-Schritt ist kein gemessener
60-FPS-Durchsatz. Aus den Renderbildern wird weder GPU-Zeit noch Touch-Latenz
abgeleitet. Warnungen zu V-Sync, Screen-space-AA und volumetrischem Nebel bei
Compatibility bleiben im Rohprotokoll sichtbar; ein Renderbild bestätigt nicht
die Verfügbarkeit dieser Funktionen auf diesem Renderer.

## 5. Echter Android-Gesamtablauf: neuer Prüfpfad

`.github/probes/kart_complete_android_probe.py` ergänzt den vorhandenen
Kreativspiel-/Fold-Prüfer. Der neue Lauf verwendet ausschließlich echte Android-
Eingaben: neues Rennen aus dem Menü, öffentliche automatische-Gas-Option,
Pause/Fortsetzen und Rückkehr. Private Spielstände, Ereignisse und Preferences
werden ausschließlich gelesen. Kein Score, Fortschritt, Resultat, ACK oder
Freischaltung wird injiziert.

Das vorhandene leichte Fahrmodell und Rail-Verhalten können Sonnenhafen mit
neutralem Stick regulär beenden. Ein separater lokaler Pilot bestätigte dies,
mit zahlreichen Rail-Kontakten. Dieser Weg dient der vollständigen Android-
Lebenszyklusprüfung, nicht der Abnahme präziser Lenkung, fairer Gegner oder
visuell eleganter Linien. Der separate Engine-Lauf fährt mit tatsächlichem
analogen Lenken und Gas.

Der neue Android-Prüfer verlangt identische Quell-/APK-Provenienz, beobachtete
erste und zweite Runde, alle 16 Tore, nativen Ergebnis-Screen und Host-Ereignis,
exakte Walletänderung, Offline-Wiederanlauf, erneutes Öffnen desselben abgeschlossenen
Ergebnisses, Rückkehr und dedupliziertes ACK. Screenshots und Video unterscheiden
Phone-, Fold- und Ergebniszustände. Auch fehlende oder unbrauchbare Aufnahmen
dürfen keinen visuellen PASS erhalten. Das neue Verfahren ist vorbereitet;
seine tatsächlichen API-35-/API-36-Ergebnisse bleiben bis zum CI-Abschluss **PENDING**.

## 6. Dateien, Quellen und reale Belege

Godot-Produktdateien: `scripts/games/kart_vehicle.gd`, `scripts/games/kart_island.gd`.
Neue fokussierte Engine-Prüfer: `kart_steering_grip_regression.gd`,
`kart_arm_contact_regression.gd`, `kart_steering_grip_capture.gd`,
`kart_race_continuity_regression.gd`, `kart_complete_flow_regression.gd` unter
`scripts/tests/`. Vorhandene Physik, Welt, Kollision, Menüs, HostBridge, LOD,
Material-Bündelung und Save/ACK-Architektur werden wiederverwendet.

App-Produktänderungen: Launcher-Guard, höhere Kandidatenversion und nach
akzeptiertem Godot-Commit dessen Pin. App-Prüf-/Builddateien:
`test/lumo3d_launcher_lifecycle_test.dart`,
`.github/probes/kart_complete_android_probe.py`,
`tools/android_qa/tests/test_kart_complete_android_evidence.py`,
`.github/workflows/lumo-runtime-apk.yml` und dieser Handoff. Den vollständigen
finalen Diff erst aus den Ergebnis-Commits übernehmen.

Offizielle Godot-4.6-Dokumentation für die erhaltene Speicherarchitektur:
[ConfigFile](https://docs.godotengine.org/en/4.6/classes/class_configfile.html)
für Variant-Speicherung, Defaults und Save-Semantik sowie
[DirAccess](https://docs.godotengine.org/en/4.6/classes/class_diraccess.html)
für absolute `user://`-Pfade und vorhandenes temporäres Speichern/Umbenennen.
Die Lösungen passen vorhandenen Projektcode an. Kein externer Spielcode,
fremdes Figurenmodell oder fremde Spielwelt wurde übernommen; keine zusätzliche
Produktabhängigkeit ist für die Reparaturen notwendig.

Reale Engine-Artefakte dieses Arbeitsstands liegen in Godot unter
`exports/complete-flow/`: Startaufstellung, Pause, wiederhergestelltes Rennen,
Ergebnis, wiedergeöffnete Garage und `evidence.json` mit jeder Torpassage.
Kontakt-/Vorher-/Nachher-Aufnahmen und Rohprotokolle bleiben getrennt.
CI sichert die Aufnahmen und den exakt getesteten Quellstand als Artefakte.
Vor dem Commit erzeugte lokale Bilder werden nicht als APK-Bilder ausgegeben.

Heinz' konkrete Video-Referenz ist
[Mario Kart World – Mushroom Cup (Full Race Gameplay)](https://www.youtube.com/watch?v=-euI313vamw).
Der Seitentitel wurde geprüft; der Medienabruf ist blockiert. Tatsächliche
Videoframes: **NOT EXECUTED**. Rohbericht:
`tools-runtime/youtube-reference/reference-access-report.json` im Arbeitsraum.
Daraus folgt **kein**
belegter Bild-für-Bild-Vergleich. Die vorhandenen Lumo-Referenzbilder unter
`docs/design_targets/2026-10-04/`, `docs/design_targets/2026-10-08-kart-fahrzeuge/`
und `assets/lumo_design/` bleiben verbindlich. Fremde Markenfiguren/Welten werden
nicht kopiert.

## 7. APK- und CI-Abschlussfelder

| Nachweis | Status bis tatsächliche Ergebnisse vorliegen |
| --- | --- |
| App RESULT SHA | **PENDING** |
| Godot RESULT SHA / zu prüfender PCK-Pin | `4d4bd2ba3ac2b956d35ec74dacbad766199e9f9c`; tatsächlicher APK-Inhalt **PENDING** |
| CI-Run / Jobs / Original-Testzahlen und Skips | **PENDING** |
| APK-Datei / Bytegröße / SHA-256 | **PENDING** |
| Paket / versionCode / versionName | **PENDING – erwartetes Preview-Paket, 1901 / 0.12.1 gegen echten APK-Inhalt prüfen** |
| Signaturzertifikat / arm64-v8a und x86_64 / 16-KiB-Ausrichtung | **PENDING – bestehende Verifier auf neue APK ausführen** |
| PCK-Commit / PCK-SHA / sauberer App- und Godot-Quellstand | **PENDING** |
| Update ab geprüfter 1602, Profilerhalt, Offline-Neustart | **PENDING** |
| Vollständige Android-Runde und Ergebnis-/ACK-Replay API 35 / 36 | **PENDING** |
| Downloadbare APK-/Bild-/Video-Artefakt-IDs | **PENDING** |

Der vorherige 1900-Lauf
[37779313196](https://github.com/Ullmann27/lumo-lernen/actions/runs/37779313196)
wurde abgebrochen; dessen frühere App-/Native-Render-Artefakte sind kein Erfolg
des neuen Builds. Der geprüfte 1602-Lauf
[37683619818](https://github.com/Ullmann27/lumo-lernen/actions/runs/37683619818)
ist historischer Vergleich, keine automatisch vererbte Gerätefreigabe des
neuen Kandidaten. Ebenso ist der 1701-Lauf mit einem fehlgeschlagenen
Kreativspiel-Szenario kein vollständig grüner Nachweis für alle neuen Abläufe.

## 8. Offene Abweichungen und nächster Integrationsschritt

**VISUAL_GAP:** Der Lenkrad-/Manschettenkontakt ist korrigiert, die gesamte
Lumo-Figur aber noch nicht als identisch mit Heinz' Referenzen abgenommen.
Ein vollständig ausgearbeitetes, referenztreues Produktionsmodell samt
Gelenk-/Haut-Rig, überzeugendem Fell/Stoff/Gummi/Metall/Glas und gesamter
Beleuchtungs-/Kameraabstimmung bleibt ein eigener überprüfbarer Arbeitsblock.
Vorhandene echte Meshes und lokale Kontakt-Lösungen werden nicht als fertiges
Produktionsasset oder vollständige Animationsabnahme umgedeutet.

**Gameplay-/Kameralücken:** Ballistische Gegner-Flüge, unterbrochene Flugzustände
über Offline-Neustart, pausegenaue kosmetische Gegneranimation, Landeflächen- und
Tunnelkamera auf echten Android-Flächen sowie tatsächliche Touch→Physik→Feedback-
Latenz sind weiter zu prüfen. Loopings/Wand-/Schienenfahrten bleiben gesperrt,
bis der gesamte Kontakt-/Steuerungs-/Gegner-/Respawn-Pfad funktioniert.

**Performance-/Gerätelücken:** Physisches Galaxy Fold außen→innen→außen in
Menü/Rennen/Pause/Ergebnis, langfristige Stabilität, Speicher/Wärme und getrennte
CPU-/GPU-Framezeiten fehlen. Emulatorresize ist kein physischer Fold-Test;
Software-Renderings sind kein Android-FPS-Nachweis. Keine 60-FPS-Zusage.

Nächster konkreter Integrationsschritt: App-Pin auf den veröffentlichten und
lokal geprüften Godot-Commit `4d4bd2ba3ac2b956d35ec74dacbad766199e9f9c` setzen und den getrennten App-Kandidaten
mit unverändertem Paket/Schlüssel bauen. CI muss den spezifischen Launcher-
Negativbeweis, die volle Flutter-Suite, exakte native Regressionen und die
neuen vollständigen Android-Runden tatsächlich abschließen. Danach originale
SHAs, Hashes, Testzahlen, Fehler/Skips und echte Aufnahmen in die obigen Felder
eintragen, Resultate unabhängig prüfen und den verbleibenden visuellen Abstand
an denselben Referenz-/Runtimeansichten konkret bewerten. Keine automatische
Main-Übernahme oder Release-Veröffentlichung.
