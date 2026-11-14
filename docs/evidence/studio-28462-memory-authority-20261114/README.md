# Aktuelle Memory-Autorität: Host 28462 / Native 29080

Dieser Beleg gehört ausschließlich zum Memory-Job **132543177183** des Studio-Laufs **43626348519**, Attempt 1. Der Job endete am 14.11.2026 um **18:28:46 UTC erfolgreich**. Der gesamte Studio-Lauf war zu diesem Zeitpunkt noch nicht abgeschlossen. Keine Befunde aus b721 wurden als aktueller Ausführungsnachweis übernommen.

## Unveränderte Quellen und Originalarchiv

- Host: `28462a7547048b75fa114e6f5832248e54c94faa`, Tree `21cc39c37c96c8d76d46434b42b172e88ffb745e`.
- Native: `29080ef8cd1a5b385eeeec97976fbefd31280427`, Tree `5ddbea2b1d5e76ed592a27c36079632d7f26cada`.
- Artefakt: `14126945691`, `lumo-studio-2020-nextgen-authority-memory`, **3.943.937 Bytes**.
- SHA-256: `50ab9d04aa2067e149097811f366043f73aaa0e26594c10a8622013ed3895908`.
- Das Original wurde einmal heruntergeladen. Alle **73 Mitglieder** wurden vollständig gelesen, CRC-geprüft und bytegleich extrahiert. Alle **28 PNGs** wurden vollständig dekodiert.
- Die vier Quellstempel, das ursprüngliche GitHub-Jobmetadatum und die Vorher-/Nachher-Quellidentitäten des Paar-Runners stimmen überein. Beide Prozesse endeten mit Exit 0.
- `original-job.log` enthält den einmal gelesenen vollständigen terminalen Log als unveränderte UTF-8-Bytes. Die Run-Metadaten sind der Stand beim Abschluss dieses einzelnen Jobs, kein Gesamtabschluss.

## Tatsächliche Ergebnisse – unterschiedliche Einheiten bleiben getrennt

| Prüfung | Ergebnis |
| --- | --- |
| Produktions-Dart-Autorität | 30 Fälle, 1.694 Checks, 0 Skip |
| Produktions-Zugplaner | 7 Fälle, 13 Checks, 0 Skip |
| Native Präsentationsfixture | 7.020 Checks, 8 Aufnahmen |
| Reale Dart/Godot-Paarung | Bericht 243 Checks; terminal 244 einschließlich letzter Berichtsschreibprüfung |
| Originale Eingabekorrelation | 19 Requests, 19 Down-/Up-Paare, 57 native Eingabe-/Submitzeilen |
| Zustands-/Sitzungsbindung | 32 Zustände, 3 Token, alle Request-ACKs positiv und sequenziell |

Die unabhängige Nachprüfung vergleicht die unveränderten Requeststrings aus Native-, Eingabe- und Dartjournal. Owner, Token, Runde, Revision, gespeicherte Revision und ACK werden an die zugehörigen Originalzustände gebunden. Verdeckte Motive bleiben in den öffentlichen Zuständen null. Alle acht eigentlichen Spielaufnahmen besitzen passende aktuelle, stabile Layoutdateien mit `pending=0`; deren Identität stimmt mit dem Authorityjournal überein.

## Speicherung, Rückkehr und Belohnung

Die tatsächliche archivierte unfertige Runde bleibt beim Wiederöffnen dieselbe und pausiert mit **550 ms** Restzeit in der Auflösungsphase. Der Mailboxtoken wechselt. Nach den echten Botphasen wird über den echten Neustartbutton eine weitere Runde gespielt und mit **vier zu null Paaren** abgeschlossen.

Die gespeicherte abgeschlossene Runde ist `rewarded=true`. Der QA-Belohnungsspeicher enthält genau **eine** eindeutige Ergebnis-ID, **2 Sterne und 16 XP**. Beim erneuten Öffnen entsteht eine neue Runde mit neuer ID und neuem Token, ohne zweite Belohnung. Schwierigkeit `leicht`, Themenpaket `alle`, der bisherige Schwer-Bestwert 17, der neue Leicht-Bestwert 4 und ein zusätzliches ursprüngliches Statistikfeld bleiben erhalten. Der synthetische Fremdkind-Sentinel bleibt bytegleich. Drei tatsächliche Rückkehraktionen sind aufgezeichnet.

Die drei gespeicherten Rundenoriginale, Statistik- und Walletdateien wurden zusätzlich zum zusammenfassenden Authoritybericht unabhängig gelesen. Das ist ein Nachweis des **QA-Dateispeichers**, keine Android-SharedPreferences- oder reale Zwei-Kind-Migrationsprüfung. Die gesonderten 28462-Fluttertests der SharedPreferences-Korrektur werden dadurch nicht ersetzt.

## Aktuelle persönliche Sichtprüfung

**19 Originaleinträge wurden in diesem Durchgang einzeln geöffnet**, darunter acht aktuelle Spielphasen, acht Präsentationsprofile und drei Flip-Zwischenstände. Da die versteckte Landscape-Fixture bytegleich zur bezahlten Wiederöffnung ist, sind dies **18 unterschiedliche Bildhashes**. Kein weiterer blockierender sichtbarer Befund in dieser Auswahl.

Die Aufnahmen zeigen eine verdeckte und eine aufgedeckte Karte, Pause und pausierte Wiederöffnung, zwei tatsächliche Bot-Aufdeckphasen, den Ergebnisdialog, die neue Runde sowie die Drehung der Karte. Die 24-Karten-Profile sind auf Phone und Fold vollständig sichtbar; Compact zeigt acht, Cutout zwölf Karten pro Seite. Lumo ist auf den schmalen/kurzen Layoutvarianten ausgeblendet. Untere Einstellungen der Modale benötigen Scrollen und sind im anfänglichen Standbild nicht vollständig sichtbar.

Alle Bildbefunde stehen mit Originalpfad, Hash, Abmessungen und Sichtgrenzen in `verification/reviewed-original-images.json`. Die neun übrigen Motion-PNGs wurden technisch dekodiert, aber nicht als persönlich gesichtet gezählt und nicht in den Dokumentupload aufgenommen.

## Ausdrückliche Grenzen und erhaltene Meldungen

Die Produktionscontroller/-regeln und echte Godot-ScreenTouch-Ereignisse laufen über den lokalen QA-Dateitransport. Uhr, private Deckplanung und Belohnungsspeicher sind QA-Adapter. Die Präsentationsprofile verwenden `platform_fixture`, keine gemessenen Android-Insetwerte. `--fixed-fps 60` ist eine Simulationsvorgabe und kein Geräte-FPS-Nachweis. Der Audiotreiber ist Dummy; es gab keinen Hörtest.

Die beiden Rendererlogs enthalten zusammen sechs Warnzeilen zu V-Sync, Screen-space AA und volumetrischem Nebel. Sie sind vollständig erhalten; es gibt in diesen Originalen keine `ERROR:`-/`SCRIPT ERROR`-/`Parse Error`-Zeilen. Keine APK-, Creative- oder Gesamtfreigabe folgt aus diesem einzelnen Job.

Ein erster lokaler Transferwrapper scheiterte vor jedem Netzwerkabruf am fehlenden Pythonmodul `requests`; die eine tatsächliche Übertragung verwendete danach die Standardbibliothek. Ein rein lesender Explorationsaufruf nahm für `publications` zunächst den falschen Feldtyp an. Beide Werkzeuggrenzen sind dokumentiert und keine Produktfehler. Die endgültigen beiden Originalprüfungen endeten mit Exit 0. Es wurden weder Flutter/Dart noch ein Renderer lokal neu gestartet.

## Dokumentensicherung

`evidence-upload-manifest.json` zählt jeden ausdrücklich ausgewählten Dokumentpfad und seine Originalbytes. Das neue Präfix ist `docs/evidence/studio-28462-memory-authority-20261114/`. Das Original-ZIP und nicht ausgewählte Screenshots sind vom Gitblob-Upload ausgeschlossen. Keine Trees, Commits, Refs, Produktdateien, Pins oder Receipts werden durch diese Sicherung geändert.
