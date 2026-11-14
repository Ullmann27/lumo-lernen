# Memory: bestätigter Plattform-Readback auf Host b721

## Befund und enger Produktfix

Basis: Host `b7210db3f53361987fd33592de438fd7984d991a`, Tree `c65558a13e4dd2950eda7a685583e5484d9b9959`.

Das gelesene `pubspec.lock` bindet shared_preferences 2.5.5. Dessen echte Legacy-Implementierung schreibt den Dart-Cache vor dem Plattformaufruf; `getString` liest diesen Cache. Der bisherige Memory-Adapter wirft bei einem negativen Schreibresultat, liefert anschließend aber denselben optimistischen Cache zurück. Die vorhandene Controller-Wiederherstellung kann diese Textgleichheit als bestätigten Schreibvorgang behandeln. Der vollständige Quellenpfad ist belegt; ein neuer ausgeführter Rotlauf wird hier **nicht** behauptet.

Geändert wird ausschließlich `memory_flutter_adapter.dart`: `readRound` und `readStats` rufen eine kleine private Methode auf, die vor jedem Lesen `preferences.reload()` erfolgreich abwarten muss. Ein fehlgeschlagener Reload wirft; auch der nächste Zugriff und eine neue Adapter-/Controllerinstanz müssen erneut erfolgreich laden. Es gibt keinen instanzlokalen Vertrauensschalter und keine Rückgabe des Caches bei einem Reloadfehler. Ein tatsächlicher Plattform-Commit mit verloren gegangener Antwort bleibt durch den anschließend bestätigten Readback wiederherstellbar.

Regeln, Dealer, Gegner, Profile, Runden-/Statistikschlüssel, Belohnungsbeträge, Controller, TableSession und die Schreibmethoden bleiben unverändert. Der eng begrenzte Zusatz verursacht einen Plattform-Read pro bisherigem Adapter-Read; Geräte-Laufzeit oder Performance wurde hierfür noch nicht gemessen.

## Neue Regressionen

`test/games/memory_preferences_durability_test.dart` definiert **14 Fälle**. Sie verwenden die echte `SharedPreferences`-Cacheimplementierung sowie den Produktionsadapter und Produktionscontroller. Ausschließlich das Plattform-Backend wird kontrolliert ersetzt. Dessen separat gelesener Inhalt dient als unabhängiges Speicherorakel.

Die Fälle prüfen abgewiesenes erstmaliges Speichern; Round- und Stats-Schreibfehler mit false und Exception; wiederholte Reloadfehler; zweite Store- und neue Controllerinstanz über derselben Preferences-Singletoninstanz; tatsächlichen Backend-Commit vor verlorener Antwort; die offene Ergebnisbestätigung nach fehlgeschlagenem Statistikwrite und identische Ergebnis-ID beim Wiederholen; Profilentzug vor einer Aktion, während eines Reads und während eines bereits angenommenen Writes. Ein bereits angenommener alter Write darf nur seinen erfassten Kindschlüssel erreichen und kein Ergebnis in die neue Auswahl einsetzen.

Die Ergebnis-ID-Prüfung im neuen Test verwendet einen ausdrücklich kontrollierten Callback und keine echte Android-Wallet. Die bestehenden Wallet-/Profiltests bleiben unverändert. Alle Reads aus dem Test-Backend sind In-Memory-Operationen; sie sind kein physischer Festplatten-, Prozessneustart- oder Androidnachweis.

## Ausführungsstand

**Noch kein Flutter-/Dart-Test dieses neuen Pakets ausgeführt.** Lokale Flutter-/Dart-/pub-get-Aufrufe bleiben ausdrücklich untersagt. Vorhanden sind die frische Git-Quellenbindung, die lokale Byte-/SHA-Prüfung und der enge Diff. 14 definierte Fälle sind keine 14 bestandenen Tests.

Für den nächsten autorisierten CI-Lauf ist der konkrete Testaufruf:

```bash
flutter test --no-pub test/games/memory_preferences_durability_test.dart
```

Die vorhandenen Memory-Profil-, Autoritäts-, Wallet- und vollständigen Flutter-Gates müssen weiterhin ausgeführt werden. Kein Gate, Timeout, Saveformat oder alter Test wurde verändert.

## Dateien

- `prepared/lib/features/games/memory/memory_flutter_adapter.dart`: einziger Produktdelta.
- `prepared/test/games/memory_preferences_durability_test.dart`: neuer begrenzter Regressionstest.
- `baseline/`: exakt gebundener ursprünglicher Adapter und unveränderter Controller.
- `evidence/implementation-against-exact-b721.patch`: enger Produktdiff.
- `evidence/source-binding.json`: b721-/Paketquellen und Hashes.
- `evidence/preparation-verification.json`: Byteprüfung und ausdrücklicher Ausführungsvorbehalt.
- `evidence/profile-and-reward-audit.json`: Profil-/Runden-/Walletbefund mit Grenzen.
- `evidence/shared_preferences-2.5.5-original.dart`: gelesene offizielle Versionsquelle.

Die gemeinsame Wallet bleibt `lumo_reward_wallet_v1`; neue Runden und Bestwerte sind an SHA-256 der erfassten studentId gebunden. Dieses Paket führt keine getrennte Kinderwallet und keine automatische Übertragung historischer unzugeordneter Memorydaten ein.

## Unabhängiger Quellenreview und Sourcefreeze

B hat die vollständigen beiden Enddateien sowie die tatsächlich gepinnten Preferences-APIs gelesen. Seine separate Notiz liegt unter `qa/memory-durability-peer-review-b721-20261114/review.json` (SHA-256 `09e5e429f0aab23a15743b8522d5b52a93c20f25af5f2502f1b016c49d454764`). Er meldet keinen zusätzlichen konkreten Blocker im geprüften Umfang und hat keine Tests ausgeführt.

`source-upload-manifest.json` bindet genau zwei Quellen samt tatsächlichen Create-Blob-IDs und vollständigen UTF-8-Readbacks. `confirmed-source-tree-inputs.json` enthält nur die beiden vorbereiteten Treeeinträge; ein Tree, Commit oder Ref wurde nicht erzeugt.
