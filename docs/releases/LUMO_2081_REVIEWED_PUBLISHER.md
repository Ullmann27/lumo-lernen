# Geprüfte Veröffentlichung von Lumo 0.14.8+2081

Dieser getrennte Zweig verändert den laufenden APK-Bau nicht. Der Veröffentlichungscode ist vorbereitet; die aktivierende Datei `config/lumo-2081-reviewed-publish.json` fehlt bewusst bis zur beobachteten vollständigen Abnahme.

- Originalquelle: `7ece88343c005920be850b3413a3bb342c42746c`.
- Godot: `c814e35249e4038f903d1fca3e19bb4751040a43`.
- Original-Baulauf: `45443343100`, Workflow `lumo-abschluss-apk.yml`.
- Neue Version: `0.14.8+2081`; gleicher Paketname und gleiches Familien-Testzertifikat.

Der endgültige Stand enthält zusätzlich die direkte Spracheingabe eigener Aufgaben und die eng begrenzte Importkorrektur für die byteidentischen Produktionsmodelle des neuen Godot-Pins. Die früheren Zwischenläufe `45433091440` und `45440702223` sind keine Veröffentlichungsquelle. Der erste scheiterte nach bestandenen Flutter-/Spielprüfungen an der fehlenden expliziten Importfreigabe des neuen Pins; der zweite wurde durch den korrigierten Stand ersetzt.

## Ablauf

1. Die später neu hinzugefügte Anforderung nennt die tatsächlichen Original-Job- und Artefakt-IDs, Archivprüfsummen, APK-/PCK-Prüfsummen und Bytezahlen. Der Code verweigert unbekannte Felder oder andere Quellen/Versionen.
2. Der nur lesende Actions-Zugang prüft Originalquelle, abgeschlossenen erfolgreichen Lauf, beide erfolgreichen Jobs und die vorgeschriebenen Einzelschritte. Die zwei Artefakte müssen demselben unveränderlichen Quellstand und Lauf gehören.
3. Die unveränderte ARM64-APK wird aus dem Originalartefakt bezogen. Manifest, reales Zertifikat, native Architektur, PCK-Bytes, Metadaten, Android-Rundgang, Backup und die sieben tatsächlich beobachteten Spielstarts müssen zusammenpassen.
4. Nur der bereitgestellte `LUMO_RELEASE_PUBLISH_TOKEN` erzeugt den neuen Tag und einen neuen Release-Entwurf. Bestehende Tags/Assets werden nicht ersetzt. Es gibt keinen Ersatzschlüssel, kein Neusignieren, keinen Neubau und keinen Main-Merge.
5. Alle hochgeladenen Dateien müssen die erwartete Größe und serverseitige SHA-256 besitzen, bevor der eigene Entwurf zur öffentlichen Test-Vorabversion wird. Anschließend wird die gesamte APK anonym über HTTPS zurückgelesen und erneut gehasht.

Der Actions-Zugang liest die Actions-Metadaten auch unmittelbar vor Veröffentlichung. Der persönliche Publisher-Schlüssel braucht dafür keine zusätzlich eingeräumte Actions-Leseberechtigung. Er wird nicht in frühere Schritte oder Protokolle geschrieben.

## Bereits ausgeführte technische Prüfung

15 Veröffentlichungsschutz-Tests für 2081 und 48 bestehende Prüfungen der verwandten Publisher bestanden. Python-Syntax und Whitespace der Schemakorrektur wurden geprüft. Diese Tests ersetzen weder die tatsächliche Android-Abnahme noch den verifizierten öffentlichen APK-Download.

### Schemaabgleich mit den echten Android-Belegen

Die Produktionsprobe schreibt `tour-result.json.installed_package` als PackageManager-Datensatz mit `userId`, `firstInstallTime`, `versionCode` und `versionName`. Die zuvor wiederverwendete Prüfung erwartete hier irrtümlich einen Paketnamen als Zeichenkette. Der auf 2081 begrenzte Validator prüft jetzt die unveränderte tatsächliche Struktur, Version `0.14.8`, `versionCode=2081`, `minSdk=24` und `targetSdk=36`. Der Paketname und dieselbe UID müssen zusätzlich im originalen `installed-package-uid.txt` stehen; auch diese Datei muss mit ihrer Kopie im Belegarchiv übereinstimmen. Die Rohbelege werden weder umgeschrieben noch normalisiert.

Die Regressionen weisen insbesondere falsche Versionen, SDKs, Paketnamen und UIDs sowie weiterhin falsche Quell-/APK-/Signaturbindungen, fehlgeschlagene Backups und fehlende oder abgestürzte native Spielstarts zurück. Der echte Datensatz und die UID-Datei aus Artefakt `14949032444` wurden ebenfalls ohne Dateiveränderung geprüft. Dieser erste Android-Versuch scheiterte später am Emulatortransport und bleibt ausdrücklich kein vollständiger Abnahmenachweis.

Bei einem gezielten Job-Neulauf enthält GitHubs Versuchsliste auch den übernommenen erfolgreichen Bau mit einer neuen Job-ID. Die Veröffentlichungsanforderung muss die tatsächlich beobachteten IDs des abgeschlossenen erfolgreichen Versuchs verwenden. Artefakte werden weiterhin über ihre exakten IDs und Prüfsummen gebunden; ein gleicher Name aus einem früheren Versuch genügt nicht.

Das Originalartefakt enthält die ARM64-APK; die Android-Abnahme verwendet eine separat signierte x86_64-APK mit identischem PCK. Eine Prüfung auf einem physischen ARM64-Gerät oder 60 FPS wird nicht daraus abgeleitet. World-NPC-Dialoge sind derzeit Textdialoge; vorhandene Sprach-/3D-Nachhilfe bleibt erhalten.
