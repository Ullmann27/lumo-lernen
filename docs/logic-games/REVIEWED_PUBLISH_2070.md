# Original-APK 2070 nach abgeschlossener Prüfung veröffentlichen

Dieser vorbereitete Workflow erledigt ausschließlich den noch offenen öffentlichen
Direktdownload der **einzelnen ARM64-APK**. Er baut und signiert nichts neu. Eine
gesicherte ZIP-Datei ist zusätzliche Datensicherung und ersetzt diesen Direktdownload
nicht. Die ursprüngliche Android-Prüfung muss zuerst vollständig beendet sein.

## Fest gebundener Kandidat

| Merkmal | Erwarteter Originalwert |
| --- | --- |
| Repository / Branch | `Ullmann27/lumo-lernen` / `feature/logic-world-20261123` |
| Original-Buildrun | `45186225313` |
| Flutter-Commit / Releaseziel | `11c0711f23f887796a7281ddfc6ee7a2aa56ac67` |
| Godot-Commit | `90648b0639391c88d3c2da0e3f235d30f725256d` |
| APK-Artefakt-ID | `14826480557` |
| Metadaten-Artefakt-ID | `14826031651` |
| Datei / Version | `Lumo-Lernen-Test-0.14.1-2070.apk` / `0.14.1+2070` |
| APK-Größe | `537159895` Bytes |
| APK SHA-256 | `8dca425b869b91b18956ecd848ed993ffbd5e21d114fe489b83f78fea6aff6ff` |
| Öffentliches Signaturzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Eingebettete PCK SHA-256 | `9a91ed2b428e086fd0d2c813fc9f55aaac5e65aa75944736a94af55673416fd6` |
| PCK-Größe | `279880864` Bytes |
| Neuer, einmaliger Releasetag | `lumo-test-0.14.1-2070-reviewed-45186225313` |

## 1. Eine berechtigte Publisher-Identität freigeben

Der Repository-Verantwortliche hinterlegt einen dafür ausdrücklich freigegebenen,
auf dieses Repository beschränkten **Fine-grained Personal Access Token** als
Actions-Repository-Secret **`LUMO_RELEASE_PUBLISH_TOKEN`**. Er benötigt
**Contents: read and write** und **Workflows: read and write**; Ablaufdatum und
vorhandene Freigaberegeln bleiben verbindlich. Den Wert weder in Chat, Auftrag,
Quelltext noch Protokoll kopieren. Keine Signierschlüssel werden benötigt.

Der Auftrag bindet den freigegebenen GitHub-Benutzernamen und dessen numerische
Benutzer-ID. Vor einem Schreibzugriff vergleicht der Publisher diese mit `GET /user`.
Dieser konkrete Workflow unterstützt eine Benutzer-Identität; ein
GitHub-App-Installationstoken wird nicht als Benutzer-Token interpretiert.

Der normale `GITHUB_TOKEN` darf nur Originalrun und Artefakte lesen. Er ist **kein
Fallback für die Veröffentlichung**. Fehlt das benannte Secret oder lehnt GitHub die
Berechtigung ab, stoppt der Ablauf. Ein erneut gestarteter Lauf erhält dadurch keine
zusätzlichen Rechte.

Hintergrund: Der Release-Zielcommit enthält Workflow-Änderungen gegenüber dem
Standardbranch. GitHub verlangt dafür die zusätzliche Workflow-Berechtigung, die
dem eingebauten Actions-Token nicht erteilt werden kann. Quellen:
[GitHub: Create a release](https://docs.github.com/en/rest/releases/releases#create-a-release),
[GitHub: GITHUB_TOKEN permissions](https://docs.github.com/en/actions/tutorials/authenticate-with-github_token).

## 2. Originalprüfung abschließen und die offenen IDs festhalten

Der ursprüngliche Baujob und der Android-Job müssen beide **success** im selben
Originalrun-Versuch haben. Der gesamte Run darf wegen seines bisherigen
Veröffentlichungsschritts fehlgeschlagen sein. Ein laufender Run wird abgewiesen.

Lesend in GitHub feststellen: tatsächliche `run_attempt`, ID des erfolgreichen
Baujobs, ID des erfolgreichen Android-Jobs und ID des fertigen Artefakts
`LUMO-ANDROID-TOUR-45186225313`. Die bereits bekannte Android-Job-ID ist
`137748819779`; vor der Freigabe deren Ergebnis im Originalrun prüfen. Nicht eine
Artefakt-ID anhand des Namens oder eines neueren Runs ersetzen.

Die Prüflogik bindet jeden Download an die exakte Artefakt-ID, den Originalrun,
dessen Commit, Branch und Ursprungsrepository. Sie kontrolliert SHA, Größe,
Manifest, ARM64-ABI, echtes öffentliches Signaturzertifikat, eingebettete PCK,
Originalprovenienz und `SPLIT-APK-IDENTITY.json`. Tour und Backup müssen die
x86_64-APK dieser Split-Provenienz und dieselbe PCK betreffen. Alle verpflichtenden
Tour-/Backup-Schritte und die tatsächlich beobachteten nativen Spielstarts
einschließlich **World** müssen bestanden sein. Das ist keine Behauptung eines
Tests auf einem physischen ARM64-Gerät oder von 60 FPS.

## 3. Auftrag erst mit vollständigen Belegen erzeugen und prüfen

**Der auslösende Auftrag gehört nicht zu dieser Vorbereitung und ist noch nicht
angelegt.** Die folgenden Shell-Variablen erst mit den tatsächlich geprüften IDs
und der freigegebenen Benutzeridentität belegen. Der Hilfsbefehl verlangt alle
Werte; leere oder ungültige Angaben scheitern. Er schreibt selbst keine Datei:

```bash
python3 scripts/lumo_world_reviewed_publish.py template \
  --build-run-attempt "$BUILD_RUN_ATTEMPT" \
  --build-job-id "$BUILD_JOB_ID" \
  --android-job-id "$ANDROID_JOB_ID" \
  --android-artifact-id "$ANDROID_ARTIFACT_ID" \
  --publisher-login "$PUBLISHER_LOGIN" \
  --publisher-user-id "$PUBLISHER_USER_ID"
```

Die erzeugte JSON-Struktur enthält sämtliche festen Identitäten aus der Tabelle
und die sechs bestätigten Angaben. Nach inhaltlicher Prüfung wird genau diese
Struktur als **`config/lumo-world-reviewed-publish.json`** übernommen. Erst ein
freigegebener Push dieser Auftragsdatei auf `feature/logic-world-20261123` startet
`.github/workflows/lumo-world-reviewed-publish.yml`. Das Hinzufügen der neuen
Workflow-/Prüfdateien allein startet ihn nicht; `main` wird nicht verändert.

## 4. Tatsächliches Ergebnis prüfen

Der Publisher stoppt vor jeder Änderung, falls der vorgesehene Tag oder Release
bereits existiert. Er ersetzt oder löscht keine bestehenden Dateien. Nach einer
erfolgreichen Erstellung lädt er den von GitHub zurückgegebenen APK-Asset-URL
**ohne Authentifizierung oder Cookies vollständig über HTTPS** herunter und prüft
wieder `537159895` Bytes sowie den ursprünglichen SHA-256. Erst danach erscheint
der bestätigte Direktlink in der Workflow-Zusammenfassung und in
`PUBLIC-DOWNLOAD-VERIFICATION.json`.

Das Actions-Artefakt `LUMO-REVIEWED-PUBLISH-<run_id>-<run_attempt>` enthält die
konkreten Herkunfts-, Freigabe- und Downloadbelege. Scheitert die Erstellung oder
der anschließende Download, zuerst diesen tatsächlichen Zustand prüfen. Ein
teilweise angelegter Release/Tag wird nicht automatisch gelöscht, verändert oder
blind erneut angelegt. Keine unbestätigte URL als funktionierenden Download ausgeben.

Lokale Prüflogik ohne Netzwerk, Secret oder Veröffentlichung testen:

```bash
python3 -m unittest discover -s scripts/tests -p test_lumo_world_reviewed_publish.py -v
```
