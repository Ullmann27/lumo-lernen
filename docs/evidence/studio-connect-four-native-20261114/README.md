# Vier gewinnt: echter nativer Spielraum, kontrollierte Integration

## Stand und Herkunft

Dieser isolierte Stand implementiert einen tatsächlich angeschlossenen Godot-Spielraum für die vorhandene Flutter-Vier-Gewinnt-Route. Er ist lokal geprüft und zur kontrollierten Integration vorbereitet. Er ist noch kein gebauter oder auf Android abgenommener Kandidat.

Die veröffentlichte Grundlage ist Host `86445f53af5d573549fc8cf03405261611f3cb7e` und Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. `source-binding.json` bindet die vor der Bearbeitung gelesenen Dateien an ihre echten Gitblobs. Die beiden Dependency-Berichte erfassen 544 gelesene Abhängigkeiten. Drei im minimalen Laufzeitprojekt erzeugte UID-/Importmetadateien sind ausdrücklich getrennt; ihre tatsächlichen ursprünglichen 803-Dateien bleiben unverändert. Auch `lumo_voice.dart` einschließlich des vorhandenen `clipMouth` ist veröffentlichter 86445-Bestand.

`source-upload-manifest.json` enthält exakt 25 neue oder geänderte Dateien: 19 Hostdateien und sechs Native-Dateien, insgesamt 330.696 Bytes. Gemeinsame Dateien sind Integrationsvorschläge. Es wurden keine Gitreferenzen, Pins, CI-Läufe oder produktiven Main-Dateien verändert. Die finalen Codebytes sind eingefroren.

## Vorher, übernommen und neu

Vorhanden waren die Flutter-Oberfläche, die Dart-Regelengine, drei Botstufen und die bisherigen Belohnungsbeträge. `connect_four_engine.dart` ist bytegleich zur veröffentlichten Grundlage. Die Regeln für gültige Spalten, Zugwechsel, Sieg, Unentschieden und sämtliche Botentscheidungen werden weiterhin ausschließlich dort berechnet. Original-Lumo und die vorhandenen 803-Animationen werden wiederverwendet.

Neu sind die echte Godot-Szene, ein dauerhafter profilbezogener Rundenzustand, die begrenzte C4-Sitzung und der native Android-Anschluss der tatsächlichen bestehenden Route. Die native Szene enthält ein perforiertes Brett aus einer Meshoberfläche mit 42 echten Löchern und 32 Segmenten pro Loch, plastische Zylindersteine, einen räumlichen Tisch, echte Beleuchtung und eine leicht geneigte orthogonale Kamera. Fallanimationen beginnen erst nach einem von Dart bestätigten Zug. Die vier Gewinnmarkierungen folgen ausschließlich der von Dart gelieferten Gewinnlinie. Original-Lumo reagiert über sein vorhandenes Animationssystem.

Die Szene hat sieben Spaltenschalter, Pause/Fortsetzen, Rückkehr, Neustart, Zweispielermodus und die drei unveränderten Botstufen. Im gemessenen 411 dp-Portrait sind alle sieben Spalten vollständig sichtbar. Schmalere Reihen verwenden horizontales Scrollen; lange Menüs verwenden vertikales Scrollen. Der neue native Lauf belegt den echten Wischer zum vollständig sichtbaren Menüknopf im 640×360-Format. Einen eigenen nativen320 dp-Wischer bis zur letzten spielbereiten Spalte behauptet er nicht; der Flutter-Fallback320 dp ist separat getestet.

## Regel-, Kinder- und Belohnungsschutz

`connect_four_round.dart` speichert eine legale Spaltenfolge. Der Wiederaufbau läuft durch die Originalengine; illegale, überlange, fremde oder nach einem Sieg fortgesetzte Folgen werden abgewiesen. Der neue Schlüssel lautet `lumo.connect_four.round.v1.<SHA256(studentId)>`. Ein Name oder Klassenwechsel ändert die Identität nicht. Vorhandene Lern-, Profil-, Wallet- oder andere Spielstände werden weder kopiert noch gelöscht oder migriert.

Der Controller serialisiert Änderungen und speichert sie vor der Anzeige und vor einem positiven nativen ACK. Vergleich gegen den vorherigen gespeicherten Inhalt schützt vor veralteten Schreibvorgängen. Die aktuelle Profil-Lease wird vor Verarbeitung, Speicherung, Belohnung und Rückkehr geprüft. Ein bereits laufender Schreibvorgang bleibt allenfalls an den alten Eigentümerschlüssel gebunden; er kann keine neue Kinderrunde ersetzen.

Die Belohnungs-ID ist `c4:<ownerSHA>:<roundId>`. Sie nutzt die vorhandene injizierte Wallet und Warteschlange. Die bisherigen Beträge bleiben unverändert: Sieg 5 Sterne/40 XP, Unentschieden 3/20, Niederlage 2/16. Erst nach dem Walletabschluss wird die Runde als belohnt gespeichert. Ein Abbruch zwischen beiden Schritten wiederholt dieselbe Ergebnis-ID, nicht die Auszahlung. Die bestehende globale Walletsemantik wurde nicht migriert.

## Eigener Android-Vertrag

C4 besitzt `lumo_lernen/connect_four`, eine eigene Bridge, einen privaten Authority-Service und eine eigene Godot-Activity. Cards-Whitelist, Cards-Authority und deren Spielbefehle bleiben unangetastet. Befehle sind auf die C4-Aktionen und explizite Schlüssel begrenzt; Sitzungstoken, Runde, Revision und Sequenz müssen passen. Nur ein unbestätigter Requestslot ist zulässig.

Jeder in der gültigen Sitzung angenommene Request endet positiv bestätigt oder ausdrücklich abgelehnt. Das gilt auch bei Pause, einem inzwischen geänderten Zug oder einer geänderten Revision. Ein neuer fremder Token wird dabei nie überschrieben. Die unabhängige Slotreview dokumentiert den gefundenen und geschlossenen Fehler.

Die Activity liefert einen vom Renderer unabhängigen Main-Looper-Heartbeat. Pause, Stop, Destroy, Binderverlust und Rückkehr beenden die Aktivität. Alte Callbacks können sie nicht wieder aktivieren. Die Dart-Frist bleibt2.500 ms; Fortsetzen bleibt explizit. Rückkehr erfolgt erst nach dem Exit-ACK und der vorhandenen dauerhaften Rückkehrmeldung. Der native Renderer kann keine Belohnung festlegen.

## Tatsächlich ausgeführte Prüfungen

| Gruppe | Tatsächliches Ergebnis | Originalbeleg |
|---|---:|---|
| Dart-Regeln, Bots, neue Sitzung/Saves, Route und bestehende Widgets |48 Tests PASS|`logs/flutter-integration-final-sequential.log`|
| Echte C4-Kotlin-Dateien, Mailboxdateien, Authority/Lifecycle, bestehender Return und Hostgenerator |25 Tests PASS,0 Skip|`logs/kotlin-and-generator-integration.log`|
| Dart-Analyzer der acht betroffenen Dateien |0 Befunde|`logs/dart-analyze-final.log`|
| Zwei Prozesse: echte Godot-Eingaben → Produktions-Dart → bestätigter Zustand → Geometrie |170 Checks PASS; Godot Exit 0 und Dart Exit 0|`runtime-final-v7/two-process-run.json`, `xorg-final-v7/godot.log`|
| Produktions-Dart-Treiber: Botantwort, Sieg, Speichern und erneutes Öffnen |1 Test PASS|`logs/runtime-dart-final-v7.log`, `runtime-final-v7/dart-result.json`|
| Filmdecode |248/248 Frames in beiden Medien vollständig; verlustloses RGB bytegleich|`runtime-final-v7/decode-verification.json`|

Die Kategorien sind verschieden und werden nicht zu einer scheinbaren einheitlichen Testzahl addiert. Die Kotlin-Prüfung verwendet die tatsächlichen Produktionsklassen und `org.json`; Android/Godot/Flutter-Randobjekte und der Main-Looper sind JVM-Testadapter. Das ist kein Android-Binderlauf.

Die Dart-Prüfung enthält unter anderem zwei Kinderidentitäten, wiederholtes Ergebnis, Unterbrechung nach Walletcommit vor Rundenspeicherung, fehlgeschlagene Speicherung, Profilwechsel während eines gehaltenen Bot-/Rewardvorgangs, veraltete Sitzungsbefehle, Pause/Resume und geschlossenes Eigentum. Der native tatsächliche Lauf beginnt mit einem einzelnen Kindzug und der Antwort der Original-KI. Danach wird über echte Bedienung eine getrennte Zweispielerrunde gestartet. Deren sieben legale Spalten sind `[0,6,1,6,2,5,3]`. Ein Stein wird während seines Falls tatsächlich pausiert und danach fortgesetzt.

Der Film enthält diese Zweispieler-Siegrunde: 248 unmittelbar aufeinanderfolgende Viewportframes, 960×540, als24 Bilder/s kodiert, Dauer 10,333 s. Es wurden keine Zwischenbilder erzeugt. Die ursprüngliche Einspieleröffnung ist separat durch PNG, Layout, Inputjournal und Dartzustände belegt. Alle neun aktuellen Standbilder und fünf aus der MP4 dekodierte Bilder wurden tatsächlich geöffnet. Die Aufnahmefrequenz ist kein Geräte-FPS-Nachweis.

## Ehrliche lokale Transport- und Speichergrenze

Der Zweiprozesslauf verwendet die echten Produktionscontroller, Regeln, Belohnungslogik und die echte Godot-Szene. Nur die Verbindung wird lokal durch Dateien ersetzt. Die Uhr/Lifecycle-Grenze wird vom Harness vorgegeben. Der Dart-Treiber verwendet `SharedPreferences.setMockInitialValues({})`; seine Wiederöffnung erfolgt im selben Prozess. Er belegt daher keine Android-Diskdauerhaftigkeit und keinen echten Android-Prozessneustart. Die Store-/Unterbrechungsfälle sind gezielte getrennte Tests.

Die Dichte-/Insetfälle sind deklarierte Plattformfixtures. Die vorhandene Cache-Logmeldung sagt dabei technisch „actual Android View insets“; die Belege dürfen daraus keinen Androidlauf ableiten. Alle entsprechenden Rohsidecars sind ausdrücklich `platform_fixture`. Eine tatsächliche Android-Abnahme muss `android_window_insets` und die realen Decor-/RenderViewwerte nachweisen.

## Read-only Layoutdiagnose

Die Szene schreibt `user://connect_four_layout_v1.json` atomar. Eine Änderung an Zustand, Layout, Pending oder Scrollposition invalidiert die alte Datei. Erst nach zwei Layoutframes und dem Ende der Steinbewegung wird ein neuer `settled`-Datensatz geschrieben. Es gibt keinen Test-Eingabeweg und keinen Zugriff auf Rundensaves darüber.

Der Datensatz bindet Token, `owner`, Runde, Revision/ACK, PID, Größe, Dichte und echte Insets. Buttonrechtecke einschließlich tatsächlicher Clip-Schnittfläche, Kameraursprung/Basis/Orthogröße und die Weltpositionen aller 42 Zellen ermöglichen eine unabhängige Projektion. Koordinaten sind explizit `godot_window_px`; Screenshotkoordinaten entstehen über das gemessene `android_observation.render_rect`. Die Rohdateien neben den Bildern stammen unverändert vom nativen Writer. Die neue Android-Probe von A bleibt eine separate Implementierung.

## Gefundene Fehler und erhaltene Gegenbelege

Die Originalfehler wurden nicht gelöscht. Dazu gehören die frühe numerische JSON-Verwechslung bei gültigen Spalten, ein gesonderter typstrikter Gewinnlinienvergleich im Test, die zuvor zu kleinen Flutter-Touchflächen, alte Widgetfixtures ohne die neue asynchrone Profil-/Nativevorbereitung sowie ein als Integer normalisierter Testwert im Kotlin-Negativfall.

Der späte echte Menügegenlauf (`runtime-menu-red-v5`) führte bei unveränderter v4-Produktquelle zu zwei Fehlern: Der auf einem Button begonnene Wischer erreichte den Scrollcontainer nicht. Die schmale Produktkorrektur setzt die sechs Menübuttons auf `MOUSE_FILTER_PASS`. Der erste Folge-Harness (`runtime-final-v6`) scrollte danach tatsächlich, überschoss aber mit einer konstanten Strecke den Zielknopf. Der finale Test berechnet seine begrenzte relative Wischrichtung aus den jeweils aktuellen Bounds und behält die volle Sichtbarkeits-/48 dp-Prüfung. `runtime-final-v7` ist der neue vollständige grüne Lauf. Historische v1/v4-Aufnahmen ersetzen ihn nicht.

## Integrationsgrenze und nächste verpflichtende Schritte

Die gemeinsamen Hostpatches betreffen AppState, Launcher, MainActivity und Hostgenerator sowie die tatsächlich verwendete C4-Oberfläche. Die drei gemeinsamen Nativepatches betreffen SceneRouter, AppBoot und `scripts/systems/host_bridge.gd`. Die neuen C4-Dateien sind getrennt; `patches/` enthält die Vorschläge gegen die verifizierten Baselines. Originalengine, Kart-, Cards-, Lern-, Profil- und Schreibtrainersysteme werden dadurch nicht ersetzt.

Root integriert diese Dateien kontrolliert, schließt den echten Zweiprozesslauf an die CI an, erstellt den neuen nativen Pin und baut anschließend den Kandidaten. Ein Android-C4-End-to-end-Lauf mit echter Autorität, echten Insets, Kind-/Botzügen, Pause, Rückkehr und wiedergeöffneter Runde steht noch aus. Gleiches gilt für einen physischen Fold7, Android-Geräteperformance/Temperatur und60 FPS. Neue Lippen-/Gesichtsanimationen sind nicht Bestandteil dieses C4-Pakets.
