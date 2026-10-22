# Lumo Lernen – Android-Build ohne GitHub Actions

Stand: 22.10.2026 · Review-only. Keine veröffentlichte APK und kein automatisch installierter Build durch dieses Dokument.

## Architekturentscheidung

- GitHub bleibt vorerst Quellarchiv und Review-System.
- Eine vorbereitete **Linux/x86_64-Buildumgebung** führt Flutter + Godot + Android SDK aus. Dieselbe Befehlsfolge eignet sich für einen eigens eingerichteten **Render-Builddienst**; dafür ist bislang **kein Lumo-APK-Dienst auf Render erstellt oder erfolgreich gebaut**.
- GitHub Actions kann für den Build vollständig ausfallen, ohne dass die tatsächlichen Buildskripte ersetzt werden müssen.
- Die vorhandene Lumo-AI-Proxy-Web-App auf Render ist **kein** Android-Builddienst. Sie bleibt unverändert.
- Continuum hat bereits einen separaten funktionierenden Render-Signierbuild. Signierschlüssel oder Zertifikate niemals zwischen Produkten austauschen.

## Verifizierte reale Projektanker

- Flutter-Projekt: `Ullmann27/lumo-lernen`, bestehender Build `scripts/build_unified_apk.sh`.
- Flutter 3.44.9, JDK 17, Android SDK 36 und Godot 4.6.3 sind die im vorhandenen GitHub-CI-Aufruf gepinnten Werkzeuge.
- Godot-Quellpin steht in `config/godot-source.json`; weder Branch-Spitzen noch ungesicherte Latest-Releases ersetzen diesen Commit.
- Das vorhandene Buildskript generiert den Android-Unterbau **außerhalb** des Repositorys und kopiert den Host zurück, integriert Godot und prüft die APK mit `scripts/verify_unified_apk.py`.
- Der aktuelle Aufruf `scripts/prepare_android.py --side-by-side` nutzt den eigenständigen Paketnamen mit Suffix `.coachpreview`, der **kein Update einer bestehenden Haupt-App** ist.
- Der Test-Build verwendet `tools/lumo-debug.keystore` mit Debug-Alias. Das ist **kein vertraulicher produktiver Google-Play-Upload-Key** und darf nicht stillschweigend als solcher verwendet werden.

## Neuer ausführbarer Einstieg

Auf einem vorbereiteten sauberen Linux-Buildrechner mit Git/Node/Python/Dart/Flutter/JDK/Android SDK:

```bash
bash scripts/portable-android.sh doctor
bash scripts/portable-android.sh tests
bash scripts/portable-android.sh preview-apk
```

`doctor` überprüft die erforderlichen Programme sowie Flutter 3.44.9 und den exakten gepinnten Godot-Konfigurationstyp. **Es kompiliert noch nichts.**

`tests` verifiziert einen sauberen Checkout und startet die vorhandenen Node- und Python-Tests, den Content-Audit, den Reparatur-Guard sowie `flutter pub get --enforce-lockfile`, `flutter analyze` und alle Flutter-Tests. Das sind echte Testläufe, keine simulierten Erfolgsmeldungen. Falls ein Werkzeug fehlt oder ein Test fehlschlägt, bleibt die Ausgabe gesperrt.

`preview-apk` ergänzt Godot 4.6.3 und ruft das bestehende `scripts/build_unified_apk.sh` auf, das die APK zusammenstellt und signaturprüft; danach erfolgt eine zusätzliche Identitätsprüfung für die erzeugte Kandidaten-APK. `dist/APK-SHA256.txt` dokumentiert deren Hash. Kein GitHub-Actions-Runner, kein Play-Upload und keine Geräteinstallation werden verwendet.

Die Shell-Syntax des neuen Wrappers und der ungültige Aufruf wurden lokal geprüft. **Die komplette Flutter-/Godot-/Android-Testsuite wurde für diesen neuen Branch nicht auf Render/Android ausgeführt.** Ein solcher Beleg ist zwingend vor Produktionsfreigabe.

## Stand nach Prüfung und Ausbau (22.10.2026, Claude)

Der Wrapper wurde weiterentwickelt, nicht ersetzt (`scripts/portable-android.sh`):

| Modus | Was er tut | Hier tatsächlich ausgeführt |
|---|---|---|
| `doctor` | listet **alle** Blocker auf einmal: Linux x86_64, Werkzeuge inkl. `rg`, Flutter 3.44.9, JDK ≥ 17 (Warnung, falls nicht 17 wie in CI), Godot-Pin, Android-SDK-Ordner, `sdkmanager`, Plattform `android-36`, akzeptierte SDK-Lizenz, NDK 28.2.13676358 (wird später installiert), build-tools mit `apksigner`+`aapt`, Test-Keystore, RAM/Platte, optional tesseract/Pillow und `xvfb-run` | ja – Exit 3, weil dieser Container **kein Android-SDK** hat (beide SDK-Blocker korrekt benannt) |
| `tests` | `flutter pub get` zuerst, dann Proxy-, Skript- und (wenn tesseract+Pillow vorhanden) Android-QA-Unit-Tests, Content-Audit, Reparatur-Guard, `flutter analyze`, alle Flutter-Tests; Logs je Schritt in `build/portable-evidence/` | ja, frischer Klon @ 7c3cb941: Exit 0 in 9:05 min, Flutter 1826 bestanden / 0 fehlgeschlagen (Details: `docs/LUMO_DEVELOPMENT_HANDOFF.md`) |
| `godot-tests` | holt exakt die Revision aus `config/godot-source.json` und führt deren eigenes `tools/validate_project.sh` aus | ja, über den Wrapper: 14/14 PASS am Pin 700baf49, Exit 0 |
| `preview-apk` | doctor → tests → godot-tests → vorhandenes `install_ndk_for_build.sh` → vorhandenes `build_unified_apk.sh` → `verify_unified_apk.py` → `PORTABLE-BUILD-EVIDENCE.json` und unveränderliche Kopien `dist/candidates/Lumo-Lernen-<version>+<code>-<commit12>-<abi>.apk` mit `SHA256SUMS.txt`; `device_test` steht ausdrücklich auf NOT EXECUTED | **nein** – `dl.google.com` (Android-SDK, Google-Maven) ist aus diesem Container gesperrt |

Gefundener und behobener Fehler: In PR #402 lief `dart scripts/audit_content.dart` vor `flutter pub get` und scheiterte auf jedem frischen Klon („Couldn't resolve the package 'lumo_lernen'“).

`scripts/install_godot_for_build.sh` prüft das Godot-4.6.3-Archiv jetzt gegen SHA-256 `d0bc2113…07f3` und verweigert jede andere Datei (positiv und negativ getestet).

`LUMO_GRADLE_CENTRAL_MIRROR=1` (Maven-Central-Spiegel gegen Drosselung) ist für den portablen Weg **opt-in**, weil das Skript die Init-Datei in `~/.gradle/init.d` legt und damit auf einem Arbeitsrechner auch andere Gradle-Projekte beträfe. Im Docker-Bauplan ist er gesetzt.

### Reproduzierbare Toolchain: `tools/portable-android/Dockerfile`

Ubuntu 24.04, OpenJDK 17, Flutter 3.44.9 (SHA-256 `a9120fa4…efcb` aus der offiziellen Release-Liste), Godot 4.6.3 (gleicher Pin wie oben), Android cmdline-tools 15859902 (SHA-256 `4e4c464f…f583` laut developer.android.com/studio), dann `platforms;android-36`, `build-tools;36.0.0`, `platform-tools`, `ndk;28.2.13676358`. Die SDK-Lizenz wird nur mit `--build-arg ACCEPT_ANDROID_SDK_LICENSES=yes` akzeptiert – das ist Heinz' Entscheidung. Das Image enthält keinen Lumo-Quellcode und keine Schlüssel.

**Status: NICHT GEBAUT.** Hier gab es keinen Docker-Daemon und keinen Zugang zu dl.google.com.

### Render-Eignungsprüfung (ohne Dienst anzulegen)

Kein Render-Dienst wurde angelegt, keine Kosten ausgelöst. `api.render.com` und `render.com` sind aus diesem Container nicht erreichbar; Kontingente (Workspace-Plan, verbrauchte Pipeline-Minuten) muss Heinz im Dashboard ablesen.

Bekannte Fakten (Websuche 22.10.2026, vor jeder Entscheidung auf render.com/pricing gegenprüfen):

- Instanzen: 1 CPU/2 GB 25 $/Monat, 2 CPU/4 GB 85 $, 4 CPU/8 GB 175 $, 4 CPU/16 GB 225 $ (Quelle: render.com/pricing, render.com/docs/compute-plans).
- Build-Pipeline: 500 Minuten/Monat inklusive, danach 5 $ je 1.000 Minuten; Performance-Pipeline 25 $ je 1.000 Minuten.
- Workflows (Flex): 0,20 $ je CPU-Stunde, 0,05 $ je GB-Stunde.
- One-off Jobs laufen auf dem Build-Artefakt eines bestehenden Dienstes und haben **keinen** Zugriff auf persistente Disks.
- Das Dateisystem ist flüchtig.
- Es ist kein KVM bekannt, also **kein Android-Emulator auf Render**.

Bewertung:

1. **Kompilieren: geeignet, mit Docker.** Static Sites oder die native Build-Umgebung sind ungeeignet, weil sie SDK, NDK und Flutter (mehrere GB) bei jedem Build neu laden müssten. Geeignet ist ein Docker-basierter Dienst aus `tools/portable-android/Dockerfile` mit mindestens 8 GB RAM (Gradle-Release-Build plus Godot-Export), der pro Commit `portable-android.sh preview-apk` als One-off Job oder Workflow-Task ausführt.
   - Grobe Kosten bei Flex-Abrechnung mit 4 CPU/16 GB und angenommenen 45 Minuten: 0,75 h × (4 × 0,20 + 16 × 0,05) ≈ **1,20 $ je Build**. Die Dauer ist auf Render nicht gemessen.
   - Ein dauerhaft laufender 4c-16g-Dienst kostet dagegen 225 $/Monat.
   - Offene Frage: Image-Größe (über 10 GB) gegen Render-Grenzen für Docker-Builds und Build-Timeouts.
2. **APK herausbringen: offen.** Wegen des flüchtigen Dateisystems muss der Job die APK hochladen. Zwei Möglichkeiten:
   - GitHub-Release mit einem fein begrenzten Token (`contents:write` nur für `lumo-lernen`). Das ist sicherheitsrelevant und braucht Freigabe.
   - Privater Objektspeicher.
   Eine öffentliche Static-Site-URL für Kinder-App-Testbuilds ist nicht empfehlenswert.
3. **Gerätetest: auf Render nicht möglich.** Ohne KVM gibt es keinen Emulator. Der bestehende Emulator-Test (`modernization_android_tour.py`, GitHub-Runner mit KVM) oder ein echtes Gerät bleiben Pflicht. Ein Compilerlauf auf Render ist kein bestandener Gerätetest.

Nächster freigabepflichtiger Schritt:
- Heinz prüft Plan und Kontingent im Render-Dashboard.
- Ein Probe-Build des Dockerfiles läuft lokal oder auf einem Docker-Host.
- Erst danach wird ein einzelner Render-Dienst angelegt.

## Render-Einführung (noch nicht aktivieren)

Ein eigener **Lumo-APK-Static-Site-Build** ist möglich, benötigt jedoch zuerst eine vollständige und reproduzierbare Linux-Toolchain einschließlich Flutter, Android SDK und Godot. Der Render-Befehl wäre **erst nach erfolgreichem lokalen Probelauf** `bash scripts/portable-android.sh preview-apk`. Publish-Pfad wäre ein separater Kandidatenordner mit unveränderlichem Artefaktnamen statt generisch `dist/Lumo-Lernen-Neu.apk`.

Render hat eigene Pipeline-Minuten- und Bandbreitenbudgets. Deshalb **kein** neuer kostenpflichtiger Dienst, Auto-Deploy oder großflächiger Buildstart ohne Kosten- und Ressourcenprüfung. Signier- und Deploy-Rechte werden getrennt von Quellcode-Permissions geprüft.

## Produktion / Play-Store-Sperren

1. Für direkte Updates: bestätigte gleiche Package-ID, gleiche Signatur, steigender `versionCode`, Datenmigration ohne Löschen und echter Samsung-Gerätetest.
2. Für Google Play: echtes **AAB-Release**, eigener geschützter Upload-Key, Play App Signing, korrekte Paketidentität, API-Ziel 36 oder neuer für neue reguläre Apps/Updates seit 31.08.2026, Store-Richtlinien sowie Datenschutz-/Kinderanforderungen vor Veröffentlichung prüfen. Dieses Review erzeugt ausdrücklich **nur eine Test-APK**.
3. In `lumo-godot` steht das separate Android-Preset nach bisheriger Prüfung noch auf `target_sdk=34`. Vor einem *separaten* Play-Release dieses Godot-Projekts ist eine eigenständige Anpassung nötig; die kombinierte Lumo-Prüfung ist davon verschieden.
4. Alte Builds, Quellpins, APK-Hashes und Tests als Rückfallpunkt erhalten. Keine automatische Migration der Lern-/Spielstände und keine Freigabe aufgrund eines grünen Exitcodes ohne APK-/Gerätedaten.

Referenzen:
- https://render.com/docs/static-sites
- https://support.google.com/googleplay/android-developer/answer/11926878
- https://developer.android.com/studio/publish/app-signing
