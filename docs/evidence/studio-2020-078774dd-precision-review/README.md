# Unabhängiger Review der C4-Präzisionskorrektur auf078774dd

**Kein konkreter statischer Guard-Rückschritt.** Der tatsächliche veröffentlichte Vergleich gegen1453 enthält genau den Fold-Test und seine Dokumentation. Der neue Testblob f33dfceb… ist lokal mit den veröffentlichten Bytes abgeglichen. Produkt, Workflow und Native-Pin sind in diesem Vergleich unverändert.

Die Änderung betrifft nur `_alignedTouchTargets`. `getSize` liefert nach der gelesenen Flutter3.44.9-Implementierung direkt `RenderBox.size`. Beide Bedingungen bleiben strikt **>=48dp**, ohne Rundung oder neuen Toleranzwert. `getRect` bleibt für die globale Zentrenzuordnung erhalten; deren Grenze bleibt0,1dp.

Die gesonderte `_fullyVisible`-Funktion bleibt bytegleich: Schnitt des globalen Knopfrechtecks mit Viewport und Bildschirm, `hitTestable` und die schon vorher vorhandene Rechentoleranz von0,001dp. Diese globale Toleranz wird nicht als mathematisch strikte48dp-Grenze ausgegeben. Die eigenständige lokale Größenprüfung bleibt strikt. Beide echten Pointerwischer, vier Formate einschließlich320×480 mit Text2.0 sowie die tatsächlichen Zielzellen und Zweispieler-Steinanzahlen bleiben ebenfalls unverändert.

Das Paket enthält den originalen veröffentlichten Vergleich, veröffentlichte Vorher-/Nachher-Testbytes, Roots Originalcheckpoint und Patch sowie einen zeilengebundenen Flutter-Quellenauszug. Die vollständige gelesene SDK-Quelldatei ist nur lokal zum Hashnachweis vorhanden; sie ist keine SDK-Installation und wird nicht ins kleine Uploadpaket aufgenommen.

Es wurden keine Tests, Compiler-, Flutter-, Cache- oder Paketaufrufe ausgeführt. Der tatsächliche Lauf43580228966 auf078774dd wird getrennt beobachtet; diese Quellenprüfung behauptet keine Android-, C4- oder Gesamtfreigabe. Roots separat berichtetes frühes12-Test-Artefakt wurde hier nicht heruntergeladen oder visuell geprüft.
