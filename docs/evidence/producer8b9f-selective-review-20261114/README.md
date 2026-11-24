# PR503 / PR182: selektiver Anschlussvorschlag

## Entscheidung

**Noch keine gemeinsame Integrationsfreigabe.** Dieser Pack bereitet eine spätere, explizite Übernahme vor. Es wurde keine Produktquelle zusammengeführt, kein Test ausgeführt, kein CI-Lauf gestartet und kein Git-Ref geändert.

Der bei diesem historischen Snapshot tatsächlich beobachtete Host-Producer ist `8b09c48ba8e4b41e8b25521b022d4d64ba4bb2bc` (Tree `ccd45e1ae122ce1b1997e6fa6feb948dc39dccaf`, PR503). Native ist `9f2e865614262c7176f9fdd987766ff5e45f2551` (Tree `8e29d5a15a424b42f27184a763adce8b2aa71b13`, PR182). Beide Heads wurden innerhalb dieses Snapshots durch die reine Metadatenfunktion bestätigt. Die neueren PR-Beschreibungen nennen ihre offenen Fehler ausdrücklich; ältere Beschreibungen bleiben als Originale erhalten.

Zielbasis dieses Vorschlags ist ausschließlich Host `0b7bacadd3cdc45d22a8e038c5df50ba8b739d62` / Tree `f3a7df4c3112ac63577db00a9637facfea5c0175` mit Native `baf148b03a7a32c6ad9f737d731f900eb9113ea1` / Tree `0c18a0ca5200ade267cfedb4c12d5c4b0a761a00`. Die laufende Abnahme dieses Zielstands wurde durch diese Arbeit nicht verändert.

## Zeitliche Grenze dieses Pakets

Root meldete am selben Tag spätere Heads Host `50503fef8e93700d9a889e33c3d2c37fccb46e42` und Native `47ca642aad9290c9ba274b08e7dadfc953854d4f`. Diese späteren Änderungen und Ergebnisse werden ausschließlich im getrennten `producer-pr503-pr182-followup-50503f-47ca64-20261114` bewertet. Sie schreiben weder die hier gebundenen Quellen noch deren tatsächliche Fehler um. Dieser historische Pack stellt die unten genannten Heads nicht als neuesten verfügbaren Producerstand dar.

## Tatsächliche Producer-Ergebnisse

| Quelle und Lauf | Tatsächliches Ergebnis | Reichweite |
| --- | --- | --- |
| Host8b, Run43604481767 | Gesamt FAIL. Vollständiger Flutterlauf: 2606 PASS, ein Memory-Fehler, 0 Skips | Fokussierte Wallet/Profile30, Quiz46 und Memory29 waren zuvor erfolgreich; Androidklassen und28 JVM-Verträge ebenfalls erfolgreich. Die abschließende Source-Clean-Prüfung nach dem vollen Flutterlauf wurde wegen dessen Fehler übersprungen. |
| Host8b, Living-Run43604484826 | 2410 PASS,196 Skips, derselbe einzelne Memory-Fall FAIL | Vollständiger Originalstack: `game_round_regression_test.dart:191`, erwartete Gewinnanzeige „Du hast gewonnen!“ fehlt. Diese Zählung gehört zu diesem separaten Job. |
| Hostc0ca, Run43603088266 |25 PASS/4 FAIL in der fokussierten Memory-Gruppe | Historische Profilfehler; der volle Flutterlauf wurde damals nicht erreicht. Sie werden durch spätere Teil-PASS nicht umgeschrieben. |
| Native9f2, Run43603969762 | Englisch SUCCESS, Memory SUCCESS, Quiz FAIL | Echte Desktop-Dart-/Godot-Prozesse, ausdrücklich gepaart mit Hostc0ca. Kein Nachweis für Host8b oder unsere Zielkombination. |

Der vollständige Stack des Hostfehlers dieses Snapshots ist aus einem unabhängigen Job desselben Heads gesichert. Der betroffene unveränderte Regressionstest hat sowohl im Producer-Basisstand als auch im aktuellen Ziel0b7 den Gitblob `8c626ae023d54c33b72b80d8cb167d98258a34be`. Aus dem fehlenden Dialog allein wird keine ungeprüfte Produkt- oder Testursache abgeleitet. Der Producer bearbeitet diesen Fehler bereits; es wurde keine parallele Reparatur begonnen.

Memory ist auf Native9f2 tatsächlich vorhanden: Szene, Presenter,13 Originalbildreferenzen und Rückkehr-/Persistenzpaarung. Der echte Lauf meldet `MEMORY_VIEW_PASS checks=7020 captures=8`, danach244 Laufzeitchecks/57 Inputs und erfolgreichen Paarabschluss. Englisch meldet3299 Checks/10 Captures/98 Inputereignisse nach dem tatsächlichen Dartproducer. Quiz scheitert dagegen bei der Prüfung des ersten aufgedeckten Ergebnisses mit62 Checks/3 Captures. Die spätere Producerbeschreibung nennt eine erlaubte null-Erklärung und eine gesonderte50:50-Darstellung als laufende Reparatur; diese unveröffentlichten Arbeiten sind keine übernommenen Quellen oder neuen PASS.

Die Detailbelege, vollständigen Joblogs, Originalmetadaten und exakten Zeilenschnitt-Hashes stehen in `ci-observations.json` und `originals/`. Das342.924.933-Byte-Flutterarchiv wurde nicht heruntergeladen; sein tatsächliches API-Objekt und Digest sind gebunden. Keine rendererbezogene Bildsichtung, installierte Android-APK, produktive Wallet- oder FPS-Abnahme wird hier behauptet.

## Präzise Übernahmefläche nach Producer-Fertigstellung

`selective-integration-manifest.json` listet jeden Pfad mit Producer-, Basis- und Zielblob. Von47 Host-Deltapfaden sind43 Produkt-, Test- oder Vertragsquellen relevant:31 neue Pfade,8 Änderungen auf einer mit0b7 identischen Dateibasis und4 erforderliche Zusammenführungen. Die43 vollständigen Producer-Texte sind jeweils gegen den veröffentlichten Gitblob geprüft. Neue Dateien aus vollständigen API-Patches wurden nur bei exakt passendem Gitblob akzeptiert; die Materialisierungsmethode ist pro Datei ausgewiesen.

| Gemeinsamer Hostpfad | Vor einer späteren Übernahme zwingend erhalten |
| --- | --- |
| `lib/features/lumo3d/lumo3d_launcher.dart` | Explizite Dorfwahl, Settlement-Parameter und vorhandene Learning/Build/Settlement-Sprachweitergabe; nur TableToken-Vertrag ergänzen. |
| `tools/auto_install/MainActivity.kt` | Dorfvalidierung und Allowlist, lokale Sprachgrenzen, bestehende Cards-/C4-Autorität und Rückkehrkette; Memory/Quiz-Autorität additiv verbinden. |
| `scripts/tests/test_embedded_android.py` | Vollständiger aktueller Cards-Window-Testblock und dessen JVM-Adapter. Producer-Erwartungen für die zusätzliche private TableActivity/Service hunkweise ergänzen. |
| `scripts/compile_android_host.sh` | Bestehende tatsächliche Compiler-/Klassenbelege. Neue fünf Table-Klassen ergänzen. Die Producerbasis enthält daneben zusätzliche C4-/Envelope-Aufzählungen; ein vollständiger Dateiersatz ist deshalb keine automatisch freigegebene Minimaländerung. |

Die getrennten Vorher-/Producer-Vergleiche liegen unter `comparisons/`; sie sind Beobachtungsdiffs, kein angewandter Integrationspatch. `collision-review.json` beschreibt die konkreten Erhaltungsverträge. `dependency-review.json` bindet134 relative Dartverweise ohne fehlenden Quellpfad. Dies ist eine statische Pfadprüfung, kein Compiler- oder Auflösungserfolg. Pubspec, Lockfile und Quellenpins bleiben unverändert.

Die neuen Bereiche sind der dauerhafte Memory-Rundencontroller mit Scheduler/Flutter-/Tableadapter, die Quiz-Runde samt öffentlichem Zustand und Repository, geprüfte Englischdeskriptoren sowie der gemeinsame private Android-Tabletransport. AppState und Wallet müssen zusammen mit ihren Profil-/Lease-/Idempotenzverträgen betrachtet werden. Eine erfolgreiche isolierte Darstellung ersetzt diese Vertragsprüfung nicht.

Native umfasst30 relevante Pfade:13 neue Pfade für bereits im Host0b7 vorhandene Original-PNG-Blobs,13 neue Textdateien,2 basisgleiche Änderungen und2 Stellen mit jüngeren integrierten Quellen. Die originalen Assets wurden nur anhand exakter Gitblobs zugeordnet, nicht erneut heruntergeladen. Der gesonderte Native-Peerbericht ist vollständig und bytegleich unter `independent-native-review/` enthalten; `independent-native-review-binding.json` bindet alle kopierten Originaldateien.

## Ausschlüsse und noch offene Abnahme

Die zwei Host-Workflowänderungen, der fremde Visual-Receipt und reine Producer-Dokumentation werden nicht importiert. Der Native-Producerworkflow und seine Dokumentation dienen ebenfalls nur als Quellen-/Gatebeleg. `protected-target-paths.json` bindet40 konkrete unverändert zu erhaltende Zielpfade, darunter Writer, Journal, InkSurface, Kamera, Diktat samt repariertem Fortschrittstest, Math, C4, lokale Sprache und unsere Android-/Pinprüfer. Weitere Dateien außerhalb des expliziten Manifests sind kein Übernahmeauftrag.

Vor einer tatsächlichen Verbindung fehlen der erfolgreiche aktuelle Memory-Vollsuitelauf, der reparierte echte Quizpaarlauf, eine ausdrücklich gepaarte aktuelle Host-/Nativequelle sowie der neue kombinierte Quellcheckpoint. Danach bleiben die bestehenden52/17-, Dream-, Discovery-, Dorf-, C4-, Cards-, Sprach-, Garage- und Updategates bestehen. Neue Memory-/Quiz-/Englischverträge und echte aktuelle Android-Einstiegs-, Save-, Besitzer- und Rückkehrbelege müssen zusätzlich gebunden werden. Dieser Pack verändert diese Gates nicht und überträgt keine grünen Ergebnisse auf eine ungetestete Kombination.

## Originaltreue

Alle gespeicherten API-Texte werden vollständig als UTF-8 zurückgelesen; JSON-Dateien werden vollständig geparst. Die späteren `get_pr_info`-Antworten sind ausdrücklich vollständige normalisierte Connectorantworten und keine behaupteten Roh-REST-Bytes. Zwei generische PR-Fetch-Fehler bleiben separat erhalten. Das Abschlussinventar und der komprimierte Gesamtpack werden vollständig zurückgelesen und je Mitglied gegen SHA256 geprüft. Es sind keine APKs, großen CI-Archive, Zugangsdaten oder signierten Download-URLs Teil dieses Packs.
