# Build 2018: Integrations- und Auslieferungsnachweise

Stand: 13.11.2026. Diese Datei beschreibt tatsächlich ausgeführte Prüfungen und
die vorbereiteten Abnahmegrenzen. Sie ist keine Veröffentlichungsgenehmigung.
`main` wurde durch Team E nicht verändert. Nach tatsächlicher Native-Abnahme und
Sichtprüfung ist der Host lokal auf `0.13.6+2018` und den unten genannten exakten
Native-Pin umgestellt. Die signierte APK und ihre Android-/Upgrade-Prüfungen
stehen noch aus; aus der Quellfreigabe folgt keine bestandene Android-Tour.

## Ausführbare Werkzeuge und Grenzen

| Arbeit | Status | Tatsächlicher Nachweis / Grenze |
| --- | --- | --- |
| Godot-Szenen, Shader, Original-GLB und Animationen bearbeiten | direkt umsetzbar | Godot 4.6.3 vorhanden; echte Import-/Laufprüfungen |
| Geometrie erzeugen und Originalassets weiterverwenden | direkt umsetzbar | Blender 4.3.2 und programmatische Meshes verfügbar |
| Reale 3D-Rendererbilder prüfen | mit vorhandenen Werkzeugen umsetzbar | GitHub Linux/X11/llvmpipe liefert Original-PNGs; lokaler Displayzugriff für diesen Prozess nicht verfügbar |
| Flutter- und Python-Tests | direkt umsetzbar | Tatsächlicher Flutter-3.44.9-/Dart-3.12.2-Runner; reproduzierbare Gradle-9.1.0-Toolchain |
| Kotlin/Java-Androidhost kompilieren | mit vorhandenen Werkzeugen umsetzbar | Drei echte GitHub-Androidkompilierungen erfolgreich; zuletzt einschließlich Registry, Binder-Service und Start-Timeout |
| Signierte APK, Emulator-Tour, In-place-Update | mit vorhandenen Werkzeugen umsetzbar | Vollständige Pipeline auf den finalen Native-Pin vorbereitet; tatsächlicher 2018-Lauf steht noch aus |
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
| Godot `e181eeca2b33390c15c1c13a8ac6eb5924fb620d` | [Run 43360298305](https://github.com/Ullmann27/lumo-godot/actions/runs/43360298305): Gameplay und Lernpreview bestanden. Neue Gates 24 PASS, 1 FAIL ausschließlich wegen des 420-s-Lerncapture-Limits. Alle anderen Renderer-Proben liefen ohne die früheren GL-/Audio-Ressourcenfehler. Keine Gesamtfreigabe dieses SHAs. |
| Godot `cc6e95a9bb5f49b70758f6d749cec1504c986fcb` | [Run 43363455876](https://github.com/Ullmann27/lumo-godot/actions/runs/43363455876): beim Folgepush abgebrochen; 24 abgeschlossene neue Gates bestanden, vollständige Lerncapture unter dem gezielt auf 900 s angehobenen Budget. 66 neue PNGs vorhanden. Die tatsächlich geöffnete Pflanzenaufnahme zeigte jedoch den falschen Titel Blatt beim Blütentext; dieser Stand wurde nicht freigegeben. |
| **Godot `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`** | **[Run 43365141980](https://github.com/Ullmann27/lumo-godot/actions/runs/43365141980): alle drei Jobs SUCCESS, 25/25 neue Gates PASS, 66 neue Produktionsszenen-PNGs. Alle 14 gestarteten Native-Workflows einschließlich Stage 2 erfolgreich.** Neuer Welt-Lernlauf: 5.328 Prüfungen; Pflanzenüberschrift und tatsächlicher Neustart-Button-Lebenszyklus korrigiert. |

Die endgültige Sichtprüfungs-Receipt unter
`config/nextgen-2018-visual-review.json` bindet **18 unveränderte Originalbilder**
aus diesem erfolgreichen Gesamtartefakt an alle sieben bearbeiteten Module.
Beide neuen Pflanzenaufnahmen wurden von Root und Integration QA geöffnet:
neutraler Starttitel und korrekter Blüte-Titel beim Blütentext. Die 21 Lernbilder
des Gesamtarchivs sind byteidentisch zur freigegebenen 51fb-Vorschau; deren übrige
19 Bilder sind byteidentisch zu den zuvor gesichteten Originalen. Team B öffnete
alle 16 finalen Jump-Bilder, Team C alle 18 Garage-/Siedlungsbilder, Team D die
sieben Bauwelt-/Rhythm-Bilder und das Cards-Team alle vier Kartenstubenbilder.

Unveränderte API-Rohmetadaten, 25 Originallogs, Quellidentität, vollständige
Bildhashlisten, Agentenreviews und Capture-Messberichte liegen unter
`docs/evidence/nextgen-2018-reviewed/metadata/`. Der Gesamtjob dauerte 20:03 Minuten,
der Legacy-Gameplayjob 19:16 Minuten und die Lernvorschau 6:52 Minuten.

Die **tatsächlich am finalen SHA** gemessenen Cards-Draw-Calls betragen:

| Viewport | Dichte | Draw-Calls | Primitive |
| --- | --- | --- | --- |
| 1280 × 720 | 1 | 361 | 176.450 |
| 412 × 915 | 1 | 241 | 132.500 |
| 690 × 829 | 1 | 332 | 174.950 |
| 2400 × 1080 | 2,625 | 368 | 179.510 |

Quelle ist das unveränderte finale `cards-render.json`: 146 Raum-Boxen in 13
Materialgruppen, 20 tatsächliche Renderer-Transformprüfungen. Das sind Messwerte
des X11-Software-Renderers, keine Geräte-FPS-, Temperatur- oder Latenzabnahme.

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
| **51fb vollständige neue Evidenz** | `14010558382` | `84a71c209c7f01015b2dd1735d27087c40b2ed37fb022c406b959128d5e0bb4c` |
| **51fb Legacy** | `14010383559` | `4ab554f9f0942d4f4ffe783a7b3cc0d3e557f6390af122fe29ca0fd453d11435` |
| **51fb Lernpreview** | `14010108635` | `52e394e41ac9eb91975eabf9696ca4e57f5780110807b5d7f1f48534ca32513b` |

Im historischen 096-Lauf hießen die beiden fehlschlagenden Gates
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

Die tatsächliche Sichtprüfungs-Receipt ist jetzt `approved`; anschließend wurden
der exakte 2018-Pin und die bedingte Veröffentlichung aktiviert. Der Publisher
verlangt weiterhin erfolgreiche Jobs für vollständige Prüfung/Build, echte
Hostkompilierung, Android-Tour und unveränderte 2017→2018-Aktualisierung sowie die
erneute Prüfung von Quelle, PCK, APK, Signatur und Receipt. Diese Android-Gates
wurden für 2018 noch nicht ausgeführt. Kein Release wurde durch Team E erstellt.

## Lokal erneut ausgeführte Werkzeugtests

- **289 Build-/Daten-/Release-Vertragstests im tatsächlich auf 2018 umgestellten Checkout: bestanden, 21,354 Sekunden, 0 übersprungen.**
- **667 Android-Probe-/Evidenztests im selben Checkout: bestanden, 19,153 Sekunden, 0 übersprungen.** Diese Tests prüfen die Probeverträge und ersetzen keinen Emulatorlauf.
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

Der danach eingefrorene vollständige Flutterlauf einschließlich der gefundenen
Cards-Querformat-/Safe-Area-Korrekturen besteht tatsächlich mit **2.462 PASS,
0 FAIL, 0 SKIPs und 542 erzeugten PNGs**. Alle 47 geprüften geänderten Dartdateien
blieben während dieses Laufs unverändert. Ergebnis und Quellhashes liegen unter
`docs/evidence/nextgen-cards-header-20261113/full-flutter-final.json` und
`full-flutter-source-hashes.json`. Die anschließende 2018-Aktivierung ändert keinen
Dart-Produktivcode; die komplette Suite wird im finalen APK-Workflow erneut geprüft.

Die tatsächlichen lokalen Logs liegen in `qa/host/`. Die Anzahl bezieht sich auf
diesen Werkzeugstand und wird nicht für später veränderte Quellen wiederverwendet.
