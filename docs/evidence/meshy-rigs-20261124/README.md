# LUMO 2078: Meshy-Fahrer und integrierte Gerätefehlerkorrekturen

Stand dieses Quellcheckpoints: 24. November 2026, vor dem neuen vollständigen APK-/Android-Lauf.

## Verbindlicher Quellstand

- Flutter-Ausgangsstand: `a7626c17cb38691a3b3d5a974d84ce274d6acf4b`.
- Veröffentlichter Godot-Commit: `b590322f4ffe881dffbbcc9bc5244a23c997e6b9`.
- Geprüfter Godot-Baum: `6a19273465c9786d64183cc6af5423ed19727b99`.
- Entwicklungszweig in beiden Repositories: `repair/lumo-device-bugs-2078`.
- App-Version: `0.14.6+2078`, Engine Godot 4.6.3, Flutter 3.44.9.

Die ursprünglichen 153 geänderten Godot-Dateien wurden über die verbundene GitHub-Schnittstelle übertragen. Ihre 94.993.886 Bytes wurden gegen die lokalen Git-Blob-IDs geprüft. Der anschließend von GitHub erstellte vollständige Baum ist exakt identisch mit dem geprüften lokalen Integrationsbaum. Der App-Pin verwendet den tatsächlich veröffentlichten Commit.

## Enthaltene Verbesserungen

Die neun ursprünglichen Meshy-Gegner Löwe, Eule, Hase, Eichhörnchen, Schildkröte, Frosch, Otter, Dachs und Katze besitzen je 26 Knochen, zwölf Animationen und drei Detailstufen. Die 27 GLBs, neun Porträts, Originalquellen, Anatomiedaten und Prüfnachweise sind vollständig erhalten. Kart und Kartensalon laden die produktiven Modelle. Der Original-Lumo bleibt der vorhandene Fuchs. Die Dorf-NPCs werden durch diese Modellintegration nicht ersetzt.

Der zuvor separat liegende World-Kamerafix ist ebenfalls enthalten. Bei Wandnähe wird der Blickvorhalt anhand des geglätteten Kameraabstands zurückgenommen; Kopf und Füße bleiben im Bild. Nahe Weltbeschriftungen werden auf 320 mal 34 dp, der Missionsstern auf 48 dp begrenzt. Physische Wegweiser behalten ihre Größe. Der Android-Export nimmt das Produktionsfahrer-Manifest ausdrücklich mit auf.

## Nachgewiesene lokale Prüfungen

| Prüfung | Ergebnis und Herkunft |
| --- | --- |
| Unabhängige GLB-Prüfung | 27 von 27 Dateien; alle aktuellen Datei-Hashes erneut abgeglichen |
| Godot-Rigvertrag | Vorhandener quellgebundener Lauf: 1.558 Prüfungen, 0 Fehler |
| Godot-Produktionsfahrer | Vorhandener quellgebundener Lauf: 8.245 Prüfungen, 0 Fehler |
| Karten-Roster und Porträts | Vorhandener quellgebundener Lauf: 119 Prüfungen, 0 Fehler |
| Export- und Paketidentitätstests | 54 Tests bestanden; vorhandenes `export-tests.log` |
| World-Kamera | Neuer fokussierter Godot-4.6.3-Lauf: 27 Prüfpunkte in drei Viewports |
| Android-Leserserver-Reparatur | 8 gezielte Regressionen und ein vorhandener XML-Parser-Integrationstest bestanden |
| Workflow | YAML und zwölf Shell-Blöcke syntaktisch geprüft |

Die Kameraprüfung verwendete das vorhandene vollständige World-Testprojekt. Alle fünf übernommenen Kamera-/Exportdateien wurden bytegenau verglichen; Details und Hashes liegen im Godot-Verzeichnis `evidence/lumo_kart_art/device_repairs_2078/`. Dies ist kein bereits bestandener Android-Test der neuen kombinierten APK.

## Vorheriger Android-Fehler und Reparatur

Der 2077-Lauf `45342477617` baute erfolgreich, scheiterte aber im Android-Onboarding an `JSONDecodeError: Unterminated string` beim Lesen der Accessibility-Hierarchie. Die bereits vorhandenen drei Versuche waren ausgeschöpft. Ein neuer Python-Client hatte keinen Neustart des unabhängigen UiAutomator-Leseservers erzwungen.

Die Reparatur startet jetzt denselben Leseserver gezielt neu, stellt seine Konfiguration wieder her und verlangt frisches XML. Maximal drei Leseversuche bleiben bestehen. Dauerhafte Transportfehler, falsches XML und fehlgeschlagene Neustarts bleiben Fehler. App und Spielstand werden dabei nicht neu gestartet oder verändert. Der neue echte Android-Lauf muss die Wirkung bestätigen.

## Vollständiger Lieferablauf

`.github/workflows/lumo-2078-device-repair.yml` wird durch die Aktualisierung des 2078-Zweiges ausgelöst. Er prüft den exakt gepinnten kombinierten Godot-Stand einschließlich Kamera- und Leserregression, erzeugt echte Rendereransichten, baut die vollständige APK und prüft Signatur, ABIs, Provenienz sowie alle 27 Modelle im tatsächlichen APK-Paket. Danach folgen Android-Rundgang, native Spielstarts und Sicherung/Wiederherstellung. Erst erfolgreiche Jobs erlauben dem Publisher ein neues Release mit direkter APK-Datei.

Der frühere lokale Bauversuch um 07:43 UTC ist unverändert in `local-build-attempt.json` und `.log` dokumentiert: `flutter` war damals nicht im verwendeten PATH. Inzwischen wurden passende Flutter- und SDK-Installationen in anderen Arbeitsverzeichnissen gefunden, jedoch kein vollständiger lokaler NDK-/Emulator-/Abhängigkeitsbestand bestätigt. Deshalb wird der eingerichtete GitHub-Bau verwendet. Der frühere Uploadstopp ist durch die erteilte Freigabe und die bestätigte vollständige Übertragung erledigt.

Zum Zeitpunkt dieses Quellcommits ist der neue Build noch nicht abgeschlossen. Seine aktuellen Ergebnisse müssen aus dem tatsächlichen 2078-Lauf und dessen unveränderlichen Artefakten übernommen werden. Desktop-Renderer und Emulator belegen keine physische Fold7-Bildrate.

## Erster vollständiger Lauf und korrigierte Testgeometrie

Lauf `45353940191` auf Flutter `099d96adc38760f223165cb396b60e0656c59f84` und dem vorherigen Godot-Pin bestand 27/27 GLBs sowie World 206, World-HUD 939, World-Geräteprüfung 44, Kamera 27, ExtraDrivers 333, SpatialMenu 641 und LAN-Einstieg 78. Danach scheiterte die NeonHome-Testfixture an drei überlappenden Streckenvorschauen. APK, Android und Veröffentlichung wurden deshalb korrekt übersprungen.

Die Fixture hatte nur das Menü auf 1280×720 vergrößert, während das reale Headless-Fenster bei 64×64 blieb. Der korrigierte Test setzt Fenstergröße und Host-Dichte vor der Menüerzeugung. Das Produktlayout bleibt unverändert; alle ursprünglichen 343 Prüfpunkte sind erhalten. Die zusätzliche Prüfung aller 15 Strecken in fünf Handy-/Fold-Konfigurationen besteht mit insgesamt 2.197 Prüfpunkten, keinen Fehlern und Exitcode 0. Der einzige zusätzliche Godot-Blob ist diese Testdatei; die Modelle bleiben unverändert. Siehe `neon-window-matrix.log` und `neon-window-verification.json`.

Der aktuelle Pin enthält diese Korrektur. Der vollständige Lieferablauf wird auf diesem neuen exakt gepinnten Stand erneut ausgeführt.
