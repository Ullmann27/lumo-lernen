# LUMO: zusätzliches Drei-Agent-Team — Integration 23.11.2026

## Konkreter Auftrag und Zusammenarbeit
Heinz bat, den vorherigen LUMO-Entwicklungsbericht mit drei zusätzlichen Coding-Agents zu unterstützen. Diese Sitzung hat drei echte Agents für Logikspiel, Gestaltung/Weltkarte und Bewohneraufträge eingesetzt. Die Koordinatorarbeit verbindet die Ergebnisse mit dem weiterlaufenden Hauptchat über dessen PRs und die gemeinsame Koordination [#537](https://github.com/Ullmann27/lumo-lernen/issues/537). Eine direkte Live-Verbindung zwischen den beiden Chat-Agentbäumen wird nicht behauptet.

Der aktuelle übernommene Hauptchat-Stand ist `91a121f4302a4840ede44ece8a0494477d81c579`. Seine beiden korrigierten Menü-/Navigationstests bleiben erhalten. Die Unterstützungs-PRs sind [Flutter #539](https://github.com/Ullmann27/lumo-lernen/pull/539) und [Godot #211](https://github.com/Ullmann27/lumo-godot/pull/211), jeweils zum Entwicklungszweig `feature/logic-world-20261123`. main bleibt unverändert.

## Spielbare Ergänzungen
- **Pfotenpfad:** 24 verschiedene deterministische Wegrätsel, sechs je Schulstufe. Das Kind plant eine Pfeilfolge, besucht nummerierte Sterne und erreicht das Picknick. Verschiedene gültige Lösungen und Umwege werden akzeptiert; Rand und Hindernisse werden tatsächlich simuliert.
- **Eingliederung:** vierte Karte im bisherigen Logikmenü; individuelle Programme, Abschlüsse und Auswahl pro Kind; Backup, Profilreset und Gesamtrücksetzung berücksichtigen die neuen Daten.
- **Echte Darstellung:** Phone-/Fold-Aufnahmen zeigten fehlende Unicode-Pfeile in der Originalschrift. Richtungstasten und Programmschritte verwenden jetzt Material-Icons; die Sternfolge verwendet lesbare Textziffern.
- **Weltkarte:** identischer Maßstab in beiden Achsen, Standort und Blickrichtung, vier Orte, Ziel-/Orts-/Gesamtfokus und große Bedienflächen. Lange Hinweise stehen im scrollbaren Dialog.
- **Freundepost:** drei tatsächliche Lieferungen Nelli → Bruno → Tilda → Nelli nach den sechs Hauptmissionen. Das Paket reist sichtbar zu Fuß oder im Kart; die Übergabe erfordert Nähe und Interaktion. Drei Freundschaftsstempel werden gespeichert; die Funktion erzeugt keine zusätzlichen Sterne oder XP.
- **Erkunden und Speichern:** Die Ampel bleibt nach der Hauptgeschichte von beiden Gehsteigen bedienbar. Wiederholtes Drücken verlängert die Wartezeit nicht. Fehlgeschlagenes Speichern bleibt ausstehend; unbekannte zukünftige Freundepost-Daten bleiben vollständig erhalten.
- Original-Schatzsuche, vorhandene Dorfwirtschaft, Schulbelege, Schreibtrainer und Journal bleiben erhalten.

## Nachgewiesene Ergebnisse vor diesem APK-Bau
- [Supportlauf 45175546161](https://github.com/Ullmann27/lumo-lernen/actions/runs/45175546161): Flutter-Analyse ohne Befunde, **53 Tests bestanden**; ursprüngliche World-Regression **169** und Freundepostmodell **289** bestanden.
- [Supportlauf 45176854451](https://github.com/Ullmann27/lumo-lernen/actions/runs/45176854451): Flutter mit dem Iconfix bei `7c0004736c95c293c310336d161f6c3cd5b441cc` erneut **53 Tests bestanden**, Analyse ohne Befunde; echte Phone-/Fold-PNGs wurden vom Koordinator gesichtet. Sein älterer nativer Prüfabschnitt wird dadurch nicht als grün ausgegeben.
- Godot **4.6.3**, dieselbe Version wie der APK-Bau: Controller **22**, Map **149 im Headless-Lauf** und tatsächliche World-Produktionsmethoden **27** Prüfungen bestanden. Die vollständigen CI-/Rendererläufe auf dem nun gepinnten nativen Stand sind separat erforderlich.
- Die Controllerprüfung beendete ursprünglich Godot mit aktivem Autoload-Klickton. Der vorhandene Teardown-Helfer prüft jetzt die tatsächliche Mixerfreigabe; es werden keine ERRORs ausgeblendet.
- Der Map-Test verwendet jetzt bereits lokale Viewportkoordinaten korrekt; der frühere Minimalprojekt-Test berücksichtigte den echten Projekt-Stretch noch nicht.
- Die World-Integration lädt nach Autoloadstart und vergleicht tatsächlich JSON-dekodierte Zukunftsdaten. Alle 27 fachlichen Assertions bleiben erhalten.
- Der gemeinsame JVM-Downloadhelfer besteht **20 Regressionstests**. Er behebt wiederholte HTTP 429-Downloads mit SHA-geprüftem gemeinsamem Cache, begrenztem Retry-After und unverändertem JAR-Pin; vier bestehende Suites verwenden denselben Helfer. Kein Test wird übersprungen.

Details zu Quellidentitäten und tatsächlichen lokalen Ausführungen:
- `team-b-evidence/world-errands-audio-teardown-report.json`
- `team-b-evidence/world-support-integration-report.json`

## Gemeinsamer Kandidat und verbindliche Freigabe
Version **0.14.1+2070**, Bauauftrag **46**, nativer Pin **93557b3ca206916a39fdeaa6ae6ce05442b08846**.
Der neue `lumo-team-b-apk.yml` baut nur auf dem Supportzweig und verändert den 2069-Bau des Hauptchats nicht.

Veröffentlichung erfolgt erst nach den vorhandenen verbindlichen Schritten: feste saubere Quellen, Flutter-/JVM-/Godot-Prüfungen, tatsächliche Rendererbilder, signierte ARM64- und x86_64-Pakete, übereinstimmender PCK-/Versions-/Zertifikatsnachweis, installierte Android-Tour, native Starts und vollständiger Android-Backup-Rundlauf. Auch Godot-ERRORs bei Exitcode 0 lassen die neuen Proben fehlschlagen. Anschließend werden APK-Prüfsumme, Herkunft und Tourstatus erneut geprüft und ein neuer unveränderlicher Test-Release erstellt.

**Dieser Commit allein bestätigt weder eine fertige APK noch einen erfolgreichen Android-Lauf.** Diese Ergebnisse sind ausschließlich am zugehörigen tatsächlichen Workflow und dessen Release-Asset zu belegen. Ein physisches Fold 7 oder stabile 60 FPS wurden hier nicht gemessen.

## Wiederaufnahme
1. Die beiden neuen Workflows auf genau diesem Flutter-SHA prüfen.
2. Bei einem echten Fehler nur den betroffenen Schritt reparieren; keine Prüfungen abschwächen.
3. Den endgültigen APK-Link erst nach vorhandenem Release-Asset, Größe, SHA256, Quell-/Godot-Pin und Signaturprüfung ausgeben.
4. Ergebnisse an die PRs #538/#539 und Godot #210/#211 sowie Koordination #537 übergeben. Kein Main-Merge.
