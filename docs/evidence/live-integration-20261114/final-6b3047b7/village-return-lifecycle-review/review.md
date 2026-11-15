# Dorf-Rückkehr: unabhängige Quellen- und Originalbildprüfung

## Bindung und Ergebnis

Geprüft wurden Host `6b3047b7979dfb86d837e74a21b0fd890e4f9e66`, Native `84789d0c2c6fb4b6ecd2897ce1951b89f958b604` und das unveränderte Rückkehrbild aus Run **43616038272, Attempt 1**, Android-Job **132536740615**, Artefakt **14125719765**. Android-QA hat das Artefakt einmalig heruntergeladen; dieser Review verwendet ausschließlich dessen vorhandene Originale.

Das tatsächlich geöffnete `village/returned-flutter-frame.png` zeigt **LUMO DORFWELT**, den nativen Knopf **‹ Spiele** sowie Ressourcen und Bauflächen. Es zeigt keine Flutter-Spielen-Navigation. Der SHA-256 lautet `51abb112ec1b8e54b909b23d735af39dfb10de27514a98cbb7d3861ab3815ee0`. Unter den 202 Original-OCR-Zeilen gibt es keinen exakten normalisierten Treffer `spielen`; der native `«Spiele`-Treffer ist ein anderes Wort. Die strenge Captionablehnung ist korrekt.

## Tatsächlich gelesene Rückkehrkette

1. `build_settlement_world.gd` setzt für den eingebetteten Dorfstart `return_scene = games`; `_leave` speichert und ruft `SceneRouter.goto` auf.
2. `scene_router.gd` leitet embedded `games` an `HostBridge.return_to_app` weiter. Es öffnet in diesem Pfad keinen nativen Spiele-Hub.
3. `host_bridge.gd` akzeptiert erst das bestätigte Android-Ergebnis und protokolliert anschließend die games-Rückkehr. Die Android-Funktion speichert das Ziel, stellt `RESULT_OK`/`finish` in den UI-Thread und beendet ausschließlich den Spielprozess nach 500 ms. Das bestätigt noch keinen gezeichneten Flutter-Frame.
4. `MainActivity.onActivityResult` wartet auf das Prozessende und liefert `destination=games`. `launchLumo3D` schließt seinen Eintrittsoverlay; `GamesContent` synchronisiert. `EmbeddedGameService` ordnet games dem Flutter-Spielebereich zu, den `AppShell` navigiert.
5. Der Manifestgenerator setzt die native Activity auf `sensorLandscape`; der Host bleibt eine normale `FlutterActivity` ohne eigene Resume-/Render-/Orientation-Override. Der in den Originallogs von QA beobachtete Wechsel zurück zu Portrait passt zu diesem Pfad. Daraus folgt keine bereits bewiesene sichtbare Wiederaufnahme.

Alle gelesenen lokalen Quellen sind in `source-binding.json` durch ihre tatsächlichen Git-Blobs an die beiden Commits gebunden.

## Konkrete Beobachterlücke und Grenze

`capture_when_ready` prüft ausschließlich die Entropie des zentralen Bildinhalts. Es weist ausdrücklich auf die getrennt erforderliche Seitenidentifikation hin. Das Originaljournal akzeptierte bereits den ersten **2400 × 1080**-Frame mit Entropie **4,971** nach **1,617 Sekunden**. Dieser inhaltsreiche Frame ist jedoch weiterhin das native Dorf.

`visible_return` prüft danach nur dieses eine Bild mit exaktem `Spielen`-OCR und Original-TSV-Replay. Erst anschließend würde es die Flutter-XML erfassen. Deshalb gibt es in diesem fehlgeschlagenen Rückweg keine nachfolgende erfolgreiche Flutter-Ansicht oder XML-Abnahme.

QA hat aus den ursprünglichen Prozess-/Activity-Logs tatsächliche ACK-, Host-Resume- und Rotationsereignisse bis unmittelbar vor dem Capture-Ende belegt. Der vollständige, als QA-Kontext gekennzeichnete Zeitbezug steht im JSON. Er beweist nicht, welcher Displaybuffer während der Aufnahme gelesen wurde. Ein kurzer Übergangsframe und ein dauerhafter sichtbarer Wiederaufnahmefehler sind durch dieses eine Bild nicht unterscheidbar.

Eine begrenzte Nachbeobachtung muss ausschließlich frische Bild-/OCR-/XML-Belege sammeln. Exakter Text, Originalbytebindung, derselbe Host, beendeter Nativeprozess, unveränderte Einstellungen, einmaliger sichtbarer Return-Touch und bisherige Frist bleiben erhalten. Auch ein passender Frame nach Fristende ist kein PASS. Zusätzliche UI-Aktionen, Namenslockerungen oder längere Wartebudgets sind nicht gerechtfertigt.

**Keine Produktquelle geändert, kein Build, keine Tests und kein neuer Geräteversuch ausgeführt.** Dieser Review erteilt keine Android-Freigabe. Der fehlgeschlagene ursprüngliche Lauf bleibt FAIL; eine spätere Diagnose muss ihre eigene Readerrevision mit der unveränderten 6b-APK binden.
