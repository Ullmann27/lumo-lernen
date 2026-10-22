# Lumo Lernen – Google-Play-Abnahme (Quellcodeaudit, 19.10.2026)

**Status: NICHT produktionsfreigegeben.** Dieses Dokument ist die
Release-Entscheidung nach Quellcodeprüfung, keine Play-Console-Abnahme.
Der bestätigte Direktinstallations-Testbuild ist **1986**.
Build **1987** ist Entwicklungsarbeit, unabhängig davon, ob Screenshots
bereits real gerendert wurden.

## Entscheidung: zuerst Lumo Lernen, Spiele kontrolliert

- Lumo Lernen bleibt das Kernprodukt, einschließlich Mathe, Deutsch,
  Englisch, Geschichten, Schreibtrainer und bestehenden Kinderdaten.
- Vier Gewinnt bleibt verfügbar; dafür existieren echte Spiel- und Testszenen.
- Lumo Cards bleibt spielbar, sobald die faire, varianzreiche Gegnerstrategie
  auf echter APK samt Regressionstests bestätigt ist.
- Die grafisch unreife Bauwelt trägt im Katalog **In Entwicklung** und
  wird über die vorhandene `_comingSoon`-Oberfläche nicht gestartet.
  Die Daten werden **nicht gelöscht**.
- Lumo Kart (Rennspiel) bleibt als getrennt abzusicherndes, eingebettetes
  Godot-Modul sichtbar. Freigabegrad 60 FPS oder AAA ist **nicht gemessen**.
  Release-Entscheidung erst nach Gameplay-Screenshots, Crash- und FPS-Proben.
- Unfertige Features dürfen nicht in Store-Screenshots als fertig erscheinen.

## Technische Play-Blocker – source confirmed

| Gate | Quelle | Ergebnis |
| --- | --- | --- |
| Android Target API 36 | `scripts/verify_unified_apk.py` | Der APK-Verifikator prüft 36; tatsächliches Store-AAB gesondert nachweisen |
| AAB statt APK | `scripts/build_unified_apk.sh` | **BLOCKIERT:** bislang `flutter build apk`, kein verifiziertes `flutter build appbundle` |
| Paket-ID für öffentliches Play | `scripts/build_unified_apk.sh`, `scripts/prepare_android.py` | **BLOCKIERT:** Entwicklungsinstallation verwendet `--side-by-side` / `.coachpreview`; produktive ID an Play-Console-Status binden |
| Produktionssignierung | `scripts/prepare_android.py` | **BLOCKIERT:** Release nutzt `tools/lumo-debug.keystore` mit Debug-Passwort; niemals als Play-Upload-Schlüssel verwenden |
| Minimalberechtigungen | `scripts/prepare_android.py` | **BLOCKIERT:** `REQUEST_INSTALL_PACKAGES` wird für sideload-Updates hinzugefügt; eigener Play-Kanal muss diese Berechtigung entfernen, sofern kein von Play gestatteter Kernzweck gegeben ist |
| Kinder-Datenschutz | `PRIVACY.md` | **BLOCKIERT:** lokale Kinderprofile, optionale Mikrofon-/Kamera-Funktion und ein schaltbarer externer KI-Proxy. Tatsächliche Netzwerkziele, SDKs, Elternfreigaben, Auftragsverarbeiter und Datenfristen prüfen |
| 16-KB-Seitengrößen | eingebettete Godot-Engine, native Android-Plug-ins | **OFFEN:** für API ≥35 64-bit natives Packaging und 16-KB-Seitengrößen anhand tatsächlichem AAB/emulierter 16-KB-Runtime prüfen |
| Größe/Asset Delivery | 1986 APK ~316 MB | **OFFEN:** AAB-Inhalt, Download-/Base-Modulbudget und Play Asset Delivery für große integrierte Kart-/3D-Dateien prüfen |
| Privatsphäre/Store-Angaben | `PRIVACY.md` | **BLOCKIERT:** öffentlich erreichbare, zutreffende Datenschutzerklärung, Data Safety, Familien-Erklärungen, Altersfreigabe und Store-Listing müssen final überprüft werden |
| Google Play Console | nicht über diesen Repositorycode zugänglich | **NICHT VERIFIZIERT:** Kontotyp, alte Paket-ID, Testerstatus, Veröffentlichungsrechte, Signatur und Zahlungsprofil erfordern Play-Console-Prüfung |

## Offizielle Anforderungen (Stand 19.10.2026)

1. Seit 31.08.2026 **Target API 36** für neue Mobile-Apps/Updates:
   https://support.google.com/googleplay/android-developer/answer/11926878
2. Neue Google-Play-Apps verwenden **Android App Bundle**:
   https://support.google.com/googleplay/android-developer/answer/9844279
3. Für Kinder: **Families**, sensible Daten, SDKs, Berechtigungen und Werbung:
   https://support.google.com/googleplay/android-developer/answer/9893335
4. Privatsphäre und Data Safety:
   https://support.google.com/googleplay/android-developer/answer/10144311
5. **16-KB-native Page Size**, aktuelle Kompatibilitäts-/Deadlinehinweise:
   https://developer.android.com/guide/practices/page-sizes
6. Neue persönliche Entwicklerkonten nach 13.11.2023: grundsätzlich
   **12 Tester ≥14 Tage** geschlossener Test vor Produktionsfreigabe:
   https://support.google.com/googleplay/android-developer/answer/14151465

## Reihenfolge mit überprüfbaren Outputs

1. 1987 Flutter-Tests und visuellen Vergleich reparieren und Emulator-Apk
   abnehmen; nicht den stabilen 1986-Direktdownload ersetzen.
2. Faire Lumo Cards / Bauwelt-Preview-Gate mit echten Tests und Screenshots
   für Handy + Fold in nächsten getesteten Release integrieren.
3. Kart-FPS, Grafik, Intro und Spiele auf Android (nicht nur Unit-Tests)
   mit echten Screenshots prüfen, ohne alte Fortschrittsdaten zu verlieren.
4. Einen getrennten **Play-AAB-Flavour** mit bekannter Paket-ID und
   dediziertem privatem Upload-Key **nur nach geklärter Signatur-/ID-Frage**
   und ohne `REQUEST_INSTALL_PACKAGES` implementieren. Keine Schlüssel im
   Repository, Chat oder Log speichern.
5. AAB + `bundletool` auf realen 64-bit-Emulatoren, API36,
   16-KB-Seiten, Fold und Performance verifizieren; Größenlimit auf
   Basis des fertigen AAB statt der APK messen.
6. Datenschutz, Play-Konsole/Closed Test, Store-Grafiken, Beschreibung
   und Familienrichtlinien nach realen Datenflüssen abnehmen.

**Freigaberegel:** Keine Aussage „Play-Store-ready“ ohne grüne AAB-/Geräte-
Tests, verifizierte Produkt-ID/Uploadsignatur und überprüfte gesetzliche,
Familien- und Kontoangaben.
