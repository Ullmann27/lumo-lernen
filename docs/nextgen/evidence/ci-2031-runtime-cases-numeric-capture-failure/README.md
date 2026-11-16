# Zusatzlauf 4 — unterschiedliche parallele Android-Aufnahmen

Der [Workflow 43822740773](https://github.com/Ullmann27/lumo-lernen/actions/runs/43822740773), Job **133149336951**, endete am **16.11.2026 um 07:24:25 UTC mit FAIL**. Quelle **7b811531ecd3034c0689edd3b39e44223d966857**, Tree **5a71668c9a912ae5a514843b8a4521ab246258b5**, `caseAttempt=4`. Die APK 2031 bleibt unverändert. Der Lauf scheiterte **vor der ersten numerischen Abgabe**; weder 15 noch 16 wurden in diesem Lauf gewertet. Keine der vier Zusatzprüfungen ist hier abgeschlossen, der aktive native Stopp wurde nicht begonnen.

## Tatsächlicher Befund

Originalfehler: `Flutter 0134-numeric-before-wrong-answer stayed visually unrendered after 12 frames; last entropy=2.791`. Alle zwölf getrennten Kandidatenbilder sind bytegleich, jeweils **994.598 Bytes**, SHA-256 **4f35e9ad513aeb47822ff071fac20b46641347754834d394aac6768d2b180081**, und zeigen den Android-Hintergrund ohne Lumo. Das unveränderte Gate lehnte sie zu Recht als Aufgabenbeleg ab. 1080×2340 Pixel, Entropie 2,791, 31,512 Sekunden: [Originalbereitschaft](original/android/runtime-cases/0134-numeric-before-wrong-answer-render-readiness.json), [Kandidat 1](original/android/runtime-cases/0134-numeric-before-wrong-answer-render-candidate-1.png). Root und Conversation haben den Originalkandidaten angesehen.

Das vorherige [XML 0132](original/android/runtime-cases/0132-numeric-nine-plus-seven.xml) enthält die aktuelle 9+7-Frage, freien Abruf, leeres aktiviertes Antwortfeld und aktivierten Prüfknopf. Das bindet Accessibility, nicht alleine entsprechende Screenshot-Pixel.

Das gleichzeitig entstandene [Originalvideo 0113](original/android/runtime-cases/0113-numeric-build-before-graded-recall.mp4) ist **1.351.831 Bytes**, SHA-256 **70d7aedde9280c924dba4e06934a6ab385ac95366d81e1c7586d8c841a8ef78b**, **42,172644 Sekunden / 41 Frames**. Conversation hat einen direkt aus den verifizierten ZIP-Originalbytes im RAM dekodierten Frame bei 20 Sekunden angesehen: bereits die vollständige lesbare 9+7-Aufgabe mit leerem Feld. Dies ist eine Auswertung des unveränderten Originalvideos, keine nachträgliche Appaufnahme. [Unveränderte Videometadaten und Transfer](verified-capture-discrepancy-video.json).

Das **spätere** [Fehlerbild 0135](original/android/runtime-cases/0135-runtime-failure-current-screen.png) zeigt ebenfalls die vollständig gerenderte Aufgabe. Root und Conversation haben es angesehen. Es wurde laut Originaljoblog um **07:24:16,778 UTC** erzeugt, nach dem letzten abgewiesenen Kandidaten um **07:24:13,809 UTC** und nach ordentlicher Recorder-Finalisierung. Die zwölf Kandidaten entstanden dagegen innerhalb `recording("numeric-build-before-graded-recall")`. Beide Standbildwege verwenden tatsächlich `adb exec-out screencap -p`.

**Belegt ist eine Diskrepanz der parallelen Aufnahmewege.** Weder ein Entropie-False-Negative noch ein fehlendes Produkt-Rendering sind damit belegt. Die tiefere Android-Surface-/Displayursache ist ohne entsprechende Laufzeitdaten offen. Keine Aufnahme wird als erfolgreicher Ersatz für die abgewiesenen Kandidaten ausgegeben.

## Eng begrenzter nächster Korrekturumfang

Nur im Supplemental-Zahlenfall darf die Vorab-Standbildaufnahme hinter das ordnungsgemäße Ende und die unveränderte positive Prüfung des bereits vorhandenen Build-Videos verschoben werden. Danach müssen die aktuelle 9+7-Ansicht und der unverändert unbeantwortete Checkpoint samt Profil/Lernbestand frisch gebunden werden. Entropieschwelle, Zeitgrenzen, tatsächliche Abgaben und alle übrigen Videoprüfungen bleiben unverändert; kein UI-Reset oder Bedienungsretry. Ein weiterer ungeeigneter Screenshot bleibt ein harter Fehler. Ein neuer Android-Erfolg wird in diesem Archiv nicht behauptet; der Original-FAIL bleibt erhalten.

## Vollständige Bewahrung

Artefakt **14204798832**: **22.181.444 Bytes**, SHA-256 **d28a0b855eb8ad8cc5127cac5fa0b453f79999dd98a798ba449bdb72ad6131df**; **187 Originalmitglieder / 24.646.807 unkomprimierte Bytes**. Alle Pfade, Größen, CRC und SHA wurden geprüft, das vollständige ZIP ist in **3 geordneten Teilen** erhalten. [Archivmanifest](archive-retention.json), [Mitgliederprüfung](artifact-verification.json), [zusätzliche Originale](additional-originals.json), [Originalresultat](original/android/runtime-cases/runtime-cases-result.json).

Komplettes Rohjoblog unter [job-log](job-log/job-log-manifest.json): **576.038 Bytes**, SHA-256 **1aaa3e574b9c1d40c0b77e9d0f525d0d321c2eadb57e94db0b8be4a2eca320fa**, zusätzlich verlustfrei gzip-komprimiert. Tatsächliche Run-/Job-/Artefaktmetadaten sind getrennt erhalten. Dieses Ergebnis ersetzt weder den vorherigen erfolgreichen vollständigen Replay noch die zuvor gesondert bestandenen Teilfälle anderer Zusatzläufe.
