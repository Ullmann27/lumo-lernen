# Lumo PR207 – Entwicklungscheckpoint, 7. Oktober 2026

## Herkunft und Isolation

- Repository: `Ullmann27/lumo-lernen`.
- Eigener Branch: `chatgpt/3d-launch-lifecycle-2026-10-07`.
- Pull Request: #207, gestapelt auf #202; kein Merge.
- BASE SHA: `35299467b7c2b9077b00160e4c7dba86c82f3d03`.
- Getesteter CODE RESULT SHA: `4a50e01410d5dee3816e1c4fa283dfdf3629b079`.
- Danach ausschließlich Build-Orchestrierung: `ec2e19d8a9cf59d6b9725ef2ced5876d27a17453`; APK-Workflow checkt weiterhin ausdrücklich CODE RESULT aus.
- Claims in #170: 6029386547, 6029444733, 6029465735, 6029746567.
- Kein Portieren des alten lokalen MVP-ZIP. Keine fremden Branches, main, Signierung, Secrets, Zahlungen oder Godot-Pin verändert.
- #204 (Curriculum/UI) und #206 (Cards-Lebenszyklus) bleiben getrennte Arbeitsbereiche; deren Änderungen sind NICHT in diesem Kandidaten enthalten.
- Godot-Quelle bleibt die über #202 integrierte `c650ff17a5b6a8016fccab0d9b530e0260c6c797`. Keine Godot-Produktdatei geändert; #20 zuletzt separat unter `d47a0de8f9e1bacf7d8c304043b03cfa48cf6e85` gelesen.

## Abgeschlossene Reparatur 1: Levelergebnisse

`lib/core/game_progress_repository.dart` ordnet die Speicheroperationen pro Kind über alle Repository-Instanzen im selben Dart-Isolate. Komplette Read-modify-write-Operationen, Lesezugriffe und Reset teilen diese Reihenfolge. `saveStars` kopiert die Eingabemap vor einem asynchronen Schritt.

Damit überschreiben gleichzeitig eintreffende Levelergebnisse einander nicht mehr; ein vorher angefordertes Ergebnis belebt einen nachfolgenden Reset nicht wieder. Ein nach dem Ergebnis angeforderter Read liest dessen Ergebnis. Bestehende Bestwert-/Unlock-Regeln bleiben unverändert.

Beweis vor der Reparatur: Run **37561184846**, SHA `f5e7f214f907c7848e27292b480e17c9dc289162`: 10 PASS / 5 FAIL über neue und bestehende Tests. Reproduzierte Fehler: parallele Ergebnisse, Reset-Reihenfolge, veralteter Read, Eingabemutation und mehrere parallele Repository-Instanzen.

Beweis nach Reparatur und Formatierung: Run **37562278964**, exakt CODE RESULT: **15 PASS / 0 FAIL**, davon zehn neue Ordnungsprüfungen und fünf bestehende Spiel-/Fortschrittsprüfungen. Zielanalyse: **0 Befunde**. Dart-Formatter: **2 Dateien, 0 Änderungen**.

Grenze: Das vorhandene Best-effort-Verhalten bei echten SharedPreferences-/Speicherfehlern wurde nicht als Erfolgsgarantie umgedeutet. Dauerhafte Schreibfehleranzeige und Mehrprozess-Persistenz bleiben gesonderte Aufgaben; der Queue-Fix ist kein ACID-Datenbanksystem.

## Abgeschlossene Reparatur 2: Flutter → Godot

`lib/features/lumo3d/lumo3d_launcher.dart` schützt den kompletten Start einschließlich Speichern und nativer Spielrückkehr gegen konkurrierende Anforderungen. Der Schutz überlebt den Neuaufbau einer Spiele-Seite. Ein bereits verlassener Bildschirm, eine darüber geöffnete Route oder ein während des Speicherns zurückgesetztes/gewechseltes Profil startet kein verspätetes Spiel. Fehler beim Speichern verhindern den Start. Fehlende Rückgabedaten gelten nicht als erfolgreicher Abschluss. Busy-/Plugin-/Speicherfehler erhalten passende Hinweise statt einer pauschalen Neustartaufforderung.

Die bestehenden Channel-Argumente und die native Rückkehrsemantik bleiben erhalten; keine Änderung an Android-Quellen. Es gibt absichtlich keinen Ablauf-Timer, der einen gesunden laufenden Rennprozess vorzeitig entsperrt.

Sauberer Negativbeweis: Run **37561798868**, SHA `69540f187c0172239670621eee67839fb3c6f5ef`: **4 PASS / 10 FAIL**, Analyse ohne Befund. Der ältere Run 37560751481 hatte zusätzlich zwei Fehler im Testaufbau (Platform-Override zu spät zurückgesetzt; MissingPlugin nicht explizit gemockt). Diese wurden korrigiert und werden NICHT als Produktfehler gezählt.

Positivbeweis nach Reparatur und Formatierung: Run **37562278916**, exakt CODE RESULT: **14 PASS / 0 FAIL**, Zielanalyse **0 Befunde**, Dart-Formatter **2 Dateien, 0 Änderungen**. Tests verwenden einen kontrollierten nativen MethodChannel, keinen physischen Android-Rennlauf.

## Vollständige Flutter-Regression

Run **37562283730**, Job **112602065618**, Checkout exakt CODE RESULT:

```text
flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2
01:14 +641 ~4: All tests passed!
```

**641 PASS / 4 SKIP / 0 FAIL.** Die 14 Launcher- und 15 Fortschrittsprüfungen sind Teil dieser Suite, nicht zusätzlich zu 641 zu addieren. Projektweite Analyse ohne Compilerfehler, aber weiterhin **144 Hinweise/Warnungen**. Keine pauschale Aussage, die gesamte App sei fehlerfrei oder visuell fertig.

Der bestehende allgemeine Change-review-Workflow hat sein verstecktes `.ci-results/`-Verzeichnis nicht als Artefakt hochgeladen. Der vollständige Job-Log wurde gelesen. Dieser fremde CI-Arbeitsbereich wurde nicht verändert. Die zwei eigenen Prüfworkflows nutzen sichtbare Verzeichnisse und haben nachweisbar herunterladbare Originalartefakte geliefert.

## Verifizierte Originalartefakte

| Prüfung | Run | Artefakt-ID | SHA-256 des heruntergeladenen ZIP |
|---|---:|---:|---|
| Fortschritt, finaler Code | 37562278964 | 11456828640 | 6530f8bb33e6b16c07115dafd2cea1bb406a8de71443d19316d339e29af50a16 |
| Launcher, finaler Code | 37562278916 | 11456528961 | 1cc8ecd6e6123b2dfb375f356d93609eb17fbec5a22895cb22b56b767f199fdc |

Beide ZIPs lokal mit SHA-256 und ZIP-CRC geprüft. Die CI-Quellkopien sind bytegleich zu ihren formatierten Kopien. Ein lokales Code-only-Patch wurde an den originalen Git-Blobs mit `git apply --check` und tatsächlichem Anwenden geprüft; alle vier Ergebnisdateien entsprechen den CI-Quellkopien.

## APK-Probe – Status dieses Checkpoints

Run **37563101658** ist gestartet, beim Schreiben dieses Checkpoints noch nicht abgeschlossen. Kein APK-Erfolg behauptet. Der Workflow checkt CODE RESULT aus, nutzt die existierenden Build-/Prüfskripte und die unveränderte Testsignatur. Keine Veröffentlichung, kein Tag und keine Release-Aktualisierung.

Paket und Version bleiben unverändert: `dev.ullmann.lumo.lumo_lernen.coachpreview`, `0.10.5+280`. Das ist ein technischer Kandidat, nicht die globale Update-Version. Ist bereits eine höher nummerierte Parallel-App installiert, keinesfalls durch Deinstallation/Datenlöschung einen Downgrade erzwingen. Den Abschluss und eventuelle Artefakte im Run prüfen, bevor eine APK ausgeliefert genannt wird.

Geplante tatsächliche Build-Prüfung: Backend-/Android-Vorbereitung, Inhaltsaudit, Repair-Guard, vollständige Flutter-Tests, Godot-PCK, APK-Signatur/Paket/ABIs, 16-KiB-ELF-/Ressourcenalignment, Digest/Provenienz und im APK enthaltene Launcher-Icon-Ressourcen. Paket-Icon-Prüfung ist NICHT gleich installierter Launcher-/Gerätetest.

## Änderungen

Produktcode (nur zwei bestehende Dateien):
- `lib/features/lumo3d/lumo3d_launcher.dart`
- `lib/core/game_progress_repository.dart`

Neue Tests und isolierte CI:
- `test/lumo3d_launcher_lifecycle_test.dart`
- `test/games/game_progress_ordering_test.dart`
- `.github/workflows/lumo-launcher-check.yml`
- `.github/workflows/lumo-progress-order-check.yml`
- `.github/workflows/lumo-pr207-candidate.yml`
- dieser Checkpoint.

Lumo-Cards-Regeln, Controller und Bilder wurden hier nicht neu gebaut; bestehende Tests laufen mit. Lumo-Kart-Fahrphysik, Strecken, Modelle, Loopings und Assets sind hier unverändert. Kein neuer Runtime-Screenshot, kein neues Asset und kein physischer Fold-/60-FPS-PASS.

## Wiederaufnahme

Zuerst #170-Claims, #207-Head und #202/#204/#206 sowie Godot #18/#20 neu lesen. Keine alten SHAs ungeprüft auf andere Branches schreiben. In einem vorhandenen Clone zunächst Status prüfen und dann einen getrennten Worktree verwenden:

```bash
git status --short
git fetch origin chatgpt/3d-launch-lifecycle-2026-10-07
git worktree add --detach ../lumo-pr207-check FETCH_HEAD
cd ../lumo-pr207-check
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2
```

Nächste drei priorisierte Pakete:
1. APK-Run auswerten; unabhängige Gegenprüfung der zwei Reparaturen und kontrollierte Zusammenführung mit den separat bearbeiteten #204/#206-Änderungen planen, nicht automatisch mergen.
2. Akzeptierten Gesamtstand als eindeutig versionierte Test-APK installieren; echter Start, Spielrückkehr, Neustart und Speichern auf schmalem Smartphone, Tablet und Fold-Zustandswechsel prüfen, Runtime-Bilder sichern.
3. Offene Cards-Persistenz/Dialog-Lebenszyklen und konkrete visuelle/3D-Lücken im jeweils freien Arbeitsbereich abarbeiten; echte Looping-/FPS-Abnahme weiterhin getrennt behandeln.
