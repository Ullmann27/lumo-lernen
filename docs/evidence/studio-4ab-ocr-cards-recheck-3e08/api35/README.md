# API 35: echte Gegenprüfung derselben 4ab-APK

**Begrenztes Ergebnis: PASS.** Job [132299721965](https://github.com/Ullmann27/lumo-lernen/actions/runs/43546627017/job/132299721965) wurde im Versuch 1 erfolgreich abgeschlossen. Die unveränderte APK aus Host `4ab96666f954baf258422d6ed277fc297b7ddeef` enthält Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`; ausgeführt wurde die separat geprüfte QA-Quelle `3e08c7953b84aed6fff30e9e55665de75f79ec77`. Dies ist keine Freigabe eines späteren Host-Builds.

## Quelle und Originalbelege

Die Vorher-/Nachher-Bindungen sind identisch: echte Arbeitsdateien und Gitmodi beider sauberen Checkouts, genau 16 freigegebene QA-Abweichungen, originale Build-Metadaten sowie APK- und PCK-Bytes. APK-SHA256: `7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6`; PCK-SHA256: `28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e`. Diese Binärprüfungen wurden auf dem CI-Runner ausgeführt; für diese Review wurde keine zusätzliche APK heruntergeladen.

Originalartefakt 14094852782: 140.941.270 Bytes, SHA256 `b60b4ca93749fa105858328eb4044c643faa9a8a254630e7de0febecf0db7409`, alle 1.342 ZIP-Mitglieder CRC-geprüft. Die große ZIP bleibt lokal als Original erhalten und gehört nicht zur kleinen Git-Uploadliste. Alle ausgewählten Originale sind gegen ihre ZIP-Mitglieder bytegleich geprüft. Der vollständige Joblog ist erhalten; Shadercache-Dateien wurden nicht ausgepackt.

## Was tatsächlich bestanden wurde

Die unveränderte Modernisierungstour besteht alle 21 Schritte auf Android SDK 35 / Release 15. Sie prüft unter anderem den Flutter-/Atelierpfad, die Kart-Menüs, eine kurze echte Fahrsequenz, Pause, Flutter-Rückkehr, Neustart und drei Displayformate. Ein vollständiges Rennen oder eine Fold7-Messung ist darin nicht enthalten.

Die anschließende Studio-Prüfung bewegt alle fünf Ergänzungsobjekte der Aufgabe 8 + 5: zwei bis zur Zehn, drei als Rest. Danach ist dieselbe Flutter-Lektion wieder sichtbar. Das Testprofil und zwei Lernschlüssel bleiben erhalten; die Veranschaulichung vergibt keine zusätzliche Kompetenzbewertung. Lokale Sprachausgaben sind technisch als abgeschlossen protokolliert. Hörqualität und Lippenbewegung sind ausdrücklich nicht geprüft.

Cards führt zwei echte, über die sichtbare Beschriftung ausgelöste Ziehaktionen aus. Die erste verändert den eigenen Handbestand von 7 auf 8, die zweite nach 35,092 Sekunden sichtbarem Idle von 8 auf 9. Die Kartenzahl bleibt jeweils 112; Lumo antwortet. Alle vier vollständigen Kartenfrontphasen bestehen mit je zwei stabilen akzeptierten Frames. Fehlende Übergangs-Sidecars wurden zunächst korrekt abgewiesen und nicht als Erfolg gewertet.

Die echte Pause erreicht `paused=true`, `canDraw=false`, Revision 9 und Quittierung 3. Der Spielstand bleibt während der Pause gleich. Die Wiederöffnung nutzt ein neues Mailbox-Token bei derselben Runde und demselben Stand 9/5; anschließend ist der Flutter-Pausendialog wieder tatsächlich sichtbar. Die drei Rückkehr-Pixelprüfungen für Lernen, erste Cards-Rückkehr und letzte Cards-Rückkehr haben jeweils zwei bestätigte Frames.

## Tatsächliche Bildsichtung

Agent A hat die zehn in [review.json](review.json) einzeln benannten PNGs tatsächlich geöffnet. Der native Speicherhinweis in Bild 13 ist nur ein Übergangsbild. Erst Bilder 14 und 16 zeigen den vollständigen Flutterdialog „Spiel pausiert“. Root hat vier Cards-Bilder zusätzlich unabhängig geöffnet; seine unveränderte Note ist beigefügt.

Die tatsächlich gelesene Android-Beobachtung meldet 1080 × 2400 Pixel, Dichte 2,625 und Systeminsets `[0,136,0,63]`. Header und untere Aktionen sind in den gesehenen Bildern frei. Dies ist eine echte Android-Messung, kein Desktopfixture. Aus einem Layoutsnapshot wird keine vollständige 48-dp-Abnahme aller Elemente abgeleitet.

Harte beziehungsweise gezackte Schatten und einfache Raummaterialien bleiben sichtbar. Der alte Grammatikfehler „Du fängt an.“ und der Mischtext „Lumo legt blue 7.“ gehören weiterhin zur geprüften alten APK. Die spätere Textkorrektur wird hier nicht als getestet ausgegeben.

## Grenzen

Eine Testperson und zwei Lernschlüssel; kein Zwei-Kind-/Journal-/Altspielstand-Migrationsnachweis. Zwei Ziehaktionen, Botreaktion, Pause, Save und Wiederöffnung; kein vollständiges Kartenspiel, eigener Kartenlegezug, Farbwahl oder Sieg. Keine physische Fold7-Messung, keine FPS-, Temperatur-, Eingabelatenz-, Facialrig- oder Lipsync-Aussage. Der Log enthält echte Emulator-/Node-Warnungen und ist nicht pauschal fehlerfrei. API 37 und spätere Produktquellen benötigen ihre eigene Abnahme.
