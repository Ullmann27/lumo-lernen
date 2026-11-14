# Memory: enger Dart-Promotionsfix nach e2db

## Tatsächlicher Ausgang

Basis ist Host `e2db0d60af51266caa9b54ffd08eb0947ae99ac6`. Der ursprüngliche `memory_round.dart`-Blob ist `6d691fffc24c70faf3a78d176cbba6b73b66c6a1` (SHA-256 `9238bc5a7966db2dccd39b819ade6925fef7270a44ae4308294769a75b178216`).

Der tatsächliche Feature-Run `43632642356` meldete im Memory-Source-Job `132562421738` einen Compilerfehler. Der unabhängig gesicherte Flutter-Analyzer des Jobs `132562421770` nennt dieselben beiden `undefined_method`-Fehler an Zeilen 268 und 277: Die Methoden der Bestätigungsschnittstelle sind für den dort statischen Typ `MemoryStore` nicht verfügbar. Die neuen Regressionen und die vollständige Flutter-Suite wurden dadurch noch nicht ausgeführt.

Die vorhandenen Originalartefakte bestätigen Flutter **3.44.9** und Dart **3.12.2**. Hier wurden nur ihre kleinen Versionsdateien gelesen und bytegleich kopiert; kein Originaljoblog oder Archiv wurde erneut heruntergeladen.

## Genau zwei geänderte Zeilen

Die beiden Aufrufe innerhalb des bereits vorhandenen `is MemoryReadbackConfirmation`-Guards verwenden jetzt einen expliziten Cast:

```dart
await (confirmation as MemoryReadbackConfirmation).confirmRoundReadback(value);
await (confirmation as MemoryReadbackConfirmation).confirmStatsReadback(value);
```

Die offizielle [Dart-Dokumentation zum Subtype mismatch](https://dart.dev/tools/non-promotion-reasons#subtype-mismatch) beschreibt die fehlende Promotion zwischen unabhängigen Interfaces und führt den expliziten Cast innerhalb des Typguards als Lösung auf. Hier prüft der unveränderte Guard dieselbe lokale finale Referenz unmittelbar vor dem jeweiligen Cast; dazwischen liegt kein Await.

Die inverse Ersetzung ausschließlich dieser zwei Aufrufzeilen rekonstruiert den vollständigen ursprünglichen e2db-Blob. Interfaces, Profilguards, Regeln, Speicherbarrieren, Tests, Fristen und alle übrigen Bytes bleiben identisch. Der zuerst erwogene Object-Deklarationsentwurf wurde nicht als Sourceblob veröffentlicht; die endgültige Übergabe enthält ausschließlich die zwei Cast-Aufrufe.

## Gesicherte Übergabe und Grenze

Die eine endgültige Datei hat 16.155 Bytes, SHA-256 `e1911d59e58d92b92dbb56a1447702656dff491ae1a61edec051b976ce74af1d`, Gitblob `4844cabaa5ed881d8f29dbd7c9758f03ef510df4`. Sie wurde vollständig UTF-8-identisch zurückgelesen. `source-confirmed-tree-inputs.json` enthält genau diesen einen Eintrag.

Der alte Memory-Freeze und seine ursprünglichen CI-Fehler bleiben unverändert. B und Root haben den engen Diff gelesen; ein neuer erfolgreicher Compiler- oder Testlauf wird hier nicht behauptet. Es gab keine lokale Dart-/Flutter-Ausführung, keine Paketinstallation und keine Refmutation. Der nächste tatsächliche CI-Lauf bleibt erforderlich.
