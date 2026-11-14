# Facial-Import: tatsächliche Änderung einer versionierten Datei

Am 14. November 2026 wurde nur das exakte neue Facial-GLB samt versionierter
Importdatei aus Native 8be3a95d5d948d457c4c39bc6694138d60b70027 in ein eigenes
Projekt unter /tmp kopiert. Es wurden keine gefrorenen Quellen geändert.

Godot 4.6.3.stable.official.7d41c59c4 wurde mit demselben Import-Aufruf wie
Stage 2 ausgeführt: --headless --editor --import --quit (240-s-Grenze).
Der tatsächliche Lauf endete mit Exit 0 nach 4,151 s. Die minimale Konfiguration
übernimmt ForwardPlus/Mobile/Web-Renderer und 4.6-Features; sie enthält keine
Autoloads, andere Assets oder Spielszene. Der generierte Importcache war leer.

Das GLB blieb exakt gleich. Die versionierte .glb.import änderte sich von
fb3244345f930d628253b8f687646566273c8adb77aa276b46815e5861304b15 zu
ea8637187b5af2f1315958c27117d05d594873c61727f6bdf0e2d910581dfb5a.
Godot ergänzt sechs Standardfelder am vorhandenen LumoEyelids-Subresource.
Die für die Lid-Geometrie erforderliche Einstellung generate/lods=2 bleibt.
Originale Vorher-/Nachherbytes, vollständiger Log, tatsächlicher Exitcode und
Diff sind hier unverändert gesichert; keine Screenshots wurden erzeugt.

Der Stage 2-Originaljob zeigt nur, dass git diff --quiet HEAD -- Exit 1 meldet.
Die isolierte Änderung belegt einen konkreten betroffenen versionierten Pfad, aber
nicht die vollständige ursprüngliche CI-Diffliste oder deren Ausschließlichkeit.
Eine eng begrenzte mögliche Reparatur ist das Versionieren der durch denselben
Importer erzeugten after.glb.import. Dieses Paket führt sie nicht aus.
