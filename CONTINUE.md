# Hier mit Lumo weiterarbeiten

**Zuerst [HANDOFF.md](docs/audit/2026-10-29/HANDOFF.md) lesen.**

Dieser Zweig enthält den vollständigen Tutor-Kern, den veröffentlichten
2002-Quellstand und die geprüften Nachweise. Kein Neuaufbau nötig.

- Tutor-Kern: [PR #414](https://github.com/Ullmann27/lumo-lernen/pull/414), `5d6d7dcd`.
- Veröffentlichte Android-Haupt-App: [PR #415](https://github.com/Ullmann27/lumo-lernen/pull/415), `ff791642`, Version `0.12.90+2002`.
- 1.952 Flutter-Tests und 43 fokussierte Fälle auf beiden Quellen bestanden;
  Analyse ohne Fehler, mit sechs bestehenden Warnungen.
- Android-/Kart-Tour, echtes 2000→2002-Update und Veröffentlichung erfolgreich.
  Am 30.10. wurde die tatsächliche ARM64-APK anonym heruntergeladen und erneut
  einschließlich Prüfsumme, Signatur, Version und eingebetteter Quellen geprüft.

[Direkte APK für Chrome](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-0.12.90-2002/Lumo-Lernen-0.12.90-2002-ARM64.apk) ·
[Release-Prüfbericht](docs/audit/2026-10-30/RELEASE_2002_VERIFICATION.md).

2002 niemals überschreiben oder als neuen Build ausgeben. `main` und die
ursprünglichen Sol-/Opus-Arbeiten bleiben geschützt. Nächste Facharbeit auf
einem eigenen Branch: echte Tutor-Kontexte in die eigenständigen Module
integrieren, danach Lesen-/Silben-/Satzbau-Szenen mit eigenen Prozessprüfungen.

[Entwicklungsbericht mit Bildern](docs/audit/2026-10-29/MILESTONE_REPORT.md) ·
[offene Modulanschlüsse](docs/audit/2026-10-29/MODULE_INTEGRATION_AUDIT.md) ·
[Opus-Szenenvertrag](docs/LUMO_LEARNING_SCENE_CONTRACT_V1.md).
