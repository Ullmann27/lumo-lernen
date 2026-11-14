# Kanonische Importdatei: begrenzter Folgeschritt

Genau ein zweiter identischer Godot 4.6.3-Import wurde tatsächlich ausgeführt.
Vorher wurde ausschließlich der selbst erzeugte /tmp-Importcache zur Seite
verschoben und erhalten; der erneute Lauf musste die Szene wirklich importieren.
Die vom ersten Lauf erzeugte .glb.import blieb nach diesem zweiten vollständigen
Import bytegleich: ea8637187b5af2f1315958c27117d05d594873c61727f6bdf0e2d910581dfb5a.
Exitcode 0, Laufzeit 3,555 s; der Scene-Import ist im vollständigen neuen Log sichtbar.

Der isolierte Ein-Datei-Patch enthält genau diese vom Importer geschriebenen
Bytes. Das Original-GLB, die explizite Lid-LOD-Einstellung und sämtliche
gefrorenen Quelldateien blieben unverändert. Keine Gitreferenz wurde verändert.
Der neue Log wurde separat aufgenommen; seine Ausgabe ist deterministisch
bytegleich zur ersten Importausgabe, die beiden Ausführungsberichte enthalten
die unterschiedlichen tatsächlichen Startzeiten und Laufzeiten.

Dieser Nachweis schließt den reproduzierten Import-Dirty-Pfad. Er ersetzt
keinen erneuten vollständigen Stage2-Lauf und behauptet nicht, dass im alten
CI-Lauf kein weiterer Pfad betroffen war. Der erste Diagnosebericht und sein
Manifest bleiben unverändert erhalten.
