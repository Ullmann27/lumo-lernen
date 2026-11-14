# Neue Studio-2020-Belege: gemeinsames Host-Evidenzpaket

## Zweck und Abgrenzung

Dieses Paket bereitet ausschließlich die dauerhafte Git-Sicherung vorhandener, explizit eingefrorener Belege vor. Es führt keine Gitmutation, keinen Test, keine neue Aufnahme und keine Produktinstallation aus. Die Originaldateien werden ohne lokale Datei- oder Archivkopie referenziert. Jede ausgewählte Datei wird erneut vollständig gelesen; Bytezahl, SHA256 und die angegebene Gitblob-ID werden geprüft. Fehlende Dateien oder abweichende Hashes verhindern ein fertiges Uploadmanifest.

Der von Root bestätigte vorherige Host-Evidenzstand ist `e423df58117c8f49bcd03c634e438392dc79c3ef`, Tree `61d1aa197fb28072ab9405039b0d171cb4ce1aea`, Branch `chatgpt/lumo-studio-4ab96666-evidence-20261114`, PR477. Dieses Paket ist eine ausdrücklich benannte Ergänzung; es behauptet keinen neuen Produkt- oder APK-Stand dieses Dokumentationsbranches.

## Eingefrorene Hauptgruppen

| Gruppe | Vorhandene Belegzeilen | Enthaltene Originale / Grenze |
| --- | ---: | --- |
| Original-Lumo-Gesicht | 109 | Blendergeneratoren, echte .blend-Autorenquelle, sieben Blenderbilder, acht produktive Godotbilder, Film und Sichtprüfung, Rig-/Neutralpose-/Ton-/Stumm-/Stoppnachweise, erhaltene Fehlversuche. Die 14 Produktquellen werden nicht erneut installiert. |
| Native-2020-Harness | 34 | Finale drei Quellen nur als Freeze/Diff beschrieben; echte Vertragslogs, ursprünglicher C4-Sichtbarkeitsfehler samt Korrektur, Sidecar-/Filmprüfung, unabhängige Treasure-Anschlussreview. Die drei eigentlichen Workflow-/Harness-/Testdateien werden nicht installiert. |
| Deutsche Cards-Rückmeldungen | 17 | Originalbefund, abgegrenzte Textkorrektur, ursprüngliche Rot-/Grünnachweise und Quellenbindung. |
| Creative: Native-Titelbefund | 80 | Tatsächliche Android-Ursachenauswahl, native Treasure-Titelkorrektur, deklarierte Save-/Inset-Fixture, vier echte neue Bilder und erhaltene Negativbefunde. Kein nachträglich erfundener Android-PASS. |
| Creative: Host-Prüfer | 13 | Enger Geometrie-/Bereitschaftsbefund und tatsächlich ausgeführte Vertragsprotokolle. |
| C4: native Sichtfixture | 19 | Vier echte Produktionsszenenbilder und Sidecar, ausdrückliche Headless-Ablehnung, sichtbare und erreichbare Eingabeziele. Die legalen Fixturezustände ersetzen keine echte Dart-/Androidrunde. |
| C4: ursprünglicher Android-Prüfer | 7 | Quellenbindung, ursprüngliche Prüferverträge und Scope. |
| C4: Deadline-Nachtrag | 8 | Begrenzte Bereitschaftskorrektur, erhaltene Rot-/Grünlogs. |
| Android-Verträge 2020 | 18 | Gezielte Versions-/Identitätsvertragsnachweise einschließlich abgegrenzter unveränderter Schema-Auszüge. Diese Auszüge bleiben Dokumentationsdateien. |
| Releaseaudit | 6 | Lesender Versions-/Release- und Quellenbefund, kein Freigabeersatz. |

Diese zehn Hauptgruppen umfassen **311 Belegzeilen**. Hinzu kommen die einzeln manifestierten unabhängigen Reviews. Alle verwendeten Eingangsmanifeste werden selbst unverändert als Provenienzdateien aufgenommen. Die endgültigen verifizierten Zahlen stehen im erzeugten `verification.json` und `upload-manifest.json`.

## Bereits vorhandene lokale Ergebnisse

Die folgenden Aussagen beziehen sich auf die erhaltenen Originalberichte, nicht auf einen neuen Testlauf durch dieses Sammelpaket:

- Facial: gezielte Regression mit 102 Prüfungen, 23 WAV-/Envelope-Verträge und 17 Wiedergabe-/Lebenszyklusverträge. Die echte produktive Godot-Aufnahme enthält 144 Zustandsmessungen und 148 dekodierte Videoframes. Sie zeigt die Originalfigur, echtes Blinzeln, Blickänderung und amplitudenabhängige geschlossene Schnauzenartikulation. Sie belegt keine vollständige phonembasierte Lippenanimation, keine neue Androidtonausgabe und keine Geräte-FPS.
- Harness: 13/13 gezielte Tests, 0 Skip, Bash-Syntax und actionlint bestanden. Alle 16 früheren Aufrufe und 37 ursprünglichen Bilder bleiben erhalten; die neuen Pflichtquellen sehen 20 Prüfungen und 53 PNGs vor. Der zunächst falsche pauschale C4-Sichtbarkeitsvertrag bleibt als Rotbeleg erhalten und wurde passend zum Produktlayout korrigiert.
- C4-Bildfixture: tatsächlicher Renderer mit 303 Prüfungen und vier Bildern, ausdrücklich schreibgeschützter Fixturehost. Sichtbarkeit von Lumo ist formatabhängig. Keine eigenen bestätigten Spielzüge oder künstlichen Save-ACKs werden als Androidbeweis ausgegeben.
- Treasure-Titel: tatsächlicher neuer Rendererbericht mit 137 Prüfungen, vier Formaten und gemessenem Kontrast von etwa 14,44 über weißem Hintergrund. Die bestehende Porträtellipse bleibt eine dokumentierte Grenze. Die Fixture- und Desktopbelege werden nicht als ausgeführte Androidfolgeprüfung bezeichnet.

Die unabhängigen Reviewnotes dokumentieren genau ihren jeweiligen Quellenstand und Prüfumfang. Insbesondere die Workflowreview hält einen damaligen Entwurf mit noch ausstehendem C4-Publisher fest; sie darf nicht zur Freigabe einer später veränderten Integration umgedeutet werden.

## Aktueller veröffentlichter Quellenstatus

Root meldete nach tatsächlicher serverseitiger Prüfung die Veröffentlichung von Native2020: Commit `8be3a95d5d948d457c4c39bc6694138d60b70027`, Tree `9edd7afed143c83fec5d2dc89949ca9325e042ce`, Branch `chatgpt/lumo-studio-2020-20261114`, DraftPR167. Der tatsächliche Lauf `43561885899` war bei dieser Nachricht **in_progress**. Diese Statusangabe stammt aus Roots aktueller GitHub-Prüfung; die vorliegende Paketierung führte keine eigene CI-Abfrage aus.

**Ein Native-2020-PASS, ein freigegebener neuer Hostpin oder eine Android-2020-Abnahme wird hier nicht behauptet.** Root-Integrationslogs, der neue C4-Publisher und dessen spätere Closure sowie aktuelle oder zukünftige CI-/Androidartefakte bleiben bewusst außerhalb dieses Freeze.

## Dateierhalt und Upload

- Originalbytes werden nicht per Textnormalisierung, Bildkonvertierung oder Archiv-Neupackung verändert. Auch leere Fehlerlogs bleiben als echte Originaldateien erhalten.
- Überschneidungen am selben Zielpfad werden ausschließlich nach vollständiger Bytegleichheit zusammengeführt. Verschiedene ausdrücklich vorgegebene Dokumentationspfade bleiben für relative Verweise und die Herkunft erhalten; identische Gitblobs können beim Upload einmalig wiederverwendet werden.
- Rotläufe, verworfene Zwischenstände und ihre ursprünglichen Quellen-/Hashangaben bleiben erkennbar. Keine alte Quelle oder Bildabnahme erhält die neue Native-SHA.
- Keine APKs, PCKs, ZIP-Archive, Import- oder Shadercaches werden aufgenommen. Der tatsächliche Facialfilm ist 1.178.091 Bytes groß. Es gibt in der ausgewählten Liste keinen Film über 10 MB; daher sind keine Teile und kein Reassembler erforderlich. Die größte ausgewählte Datei, die Blender-Autorenquelle, bleibt mit 5.746.571 Bytes unter der einzelnen Git-Requestgrenze nach Base64.
- Das Uploadmanifest enthält ausschließlich Ziele unter `docs/evidence/` im Hostrepository `Ullmann27/lumo-lernen`. Quellmanifeste werden als unveränderte Dokumente bewahrt, ihre darin benannten Produktdateien aber nicht rekursiv übernommen.

## Wiederholbarer Bytecheck

```sh
python3 verify_and_prepare_manifest.py --registry input-manifests.json --output .
```

Der Prüfer verarbeitet nur die explizite Liste; er entdeckt oder übernimmt keine weiteren Dateien automatisch. `verification.json` enthält jede tatsächlich geprüfte Originalidentität und ausgeschlossene Produktzeile. `upload-manifest.json` trägt für jedes Uploadziel den vorhandenen Originalpfad, Gitmodus, Bytezahl, SHA256, Gitblob-ID und die Eingangsmanifest-Herkunft. Das Uploadmanifest selbst wird separat über seinen endgültigen Dateihash übergeben, um eine zirkuläre Selbsthashreferenz zu vermeiden.
