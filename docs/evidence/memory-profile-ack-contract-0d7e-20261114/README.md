# Memory-Profiltests: ACK und abgeschlossene Testschreibvorgänge

Basis ist ausschließlich Host `0d7e6e5efb1fe8cd2e9a7f92cdd4034b81173304`. Der neue Patch verändert nur `test/games/memory_profile_storage_test.dart`; Controller, Adapter, Wallet und Widgets bleiben unverändert.

## Tatsächlicher Ausgangsbefund

Der vorhandene Originaljoblog (SHA256 `730624ed6be190ce6305d6b8c90e4d8eddb96c9a25ac22c5c4b4139c5e1b4ab2`) meldet drei Fehler in dieser Datei. Im ersten Fall erwartet Zeile 175 genau einen Statistikschreibvorgang; tatsächlich wurden zuerst die bestehenden leicht-Bestwerte unverändert positiv bestätigt und danach die echte profi-Auswahl geschrieben. Die positive Bestätigung ist Bestandteil des neuen Speichervertrags und darf nicht entfernt werden.

Diese Assertion steht vor `gate.complete()`. Ihr tatsächlicher Abbruch lässt das gehaltene Future offen. Der bestehende, absichtlich fortbestehende Controller-Ownerpfad wartet weiter auf diesen Schreibvorgang. Die danach für dasselbe Kind angelegten Controller kommen deshalb in diesem Quellenpfad nicht bis zur fertigen Oberfläche. Der dazwischen erfolgreiche Identitätsfall wechselt dagegen zu Kind B. Das ist eine Erklärung aus Originalreihenfolge und gelesener Quelle; ein neuer isolierter Widgetlauf wurde nicht durchgeführt.

## Enger Testnachtrag

Beide betroffenen Schreibtests prüfen zuerst den vollständigen, exakt identischen Statistik-Lade-ACK inklusive Kindschlüssel. Erst danach wird ein Checkpoint für Nutzereingaben gesetzt. Die weiterhin erwartete Reihenfolge und Anzahl der echten Änderungen bleiben erhalten; vollständige Schlüssel und serialisierte Payloads sowie unveränderte Speicherwerte während des gehaltenen ACK werden zusätzlich geprüft. Beim Profilwechsel wird auch der separate ACK von Kind B im vollständigen Verlauf gebunden.

Beide Testgates werden in `finally` ausschließlich bei noch fehlendem Abschluss freigegeben. `tester.idle()`, Widgetabbau und ein zweites `idle()` arbeiten ausstehende Fortsetzungen in derselben Widget-Testzone ab. Eine ursprüngliche Assertion bleibt ein Fehler; sie soll weitere Tests nicht durch einen absichtlich offen gebliebenen Schreibvorgang blockieren.

Alle sechs ursprünglichen Testnamen bleiben erhalten. Vier vollständige Testblöcke sind bytegleich. Die inverse Ersetzung der genau zwei geänderten Testblöcke stellt die gesamte frisch von GitHub gelesene Basisdatei wieder her.

## Ausführungsgrenze

Es erfolgten keine lokalen Dart-/Flutteraufrufe, keine Installation und keine neue Widget-Testausführung. Der Originalfehler bleibt erhalten. Der neue tatsächliche CI-Lauf muss die sechs Profilfälle zusammen mit den Speicher-/Wallet-Gegenfällen bestätigen. Es gibt keinen neuen Android-, Datenträger- oder fsync-Nachweis.

Die statischen Quellbindungen und der unveränderte Originalauszug stehen unter `evidence/`. Die unabhängige Peerprüfung erfolgt bei B; deren eigener Beleg wird getrennt referenziert.
