# LUMO: zusätzliches Drei-Agent-Team – gemeinsamer Kandidat 2071

Stand: 23. November 2026.

## Auftrag und tatsächliche Zusammenarbeit

Heinz beauftragte diese Sitzung, den vorherigen LUMO-Entwicklungsbericht mit drei zusätzlichen Agents zu unterstützen. Diese drei Agents bearbeiten Logikspiele, Darstellung und Bewohneraufträge. Root führt ihre Ergebnisse mit den laufenden Hauptteam-Änderungen über gemeinsame Git-Quellen und PRs zusammen. Eine direkte Verbindung zwischen zwei Chat-Laufzeiten wird nicht behauptet.

Hauptteam: Flutter `47c1a6437aee4320598f3ead58be76b50934567f`, Godot `90648b0639391c88d3c2da0e3f235d30f725256d`. Die Supportzweige heißen `support/logic-world-team-b-20261123`; Ziel ist `feature/logic-world-20261123`. [Flutter #539](https://github.com/Ullmann27/lumo-lernen/pull/539), [Godot #211](https://github.com/Ullmann27/lumo-godot/pull/211), [Koordination #537](https://github.com/Ullmann27/lumo-lernen/issues/537). Main bleibt unverändert.

## Spielbare Ergänzungen

- **Pfotenpfad:** 24 deterministische Wegrätsel, sechs je Schulstufe. Das Kind plant Pfeile, besucht nummerierte Sterne und erreicht das Picknick. Tatsächliche Simulation prüft Rand, Hindernisse und Reihenfolge; verschiedene gültige Wege sind erlaubt.
- **Direkte Spielwahl:** Vier große Einstiegsknöpfe stehen vor dem Titelbild. Alle vier Spiele bleiben bereits auf dem ersten Bildschirm erreichbar, auch auf 344 px Breite und im kurzen Querformat mit großer Schrift. Die bisherigen Detailkarten und Spielwege bleiben erhalten.
- **Vier Logikspiele:** Die bisherigen 144 Sudoku-, Wort- und Matheaufgaben bleiben erhalten. Pfotenpfad ergänzt sie auf 168 Aufgaben.
- **Telefonbedienung:** Bei normaler Schriftgröße bleiben auf schmalen Telefonen das vollständige Brett und die vier Pfeile zusammen sichtbar. Klassen-/Pfadwahl und vollständige Hinweise sind über klar benannte Bereiche erreichbar; der Plan lässt sich horizontal durchsehen. Die Speicheranzeige verändert die Bretthöhe nicht. Größere Schrift behält die vollständig scrollbare Darstellung.
- **Profile:** Auswahl, Programme und Abschlüsse sind je Kind getrennt. Backup, Profilreset und Gesamtrücksetzung berücksichtigen die neuen Daten; verspätete Aktionen behalten ihre ursprüngliche Profilzuständigkeit.
- **Weltkarte:** Gleicher Maßstab in beiden Achsen, Standort, Blickrichtung, Ziel und vier Orte. Große Schaltflächen bieten Ziel-, Orts- und Weltfokus; ausführliche Hinweise bleiben scrollbar.
- **Freundepost:** Drei Lieferungen Nelli → Bruno → Tilda → Nelli nach den sechs Hauptmissionen. Paket am Fuchs beziehungsweise Kart, tatsächliche Nähe und Interaktion bei der Übergabe, drei gespeicherte Freundschaftsstempel.
- **Ampel und Speichern:** Bedienung von beiden Gehsteigen auch nach der Hauptgeschichte. Wiederholtes Drücken verlängert die Wartezeit nicht. Fehlgeschlagenes Speichern wird erneut versucht; unbekannte zukünftige Freundepost-Daten bleiben erhalten.
- **Gemeinsame World-Korrekturen:** Normale Kamera mit freiem Blick, echte HUD-Mindestgrößen, Joystick neben der Aktionsspalte, begehbarer Schuleingang und kleiner Wegweiser. Die Originalaufnahmeorte bleiben erhalten.

Original-Schatzsuche, vorhandene Dorfökonomie, Schreibtrainer, Journal und bestehende Lernstände bleiben angeschlossen.

## Belegte Prüfungen und Grenzen

Der ursprüngliche Supportstand Flutter `404d6bcaaff0ac47bf1326551381110126daf9e4` / Godot `93557b3ca206916a39fdeaa6ae6ce05442b08846` bestand [Supportlauf 45181487860](https://github.com/Ullmann27/lumo-lernen/actions/runs/45181487860): Flutter-Analyse, 53 Flutter-Tests, 20 JAR-Helfertests sowie World 169, Freundepost 289, Controller 22, World-Integration 27 und Kartenrenderer 152 Prüfaussagen.

Sein [vollständiger APK-Bauversuch 45181487984](https://github.com/Ullmann27/lumo-lernen/actions/runs/45181487984) bestand 119 JVM-Tests, 180 Flutter-Tests und die World-/Renderer-Prüfungen, scheiterte beim erneuten kalten Fontimport. Die tatsächliche Sichtprüfung bestätigte verdeckte Fahransichten und angeschnittene Aktionsknöpfe. Dieser 2070 wird ausdrücklich nicht als fertige oder freigegebene APK ausgegeben. [Vollständiger Befund](TEAM_B_2070_QUALITY.md).

Der serialisierte Ressourcenimport wurde mit Godot 4.6.3 untersucht und anschließend im vollständigen CI-Import von `7c6e728b1c0ec45d7098855c205bba6dfc50c190` erfolgreich ausgeführt: 2.089 Imports einschließlich aller drei Nunito-Schriften, keine Importfehler. Die danach gefundenen Typfehler gehörten zum älteren Hauptteam-Zwischenstand und sind im übernommenen `90648b0` korrigiert. Alle Fehlergates bleiben aktiv; eine PASS-Zeile mit vorherigem Compile-Fehler gilt nicht als Erfolg.

Der JAR-Helfer behält den festgelegten SHA-256 bei und verwendet einen gemeinsamen geprüften Cache, begrenzte Wiederholungen sowie die bekannten Maven-Endpunkte. Er verändert keine Android-Produktlogik.

Der neueste kombinierte native Stand `e0460c0b3eda9d42e9d963eb2236dc8d9c7b5913` besteht [Supportlauf 45186770272](https://github.com/Ullmann27/lumo-lernen/actions/runs/45186770272) vollständig mit Godot 4.6.3: World **194**, Freundepost **289**, Controller **22**, World-Integration **27**, HUD **499** und Kartenrenderer **152** Prüfaussagen. Flutter am zugehörigen Zwischenstand `02d674daa65d13d2517a005943cd86db1ff5636b` besteht 53 Tests und die Analyse. Die spätere kompakte Telefonansicht und der vollständige APK-/Android-Kandidat müssen separat geprüft werden.

Der Zwischenstand `af1b15a690ff34f5c9de7e1cbf155ff050156a97` bestand [45190521155](https://github.com/Ullmann27/lumo-lernen/actions/runs/45190521155) vollständig: 61 Flutter-Tests, Analyse ohne Befund und alle nativen Prüfungen. Die neuen Telefonaufnahmen zeigen vollständiges Brett und Steuerung sowie das echte Auswahlsheet. Root entdeckte dabei die kontrastarme weiße Los!-Beschriftung auf `#95FF79`; der Farbkontrast beträgt rechnerisch etwa 1,246:1. Der minimale Fix lässt die Beschriftung den bereits vorhandenen Button-Vordergrund `#071C38` erben (etwa 13,681:1); deaktivierte Zustände erben ihre eigene vorgesehene Farbe. Die gemeinsame LogicAction-Komponente, Geometrie und Spiellogik bleiben unverändert. Der Vorläuferauftrag47/Lauf45190521151 wird vor Veröffentlichung durch Auftrag48 ersetzt. Kein neuer Runtime-PASS wird vor Ausführung behauptet.

## Kandidatenidentität und ausstehende Freigabe

Neuer gemeinsamer Kandidat: **0.14.2+2071**, Bauauftrag **48**, Godot **e0460c0b3eda9d42e9d963eb2236dc8d9c7b5913**, Engine **4.6.3**. Der jeweils tatsächlich gebaute Flutter-Commit steht in der Build-Provenienz.

Die neue Quelle muss alle Prüfungen erneut bestehen: Flutter/JVM, echte Godot-Quellen und Rendereraufnahmen, signierte ARM64- und x86_64-Pakete mit gleichem PCK und Zertifikat, World und HUD gegen das extrahierte APK-PCK, installierte Android-Tour, native Starts und Android-SAF-Sicherung mit Wiederherstellung. Die fünf World-Aufnahmen werden vor dem APK-Bau bereitgestellt und tatsächlich angesehen. Ein bestätigter Sichtfehler stoppt die Auslieferung.

Es wird weder eine fertige 2071-APK noch ein bestandener Android-Rundgang vor dessen tatsächlichem Ergebnis behauptet. Die bestehende installierte Android-Tour prüft Onboarding, Lernatelier, Kartfahrt, Rückkehr und Erhalt des Lernstands; die native Startdiagnose prüft außerdem Lumo World. Pfotenpfad wird gezielt durch Domain-, Speicher-, Widget- und PNG-Tests geprüft, jedoch von dieser vorhandenen Android-Tour nicht geöffnet. Ein grüner Tourlauf wird daher nicht als Android-Prüfung seiner einzelnen Bedienabläufe bezeichnet. Physische Fold-7-Messung und stabile 60 FPS sind offen.

## Fortsetzung

Den exakten Kandidatenlauf bis zu seinen echten Ergebnissen verfolgen. Nur konkrete verbleibende Fehler korrigieren und keine Gates abschwächen. Den öffentlichen Direktlink erst nach vorhandenem Release-Asset, Dateigröße, SHA-256, Quellidentität und Signaturnachweis ausgeben. Die historische HTTP-403-Antwort am Release-Endpunkt bleibt ein möglicher tatsächlicher Veröffentlichungsblocker; keine Berechtigung umgehen.

Endergebnisse in #538/#539, Godot #210/#211 und #537 vermerken. Main bleibt geschützt.
