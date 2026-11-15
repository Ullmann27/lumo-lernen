# Ganze CrossGrade-Lernansichten

Sechs unveränderte PNG-Aufnahmen des tatsächlich ausgeführten Flutter-Fensters, mit Nunito- und Material-Icon-Fonts. Einstieg: vorhandene praktische Aktivität `g1_art_notice` → digitale Ergänzung → `CrossGradePracticeScreen`, Geometrie Formen. Der Test überprüft den aktuellen kanonischen Aufgabenanschluss und sämtliche Auswahl-/Objektkennungen; `manifest.json` dokumentiert die erzeugten Aufgaben.

Die Dateien `*-entry.png` zeigen den Einstieg, `*-task.png` den per echter Scrollbewegung erreichbaren Aufgabenbereich. Keine Montage und keine nachträgliche Bildbearbeitung.

Logische Größen: kleines Handy 320 × 780, Fold-Außenansicht 344 × 882, Fold-Innenansicht 690 × 829. Rasterisierung mit Faktor 1,5. Das sind Viewport-Simulationen, keine Tests auf physischen Samsung-Geräten. Ein frisches lokales Prüfprofil erzeugt keine erfundenen Lernstände oder Belohnungen.

Reproduktion: `flutter test --no-pub test/learning/cross_grade_navigation_capture_test.dart` (im gemeinsamen Workspace mit vereinbartem `flock --close`).
