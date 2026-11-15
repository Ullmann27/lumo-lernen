# Android-Auslieferung 0.13.15 (2027)

Stand: 15.11.2026, 22:18 UTC. **Noch keine öffentliche Auslieferung und keine bestandene Android-Lerntour behauptet.** Der vollständige Replay läuft unter [43768151118](https://github.com/Ullmann27/lumo-lernen/actions/runs/43768151118).

## Unveränderliche Produktidentität

| Bestandteil | Identität |
|---|---|
| Flutter-Appquelle | `72a7914059d10152604b877cfeaf8bd1d2155810` |
| Godot-Quelle | `ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Version | `0.13.15`, versionCode `2027` |
| Bestehende Testsignatur SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| ARM64-APK | 535014830 Bytes; SHA-256 `20722fad9ca114c0182b928d132fdc674aa7a9b76f92eea20f3135a605e63be5` |
| x86_64-APK für Emulator | 538177759 Bytes; SHA-256 `9f3166a4e071f3f0e4217b1aa7e2e100bbf9ee2cfeb41bdbc47d33827e768fc9` |
| Eingebetteter PCK | 278589004 Bytes; SHA-256 `aeec3bee15604e814dfe02b643e55977497f18fa08283b1de1be0d3dda4aa65a` |

Beide APKs wurden im [Quelllauf 43759362796](https://github.com/Ullmann27/lumo-lernen/actions/runs/43759362796) gebaut. Der Validierungsjob `132950549079` und der wiederholte Buildjob `132956370454` sind erfolgreich. Der Lauf insgesamt ist wegen seines ursprünglichen Android-Prüflesers fehlgeschlagen. Erfolgreiche Teilbefunde werden nicht in einen erfolgreichen Gesamtlauf umgedeutet. Das ist die bestehende Testsignatur, keine Play-Produktionssignatur.

## Nachgewiesene Validierung

2.870 Flutter-Tests bestanden, 202 übersprungen, kein fehlgeschlagener Flutter-Test im angegebenen Quelllauf. Die Analyse meldet 0 Fehler, 4 Warnungen und 275 Hinweise. 55 Host-Vertragsprüfungen und elf native Prüfläufe bestanden. Letztere melden zusammen 55.509 Prüfaussagen; diese Zahl beschreibt keine entsprechend große Menge unabhängiger Tests. Die 18 geschützten Dateien sind gegenüber der vereinbarten Basis bytegleich.

Die Originale bis zur Installationspfadkorrektur stehen in [der unveränderten Belegsammlung](evidence/original-build-and-qa-20261115/README.md). Danach hat Lauf `43766331070` die exakte x86-APK erfolgreich installiert und über die echte UI ein ausschließlich fiktives Profil angelegt. Er scheiterte bei der Navigation zum tiefer liegenden Mikrofon-Schalter. Die aufgezeichneten Original-XMLs und ihre Hashes liegen in `tools/android_qa/tests/fixtures/nextgen_settings_43766331070/`.

## Aktueller Prüf- und Veröffentlichungsweg

Der QA-Zweig `qa/lumo-nextgen-reference-android-20261115` steht auf `78f836728e3d4a5e067a774fa346933b067ea246`. Sein Tree ist `e5e58c54b3505bcc89072f9a2f87cdc15999e249`. Dieser Stand verwendet die vorhandene x86-APK unverändert; er baut keine neue App. Die Korrekturen betreffen ausschließlich Prüfleser, beobachtete Navigation und Testbelege. Die anschließenden produktiven Lernrouten wurden gegen die APK-Quelle abgeglichen.

Der laufende Job `132977803483` führt zuerst alle ursprünglichen Lern-, Erhaltungs- und Performancegates aus und anschließend die zusätzlichen nativen Banane-/Musterszenen. Eine erfolgreiche Installation allein ist kein bestandener Lerndurchlauf.

`tools/nextgen/prepare_learning_replay_release.py` und `.github/workflows/lumo-nextgen-learning-replay-publish.yml` bereiten die spätere Veröffentlichung derselben ARM64-Bytes vor. Die Aktivierungskonfiguration ist noch nicht angelegt. Sie darf erst den tatsächlich erfolgreichen QA-Commit, Run und das größen-/digestgeprüfte Artefakt enthalten. Der Veröffentlicher prüft beide vollständigen Lernergebnisse und die ursprüngliche Produktidentität erneut; ein vorhandenes Release wird nicht überschrieben.

## Verbindliche Grenzen

`fullModernizationComplete` bleibt `false`. Die [Abdeckungsliste](COVERAGE.md) unterscheidet 19 Moduleinstiege, sechs Labmodi und sieben angeleitete Lektionen von elf spezialisierten nativen Szenentypen plus generischer Aufgabenkarte. Es besteht keine individuelle räumliche Fachsimulation für jede der 236 Curriculumfamilien.

Das Prüfgerät ist ein Android-35-x86_64-Emulator mit Software-Grafik. Physisches ARM64-/Fold7-Verhalten, echte gesprochene Erkennung/Korrektur, hörbare Sprachqualität, Phonemzeiten, Langzeitstabilität und 60 FPS sind damit noch nicht nachgewiesen. `main` wurde durch diese Runde nicht gemergt. Parallele Kart-/Dschungel-Folgearbeiten gehören nicht zu dieser Auslieferung.
