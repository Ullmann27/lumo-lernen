# Lumo – Einstieg und Fortsetzung

Stand: 2. Oktober 2026. Aktiver Anwendungscode: dieses Repository.

- [Aktueller Lernfuchs-/APK-Arbeitsstand](docs/LUMO_COACH_2026-10-02.md)
- [Vorheriger Arbeitsstand und Prüfungen](docs/FORTSETZUNG_2026-10-02.md)
- [Neustartbericht aus dem vorherigen Chat](docs/NEUSTART_2026-10-02.md)
- [Alle 19 übergebenen Projektdateien](archive/project-sources/2026-10-02/README.md) mit Herkunft, Dateigröße, SHA-256 und Duplikatzuordnung. Die öffentliche Archivierung wurde am 2. Oktober 2026 ausdrücklich freigegeben.
- Flutter-App: `lib/`, Regressionstests: `test/`.
- KI-Servercode: `server/lumo-ai-proxy/`.
- Android-Bau: `.github/workflows/release-apk.yml`; native Verbindung: `scripts/prepare_android.py`.
- Separate Godot-Spiele: [Ullmann27/lumo-godot](https://github.com/Ullmann27/lumo-godot).

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
Der Render-Connector verlangt jedoch noch die ausdrückliche Wahl des Workspaces
`My Workspace`; deshalb wurden keine Kontoeinstellungen oder Deployments geändert.
Ein neutraler Liveaufruf bestätigte einen Provider-Limitfehler. Lokale/CI-Tests
belegen keine funktionierende Live-KI und ersetzen keinen Android-Gerätetest.
