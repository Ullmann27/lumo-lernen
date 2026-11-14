# Neue native Quizshow – Quellen- und Belegfreeze

Diese Fassung wurde nach dem Verlust der vorigen Laufzeit neu aus den gesicherten Quellen aufgebaut. Maßgeblich sind Native `34421df83566dd4773420cc2a225887956459435` und der gelesene Quiz-Protokollstand Host `1a903aefc751f80537c7dd4c96ae8c99915962f5`. Ergebnisse der verlorenen früheren Fassung werden nicht übertragen. Root integriert Router, HostBridge und den neuen Hoststand getrennt.

## Drei eigene Quellen

| Pfad | SHA256 | bestätigter Gitblob |
|---|---|---|
| `scenes/games/quiz_studio.tscn` | `4b9d269b4410810637e2e8db74ca7ce2725f66d5c20190fdaddf8eca6a68c05f` | `7b674ff774f5cd05120472949dffc1b5c37cea8a` |
| `scripts/games/quiz/quiz_studio.gd` | `43d290ceb727640ff764d2cf4b639d4d57bc1031dd436146e1a478af60f90b29` | `573af4e6c55dd44b8832f588545300d18309c89d` |
| `scripts/tests/quiz_studio_runtime.gd` | `22d0d8a4357b63453d35f5befaaae2c4ba0fea19b95bd54bf025a9a00a6ac36c` | `22a76b56645a495887a7e39ede10707a38d6efc5` |

Alle drei Blobs wurden vollständig als UTF-8 zurückgelesen. Die Bühne ist ein Presenter des öffentlichen QuizTableSession-Zustands: Original Lumo, Podium und Lampenbogen, Frage/Antworten, Auswahl, Joker, Erklärung, Pause, Wiederaufnahme und Ende. Die native Produktquelle enthält keine eigene Quizbank, keine Walletbuchung und keinen QA-Orakelzugriff. Token, Runde, Revision, Sequenz und bestätigte Exit-ACKs binden die Kommunikation. Fehlender oder ungültiger Zustand deaktiviert die alten Eingaben.

## Tatsächlich ausgeführt

- Finale unveränderte Quellen: Headless-Fixture **137 Checks, 0 Fehler, Exit 0**, 4,927 Sekunden; Renderer-Fixture **151 Checks, sieben PNGs, 0 Fehler, Exit 0**, 25,364 Sekunden. Originale unter `evidence/final-headless*` und `evidence/final-render/`.
- Sieben aktuelle Originalbilder wurden einzeln geöffnet und samt Hash/Abmessungen in `evidence/final-image-review.json` dokumentiert. Die kurze Ansicht und das Cutoutprofil benötigen vertikales Scrollen. Bei Cutout ist der deaktivierte Aufdeckenknopf teilweise unterhalb des Ausschnitts, Joker folgen darunter. Tatsächliche ScreenTouch-/ScreenDrag-Eingaben bleiben im Originalbericht erhalten.
- Das QA-Minimalprojekt verwendet unveränderte Original-Lumo-/MobileRuntime-Abhängigkeiten aus Native344. Die 24 Abhängigkeiten sind in `evidence/runtime-baseline-binding.json` gebunden. Die Quellen vor und nach den finalen Läufen sind identisch.
- Erhaltene Gegenbefunde: erste Typinferfehler, fehlende Desktop-Touchemulation im ersten Fixturelauf sowie tatsächliche 2400×1079-Framebufferabweichung vor dem expliziten EXPAND-Aspect. Diese historischen Rotläufe und ihre Rohdaten bleiben erhalten. Keine Dimensionsprüfung wurde entfernt.

## Ausführbare Einstiege

Headless-Fixture, frisches Ausgabeverzeichnis:

```sh
LUMO_CAPTURE_DIR=/absolute/fresh-headless-output godot --headless --path /absolute/native-checkout --script res://scripts/tests/quiz_studio_runtime.gd -- --fixture
```

Lokaler echter Renderer mit dem vorhandenen Native-Runner (Godot 4.6.3, Python, Xorg-Dummy, xauth, Mesa; kein Flutter nötig):

```sh
LUMO_CAPTURE_DIR=/absolute/fresh-render-output/captures python tools/run_local_renderer.py --display 109 --output /absolute/fresh-render-output --timeout 480 --project /absolute/native-checkout -- --resolution 960x540 --disable-vsync --script res://scripts/tests/quiz_studio_runtime.gd -- --fixture --capture
```

Der Fixturemarker lautet `[QuizStudioFixture] PASS`. `--capture` erfordert einen echten Renderer. Das Skript verweigert vorhandene Ergebnisdateien; für jeden neuen Lauf ist ein neues Ausgabeverzeichnis nötig.

## Noch ausstehender echter Dart↔Godot-Nachweis

Root muss `tools/android_qa/quiz_native_authority.dart` aus dem exakt gepinnten Host in einem eigenen leeren Verzeichnis parallel starten. Godot erhält dieses Verzeichnis über `LUMO_QUIZ_QA_DIR`; denselben Einstieg **ohne `--fixture`**, bei Renderer zusätzlich `--capture`. Der QA-Treiber liest öffentliche Zustände und einen nur für diesen Test verfügbaren, runden-/fragennummergebundenen Orakelstand; die native Produktquelle liest das Orakel nicht. Der Authority-Harness hat eine 300-Sekunden-Grenze. Beide Prozesse müssen erfolgreich enden; im Godotbericht müssen `failures` leer und der Marker `[QuizStudioRuntime] PASS` vorhanden sein. Die bloße Abschlussmeldung des Dart-Harness genügt nicht.

Diese Schnittstelle prüft echte Dart-Quizregeln, Bank, Controller und Save-CAS, nutzt dabei jedoch einen deklarierten QA-Prämiencallback. Sie ersetzt weder den produktiven AppState-Walletvertrag noch Android-Bridge-/Geräteabnahme. In dieser Ersatzlaufzeit gibt es keine freigegebene Dartinstallation; der Zwei-Prozess-Lauf wurde hier nicht ausgeführt. Die sichtbaren 5000 Sterne im Fixturebild sind keine produktive Buchung. Die Szene hat schriftliche Lumo-Hinweise; eine neue Sprach-/Phonemfunktion wird nicht behauptet. Bühne und Software-Renderer erlauben keine AAA-, Android- oder physische FPS-Freigabe.
