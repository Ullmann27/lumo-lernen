# Lesende Android-Geräteaufnahme für LUMO

`fold_device_capture.py` sammelt einen nachvollziehbaren Rohdatensatz für eine
spätere Abnahme am Fold7. Es installiert oder startet keine App. Es verändert
keine Geräteeinstellung, setzt keine Statistik zurück und schreibt keine
LUMO-Daten. Alle ausgeführten Gerätebefehle stehen in einer geschlossenen Liste
lesender Aufrufe. Benötigt werden Python 3.10 oder neuer, Android Platform Tools
mit `adb` und eine bereits autorisierte USB- oder TCP-Verbindung. Die ADB-Shell
muss UID 2000 haben; das Programm fordert niemals Root an.

## Vorbereiten und ausführen

Die zu prüfende **monolithische ARM64-APK** muss bereits installiert sein. Ihre
Originaldatei und die zugehörige originale `BUILD-PROVENANCE.json` müssen lokal
vorliegen. Die erwarteten vollständigen Host-/Native-Commits und der APK-SHA256
müssen aus dem unabhängig geprüften Auslieferungsnachweis stammen. Es gibt
keinen fest eingebauten Commit oder Versionscode. Die vorhandene vollständige
Prüfung durch `scripts/verify_unified_apk.py` bleibt erforderlich; der Sammler
ersetzt weder deren Signaturprüfung noch die Auslieferungsgates.

Die folgenden Variablen müssen mit den **tatsächlichen** Werten gesetzt sein.
`LUMO_CAPTURE_OUT` bezeichnet einen neuen, noch nicht vorhandenen lokalen Ordner.
Die gewünschte Szene vor Beginn selbst öffnen und während der Aufnahme normal
bedienen. Das Programm betätigt keine Schaltflächen und fordert keine bestimmte
Szene als bereits erfolgreich geprüft an.

```bash
: "${LUMO_DEVICE_SERIAL:?Tatsächliche autorisierte ADB-Gerätekennung setzen}"
: "${LUMO_APK:?Pfad zur unabhängig geprüften ARM64-APK setzen}"
: "${LUMO_PROVENANCE:?Pfad zur originalen BUILD-PROVENANCE.json setzen}"
: "${LUMO_HOST_SHA:?Vollständigen erwarteten Host-Commit setzen}"
: "${LUMO_NATIVE_SHA:?Vollständigen erwarteten Native-Commit setzen}"
: "${LUMO_APK_SHA256:?Unabhängig geprüften erwarteten APK-SHA256 setzen}"
: "${LUMO_CAPTURE_OUT:?Neuen Ausgabeordner setzen}"

python3 -B tools/android_qa/fold_device_capture.py \
  --serial "$LUMO_DEVICE_SERIAL" \
  --package dev.ullmann.lumo.lumo_lernen.coachpreview \
  --apk "$LUMO_APK" --provenance "$LUMO_PROVENANCE" \
  --source "$LUMO_HOST_SHA" --native-source "$LUMO_NATIVE_SHA" \
  --expected-apk-sha256 "$LUMO_APK_SHA256" \
  --expected-api 37 --samples 3 --interval 5 --budget 180 \
  --out "$LUMO_CAPTURE_OUT"
```

Alle Geräteaufrufe enthalten `adb -s SERIAL`. `--adb` kann ein konkretes lokales
ADB-Programm benennen. Vor **und** nach der Sammlung werden Gerätekennung,
gewöhnliche Shell-UID, Paketpfad, SHA256 und Bytezahl der installierten
`base.apk` sowie der Build-Fingerprint gelesen. Andere APK-Bytes, mehrere APK-
Pfade/Splits, fehlende Leserechte oder eine abweichende Abschlussbindung führen
zu einem Fehler. Der lokale PCK-Inhalt und sein eingebetteter Native-Pin werden
gegen die Originalmetadaten geprüft. Das Zertifikatsfeld wird gegen die
bestehende LUMO-Familienrichtlinie geprüft; ohne `apksigner` entsteht hier keine
neue kryptografische Signaturprüfung. Aus UID 2000 folgt keine Root-Attestierung
des gesamten Geräts.

## Erfasste Daten und ihre Grenzen

| Bereich | Tatsächliche lesende Quelle | Aussagegrenze |
|---|---|---|
| Identität | ausgewählte `getprop`-Werte, `pm path`, `toybox sha256sum`/`stat` | Modell/Fingerprint sind beobachtete Geräteangaben; keine Hardwareattestierung. SDK 37 verlangt Release-Hauptversion 17. |
| Display/Fenster/Eingabe | `wm size`, `wm density`, `dumpsys display`, `window`, `input` | Rohzustand und System-Insetinformationen, keine automatisch bestandene Touch-Abnahme. |
| Prozesse | `pidof`, lesbares `/proc/PID/cmdline` und `/proc/PID/stat` vor/nach `meminfo` | CPU-Ticks und RSS-Seiten bleiben Originaleinheiten. PID-Wiederverwendung wird abgewiesen. Keine berechnete CPU-Auslastung. |
| Speicher | `dumpsys meminfo PID` für Host und `:lumo_game` | Native PSS/RSS werden nur aus dem bereits vorhandenen strengen Parser übernommen. Fehlendes `/proc` bleibt fehlend; eine einzelne passende Meminfo-Ausgabe wird als Einzelbeobachtung mit ihrer Lebensdauer-Prüfgrenze gekennzeichnet. |
| Temperatur/Last | `dumpsys thermalservice`, `battery`, `cpuinfo` | Thermische Schwere nur bei erkennbarer Formatversion, bereitem HAL und ohne aktivierten Override. Sensorwerte bleiben roh; Batterie-, Haut- und CPU-Werte werden nicht vermischt. |
| HWUI | `dumpsys gfxinfo PACKAGE framestats` | Ausschließlich HWUI-Rohdaten. Erkannte Zeilen sind **kein Godot-/SurfaceView-FPS-Nachweis**. |
| SurfaceFlinger | `--list`, optional `--latency EXAKTER_LAYERNAME` | Unveränderte, möglicherweise alte/unvollständige Puffer. Ein VSync-Intervall ist keine gemessene App-Bildrate. |

Der optionale `--surface-layer` muss den tatsächlich beobachteten vollständigen
LUMO-SurfaceView-Layernamen enthalten. Er wird als **ein** sicher quotiertes
Shellargument übergeben. Es gibt kein `--latency-clear`, kein Aktivieren oder
Zurücksetzen von Timestats und keine Ableitung von FPS aus diesen Daten.

`native_fps`, `gpu_frame_time` und `touch_latency` bleiben stets
`NOT_MEASURED` mit `null` statt einer erfundenen Zahl. Eine leere oder verweigerte
Quelle wird als fehlend/ungeeignet protokolliert. Der Host-Meminfo-Dump bleibt
roh. Messaufrufe sind sequenziell und erzeugen selbst Last; die gewünschte
Abtastperiode ist keine Frameperiode. Eine kurze Aufnahme beweist keine
Temperaturstabilität über eine lange Spielsitzung. Eine erfolgreiche
Datensammlung bestätigt weder 60 FPS noch Steuerungsqualität, mehrere Kinder,
Speicherstandmigration oder eine Releasefreigabe.

## Ergebnisse und Fehler

`capture.json` enthält Quellenbindung, Parameter, Beobachtungen und Grenzen.
`commands.jsonl` enthält für jeden Aufruf Argumente, UTC-/monotone Zeit,
Laufzeit, Exitcode, Status und Rohdateihashes. `raw/` bewahrt stdout/stderr
unverändert, auch nach Timeout oder Unterbrechung. Die Originalprovenienz wird
bytegleich kopiert; die APK wird nicht in die Ausgabe kopiert.
`MANIFEST.json` verzeichnet alle Ergebnisdateien außer sich selbst mit Größe
und SHA256. Rohdaten können Gerätekennungen und aktuelle Fenstertitel enthalten.

Exit 0 bedeutet ausschließlich `RECORDED_WITH_LIMITATIONS`; einzelne optionale
Messgrößen dürfen dabei fehlen. Identitäts- oder Abschlussfehler liefern Exit 2,
Strg-C Exit 130 und `INTERRUPTED_UNVERIFIED_END`. Vorhandene Ausgabeordner werden
nicht überschrieben. Maximal 120 Stichproben, 1–60 Sekunden gewünschter Abstand,
1–30 Sekunden pro Befehl und 10–1800 Sekunden gemeinsames ADB-Budget sind möglich.
Lokale APK-Prüfung erfolgt vor diesem ADB-Budget. Rohdateien werden nicht gekürzt;
Ausgaben über 8 MiB werden nicht automatisch geparst.

Gezielte lokale Tests, vollständig synthetisch und ohne ADB:

```bash
python3 -B -m unittest discover -s tools/android_qa/tests \
  -p test_fold_device_capture.py -v
```

## Geprüfte Primärquellen

Am 13. November 2026 gelesen; OEMs können Dumps verweigern oder anders formatieren.
Es wurde kein fremder Quellcode übernommen. Wiederverwendet werden ausschließlich
`parse_proc_stat` und `parse_meminfo` aus `runtime_resource_evidence.py`; dessen
Root-/Emulator-Orchestrierung wird nicht aufgerufen.

- [Android ADB: Geräteauswahl und Shellquotierung](https://developer.android.com/tools/adb).
- [Android dumpsys: Dienst-, Speicher- und HWUI-Diagnostik](https://developer.android.com/tools/dumpsys).
- [Android Rendering-Metriken und Grenzen für OpenGL-/Vulkan-Anwendungen](https://developer.android.com/topic/performance/issues/render).
- [AOSP ThermalManagerService](https://android.googlesource.com/platform/frameworks/base/+/main/services/core/java/com/android/server/power/ThermalManagerService.java), gelesener Blob `42dbb7974fe2012bf5fb947168417e47a8445773`: lesender Dump, Override/HAL/Schwere getrennt.
- [AOSP SurfaceFlinger](https://android.googlesource.com/platform/frameworks/native/+/refs/heads/main/services/surfaceflinger/SurfaceFlinger.cpp), gelesener Blob `8c6ae0e7aa83ccf5a0af5a4f814c2bd870fb90ba`: `--latency` liest, `--latency-clear` verändert Statistik; der Sammler nutzt letzteres nicht.
- [AOSP PackageManager `pm path`](https://android.googlesource.com/platform/frameworks/base/+/02dc0569ca213a26e5913f7478f2dc5d99c30221/services/core/java/com/android/server/pm/PackageManagerShellCommand.java) und [AOSP Toybox SHA256](https://android.googlesource.com/platform/external/toybox/+/40d21c59f76a9388b0ebb5c4c706732c2d034a67/toys/lsb/md5sum.c): lesende Paketpfad-/Dateihash-Erfassung.
