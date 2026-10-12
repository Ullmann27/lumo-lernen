# Lumo Lernen – Google-Play-Readiness / Release-Gate
**Stand: 10.10.2026.** Dokumentierter Vorbereitungsschritt, **keine** Behauptung einer Play-Store-Freigabe. Der tatsächliche neue App-Build wurde anhand des Zweiges `computer/lumo-cards-connect-four-2026-10-10` (Stand Version `0.12.15+1922`) untersucht. Andere Branches und PRs müssen vor Integration erneut geprüft werden.

## Ziel und Veröffentlichungsstrategie
**Produkt 1:** Lumo Lernen als Haupt-App mit Lernen, Spielen, Belohnungen, Kinderprofilen, Lumo Cards, 4 Gewinnt, Bauwelt und eingebettetem Lumo Kart. Ein einheitlicher Google-Play-Eintrag und eine gemeinsam gepflegte Lern-/Spielwelt sind die Ausgangsplanung. **Eigenständiges Lumo Kart** ist optional erst nach separater Produktentscheidung; eigene Paket-ID, getrennte Richtlinien, Branding und Release-Tests wären dann erforderlich. Keine Duplikate oder als „fertig“ beworbene unvollständige Spielmodi.

## Verifizierte technische Ist-Befunde
| Prüfpunkt | tatsächlicher Zustand | Konsequenz |
| --- | --- | --- |
| Flutter-Version | `pubspec.yaml`: `0.12.15+1922` im oben genannten Computer-Branch | Für jedes Play-Update VersionCode strikt erhöhen; nach Branch-Merges neu ermitteln. |
| SDK | `scripts/verify_unified_apk.py` prüft `targetSdkVersion:'36'`, `minSdk 24` | Positiv, aber gegen **tatsächliches Play-AAB** nachprüfen. Seit 31.08.2026 erfordert Play für neue reguläre Apps/Updates Android API 36+. |
| Buildformat | `scripts/build_unified_apk.sh`: `flutter build apk --release`, kein AAB im geprüften Workflow | Separaten `flutter build appbundle --release`-Build für einen **neuen Play-Track** implementieren; bestehende APK-Testpipeline unverändert erhalten. |
| Testpaket | `prepare_android.py --side-by-side`, `verify_unified_apk.py` erzwingt `dev.ullmann.lumo.lumo_lernen.coachpreview` | **Nicht** versehentlich als Produktpaket einreichen. Produktionspaket `dev.ullmann.lumo.lumo_lernen` ist Vorschlag aus `prepare_android.py` ohne Flag; vor Produktion ausdrücklich auf Play-Console-Bestand/alte Installationen abstimmen. Ein Play-Paketname kann nach Veröffentlichung praktisch nicht gewechselt werden. |
| Signing | `prepare_android.py`: `release` übernimmt `debug`-Signatur, `tools/lumo-debug.keystore` | **STOP für Play-Produktivfreigabe.** Dedizierten privaten Upload-Key, sichere Secret-Verwaltung, Play App Signing, Signaturprüfung und Backup-Prozess einführen. Keine Keystore-/Passwortdaten in GitHub/Chats speichern. |
| Berechtigungen | `prepare_android.py` fügt `INTERNET, CAMERA, RECORD_AUDIO, REQUEST_INSTALL_PACKAGES` hinzu | **STOP für Play**, bis alle Berechtigungen/SDKs auditiert, an die jeweilige Produktfunktion gebunden und minimalisiert sind. Speziell `REQUEST_INSTALL_PACKAGES` ist für eine Kinder-Lern-App nicht ohne besonderen, zulässigen Kernzweck geeignet; getrennten Play-Flavor ohne diese Berechtigung planen. |
| Godot | `scripts/prepare_embedded_games.py` nutzt Godot 4.6.3, arm64-v8a und x86_64 | AAB-Inhalt, native Bibliotheken, `.pck`, dynamische Delivery-Splits und reale Installation/Start mit `bundletool` prüfen. |
| Datenschutz | `PRIVACY.md` bezeichnet sich ausdrücklich als **Entwicklungsstand**, nicht finale Datenschutzerklärung | Freigegebene Datenschutzerklärung, tatsächliche Datenströme, Empfänger, Löschfristen und Kontaktstelle erforderlich. |
| Netzdienste | Laut `PRIVACY.md` ist der KI-Proxy standardmäßig aus, optional Chat-POST an einen konfigurierten Proxy, TTS/STT/MLKit nutzen eventuell Drittanbieter | SDK- und Netzverkehrs-Audit einschließlich aktivierter Optionen; Data-Safety-Angaben dürfen niemals aus „offline by default“ abgeleitet werden. |
| Artefakt | Erfolgreicher GitHub-Probe-APK-Build 38051726194, noch keine verifizierte Play-AAB-Releasepipeline | Grüner APK-Workflow ≠ Store-Zulassung, Gerätetest oder produktive Uploadsignatur. |

**Quellen im Repo:** `pubspec.yaml`, `scripts/prepare_android.py`, `scripts/build_unified_apk.sh`, `scripts/verify_unified_apk.py`, `scripts/prepare_embedded_games.py`, `PRIVACY.md`, `.github/workflows/release-apk.yml`.

## Nicht verhandelbare Arbeitspakete

### P0 — Produktidentität und Release-Sicherheit (BLOCKER)
- [ ] Mit Verantwortlichem festlegen: erster Play-Eintrag oder bestehender Play-Eintrag? Genaue Package-ID und alte Produktionssignatur überprüfen, bevor *irgendetwas* umgestellt wird.
- [ ] Produktions-Flavor erstellen, der `.coachpreview`-Build und bestehende Tester-Installationen unberührt lässt. Produktionspaket einmalig auf Bestands-/Play-Console-ID festlegen.
- [ ] `REQUEST_INSTALL_PACKAGES` im Play-Manifest entfernen, wenn keine von Google erlaubte Kernfunktion existiert. Ein bestehender Selbstupdate-/APK-Installationspfad darf nicht einfach unangemeldet im Play-Release bleiben. Sideload-Testbuild weiterhin getrennt.
- [ ] Begründung und Laufzeitgrenzen für `INTERNET`, `CAMERA` und `RECORD_AUDIO` prüfen: opt-in, Laufzeitabfrage, Kindermodus und Elternkontrollen; kein Zwangszugriff auf Kamera/Mikrofon beim Appstart.
- [ ] *Dedizierten* Upload-Keystore außerhalb des Repos sicher erzeugen, Backup, Rollen und Passwortverwaltung, Play App Signing konfigurieren. Kein generischer Debug-Key oder veröffentlichter Keystore fürs erste Produktrelease.
- [ ] Getrennten AAB-Workflow und `scripts/build_play_aab.sh` (oder äquivalent) schaffen: bekannte Source-SHA, offizielle Release-Signatur via GitHub Secrets/OIDC, reproduzierbare Godot-Exporte, SHA256, VersionCode, Paketname, Signing-Fingerprint; **ohne** automatisch in Play hochzuladen.
- [ ] Aus AAB mit `bundletool` installierbare APKs auf Emulator/Gerät erzeugen und Android-API-36-Target, armeabi-/arm64-/x86_64-ABIs, Orientierung, Netzbetrieb, `.pck`-Inhalte, Start und Upgrades prüfen.
- [ ] Größenbudget und Android-App-Bundle-/Play-Asset-Delivery-Grenzen mit dem tatsächlichen AAB und Google Play Console überprüfen. Keine Annahme aus einer ~201-MB-Probe-APK.

### P0 — Kinder-/Datenschutz- und Richtlinienfreigabe (BLOCKER)
- [ ] Zielgruppe in Google Play korrekt wählen (Lumo Lernen für Volksschulkinder); Kinder-/Families-Richtlinie, IARC-Altersfreigabe und App-Inhalte tatsächlich beantworten.
- [ ] Alle Datenflüsse/SDKs dokumentieren: Kinderprofile, Namen, Lernfortschritt, Stimmen/Text, Kamera/ML Kit, Mikrofon/STT, KI-Proxy, Render-Server, TTS-Anbieter, Analytik, Crashlogs, Backups, Netzwerk, Retention, Auftragsverarbeiter und Datenübermittlungsorte.
- [ ] Data Safety für Datenzugriff, Erhebung, Weitergabe, Zweck, Verschlüsselung, Löschung, Kinderzielgruppe und SDKs **nach tatsächlicher technischer Prüfung**, nicht mit erfundenen Nein-Angaben ausfüllen.
- [ ] Öffentliche dauerhaft erreichbare Datenschutzerklärung als **Webseite**, in App und Play Listing verlinkt; tatsächlicher Verantwortlicher, Kontakt, Löschfristen, Drittanbieter, Elternrechte und optionaler KI-Datenfluss. `PRIVACY.md` ist nur Vorarbeit.
- [ ] Falls App-Accounts angelegt werden können: Deaktivierung/Löschung inklusive externem Löschanfrage-Link nach Play-Regeln; lokale Profile separat auf Lösch-/Exportmöglichkeit prüfen. Vorhandene Kinder-Daten vor Updates nicht beschädigen.
- [ ] Keine personalisierte Kinderwerbung; Werbung/IAP nur bei gesonderter Familien- und Monetarisierungsprüfung. Keine Kamera-/Mikrofonaufzeichnung oder Datenübertragung ohne erforderliche transparente Einwilligungen.
- [ ] Nur zugelassene SDKs für Kinder, keine verdeckten Tracker; tatsächliches Verhalten im aktiven/inaktiven KI-Modus testen.
- [ ] Entwicklerinformation, öffentliche Support-Mailadresse, Kontaktmöglichkeit und gegebenenfalls Webauftritt einrichten, sobald vom Kontoinhaber freigegeben. Keine Kontaktdaten raten.

### P1 — Play-Store-Eintrag und Markenassets
- [ ] Markenname: **Lumo Lernen** (Arbeitsname, final nach Console-Verfügbarkeit prüfen); Hauptversprechen ist **Lernen + Spielen**, nicht „nur Lumo Kart“. Kein irreführender Shop-Screenshot.
- [ ] App-Icon: 512×512 px, 32-bit PNG sRGB, höchstens 1.024 KB, Original-Lumo/Logo wiedererkennbar; bei Play Store keine selbstgezeichneten Rundmasken/Schatten im Icon.
- [ ] Feature Graphic: 1024×500 px JPEG oder 24-bit PNG ohne Alpha, echte Lumo-Lern- und Spielwelt statt reiner Rennspiel-Werbung.
- [ ] Screenshots: wenigstens zwei reale App-/Spielaufnahmen, empfohlen passende Serien für Smartphone-Hochformat, Kart-Querformat und Tablet/Fold, bei Bedarf bis acht je Gerätetyp. Screenshots müssen tatsächliche Runtime abbilden, keine generierten Konzeptillustrationen.
- [ ] Store-Kurz- und Langbeschreibung (DE, optional EN) auf aktuell tatsächlich funktionierende Features abstimmen, nicht unveröffentlichte Experimente als spielbar bewerben.
- [ ] Optional: Kurzvideo aus echter Android/Godot-Runtime, ohne Fake-Gameplay.
- [ ] Kategorien, Kontaktseite, Altersangabe, Länder (zunächst Österreich/Deutschland nach Entscheidung), Preismodell und Produkttyp (App/Spiel) in Play Console definieren.

### P1 — Testfreigabe
- [ ] Internen Track zum Testen nutzen, kein automatischer Produktionsrollout. Persönliche Entwicklerkonten, die nach 13.11.2023 erstellt wurden, brauchen vor Produktionsfreigabe grundsätzlich **mindestens 12 Tester über 14 Tage fortlaufend im geschlossenen Test**; konkreten Kontostatus in Play Console verifizieren.
- [ ] Android 16, unterschiedliche DPI, klein/großes Fold, Portrait-Lernen/Querformat-Kart, Back-Button, Installations- und Update-Verhalten, lokale Profile/Belohnungen, Offline/Online, Audiofocus, Mic/Camera-Permissions sowie Godot-PCK prüfen.
- [ ] Runtime-Screenshots als Referenz/VORHER/NACHHER/VERGLEICH für alle identitätsstiftenden Szenen; User kann jederzeit korrigieren. Anzeigename, Icon und Store-Bilder erst nach Freigabe.
- [ ] Pre-Launch Report in Play Console, tatsächliche Crash-/ANR-Auswertung und Datenschutz-Review.
- [ ] Nur manuell freigegebene Releases, zuerst geschlossener Test, später gestufter Rollout.

## Release-Gates in einem Satz
**Keine Play-Einreichung, bevor Produktpackage, eigene Uploadsignatur, AAB, Play-konformes Manifest, öffentliche Datenschutzerklärung/Data Safety, Families-Erklärungen, testbarer Store-Eintrag und Runtime-/Installationsnachweis vollständig vorliegen.**

## Offizielle Quellen, Stand 10.10.2026
- Ziel-API-Level API 36 ab 31.08.2026: https://support.google.com/googleplay/android-developer/answer/11926878?hl=de
- Android App Bundle: https://developer.android.com/guide/app-bundle
- Play-Store-Grafiken: https://support.google.com/googleplay/android-developer/answer/9866151
- Families/Kinderschutz: https://support.google.com/googleplay/android-developer/answer/9893335?hl=de
- Data Safety/Datenschutzerklärung: https://support.google.com/googleplay/android-developer/answer/9859455
- Installationsberechtigung: https://support.google.com/googleplay/android-developer/answer/12085295?hl=de
- Account-Löschung (falls Account-Erstellung): https://support.google.com/googleplay/android-developer/answer/13327111?hl=de
- Neue persönliche Developer-Konten: https://support.google.com/googleplay/android-developer/answer/14151465?hl=de-BI

**Status:** Vorbereitung im GitHub-Entwicklungszweig dokumentiert. Kein Play-Console-Zugriff, kein Produktions-AAB, kein produktiver Uploadschlüssel, keine öffentliche Store-Freigabe durch diesen Dokumentationsschritt.
