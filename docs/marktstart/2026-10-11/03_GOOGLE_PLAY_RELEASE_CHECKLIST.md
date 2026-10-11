# 03 – Österreich / Google Play: Veröffentlichungs- und Verkaufsvoraussetzungen

**Stand: 11.10.2026.** Vorbereitung/Checkliste, keine abschließende Rechts- oder Steuerberatung. Kein Play-Console-Status wurde aus dem privaten Konto ausgelesen.

## A. Vom Kontoinhaber selbst zu klären (ohne Zugangsdaten in Chat/GitHub)

- [ ] Existiert bereits ein Google-Play-Console-Konto? Welcher rechtliche Kontotyp (privat oder Organisation), welche Identitätsprüfung, welche Landeseinstellung?
- [ ] Falls neu: Google verlangt für Play Console derzeit **einmalig 25 USD Registrierungsgebühr**. Entscheidung und Zahlung nur durch den Kontoinhaber; nicht automatisiert auslösen. [Offizielle Hilfe](https://support.google.com/googleplay/android-developer/answer/6112435?hl=de).
- [ ] Für neues persönliches Play-Entwicklerkonto je nach Geltung der Google-Regel **mindestens 12 dauerhaft optierte Closed-Tester über 14 aufeinanderfolgende Tage**, danach Antrag auf Produktionszugang. Nicht automatisch für jedes Altkonto dieselben Bedingungen annehmen. [Google Testanforderungen](https://support.google.com/googleplay/android-developer/answer/14151465).
- [ ] Für Organisation: rechtliche Existenz, gegebenenfalls D-U-N-S und verifizierte Firmenwebsite; für Einzelperson individuelle Identität/Bestimmungen. [Kontotypwahl](https://support.google.com/googleplay/android-developer/answer/13634885).
- [ ] Ein Payments-/Händlerprofil mit richtigen Geschäftsdaten und ggf. Bankverbindung anlegen bzw. vorhandenes prüfen. [Zahlungsprofil](https://support.google.com/googleplay/android-developer/answer/7161426?hl=de).
- [ ] Österreichischer Marktauftritt: Unternehmens-/Steuerstatus, etwaige Gewerbe-/Umsatzsteuerpflicht, Pflichtangaben, Verbraucherschutz und EWR-Trader-Kennzeichnung mit WKO/Steuerberater oder zuständiger Stelle prüfen. EWR-DSA-Trader-Identifizierung im Plattformverfahren beachten. [EU DSA Art 30](https://eur-lex.europa.eu/eli/reg/2022/2065).
- [ ] Offizielle Kontaktadresse für Support, Impressum, Datenschutz, Beschwerden und Auskünfte festlegen; keine privaten Kontakt-/Kontodaten in GitHub committen.
- [ ] Verbindliche Play-Package-ID und Signing-/Update-Strategie festlegen. Aktueller 1928-Tech-Build nutzt `dev.ullmann.lumo.lumo_lernen.coachpreview`, ist keine automatisch produktive Play-Identität.
- [ ] Store-Listing, Alterszielgruppe, Content-Rating, Data Safety, Datenschutz-URL, Kategorien, Preisgestaltung, Rechnungs- und Aboangaben aus tatsächlichem Verhalten der App beantworten.

## B. Kinderschutz und Datenschutz: technische Freigabe

- [ ] Angemessene EWR-/österreichische Datenschutzprüfung (DSGVO, österreichisches DSG, ggf. anderes anwendbares Recht), Datenverarbeitungsverzeichnis/Verantwortliche, Rechtsgrundlagen und AV-Verträge.
- [ ] In Österreich ist bei **einwilligungsbasierter direkter Bereitstellung eines Dienstes der Informationsgesellschaft an ein Kind** gemäß `§ 4 Abs. 4 DSG` die eigene Einwilligung ab dem vollendeten 14. Lebensjahr relevant; darunter sind die Anforderungen des Art. 8 DSGVO bzw. elterlicher Zustimmung zu prüfen. Nicht als pauschale Einwilligung für alle Datenverarbeitungen verstehen. [RIS geltende Fassung](https://ris.bka.gv.at/geltendeFassung.wxe?Abfrage=bundesnormen&Gesetzesnummer=10001597).
- [ ] Google **Families Policy**: Zielaltersgruppe, genaue SDK-/Datenflüsse, Werbung, In-App-Kommerz und Drittanbieter prüfen. Keine manipulative Kaufwerbung im Kinderbereich und keine personalisierte Werbung an Kinder. Empfehlung: **keine Werbe-SDKs**. [Google Families](https://support.google.com/googleplay/android-developer/answer/9893335).
- [ ] Datenschutzseite innerhalb der App und öffentlich zugängliche URL mit den **tatsächlich** erhobenen und übertragenen Daten; Play Data Safety passend dazu. [Play User Data](https://support.google.com/googleplay/android-developer/answer/10144311).
- [ ] Konto-/Datenlöschung in App und als externe Anfragefunktion, **falls** App eine Online-Kontoerstellung erlaubt. Lokale Kinderprofile vs. Dienstkonto differenzieren; unabhängig davon Auskunft/Löschmöglichkeiten bereitstellen. [Account deletion policy](https://support.google.com/googleplay/android-developer/answer/13327111).
- [ ] Mikrofon, Kamera, Foto-Hilfe, Sprache und KI werden separat durch Eltern freigegeben. Kein Kauf soll diese Einwilligung ersetzen.
- [ ] P0 aus Code-Audit: Kindername in optionaler KI-Wochenanalyse `lumo_insight_dashboard.dart` minimieren; alle Online-Datenflüsse und serverseitige Logs prüfen.
- [ ] Vertragsbedingungen, Abonnementdauer, automatische Verlängerung, Kündigungsweg und tatsächliche Leistungen klar und elternverständlich darstellen.

## C. Billing und Store-Freigabe

- [ ] Google Play Billing entsprechend offizieller `Billing Library` bzw. gepflegter Flutter-Integration einbinden. [Android-Dokumentation](https://developer.android.com/google/play/billing/integrate).
- [ ] Produkte im Play Console-Katalog anlegen: z. B. Subscriptions `lumo_premium`, Basispläne `monthly` / `yearly`. IDs final mit tatsächlicher Kontokonfiguration abgleichen. [Play Subscriptions](https://support.google.com/googleplay/android-developer/answer/140504).
- [ ] Serverseitig Purchase-Token und Status prüfen, Kauf bestätigen, RTDN idempotent verarbeiten, Entitlements verwalten. Nie allein anhand lokaler `SharedPreferences` kaufberechtigt setzen. [Backend-Leitfaden](https://developer.android.com/google/play/billing/backend).
- [ ] Testkäufe über lizenzierte Play-Testkonten und internen/geschlossenen Track durchführen; pending, restore, cancel, refund, grace, account hold und offline testen.
- [ ] Google-Gebühren, Auszahlungs- und Umsatzsteuerbehandlung zum konkreten Merchant-/EWR-Modell prüfen. Seit Juni 2026 ist für EWR-Play-Billing-Abos eine Kombination **10 % Service + 5 % Billing** dokumentiert, aber keine pauschale Nettoerlösgarantie. [Aktuelles Gebührenmodell](https://support.google.com/googleplay/android-developer/answer/112622).
- [ ] Android App Bundle `AAB` aus korrekter produktiver Paketkennung, schlüssiger Signatur und den benötigten ABIs erstellen; Play App Signing, Artefakt- und Runtimeprüfung.
- [ ] Produktiv-Release erst nach Freigabe durch den Kontoinhaber, keine versehentlichen Echtauszahlungen/Käufe aus Entwicklungsbranches.

## D. Realistischer 4-Wochen-Sprint – nicht als Garantie

- **Woche 1:** Elternbereich-/Datenschutz-P0, betriebliche Entscheidungen, Preis- und Entitlement-Design, 10–20 Elterninterviews.
- **Woche 2:** Billing-Grundlage hinter Featureflag, Kaufbeleg-Verifikation/Backend, Testprodukte, Staging-Build und automatisierte Tests.
- **Woche 3:** Play Closed Test mit echten Familien, UI-/Datenschutz-/Voice-Kostenmessung, Bugfixes, Store-Bilder mit tatsächlicher Runtime.
- **Woche 4:** Closed-Test-Dauer und tatsächlichen Konto-/Play-Status prüfen; bei Freigabe Zahlungs- und Compliance-Abnahme und stufenweise Veröffentlichung. Falls Google die 14-Tage-Regel anwendet, kann der öffentliche Start entsprechend später sein.

## Freigabe-Entscheidung

**GO** erst, wenn Alleinstellungsmerkmale tatsächlich funktionieren, Kinderschutz und Nutzerdatenprüfungen bestanden, Kauf und Restore unter Google Play getestet, Betriebskosten kalkuliert und Paket/Signing/Play-Console freigegeben sind.

**NO-GO** bei fehlendem Eltern-Gate, Kauf ohne Serververifikation, unkontrollierten Drittanbieter-KI-Datenflüssen, Kinder-Paywall oder nicht erreichbarem Support/Datenschutznachweis.
