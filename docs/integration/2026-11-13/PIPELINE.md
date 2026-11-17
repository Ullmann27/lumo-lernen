# LUMO: aktive Integration und Reparatur

Stand: 13. November 2026. Ein Hauptintegrator und drei Helfer übernehmen bestehende fertige Beiträge und reparieren konkret nachgewiesene Anschlussfehler. Andere Teams entwickeln auf ihren eigenen Zweigen weiter. Der Besitzer hat geplante Aufgaben ausdrücklich abgelehnt; die kurz erstellte Folgeprüfung ist deaktiviert. Dieser Stand startet keinen Hintergrunddienst.

Gemeinsamer Sammelpunkt: [Flutter PR #465](https://github.com/Ullmann27/lumo-lernen/pull/465), Zweig `integration/lumo-connections-20261113` in beiden Repositories. Die aktuelle Quellenwarteschlange steht in `status.json`. Eigene GitHub-Checkpoints werden mit erwartetem alten SHA geschrieben und gegen den lokalen Git-Baum geprüft; lokale und remote Commit-IDs können wegen unterschiedlicher Commit-Metadaten abweichen.

## Integrierte Quellen

Produktbasis ist inzwischen Flutter `8eab228433f124c1e2332e3d3c2ecf462ec8b136`. Die fertige Supportquelle aus #464 einschließlich der späteren Logcat-Korrektur für Bewegungsnachweise ist erhalten. Der alte 1999-Updatejob bleibt auf seinen tatsächlichen historischen Kandidaten beschränkt; sein Prüfkörper ist unverändert.

Studio-Host `a8e09123805b2bf30706c8dd1914b928ae6b24ca` und der passende native Studio-Snapshot `cfa9f6657a2fda218f8752dbd21e4cfb49045a70` sind im Integrationsbaum. Native benötigt zusätzlich den bereits reparierten Blender-Importausschluss, die echte Körperraum-Fußhubprüfung und die angeschlossenen Sharing-/Puzzle-Gates. Der neue JSON-Vertrag prüft reale Flutter-Launchdaten mit Godots Parser und Produktionsmodell: Division, asymmetrische Multiplikation und Brüche bleiben unverändert.

Host `fe66edf97ae1cf8b680fd1b596ea06425352b379` reicht die bestehenden Offline-Sprachoptionen auch für scene=build durch. Die Zusammenführung erhält Studio equal_sharing in MainActivity. Die zusätzliche Quellenprüfung bestätigt: HostBridge und SceneRouter erhalten diese Optionen, aber beide veröffentlichten Bauwelt-Skripte in `7c088c5` rufen noch kein LumoHost.speakLearning auf. Die hörbare Bauwelt-Sprachfunktion wartet deshalb auf den bereits beim Producer bearbeiteten nativen Anschluss.

Die bislang fehlenden brauchbaren Garage-/Resume-Nachweise aus #456 sind an das aktuelle Menü angeschlossen: echte Kart- und Fahrerwahl, neue Rennidentität, Pause, tatsächlicher Weiterfahren-Touch und messbare Weiterfahrt desselben Rennens. Der Fahrer wird anhand der beobachteten Karte gewählt, weil der sichtbare Schriftzug Lumo sonst mit dem Logo verwechselt werden konnte. Die responsiven Pokal-/Grand-Prix-Beschriftungen werden aus dem aktuellen Bildschirm gelesen. Kein gespeicherter Spielzustand wird zur Auswahl injiziert.

## Tatsächliche Prüfungen und Grenzen

- Historischer kompletter Skriptlauf: 318 PASS, 0 Fehler/Skips auf dem im Manifest festgehaltenen Baum. Der frühere Android-Probe-Vertragslauf mit 736 PASS gilt ebenfalls nur für seinen damaligen Quellstand.
- Aktuelle betroffene Garage-/Pokal-/Tour-Verträge: 53 PASS, 0 Fehler/Skips, mit unveränderten Quellhashes. Vorherige 48er/41er Nachweise bleiben historische Belege.
- Studio: 91 gezielte Flutter-Tests und der Host-Generierungsvertrag PASS. Fünf tatsächlich serialisierte Aufgaben werden zusätzlich mit 135 Godot-Prüfungen gelesen; das ist kein Android-IPC-Nachweis.
- Bauwelt-Sprachoptionen auf kombiniertem Studio-Host: 47 Flutter-, 12 Python-/Host-/Offline- und 9 Kotlin-Returnstore-Tests PASS.

Rohprotokolle, genaue Kommandos und Quellhashes liegen unter `docs/evidence/integration-20261113/`. Es gibt noch keine neue reale Android-Tour, keine Abnahme auf einem physischen Fold7 und keine neue visuelle Freigabe des kombinierten Native-Standes.

## Noch zusammenzuführen

Die Grafiklieferung `01cf063` wird mit ihren inzwischen veröffentlichten Folgekorrekturen geprüft. Ein tatsächlicher Zugriff auf beim Kartvariantenwechsel freigegebene Anker wird repariert; die bereits vom Producer veröffentlichte Audio-Freigabe der Szenenaufnahmen wird wiederverwendet. Die freie Bauwelt aus `7c088c5` ist als separates fertiges Modul geprüft. Die neue Dorf-UI und ihre Sprach-/Story-Anschlüsse waren beim letzten Quellenvergleich noch lokale Producer-Nachfolger. Rooms/Cards und die gesonderte 2019-APK-QA enthalten ebenfalls noch keine veröffentlichte fertige Übergabe; siehe `rooms_cards_handoff.md`.

**Dieser PR bleibt ein Entwurf für eine zusammengehörige Host-/Native-Lieferung.** Der aktuelle Host-Pin und die bestehende Bildfreigabe beziehen sich weiterhin auf `ada5ed81ad62339f15289da62670c0a4f9f7f2b9`. Sie werden erst durch einen konkret geprüften neuen Native-SHA und dessen originale Rendererbelege ersetzt. Alte Freigaben werden nicht umetikettiert; Puzzle gehört in die neue Abnahme. Der aktive Produktlauf 43428626135 bleibt im Besitz des Release-Teams. Der frühere Lauf 43405216014 wurde wegen der Produktaktualisierung beendet. Main und die Producer-Arbeitsbäume bleiben geschützt.
