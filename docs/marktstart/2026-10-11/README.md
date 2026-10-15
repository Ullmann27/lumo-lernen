# Lumo Lernen – Marktstart und Monetarisierung (Vorbereitung, 11.10.2026)

**Status: KONZEPT / TECHNISCHER BESTANDSAUDIT / ENTWICKLUNGSAUFTRAG. Keine aktivierten Zahlungen und keine Veröffentlichung.**

Ziel: frühestmöglicher **sicherer, glaubwürdiger und technisch tragfähiger** kostenpflichtiger Start von Lumo Lernen in Österreich mit Ausbau für den DACH-Raum. Hauptprodukt ist die bestehende Lern-App für 1.–4. Volksschule; Lumo Kart ist ein späterer Differenzierungs- und Bindungsfaktor und darf den Markteintritt nicht unbegrenzt verzögern.

## Arbeitsdateien
- [01 – Produkt, Positionierung, Preise, grobes Umsatzmodell](01_PRODUKT_PREISE.md)
- [02 – Technischer Code-Audit und notwendige Freigabesicherungen](02_CODE_AUDIT_RISIKEN.md)
- [03 – Google Play, Datenschutz, rechtliche und operative Checkliste](03_GOOGLE_PLAY_RELEASE_CHECKLIST.md)
- [04 – Ausführbarer Entwicklungsauftrag für SOL / Computer](04_SOL_MONETARISIERUNG_AUFTRAG.md)
- [05 – Textentwürfe für den Play Store und Conversion-Material](05_STORE_MATERIAL_TEXTE.md)

## Geprüfter Code-Stand
- App: `Ullmann27/lumo-lernen`, PR [#259](https://github.com/Ullmann27/lumo-lernen/pull/259), Head **`bef1403ed5d0243f8c6daca2717e998081cab15e`**, Produktstand `0.12.21+1928`.
- Die bereitgestellte 1928-APK ist eine **technische Vorabversion**, nicht automatisch Play-veröffentlichungsfähig.
- Bestehende separate Parallelentwicklung an Sulafat, Godot, Kart-Menü, Fold, KI und Lern-UI beachten.
- Dieser Dokumentations-Branch basiert unabhängig auf `main` und darf den aktuell aktiven SOL-Branch nicht überschreiben.

## Nicht als erledigt melden
- Google Play Console-Account, Zahlungsprofil, Bank-/Steuerdaten: **nicht geprüft, benutzerseitig nötig**.
- Google Play Billing/Subscription: **im geprüften Flutter-`pubspec.yaml` nicht enthalten**.
- Backendvalidierung von Kaufbelegen, wiederherstellbare Entitlements, Eltern-Gate: **nicht nachgewiesen**.
- Store-Datenschutzangaben/AV-Verträge/Play Families-Prüfung: **offen**.
- Physischer Fold-Test, zahlende Nutzer oder tatsächlich erzielter Umsatz: **nicht vorhanden/nicht verifiziert**.

## Entscheidungsvorlage
**MVP-Monetarisierung:** kostenloser werbefreier Grundzugang + ein `Lumo Premium`-Abo mit Monats- und Jahresbasisplan. Nur Eltern können kaufen. Alltagslernen, Auskunft und Zugriff auf eigene Lernstände dürfen nicht unzumutbar durch Werbung/Kaufbarrieren gestört werden. Ein gesonderter Familien-Cloudtarif erst, wenn verifizierte elternbezogene Geräte-/Profil-Synchronisation existiert. Keine zufallsbasierten Echtgeldkäufe und keine aggressive Vermarktung an Kinder.

## Umsetzung
1. SOL beendet zuerst den laufenden Kart-/Fold-Arbeitsabschnitt. Kein Branch-Wechsel mitten im aktuellen Build.
2. Danach nach Prüfung der neuesten PR-Köpfe gesonderten Monetarisierungs-Featurebranch anlegen und **alle Bezahlfunktionen standardmäßig deaktiviert** halten.
3. Elternzugangsprüfung + Entitlement-Grundlage + testbare Billing-Abstraktion implementieren; Play-Konfiguration und Backend-Verifikation ergänzen.
4. Vor öffentlichem Verkauf: echte Play-Testkäufe, Updates, Rückerstattungen, Kündigungen, Offline-/Restore-Fälle, Sicherheit und juristische Pflichtangaben abnehmen.
5. Bis Freigabe: Eltern-/Lernbereiche ohne Paywallfunktion weiter nutzbar; keine Produktivauszahlung oder Play-Veröffentlichung aus diesem Dokumentations-PR.

Weitere Entscheidungen und fehlende Daten explizit nachführen; alle Zahlen sind Annahmen, keine Umsatzgarantie.
