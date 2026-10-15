# Lumo Kart – Asset- und Produktionsübergabe (10.10.2026)

**Zuerst lesen:** [SOL_MASTER_AUFTRAG.md](./SOL_MASTER_AUFTRAG.md) und [ASSET_BESTAND_UND_TRANSFER.md](./ASSET_BESTAND_UND_TRANSFER.md).

## Status dieser Übergabe

- ✅ Diese Übergabe-Dokumente befinden sich auf dem Branch `chatgpt/lumo-kart-assets-handoff-2026-10-10` im Repository `Ullmann27/lumo-lernen`.
- ✅ Die zehn vorhandenen ZIP-Bände wurden **lokal** geprüft: insgesamt 492.200.065 Bytes; jedes ZIP ist kleiner als 50.000.000 Bytes; 95 Bilddateien aus 32 Ausgangsbildern.
- ⚠️ **Die zehn ZIP-Dateien selbst sind NICHT Teil dieses Git-Branches.** Die GitHub-Verbindung unterstützt hier das Schreiben von Textdateien, aber keinen direkten Upload der vorhandenen binären 492-MB-Archive. Keine in GitHub vorhandenen ZIPs vortäuschen!
- ⚠️ Wenn du als Computer-Agent die ZIPs nicht in deinem Workspace findest, **bitte den Nutzer um die zehn Archive** oder greife auf eine vom Nutzer autorisierte Dateiablage zu. Keine Links erfinden und keine kostenpflichtige Neubildgenerierung anstelle der Originale starten.
- ✅ Die bisherigen Originalreferenzen zum bestehenden App- und Kart-Design sind in den bestehenden GitHub-Branches dokumentiert; prüfe vor Verwendung, ob der jeweilige Referenzpfad unter deiner Checkout-Revision wirklich vorhanden ist.

## Repositories

- Flutter/Android: https://github.com/Ullmann27/lumo-lernen
- Godot-Spiel: https://github.com/Ullmann27/lumo-godot

## Verbindliche alte und neue Gestaltungsvorgaben

- `docs/DESIGN_ZIEL_2026-10-04.md`: Start, Anmeldung, Lernen, Mathematik, Spielewelt, Fold.
- `docs/DESIGN_ZIEL_KART_2026-10-04.md`: fünf Kart-Menükarten, Garage, Cup-/Streckenauswahl, Streckenbausteine und Freizeitracing ohne Matheaufgaben.
- `docs/DESIGN_ASSETS_2026-10-04.md`: vorhandene und geplante Grafik-IDs.
- PR #248 (App): Originalbildarchiv `docs/design/2026-10-10-lumo-games/references/`, u. a. `50666.gif` als besonders wichtige Menüreferenz; **unmerged**.
- PR #256 (App): aktueller Grafik-/Fold-Integrationsstand; **unmerged**.
- PR #51 (Godot): vorhandenes animiertes Lumo-Rig, 65 Knochen, neun Clips; **unmerged**.

## Sofortiger Start

1. Lade diese beiden GitHub-Repositories mit allen relevanten offenen PRs; prüfe SHA und Godot-Pin.
2. Stelle sicher, dass die Originalbilder `50666.gif` und `50294.png` sichtbar sind. Die Visuals sind maßgeblich, keine neue Markengestaltung entwerfen.
3. Prüfe Lumo-Kart-Menü **in echter Laufzeit**, insbesondere Samsung-Fold-Querformat: große Texte, große Touchflächen, Logo, Bühne mit animiertem Lumo.
4. Verifiziere und integriere das vorhandene Animations-Rig aus Godot-PR #51 kontrolliert.
5. Inventarisiere die zehn ZIPs, sobald sie bereitgestellt wurden; bevorzuge die nativen Referenzen, behandle hochskalierte 4K-Bilder ausdrücklich nicht als zusätzliche 3D-Information.
6. Verbessere **eine bereits spielbare Strecke** mit bezahlfreiem Blender-/Godot-Baukasten, Looping, Schanzen, Steilkurven, Boosts und passender Landschaft. Zielrunde ~50 s messen, nicht nur behaupten.
7. Prüfe anschließend die komplette Lern-App von Start/Profil bis Aufgaben/Spiele; erhalte Fortschrittsdaten, Sulafat-System und funktionierende Bereiche.
8. Dokumentiere echte Screenshots, Tests, Commits, offene Fehler; Android-APK nur nach funktionierendem Build und Integritätskontrolle.

## Wichtige Grenzen

Kein unautorisierter Zugriff, keine Umgehung von Login-/Paywall-/Kontosperren, keine kostenpflichtige Meshy-/Tripo-Generierung ohne Zustimmung. Keine eigenen Merges nach `main` und keine ungetesteten Releaseversprechen. Andere Agenten arbeiten parallel insbesondere an Sulafat-Stimme und am 3D-Kart.
