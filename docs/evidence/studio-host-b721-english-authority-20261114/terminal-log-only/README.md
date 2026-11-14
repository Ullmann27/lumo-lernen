# Neuer Studio-b721-Englischlauf: CI-Abschluss, Bildprüfung offen

Der tatsächliche Job [132521067410](https://github.com/Ullmann27/lumo-lernen/actions/runs/43619285124/job/132521067410) im Studio-Run **43619285124**, Attempt 1, ist am 14. November 2026 um **17:16:23 UTC** mit **completed / success** beendet. Die gespeicherten Originalmetadaten binden ihn an Host `b7210db3f53361987fd33592de438fd7984d991a`; die tatsächlichen Checkout-Ausgaben im vollständigen Joblog nennen zusätzlich Native `29080ef8cd1a5b385eeeec97976fbefd31280427`.

| Aktueller Befund | Originalnachweis |
|---|---|
| Echter Dart-Aufgabenproducer: **10 Fälle / 2.955 Prüfungen** | Joblog Zeile 3167 |
| Echter Software-Renderer: **7.691 Prüfungen / 17 Aufnahmen / 196 Inputereignisse** | Joblog Zeile 3271 |
| Fixtureart `actual_dart_producer_report` | Aktueller Marker und verpflichtende Workflowprüfung |
| Getrackte Host-/Native-Quellenprüfung | Step 15 success; beide `git diff --exit-code HEAD --` |
| 17 aktuelle Bilder persönlich geöffnet | **0**, noch offen |

Es werden keine älteren 50503-, 47ca- oder 7633-Resultate als neue Belege ausgegeben. Die Quiz-/Memory-Schritte 11–14 sind aufgrund der separaten Matrixaktivität hier übersprungen; die English-Schritte sind erfolgreich. Der gesamte Studio-Lauf war bei diesem Metadatenabruf noch `in_progress`; dieser Bericht erteilt dafür keine Gesamtfreigabe.

## Unveränderte Originale und enge Grenzen

Der vollständige Originallog wurde **genau einmal nach Terminalstatus** abgerufen und im Functions-Speicher bewahrt. Er enthält **309.324 UTF-8-Bytes**, SHA256 `ae34ccf08491afbb212a35edce3489331f2df9b95811d1b4b9e4280ff956e079`. Die Run-/Job-/Artefaktlisten und die exakt veröffentlichte Workflowdatei werden daneben unverändert gesichert. Die drei Renderingwarnungen (V-Sync-Unterstützung, Screen-space-AA nur in Forward+/Mobile und volumetrischer Nebel nur in Forward+) bleiben ausdrücklich erhalten; ebenso die Actions-Deprecations.

Artefakt **14123388980**, `lumo-studio-2020-nextgen-authority-english`, ist laut originaler REST-Metadatenliste und übereinstimmender Uploadmeldung **4.559.425 Bytes** groß und trägt SHA256 `78f930c157798be8c117a81dd0f76112b7d890fa15af8f8bf7c462b871dbb2cd`. **Dieses ZIP wurde noch nicht heruntergeladen.** Es gibt hier keine lokale SHA-/CRC-Prüfung, keine Mitgliederinventur und keinen neuen Bildfreigabenachweis. Die 17 Bilder sind ausschließlich die aktuelle Runner-/Workflowmeldung und bleiben ungesichtet.

Die lokale Umgebung fiel vor diesem Abschluss aus; auf Roots ausdrückliche Vorgabe erfolgen keine lokalen Dateiaufrufe, Tests oder Bildaufrufe bis zur Recovery. Der neue Textnachweis wird direkt aus den bereits erhaltenen UTF-8-Antworten als unveränderliche Gitblobs gespeichert und vollständig zurückgelesen. Keine Trees, Commits, Refs, Receipts oder Pins werden verändert.

Godot lief tatsächlich unter Linux/Xvfb mit Mesa llvmpipe und dem Audio-Treiber `Dummy`. Die im Konsolentext als „actual Android View insets“ bezeichneten Werte stammen in diesem Lauf aus der Regression-Fixture und werden nicht als Androidmessung ausgegeben. Echter Aufgabenproducer und Software-Renderer belegen weder reale Android-Wiedergabe noch gehörte englische Aussprache, physische 48-dp-Bedienung oder 60 FPS. Die tatsächlichen 17 PNG-/Report-/Quellenstempelprüfungen folgen erst nach wieder verfügbarer Dateiumgebung.
