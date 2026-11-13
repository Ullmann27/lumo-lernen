# Build 2018: Integrations- und Auslieferungsnachweise

Stand: 13.11.2026. Diese Datei beschreibt tatsächlich ausgeführte Prüfungen und
die vorbereiteten Abnahmegrenzen. Sie ist keine Veröffentlichungsgenehmigung.
`main` wurde durch Team E nicht verändert; Version und endgültiger Native-Pin
sind während der visuellen Nachbesserung noch nicht freigegeben.

## Ausführbare Werkzeuge und Grenzen

| Arbeit | Status | Tatsächlicher Nachweis / Grenze |
| --- | --- | --- |
| Godot-Szenen, Shader, Original-GLB und Animationen bearbeiten | direkt umsetzbar | Godot 4.6.3 vorhanden; echte Import-/Laufprüfungen |
| Geometrie erzeugen und Originalassets weiterverwenden | direkt umsetzbar | Blender 4.3.2 und programmatische Meshes verfügbar |
| Reale 3D-Rendererbilder prüfen | mit vorhandenen Werkzeugen umsetzbar | GitHub Linux/X11/llvmpipe liefert Original-PNGs; lokaler Displayzugriff für diesen Prozess nicht verfügbar |
| Flutter- und Python-Tests | direkt umsetzbar | Tatsächlicher Flutter-3.44.9-/Dart-3.12.2-Runner; reproduzierbare Gradle-9.1.0-Toolchain |
| Kotlin/Java-Androidhost kompilieren | mit vorhandenen Werkzeugen umsetzbar | Drei echte GitHub-Androidkompilierungen erfolgreich; zuletzt einschließlich Registry, Binder-Service und Start-Timeout |
| Signierte APK, Emulator-Tour, In-place-Update | mit vorhandenen Werkzeugen umsetzbar | Vollständige Pipeline vorbereitet; erst nach finalem Native-Pin ausführbar |
| Samsung Z Fold7, Android 17, Temperatur/Touchlatenz/60 FPS | derzeit blockiert | Kein physisches Zielgerät angebunden. Linuxbilder und Android-35-x86-Emulator ersetzen diesen Nachweis nicht. |

## Tatsächlich vorhandene CI-Belege

| Exakter Source | Tatsächliches Ergebnis |
| --- | --- |
| Godot `d66aaebf9185e8b86d9d09d8a66149860239c6e2` | [Run 43351450613](https://github.com/Ullmann27/lumo-godot/actions/runs/43351450613): vollständige Gameplay-/Action-/2014-/Technical-Art-Gates und damals 20 neue Gates bestanden. 71 PNGs aus dem neuen Artefakt plus 22 aus dem Legacy-Artefakt heruntergeladen. Dieser Zwischenstand erhielt keine endgültige visuelle Freigabe. |
| Flutter `2d36496d5ed3684d52dab633b6e9a5d24cef0456` | [Run 43351542336](https://github.com/Ullmann27/lumo-lernen/actions/runs/43351542336), Job `131643514999`: echte Kotlin-/Java-Kompilierung, `BUILD SUCCESSFUL in 2m 57s`, 107 Tasks; ursprüngliche Cards-IPC- und Offline-Speech-Quellen enthalten. |
| Flutter `c9e05e24db94e4d366acca0255925ef7c46a6f7a` | [Run 43353261145](https://github.com/Ullmann27/lumo-lernen/actions/runs/43353261145), Job `131649128007`: erneut echte Kotlin-/Java-Kompilierung, `BUILD SUCCESSFUL in 3m 26s`, 107 Tasks. Neuer CardsAuthorityService und aktuelle Lebenszyklusänderungen enthalten. Keine APK oder Android-Laufzeitfreigabe daraus ableiten. |
| Flutter `8a228c53c342675fd89b6ab9b662d40fb60a8535` | [Run 43357088248](https://github.com/Ullmann27/lumo-lernen/actions/runs/43357088248), Job `131661587570`: `BUILD SUCCESSFUL in 3m 16s`; neun echte Bytecodeklassen einschließlich Registry/Service nachgewiesen. Davor sechs Produktionsregistry-/Installerprüfungen bestanden. APK-Pinprüfung bleibt bis zur 2018-Freigabe gesperrt, Android-Tour/Upgrade/Veröffentlichung wurden nicht ausgeführt. |
| Godot `096c9d20a3a1b92605e0a4f648e1afd87f967b9a` | [Run 43354218466](https://github.com/Ullmann27/lumo-godot/actions/runs/43354218466): fokussierter echter Lernrenderer mit 21 PNGs erfolgreich. Neue Gates: 23 PASS, 2 FAIL; alle 75 Originalbilder des Gesamtartefakts heruntergeladen. Settlement-/Umgebungsproben scheitern nach ihren Spielaussagen an geleakten GL-Texturen. Legacy-Action-Job scheitert nach seinen 24 Lasso-Aussagen an vier noch referenzierten Ressourcen beim Prozessende. Diese Fehler werden nicht ausgefiltert. |
| Godot `c5c71145ffaa9ca90b501c5020967b8d5062c387` | [Run 43358819881](https://github.com/Ullmann27/lumo-godot/actions/runs/43358819881): Lernpreview 21 Bilder bestanden. Voller Job vor Abschluss abgelöst: Settlement-Parsefehler nach Formatierung; Lerncapture im parallelen Gesamtlauf nach 18 Bildern am 420-s-Limit. Unabhängiger echter Environment-Render: 53 PASS, sauberer Exit ohne frühere GL-Texturfehler. Teilarchiv enthält 48 PNGs, keine vollständige Freigabe. |
| Godot `e181eeca2b33390c15c1c13a8ac6eb5924fb620d` | [Run 43360298305](https://github.com/Ullmann27/lumo-godot/actions/runs/43360298305): korrigierter Settlement-Callback. Lernpreview erneut 21 Bilder bestanden, jedes PNG nach tatsächlichem Hashvergleich byteidentisch mit dem vollständig gesichteten c5-Lernbild. Die übrigen Jobs laufen zum Zeitpunkt dieses Berichts noch; keine Gesamtabnahme daraus ableiten. |

Verifizierte ZIP-Digests:

| Artefakt | ID | SHA-256 |
| --- | --- | --- |
| d66 neue Szenen | `14004132755` | `f47d73df4c3084f644238555666959ab3f29c0d9e121c60932b9273739384fc0` |
| d66 Legacy | `14003839859` | `b0856ec0a3bed5637a55c0701dbdbbf5241bbac1d3b2008fafb25a71ce2170a6` |
| Host c9 Kompilierung | `14005081851` | `25cc600debde803e062bbf67ce2723c888c94e14e0dc923b78e9177823beae74` |
| Host 8a Kompilierung | `14005894311` | `d10c8b64bcb62fc530ac4b13c599011594fea811a9c999f6b6d4d00a06b671cc` |
| 096 Lernpreview | `14006155015` | `56bf30015a3de03869146941fb167dbc5eb0a0c656a4d0ed07ed38c2bc6f5ac7` |
| 096 alle neuen Szenen | `14006170582` | `32fa6f43a54bf4940bb7e46b7d6ec86f2a36e585f08860974fa2b2a68e930607` |
| c5 Lernpreview | `14007781236` | `7870ab42d73de43d9980f5c344136a34fadae58a3fb8ca2e25b22ed2ecaebe3a` |
| c5 Teilarchiv | `14007662211` | `64edf232ad0793f53d6aa334a5d224f045622a167b7dc2db4b0bf73341a484c2` |
| e181 Lernpreview | `14008426690` | `336cd3f4fecd08495273354d406a8b86d32a2516f0f93490425e0b40f586aeb1` |

Die beiden neuen fehlschlagenden Gates heißen
`build_settlement_play_regression/rendered` und
`creative_nextgen_environment_regression/rendered`. Sie erreichen 114 bzw. 48
Aussagen; die anschließenden Rendererfehler über jeweils 21.844 Byte große
Texturen machen diese Läufe trotzdem ungültig. Die unabhängigen Bilder anderer
Module werden weiterhin erstellt. Die Rhythm-Bilder dieses SHAs gehören zum
damaligen 48-/54-Aussagen-Stand, nicht zum später lokal erweiterten Test.

## Sichtprüfung der 21 Lernbilder aus 096c9d20

Alle 21 Originalbilder wurden geöffnet. Die Zehnerfelder zeigen jetzt die
Zustände 8, 10 und 13 getrennt; die Hochformatansicht nutzt die verfügbare Fläche.
Subtraktion zeigt tatsächlich acht verbleibende Würfel und fünf weggenommene.
Pflanzenteile und die drei vollständig gefüllten Vierergruppen sind erkennbar.

Vor einer Freigabe gemeldete Restfehler:

- `syllables-start.png`: untere Glyphenteile auf den drei Start-Silbenblöcken verdeckt.
- `fraction_parts-complete.png`: räumliche Beschriftung weiterhin `1/4`, obwohl drei Viertel gefüllt sind.
- `bridge_hundred-start.png` und `bridge_hundred-complete.png`: der vorhandene Hunderter ist als kleiner unbeschrifteter Block nicht eindeutig vom Zehnermaterial unterscheidbar.
- `fraction_parts-start.png`: Zusatzteile werden teilweise vom unteren Bedienfeld verdeckt.
- Helle gelbliche Bodenflächen, starke Glanzstellen am Fuchs und große graue Randflächen im dichten Querformat bleiben Gegenstand der visuellen Überarbeitung.

Diese Feststellungen wurden Team A und der Integration gemeldet. Ein bestandener
Capture-Marker ersetzt weder diese Sichtprüfung noch die notwendige Korrektur.

## Neue verbindliche Auslieferungsgrenzen

Die neue Host-Pipeline erhält die historischen 2017-Releasegates und ergänzt:

1. Eigenständige echte Hostkompilierung mit neun Pflichtklassen einschließlich `CardsAuthorityService.class` und `CardsAuthorityRegistry.class`. Der Compile-Job führt davor die Produktionsregistry in fünf tatsächlichen JVM-Szenarien sowie den Android-Installervertrag aus; auch deren Log wird archiviert.
2. Alle Fluttertests ohne übersprungene Tests; die gesetzten Capture-Verzeichnisse, Einzeldateien und tatsächlich erzeugten Bildzahlen werden im Ergebnis ausgewiesen.
3. Vollständige alte Native-Gates sowie die neuen Produktionsszenen; unabhängige
   Prüfungen sammeln bei einem Fehler weiter Bilder, die Gesamtabnahme bleibt `FAIL`.
4. Tatsächliche Android-Oberflächenprobe: Zehnerbrücke über die sichtbare Flutterroute,
   fünf echte Bewegungen, unveränderte Lernwerte und Rückkehr zur gleichen Aufgabe.
   Zusätzlich ist die technische Sprachprüfung vorbereitet: vorhandene sichtbare
   lokale Modellfreigabe, unveränderte Mikrofon-/Cloudfreigaben, Flugmodus sowie
   echte MediaPlayer-Start-/Endemeldungen für Eingangserklärung und gesprochenes
   Ergebnis nach der fünften Bewegung. Der isolierte Sprachprozess muss bei der
   Rückkehr beendet sein. Diese neue Androidprüfung wurde noch nicht ausgeführt.
   `-noaudio` erlaubt ausdrücklich keine Abnahme hörbarer Qualität oder Lippensynchronität.
5. Tatsächliche Kartenstube: zwei native Ziehen-Aktionen mit Dart-ACK und Speicherung,
   vollständige 112-Karten-Erhaltung, Kind-/Rundenidentität, sichtbare OS-Servicebindung
   vor und nach mindestens 35 Sekunden, Pause, Rückkehr und Wiederöffnung.
6. Echtes unverändertes 2017-Paket als In-place-Updatebasis.
7. Veröffentlichung ausschließlich nach genauer Quell-/PCK-/APK-/Signaturprüfung und
   einer expliziten, an den finalen Native-SHA gebundenen Sichtprüfungs-Receipt.

`publish-reviewed-2018` ist ausdrücklich deaktiviert. Die Receipt unter
`config/nextgen-2018-visual-review.json` bleibt `pending`. Der Vorbereiter
`scripts/record_nextgen_visual_review.py` kann erst nach tatsächlicher Sichtung
Original-PNGs aus einem SHA-geprüften erfolgreichen CI-Archiv übernehmen. Er prüft
den Source im Archiv, das vollständige Native-CI-Ergebnis und die Abdeckung aller
sieben bearbeiteten Produktionsszenen. Er aktiviert die Veröffentlichung nicht.

## Lokal erneut ausgeführte Werkzeugtests

- 287 Build-/Daten-/Release-Vertragstests nach Sprach-Evidenzintegration: bestanden, 20,939 Sekunden, 0 übersprungen.
- 667 Android-Probe-/Evidenztests: bestanden, 19,621 Sekunden, 0 übersprungen.
- 3 Native-Runner-Orchestrierungstests: bestanden; ihre Fake-Engine prüft ausschließlich
  Fehlerfortsetzung und Ablehnung, niemals Grafik oder Gameplay.
- 6 neue Delivery-/Receipt-Tests plus 5 Workflow-Tests: bestanden; synthetische
  Testfixtures werden ausdrücklich nicht als Render-/APK-Evidenz gespeichert.
- Alle Shellblöcke des neuen Hostworkflows: `bash -n` erfolgreich.

Der erste vollständige lokale Flutterlauf auf dem integrierten Arbeitsstand
endete mit **2.427 PASS, 2 FAIL, 0 SKIPs**, Exitcode 1 und 530 echten PNGs. Beide
Fehler lagen im Elternbericht-Privacytest: durch wiederholte Diagnosequalifizierung
verdrängte die Promptgrenze zwei der acht erwarteten Themen. Der Fehler wurde
Team B gemeldet; dieser fehlgeschlagene Gesamtbeleg bleibt erhalten unter
`qa/host/full-acceptance-d4bcb495/`. Er ist keine Freigabe der danach geänderten Quellen.

Die anschließend ergänzte Capture-Sammlung wurde separat tatsächlich ausgeführt:
15 Tests bestanden, keine übersprungen, Exitcode 0; sechs aktuelle Lesebilder,
zwei Lern-DNA-Bilder und ein Pokalbild liegen unter
`qa/host/new-module-capture-acceptance-corrected/`. Der erste Versuch wies dem
Pokalexport irrtümlich einen Ordner statt eines PNG-Dateinamens zu und scheiterte;
der korrigierte Runner unterscheidet jetzt Ordner und Einzeldateien. Die vollständige
Flutter-Suite muss am endgültigen CI-Commit erneut erfolgreich laufen.

Die tatsächlichen lokalen Logs liegen in `qa/host/`. Die Anzahl bezieht sich auf
diesen Werkzeugstand und wird nicht für später veränderte Quellen wiederverwendet.
