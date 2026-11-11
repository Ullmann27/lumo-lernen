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

API-Stand **2026-11-11, 13:25:06 UTC**: `verify-and-build` ist erfolgreich
abgeschlossen; `android-tour` läuft. Für `update-from-2014` liegt zu diesem
Zeitpunkt noch kein erfolgreicher Jobnachweis vor. Alle sichtbaren Jobs gehören
zum genannten Quellstand und Run-Versuch 1. Dies ist eine Momentaufnahme,
keine spätere Android- oder Update-Freigabe.

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
  Androidtour und des Update-Kandidaten sein. Die tatsächlichen Ergebnisdateien
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

## Wiederaufnahme

1. Den exakten Unified-Run erneut einlesen und alle drei erfolgreichen Jobs
   sowie die zugehörigen Artefakte bestätigen.
2. Die separate zusätzliche APK-Prüfung für Garagenauswahl und Wiederaufnahme
   auswerten. Sie ist noch nicht als bestandener Nachweis oder Publisher-Gate
   aufgenommen und darf erst nach ihrem tatsächlichen Erfolg berücksichtigt werden.
3. Einen tatsächlich berechtigten Veröffentlichungsweg bereitstellen und
   prüfen, ohne den festen Source oder bestehende Tags zu verändern.
4. Erst nach diesen Nachweisen die konkrete Auslieferung erneut freigeben.
   Der gesicherte Arbeitszweig selbst aktiviert den nur auf PRs reagierenden
   Publisher nicht. Ein direkter APK-Link darf erst nach vorhandener,
   unverändert verifizierter öffentlicher Datei als Lieferung ausgegeben werden.
