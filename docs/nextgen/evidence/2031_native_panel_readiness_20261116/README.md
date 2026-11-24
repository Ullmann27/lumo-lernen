# Native Fragenoberfläche: erst tatsächliches Panel beobachten

## Unverändertes Original

Zusatzlauf **43816667737**, Job **133130171146**, QA-Commit
`25d4aa1eb3b684eb10e38b4fa7e0270d02e8f9b3` ist **FAIL**. Er prüfte die
unveränderte APK aus `e05a96a52aaf57e466e79831f15aaffd144284ee` mit Native
`678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Artefakt **14203032627** hat
**29.082.573 Bytes**, SHA-256
`663d9f34fcfbbcf12360ee03dfd889df9469bbd13f3ef7ca67dcfa11ec09411a`.
Die vollständigen 753 ursprünglichen ZIP-Mitglieder bleiben im separaten
Originalarchiv `ci-2031-runtime-cases-native-panel-failure` erhalten.

Die drei Dateien unter
`tools/android_qa/tests/fixtures/nextgen_panel_43816667737/` sind bytegleiche
Originale aus diesem ZIP; Herkunft, Größen und Einzelhashes stehen im Manifest.
Zur Diagnose wurde das vollständige ZIP aus seinen vier Teilen ausschließlich
im RAM rekonstruiert und erneut gegen Größe und SHA-256 geprüft.

## Konkrete Ursache

Das tatsächliche Touchjournal `0342-runtime-banana-open-question-surface-readiness.json`
enthält zwei stabile OCR-Beobachtungen des Knopfes **Lumo fragen**, Bounds
`[551,1952,831,1997]`, und genau eine angeforderte Eingabe bei `[691,1974]`.
Diese Werte werden ausschließlich als Originalbeleg aufbewahrt; der Fix
übernimmt daraus keine Klickkoordinaten.

Das selbst betrachtete Bild `0343-runtime-banana-slower-panel.png` zeigt noch
die unverschattete Banane-Lernszene ohne Fragepanel. Mit der unveränderten
Panel-Farbmaske besitzt es **0 passende Pixel**. Der darauf folgende echte
Fehlerscreenshot `0344-runtime-failure-current-screen.png` zeigt bereits
**Frag Lumo**, **Zurück**, das Fragefeld und die unten angeschnittenen Shortcuts.
Dieselbe Maske findet dort Bounds `[40,606,1040,1803]` mit **749.307** passenden
Pixeln, entsprechend **62,5987 %** der umschließenden Fläche. Die beiden
Capture-Logzeilen stammen von 06:34:41.5006266Z und 06:34:42.8675601Z.
Das ist keine Messung der Eingabe-zu-Render-Latenz.

Die native Quelle `scripts/learning/learning_conversation_panel.gd` setzt
`panel.bg_color = Color("fff8e8")`. Farbe und vorhandene Toleranz funktionieren
am tatsächlichen geöffneten Panel. Der Fehler entsteht vorher: Der erste
fehlende Hintergrund löst unmittelbar eine Exception aus. Deshalb wird die
Panel-OCR im fehlgeschlagenen Lauf noch gar nicht ausgeführt. Ein Header- oder
Langsamer-OCR-Erfolg wird aus dem nachträglichen Fehlerbild nicht behauptet.

Beide Wege verwenden denselben Hintergrundleser:

- Vollständige Referenztour: `ReferenceProbe.question_repeat_target()`.
- Zusatzfall: `question_slower_target()` im nativen Runtime-Helper.

## Enger QA-Fix

Nur **null passende Panelpixel vor der ersten tatsächlichen Panelbeobachtung**
werden als `QuestionPanelNotObserved` unterschieden. Der jeweilige Aufrufer
bewahrt das aktuelle Bild mit `PANEL_NOT_YET_OBSERVED` auf und beobachtet frisch
weiter. Die Grenzen bleiben **12 Versuche** für die Referenztour und **90 Sekunden**
für den Zusatzfall. Es bleibt bei genau einem Fragen-Tap.

Ein zu kleines oder verstreutes Pixelvorkommen bleibt ein harter Fehler. Ein
bereits beobachtetes Panel darf nicht verschwinden oder seine Geometrie über
die vorhandene Toleranz hinaus wechseln. Ein unbrauchbarer Oberflächenframe
verwirft sowohl die vorherige Zielbeobachtung als auch den Headerbefund;
anschließend sind ein frischer Header und zwei neue stabile Zielbeobachtungen
nötig. Das bestehende Scrollen innerhalb des beobachteten Panels behält seine
Header-/Geometriebindung und die aktuellen Shortcut-Geschwister.

Farbe, Pixeltoleranz, Mindestmaße, Flächenanteil, OCR-Labels, Geometrietoleranz,
Koordinatenermittlung, Geschwisterprüfung und die vorhandenen Audio-/Video- und
Aufgabenprüfungen werden nicht gelockert. APK, Produktquellen, gemeinsame
Recorderimplementierung, Workflows, Configs und Publisher bleiben unverändert.

## Tatsächlich ausgeführte Prüfung

Zuerst wurden die zwei Aufrufwege an unveränderter Produktion von
`d0729fbc400601c15940329e9e3ae6b0f4e54b02` mit der Originalbildfolge geprüft:
**2 Tests, 2 erwartete RuntimeErrors** an genau der ursprünglichen
Hintergrundprüfung. Log, Testpatch und Quellenprovenienz sind erhalten.
Der ursprüngliche Testpatch liegt bytegleich in `panel-original-sequence-red-tests.patch.gz`
(Gzip mit mtime=0); der Hash in der RED-Provenienz bezieht sich auf die
unveränderten entpackten Patchbytes.

Nach dem Fix bestehen **54/54 Tests** aus den beiden zugehörigen bestehenden
Testmodulen, ohne Fehler oder Skips. Darunter sind die Originalbildfolge,
dauerhaft fehlendes Panel, zu spät eintreffendes Panel/OCR, mehrdeutige Pixel,
gewechselte Geometrie, verschwundenes Panel, ungültiger Zwischenframe,
fehlender Header oder Geschwister sowie die unveränderten Wiedergabe- und
Ergebnisgrenzen. Die vollständige Ausgabe steht in `panel-focused-first.log`.

Die Bildbytes und das ursprüngliche Fragen-Touchjournal sind echte
Androidbelege. Capturefolge, Uhr und OCR-Antworten der neuen Hosttests sind
ausdrücklich konstruierte Testgrenzen; insbesondere wird das zweite Originalbild
für eine simulierte weitere stabile Beobachtung wiederverwendet. Das ist kein
zusätzlicher Androidframe und kein Android-PASS. Ein neuer realer Lauf muss
Panelerkennung, Langsamer-Wiedergabe und anschließenden Stop-Fall erst belegen.
