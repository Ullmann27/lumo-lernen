# System-Image-Anschluss1906 · neue Beschreibung nach Wiederherstellung

Diese Beschreibung wurde am9. Oktober2026UTC neu erstellt. Sie ist nicht die
verlorene ursprüngliche SDK576-Übergabe. Der Helper selbst ist bytegleich mit
dem veröffentlichten Diagnosecommit7cff9e0eb233b6386b51d459f8b29a2958d3e21d
(SHA2568925b7b41fada3c41fc80959c03fb71314f60530adbdc8e6614ea94e0c6a9c51).
Seine neuen Tests liefern58 PASS/0 FAIL/0 SKIP; keine alten56-/398-/436-
Testergebnisse werden auf den neuen Testquellstand übertragen.

Der ursprüngliche Android-Runner bleibt erhalten. Der Vorlauf prüft ausschließlich
`system-images;android-35;google_apis;x86_64` bzw.API36. Er erzeugt keine AVD,
ändert keine Emulatordefinition und beantwortet keine Lizenzabfrage. Bereits
vorhandene reguläre Lizenzdateien und der vorhandene SDKmanager sind erforderlich.
Alle Operationen teilen600 Sekunden; nur die genau bekannte rc1/ZipFile-Antwort
erlaubt höchstens drei Installationsversuche. Andere Fehler bleiben FAIL.

Vier Pflichtimages müssen regulär, nicht symlink und nicht leer sein:
`system.img`, `vendor.img`, `kernel-ranchu`, `ramdisk.img`. Zusätzlich muss eine
vollständig gültige Form vorliegen:

- Legacy: reguläre nicht leere `userdata.img`.
- Moderne Seeds: regulärer nicht symlink `data/`-Ordner mit regulärem
  `empty_data_disk` (null Bytes zulässig) und regulärer nicht leerer `local.prop`.

Eine vorhandene ungültige Alternative wird auch dann abgewiesen, wenn die andere
Form gültig ist. Symlinks, FIFOs, falsche Typen, beschädigte Metadaten, fremde
API/Architektur und abweichende installierte Revisionen bleiben FAIL. Rohe
Properties/XML und installierte Paketliste bleiben erhalten; der Bootstrap-
Bericht bindet beobachtete Größen. Er behauptet keine unbekannten Seed-Content-
Hashes und keine tatsächliche AVD-/Android-Ausführung.

Quelle ist die im vorhandenen Helper genannte offizielle
[SDKmanager-Dokumentation](https://developer.android.com/tools/sdkmanager).
Der Aufruf wird an das bestehende Projekt angepasst; es wurde kein fremder
Implementierungscode übernommen. Neue Tests prüfen den echten lokalen Helper
mit kontrollierten Metadaten, Fehlern, Fristen und CLI-Prozessen. Ein tatsächlich
neu installierter SDK/Emulator bleibt in diesem Wiederherstellungsstand
**NOT EXECUTED**, bis der frische Androidlauf entsprechende Rohdaten liefert.
