# Vier bestehende Walletverträge an die positive Dedup-Bestätigung anschließen

## Grund und unveränderter Produktvertrag

Der tatsächliche Flutterjob [132564402577](https://github.com/Ullmann27/lumo-lernen/actions/runs/43633267932/job/132564402577) auf Host `0d7e6e5efb1fe8cd2e9a7f92cdd4034b81173304` scheiterte nach erfolgreicher Analyzerprüfung im frühen Fokuslauf: 23 bestanden, 7 fehlgeschlagen. Vier davon sind die hier betroffenen Schlusszählungen in zwei bestehenden Wallet-Testdateien. Das Originalprotokoll belegt jeweils einen zusätzlichen **inhaltlich identischen** Schreibvorgang nach einer schon bekannten Ergebnis-ID.

Die produktive positive Dedup-ACK-Barriere bleibt unverändert: Bereits bekannte Ergebnisse dürfen erst nach einem erneut erfolgreich abgeschlossenen `_persist(current)` bestätigt werden. Sie dürfen weder nochmals gutgeschrieben noch nochmals als Änderung ausgesendet werden. Die anderen drei Fehler gehören zu den getrennten Memory-Widgetfixtures und werden in diesem Paket nicht geändert.

## Enges Testdelta

- `test/reward_wallet_queue_zone_test.dart`: Beide bestehenden Fälle behalten ihre vorherigen Zonen-, Warteschlangen-, Reihenfolge-, Saldo- und Ergebnis-ID-Prüfungen. Der vollständige alte Schreibprefix wird vor dem Wiederholungsaufruf gebunden; danach ist genau ein weiterer identischer Abschlusswrite erforderlich. Rückgabewert und Plattformfixture-Inhalt bleiben vollständig gleich. Neue Replay-Listener werden im `finally` entfernt und dürfen kein Änderungsereignis erhalten.
- `test/reward_wallet_transaction_test.dart`: Beide bestehenden Parameterfälle `falseResult` und `exception` behalten die Prüfung der fehlgeschlagenen ersten Speicherung und der nachfolgenden Lernbelohnungen. Vor dem Doppelaufruf müssen weiterhin genau vier bisherige Writes vorliegen. Anschließend ist ausschließlich deren unveränderter vollständiger Prefix plus ein identischer bestätigter Walletwert erlaubt. Der Rückgabewert, der aktuelle Snapshot und der gespeicherte Inhalt bleiben gleich; die bestehende Ereignisliste darf nicht wachsen.

Die vorhandenen Plattformfixtures geben für den abschließenden Write tatsächlich ihren positiven `super.setValue`-Abschluss zurück; der Test wartet auf diesen Rückgabepfad. Eine physische Android-Disk-/Stromausfallgarantie wird daraus nicht abgeleitet. Die neuen 14 Wallet-Grenzfälle und ihre stärkere Cache-/Disk-Trennung bleiben unverändert.

## Quellen- und Prüfgrenze

Nur drei Ersetzungsregionen in den zwei Testdateien wurden geändert. Ihre inverse Entfernung rekonstruiert die gesamten exakten 0d7e-Baselinebytes. Beide Baselines wurden zusätzlich vollständig aus ihrem Gitblob gelesen und bytegleich mit dem Commitpfad verglichen. Produktcode, Plattformhelper und alle übrigen Testfälle bleiben außerhalb des Deltas.

**Keine lokale Dart-/Flutter-Ausführung, keine Paketinstallation und kein neuer Test-PASS.** Die reine Quellenprüfung und die tatsächliche spätere CI-Ausführung sind getrennt. Die negative 0d7e-Evidenz bleibt vollständig erhalten; ihre 23/7 sind keine vollständige Suite und kein Ergebnis der 45 neuen Fälle.

`source-upload-manifest.json` bindet die beiden Testdateien. `evidence/implementation-against-exact-0d7e.patch` und `evidence/source-boundary-proof.json` dokumentieren den eng begrenzten Unterschied. Gitblobs werden unveränderlich gesichert; Tree, Commit, Ref und CI-Rerun bleiben beim Integrator.
