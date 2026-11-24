# Lumo Lernen

Lern-App für Volksschulkinder (Flutter/Android) mit dem Lernfuchs Lumo, Lernmodulen,
Lesen, Spielen und dem 3D-Spiel Lumo Kart (Godot, eingebettet).

Einstieg für Entwickler und KIs: [`CODEX_START.md`](CODEX_START.md).
Regeln: [`CLAUDE.md`](CLAUDE.md). Datenschutz: [`PRIVACY.md`](PRIVACY.md).

Aktuelle Cards-/Vier-Gewinnt-Überarbeitung: [`docs/COMPUTER_CARDS_1922.md`](docs/COMPUTER_CARDS_1922.md).
Quell- und Sprachdateiprüfung: `node scripts/audit_source.mjs`.

## Android-Testversion 0.14.6+2078: manueller Download

Die Original-APK 2078 ist gebaut und auf Bytes, Paket sowie Testsignatur geprüft. Android-Tour **23/23**, verbindliche native Starts **7/7** und SAF-Sicherung/Wiederherstellung **8/8** sind bestanden. **Die Veröffentlichung ist nach zwei fehlgeschlagenen Publisher-Versuchen noch blockiert. Ein öffentlicher APK-Downloadlink besteht noch nicht.**

Nach legitimer Veröffentlichung und vollständiger öffentlicher Byteprüfung wird hier die einzelne Datei `Lumo-Lernen-0.14.6-2078.apk` als manueller Chrome-Download verlinkt. Gebaute Identität: **701.640.419 Bytes**, Version **0.14.6**, Code **2078**, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`. Vor einer Aktualisierung nicht deinstallieren; Paket und Signatur müssen zur vorhandenen Familien-App passen.

[Aktueller Status und bekannte Grenzen](STATUS.md) · [Originalberichte und Publisherfehler](docs/evidence/meshy-rigs-20261124/final-45365478105/README.md). Die Testabnahme umfasst keine physische Fold7-Bildrate, Audioausgabe oder vollständige Zwei-Runden-Rennenabnahme. Nichtfatale Logmeldungen und ein kleiner optischer Restbefund sind ausdrücklich dokumentiert.

## Bestehender Update-Button der Familien-App

Der vorhandene Kanal berücksichtigt ausschließlich veröffentlichte Prereleases mit dem Tag `coachpreview-build-N` und dem exakten Asset `Lumo-Lernen-Neu.apk`. Drafts werden ignoriert. Das ist in `lib/core/app_update_service.dart`, Methode `familyPreviewFromReleases`, festgelegt.

Der 2078-Publisher verwendet einen separaten versions- und rungebundenen Tag sowie `Lumo-Lernen-0.14.6-2078.apk`. Eine erfolgreiche manuelle Veröffentlichung in diesem Schema macht 2078 deshalb noch nicht im vorhandenen Update-Button auffindbar. Der Kanal wird in diesem Arbeitsschritt nicht umgestellt. Ausführliche Beschreibung: [Familien-Updatekanal](docs/releases/LUMO_FAMILIEN_UPDATEKANAL.md).

## Historischer Dokumentationsstand

Die frühere README dokumentierte Build 2004 und einen damals vorgesehenen Build 2012. Diese Angaben werden hier nicht als heutiger Kanalstand übernommen. Ihr unveränderter Originalwortlaut bleibt im [historischen README-Beleg](docs/evidence/meshy-rigs-20261124/final-45365478105/history/README-before-2078.txt) erhalten.
