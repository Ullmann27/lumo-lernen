# Lernstudio: aktuelle Aufgaben bleiben bis zur Antwort erhalten

Der produktive Adapter erkennt nun die tatsächlich vorliegende Multiplikation,
Division und gleichnamige Bruchaddition. Vollständige Bruchausdrücke werden vor
Ganzzahl-Plus/Minus ausgewertet. `1/4 + 2/4` darf kein Payload für `4 + 2` ergeben.
Bruchantworten bleiben rationaler Text: vorher entfernte `_payload` den Schrägstrich
und verwandelte beispielsweise `3/4` in `34`. Das betrifft flüchtige Aufgaben- und
Antwortwerte; bestehende gespeicherte Profile werden nicht migriert.

`NativeLearningActivity.fromTask` prüft die Operanden und die tatsächliche
Aufgabenlösung. Gültige kleine Divisionen öffnen `equal_sharing`, Multiplikationen
das vorhandene `equal_groups` und Bruchadditionen das vorhandene `fraction_parts`.
Der Android-Host wurde um genau den neuen Deskriptor ergänzt. Ein zusätzlicher
Installer-Vertragstest bereitet den echten Host vor und prüft, dass alle von
Flutter erzeugbaren Lernarten zugelassen und unverändert weitergegeben werden.

Die gemeinsame Aktionsschaltfläche **Mit Lumo in 3D ausprobieren** verwendet den
vorhandenen Launcher. Hilfe wird vor dem Aufruf markiert; Rückkehr behält dieselbe
Aufgabe. Die native Ansicht kann keine Antwort, Sterne oder Kompetenz buchen.
Die vorhandenen Eltern-, Test-, Voice- und Profilgrenzen wurden nicht umgebaut.

## Weitere tatsächlich behobene Darstellungsfehler

- `DivisionGroupsVisual` zeigte zuvor höchstens sechs Gruppen und höchstens neun
  Objekte pro Gruppe bei unverändert größerer Überschrift. Es zeigt jetzt alle
  1–12 unterstützten Gruppen. Große Gruppen werden exakt durch mit 100, 10 und 1
  beschriftete Bündel dargestellt. Nicht unterstützte/inkonsistente Aufgaben
  behalten lesbaren Originaltext und bekommen keine erfundene Standarddivision.
- `FractionPizzaVisual` setzte bei zwei Brüchen immer ein Gleichheitszeichen
  dazwischen. Eine Bruchaddition zeigt nun das tatsächliche Pluszeichen.

## Tatsächliche Prüfung

**47 Flutter-Tests bestanden**, davon neun neue Tests zu exakten Aufgabenpayloads,
rationalen Antworten, Ablehnung unpassender Modelle, realen lokalen Generatoren,
vollständigen Gruppen/Bündeln, Bruchoperator und dem vorhandenen Android-Launcher.
Der neue echte `LearningContent`-Widgettest öffnet die aktuelle Bruchaufgabe,
kehrt zur identischen Aufgabe zurück, kontrolliert null Belohnung beim Rücklauf
und beantwortet sie anschließend falsch. Das gespeicherte Antwortprotokoll
enthält die unveränderte Bruchantwort und `hintUsed: true`; der Schwächenzähler
wird dadurch nicht erhöht. Die vorhandenen Tests prüfen zusätzlich
Schularbeitssperre, Profilwechsel, gleichnamige Kinder und alte Eingabecallbacks.

**Vier Hostvorbereitungs-Tests bestanden**. Die gezielte Dart-Analyse der vier
Produktions-/Testdateien meldete **keine Befunde**. Die nativen MethodChannel-
Antworten im Widgettest sind kontrollierte Testdoubles. Hostvorbereitung ist
kein Android-Compile und kein Nachweis hörbarer Sprache.

Rohlogs und Quellhashes: `docs/evidence/studio-learning-20261113/RESULT.json`.
Godot-Interaktionsnachweise stehen im anderen Repository unter
`docs/STUDIO_LEARNING_20261113.md`. Die endgültige APK, aktuelle Rendererbilder
und Fold7-Framezeiten werden vom zentralen Integrationslauf geprüft.
