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

## Bestanden: vollständige Quellvalidierung 2029

Job `133033472392` des aktuellen Laufs ist erfolgreich: **2.887 Flutter PASS / 0 FAIL / 202 vorhandene SKIP**, Analyzer **0 Fehler / 4 Warnungen / 274 Hinweise**, **109 Host-Testmethoden**, tatsächlicher Godot-4.6.3-Import und zwölf native Programme mit **55.552 Prüfaussagen**. Projektvalidator **118 PASS / 0 WARN / 0 FAIL**. Die 247 Inventar-Hashes und 18 Schutzdateien wurden am tatsächlichen CI-Quellstand geprüft. Alle 55 Originalartefaktdateien und der vollständige verlustfrei komprimierte Joblog stehen in `evidence/ci-2029-validation/`. Der isolierte Avatar-ObjectDB-Hinweis bleibt unverändert dokumentiert. Der neue APK-Build läuft; Android und Download sind noch nicht bestanden.

## Bestanden: neue signierte APKs 2029

Buildjob `133037491223` ist erfolgreich. ARM64: **535.021.166 Byte**, SHA-256 `bc8fdd9c1f70d7d6e374b5424029e127531525deb4f2dec1e69de4ea8f6ee0c3`; x86_64: **538.184.171 Byte**, SHA-256 `01e0c126930b48cb8089f0671ed9238b5dc6ded903e288ad7c1fda452ed3cf0f`. Paket, Version, vorhandene Testsignatur, ABI, 16-KiB-Ausrichtung, Native-Pin und lokale Sprachassets sind an den tatsächlichen APKs geprüft. Der vollständige ARM64-Artefakt- und APK-Bytehash wurde zusätzlich lokal bestätigt. Originalnachweise: `evidence/ci-2029-build/`. Androidjob `133040408296` läuft; ein Android-PASS oder öffentlicher Download ist noch nicht bestätigt.

## Tatsächlicher Androidfehler; keine Veröffentlichung

Androidjob 133040408296 von Lauf43785937519 endete mit FAIL. Die erste sichtbare Steinbewegung nach Gesprächsrückkehr bleibt ungespeichert (moved0 statt1). Die aktuellen Original-XMLs zeigen beim Tap noch deaktivierte Coach-/Bautasten; das spätere Original-PNG zeigt sie aktiv. Der korrekte Tappunkt und das geschlossene Modal sind unabhängig geprüft. Eine zeitliche Frame-/Rebinding-Ursache wird noch untersucht; die bestehende Widgetprüfung reicht für diese echte Erstbedienung nicht aus.

Alle260 Originaldateien und der vollständige Joblog sind in `evidence/ci-2029-android-bridge-return-failure/` unverändert erhalten. Die nachfolgenden Größenwechsel-/Native-/Banane-/Muster-/Performanceabschnitte wurden nicht erreicht. Der Publisher wurde übersprungen; die gebaute2029-APK ist nicht freigegeben. Eine notwendige weitere Produktkorrektur bekommt einen neuen vollständigen Build und eine eigene Version.
