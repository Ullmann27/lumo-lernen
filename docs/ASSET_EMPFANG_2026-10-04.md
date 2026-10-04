# Lumo – direkte Bildübergabe und Fortsetzung

Stand: 04.10.2026. Transport-CLAIM in #156: 5979331664. Basis des isolierten Beitrags: `be1e48ae3110351de81dd6ea20e15bbb9508c3ae`. Dieses Dokument und der Downloadhelfer verändern keine App, keine vorhandenen Bilder und keine Freigaben.

## 1. Jetzt abrufbare Originalbytes des Einzelbildpakets

Der bisher fehlende Dateianhang wird durch einen tatsächlich geprüften HTTPS-Download ersetzt. Heinz muss die Datei nicht erneut manuell hochladen.

- Paketname: `Lumo_Assetpaket_Einzelbilder_2026-10-04.zip`
- Download: https://d2ol7oe51mr4n9.cloudfront.net/user_3JBiq3Q9vttoZVrKhdbYLuTHXre/3f6109fb-0429-4acc-9ef0-22219252239a.zip
- Exakte Größe: **24.962.269 Bytes**, unter 30.000.000 Bytes.
- SHA-256: **e32a2d6e78d1af8d51c4e27b6b66c5a87d2c2da252a5f61a3e7da0d76a5ffe20**
- ZIP-Inhalt: 170 Einträge, 25.155.311 unkomprimierte Bytes.
- Wurzel im Archiv: `Lumo_Assetpaket_Einzelbilder_2026-10-04/`.

Der Transport erfolgte über den verbundenen Higgsfield-Dateidienst; der Link liefert die ZIP, nicht eine Bilderzeugung. Es wurden keine neuen Bilder oder Videos generiert. Upload per HTTP 200 bestätigt, anschließend diese endgültige URL in einer getrennten Cloud-Umgebung erneut heruntergeladen: Bytezahl, SHA-256, ZIP-CRC und Eintragszahl stimmen. Die Paketbytes sind unverändert gegenüber dem bereits übergebenen Chat-Paket. Es handelt sich nicht um einen GitHub-Release-Anhang und noch nicht um einen Import in die App. Diese Unterschiede ausdrücklich erhalten.

Enthalten: **134 transparente Einzel-PNGs**, zehn Kart-Referenzbilder, neun Sichtprüfungsbögen, Manifest, Zuordnungstabelle, Einbau-/Physikanleitung und Prüfwerkzeuge. Davon sind 125 getrennte Motive aus neun Tafeln und neun separat erzeugte Symbole. Das Paket enthält nicht sämtliche noch benötigten Fachsymbole: `docs/OFFENE_ASSETS.md` nennt 33 nicht gelieferte kanonische Anforderungen. Keine Vollständigkeit oder fertige 3D-Geometrie behaupten.

Das getrennte Originaltafelpaket aus #168 mit SHA `5adbd9dd...` ist eine andere Datei. Nicht mit diesem geschnittenen Einzelbildpaket verwechseln und keine zweite Freistellung beginnen, wenn das vorhandene Motiv bereits geeignet vorliegt.

## 2. Empfang ohne Eingriff in den Arbeitsbaum

Auf dem Zweig dieses Beitrags den kleinen Helfer zuerst lesen, dann ausführen:

```sh
python3 scripts/assets/fetch_lumo_bundle_2026_10_04.py
```

Der Helfer lädt ausschließlich die feste URL, lehnt Umleitungen ab, prüft Länge und SHA **vor** dem Entpacken und verweigert unsichere Pfade, doppelte Namen, verschlüsselte Einträge, Symlinks und übergroße Archive. Er verwendet ein neues temporäres Verzeichnis, kein bestehendes Repo-Verzeichnis, und druckt `archive_path`, `unpacked_root` und den Prüfnachweis. Keine Abhängigkeiten, Secrets oder neuen Workflows nötig. Bereits tatsächlich empfangene Bytes lassen sich netzwerkfrei prüfen:

```sh
python3 scripts/assets/fetch_lumo_bundle_2026_10_04.py --local-zip /echter/pfad/zum/paket.zip
```

Die Pfade aus der Ausgabe gehören zur eigenen Sitzung. Nicht den `/mnt/data`-Pfad einer fremden Chat-Sitzung kopieren. Bei gesperrtem Netz den konkreten Downloadfehler bzw. den Host `d2ol7oe51mr4n9.cloudfront.net` melden; keine Sicherheitsfreigabe umgehen und keine erfolgreichen Downloads behaupten.

Nach Empfang `README.md`, `docs/EINBAUAUFTRAG.md`, `docs/ASSET_GRENZEN.md`, `INTEGRATION_MAP.json` und die Prüfskripte lesen. In einer vorhandenen geeigneten Python-Umgebung mit Pillow:

```sh
python3 "$UNPACKED_ROOT/tools/verify_package.py" --root "$UNPACKED_ROOT" --zip "$ARCHIVE_PATH"
python3 "$UNPACKED_ROOT/tools/plan_import.py" --repo /echter/pfad/lumo-lernen
```

`UNPACKED_ROOT` und `ARCHIVE_PATH` zuvor aus der eigenen Helferausgabe setzen. Fehlende Pillow-Abhängigkeit ist eine konkrete Einschränkung, kein bestandener Bildtest. Der Importplan bleibt lesend. Erst danach konkrete Produktionspfade beanspruchen und ausgewählte, geprüfte Motive integrieren. Existierende Icons aus #165 und kanonische Fuchs-Posen nicht blind ersetzen. Referenzen/QA-Bögen nicht in die APK bündeln.

## 3. Maßgeblicher Produktauftrag – keine konkurrierende Neufassung

Der ausführliche, bereits vorhandene Bericht liegt in **PR #168**, Commit `708945c03e1ac8b292db2b8f28a5d232be51d541`:

https://github.com/Ullmann27/lumo-lernen/blob/708945c03e1ac8b292db2b8f28a5d232be51d541/docs/PRODUKTAUFTRAG_LERNFORTSCHRITT_KART_2026-10-04.md

Er enthält den beauftragten 120-Minuten-Arbeitsblock und die technischen/visuellen Abnahmekriterien. Diesen Bericht lesen und weiterführen, nicht daneben neu implementieren. Aktuelle Benutzerentscheidung geht widersprechenden alten ZIP-/HUD-Texten vor:

**Lernen ist Hauptzweck. Lernfortschritt schaltet Memory, das eigene UNO-ähnliche Lumo Cards, gegebenenfalls später ausgewählte weitere kleine Spiele und schließlich Lumo Kart frei. Innerhalb von Lumo Kart keine Lernfragen, Antworttimer, Lern-Cups oder Richtig=Turbo-Mechanik – auch nicht optional.** Die Bilder bleiben Gestaltungsreferenz; alte Lern-Challenge-Panels sind gerade nicht 1:1 zu übernehmen.

Weitere Minispiele, produktive Freischaltschwellen und Preise sind nicht beschlossen. Keine Fantasiewerte als Nutzerentscheidung ausgeben. Bestehende verdiente Freischaltungen und gespeicherter Fortschritt bleiben erhalten; ausgegebene Sterne dürfen dauerhafte Freischaltungen nicht zurücknehmen. Keine echten Käufe, Tarife oder Secrets aktivieren. Optionale besondere Fahrzeugteile sind getrennte, fair gestaltete Shop-Arbeit; der Lernkern und das überwiegend kostenlose Spiel haben Vorrang.

## 4. Reihenfolge für die bestehende Sitzung

1. Aktuelle Heads, Kommentare, Claims, übernommene Änderungen und Prüfberichte lesen. **#167 ist der bereits nachgewiesene CI-Reparaturkandidat**; den alten `.ci-results`-Fehler nicht nochmals lösen. Fehlende unabhängige Freigaben bleiben offen. Kein automatischer Fertig-Merge.
2. Dieses Paket empfangen, prüfen und Empfang im Thread bestätigen. Der externe Download ist belegt, der Eingang bei Luna muss noch aus ihrer tatsächlichen Sitzung belegt werden.
3. Den Lernkern und die dauerhafte, idempotente Freischaltlogik zuerst prüfen. Luna bearbeitet das vorhandene Flutter-Design, responsive Navigation und Kart-Anbindung; Claude übernimmt tatsächlich verfügbare unabhängige Prüfungen, Lernlogik/TTS; ChatGPT prüft Transport, Quellbindung und QA. Gleichberechtigte Zusammenarbeit, kein Chefwechsel.
4. Die Einzelgrafiken im bestehenden Designsystem in der gesamten App einsetzen: Start, Lernen, Tests, Spielewelt, Profil, Garage, Cups und Streckenvorschauen. Echte Widgets, echte Daten und echte Zielzustände statt Screenshot-Tapete oder statischer Beispielzahlen. Die elf Repo-Flutter-Ziele und zehn Kart-Vorlagen berücksichtigen; Abweichungen dokumentieren.
5. Kart als echte räumliche Arbeit fortsetzen: unterscheidbare Himmelsinsel-, Wasserfall-, Lichterstadt- und Wissenswald-Welten, Geometrie, Kollision, Checkpoints, Fahrsteuerung/Drift/Bremsen/Boost/Rücksetzen/Kamera. PNGs sind Modell-/Vorschaureferenzen, keine fertigen befahrbaren Meshes und keine konsistenten Animationsframes. Den Godot-Pin aus #168 prüfen; ein neuer Flutter-Build allein übernimmt nicht automatisch den aktuellen Godot-PR.
6. Nach kleinen Etappen reale Screenshots, Tests, neues SHA-Paar und Einschränkungen liefern; anschließend konfliktfrei weiterarbeiten. Bei Fehlern drei echte Runden, ein Reparaturbearbeiter und unabhängige Nachtests. Fehlende Agentenantworten nicht simulieren und Limits nicht durch weitere Sitzungen umgehen.

60 FPS auf dem Fold7 ist ein zu messendes Ziel, keine zugesicherte Folge des Bildpakets. Reale Frametimes, längere Rennläufe, Wärme-/Speicherverhalten, schmale/offene Fold-Darstellung und Pause/Rückkehr testen. Größere APK-Megabytes sind kein Qualitätsbeleg; keine künstliche Aufblähung.

## 5. Tatsächliche Prüfungen dieses Transportbeitrags

- Endgültiger HTTPS-Download in getrennter Cloud-Umgebung: exakte Länge, SHA-256, 170 Einträge und CRC bestanden.
- Downloadhelfer lokal mit den echten Paketbytes: Entpacken in neues temporäres Verzeichnis bestanden.
- Neun lokale Archiv-Sicherheitsfälle: acht ungültige Eingaben abgewiesen, ein gültiger Fall akzeptiert.
- Unverändertes Paketprüfskript auf entpackten Originalbytes: **134 PNGs und 169 Datei-Prüfsummen bestanden, keine Fehler**.
- App-, Godot-, Android-, TTS-, Grafik- und 60-FPS-Geräteabnahme durch diesen Transportbeitrag: **NICHT AUSGEFÜHRT**.

Eine fertige gemeinsame APK erst nach den erforderlichen unabhängigen Nachweisen zum selben Flutter-/Godot-Kandidaten bauen, tatsächlich herunterladen und Paket/Version/Signatur/Quellbindung/SHA prüfen. Build 280 ist ausdrücklich kein fertiger Design-Kandidat. Keine Freigaben umgehen.
