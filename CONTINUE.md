# LUMO Next Generation – Android-Erstbedienung 2029 noch fehlerhaft

Stand: 16. November 2026. **Kandidat 2029 wird nicht veröffentlicht.** Der vollständige Lauf [43785937519](https://github.com/Ullmann27/lumo-lernen/actions/runs/43785937519) auf APK-/QA-Quelle **684f54a6d11cfb5eccaec30f39fe34d6c17c82cc** hat Quellvalidierung und beide APK-Builds bestanden, aber Androidjob **133040408296** ist beim ersten Stein-Tap nach der eigenen Gesprächsrückkehr erneut fehlgeschlagen. Veröffentlichung wurde übersprungen.

Die echte gespeicherte Aufgabe bleibt `bridge-8-5`, Phase example, hint/support3, moved0 statt1. Der Tap liegt im tatsächlich beobachteten ersten Stein (204,731 innerhalb [138,665]–[270,797]); kein Zwischen-Scroll und kein sichtbares Gesprächs-Overlay. Die XML-Dateien vor dem Tap zeigen gewöhnliche Coach-/Bautasten deaktiviert, das abschließende Originalbild zeigt sie bereits aktiv. Damit ist eine dauerhaft unveränderte Sperre nicht belegt. Die zeitliche Folge von Rückkehr, deferred publish und angefordertem Frame wird gezielt untersucht. Eine konkrete Ursache oder neue Reparatur wird hier noch nicht als bewiesen bezeichnet.

**Alle 260 Originaldateien, beide Originalvideos und der vollständige Joblog sind erhalten** unter `docs/nextgen/evidence/ci-2029-android-bridge-return-failure/`. Die früheren Fehler bleiben ebenfalls unverändert. Die tatsächlich bestandenen 2.887 Fluttertests,109 Hosttests und native Prüfungen gelten weiterhin als Quellprüfung; sie decken diesen realen Erst-Tap-Ablauf noch nicht ausreichend ab.

Die signierten neuen APKs sind gebaut und überprüft: Version **0.13.17+2029**, Native **678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef**. ARM64 **535.021.166 Byte**, SHA-256 `bc8fdd9c1f70d7d6e374b5424029e127531525deb4f2dec1e69de4ea8f6ee0c3`. Die vollständigen ARM64-Bytes wurden zusätzlich lokal gegen Artefakt und Originalmetadaten geprüft. Das ersetzt den fehlenden Android-PASS nicht.

Nächster Schritt: strengere Reproduktion des beobachteten Frame-/Erstbedienungsablaufs, minimaler Produktfix nur bei belegter Ursache, anschließender neuer vollständiger Build mit eigener Version. Keine zweite automatische Eingabe, kein geänderter Checkpoint und keine abgeschwächte Abnahmebedingung. `main` bleibt unberührt; `fullModernizationComplete=false` bleibt zutreffend.

## Integrierte Produktkorrektur für den nächsten Kandidaten

Die tatsächliche Übergangslücke ist jetzt durch zwei neue RED-Fälle auf unveränderter 684-Quelle reproduziert: Das Modell erschien bedienbar, obwohl seine Aufgabenidentität fehlte. Der geprüfte Fix aktiviert alle Lab-Modelle erst mit gültiger eigener Bindung und fordert den Frame für die bisherige Rückkehrveröffentlichung ausdrücklich an. Die finale Regression verwendet das echte Systemanimationsflag, stellt die Frage und prüft jeden angeforderten Rückkehrframe. Genau ein Tap im ersten aktiv angebotenen Frame muss moved1 speichern. **27/27 gezielte Prüfungen bestehen**, Analyse ohne Befunde. Der separate Teamstand `a4e73ccf5b7ea0686d941d9160957230a94b93a6` ist veröffentlicht und übernommen; exakte Komponentenbindung unter `docs/nextgen/evidence/2030-product-integration-20261116/`. Die Aktualisierung des Inventars und ein neuer vollständiger Build **0.13.18+2030** folgen. Noch kein neuer Android-PASS.

## Archiv: tatsächlicher Quell-/Buildfortschritt 2029 vor Androidabschluss

# LUMO Next Generation – vollständiger Kandidat 2029 vorbereitet

Stand: 16. November 2026. **0.13.17+2029** enthält die minimale Produktkorrektur für den tatsächlich blockierten Lab-Rückweg. APK 2028 wird nicht veröffentlicht. Ihr zweiter Replay [43783036351](https://github.com/Ullmann27/lumo-lernen/actions/runs/43783036351) bleibt FAIL; alle 274 Originaldateien und der vollständige Log sind in `docs/nextgen/evidence/ci-2028-replay-bridge-checkpoint-failure/` erhalten.

Die Lab-Aufgabe baut ihre Bedienelemente jetzt erst mit der neu gebundenen aktuellen Aufgabenidentität auf. Drei identische Regressionen scheitern gegen die unveränderte Quelle fc5 und bestehen mit dem Fix: eigene Gesprächsrückkehr, Gesprächsrückkehr nach inactive → resumed sowie sichtbare Wiederaufnahme ohne Größenwechsel. **27/27 gezielte Flutterprüfungen** bestehen einschließlich bestehender Bus-/Native-/Runtimegrenzen. Alte Rückrufe bleiben abgewiesen; Aufgabe, Hilfestand und Belohnungen bleiben erhalten. Die Tests liefen im dokumentierten Produzenten-Worktree; sie werden nicht als kompletter Root- oder Androidlauf bezeichnet.

Der veröffentlichte Produktcheckpoint ist **f3178bb418c84ad013cc18eaea89f48f7859119b**, Native bleibt **678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef**. Der tatsächliche Dart-Katalog wurde an f317 erneut exportiert (1 PASS). Die aktualisierte Abdeckungsliste enthält **247 überprüfte Quellhashes**; **18 geschützte Dateien** sind bytegleich zum geschützten Ausgangsstand. Snapshot und genaue lokale Prüfprovenienz stehen in `docs/nextgen/evidence/coverage_refresh_20261116_2029/verification.json`. Danach wurden nur Versions-/Liefermetadaten und Dokumentation geändert.

Der normale Veröffentlichungspfad prüft jetzt Release und Tag auf tatsächliche Abwesenheit sowie nach Erstellung sämtliche Bytes der öffentlichen APK ohne Anmeldung. **13/13 gezielte Prüferfälle** und ein unabhängiger Quellreview bestehen; zusammen mit der bestehenden Versionspolicy bestehen **53/53 Hostprüfungen**. Die genaue Komponenten-/Commit-/Treekarte steht unter `docs/nextgen/evidence/2029-component-integration-20261116/`.

Die Aktivierung dieser Konfiguration startet die vollständige Quellvalidierung, neue signierte ARM64-/x86-Builds, die unveränderten vollständigen Androidtouren und erst danach die Veröffentlichung. **Es gibt zum Zeitpunkt dieses Vorlaufdokuments keine verifizierte 2029-APK, keinen Android-PASS und keinen neuen öffentlichen Download.** Aktueller Lieferpfad: `docs/nextgen/ANDROID_DELIVERY_2029.md`. `fullModernizationComplete=false` bleibt bestehen; allgemeine Aufgabenkarte, separate optionale Godot-Activity und tatsächliche Geräte-/Variantenlücken bleiben ausgewiesen. `main` und frühere Releases bleiben unverändert.

## Bestanden: neue signierte APKs 2029

Buildjob `133037491223` ist erfolgreich. ARM64: **535.021.166 Byte**, SHA-256 `bc8fdd9c1f70d7d6e374b5424029e127531525deb4f2dec1e69de4ea8f6ee0c3`; x86_64: **538.184.171 Byte**, SHA-256 `01e0c126930b48cb8089f0671ed9238b5dc6ded903e288ad7c1fda452ed3cf0f`. Paket, Version, vorhandene Testsignatur, ABI, 16-KiB-Ausrichtung, Native-Pin und lokale Sprachassets sind an den tatsächlichen APKs geprüft. Der vollständige ARM64-Artefakt- und APK-Bytehash wurde zusätzlich lokal bestätigt. Originalnachweise: `docs/nextgen/evidence/ci-2029-build/`. Androidjob `133040408296` läuft; ein Android-PASS oder öffentlicher Download ist noch nicht bestätigt.

## Bestanden: vollständige Quellvalidierung 2029

Job `133033472392` des aktuellen Laufs ist erfolgreich: **2.887 Flutter PASS / 0 FAIL / 202 vorhandene SKIP**, Analyzer **0 Fehler / 4 Warnungen / 274 Hinweise**, **109 Host-Testmethoden**, tatsächlicher Godot-4.6.3-Import und zwölf native Programme mit **55.552 Prüfaussagen**. Projektvalidator **118 PASS / 0 WARN / 0 FAIL**. Die 247 Inventar-Hashes und 18 Schutzdateien wurden am tatsächlichen CI-Quellstand geprüft. Alle 55 Originalartefaktdateien und der vollständige verlustfrei komprimierte Joblog stehen in `docs/nextgen/evidence/ci-2029-validation/`. Der isolierte Avatar-ObjectDB-Hinweis bleibt unverändert dokumentiert. Der neue APK-Build läuft; Android und Download sind noch nicht bestanden.

## Tatsächliche Aktivierung

Der vollständige neue Lauf [43785937519](https://github.com/Ullmann27/lumo-lernen/actions/runs/43785937519) wurde am Quellcommit **684f54a6d11cfb5eccaec30f39fe34d6c17c82cc** tatsächlich gestartet. Native bleibt `678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`. Die beobachtete Run-Quelle stimmt mit dem veröffentlichten Commit überein; der API-Commit besitzt exakt den lokal geprüften Tree. Originale Aktivierungsbindung: `docs/nextgen/evidence/2029-build-activation-20261116/activation.json`. Laufstatus bei diesem Eintrag: **in_progress**, noch kein Gesamt-/Android-/Download-PASS.

## Aktuelle Wiederaufnahme 2029

1. Exakten Branch/HEAD und uncommittete Dateien prüfen; kein Reset, Clean oder Force-Push. Produktfix und Downloadprüfer sind bereits am veröffentlichten f317-Produktcheckpoint integriert; nicht erneut übernehmen.
2. Die vorbereitete Konfiguration `0.13.17+2029`, Versioncode 2029 und Native-Pin-Policy gehören zusammen. Katalogexport und alle Quellhashes sind aktualisiert. Nach diesem Snapshot ist kein weiteres lib/assets/android-Delta zulässig, ohne Inventar und Prüfbindung entsprechend zu erneuern.
3. Den tatsächlichen Lauf von `.github/workflows/lumo-nextgen-learning-apk.yml` anhand seines exakten Aktivierungs-HEAD verfolgen. Validate, neue ARM64-/x86-Builds und beide vollständigen Androidtouren müssen erfolgreich sein. Fehler und Originalartefakte unverändert sichern; keine Gatebedingung abschwächen.
4. Der normale 2029-Publisher verlangt QA-Commit gleich APK-Quellcommit. Die historischen 2028-Replay-/Publikationszweige dürfen diese neue Quelle nicht freigeben.
5. Nur ein erfolgreicher vollständiger anonymer Byte-/Hashabruf und passende echte Release-/Tag-/Assetmetadaten bestätigen den direkten APK-Link. Danach tatsächliche Androidbilder, Messungen, Quellen und verbleibende Grenzen im Abschlussnachweis ergänzen.

## Archiv: Kandidat 2028 und unveränderte Originalnachweise

# LUMO Next Generation – gebauter Kandidat 2028, Androidwiederholung ausstehend

Stand: 16. November 2026. APK-Quelle **fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242**, Native **678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef**, Version **0.13.16+2028**. Der Integrationszweig ist `integration/lumo-nextgen-learning-20261115`. Paket `dev.ullmann.lumo.lumo_lernen.coachpreview` und bestehende Testsignatur bleiben erhalten; `main` wurde nicht zusammengeführt.

## Tatsächlicher vollständiger Quell- und Buildlauf

[Lauf 43774460935](https://github.com/Ullmann27/lumo-lernen/actions/runs/43774460935) hat die Quellvalidierung und beide Builds bestanden. Die originale Androidtour ist fehlgeschlagen; deshalb wurde nichts veröffentlicht.

- Flutter: **2.884 PASS, 0 FAIL, 202 vorhandene SKIP**. Analyzer: **0 Fehler, 4 Warnungen, 274 Hinweise**.
- Host: **73 Python-Testmethoden PASS**; enthaltene JVM-Prüfaussagen sind keine zusätzlichen Androidtests.
- Tatsächlicher Godot-4.6.3-Import erfolgreich; zwölf native Programme mit zusammen **55.552 Prüfaussagen**. Projektvalidator **118 PASS / 0 WARN / 0 FAIL**. Der ObjectDB-Hinweis am Ende des isolierten Avatar-Vertragstests ist im Original erhalten; er wird weder als belegter App-Leak noch als leakfreier Lauf umgedeutet.
- Alle **245 Quellhashes** des aktuellen Inventars und **18 geschützte Schreib-/Journaldateien** wurden geprüft.
- ARM64: **535.020.882 Byte**, SHA-256 `3bc5255101fe28ad62881a8aab478fd02650dc6e92a6abbe0d0d137367f06238`.
- x86_64: **538.184.315 Byte**, SHA-256 `6b3a2f62ea80144b5af397e6353d1a52f2210109531a1edd49a1b22ec2bc4fa9`.
- Gemeinsamer nativer Pack: SHA-256 `69899113f134c04550a5073cd9657315e0cb0bb418f9e06fa76a482041757bc0`.
- Bestehendes Testzertifikat: SHA-256 `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`. Die ARM64-Datei wurde zusätzlich vollständig heruntergeladen und unabhängig erneut verifiziert. Das ist kein physischer ARM64-Laufzeitnachweis.

Originale und vollständige Logs: `docs/nextgen/evidence/ci-2028-validation/`, `ci-2028-build/`, `ci-2028-permission-transition-failure/`. Große Original-ZIP-Dateien sind gegebenenfalls verlustfrei geteilt; Teilreihenfolge und Originalhash sind dokumentiert.

## Tatsächlicher Androidstand und nächste Abnahme

Die reale x86-Tour erreichte die korrigierte aufgabenbezogene Lab-Antwort auf „Warum zuerst zwei?“ und anschließend Stopp. Bei der Mikrofonfreigabe wurde ein unsichtbarer Android-Permission-Container mit Höhe null zu früh als fertige Abfrage geprüft. Der folgende Original-Screenshot zeigt die richtige Audioaufnahme-Abfrage für LUMO mit einer sichtbaren Zulassen-Taste. **Der Lauf bleibt FAIL**, die vollständige Tour und die zusätzlichen nativen Banane-/Musterszenen sind damit nicht bestanden.

Der erste unveränderliche Replay [43781148281](https://github.com/Ullmann27/lumo-lernen/actions/runs/43781148281) auf QA-Commit `6f8532940693cbba7059bed4037f9aa6d924bac4` bestand seine 123 Checkerprüfungen und die ursprüngliche Quell-/Artefaktbindung. Die reale Tour erreichte erneut die passende Lab-Erklärung und anschließend den fertigen Berechtigungsdialog. Vor dem Zulassen-Tap scheiterte der Testleser an einem Dictionary-Zugriff auf einen echten XML-Element-Knoten. **Auch dieser Lauf bleibt FAIL.** Alle 177 Originaldateien und der vollständige Joblog stehen unter `docs/nextgen/evidence/ci-2028-replay-xml-node-failure/`. Die minimale XML-Korrektur besteht einschließlich Original-Regression 64 Prüfungen.

Die vollständige Tour wird nach Übernahme der geprüften Reader-Korrekturen erneut gegen exakt dieselbe APK ausgeführt. Nach einer tatsächlich erteilten Mikrofonfreigabe darf der Test einen neuen ausdrücklich protokollierten Druck auf Sprechen ausführen, wenn die frisch sichtbare eigene Aufgabenansicht die tatsächliche deutsche Bereitschaft zeigt; Bereitschaft selbst ist kein bestandenes Mikrofonergebnis. Das Produkt startet nach der Unterbrechung bewusst nicht automatisch eine Aufnahme. APK-Quelle, QA-Commit, Buildlauf und Prüflauf bleiben getrennt. Ein Replay-PASS und öffentlicher Download sind noch nicht nachgewiesen.

## Abdeckung und Grenzen

`docs/nextgen/COVERAGE.json` und `COVERAGE.md` erfassen den Produkt-Snapshot `daf6ca5e9f7df7b32a32ef987d067035ddb5328c`; bis zur APK-Quelle fc5 gibt es keine weitere Änderung an `lib` oder `tools/auto_install`. Erfasst sind 61 Inventareinträge, 236 Curriculum-Familien, 19 aktive Fachmoduleinstiege in 18 Oberflächen, sechs Lab-Modi und sieben geführte Lektionen. Diese Zahlen sind keine Zahl einzeln vollständig modernisierter oder auf Android durchgespielter Varianten.

`fullModernizationComplete` bleibt **false**. Elf native Spezialmodelle ergänzen eine gemeinsame Aufgabenkarte. Zahlreiche Fachmodule und Lab-Einstiege nutzen diese Karte. Die Figur läuft über die bestehende separate Godot-Activity, nicht eingebettet in jede Flutter-Aufgabe. Physische Fold7-/ARM64-Nutzung, echte gesprochene Erkennung, hörbare Qualität, umfassende Variantenabdeckung, Update-/Prozesstod-Erhaltung und 60 FPS sind ohne ihre jeweiligen tatsächlichen Nachweise offen. Kart- und native Dschungel-Folgearbeiten sind ausgeschlossen.

Vertrag: `docs/nextgen/INTEGRATION_V1.md`. Aktueller Lieferpfad: `docs/nextgen/ANDROID_DELIVERY_2028.md`.

## Verbindliche Wiederaufnahme

1. Branch, HEAD und Arbeitsdateien sichern; kein Reset, Clean oder Force-Push. Der letzte tatsächliche Remote-Checkpoint ist über die Branchreferenz zu prüfen. APK-Quelle bleibt fc5; Dokumentations-/QA-Commits ändern diese bereits gebauten Bytes nicht.
2. Die minimalen XML- und Postgrant-Leserkorrekturen nach gezielter Prüfung integrieren; anschließend ausschließlich `config/nextgen-2028-replay.json.replayAttempt` erhöhen und `.github/workflows/lumo-nextgen-2028-replay.yml` auf `qa/lumo-nextgen-2028-android-20261116` neu aktivieren. Der Replay verwendet das bestehende x86-Artefakt **14185954865** aus Lauf **43774460935**. `config/nextgen-release.json` hierfür nicht verändern und die alte 2027-Wiederholung nicht starten.
3. Den neuen tatsächlichen Lauf verfolgen. Originalfehler, echte Screenshots/XML, installierte Byteidentität, aktuelle Aufgaben-/Profilbindung und komplette Ton-/Figur-/Effektfenster erhalten. Nach jedem Fehler Ursache prüfen; keine fehlenden Szenen als PASS setzen. Eine weitere Produktänderung würde neue APKs und eine entsprechend neue Version erfordern.
4. Erst nach vollständigem erfolgreichen Replay `config/nextgen-2028-replay-publish.json` mit dessen exaktem QA-Commit, Lauf und Artefakt-ID/Größe/Hash auf `delivery/lumo-nextgen-2028-replay-20261116` aktivieren. Der separate Publisher verifiziert erneut beide Lerntouren, ursprüngliche Buildjobs, originale fehlgeschlagene Androidbelege und die unveränderte ARM64-Datei. Danach den echten öffentlichen Download und seine vollständige anonyme SHA-Prüfung bestätigen.
5. `STATUS.md`, diese Übergabe und `ANDROID_DELIVERY_2028.md` mit den tatsächlichen Ergebnissen ergänzen. `fullModernizationComplete=false` und sämtliche konkreten Grenzen bleiben bestehen, solange ihre eigene Abnahme fehlt. Frühere Releases und `main` bleiben unverändert.

## Archiv: ursprünglicher 2027-Vorlauf

# LUMO Next Generation – integrierter Android-Kandidat 2027

Stand: 15. November 2026. Aktive Arbeit auf `integration/lumo-nextgen-learning-20261115`; main bleibt geschützt. Die Kandidatenversion ist **0.13.15+2027**, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, bestehende Testsignatur. Der native Quellstand ist **ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb** aus `Ullmann27/lumo-godot`. Die folgenden archivierten 2023-/2020-Stände sind keine Angaben über diesen Kandidaten.

Der tatsächliche Umfang und seine Grenzen stehen in `docs/nextgen/COVERAGE.json` und `COVERAGE.md`; der gemeinsame Vertrag in `docs/nextgen/INTEGRATION_V1.md`. Die Matrix kennzeichnet die Modernisierung weiterhin ausdrücklich als unvollständig. Eine native Erklärung wird über die bestehende separate Godot-Activity geöffnet, nicht als dauerhaft eingebettete 3D-Figur in jeder Flutter-Aufgabe. 18 geschützte Schreib-/Journalquellen bleiben unverändert gegenüber `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`. Kart- und native Dschungel-Folgearbeiten wurden nicht übernommen.

Der erste vollständige CI-Lauf [43750469368](https://github.com/Ullmann27/lumo-lernen/actions/runs/43750469368) auf `aea9f63e5ea7a85a2d0a67d3b0e8988b0b0eb1fa` bestand Analyse, Toolchain- und Quellschutzprüfung, scheiterte jedoch mit 2.809 bestandenen, 27 fehlgeschlagenen und 202 vorhandenen übersprungenen Flutter-Tests. Er erzeugte keine APK. Die gezielten Korrekturen, Originalprotokolle und zusätzlichen Audio-Owner-Regressionen sind in `docs/nextgen/evidence/ci_retry_20261115/` dokumentiert. Es wurden keine neuen Skips eingeführt.

Der zweite Lauf [43753810844](https://github.com/Ullmann27/lumo-lernen/actions/runs/43753810844) auf `e3c0735cedd48adf625c23391d2818580712e7a9` bestand die vollständigen Flutter- und Host-Vertragsprüfungen. Seine native Sammelstufe blieb ohne Abschluss. Die lokale Reproduktion am ursprünglichen Pin fand zwei veraltete Testzugriffe mit Laufzeitfehler vor `quit()` sowie reale Englisch-/Zehnerfeld-Layoutfehler. Alle elf nativen Programme bestehen nach der Korrektur mit 55.509 Checks; Originale und 26 echte Linux-Rendereraufnahmen liegen im Godot-Repository unter `docs/nextgen/evidence/native-ci-05/`. Die neue CI trennt Import und Tests, begrenzt jeden Aufruf und ersetzt veraltete eigene Kandidatenläufe.

Der dritte vollständige Versuch benutzt `.github/workflows/lumo-nextgen-learning-apk.yml` und wird durch `buildAttempt: 3` ausgelöst. Ein endgültiger APK-/Android-/Downloadnachweis ist beim Schreiben dieses Vorlaufstatus noch offen. Der Publisher darf erst nach vollständiger Validierung, Build und tatsächlicher Androidtour einen neuen unveränderlichen Release anlegen. Weder frühere APKs noch gezielte Widget-/Desktopprüfungen gelten dafür als Ersatz.

## Wiederaufnahme dieses Kandidaten

1. Branch/HEAD/Arbeitsbaum prüfen und sichern, keine Reset-/Clean-/Force-Befehle. Der veröffentlichte Zwischenstand mit CI-Reparaturen und Mini-/Story-Audiobesitz ist `eebee303bc34b17ec5fdbad68067906877c9d18a`.
2. Den tatsächlichen nächsten Run der Nextgen-Workflowdatei anhand seines `head_sha` verfolgen. Fehlschläge mit unveränderten Originalprotokollen sichern und an ihrer Ursache korrigieren; Qualitätsgates nicht umgehen.
3. Nach grünem Build die ARM64-Test-APK, eingebetteten nativen Commit, Paket/Version, bestehende Testsignatur, Bytezahl und SHA-256 prüfen. Der Androidjob installiert die x86_64-Ausgabe desselben Buildstands und prüft reale Szenen/Audiostatus sowie emulierte Außen-/Innenmaße. Das ist kein physischer Fold7- oder Mikrofonbeleg.
4. Erst nach grünem Androidjob den tatsächlichen neuen direkten öffentlichen `.apk`-Download prüfen, Screenshots/Video und Messwerte aus Originalartefakten auswerten und Abschlussnachweis aktualisieren. Frühere Releases unverändert lassen.

## Archiv: frühere Entwicklungsstände

# LUMO 2023 – gemeinsamer Host-Checkpoint, 15. November 2026

Dieser isolierte Integrationszweig vereinigt die tatsächlichen Eltern
`3584bc54152a1aa48193eb4934ecd10bdbccf4c4` (Blender-APK 2022) und
`c9813fde66d36f8b44916a0d7c4898c30e6227e3` (aktuelle App-Reparaturen).
Die neue Kandidatenversion ist **0.13.11+2023**.

Enthalten bleiben die Memory-/Quiz-/Englisch-Integration und die native
Spielewelt aus 2022. Hinzu kommen die aktuellen Schreibflächen-,
Szenensichtbarkeits-, Safari-Eigentümer-, Vier-gewinnt-Übergabe- und
Nunito-Darstellungskorrekturen. Beide Navigationspfade werden beibehalten:
sofort spielbares Flutter-Vier-gewinnt und ausdrücklicher nativer 3D-Einstieg.
Bestehende Profile, Speicherverträge, Schreibtrainer und Journal bleiben erhalten.

Der Native-Pin ist in diesem **Zwischenstand** weiterhin
`0e7be88791bf4ed5d556d535078471e05a02315d`. Der Koordinator muss vor dem
endgültigen APK-Bau den tatsächlich geprüften gemeinsamen Godot-Commit
übereinstimmend in `config/godot-source.json`, der expliziten Policy für 2023
und `COMBINED_2023_REVISION` im Pin-Regressionstest binden. Die Pins für
2020, 2021 und 2022 bleiben getrennt. Historische 2020-/2021-Workflows werden
nicht als 2023-Abnahme umetikettiert und durch diesen Checkpoint nicht gestartet.

Gezielte Flutter- und Vertragsprüfungen dieses neuen gemeinsamen Hosts stehen
bei Erstellung dieses Checkpoints noch aus. Frühere grüne Läufe ersetzen diese
Prüfungen nicht. Für 2023 sind noch kein APK-Bau, keine tatsächliche Androidtour,
keine vollständige Updateabnahme und kein öffentlicher Download bestätigt.
Main und frühere Releases bleiben unverändert.

## Archiv: frühere Übergaben und Originalnachweise

# LUMO 2020 – tatsächlichen sichtbaren Dorf-Rückweg erneut abnehmen

Stand: 2026-11-14 18:50:01 UTC. Der unmittelbar auf Host6b vorbereitete Korrekturstand
`a7e06055f70929e918d48a1397bf656c1880adb4` ändert ausschließlich den Android-
Dorfbeobachter und seine Tests. Alle Produktdateien, sämtliche Workflows und der
Native-Pin `84789d0c2c6fb4b6ecd2897ce1951b89f958b604` bleiben bytegleich.

Die ursprüngliche [Gesamtabnahme 43616038272/1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43616038272)
auf Host6b endete mit vier erfolgreichen Jobs, einem fehlgeschlagenen Androidjob
und zwei übersprungenen Folgejobs. Der vollständige Flutterlauf bestand tatsächlich
2.651 Fälle ohne Fehler oder Skips; Feature30 und der echte 2017→2020-Updatevertrag
bestanden ebenfalls. Diese Ergebnisse sind keine vollständige Androidfreigabe:
Beim Dorf-Rückweg zeigt das erhaltene Originalbild noch „LUMO DORFWELT“,
obwohl Host-Rückkehr und Ende des Nativeprozesses bereits aufgezeichnet waren.
Die strikte Forderung nach sichtbarem „Spielen“ hat deshalb richtig abgelehnt.
Die nachfolgende Vier-gewinnt-Tour wurde nicht erreicht.

Der Korrekturstand beobachtet innerhalb des bisherigen kombinierten 90-Sekunden-
Budgets frische Bilder, Original-OCR und die aktuelle Flutter-Semantik.
Jeder verworfene Versuch bleibt getrennt erhalten. Es gibt genau denselben
einmaligen Rückkehr-Tap, keine zusätzliche App-Aktion und keine Lockerung
der Captions, Prozess-, Quellen- oder Profilerhaltungsprüfungen.
Der unveränderte XML-Leser hat keinen eigenen Timeoutparameter; eine verspätete
Rückgabe wird dennoch abgelehnt. Alle 34 alten Testmethoden bleiben erhalten;
neun gezielte Fälle kommen hinzu. Der echte Offline-Grünlog enthält 43 bestandene
Fälle, keinen Fehler und keinen Skip in 43,153 Sekunden. Der ursprüngliche
Rotbeleg sowie der unabhängige Review bleiben dauerhaft erhalten.

Root hat beide Original-Testlogs, den unabhängigen Gegenreview und die
vollständigen Gitbäume geprüft. Der genaue Vorlaufbeleg steht unter
`docs/evidence/live-integration-20261114/village-return-observation-6b3047b7/root-activation-review.json`.
Dieser Aktivierungsschritt ergänzt nur die Statusdokumente und Reviewbelege.
Der neue exakte Hostkopf muss erneut Feature30, die vollständige Flutter-Suite,
alle sieben Pflichtjobs, direkte Village-/C4-Androidtouren, Updateerhaltung
und Original-Delivery-Replay bestehen. Der getrennte Diagnosepfad mit unveränderter
6b-APK wird ausdrücklich nicht als neue Gesamtabnahme gewertet.

Version bleibt der noch unveröffentlichte Testkandidat **0.13.8+2020**.
Die früher vorbereiteten 6b-Reader-/Publisherzweige bleiben inaktiv; spätere
Auslieferung muss an den tatsächlichen neuen Quellstand und seine neuen Originale
gebunden werden. Main und frühere Releases bleiben unverändert.

## Archiv: vorheriger Aktivierungsstand

# LUMO 2020 – erneute Gesamtabnahme nach beobachtetem Testfehler

Stand: 14. November 2026, 16:30 UTC. Der vorbereitete Korrekturstand
`407e3503c2777b76647c841867d278977160cbba` basiert unmittelbar auf dem gemeinsam
integrierten Host93. Sein vollständiger Baum ändert genau eine Testdatei:
Ein Nullzeit-`pump()` startet unmittelbar nach dem echten Antippen der
Belohnungsanzeige deren Rückanimation. Die anschließenden 300 ms, alle 30 Fälle,
sämtliche Erfolgskriterien und alle Produktdateien bleiben bytegleich.
Die unabhängige vollständige Baum-/Byteprüfung steht in
`docs/evidence/feature-reward-frame-20261114/root-activation-review.json`.

Der ursprüngliche [Featurelauf 43615128301/1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43615128301)
auf93 ist tatsächlich fehlgeschlagen: 26 erfolgreiche und vier fehlgeschlagene
Fälle, kein Skip. Alle vier Fehler liegen vor dem jeweiligen Modus-/Profilwechsel
an derselben Overlay-Abbau-Erwartung. Die richtigen Antworten, zwei Sterne,
zehn XP und der sichtbare Tap wurden zuvor bestätigt. Der vollständige unveränderte
[Rotbeleg](https://github.com/Ullmann27/lumo-lernen/tree/c4a6692e97b6a1e47edc40d70e05f7a0ca76a435)
bleibt erhalten. Der korrigierte Teststand ist vor dem neuen CI-Lauf noch nicht
ausgeführt; eine grüne Widgetabnahme wird hier nicht behauptet.

Der Produktblob bleibt `f42eb9e1f206fe87c64008906c6b911d59a49fe4`,
der Native-Pin bleibt `84789d0c2c6fb4b6ecd2897ce1951b89f958b604`.
Die zusätzliche Native-Abnahme43613299144/1 ist jetzt terminal erfolgreich;
ihre echten Originale bestätigen auch identische vollständige Quelle und
rohe Indexbytes. Das ersetzt keine neue Host-Abnahme.

Dieser neue Aktivierungsschritt ergänzt nur diesen Status und den Reviewbeleg.
Der exakt neue Hostkopf muss erneut Feature30, die vollständige Flutter-Suite
und alle sieben Pflichtjobs mit neuer signierter APK, direkter Village-/C4-
Androidprüfung, Updateerhalt und Original-Delivery-Replay durchlaufen.
Host93 und der alte1e-Lauf sind keine Veröffentlichungsgrundlage.
Der Publisher bleibt bis zu allen tatsächlichen neuen Originalnachweisen inaktiv.

## Archiv: vorheriger Aktivierungsstand

# LUMO 2020 – vollständige Abnahme des gemeinsamen Stands

Stand: 14. November 2026, 16:18 UTC. Dieser Aktivierungsschritt ergänzt ausschließlich
Status und originale Vorlaufbelege. Produkt und Prüfprogramme entsprechen dem
vorbereiteten Host `b2f7493bda3bc22c1296f2284888ff7302f18883`,
Tree `2bffbaf37f5e5d9a9c4d4a018faa81b7d621ca98`.
Seine vollständigen 4.967 Dateien stimmen mit der geplanten Vereinigung überein.
Der aktuelle Producer `057a4e8d067872c4f3514b126aa04c3706d2e5b5`, Garage d7b5289
und Safari fe5df7f4 sind integriert. Die geschützten Schreibtrainer-, Journal-
und Speicherdateien bleiben unverändert.

Der exakte Native-Pin ist `84789d0c2c6fb4b6ecd2897ce1951b89f958b604`.
Alle elf Native-PR-Läufe sind erfolgreich abgeschlossen; der zusätzliche
[Discovery-/Scaling-/Minimap-Lauf](https://github.com/Ullmann27/lumo-godot/actions/runs/43613299144)
wird noch abschließend geprüft. Die dortige strikte Quell-/Indexgrenze bleibt
Pflicht. Lokale Rendererbilder allein ersetzen sie nicht.

## Tatsächlich geprüfte Garagenkorrektur

Die getrennt an QA 4017a94d und die unveränderte frühere 1e22/e9-APK gebundene
[API35-Diagnose 43612493152](https://github.com/Ullmann27/lumo-lernen/actions/runs/43612493152)
hat drei von drei Jobs erfolgreich beendet: 101 Vorlaufverträge, vollständige
Main-Tour mit 21/21 Schritten sowie das 2017→2020-Update. Die originalen Resultate
belegen echte Fahrzeugwahl, gespeichertes Gecko-Velo-Rennen, Fahrt, Pause,
Fortsetzen und Hostrückkehr. Im Update wurde auch der neue beobachtete Pixelanker
tatsächlich benötigt. UID, erste Installationszeit und sieben vorhandene Lernkeys
blieben über Update, Kart, Neustart und drei Foldmaße erhalten. Es waren keine
befüllten Schreib-/Journalinhalte angelegt. Die separaten direkten Village- und
C4-Proben sind nicht Teil dieser Diagnose; sie bleiben im neuen Gesamtlauf Pflicht.
Die vollständige Archiv-/Bildprüfung der Diagnose wird getrennt dokumentiert.

## Lokale Gesamtprüfung und verbindlicher neuer Lauf

Die unveränderte vollständige Script-Suite auf b2 wurde tatsächlich ausgeführt:
924 gemeldete Tests, Exit 1, sechs Fehler und drei Skips. Drei echte Unix-Sockettests
scheitern in dieser Arbeitsumgebung bereits an `socket(AF_UNIX)` mit
`PermissionError: Operation not permitted`; drei Klassen sowie die Skips benötigen
die hier fehlenden verifizierten Gradle-/Kotlin-Bibliotheken. Java ist vorhanden.
Es gibt keine lokale vollständige Freigabe. Der Original-Log mit SHA256
`b5073f23af710b72e95f747c2c1983c042c0eac0c8bdfa69c298693051deeaaa`,
Aufruf, Resultat und Quellenvergleich liegen in
`docs/evidence/combined-b2-preflight-20261114/`. Getrackte Quellen blieben gleich.

Der vorhandene vollständige CI-Workflow richtet seine festgelegte Java-/Gradle-
Toolchain ein und muss die unveränderte komplette Suite ohne Fehler oder Skips
ausführen. Alle sieben Pflichtjobs, der zusätzliche Feature30-Lauf einschließlich
acht Safari-Fällen, vollständiges Flutter, neue signierte APKs, echte
API35-Main-/Village-/C4-Touren, vollständiges Update und Original-Delivery-Replay
bleiben für diesen neuen Quellstand erforderlich.

Version bleibt der unveröffentlichte Testkandidat **0.13.8+2020**. Der alte Publisher
9448c47 bleibt inaktiv. Erst nach sämtlichen neuen Originalnachweisen darf ein
neu gebundener Publisher das neue öffentliche ARM64-Asset bereitstellen und dessen
tatsächlich geladene Bytes prüfen. Main und frühere Releases werden nicht verändert.

## Archiv: vorheriger Vorlaufstand

# LUMO 2020 – laufende gemeinsame Integration, 14. November 2026

Der aktuelle Arbeitsstand führt Host `1e22d2455937e2640d1e44e153d290746f3afe49`
und den neuen Entwicklungsstand `057a4e8d067872c4f3514b126aa04c3706d2e5b5`
zusammen. Beide tatsächlichen Eltern und alle bestehenden Originalbelege bleiben
im Git-Verlauf erhalten. Die geprüfte Garagenkorrektur aus
`d7b5289f5b17cc6adf65fe2511971371f289cb6a` ist mit beiden realen Eltern integriert.
Die aktuelle Native-Quelle ist `84789d0c2c6fb4b6ecd2897ce1951b89f958b604`,
Tree `91cc8fc1c6f8a36336b7ac9a12585284a983a6f6`. Sie vereinigt e9a9 und a69f535
über fe861bd und aktiviert zusätzlich die vorhandene Discovery-/Village-/Minimap-
Abnahme auf dem zentralen Entwicklungszweig. Sämtliche 3.769 anderen Dateien
blieben bei dieser Triggerkorrektur unverändert; alle 50 historischen Pins bleiben.

Native-Run [43613299144](https://github.com/Ullmann27/lumo-godot/actions/runs/43613299144)
prüft exakt diesen neuen Pin. Die API35-Diagnose
[43612493152](https://github.com/Ullmann27/lumo-lernen/actions/runs/43612493152)
prüft bewusst die unveränderte frühere 1e22-APK mit getrennt gebundener QA-Quelle
4017a94d. Ihre 101 Vorlaufverträge sind bestanden; beide Gerätetouren laufen.
Die neue Hostunion bestand 177 gezielte Scriptverträge und danach 25 aktuelle
Pinverträge. Die verzögerte Safari-Fortsetzung aus fe5df7f4 ist jetzt an denselben
Modus und dasselbe Profil gebunden; acht zusätzliche Widgetfälle prüfen richtige
und falsche Antworten bei Moduswechsel, Rückwechsel, unveränderter Safari und
Profilwechsel. Der 30-Fälle-Featureworkflow ist zusätzlich an den zentralen
App-Entwicklungszweig angeschlossen. Die neuen Widgetfälle wurden lokal nicht
ausgeführt; ihr tatsächlicher CI-Lauf bleibt erforderlich. Diese Teilnachweise
sind keine abschließende neue APK-Abnahme.

## Tatsächlich abgeschlossener Lauf auf 1e22

Run [43596913210](https://github.com/Ullmann27/lumo-lernen/actions/runs/43596913210),
Versuch 1: C4-Runtime, Android-Host-Kompilierung und Verify-and-build bestanden.
2.627 Flutter-Tests ohne Fehler/Skip, 566 erfasste PNGs, 932 Scriptverträge,
Native52/17, Return21, Dream5/7/2, Live9/7 und Discovery10/38 sind belegt.
Die signierten Test-APKs wurden gebaut und ihre tatsächlichen Bytes überprüft.
Der ARM64-SHA256 ist `44faa59620955d58fc43e7b6a6488222fe70f8445884384c17c6b379f775d5bd`.

Beide anschließenden API35-Jobs scheiterten bei der Garagenauswahl nach dem
Wischen: `No currently visible vehicle card in the actual left list`.
Die Originalbilder zeigen abgeschnittene Fahrzeugnamen und einen Wischendpunkt
oberhalb der tatsächlich sichtbaren Liste. Race/Drive/Pause, Village und C4
wurden auf diesem Androidlauf nicht abschließend erreicht; die beiden
Auslieferungsjobs wurden übersprungen. Eine Veröffentlichung bleibt gesperrt.

Das reale 2017→2020-Update selbst gelang mit gleicher UID und Installationszeit.
Die 15 vorhandenen Preference-Keys, darunter sieben Lernkeys, wurden erhalten;
ein korrektes Mathematikresultat, ein Stern und fünf XP sind dokumentiert.
Die erlaubte independentEvidence-v1-Migration wurde erkannt. Es waren keine
Journal- oder Schreibinhalte angelegt; deren konkrete Inhaltsmigration wird
hieraus nicht behauptet. Die anschließende Kart-/Restart-/Fold-Abnahme blieb offen.

## Nächste verbindliche Schritte

1. Neue Producer-Änderungen, eigene Live-/Ink-/Village-Ergänzungen und aktuelle
   Originalhinweise vollständig vereinigen; unveränderte geschützte Module prüfen.
2. Den beobachtungsgebundenen Garagenprüfschritt mit Originalfixtures und einem
   echten API35-Lauf auf der unveränderten 1e22-APK prüfen. QA-Quelle und APK-Quelle
   bleiben getrennt gebunden. Alle Touch-/Zeit-/Race-/Speicher-Grenzen gelten weiter.
3. Den exakten neuen gemeinsamen Stand durch sämtliche sieben Pflichtjobs führen.
   Eine Diagnostikfreigabe ersetzt diesen vollständigen neuen Lauf nicht.
4. Erst nach vollständiger Originalprüfung einen neuen Publisher exakt an Quelle,
   Lauf und Versuch binden; öffentliches ARM64-Asset frisch laden und byteprüfen.
   Der vorbereitete Publisher 9448c47 bleibt gegen den gescheiterten Lauf inaktiv.

Die folgenden früheren Abschnitte sind Archivstände; sie bescheinigen keine
Abnahme oder Veröffentlichung des hier vorbereiteten neuen gemeinsamen Stands.

## Archiv: bisheriger Integrationsstand 1e22

# Aktueller gemeinsamer LUMO-2020-Integrationsstand — 14. November 2026

Host-Review: [PR 497](https://github.com/Ullmann27/lumo-lernen/pull/497).
Arbeitszweig: `integration/lumo-live-connections-20261114`.
Version: **0.13.8+2020**, unveröffentlichter Family-Testkandidat.
Native-Review: [PR 173](https://github.com/Ullmann27/lumo-godot/pull/173).
Exakt gebundene Godot-4.6.3-Quelle: `e9a9f60f20403ffa6b2b26d1437f958b2704d2aa`,
Tree `1c2b5da7a4485cb8b911adcac2b567481cf902b5`.
Main und vorhandene Veröffentlichungen bleiben geschützt.

## Vollständige Zusammenführung

Dieser Host-Merge führt `9516068cfb67938fc90d48ff45d56169f00941fc` und den
tatsächlichen aktuellen Qualitätszweig `aab09275ec6b5808de9be539ca4e1a7e70921249`
mit beiden realen Eltern zusammen. Die gemeinsame Basis ist
`803a4e960ffb804a46b6d09417731c031f00f680`.
Der Abgleich verwendet vollständige rekursive Git-Bäume, weil die
Compare-Dateiliste bei 300 der 302 Upstreamänderungen endet.
280 Änderungen werden als Originalblobs übernommen; 18 konkurrierende Dateien
werden ausdrücklich aufgelöst. Vier bereits identische Änderungen und sämtliche
151 ausschließlich eigenen Änderungen bleiben erhalten. Es gibt keine Löschung.

Der Native-Merge verbindet `71a4c1e2304b52005950b12490d070c286c45438`
mit `e2d15dbc5f3709306decb139eeb70a1cf30c0b73`.
Sein vollständiger Baum wurde unabhängig mit allen 3.712 Nicht-Tree-Einträgen
verglichen: null Abweichungen von der berechneten Vereinigung. Die 63 zusätzlichen
Upstreamblobs und zwei Provenienzdateien ergänzen den bisherigen Stand.
Alle geschützten Hub-/Village-Dateien und bisherigen Prüfprogramme bleiben
blob- und modusgleich.

Die elf Spieleportale, der direkte Dorfwirtschaft-Einstieg samt sichtbarer
Rückkehr zu Spiele, gesicherte Profile/Lernstände, Original-Lumo, gemeinsames
Zeichnen sowie die vorhandenen Schreibtrainer- und Journalmodule bleiben
angeschlossen. Dazu kommen die exakte kumulative Mathematik-Themenwahl,
unverkleinerte gedrückte C4-Touchflächen, sichere Kart-Minimap-Geometrie,
die zusätzliche Dream-Abnahme und die präzise Android-Continue-Erkennung.

Die Testauflösung behält echte Spielzüge, Replay-/Restart-Nachweise, vollständige
Rückwege und alle Herkunftsprüfungen. Die Auslieferung verlangt weiterhin genau
elf Assets einschließlich des originalen Village-Android-Ergebnisses.
Live9/7 und Discovery10/38 bleiben zusätzlich zu Dream5/7/2 verpflichtend.

## Tatsächlicher abgeschlossener Vorgängerlauf

Run [43586101225](https://github.com/Ullmann27/lumo-lernen/actions/runs/43586101225),
Versuch 1, prüfte Host `07cac7225e2f7b6451665dfda9c38841f51c758b`
und Native `71a4c1e2304b52005950b12490d070c286c45438`.

- C4-Runtime und tatsächliche Android-Host-Kompilierung bestanden.
- Die vollständige Flutter-Abnahme bestand **2.625 Tests**, ohne Fehler,
  übersprungene Tests, Runner- oder Capturefehler; **566 PNGs** wurden erfasst.
- Die 52 Native-Modi mit 17 Extension-PNGs bestanden. Der gesamte große
  Native-Schritt benötigte 58 Minuten 51 Sekunden; die 52er-Stufe selbst
  rund 41 Minuten 25 Sekunden.
- Live bestand neun Proben und sieben PNGs. Bei Discovery waren acht von zehn
  Proben abgeschlossen; die Lernwelt-Capture erreichte zehn von 25 Bildern.
  Die abschließende Discovery10/38-Freigabe wurde nicht erreicht.
- Der Buildjob wurde nach etwa 90 Minuten abgebrochen. Das Originalprotokoll
  meldet `The operation was canceled.`; die vollständige Providerannotation
  war nicht zugänglich. Vorher wurde im Native-Abschnitt kein Engine-,
  Assertion-, Ressourcenleck- oder innerer Probe-Timeoutfehler gefunden.
  APK-Build, Android-Touren, Update und Abschlussjobs wurden nicht ausgeführt.

Das äußere Buildbudget wurde deshalb von 90 auf 150 Minuten erhöht.
Alle inneren Probegrenzen, Fehlermarker und erforderlichen Prüfungen bleiben
bestehen. Der neue Dream-Vertrag ergänzt fünf echte Proben, sieben Original-PNGs
und zwei Originalberichte; sein Reader bleibt vor dem Import exakt an
Gitblob `da8eed7d6383fcbc82a03596518a5fcc3b9a00c5` und SHA256
`f7296a802d15c382dbcc77640373a0f53e30306fcaab3de869549ff1656de89d` gebunden.

Die ungekürzten Vorgängeroriginale sind dauerhaft gesichert:
[Android/Build](https://github.com/Ullmann27/lumo-lernen/commit/5cc5ef0498012cf49ce5070cc8d932a855b3260a),
[Flutter](https://github.com/Ullmann27/lumo-lernen/commit/b40260edaf5ecfa8eef060a46364021b2a9eadd0)
und [Native-Originalprüfung](https://github.com/Ullmann27/lumo-lernen/commit/a6216484bd48bc2db8615d73d1397c0b5b35feb4).
Sie bescheinigen keinen neuen APK-Erfolg.

## Noch auszuführende gemeinsame Abnahme und Auslieferung

Der exakte neue Hostkopf muss seinen eigenen vollständigen Flutter-/Scriptlauf,
Native52/17, Live9/7, Discovery10/38, Dream5/7/2 und zusätzlichen Return-/Wisp-Nachweis
bestehen. Danach folgen frische signierte ARM64-/x86-APKs, die tatsächlichen
API35-Atelier/Kart/Village/C4-Touren, das datenerhaltende 2017→2020-Update und die
vollständige erneute Auslieferungsprüfung. Alle sieben Pflichtjobs müssen zum
selben aktuellen Quellstand und Run gehören.

Der ausführbare Publisher ist vorbereitet, aber die früher an Host07/Run43586101225
gebundenen Objekte sind verworfen und dürfen nicht aktiviert werden.
Er wird erst an den endgültigen erfolgreichen neuen Kopf und dessen tatsächlichen
Run gebunden. Er prüft das originale Delivery-Bundle, wiederholt Signatur,
Paket-/Versions-/ABI-/Quellenprüfung an der tatsächlichen ARM64-APK, erstellt
ausschließlich ein neues Release und vergleicht anschließend die anonym
heruntergeladenen öffentlichen APK-Bytes mit den freigegebenen Originalen.
Der dauerhafte Eigentümerauftrag in AGENTS.md erlaubt diese neue Testauslieferung
ohne erneute Nachfrage; ein geplanter Pfad ist noch kein gültiger Downloadlink.

Die Ausführungsumgebung wurde nach dem Remote-Quellabgleich als frische leere
Umgebung wiederhergestellt. Der vollständige Checkpoint
`f36579a3a7e06045eaecea7c00e497ac06930100`, Tree
`ed67b3939bb3caeb69231a2c70387860155b1a83`, wurde tatsächlich ausgecheckt.

Auf genau diesem gemeinsamen Produkt-/Test-/Workflowstand bestanden am
14.11.2026 von 12:47:32 bis 12:49:03 UTC **373 gezielte Tests in 16 Dateien**,
ohne Fehler oder Skips. Sechs YAMLs, sechs echte extrahierte Native-Shellblöcke
und die vorhandene Diagnostic-Shell bestanden ihre Syntaxprüfung.
Alle 4.655 Dateien wurden vor und nach dem Lauf gegen ihre Gitblobs geprüft;
Quelle und gesamte Dateiidentität blieben unverändert. Root hat die 16
Originalprotokolle, ihre Hashes und Testzahlen unabhängig nachgelesen.
Lokale Werkzeuge: Python 3.12.14, PyYAML 6.0.3 und Pillow 13.0.0.
Der vollständige Kandidatenworkflow verwendet weiterhin sein gepinntes
Pillow 12.3.0. Actionlint war lokal nicht vorhanden und wurde nicht ausgeführt.
Diese fokussierten Tests ersetzen keinen Flutter-, Renderer-, APK- oder
Emulatorlauf auf dem endgültigen Hostkopf.

Der vorliegende Freigabe-Commit ergänzt zum geprüften Checkpoint ausschließlich
diese Originalbelege und Statusdokumentation. Produkt, Tests, Policies, Assets,
Native-Pin und Workflows bleiben bytegleich. Der separate alte Publisher wurde
zusätzlich tatsächlich nur auf Syntax geprüft: YAML, sieben Bash-Blöcke und
drei Python-Heredocs bestanden; seine verworfene07-Bindung blieb unverändert.
Originale: [Publisher-Syntaxbeleg](https://github.com/Ullmann27/lumo-lernen/commit/68cff44598c141e5f1f0c02012c5e6503503d4da).

Play-Produktionssignierung, Play-Console-Abnahme, physische Android-Bildraten und
thermisches Dauerverhalten sind weiterhin unbelegt. Die strukturelle
Mathematik-/Curriculumprüfung ersetzt keine vollständige pädagogische Freigabe.
Private Profildaten werden nicht als öffentliche Betreiberangaben übernommen.

## Verbindliche Wiederaufnahme dieses Kandidaten

1. Tatsächliche Host-/Native-Refs und den aktuellen PR-Kopf lesen. Die obigen
   Eltern und der Native-Pin bestimmen die zusammengeführte Quelle; ältere
   zwischengespeicherte PR-Basisfelder ersetzen keine tatsächliche Branch-Ref.
2. Den neuen PR-Lauf auf genau diesem Hostkopf verfolgen. Originale Jobs,
   Versuch, Logtexte und Artefaktidentitäten prüfen. Keine früheren grünen
   Ergebnisse als neue Freigabe übertragen.
3. Bei Fehlern den konkreten ersten Fehler aus dem Originalprotokoll beheben,
   alle anderen Prüfungen beibehalten und die nächste Quelle erneut prüfen.
   Ohne neue fachliche Änderung keine erfolgreichen optionalen Prüfungen wiederholen.
4. Nach sieben erfolgreichen Pflichtjobs das originale Auslieferungsartefakt
   streng erneut prüfen und erst dann den vorbereiteten Publisher mit dem
   tatsächlichen neuen Host-/Native-/Run-/Attempt-Bezug aktivieren.
5. Vor jeder Veröffentlichung Release-/Tag-Leerstand, aktuelle Quellen und
   Originalartefakte erneut lesen. Alte Releases und Tags bleiben unverändert.
   Die neue öffentliche ARM64-Datei vollständig herunterladen und ihre
   Größe sowie SHA256 mit den ursprünglichen freigegebenen Bytes vergleichen.
6. Den funktionierenden direkten HTTPS-Link zur einzelnen APK samt Version,
   Host-/Native-Commit, Testsignatur und SHA256 liefern. Fehlt ein tatsächlicher
   Prüf- oder Veröffentlichungsschritt, die genaue Grenze dokumentieren.


---

# Historische Übergaben beider Eltern

Die folgenden unveränderten Texte dokumentieren die jeweiligen früheren Quellen.
Alte Pins, offene Prüfungen, Zugangsgrenzen und vorgeschlagene Aktionen sind
historisch; maßgeblich ist der aktuelle gemeinsame Stand oben.

## Bisheriger eigener Integrationsstand

# Active LUMO 2020 integration and complete acceptance — 2026-11-14

Active review: https://github.com/Ullmann27/lumo-lernen/pull/497
Working branch: `integration/lumo-live-connections-20261114`.
Version: `0.13.8+2020`.
Exact native source: `71a4c1e2304b52005950b12490d070c286c45438`.
Native review: https://github.com/Ullmann27/lumo-godot/pull/173.
Main remains protected.

## Integrated behavior

The complete host integration through `cf2593cb6dec51b66461c8e5984dfbfdd5091c22`
is retained, including the Play-quality base, drawing and learning progress,
eleven Flutter game portals, responsive C4, direct Dorfwirtschaft launch and the
existing handwriting/journal modules.

The native Hub now loads the existing original facial Lumo rig. Its actual GLB,
bones, animations, visible mesh and free camera framing are checked. Eight native
routes are retained. The original portrait and landscape PNGs were independently
viewed; the portrait keeps its existing scroll continuation.

A direct embedded Dorfwirtschaft entry now has the visible `‹ Spiele` return
through the existing save and HostBridge path. Failed saves block departure,
and a refused return acknowledgement remains retryable. The original internal
Bauwelt context and the optional Bauwelt route remain available. AndroidBack
continues to pause. The original initialized-state marker identifies the actual
running village for the additive API35 roundtrip proof.

The Home capture tests now open the real subject expansion, wait for its actual
animation frames, require the first Mathe card to be fully visible and hittable,
and capture that state. Village captures use Flutter's SDK-owned Android platform
variant so the framework restores its debug state correctly.

## Actual predecessor and focused results

The first combined run on 7fd9e916 reported 2,612 passed / three failed / zero
skipped / 546 PNGs. Its three outdated Diktat finders were repaired.

The next combined run [43582160954](https://github.com/Ullmann27/lumo-lernen/actions/runs/43582160954)
on cf2593cb passed native C4 runtime, actual Android host compilation, static
analysis and all 888 script tests. Full Flutter reported **2,619 passed / six
failed / zero skipped / 566 PNGs**. All three repaired Diktat cases passed
individually. The six failures were the Village tests' platform-cleanup invariant,
after their layout and real launch assertions. No APK was built by this run.

The focused corrections subsequently passed:
- Home run 43584516810: 13 Home/navigation tests and eight additional world tests,
  with eight original captures; the four learning-card captures now show real
  opened subject cards.
- Village run 43583899148: 27 Flutter tests, six original captures and actual
  Kotlin/Android host compilation.
- Native 71a4c1e2: original Hub identity and two real renders; Village host return,
  save/restore and rejected-ACK retry; existing Rig, VillageScene and Economy
  regressions; eleven helper tests with 57 negative cases and a read-only replay
  of the complete 38-image set.

## Required final acceptance

The exact next combined host must pass its own full Flutter suite, the native
52-mode suite and original 17-image extension, Live nine-probe/seven-image suite,
Discovery ten-probe/38-image suite, signed APK build, actual API35
Atelier/Kart/Village/C4 journeys, 2017-to-2020 data-preserving update and final
delivery replay. The Village result must be bound to the same original APK,
source, run, main tour, native PID, profile, real scene and preserved learning data.
Only the complete accepted source may be used for a new direct APK release.

Focused or predecessor results do not certify the final APK. No physical Android
60-FPS, Play-production signing or curriculum-wide approval is claimed.
Original evidence and source provenance remain under
`docs/evidence/live-root-integration-20261114/source-integration.json`,
`docs/evidence/capture-state-qa-20261114/` and the corresponding native evidence.

---

## Previous combined-candidate handoff

# Active LUMO 2020 combined integration — 2026-11-14

Active review: https://github.com/Ullmann27/lumo-lernen/pull/497
Working branch: `integration/lumo-live-connections-20261114`.
Version: `0.13.8+2020`.
Exact native source: `7d53f29e68269c21d1d5a66bdf3d488f8e886970`.
Native review: https://github.com/Ullmann27/lumo-godot/pull/173.
Main remains protected.

## Integrated source and acceptance boundary

The complete Play-quality follow-up through `803a4e960ffb804a46b6d09417731c031f00f680`
is preserved in the host integration. The native integration also includes the
actual latest native base `f052c2795b765265dbb6f5c27b9e92b557d39a39`; all original
Wisp checks and the four additional GPU checks remain enabled.

This candidate connects the eleven game portals, the direct Dorfwirtschaft
Flutter/Android/native route, the shared drawing surface, native learning
feedback and celebrations, game-hub routes, the learning world and its garden,
and the existing learning/journal modules. Responsive Home and village title
layouts retain real touch, navigation, large-text and original-image checks.
The Diktat tests now draw on the actual shared ink surface while retaining all
progress, repeated-rating and earned-reward assertions.

The first combined host `7fd9e91683ecf703c00f100e314aced9191f7847` was tested in
run https://github.com/Ullmann27/lumo-lernen/actions/runs/43579007561.
Native C4 runtime and Android host compilation passed. Full Flutter acceptance
reported 2,612 passed, three failed, zero skipped and 546 original PNGs.
All three failures came from the outdated Diktat gesture finder; their original
failure evidence is retained. No APK was built by that failed run.

The expanded native source passed ten local probes and all 38 discovery PNG
checks. The delivery verifier passed 129 Python tests, including its negative
checks. These focused results do not replace the new combined acceptance run.
The exact current host must pass the complete Flutter and native suites, signed
APK build, Android API35 journey, 2017-to-2020 data-preserving update, and final
delivery verification before its APK can be presented as accepted.
Physical Android 60-FPS performance has not been measured.

Source provenance and original evidence:
`docs/evidence/live-root-integration-20261114/source-integration.json`.
The full acceptance runner now requires original Village, Home and Nextgen
captures. The main C4 workflow also requires all discovery probes and images,
and the delivery verifier replays both original native connection helpers.

---

## Preserved earlier project handoff

# Active LUMO 2020 Play-quality candidate — 2026-11-14

## Hinzugekommener Qualitätsstand aab09275

## Archiv: eingegangener Entwicklungsstand 057a

# LUMO 2020: zusammengeführter Abnahmekandidat – 14. November 2026

Arbeitszweig: `work/lumo-play-quality-20261114`. Review: [PR 491](https://github.com/Ullmann27/lumo-lernen/pull/491). Version **0.13.8+2020** ist weiterhin ein unveröffentlichter Testkandidat.

Dieser Stand führt die tatsächlichen Host-Eltern `77936fae6ce7b7bcbddb93dda19fb0104f696e12` und `0b7bacadd3cdc45d22a8e038c5df50ba8b739d62` zusammen. Der gemeinsame Host-Vorfahr ist `3d91bd8355a539c3c2413760959684cd3fee985a`. Der Native-Pin lautet `a69f53518b2510873d88f00ff2783d616ab53702`, Tree `607643d9e109079925e21dfcf9c991a8250d4a46`, mit den tatsächlichen geordneten Eltern `e2d15dbc5f3709306decb139eeb70a1cf30c0b73` und `baf148b03a7a32c6ad9f737d731f900eb9113ea1`.

## Zusammenführung und erhaltene Funktionen

Die vollständigen Git-Bäume ergeben 221 nur im neuen Integrationsstand geänderte Host-Pfade, drei bereits identische Änderungen und zehn Überschneidungen. Fünf Quell-/Testdateien wurden konfliktfrei durch einen echten Dreiwegevergleich vereinigt und unabhängig erneut geprüft. Die drei Native-Pin-Stellen wurden gemeinsam an den geprüften Zweieltern-Commit gebunden. Beide älteren Status-Vorspänne bleiben unten unverändert als historische Aufzeichnungen erhalten.

Die fünf ursprünglichen Lizenz-/Herkunftstexte werden weiterhin als kontrollierte Android-Assets beigepackt; die 10 zugehörigen Code-/Testdateien und die geprüfte dunkle Prompt-Beschriftung bleiben bytegleich aus Host7793 erhalten. Die neuen Dorfwelt-, Kamera-, Profil-, Diktat- und Android-Verbindungen bleiben aus Host0b7 erhalten. Der native Baum bewahrt alle 3.689 Einträge aus baf148b und ergänzt ausschließlich 32 ursprüngliche e2-Nachweisdateien. Die beiden gemeinsamen Kart-/SafeArea-Änderungen waren bereits identisch. Historische Tests werden dadurch nicht zu Ergebnissen dieses neuen Standes.

## Tatsächlich geprüfter Umfang vor dem vollständigen Build

Die aufgelösten Quellen wurden mit zehn bestehenden Python-Vertragsmodulen geprüft: insgesamt **248 unterschiedliche Testfälle erfolgreich**, verteilt auf drei tatsächliche Aufrufe. Der erste Aufruf meldete 200 erfolgreiche Fälle und drei Importfehler, weil der Test-Fixture-Suchpfad im lokalen Aufruf fehlte. Nach dessen Korrektur liefen 47 weitere Fälle erfolgreich; ein weiterer Fall benötigte den im lokalen Teilauszug fehlenden unveränderten Sprachkatalog. Nach Wiederherstellung dieses Originalinputs lief auch dieser eine Fall erfolgreich. Sämtliche ursprünglichen Fehlerprotokolle bleiben erhalten. Es wurden dafür keine Produkt- oder Testdateien verändert; alle ursprünglichen 1.641 materialisierten Quelldateien blieben identisch, hinzu kam genau der ursprüngliche Katalog.

Der zusammengeführte Workflow wurde als YAML gelesen und alle **48 Shell-Blöcke** bestanden `bash -n`. Dies ist eine Syntaxprüfung und keine ausgeführte Workflow-Abnahme. Die unabhängigen Host- und Native-Reviews bestätigten den Erhalt der jeweiligen Änderungen und Prüfungen.

## Nächster verbindlicher Schritt

Der vollständige Ablauf muss auf diesem neuen Host-/Native-Paar erneut laufen: Android-Hostkompilierung, sämtliche Flutter- und Build-Verträge, reale C4-, Native52-, Dream- und Discovery-Prüfungen, neue signierte APKs, die aktuellen Android-Touren einschließlich Village/C4 sowie die Erhaltung beim Update 2017→2020. Erst die Originalartefakte dieses Standes dürfen für seine Auslieferung verwendet werden. Ein neuer geprüfter APK-Download oder eine Play-Freigabe liegt zum Zeitpunkt dieser Zusammenführung nicht vor.

Die bisherigen Ergebnisse, Grenzen und tatsächlichen Fehlläufe stehen in den folgenden historischen Aufzeichnungen. Der aktuelle Ausführungsstand wird zusätzlich im Evidenzzweig `checkpoint/lumo-aab-ci-20261114-2708` unter `docs/evidence/quality-aab-ci-20261114/LIVE_HANDOFF.json` fortgeführt. Produktiver Main und bestehende Releases bleiben unverändert.

---

## Bewahrter Stand des Qualitätszweigs vor dieser Zusammenführung


# Aktueller LUMO-2020-Kandidat – 14. November 2026

Review: [PR 491](https://github.com/Ullmann27/lumo-lernen/pull/491). Arbeitszweig: `work/lumo-play-quality-20261114`. Wiederaufnahme: `checkpoint/lumo-next-quality-20261114-2708`. Version **0.13.8+2020** bleibt ein unveröffentlichter Testkandidat. Main und bestehende Releases bleiben geschützt.

Dieser Stand führt den Qualitätscheckpoint `38c2fe8cb9e1b1021842e886c1a7cfa199e687ca` und den Integrationsstand `3d91bd8355a539c3c2413760959684cd3fee985a` mit beiden tatsächlichen Eltern zusammen. Der gemeinsame Host-Vorfahr ist `32e7efbff427fef64e90b3a1fcecd3b52f00af42`. Die exakt gebundene Native-Revision ist `e2d15dbc5f3709306decb139eeb70a1cf30c0b73` (Tree `ea0f73ae6aad8792a963cadaa483c290a2f2a62e`), ein tatsächlicher Merge mit den Eltern `bd0712259bb64908a5649ee1999638826c9eb597` und `6ecc560ea16202b935c4f1d32b08b93cda358e02`. Originale: [Native-Zusammenführung](https://github.com/Ullmann27/lumo-godot/tree/e2d15dbc5f3709306decb139eeb70a1cf30c0b73/docs/evidence/native-dream-minimap-merge-20261114). Der Kandidat wird für den vollständigen Lauf auf diesen Quellen eingefroren; spätere parallele Erweiterungen werden während dieser Abnahme nicht automatisch übernommen.

## Enthaltene Korrekturen

- Die Mathematik-Auswahl behält das ausdrücklich gewählte Thema auch bei Wiederholungen aus früheren Klassen. Ein Alias der aktuellen Klasse ersetzt kein anderes exakt angefordertes Thema. Zulässige Aufgabenmischungen innerhalb eines Themas bleiben erhalten.
- Die passive Kart-Minimap berücksichtigt das tatsächliche sichere Bildschirmrechteck, Steuerelemente, Pedalgrafik und eingeblendete Hinweise. Sie reagiert auch auf das Erscheinen und Verschwinden des Sprunghinweises. Fahrphysik und vorhandene Steuerung bleiben erhalten.
- Connect Four behält seine vollständigen Touchflächen beim Drücken. Android erkennt die alleinstehende Continue-Beschriftung. Die Quellenbindung akzeptiert den Qualitätszweig ausdrücklich und prüft weiterhin genau den aktuellen PR-Kopf, Run, Workflow, Branch und Artefaktinhalt.
- Die bisherigen 52 Native-Prüfmodi, die strenge Return-21-Stufe und die zusätzlichen frühen Return-/Wisp-Stufen bleiben unverändert. Die Traumwelt ergänzt fünf Pflichtmodi mit sieben tatsächlichen PNGs und zwei Originalberichten. Ihr Reader wird vor dem Import an den freigegebenen Git-Blob und SHA-256 gebunden; die Auslieferungsprüfung wiederholt seine Prüfung ohne Veränderung der Originale.
- Frühere Formeingabe-, Navigations-, Datenschutz- und Family-/Play-Korrekturen bleiben erhalten. Schreibtrainer, Journal, Profile, Lernstände und der vollständige bisherige Host-Assetbaum werden durch diese Zusammenführung nicht ersetzt.

## Tatsächlich vorhandene eng begrenzte Nachweise

**Mathematik:** Derselbe Vertrag lief mit echten Produktions-Dart-Dateien gegen beide Fassungen. Der alte Generator verletzte 386 Bedingungen; die Korrektur bestand 29.845 erreichte Prüfungen. Geprüft wurden 145 kumulative Klassen-/Themenkombinationen mit 32 Seeds, 4.640 tatsächliche Factory-Aufrufe und 3.955 direkte Template-Aufrufe. Der Flutter-Testwrapper ist enthalten; seine Ausführung gehört zum nächsten vollständigen Kandidatenlauf. Originale: `docs/evidence/math-exact-cumulative-20261114/EXECUTION.md`.

**Minimap:** Dieselbe Godot-4.6.3-Probe meldete beim alten Produktionscode 380 Prüfungen mit 26 Fehlern, bei der Korrektur 380 ohne Fehler. Auch die Kombination mit den neuen Dream-Quellen bestand die tatsächlichen 380 Prüfungen. Alle 15 bisherigen SafeArea-Ziele bleiben erhalten. Die lokale Geometrieprobe enthält keine Rasterbilder und bescheinigt keine Android-Bildrate; der vollständige Renderer-Lauf bleibt erforderlich.

**Bisheriger Host-Zwischenstand:** Auf `dfc3e0a1ea20f1491e4844ecfa913c598e1c6c5f` bestanden 226 gezielte Python-Tests sowie Actionlint und die Bash-Syntaxprüfungen der vier bisherigen Native-Blöcke. Ein erster Fehler beim Modul-Suchpfad ist zusammen mit dem unveränderten erfolgreichen Wiederholungslauf gesichert. Auf `38c2fe8cb9e1b1021842e886c1a7cfa199e687ca` bestanden zusätzlich die 65 aktuellen und historischen Pin-Verträge. Originale: `docs/evidence/quality-32e7-merge-20261114/local-execution/`.

**Gemeinsamer Host-/Dream-Stand:** Auf dem tatsächlichen Merge `dc966e8e4e4f69c5cb19e53822625025bb0fe766` (Tree `883461f7827d92eb4175b191bb66202a98251f60`) bestanden 237 gezielte Python-Tests in 26,816 Sekunden, Actionlint und Bash-Syntaxprüfungen aller fünf relevanten Native-Blöcke. HEAD, Tree, verfolgte Dateien und Index blieben unverändert. Vollständige Originale und der tatsächlich ausgeführte Treiber: `docs/evidence/quality-dream-merge-20261114/execution/` und `run_committed_source_checks.py`.

Der abschließende Freigabe-Commit ergänzt ausschließlich diese Nachweise und die Statusdokumente; der geprüfte Produkt-, Test-, Policy- und Workflow-Code bleibt bytegleich. Der vollständige CI-Lauf auf genau diesem neuen PR-Kopf wird damit angefordert und muss noch tatsächlich bestehen. Frühere Erfolge werden diesem Stand nicht als APK- oder Android-Freigabe zugerechnet.

## Abgeschlossener Vorgängerlauf und seine Grenzen

Run [43578509499](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499) auf Host `803a4e960ffb804a46b6d09417731c031f00f680` endete insgesamt mit **Fehler**. Der Hauptjob bestand 2.569 Flutter-Tests, 872 Build-Verträge, 929 Android-Probe-Verträge und 52 Native-Modi und erzeugte eine signierte Family-Test-APK. Das echte Update 2017→2020 erhielt das eine geprüfte Kinderprofil und seine gespeicherten Ergebnisse über sechs Snapshots auf einem API-35-Emulator.

Die allgemeine Android-Tour bestand 21 Schritte ohne erfassten fatalen Absturz. Connect Four brach aber vor dem Spiel wegen des damals nicht erlaubten Qualitätszweigs ab: null Spielbeobachtungen, Übergänge und Rückgaben. Die abschließenden Freigabe- und Auslieferungsjobs wurden übersprungen. Originale sind im Evidence-Commit [6a5ae5327570fc60434672074f246c95e1c59283](https://github.com/Ullmann27/lumo-lernen/commit/6a5ae5327570fc60434672074f246c95e1c59283) erhalten. Diese alte APK enthält die neueren Korrekturen nicht.

Der separate Integrationslauf `43583493817` auf 32e7 scheiterte an einer von 938 Android-Probe-Vertragsprüfungen: Die Continue-Mock-Erwartung enthielt das erforderliche `standalone_caption=True` noch nicht. Das vollständige ursprüngliche Fehlerprotokoll und die korrigierte enge Erwartung bleiben gesichert.

## Noch erforderliche Auslieferung und Play-Abnahme

Den vollständigen Workflow auf dem exakten eingefrorenen PR-Kopf ausführen. Frische Flutter-/Native-/Android-Originale und das echte 2017-Update prüfen, die daraus gebaute signierte ARM64-APK samt Herkunft, Zertifikat, Größe und SHA-256 verifizieren und sämtliche Abschlussgates verlangen.

Der bestehende 2020-Workflow bereitet danach ein Actions-Auslieferungsartefakt vor. Die verfügbare GitHub-Anbindung stellt zurzeit keinen Weg für die Erstellung, den APK-Upload und die Veröffentlichung eines neuen öffentlichen Releases bereit; das lokale `gh` ist nicht angemeldet. Die alten Publisher sind an ihre historischen Kandidaten gebunden. Ihr Umnutzen ersetzt keinen berechtigten 2020-Upload. Der tatsächlich geprüfte Zugang und die Grenzen stehen in `docs/evidence/c4-delivery-access-review-20261114/review.json`. Ein geplanter Downloadpfad ist kein existierender öffentlicher APK-Link.

Der Play-AAB-Builder und seine Prüfungen sind vorhanden. Tatsächliche Play-Upload-Signierung, ein damit gebautes AAB und Play-Console-Abnahme fehlen. Die veröffentlichungsfähige Datenschutzerklärung und die Meldemöglichkeit für Online-KI-Inhalte benötigen noch die verifizierten Betreiber-, Kontakt- und Backend-Angaben. Für die Backend-Inspektion verlangt der Anbieter die ausdrückliche Auswahl eines Workspaces. Keine privaten Konto- oder Profildaten als öffentliche Kontaktdaten verwenden. Datenprüfung: `docs/evidence/play-data-audit-20261114-2708/`. Der belegte deutsche Store-Text liegt als unveröffentlichter Entwurf unter `docs/release/PLAY_STORE_LISTING_DE_2026-11-14.md`.

Physische Android-Bildraten, Frame-Pacing und thermisches Dauerverhalten sind ungemessen. Weder konstante 60 FPS, eine Nintendo-Freigabe noch Play-Store-Reife werden bescheinigt.

## Wiederaufnahme

Originalcode und Nachweise sind in Git gesichert. Lokale Änderungen vor jeder Aktualisierung prüfen und das vorgeschriebene Autosave ausführen. Aktuelle PR-/Run-Metadaten vor der Fortsetzung lesen. Die aktive Arbeit nutzt höchstens vier gleichzeitige Agenten in der bestehenden Hierarchie; die Rollenbeschreibung erzeugt keine unbegrenzten oder dauerhaften Hintergrundprozesse.

---

# Historical handoff before the current integration

The following earlier notes are retained as history. Older pins, pending-test statements and proposed actions below do not override the current source and results above.

## Earlier 803a quality candidate

## Gemeinsame frühere Projekthistorie


Active review: https://github.com/Ullmann27/lumo-lernen/pull/491
Working branch: `work/lumo-play-quality-20261114`.
Base review: PR485, `integration/lumo-c4-connections-20261114`.
Version remains `0.13.8+2020`. Integration base `729585db3f49ecff7f0632439f90edb882f09454`
is merged with the actual ancestry retained. Its native integration pin is
`0e26153f0e58cc05739e72923b4c563a4cf380b8`.
Main is protected.

## Implemented and independently checked

- Shape drawing uses the existing ink surface, keeps the primary pointer,
  does not scroll the parent, and drops cancelled unfinished strokes.
- Left navigation respects reduced-animation and calm settings. The recovered
  exact learning selector and the 7,552-sample / 236-family audit are preserved;
  this is structural sample evidence, not a curriculum-wide approval.
- Family and Play distribution are separated in Android metadata, updater
  behavior and signing preparation. The new local `scripts/build_play_bundle.sh`
  prepares a canonical, externally signed AAB and verifies the actual bundle.
- Connect Four's board and minimum-48dp controls share a horizontal viewport.
  Phone margins adapt before scrolling is necessary. Older Flutter-only tests
  now explicitly establish the unavailable-native-plugin boundary.
- The historical APK diagnostic uses a stable QA pin fixture while the actual
  production verifier still rejects a wrong native revision/repository.
- The scanner accurately describes on-device text recognition. Unsupported
  app-wide tracking/Families assertions are removed from its developer header.

Focused final evidence is in:
`docs/evidence/connect-four-scroll-20261114/` (15 tests, five real PNGs,
0 analyzer errors/warnings and ten unchanged informational diagnostics);
`docs/evidence/play-aab-local-20261114/` (52 tests run together by root);
and `docs/evidence/play-quality-20261114/ci-followup/` (19 diagnostic tests
after reproducing the original failure). Root opened all five final C4 images.
The small landscape scroll mask still clips some decorative edge pixels; the
actual board cells and controls remain visible.

The preserved source checkpoints are C4
`43d66732d9450657147fb9a12a7811121a9557dc` and Play
`864452466627b366bd67f53ce2d581a05897ed62`. Their real ancestry is retained
when combining the next candidate. Earlier shape/learning/distribution evidence
under the 2026-11-14 directories remains applicable only to its recorded scope.

## Integration merge verification

Checkpoint `c1fef2d548ceaf42ccde8c8d8553d81f8400c349`, tree
`a2c9c60f56d536241ccc6ac84d8bf90b26734044`, joins the previous quality
candidate `95f12c7173e6ee718b03dce67ca2d7c6543fe716` with integration
`729585db3f49ecff7f0632439f90edb882f09454`. The two add/add conflicts were
resolved by retaining the formatted audit and stronger current-grade negative
checks. The complete live-source learning audit, console/decoder repairs and
17-raster native contract remain mandatory; the two exact permitted branches
still share every source/run/PR-head gate.

On the committed merged source: 123 focused Python contract methods passed,
workflow actionlint passed, and actual Dart generation plus the production
output verifier checked 7,552 samples across all 236 selected families.
This was a local check, with no invented GitHub run binding. The first attempt
before local HEAD advanced correctly failed the immutable-helper check; its
raw failure is preserved alongside the successful committed-source run.
Evidence: `docs/evidence/quality-integration-20261114/`.

## Actual predecessor CI and the next candidate

Host `01575aafc3f5b9032900bb57520ee65e98d7546c`, run 43576227541,
passed Android host compilation and the actual Dart/rendered-Godot C4 job.
The native runtime reported 170 successful checks; root rechecked all 259
recorded image hashes and opened seven original screenshots. The complete
Flutter/capture suite passed 2,564 tests, with no failures, skips or capture
errors, and produced 546 PNGs. Root separately opened six actual Home,
Journal and handwriting originals; a missing glyph in the Schreibcoach
capture remains an explicitly bounded visual observation. All 872 build-contract
tests passed. The subsequent 928-test Android-probe regression failed with
11 errors: the historical 2019 test invoked the real wrapper against current
2020 configuration. APK build and actual Android acceptance were not reached.
These are partial results of that exact predecessor, not Android/APK approval
of this follow-up. Original artifact identities, the
unmodified Flutter summary and root observations are preserved under
`docs/evidence/quality-01575-ci-20261114/`.

The independent Astra run 43576227534 failed with one class-setup error in
its 868-test inventory because FFmpeg was absent. The repaired workflow
installs FFmpeg and explicitly verifies ffmpeg and ffprobe before retaining
the original complete MP4/test inventory. Actual decoded failure logs,
actionlint, shell syntax checks and eight existing contract tests are in
`docs/evidence/astra-ffmpeg-20261114/`.

The bounded Orange URL-builder repair removes the free-text fallback when
a recognized color also names a fruit. The identical seven tests gave five
passes and two failures on the original code, then seven passes with the fix.
Default online opt-in remains false. The independent review and raw logs are
under `docs/evidence/image-prompt-privacy-20261114-2708/` and
`docs/evidence/play-data-audit-20261114-2708/`.


The historical 2019 test now uses a temporary 2019 source fixture with the
byte-identical real wrapper and real reviewed-pin policy, preserving every
original artifact identity negative case. Two additional rejected configurations
exercise the actual entry point before a blocked runner. Production version and
pin guards remain unchanged. See `docs/evidence/studio-2019-fixture-20261114/`.


After the local environment returned, the exact repaired test blob was actually
executed with ten unchanged, blob-checked predecessor dependencies. All three
StudioUpdateWrapperExecutionTests passed in 0.043 seconds; the eleven source
blobs were identical before and after execution. This is a focused Python
fixture result, not Android acceptance; the original failed CI remains preserved.

The combined follow-up needs a fresh `lumo-connect-four-2020.yml` run on its
actual PR head. Retain all full Flutter, build-contract, native, APK,
Android-C4, 2017-to-2020 preservation and delivery-verifier gates. A green
checkpoint test or an older source's APK does not approve this candidate.

## Release items still requiring real evidence

No Play-upload-signed AAB was produced: authorized external upload signing
inputs were not supplied. The builder and validator are executable source,
not proof of Play acceptance, generated-APK runtime, download size or physical
16-KiB compatibility. See `docs/release/PLAY_AAB_LOCAL_BUILD_2026-11-14.md`.

The direct native child `0e26153f` already contains the narrow Treasure
visibility correction, the five-profile/ten-state regression and the strict
17-raster compatibility update. Independent exact-blob review found production
and regression byte-identical to the separately tested port. The old source
failed 40 of 3,221 headless checks; the corrected source passed all 3,341.
Two local X11 attempts ended with SIGKILL before producing PNGs, so no local
render approval is claimed. The actual full 52-mode rendered CI gate is still
required. Directly replacing integration with PR167's divergent `785413d3`
would lose modules; its whole tree was not substituted.


The bounded data/SDK review at the exact predecessor is preserved under
`docs/evidence/play-data-audit-20261114-2708/`. It identifies the missing full
in-app privacy disclosure and content-reporting route, plus unverified actual
operator/hosting/retention facts. Prepared manifests and static SDK inspection
are not final AAB/network evidence. The local environment disconnected during
final evidence collection; the report explicitly lists missing raw outputs.

Actual child-data/backend disclosures, Play Console declarations, signed AAB
testing, and physical device frame-rate/thermal measurements remain separate
acceptance work. No Google Play publication or Nintendo-level performance is
claimed by this source checkpoint.

The delegated work used a coordinator, a release lead, a specialist and its
review worker within four concurrent sessions total. Recover work from the
published branches and immutable evidence; role files alone do not launch
persistent workers.

Earlier notes below are retained as historical context, not current approval.

---


## Bewahrter Stand des Integrationszweigs vor dieser Zusammenführung

# Diktat progress fixture repaired and checked — 2026-11-14

This documentation/evidence-only activation follows Host
`cfa4725263f15e9cc3f75d8f6dfae0949fbb86ab`, tree
`d0fedc2ceeb02e7eefea61b2667195a43f14bdf6`. The sole executable delta from
Host79c7 is the existing Diktat progress test helper: it now selects the actual
four `LumoInkSurface` rows inside the actual `WortDiktatScreen`, makes the first
row visible and performs the unchanged real drag/Fertig/self-rating flow.
All original test bodies and progress, persistence and bonus assertions remain
byte-identical. No product, Writer, InkSurface, Journal or child-data code changed.

The complete existing test file ran exactly once on cfa4725: **17 PASS,
0 failures, 0 skips, exit 0**, in 59.552 seconds with the existing locked packages
and `--no-pub`. The original machine stream ends with success=true. All 4,475
index entries, 2,342 materialized files, HEAD/tree, raw index and package inputs
are unchanged. Full original evidence and the independent source review are in
[the Diktat acceptance pack](docs/evidence/host-diktat-acceptance-20261114/).

Both earlier complete C4 Flutter results remain failures: Host37ec recorded
2,605 passes and the three obsolete-finder errors before its later cancellation;
Host79c7 run43603036260 ended FAILURE at 14:23:35 UTC with the same 2,605
passes, three errors and zero skips. These are not runtime-product successes
and are not relabelled by this focused repair. The full pipeline must now
run on this exact successor, with its own attempt and original artifacts.

The fixed Native source remains
`baf148b03a7a32c6ad9f737d731f900eb9113ea1`. Its separate original Native run
43600806315/attempt1/job132464933411 succeeded: 47 Python methods, four
headless groups, Dream5/7/2, Discovery10/38/2, Village339/42/46 and rendered
Mobile428 with 4 safe-area plus 9 minimap PNGs. All 60 PNGs were technically
decoded; Root directly inspected exactly the 15 new Village/Mobile/Minimap
images. This does not claim Android, device FPS or a full Host acceptance.
[Native result and Root observations](docs/evidence/host-diktat-acceptance-20261114/native-handoff.json).

Outer Host/Android budgets remain **150/80 minutes**; every inner deadline,
release verifier and historical pin is unchanged. PR485 is still the integration
candidate. The separate publisher is preserved on
`integration/lumo-c4-publisher-20261114` at 72143d3586109967773d6442072d486c11dc1449;
its actual source9799d1d passed 32 isolated contracts once, without any live
release operation. Publication requires a complete successful new seven-job
C4 run, the authenticated prepared bundle and verified public APK bytes.

## Preserved preceding activation and evidence records

# Activate the verified complete-build budget

This documentation/evidence-only activation follows published Host
`c77e2456ac8eb7e02a9950e7b764684da6f5eb7b`, tree
`d124623c936de7d2fe142a22c2683dfbb1343ac2`. Its actual single Delivery
regression invocation passed all **71 methods**, with exit 0 and no failures,
errors or skips. One Actionlint invocation passed the exact changed workflow.
All 4,460 index paths, 749 materialized sources, HEAD, tree, raw index and
Git status remained unchanged. Full original streams, invocation and inventories
are preserved in [the actual validation pack](docs/evidence/host-budget150-acceptance-20261114/).

The effective outer Host build/Android budgets are **150/80 minutes**.
Individual probes, exact Native pin, every runtime/product file and all
release verifiers are unchanged by this activation. The actual complete
C4 workflow must bind this successor, its attempt and original artifacts.
Previous run 43601673844 remains bound to Host37ec; its successful Runtime
and Android compile do not substitute for this new source run.

## Preserved correction and preceding activation records

# Current build-budget correction — 2026-11-14

This narrowly scoped successor follows Host
`37ec6c6aee67c31ce16550cd59d616c80e80e305`, tree
`6ab0e6cafc9fb37d3b3d95d76805aff4b6810d7a`. Its unchanged Native pin is
`baf148b03a7a32c6ad9f737d731f900eb9113ea1`. The current outer Host build
budget is **150 minutes**; the Android budget remains **80 minutes**.
Every individual probe limit, required gate, source/PR binding, signature
policy and publication check remains unchanged. Only one workflow value
and its two existing Delivery-test expectations change.

The reason is original predecessor run 43590864772, job 132436033818:
the service recorded a 90-minute whole-job timeout during APK construction.
Its original API timeline shows 22m06 before Native, 64m07 for the Native
step and 1m17 for Dream. The current integration also includes the additional
Discovery stage (19m05 actually observed on c300). The new outer limit leaves
reserve for the real APK build, verification, upload and runner variation.
Root read the original API and the separately published timeout observation;
no current-candidate timeout or new Android success is claimed.

The 37ec run 43601673844 belongs to the previous source, even though its
Runtime and Android-compile stages completed successfully. The corrected
successor requires its own exact-source complete workflow. Local verification
of the budget correction follows its published source checkpoint. Originals:
[`docs/evidence/host-build-budget150-20261114/`](docs/evidence/host-build-budget150-20261114/).

## Previous activation notes retained verbatim

The following 120-minute references describe the preceding activation and
are superseded only by the current outer build budget stated above.

# Continue the combined 2020 acceptance

Updated: 2026-11-14. Documentation activation base:
Host 68f86b7dafa2dcd1e42ee019c4be46b9e9bdc697 /
tree ecd5df0797c2b4102f2c7bbc30146f3061d713ce.
Its exact configured Native source is
baf148b03a7a32c6ad9f737d731f900eb9113ea1 /
tree 0c18a0ca5200ade267cfedb4c12d5c4b0a761a00.
Version remains 0.13.8+2020. Bind the subsequent actual workflow to its
own final Host SHA; this documentation-only commit adds no feature,
workflow or pin change.

Native run 43600806315, attempt 1, job 132464933411 is still in progress
in the recorded activation handoff. Its final renderer acceptance is open.
The original Actionlint/Mobile380 results belong to parent
4d2cbb6ea235c7bf519aa5f3873a16f6b177be2b and unchanged product/workflow
blobs, not a completed new Native or Android run.

## Final pin check before activation

On published Host 68f86b7dafa2dcd1e42ee019c4be46b9e9bdc697 with Native
baf148b03a7a32c6ad9f737d731f900eb9113ea1, one actual local invocation
passed all 64 existing pin contracts (24 Candidate and 40 Legacy), with
exit 0 and zero errors, failures or skips. All 4,440 index paths and all
seven required materialized original sources remained unchanged; the other
4,433 index paths were explicitly sparse-absent. Complete original streams,
invocation, preparation and before/after source inventories are preserved in
[the activation evidence](docs/evidence/host-final-activation-20261114/).
This is local pin acceptance only; the complete new Android workflow remains required.

## Resume the fixed candidate

Keep the activation's exact Host source and configured Native pin fixed while
its complete C4 workflow runs. Main, historical releases and producer branches
remain unchanged. This candidate introduces no further feature work after
activation; new producer deltas belong in separate review packs.

1. Bind the actual workflow run to its Host SHA/tree, configured Native SHA,
   attempt and original job/artifact metadata. A successful predecessor or
   local test run cannot supply a missing current-source gate.
2. Require genuine runtime/compile and full build acceptance, including the
   exact-topic Math contract, every enabled Flutter capture without skips,
   the current-grade curriculum audit, complete script/Android QA contracts,
   52 native modes / 17 rasters, Dream and Discovery 10/38/2.
3. Use the same verified candidate APK for the actual API35 main tour, C4 and
   Village. Preserve package/version/signature/ABI/APK/PCK/source identities,
   original screenshots/OCR/TSV/logs and the learning/profile comparisons.
   Village must actually enter the settlement and return to Flutter with the
   existing ownership/save/acknowledgement checks. C4 must observe Flutter
   games after the single leave action and retain its two fresh portal reads.
4. Require the real in-place 2017-to-2020 preservation job and the final
   candidate verifier. Keep individual probe deadlines, original error gates
   and no-skip policy. The 120-minute build and 80-minute Android outer
   budgets do not extend a local input, arrival or observation deadline.
5. Require the read-only delivery verifier and its complete original evidence
   bundle. The existing C4 delivery step prepares a bundle without publishing
   a release. Do not present an APK link as accepted before the exact
   current-source build, Android, update and delivery gates are complete.

## Evidence already completed

The following results are complete on their named sources and do not need
optional broad local repetition merely for this activation:

- 0411b62f59425bc4f36226ca59e9ed5ef901709a: 88 Pipeline/Delivery methods,
  zero skips, and C4 Actionlint. Original result:
  docs/evidence/math-pr491-source-20261114/host0411-validation-result.json.
- bb97ab6b2e563f3662f1ce5e6141e95cf62d79a7: actual old-0411 Math RED
  (three known failures), current Dart GREEN (29,845 checks, 3,955 template
  calls, 4,640 factory calls), and strict official Flutter 3.44.9 / Dart 3.12.2
  pub resolution with unchanged pubspec/lock.
- The same bb97: exactly nine focused Flutter methods, zero failures/skips,
  actual exit 0 in 22.867 seconds; Math 1 plus Village routing 2 and captures 6.
  All 2,327 materialized source files, 4,383 logical index paths, HEAD/tree,
  index bytes and empty status remained unchanged. The optional Feature22
  suite was not rerun.
- a8a9b84cffd9819d4c8c2dddb55e870f448a9f13: 70 Kart/Garage/Driver/Readiness
  methods, zero skips, and a separate actual old-source Boru callback RED.
  Original result:
  docs/evidence/c4-return-navigation-source-20261114/kart-a8a9-validation-result.json.
- adb88bef880861e23b451166c04ee7d28c96a95d: 36 C4 Evidence/Deadline/
  Navigation methods, zero skips. The single leave action, 30-second Flutter
  return observation, global 900-second limit and late-arrival rejection remain.

The newer compact proofs are under
docs/evidence/host-focused-acceptance-20261114/:
math-dart-pub-originals.tar.gz, math-village-widget-originals.tar.gz,
c4-navigation-originals.tar.gz, their summaries/handoffs, capture inventory
and separate visual/source reviews. Their original bytes and source bindings
are preserved. The widget archive keeps the first adapter failure with its
unknown child exit separately from the successful authorized follow-up.

All six Village PNGs were actually inspected. Dorfwirtschaft remains fully
visible and separate from Bauwelt; wide layouts retain the fox/action area,
and large text changes the grid without clipping the Village title. Some
lower content continues outside the viewport. Static images and mocked-bridge
widget tests do not prove Android input, native return, audible speech,
screenreader behavior or physical-device performance.

## Historical failure remains authoritative

Run 43589206933 is an Android-failed, unpublished predecessor. Its original
Boru/garage evidence is the basis for the bounded word-recovery repair; the
new local 70-method result does not turn that historical run green. Keep its
logs, artifacts, first failures and unexecuted downstream stages unchanged.

Do not reuse old APKs, old receipts or historical runtime successes as the
acceptance of the newly activated combination. Keep later device observations
and any remaining repair work explicitly tied to their actual APK and probe
sources.

## Preserved historical CONTINUE

The complete original CONTINUE.md begins below, byte-for-byte unchanged.
Its previous tools, branches, pins and pending work are historical context;
the activation and source-bound requirements above govern this candidate.

---

# Integration follow-up: repair the real Android Cup selector

Updated: 2026-11-13. This follows published Host51e92fb5/treea13ab981.
Its immutable run43502594333 completed with successful Android Host compile,
APK build,2512 Flutter tests,472 build contracts and812 Android-probe contracts
without skips. API35, API37 and2017→2019 Update then failed on the same
ambiguous Cup-caption target. Final Verify and Publisher correctly skipped.

The current patch changes only the Cup matcher in the shared QA helper, plus
seven focused tests and six exact original OCR/readiness fixtures with manifest.
The matcher keeps decorative symbols instead of promoting '= Grand Prix' into
a second real target. Existing geometry/IoU, two-frame stability, image hashes,
actual race mode, progress and pause requirements remain. Twelve focused
methods pass; original red cases remain archived. Root directly inspected the
original API35 landing image; independent Native/source/fixture review passed.

API37 SDK/CLI22/AVD/framework preparation genuinely passed. Initial actual
2017→2019 install-r/offline learning preservation passed, but later Kart/restart/
Fold checks were not reached; two older baseline language-navigation failures
also remain explicit. New Cards lifecycle runtime acceptance was not reached.
None of these partial results make the original Android run green.

Native993c, all three2019 pins, both current visual receipts, original2018
receipt, version0.13.7+2019, product code and workflow gates are unchanged.
This repaired integration source needs its own fresh required PR CI.

The completed51e auxiliary and bounded recent-work review were copied byte-exact
from the separate published evidence checkpoint. All current failure and repair
proofs are under docs/evidence/integration-20261113/host-51e-*.

Separate DraftPR474 (QA6dcc5f5d/tree5b48c96a) runs additional creative controls
against the unchanged51e APK. Its actual push run43513179062 started; the last
observed21:48 status was in progress. Its APK source must never be confused
with its QA source or any new integration source. Await the actual result and
direct Jump-video review before making gameplay claims.

Earlier integration context below is retained as historical evidence.

---

# Continue combined LUMO integration / candidate 2019

Active drafts: Native PR160 and Host PR465. This follow-up builds on published
Host 38a49f7dda404923da3955592ccb213871f2027d, tree
625b7940d9e8a4ddf32203126721efd97b3e8c2e (local twin 44dfd78d).
It selectively connects Producer318 Cards lifecycle and Android17 preparation,
and repairs the scroll assertion found by the actual 38a CI. Native source 993c,
all three 2019 pins, both current visual receipts, version 0.13.7+2019 and the
original 2018 receipt remain unchanged. Root publishes the exact new tree with
expected parent 38a49f7d; after publication, any later update must use the
actually observed current head. Android acceptance belongs to that new source.

## Current published-producer connection and prior Host CI

Producer PR466 was read at 20:04:08 UTC at
31883868bac56699dbf3b3d60a7cdb7afc496a8b, tree
5ca2eeee9ea3af3f67acbee83f19934942c1c5d5. Only its missing Cards lifecycle and
API37 preparation are connected. The current final-scroll helper and historical
APK verifier already matched. Producer pin/receipt/profile substitutions,
older workflow guards and relative Native Venv were not imported.

The Cards main-looper heartbeat renews every 500 ms only with visible Activity
and actual service authority. Pause, stop, return, destruction or lost authority
end it; stale callbacks cannot restart it. Render reads do not renew the lease.
The existing complete window and Learning/Build speech blocks are preserved.
Bounded lifecycle observations retain the original state result or exception;
they cannot replace any original Cards readiness or pixel gate. The corrected
delayed-engine fixture tests actual onStart and service binding before allowing
an active pulse. Final Cards evidence is 20 JVM/window/return plus 12 diagnostic
contracts, all passing without skips, with the original behavioral reds retained.

Both 2019 workflows modify only android-tour. API35 uses exact upstream action
a421e43855164a8197daf9d8d40fe71c6996bb0d; API37 uses that same checkout with
the reviewed additive guard immediately after the original boot-property wait.
The action's original keyevent, settings and cleanup remain. Official CLI22 ZIP
and installed files are hash-bound; original and newly generated AVD settings
are recorded. Actual API37/Android17 framework services and stable system_server
must pass before the unchanged candidate probes. The original state/disk/image
files are observed, never rewritten as a repair. Exact source and APK binding,
failure diagnostics, numeric API35/API37 measurements and separate artifacts
remain mandatory. Local 42 API37/delivery contracts and both actionlint checks
pass; the old workflows first failed the missing connection tests. This is not
an actual local SDK installation, boot or device-performance result.

The old default-scroll assertion now checks 24 gestures, 13 observations in each
direction and both final view positions. Seven existing voice/return and six
final-scroll cases pass, with the actual original 26-versus-24 failure retained.
No product scroll budget was increased. These 87 focused methods are disjoint;
their original logs and source bindings live in host-318-connection, while the
scroll-specific original repair is also retained in host-38a-auxiliary.

Original Host run 43497829121 is FAILURE on 38a49f7d. Compile job 132135471404
genuinely passed (actual AAR4.6.3 and nine required JVM classes). Build job
132135471868 passed its complete 2,512-test Flutter suite without skips, then
failed exactly one of 436 script tests: the obsolete scroll assertion. There
was no APK build, emulator tour or update test; dependent jobs skipped.
Auxiliary CI separately has eight current SUCCESS workflows, one Script-Recovery
FAILURE on that same assertion, eight expected historical SKIPs and two replaced
Change-Review CANCELLED runs. The two successful auxiliary full Flutter runs each
have 2,316 passes and 196 skips; analyzers retain 103 infos and five warnings.
Full original logs/metadata, exact failure and artifact identities are preserved
under host-38a-android and host-38a-auxiliary. No prior-source green is transferred
to the new candidate.

## Current Native source and finished gates

Native PR160 and its integration ref now point to
`993c145304c3e5f8aa947e1c7a949a8ef8685415`, Tree
`f13dd5fc5540ecb7705c5f18bf3cf8ba6e79d7a6`. Root's local Native twin is
`3497fc3cf9c3100ceb05f86c834f1668422d2dd8`.

All thirteen auxiliary workflows and all fourteen original job logs are now
clean on this exact source. The 158 successful steps and two expected
complementary Lifecycle-matrix skips are recorded separately. The repaired
Geometry run 43489950863 / job 132108137506 passed all five workflow counterchecks
and genuine import/geometry execution. Its original log ZIP 14069312290 has
SHA256 `e0719fa627076fe6034d7e902e5cadf28a9328341ec1df893619cde5843e18b7`.
Direct Head and PR-merge checkout 80f93e52 have the same exact source tree.
Original logs, metadata, source bytes and the actual new result are preserved
under `docs/evidence/integration-20261113/native-993c-auxiliary/`.

Graphics run 43489950655 completed all three jobs successfully. Three new
original archives, 62 fully decoded PNGs (36 current, 26 baseline), 40 clean
artifact logs and their source/ZIP/image bindings are preserved under
`docs/evidence/integration-20261113/native-993c-graphics/`. Root directly
opened the five current required originals, including wide/portrait Home.
The final review SHA256 is
`2c383d58a58fed9b97c857ff88bf6f97c32ceda55baa6f9606b5a62fe503f293`;
the prepared selection is
`8d2ab7a70941b1567a4f946e4c7395fffd69d4e4b73a34daf1368737544f9e90`.
The current Graphics receipt was produced by the existing recorder from these
three original ZIPs and five actual Root observations. Its SHA256 is
7b92eef83695cd35f1712b4095a6389e4d661eeabe5bf9ed03d8c0304608170a.

Nextgen run 43489950659 completed all eight jobs successfully at 19:42:56 UTC.
Original bundle 14072020645 contains 176,663,366 bytes; SHA256:
69b9112e524a6e204d8504c787768513e57e2c59a236d1488b8d6ec4e49cada0.
The unchanged frozen Host 2fa parser passes 43 Core / 24 Studio / 4 Village /
6 Puzzle-menu / 6 Touch pairs plus 32 Touch images. All four source trees are
f13dd5fc. The complete bundle contains 146 decoded PNGs (136 current, 10 baseline)
and 108 clean artifact logs. All eight full original job logs are retained.
Release 444662111 / asset 744941184 has the same exact source and ZIP digest;
the original archive job downloaded the public bytes and compared them with cmp.

Root directly opened all 19 selected Worlds originals and three selected Touch
originals. The resulting 22-image review covers nine distinct production families,
three Touch groups, all four Village states and all six Puzzle-menu states.
The separate final byte-binding record has SHA256
feff0b8174365f97088729233fb656aa9cd7f47c4c94f8923eb93187c2cbbf96.
Actual overflow, wrapping and ellipsized labels remain in the findings; static
review does not claim natural input or device performance. The existing Native
recorder produced config/nextgen-2019-visual-review.json with SHA256
1ed85c672b956792498ab3cf3948dab0bc0417ccb071e13c51ef2f1840c78943.
Complete original metadata/logs/indices and Root observations are preserved in
native-993c-nextgen. Both current receipts approve precisely 993c; no older
source or review is silently substituted.

## Geometry defect and historical correction

The prior 90d and cce original geometry jobs reported success and a positive
marker despite eleven real Parse/Compile errors. Their manually copied fixture
omitted four existing transitive source files; a nonterminal inverted grep
failed to stop the shell before the later positive marker. Historical green
API states are not reinterpreted as clean geometry proof.

The published 993c fix adds the complete unchanged 15-file dependency closure
and runs both genuine engine phases through the unchanged strict runner, with
original 120-second limits and success marker. The actual local old fixture
faithfully reproduces Exit 0 plus the marker despite eleven errors; the repaired
fixture runs cleanly in 9.697 seconds. Five synthetic counterchecks, actionlint
and an independent 18-source review support the narrow fix. The final trigger
change preserves the actually executed engine block byte-for-byte. The new
published CI confirmation above is a separate, genuine success.

The fully completed prior 90d Nextgen run 43483977169 retains its own exact
43 Core / 24 Studio / 4 Village / 6 Puzzle / 6 Touch pairs + 32 Touch-PNG contract.
Original bundle 14069131343 has 176,564,239 bytes and SHA256
`744949fb597d7a7f9442db0cee16740f241adcee3c515f6fd4154ebd2dec6800`.
All eight full job logs, frozen Host 2fa parser, complete indices, release/tag
bindings, all non-ZIP metadata and 268 original artifact-log members are now
preserved losslessly in `native-90d-checkpoint/`. Its original 146 PNGs include
136 current and 10 baseline frames. Root opened six Puzzle originals at that
source, explicitly documenting compact scrolling. That predecessor proof does
not approve 993c; its separate geometry defect still prevents overall acceptance.

## Host code repairs and scoped validation

The published Host 5d44 source connects the exact final-scroll observation,
SDK37.0 package selector for numeric API37 and absolute Native Python Venv.
The actual API37/Android17 measurement, version, identities and publish guards
remain. Six Scroll, 25 workflow/platform and 126 Android-neighbour methods pass:
157 disjoint focused methods, no errors or skips; both workflows pass actionlint.
All 1,853 bound paths stayed unchanged during the tests. Original producer
failures, stable SDK catalogs, Action implementation, local red/green logs and
independent source review remain under `host-2019-readiness/`.

The prior 2fa/851554 checkpoint retains its full 434 Script and 794 Android-QA
results with 1,246 unchanged bound paths. Original missing-Gradle diagnostics
and inherited ResourceWarnings remain preserved. No full-suite rerun or
Android execution is inferred from the current documentation/evidence update.
The original handwriting trainer, journal, child saves and game product paths
remain. The unchanged Flutter runtime retains its earlier scoped 55 checks.

Historical APK expectations remain bound to four explicit immutable Git blobs
with replacement objects disabled, while current signature/ABI/voice/PCK checks
stay enforced. The additive 2017-to-2020 wrapper retains strictly typed exclusive
opt-in; existing 2018/2019 behavior remains and the actual 2020 release pin stays
unapproved. No whole older Collector branch is substituted for stronger gates.

## Complete the actual Android connection

All three 2019 pins now identify 993c145304c3e5f8aa947e1c7a949a8ef8685415.
The actual verify_kart_graphics_delivery.verify_visual_acceptance call passed
with both current receipts, original workflow metadata and the original complete
Native ZIP. The strict pin CLI and 63 current/historical pin regressions also
passed with no errors or skips. Exact commands, original logs, source identities
and preserved-path verification are retained under host-993c-connection.
No unchanged full-suite or Android run is inferred from these focused results.

Publish the exact final Host tree to PR465 using the observed expected head, then
observe LUMO Kart graphics 2019 Android candidate on that actual Host SHA.
Required jobs are android-host-compile, verify-and-build, both android-tour
matrix jobs (actual API35 and API37/Android17), update-2019-from-2017 and
verify-reviewed-2019. ARM64/x86 APK bytes, signature, native PCK, source identity
and real 2017-to-2019 learning-state preservation must agree across their proofs.
The integration PR permits the internal completion job. A workflow_dispatch
would skip that PR-exclusive completion job, so it is not an equivalent path.
publish-reviewed-2019 requires the separate producer branch and remains skipped
on integration/lumo-connections-20261113. No APK publication is authorized here.

Main, live Host PR461 and producer dirty worktrees stay protected. Root alone
stages/commits and moves its own refs. No unattended automation is enabled.
The 20:04:08 UTC Producer check found new source only in Host PR466 (31883868).
Native 158/165 and Host 468/469 stayed at their previously reviewed heads;
newer metadata timestamps were not treated as new source work.

## Historical published graphics producer handoff

The following original producer notes are preserved as history. They do not
replace the active combined integration source, acceptance or publication scope.

The current isolated host branch is `chatgpt/lumo-kart-graphics-apk-20261113`,
based on PR #461 recovery `8eab228433f124c1e2332e3d3c2ecf462ec8b136`.
Native changes are in PR #159, `chatgpt/lumo-graphics-expansion-20261113`, based
on PR #157 source `ada5ed81ad62339f15289da62670c0a4f9f7f2b9`.
The historical 2018 notes below are retained as history, not current delivery
approval. Main and previous releases remain untouched.

1. Check the actual branch/PR heads and dirty workspaces before continuing.
   Existing concurrent worktrees are not disposal candidates. Save through the
   authorized GitHub connector with exact-tree checks and expected-SHA leases;
   do not reset, force push or depend on an unavailable authenticated CLI push.
2. Read `docs/KART_GRAPHICS_2019_QA.md` and
   `docs/KART_GRAPHICS_2019_DELIVERY.md`. The final native candidate is
   `25e3a1187234860414fa69822e7b301e75880c82`, tree
   `71b52d8ab5b14a36cb50c4dc1164ee347bd7d9b8`, graphics run `43445815461`.
   Its product files are byte-identical to `ea72b244`: only editor-import
   invocation in the graphics workflow changed. On the previous run
   `43441307548`, Worlds and Feedback succeeded; Root and their module agents opened all six
   current images in each area. Their verified original bytes are preserved in
   `docs/evidence/kart-graphics-2019-reviewed/`. The current Home capture and all
   seven new/preserved Home gates passed, but attempt 1's old-source importer
   segfaulted (exit 139). Its failure excerpt is preserved. The exact failed
   Home job failed a second time on the same old-source import. Both excerpts
   and two successful isolated full local imports are preserved. The new CI
   invocation isolates XDG before import and uses the complete --import exit
   instead of --quit. This is not a proven native crash diagnosis. The entire
   new run must pass; preserved ea72 evidence cannot approve the new source.
   No final visual receipt or 2019 APK is approved.
3. Native corrections include physical menu preview resolution, ground-connected
   winter stations with exact obstruction checks, live vehicle-effect rebinding,
   and the actual Cards header safe-area defect found in the 2018 Android tour.
   The 2018 tour's repeated Pause OCR rejection must not be hidden by relaxing
   OCR, card-face pixel, same-revision, two-frame or timeout gates.
4. Version, native config, the additive `APPROVED[2019]` entry and current-candidate
   tests now bind 0.13.7+2019 to the exact native candidate. The 24 pin-policy
   tests pass. This source identity decision follows actual current-image review
   and does not replace full workflow acceptance. After the retry and all three
   final native jobs succeed, create the dated receipt with original
   logs/PNGs/API metadata. Preserve every historical pin and the 2018 workflow,
   receipt and publisher. Recheck PR #461 for concurrent recovery before the
   final host PR. The dedicated 2019 internal PR workflow builds fresh signed
   ARM64/x86 APKs and performs the full Android tour and real 2017-to-2019 update.
5. Complete actual Android acceptance and immutable public publication. Verify
   the direct HTTPS APK bytes, signature, source identity, size and SHA-256
   before returning a link. An earlier APK or desktop image review cannot stand
   in for this candidate. Physical Fold7/Android17 performance, thermal behavior,
   audible speech and input latency remain outside emulator proof.

## Historical Next Generation / candidate 2018 handoff

Current work is on `chatgpt/lumo-nextgen-20261113`, host PR #461 and native PR #157. Do not switch back to the previous 2017 branch or replace the current dirty workspace. Main remains unchanged.

Verified starting points are host `47889f74a651b073965def70743417cf320b1eb9` (PR #459) and Godot `1d5c5cb45a323228f627ec529e6ff1ddd86f1c57` (PR #156). The real 2017 public APK now exists; PR #460 recovered publication only. It is an update baseline, never the new deliverable.

1. Inspect the actual current PR heads before continuing. Connector commits and the local base HEAD differ: no unauthenticated CLI push, automatic watcher, reset or checkout while this shared workspace contains coordinated changes. Use explicit connector trees/commits and expected-SHA ref updates.
2. Read `docs/NEXTGEN_AUDIT_20261113.md`, `docs/NEXTGEN_QA_2018.md`, the module reports, and current CI logs. Implemented learning includes seven genuine native concepts, same-task assistance, local speech integration, assisted-versus-independent evidence, and explicit reading-comprehension assessment. Games include original-Lumo Jump controls/expeditions, city economy and AI, actual Cards room/cup, garage goals and Rhythm tour. The entire master request is not declared complete.
3. Current native candidate is `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`. Earlier `e181eeca2b33390c15c1c13a8ac6eb5924fb620d` passed legacy gameplay and 24/25 new gates; the learning capture hit its 420-second software-render timeout. Its independent preview produced 21 genuine PNGs, all inspected. The runner now allows 900 seconds only for that capture. `cc6e95a9bb5f49b70758f6d749cec1504c986fcb` also passed its independent learning preview, but Root found a real plant heading/explanation mismatch in the image. The new real-touch regression additionally exposed a locked-button restart error. Both are fixed in `51fb026`: 5328 actual native learning checks pass; final native approval is recorded in item 5, and Android acceptance remains item 6. Earlier successful images never approve a corrected source automatically.
4. Host product checkpoint `bf695de27f87fca592f6fe46ebc57119a0ea6c0a` passed the complete local Flutter suite: 2462 tests, zero failed/skipped, 542 PNGs, all 47 changed Dart source/test hashes unchanged through the run. Evidence is under `docs/evidence/nextgen-cards-header-20261113/`. Full analysis exits 0 with no errors, 5 warnings and 103 information findings. Host `8a228c53c342675fd89b6ab9b662d40fb60a8535` passed actual Kotlin/Java compilation, including nine required classes; that remains historical compile evidence and the final release must compile again. Real Android speech, IPC, APK gameplay and update acceptance are not yet established.
5. Final native `51fb026f0b0e7a43b3aad30cc0fcdc144050c724` now passes all 14 workflows, including complete Nextgen run `43365141980` (all three jobs successful, all 25 new gates PASS). Native artifact `14010558382` is SHA-256 `84a71c209c7f01015b2dd1735d27087c40b2ed37fb022c406b959128d5e0bb4c`. All 66 current original images are covered by actual final module reviews and explicitly recorded byte-identical comparisons with previously inspected originals; both corrected plant images and portrait math were opened again. The genuine source-bound receipt is now approved in `config/nextgen-2018-visual-review.json`; selected originals, raw metadata, logs, metrics and reviews are under `docs/evidence/nextgen-2018-reviewed/`. No image-generation output is accepted as renderer evidence.
6. Candidate version remains 0.13.6+2018 with exact native pin `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`; historical pins remain unchanged. Both 8f2925b2 runs `43368260144`/`43368257044` compiled signed APKs and passed the original 21-check Android tour, but FAILED the new probe at the collapsed learning-tools entry. They did not run upgrade/publication. A separate real 4-case router reproduction also proved that generic native returns removed the originating Guided/Cards route. **Do not release or reuse that APK as an accepted candidate.** The original failure, raw logs and exact test are secured in checkpoint `ce2a3c0289800a93b760adbf2f403b56fd5e27c9`.
   The current repair introduces live caller-session ownership in the three existing Android host templates, preserves durable cold/legacy navigation and rewards, fixes actual tools/course navigation and retained-scroll assertions, and makes Cards readiness follow current heartbeat/revision evidence. PR synchronization is now the single automatic APK event; the historical Unified workflow rejects build 2018. Local repair acceptance: 31 Flutter route/service tests, 21 Kotlin/store/installer checks, all 304 build contracts and all 684 Android-probe contracts PASS; no skipped tests. See `docs/qa/2026-11-13-build2018-recovery.md` and its linked raw evidence. No Dart production, native source, version or child-data migration changed in this repair.
   The full workflow `.github/workflows/lumo-nextgen-2018.yml` must now pass on this actual repaired host commit: full Flutter/native gates, fresh signed ARM64/x86 APKs, live Android learning/Cards actions and speech, original game tour, in-place 2017-to-2018 update and public download verification. Use the matching internal PR run; a manual run does not publish. Speech requires real local MediaPlayer start/completion offline; the emulator's `-noaudio` does not establish audible quality or mouth synchrony. Never replace these pending gates with the old candidate's results.
7. The repository owner's existing instruction authorizes an immutable public test APK without another question. Enable the prepared publication job only after its concrete source/visual prerequisites are met; downstream actual build/tour/update/signature/provenance gates still apply. Verify release bytes, file size, signing certificate and SHA-256 before returning the direct HTTPS APK URL. Do not publish or present a failed/unverified candidate as successful.

Local toolchain: Flutter/Dart under `/workspace/scratch/e0abce7d2838/toolchain/flutter/bin`, Godot 4.6.3, Gradle 9.1.0. Original assets and child data must be preserved. There is no connected physical Galaxy Z Fold7: no desktop/emulator result establishes 60 FPS, thermal behavior or physical input latency on Android 17.
