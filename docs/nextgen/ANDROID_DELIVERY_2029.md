# Vollständiger Nachfolgekandidat 0.13.17 (2029)

## Produktänderung und unveränderte Fehlergeschichte

Kandidat 2028 wurde nicht veröffentlicht. Der echte Androidlauf 43783036351 scheiterte nach korrekter Mikrofonfreigabe und ausdrücklich angezeigter Gerätebegrenzung beim ersten Stein-Tap nach Rückkehr aus dem eigenen Lab-Gespräch. Die UI besaß noch Rückrufe ohne gültige Aufgabenidentität, obwohl der Bus anschließend wieder gebunden war. Die vollständigen Originalartefakte bleiben als FAIL in `evidence/ci-2028-replay-bridge-checkpoint-failure/` erhalten.

`LearningLabScreen._publish()` merkt sich jetzt die vorherige Identität und baut nach einer tatsächlich neuen gültigen Bindung die Oberfläche lokal erneut auf. Die vorhandenen Scope-/Pausen-/Native-/Audio-Grenzen bleiben erhalten. Drei Regressionen reproduzieren den Fehler gegen die unveränderte fc5-Quelle; mit der Korrektur bestehen sie zusammen mit 24 vorhandenen Fällen. Die Testdateien und vollständigen RED/GREEN-Protokolle mit exakten Quellhashes stehen unter `evidence/lab_route_return_20261116/`. Das ist gezielte Widgetprüfung, kein Android-PASS.

## Exakte Quellen und Konfiguration

- Repository: `Ullmann27/lumo-lernen`, Integrationsbranch `integration/lumo-nextgen-learning-20261115`.
- Veröffentlichter integrierter Produktcheckpoint und Katalogquelle: `f3178bb418c84ad013cc18eaea89f48f7859119b`; Tree `f7fff6de8cd1a431b12fc7568fb49f2652a1ed14`.
- Native: `Ullmann27/lumo-godot`, `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.
- Version: `0.13.17+2029`; neues vorgesehenes Tag `lumo-nextgen-learning-0.13.17-2029`.
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Bestehende Testsignatur, SHA-256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Keine Play-Produktionssignierung.
- Geschützte Quellen: 18 bytegleich gegenüber `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`; frischer Katalog: 247 überprüfte Quellhashes.

Die Komponenten wurden getrennt veröffentlicht und anhand identischer Trees übernommen. Produzenten-, API- und Integrationszuordnung stehen in `evidence/2029-component-integration-20261116/components.json`. Der finale Aktivierungscommit und die tatsächliche Run-ID werden nach der Veröffentlichung dieses Konfigurationsstands separat protokolliert; sie werden nicht vorweg erfunden.

## Verpflichtender tatsächlicher Lieferlauf

`.github/workflows/lumo-nextgen-learning-apk.yml` muss den neuen Quellstand vollständig validieren und beide APKs neu bauen. Es folgen die gesamte originale Lerntour und danach die zusätzlichen nativen Banane-/Musterprüfungen. Die vorher fehlgeschlagene Steinbewegung, gespeicherter Fortschritt, Außen-/Innenmaße, echte native 8+5-Erklärung, echte Wiedergabemeldungen und Performancefenster bleiben verbindlich. Die bisherigen Leserkorrekturen ändern keine Produkt- oder Ergebnisbedingung.

Der normale Publisher verlangt weiterhin QA-Quelle gleich APK-Quelle. Er überprüft `DELIVERY.json` und `BUILD-PROVENANCE.json`, tatsächliche HTTP-404 für Release und Tag, erzeugt ein neues unveränderliches Prerelease und überprüft danach tatsächliches Tagziel, Quellcommit, Version, Assetname und Bytezahl. Anschließend wird die vollständige öffentliche APK anonym gelesen und per SHA-256 verglichen. `PUBLIC-DOWNLOAD-VERIFIED.json` darf erst nach vollständigem Erfolg entstehen. Die 13 gezielten Hosttests und der unabhängige Review sind in `evidence/source_public_download_20261116/` belegt; sie ersetzen diesen realen Abruf nicht.

## Stand dieses Vorlaufdokuments

Der neue Katalogexport besteht 1 Test. 27 gezielte Produktprüfungen und 13 Downloadprüferfälle bestehen; die gemeinsame lokale Versions-/Publikationsprüfung besteht 53 Testmethoden. Ein kompletter 2029-Quelllauf, 2029-APK, 2029-Android-PASS oder öffentlicher 2029-Download ist beim Schreiben noch nicht nachgewiesen. Keine alte APK und kein altes Ergebnis werden umetikettiert.

`fullModernizationComplete=false` bleibt zutreffend. Die Inventarzahlen sind keine vollständige Abnahme sämtlicher Varianten. Viele Einstiege nutzen die allgemeine native Aufgabenkarte; die Figur läuft über die bestehende separate Godot-Activity. Physische Fold7-/ARM64-Laufzeit, echte gesprochene Erkennung, hörbare Qualität, langfristig 60 FPS, Upgrade-/Prozesstod-Erhaltung und alle Varianten benötigen ihre jeweiligen tatsächlichen Nachweise. Kart- und native Dschungel-Folgearbeiten bleiben außerhalb dieser Runde.

## Tatsächliche Aktivierung

Der vollständige neue Lauf [43785937519](https://github.com/Ullmann27/lumo-lernen/actions/runs/43785937519) wurde am Quellcommit **684f54a6d11cfb5eccaec30f39fe34d6c17c82cc** tatsächlich gestartet. Native bleibt `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Die beobachtete Run-Quelle stimmt mit dem veröffentlichten Commit überein; der API-Commit besitzt exakt den lokal geprüften Tree. Originale Aktivierungsbindung: `evidence/2029-build-activation-20261116/activation.json`. Laufstatus bei diesem Eintrag: **in_progress**, noch kein Gesamt-/Android-/Download-PASS.
