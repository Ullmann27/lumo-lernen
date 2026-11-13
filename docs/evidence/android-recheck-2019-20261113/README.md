# Getrennte Android-Gegenprüfung der unveränderten e3d-APK

**Vorbereitungsstand: lokale enge Verträge und Syntaxprüfungen bestanden; echte Emulatorausführung noch ausstehend.** Dieser Zweig baut keine APK und veröffentlicht kein Release. Er prüft die bereits gebaute Version **0.13.7+2019** erneut mit zwei begrenzten Korrekturen am Prüfablauf.

Basis und tatsächliche APK-Quelle sind `e3d161cb2f79b732ac2dbafc2764b151247f018b`, Native-Pin `76980a941fa05d047574d8cc386d3249d93ffca3`. Der getrennte Zweig heißt `chatgpt/lumo-android-recheck-2019-20261113`; der Workflow startet auf dessen passenden Push oder durch `workflow_dispatch`.

## Fest gebundene Eingabe

| Eingabe | Unveränderliche Identität |
|---|---|
| Originaler Build | Run 43461547945, erfolgreicher `verify-and-build`-Job 132009667976 |
| Kandidatenartefakt | ID 14061222588, `lumo-studio-2019-candidate`, 647.427.173 Bytes |
| GitHub-Archivdigest | `1f7290285cc20c2739005de2221b9bdd3573989c73aa6520f79a89551e1256e5` |
| Tatsächliche x86_64-APK | 325.277.610 Bytes, SHA256 `d2ffac6c1749284ae3c7e6439a6775f086bdcaec308595ae58b988dddf99bf93` |
| Tatsächlich eingebettetes PCK | 66.217.416 Bytes, SHA256 `a5bd0c24692b97acad1ce48522f5f34aa56643009af341a70c5aaaa01b71dfe3` |

Der Workflow lädt das feste Originalartefakt mit `actions: read` und prüft aktuelle GitHub-Metadaten, Quellenbindung und den erfolgreichen ursprünglichen Buildschritt. Der gesamte damalige Studio-Run darf wegen der späteren Android-Probleme fehlgeschlagen sein; sein tatsächlich erfolgreicher Build muss dennoch unverändert und vollständig nachgewiesen sein.

Vor dem Emulatorstart werden die tatsächlichen APK-Bytes, das aus der APK gelesene PCK, die eingebettete Quellen-JSON, originale `BUILD-PROVENANCE.json` und `ANDROID-TOUR-SHA256SUMS.txt` miteinander und mit den festen Werten verglichen. Paket, Version, ABI, ursprüngliche Familiensignatur und Native-Pin müssen stimmen. Dies ergänzt die bereits erfolgte strenge APK-Verifikation im Originalbuild; es behauptet keine neue Signierung.

## Zwei getrennte Quellen ohne Änderung der bisherigen Identitätsgates

Die vorhandene `modernization_android_tour.verify_apk_identity()` liest Git-HEAD, Pubspec und Native-Pin aus ihrem Arbeitsverzeichnis. Deshalb wird ein zweiter, unveränderlicher e3d-Checkout unter `apk-source/` angelegt. Ein einzelner Bashaufruf innerhalb der Emulator-Action wechselt in dieses Verzeichnis und führt die **absoluten Python-Pfade aus dem neuen Prüfercheckout** aus. Die ursprüngliche Tour und die Studio-Oberflächenprobe bleiben bytegleich zu e3d. Es gibt keinen Versionsoverride und keinen ersetzten Identitätsprüfer.

`tour/recheck/before.json` und `after.json` protokollieren deshalb getrennt:

- `apk_source`: tatsächlicher e3d-HEAD und Tree des unveränderten APK-Quellverzeichnisses;
- `probe_source`: tatsächlicher neuer Diagnosecommit und dessen Tree;
- tatsächliche APK-/PCK-Hashes sowie Hashes der verwendeten Probe-, Helper- und Workflowdateien;
- fehlende Änderungen an versionierten Dateien in beiden Checkouts.

Die beiden Quellen dürfen nicht als neuer App-Build zusammengefasst werden. Die Bashdatei hält beide Python-Proben in demselben Arbeitsverzeichnis; sie verlässt sich nicht auf ein zwischen den einzelnen Action-Skriptzeilen fortbestehendes `cd`.

## Beibehaltene Ausführung und die beiden begrenzten Korrekturen

Zuerst laufen die sechs neuen Verträge für die finale Live-Beobachtung nach dem letzten zulässigen Scrollschritt. Die beiden von Agent C übernommenen Dateien sind bytegleich mit dessen Freeze. Der Helper fügt keine weitere Geste hinzu, verändert keine Elternfreigabe und ersetzt keine Touchziele.

Anschließend bleiben die bisherigen `test_nextgen*.py`- und `test_studio*.py`-Aufrufe, UI-/OCR-Abhängigkeiten, Emulatorparameter sowie die vollständige normale Android-Tour und die danach erforderlichen Studio-Lern-/Cards-Prüfungen erhalten. Die Matrix bleibt **API 35 und API 37**. API 35 verwendet weiterhin Emulatorbuild `14472402` und 3072 MiB RAM.

Nur die API-37-Paketkennung der Emulator-Action lautet **`37.0`**. Das reale Diagnoseartefakt **14064150357**, Run **43476259207**, Quelle `31b6c1d69e5ac0b588df91bd8b34149e142e05d4`, hat diesen stabilen Katalogpfad bestätigt. Die Action ist auf den tatsächlich untersuchten Commit `a421e43855164a8197daf9d8d40fe71c6996bb0d` gebunden. Matrixwert 37, `--expected-api 37`, gemessene SDK 37 und tatsächliche Android-Version 17 bleiben unverändert erforderlich. Der abschließende Diagnoseprüfer verwendet hierfür die vorhandenen strengen Runtime-Prüffunktionen aus `verify_studio_delivery.py` einschließlich des Abgleichs zwischen Tour und Oberflächenbericht.

Die Originaltour muss vollständig PASS sein, bevor Learning/Cards starten. Beide Proben lesen und benutzen dieselbe APK. Ein Fehler bricht den Shellpfad ab und bleibt in den unveränderten Ergebnissen sichtbar. Ein separater `always()`-Upload bewahrt die Diagnosebelege unter `lumo-2019-android-recheck-api<35|37>-<run>-<attempt>`. Er enthält `tour/`, keine APK und keine Releasefreigabe.

## Tatsächlich lokal geprüft

- Scroll-Verträge: **6/6 bestanden**, 0 übersprungen, 0,083 s.
- Zusätzliche Identitätsverträge: **6/6 bestanden**, 0 übersprungen, 0,056 s. Sie prüfen unter anderem falsche Quellen/Versionen/Signaturen, veränderte APK- und PCK-Bytes, fehlgeschlagene Originalbuilds und den echten Git-Arbeitsverzeichnisunterschied bei unverändert geladener Tourfunktion.
- `actionlint` 1.7.12: Exit 0.
- Alle sieben tatsächlichen Workflow-Shellblöcke und der Bashrunner: `bash -n` Exit 0.
- Vier Python-Dateien erfolgreich geparst; `git diff --check` Exit 0.
- Neun relevante bestehende Workflow-/Prüfer-/Metadatendateien bytegleich zu e3d.

Die zusätzlichen Identitätstests verwenden synthetische kleine ZIP-Dateien und echte temporäre Git-Repositories. Sie sind kein Android- oder echter APK-Lauf. Die vollständige lokale Testmatrix wurde nicht erneut ausgeführt. Alle Rohresultate stehen in den beiden Testlogs und `local-validation.json`.

## Grenzen

Dieser Gegenprüfungsworkflow ersetzt keinen ursprünglichen Studio-Releasegate. Es gibt weder Buildabhängigkeit noch Publisher. Selbst ein erfolgreicher Diagnoseabschluss wäre ein Beleg für die unveränderten e3d-Binärbytes mit getrenntem korrigiertem Prüfercommit. Der nächste vollständige Studio-Kandidatenlauf und seine Auslieferungsprüfung bleiben separat erforderlich. Physischer Fold7, Wärme, 60 FPS und hörbare Audioqualität sind hier nicht nachgewiesen.
