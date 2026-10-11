# 04 – Perplexity Computer / SOL 6.1 MAX: Verkaufsfähigkeit als separate nächste Phase

**WICHTIG: Die aktuell laufende Godot-/Fold-/Lumo-Kart-Arbeit nicht abbrechen. Dies ist ein aufgeschobener, isolierter Anschlussauftrag für die bereits bestehende Lumo-Lernen-App. Kein neuer Prototyp und KEINE öffentlich aktivierten Käufe.**

Lies zuerst:
- `docs/marktstart/2026-10-11/README.md`
- `docs/marktstart/2026-10-11/01_PRODUKT_PREISE.md`
- `docs/marktstart/2026-10-11/02_CODE_AUDIT_RISIKEN.md`
- `docs/marktstart/2026-10-11/03_GOOGLE_PLAY_RELEASE_CHECKLIST.md`
- `docs/marktstart/2026-10-11/05_STORE_MATERIAL_TEXTE.md`

Repo: https://github.com/Ullmann27/lumo-lernen . Vor jedem Eingriff aktuellen Produktbranch und PR #259 sowie neuere Eltern-/Voice-/Kart-Branches identifizieren; der Dokumentationsbranch basiert auf altem `main` und ist nicht automatisch der neueste App-Code. Andere Agenten nicht überschreiben.

## Verbindlicher Auftrag: mindestens eine **technisch verkaufsfertig vorbereitete**, kindersichere Premium-Architektur

### Phase A – Exit-Kriterien und Bestandsaudit

1. Prüfe vorhandene Store/Pay/Billing/Family-Mechanismen im neuesten Quellcode. Übernimm kein altes Gerüst ungeprüft.
2. Prüfe den **gesamten** Weg `AppShell → Elternbereich → Kaufoption → Kauf` und tiefe Navigation. Falls der Elternbereich frei erreichbar ist, definiere einen wirksamen Adult-Gate-Flow vor jeder kommerziellen oder datenrechtlich relevanten Elternaktion.
3. Prüfe den `LumoInsightDashboard`-KI-Wochenbericht: Der aktuelle Code setzt `childName` als Freitext in den externen AI-Request. Minimierung vor Release; keine Rückübermittlung über Bot-/Bilddiagnose.
4. Prüfstatus für `pubspec.yaml`, `app_settings.dart`, `profile_repository.dart`, `settings_content.dart`, `lumo_insight_dashboard.dart`, `lumo_ai_proxy_client.dart`, serverseitige Proxy-Endpoints dokumentieren.
5. Unterscheide **lokales Kinderprofil**, **Eltern-/Käuferidentität**, **Google-Play-Abo**, **KI-Datenfreigabe** sauber voneinander. Ein bezahltes Abo ist keine Einwilligung in Cloud-KI.

### Phase B – isolierte Umsetzung (featureflag OFF)

1. Implementiere ein testbares Premium-Domainmodell (z. B. `LumoEntitlement`, `PremiumPlan`, `SubscriptionStatus`, `EntitlementRepository`). In Apps ohne Play-Installation keine echten Paywalls.
2. Erstelle eine testbare Billing-Schnittstelle mit Fake-/Sandbox-Adapter und einem Play-Adapter entsprechend aktueller, gepflegter Flutter-/Play-Billing-API. Keine hardcodierten, unbestätigten Produktpreise bei kaufbaren Play-Produkten; Live-Produktdetails von Play beziehen.
3. Bereite für Google Play **ein** Subscription-Produkt `lumo_premium` mit **zwei** Basisplänen vor (monatlich, jährlich). IDs müssen mit der späteren Play Console abgestimmt werden. Familienabo vorerst nicht implementieren.
4. Serverseitige Kaufvalidierung via Google Play Developer API: Tokens verifizieren, Zustand sicher speichern, erste Käufe bestätigen, Dubletten ignorieren, RTDN idempotent, Kündigung/Grace/Pending/Refund/On-Hold/Ablauf richtig behandeln. Ein Backend-API-Schlüssel darf nie in Flutter/Godot ausgeliefert werden.
5. Entitlements nicht an Kind-Name oder sichtbare lokalen Sterne binden. Keine Profil-/Lernstand-Migration ohne Backup. Premiumrechte von `shared_preferences` trennen.
6. Im Elternbereich eine klar zu findende, visuell Lumo-konforme Premium-Karte ergänzen, **nur im Testmodus sichtbar**, Eltern-Gate für jeden Kauf und Abomanagement. Preis, Laufzeit, automatische Verlängerung, Play-Kündigungsweg, „Käufe wiederherstellen“ und Support erklären.
7. Kindersicht: keinerlei Kaufbutton, Kaufpopup, Werbe-SDK, Coins-zu-Echtgeld-Verwechslung oder Druck während Aufgaben/Rennen. Bestehende Kernübungen weiter frei spielbar.
8. Aufeinanderfolgende Unterbrechungen, App-Updates, Geräte-Rotation, Fold, Offline/Serverausfall und Deep Links korrekt behandeln.

### Phase C – Abnahme & Testfälle

- Automatische Fake-Billing-Tests für `free/pending/active/grace/hold/cancelled/revoked/expired`.
- IDs, Ratenlimits, Timeout, fehlerhafte Tokens, Kaufduplikate, Replay und mehrfach zugestellte RTDN.
- Kaufabschluss nur bei gültiger erwachsener Session; Abbruch, fehlende Verbindung und Pending ohne Premium.
- Profil A/B + Stern-/Walletstände vor/nach Play-Testupgrade erhalten; Audiofreigaben bleiben unverändert.
- Nutzer kann Abo kündigen und Lern-App weiter gratis nutzen.
- „Käufe wiederherstellen“ stimmt mit Play-Zustand überein.
- Datenschutz: keine neue Cloud-Datenübertragung allein durch Premium-Schalter; KI-Wochenbericht ohne persönlichen Namen oder mit rechtskonform belegter Freigabe.
- Flutter analyze/full test; Android-Smoke auf mindestens Emulator; echter Samsung-/Fold-Test separat ausweisen.
- Erst nach tatsächlicher Play-Konsolenfreigabe: echte Testabos nur über **License Testers**, keine Echtgeld-Käufe.

### Phase D – Store-Readiness, KI- und Kostenkontrolle

- Baue aus dem vorhandenen echten Produktergebnis einen Store-Screenshot-Satz (Lernen, Mathe-Mengenbild, Schreiben, Elternbericht, Spiele, Kart). Keine Design-Mockups als Gameplay ausgeben.
- Prüfe für Online-KI/TTS den effektiven Stückkostensatz pro 100, 500, 1000 aktiven Elternabos. Keine unbegrenzte Sprach- oder LLM-Flatrate ohne kalkulierbare Abuse-Grenzen.
- Erstelle Privacy/Data Safety-Datenflussmatrix inklusive Kamera, Mikrofon, Speech SDK, Render, LLM- und TTS-Anbieter.
- Verfügbare Features im Storetext nach tatsächlichem getesteten Release auswählen; keine unvollständigen Animation-/AI-Versprechen.
- Speichere Play-Test-/Compliance-Aufgaben und Abschlussstatus mit verantwortlichem Sign-off.

### Koordination, Grenzen, konkrete Lieferung

- Eigenen Featurebranch und Draft-PR nutzen, niemals `main` direkt verändern.
- Gegebenenfalls auftauchende Play-Konto-Anmelde- und Zahlungsbildschirme **nur vom Nutzer autorisieren lassen**. Keine Bank-/Ausweisdaten anfordern oder committen, keine 25-USD-Registrierung automatisch zahlen.
- Keine Echtgeldzahlungs-/Produktivfreigabe und keine Veröffentlichung ohne ausdrückliches Go des Nutzers.
- Die laufende Kart-Entwicklung hat zuerst Vorrang; diese Monetarisierung erst danach in separater Phase.
- Lieferumfang: Code-PR(s), Unit-/Integrations-/Staging-Tests, Eltern-Premium-Testansichten, Datenschutz-Matrix, präzise noch vom Kontoinhaber auszufüllende Play-Console-Schritte und tatsächliche Kostenmessung.
- **Abnahme:** Technische Kaufvorbereitung im Testmodus nachgewiesen; Verkauf gesperrt bis Play-Console, Datenschutz, Eltern-Gate und echte Google-Play-Testkäufe vollständig abgenommen sind.

**SOFORTIGE ANWEISUNG FÜR DIESEN ZEITPUNKT:** Setze erst deine aktuell laufende Lumo-Kart-/Fold-Qualitätsarbeit nahtlos fort. Vermerke diesen Auftrag als nachfolgende Monetarisierungsphase; beginne keine kostenpflichtigen Aktionen, keinen doppelten Lumo-Umbau und keinen voreiligen Release.
