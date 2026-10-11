# 02 – Technischer Readiness-Audit der derzeitigen Lumo-App

**Geprüfter Branch:** `computer/lumo-kart-android-1928-2026-10-11`, Head `bef1403ed5d0243f8c6daca2717e998081cab15e` (App-PR #259), 11.10.2026. Nur Quellcodeprüfung ausgewählter Dateipfade – **kein vollständiger Penetrationstest, keine Abnahme auf echtem Gerät**.

| Befund / Quelle | Ist-Zustand | Einstufung | Nötiger Schritt |
|---|---|---|---|
| `pubspec.yaml` | `in_app_purchase`, `billing_client` oder gleichwertige Google-Play-Abrechnung fehlen in geprüften Dependencies | **P0** | Echte Google-Play-Billing-Integration erst auf separatem Branch, 100 % feature-gated, Kauf nie nur clientseitig freischalten |
| `lib/features/settings/settings_content.dart` | Bereits umfangreicher Elternbereich mit Profil-/Schreibbericht, Lern-DNA, KI-Elternberatung, Cloud-Freigaben | **Wiederverwenden** | Premium-Unterbereich mit Elternprüfung statt neues Menü erfinden |
| `lib/app/app_shell.dart` Zeilen ca. 310–332 und 440–441 | `LumoSection.settings` wird in der geprüften Navigation ohne sichtbare eigene Erwachsenen-Authentifizierung aufgerufen; ein vorgeschaltetes Parent-Gate ist auf diesem Pfad nicht nachgewiesen | **P0 Sicherheit/UX** | Einmalige zentrale Adult-Gate-Prüfung für Zahlung, Verwaltung, PIN/Altersfrage, KI-Freigaben, Datenaktionen; Tests gegen Deep Links/Back-Navigation |
| `lib/features/parents/lumo_insight_dashboard.dart` ca. Zeile 450 | KI-Wochenanalyse setzt `state.childName` in den Anfrage-Text; beim Opt-in kann so ein Kindername in die externe KI-Kommunikation gelangen | **P0 Privacy** | Datenminimierung/Anonymisierung prüfen; Kind beim Proxy nur als „das Kind“ oder pseudonyme ID ohne echten Namen; Opt-in- und Datenschutzhinweis sowie Serverlogging prüfen |
| `lib/core/app_settings.dart` | `aiProxyEnabled = false`, `cloudVoiceEnabled = false`, `microphoneEnabled = false` und Scanner default AUS | **Gute Ausgangsbasis** | Standardwerte erhalten, getrennte Elternfreigaben auch nach Premium-Kauf respektieren. Zahlung ist keine Zustimmung zur Datenverarbeitung. |
| `lib/core/profile_repository.dart` | Aktives lokales Profil via SharedPreferences gespeichert | **P0 Entitlement-Architektur** | Aborecht nicht an `childName` koppeln; kaufenden Eltern-/Play-Konto-Kontext von lokalen Kinderprofilen trennen; Profil-/Wallet-Daten nie bei Abo-Kündigung löschen |
| `lib/features/parents/lumo_insight_dashboard.dart` | Fähigkeiten für visuelle Fortschrittsberichte und Empfehlungen existieren | **Pluspunkt** | Für Premium echtes fertiges Feature freigeben, keine künstlichen Online-KI-Versprechen |
| `PRIVACY.md` | Explizit als Entwicklungsstand mit offenen Datenschutzfragen gekennzeichnet | **P0 Veröffentlichung** | Reale Datenflussinventur (Plugins, Mic, Foto, KI, Stimme, Analytics), DPA/AVV, Lösch- und Aufbewahrungsregeln, Play Data Safety und rechtlich geprüfte Datenschutzerklärung |
| `server/lumo-ai-proxy/README.md` | Chat-/Task-/Sprachendpunkte mit optionalem Opt-in; Serverkonfiguration, Upstream-Kosten und Datenschutz zu prüfen | **P0 Kosten/Sicherheit** | Serverratelimits, Auth, Missbrauchssperren, Budgetgrenzen, Pro-Kopf-Kosten und Logs vor bezahlter „KI“-Leistung prüfen |
| App-PR #259 / Release 1928 | Erfolgreiche Build-/Flutter-Tests und Android-16-Emulator-Nachweise, aber eigenständige `coachpreview`-Paketkennung | **Nicht produktionsfrei** | Finale Play-Paketkennung früh wählen: Signatur-/Package-Wechsel kann Updates und Zugriff auf bestehende lokale Daten verhindern |

**Risikohinweis:** Die Elternbereich-Navigation und die KI-Analyse sind konkrete Ansatzpunkte aus den gezeigten Dateien. Der endgültige Schutzstatus kann erst durch End-to-End-Tests der gesamten App und nach eventuellen neueren Commits bestätigt werden.

## Empfohlenes Entitlement-Design

- Ein `lumo_premium`-Abonnement mit Basisplänen `monthly` und `yearly`; IDs und Preise zuerst als **Entwurf**, erst im autorisierten Play Console-Konto einrichten.
- `EntitlementRepository` mit getrennten Zuständen `unknown`, `free`, `pending`, `active`, `grace`, `on_hold`, `expired`, `revoked` und Testfake für automatisierte Fälle.
- Nur **verifizierter** Kauf und eindeutige Eltern-Kaufberechtigung schalten Premium frei. Informationen aus dem Flutter-Client sind keine sichere alleinige Quelle.
- Secure Backend verifiziert Google-Play-Purchase-Tokens über Play Developer API, entwertet Duplikate, verarbeitet RTDN idempotent, bestätigt erste Abokäufe, behandelt Grace Period/Account Hold/Kündigung/Erstattung.
- Play-Konto-Kaufzuordnung und elterliche Identität datensparsam halten; kein Loginzwang der Kinder, kein Übertragen lokaler Lernstände allein wegen eines Abokaufs.
- `restorePurchases` bei Neuinstallation und Gerätewechsel, soweit die Architektur eine legitime Zuordnung erlaubt. Mehrgeräte-/Familien-Abo zunächst nicht bewerben, bis es implementiert und getestet ist.
- Offline-Verhalten: kurzer klar definierter verifizierter Cache mit Ablauf- und Sperrstrategie; kein dauerhafter Premium-Zugang allein auf Basis manipulierbarer lokaler Preferences.
- **Eltern-Gate** vor Preis-/Kaufdialogen und Verwaltungsaktionen, nicht vor gewöhnlichen Lernaufgaben. Es darf auch nach Navigation, App-Rückkehr und Deep Links nicht umgehbar sein.
- Ein Nutzer kann `Premium` kündigen, ohne Lernstände zu verlieren. Eigenständige Datenlöschung nur über entsprechenden Elternablauf.
- Angebotstexte: Endpreis, Periodizität, automatische Verlängerung, kündbar über Google Play und die tatsächlich verfügbaren Funktionen deutlich angeben.

## Testmatrix vor erstem Verkauf

| Test | Muss bestanden sein |
|---|---|
| Kauf im Play-Lizenztest | Eltern-Gate → Google UI → Serververifikation → Berechtigung |
| Nicht abgeschlossener Kauf | `pending` schaltet kein Premium frei |
| Doppelte Callback-/RTDN-Zustellung | Eine Berechtigung, keine doppelte Abo-/Belohnungsaktivierung |
| Abobestätigung | Erster Kauf fristgerecht acknowledged |
| Rückzahlung / Erstattung / Widerruf | Rechte korrekt zurückgesetzt, Kinderlerndaten bleiben erhalten |
| Gnadenfrist / Kontosperre / Ablauf | korrekte Rechte, verständliche Elternanzeige |
| Restore / Gerätewechsel / Reinstallation | Rechte entsprechend Play-/Backend-Kauf gültig zugeordnet |
| Offline und API-Ausfall | keine Auskunfts-/Datenschutzfunktionen behindert, keine manipulierte lokale Freischaltung |
| Kind auf Kaufbutton | ohne Elternprüfung kein Google-Billing-Sheet |
| Eltern schließen Kaufdialog | App läuft normal weiter; keine begonnene Übung verloren |
| Upgrade von bestehenden APKs | Profile, Sterne, Wallet, Fortsetzen und Audio-/KI-Freigaben bleiben |
| Geräte / Layout | Handy, Cover/Fold, offene Fold-Ansicht, Hoch-/Querformat und Systemränder |
| Datenschutz | Kein Personenname im KI-Request ohne bewusste freigegebene Verarbeitung; keine unerwartete Tracking- oder Ads-SDK |
| Release | Google Play AAB, eigenes Releasekeystore-/Play-App-Signing-Konzept und tatsächlicher Play-Testtrack verifiziert |

## Technischer Stopp-Punkt

**Kein Abo-Verkauf und kein Zahlungsknopf im Kinderkontext** vor abgeschlossener Elternprüfung, Play-Verifikation, Rechts-/Datenschutzfreigabe und echter Closed-Test-Abnahme. Bestehende Lernfunktionalität nicht verschlechtern, nur um eine Paywall zu platzieren.
