# Nächster konkreter Schritt

Auf `design/lumo-home-cinematic-20261020` weiterarbeiten. Nicht erneut von
Main oder dem reinen Designbrief beginnen.

1. Kategorie 1: Hero mit vollständig sichtbarem Original-Lumo, lesbarem
   dynamischem Begrüßungstext und goldener Loslernen-Aktion umsetzen.
2. Gemeinsame Glas-/Materialhierarchie und begrenzte Szeneneffekte verwenden.
   Weniger Bewegung, Ruhemodus und ausgeblendete Routen berücksichtigen.
3. Mit demselben Produktions-Shell-Test nach `evidence/after` rendern:

   ```sh
   LUMO_NEXTGEN_CAPTURES=docs/design/lumo-nextgen-2026-10-20/evidence/after \
     flutter test --no-pub --reporter expanded \
     test/design/home_nextgen_capture_test.dart
   ```

4. Vorher/Nachher tatsächlich ansehen; insbesondere Ohren, Textfaktor 2,
   Fold, kleine Touchziele und Lernhelfer prüfen.
5. Home-/Navigation-/Wallet-/Zweitversuch-Regressionen und Analyse ausführen.
   Ergebnisse, veränderte Pfade und verbleibende Abweichungen in STATUS
   dokumentieren; Code und Bilder committen und pushen. Draft-PR auf #392.
6. Kategorie 2 erst nach dem Qualitätsgate von Kategorie 1 beginnen.

Originalreferenzen fehlen konkret wie in STATUS und ASSET_CATALOG benannt.
Vorhandene Fuchsassets weiterverwenden; fehlende Bilder nicht erfinden.
