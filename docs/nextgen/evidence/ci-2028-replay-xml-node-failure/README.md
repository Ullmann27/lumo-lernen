# Unveränderter 2028-Replayfehler: XML-Knotentyp

[Lauf 43781148281](https://github.com/Ullmann27/lumo-lernen/actions/runs/43781148281), Job 133018387128, QA-Commit `6f8532940693cbba7059bed4037f9aa6d924bac4`, endete mit FAIL. Die unveränderte installierte x86-APK stammt weiter aus `fc5f6403cb8fb5e26a103ec2deeaa3662c5fa242` (0.13.16+2028). Alle 177 Mitglieder des Originals sind in den bytegeprüften ZIP-Teilen erhalten. Der vollständige Joblog ist verlustfrei komprimiert. Die ursprüngliche fehlgeschlagene Buildtour bleibt getrennt erhalten.

Der neue Download prüfte die tatsächlichen ursprünglichen Validate-/Buildjobs einschließlich ihrer Quellbindung erfolgreich. Alle 123 damaligen Checkerprüfungen bestanden. Die tatsächlich ausgeführte originale Androidtour erreichte erneut die aufgabenbezogene Lab-Erklärung auf „Warum zuerst zwei?“ und Stopp. Der fertige Mikrofon-Berechtigungsdialog wurde jetzt beobachtet. Der Reader scheiterte anschließend vor dem Zulassen-Tap an `TypeError: element indices must be integers`: Ein tatsächlicher `xml.etree.ElementTree.Element` wurde wie ein Dictionary mit `node["package"]` gelesen.

`0139-microphone-outcome.xml` ist das originale vollständige XML (30.798 Byte, SHA-256 `3b4d7f4b79585edb0bbeb0e7e7bcdc102cd06e1b797c213dc60b8f34845e6e6b`). Es zeigt den Audioaufnahme-Prompt für Lumo Lernen Neu und genau einen aktivierten sichtbaren Zulassen-Knopf bei (137, 1127, 943, 1281). Das originale Fehlerbild zeigt denselben Dialog. Hier ist kein App-Absturz, keine tatsächlich erteilte Freigabe und kein Mikrofonerfolg belegt. Die anschließenden nativen Referenzszenen wurden nicht erreicht.

Die minimale Korrektur ersetzt exakt drei Attributzugriffe durch `.get("package")`; sämtliche Ergebnis- und Zeitgates bleiben erhalten. Ein neuer Regressionstest durchläuft den wirklichen Parser mit genau diesem XML und echten Element-Knoten. Sein originales RED reproduziert den Fehler; das vollständige Modul besteht anschließend 64 Prüfungen. Die 14 bisherigen synthetischen Permission-Fälle verwenden nun ebenfalls echte XML-Elemente. RED/GREEN, Fixture und Hashmanifest stehen unter `tools/android_qa/tests/fixtures/nextgen_permission_43781148281/`.

Der Komponentenbranch `qa/lumo-permission-reader-20261116` veröffentlicht den Korrekturbaum `4488c4b41b2fb3cb7d1f50a06f8cea1a9da4cece` als `842285f1fb7458f72a8491e34ceed922a96fa77a`; der lokale Produzentencommit `7ec6e995bb517f3b8fd74b39522404db3f1f594d` hat denselben Baum. Es gibt keine Produktänderung und keinen neuen APK-Build durch diese Korrektur.

Umgebung: Android-35-x86_64-Emulator, Software-Grafik, kein physisches Telefon/Fold7. Die vollständige Tour muss neu laufen. Dieses Ergebnis bleibt FAIL; kein öffentlicher Download und keine vollständige Modernisierung sind damit freigegeben.

`archive-parts.json` nennt Reihenfolge, Einzelhashes und Gesamthash. Das Aneinanderhängen der binären Teile stellt die originale ZIP ohne Neukomprimierung her.
