# Vorbereitung: zwei tatsächlich bediente Ergebnisaktionen bei 640 × 360

## Gegenstand und aktueller Stand

Dieser eigenständige QA-Entwurf schließt genau die Abdeckungsfrage aus dem
originalen Desktop-Artefakt 14112302039: Im kleinen gewonnenen Vier-gewinnt-Dialog
lagen **Neue Runde** und **Gegen Lumo spielen** unterhalb des sichtbaren
Scrollausschnitts. Der bisherige Lauf belegte dort lediglich **Brett ansehen**.
Das ist eine fehlende Bedienabdeckung; daraus wurde kein Produktfehler abgeleitet.

Die vier neuen QA-Dateien sind vorbereitet und unabhängig im Quelltext gelesen.
Sie verändern weder Produktdateien noch die bisherigen Release-Allowlisten.
Der erste, noch unreferenzierte QA-Commit
`a452610746973dd75684192ba04fdc8261d51d8b` wurde vor dem tatsächlichen Godot-
Parserbefund erstellt. Er enthielt den inzwischen ersetzten nativen Entwurf
`92368c1e776c3b32ed2147127ea0c5d52f66df70` und darf nicht als finale QA-Quelle dienen.
Maßgeblich ist der nachstehende Vierersatz mit der eng korrigierten und tatsächlich
geparsten GDScript-Datei. Root hat ihn als separaten QA-Commit
`dc2e1b50ebeadb895aa691d809f2c457e0142633`, Tree
`f332fbe5593d1f18dba5f93e01a7d2c3112fb99e`, mit alleiniger Parent-Quelle `aab09275…`
veröffentlicht. Tatsächlich beobachtet ist Run
[43594135818, Attempt 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43594135818),
ausgelöst durch `push`, mit genau diesem QA-Head. Bei der Übergabe dieses
Vorbereitungsbelegs war er in Bearbeitung; sein Runtime-Schritt war noch nicht
abgeschlossen. Lokal wurde kein Spiel oder Renderer gestartet. Ein tatsächliches
Ergebnis der beiden Aktionen darf erst aus dem separat zu prüfenden abgeschlossenen
CI-Lauf stammen.

## Unveränderte Produktquellen

| Quelle | Commit | Tree |
|---|---|---|
| Host | `aab09275ec6b5808de9be539ca4e1a7e70921249` | `baaa84b40b09e61d144f158e5b35a1c4dc5d2ef0` |
| Native | `e2d15dbc5f3709306decb139eeb70a1cf30c0b73` | `ea0f73ae6aad8792a963cadaa483c290a2f2a62e` |

Der neue QA-Commit muss ein eigener direkter Child des genannten Hosts sein und
genau diese vier Dateien hinzufügen. Ein gemischter Produkt-/QA-Commit wird vom
Vorprüfer abgelehnt. Vorbereitungsevidenz gehört deshalb in einen getrennten
Evidenzcheckpoint und nicht als fünfte Datei in diesen QA-Commit.

| Neue Datei | Git-Blob |
|---|---|
| `.github/workflows/lumo-c4-small-result-actions-qa.yml` | `5c4b9ef0d35c73934030e472d50157c92db468fa` |
| `scripts/run_connect_four_small_result_actions_qa.py` | `d5038a4e41c5cbf45b7df7e40f936f3091cf40c5` |
| `test/games/connect_four_small_result_actions_qa.dart` | `0585ee1b83725a588ea2ed6f6d4ec87ffc525d7e` |
| `tools/qa/connect_four_small_result_actions_qa.gd` | `cc9ef04069bb2d73d2953a725e7ee5974e5b496f` |

Die neuen Dateien werden im späteren frischen CI-Arbeitsverzeichnis ausdrücklich
als QA-Overlays in zwei separate, unveränderte Produktcheckouts kopiert. Der
Runner prüft HEAD, Tree, Index, relevante untracked Dateien und die tatsächlichen
Dateiblobs. Die Overlays werden getrennt an ihren QA-Commit gebunden. Ein
vorhandenes Ziel oder ein bereits benutzter Ausgabeordner wird nicht überschrieben.

Wiederverwendete tatsächliche Infrastruktur:

- Native Touch-/Scroll-/Capture-Helfer: `scripts/tests/connect_four_runtime_regression.gd`,
  Blob `94c32597c0170c5c3199e39ca6fbfcc1caf25f99`.
- Host-Runner-Helfer: `scripts/run_connect_four_runtime.py`,
  Blob `36d93ed0908705e339346bf5ef451cf047b641b5`.
- FileTransport: `test/games/connect_four_runtime_bridge.dart`,
  Blob `6ae4695d06f955d5c9501bdce22ed9a83a0a26d0`.
- Produktionssession: `lib/features/games/connect_four/connect_four_table_session.dart`,
  Blob `fd8efe8e114de656b6802e097b96910535d83c39`.
- Produktionscontroller: `lib/features/games/connect_four/connect_four_round.dart`,
  Blob `853d9e4a59475725a44db8f6c252e691f0bcdad8`.

## Vorgesehener tatsächlicher Bedienablauf

Das echte Godot-Fenster ist durchgehend 640 × 360 Pixel groß, mit Dichte 1 und
expliziter QA-Safe-Area von jeweils 24 Pixeln oben und unten. Die vorhandene
Desktop-Transportgrenze und der SharedPreferences-Testbackend bleiben sichtbar
benannt; dies ist kein Android-Binder- oder physischer Geräteversuch.

1. Durch einen tatsächlichen Menü-Touch den Zweispielermodus wählen. Sieben
   tatsächliche Spalten-Touches `[0, 6, 1, 6, 2, 5, 3]` führen über den unveränderten
   Dart-Controller zu einer bestätigten, belohnten Gewinnrunde.
2. Das Gewinnmenü tatsächlich öffnen. Den oberen Referenzknopf durch reale
   Scrollereignisse zeigen. Die untere Aktion muss zunächst unvollständig sichtbar
   sein. **Neue Runde** durch ScreenTouch/ScreenDrag freiscrollen und vollständig
   sichtbar antippen. Erwartet wird die echte `restart`-Anforderung samt ACK,
   neuer Rundennummer und leerem, aktivem Zweispielerbrett.
3. Die neue Runde wieder mit denselben sieben tatsächlichen Zügen gewinnen.
   **Gegen Lumo spielen** im Gewinnmenü tatsächlich freiscrollen und antippen.
   Erwartet wird die echte `mode`-Anforderung mit `twoPlayers:false`, ein passender
   ACK und eine neue leere, aktive Solorunde.
4. Tatsächlich zurückkehren und den Exit-ACK prüfen. Die zwei abgeschlossenen
   Runden müssen genau zwei unterschiedliche Result-IDs, 10 Sterne und 80 XP
   erzeugt haben. Ein erneutes Öffnen im selben Testprozess darf die Endrunde
   oder die Belohnung nicht verändern.

Der Dart-Harness beobachtet die tatsächlich empfangenen Anforderungen und
veröffentlichten Produktionszustände. Er vergleicht beide Übergänge vollständig
mit den nativen Vorher-/Nachherzuständen, statt lediglich einen nativen PASS-Text
zu übernehmen. Der Renderer muss alle Aktionen durch die ursprünglichen
Touch-Helfer anstoßen; direkte Controller-Aufrufe zum Neustart oder Moduswechsel
werden nicht als Ersatz benutzt.

Erwartet werden genau vier originale 640 × 360 PNGs und vier zugehörige aktuelle
Layoutbeobachtungen, jeweils vor und nach den beiden Zielaktionen. Der Runner
dekodiert die PNGs und bindet sie an Zustand, sichere Fläche, vollständig sichtbare
mindestens 48 × 48 große Ziele sowie die tatsächlichen Scroll-/Tapdaten. Logische
Framezähler und das Argument `--fixed-fps 24` sind keine FPS-Messung. Es wird kein
zusätzlicher Film erzeugt.

## Konkreter, vorab zu prüfender CI-Startweg

Der geprüfte Startweg ist ausschließlich ein normaler Push auf den separaten
Branch `qa/lumo-c4-small-result-actions-20261114-2708`. Root hat diesen nach der
Prüfung des endgültigen Vierersatzes und der statischen Ergebnisse genutzt; der
tatsächlich beobachtete Lauf ist oben gebunden. Das derzeit verfügbare
GitHub-Werkzeug kann Git-Objekte und Refs verwalten; ein authentifizierter
`workflow_dispatch`-Aufruf ist in dieser Sitzung nicht verfügbar. Deshalb enthält
der Entwurf keinen vermeintlich sofort ausführbaren manuellen Startweg.

Der neue Workflow akzeptiert nur das exakte Repository, diesen exakten Branch
und Änderungen an seinen vier neuen QA-Dateien. Es ist kein Pull Request für
den QA-Start vorgesehen. Der Quelltextabgleich des eingefrorenen Hosts umfasst
alle 110 vorhandenen Workflows: 79 besitzen einen Push-Trigger. Alle vorhandenen
Branchmuster sind wörtliche Namen; keiner entspricht dem vorgeschlagenen QA-
Branch. Der einzige Push-Workflow ohne Branchfilter ist `copilot-setup-steps.yml`;
sein einziger Pfadfilter betrifft die unveränderte eigene Workflow-Datei. Es gibt
in diesen 110 Dateien keine `workflow_run`-, `workflow_call`- oder `create`-Events.
Der vollständige Quellenbefund steht in `existing-push-filters.json`.

Die offiziellen GitHub-Regeln bestätigen, dass Push-Workflows nicht in den
Default-Branch gemergt sein müssen und Branch-/Pfadfilter gemeinsam erfüllt sein
müssen. Bei einem neuen Branch gelten andere Diff-Grenzen als bei einem bestehenden
Branch; deshalb ist ein einzelner vier-Dateien-QA-Child vorgesehen, kein großer
Sammelpush. Der tatsächliche Start und sein Run-SHA müssen anschließend separat
abgerufen werden; der Entwurf allein ist kein gestarteter oder bestandener Lauf.

- https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#push
- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onpushpull_requestpull_request_targetpathspaths-ignore

Die CI führt nur die bisherigen erforderlichen Desktop-Abhängigkeiten, den
gebundenen Godot-Import und diesen einen Zwei-Aktionen-Harness aus. Sie baut keine
APK und startet weder den 52-Modus-Gesamtlauf noch einen weiteren Dream-/Android-
Lauf. Originale Import-, Dart- und Godot-Logs sowie Quellenidentitäten, Zustände,
Eingaben und Captures werden auch bei einem Fehler archiviert.

## Tatsächlich ausgeführte lokale statische Prüfungen

Die Originale liegen im begleitenden Verzeichnis `static-checks/` und im
abschließenden Evidenzindex. Sie sind strikt von einem künftigen Bedienlauf zu
unterscheiden.

- Python 3.12.14: `compile()` des eingefrorenen Runners, Exit 0; kein Aufruf
  seiner Prüflogik.
- Actionlint 1.7.12: der echte neue Workflow, Exit 0; externe Shellcheck-/Pyflakes-
  Hilfsprogramme ausdrücklich deaktiviert. Alle fünf echten `run`-Blöcke wurden
  zusätzlich mit Bash 5.2.37 und `bash -n` geprüft, jeweils Exit 0.
- Dart 3.12.2: `dart format --output=none` auf genau dem QA-Overlay, Exit 0.
  Die Formatter-Meldung „Changed“ betrifft hier nur die unterdrückte Ausgabe;
  anschließender Hashvergleich bestätigt unveränderte Bytes.
- Genau ein enger Dart-Analyzer-Versuch: **Exit 3, 30 Meldungen**. Das vorhandene
  historische PackageConfig enthält 104 Einträge, von denen nach dem Reset nur
  fünf SDK-/lokale Pfade noch existieren. Die Meldungen betreffen fehlendes
  `shared_preferences` und nicht aufgelöste Test-Matcher/Timeout-Abhängigkeiten.
  Es wurden keine Ersatzpakete oder Stubs erzeugt und keine Pakete nachgeladen.
  Das ist ein dokumentierter Abhängigkeitsblocker, kein bestandener Typcheck.

Der fehlgeschlagene erste Shared-Clone-Versuch ist ebenfalls im Original erhalten
(lokal fehlendes Promisorobjekt, Exit 128). Anschließend wurden 446 tatsächlich
vorhandene Hostdateien anhand ihrer exakten Gitblobs in eine separate Textkopie
übernommen. Dies ist keine Behauptung eines vollständigen Git-Checkouts. Alle
446 Produktionsdateien und das unveränderte QA-Overlay wurden vor und nach dem
Parser-/Analyzer-Versuch gehasht; keine Abweichung wurde festgestellt.

Der zusätzliche tatsächliche Godot-4.6.3-Parsercheck war zunächst rot: `--headless
--check-only` auf dem ersten Overlay `92368c1…` endete mit Exit 1, weil die lokale
Variable `var exact := (...)` aus dynamischen Rückgabewerten nicht inferiert werden
konnte. Der unveränderte Originalfehler bleibt erhalten. Ausschließlich diese
Zeile wurde zu `var exact: bool = (...)` geändert; Prüfbedingungen und Ablauf
blieben identisch. Derselbe Check auf `cc9ef040…` endete tatsächlich mit Exit 0
am 14.11.2026 um 12:17:13 UTC. Er führte kein Spiel und kein Rendering aus.
Alle 1.454 tatsächlich materialisierten Native-Produktdateien und der ursprüngliche
Touch-Helfer blieben vor und nach beiden Parserprüfungen unverändert. Die
Parserkopie wird ausdrücklich als geprüfte Quellteilmenge mit kopiertem vorhandenem
Importcache dokumentiert; es gab keinen neuen Import oder vollständigen
Checkout-Nachweis.

Der unabhängige Dart-Quellenreview liegt als `independent-dart-review.json`, Blob
`d9615ad95c2e882237fe21238a3a265e31a7f521`, vor. Sein Dart-Blob bleibt unverändert;
die einzige nachfolgende Native-QA-Änderung ist die oben dokumentierte explizite
Typangabe. `source-final.json` bindet den finalen Vierersatz und erhält die
ursprünglichen Vorher-/Nachheridentitäten als historischen Stand. Ein fehlender
lokaler Dart-Typcheck bleibt auch nach den anderen grünen Syntaxprüfungen offen
und muss durch den echten Flutter-Compiler im ausdrücklich begrenzten künftigen
QA-Lauf geklärt werden.
