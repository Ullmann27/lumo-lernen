# LUMO 2078: vorbereitete, noch inaktive Veröffentlichung

Diese Vorbereitung veröffentlicht ausschließlich die bereits gebaute und geprüfte APK aus `Ullmann27/lumo-lernen`, Quelle `94cabcff7f6c568eddfe6805801f49a00ad58312`, Originallauf `45365478105`, Originalartefakt `14908418202`. Sie baut und signiert nichts neu. Der separate Branch heißt `support/lumo-2078-reviewed-publish`; Produktzweige und `main` bleiben unberührt.

**Noch keine Veröffentlichung:** Der aktivierende Pfad `config/lumo-2078-reviewed-publish.json` fehlt absichtlich. Der Vorbereitungscommit trägt `[skip ci]`. Diese Dateien belegen weder ein vorhandenes Secret noch einen erfolgreichen neuen Publisher oder einen öffentlichen APK-Link.

## Tatsächliche Kontosperre und notwendiger Eigentümerschritt

Der Eigentümer hat die Einrichtung autorisiert. Der verbundene GitHub-Zugang bietet hier jedoch keine Token-/Secret-Schreibfunktion. Die Kontoeinstellungen führten im Browser zunächst zu einer abgemeldeten 404-Seite und anschließend zur Anmeldung; Tab 10 wurde bei der Formularprüfung und einer leichteren Wiederholungsprüfung jeweils nicht mehr verfügbar. Es wurden keine Zugangsdaten erstellt oder eingegeben und keine Berechtigungen geändert.

Der Kontoinhaber muss deshalb in seinem angemeldeten GitHub-Konto einen Fine-grained Personal Access Token für **ausschließlich `Ullmann27/lumo-lernen`** einrichten: **Contents: Read and write** und **Workflows: Read and write**. Den Token direkt als Repository-Actions-Secret **`LUMO_RELEASE_PUBLISH_TOKEN`** hinterlegen. Den Token weder in den Chat noch in eine Projektdatei kopieren. Die Identität wird auf `Ullmann27`, Benutzer-ID `64243701`, fest geprüft.

Offizielle Anleitungen: [Personal Access Tokens verwalten](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) und [Secrets in GitHub Actions verwenden](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets). Es ist kein angemeldetes oder vorausgefülltes Formular vorbereitet.

## Bewusst getrennte Aktivierung nach der Prüfung

Nach rechtmäßiger Secret-Einrichtung und Prüfung dieser Vorbereitung wird `docs/releases/lumo-2078-publication-request.example.json` unverändert als **neue** Datei `config/lumo-2078-reviewed-publish.json` auf dem genannten Supportbranch hinzugefügt. Nur dieser separate Aktivierungscommit darf den Workflow auslösen; er darf kein `[skip ci]` tragen. Der Code verlangt ausdrücklich den Git-Änderungstyp `A` für genau diesen Pfad im aktuellen Commit. Eine vorhandene Request-Datei zu ändern oder diesen Vorbereitungscommit erneut auszuführen aktiviert nichts.

Der Workflow verwendet `GITHUB_TOKEN` ausschließlich für die lesenden Original-Gate- und Artefaktzugriffe. Nur der abschließende Veröffentlichungsschritt erhält `LUMO_RELEASE_PUBLISH_TOKEN`; es gibt keinen Ersatz durch `GITHUB_TOKEN`. Authentifizierte API-GETs sind auf `api.github.com` begrenzt, folgen keinen Weiterleitungen und verwenden keinen Umgebungsproxy. Der GitHub-CLI-Aufruf erzwingt `GH_HOST=github.com`, isoliert seine Konfiguration und entfernt geerbte Proxy- und Enterprise-Authentifizierung. Tokens stehen nur in der Prozessumgebung.

## Feste Herkunft und unveränderte Fehlerhistorie

Die drei Qualitätsjobs aus Attempt 1 müssen erfolgreich sein: Native `138346148805`, APK `138357008376`, Android `138363355593`. Beide ursprünglichen Publisher `138384742953` und `138386118647` müssen weiterhin als fehlgeschlagen dokumentiert sein; der Originallauf bleibt mit Attempt 2 auf `failure`. Ihre unveränderten Logs liegen unter `lumo-2078-original-evidence`. Der neue Ablauf schreibt diese Fehler nicht nachträglich als Erfolge um.

Die Original-API-Metadaten müssen für das Artefakt exakt `701710167` ZIP-Bytes und SHA-256 `1b52eac413a54f1f8406a76f2880cccec3294c5e16b6ee0705f38e0b4dc2e97e` ausweisen. `actions/download-artifact@v4` lädt genau diese Artefakt-ID aus genau diesem Lauf. Anschließend werden alle neun entpackten Originaldateien nach Größe und SHA-256 geprüft. Die APK muss **701640419 Bytes** und SHA-256 **`3e49c99c22d05f7003e4477911d0f72e20fd3447cf6f9d55f6ab805c5fbc8198`** haben. Hinzu kommen die unveränderten Originalmetadaten und Android-/SAF-Nachweise; deren sieben kopierte Dateien sind separat hashgebunden. Das ZIP wird in dieser lokalen Vorbereitung nicht nochmals heruntergeladen.

## Veröffentlichung und öffentliche Byteprüfung

Der vorgesehene neue Tag ist `lumo-0.14.6-2078-45365478105`. Sowohl Tag als auch Release müssen zunächst fehlen. Der Publisher erstellt den Tag atomar auf der geprüften Quelle und anschließend seinen eigenen neuen Draft als Prerelease, nicht als Latest. Er überschreibt oder löscht keine bestehenden Tags, Releases oder Assets. Die vollständige Asset-Menge, Eigentümer-/Uploader-ID, Größen und **alle SHA-256-Digests** müssen vor der Freigabe exakt stimmen; ein fehlender GitHub-Digest blockiert die Veröffentlichung. Draft-URLs dürfen GitHubs vorläufiges Format haben. Kanonische öffentliche Tag- und Download-URLs werden erst nach der Veröffentlichung verlangt.

Danach wird die vollständige APK über ihre tatsächlich von GitHub gelieferte, auf Repository/Tag/Datei begrenzte öffentliche URL anonym gelesen und erneut nach Größe und SHA-256 geprüft. Der Download verwendet keine Authentifizierungsheader, Cookies oder Umgebungsproxies. Belege enthalten keine temporären Redirect-/SAS-URLs oder HTTP-Fehlertexte. Das beobachtete API-Feld `immutable` wird übernommen; eine aktivierte serverseitige Unveränderlichkeit wird nicht vorausgesetzt.

Ein Teilfehler stoppt den Ablauf. Ein dabei bereits angelegter eigener Tag oder Draft bleibt zur Prüfung erhalten; es gibt keine automatische Löschung, Überschreibung oder Wiederholungsserie. Die Grenzen der Spielabnahme stehen weiterhin unverändert in `lumo-2078-original-evidence/RELEASE-NOTES-READY.md`.

## Lokale Prüfung und verbleibende Grenze

Zwölf gezielte Guard-Tests sind bestanden. Sie decken falsche Quelle/Bytes/Identität, fehlende Original-Gates, vorhandene Release-Ziele, Draft-/Public-URL-Bindung, fehlende Asset-Digests und die Authentifizierungsgrenzen ab; alle Netzwerk- und Mutationsaufrufe sind darin simuliert. Der Gate-Validator wurde außerdem erfolgreich gegen tatsächlich gelesene Original-API-Metadaten ausgeführt. Python-, YAML- und Shell-Syntax, Originaldateihashes sowie unveränderte Helper aus dem gepinnten Basiscommit werden im lokalen `PREPARATION-VALIDATION.json` ausgewiesen.

Eine erfolgreiche Token-Provisionierung oder echte Veröffentlichung wurde damit nicht geprüft. Die noch erforderliche Kontoeinrichtung bleibt ein Schritt des angemeldeten Kontoinhabers.
