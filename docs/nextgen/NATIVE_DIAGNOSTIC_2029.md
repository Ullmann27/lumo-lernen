# Native 2029: getrennte Androiddiagnostik

**Vorbereitung, keine Androidabnahme.** Dieser Zweig ergänzt ausschließlich neue
QA-Dateien. Die existierende APK wird nicht neu gebaut. Der ursprüngliche Lauf
43785937519 bleibt mit seinem Androidfehler unverändert **FAIL**.

## Feste Herkunft

| Feld | Erwarteter Wert |
| --- | --- |
| APK-Quelle | `684f54a6d11cfb5eccaec30f39fe34d6c17c82cc` |
| Native-Quelle | `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef` |
| Version | `0.13.17+2029` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Ursprünglicher Lauf | `43785937519`, abgeschlossen mit `failure` |
| Validate / Build | `133033472392` / `133037491223`, jeweils `success` |
| Ursprünglicher Androidjob | `133040408296`, `failure` |
| x86-Artefakt | `14191466126`, `lumo-nextgen-x86` |
| ZIP | 538198271 Bytes; SHA-256 `059ac8a9e2d13d1c52ac35237a465fbfaeba7d7cb6d3de352f47ae6a5113e2c9` |
| APK | 538184171 Bytes; SHA-256 `01e0c126930b48cb8089f0671ed9238b5dc6ded903e288ad7c1fda452ed3cf0f` |
| PCK-SHA-256 | `9aeb88d1dc52f612ea591c04d7651ccc3eef8b807b33b8b78c2f82b4e4eea303` |
| Zertifikat-SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

Der Downloader verlangt die konkreten REST-Metadaten einschließlich `head_sha`
aller drei ursprünglichen Jobs und die unabhängige APK-Verifikation im Buildjob.
Er prüft ZIP-Größe und Hash vor sicherer Extraktion und danach APK-Größe, Hash
und Provenienz. Der Lauf prüft diese Bindung erneut. Der vorhandene Installer
prüft zusätzlich Manifest, Signatur, eingebettete Native-Quelle, tatsächlichen
PCK-Hash und die installierten APK-Bytes. Es gibt keine Suche nach Ersatzartefakten.

Die eigene QA-Revision und ihr Workflowlauf müssen von der APK-Quelle und deren
Lauf verschieden sein. Der vollständige Git-Tree-Vergleich erlaubt ausschließlich
die fünf neuen, im Entry namentlich registrierten Dateien; Änderungen vorhandener
Probes, Publikationsgates oder Produktquellen werden abgewiesen.

## Drei voneinander unabhängige Szenen

Workflow `.github/workflows/lumo-nextgen-2029-native-diagnostic.yml` startet nur
auf `qa/lumo-nextgen-2029-native-diagnostic-20261116`. Die Matrix hat
`fail-fast: false` und `max-parallel: 2`. Berechtigungen sind ausschließlich
`contents: read` und `actions: read`; ein Publisher ist nicht enthalten.

Jede Szene verwendet einen eigenen frischen API35-x86_64-Emulator mit derselben
Software-Grafik-/Reader-Konfiguration wie der ursprüngliche Lauf. Jede verlangt
ein zuvor nicht installiertes Paket, echte sichtbare Einrichtung des fiktiven
Klasse-1-Profils und die vorhandenen sichtbaren Spracheinstellungen. Es werden
keine privaten Appdaten geschrieben, keine Berechtigungen vorab erteilt und
keine bestehende Installation gelöscht oder zurückgesetzt.

| Szene | Unverändert wiederverwendeter Ablauf und tatsächliches Ziel |
| --- | --- |
| `banana` | `ReferenceProbe.banana()`: sichtbarer Guided-Kurs bis Ba–na–ne, nativer Einstieg, drei Silbenschritte, aktuelle MediaPlayer-Ereignisse, Wiederholen im Fragepanel mit vier neuen geordneten Segmenten, sichtbare Rückkehr und gespeicherter Profilschutz. |
| `pattern` | `academy()` und `ReferenceProbe.pattern()`: aktuelle zufällige Core-Folge lesen, nativer Gruppentipp und Formvorschlag, aktuelle Wiedergabe, Rückkehr zur gleichen unbeantworteten Aufgabe und unveränderte Lern-/Belohnungsdaten. `submit_core_answer` ist fest `false`. |
| `bridge` | `academy()` und vorhandener `LearningProbe.native_roundtrip()`: Guided-8+5, sichtbarer nativer Einstieg, zwei Modellbewegungen, tatsächliche Texteingabe „Warum zuerst zwei?“, beobachtete automatische Zweier-Demonstration, aktuelle Wiedergabe, vorhandene Performancefenster und Rückkehr-/Datenschutzprüfung. Die bekannten Lab-Gesprächsrückkehrschritte werden hier nicht als bestanden ausgegeben. |

Die normalen vollständigen Touren, deren Vorbedingungen und historische
2027-/2028-Dateien bleiben unverändert. Ein Fehler einer Szene stoppt ihren Job,
aber nicht die anderen Szenen. Beobachtete Fehler werden mit Originalbildern,
Videos, XML und verfügbaren Audioereignissen aufbewahrt.

## Ergebnis- und Artefaktpfade

Jeder Matrixjob lädt `evidence/` als eigenes Artefakt hoch:

- `lumo-nextgen-2029-native-diagnostic-banana`
- `lumo-nextgen-2029-native-diagnostic-pattern`
- `lumo-nextgen-2029-native-diagnostic-bridge`

`origin/` enthält unveränderte REST-Antworten in `source-run.json`,
`source-artifact.json`, `source-validate-job.json`, `source-build-job.json` und
`source-failed-android-job.json`, dazu `qa-source-binding.json` und
`verified-download.json`. `checkers/diagnostic-checkers.log` enthält die
Prüferausgabe; `emulator/` enthält die tatsächlichen Software-Renderer-Ausgaben.

`diagnostic-android/diagnostic-android-result.json` wird vom Runtime-Entry auch
bei einem Szenenfehler geschrieben. Es enthält `scene`, `qa_commit`,
`qa_workflow_run`, APK-/Native-/Quelllaufbindung und Helper-Dateihashes.
`status` bleibt **immer `DIAGNOSTIC_ONLY`**; nur `diagnostic_outcome` wird
`COMPLETED` oder `FAILED`. `release_eligible`,
`original_probe_requirement_satisfied` und
`original_failed_android_reclassified` bleiben `false`. Es entsteht kein
`learning-android-result.json` oder `reference-android-result.json`.

Das Resultat enthält bei abgeschlossener Szene `banana`, `pattern` oder
`native_learning`. Zugehörige rohe XML-, PNG-, MP4- und Logdateien liegen im selben
Verzeichnis. MediaPlayer-Ereignisse belegen aktuelle Wiedergabe, keine akustische
Wortqualität. Videos haben keinen Audiotrack. Native Langsamer-Wiedergabe, echte
Spracherkennung, Mund-/Pfotenabbruch und physische 60 FPS werden nicht behauptet.

## Gezielte Vorbereitungstests

`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools/android_qa/tests -p 'test_nextgen_2029_native_diagnostic.py' -v`

**12/12 bestanden**, keine Skips. Geprüft sind falsche Quellen/Versionen/Signatur
und PCKs, tatsächliche Hash-/Größenprüfung an ausdrücklich synthetischen kleinen
Dateien, falsche Artefakt-/Jobdaten, fehlender Original-FAIL, szenenfremde oder
veränderte Downloadbelege, verbotene Produkt-/Gateänderungen, falscher API-Stand
oder bestehendes Paket, unabhängige Szenenaufrufe sowie Diagnosegrenzen auch im
Fehlerfall. Ein echter Stub-Unterprozess bestätigt Argumentweitergabe und
Exitcode-Propagation des Bashwrappers. Dies sind Prüfertests, keine Android-
oder Wiedergabeergebnisse. Root aktiviert den geprüften Zweig separat.
