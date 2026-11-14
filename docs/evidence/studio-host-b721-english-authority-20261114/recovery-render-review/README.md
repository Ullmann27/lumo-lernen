# Studio b721: nachgeholte Sichtprüfung des aktuellen Englisch-Originals

## Herkunft und tatsächlicher Abschluss

Diese Ergänzung gehört ausschließlich zu Host `b7210db3f53361987fd33592de438fd7984d991a`, Native `29080ef8cd1a5b385eeeec97976fbefd31280427`, [Studio-Lauf 43619285124](https://github.com/Ullmann27/lumo-lernen/actions/runs/43619285124), Versuch 1. Der Originaljob `132521067410` (`Nextgen english actual authority`) wurde laut gespeicherten GitHub-Metadaten erfolgreich abgeschlossen. Daraus folgt keine Gesamtfreigabe des Studio-Laufs oder einer APK.

Nach der Wiederherstellung der lokalen Umgebung wurde das Originalartefakt `14123388980` genau einmal heruntergeladen: **4.559.425 Byte**, SHA256 `78f930c157798be8c117a81dd0f76112b7d890fa15af8f8bf7c462b871dbb2cd`. Alle **63 ZIP-Mitglieder** wurden vollständig gelesen und auf CRC geprüft. Alle 17 PNGs wurden vollständig dekodiert und anschließend tatsächlich geöffnet. Nach der Sichtung wurden sämtliche extrahierten Originaldateien erneut bytegleich gegen ihre ZIP-Mitglieder geprüft.

Der frühere [Bericht während des Umgebungsausfalls](https://github.com/Ullmann27/lumo-lernen/blob/5910fa9d3867af79b1f7771b5ce84e9ac5c4f1f0/docs/evidence/studio-host-b721-english-authority-20261114/terminal-log-only/review.json) bleibt unverändert. Seine damalige Aussage „Bilder ungesichtet“ war zutreffend. Diese neue Ergänzung dokumentiert die spätere Sichtung. Der vollständige ursprüngliche Joblog wurde nicht erneut abgerufen.

## Gemessene Ergebnisse dieses Originals

| Bereich | Tatsächlicher Befund |
|---|---|
| Dart-Aufgabenproduzent | 10 Fälle, 2.955 Prüfungen, 0 Fehler; echte Produktionsverträge mit synthetischem Kind |
| Godot-Lernszene | 7.691 Prüfungen, 0 Fehler, 14 Objektfälle, 17 Aufnahmen |
| Eingabe | 196 aufgezeichnete ScreenTouch-Ereignisse; Press/Release-Ereignisse werden nicht als 196 einzelne Tipps ausgegeben |
| Diagnosebindung | Alle 17 Launchbeschreibungen stimmen mit dem tatsächlichen Dart-Output überein; alle fünf berichteten Native-Quellen frisch gegen die exakten Gitblobs geprüft |
| Bedienflächen | Kleinste berichtete exponierte UI-Seite 52 dp; kleinste Objekt-Zielseite 48 dp |
| Projektprüfung | 117 PASS, 7 WARN, 0 FAIL |
| Bildsichtung | 17 aktuelle Originalbilder persönlich geöffnet, kein konkreter Sichtbarkeitsblocker in diesen Bildern |

Die aktuellen **7.691** Prüfungen ersetzen hier keine historische Zahl und werden nicht mit früheren Läufen addiert. Der echte Producer-Output hat SHA256 `75ef38eda89ae1d57dff0ac61ea5ef192cf322f7101c7ad0fcd0bffeea150dac`; genau dieser Hash steht im Rendererbericht.

## Sichtbefund

Die Aufnahmen zeigen die 14 vorhandenen Wörter **pen, bag, school bag, pencil case, book, chair, paper, ruler, rubber, desk, ball, car, sun und apple** sowie zusätzliche Hilfe-/Abschlusszustände für ball und book. Die tatsächlichen Formate reichen von 640×360 und 960×540 bis 412×915, 1080×2400 und 2400×1080. Titel, nummerierte Zuordnungen und Rückkehr-/Hilfe-/Vorleseaktionen sind in den jeweils geprüften Bildern sichtbar. Die Mehrworttitel „school bag“ und „pencil case“ sowie die vollständigen unteren Bedienelemente wurden in den schmalen Formaten geprüft.

Die Hilfemarkierung zeigt das gesuchte Objekt; nach richtiger Zuordnung sind Auswahl und Hilfe gesperrt und die Rückkehraktion bleibt sichtbar. Die reale Lumo-Figur ist in den geprüften Ansichten erkennbar und nicht vom Aufgabenfeld verdeckt. Die Objekte sind einfache geometrische Lernmodelle mit stilisierten Materialien und teilweise harten Schatten. Einzelbefunde und exakte Bildhashes stehen in `image-review.json`.

## Erhaltene Warnungen und Prüfgrenzen

`project-validation.log` meldet sechs fehlende Asset-Aliaspfade unter `assets/models/` (`lumo_fox`, `hub_island`, drei Portale und `star_collectible`) mit dem Hinweis auf AssetLoader-Platzhalter. Außerdem ist `tools/build_web_bundle.sh` nicht ausführbar. Die Logmeldung wird erhalten; daraus wird keine unbewiesene Aussage über den Ursprung der tatsächlich sichtbaren Figur abgeleitet.

`english-render.log` meldet nicht umschaltbares V-Sync sowie für den Compatibility-Renderer nicht verfügbare Screen-space-AA- und Volumetric-Fog-Funktionen. Der Lauf verwendet X11/Mesa/llvmpipe. Keine dieser Warnungen wird als nachgewiesen harmlos klassifiziert. Der Bericht enthält die konkreten Zeilen und Kontexte.

Plattforminsets sowie JNI-/Audioübergaben sind ausdrücklich Testgrenzen. `return_count=1` pro Fall belegt den Testtransport, keine tatsächliche Android-Activity-Rückkehr. Es gab für diesen Nachtrag **keine neue lokale Testausführung und kein neues Rendering**. Weder tatsächliche Modellinferenz/gehörte englische Aussprache noch Android, 60 FPS, thermisches Verhalten, Zwei-Kind-Migration, Journal oder Schreibtrainer werden hier abgenommen. Der b721-Hostpfad für englisches Wort plus deutsche Erklärung muss getrennt von diesem nativen Audio-Testdouble bewertet werden.

## Dateien und Integrationsgrenze

`originals/` enthält die 63 unveränderten Artefaktdateien. `verified-original-extraction.json` bindet den ursprünglichen Download-/Extraktionszeitpunkt; sein damaliges `visual_review_completed=false` wird nicht nachträglich umgeschrieben. `post-view-original-binding.json` bindet die spätere Sichtung. `source-binding.json`, `review.json` und `image-review.json` geben Quellen und Grenzen wieder. Das Uploadmanifest listet ausschließlich neue Dokumentationsziele; das ZIP selbst und produktive Quellkopien gehören nicht dazu. Dieses Paket verändert keine Quelle, keinen Pin, keine Receipt und keinen Git-Ref.
