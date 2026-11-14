# Vier gewinnt: strenger Visualtest nach abgeschlossener Flutter-Rückkehr

## Quelle und belegter Fehler

Ausgangsquelle ist der veröffentlichte Host `ae394f55c606ce66999df5b72acd1f8d34ec3ee4`. Die einzige hier bearbeitete Repositorydatei ist `test/design/connect_four_visual_test.dart`; Produktänderungen gehören Root und sind nicht Teil dieses Pakets.

Der originale Core-Lauf `43576453040`, Job `132391629884`, enthält den tatsächlichen roten Gegenbeleg. Bei 360 × 800 liegt die erste Knopfmitte bei 48,0 dp, die zugehörige Brettmitte bei 46,62857142857142 dp. Die Abweichung 1,3714285714285808 überschreitet die vorhandene 1-dp-Grenze. Dies ist ein relevanter geometrischer Zuordnungsfehler, keine überholte Forderung nach kleineren Knöpfen. Die bestehenden mindestens 48 × 48 dp bleiben erforderlich.

Bei 640 × 360 meldet derselbe Originallauf einen nicht treffenden Tap auf `connect-mode-true`; später fehlt das erwartete Spaltenziel. Der veröffentlichte Quellpfad pausiert während des asynchronen Native-Starts und setzt die Flutter-Ersatzansicht nach fehlender Integration fort. Der alte Visualtest wartet diesen Abschluss nicht ausdrücklich ab. Andere vorhandene C4-Tests deklarieren den fehlenden Native-Pluginpfad bereits ausdrücklich. Eine lokale Bildaufnahme dieses Zwischenzustands liegt aus diesen Versuchen nicht vor.

## Teständerung

- Der echte MethodChannel antwortet in der Testfixture ausdrücklich mit `MissingPluginException`; es gibt keine vorgetäuschte erfolgreiche Native-Sitzung.
- Ein begrenzter Helfer pumpt höchstens 100 Schritte zu je 20 ms Testzeit, bis die Pause verschwunden ist und alle sieben vorhandenen IconButtons aktiviert sind. Das ist eine Testwartebedingung, keine gemessene Gerätezeit.
- Der Moduswechsel bleibt ein echter, vorher auf Treffbarkeit geprüfter Tap. Erst die tatsächlich neu aufgebaute Zweispieleransicht und wieder aktivierte Controls erlauben die folgenden Eingaben.
- Die sechs ursprünglichen Zugspalten bleiben unverändert. Nach jedem tatsächlichen Tap werden die erwartete Steinanzahl, die konkrete Zielzelle und der richtige Spieler geprüft; die nächste Eingabe wartet auf die abgeschlossene Darstellung.
- Alle fünf Originalformate, die Fuchsgrenzen, die tatsächliche optionale Framebufferaufnahme und die strikte Zentrenabweichung von höchstens 1 dp bleiben erhalten. Nach jedem `ensureVisible` müssen Brett und Knopf weiterhin dieselbe Spaltenmitte besitzen. Jeder geprüfte Knopf misst mindestens 48 × 48 dp und sein Mittelpunkt ist treffbar.
- Der eigene Walletzustand wird je Fall isoliert; Aufräumen erfolgt auch nach einer Assertion. Es gibt keine Änderungen an Spielregeln, gespeicherten Produktdaten, Workflows oder Freigabegates.

Der Mittelpunkt-Hittest und `ensureVisible` belegen allein weder einen echten Fingerwischer noch die vollständige exponierte Clip-Schnittfläche eines 48-dp-Ziels. Dafür bereitet Root eine zusätzliche, getrennte Fold-Regressionsprüfung vor.

## Tatsächlicher Prüfstand

Die neue Testdatei wurde vollständig gegen den ursprünglichen GitHub-Blob gelesen und unabhängig von Agent A geprüft. Ihr bestätigter unveränderlicher Gitblob lautet `2b6225ad3972ae801620d8363458833434358616`, SHA256 `769da01fdacc066f5f36ac42a70790d3007abb0498628ec38a981627c99eb11c`. Vollständiger GitHub-Readback und lokale Bytes stimmen überein. Es wurde kein Tree, Commit oder Ref geändert.

**Für diesen neuen Teststand gibt es noch keinen ausgeführten grünen Lauf.** Der erste lokale Originalversuch scheiterte vor Dart-Testbeginn an einem fehlenden pubspec-Asset. Das Asset wurde danach durch Root aus der exakten veröffentlichten Quelle ergänzt. Der zweite unveränderte Versuch brach bereits beim Laden mit `Dart compiler exited unexpectedly` ab; der anschließende Ausfall der Ausführungsumgebung verhinderte einen gespeicherten terminalen Wrapperstatus. Ein Exitcode wird dafür nicht erfunden. Beide Originalausgaben bleiben erhalten und gelten nicht als C4-Assertiongegenbeleg.

Nach Wiederherstellung fehlte der Paketcache. Root hat weitere lokale Flutterstarts beendet; der tatsächliche Gegenlauf muss mit der vorhandenen GitHub-Toolchain erfolgen. Diese Note behauptet weder einen neuen Flutter-PASS noch Android-, Bild-, Leistungs- oder Releasefreigabe. Der bereits fehlgeschlagene ae394-Lauf bleibt unverändert fehlgeschlagen.

## Eigentümerschaft

Agent B: die eine Visualtestdatei, deren strikter Diff und diese Belege. Root: Produktgeometrie, zusätzliche Fold-Wischprüfung und Integration. Agent C: separater vorhandener `games_screen_flow_test.dart`-Fall. Agent A: unabhängiger reiner Quellenreview; keine Testwiederholung durch ihn.
