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
