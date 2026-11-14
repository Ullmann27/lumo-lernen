# Attention-/Landing-Vertrag auf Native 8be3

## Konkreter Ausgangsfehler

Der unveränderte GitHub-Lauf `43561885899`, Job `132347187683`, scheiterte auf `8be3a95d5d948d457c4c39bc6694138d60b70027` an genau einer von 1.843 Prüfungen: Der Test las das vom Actor ausgewählte neue Facial-GLB und verglich diese Bytes mit dem historischen Original-GLB-Hash. Der Actor verwendet den Gesichtsableiter bewusst; das Original liegt weiterhin unverändert an seinem bisherigen Pfad.

Der vollständige originale Joblog bleibt im gesonderten Beobachtungspaket `qa/studio-2020-native-8be3-observation-20261114/gameplay-failure/original-job.log`. Dieser Befund wurde lokal mit dem unveränderten veröffentlichten Test reproduziert: **1.843 Prüfungen, genau ein Fehler, Prozessende 1**.

## Eng begrenzte Änderung

Die einzige Quelländerung betrifft `scripts/tests/lumo_attention_landing_regression.gd`. Die irrtümlich vermischte Identitätsprüfung wird durch vier explizite Bedingungen ersetzt:

1. Der Actor bindet das historische Original weiterhin an `res://assets/characters/lumo_animated/Lumo-Animated-Mobile.glb`.
2. Diese Originaldatei besitzt weiterhin SHA256 `3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5`.
3. Der Actor wählt ausdrücklich `res://assets/characters/lumo_facial/Lumo-Facial-Mobile.glb`.
4. Dessen Bytes entsprechen dem geprüften Ableiter mit SHA256 `e14aea79eb9918f5184c8ded64e8c1343bf71f553772a4f59298ada6862d9524`.

Der JSON-Bericht benennt Original und Ableiter getrennt. Die bisherigen echten Handkontakt-, Blick-, Lande-, Pausen-, Reduced-Motion-, Gesten- und Aufräumprüfungen sowie deren Grenzwerte sind bytegleich erhalten. Es gibt keine Änderung an Actor, Mesh, Animation, Fahrphysik, Spielständen oder CI-Gates.

## Tatsächlich ausgeführte Prüfung

Der private Lauf verwendet Godot `4.6.3.stable.official.7d41c59c4`, Headless und den Dummy-Audiotreiber. 1.185 benötigte Projektdateien wurden vor dem Lauf einzeln an den veröffentlichten Git-Tree `9edd7afed143c83fec5d2dc89949ca9325e042ce` gebunden und physisch nach `/tmp/lumo-attention-8be3-20261114/runtime` kopiert. Die eingefrorenen Ursprungsdateien wurden nach beiden Läufen erneut gehasht und sind unverändert.

Der einmalige echte Editorimport normalisierte ausschließlich `Lumo-Facial-Mobile.glb.import` von `fb324434…` auf `ea863718…`. Dieser separat dokumentierte Importbefund ist in beiden Gegenläufen identisch und entspricht der unabhängig geprüften kanonischen Importkorrektur. Der Importcache und diese Normalisierung werden nicht als unveränderter Git-Checkout ausgegeben.

| Lauf | Ergebnis | Dauer | Tatsächliche Messwerte |
|---|---|---:|---|
| Originaltest auf 8be3 | 1.843 Prüfungen, 1 Fehler, Exit 1 | 0,772 s | Handkontakt maximal 1,145121 mm; Landeimpuls 0,573351 |
| Eng korrigierter Test | 1.846 Prüfungen, 0 Fehler, Exit 0 | 0,878 s | Dieselben Handkontakt- und Landewerte; beide GLB-Identitäten bestätigt |

Der grüne Originallog enthält keine `ERROR:`-Zeile. Die um drei gestiegene Zahl entsteht ausschließlich durch den Austausch einer vermischten Identitätsbedingung gegen vier getrennte Bedingungen. Alle übrigen Prüfungen sind erhalten.

## Grenze und Integration

Das Paket enthält genau eine zur Integration bestimmte Testdatei im `source-upload-manifest.json`. Es ist ein lokaler gezielter Gegenbeleg, keine erfolgreiche neue GitHub-Gesamtabnahme, keine neue Rendereraufnahme und kein Android- oder Geräte-FPS-Nachweis. Der ursprüngliche Native-2020-Lauf bleibt fehlgeschlagen. Root integriert diesen Test getrennt von den unabhängig bearbeiteten Import- und Gesichtsfilm-Verträgen und startet erst anschließend einen neuen vollständigen Kandidatenlauf.
