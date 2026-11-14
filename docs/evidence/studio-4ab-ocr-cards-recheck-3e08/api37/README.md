# API 37: Originalfehler beim ersten Cards-Return

**Gesamtergebnis dieses Diagnosejobs: FAILURE.** [Job 132299721937](https://github.com/Ullmann27/lumo-lernen/actions/runs/43546627017/job/132299721937), Versuch 1, prüft die unveränderte APK `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` unter der getrennten QA-Quelle `3e08c7953b84aed6fff30e9e55665de75f79ec77`. Der Fehler wird nicht als bestandene Gesamtabnahme ausgegeben.

## Original- und Quellenbindung

Artefakt 14095356997: 140.451.755 Bytes, SHA256 `3f143f91cd5b642e34ae1c087b1918a75f2f8b713071c19197c894adab181dfb`. Alle 1.734 ZIP-Mitglieder wurden CRC-geprüft, alle ausgewählten Originale gegen ihre ZIP-Mitglieder bytegleich verglichen. Die große lokale ZIP ist nicht Bestandteil der kleinen Git-Uploadliste. Vollständiger Originaljoblog, Metadaten, maschinelle Berichte und ausgewählte tatsächliche Bilder bleiben erhalten; kein Shadercache-Vollauszug.

Vorher-/Nachher-Bindungen sind identisch, auch nach dem Fehler. Auf dem CI-Runner gemessene APK-SHA256: `7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6`; PCK: `28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e`. Genau 16 überprüfte QA-Abweichungen und alle übrigen Gitblobs/Modi werden gebunden. Keine zusätzliche lokale APK wurde heruntergeladen.

## Erreichte Teilprüfungen

Der tatsächliche Android-17-Frameworkguard besteht: SDK 37 / Release 17, PID 621, Startzähler 1, vier bereite Beobachtungen über 13,637 Sekunden. Die normale unveränderte 21-Schritte-Tour besteht vollständig. Danach werden alle fünf Objekte von 8 + 5 bewegt und dieselbe Flutter-Lektion wieder sichtbar erreicht. Zwei Lernschlüssel und das eine Testprofil bleiben erhalten; die Veranschaulichung vergibt keine Kompetenzbewertung. Audioqualität und Lipsync sind ausdrücklich ungeprüft.

Bei Cards bestehen vor dem Rückkehrfehler alle vier vollständigen Frontphasen mit je zwei stabilen akzeptierten Frames. Reale Ziehanfragen mit Sequenz 1 und 2 sind gespeichert, die eigene Hand wächst 7 → 8 → 9, der Stapel 97 → 96 → 95; die ausgewerteten Saves enthalten jeweils 112 eindeutige Karten. Native Pause wird tatsächlich quittiert: Revision 8, ack 3, paused=true, canDraw=false. Der gespeicherte Rundenzustand ist vor und während der beiden Pausebeobachtungen identisch.

Diese Ergebnisse sind Teilbefunde. Der vollständige Cards-Ergebnisblock fehlt, weil die Funktion beim ersten Flutter-Return abbricht. Wiederöffnung, neues Mailbox-Token und abschließende Cards-/Lernzustandsprüfung wurden in diesem Lauf nicht erreicht.

## Konkreter Fehler und zwei unterschiedliche echte Bilder

Die Zugriffskette erreicht zunächst das Ende des nativen Prozesses, MainActivity und die semantische Pauseansicht. Der erste danach gespeicherte Pixelkandidat zeigt jedoch die tatsächliche Flutter-Ladeüberlagerung „Die Spielwelt wird geöffnet / Gleich geht dein Abenteuer los!“. Das ist kein falsch erkanntes Pausenschild und kein belegter zurückgebliebener Godot-Tisch. Die unveränderte Originalquelle des Flutter-Covers ist in B's unabhängiger Note gebunden.

Schon der erste Contrast-OCR-Durchgang erkennt den echten Ladehinweis mit gültigen Bounds und hohen Wortkonfidenzen. Weitere Bildvarianten, drei Goldkomponenten und zwölf Kacheln bearbeiten anschließend denselben falschen Zustand. Die nächste Screencap erhält nur noch 0,776482 Sekunden des unveränderten 30-Sekunden-Budgets und endet mit Timeout. Der erste Frame wurde korrekt verworfen.

Das später im Exceptionpfad gespeicherte Bild `99_nextgen_failure.png` zeigt die vollständige sichtbare Flutter-Pausekarte. Es ist kein zweifacher positiver Gatebeleg. Die wenigen gespeicherten Beobachtungen zeigen nicht, zu welchem Zeitpunkt die erste korrekte Pause-Rasterung verfügbar war. ZIP-Zeitstempel sind Dateizeiten mit begrenzter Auflösung, keine Scanout-/GPU-Zeitmessungen.

## Tatsächliche Sichtung und nächste Grenze

Agent A hat vier ausgewählte Bilder aus diesem Original geöffnet: native Lernfertigstellung, wirkliche Flutter-Lernrückkehr, Cards nach zweitem Ziehen und native Speicher-/Pausephase. Agent B hat die beiden Rückkehr-/Fehlerbilder einzeln geöffnet und sieben relevante ZIP-Mitglieder nochmals bytegeprüft. Die verbleibenden drei mitgesicherten PNGs werden nicht als von A gesichtet ausgegeben.

Die getrennte nächste QA-Korrektur darf diesen tatsächlich erkannten Ladehinweis lediglich früh negativ verwerfen und einen frischen Frame beobachten. Das ursprüngliche 30-Sekunden-Budget, zwölf Beobachtungen, zwei positive Captions und sämtliche Prozess-/Save-/Bildgates bleiben bestehen. Diese künftige Korrektur und ihr späterer Lauf sind kein Teil des vorliegenden Originals. Keine Produktänderung oder Wiederholung wurde für diese Review ausgeführt.

Keine physische Fold7-, FPS-, Wärme-, Touchlatenz-, Gesichtsrigger- oder Lippenbewegungsabnahme. Ein Testkind, keine Zwei-Kind-/Journal-/Altspielstandmigration. Keine Aussage über spätere c081-/86445-Binärdateien. Warnungen und der Fehler bleiben im vollständigen Rohlog erhalten.
