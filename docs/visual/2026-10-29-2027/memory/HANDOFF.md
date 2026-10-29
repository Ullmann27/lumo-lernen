# Memory 2027 – Übergabe für Folgemodelle

## Sicherer Ausgangspunkt

Die unveränderte, bereits freigegebene Lumo-Familien-App ist Build 2003. Dieses Arbeitspaket befindet sich **nur** auf `chatgpt/lumo-2027-memory-stage-20261029`. Die zuvor von Opus geplanten Memory-Agenten waren zum letzten GitHub-Check noch nicht als Remote-Zweig sichtbar. Diese Arbeit darf später nur nach einem aktualisierten Konfliktvergleich mit möglicherweise nachgereichten Agentenänderungen integriert werden.

## Tatsächlich programmiert

- Neue `LumoMemoryStage` als Flutter-`Stack` mit hit-test-neutralem `CustomPaint`, dessen Laufzeit unabhängig von der Kartenzahl bleibt.
- Perspektivisch gezeichnete Tischgravur, Farbreflexe, helles Metallprofil und vier ruhige Lichtpunkte. Kein Material-/Netzwerkdownload, keine Daueranimation.
- Live-Einbindung in die bestehende Memory-Brettansicht: echte 3D-Kartenflip-Logik, Paarregeln, Schwierigkeitsgrade, Lumo-Gegner und lokale Bestwerte bleiben unverändert.
- Kartenrückseite erhält hochwertigen vierstufigen Cyan/Blau-Metallverlauf.
- Neuer Widgettest für 344×882, 690×829 und 850×392. Er sucht den echten Stage-Key, überprüft `IgnorePointer`, hitteste die Karte und tippt sie an.

## Qualität und Grenzen

Diese Oberfläche ist eine kostenarme 2.5D-Inszenierung und **noch kein vollständiger filmischer Memory-Redesign**. Keine Behauptung über tatsächliche 60 FPS oder Fold7-Rendering. Keine Live-APK. Neue Bilder oder die Original-Memory-Regeln wurden nicht ersetzt.

## Nacharbeiten

1. Auf dem Branch `flutter analyze` und fokussierte `flutter test --concurrency=1 test/games/memory_screen_test.dart test/games/memory_match_feedback_test.dart test/games/memory_2027_stage_test.dart` durchführen.
2. Echte Vorher-/Nachher-Captures bei 344×882 und 690×829 erstellen und manuell beurteilen.
3. Bei bestandenem CI den branch-spezifischen Diff gegen aktuelle 2027-Memory-Agentenergebnisse vergleichen, erst dann eine Integration erwägen.
4. Die existierende signierte Familien-App nicht deinstallieren oder die Release-2003-Artefakte ändern.


## CI-Folgereparatur

Der neue Spiele-PR löste die alte `Lumo Games Visual QA – genuine before/after` aus. Der unveränderliche 1989→1990-Test verlangt ausdrücklich die Versionen `0.12.77+1989` und `0.12.78+1990`, scheiterte deshalb auf der korrekten 2003-Basis bei der Versionserkennung, **vor jeder Grafikprüfung**. Als begrenzte Abhilfe sind die zwei exakten Quellen aus dem bereits bestehenden geprüften Reparaturzweig `repair/lumo-historical-visual-qa-20261022` bytegleich übernommen:

- `.github/workflows/lumo-games-before-after.yml`: Job `capture-games` ausschließlich für die beiden historischen 1990-Branches, ohne die originalen Beweisversionen zu ändern.
- `scripts/tests/test_historical_games_visual_qa_scope.py`: sichert den genauen Branch-Filter und die unveränderten historischen Beweise.

Dies ist eine **CI-Falschpositiv-Reparatur**, keine Veränderung an Memory-Spielstand oder App-Veröffentlichung. Die tatsächlich neuen Memory-Tests und der kombinierte 2003-Android-Build bleiben weiterhin verpflichtend.
