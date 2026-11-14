# Studio 2020: tatsächliche C4-CI-Fehler und begrenzte Korrektur

## Beobachteter Ausgangspunkt

Der gemeinsame Hostcommit `ae394f55c606ce66999df5b72acd1f8d34ec3ee4` bestand den tatsächlichen Android-Hostcompile. Sein [Studio-Run 43576453139](https://github.com/Ullmann27/lumo-lernen/actions/runs/43576453139) scheiterte anschließend in der vollständigen Flutter-Suite: **2.549 bestanden, drei fehlgeschlagen, kein Skip**. APK-Bau, Androidtouren, C4-Androidprobe, Creative, Update und Publisher wurden nicht ausgeführt. Vier Workflows meldeten dieselbe Gruppe aus drei C4-Testfehlern; ihre Testzahlen werden nicht addiert.

Die Originalfehler zeigen zwei verschiedene Sachverhalte. Der ältere Spielablauftest erwartete unmittelbar nach einem einzelnen Frame bereits aktivierte Spalten, obwohl der neue Android-Einstieg die reale native Sitzung noch öffnete beziehungsweise auf die Flutter-Ersatzoberfläche zurückfiel. Die bisherigen Visualtests deklarierten diesen Fallback ebenfalls nicht ausdrücklich.

Zusätzlich lag ein echter Produktfehler vor: In schmalen Ansichten hatte die Knopfzeile eine eigene horizontale Scrollfläche und eine andere Breite als das Brett. Der Visualtest bei 360 × 800 verglich die X-Mitten von Zelle und Knopf. Die Werte 46,6286 und 48 waren **Positionen, keine Knopfbreiten**. Die strikte Zuordnungsprüfung bleibt erhalten.

## Produktänderung

`lib/features/games/connect_four/lumo_connect_four_game.dart` verwendet für Brett und Knöpfe einen einzigen horizontalen Scrollinhalt. Beide teilen dieselbe Außenbreite und denselben Innenrand von 12,4 dp. Die Mindestbreite 360,8 dp lässt sieben Spalten mit jeweils mindestens 48 dp zu. Jede Knopfmitte bleibt beim Scrollen unter der zugehörigen Brettspalte.

Die Höhe wird unabhängig von der Breite aus dem tatsächlichen Platz berechnet. Für Sockel, Abstand und Knöpfe bleiben zusammen 84 dp reserviert. In kurzen Querformaten wird die Brettoberfläche flacher; die vorhandene Berechnung aus der kleineren Zellseite hält die Steine kreisrund. Die gewählte Mindestbretthöhe 168,8 dp entspricht 24 dp je Reihe plus Rahmen. Sie ist eine Layoutentscheidung, keine behauptete Android-Vorgabe. Bei noch weniger Höhe bleibt der gesamte Bereich vertikal scrollbar.

Im Hochformat verwendet die Oberfläche Sliver mit den tatsächlichen Höhen von Kopf, Moduswahl und Zugtext. Große Schrift kann diese Elemente mit wegscrollen, während der Spielbereich eine positive Mindesthöhe behält. Der innere vertikale Notfall-Scroller übernimmt ausdrücklich keinen primären Scrollcontroller.

Controller, Native-Einstieg, Regeln, Persistenz, Kopf, Modi, Begleiter und eigentliche Steinzeichnung bleiben in ihren bisherigen Quellabschnitten bytegleich. Die bereits geprüfte Native-Quelle `785413d395292a243eaa0a0748671eb15d3f80ff`, Versionszuordnung, 49 Originalbilder und Native-Receipt werden nicht geändert.

## Aussagekräftige Regressionen

Der Spielablauftest richtet einen ausdrücklichen fehlenden Native-Pluginzugang ein, verlangt genau einen echten Öffnungsversuch und wartet begrenzt auf die tatsächlich wieder verfügbaren sieben Spalten. Sein vollständiger Spiel-, Wallet-, Neustart- und Bot-Abbruchteil bleibt erhalten.

Der Visualtest behält alle fünf bisherigen Formate, die Fuchsgrenzen und die strikte Zentrenprüfung mit höchstens einem dp Abweichung. Er verlangt zusätzlich einen tatsächlich treffbaren Modustap und belegt die sechs ursprünglichen Züge durch deren Zielzellen und die Anzahl der Spielsteine. Kein erfolgreicher nativer Einstieg wird als Fixture erfunden.

Der erweiterte Foldtest prüft 320 × 740, 360 × 800, 640 × 360 sowie 320 × 480 mit doppelter Textskalierung. Er verwendet tatsächliche Pointerwischer in beide Richtungen. Vor und nach dem Scrollen müssen Brett- und Knopfmitten übereinstimmen. Die getesteten Endspalten müssen eine vollständig exponierte Fläche von mindestens 48 × 48 dp haben. Der Zweispielermodus wird ausdrücklich geprüft; nach den beiden manuellen Taps müssen exakt ein Kinderstein und anschließend zusätzlich ein Goldstein vorhanden sein. Ein automatisch gezogener Botstein darf diese Beobachtung nicht ersetzen. Diese vier Fixtures enthalten keine Safe-Area-Insets und stellen keine allgemeine Geräteabnahme dar.

## Erhaltene Gates und tatsächlicher Prüfstand

Der vorhandene Workflow erhält vor der vollständigen Suite nur zwei zusätzliche Schritte: die drei konkret betroffenen Testdateien früh ausführen und deren originale Ausgabe, Bilder, Quellstände sowie Exitcodes archivieren. Alle bisherigen Schritte, Bedingungen, Rechte und Zeitbudgets sind nach vollständigem YAML-Strukturvergleich unverändert. Sowohl ein Flutterfehler als auch ein Fehler beim Schreiben des Originalprotokolls lässt den neuen Schritt fehlschlagen. Die vollständige Suite und alle Android-, Update-, Creative- und Publishergates bleiben verpflichtend.

Die vier finalen Dart-Dateien wurden tatsächlich vom Dart-Formatter geparst, Exit 0. Die acht vorhandenen Android-2020-Workflowverträge bestanden tatsächlich mit Exit 0 und ohne Skip. Das ist keine Dart-Typprüfung und kein ausgeführter Widget- oder Androidtest.

Die lokale Gegenprüfung war zunächst vor Teststart wegen eines fehlenden Assetbundles blockiert; der Fehler wurde im Testaufbau behoben. Danach brach der lokale Dart-Compiler beim Laden ab, gefolgt von einem Ausfall der Ausführungsumgebung. Die endgültigen Exitcodes dieser unterbrochenen Prozesse sind unbekannt. Nach der Wiederherstellung fehlte der Paketcache; die automatische Freigabeprüfung blockierte dessen Wiederherstellung wegen eines unerwarteten Zugriffs auf eine Cloud-Metadatenadresse. Es wurde kein Wiederholungs- oder Umgehungsdownload ausgeführt. Der bestehende GitHub-CI-Weg muss daher die tatsächliche Ausführung der korrigierten Quellen belegen.

Dieser Commit ist bis zu seinem eigenen erfolgreichen Lauf ein Korrekturkandidat. Er behauptet keine fertige APK, keine erfolgreiche Androidtour und keine physische Fold7-Leistung. Main bleibt unverändert.
