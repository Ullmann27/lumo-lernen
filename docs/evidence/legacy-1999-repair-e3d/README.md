# Getrennte Reparatur des historischen 1999-Update-Gates

**Status: lokal geprüfter Reparaturpatch, nicht integriert und nicht als Android-Erfolg ausgegeben.**

Der saubere Ausgangsstand dieses separaten, detached Worktrees ist Hostcommit `e3d161cb2f79b732ac2dbafc2764b151247f018b` (Tree `2e05089253dcfa51f2541b94f88565e4c33b4609`). Der laufende Host- und Native-Stand sowie die Studio-CI wurden nicht verändert. Es wurde kein Commit gepusht und kein Workflow gestartet oder wiederholt.

## Tatsächlicher Fehler

Run `43461548520`, Job `132009474907` lädt weiterhin die festgeschriebenen historischen 1997-/1999-APKs. Der aktuelle APK-Prüfer erwartet jedoch die Version des aktuellen Checkouts und bricht deshalb mit `Wrong Android version: 0.12.87+1999, expected 0.13.7+2019` ab. Ein bloßes Versionsoverride würde anschließend noch den falschen aktuellen Godot-Pin verwenden.

Die originalen Root-Belege sind unverändert als `legacy-1999-workflow-e3d-review.json` und `legacy-1999-workflow-e3d-failure.log` beigelegt. Ihr Hash wurde vor der Übernahme geprüft. Der historische Verifier aus dem tatsächlichen Kandidatencommit `c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf` enthält außerdem noch nicht den heutigen fest eingebauten Familien-Zertifikatsvergleich. Einfach alten Prüfcode auszuführen wäre daher kein sauberer Ersatz.

## Begrenzte Reparatur

Der Patch ändert genau zwei bestehende Dateien und ergänzt einen Vertragstest:

- `.github/workflows/lumo-1999-update-gate.yml`: separater sparse Checkout des unveränderlichen 1999-Commits; beide bisherigen ABI-Prüfungen erhalten denselben ausdrücklich gebundenen Erwartungsstand. Die festen Artefaktruns, Signaturprüfung der Baseline, aktuelle Android-Probe, Offline- und Datenerhaltungsgates bleiben bestehen.
- `scripts/verify_unified_apk.py`: ein optionales, ausdrücklich gepaartes Repository-/Commitargument liest die vier erwarteten Metadatendateien unmittelbar aus Gitobjekten. Der aktuelle Prüfcode bleibt zuständig. Ein beweglicher Branchname, ein verkürzter oder unbekannter Commit und widersprechende Versionsumgebungsvariablen werden abgelehnt. Lokale Änderungen an den Metadatendateien beeinflussen die gebundenen Erwartungen nicht.
- `scripts/tests/test_historical_apk_expectations.py`: synthetische positive und negative Vertragsfälle einschließlich des wirklichen CLI-Einstiegs, beider ABIs und unveränderter Schutzbedingungen.

Die vier historischen Metadaten sind `pubspec.yaml`, `config/godot-source.json`, `config/lumo-offline-voice.json` und `assets/audio/voice/lumo_free/catalog.json`. Ihre tatsächlich aus dem c60-Commit gelesenen Git-Blobs und SHA256 stehen in `real-historical-expectations.json`. Sie ergeben `0.12.87+1999` und Godot `4d0fd40fdf188be6ca86057596c7b51f41701fa3`.

Die Paketkennung, feste Familien-Signatur, Mindest-/Ziel-SDK, exakten ABIs, benötigten nativen Bibliotheken, Sprachmodell-/Clip-/Lizenzhashes, Ressourcenverpackung, 16-KiB-ELF-Ausrichtung, native Quellrevision, PCK-Hash und private Activity-/Releaseprüfung bleiben erhalten. Der AST-Vergleich der alten Schutzbedingungen ist in `preservation-review.json` dokumentiert. Signaturprüfer, Java-Zertifikatsprüfer, stabiler Keystore, Android-Proben und Datenerhaltungsbibliothek sind bytegleich zu e3d. Der normale aktuelle Build verwendet weiterhin seine aktuellen Metadaten.

## Tatsächlich ausgeführte lokale Prüfungen

| Prüfung | Ergebnis |
| --- | --- |
| Neuer Vertrag vor dem Fix | 15 Testmethoden; 1 Failure und 25 Fehler einschließlich Subtests; Exit 1 |
| Neuer Vertrag nach dem Fix | 15/15 PASS, 0 SKIP; Exit 0 |
| Bestehende ABI-/Sprachasset-Verträge | 9/9 PASS, 0 SKIP; Exit 0 |
| actionlint 1.7.12 | Exit 0, leeres Fehlerprotokoll |
| `bash -n` | Alle sechs Run-/Emulatorskriptblöcke PASS |
| `git diff --check` | Exit 0 |
| Patch gegen die exakten e3d-Ausgangsdateien | `git apply --check` PASS |
| Rückwärtsprüfung gegen den isolierten Arbeitsstand | `git apply --check --reverse` PASS |

Die neuen ZIP-Fixtures sind ausdrücklich keine signierten Android-APKs. Nur die externen Signatur- und aapt-Leser werden für diese Tests ersetzt; Git liest echte lokale Commitobjekte, und die Paket-, PCK-, Voice-, ABI- und Ressourcenprüfungen laufen tatsächlich. Die tatsächliche 1997→1999-Emulatortour wird durch diesen lokalen Nachweis nicht ersetzt.

Das grüne Protokoll enthält vier `ResourceWarning`-Meldungen des bereits vorbestehenden nicht explizit geschlossenen Dateihandles bei der abschließenden APK-Digestberechnung. Dieser unveränderte Altcode wurde nicht nebenbei umgebaut. Die Git-Fehlermeldung zur Nullrevision gehört zu einem bewusst negativen Test und ist erwartete Ablehnung.

## Unabhängiger Quellreview

Agent B hat die drei geänderten Code-/Testdateien an exakt den im Bericht gespeicherten SHA256 nochmals ausschließlich lesend geprüft. Es wurde kein zusätzlicher konkreter Blocker festgestellt. B bestätigte insbesondere die unveränderlichen Gitbytes, die erhaltenen aktuellen Signatur-/APK-Gates und das unveränderte Standardverhalten. Es wurden dabei keine Tests wiederholt und keine Dateien verändert; siehe [separate Reviewnotiz](independent-source-review.json).

## Übergabe

[Anwendbarer Patch](legacy-1999-source-bound-verifier.patch) · [Maschinenlesbarer Bericht](REPORT.json) · [Rotes Protokoll](contracts-red.log) · [Grünes Protokoll](contracts-green.log) · [Bestehende Verträge](existing-apk-contracts.log) · [Quell- und Schutzvergleich](preservation-review.json)

Patch-SHA256: `47bc8f0dd249a56ec521a671e30f6927ea5532a35b8b034eeae54b0dcb7a744c`.

Die Änderung ist für eine separate Prüfung und Integration vorbereitet. Erst ein danach tatsächlich ausgeführter erfolgreicher historischer Android-Lauf kann den alten Gate erneut freigeben. Die laufende Studio-2019-Auslieferung erhält aus diesem Patch keine vorweggenommene Freigabe und keine neuen Quellbytes.
