# Lumo Lernen

Lern-App für Volksschulkinder (Flutter/Android) mit dem Lernfuchs Lumo, Lernmodulen,
Lesen, Spielen und dem 3D-Spiel Lumo Kart (Godot, eingebettet).

Einstieg für Entwickler und KIs: [`CODEX_START.md`](CODEX_START.md).
Regeln: [`CLAUDE.md`](CLAUDE.md). Datenschutz: [`PRIVACY.md`](PRIVACY.md).

Aktuelle Cards-/Vier-Gewinnt-Überarbeitung: [`docs/COMPUTER_CARDS_1922.md`](docs/COMPUTER_CARDS_1922.md).
Quell- und Sprachdateiprüfung: `node scripts/audit_source.mjs`.

## Android-Testversion (Familien-App)

Die auf dem Gerät installierte Familien-App (`dev.ullmann.lumo.lumo_lernen.coachpreview`) holt Updates nur über veröffentlichte GitHub-Prereleases mit dem Tag `coachpreview-build-N` und der Datei `Lumo-Lernen-Neu.apk`. Entwürfe (Drafts) werden vom Update-Button absichtlich ignoriert. Nicht vorher deinstallieren, sonst gehen Profile und Lernstand verloren.

Aktuell veröffentlicht: [coachpreview-build-2004](https://github.com/Ullmann27/lumo-lernen/releases/tag/coachpreview-build-2004) (0.12.92+2004). Direktlink: [Lumo-Lernen-Neu.apk](https://github.com/Ullmann27/lumo-lernen/releases/download/coachpreview-build-2004/Lumo-Lernen-Neu.apk), Prüfziffer: [Lumo-Lernen-Neu.apk.sha256](https://github.com/Ullmann27/lumo-lernen/releases/download/coachpreview-build-2004/Lumo-Lernen-Neu.apk.sha256).

Die nächste Version 0.13.0+2012 ist noch nicht veröffentlicht. Ablauf: [`docs/releases/LUMO_FAMILIEN_UPDATEKANAL.md`](docs/releases/LUMO_FAMILIEN_UPDATEKANAL.md). Wiederverwendbare Pipeline: `.github/workflows/lumo-family-draft-release.yml`.
