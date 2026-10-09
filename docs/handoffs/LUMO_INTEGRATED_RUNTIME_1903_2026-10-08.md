# Lumo1903 – bestätigter Pausefix und robuste Android-Abnahme

Status beim Commit: **VISUAL_GAP / NOT FINISHED**. APK1903 ist vor dem tatsächlichen
Build und den Android-Jobs nicht freigegeben. Keine Main-Übernahme oder Release.

## Aktive Herkunft

- App-Produkt-BASE: `22b221b2ebe5c85562f359e471c8ca2d44ee8354` (PR216).
- Übernommener QA-RESULT: `bd08f8c51672c80edb82439e6ec69c26ad74a3b1`
  (PR218), mit Parent4f7108f9 (PR217). Beide Merge-Eltern bleiben erhalten.
- Godot-BASE: `9f17cd2f7af652917a0c1290e506e1211a08fb3f`.
- Tatsächlicher neuer Exportpin: `18238d48f96b76c4175b705a9bf05e82e339bdd0`,
  Tree `a34537f0126732cc666d183f1cd7c8b39c2f0664`, Godot4.6.3 (PR29).
- Eigener Integrationsbranch beider Repositories:
  `codex/lumo-integrated-runtime-2026-10-08`; Version `0.12.1+1903`.
- App-RESULT ist der tatsächliche HEAD/saubere CI-Checkout dieses Commits und
  wird im gebauten `BUILD-PROVENANCE.json` gebunden; keinen älteren SHA einsetzen.
- Folgepaket-BASE: `76daa1fbf005d7ff3b74c17ec7241ef728a46785`,
  Tree `d652e20ad1521b7779b950b49439a7c4977b0f83`. Freier Arbeitsbranch:
  `codex/lumo-kart-modal-scroll-2026-10-08`; anschließend gleicher Commit im
  bestehenden Integrationsbranch/PR216. Version1903 bleibt, weil noch keine
  1903-APK gebaut wurde. Produkt-Godotpin18238d48 bleibt unverändert.

## Bestätigte Fehler und kleinstes Folgepaket

Der tatsächliche1902-APK-Lauf37803223814 hat einen erfolgreichen Build,
Build/Rhythmus auf API35 PASS und Puzzle/Treasure/Kart35/Kart36 FAIL.
Die frühen Puzzle-/Treasure-Touchziele stammen aus einer noch unvollständigen
nativen Oberfläche. Die alte Kart-Probe akzeptierte die gespeicherte Ergebnis-ID
des vorherigen Rennens. Unabhängig davon überdeckte die eingefrorene Startzahl
sichtbar das echte Pausemenü: ein reproduzierter Produktionsfehler.

Godot ändert ausschließlich die Sichtbarkeit der Startlichter und friert den
verbleibenden Grün-Timer während Pause ein. Neue echte Garage/Touch-Prüfung:
Preview, Countdown, Grün und Fahrt jeweils Pause/Fortsetzen, acht Fälle, neun
reale PNGs. BASE strikt RED; neuer Tree strikt GL GREEN/Exit0/keine ERRORs.
Bestehende Camera/CompleteFlow/Continuity wurden gezielt sauber geprüft.
Der separate PauseLayout-Wrapper war wegen falsch angegebenem Sollmarker formal
FAIL; tatsächliche Testausführung Exit0/PASS. Diesen Fehlversuch erhalten.

Die Android-Proben warten vor realen nativen Touches auf aktuelle vollständige
Frames und zwei stabile, tatsächlich erkannte OCR-Ziele innerhalb eines
120-s-Gesamtbudgets. Exact-Captions bleiben bis OCR-Varianten/Tile-Fallback exakt.
Der vollständige Kartablauf verlangt vor der ersten Pause eine neue stabile
Renn-ID, exaktes Setup, natürlich abgeschlossenen Countdown, elapsed>=1,
Gate0 und unfinished; Rohsaves und Readiness-Journal werden erhalten.
Keine gesetzte Position, Zielauslösung, ACK oder Belohnung. Bestehende16Gates/
zweiRunden, Hostevent, genau3Sterne/0XP und Duplicate-Replay-Gates bleiben strikt.

262 lokale Python-Guards PASS/0SKIP/0FAIL; unabhängige Surface16/Fullrace28-Prüfung
und echte ursprüngliche TSV-/Frame-Replays PASS. Das sind keine Android-Runs.
Der getrennte Followup37810681375 prüft genau die unveränderte alte1902-APK
(SHA6436beeadc7355b1d4681c4621a160cbfe1136ee764ab57c9801506855f8edd3).
Sein Erfolg darf nicht als Nachweis des neuen1903-Produktpins ausgegeben werden.

## Belegte Folgefehler und Abbruchkriterien

Followup37810681375: Puzzle35 und Treasure35 PASS; Kart35 und Kart36 FAIL.
Beide Kartjobs erreichten tatsächlich neue Renn-ID, vollständiges HUD und Pause.
Danach verwendete die Probe das sichtbare HUD-GAS außerhalb des Pausemodals
als Scrollanker: zehn unveränderte Frames pro API, keine Fahrt/ACK/Belohnung.
Die neue Probe verlangt die zwei tatsächlich sichtbaren festen Navigationstexte
als Modalgrenzen, passende Inhaltstexte und zwei vollständige stabile Frames.
Beide Swipe-Endpunkte müssen innerhalb des beobachteten Inhalts liegen.
Bare HUD-GAS, fehlende/mehrdeutige Grenzen, Größenwechsel und unvollständige
Frames berechtigen keinen Swipe. 40 fokussierte Guards PASS/0SKIP; unabhängige
Review ohne Blocker. Alle20 Original-PNG/OCR-Paare sind gegen die unveränderten
ZIP-Memberbytes/Hash/CRC geprüft; ihre neue Geometrie bleibt im Modal.
Das ist ausschließlich Offline-Geometrieprüfung, kein erfolgreicher Androidlauf.

App76daa1fb, Run37811278021: Quellen und20 Native-Proben PASS, APK-Bau FAIL
beim tatsächlichen Download von NDK28.2.13676358: `Archive is not a ZIP archive`.
APK-Schritt und alle Androidjobs SKIPPED. Quelle sauber, generierte Testdateien
im separaten Buildcheckout leer; Transportursache nicht belegt.
Neue frühe NDK-Prüfung verwendet ausschließlich das bereits konfigurierte Paket
und vorhandene offizielle sdkmanager-Syntax. Exakte Paketrevision und tatsächlicher
Linux-Clang werden geprüft. Nur der belegte ZIP-Fehler auf ausdrücklich disposable
CI-Runner erlaubt einen begrenzten Reinstall des exakten Pakets. Ursprüngliche
Logs bleiben erhalten; Timeout, Logverlust, Identitäts-/Compilerfehler, fehlende
Lizenzen oder anderer Installfehler brechen ab. Keine automatische Lizenzannahme,
NDK-Ausweichversion oder Löschung fremder SDK-Pakete.
Quelle: https://developer.android.com/tools/sdkmanager ; eigene kleine Anpassung
des bestehenden Buildablaufs, kein übernommener fremder Implementierungscode.
Echte temporäre Fake-SDK-Integrationstests prüfen diese Fehler-/Retrygrenzen;
20 NDK-Fälle und alle29 Scriptprüfungen lokal PASS/0SKIP; komplette Android-
Guard-Suite274 lokal PASS/0SKIP. Fokusfälle sind Teilmengen, nicht addieren.
reale NDK-Installation erst im neuen CI-Lauf. Erfolgsbedingung ist die tatsächlich
gebaute, verifizierte APK und unverändert strenge Android-Abnahme. Bei neuem
Fehler zuerst Originaldaten auswerten; keine Tests abschwächen.

## Neue CI und notwendige Auswertung

Der eigene Runtimeworkflow prüft aktuelle Flutter-/Backend-/Inhaltsquellen und
20 strenge Native-Proben einschließlich neuer Pauseprüfung/neun echter PNGs.
QA-Pillow12.3.0 ist im isolierten Venv deklariert; tatsächliche optionale Skips
und Abhängigkeiten werden aufgezeichnet. APK-Bau bleibt in sauberem separatem
Checkout; unerwartete getrackte Änderungen bleiben ein harter Fehler.
Der bekannte generierte Testcapture wird dokumentiert, nicht zum Produktcode.

Erst tatsächliche1903-APK bauen, Paket/Version/Signatur/ELF/PCK prüfen und alle
fünf Modi API35 plus Kart API36 auswerten. Beide Kartjobs müssen echte Fahrt,
Pause/Save/Offline-Reopen, Ziel/Ergebnis, Host-ACK/Wallet und Replay sowie
Menü/Pause/Ergebnis-Außen→Innen→Außen mit unverändertem Fortschritt prüfen.
Rohlogs, echte Androidbilder und Rundenvideo erhalten; keine Dateinamen als
Beweis einer erfolgreichen Flutter-Rückkehr verwenden.

## Offene Grenzen

Materialien, Gesicht/Produktionsrig und Gesamtwelt bleiben VISUAL_GAP.
CPU/GPU/Framezeiten, Speicher/Wärme/Soak, ARM-Gerät, physisches Fold und
Touch→Physik→Feedback sind NOT EXECUTED. Kein60FPS-Versprechen.
YouTube-Referenz hat bisher0 zugängliche echte Frames: zeitlicher Vergleich
NOT EXECUTED. Lumo-Identität und bestehende Referenzen bleiben verbindlich.
Loopings/Wand/Schiene sind nicht freigegeben; separater Shop-Speicherclaim offen.
Alle alten Build-/Android-Fails bleiben im Abschlussjournal erhalten.
