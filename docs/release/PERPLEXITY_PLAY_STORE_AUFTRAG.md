# PERPLEXITY COMPUTER — LUMO GOOGLE PLAY RELEASE READINESS (Add-on)
Stand: 10.10.2026

**AUFTRAG:** Parallel zur weiterlaufenden Lumo-Kart-/Grafikentwicklung die bestehende **Lumo Lernen**-Flutter+Godot-App für einen späteren Google-Play-Release vorbereiten. Hauptprodukt bleibt Lumo Lernen, mit Kart, Cards, 4 Gewinnt und Bauwelt. Die laufende visuelle Screenshot-/Vorher-Nachher-Kontrolle bleibt verpflichtend; kein neues Comicdesign, keine stillen Änderungen an bestehenden Kinderprofilen.

Quellen:
- https://github.com/Ullmann27/lumo-lernen
- https://github.com/Ullmann27/lumo-godot
- **Lies vollständig:** `docs/release/GOOGLE_PLAY_READINESS_2026-10-10.md` auf Branch `codex/lumo-reference-assets-2026-10-10`.
- Lies ebenfalls den bereits gespeicherten vollständigen Lumo-AAA-Produktionsauftrag unter `docs/design/2026-10-10-lumo-games/LUMO_PERPLEXITY_COMPUTER_AAA_GESAMTPROMPT.txt`.

**Wichtige konkrete Ist-Befunde:**
1. `scripts/build_unified_apk.sh` erstellt eine **APK**, keine `.aab`. Für Play separate AAB-CI schaffen.
2. `scripts/prepare_android.py` unterschreibt bisher auch `release` mit `debug` und erzeugt für Testzwecke `.coachpreview`. **Niemals debug-signed oder `.coachpreview` automatisch als Play-Produkt veröffentlichen.**
3. `prepare_android.py` fügt `REQUEST_INSTALL_PACKAGES` sowie `CAMERA`/`RECORD_AUDIO` hinzu. Play-spezifisches Manifest mit minimalen berechtigten Berechtigungen einführen; test-sideload Build als separaten Flavor erhalten.
4. `verify_unified_apk.py` erwartet targetSdk API36, minSdk 24. Auch *AAB* und generierte Split-APKs unabhängig prüfen.
5. `PRIVACY.md` bezeichnet sich explizit als Entwicklungsstand, die Kinder-/KI-/STT-/MLKit-Datenströme sind noch nicht abschließend geprüft; keine fiktiven Datenschutzerklärungen, Data-Safety-Aussagen oder Kontaktpersonen erfinden.

**SICHERE AUTOMATION:**
- Zuerst Readiness-Audit; lade Google-Play-Originalregeln und eigentliche Quellcode-Dateien, ermittle aktuelle Produkttyp-/Package-ID anhand des vorhandenen Play-Eintrags, **falls du wirklich autorisierten Konsolenzugriff hast**. Andernfalls keine Identität mutmaßlich festlegen.
- Implementiere eine **separate** `playRelease`-Pipeline, die ohne freigegebene Signing-Credentials sicher **fail closed** ist; niemals Keys/Passwörter in Quellcode, GitHub, Logs oder Perplexity-Chats hinterlegen. Test-/Coachpreview-Builds unverändert erhalten.
- Sichere Versionierung, SDK 36, AndroidManifest, ABI/PCK, AAB- und bundletool-Prüfung, Signing-Provenienz, SHA256, Android-16-Emulatorstart und Updateprüfung automatisieren, soweit Werkzeuge zugänglich sind. Kein Merge ohne Regresstests.
- Für Google Play: Kinder-/Families-Konformität, Data Safety, Datenschutz-Webseite, Berechtigungen, Account-Löschung nur falls zutreffend, IARC, Support-Kontakt und Eintragsgrafiken als überprüfbare Liste vorbereiten. Keine Nutzerantworten oder Formulare vortäuschen.
- Store-Grafiken **nur** aus echten Screenshot-Aufnahmen der App/Spiele nach Design-Review; App-Icon 512×512 PNG, Feature-Grafik 1024×500 und passende echte Smartphone-/Fold-Screenshots. Nutze das verbindliche Lumo-Design.
- Beginne mit internem Testtrack und Play-Console-Vorabprüfung nach Nutzerautorisierung. Keine öffentliche Veröffentlichung, keine externen Gebühren oder Käufe, keine produktive Kontoveränderung ohne ausdrücklichen Auftrag.
- Sende bei jedem Meilenstein GitHub-Commit, konkreten Status und echte Vorher-/Nachher-Bilder bei sichtbaren Änderungen. Behalte Astras Art-Direction-/Rendering-Auftrag und den laufenden Perplexity-Computer-Job bei; keine parallelen Konflikte im Godot-Branch.

**JETZT:** Source-Audit, Liste der Release-Blocker, nicht-invasiven AAB- und Manifest-Plan, risikoarme separate PRs. Die zukünftige App nicht jetzt unautorisiert veröffentlichen.
