# GitHub-Zugang bestätigt; gesonderter Veröffentlichungszugang nicht verfügbar

Stand: 24. November 2026, nach dem tatsächlichen Prüflauf 45385067930.

## Bestätigter verbundener Zugang

Der GitHub-Connector ist mit `Ullmann27` / User-ID `64243701` verbunden. Die Repositoryabfrage meldet Pushzugriff auf `Ullmann27/lumo-lernen`. Über diesen Zugang wurden Quellcode, Modelle, Nachweise und auch der neue Prüfworkflow erfolgreich gespeichert. Eine Aussage, es bestehe überhaupt kein GitHub-Zugang, wäre falsch.

Die derzeit angebotenen Connectoroperationen erlauben Repository-/Datei-/Branchänderungen und das Lesen von Releases, enthalten aber keine schreibende Release-/Tag-/Assetoperation. Der integrierte Actions-Buildtoken ist eine davon getrennte Identität.

## Tatsächlicher, ausschließlich lesender Preflight

- [Prüflauf 45385067930](https://github.com/Ullmann27/lumo-lernen/actions/runs/45385067930), Versuch 1, Job `138413747264`.
- Workflowquelle `71a56e4500580779db014e508468d60a90eaf1fb`, Branch `support/lumo-2078-publisher-preflight`.
- Exakter Baum `937f954f7184f58d4d6052c161904f8fdd58cf18`, lokal und remote abgeglichen.
- Artefakt `14914848973`, 520 ZIP-Bytes, SHA256 `b7ab9b74b116c4c5b9c7e8ceb0ea1f8fd02e8de6e7ee95368a8d3f704f1751f0`.
- Originaldatei [PUBLISHER-PREFLIGHT.json](PUBLISHER-PREFLIGHT.json): `credential_available: false`, `status: BLOCKED`, `writes_performed: false`.
- [Unverändertes Originalprotokoll](publisher-preflight-original.log).

Der Job erhielt keinen Wert für das bereits im Projekt vorgesehene `LUMO_RELEASE_PUBLISH_TOKEN` und stoppte vor jeder authentifizierten API-Anfrage mit diesem Zugang. Das beweist seine Nichtverfügbarkeit für diesen Job. Es beweist nicht, dass in sämtlichen anderen GitHub-Environments oder Konten keine Zugangsdaten existieren. Es wurden keine Secretwerte abgerufen, ausgegeben, kopiert oder geändert; keine fremden Credentialnamen ausprobiert.

## Warum kein weiterer Versuch mit dem normalen Buildtoken erfolgte

Die aktuelle [GitHub-Release-Dokumentation](https://docs.github.com/en/rest/releases/releases#create-a-release) verlangt eine für Workflowänderungen autorisierte Identität, wenn der Releasezielcommit Workflowdateien gegenüber dem Defaultbranch verändert. Das eingebaute `GITHUB_TOKEN` kann diese zusätzliche Autorisierung nicht erhalten.

Der Defaultbranch ist `main` an `b24474875fe6eb02d4de01030eab9fa4a4aa6007`. Die Datei `.github/workflows/lumo-2078-device-repair.yml` fehlt dort (API 404) und existiert in der geprüften Produktquelle `94cabcff7f6c568eddfe6805801f49a00ad58312`. Der dokumentierte Fall trifft damit zu. Die ursprüngliche konkrete Fehlermeldung bleibt ein Timeout; die beiden fehlgeschlagenen Originalpublisher werden nicht nachträglich anders bewertet.

## Verbleibende Voraussetzung

Für die automatisierte Veröffentlichung muss die bereits vorgesehene, legitime Publisher-Identität eingerichtet und für diesen Ablauf bereitgestellt sein. Das bestehende Projektkonzept begrenzt den Zugang auf dieses Repository und die erforderlichen Rechte `Contents: write` und `Workflows: write`. Eine Neueinrichtung oder Erweiterung ist eine Kontoeinstellung durch den Inhaber; sie wurde nicht stillschweigend vorgenommen. Zugangsdaten gehören nicht in Chat, Quellcode oder Belege.

Danach ist ein gesonderter 2078-Veröffentlichungsablauf an die tatsächlich vorhandene Identität und die bestandenen Originalqualitätsjobs zu binden. Die alten 2070-/2071-Publisher bleiben unverändert. Keine erneute Erstellung oder Signierung der APK ist erforderlich. Erst ein tatsächlich vorhandenes Release mit vollständigem Originalasset und anschließendem anonymem Byteabgleich erfüllt die Auslieferung.

Die Browser-Passkey-Anmeldung scheiterte sichtbar. Nach dem ausdrücklichen Hinweis des Nutzers wurde ausschließlich der verbundene GitHub-Weg weiterverfolgt. Die Browser-Anmeldung wird nicht pauschal als notwendiger nächster Schritt festgelegt.

## Produktstatus bleibt erhalten

APK 0.14.6+2078: 701640419 Bytes, SHA256 `3e49c99c22d05f7003e4477911d0f72e20fd3447cf6f9d55f6ab805c5fbc8198`. Native 15.246, Android-Tour 23/23, verpflichtende Starts 7/7 und SAF 8/8 sind bestanden. Alle im übergeordneten Bericht dokumentierten Prüfgrenzen bleiben bestehen. Es gibt weiterhin keinen nachgewiesenen öffentlichen Einzel-APK-Link.
