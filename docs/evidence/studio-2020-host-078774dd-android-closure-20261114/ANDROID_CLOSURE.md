# Studio 078774dd: Builderfehler vor Android

Run **43580228966**, Attempt **1**, Host **078774ddaf64808addaa4c6406f6a3c85b1f239a**, Native **785413d395292a243eaa0a0748671eb15d3f80ff** ist laut originalen Abschlussmetadaten **FAILURE**. Builderjob **132403166536** scheiterte in Step **32** und beendete den Schritt mit Exit **1**. Hostcompile **132403166681** war erfolgreich.

## Zwei getrennte Blocker und ein Folgefehler

1. **Fehlendes ffmpeg im Facial-Movie-Pfad.** Das vollständige Originallog meldet zunächst den echten Godot-Capturemarker und 148 aufgezeichnete AVI-Frames. Danach scheitert der externe Programmstart mit `FileNotFoundError: 'ffmpeg'` (Zeilen 9011–9021). Die tatsächliche Native-Step-Paketinstallation enthält nur xvfb und die beiden Mesa-Pakete (Originalzeilen 3277–3278; veröffentlichter Workflow 316–317). ffmpeg steht im Workflow nur in einem anderen, nachgelagerten Creativejob. Der gerenderte AVI-Teil ist damit kein vollständiger Facial-Movie-PASS.
2. **Treasure-Renderer beendet nicht innerhalb 600 Sekunden.** Die Probe startet um 10:34:21 UTC und protokolliert bis 10:41:34 verschiedene Fenster-/Insetzustände, zuletzt 2400×1080 mit Cutout. Um 10:44:21 beendet der ProbeRunner sie wegen Timeout ohne erforderlichen Abschlussmarker (9066–9067). Das Originallog allein entscheidet nicht, ob die Ursache in Laufzeit, Prozesszustand oder Produkt liegt. Die fünf beobachteten Formate beweisen keine vollständigen Fresh-/Resume-Durchläufe.
3. **Folgender Rosterfehler:** `movie.json` fehlt (9068–9077), nachdem die Konvertierung bereits am fehlenden ffmpeg scheiterte. Die Schlusszeile nennt Facial, Treasure und Roster getrennt; der Step endet mit Exit 1 (9078–9079).

Die vier früheren Resource-/ObjectDB-Shutdownmeldungen nach KartAI, Racecraft, RivalDrift und FullField werden mit Kontext erhalten. Sie folgen deren PASS-Markern und der Lauf setzt fort. Das ist weder eine Harmlosigkeitsfeststellung noch eine Erklärung für die später ausdrücklich gescheiterten Studio-Untergates.

## Reichweite

Der tatsächliche Dart/Godot-Zweiprozesslauf (Step 33), APK-Bau, Kandidatenupload sowie die gesamte Androidmatrix, Creative, Update 2017→2020 und Publisher wurden übersprungen. Die Matrix erscheint in den Originalmetadaten nur als übersprungener, nicht expandierter Name. Es gab somit keine ausgeführten API35-/API37-Abnahmen und keine neue APK dieses Runs. Der separat protokollierte C4-Visualmarker (303 Checks, vier Bilder) bleibt ein Visualfixture.

`builder-original-job.log` ist der einmalig abgerufene vollständige dekodierte GitHub-Joblog, einschließlich UTF-8-BOM und Schlusszeilen: **1.146.964 Bytes**, **9.154 Textzeilen**, SHA256 **c922c2df3400fa97bbaa4f00ab8e2d046d3a326a872a36ac16022bac01a3210c**. `failure-contexts.json` enthält unveränderte ausgewählte Zeilen mit ihrer Position im vollständigen Log. `artifacts-terminal-original.json` enthält alle acht Artefakte einschließlich des fehlgeschlagenen nativen Teilarchivs **14110219450**; kein Archiv wurde durch diese Auswertung heruntergeladen.

Die Quelle blieb unverändert. Es wurden keine Tests, Reruns, Produkt-/Workflowänderungen oder Git-Refaktionen ausgeführt. Die vertiefte unabhängige Dependency-/Cleanup-Einordnung erfolgt getrennt durch B.
