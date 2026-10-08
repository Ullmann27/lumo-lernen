# Lumo Kart – Android-Integration, 8. Oktober 2026

## Ausgangspunkt

Die neue Etappe setzt unmittelbar auf dem letzten gespeicherten Opus-Stand
`be9524fd133041ff5ec4f158561685d6b1a8323b` auf. Dieser enthält die App-Stimme,
das Bewegungssystem und den Godot-Pin für Kart-Intro, Startaufstellung,
Startampel, Winken, Musik und Lautstärken. Historische HTML-Prototypen und
`main` ersetzen diesen Stand nicht.

Arbeitsbranch: `codex/lumo-kart-stage2-android-2026-10-08`.

## Android-Paket und Update

| Eigenschaft | Neuer Kandidat |
|---|---|
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Version | `0.11.1+1800` |
| Signaturzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Engine | Godot `4.6.3` |
| Architekturen | `arm64-v8a`, `x86_64` |
| Mindest-/Ziel-Android | API 24 / API 36 |

Der vorhandene stabile Schlüssel wird unverändert genutzt. Sein öffentlicher
Zertifikat-Hash wurde lokal erneut ermittelt. Paket und Zertifikat stimmen mit
den dokumentierten Kandidaten 1602/1701 überein; Build 1800 ist höher.
Eine tatsächliche Installation und der Profilerhalt des neuen Kandidaten sind
vor dem CI-Nutzungstest noch **NOT EXECUTED**.

## Buildroute

Die vorbereitete Pipeline `.github/workflows/lumo-kart-stage2.yml` läuft bei
Push auf den genannten Arbeitsbranch oder durch `workflow_dispatch`.
Sie nutzt die im Repository erklärte Version aus `pubspec.yaml`. Auch die
allgemeine Pipeline `release-apk.yml` übernimmt nun diese Version: deren
veralteter Override `0.10.6`/Run-Nummer war mit dem aktuellen Buildschutz
nicht mehr vereinbar.

1. Flutter 3.44.9 / Java 17: Lockfile, Analyse und vollständige Fluttertests.
2. Python-Build-/Androidtests, Backendtests, Inhaltsaudit und Integrationsschutz.
3. Godot 4.6.3: exakt gepinnter Commit, echte Engine-Renderings sowie
   Fold-, Menü-, Physik-, Flotten-, Hafen-, Fahrzeuggeometrie- und
   Fahrzeugdetail-Regressionen.
   Der Probe-Runner verlangt sauberes Prozessende und PASS; Engine-/Scriptfehler
   oder Zeitüberschreitungen bleiben auch bei vorhandenem PASS fehlgeschlagen.
   Flotte und Hafen werden anschließend aus demselben Pin in der tatsächlichen
   Engine aufgenommen; 36 Kartansichten, 12 Modulansichten, vier Rennaufnahmen,
   neun statische Kart-GLBs und die Hafenansichten werden als Belege gespeichert.
4. Gemeinsame Release-APK durch `scripts/build_unified_apk.sh` aus sauberem
   Git-Quellstand. Prüfung von Paket, Version, Signatur, PCK-Commit/-Hash,
   Architekturen, Ressourcen und 16-KiB-ELF-Ausrichtung.
5. Android-Emulator: Update von der geprüften APK 1602; Profilerhalt,
   Offline-Neustart, Bauwelt, Puzzle, Rhythmus, Schatzsuche und Kart unter
   API 35; Kart zusätzlich unter API 36. API und Kandidatenquelle werden
   gegen die angeforderte Matrix/den Quellcommit geprüft.

Das Buildartefakt heißt `lumo-visual-apk-<run_id>` und enthält
`Lumo-Lernen-Neu.apk`, Prüfsumme, APK-Prüfbericht und Bauprovenienz.
Rohbelege der Android-Szenarien heißen
`lumo-kart-stage2-android-<spiel>-api<api>-<run_id>`.
Diese Pipeline veröffentlicht keine Releases und führt keinen Merge aus.

## Lokal erneut geprüft

| Prüfung | Ergebnis |
|---|---|
| `python3 -m unittest discover -s scripts/tests` | 9 bestanden |
| `node --test server/lumo-ai-proxy/test/*.test.js` | 22 bestanden |
| `python3 -m unittest discover -s tools/android_qa/tests` | 187 bestanden |
| Stabiles Signaturzertifikat | Hash bestätigt |
| YAML und `git diff --check` | bestanden |
| Probe-Runner: sauberer PASS, Scriptfehler trotz PASS, fehlender Marker, Exitfehler, Timeout | 5 Verhaltensprüfungen bestanden |
| Flutteranalyse und Fluttertests | NOT EXECUTED – Flutter hier nicht installiert |
| APK-Bau/Installation und neue Android-Szenarien | NOT EXECUTED – CI noch nicht gestartet |
| Echtes Galaxy Z Fold, 60 FPS, Wärmeentwicklung | NOT EXECUTED – kein physisches Gerät |

Die genannten lokalen Testzahlen ersetzen keine Nutzung der neuen APK.
Der finale Godot-Pin und die Kandidatenprovenienz werden erst nach Abschluss
der Godot-Etappe festgeschrieben; ein APK-Hash wird erst nach dem tatsächlichen
Bau genannt.
