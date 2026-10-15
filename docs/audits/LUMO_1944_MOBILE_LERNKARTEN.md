# Lumo 1944 – Mobile Lernkarten & Schulstufenmissionen

Basis: Build 1943, Commit `cbb25b2729a9406a7215c8cae93e8f74068ef402`.

- Fix: Aktionskarten im Schularbeiten-/Mathe-/Deutsch-Bereich passen auch auf schmale Fold-Cover. Raster nutzt große Bildschirme dynamisch.
- Fix: Schriftvergrößerung erhöht die Kartenhöhe, statt Beschreibungen in feste 160 dp zu pressen.
- Besserer Zugriff auf Aktionskarten per Fokus/Accessibility mittels InkWell statt ausschließlich GestureDetector.
- Mathe-Insel startet eine tatsächlich vorhandene Unit aus der aktuell gewählten Schulstufe; keine pauschale Klasse-1-Unit für Klasse 4.
- Kurzübung benennt ehrlich, was startet, statt unbelegt drei abgeschlossene Aufgaben zu versprechen.
- Unbenutzte Imports entfernt. CI soll 280/360/967 dp, 160% Schrift, Englisch-Routing sowie vollständige Tests und signierte kombinierte APK prüfen.

Keine rückwirkenden Änderungen an 1943, nicht an main mergen, nicht veröffentlichen, keine echte Hardware- oder Hörprobe behaupten.
