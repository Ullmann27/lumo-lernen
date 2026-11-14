# Versions- und Auslieferungsaudit für 0.13.8+2020

**Status: ausschließlich lesende Prüfung und konkrete Patchliste; keine neue Versionsfreigabe.** Geprüfte Ausgangsquellen: Host `86445f53af5d573549fc8cf03405261611f3cb7e` (Tree `2389b97232041bb77307e47ecc0e550772339a4e`) und Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` (Tree `dc24bfa8b3fac8812c88cfc8f8eab3af1479979c`). Die tatsächlichen lokalen Gitblob- und SHA-256-Abgleiche stehen in den beigefügten Bindungsdateien. Es wurden keine Tests ausgeführt und keine Produkt-, Versions-, Pin-, Workflow-, Gitref- oder CI-Dateien geändert.

## Entscheidung

Ein getrenntes `0.13.8+2020` ist sauber möglich. Der bloße Wechsel von `pubspec.yaml` reicht ausdrücklich nicht: Die derzeitige Studio-Kette sperrt Version, Nativequelle, Artefaktnamen, Workflowpfad, Branch, Bildrezept und Releaseziel jeweils separat. Alle diese Sperren müssen für 2020 ausdrücklich ergänzt werden. Die bestehenden 2019-Verträge, deren Quellzuordnung zu 803, Originalbilder, Tags und Ergebnisse bleiben erhalten.

Die neuen C4- und Gesichtsquellen sind zum Auditzeitpunkt separate Integrationspakete. Dieser Bericht erfindet weder ihren späteren gemeinsamen Native-SHA noch einen bestandenen 2020-Lauf oder ein neues Bildrezept.

## 1. Gestapelte Branches und Workflows

Vorgeschlagene **neue**, hier nicht angelegte Köpfe: `chatgpt/lumo-studio-2020-20261114` in beiden Repositories. Der Host-PR soll auf dem bisherigen Studio-2019-Branch aufbauen; die Quelle dieses Ausgangsstands bleibt für die Integration exakt 86445. Native baut auf exakt 803 auf. Wenn der vorhandene Branch zwischenzeitlich weitergeht, ist dessen tatsächlicher Kopf vor Anlegen der PR-Kette erneut abzugleichen.

Im Host ist `.github/workflows/lumo-studio-2019.yml` bei `pull_request.branches` auf `chatgpt/lumo-nextgen-20261113` begrenzt. Das ist der **Zielbranch** der PR. Die Jobbedingungen erlauben zusätzlich nur den Kopf `chatgpt/lumo-studio-20261113`; Dispatch prüft denselben Namen. Der Publisher läuft nur bei einer PR aus demselben Repository und diesem Kopf. Ein auf Studio-2019 gestapelter 2020-PR erfüllt diese Bedingungen nicht.

Deshalb einen eigenen `.github/workflows/lumo-studio-2020.yml` ergänzen: neue PR-Basis Studio-2019, exakter neuer Kopf und Dispatchbranch, eigene Concurrencygruppe, eigene Artifactnamen und eigener Publisherjob. Die bisherigen Identitäts- und Berechtigungsbedingungen übernehmen; keine pauschale Branchwildcard und kein Publisher per ungeschütztem Dispatch.

Native verwendet ebenfalls `.github/workflows/lumo-studio-2019.yml`, aber einen Pushfilter auf den bisherigen Studio-2019-Branch. Auch `archive-evidence` prüft diesen Branch ausdrücklich. Ein eigener 2020-Workflow muss den neuen Push-/Archivbranch und sämtliche 2020-Artifactnamen gemeinsam binden. Der bestehende Archivtag `studio-evidence-<Native-SHA>-<Artifact-ID>` ist bereits quell- und artefaktspezifisch und braucht keine numerische Umbenennung.

## 2. Konkrete Dateiänderungen

| Bereich | Tatsächliche Dateien / Stellen | Enger notwendiger Nachtrag |
|---|---|---|
| Appversion | `pubspec.yaml` | Nur im neuen Kandidaten `version: 0.13.8+2020`. |
| Nativepin | `config/godot-source.json`; `scripts/verify_legacy_release_pin.py::APPROVED` | Erst nach realem gemeinsamen Nativefreeze und dessen Abnahme den tatsächlichen 40-Zeichen-SHA für 2020 eintragen. 2019 bleibt 803. Keine Null-, Platzhalter- oder alte Ersatzquelle. |
| Pinverträge | `scripts/tests/test_candidate_2011_pin.py` | Die aktuelle Repositoryerwartung ist fest 2019/0.13.7. Die historische Prüfsumme schließt bisher nur die expliziten 2011–2019-Nachträge aus. 2020 steht außerdem ausdrücklich in der Liste unbekannter Versionen. Alle drei Stellen ergänzen; neue positive/exakte und negative 2020-Fälle, 2019- und übrige historische Prüfungen behalten. `test_legacy_release_pin.py` bleibt historische Abdeckung. |
| Hostworkflow | Neu `.github/workflows/lumo-studio-2020.yml`, aus dem geprüften 2019-Vertrag abgeleitet | Versionassert, Branches, Concurrency, Download/Uploadnamen, API37-`--workflow`-Provenienz, Updatewrapper, Publisher und Releaseziel explizit 2020. Alle vorhandenen Pflichtschritte plus neue C4-/Gesichtsgates. |
| Nativeworkflow | Neu `.github/workflows/lumo-studio-2020.yml` im Godot-Repo | Gleiche acht Pflichtjobs und Archivierung mit neuer Branch-/Artifactbindung; neue Tests und Originalbelege additiv. |
| Visuelles Rezept | `scripts/verify_studio_delivery.py`, `scripts/record_studio_visual_review.py`; neu `config/studio-2020-visual-review.json` und `docs/evidence/studio-2020-reviewed/` | Expliziter zweiter Versionsvertrag für 2020; bestehender 2019-Vertrag bleibt. Neue Rezeptdatei erst aus tatsächlich erfolgreichem Originalarchiv und echter Sichtprüfung erzeugen. |
| Native-Surfaces-Androidprobe | `.github/probes/lumo_studio_surfaces_android_probe.py`, derzeit Versionssperre bei etwa Zeile 801 | Einen ausdrücklich freigegebenen 2020-Kontext ergänzen. Unveränderte Lern-, Sprach-, Kartenfront-, Layout-, Pixel-, Zieh-, Bot-, Pause-, Save-, Reopen- und Flutterrückkehrprüfungen. Keine `>=2019`-Freigabe. |
| Creative-Androidprobe | `.github/probes/studio_creative_android_probe.py`: `ARTIFACT`, `verify_candidate_metadata`, installierte Version | 2020 muss seinen eigenen Workflow, frischen Kandidatenartefakt-ID/Digest und installierte 2020 binden. Alte 2019-Bindung weiterhin separat prüfbar. |
| Creative-Publisher | `scripts/verify_studio_creative_android.py` und dessen Aufruf | Der Publisher verwendet die Bindungslogik der Creative-Probe. Er muss denselben expliziten 2020-Kontext erhalten; alle vier bestehenden Spiel-/Save-/Videoverträge bleiben hart. |
| Updatewrapper | Neu `.github/probes/lumo_2020_update_android_probe.py` | Bestehender 2019-Wrapper unverändert. Echter Ausgangsstand 2017 mit seinen bereits festgelegten Host-/Nativequellen; tatsächliche Kandidatenversion 2020 und deren geprüfter Pin. |
| Exakte Migrationszulassung | `.github/probes/lumo_2003_update_android_probe.py` und `tools/android_qa/update_preservation.py` | Aktuell nur (2017,2018) und (2017,2019). Nach bestätigtem unverändertem Schema genau (2017,2020) ergänzen. Alle Feld-, Typ-, Eigentümer-, Fremdkind-, Installations- und APK-Prüfungen beibehalten. |
| Updateverträge | `tools/android_qa/tests/test_update_preservation.py` | (2017,2020) ist derzeit ein negativer Fall. Eigene 2020-Klasse mit allen bestehenden Invarianten und echter Wrappergrenze ergänzen; die alten 2018-/2019-Fälle und Originalfixture nicht umetikettieren. |
| Receipt-/Publisherverträge | `scripts/tests/test_studio_delivery.py`, `test_studio_cards_capture_binding.py`, `test_studio_creative_delivery.py`, `test_studio_creative_android_probe.py` | 2019-Tests behalten; explizite 2020-Negativfälle für altes Rezept, altes APK/PCK, falsche Version/Quelle/Artefakt-ID, fehlende neue Gates sowie fehlende C4-/Gesichtsnachweise ergänzen. |
| Native-Harnessvertrag | `tools/validate_studio.sh`, `tools/tests/test_nextgen_runner.py` | Aktuell exakt 16 Aufrufe / 37 Studio-PNGs einschließlich Cards- und Shared-SafeArea-Sidecars. Neue Fälle additiv aufnehmen und den echten Roster samt negativen fehlenden/manipulierten Belegen aktualisieren. Alle bisherigen 16/37 bleiben Pflicht. |
| Neue Funktionsabnahme | C4: eingefrorenes Quellenmanifest und neuer `scripts/run_connect_four_runtime.py`; Gesichtsmanifest von B; neue Android-C4-Probe von A | Produktintegration und Gateanschlüsse im neuen Kandidaten. Der lokale Dart–Godot-Lauf ist kein Androidkanal. Die 2019-Cards-Tour ersetzt keine C4-Tour; ein Studioportrait ersetzt keine angeschlossene Gesichts-/Sprachprüfung. |

Die Dateinamen für neue 2020-Einstiegspunkte sind Vorschläge für Root, keine bereits existierenden oder geprüften Dateien. Ein geeigneter kleiner gemeinsamer Mechanismus ist ein **unveränderlicher, ausdrücklich ausgewählter Versionsvertrag** (2019 beziehungsweise 2020), der Version, Workflow, Artefakt und Receiptpfad gemeinsam enthält. Bestehende 2019-Einstiege bleiben standardmäßig auf 2019 beschränkt. Eine freie Umgebungsvariable, beliebige Versionsgrenze oder nachträgliche Änderung importierter globaler Konstanten wäre keine gleichwertige sichere Trennung.

Die vorhandene AST-Erhaltung in `test_studio_delivery.py` prüft konkrete Androidgates gegenüber dem älteren gemeinsamen Vertrag. Ein notwendiger Parameter-/Policyumbau muss deshalb gezielt mit gleichwertigem AST-/Verhaltensnachweis begleitet werden; dieser Vertrag darf nicht einfach entfernt werden.

## 3. Namen, die im neuen Workflow zusammenpassen müssen

| Gegenstand | Bestehender Vertrag | Neuer, vorgeschlagener Vertrag |
|---|---|---|
| Kandidaten-ZIP | `lumo-studio-2019-candidate` | `lumo-studio-2020-candidate` |
| ARM64-Artefakt | `lumo-studio-2019-arm64-verified` | `lumo-studio-2020-arm64-verified` |
| Androidhost | `lumo-studio-2019-android-host-compile` | `lumo-studio-2020-android-host-compile` |
| API35 / API37 | `lumo-studio-2019-android-tour` / `lumo-studio-2019-android-17-tour` | dieselben Rollen mit `2020` |
| Creative | `lumo-studio-2019-creative-android` | `lumo-studio-2020-creative-android` |
| Update | `lumo-2019-in-place-update-proof` | `lumo-2020-in-place-update-proof` |
| Gesamtes Nativearchiv | `lumo-studio-2019-native-evidence` | `lumo-studio-2020-native-evidence` |
| Bildrezept | `config/studio-2019-visual-review.json` | `config/studio-2020-visual-review.json` |
| APK-Releasetag | `coachpreview-build-2019` | `coachpreview-build-2020` |

Auch die Native-Teilarchive, OCR-Belegnamen und finalen Delivery-Receipt-Artefakte sollten im neuen Workflow eine eindeutige 2020-Zuordnung erhalten. Die generischen Dateinamen innerhalb einer quellengebundenen Artefaktwurzel können bestehen bleiben.

**Die entsprechende neue APK-URL ist zu diesem Zeitpunkt nur ein vorgesehenes Ziel und wird hier ausdrücklich nicht als existierender Download angegeben.** Der Publisher muss alle Lookup-, Existing-Tag-, Create-, Public-Readback- und Hashstellen auf genau den neuen Tag binden. Bestehendes Release nur überprüfen, niemals überschreiben. Der vorhandene `release_pipeline_gates.py` unterstützt den numerischen Folgetag bereits und prüft die tatsächlich veröffentlichten Familienversionen; dessen feste Paketkennung, Signatur und ARM64-Anforderung bleiben unverändert.

## 4. Was ohne Versionssonderfall wiederverwendbar ist

`scripts/build_version.py`, `build_unified_apk.sh`, `verify_unified_apk.py`, `prepare_embedded_games.py` und `.github/probes/modernization_android_tour.py` leiten ihre Versionsidentität bereits aus dem tatsächlichen Pubspec beziehungsweise den aktuellen Provenienz-/APKdaten ab. Keine neue fest eingetragene 2020 in diesen generischen Teilen nötig. `prepare_embedded_games.py` erzwingt bereits übereinstimmende ABI-Versioncodes.

Die Framework-/CLI22-Prüfer brauchen ebenfalls keine neue Androidversion: API37 muss weiterhin den tatsächlichen SDK37-/Release17-Pfad, die echten CLI-/AVD-/Image-/Systemserverbeobachtungen und den unveränderten Lebenszyklus durchlaufen. Im neuen Workflow muss lediglich dessen **tatsächlicher eigener Pfad** an die bestehende Provenienzerfassung übergeben werden.

Native `export_presets.cfg` enthält zwar 1/0.1.0 für den eigenständigen Export. Diese Werte sind nicht der Flutter-Familien-APK-Versioncode; sie sind kein Anlass, das geprüfte Hostversionsverfahren zu umgehen.

## 5. Unverändert harte Abnahme für 2020

- Vollständige Flutter- und Python-Gruppen, unveränderte No-Skip-Regeln und tatsächlicher OCR-Replay mit installierten deutschen/englischen Modellen.
- Tatsächliche Androidhostkompilierung sowie ursprüngliche Native-, Action-, Nextgen-, Studio- und Touchgates am **neuen exakten Nativepin**.
- Acht unabhängige Native-Pflichtjobidentitäten, dieselben fünf sauberen Quellstempelbereiche, Original-ZIP-/CRC-/Digestbindung und echte neue visuelle Belege. Alte 803-Bilder bleiben historische Evidenz.
- Beide separaten API35-/API37-Touren am selben frisch gebauten x86-APK und identischem PCK zum ARM64-Kandidaten. Die bestehende API37-/Release17-Sperre bleibt.
- Tatsächliches 2017→2020-Update mit vorhandenen Lernwerten/Wallet-/Eigentümerdaten. Ein 2019→2020-Test ist zusätzlich sinnvoll, sobald ein konkretes freigegebenes 2019-Ausgangs-APK mit unveränderter Identität vorliegt; dessen bereits migrierte Daten brauchen keine künstliche zweite IndependentEvidence-Migration.
- Vorhandene Learning-/Cards-/Creativeinteraktionen und echte Flutterrückkehr weiterhin vollständig. Hinzu kommen neue C4-Runde/Bot/Pause/Reopen/Profil-/Reward-Verträge und reale erreichbare Gesichtsanimation.
- Publisher erst nach allen bisherigen **und** neuen Pflichtjobs sowie tatsächlichen neuen Rezepten. Ein zusätzliches Job ohne Aufnahme in die Publisher-`needs`-/Ergebnisprüfung wäre kein Releasegate.
- Gleiches Familienpaket und Zertifikat; neue Version monoton höher; öffentliche Original-APK nach Veröffentlichung erneut lesen und Hash vergleichen. Physisches Fold7/60FPS wird aus keinem dieser Schritte abgeleitet.

## 6. Einbaureihenfolge und verbleibende Risiken

1. Neue Branch-/Workflowketten ausdrücklich vorbereiten; alte 2019-Kette unverändert weiterlaufen lassen.
2. C4- und Gesichtspakete kontrolliert mit allen gemeinsamen Host-/Native-Insertionen zusammenführen. Bisher eingefrorene unabhängige Belege bleiben auf ihre tatsächlichen Quellen begrenzt.
3. Gemeinsamen Nativekopf tatsächlich erzeugen, volle Nativeabnahme und Originalrendererbilder durchführen. Erst dann den realen Pin und ein neues geprüftes Rezept in 2020 übernehmen.
4. Vollständigen neuen Hostkopf einfrieren. Zweiprozess-C4-Abnahme und echte Android-C4-Probe müssen genau diesen Host und neuen Nativepin binden. Alte 86445-Androidresultate decken C4 nicht ab.
5. Gesamte 2020-Kette durchführen; Originalfehler bleiben Originalfehler, keine Wiederverwendung eines 2019-PASS als 2020-PASS.
6. Erst der erfolgreiche Publisher darf den neuen Releasetag erzeugen; dieser Audit erzeugt weder Freigabe noch Download.

Größte konkrete Risiken sind die PR-Basis-/Kopffilter, die noch ausdrückliche 2020-Ablehnung in Pin- und Migrationsregeln, inkonsistent umbenannte Artefakte, unverändert übernommene 16/37-Harnessfixtures, die an 2019 gebundenen Recorderkonstanten und ein Publisher, der neue C4-/Gesichtsgates nicht zwingend benötigt. Die normalen Identitätsprüfer lassen sich unverändert weiterverwenden; ihre Aussage darf durch keinen freien Override geschwächt werden.

## Nachweisgrenze

Dies ist eine statische, mit veröffentlichten Gitblobs abgeglichene Integrationsprüfung. Keine Tests, Builds, Androidaktionen, neue Bilder, Releases oder CI-Reruns wurden für diesen Audit ausgeführt. Die historischen Prüfzahlen wurden bewusst nicht zu einer neuen 2020-Prüfzahl zusammengerechnet. Alle hier als neu bezeichneten Pfade und Regeln sind vorgeschlagene beziehungsweise noch einzubindende Änderungen.
