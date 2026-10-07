# Lumo – Installation und Update, 7. Oktober 2026

## Ergebnis

Eine tatsächlich gebaute Test-APK **0.10.7+1400** liegt vor. Dieselbe APK wurde über die echten Vorgängerversionen **280, 1291 und 1321** installiert. Alle drei abschließenden Updateprüfungen bestanden. Ein zuvor über die Bedienoberfläche angelegtes fiktives Profil `LumoTest` blieb nach Update, Offline-Neustart und erneuter Installation derselben1400-Datei sichtbar. Keine Deinstallation, kein Löschen der App-Daten und keine Umgehung der Android-Versions- oder Signaturprüfung wurden verwendet.

Das behebt einen belegten Auslieferungsfehler. Der konkrete Installerfehler auf Heinz' physischem Telefon bleibt unbestätigt: sein Screenshot zeigt die APK in der Dateiliste, nicht den Fehlerdialog. Es wird keine erfolgreiche Installation auf seinem Samsung-Gerät behauptet.

## Ausgangsfehler

Die zuletzt ausgelieferte Datei `Lumo_Lernen_35a7a0a_0.10.5_280.apk` hatte versionCode280. Frühere tatsächlich vorhandene APKs derselben coachpreview-App hatten1291 beziehungsweise1321 und dieselbe Zertifikatskennung. Die vollständigen APKs wurden aus GitHub-Artefakten heruntergeladen; deren Manifest und Signaturblock wurden unabhängig gelesen.

Auf Android16/API36 wurde der konkrete Fehler zweimal real reproduziert:

```text
INSTALL_FAILED_VERSION_DOWNGRADE
Update version code 280 is older than current 1291
Update version code 280 is older than current 1321
```

Anschließend wurde jeweils exakt die1400-APK erfolgreich als Update installiert. Die frühere Fresh-install-Prüfung von280 konnte diese Update-Inkompatibilität nicht erkennen. Das war ein Fehler der Auslieferung, nicht ein Beleg dafür, dass Heinz die Datei falsch geöffnet hätte.

Offizielle Android-Grundlage: https://developer.android.com/studio/publish/versioning – versionCode verhindert niedrigere Updateversionen. Gleiche App-Identität/Zertifikat wurden beibehalten, nicht durch ein neues Paket oder einen neuen Schlüssel umgangen.

## Herkunft der tatsächlich ausgelieferten APK

- Repository: `Ullmann27/lumo-lernen`.
- Eigenständiger Branch: `chatgpt/install-upgrade-2026-10-07`.
- Draft-PR: **#208**, auf #207 gestapelt; nicht gemergt, kein Release.
- BASE SHA: **`b6a0afa421e5e854345bfac5cc2be1813a7c3e50`**.
- Getesteter und gebauter APK-SOURCE: **`2beabe722dd40bfe110236a305e66e9122e944b6`**.
- Letzter Prüfharness-SHA vor diesem Dokument: **`b1a8859a5427aa8affac048e0ce90c3cdab17b1a`**.
- Anzeigename: **Lumo Lernen Neu**.
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Version: **0.10.7+1400**; aus der neuen expliziten Versionskonfiguration an den Build übergeben.
- APK-Größe: **169.227.308 Byte**.
- APK SHA256: **`d33b9f5f04a013bc1bcafb579758d109f511ff69e9c08bc95b68c34d9b1c6e7e`**.
- Unverändertes Testzertifikat SHA256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- Android: minSDK24, targetSDK36; arm64-v8a und x86_64.
- Godot unverändert: `c650ff17a5b6a8016fccab0d9b530e0260c6c797`, Engine4.6.3.
- Neues PCK SHA256: `3dc180c694bd8d15edc1e43e0742031c5df0d5866e5b5e81d662e200527cf3bb`.
- Build-Provenienz: **tracked_source_clean=true**.

APK-Build: Run **37576067479**, Buildjob **112645129786**, Ergebnis erfolgreich. Kandidatenartefakt **11463275673**, `lumo-install-candidate-37576067479`, ZIP SHA256 `7b9fb4b1ca44971dc50fe8f09daf7dfac3799274454f1ecda4a69cfd9aa0f358`. Die APK wurde daraus unverändert als `Lumo_Lernen_0.10.7_1400.apk` bereitgestellt, nicht lediglich eine ältere Datei umbenannt.

Build-Belege: Artefakt **11462409672**, `lumo-install-build-evidence-37576067479`, ZIP SHA256 `6c6d59e3886157ec9d0a69ed1098afd3c104768f0bc5fd49bdb1e8400f65ceec`.

## Tatsächliche Updateprüfungen

| Ausgangsversion | Android-Emulator | Erfolgreicher Run | Originalartefakt |
|---|---|---:|---:|
| 280 → 1400 | Android15 / API35 / x86_64 | 37577570787 | 11463730663 |
| 1291 → 1400 | Android16 / API36 / x86_64 | 37577353561 | 11462553872 |
| 1321 → 1400 | Android16 / API36 / x86_64 | 37576939193 | 11462453449 |

Alle drei erfolgreichen Jobs wurden bis zum Abschluss gelesen. Danach wurden die Original-ZIPs heruntergeladen, CRC und SHA256 geprüft und die tatsächlichen Installerprotokolle, Prozess-/Paketdaten, gespeicherten Profilnamen und Screenshot-Digests ausgewertet. Vorher-/Nachherbilder wurden zusätzlich visuell kontrolliert.

Artefakt-Prüfsummen:
- 280-Update-ZIP: `7c720d5366ccea0046ae5987b652c77bc1e9e932c59431bde864442253062c7d`.
- 1291-Update-ZIP: `b7020d2d47ce6478dead22ac40e75fce204f7667e06d9d1e94173cf34220931e`.
- 1321-Update-ZIP: `5326011781ce5cb5282ccc457a6f0b10778deefe7e8c903c159a98bdf18e4d31`.

In jedem Emulator wurde die tatsächliche Vorgänger-APK frisch installiert und darin `LumoTest` über echte UI-Bedienelemente gespeichert. Erst danach erfolgte das Update mittels `adb install -r`, also **über eine vorhandene App samt deren Daten**. Das ist nicht bloß ein Fresh-install-Test der neuen Datei.

Paket-Identität blieb jeweils erhalten:
- 280: UID10209 und firstInstallTime2026-10-07 05:44:03 vor/nach Update identisch.
- 1291: UID10216 und firstInstallTime2026-10-07 05:41:43 identisch.
- 1321: UID10216 und firstInstallTime2026-10-07 05:36:33 identisch; eigener Emulator, keine gemeinsame Installation mit1291.

Die1400-Installation meldete jeweils `Success`. Das Profil wurde danach angezeigt, die Spielewelt geöffnet, die App offline neu gestartet und dieselbe1400-Datei nochmals erfolgreich installiert. Das Profil blieb sichtbar. In keinem abschließenden Lauf erschien das Paket im Android-Crashbuffer.

Prüfumfang: **Profilerhalt und Installation**, nicht pauschaler Beweis, dass alle möglichen Spielstände, Belohnungen oder jedes Nutzerdatum einer beliebigen realen Installation verlustfrei migriert werden.

## Build- und Codeprüfungen

Für den gebauten Produkt-SHA2beabe7 bestanden:
- Vollständige Flutter-Suite: **641 PASS /4 SKIP /0 FAIL**.
- Backend: **22 PASS**.
- Android-Vorbereitung: **5 PASS**.
- Native Lumo-Icon-Tests: **8 PASS** im Build.
- Inhaltsaudit: **40.960 Aufgaben, PASS** nach dessen automatischen Regeln.
- APK-Signatur, Paket, ABIs, eingebettetes PCK, ELF-/Ressourcenalignment: PASS.
- Projektanalyse: keine Compilerfehler, aber **144 Hinweise/Warnungen bleiben**.

Die Quellen wurden getestet und die APK aus einem separaten sauberen Worktree **desselben SHA** gebaut. Das vorhandene Screenshot-Testprogramm schreibt nach `.ci-results/onboarding-visual`; diese teilweise getrackten Ausgabebilder wurden im Test-Checkout erhalten und als Belege gesichert, nicht durch Zurücksetzen versteckt. Änderungen an anderen getrackten Dateien hätten den Ablauf weiterhin abgebrochen. Keine Produktionssignatur, Secrets oder fremde Branches geändert.

## Transparente Fehlläufe und Testkorrekturen

1. Run37575499479 stoppte vor der APK-Erstellung, weil der echte Onboarding-Screenshot-Test ein getracktes Ausgabe-PNG neu erzeugte. Die harte Quellintegritätsprüfung schlug korrekt an. Abhilfe: separater sauberer Build-Worktree desselben getesteten SHA; echte Testbilder/Digests aufbewahrt. Fehlerartefakt11462841138 bleibt erhalten.
2. Der ursprüngliche Sammellauf37576067479 hat einen erfolgreichen Build, aber bleibt insgesamt **rot**: Seine ersten Update-Fixtures suchten im Package-Dump ausschließlich `userId`, während beide aktuellen Emulatorimages `appId` ausgeben. Beide Baseline-APKs waren bereits erfolgreich installiert. Artefakte11462669713 und11463236513 beweisen diesen Testparserfehler; daraus wurde kein App-Installationsfehler abgeleitet.
3. Die separat korrigierten Prüfprogramme lesen beide tatsächlich vorkommenden Metadatenfelder. Die drei oben genannten **eigenständigen** Nachprüfungen bestehen auf derselben APK. Es wird nicht behauptet, dass der ursprüngliche Sammellauf oder dessen übersprungener Acceptance-Job rückwirkend grün geworden wäre. Für Wiederholungen dieser APK die drei dokumentierten Nachprüfworkflows nutzen; den historischen zu engen Sammellauf-Fixture nicht als aktuelle Abnahme verwenden.

## Abgrenzung und weitere Arbeit

Diese APK ist eine **Installations-/Versionsreparatur auf dem PR207-Stand**. Keine neuen Kartenregeln, Rennmechaniken, Modelle, Strecken oder Grafiken wurden hineinkopiert. PR204/PR206 und der fremde Integrationszweig `chatgpt/lumo-next-integration-2026-10-07` bleiben separat; sie sind nicht in dieser Lieferung enthalten. Der parallele Installerzweig `chatgpt/android-install-upgrade-2026-10-07` wurde ebenfalls nicht überschrieben.

Version1400 wurde im Koordinationsissue170 reserviert. **Spätere als Update ausgelieferte coachpreview-APKs müssen bei gleicher Paketkennung/Signatur einen höheren Code als1400 erhalten.** Eine1335 oder die alte280 darf nicht anschließend als neueres Update über1400 angeboten werden. Der alte Default280 in übergeordneten Buildpfaden ist für zukünftige Lieferungen ausdrücklich nicht ausreichend; die koordinierte Gesamtintegration muss die monotone Versionierung übernehmen.

Offen: konkrete Bestätigung auf Heinz' Samsung, eventuelle zusätzliche Installer-/Sicherheitsmeldung, vollständige Cards-/Kart-Spielstandmigration, physische Fold-/Scharnier-/Leistungsprüfung und die bekannten visuellen Lücken. Keine Sicherheitsfunktion des Telefons pauschal abschalten und keine Daten löschen, um eine Installationsmeldung zu umgehen. Falls1400 abgelehnt wird, den vollständigen tatsächlichen Installer-Fehlerdialog statt der Dateiliste anfordern.

## Wiederaufnahme

Aktuelle Claims in #170 und Heads von #202/#204/#206/#207/#208 sowie den Integrationszweigen erneut lesen. Die installierbare Datei stets über APK-SOURCE2beabe7 und ihren Digest identifizieren; spätere Prüfharness-/Dokumentationscommits sind nicht automatisch der APK-SOURCE. Kein automatischer Merge oder Produktionsrelease.

Priorisierte Fortsetzung: (1) Installation auf Heinz' Gerät bestätigen beziehungsweise echten Installerfehler konkret auswerten; (2) abgestimmte Gesamtintegration der separaten App-/Cards-Arbeiten mit Version>1400 und erneuter Updateprüfung; (3) vollständige Spiel-/Speicher-/Fold- und Grafikabnahme am integrierten Stand.
