# Lab nach Gespräch und Unterbrechung wieder bedienbar

## Nachgewiesener Produktfehler

Der unveränderte APK-Quellstand `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242`
scheiterte im Android-Replay `43783036351`, Job `133024363592`, QA-Commit
`0919f32431ce07491e0e182b3ea12b21aaaf9540` nach der Gesprächsrückkehr:
Der korrekt beobachtete Tap auf **Vorratsstein 1** ließ `bridge-8-5` bei
`moved=0`, `phase=example`. Die Lernbuttons waren zugleich deaktiviert.

`_LumoConversationRoute.didComplete` meldet bereits beim Pop eine leere Route.
Der Lab behält sein Gesprächs-Token bis `route.completed`. Ein zwischenzeitlicher
Build erhält deshalb keine eigene Coach-Identität: `_bound` deaktiviert Buttons,
während `_model` einen leeren Scope in einem äußerlich aktiven Stein-Callback
festhält. Die spätere `_publish`-Ausführung stellte die Busbindung wieder her,
löste aber keinen verlässlichen lokalen Build aus. Auch nach gewöhnlichem
`inactive` → `resumed` konnte die sichtbare Ansicht deaktiviert bleiben.

## Enger Fix

Nur `LearningLabScreen._publish` ändert Produktverhalten: Nach erfolgreicher
Veröffentlichung einer neuen **eigenen** Identität wird ein lokaler Build
angefordert. Die vorhandenen Aktivitäts-, Profil-, Routen- und Scope-Prüfungen
bleiben erhalten. Alte Callbacks werden weiterhin verworfen; Aufgabenbewertung,
Audioeigentum, Hilfe, Belohnungen, Aufgaben-IDs und Checkpointformat bleiben gleich.
Der Android-Leser und sein `moved=1`-Gate wurden nicht geändert.

## Tatsächliche lokale Prüfung

- `red.log`: drei gezielte Fälle auf der ursprünglichen fc5-Produktdatei,
  alle drei wie erwartet fehlgeschlagen. Der finale Testinhalt ist in
  `red-provenance.json` gehasht; die Fixdatei wurde anschließend bytegleich
  wiederhergestellt. `red-initial-two-cases.log` erhält den ersten Zweifall-Beleg.
- `green.log`: **27/27 PASS**, davon drei neue Regressionen und 24 vorhandene
  Tests aus Lab-Bus-, Native-Entry- und Runtime-Suiten.
- `analyze.log`: die beiden geänderten Dart-Dateien ohne Analysebefund.

Die neuen Fälle prüfen sichtbare Modellbedienung und gespeichertes `moved=1`
nach eigener Modalrückkehr, nach Unterbrechung im Gespräch und nach Resume der
bereits sichtbaren Aufgabe. Alte Callbacks bleiben wirkungslos. Die Rückkehr
verwendet kontrollierte Frames, keinen Resize, keinen Settings-Refresh und kein
`pumpAndSettle`. Die vorhandenen Suiten sichern fremde Overlays, Profilwechsel,
Dispose, verspätete Antworten, Audioeigentum, native Rückkehr und ausdrückliche
Antwortbestätigung ab.

**Kein neuer Android-Runtime-PASS, kein APK-Build und keine Veröffentlichung
durch diesen Patch.** Der vollständige neue Kandidat muss die unveränderte
Android-Tour einschließlich Speicherung, Audio und Referenzszenen noch bestehen.
Das Mikrofonergebnis des fehlgeschlagenen 2028-Replays war die ausdrücklich
angezeigte Geräteeinschränkung; echte deutsche Erkennung wurde nicht bestätigt.

`handoff.json` bindet die Originalbelege, Quell- und Testdateien sowie die lokalen
Protokolle mit SHA-256. Die vollständigen Originalartefakte bleiben unverändert
in der separaten Belegsammlung des Hauptzweigs erhalten.
