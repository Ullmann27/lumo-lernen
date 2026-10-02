# Lumo – Einstieg und Fortsetzung

Stand: 2. Oktober 2026. Aktiver Anwendungscode: dieses Repository.

- [Aktueller Arbeitsstand und Prüfungen](docs/FORTSETZUNG_2026-10-02.md)
- [Neustartbericht aus dem vorherigen Chat](docs/NEUSTART_2026-10-02.md)
- 19 übergebene Projektdateien sind lokal mit Herkunft, Dateigröße, SHA-256 und Duplikatzuordnung vorbereitet. Ihre Veröffentlichung im öffentlichen Repository wartet auf ausdrückliche Nutzerfreigabe.
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

Der Nutzer hat für diese Fortsetzung **nur das Codex-Projekt** gewählt.
Render-Zugriff und Live-Deployment werden nicht durchgeführt. Eine erfolgreiche
lokale oder CI-Prüfung belegt keine reparierte Live-KI und ersetzt keinen
Gerätetest mit der Lehrerin.
