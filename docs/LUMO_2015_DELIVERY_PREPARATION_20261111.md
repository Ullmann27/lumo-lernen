# LUMO 2015: gesicherte Auslieferungsvorbereitung

**Vorbereitung, keine Veröffentlichungsfreigabe.** Dieser Arbeitszweig sichert
den geprüften Entwurf des [Releaseworkflows](../.github/workflows/lumo-2015-verified-release.yml).
Es wurde kein PR geöffnet, kein Workflow manuell gestartet, kein Tag angelegt
und keine APK veröffentlicht. Der frühe Berechtigungs-Guard bleibt blockierend.

## Fest gebundener Kandidat

| Zuordnung | Wert |
| --- | --- |
| Flutter / APK-Quellstand | `2718f405e69c193d0121c6f6447fe53769d7c803` |
| Godot | `b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1`, Engine 4.6.3 |
| Version | `0.13.3+2015` |
| Unified-Run | [43024454590](https://github.com/Ullmann27/lumo-lernen/actions/runs/43024454590) |
| Workflow-ID / Ereignis | `385610539` / `pull_request` |
| Vorhandenes ARM64-Artefakt | `lumo-unified-arm64-verified` |
| Vorgesehener Familienkanal | `coachpreview-build-2015` |
| Erforderlicher Dateiname | `Lumo-Lernen-Neu.apk` plus `Lumo-Lernen-Neu.apk.sha256` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Zertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Lokaler Workflow-Vorbereitungscommit | `1f1d102736b936125df66dc39a96acff34fc1e07` |

API-Stand **2026-11-11, 14:10:11 UTC**: Unified-Run `43024454590` ist
`completed/success`. Seine drei Pflichtjobs `verify-and-build`, `android-tour`
und `update-from-2014` sind im Versuch 1 auf exakt `2718f405…` erfolgreich.
Die zusätzliche Android-Garagenprüfung ist weiterhin **nicht bestanden**;
ihre konkrete Bindung und die beobachtete Sperre stehen im folgenden Abschnitt.

## Zusätzlich verpflichtende Originalnachweise der Android-Garage

| Zuordnung | Fest gebundener Wert |
| --- | --- |
| Zusätzlicher QA-Run | [43034616066](https://github.com/Ullmann27/lumo-lernen/actions/runs/43034616066) |
| QA-Quellstand | `a1d581f0b0b392e0bc4ad7d90fd38d14f8d74095` |
| Erforderlicher Versuch | `2` |
| QA-Workflow | ID `414716713`, `.github/workflows/lumo-2015-android-garage-qa.yml`, `pull_request` |
| QA-Job | `existing-apk-garage`; im beobachteten Versuch ID `130572125063` |
| Originalartefakt | `lumo-2015-existing-apk-garage-android-proof` |
| Tatsächlich getestete APK | x86_64, SHA-256 `b863bc25bc07a7ca3fb78ad4fd56a6f816d091f821c5b9af27bfb0a7aecbcb4e` |
| Verlangtes Originalergebnis | `runtime/garage-result.json` im Originalartefakt |

Der QA-Commit ist ausdrücklich **kein APK-Quellstand**. Die App bleibt auf
Flutter `2718f405…` und Godot `b357b2f…` gebunden. Der zusätzliche Validator
wird aus einem eigenen, getrennten `delivery-guard`-Checkout geladen; die
ursprünglichen Build-, Tour-, Update-, Signatur- und Familienkanalregeln bleiben
im unveränderten APK-Source-Checkout.

Der [neue Validator](../scripts/verify_lumo_2015_garage_delivery.py) verlangt
den exakt gebundenen, erfolgreichen Run und Job sowie ein eindeutiges Artefakt
innerhalb der Zeitspanne dieses Jobversuchs. GitHub behält gleichnamige
Artefakte älterer Versuche: Diese werden anhand ihrer Erstellzeit ausgeschlossen,
nicht überschrieben oder als neuer Nachweis verwendet. Der ausgewählte
Artefakt-ID wird heruntergeladen. ID, Archivdigest, Größe, Zeitstempel, Job und
Versuch müssen beim erneuten API-Abruf vor jeder vorgesehenen Tag-Anlage
unverändert sein. Laufende, fehlgeschlagene, übersprungene oder fremde Ergebnisse
brechen ab.

Ein erfolgreicher Jobstatus reicht nicht. Der Validator liest das Original-JSON
am festen Pfad, lehnt doppelte Ergebnisdateien, doppelte JSON-Schlüssel und
nicht endliche Zahlen ab und prüft alle 15 Pflichtschritte einschließlich ihrer
konkreten Nachweise:

- Comet und Gecko Velo müssen zwei verschiedene tatsächliche Rennen mit
  Originalfahrer `fox`, Modus `cup` und Strecke `sonnenhafen` begonnen haben.
  Ausgewähltes Fahrzeug, Renn-ID, beendeter Countdown und gestartete Rennzeit
  müssen mit dem jeweiligen Auswahl- und Startnachweis übereinstimmen.
- Die ursprünglichen Touch-Readiness-Dateien müssen wirklich gesendete,
  eindeutig beschriftete Eingaben aus zwei stabilen Beobachtungen enthalten.
  Die zugehörigen PNGs werden anhand ihrer ursprünglichen SHA-256-Werte und
  Abmessungen geprüft. Ersetzte oder fehlende Aufnahmen brechen ab.
- Beide Fahrten benötigen mindestens 8 Meter und 2,5 Sekunden Fortschritt,
  denselben Rennkontext sowie die unveränderten Kriterien für eine sichtbar
  bewegte, vollständig gerenderte Spielwelt.
- Für die Pause werden die beiden ursprünglichen `paused-*-session.cfg`
  zusätzlich mit den JSON-Werten verglichen. Nach `Weiterfahren` müssen erneut
  mindestens 8 Meter und 2,5 Sekunden in derselben Comet-Fahrt entstehen.
  Die Pausebeobachtung bleibt ausdrücklich auf zwei gespeicherte Proben über
  drei Wall-Sekunden begrenzt, ohne Behauptung einer kontinuierlichen Physikspur.
- Fold-Außen- und Innenlayout benötigen die native `LumoGameActivity`, die
  originalen Displaydaten und PNG-Abmessungen, die tatsächliche Garagenüberschrift,
  beide Fahrzeugbeschriftungen, Auswahlbestätigung und Rückkehr zu Flutter.
- Originale Paket-/Versions-/Zertifikats-/Provenance-Prüfungen müssen vollständig
  sein. Das x86-APK muss mit Tour und Update identisch sein; sein PCK-Digest muss
  mit dem tatsächlich ausgelieferten ARM64-PCK übereinstimmen. Lernstandserhaltung
  und ein vorhandener, erfolgreicher originaler Fatal-Logcat-Nachweis sind Pflicht.

Das Original-JSON wird nicht neu erzeugt oder zu einem Erfolg umgeschrieben.
Sein SHA-256 wird im Auslieferungsnachweis festgehalten; erst nach vollständig
bestandenen Prüfungen wäre eine byteidentische Kopie im Release-Prüfartefakt
vorgesehen.

### Tatsächlich beobachtete aktuelle Blockade

Der letzte autorisierte Versuch 2 endete **`completed/failure`**. Die
Paket-/OCR-Vorbereitung schlug fehl, der Emulator-/Garagentest wurde `skipped`.
Die vom QA-Autor ausgewerteten Originaljoblogs benennen die DNS-Auflösung der
offiziellen Ubuntu-Paketquellen als Ursache; es wurden keine UI-Assertions
ausgeführt oder abgeschwächt. Es ist kein weiterer Wiederanlauf ausgelöst worden.

Die eigene API-Abfrage und die tatsächliche lokale Auswertung dieses
Fehlerstands durch den neuen Validator sind im
[Blockadeprotokoll](qa/lumo_2015_delivery_guard_blocker_20261111.json) festgehalten.
Der Validator lehnte den Stand ausdrücklich wegen `conclusion` ab.
Artefakt `13861309860`, erstellt am 2026-11-11 um 14:07:09 UTC, gehört zum
fehlgeschlagenen Versuch 2; sein Archivdigest lautet
`sha256:8a59b7d5538b490ec42bb565866df056b0c15e12633d6d660b0df998ea116514`.
Das ältere Artefakt `13862712473` gehört zeitlich zu Versuch 1 und zählt nicht
als Nachweis für Versuch 2. **Keines davon wird als bestandene Android-Garage
oder als Veröffentlichungsfreigabe bezeichnet.**

## Konkrete Berechtigungsgrenze

Die aktuelle [GitHub-Dokumentation zu Create a release](https://docs.github.com/en/rest/releases/releases#create-a-release)
verlangt zusätzlich **Workflows: write**, wenn der Zielcommit Workflowdateien
gegenüber dem Defaultbranch hinzufügt oder verändert. Die Dokumentation stellt
ausdrücklich klar, dass der normale Actions-`GITHUB_TOKEN` diese Berechtigung
nicht erhalten kann. Der vorbereitete Workflow verwendet `github.token`.

Die Voraussetzung ist für diesen Kandidaten konkret erfüllt: Die Datei
`.github/workflows/lumo-unified-integration-2026.yml` hat am festen Source den
Git-Blob `185fae8a08d5e71e2b0f990dadae41e1766aa2b6`; auf dem überprüften
Defaultbranch `main` lautet er `2c4bf0ed888997cee9ab79d2f9d9a1006d086b62`.

Der Entwurf vergleicht deshalb vor jedem Schreibzugriff die Workflowdateien
des festen Zielcommits mit dem jeweils aktuellen Defaultbranch und bricht bei
dieser Berechtigungsgrenze nachvollziehbar ab. Es wurde kein tatsächlicher
403/404 durch einen Veröffentlichungsversuch erzeugt. Es wird weder ein
anderer Zielcommit angegeben noch eine nicht vorhandene Berechtigung behauptet.

Nach Prüfung durch den Integrator stehen in dieser Sitzung weder ein bei
GitHub angemeldeter Browser noch Connector-Funktionen zum Erstellen eines
Releases und Hochladen seiner Assets zur Verfügung. Es wurden keine
alternativen Tokens oder Secrets gesucht. Ein tatsächlich berechtigter
Veröffentlichungsweg bleibt erforderlich; die Workflowdatei allein stellt ihn
nicht bereit.

## Bereits vorbereitete Prüfungen

- Der unveränderliche Run muss zum genauen Workflow, Ereignis, Repository,
  Branch und Source gehören. `verify-and-build`, `android-tour` und
  `update-from-2014` müssen im selben Run-Versuch jeweils erfolgreich sein.
- Es wird ausschließlich das vorhandene ARM64-Artefakt heruntergeladen.
  Paket, Version, SHA-256, Dateigröße, Signatur und nativer Pin werden erneut
  geprüft. Der vorhandene Java-Verifier benötigt dafür nur den bekannten
  öffentlichen Zertifikatsfingerprint, keinen Signierschlüssel.
- Das tatsächlich eingebettete PCK muss byteidentisch zu den PCK-Digests der
  Androidtour, des Update-Kandidaten und der zusätzlichen Garage sein. Die tatsächlichen Ergebnisdateien
  müssen erfolgreiche Lernstandserhaltung, Offline-Kart, Neustart und Fold-Zustände
  nachweisen.
- Die vorhandenen Familienkanal-Regeln bleiben erhalten. Der aktuelle
  veröffentlichte Versionsstand wird unmittelbar vor einer vorgesehenen
  Tag-Anlage erneut geprüft. Ein bestehender Tag oder Release wird nicht
  überschrieben; die vorgesehene Tag-Neuanlage ist atomar.
- Erst danach wäre die einzelne APK als Prerelease vorgesehen, gefolgt von
  einem öffentlichen Download ohne Authentifizierungsheader und erneutem
  SHA-256-Abgleich. Es gibt keinen zusätzlichen Build, keine neue Paketkennung,
  keine Signierungsänderung und keinen Main-Merge.

Die Vorbereitung wurde mit **71 synthetischen Guard-Fällen**, anschließend
**15 ergänzenden PCK-/Versions-/Berechtigungsfällen** und **9 bestehenden
Familienkanal-Tests** geprüft. YAML, Shell, Python und JavaScript wurden auf
Syntax geprüft. Die synthetischen APK-Fixtures waren ausdrücklich unsigniert;
diese Offlineprüfungen sind keine tatsächliche APK- oder Publikationsfreigabe.
Der unabhängige Review führte zu zusätzlicher PCK-Bindung, erneuter Prüfung des
Versionsstands und dem dokumentierten Berechtigungs-Guard.

Die zusätzliche Garagenbindung wurde anschließend mit **30 lokalen
Guardtests** geprüft, darunter fehlgeschlagene/laufende Runs, falsche Quellen,
frühere Artefaktversuche, fehlende Fold-Daten, identische Renn-IDs, fehlender
Fahrfortschritt, manipulierte Originaldateien, Fatalmeldungen und ein geändertes
Artefakt beim finalen CLI-Recheck. Alle 30 Tests und die erneut ausgeführten
**9 bestehenden Familienkanaltests** sind bestanden. Die Fixtures sind
ausdrücklich synthetisch und enthalten keine echten Android-Erfolgsergebnisse.
YAML, alle 10 Shellblöcke, 4 JavaScriptblöcke und 3 eingebettete Pythonblöcke
wurden auf Syntax geprüft. Der QA-Autor hat die verwendeten Ergebnisfelder
und Originalpfade unabhängig mit dem unveränderten Probe-Schema verglichen.

Reproduzierbare lokale Befehle:

```sh
python3 -m unittest discover -v -s scripts/tests -p test_lumo_2015_garage_delivery.py
python3 -m unittest discover -v -s scripts/tests -p test_release_pipeline_gates.py
```

## Wiederaufnahme

1. Den exakten Unified-Run erneut einlesen und alle drei erfolgreichen Jobs
   sowie die zugehörigen Artefakte bestätigen.
2. Für die separate Garagenprüfung einen tatsächlich erfolgreichen, ausdrücklich
   geprüften Lauf samt unverändertem Originalartefakt erhalten. Der derzeit fest
   gebundene Versuch 2 ist fehlgeschlagen und blockiert. Ein zukünftiger Run oder
   Versuch benötigt eine nachvollziehbar geprüfte neue feste Bindung; kein
   automatischer Wechsel auf irgendeinen grünen Lauf.
3. Einen tatsächlich berechtigten Veröffentlichungsweg bereitstellen und
   prüfen, ohne den festen Source oder bestehende Tags zu verändern.
4. Erst nach diesen Nachweisen die konkrete Auslieferung erneut freigeben.
   Der gesicherte Arbeitszweig selbst aktiviert den nur auf PRs reagierenden
   Publisher nicht. Ein direkter APK-Link darf erst nach vorhandener,
   unverändert verifizierter öffentlicher Datei als Lieferung ausgegeben werden.
