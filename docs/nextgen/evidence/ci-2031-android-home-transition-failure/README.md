# Originaler Android-FAIL 2031: nicht synchronisierte Home-Prüfung

**Android: FAIL. Veröffentlichung: SKIPPED. Der Originalfehler bleibt unverändert.**

Quelle ist der tatsächliche [Androidjob 133088843594](https://github.com/Ullmann27/lumo-lernen/actions/runs/43800892196/job/133088843594) aus Run **43800892196**, APK-/QA-Commit **e05a96a52aaf57e466e79831f15aaffd144284ee**, Version **0.13.19+2031**. Validate und Build waren erfolgreich. Die genaue APK-, PCK-, Geräte- und Zertifikatsidentität steht im bytegleich erhaltenen `selected-originals/learning-android-result.json` und `summary.json`.

## Tatsächlich erreicht

- Die getippte Frage „Warum zuerst zwei?“ wurde auf die aktive Zehnerbrücke bezogen; Erklärung, Stopptaste und Rückkehr waren sichtbar. Der erste Modell-Tipp, Pause/Resume und Routen-Rückweg erhielten den tatsächlichen Checkpoint `bridge-8-5`, `moved: 1`.
- **Alle vier Größenwechsel wurden abgeschlossen:** 720×1600@320 dpi, 1768×2208@360 dpi, emuliertes Fold7 außen 1080×2520@420 dpi und innen 1968×2184@420 dpi. Tatsächliche WM-Ausgabe und PNG-Pixel stimmen; Profil und die zwei verglichenen Lernschlüssel bleiben gleich. Auch die Wiederherstellung der Ausgangsgröße erhielt den Checkpoint.
- Die vier Größenwechsel-Videos haben positive ffprobe-Dauern von etwa 4,33 bis 4,85 Sekunden. Die Encodergröße bleibt pro Clip fest; Zielpixel sind über WM und PNG belegt. Es gibt keinen physischen Fold-/Scharnierbeleg.
- Die Flutter-Wortwerkstatt wurde mit Ba–na–ne erreicht, einschließlich Wiederholung, Langsamer und Stopp. Das unveränderte Bild 0271 zeigt die Wortwerkstatt vor Home. Diese Beobachtungen sind kein Nachweis der späteren nativen Banane-Referenz.
- Mikrofon: ausdrücklich `NOT_VERIFIED`; kein echtes gesprochenes Testwort und kein behaupteter Erkennungserfolg. Die Screenrecord-Videos enthalten kein aufgenommenes Audio.

## Primärer Fehler und Beobachtungslücke

`task_roundtrips("words", ...)` sendet genau einmal `KEYCODE_HOME` und fragt unmittelbar `dumpsys activity activities` ab. Der bestehende Code prüft `PACKAGE not in resumed`, **bevor** er die Rohzeilen speichert. Die Assertion `App did not actually leave the foreground` scheitert. Der konkrete fehlgeschlagene frühe Wort-Dump ist deshalb nicht enthalten und darf nicht nachträglich erfunden werden.

Die spätere Originalaufnahme **0272 zeigt eindeutig den Android-Launcher**, keine erneut geöffnete Lumo-App. Das passt zu einer noch laufenden Home-Transition bei der frühen Einzelabfrage; der genaue frühe Zustand bleibt offen. Die gelesenen Lab-, AppShell- und MainActivity-Lifecycle-Pfade führen in diesen Pause-/Resume-Hooks keinen App-Neustart aus. Die vorhandenen Originale belegen keinen unerlaubten Produkt-Relaunch. Der frühere erhaltene Bridge-Activity-Dump 0163 darf nicht als Wort-Dump umgedeutet werden.

Die Wort-Pause samt anschließender Rückkehr und Checkpointvergleich ist **nicht abgenommen**. Native 8+5, native Banane, natives Muster, aktuelle native Leistungsmessung und die zweite vollständige Referenztour wurden nicht erreicht.

## Sekundärer Aufnahmefehler

Beim Aufräumen wirft `recording()` zusätzlich `No decodable actual video was recorded`. Die originale ffprobe-Datei 0270 beschreibt einen H.264-Frame mit `duration_ts: 0` und ohne positive `format.duration`. Der sekundäre Fehler überschreibt das Ergebnisfeld; der Originaltraceback enthält beide Ausnahmen. Das ist keine Messung der App-FPS. Die positive Videodauer-Anforderung bleibt bestehen.

## Verlustfreie Aufbewahrung

- `artifact-14197925395.zip.part01` bis `.part04` enthalten die vollständigen **29.373.558 ZIP-Bytes**, SHA-256 **f2d1ca9232685fe4d25fcd8d6bd745a687f08ac7eb4ef1c5ec36e469d0ba03f4**. Reihenfolge und Einzelhashes stehen in `archive-parts.json`.
- Alle **335 Originalmitglieder** (33.679.689 unkomprimierte Bytes) wurden erneut gegen CRC, Bytezahl, SHA-256 und die extrahierten Originale geprüft. Das gesamte ZIP ist bytegleich rekonstruierbar. `artifact-verification.json` bleibt bytegleich.
- `job-133088843594.log.gz` bewahrt das vollständige **428.498-Byte-Joblog**, Rohhash **a862e1e153c503c34dfbb8495e9c252df7af1625a88f1f5558e3ac1bf3158b4b**. Der Dekompressionsvergleich ist bytegleich; die unveränderte Logmanifestdatei nennt beide Hashes.
- `selected-originals/` ist eine kleine unveränderte Sichtungsauswahl; `selected-originals.json` bindet jede Datei an ihr ZIP-Mitglied. Alle übrigen Videos und Rohdateien bleiben im vollständigen geteilten ZIP erhalten.
- `summary.json` und dieser Text sind abgeleitete Einordnungen, kein neuer Testlauf. `observed-jobs.json` und `github-artifact.json` erhalten die tatsächlich gelesene GitHub-Zuordnung.

Zum Rekonstruieren an einem Ort mit genügend Speicher:

```sh
cat artifact-14197925395.zip.part01 artifact-14197925395.zip.part02 artifact-14197925395.zip.part03 artifact-14197925395.zip.part04 > artifact-14197925395.zip
sha256sum artifact-14197925395.zip
gzip -dc job-133088843594.log.gz > job-133088843594.log
```

Die Archivierung verändert den ursprünglichen FAIL nicht und startet keinen neuen Androidlauf. **`fullModernizationComplete=false`** bleibt bestehen.
