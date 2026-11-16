# Sichtbare Touch-Flächen aus den originalen 2031-Ansichten

Dies ist eine rein lesende Auswertung der vier tatsächlichen UIAutomator-XMLs und WM-Metadaten aus Run **43800892196**, Artefakt **14197925395**, APK-Quelle **e05a96a52aaf57e466e79831f15aaffd144284ee**. Kein neuer Androidlauf und keine nachträgliche Änderung seines FAIL-Ergebnisses.

Die hier kopierten acht Originaldateien wurden gegen das unveränderte vollständige Artefaktmanifest bytegeprüft. `inspection.json` enthält ihre Hashes und jede ausgewertete Beobachtung. Umrechnung: sichtbare Pixel × 160 / tatsächliche Android-Testdichte in dpi. Die Testdichte ist keine physische PPI-Angabe.

Unter den vier Modell-XMLs befinden sich **35 aktivierte, als klickbar gemeldete Beobachtungen**. **29** erreichen in den beobachteten sichtbaren Bounds in beiden Dimensionen mindestens 48 dp. Die sechs übrigen Rechtecke liegen jeweils genau am unteren Rand ihres scrollbaren Vorfahren und sind nur teilweise im Viewport sichtbar; ihre sichtbare Höhe unterschreitet 48 dp. Daraus wird keine vollständige Touch-Abnahme oder vollständige Tastenhöhe abgeleitet.

Die vollständig sichtbaren Vorratssteine und Zurücktasten erreichen in allen vier Ansichten mindestens 48 × 48 dp. Die vollständig sichtbaren verschobenen Steine sind größer. Die Auswertung enthält Wiederholungen derselben Bedienelemente in unterschiedlichen Größen; **35 ist keine Zahl verschiedener App-Funktionen**.

`allAppTouchTargetsVerified=false`: Native 3D-Touch-Flächen, verdeckte Teile, weitere Scrollpositionen, sämtliche anderen Aufgaben und physische Geräte werden durch diese Daten nicht nachgewiesen. Die Screenshots dieser Ansichten und alle übrigen Originale bleiben unter `../ci-2031-android-home-transition-failure/` erhalten.
