# Lumo – Einstieg und Fortsetzung

Stand: 4. Oktober 2026. Aktiver Anwendungscode: dieses Repository.

## Neuer Auftrag: Grafik nach den zwölf Originalentwürfen

Zuerst [Copilot-Anschlussauftrag und vollständigen Bildindex](docs/COPILOT_GRAFIK_2026-10-04.md) lesen. Die neuere Kart-Grafik liegt in `Ullmann27/lumo-godot`, PR #4, `codex/lumo-holographic-kart-2026-10-03`. Die aktuelle Flutter-/Android-Integration bleibt in diesem Zweig. Den zurückliegenden Flutter-Zweig `codex/lumo-holographic-2026-10-03` nicht ungeprüft als vollständigen aktuellen App-Stand übernehmen. Alle zwölf Originalbilder wurden wiedergefunden und angesehen; ihre PNG-Bytes sind mit dieser Übergabe nicht nach GitHub übertragen. Das neue Dokument unterscheidet Bildziel, vorhandenen Code und tatsächlich bestätigte Tests.

Die folgenden Notizen bewahren den bisherigen APK-/Integrationsnachweis. Die Dokumentationsübergabe hat weder App-Code noch APK-Bytes geändert.

- [Aktuelle APK-Übergabe, frische Android-Bildschirmabfragen und laufender Gesamttest](docs/ANDROID_LIVE_UI_2026-10-04.md).
  Eine echte APK 0.10.5 / Build 280 wurde im Chat mit identischen geprüften Bytes als **Testversion** und ZIP bereitgestellt. Die vollständige Android-Nutzungsprüfung ist noch nicht als bestanden bestätigt. Aktueller Folgelauf: `37181279924`, QA-Commit `b98fd4a4336b660b39006aa81a58d112c8ededf8`. Vor einer neuen Erfolgsaussage seinen Original-Proof lesen; kein bloßer Logauszug ersetzt ihn.
- [Gemeinsame Flutter-/Godot-Android-App und vorheriger Prüfstand](docs/UNIFIED_ANDROID_2026-10-03.md)
- Fortsetzungszweig: `codex/lumo-unified-android-2026-10-03`.
- Godot-Quelle wird in `config/godot-source.json` auf einen gespeicherten Commit festgelegt.
- Der gemeinsame Bau erfolgt mit `bash scripts/build_unified_apk.sh` (Flutter 3.44.9, Godot 4.6.3).

- [Aktueller Lernfuchs-/APK-Arbeitsstand](docs/LUMO_COACH_2026-10-02.md)
- [Vorheriger Arbeitsstand und Prüfungen](docs/FORTSETZUNG_2026-10-02.md)
- [Neustartbericht aus dem vorherigen Chat](docs/NEUSTART_2026-10-02.md)
- [Alle 19 übergebenen Projektdateien](archive/project-sources/2026-10-02/README.md) mit Herkunft, Dateigröße, SHA-256 und Duplikatzuordnung. Die öffentliche Archivierung wurde am 2. Oktober 2026 ausdrücklich freigegeben.
- Flutter-App: `lib/`, Regressionstests: `test/`.
- KI-Servercode: `server/lumo-ai-proxy/`.
- Android-Bau: `.github/workflows/release-apk.yml`; native Verbindung: `scripts/prepare_android.py`.
- Godot-Spielquellen: [Ullmann27/lumo-godot](https://github.com/Ullmann27/lumo-godot), jetzt im selben Android-Paket eingebettet.

Die archivierten HTML-/Flutter-Prototypen sind historische Quellen. Ihr alter
Democode, feste PINs, simulierte Erkennung und Implementierungsbehauptungen
sind kein Nachweis für den aktuellen Funktionsstand. Die produktiven Pfade
liegen in `lib/` und `server/`, nicht im Archiv.

PR #151 wurde am 2. Oktober bereits nach `main` übernommen. Diese Fortsetzung
baut auf `1e0eeaa7d0a78fcaf89977b47bf03826b56f34eb` auf und sammelt die danach
noch offenen Korrekturen im Zweig
`codex/lumo-school-readiness-followup-2026-10-02`.

Der Nutzer möchte alle Änderungen im Codex-Projekt und eine neue installierbare
APK. Nach Veröffentlichung von `school-test-270` hat er ausdrücklich zusätzlich
die KI-Aktivierung, überarbeitete Aufgaben und einen flüssig bewegten Lernfuchs
beauftragt. Dieser neuere Auftrag ersetzt die frühere Beschränkung „kein Render“.
Am 3. Oktober wurde der eindeutige bestehende Renderdienst mit seinem Workspace
requestbezogen lesend geprüft; dafür war keine Änderung der kontoweiten Auswahl
nötig. Ein neutraler Liveaufruf bestätigte weiter einen Provider-Limitfehler.
Der jeweils aktuelle KI-/APK-Nachweis steht im neuen Integrationsbericht.
Lokale/CI-Tests belegen keine funktionierende Live-KI und ersetzen keinen
Android-Gerätetest.
