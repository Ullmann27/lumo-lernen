# Aktueller Stand: APK 2032 veröffentlicht, gezielter Nachlauf läuft

Stand **16.11.2026 10:59 UTC**. APK-Quelle **9b38360ca5f21919dce4a2b99e605ee39bbbf454**, Native **9d6ef1d704a0e54098a8f8f0818f36deae0e3789**. Vollständiger Run **43837592237**, Versuch **2 SUCCESS**, Android **133221738048 SUCCESS**, Publisher **133238196787 SUCCESS**. Früherer Androidjob **133211685356 FAIL** bleibt unverändert erhalten.

[**Direkte ARM64-APK 0.13.20+2032**](https://github.com/Ullmann27/lumo-lernen/releases/download/lumo-nextgen-learning-0.13.20-2032/Lumo-Lernen-Neu-0.13.20-2032.apk): **535.026.462 Bytes**, SHA-256 **cfa6709547ed82ffe6f081568c3bc454e1cc41afbfea2ecf9c85f534a6ea42de**. Vollständiger anonymer HTTP-200-Download im Publisher am **10:33:37 UTC** geprüft; tatsächliches Release **446893589**, APK-Asset **754429456**. [Publikationsbelege](docs/nextgen/evidence/ci-2032-publication-verified/README.md).

Aktuelle Lerntour und Referenztour **PASS_WITH_LIMITATIONS**. Der aktive native Stopp ist mit echtem Tap, aktiver ID13/PID10808 und 13,578s Nachfenster belegt. Muster-Core-Abgabe dagegen **NOT_EXERCISED**: zeilenexakte Überschrift im mehrzeiligen ImageView-Label wird vom alten Ganzfeldselektor nicht erkannt. Aktuelle Performance **47 Samples**, **823,183787ms / 1,214795548Hz**, Software-Emulator; kein 60-FPS- oder physischer Gerätebeleg. [Originale](docs/nextgen/evidence/ci-2032-android-complete-verified/README.md), [aktueller Lieferbericht](docs/nextgen/ANDROID_DELIVERY_2032.md).

**Aktueller Zusatzlauf:** [43853317375](https://github.com/Ullmann27/lumo-lernen/actions/runs/43853317375), Versuch 1, Job **133251156609**, tatsächlich seit **10:56:42 UTC IN_PROGRESS**. QA-Branch `qa/lumo-nextgen-2032-runtime-cases-20261116`, Commit **ce8458e88d16e7c3b97fafcf34c4d29b0c1d9fdc**, Tree **24b83e7f0464a344bdfab26565856a368f841ff3**. Die finale Übergabe und der unabhängige Review sind unverändert [gesichert](docs/nextgen/evidence/2032-runtime-cases-activation-20261116/README.md). Vier Pflichtfälle: falsch bewertete Zahl mit Korrektur, Wechsel während aktiver Wortwiedergabe, native Banane langsamer und tatsächliche Core-Musterabgabe nach nativer Hilfe. Gleiche gebaute APK, kein Rebuild/Publisher, historische 2031-Dateien/Gates unverändert. Als Nächstes tatsächliche neue Originale sichern und unabhängig prüfen; noch kein neuer Android-PASS. Keine weiteren unveränderten Haupttour-Reruns.

Die kompletten aktuellen Actions-Originale liegen temporär unter `/dev/shm/lumo-2032-android-attempt2-originals`; ZIP **158.127.888 Bytes**, SHA **b925e0ed41110053bf4ad07dd1d1f27c015598bd1b6669b3342a5073ef2a7db7**, alle **4.066** Mitglieder geprüft. Alle Texte/XML/JSON sind zusätzlich im eingecheckten `original-text-evidence.zip`, ausgewählte Originalbilder/-filme einzeln. Der erfolgreiche Publisher stellte alle Originale im öffentlichen `Android-Lernpruefung.tar.gz` bereit. Der lokale zusätzliche TAR-Direkttransport war vor dem ersten Byte nicht verfügbar; der öffentliche APK-Download ist trotzdem vollständig in CI verifiziert. Originalprotokoll erhalten.

`fullModernizationComplete=false`. Keine echte STT, kein physischer Fold7, kein gemessener gemeinsamer akustischer Mund-/Gestenstopp und kein vollständiger 48-dp-Nachweis. `main` geschützt. Fremde Story-PNGs und native generierte UID-Dateien unverändert lassen; freie Overlaykapazität beachten. Alle älteren Fortschrittsabschnitte unten sind historische Checkpoints und nicht der aktuelle Lieferstatus.

---

# LUMO 2032 — APK geprüft, unveränderter Androidversuch 2 läuft

Stand: **16. November 2026, 09:55 UTC**. Lauf [43837592237](https://github.com/Ullmann27/lumo-lernen/actions/runs/43837592237), Versuch 1: **Validate und Build SUCCESS, Android 133211685356 FAIL, Veröffentlichung SKIPPED**. Ein fremder Android-Dialog „Pixel Launcher isn’t responding“ blockierte das Onboarding. Alle Originale sind gesichert; der zuvor vorbereitete frische Versuch ist inzwischen wie unten beschrieben gestartet. **2032 ist noch nicht veröffentlicht.**

## Tatsächlich gestarteter zweiter Versuch

**Versuch 2 läuft seit 16.11.2026, 09:58:59 UTC**, Androidjob **133221738048**, unveränderte APK-/QA-Quelle **9b38360ca5f21919dce4a2b99e605ee39bbbf454**. Der einmalige Failed-Jobs-Rerun wurde über die vorhandene GitHub-Funktion angenommen und anschließend anhand tatsächlicher Run-/Jobmetadaten bestätigt. Originalfehler und vollständiger Build-Beleg sind zuvor im Checkpoint **ede53714a5622f92b87a547842f079d5c2c80a20** gesichert. [Aktivierungsbeleg](docs/nextgen/evidence/2032-android-retry-20261116/activation.json).

Produkt, Probe, Workflow, Publisher und sämtliche Prüfbedingungen bleiben unverändert. Keine neue Kompilierung oder neue APK-Version wird behauptet. Noch kein neuer Android-PASS und kein öffentlicher 2032-Download. Bei erneutem Fehler zuerst die neuen Originale prüfen; keine weitere unveränderte Wiederholung.

## Exakte Identität

| Teil | Tatsächlicher Stand |
|---|---|
| Aktivierte APK-/QA-Quelle | `9b38360ca5f21919dce4a2b99e605ee39bbbf454` |
| Quellbaum | `1c572ff37dde942229e8ae8b1f141ec95df50545` |
| Gepinnte native Quelle | `9d6ef1d704a0e54098a8f8f0818f36deae0e3789` |
| Native Tree | `26b6e5301372d4ade91ca8955f7c1ccf5d0dee78` |
| Version | `0.13.20+2032` |
| Branch in beiden Repositories | `integration/lumo-nextgen-learning-20261115` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Bestehendes Testzertifikat | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

Nachfolgende Dokumentationscommits verändern nicht die Quelle des laufenden Builds. Es wurde kein Merge nach `main` vorgenommen.

## Tatsächlich abgeschlossene neue Validierung

Job **133197989015: SUCCESS**. [Unveränderte Originale und Auswertung](docs/nextgen/evidence/ci-2032-validation/README.md), [Root-Integritätsprüfung](docs/nextgen/evidence/ci-2032-validation/root-integration-review.json).

| Prüfebene | Ergebnis |
|---|---:|
| Vollständige Flutter-Suite | **2.896 PASS / 202 SKIP / 0 FAIL** |
| Analyzer | **0 Fehler / 4 Warnungen / 274 Infos** |
| Host-unittest | **174/174 Methoden PASS**, darin alle 11 neuen aktuellen Stoppfälle |
| Tatsächlicher Godot-Import | **SUCCESS**, Godot `4.6.3.stable.official.7d41c59c4` |
| Native Regressionen | **13 Programme / 55.631 Prüfaussagen**, darin 79 Kontrastchecks |
| Separater Projektvalidator | **118 PASS / 0 WARN / 0 FAIL** |
| Quellbindung | **364** Coverage-Quellhashes und **18** bytegleiche Schutzdateien |

Die 202 Skips bleiben Skips; individuelle Gründe sind aus dem parallelen expanded-Original nicht zuverlässig zuzuordnen. Die vier Analyzerwarnungen betreffen ungenutzte Importe/Felder. Der isolierte Avatarprüfer enthält weiterhin eine erhaltene ObjectDB-Warnung beim Beenden. Keine warnungsfreie Gesamtprüfung behauptet. Native Headless-/Hostprüfungen sind keine neuen Android-, Mikrofon- oder Akustiknachweise.

Artefakt **14212363195**, vollständiges ZIP **264.077 Bytes**, SHA-256 `167bed7006a1fcad952685f92f9583f6158a5f5bc1434a9c153484e24b3d41cd`. Alle **58 Originalmitglieder** und der vollständige Rohjoblog sind erhalten. Root hat das gesamte Übergabepaket, ZIP/Originalbytes, Schlussresultate und Quellbindungen unabhängig nachgeprüft.

## Tatsächlich gebaute und geprüfte APKs

Buildjob **133206155437 SUCCESS**. Beide Original-VERIFY-Dateien bestätigen Paket, Version, bestehendes Testzertifikat, ABI, 16-KiB-ELF-Ausrichtung und gepinnte Native-/Sprachinhalte. [Build-Originale](docs/nextgen/evidence/ci-2032-build/README.md), [Root-Bytebindung](docs/nextgen/evidence/ci-2032-build/root-integration-review.json).

| APK | Bytes | SHA-256 |
|---|---:|---|
| ARM64 | 535.026.462 | `cfa6709547ed82ffe6f081568c3bc454e1cc41afbfea2ecf9c85f534a6ea42de` |
| x86_64 | 538.191.855 | `388c03118b2677817eba130610d9a8e32e964d91f644f61a9a2bcf5141465ad1` |

Das PCK ist in beiden Varianten identisch: **278.589.884 Bytes**, SHA-256 `e7313f1cd28dd00ee324e6798aec6be65e91b28a09bb2b5d2a012a45de5953e7`. Root hat zusätzlich das vollständige ARM64-Archiv und alle APK-Bytes überprüft. Dies ist keine physische ARM64-Ausführung.

## Ursprünglicher Androidfehler und begrenzter nächster Versuch

Die installierte x86-APK stimmt bytegenau. Alle **22** Welcome-XMLs enthalten jedoch ausschließlich den blockierenden Android-ANR-Dialog für Pixel Launcher und SystemUI. Das echte Bild zeigt Lumo samt Startknopf dahinter. Es wurde kein Startknopf gedrückt und keine Lernszene erreicht. Die konkrete Ursache des Launcher-Hängers ist nicht belegt; aus diesen Daten folgt kein Produkt- oder Readerpatch. **42 vollständige Originaldateien**, ZIP, Rohjoblog, echtes Video/Bild und zwei unabhängige Reviews: [Fehlerbeleg](docs/nextgen/evidence/ci-2032-android-launcher-anr-failure/README.md).

Genau ein frischer Versuch mit denselben APKs und unveränderten Prüfbedingungen ist vorbereitet. Der ursprüngliche FAIL bleibt erhalten. Keine Systemmodalität wird weggeklickt, kein Gate gelockert. Erst dessen eigene tatsächliche Originale können einen neuen Androidbefund liefern.

## Inhalt und Abdeckung

Die integrierte Lernwelt besitzt den versionierten Aufgaben-/Gesprächsvertrag, den ursprünglichen weiterbearbeiteten Lumo-Fuchs und aufgabenbezogene native Erklärwege. Die konkrete neue Produktänderung für 2032 korrigiert die Schriftfarben interaktiver nativer Lernbuttons. Der neue aktuelle Stoppfall gehört verpflichtend zur Referenztour und zur Veröffentlichungsprüfung.

Der [aktuelle Katalog](docs/nextgen/COVERAGE.md) erfasst **61 Inventareinträge, 55 Screen-Dateien und 236 Lehrplanfamilien**. Das sind keine 236 spezialisierten, gerätegeprüften 3D-Szenen. Zahlreiche Einstiege nutzen die allgemeine native Aufgabenkarte; Godot bleibt die bestehende separate Activity. **`fullModernizationComplete=false` bleibt zutreffend.** Physischer Fold7/ARM64, deutsche STT, alle Varianten, durchgängige 48-dp-Abnahme, gemeinsame akustische Mund-/Gesten-Stoppmessung und 60 FPS sind nicht nachgewiesen.

Der [Bericht 2032](docs/nextgen/ANDROID_DELIVERY_2032.md) bleibt **DRAFT_PENDING_CURRENT_ANDROID_AND_PUBLICATION**. Frischer Katalogexport: Run **43836322226**, Quelle `a5ea7422b1152576b34cf80519856129ff264ac1`, tatsächlicher Exporttest **1 PASS**, 480 geprüfte Exportquellen. [Originalbelege](docs/nextgen/evidence/ci-2032-catalog-export/README.md).

## Nächster Schritt und Historie

Den begründeten frischen Androidversuch mit beiden vollständigen Touren samt aktivem Stopp und anschließend den vollständigen anonymen Download begleiten. Neue APK-/PCK-Hashes, Paket-/Signaturprüfung und echte Medien ausschließlich aus dem aktuellen Lauf ergänzen. [Konkrete Wiederaufnahme](CONTINUE.md).

Die bereits veröffentlichte [APK 2031 und ihre Befunde](docs/nextgen/ANDROID_DELIVERY_2031.md) bleiben historisch; sie ersetzen keine Abnahme der korrigierten 2032-Bytes. Alle alten Originalfehler und Archive bleiben in Git/remote erhalten. Die zuvor langen laufenden Statusnotizen sind vollständig im [gesicherten Statusstand vor dieser Kürzung](https://github.com/Ullmann27/lumo-lernen/blob/7b2cabc89ace083eb7f30d9d06f19c7d840406e5/STATUS.md) nachlesbar.

## 16.11.2026 – unabhängige Berichtsprüfung und Belegsicherung

Die [unabhängige Präzisionsprüfung](docs/nextgen/evidence/2032-delivery-precision-review-20261116/readonly-review-ede53714.json) ist unverändert gesichert. Sie bestätigt die Trennung von Build, erstem Androidfehler und noch offenem neuen Gerätetest. Die einzige überholte Zukunftsform im Lieferbericht wurde auf den tatsächlich laufenden zweiten Versuch aktualisiert; kein neuer Testerfolg wird daraus abgeleitet.

Zur Vorbereitung weiterer Originalmedien wurden ausschließlich 103 lokale, vorher bytegenau gegen `517349eeecf6d6b990f40db50560786733072baa` geprüfte historische Belegdateien aus sechs Verzeichnissen über den bestehenden Sparse-Checkout ausgeblendet. Alle Gitobjekte und Remote-Dateien bleiben erhalten; fremde Dateien und andere Worktrees wurden nicht verändert. [Prüfmanifest](docs/nextgen/evidence/2032-native-contrast-integration-20261116/root-archive-materialization5.json). Die logischen 59.281.910 Dateibytes ergeben in dieser überlagerten Dateiumgebung nur 1.445.888 zusätzliche freie Bytes; die weitere Originalsicherung muss diesen tatsächlich gemessenen Speicherstand beachten.

## 16.11.2026 – ursprüngliche Teamlieferungen konkret gebunden

Der [unabhängige Team-/Vertragsvergleich](docs/nextgen/evidence/2032-original-team-integration-review-20261116/readonly-review-bd876747.json) und der [zusätzliche Root-Bytevergleich](docs/nextgen/evidence/2032-original-team-integration-review-20261116/root-byte-review.json) sind gesichert. Der Lieferbericht benennt jetzt die ursprünglichen Chat-2/3/4-Zweige und tatsächlichen Komponenten-/Snapshotstände. Insbesondere wird der uncommittete finale Avatar-Snapshot nicht zum ursprünglichen sauberen Producercommit umgedeutet; Chat 4s Integration bleibt selektiv, der EA-Vertrag kanonisch. APK-Quelle, native Revision und laufender Androidversuch sind unverändert.
