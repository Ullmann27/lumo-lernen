# Englisch-Sprachausgabe: Quellenbefund zu Host 2e20 / Native 29080

## Ergebnis

Der native Englischablauf spricht derzeit deutsche Aufgaben-, Hilfe- und Abschlusstexte. Das sichtbare englische Zielwort wird über den vorhandenen Anhören-Knopf **nicht** zur Aussprache übergeben. Es gibt dort weder eine englische Sprachwahl noch einen Wortclip-Aufruf. Dies ist eine konkrete verbleibende Funktionslücke; es ist kein Hörnachweis einer falschen Aussprache.

Die Prüfung bindet 19 Hostdateien an `2e20f5f24cee7a696296e6bea5618cc130a40ce2` und drei Native-Dateien an `29080ef8cd1a5b385eeeec97976fbefd31280427`. Alle lokalen Bytes, Größen und Gitblobs stimmen mit den tatsächlichen Git-Trees überein. `source-binding.json` enthält die vollständigen Identitäten; `source-excerpts.json` enthält die gelesenen Stellen mit exakten Commitlinks und Zeilen.

## Tatsächlicher Datenfluss

| Stelle | Beobachtetes Verhalten |
| --- | --- |
| `learning_world.gd::_voice_action` und `_queue_narration` | Verwenden `explanation.text`. Der Sprachrequest enthält ausschließlich `id`, `text`, `style`. |
| `learning_activity.gd::explanation` | Englischzweig liefert deutsche Anweisung, deutsche Hilfe oder die deutsche Bedeutung beim Abschluss. |
| `LumoLearningSpeech.kt` | Übernimmt diesen Text in den lokalen Adapter, ohne englische Sprachwahl. |
| `LumoOfflineSpeechBridge.kt` / `LumoOfflineSpeechEngine.java` | Identität F2; Ergebnisse als `de`; `prepareGerman` umschließt jeden Text mit `<de>…</de>`. |
| Host-Descriptor | Enthält das aus der tatsächlichen Aufgabe geprüfte `word`, `meaning`, `objects`; kein Sprach- oder Clipfeld. |

Die zwei aktuellen Clipkataloge enthalten 155 F2- und sechs Sulafat-Einträge. Für keines der 14 unterstützten englischen Zielwörter existiert ein exakter Wortschlüssel, Worttext oder Alias. Diese Aussage betrifft die Katalogmetadaten; es wurde kein Audioclip angehört. Der native Sprachadapter verwendet diese Clipkataloge ohnehin nicht.

## Erhaltene Grenzen

Die native Stimme erfordert Elternfreigabe, aktivierte Stimme und die tatsächlich ausgewählte lokale F2-Identität. Automatisches Vorlesen hängt zusätzlich an AutoRead und ausgeschaltetem Ruhemodus. Der Quellenpfad schützt Pause, Stop, Activity-Wechsel, späte Workerantworten und zerstörte Instanzen mit Generation und Main-Thread-Zustand. Position und Hüllkurve sind an den tatsächlichen MediaPlayer gebunden; System-Stummschaltung bzw. Lautstärke null unterdrücken die als hörbar veröffentlichte Hüllkurve. Das sind gelesene Implementierungsgrenzen, kein neuer Androidnachweis.

Die gesamte App besitzt daneben einen separaten, explizit freigegebenen Sulafat-Cloudpfad. Er wird im hier untersuchten nativen Lernpfad nicht verwendet. Daher wird keine pauschale Cloudfreiheit aller Appmodule behauptet.

## Engster möglicher Anschluss — noch nicht implementiert

Das englische Wort könnte im Host aus dem bereits validierten aktuellen Lern-Descriptor abgeleitet und mit derselben F2-Stimme vor der unveränderten deutschen Erklärung gesprochen werden. Dafür muss zuerst die konkrete englische Sprach-/Tokenizerfähigkeit der exakt gepinnten Modellbytes bestätigt werden. Ein bloßer Austausch von `<de>` gegen `<en>` genügt nicht. Native 29080 kann bei diesem Ansatz unverändert bleiben; Stop, Elternregeln, einzelne Requestgeneration und echte Wiedergabeposition müssen erhalten bleiben.

Kein Produktpatch, kein neuer Test, keine Synthese, keine Hörprüfung und keine Git-Refänderung wurden für diesen Quellenbefund vorgenommen. Die aktuelle CI-/17-Bildabnahme ist ein gesonderter Renderer-/Producerbeleg und keine Englisch-Audiofreigabe.
