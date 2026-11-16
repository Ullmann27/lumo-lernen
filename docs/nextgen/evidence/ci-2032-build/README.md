# Originalbeleg: abgeschlossener Android-Build 2032

## Herkunft und Umfang

GitHub-Run `43837592237`, Job `133206155437` (`build`) ist laut abgerufenem Actions-Jobdatensatz **completed / success**. Alle 15 aufgeführten Schritte sind erfolgreich abgeschlossen.

- Flutter-/Workflowquelle: `9b38360ca5f21919dce4a2b99e605ee39bbbf454`
- Quellbaum: `1c572ff37dde942229e8ae8b1f141ec95df50545`
- Nativequelle: `9d6ef1d704a0e54098a8f8f0818f36deae0e3789`, Godot 4.6.3
- Androidversion: **0.13.20+2032**
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`
- Testzertifikat SHA-256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`

Der Reviewer hat nur das kleine Build-Proof-Archiv heruntergeladen. Die großen ARM64-/x86-Artefakte wurden ausschließlich anhand ihrer originalen Actions-Metadaten und der erfolgreichen Uploadmeldungen zugeordnet. Root übernimmt die getrennte vollständige ARM64-Byteprüfung.

## Tatsächliche Originalwerte

| Originalprüfung | ARM64 | x86 |
| --- | --- | --- |
| ABI | `arm64-v8a` | `x86_64` |
| APK-Bytes | 535.026.462 | 538.191.855 |
| APK-SHA-256 | `cfa6709547ed82ffe6f081568c3bc454e1cc41afbfea2ecf9c85f534a6ea42de` | `388c03118b2677817eba130610d9a8e32e964d91f644f61a9a2bcf5141465ad1` |
| ELF-16-KiB-Ausrichtung | true | true |
| resources.arsc ausgerichtet | true | true |
| minSdk / targetSdk | 24 / 36 | 24 / 36 |

Beide Prüfungen nennen dasselbe PCK: **278.589.884 Bytes**, SHA-256 `e7313f1cd28dd00ee324e6798aec6be65e91b28a09bb2b5d2a012a45de5953e7`.

Die beiden `offlineVoice`-Objekte sind identisch und passen zur exakten Quellkonfiguration: `lumo-free-supertonic-de-v1`, F2, Speaker 1, 44.100 Hz, ONNX Runtime 1.23.1, **155 Clips**, sieben gepinnte Modelldateien und unveränderte Modelllizenz. Die fünf verpackten Notice-Dateien stimmen vollständig mit `config/lumo-notices.json` dieses Quellstands überein. Der Reader vergleicht hierfür die gespeicherten CI-Ergebnisse mit den Git-Originalbytes; es wurde kein neuer APK-Prüfer gestartet.

## Unveränderte Originale

- `lumo-nextgen-build-proof-14213960166.zip`: **63.232 Bytes**, SHA-256 `08139630b7229ff1d99c71e5f8f9952be082df0e5fe266d172cd9bf541899898`.
- Alle **5 Originaldateien / 742.916 entpackten Bytes** sind unter `original/` enthalten. Archiv-Digest, Größe, Mitgliedsnamen, jedes CRC, jede Mitgliedsgröße und jeder SHA-256 wurden überprüft; die geschriebenen Kopien wurden bytegleich zurückgelesen.
- `job-133206155437.log`: vollständiger vom Connector gelieferter dekodierter Joblog, **1.227.723 UTF-8-Bytes**, SHA-256 `f013b293279a587bc3ec38afe6d5c96f296fd55bf1ecefbf945a0825aeeeb41f`. Führende BOM sowie **11.325 LF / 0 CR** unverändert erhalten. Dies behauptet keine Kenntnis einer davon abweichenden HTTP-Transferkodierung.
- `github-build-metadata.json`: abgeschlossener Job mit Schritten sowie die drei Build-Artefaktmetadaten.
- `artifact-verification.json` und `job-log-verification.json`: vollständige Transport-/Integritätsbindung.
- `source-review.json`: **11** gelesene Quellblobs mit SHA-256/Git-Blob und Nachweise der Upload-/Source-Zuordnung.
- `summary.json`: maschinenlesbare Befunde und Grenzen.
- `handoff.json`: SHA-256/Bytezahl aller Paketdateien außer sich selbst.

## Aussagegrenzen

Die VERIFY-JSONs haben keinen eigenen Flutter-Commit-Schlüssel. Die Bindung an `9b38360…` folgt aus den unveränderlichen Actions-Artefaktmetadaten, dem aufgezeichneten exakten Checkout und dem erfolgreich ausgeführten Build-Schritt, der `BUILD-PROVENANCE.flutter_source_commit == GITHUB_SHA` und `tracked_source_clean == true` verlangt. Die drei Sidecars in den großen Artefakten wurden durch diesen Reviewer nicht zusätzlich heruntergeladen.

Der CI-Prüfer kontrolliert die tatsächlichen APK-Bytes, Signatur, Ressourcen und Sprachdateien. Diese unabhängige Auswertung bestätigt seine Originalausgaben und Quellbindung; sie ist keine zweite lokale APK- oder Signaturprüfung. ELF-Ausrichtung ist kein Laufzeittest auf einem physischen 16-KiB-Gerät. Verzeichnis-/Lizenzdateiverifikation ist keine rechtliche Rechtefreigabe oder vollständige PCK-Inhaltsprüfung. Verfügbare Sprachressourcen sind kein Beleg hörbarer Wiedergabe, akustischen Tempos oder Mikrofonerkennung.

Dieser Build-Beleg enthält **keinen neuen Androidtour-, aktiven-Stopp-, Leistungs- oder Veröffentlichungs-PASS**. Es wurden keine Tests, Builds, CI-Wiederholungen, Repository-/Remoteänderungen oder großen APK-Downloads durchgeführt. Das zuvor eingefrorene Validationpaket und die Musterabgabe-Lesenotiz bleiben unverändert.
