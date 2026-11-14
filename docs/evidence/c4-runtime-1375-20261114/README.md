# Aktuelle C4-Runtime-Originale: 1375da19

Dieser Nachweis gehört ausschließlich zu Host `1375da193af0152af64f91d86577aa9768cd50db` / Tree `ebaf259b92a4c7923782e195c3a932112ce81027`, Native `e2d15dbc5f3709306decb139eeb70a1cf30c0b73` / Tree `ea0f73ae6aad8792a963cadaa483c290a2f2a62e`, Run `43599456596`, Attempt 1, Runtimejob `132460874104`.

## Originalübernahme und Bindung

Das aktuelle Artefakt `14115597521` wurde genau einmal über den offiziellen GitHub-Download übernommen: 22.157.468 Bytes, SHA-256 `dec176c035f5183ce2fbd33f78e95cdb55d7b9b58f16841e3ac34bfee80be836`. Der vollständige Index bindet alle 399 Originaldateien; CRC, kanonische Pfade und reguläre Dateitypen wurden geprüft. Es wurde kein Archivcode ausgeführt. Die Original-API bindet das Artefakt und den um 13:25:21 UTC erfolgreich abgeschlossenen Runtimejob an den genannten Head und Attempt. Der Mainlauf war bei dieser API-Abfrage noch in Bearbeitung.

Der bereits gesicherte vollständige Original-Joblog `0e0243629f4d21c681e96b61c3cce59f6c702231` liegt beim ReleaseLead und wird hier nicht dupliziert.

## Tatsächlicher Leserabgleich

Das separat erhaltene Prüfskript hat nur `validate_native_log` und `validate_results` aus dem exakt auf 1375 gebundenen Host-Reader `36d93ed0908705e339346bf5ef451cf047b641b5` aufgerufen. Es hat keine Spielprozesse, Tests oder Renderer gestartet. Python 3.12.14 / Pillow 13.0.0; tatsächlicher Leserprozess Exit 0.

Die frische Auswertung stimmt exakt mit dem Original-Gatebericht überein:

- 170 ursprüngliche Native-Prüfungen, keine gemeldeten Native-Fehler; ursprüngliche Dart- und Godot-Prozessenden jeweils 0.
- 250 zusammenhängende Frame-PNGs plus neun benannte Aufnahmen: alle 259 PNGs decodiert und ihre Größen und SHA-256 gegen die Originalberichte geprüft.
- Originale Quellinventare vor und nach dem CI-Lauf bytegleich. Die erfassten 447 Host- und 1.256 Native-Dateien stimmen hinsichtlich Pfad, Modus, Git-Blob und Größe mit den exakt gebundenen Remote-Trees überein.
- Letzter Dartzustand und Native-Endzustand identisch: ACK 23, Revision 33, Exit bestätigt. Der ursprüngliche Bericht bindet fünf Sterne, 40 XP und das Wiederöffnen derselben Runde im verwendeten Test-Preferences-Backend.
- Alle 399 Originaldateien und der verwendete Reader blieben während dieser lokalen Lesekontrolle unverändert.

## Vier tatsächlich geöffnete Originalbilder

Der vorhandene TouchWorker hat die aktuellen Aufnahmen selbst geöffnet: leer 960×540, Gewinn 960×540, Portrait 1080×2400 und kleines Querformat 640×360. Die vier PNGs und die zugehörigen unveränderten Layoutberichte sind mitgesichert.

In der Portrait-Aufnahme sind „Brett ansehen“, „Neue Runde“ und „Gegen Lumo spielen“ vollständig sichtbar. Im kleinen Querformat zeigt der aktuelle Scrollausschnitt nur „Brett ansehen“ vollständig. Für die beiden unteren Aktionen vermerkt das Original-Layout bei Revision 29 / ACK 19 `clipped: true` und `hit_rect_px: [0,0,0,0]`. Das ist eine dokumentierte Grenze dieses Capturezustands, kein erneuter Nachweis des Freiscrollens und Betätigens.

Die separate R3-Bedienprüfung bleibt ein eigener Nachweis; sie wird nicht als Teil dieses neuen Standardruntime-Laufs ausgegeben.

## Grenzen

Dies ist eine Desktopprüfung mit lokaler Dateischnittstelle, Test-SharedPreferences, llvmpipe und vorgegebenen Android-artigen Insets. Die 24 FPS sind das konfigurierte Aufnahmeformat und keine gemessene Gerätebildrate. Die Quelle der Probe ist unverändert `scripts/tests/connect_four_runtime_regression.gd`, Blob `94c32597c0170c5c3199e39ca6fbfcc1caf25f99`; der Darttreiber ist `test/games/connect_four_runtime_bridge.dart`, Blob `6ae4695d06f955d5c9501bdce22ed9a83a0a26d0`.

Kein neuer Android-, Binder-, Disk-Persistenz-, APK- oder Play-Store-Nachweis wird daraus abgeleitet. Ein erfolgreicher Runtimejob ist keine Aussage über den späteren Abschluss des gesamten Mainlaufs. Es wurde kein weiterer Lauf ausgelöst und keine Produktdatei oder Ref geändert.
