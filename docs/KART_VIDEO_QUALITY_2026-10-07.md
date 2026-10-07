# Lumo Kart – visueller Teststand 0.10.9+1504

Dieser Teststand setzt die vier von Heinz gelieferten Videos als Gestaltungsreferenz
für App-Einstieg, Kart-Menü und Rennwelten um. Er wird als Draft-PR geprüft und
nicht automatisch nach `main` übernommen oder als Release veröffentlicht.

## App-Einstieg

Die native Lumo-Kart-Startkarte zeigt eine echte Aufnahme einer umgesetzten
Rennwelt, den bestehenden Lumo-Fuchs, den Startbutton „Losfahren“ und die
Katalogangaben „12 Welten“ / „5 Spielmodi“. Die Vorschau wird aus einer tatsächlich
von Godot gerenderten Aufnahme erstellt. Sie darf nicht durch ein Referenzvideo,
ein Werbebild oder einen nicht implementierten Spielstand ersetzt werden.

Cards und Kart starten weiterhin über die bestehenden Launcher. Ihre Schaltflächen
haben mindestens 48 dp Höhe. Bei großer Systemschrift werden die Karten
untereinander angeordnet; der Inhalt bleibt scrollbar. Der bestehende Resize-Test
prüft Cover, Fold innen, Tablet, zweifache Textgröße und die Rückkehr zum
Außendisplay mit derselben `GamesContent`-State-Instanz. Er prüft dabei für beide
Startbuttons sichtbare, vollständige Labels und erreichbare Touch-Flächen.

## Herkunft der Vorschau

Die erste App-Vorschau stammt aus einem früheren tatsächlichen Godot-Render
vom Quellstand `aaa0bb2202fb3d2567701f744f873c873b899a15`, Aufnahme
`candy_cloud-120.png`. Sie ist eine reine WebP-Konvertierung des vollständigen
1280×720-Renderbildes. Die Rennwelt-Geometrie entspricht dem neuen Kandidaten;
Himmel und Licht wurden danach weiter verbessert. Vorschau-Quellstand und
eingebetteter APK-Quellstand sind deshalb ausdrücklich getrennt dokumentiert.
Der nächste fertige Render des finalen Pins ersetzt nur Vorschau und Herkunft.

- Quell-PNG SHA-256: `ce3c1d828905b083ce681d0c11c7abedff121c956880153bd0785140a6d983c5`
- Vorschau-WebP SHA-256: `77e3d4d3251c677ca3afd6e482df6bc57958be471517b4f874dcdd83bf8e5b2c`

## Quellen und Build-Nachweis

Die verbindliche Godot-Revision steht in `config/godot-source.json`:
`0835a91017a5b0002440b5328e89ce12b1bb8a6d` (Godot 4.6.3). Der Build
exportiert diesen Quellstand in dieselbe APK und prüft Revision und PCK-Hash aus
den APK-Bytes. Der APK-Prüfer liest die Standardversion aus `pubspec.yaml`;
explizite Build-Variablen bleiben möglich.

Der Workflow `lumo-video-quality.yml` prüft die vollständige Flutter-Suite,
App-Analyse und native Vorbereitung und erzeugt echte App-Aufnahmen. Auf
demselben Runner checkt er den exakt gepinnten Godot-SHA separat aus und prüft
Import, tatsächliches GL-Rendering, Fold-Multi-Touch, Menüablauf und Fahrphysik.
Native Aufnahmen und Protokolle werden vor dem APK-Build als eigene Artefakte
hochgeladen. Die APK wird erst nach erfolgreichen nativen Prüfungen gebaut. Das
APK-Artefakt enthält `APK-VERIFICATION.json`, `BUILD-PROVENANCE.json`,
`SHA256SUMS.txt` und `TEST-RESULTS.txt` aus diesem Build.

Ein erfolgreicher CI-Lauf belegt weder die Gleichheit mit gerenderten
Referenzvideos noch eine gemessene Bildrate auf einem physischen Fold. Diese
Aussagen werden erst nach entsprechender visueller bzw. Geräteprüfung getroffen.
