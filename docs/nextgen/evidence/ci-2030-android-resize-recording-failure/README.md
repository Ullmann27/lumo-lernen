# Originaler Android-FAIL 2030: Kompaktaufnahme ohne positive Dauer

**Status: FAIL. Veröffentlichung: SKIPPED. Keine Releasefreigabe und kein neuer Android-PASS.**

Dieses Verzeichnis bewahrt den vollständigen Originalbeleg des Androidjobs
[133056371546](https://github.com/Ullmann27/lumo-lernen/actions/runs/43790915460/job/133056371546)
aus [Run 43790915460](https://github.com/Ullmann27/lumo-lernen/actions/runs/43790915460).
Validate und Build waren erfolgreich; der Androidjob scheiterte in der ersten
Kompaktaufnahme. Die übergeordnete Statusangabe zu Validate/Build und der
übersprungenen Veröffentlichung stammt aus der von Root geprüften Laufzuordnung.
Das vollständige Androidprotokoll und dessen unverändertes Ergebnis sind hier enthalten.

## Exakte Herkunft

| Feld | Originalwert |
| --- | --- |
| Flutter-Quelle | `c4e330faa61e231dd3fd44c21085c95ddcd5b7c9` |
| Version | `0.13.18+2030` |
| Native-Quelle | `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef` |
| x86-APK SHA-256 | `66870e9232eaf05e5cad893d410cb8046318ae6d226c0bd0e90e1af0a178a4f2` |
| PCK SHA-256 | `8a92cb22afabe31dfba7fc80f73e4b92aa7fb469c69699745fcb7c00d84b484b` |
| Artefakt | `14192539626`, 19.467.723 Bytes, 225 Dateien |
| Original-ZIP SHA-256 | `e7ca12c47729ece9ca880db91a80beea0dec63cc5d82f5d7c0c975e3c9885b35` |

Paket, Signatur, Version und installierter Bytehash stehen unverändert in
`selected-originals/learning-android-result.json`; die Buildherkunft in
`selected-originals/candidate-BUILD-PROVENANCE.json`. Die PCK-Bytes gehören genau
zu diesem 2030-Build und dürfen nicht durch einen Hash des älteren 2029-Builds ersetzt werden.

## Tatsächlich erreichte Schritte

- Die Installation, das fiktive Klasse-1-Profil, die Einstellungen und das
  aufgabenbezogene Gespräch wurden erreicht. Die getippte Frage „Warum zuerst zwei?“
  erhielt die im Originalergebnis gespeicherte Erklärung mit 8, 2, 10 und den übrigen 3.
- Nach dem Gesprächs-Rückweg bewirkte der erste protokollierte Tipp auf
  „Vorratsstein 1, ins Feld verschieben“ den Übergang `moved: 0` zu `moved: 1`.
  Belege: Präferenzen 0153, Touch 0156 und erster Checkpoint 0157.
- Pause/Resume und der echte Routen-Rückweg erhielten Profil und Lernstand.
  Das Originalergebnis vergleicht jeweils zwei Lernschlüssel. Der zusätzliche
  rein lesende Archivvergleich bestätigt darüber hinaus identische geparste
  Präferenzwerte vom ersten `moved: 1` bis zum Kompakt-Checkpoint.
- Die kompakte Zielansicht meldet tatsächlich WM-Override `720×1600`, Testdichte
  `320 dpi`; PNG 0186 besitzt genau diese Pixelmaße. Das sind Android-Testwerte,
  keine Behauptung über die physische Pixeldichte eines Geräts.
- Der kompakte Aufgabenstand bleibt `moved: 1`, `attempt: 0`, `done: false`.
  Es wurde dabei keine Antwort gewertet oder Belohnung neu ausgelöst.
- Der Mikrofon-Permissionweg wurde erreicht. Das Ergebnis lautet ausdrücklich
  `explicit_device_limitation` und `recognition: NOT_VERIFIED`; es wurde kein
  echtes gesprochenes Testwort geliefert und kein STT-Erfolg festgestellt.

## Konkreter Abbruch und seine Grenze

`learning-android-result.json` bricht beim Verlassen von `recording()` in
`resize_bridge()` ab: **`No decodable actual video was recorded`**.
Dieser vorhandene allgemeine Fehlertext ist keine Feststellung eines defekten Codecs.
Das unveränderte 93.539-Byte-MP4 enthält laut vorhandener ffprobe-Auswertung einen
lesbaren H.264-Videoframe bei `720×1600`; Streamdauer `0.000000`, keine
`format.duration`. Damit erfüllt es das unveränderte Gate für eine positive
Videodauer nicht. Die Recorder-Stderr-Datei ist leer.

Die damalige Probe führte WM-Größenwechsel und Wartezeit vor dem Aufnahmestart aus.
Die danach beobachtete Zielseite erforderte keine Suchgeste; aufgenommen wurde die
ruhende Kompaktansicht. Dieser Capture-Ablauf und die Originaldatei belegen den
Fehler. Sie begründen keinen vollständigen Resize-PASS und keine nachträgliche
Umdeutung dieses Laufs. Die Behebung des Ablaufs wird getrennt versioniert.

**Nicht erreicht:** erweiterte Ansicht, beide emulierten Fold7-Auflösungen,
die späteren Labor-Banane-/Musterteile, native 8+5-, Banane- und Musterreferenzen
sowie deren Audio-/Avatar-/Performanceprüfungen. Für diese Schritte enthält dieser
Lauf keinen erfolgreichen Nachweis.

## Vollständigkeit und Rekonstruktion

- `artifact-14192539626.zip.part01` bis `.part03` enthalten die vollständigen,
  unveränderten ZIP-Bytes in 8-MiB-Teilen. `archive-parts.json` nennt Reihenfolge,
  Größen und Einzelhashes. Zusammengesetzte Größe und SHA-256 wurden erneut geprüft.
- `artifact-verification.json` wurde bytegleich aus der Originalablage übernommen.
  Alle 225 ZIP-Mitglieder wurden erneut gegen CRC, Bytezahl und SHA-256 sowie gegen
  die vorhandenen extrahierten Originale geprüft. Eindeutige sichere ZIP-Pfade wurden geprüft.
- `job-133056371546.log.gz` enthält das vollständige 424.364-Byte-Joblog mit 3.716
  Zeilen, einschließlich ursprünglichem UTF-8-BOM. Gzip-Mtime ist 0. Der
  Dekompressionsvergleich ist bytegleich; beide Hashes stehen in `job-log-verification.json`.
- `selected-originals/` enthält nur eine kleine, bytegleiche Auswahl zur direkten
  Sichtung. Ihr Manifest ordnet jede Datei dem ursprünglichen ZIP-Mitglied zu.
  Das Pause-/Rückkehrvideo wird nicht nochmals dupliziert; seine Metadaten liegen
  im Auszug und seine vollständigen Bytes im ZIP.
- `derived-inspection/root-ffprobe-original.json` ist die unveränderte, nachträgliche
  Root-Auswertung des Original-MP4. Sie ist ausdrücklich kein Originalmitglied des
  CI-ZIP. `summary.json` ist eine abgeleitete Einordnung, kein neues Testergebnis.
- `verification.json` bindet die Archivdateien durch Bytezahlen und SHA-256.

Zum Rekonstruieren an einem Ort mit genügend Platz:

```sh
cat artifact-14192539626.zip.part01 artifact-14192539626.zip.part02 artifact-14192539626.zip.part03 > artifact-14192539626.zip
sha256sum artifact-14192539626.zip
gzip -dc job-133056371546.log.gz > job-133056371546.log
```

Vor dem Entpacken müssen die ZIP-Bytezahl und der oben angegebene SHA-256 stimmen.
Die ursprünglichen Dateien wurden nicht verändert oder gelöscht. Für diese
Archivierung wurde kein neuer Androidlauf gestartet.
