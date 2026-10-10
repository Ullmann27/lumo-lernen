# Lumo Lernen: Nach Perplexity-Zugriffssperre auf GitHub gesicherte Kart-Integration

Stand 10.10.2026. **Separater Integrationskandidat, kein Produktions- oder Play-Store-Release.**

## Ausgangssituation
Perplexity Computer wurde für den Nutzer mit "Not eligible" bzw. "Wir konnten Ihr Konto derzeit nicht verifizieren" unterbrochen. In den GitHub-Repositories sind die bis dahin gepushten Entwicklungsstände weiterhin nachweislich vorhanden. Nicht gepushte Perplexity-Dateien oder in dessen Computer-Dateisystem gespeicherte Artefakte können aus GitHub nicht wiederhergestellt werden.

## Exakt geprüfte Quellen
- Flutter-Mutterzweig: `computer/lumo-aaa-integration-2026-10-10`, Ausgangscommit `c747abc2c89eedd856f30091a8d2ce445011322d`, PR https://github.com/Ullmann27/lumo-lernen/pull/250
- Dessen bestehende Basis enthält die Cards-/Vier-Gewinnt-Arbeit aus Build1922: https://github.com/Ullmann27/lumo-lernen/pull/249
- Godot: `computer/lumo-kart-aaa-2026-10-10`, commit **`f672e02cf1101f3366b6d506fa7d7b77bb535b42`**, PR https://github.com/Ullmann27/lumo-godot/pull/47
- Godot Stage2: https://github.com/Ullmann27/lumo-godot/actions/runs/38055934253 — **success** für den angegebenen Commit.
- Godot Fold-Menü: https://github.com/Ullmann27/lumo-godot/actions/runs/38055937553 — **success** für denselben Commit.
- Bereits funktionierende Flutter-Änderungsprüfung auf Muttercommit: https://github.com/Ullmann27/lumo-lernen/actions/runs/38054662623 — **success**, ausdrücklich kein Android/APK-Freigabebeweis.
- Das ältere Probe-APK unter https://github.com/Ullmann27/lumo-lernen/actions/runs/38051726194 gehört zum alten Build1922 und enthält **nicht** den Godot-M2-Fix; nicht als neue Integrations-APK bezeichnen.

## Änderungen dieses Integrationszweigs
1. `config/godot-source.json` pinnt ausschließlich den im Godot-Stage2- und Fold-Workflow grünen Commit `f672e02...`; PCK-Exporter verifiziert weiterhin den Git-SHA. Die Godot-Quellen liegen unverändert im Godot-PR #47, nicht als zweite App.
2. `pubspec.yaml` erhöht die ausschließlich parallele Testversion von `0.12.15+1922` auf `0.12.16+1923`. Die bestehende Side-by-side-Package-ID `dev.ullmann.lumo.lumo_lernen.coachpreview` bleibt erhalten, womit eine bestehende produktive Installation nicht überschrieben wird.
3. Der bestehende und bisher erfolgreiche Android-Workflow wird nur auf diesem **temporären Arbeitszweig** durch einen gezielten Push-Trigger angestoßen; Tests, Godot 4.6.3, PCK-Provenienz, Signaturprüfung und Ausgabe von `dist/Lumo-Lernen-Neu.apk` bleiben unverändert.
4. Keine Änderung an Lumo-Kinderprofilen, Lernständen, Domänen-IDs, Geschenken, Store-Abos, Produktionspaket oder Debug-/Play-Signatur.

## Gesicherte echte Laufzeit-Bilder
- Vorher/Nachher 320×568: https://github.com/Ullmann27/lumo-godot/blob/computer/lumo-kart-aaa-2026-10-10/docs/qa/visual/kart-aaa/2026-10-10/m2-layout/compare/kart-saved-320x568-before-after.png
- Vorher/Nachher 1280×720: https://github.com/Ullmann27/lumo-godot/blob/computer/lumo-kart-aaa-2026-10-10/docs/qa/visual/kart-aaa/2026-10-10/m2-layout/compare/driver-1280x720-before-after.png
- Vorher/Nachher kompakt: https://github.com/Ullmann27/lumo-godot/blob/computer/lumo-kart-aaa-2026-10-10/docs/qa/visual/kart-aaa/2026-10-10/m1/vergleich-640x360.png

## Testfreigabe (noch offen bis CI-Ergebnis)
- [x] Godot-Stage2 erfolgreich bei exakt gepinnter Godot-Revision.
- [x] Godot-Fold-Menü erfolgreich bei exakt gepinnter Godot-Revision.
- [ ] Vollständige Flutter-Regressionen für Flutter HEAD mit neuem Pin.
- [ ] Echte Android-APK auf Flutter HEAD gebaut und SHA, Package, Signatur, Version, PCK validiert.
- [ ] APK-Installation auf physischem Fold, gespeichertes Rennen, Touch/Orientierung, Profile/Rewards, Audio geprüft.
- [ ] Original-Referenztreue des 3D-Fuchses und der Strecken visuell vom Nutzer abgenommen.
- [ ] Separates Google-Play-AAB-/Familien-/Datenschutz-Gate.

**Keine Behauptung eines fertigen, installierten, grafikfreigegebenen oder veröffentlichten Produkts.** Bei einem CI-Fehler zunächst konkretes Log und exakte Revision untersuchen; niemals fehlgeschlagene Prüfungen als Erfolg ausgeben. Keine Android-Artefakte zusammenführen, bevor Quelle und Resultat identisch sind.
