# Echte Android-Abnahme für die neue Vier-gewinnt-Szene

Stand: 14. November 2026. Dieser Prüfer ist vorbereitet und lokal mit **25 Vertragsfällen bestanden**. Es wurde damit noch keine APK, kein Android-Gerät und kein Emulator ausgeführt. Die bereits gebaute Quelle `86445f53af5d573549fc8cf03405261611f3cb7e` enthält die neue native Vier-gewinnt-Szene noch nicht; ihr Android-PASS ist ausdrücklich kein C4-PASS.

## Ausführung nach dem nächsten echten Kandidatenbau

Die neue Datei gehört unter `.github/probes/lumo_connect_four_android_probe.py` in genau den Hostcommit, aus dem die zu prüfende APK gebaut wird. Erforderlich sind ein sauberer Hostcheckout, ein sauberer Checkout seines tatsächlich gepinnten Nativecommits, die originale x86-APK samt `BUILD-PROVENANCE.json` und `ANDROID-TOUR-SHA256SUMS.txt` sowie das erfolgreiche Ergebnis der unveränderten normalen 21-Schritte-Tour auf derselben bereits installierten APK.

Die Umgebung benötigt dieselben Python-/Pillow-/ADB-/UI-Leseabhängigkeiten wie die vorhandenen Androidproben. Für die bestehenden Flutter-Rückkehrprüfungen bleiben Tesseract mit Deutsch und Englisch sowie die vorhandenen Grenzen von 30 Sekunden, 12 Beobachtungen und zwei bestätigten sichtbaren Bildern nötig. Der neue Prüfer ändert diese Helfer nicht.

Der folgende Aufruf verwendet ausdrücklich vom Kandidatenworkflow gesetzte Quellen- und Artefaktpfade. `LUMO_HOST_COMMIT` und `LUMO_NATIVE_COMMIT` sind vollständige, tatsächlich veröffentlichte SHA-Werte des neuen Kandidaten, keine Werte eines früheren Laufs.

```bash
cd "${LUMO_HOST_SOURCE:?Sauberer Hostcheckout erforderlich}"
python3 .github/probes/lumo_connect_four_android_probe.py \
  --candidate-source . \
  --native-source "${LUMO_NATIVE_SOURCE:?Sauberer gepinnter Nativecheckout erforderlich}" \
  --expected-source "${LUMO_HOST_COMMIT:?Vollständiger APK-Quellcommit erforderlich}" \
  --expected-native "${LUMO_NATIVE_COMMIT:?Vollständiger Native-Pin erforderlich}" \
  --apk "${LUMO_CANDIDATE_APK:?Originale x86-APK erforderlich}" \
  --provenance "${LUMO_BUILD_PROVENANCE:?Originale Buildprovenienz erforderlich}" \
  --sums "${LUMO_ANDROID_SUMS:?Originale Prüfsummen erforderlich}" \
  --tour-result "${LUMO_TOUR_RESULT:?Erfolgreiche normale Tour erforderlich}" \
  --expected-api "${LUMO_EXPECTED_API:?35 oder 37 erforderlich}" \
  --serial "${LUMO_EMULATOR_SERIAL:?Expliziter Emulator erforderlich}" \
  --out "${LUMO_C4_EVIDENCE:?Neuer Belegordner erforderlich}"
```

Der isolierte CI-Emulator muss bereits durch die ursprüngliche Tour eingerichtet und gerootet sein. Der Prüfer installiert nichts, fordert kein Root an, leert keine Appdaten und schreibt weder Spielstände noch IPC-Anfragen. Er verwendet echte sichtbare Touchziele, die Home-Taste und den normalen Launcheraufruf. Spielstandänderungen erfolgen ausschließlich durch die App als Folge dieser Eingaben. Die vorhandene künstliche Testperson muss eine neue, leere Einzelspielerrunde besitzen; andernfalls scheitert die Prüfung, ohne bestehende Runden zu löschen.

## Tatsächlich verlangte Grenzen

- Exakte Host-/Native-Commitbindung, saubere versionierte Arbeitsbytes, ausgeführter Prüfer aus dem Kandidatencheckout, ursprünglicher APK-/Signatur-/Versions-/ABI-Verifier und zusätzlich echter Hash des eingebetteten `assets/lumo_game.pck`.
- Hash der tatsächlich installierten `base.apk` vor und nach der Tour. Die vollständigen Quellen- und Binärbindungen müssen gleich bleiben.
- Tatsächliches Android SDK 35 / Release 15 oder SDK 37 / Release 17, explizite Emulatorseriennummer und tatsächlich gelesene Bildschirmdichte.
- Echter Spiele-Hub-Eintrag „Vier gewinnt“. Zwei sichtbare Kindzüge über die Spaltentasten, zwei bestätigte Botantworten, gespeicherte legale Zugfolge, positive Bestätigung derselben aktuellen Runde und unabhängige Rekonstruktion aller 42 Felder.
- Echte Android-Fensterinsets. Testfixtures werden vom Androidpfad abgewiesen. Alle tatsächlich benutzten nativen Ziele müssen sichtbar, freigegeben, unverdeckt und im exponierten Touchrechteck mindestens 48 dp groß sein.
- Read-only Sidecar `connect_four_layout_v1.json`, gebunden an Kinderhash, Rundennummer, Prozess, Mailboxtoken, Revision und abgeschlossenen Layoutzustand. Die Rohdatei und der öffentliche Spielzustand müssen vor und nach jeder akzeptierten Aufnahme unverändert sein. Ein Wechsel vor dem Tipp verhindert die Eingabe.
- Kamera und räumliche Zellgeometrie werden unabhängig auf das Screenshot-Dekorrechteck projiziert. Gemeldete Zentren und Ecken müssen innerhalb eines Pixels übereinstimmen. Die tatsächlichen cyanfarbenen und goldfarbenen Steinpixel werden an unabhängig berechneten Punkten geprüft; die gelieferten Polygone dienen nicht als alleinige Pixelreferenz.
- Pause/Fortsetzen, echte Home-Unterbrechung mit inaktiver Lease, unveränderte Runde im Hintergrund, monotone Pause-Epoche, Rückkehr derselben Activity und ausdrückliches Fortsetzen.
- Echter nativer Zurück-Knopf, beendeter isolierter Prozess, zweimal bestätigte sichtbare Flutter-Pausekarte, geschlossenes altes IPC-Verzeichnis, erneute Öffnung mit neuem Token und identischem gespeicherten Spiel. Danach erneute echte Flutter-Rückkehr und Erhalt der bestehenden Lernschlüssel.

Jeder fehlende Zustand bleibt ein Fehler. Es gibt keine Save-Injektion, keinen direkten Aufruf der Spielbefehle und kein Ausweichen auf eine frühere APK. Eine fehlgeschlagene Aufnahme behält ihre Originalbytes und Fehlernotiz. Ein bereits vorhandenes `result.json` wird nicht überschrieben.

## Lokale Belege und Grenzen

Der neue Test läuft mit:

```bash
python3 -W error::ResourceWarning -m unittest discover \
  -s tools/android_qa/tests -p test_connect_four_android_probe.py -v
```

`evidence/contract-final.log` dokumentiert **25/25 PASS, 0 Skip**. Die Fälle prüfen unter anderem illegale Zugfolgen, fremde Kinderidentität, falsche Bestätigungen, veränderte Rohzustände, zu kleine oder verdeckte Touchflächen, falsche Kamera-/Geometriedaten, fehlende Steinpixel und falsche oder doppelte PCK-ZIP-Mitglieder. Die Farbbilder und Binärarchive dieser Fälle sind ausdrücklich synthetische Testdaten.

Die kleine JSON-Fixture ist dagegen bytegleich zum tatsächlichen lokalen Godot-Sidecar aus `qa/connect-four-native-86445-803e/runtime-final-v7/connect_four_phone_playing.layout.json`, SHA256 `6bc6ec736379fae23fa641543704017a3514036c66de2d2c5e2badd436d867ff`. Herkunft und Grenzen stehen neben ihr in `origin.json`. Ihre Aufnahmequelle heißt `platform_fixture`. Das zugehörige Desktop-PNG hat 1079 × 2400 Pixel bei gemeldetem Fenster 1080 × 2400. Ein eigener negativer Test verhindert, dass dieser Unterschied unbemerkt als passendes Android-Dekorbild akzeptiert wird.

Der erste lokale Lauf hatte einen Fehler in der synthetischen Prüfung eines bereits gepaddeten Fensters: Die unverändert übernommene Headerhöhe war nach zusätzlicher Skalierung kleiner als 48 dp und wurde korrekt abgewiesen. `evidence/first-contract-run.log` bleibt erhalten. Nur die erfundene Testanordnung wurde zu einem ausreichend großen Ziel korrigiert; die 48-dp-Grenze blieb unverändert.

Nicht geprüft sind eine physische Fold7-Ausführung, FPS, Wärme, Eingabelatenz, der Wechsel zwischen zwei echten Kinderprofilen, abgeschlossene Turniere oder alle Botstrategien. Diese Grenzen bleiben auch nach einem künftigen Emulator-PASS bestehen. Die neue Szene braucht einen neuen tatsächlichen APK-Lauf; dieses Vorbereitungspaket ist keine Freigabe.
