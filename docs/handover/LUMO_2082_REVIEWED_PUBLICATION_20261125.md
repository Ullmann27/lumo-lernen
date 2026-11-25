# LUMO 2082: geprüfte Veröffentlichung unveränderter APK-Bytes

Stand: 25.11.2026. Dies ist eine Implementierungsübergabe, kein Build- oder Veröffentlichungsnachweis.

## Vorbereitung und Grenze

Der Publisher baut und signiert nichts. Er verarbeitet ausschließlich die ARM64-APK und Prüfbelege aus einem vollständig erfolgreichen Lauf von `.github/workflows/lumo-intelligence-2082.yml` auf `integration/lumo-intelligence-2082-20261125`. Er verlangt die erfolgreiche Lernprüfung, den vollständigen APK-Bau und die echte Android-Tour des exakt gebundenen Laufversuchs.

Die neue Implementierung liegt zunächst auf einem isolierten Entwicklungszweig. Es wurde kein aktivierender Veröffentlichungsauftrag angelegt. Die Workflow-Definition reagiert ausschließlich auf einen Push mit neu hinzugefügter Datei `config/lumo-2082-reviewed-publish.json` auf `support/lumo-2082-reviewed-publication`. Ein geänderter oder erneut verwendeter Auftrag wird nicht als neuer Auftrag akzeptiert. Ein GitHub-Rerun bleibt an denselben Auftrag gebunden.

## Benötigte reale Metadaten

Die JSON-Datei muss dem vollständigen Schema `config/lumo-2082-reviewed-publish.schema.json` entsprechen. Es gibt bewusst keinen mit Beispielwerten ausgefüllten Auftrag.

Feste Werte werden im Skript zusätzlich geprüft: Repository `Ullmann27/lumo-lernen`, Repository-ID `1222433959`, Owner-ID `64243701`, Versionsname `0.14.9`, versionCode `2082`, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, Dateiname `Lumo-Lernen-Test-0.14.9-2082.apk` und Testzertifikat `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.

Aus dem tatsächlichen erfolgreichen Kandidaten müssen folgende Werte übernommen und unabhängig verglichen werden:

- `flutter_commit`, `godot_commit`: vollständige Commit-SHAs; der Godot-Pin muss zusätzlich im Flutter-Quellstand stehen.
- `build_run_id`, `build_run_attempt`: genau der erfolgreich abgeschlossene Workflow-Lauf und Versuch.
- `intelligence_job_id`, `build_job_id`, `android_job_id`: drei unterschiedliche, erfolgreiche Jobs dieses Versuchs.
- `apk_bytes`, `apk_sha256`, `pck_bytes`, `pck_sha256`: aus den Originalbelegen, anschließend an den tatsächlichen Bytes erneut geprüft.
- Für `apk`, `android` und `intelligence` jeweils `<label>_artifact_id`, `<label>_artifact_bytes`, `<label>_artifact_sha256`: beobachtete GitHub-Artefaktmetadaten, beim Hash ohne `sha256:`-Präfix.
- `release_tag`: exakt `lumo-0.14.9-2082-` gefolgt von der tatsächlichen `build_run_id`.

Auch die IDs, Hashes und Bytezahlen der Intelligence-Testbelege sind bindend. Alte 2081-Werte sind kein Ersatz. Falls sich der Build-Quellstand vor dem erfolgreichen Lauf ändert, muss der Auftrag diesen erfolgreichen Quellstand enthalten.

## Prüfkette

Der Job `verify` erhält nur `contents:read` und `actions:read`. Er liest die erfolgreiche GitHub-Lauf-/Job-/Artefaktidentität, den Versionsstand und Godot-Pin direkt am festgelegten Commit. Er lädt alle drei ZIP-Dateien nach Artefakt-ID, hasht die vollständigen ZIP-Bytes und prüft deren Bytezahl. Die API-Autorisierung wird nicht an den Storage-Redirect weitergereicht. Die Extraktion weist Traversal, Aliasnamen, Duplikate, Links, Sonderdateien, verschlüsselte Einträge und übergroße Archive ab.

An der extrahierten APK werden SHA-256, Bytezahl, Manifest, ARM64-Bibliotheken, Signaturzertifikat, eingebetteter Godot-Quellnachweis und komplette PCK-Bytes erneut geprüft. Die ursprünglichen Provenienz-/Split-Belege, Android-Paketmanagerdaten, UID-Aufzeichnung, Tour, Backup-Rückspielung und sieben native Starts bleiben verbindlich. Alle vorhandenen Tour- und Backup-Schritte müssen erfolgreich sein; doppelte oder fehlende Pflichtschritte sperren die Freigabe. Auch die mitgelieferten Belegarchive müssen mit den geprüften Originaldokumenten übereinstimmen.

Ein neuer Übergabe-Artefakt enthält genau die freigegebenen Release-Dateien und Prüfbelege. Der Job liefert dessen ID/SHA-256 sowie den SHA-256 der Freigabedatei als Job-Ausgaben. Der getrennte Job `publish` prüft erneut die vollständige Übergabe-ZIP, den Lauf-/Commit-/Versuchsbezug, den Freigabe-Hash und sämtliche auszuliefernden Bytes. Erst dieser Job erhält `contents:write`. Es wird ausschließlich sein kurzlebiger `GITHUB_TOKEN` verwendet.

Vor der ersten Mutation werden Repository und Owner, die laufende Publisher-Workflowidentität, die erfolgreichen Quellprüfungen und die lokale Dateimenge nochmals geprüft. Existierender Tag oder existierendes Release sperren die Ausführung. Nur beobachtetes HTTP 404 gilt als Abwesenheit. Danach werden einmalig ein neuer Tag am exakten geprüften Flutter-Commit und ein neuer leerer Draft erstellt, unveränderte Assets hochgeladen, die Server-Digests verglichen und der Draft veröffentlicht. Es gibt weder Clobber noch Delete, Tag-Verschiebung, abweichenden Zielcommit, Token-Fallback oder automatischen Wiederholungs-Write.

## Identität, Berechtigung und Unveränderlichkeit

GitHub dokumentiert `GITHUB_TOKEN` als Installationstoken der GitHub-Actions-App. Deshalb wird kein `GET /user` gegen ein erwartetes Benutzerkonto ausgeführt. Repository-Eigentümer bleibt `Ullmann27` mit ID `64243701`; Ersteller und Uploader des neuen Releases müssen `github-actions[bot]`, ID `41898282`, Typ `Bot` sein. Diese Bot-Identität ist auch an bestehenden öffentlichen Releases dieses Repositorys beobachtbar.

Die offizielle GitHub-Dokumentation beschreibt eine zusätzliche Grenze für Create/Update Release, wenn der Zielcommit Workflow-Dateien gegenüber dem Default-Branch verändert: Dafür kann `Workflows:write` erforderlich sein, das `GITHUB_TOKEN` nicht erhalten kann. Der Publisher verändert weder diese Schutzregel noch den Zielcommit und versucht keine alternative Identität. Tritt ein HTTP 403/404 oder anderer Fehler auf, protokolliert er Phase, erlaubte Fehlerklasse und tatsächlichen HTTP-/Exitstatus ohne Token, API-Antworttext oder sensible Prozessausgabe.

Ein erfolgreicher Veröffentlichungslauf liest anschließend die ganze öffentlich angebotene APK über einen frischen anonymen HTTPS-Client zurück und vergleicht SHA-256 und Bytezahl. Erst danach entsteht `PUBLIC-DOWNLOAD-VERIFICATION.json`. Ein vorberechneter Link ist kein Auslieferungsnachweis.

Der Publisher ersetzt keine vorhandenen Tags, Releases oder Assets. GitHubs separate serverseitige Eigenschaft `immutable` wird in `server_immutable_observed` unverändert protokolliert. Ein Wert `false` oder fehlender Wert darf nicht als aktivierte serverseitige Unveränderlichkeit beschrieben werden. An den bei Vorbereitung betrachteten vorhandenen Releases war `immutable:false` gesetzt; die Einstellung eines künftigen 2082-Releases muss am realen Ergebnis bewertet werden.

Quellen:

- https://docs.github.com/en/actions/concepts/security/github_token
- https://docs.github.com/en/rest/releases/releases#create-a-release
- https://docs.github.com/en/rest/releases/releases#update-a-release
- https://docs.github.com/en/code-security/concepts/supply-chain-security/immutable-releases
- https://api.github.com/repos/Ullmann27/lumo-lernen/releases?per_page=10

## Tests und Ausführung

Direkter Testaufruf: `python3 -m unittest scripts.tests.test_lumo_2082_reviewed_publish -v`. Das Testmodul muss vorhanden und importierbar sein; ein fehlender Dateiname darf nicht als erfolgreicher Lauf mit null Tests gelten. Die Tests verwenden ausschließlich synthetische Dateien/API-Antworten und führen keine Netzwerkmutationen aus.

Die vorhandene Arbeitsumgebung konnte keine lokalen Shell- oder Python-Befehle ausführen. Daher behauptet diese Übergabe keinen lokal bestandenen Testlauf. Der Read-only-Workflow-Job führt die Tests vor jedem Auftrag aus; die Koordination kann sie zusätzlich auf einem isolierten CI-Zweig prüfen. Der unabhängige statische Review des ersten Skript-/Workflow-Stands ergab keine blockierenden Befunde.

Wenn eine Berechtigungsgrenze die Veröffentlichung stoppt, bleiben die originalen GitHub-Artefakte und echten Prüfprotokolle die überprüfbare Alternative. Ein Workflow-Artefakt wird nicht als anonymer öffentlicher APK-Direktdownload bezeichnet. Weder 60 FPS auf einem physischen Gerät noch ein Fold7-Gerätetest werden aus CI-/Emulatorbelegen abgeleitet.
