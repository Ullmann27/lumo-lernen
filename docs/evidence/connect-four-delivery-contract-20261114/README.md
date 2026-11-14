# C4-Auslieferungsprüfung für Studio 2020

Stand: 14. November 2026. Isolierte Vorbereitung auf der Host-Basis
`86445f53af5d573549fc8cf03405261611f3cb7e`; noch kein neuer Android-Lauf
und keine Freigabe eines 2020-Kandidaten.

## Umfang und tatsächlich ausgeführte Prüfungen

Das Quellenpaket enthält genau zwei neue Dateien:

- `scripts/verify_studio_connect_four_android.py`
- `scripts/tests/test_studio_connect_four_android_delivery.py`

Der abschließende lokale Lauf hat **29 synthetische Vertragsprüfungen, 0 Fehler,
0 übersprungene Tests** ergeben (unittest 2,339 Sekunden). Aufruf:

```bash
python3 -W error::ResourceWarning -B -m unittest discover \
  -s scripts/tests -p test_studio_connect_four_android_delivery.py -v
```

`evidence/final-contracts.log` ist das unveränderte Protokoll. Der erste
28er-Lauf und dessen damalige Hilfsquellenbindung bleiben separat erhalten.
Der abschließende Lauf verwendet die unabhängig geprüfte C4-Probe mit den
zwei zusätzlichen Zeitgrenzen nach dem Lesen
(`d9c72a9f4c98851ef37095441404947b178237fa4b560b3ae232759a6adf961e`).
Die unveränderten Hilfsmodule im isolierten `host/` dienen nur der Ausführung
dieser Tests und gehören nicht zu diesem Quellenmanifest.

Die Tests erzeugen ausschließlich temporäre Parserbeispiele. Sie erzeugen
keine akzeptierte Android-Freigabe. Die CLI wurde zusätzlich mit `--help`
geladen; dabei wurde kein Gerät, Renderer oder Dart-Prozess gestartet.

## Anschluss im echten Publisher

Der Publisher benötigt einen sauberen Host-Checkout am tatsächlichen neuen
Kandidaten-SHA und einen sauberen Native-Checkout am tatsächlichen Pin. Für den
sparse Native-Checkout müssen mindestens folgende Dateien vorhanden sein:

- `scripts/games/connect_four/connect_four_table.gd`
- `scenes/games/connect_four_table.tscn`
- `scripts/tests/connect_four_runtime_regression.gd`

Die Gitobjekte müssen den vollständigen relevanten Baum enthalten, damit die
vor und nach dem Zweiprozesslauf aufgezeichnete Dateiliste gegen denselben
Commit geprüft werden kann. Es wird kein fiktiver neuer Native-Pin eingesetzt.

Die vollständigen Originalartefakte müssen unverändert unter diesen Pfaden
bereitliegen:

| Originalartefakt | Lokaler Pfad |
| --- | --- |
| `lumo-studio-2020-android-tour` | `proofs/tour/` |
| `lumo-studio-2020-android-17-tour` | `proofs/android17/` |
| `lumo-candidate-pinned-native-gameplay` | `proofs/native-runtime/` |
| REST-Daten des aktuellen Runs | `proofs/c4-metadata/run.json`, `jobs.json`, `artifacts.json` |

`jobs.json` und `artifacts.json` müssen die vollständigen aktuellen Listen
enthalten. Die vier Pflichtjobs heißen `verify-and-build`,
`android-host-compile`, `Android API 35 live application tour` und
`Android API 37 live application tour`. Sie müssen am tatsächlichen Host-SHA
und aktuellen Run-Versuch erfolgreich beendet sein. Der Gesamt-Run darf
während seines Publishers noch laufen. Die Artefakterzeugungszeit muss in
das jeweilige erfolgreiche aktuelle Jobintervall fallen; ein älterer Versuch
genügt nicht. Der Kandidatenname ist `lumo-studio-2020-candidate`.

Die folgenden Variablen sind vom bestehenden Publisher aus seinen geprüften
Originalmetadaten zu befüllen, nicht aus Testfixtures: `SOURCE_SHA`,
`NATIVE_SHA`, `CANDIDATE_ARTIFACT_SHA256`, `ANDROID_TOUR_APK_SHA256`,
`GODOT_PCK_SHA256`, `BUILD_RUN_ID` und `CANDIDATE_ARTIFACT_ID`.
`ANDROID_TOUR_APK_SHA256` stammt aus `RELEASE-FACTS.androidTourApkSha256`,
der PCK-Hash aus der zugehörigen `BUILD-PROVENANCE`.

```bash
python3 scripts/verify_studio_connect_four_android.py \
  --source-sha "$SOURCE_SHA" \
  --native-sha "$NATIVE_SHA" \
  --artifact-digest "$CANDIDATE_ARTIFACT_SHA256" \
  --apk-sha256 "$ANDROID_TOUR_APK_SHA256" \
  --pck-sha256 "$GODOT_PCK_SHA256" \
  --build-run "$BUILD_RUN_ID" \
  --artifact-id "$CANDIDATE_ARTIFACT_ID" \
  --native-source c4-native-source \
  --metadata-dir proofs/c4-metadata \
  --api35 proofs/tour/connect-four \
  --api37 proofs/android17/connect-four \
  --main-tour35 proofs/tour/tour-result.json \
  --main-tour37 proofs/android17/tour-result.json \
  --runtime proofs/native-runtime/connect-four-runtime \
  --out proofs/connect-four-delivery.json
```

Die Original-Archivprüfung und der Download bleiben Aufgabe des aufrufenden
Publishers. Dieser Prüfer bindet die daraus bereitgestellten Originaldateien
an aktuelle REST-Metadaten und prüft ihre inneren Rohdaten-, Quellen- und
Bildbindungen erneut. Er lädt keine Archive herunter und installiert keine APK.

## Erzwungene Grenzen

Für beide Android-Ausgaben werden exakte APK-, PCK-, Host- und Native-Hashes,
Version `0.13.8+2020`, Familiensignatur, ursprüngliche ABI-Prüfung, installierte
APK vor/nach und die aktuellen ausgeführten Probequellen verlangt. Die
unveränderte Haupttour mit 21 erfolgreichen Schritten muss zur selben APK und
API gehören. API 35/Android 15 und API 37/Android 17 sind getrennt erforderlich.

Der C4-Teil prüft erneut acht originale Zustands-/Layout-/PNG-Klammern, zwei
tatsächliche Kindereingaben samt Botantworten, bestätigte IPC-Anfragen,
unabhängig projizierte belegte Spielfeldzellen, echte Touchpunkte und mindestens
48 dp freiliegende Ziele. Hinzu kommen Pause/Fortsetzen, Home mit inaktiver
Activity-Lease, drei aktive Lease-Beobachtungen unter der ursprünglichen
2500-ms-Regel, derselbe gespeicherte Verlauf beim Wiederöffnen, ein neuer
Mailbox-Token und die erhaltenen Lernschlüssel des beobachteten Kindes.

Beide Flutter-Rückwege müssen jeweils zwei zuletzt aufeinanderfolgende echte
positive Bilder innerhalb der unveränderten 30 Sekunden und höchstens zwölf
Beobachtungen enthalten. Die originale Caption-Normalisierung bleibt erhalten;
die Caption muss weiterhin in den tatsächlichen OCR-Zeilen mit gültigen
aktuellen Bildgrenzen vorkommen. Ein Ladebild kann das nicht ersetzen.

Zusätzlich wird der echte Zweiprozesslauf über den unveränderten
`run_connect_four_runtime.validate_results` erneut ausgewertet: beide
Prozess-Exitcodes, vorher/nachher identische Quellen, Original-Godotlog,
mindestens die vorhandenen 170 Prüfungen, reale Fallbewegung, PNGs/Frames,
legale Gewinnfolge und die vorhandene Belohnungsprüfung. Die reine
Visualfixture erfüllt diesen Vertrag nicht.

Die Prüfung der Disc-Pixel betrifft belegte Zellen. Das leere Startbrett wird
als leerer Regel-/Geometriezustand geprüft, nicht als pixelweise Vollabnahme
aller leeren Löcher. Es entstehen keine Aussagen über zwei Kinderwechsel,
sämtliche Gegnerstrategien, alte native Spielstände oder physische
Fold7-Bildrate, Temperatur und Eingabelatenz. Ein positiver lokaler Parserlauf
ersetzt keinen der noch ausstehenden tatsächlichen 2020-Läufe.
