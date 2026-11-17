# Unveränderte Ausschnitte des tatsächlichen Android-Fehllaufs

Quelle `e05a96a52aaf57e466e79831f15aaffd144284ee`, Run `43800892196`,
Job `133088843594`, Artefakt `14197925395`. `manifest.json` bindet jedes der vier
bytegleich übernommenen Originale an das vollständige, von Root verifizierte
ZIP. Der ursprüngliche Lauf bleibt **FAIL**.

- `0163-bridge-paused-activity.txt` ist die tatsächlich beobachtete frühere
  Bridge-Pause mit Androids NexusLauncher. Es ist kein nachträglich erfundener
  Dump der später fehlgeschlagenen Wort-Pause.
- `0270-words-pause-return.mp4` und dessen unverändertes CI-ffprobe-JSON erhalten
  die tatsächliche Einbildaufnahme ohne positive Videodauer.
- `learning-android-result.json` enthält den ursprünglichen Home-Primärfehler
  und dessen anschließende Überdeckung durch den Aufnahmefehler.

Der abgewiesene frühe Wort-Activity-Dump fehlt im Originalarchiv, weil die alte
Probe ihn erst nach ihrer Assertion geschrieben hätte. Die Tests konstruieren
App→Launcher-, Leer-, Mehrdeutigkeits- und Deadline-Abläufe ausdrücklich. Sie
verwenden den echten früheren Launcher-Dump als zulässige Beobachtung und rufen
lokales ffprobe auf der unveränderten MP4 auf; adb/Recordertransport und Zeit
sind kontrollierte Testadapter. Kein neuer Androidlauf und kein Produkt-PASS.
