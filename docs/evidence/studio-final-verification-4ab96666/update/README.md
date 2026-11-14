# 4ab: tatsächliches Update 2017 → 2019

Run **43530667812**, Job **132269951387** ist **SUCCESS**. Die unveränderten Originaldaten binden Host `4ab96666f954baf258422d6ed277fc297b7ddeef`, Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` und die neu gebaute x86-APK. Dies ist die unabhängige nachträgliche Auswertung dieses Laufs; der Reviewer hat keinen neuen Geräte- oder Testlauf ausgeführt.

## Tatsächlich erhalten

Die Installation mit `install -r` behält UID **10209** und `firstInstallTime=2026-11-14 01:01:38`. Das eine Testprofil LumoTest und seine fünf verglichenen Identitätsfelder bleiben erhalten. Die sieben geschützten Lernschlüssel bewahren **eine richtige Antwort, einen Stern und fünf XP**. Bei einem Kompetenzdatensatz bleiben alle zehn bestehenden Felder samt Typ unverändert; ausschließlich `independentEvidence` wird entsprechend der zugelassenen Migration von 2017 nach 2019 ergänzt.

Nach Offline-Kart, `force-stop` mit neuem Appstart und drei simulierten Displaygrößen stimmen die sieben geschützten Werte exakt mit dem Zustand nach dem Update überein. Der gesamte Preferences-Text ist wegen dokumentierter anderer Änderungen nicht bytegleich. Die ursprünglichen zehn Kompetenzfelder, die Ergänzung und alle nachfolgenden Vergleiche sind in [independent-data-comparison.json](independent-data-comparison.json) einzeln aufgeführt.

## Grenzen und nicht erfolgreiche alte Teilversuche

Die optionale Navigation der alten 2017-Baseline zu Deutsch und Englisch meldet jeweils `FAIL: Kein Bedienelement beginnt mit ...`. Das alte Bild `baseline-learning/12-restored-learning-menu.png` zeigt einen leeren Hauptbereich, obwohl Sterne und XP im Header sichtbar sind. Es wird deshalb nicht als vollständig wiederhergestelltes Lernmenü anerkannt. Diese Befunde werden weder durch eine spätere neue Tour ersetzt noch als Fächer-PASS ausgegeben.

Neun ausgewählte Originalbilder wurden tatsächlich einzeln geöffnet; ihre Dateihashes und begrenzten Befunde stehen in [independent-review.json](independent-review.json). Die Bildnamen „fold“ bezeichnen simulierte Emulatorgrößen, keinen physischen Fold7-Lauf. Zwei-Kind-Fälle, gefüllte Journale, Schreib- und Lesedaten sowie alte native Spielstände wurden durch diese Ein-Kind-Fixture nicht geprüft.

## Originale und Nachprüfbarkeit

[update-result.json](selected-originals/update-result.json) ist der unveränderte Hauptbericht. [artifact-byte-verification.json](artifact-byte-verification.json) bindet alle **448 Original-ZIP-Mitglieder** durch CRC und SHA256. Das **105.702.437 Byte** große Original-ZIP bleibt lokal unverändert erhalten. Es wurden weder APKs kopiert noch alle Cachedateien extrahiert. [source-binding.json](source-binding.json) bindet gelesene Prüferbytes an den veröffentlichten 4ab-Git-Baum; der lokale Git-HEAD wird nicht als Kandidatenidentität ausgegeben. Die explizite Uploadliste steht in [evidence-upload-manifest.json](evidence-upload-manifest.json).

**Keine Gesamtfreigabe:** Die separaten aktuellen API35/API37-Oberflächengates sind fehlgeschlagen.
