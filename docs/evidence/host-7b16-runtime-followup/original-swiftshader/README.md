# API37 SwiftShader: belegter Shaderfehler beim Kartstart

Dieser eingefrorene Diagnosepack gehört ausschließlich zum ursprünglichen QA-Lauf **43551424080**, Versuch **1**, Job **132314688434**, QA-Quelle **61c94cfb**. Die geprüfte APK stammt unverändert aus **Host7b16f2f5 / Native17f5b9d4**. Es gibt daraus keinen Android-, Funktions-, Visual- oder FPS-PASS.

## Tatsächlicher Befund

Das bytegenau nachgelesene Original `memory-originals/originals/logcat.txt` enthält vier Fehler beim Linken von `SceneShaderGLES3`, sechs beim Linken von `CanvasShaderGLES3` und zehn dazugehörige Fehler mit `GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`. Sie beginnen um03:29:47.668UTC. Die tatsächliche Engine meldet Godot4.6.3; ihr GLES-Pfad ist SwiftShader4.0.0.1 im Compatibility-Renderer. Danach werden Hauptschleife, Kart-Router, korrekte Querformat-Insetdaten und die Garage gestartet. Das bereits direkt gesichtete originale Bild bleibt bis auf Android-Systemleisten leer. Die exakten unveränderten Logzeilen und Quell-/Bildbindungen stehen in `diagnosis.json`.

Diese Kombination belegt einen wirklichen Shader-Linkfehler, der die leere Szene samt UI nachvollziehbar erklärt. Ein konkreter interner SwiftShader-Defekt bleibt eine begründete Hypothese. Der einmalige frühe Orientierungs-/Buffer-Hinweis beweist keine dauerhafte Ursache; die anschließenden Landschafts- und Insetbelege widersprechen einem bloß fehlenden Startabschluss. Eine pauschal längere Wartefrist ist daher nicht begründet.

## Getrennte Aufzeichnungslücke

Die ursprüngliche durchgehende Host-Logcat-Aufzeichnung endete schon beim ADB-Root-Neustart mit Returncode255. Die Runtime-ANR-Nachkontrolle hat den Lauf deshalb korrekt abgelehnt. Dieses später von der Tour gespeicherte2-Millionen-Zeichen-Endstück enthält zwar den Kartstart samt Shaderfehlern, ersetzt aber keine lückenlose Aufzeichnung. Weder der leere Fatal-Crash-Ausschnitt noch der spätere bereite Endzustand geben einen ANR-Freibrief.

## Transport und Quellen

Das ursprüngliche Actions-Artefakt14096976074 (39.307.727Bytes, SHA256`9aaa2850bc96b39833a3e5893f020a5ecf19d7038fc326f18affed7448e37055`) wurde einmal nach ausdrücklicher Freigabe mit dem unveränderten geprüften RAM-Collector vollständig eingelesen. Alle460Mitglieder wurden per CRC und SHA256 geprüft; ihr vollständiger Index stimmt mit der früheren Originalinventur überein. Sechs ausgewählte Originale mit insgesamt2.030.823Bytes sind hier bytegleich erhalten. Es wurden weder ein vollständiges ZIP noch neue PNGs auf Platte geschrieben. Der komplette externe Original-ZIP bleibt unter seiner tatsächlichen Actions-Retention (API-Ablaufdatum2026-12-14T03:31:30Z); diese lokale Auswahl ist keine Gesamtkopie. Eine temporäre signierte Transport-URL wurde weder in diesen Pack geschrieben noch beibehalten.

`source-binding.json` bindet nur gelesene unveränderliche Gitobjekte und ihre tatsächlichen lokalen Zwillinge. `external-originals.json` verweist samt Hash auf schon vorhandene Originalmetadaten, Bilder, Konfigurationsdateien und den vollständigen zentralen Joblog, ohne sie erneut zu duplizieren. Die unterschiedlichen Image-Revisionswerte8im Paketdescriptor und7in source.properties sowie der effektiv beobachtete Heap576bleiben unverändert erhalten.

## Enger nächster Vergleich

Root hat einen zusätzlichen, getrennten Fall **api37-swangle** freigegeben. Nur der Renderer-Backendparameter ändert sich; APK, PCK, Image, Emulator37.2.13, CPU/RAM/Display/Heap und die bestehenden Fristen bleiben gleich. Die offiziellen Emulatorunterlagen vom13.11.2026 beschreiben SWANGLE als ANGLE mit SwiftShader. Die gelesene AOSP-Implementierung bestätigt diese Verbindung, stammt aber von einem beweglichen Entwicklungszweig und ist nicht als exakte Quelle des installierten37.2.13-Builds verifiziert. URLs, Referenzen, Blob und Versionsgrenzen stehen in `primary-sources.json`.

Der neue Lauf muss deshalb selbst seine Startargumente, effektive Hardwarekonfiguration und eine tatsächliche GLES-Rendererzeile mit ANGLE plus SwiftShader nachweisen. Ein Wort im Kommando reicht nicht. Shaderfehler bleiben harte Fehler; normale Landing-, Input-, Tour- und kontinuierliche ANR-Prüfungen bleiben erforderlich. Hier wurde kein SWANGLE-Lauf ausgeführt, keine App-/Native-Lichtgrenze verändert und kein gegenwärtiger Fehler in einen Erfolg umgedeutet.
