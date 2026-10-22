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
