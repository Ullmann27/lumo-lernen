# Lokale Datensicherung und Wiederherstellung

## Ausgangsbeleg und heutiger Anschluss

Die bereitgestellten Originale `05-lumo_lernen_agent_playready_prototype_app.html` (Zeilen 861–862, UI-Anschluss 894) und `09-lumo_lernen_menu_pro_app.html` (Zeilen 324–326) besitzen einen vollständigen Export/Import ihres damaligen JavaScript-Zustands. Exportiert wird `st` als JSON; importiert wird direkt in den jeweiligen localStorage-Schlüssel und anschließend die Seite neu geladen.

Der vorhandene Flutter-Stand hatte keinen entsprechenden allgemeinen Datenexport. Die vorhandene Kart-Geister-Dateiauswahl transportiert ausschließlich Kart-Geister. Diese Integration ergänzt daher eine eigenständige Backup-Domäne, einen Dienst, eine Elternkarte und einen kleinen Android-Anschluss. Die alten HTML-Dateien sind **kein kompatibles Format** für die heutigen Flutter-/Godot-Daten. Ihr ungeprüfter Import wird abgelehnt.

Der Settings-Anschluss lautet `LocalBackupCard(app: appState)` aus `lib/features/backup/local_backup_card.dart`. Journal, Schreibtrainer und bestehende Lerneditoren werden nicht umgebaut.

## Enthaltener persistenter Umfang

| Bereich | Inhalt |
|---|---|
| Flutter-Präferenzen | Vorhandene Daten unter `lumo_`, `lumo.`, `cross_grade_practice_v1:` und `cross_grade_writing_v1:` mit ihren ursprünglichen bool/int/double/String/StringList-Typen. |
| Profile und Lernen | Kinderprofile, Schulverzeichnis und aktive Auswahl, Lern-/Lese-/Schreibdaten, Journal, Geschichten, Aufgabenprotokolle, eigene Elternaufgaben einschließlich noch nicht vollständig bestätigter Versuche. |
| Belohnungen | Vollständiger gespeicherter Wallet-Wert mit Ergebnis-IDs, Gutschein-Transaktionshistorie und Zimmeraktionen sowie eigene Gutschein-/Zimmer-Daten und Pending-Belege. |
| Native Profilzuordnung | `lumo_3d_profile_keys_v1`, zugehöriger `lumo_3d_save_salt_v1` und lokale Lernidentität. Der Salt ist Bestandteil der Spielstandzuordnung und wird erhalten. |
| Native Spiele | Gespeicherte CFG-/JSON-Familien für Kart, Parcours, Werkstatt/Streckenpass, Run, Jump, SkyPost, Bauwelt/Settlement, Puzzle, Rhythmus, Schatzsuche, Karten und Schach; native Fortschritts-/Darstellungseinstellungen und Dateien unter `kart_geister/`. |
| Noch offene Spielergebnisse | `lumo_game_events.json` mit Ergebnis-IDs sowie `lumo_host_pending_rewards.cfg`. Alte Activity-Navigation und `callerReturnSession` werden aus dem transportierten Event-Store entfernt. |

Zugangsdaten-/Freigabeschlüssel werden anhand der dokumentierten Policy ausgeschlossen. In `lumo_app_settings_v1` bleiben Lern-/Darstellungseinstellungen erhalten; Mikrofon, Scanner, Cloud-Sprache, lokale Modellzustimmung, KI-Proxy, LAN und Geisterfreigabe werden auf `false` gesetzt. Die Proxy-Adresse wird auf den öffentlichen Standard zurückgesetzt. Beim Restore bleiben ausgeschlossene private Präferenzschlüssel des Zielgeräts bestehen.

APK-/PCK-/Modell-Assets, Cachedateien, Locks, Diagnosebilder und die transienten Token-Verzeichnisse der Karten-/Vier-Gewinnt-/Tischspiel-Bridges sind kein transportierter Spielstand. Diese Funktion stellt persistente Daten wieder her; sie setzt keine lebende Android-Activity oder laufende Spielinstanz auf einem anderen Gerät fort. Die Sicherungsdatei ist unverschlüsseltes JSON; die Elternkarte benennt dies vor der Speicherortwahl.

## Format und Prüfung

`format=lumo-local-backup`, `version=1`: Die Hülle enthält UTC-Erstellungsdatum, einen kanonischen JSON-Payload und dessen SHA-256. Jede native Datei trägt Pfad, Bytezahl, SHA-256 und Base64-Inhalt. Alle Daten werden vor dem Vormerken gelesen und geprüft. Prüfsummen dienen der Beschädigungserkennung; sie sind keine digitale Signatur des Erstellers.

Geprüft werden Format/Version, UTF-8, Datentypen, JSON-Struktur, vollständige native Profilzuordnung, wichtige Profil-/Journal-/Wallet-Strukturen und Gutscheinbelege. Native JSON-Dateien müssen JSON-Objekte enthalten; CFG-Dateien bleiben UTF-8-Text mit unveränderten Bytes. Die jeweiligen Spielregeln interpretieren ihren gespeicherten Spielstand weiterhin selbst. Pfade sind auf die tatsächlichen Speicherfamilien begrenzt; Traversal, doppelte Dateien und symbolische Ziele werden abgewiesen. Reservierte interne Präferenz-Encodings können nicht als normaler Text eingeschleust werden.

Grenzen: 64 MiB Archiv, 16 MiB Präferenzen, 32 MiB native Dateien insgesamt, 8 MiB je Datei, 1.024 Dateien, 20.000 Präferenzen und 64 JSON-Verschachtelungsebenen. Es wird kein beliebiger Archivpfad entpackt.

## Konsistenz und unterbrochener Import

`LumoAppState.withBackupStoragePaused` pausiert die Profilwahl, drainiert bereits angenommene Lernoperationen und Rewards, die Gutschein- und Zimmer-Repository-Queues sowie offene Lern-/Cosmos-/Tutor-/Tagesmissions-/Aufgabenprotokoll-Schreibvorgänge. Anschließend hält es die bestehende `LearningStorage`-Serialisierung während des Snapshots bzw. Vormerkens. Ein Speicherversagen wird weitergegeben; es gilt nicht als erfolgreiche Sicherung. Insbesondere blockiert ein nach dem Tutor-Drain noch offener Lernschritt den Snapshot. Inaktive Profile erhalten beim Flush keine aktuelle UI-Generation; ihre Daten werden gespeichert, ohne das ausgewählte Kind auszutauschen.

Beim Export werden native Ergebnisse unter dem vorhandenen Event-Store-Lock vor den frisch geladenen Flutter-Präferenzen erfasst. Die normale Ereignisbestätigung erfolgt erst nach dem dauerhaften Wallet-Schreibvorgang. Damit enthält eine Sicherung entweder noch das ausstehende Ergebnis oder bereits seine idempotente Wallet-Quittung, gegebenenfalls beides. Ein aktiver nativer Spielprozess oder ein offener Start-/Rückkehrvorgang blockiert die Sicherung.

Der Import zeigt zuerst Datum, Profile und Eintrags-/Dateizahlen. Eine ausdrückliche Erwachsenen-Checkbox schaltet „Wiederherstellen und schließen“ frei. Die exakten geprüften Bytes werden nur in den privaten NoBackup-Bereich vorgemerkt. Lumo beendet anschließend seinen Task und Prozess; die Eltern öffnen die App erneut. Eine zufällige Prozesskennung verhindert, dass bloße Activity-Neuerstellung oder Rotation als Kaltstart gilt.

`MainActivity.onCreate` führt die Wiederherstellung **vor** `super.onCreate` aus. Zu diesem Zeitpunkt existieren weder neue Flutter-Plugins noch alte Dart-Repository-Caches. Die Dateitransaktion hält eine gehashte Vorher- und Nachher-Kopie bereit und prüft freien Platz für den Rollback. Erst nach dauerhaftem `applying`-Journal werden native Dateien und danach die Präferenzen ersetzt. Nach vollständigem Commit wird `committed` geschrieben und die Vorher-Kopie als lokale Rücksicherung erhalten.

Ein abgebrochener `applying`-Vorgang wird beim nächsten Start auf die Vorher-Kopie zurückgesetzt. Auch ein erneut unterbrochener Rollback kann dieselbe Kopie wieder anwenden. Ein bereits festgeschriebener Commit wird fertig aufgeräumt. Kann die Rücksicherung wegen eines anhaltenden Speicherfehlers nicht beendet werden, bleiben Journal und Originalkopien erhalten und Flutter startet nicht in einem halb ersetzten Datenbestand. Die Elternkarte meldet einen erfolgreich wiederhergestellten bzw. zurückgesicherten Stand und bietet die lokale Vorher-Kopie zum Rückholen an.

## Android-Schnittstelle

Channel: `lumo_lernen/local_backup`. Methoden: `status`, `snapshotNative`, `saveBackup`, `pickBackup`, `stageRestore`, `stagePrevious`, `closeForRestore`.

Die App verwendet `ACTION_CREATE_DOCUMENT` und `ACTION_OPEN_DOCUMENT`, MIME `application/json`; beim Öffnen werden zusätzlich `application/octet-stream` und `text/plain` akzeptiert. Standardname: `Lumo-Sicherung-yyyy-MM-dd-HHmm.json`. Nur die vom Android-Dateidialog gewährte `content://`-Datei wird geöffnet. Ein Abbruch liefert `false` bzw. `null` und ändert keine Lerndaten. Es werden keine zusätzlichen Cloud-Dienste, allgemeinen Speicherrechte oder automatischen Neustart-Alarme eingebunden.

## Prüfung am 22.11.2026

| Prüfung | Beobachtetes Ergebnis |
|---|---|
| Neue Backup-Format-/Flowtests | 20/20 PASS: Roundtrip, persönliche Daten, Rechteausschluss, native IDs/Bytes, beschädigte und fremde Formate, Grenzen, Profile, echte 390-dp-Bestätigungs-UI, Abbruch, ausstehende Wallet-Writes, aktive Profilanzeige nach dem Flush mehrerer Kinder und blockierender Tutor-Speicherfehler mit erfolgreichem Retry. |
| Gemeinsamer Flutter-Lauf | 33/33 PASS, einschließlich bestehender AppState-Identitäts-, Profil-Isolations- und beschädigter-Profil-Regressionen. Die beiden zusätzlichen Review-Regressionen waren vor der Korrektur nachweislich rot; siehe `backup-review-before.txt`. |
| Native Transaktion | 14/14 PASS auf echten temporären JVM-Dateien: Roundtrip/Vorher-Kopie, Stage/Abbruch, Prozessunterbrechungen vor/nach Journal und Commit, Dateitausch, Preferences, erneut unterbrochener Rollback, Schreibfehler, Hash-/Pfad-/Symlink-/Größenfehler. |
| Nativer API-Compilecheck | PASS: tatsächlicher SAF-Bridge-Code und GameEventStore gegen das offizielle Android-API-36-JAR, vorhandene JDK-/Kotlin-Werkzeuge. Der Flutter-Channel ist dabei nur eine deklarierte Transport-Schnittstelle. |
| Android-Generator | 3/3 PASS, darunter beide echten Backup-Quellen mit ursprünglichem Inhalt und angepasstem Namespace bei wiederholter Vorbereitung. |
| Dart-Analyse | Keine Befunde in den Backup-Dateien, deren Tests und AppState. |

Belege neben diesem Bericht: `backup-flutter-tests.txt`, `backup-native-tests.txt`, `backup-generator-tests.txt`, `backup-analysis.txt`. Die ersten beiden Dialogprüfungen fanden einen unnötig weiterlaufenden Ladeindikator während der Erwachsenenentscheidung; dieser pausiert nun während des Dialogs. Der vollständige 31er-Lauf wurde danach erfolgreich wiederholt.

Diese lokalen Prüfungen belegen noch keinen Android-SAF-Rundlauf der neuen APK. Dafür wird eine eigene echte Emulatorprobe mit Dateiauswahl, ausdrücklicher Wiederherstellung, Prozessende, erneutem Start und Vergleich gespeicherter Werte in den APK-Workflow integriert. Ihr Ergebnis muss aus dem tatsächlichen Lauf entnommen werden.

## Gemeinsame neue AppState-Delegatoren

- `awardParentTaskResult({required LearningProfileLease lease, required String resultId, required int stars, required int xp})`: bindet die stabile `parent:<owner-hash>:<32 hex>`-ID und Wertebereiche an das aktuelle Profil und die vorhandene idempotente Reward-Queue.
- `loadRewardShopWallet({required LearningProfileLease lease})`: wartet auf vorherige Rewards und prüft die aktive Profilzuordnung vor und nach dem Lesen.
- `redeemShopReward({required LearningProfileLease lease, required RewardShopRedemption redemption})`: prüft denselben Besitzer während der atomaren Wallet-Abbuchung und übernimmt den tatsächlich gespeicherten Wallet-Wert in die Anzeige.

Die Vorgänge sind durch `_trackLearning` für den Backup-Drain sichtbar. Sie vergeben keine erfundenen Curriculum- oder Tagesmissions-Kompetenzen für Elternaufgaben.
