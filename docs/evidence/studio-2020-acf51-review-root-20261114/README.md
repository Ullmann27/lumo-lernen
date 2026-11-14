# Aktueller Native-Lauf bestanden; Sichtprüfung fordert eine Produktkorrektur

Dieses eingefrorene Belegpaket betrifft ausschließlich Native `acf51d3bd2997c4b731e9a48e1791e05e756a132`, Run `43565059832`, Versuch 1. Alle neun Jobs sind tatsächlich erfolgreich abgeschlossen. Root hat die aktuellen Originalmetadaten unabhängig nochmals von GitHub gelesen.

Das öffentliche Originalarchiv ist an Artefakt `14103142984` gebunden: **225.382.332 Bytes**, SHA256 `4c1e6705f952efe789b0f5eb17d0bcf26cc369c4411b52a6ec5a4567a9b26aac`. Root hat die vollständigen ZIP-Bytes, alle 5.064 Mitglieds-CRCs und fünf saubere Capture-Source-Stamps geprüft. Die originale ZIP liegt zusätzlich dauerhaft im veröffentlichten GitHub-Belegrelease; sie wird hier nicht nochmals als großer Gitblob dupliziert.

## Tatsächlich durchgeführte Sichtprüfung

Root und genau drei Entwicklungsagenten haben insgesamt **48 unterschiedliche aktuelle Original-PNGs** tatsächlich geöffnet: Root 13, Lernen 8, Charakter 12, Spiele 15. Jede Selection enthält konkrete Bildbeobachtungen und Grenzen. Die Charakterprüfung umfasst außerdem den aktuellen vollständig decodierten Gesichtsfilm: alle 148 Bilder wurden auf 13 Kontaktbögen angesehen, zwei zusätzlich als volle Einzelbilder. Eine hörende Audioprüfung oder physische Geräte-FPS wird nicht behauptet.

**Eine finale Bildfreigabe oder ein Hostpin wurde nicht erstellt.** Zwei aktuelle Treasure-Originale zeigen einen konkreten Gameplay-Sichtfehler: Das große Aufgabenfeld verdeckt Lumo am Start fast vollständig, sowohl bei 640×320 als auch im 2400×1080-Safe-Area-Fixture. Die weiße allgemeine Erkundungszeile verliert auf heller Architektur zusätzlich Kontrast. Beide Original-PNGs sind diesem Paket unverändert beigefügt. C bereitet eine enge Layoutkorrektur vor; deren geänderte Quelle benötigt einen eigenen vollständigen Lauf und eigene Originalbilder.

Weitere sichtbare Grenzen bleiben ausdrücklich bestehen: dichte Bau-/Jump-HUDs, gekürzte schmale Überschriften, sichtbare feine Lidkante in extremer Nahaufnahme, C4-Freiraum im Portrait, teilweise sichtbare letzte Puzzle-Menüaktion am Scrollrand sowie die bestehende Singularform `1 Münzen` im Siedlungsdialog. Diese Aufzählung ist keine Behauptung neuer Fehler in allen Modulen.

## Erfolgreicher Jobstatus ist kein fehlerfreies Log

Die beiden ausgewerteten aktuellen Originaljobs Studio und Gameplay haben den Status `completed/success`. Der Studio-Roster meldet 20 Prüfgruppen und 53 Original-PNGs. Der Attention-Landing-Lauf meldet tatsächlich 1.846 Checks / 0 Fehler.

Gameplay enthält trotzdem drei Ressourcen-ERRORs beim Prozessende: `kart_ai_behavior_regression.gd` (4 Ressourcen), `kart_racecraft_regression.gd` (4) und `kart_full_field_regression.gd` (2). Vier ObjectDB-Warnungen einschließlich des ersten Harbor-Hook-Aufrufs sind mit Zeilenkontext erhalten. Der jeweilige numerische Einzel-Exitcode wird nicht direkt gedruckt; der entsprechende Schluss aus den unverändert gebundenen Harnessquellen wird ausdrücklich als Schluss gekennzeichnet. Vorhandene Filter erlauben den Ressourcenwortlaut. Das Paket erklärt die Meldungen weder ohne Ursachenprüfung für harmlos noch ohne Nachweis für einen neuen Produktdefekt.

## Nachvollziehbarkeit

- Die vollständigen einzelnen Eingangsmanifeste werden unverändert mitgeführt.
- Alle Dateien werden vor dem Upload anhand ihrer Bytes, SHA256 und Gitblob-SHA geprüft.
- Der vorherige Gitcheckpoint der 555 Dokumente an `20fbe81804d91e2fc4270a83cfa3038e8557b71d` liegt bei.
- Die zusätzliche Inventur aller zehn Hauptspiele, Zusatzspiele und Lernzugänge wird getrennt als quellengebundene Dokumentation aufgenommen. Ihre Statusaussagen beziehen sich auf ihren ausdrücklich dokumentierten Aufnahmezeitpunkt.
- Es gibt hier keine neue Produktquelle, kein Android-2020-Ergebnis, keine APK-Freigabe und keinen Main-Merge.

Quellen: [Native-Run](https://github.com/Ullmann27/lumo-godot/actions/runs/43565059832), [Originalarchiv](https://github.com/Ullmann27/lumo-godot/releases/tag/studio-2020-evidence-acf51d3bd2997c4b731e9a48e1791e05e756a132-14103142984), [Native-PR 167](https://github.com/Ullmann27/lumo-godot/pull/167).
