# Lumo: verbindliche visuelle Vorher-/Nachher-Abnahme

Gilt für **jede** Änderung an Layout, Grafiken, Farben, Typografie, Animation,
Lumo-Figuren, Story-Illustrationen, interaktiven Spielen oder Kart-Oberflächen.
Ein bestandener Compiler-/Unit-Test **ersetzt nie** die Sichtprüfung.

## Mindestnachweise pro Designänderung

1. **Vorher**: echter, unveränderter Runtime-Screenshot des letzten
   freigegebenen Builds. Die Versionsnummer und Commit-SHA sind beizulegen.
2. **Nachher**: derselbe reale Bildschirm aus dem neuen Branch, mit gleicher
   Bildschirmgröße, Einstellungen, Sprache, Story-/Fragen-Sequenz und Test-Seed.
3. **Gemeinsamer Vergleich**: direkter Vorher-/Nachher-PNG-Vergleich;
   Original-PNGs zusätzlich im Archiv lassen. Keine nachträglich veränderten
   Screenshots, keine Mockups als angebliche App-Aufnahmen.
4. **Gerätematrix**: mindestens 412×915 (Handy), 344×882 (Fold-Außendisplay)
   und 690×829 (Fold geöffnet) in logischen Pixeln. Auf Bedarf Querformat
   zusätzlich. Für Kart mindestens echtes Godot-Gameplay-Rendering, nicht
   nur Flutter-Widgettests.
5. **Prüfung**: Text gut lesbar, kein Überlauf, echte Original-Lumo-Figur,
   auswählbare Elemente sichtbar, Touch-Ziele ausreichend groß,
   Zustände für Auswahl/Fehler/Erfolg nachvollziehbar, Animationen bei
   reduziertem Bewegungsmodus geprüft.
6. **Transparenz**: Wenn ein Bild noch nicht gerendert wurde, steht
   **'Screenshot ausstehend'**. Wenn Tests fehlschlagen, steht
   **'visuelle Abnahme nicht bestanden'**. Niemals Ersatzbilder oder reine
   Programmbeschreibungen als verifizierte Resultate präsentieren.
7. **Veröffentlichung**: Bei Design-/Grafikänderungen zuerst funktionierender
   Screenshot-Nachweis, dann CI und Android-Emulatorprüfung; erst danach
   eine APK als neue freigegebene Version bezeichnen.
8. **Übergabe an den Nutzer**: Vorher und Nachher **hier im Chat zeigen**,
   sobald die echten PNGs verfügbar sind, sowie GitHub-Artefakt/Galerie
   verlinken. Benenne explizit, was im Android-Release sichtbar ist und
   was nur in einem Entwicklungsbranch existiert.

## 1987: erste verpflichtende Vergleichsserie

- GitHub Action: `.github/workflows/lumo-visual-before-after.yml`
- Unveränderter Ausgangspunkt: `lumo-v0.12.74-1986-integrated-reading`
- Neuer Quellstand: exakter Head von PR #380
- Test: `test/design/denkprofil_knobel_before_after_capture_test.dart`
- Berichtsgenerator: `scripts/visual_before_after_report.py`
- Resultat: 15 Originale vorher, 15 Originale nachher, 15 vergleichende
  PNGs, lokale HTML-Galerie `index.html`, SHA-256-Manifest sowie
  `PROVENANCE.txt`, im GitHub Actions Artifact (90 Tage).

Diese Tests decken **Denkprofil und Knobeltest** ab. Für weitere geänderte
Bildschirme müssen eigene echte Vorher-/Nachher-Fälle ergänzt werden;
diese 15 Paare sind kein Beleg für andere Screens oder Kart-3D-Qualität.
