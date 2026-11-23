# Team-B-Original-APK 2071 nach abgeschlossener Prüfung veröffentlichen

Dieser vorbereitete Workflow erledigt ausschließlich den noch offenen öffentlichen
Direktdownload der **einzelnen ARM64-APK**. Er baut und signiert nichts neu. Eine
gesicherte ZIP-Datei ist zusätzliche Datensicherung und ersetzt diesen Direktdownload
nicht. Die ursprüngliche Android-Prüfung muss zuerst vollständig beendet sein.

Diese eigenständige Team-B-Variante übernimmt die vollständigen Schutzprüfungen
von `00056a379d40cda2538619f114c12c76ed3c7f1c`. Die ursprünglichen Dateien
`lumo-world-reviewed-publish.yml` und `lumo_world_reviewed_publish.py` bleiben
unverändert. Die neue Variante verwendet ausschließlich
`.github/workflows/lumo-team-b-reviewed-publish.yml`,
`scripts/lumo_team_b_reviewed_publish.py` und das Arbeitsverzeichnis
`reviewed-team-b/`.

Stand der Vorbereitung: Der ursprüngliche Baujob ist erfolgreich beendet. Der
Android-Job war bei Vorbereitung dieses Ablaufs noch aktiv; seine erfolgreiche
Beendigung und die tatsächliche Android-Artefakt-ID sind vor jedem Auftrag neu zu
prüfen. Weder ein Veröffentlichungsauftrag noch ein Secretzugriff oder eine
Veröffentlichung gehört zu dieser Vorbereitung.

## Fest gebundener Kandidat

| Merkmal | Erwarteter Originalwert |
| --- | --- |
| Repository / Branch | `Ullmann27/lumo-lernen` / `support/logic-world-team-b-20261123` |
| Original-Buildrun / Versuch | `45191784853` / `1` |
| Ursprünglicher APK-Workflow | `.github/workflows/lumo-team-b-apk.yml` |
| Baujob | `137751923651` – erfolgreich abgeschlossen |
| Android-Job | `137767273722` – Erfolg vor Freigabe prüfen |
| Flutter-Commit / Releaseziel | `b4db287fe562893d849d1c826c9b92e8f2e44761` |
| Godot-Commit | `e0460c0b3eda9d42e9d963eb2236dc8d9c7b5913` |
| APK-Artefakt-ID | `14828082269` |
| Metadaten-Artefakt-ID | `14827937341` |
| Datei / Version | `Lumo-Lernen-Test-0.14.2-2071.apk` / `0.14.2+2071` |
| APK-Größe | `537231343` Bytes |
| APK SHA-256 | `c7036b318ba9f3e0c0751abcc1f3745ce0fd0a96a617954501feb40b63627737` |
| Öffentliches Signaturzertifikat SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |
| Eingebettete PCK SHA-256 | `398cf6cdd6cac5233037b6cd1247c89b3a92392050a0c9a9696af82d0beedf5f` |
| PCK-Größe | `279910300` Bytes |
| Neuer, einmaliger Releasetag | `lumo-test-0.14.2-2071-reviewed-45191784853` |

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
`LUMO-ANDROID-TOUR-45191784853`. Die bereits bekannte Android-Job-ID ist
`137767273722`, die Baujob-ID `137751923651` und der beobachtete
Run-Versuch `1`; vor der Freigabe alle Ergebnisse im Originalrun prüfen. Nicht eine
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
angelegt.** Die noch offenen Shell-Variablen erst mit der tatsächlich nach erfolgreichem
Android-Job festgestellten Artefakt-ID und der freigegebenen Benutzeridentität
belegen. Die nachfolgenden Run- und Job-IDs bezeichnen den oben gebundenen
Originalversuch. Der Hilfsbefehl verlangt alle Werte; leere oder ungültige Angaben scheitern. Er schreibt selbst keine Datei:

```bash
python3 scripts/lumo_team_b_reviewed_publish.py template \
  --build-run-attempt 1 \
  --build-job-id 137751923651 \
  --android-job-id 137767273722 \
  --android-artifact-id "$ANDROID_ARTIFACT_ID" \
  --publisher-login "$PUBLISHER_LOGIN" \
  --publisher-user-id "$PUBLISHER_USER_ID"
```

Die erzeugte JSON-Struktur enthält sämtliche festen Identitäten aus der Tabelle
und die sechs bestätigten Lauf-, Artefakt- und Benutzerangaben. Nach inhaltlicher
Prüfung wird genau diese Struktur als **`config/lumo-team-b-reviewed-publish.json`** übernommen. Erst ein
freigegebener Push dieser Auftragsdatei auf `support/logic-world-team-b-20261123` startet
`.github/workflows/lumo-team-b-reviewed-publish.yml`. Das Hinzufügen der neuen
Workflow-/Prüfdateien allein startet ihn nicht; `main` wird nicht verändert.

## 4. Tatsächliches Ergebnis prüfen

Der Publisher stoppt vor jeder Änderung, falls der vorgesehene Tag oder Release
bereits existiert. Er ersetzt oder löscht keine bestehenden Dateien. Nach einer
erfolgreichen Erstellung lädt er den von GitHub zurückgegebenen APK-Asset-URL
**ohne Authentifizierung oder Cookies vollständig über HTTPS** herunter und prüft
wieder `537231343` Bytes sowie den ursprünglichen SHA-256. Erst danach erscheint
der bestätigte Direktlink in der Workflow-Zusammenfassung und in
`PUBLIC-DOWNLOAD-VERIFICATION.json`.

Das Actions-Artefakt `LUMO-TEAM-B-REVIEWED-PUBLISH-<run_id>-<run_attempt>` enthält die
konkreten Herkunfts-, Freigabe- und Downloadbelege. Scheitert die Erstellung oder
der anschließende Download, zuerst diesen tatsächlichen Zustand prüfen. Ein
teilweise angelegter Release/Tag wird nicht automatisch gelöscht, verändert oder
blind erneut angelegt. Keine unbestätigte URL als funktionierenden Download ausgeben.

Lokale Prüflogik ohne Netzwerk, Secret oder Veröffentlichung testen:

```bash
python3 -m unittest discover -s scripts/tests -p test_lumo_team_b_reviewed_publish.py -v
```
