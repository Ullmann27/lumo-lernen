# Explizite Android-Prüfverträge für Studio 2020

**Status:** sieben isolierte Quellen-/Testdateien vorbereitet; lokale Vertragsprüfungen bestanden. Kein neuer Nativepin, kein neuer Androidlauf, keine Installation und keine Auslieferungsfreigabe.

Die Ausgangsbytes sind an Host `86445f53af5d573549fc8cf03405261611f3cb7e`, Tree `2389b97232041bb77307e47ecc0e550772339a4e`, gebunden. `baseline-binding.json` enthält Gitblob, SHA256 und Größe der tatsächlich verwendeten Dateien. Aktive Host-/Native-Checkouts, Branches, Workflows, Receipts und Versionskonfigurationen wurden nicht geändert.

## Integration

`source-upload-manifest.json` listet exakt die sieben vorgesehenen Dateien. Die beiden vorhandenen Proben bekommen die neue Option `--studio-version {2019,2020}`; ohne Option bleibt **2019** ausgewählt.

| Ausdrücklich gewählter Vertrag | APK-Version | Kandidatenartefakt | Herkunftsworkflow |
|---|---|---|---|
| 2019, auch Default | 0.13.7+2019 | `lumo-studio-2019-candidate` | `.github/workflows/lumo-studio-2019.yml` |
| 2020 | 0.13.8+2020 | `lumo-studio-2020-candidate` | `.github/workflows/lumo-studio-2020.yml` |

Die Creative-Probe verlangt weiterhin die tatsächliche aktuelle Artefakt-ID, den GitHub-Digest, den erfolgreichen Builder und passende Host-/Nativequellen. Ihr Metadatenprüfer erhält `verify_candidate_metadata(..., studio_version=2020)` als expliziten Keywordparameter. Der Publisher muss denselben Parameter für 2020 weiterreichen; sein Code gehört nicht zu diesem Paket. Die alte 2019-Rückgabeform und `ARTIFACT`-Konstante bleiben erhalten. Versionname und Versioncode werden zusätzlich am ursprünglichen APK-Verifierergebnis und an der installierten App kontrolliert.

**Surface-Komposition:** Die vollständige Surface-Datei in `patched/` enthält nur das Versionsdelta gegen 86445. Sie darf den separat geprüften negativen Ladecaption-Patch nicht überschreiben. Dafür liegt `surface-version-only.patch` bei. Seine Anwendung auf `qa/cards-return-loading-frame-3e08/patched/.github/probes/lumo_studio_surfaces_android_probe.py` wurde in einer isolierten Kopie tatsächlich geprüft. `evidence/surface-composition.json` bindet die Ausgangsbytes, das Versionspatch und das kompilierbare Ergebnis; `capture_returned_flutter` bleibt dabei AST-identisch zur negativen Ladecaption-Fassung.

## Datenerhalt: genau 2017 nach 2020

Der neue Einstieg `.github/probes/lumo_2020_update_android_probe.py` behält die tatsächliche 2017-Basis bei:

- Host `47889f74a651b073965def70743417cf320b1eb9`.
- Native `1d5c5cb45a323228f627ec529e6ff1ddd86f1c57`.
- Kandidatenversion ausdrücklich 2020; der zukünftige Nativepin muss aus der echten, freigegebenen Policy stammen. Dieses Paket fügt dieser Policy keinen Pin hinzu.

Die gemeinsamen Migrationsprüfer ergänzen ausschließlich `(2017, 2020)` neben `(2017, 2018)` und `(2017, 2019)`. **2019 nach 2020 bleibt abgewiesen.** Die vorhandenen 2019-Wrapperbytes bleiben vollständig unverändert.

Die drei tatsächlichen Dart-Schemadateien wurden am unveränderlichen 86445-Commit frisch gelesen und mit den gegenwärtig gestagten Bytes verglichen: `progress_repository.dart`, `independent_evidence.dart` und `lumo_learning_domain.dart` stimmen bytegleich überein. Die Quellenbindung steht in `schema-source-binding.json`. Der zulässige Nachtrag bleibt genau `independentEvidence` mit Version 1; die zehn alten Felder `skillId`, `subject`, `unit`, `correct`, `wrong`, `hintCount`, `currentStreak`, `currentMisses`, `difficulty` und `lastSeen` müssen ihren Wert und Typ behalten. Fremde Kinder, andere Schlüssel, Profilidentität, Installation, Belohnungen und spätere Zustände bleiben den ursprünglichen strengen Vergleichen unterworfen. Begleitete Übungen werden weiterhin nicht zu selbständigen Erfolgen umgedeutet.

Die historische Testfixture bleibt das ursprüngliche 2017/2018-Artefakt mit SHA256 `8815f517552ebdde7908ff98b1bb389147a4857ccb4a75cabd65e2142eb3338a`. Die Wiederverwendung ihres Schemas ist ein Validatorvertrag und kein tatsächlicher 2020-Updatebeleg. Die echten 86445-Updatebeweise werden nicht umetikettiert.

## Ausgeführte, begrenzte Prüfungen

| Gruppe | Tatsächliches Ergebnis | Originalprotokoll |
|---|---|---|
| Bestehende und neue Update-/Migrationsverträge | 53 PASS, 0 Skip | `evidence/update-contracts.log` |
| Explizite 2019-/2020-Versionen, Artefakte und Surface-Hauptpfad | 8 PASS, 0 Skip | `evidence/studio-version-contracts.log` |
| Vorhandene Creative-Verträge | 9 PASS, 0 Skip | `evidence/existing-creative-contracts.log` |

Kommandos, Laufzeiten, Exitcodes und Loghashes stehen in `evidence/execution-first.json`. Die echten Wrapper und der Surface-Hauptpfad laufen in den neuen Fällen bis zu einer ausdrücklich blockierten Androidgrenze; das erwartete Ergebnis dieser synthetischen Teilversuche ist `FAIL` mit dem Testgrenzhinweis. Ein echter Android-PASS kann dadurch nicht entstehen.

Der historische 2019-Wrappertest verwendet jetzt eine temporäre 2019-Quellumgebung und die tatsächlichen unveränderten Policybytes. Dadurch prüft er weiterhin 2019, auch wenn die Repository-pubspec später 2020 auswählt. Der 2020-Wrappervertrag ergänzt nur in seiner temporären Testkopie eine ausdrücklich synthetische Policyzuordnung; ein eigener Gegenfall entfernt diese Zuordnung und verlangt die Ablehnung vor jedem Androidaufruf. Keine solche Zuordnung wird in Produktionsdateien übernommen.

`evidence/ast-preservation.json` bestätigt: alle bisherigen Surface-Funktionen außer dem notwendigen Haupteinstieg sind unverändert; insbesondere Lern-, Sprach-, Karten-, Pixel-, Layout-, Save- und Rückkehrprüfungen. Die vier Creative-Spielmethoden sind ebenfalls unverändert. Bei beiden gemeinsamen Migrationsprüfern unterscheiden sich nur das eine zusätzliche Versionspaar und die entsprechende Fehlermeldung. Die zwei anfänglichen Metadaten-Inspektionsfehler sind in `inspection-tooling-notes.json` erhalten; sie betrafen einen absichtlich umbenannten Testnamen und den lokalen Logpfad, keine Produkt- oder Androidausführung.

Root muss noch den tatsächlich geprüften zukünftigen Nativepin, neue Workflowaufrufe, Publisherparameter und frische Originalbelege integrieren. Das bleibt eine notwendige spätere Freigabegrenze. Dieses Paket lockert weder Pixelschwellen noch Fristen, Spiellogik, Speicherstände oder Geräteanforderungen.
