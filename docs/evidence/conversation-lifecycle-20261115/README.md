# Gespräch: abgebrochener Mikrofonstart bleibt abgebrochen

Stand: 15.11.2026. Eigener Arbeitszweig
`support/lumo-nextgen-conversation-review-20261115`, gemeinsame Basis
`6f4a8c4753f4d06d0b392da0789b8162b2faa71b`.

## Fehler und kleine Korrektur

Der sichtbare Sprechen-Button konnte noch eine Aufnahme starten, nachdem die
App während der asynchronen Spracherkennungsinitialisierung pausiert und
wieder geöffnet worden war. Der alte Ablauf prüfte nach der Initialisierung
nur `mounted` und die Verfügbarkeit der Spracherkennung. Ein Rückkehrwechsel
in den Vordergrund erneuert jedoch nicht die frühere Aufnahmeabsicht.

`lib/features/agent/lumo_agent_content.dart` bindet den Start jetzt an die
vorhandene `_questionGeneration`. Nach jedem vorbereitenden Await und in den
zugehörigen Ergebnis-/Fehlercallbacks müssen Widget, Vordergrund und dieselbe
Generation weiter gültig sein. Die bereits vorhandenen Unterbrechungen bei
Pause, Aufgaben-/Profilwechsel und neuer Frage invalidieren damit auch einen
noch nicht gestarteten Mikrofonvorgang. Eine vorhandene fehlende Blockklammer
im selben Lifecycle-Handler wurde für die strenge Analyse ergänzt.

Keine neue Profil-, Aufgaben-, Lernstands- oder Belohnungsstruktur. Keine
Änderung an Schreibtrainer, Journal, Kart, Dschungel oder Chat-4-Namespace.

## Eigenständige Verhaltensregression

`test/lumo_agent_microphone_lifecycle_test.dart` öffnet das wirkliche
`LumoAgentContent`-Widget und tippt den sichtbaren Sprechen-Button. Die
vorhandene Dart-Implementierung von `speech_to_text` bleibt aktiv; nur ihre
native MethodChannel-Antwort auf `initialize` wird kontrolliert verzögert.

Der Test durchläuft die gültige Lifecycle-Folge
`inactive → hidden → paused → hidden → inactive → resumed`, bevor die alte
Initialisierung abgeschlossen wird. Er fordert danach keinen `listen`-Aufruf.
Ein neuer ausdrücklicher Button-Tipp muss weiterhin genau einen Aufruf mit
`onDevice: true` erzeugen. Sterne, XP und gelöste Aufgaben bleiben unverändert.

| Prüfung | Tatsächliches Ergebnis | Protokoll |
|---|---|---|
| Identischer Regressionstest auf unveränderter Produktbasis | Erwartetes RED: ein unerlaubter `listen`-Aufruf nach Pause/Rückkehr | `baseline-red.log` |
| Regressionstest mit Generation-Prüfung | 1 bestanden, Exit 0 | `fixed-green.log` |
| Finaler gezielter Lauf aus fünf Testdateien | 20 bestanden, 0 fehlgeschlagen, 0 übersprungen, Exit 0 | `focused-regression.log` |
| Strenge Analyse beider geänderten Dart-Dateien | Keine Probleme, Exit 0 | `analyze.log` |

Der endgültige Testlauf umfasst:

```text
test/lumo_agent_microphone_lifecycle_test.dart
test/lumo_context_conversation_test.dart
test/lumo_speech_privacy_test.dart
test/lumo_companion_host_test.dart
test/design/lumo_agent_hologlass_layout_test.dart
```

## Vollständige Versuchsspur

`fixture-first-attempt.log` enthält den ersten Testversuch mit einer ungültig
abgekürzten Lifecycle-Folge sowie der beobachteten Zielverletzung. Diese
Fixture wurde korrigiert; erst das danach erzeugte `baseline-red.log` ist der
saubere RED-Beleg. Keine Produktänderung erfolgte vor diesem sauberen RED.

`analyze-initial.log` enthält die vorhandene fehlende Blockklammer im
Lifecycle-Handler. `focused-before-lint-cleanup.log` bewahrt den davor bereits
erfolgreichen 20-Test-Lauf. `analyze-sdk-concurrency.log` enthält einen
gesonderten SDK-Startkonflikt bei gleichzeitigen Flutter-Aufrufen
(`engine.stamp.tmp.19`); dies ist kein Analyzer- oder Produktfehler. Der finale
Analyzelauf wurde nach Abschluss des Tests mit äußerem `flock` ausgeführt.

## Exakte Toolchain und Wiederholung

Der tatsächlich ausgeführte gemeinsame SDK ist
`/workspace/scratch/c5a7dadab95f/toolchain/flutter`:

- Flutter **3.44.9**, stable;
- Framework `6b182d2c7585eba26d4edce0f97630effd256c33`;
- Engine `5a2a6a42cce67f965cf540fcecf616faca624aa1`;
- Dart **3.12.2**, Linux x86_64.

Die Version/Revision wurde mit `flutter --version --machine`, Git-Tag und
dem [offiziellen Flutter-Release](https://github.com/flutter/flutter/releases/tag/3.44.9)
abgeglichen. `flutter pub get --enforce-lockfile` lief erfolgreich; die
vorhandene `pubspec.lock` blieb unverändert. `source-manifest.json` enthält
die Datei-Hashes und die SDK-Metadaten des Prüfstands.

Für parallele Cloud-Sitzungen den Flutter-Start zusätzlich serialisieren:

```bash
flock /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock \
  /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test \
  --no-pub --reporter expanded \
  test/lumo_agent_microphone_lifecycle_test.dart \
  test/lumo_context_conversation_test.dart \
  test/lumo_speech_privacy_test.dart \
  test/lumo_companion_host_test.dart \
  test/design/lumo_agent_hologlass_layout_test.dart
```

Dies sind lokale Flutter-Widget-/MethodChannel-Verhaltensprüfungen. Eine
tatsächliche Android-Mikrofonaufnahme, hörbare Audioabnahme, vollständige
Flutter-Suite, neue APK und Prüfung des endgültig integrierten Chat-4-Codes
sind durch diesen kleinen Patch nicht belegt.

Der Zweig wird lokal committed; gemäß Hauptchat-Auftrag erfolgt die
Remote-Sicherung durch den Root über den GitHub-Connector. Kein Shell-Push.
