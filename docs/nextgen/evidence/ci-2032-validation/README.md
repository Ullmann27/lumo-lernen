# Unabhängiger Originalbeleg: 2032-Validierung

## Identität und Ergebnis

Job **validate / 133197989015** in Run **43837592237** ist vollständig **SUCCESS**. Diese Ablage enthält ausschließlich die unveränderten Originale und die abgeleitete Auswertung dieses Jobs. Sie bewertet nicht den nachfolgenden APK-Build, die Androidtour oder eine Veröffentlichung.

- Flutterquelle: `9b38360ca5f21919dce4a2b99e605ee39bbbf454`
- Quellbaum: `1c572ff37dde942229e8ae8b1f141ec95df50545`
- Nativequelle: `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`
- Kandidatenversion: **0.13.20+2032**
- GitHub: https://github.com/Ullmann27/lumo-lernen/actions/runs/43837592237/job/133197989015

| Prüfebene | Tatsächlich belegtes Ergebnis |
|---|---|
| Flutter | **2.896 PASS, 202 SKIP, 0 FAIL**, Terminalzeile `08:12 +2896 ~202: All tests passed!` |
| Analyzer | **0 Fehler, 4 Warnungen, 274 Infos**; bestanden unter dem erklärten `--no-fatal-infos --no-fatal-warnings`-Gate |
| Host-unittest | **174 Methoden PASS**, keine Fehler/Skips; 173 einzeilige und eine zweizeilige Methodenausgabe, alle einmal gezählt |
| Neuer aktueller Stoppanschluss | Alle **11** neuen Hostmethoden im vollständigen CI-Log tatsächlich `ok`; kein Android-Stoppnachweis daraus |
| Godot | **4.6.3.stable.official.7d41c59c4**; tatsächlicher Assetimport erfolgreich, keine `ERROR:`-/`SCRIPT ERROR:`-Zeilen im Importlog |
| Native Programme | **13 Programme, 55.631 Checks** aus ihren einzelnen Originalzusammenfassungen |
| Projektvalidator | Zusätzlich **118 PASS / 0 WARN / 0 FAIL** |
| Inventarquellen | **364** Hashes im CI geprüft und anschließend nochmals gegen die exakten Gitblobs des Quellcommits verglichen |
| Geschützte Dateien | **18** Dateien gegen den Quellcommit und Basis `6f4a8c4753f4d06d0b392da0789b8162b2faa71b` bytegleich bestätigt |

Die Flutter-Gesamtzahlen stammen aus genau einer abschließenden Reporterzeile. Fortschrittszeilen mit wiederholten fremden aktiven Testnamen werden nicht addiert. Der Skipzähler steigt 202-mal; eindeutige individuelle Skipgründe liefert dieses expanded-Original nicht. Die 14 zusätzlichen `LumoSound ... skipped (MissingPluginException)`-Zeilen beschreiben ausgelassene Soundeffekte im Hosttest und sind keine weiteren Testskips.

## Native Einzelzählung

| Originalprogramm | Checks |
|---|---:|
| `learning_android_host_capability_regression` | 43 |
| `learning_button_state_contrast_regression` | 79 |
| `learning_companion_scope_regression` | 56 |
| `learning_english_regression` | 7,239 |
| `learning_generation_regression` | 47 |
| `learning_host_payload_regression` | 135 |
| `learning_pattern_regression` | 33,077 |
| `learning_sharing_regression` | 1,811 |
| `learning_wonder_details_regression` | 100 |
| `learning_world_regression` | 5,351 |
| `nextgen_avatar_contract_review` | 300 |
| `nextgen_learning_base_audio_regression` | 69 |
| `nextgen_learning_route_review` | 7,324 |
| **Summe der 13 Programme** | **55.631** |

Die Kontrastprüfung meldet **79/79**, sechs Callback-Aktivierungen und 16 aufgezeichnete Eingabezustände. Sie prüft die echte Produktionsfactory isoliert/headless und keine Android-Framebufferpixel oder hörbare Stille. Englisch meldet 7.239 Checks, 17 Szenenzustände und 196 Eingabeereignisse mit ausdrücklich benannten Plattform-/JNI-/Audiofixtures. Die Avatarprüfung enthält eine erhaltene `ObjectDB instances leaked at exit`-Warnung; sie wird nicht als warnungsfrei bezeichnet. Die Aussage des separaten Projektvalidators bleibt davon getrennt.

## Unveränderte Originale und Integrität

- Artefakt **14212363195**, `lumo-nextgen-validation-14212363195.zip`: **264.077 Bytes**, SHA256 `167bed7006a1fcad952685f92f9583f6158a5f5bc1434a9c153484e24b3d41cd`.
- Der ZIP-SHA stimmt mit GitHubs Artefaktdigest und der Digestzeile im vollständigen Jobprotokoll überein.
- **58/58 Dateien**, insgesamt **1.927.153 entpackte Bytes**: alle Namen, Größen, CRC32 und SHA256 geprüft; jede abgelegte Datei anschließend erneut bytegleich verglichen. Keine Mitglieder ausgelassen oder umgeschrieben.
- `job-133197989015.log`: **1.739.643 Bytes**, SHA256 `fce7d09999355a493d28604e989a6e431a0461c21d2b0d1c13cc325ad2c6ffac`. Einmaliger Abruf über `fetch_workflow_job_logs`; der dekodierte UTF-8-Inhalt wurde ohne Textnormalisierung gespeichert. UTF-8-BOM und alle 14.091 LF-Zeichen sind erhalten; ursprünglicher Inhalt enthält keine CR-Zeichen.
- `artifact-verification.json`, `job-log-verification.json`, `independent-source-verification.json` und `summary.json` enthalten die überprüfbaren Einzelbindungen.

`original/` enthält ausschließlich die 58 originalen ZIP-Mitglieder. Weitere JSONs und diese README sind ausdrücklich abgeleitete Metadaten. Die Quellhashprüfung ist keine Vollmodernisierungsabnahme. Es wurden keine Tests erneut ausgeführt, keine APK heruntergeladen, keine Repositorydateien geändert und keine Remote-/CI-Schreibaktion durchgeführt.
